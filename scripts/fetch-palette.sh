#!/bin/bash

# Color Palette Hunter - Fetch palettes from colorhunt.co and coolors.co
# Supports multiple themes, search queries, and output formats

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
THEME=""
QUERY=""
LIMIT=5
FORMAT="json"
OUTPUT=""
FETCH_TYPE="search"  # search, trending, popular, random
SOURCE="colorhunt"    # colorhunt or coolors
COOLORS_URL=""
CACHE_DIR="${XDG_CACHE_HOME:-.cache}/color-palette-hunter"
CACHE_FILE=""

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -s, --source <SOURCE>      Palette source: colorhunt|coolors (default: colorhunt)
  -t, --theme <THEME>        Search by theme (pastel, vibrant, dark, modern, etc.)
  -q, --query <QUERY>        Free-form search query
  -l, --limit <NUM>          Number of palettes to fetch (default: 5)
  -f, --format <FORMAT>      Output format: json|css|tailwind|html (default: json)
  -o, --output <FILE>        Save to file instead of stdout
  --trending                 Fetch trending palettes
  --popular                  Fetch popular palettes
  --random                   Get random palettes
  --coolors-url <URL>        Fetch a specific Coolors palette by URL
  -h, --help                 Show this help message

Examples:
  $(basename "$0") --trending --limit 10
  $(basename "$0") --source coolors --trending --limit 5
  $(basename "$0") --coolors-url "https://coolors.co/264653-2a9d8f-e9c46a-f4a261-e76f51"
  $(basename "$0") --theme pastel --limit 5 --format css
  $(basename "$0") --query "modern minimalist" --format tailwind --output palette.json
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--source)
                SOURCE="$2"
                shift 2
                ;;
            -t|--theme)
                THEME="$2"
                shift 2
                ;;
            -q|--query)
                QUERY="$2"
                shift 2
                ;;
            -l|--limit)
                LIMIT="$2"
                shift 2
                ;;
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            --trending)
                FETCH_TYPE="trending"
                shift
                ;;
            --popular)
                FETCH_TYPE="popular"
                shift
                ;;
            --random)
                FETCH_TYPE="random"
                shift
                ;;
            --coolors-url)
                COOLORS_URL="$2"
                SOURCE="coolors"
                FETCH_TYPE="url"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                usage
                ;;
        esac
    done
}

# Generate cache key
generate_cache_key() {
    local key="${FETCH_TYPE}:${THEME}:${QUERY}:${LIMIT}"
    echo "$key" | sha256sum | awk '{print $1}'
}

# Fetch from Color Hunt API (via web scraping)
fetch_colorhunt() {
    CACHE_FILE="${CACHE_DIR}/$(generate_cache_key).json"
    
    # Check cache first
    if [[ -f "$CACHE_FILE" && $(( $(date +%s) - $(stat -c%Y "$CACHE_FILE" 2>/dev/null || stat -f%m "$CACHE_FILE") )) -lt 3600 ]]; then
        echo -e "${GREEN}✓ Using cached palettes${NC}" >&2
        cat "$CACHE_FILE"
        return 0
    fi
    
    echo -e "${YELLOW}Fetching palettes from Color Hunt...${NC}" >&2
    
    local url="https://www.colorhunt.co/php/feed.php"
    
    # Map fetch types to valid sort values (trending/hot are not supported by the API)
    local sort_value="$FETCH_TYPE"
    case "$FETCH_TYPE" in
        trending)
            sort_value="popular"
            ;;
        search)
            sort_value="popular"
            ;;
    esac
    
    # Fetch with timeout and retry logic
    local response
    response=$(curl -s --max-time 10 --retry 2 --retry-delay 1 \
        -H "User-Agent: Mozilla/5.0" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "Referer: https://www.colorhunt.co/" \
        -X POST \
        -d "step=0&sort=${sort_value}&tags=${THEME:-}${QUERY:-}&timeframe=30" \
        "$url" 2>/dev/null || echo "[]")
    
    # Check if response is valid JSON array
    if echo "$response" | jq -e 'type == "array"' >/dev/null 2>&1; then
        # Convert colorhunt format to our standard format
        local palettes="[]"
        local count=0
        while IFS= read -r item; do
            local code likes date
            code=$(echo "$item" | jq -r '.code // empty')
            likes=$(echo "$item" | jq -r '.likes // 0')
            [[ -z "$code" ]] && continue
            local colors="[]"
            local i=0
            while [[ $i -lt 4 ]]; do
                local hex="${code:$((i*6)):6}"
                [[ -z "$hex" ]] && break
                colors=$(echo "$colors" | jq --arg c "#$hex" '. + [$c]')
                i=$((i+1))
            done
            local name="Palette $((count + 1))"
            palettes=$(echo "$palettes" | jq \
                --argjson colors "$colors" \
                --arg name "$name" \
                --arg likes "$likes" \
                '. + [{"name": $name, "colors": $colors, "likes": ($likes | tonumber), "source": "colorhunt"}]')
            count=$((count + 1))
            [[ $count -ge $LIMIT ]] && break
        done < <(echo "$response" | jq -c '.[]')
        
        local result
        result=$(echo '{"palettes": []}' | jq --argjson palettes "$palettes" '.palettes = $palettes')
        
        echo "$result" > "$CACHE_FILE"
        echo "$result"
        return 0
    fi
    
    # Fallback: try to extract palette codes from HTML page
    echo -e "${YELLOW}⚠ API returned non-JSON, scraping HTML...${NC}" >&2
    local html
    html=$(curl -s --max-time 10 --retry 2 --retry-delay 1 \
        -H "User-Agent: Mozilla/5.0" \
        "https://www.colorhunt.co/palettes/${FETCH_TYPE}" 2>/dev/null || echo "")
    
    if [[ -z "$html" ]]; then
        echo -e "${RED}✗ Failed to fetch palettes${NC}" >&2
        return 1
    fi
    
    # Extract palette codes from data-code attributes or palette links
    local codes
    codes=$(echo "$html" | grep -oP 'data-code="[A-Fa-f0-9]{20}"' | sed 's/data-code="//;s/"//' | head -n "$LIMIT")
    
    if [[ -z "$codes" ]]; then
        # Try alternative pattern: palette links (20-char hex)
        codes=$(echo "$html" | grep -oP '/palette/[A-Fa-f0-9]{20}' | sed 's|/palette/||' | head -n "$LIMIT")
    fi
    
    if [[ -z "$codes" ]]; then
        # Try hex codes in URL paths
        codes=$(echo "$html" | grep -oP '[A-Fa-f0-9]{20}' | sort -u | head -n "$LIMIT")
    fi
    
    if [[ -z "$codes" ]]; then
        echo -e "${RED}✗ No palettes found${NC}" >&2
        return 1
    fi
    
    local palettes="[]"
    local count=0
    while IFS= read -r code; do
        [[ -z "$code" ]] && continue
        local colors="[]"
        local i=0
        while [[ $i -lt 4 ]]; do
            local hex="${code:$((i*6)):6}"
            [[ -z "$hex" ]] && break
            colors=$(echo "$colors" | jq --arg c "#$hex" '. + [$c]')
            i=$((i+1))
        done
        local name="Palette $((count + 1))"
        palettes=$(echo "$palettes" | jq \
            --argjson colors "$colors" \
            --arg name "$name" \
            '. + [{"name": $name, "colors": $colors, "source": "colorhunt"}]')
        count=$((count + 1))
        [[ $count -ge $LIMIT ]] && break
    done <<< "$codes"
    
    local result
    result=$(echo '{"palettes": []}' | jq --argjson palettes "$palettes" '.palettes = $palettes')
    
    echo "$result" > "$CACHE_FILE"
    echo "$result"
}

# Fetch from Coolors.co
fetch_coolors() {
    # If a specific URL was provided, parse colors directly from it
    if [[ "$FETCH_TYPE" == "url" && -n "$COOLORS_URL" ]]; then
        fetch_coolors_url "$COOLORS_URL"
        return $?
    fi

    CACHE_FILE="${CACHE_DIR}/coolors_$(generate_cache_key).json"

    # Check cache first
    if [[ -f "$CACHE_FILE" && $(( $(date +%s) - $(stat -c%Y "$CACHE_FILE" 2>/dev/null || stat -f%m "$CACHE_FILE" 2>/dev/null) )) -lt 3600 ]]; then
        echo -e "${GREEN}✓ Using cached palettes${NC}" >&2
        cat "$CACHE_FILE"
        return 0
    fi

    echo -e "${YELLOW}Fetching palettes from Coolors...${NC}" >&2

    local base_url=""
    case "$FETCH_TYPE" in
        trending)
            base_url="https://coolors.co/palettes/trending"
            ;;
        popular)
            base_url="https://coolors.co/palettes/popular"
            ;;
        random)
            base_url="https://coolors.co/palettes/trending"
            ;;
        search)
            if [[ -n "$THEME" ]]; then
                local encoded=$(echo -n "$THEME" | jq -sRr @uri)
                base_url="https://coolors.co/palettes/tag/${encoded}"
            elif [[ -n "$QUERY" ]]; then
                local encoded=$(echo -n "$QUERY" | jq -sRr @uri)
                base_url="https://coolors.co/palettes/tag/${encoded}"
            else
                base_url="https://coolors.co/palettes/trending"
            fi
            ;;
    esac

    # Coolors has no public API and renders palettes via JavaScript.
    # Scraping the HTML page does not yield palette URLs.
    # For browsing, users should use --coolors-url with a direct link.
    echo -e "${YELLOW}⚠ Coolors requires a direct URL (--coolors-url).${NC}" >&2
    echo -e "${YELLOW}  Browse palettes at https://coolors.co/palettes and copy a URL.${NC}" >&2
    echo -e "${YELLOW}  Example: --coolors-url \"https://coolors.co/264653-2a9d8f-e9c46a-f4a261-e76f51\"${NC}" >&2
    return 1
}

# Fetch a single Coolors palette by URL
fetch_coolors_url() {
    local url="$1"

    # Extract colors directly from the URL (format: HEX1-HEX2-HEX3-...)
    local colors
    colors=$(echo "$url" | grep -oP '[A-Fa-f0-9]{6}' | sed 's/^/#/')

    if [[ -z "$colors" ]]; then
        echo -e "${RED}✗ No colors found in URL: $url${NC}" >&2
        return 1
    fi

    local color_array
    color_array=$(echo "$colors" | jq -R . | jq -s .)
    local name
    name=$(echo "$colors" | head -1 | sed 's/^#//')

    local result
    result=$(echo '{"palettes": []}' | jq \
        --argjson colors "$color_array" \
        --arg name "$name" \
        --arg url "$url" \
        '.palettes = [{"name": $name, "colors": $colors, "source": "coolors", "url": $url}]')

    echo "$result"
}

# Convert JSON to CSS format
to_css() {
    local palettes="$1"
    
    cat << 'EOF'
/* Color Palettes */

EOF
    
    echo "$palettes" | jq -r '.palettes[] |
    ".palette-\(.name | gsub("[^a-zA-Z0-9]"; "-") | ascii_downcase) {" as $sel |
    $sel,
    (.colors | to_entries | map("  --color\(.key + 1): \(.value);") | .[]),
    "}"
    '
}

# Convert JSON to Tailwind format
to_tailwind() {
    local palettes="$1"
    
    cat << 'EOF'
module.exports = {
  theme: {
    extend: {
      colors: {
        palette: {
EOF
    
    echo "$palettes" | jq -r '.palettes[] | 
    .colors | to_entries | 
    map("          \(.key + 1): \"\(.value)\",") | .[]' | head -n -1
    
    echo "        \".colors[-1]: \(.colors | .[-1])\""
    
    cat << 'EOF'
        }
      }
    }
  }
}
EOF
}

# Convert JSON to HTML with color swatches
to_html() {
    local palettes="$1"
    
    cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Color Palettes</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 20px; background: #f5f5f5; }
        .palette { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .palette-title { font-size: 18px; font-weight: 600; margin-bottom: 15px; color: #333; }
        .colors { display: flex; gap: 10px; margin-bottom: 15px; }
        .color-box { flex: 1; height: 100px; border-radius: 4px; display: flex; align-items: flex-end; justify-content: center; color: white; font-size: 12px; font-weight: bold; text-shadow: 0 1px 2px rgba(0,0,0,0.3); }
        .color-code { background: white; color: #333; padding: 8px 12px; border-radius: 4px; font-size: 12px; font-family: monospace; cursor: pointer; }
        .color-code:hover { background: #f0f0f0; }
        .tags { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 10px; }
        .tag { background: #e0e0e0; color: #555; padding: 4px 12px; border-radius: 12px; font-size: 12px; }
    </style>
</head>
<body>
    <h1>Color Palettes from Color Hunt</h1>
EOF
    
    echo "$palettes" | jq -r '.palettes[] | 
    "<div class=\"palette\">
        <div class=\"palette-title\">\(.name // "Unnamed")</div>
        <div class=\"colors\">" + 
    (.colors | map("<div class=\"color-box\" style=\"background: \(.)\"><span class=\"color-code\">\(.)</span></div>") | join("")) +
    "</div>" +
    (if .tags then "<div class=\"tags\">" + (.tags | map("<span class=\"tag\">\(.)</span>") | join("")) + "</div>" else "" end) +
    "</div>"'
    
    cat << 'EOF'
</body>
</html>
EOF
}

# Main execution
main() {
    parse_args "$@"

    # Validate source
    if ! [[ "$SOURCE" =~ ^(colorhunt|coolors)$ ]]; then
        echo -e "${RED}Invalid source: $SOURCE${NC}"
        echo "Supported: colorhunt, coolors"
        exit 1
    fi

    # Validate format
    if ! [[ "$FORMAT" =~ ^(json|css|tailwind|html)$ ]]; then
        echo -e "${RED}Invalid format: $FORMAT${NC}"
        echo "Supported: json, css, tailwind, html"
        exit 1
    fi

    # Fetch palettes
    local palettes
    if [[ "$SOURCE" == "coolors" ]]; then
        palettes=$(fetch_coolors)
    else
        palettes=$(fetch_colorhunt)
    fi
    
    if [[ -z "$palettes" ]]; then
        echo -e "${RED}Failed to fetch palettes${NC}" >&2
        exit 1
    fi
    
    # Convert format
    local output
    case "$FORMAT" in
        json)
            output="$palettes"
            ;;
        css)
            output=$(to_css "$palettes")
            ;;
        tailwind)
            output=$(to_tailwind "$palettes")
            ;;
        html)
            output=$(to_html "$palettes")
            ;;
    esac
    
    # Output
    if [[ -n "$OUTPUT" ]]; then
        echo "$output" > "$OUTPUT"
        echo -e "${GREEN}✓ Saved to $OUTPUT${NC}"
    else
        echo "$output"
    fi
}

main "$@"

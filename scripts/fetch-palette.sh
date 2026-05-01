#!/bin/bash

# Color Palette Hunter - Fetch palettes from colorhunt.co
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
CACHE_DIR="${XDG_CACHE_HOME:-.cache}/color-palette-hunter"
CACHE_FILE=""

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -t, --theme <THEME>        Search by theme (pastel, vibrant, dark, modern, etc.)
  -q, --query <QUERY>        Free-form search query
  -l, --limit <NUM>          Number of palettes to fetch (default: 5)
  -f, --format <FORMAT>      Output format: json|css|tailwind|html (default: json)
  -o, --output <FILE>        Save to file instead of stdout
  --trending                 Fetch trending palettes
  --popular                  Fetch popular palettes
  --random                   Get random palettes
  -h, --help                 Show this help message

Examples:
  $(basename "$0") --trending --limit 10
  $(basename "$0") --theme pastel --limit 5 --format css
  $(basename "$0") --query "modern minimalist" --format tailwind --output palette.json
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
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
    if [[ -f "$CACHE_FILE" && $(( $(date +%s) - $(stat -f%m "$CACHE_FILE" 2>/dev/null || stat -c%Y "$CACHE_FILE") )) -lt 3600 ]]; then
        echo -e "${GREEN}✓ Using cached palettes${NC}" >&2
        cat "$CACHE_FILE"
        return 0
    fi
    
    echo -e "${YELLOW}Fetching palettes from Color Hunt...${NC}" >&2
    
    local url=""
    case "$FETCH_TYPE" in
        trending)
            url="https://www.colorhunt.co/api/palettes/trending?count=$LIMIT"
            ;;
        popular)
            url="https://www.colorhunt.co/api/palettes/popular?count=$LIMIT"
            ;;
        random)
            url="https://www.colorhunt.co/api/palettes/random?count=$LIMIT"
            ;;
        search)
            if [[ -n "$THEME" ]]; then
                url="https://www.colorhunt.co/api/palettes/search?q=${THEME}&count=$LIMIT"
            elif [[ -n "$QUERY" ]]; then
                # URL encode the query
                local encoded_query=$(echo -n "$QUERY" | jq -sRr @uri)
                url="https://www.colorhunt.co/api/palettes/search?q=${encoded_query}&count=$LIMIT"
            else
                # Default to trending if no search term
                url="https://www.colorhunt.co/api/palettes/trending?count=$LIMIT"
            fi
            ;;
    esac
    
    # Fetch with timeout and retry logic
    local response
    response=$(curl -s --max-time 10 --retry 2 --retry-delay 1 -H "User-Agent: Mozilla/5.0" "$url" 2>/dev/null || echo "{}")
    
    if [[ -z "$response" || "$response" == "{}" ]]; then
        echo -e "${RED}✗ Failed to fetch palettes${NC}" >&2
        return 1
    fi
    
    # Cache the result
    echo "$response" > "$CACHE_FILE"
    echo "$response"
}

# Convert JSON to CSS format
to_css() {
    local palettes="$1"
    
    cat << 'EOF'
/* Color Palettes from Color Hunt */

EOF
    
    echo "$palettes" | jq -r '.palettes[]? | 
    ":root--\(.name | gsub("[^a-zA-Z0-9]"; "-") | ascii_downcase) {" as $name |
    ($name | split("--") | join(" ") | ltrimstr(" ")) as $selector |
    "." + ($selector | gsub(" "; "-")) + " {"' | while read line; do
        if [[ -n "$line" ]]; then
            echo "$line"
        fi
    done
    
    echo "$palettes" | jq -r '.palettes[] | 
    to_entries | 
    map("  --color-\(.key + 1): \(.value.color);") | .[]' 
    
    echo "}"
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
    
    # Validate format
    if ! [[ "$FORMAT" =~ ^(json|css|tailwind|html)$ ]]; then
        echo -e "${RED}Invalid format: $FORMAT${NC}"
        echo "Supported: json, css, tailwind, html"
        exit 1
    fi
    
    # Fetch palettes
    local palettes
    palettes=$(fetch_colorhunt)
    
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

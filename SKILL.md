---
name: color-palette-hunter
description: Automatically fetch color palettes from Color Hunt (colorhunt.co) and Coolors (coolors.co) based on design requirements. Extract trending, popular, or search-based palettes and export them for design applications. Integrates with the-designer theme catalog for genre-aware palette recommendations and OKLCH token generation.
---

# Color Palette Hunter Skill

## Overview
This skill provides an automated interface to discover and extract color palettes from Color Hunt (colorhunt.co) and Coolors (coolors.co). Perfect for design work, it fetches palettes based on themes, trends, or custom queries and exports them in multiple formats for immediate use in design tools. Integrates with the-designer's theme catalog and OKLCH token system for production-ready design tokens.

## MCP Integration

When the `the-designer` MCP server is installed alongside this skill, both systems coexist:

| Capability | MCP Tool | Skill Script |
|------------|----------|--------------|
| Fetch palettes | `palette_fetch` (native TS API) | `scripts/fetch-palette.sh` (CLI) |
| Convert formats | `palette_convert` (TS) | `scripts/palette-to-design.py` (CLI) |
| Palette variants | `generate_palette_variants` (TS) | — |
| Token generation | `generate_tokens` (TS) | — |
| Theme catalog | `list_themes` (TS) | — |
| Genre detection | `detect_genre` (TS) | — |

**Workflow integration**: After fetching palettes via `palette_fetch`, use `detect_genre` to classify the design context, then `list_themes` + `generate_tokens` to produce an OKLCH-based token system that incorporates the fetched palette as accent colors.

**Standalone usage**: The skill scripts work independently without the MCP installed. Use the CLI commands below for direct terminal access.

## Usage
- **Role**: Design Color Curator
- **Trigger**: "Find color palettes for [theme]", "Get trending palettes", "Search palettes for modern design"
- **Output**: Color palettes in JSON, CSS, or direct Tailwind/design tool formats

## Dependencies
- `curl`: For HTTP requests to Color Hunt
- `jq`: For JSON parsing and formatting
- `python3`: For advanced palette processing and format conversion

## Commands

### `scripts/fetch-palette.sh`
Fetches color palettes from Color Hunt with multiple filtering options.

**Syntax:**
```bash
./scripts/fetch-palette.sh [OPTIONS]
```

**Options:**
- `-s, --source <SOURCE>`: Palette source: `colorhunt` or `coolors` (default: colorhunt)
- `-t, --theme <THEME>`: Search by theme (e.g., "modern", "pastel", "vibrant", "dark")
- `-q, --query <QUERY>`: Free-form search query
- `-l, --limit <NUM>`: Number of palettes to fetch (default: 5)
- `-f, --format <FORMAT>`: Output format - json|css|tailwind|html (default: json)
- `-o, --output <FILE>`: Save to file instead of stdout
- `--trending`: Fetch only trending palettes
- `--popular`: Fetch only popular palettes
- `--random`: Get random palettes
- `--coolors-url <URL>`: Fetch a specific Coolors palette by URL

**Examples:**

1. **Fetch trending palettes:**
   ```bash
   scripts/fetch-palette.sh --trending --limit 5
   ```

2. **Search palettes by theme:**
   ```bash
   scripts/fetch-palette.sh --theme pastel --limit 10
   ```

3. **Fetch from Coolors (URL only):**
   Coolors has no public API — palettes are loaded via JavaScript. Only direct URL fetching works:
   ```bash
   scripts/fetch-palette.sh --coolors-url "https://coolors.co/264653-2a9d8f-e9c46a-f4a261-e76f51"
   ```

4. **Fetch and generate themed tokens:**
   ```bash
   # Fetch palette
   scripts/fetch-palette.sh --theme ocean --format json > ocean-palette.json
   ```
   Then via MCP: `palette_convert` → `detect_genre` → `generate_tokens`

5. **Get palettes with custom query:**
   ```bash
   scripts/fetch-palette.sh --query "modern minimalist" --format tailwind
   ```

6. **Export to CSS variables:**
   ```bash
   scripts/fetch-palette.sh --trending --format css --output palette.css
   ```

7. **Get random palettes for inspiration:**
   ```bash
   scripts/fetch-palette.sh --random --limit 3 --format html
   ```

### `scripts/palette-to-design.py`
Converts fetched palettes into design-specific formats.

**Syntax:**
```bash
python3 scripts/palette-to-design.py <INPUT.json> --target <FORMAT>
```

**Formats:**
- `tailwind`: Tailwind CSS color configuration
- `figma`: Figma design token format
- `scss`: SCSS variables
- `css`: CSS custom properties
- `android`: Android color resources
- `swift`: Swift color literals

**Examples:**
```bash
# Convert to Tailwind config
python3 scripts/palette-to-design.py palettes.json --target tailwind

# Convert to Figma tokens
python3 scripts/palette-to-design.py palettes.json --target figma
```

## The-designer Integration Workflow

For production-ready design systems, combine palette hunting with the-designer's theme catalog:

```
1. palette_fetch({ mode: "theme", theme: "ocean", limit: 3 })
   → Returns hex palettes from Color Hunt

2. detect_genre({ brief: "ocean-themed analytics dashboard" })
   → Returns "modern-minimal" (or appropriate genre)

3. list_themes({ genre: "modern-minimal" })
   → Returns Cobalt, Coral themes with OKLCH values

4. generate_tokens({ theme_name: "Cobalt" })
   → Returns tokens.css with all OKLCH color tokens, fonts, spacing

5. palette_convert({ palettes, target: "css" })
   → Converts fetched palette to CSS custom properties
```

### Color Discipline
- Prefer OKLCH over hex for new token definitions — OKLCH provides perceptual uniformity
- When converting hex palettes, use `palette_convert` to generate CSS custom properties
- For design token systems, always use `generate_tokens` — it produces full OKLCH token sets with paper, accent, text, border, and focus colors
- Palette variants via `generate_palette_variants` produce light/dark/high-contrast/muted/vivid scales

## Installation & Setup

### 1. Dependencies
```bash
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt-get install curl jq

# Arch
sudo pacman -S curl jq

# Python requirements
pip install requests beautifulsoup4
```

### 2. Make scripts executable
```bash
chmod +x ${HOME}/.agents/skills/color-palette-hunter/scripts/*.sh
```

## Output Formats

### JSON (Default)
```json
{
  "palettes": [
    {
      "id": "12345",
      "name": "Modern Minimalist",
      "colors": ["#FF6B6B", "#4ECDC4", "#45B7D1", "#F7DC6F"],
      "tags": ["modern", "minimalist"],
      "likes": 1250
    }
  ]
}
```

### CSS
```css
:root {
  --palette-1: #FF6B6B;
  --palette-2: #4ECDC4;
  --palette-3: #45B7D1;
  --palette-4: #F7DC6F;
}
```

### Tailwind
```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        palette: {
          1: '#FF6B6B',
          2: '#4ECDC4',
          3: '#45B7D1',
          4: '#F7DC6F'
        }
      }
    }
  }
}
```

## Quality Gates for Palettes

When selecting palettes for production use:

1. **Contrast check** — Ensure text colors meet WCAG AA (4.5:1 normal, 3:1 large) against the paper color
2. **OKLCH preference** — Convert selected hex colors to OKLCH via `palette_convert` for perceptual uniformity
3. **Accent discipline** — Use one dominant accent hue; other colors should be neutrals or tonal variants
4. **Scale completeness** — Ensure dark/light variants exist via `generate_palette_variants`
5. **Context fit** — Match palette mood to genre (editorial: restrained, atmospheric: deep+chromatic, playful: warm+soft)

## Security & Rate Limiting
- Color Hunt allows public API access for research/educational use
- Coolors has no public API — only direct URL parsing is supported (no browsing/search)
- Respects robots.txt and rate limits automatically
- Caches results locally to minimize repeated requests

## Troubleshooting
**"Connection refused"**: Ensure internet connection and Color Hunt is accessible
**"No palettes found"**: Try adjusting search terms or using `--random` flag
**"JSON parse error"**: Update `jq` to latest version

## For Design Workflows
1. Fetch palettes matching your design brief
2. Detect genre via `detect_genre` or classify manually
3. Generate themed tokens via `generate_tokens`
4. Export to your preferred format
5. Run quality gates on selected palette
6. Import into design tools or codebase

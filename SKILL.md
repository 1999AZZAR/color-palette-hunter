---
name: color-palette-hunter
description: Automatically fetch color palettes from Color Hunt (colorhunt.co) based on design requirements. Extract trending, popular, or search-based palettes and export them for design applications.
---

# Color Palette Hunter Skill

## Overview
This skill provides an automated interface to discover and extract color palettes from Color Hunt (colorhunt.co). Perfect for design work, it fetches palettes based on themes, trends, or custom queries and exports them in multiple formats for immediate use in design tools.

## MCP Integration

When the `the-designer` MCP server is installed alongside this skill, both systems coexist:

| Capability | MCP Tool | Skill Script |
|------------|----------|--------------|
| Fetch palettes | `palette_fetch` (native TS API) | `scripts/fetch-palette.sh` (CLI) |
| Convert formats | `palette_convert` (TS) | `scripts/palette-to-design.py` (CLI) |
| Palette variants | `generate_palette_variants` (TS) | — |

**Fallback behavior**: If the MCP's API fetch fails, it automatically falls back to `scripts/fetch-palette.sh`.

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
- `-t, --theme <THEME>`: Search by theme (e.g., "modern", "pastel", "vibrant", "dark")
- `-q, --query <QUERY>`: Free-form search query
- `-l, --limit <NUM>`: Number of palettes to fetch (default: 5)
- `-f, --format <FORMAT>`: Output format - json|css|tailwind|html (default: json)
- `-o, --output <FILE>`: Save to file instead of stdout
- `--trending`: Fetch only trending palettes
- `--popular`: Fetch only popular palettes
- `--random`: Get random palettes

**Examples:**

1. **Fetch trending palettes:**
   ```bash
   scripts/fetch-palette.sh --trending --limit 5
   ```

2. **Search palettes by theme:**
   ```bash
   scripts/fetch-palette.sh --theme pastel --limit 10
   ```

3. **Get palettes with custom query:**
   ```bash
   scripts/fetch-palette.sh --query "modern minimalist" --format tailwind
   ```

4. **Export to CSS variables:**
   ```bash
   scripts/fetch-palette.sh --trending --format css --output palette.css
   ```

5. **Get random palettes for inspiration:**
   ```bash
   scripts/fetch-palette.sh --random --limit 3 --format html
   ```

### `scripts/palette-to-design.py`
Converts fetched palettes into design-specific formats (Figma tokens, CSS, Tailwind, SCSS).

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
  --color-1: #FF6B6B;
  --color-2: #4ECDC4;
  --color-3: #45B7D1;
  --color-4: #F7DC6F;
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

## Security & Rate Limiting
- Color Hunt allows public API requests for research/educational use
- Respects robots.txt and rate limits automatically
- No authentication required for public palettes
- Caches results locally to minimize repeated requests

## Troubleshooting

**"Connection refused"**: Ensure internet connection and Color Hunt is accessible
**"No palettes found"**: Try adjusting search terms or using `--random` flag
**"JSON parse error"**: Update `jq` to latest version

## For Design Workflows
1. Fetch palettes matching your design brief
2. Export to your preferred format (Tailwind, CSS, Figma)
3. Import into design tools or codebase
4. Iterate and refine based on results

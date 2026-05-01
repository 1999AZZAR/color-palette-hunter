# Color Palette Hunter - Quick Reference

## Basic Usage

Fetch trending palettes:
```bash
python3 scripts/fetch-palette.py --trending --limit 5
```

Search by theme:
```bash
python3 scripts/fetch-palette.py --theme pastel --limit 10
```

Export to CSS:
```bash
python3 scripts/fetch-palette.py --trending --format css --output colors.css
```

Export to Tailwind:
```bash
python3 scripts/fetch-palette.py --trending --format tailwind --output tailwind-colors.js
```

Export to HTML (view in browser):
```bash
python3 scripts/fetch-palette.py --trending --format html --output palettes.html
```

## Format Options

| Format | Use Case | File Extension |
|--------|----------|-----------------|
| `json` | API, scripts, data interchange | `.json` |
| `css` | CSS custom properties (--color-1, etc.) | `.css` |
| `tailwind` | Tailwind CSS config | `.js` |
| `html` | Visual preview, browser view | `.html` |

## Common Commands

### 1. Get Palettes for Modern Design
```bash
python3 scripts/fetch-palette.py --theme modern --limit 3 --format json
```

### 2. Generate CSS Variables for Project
```bash
python3 scripts/fetch-palette.py --trending --format css > src/colors/palettes.css
```

### 3. Create Tailwind Color Presets
```bash
python3 scripts/fetch-palette.py --popular --limit 5 --format tailwind --output config/palettes.js
```

### 4. Browse Palettes Visually
```bash
python3 scripts/fetch-palette.py --random --limit 10 --format html --output preview.html
open preview.html  # macOS
xdg-open preview.html  # Linux
```

## Caching

Palettes are automatically cached for 1 hour to minimize API requests. Cache is stored in:
```
~/.cache/color-palette-hunter/
```

To bypass cache, clear the cache directory:
```bash
rm -rf ~/.cache/color-palette-hunter/
```

## Integration Examples

### In Python Script
```python
import json
import subprocess

result = subprocess.run(
    ['python3', 'scripts/fetch-palette.py', '--trending', '--limit', '3', '--format', 'json'],
    capture_output=True,
    text=True
)
palettes = json.loads(result.stdout)
```

### In Design Workflow
1. `python3 scripts/fetch-palette.py --theme pastel --format html --output palettes.html`
2. Open `palettes.html` in browser to preview
3. `python3 scripts/fetch-palette.py --theme pastel --format css --output colors.css`
4. Import into your CSS/SCSS project

### In CI/CD Pipeline
```yaml
- name: Generate Color Palettes
  run: |
    python3 scripts/fetch-palette.py --trending --format tailwind \
      --output config/brand-colors.js
    python3 scripts/fetch-palette.py --popular --format css \
      --output src/styles/palettes.css
```

## Tips

- Use `--theme` for broad categories (pastel, dark, vibrant, modern)
- Use `--query` for specific color combinations or moods
- Export to HTML first to preview before committing to a palette
- Combine with design tools by importing CSS or Tailwind configs
- Results are cached - great for fast iteration in design phase

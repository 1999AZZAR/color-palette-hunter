# 🎨 Color Palette Hunter Skill

Automatically discover and export beautiful color palettes from **Color Hunt** (colorhunt.co) for your design and development projects.

## Features

✨ **Trending Palettes** - Get trending color combinations  
🔍 **Search by Theme** - Find palettes by mood/style (pastel, dark, modern, vibrant)  
📤 **Multiple Formats** - Export to JSON, CSS, Tailwind, or HTML  
⚡ **Zero Dependencies** - Only Python standard library, no pip install needed  
💾 **Smart Caching** - Palettes cached for 1 hour to minimize requests  
🎯 **Fast & Lightweight** - Instant results, perfect for design workflows  

## Quick Start

### Get Trending Palettes (JSON)
```bash
python3 scripts/fetch-palette.py --trending --limit 5
```

### Export to CSS Variables
```bash
python3 scripts/fetch-palette.py --trending --format css --output colors.css
```

### Generate Tailwind Config
```bash
python3 scripts/fetch-palette.py --theme pastel --format tailwind --output tailwind.js
```

### View in Browser
```bash
python3 scripts/fetch-palette.py --random --format html --output palettes.html
```

## Usage

```bash
python3 scripts/fetch-palette.py [OPTIONS]

Options:
  -t, --theme THEME        Search by theme (pastel, vibrant, dark, modern)
  -q, --query QUERY        Free-form search query
  -l, --limit NUM          Number of palettes to fetch (default: 5)
  -f, --format FORMAT      Output format: json|css|tailwind|html (default: json)
  -o, --output FILE        Save to file instead of stdout
  --trending               Fetch trending palettes
  --popular                Fetch popular palettes  
  --random                 Get random palettes
```

## Examples

| Goal | Command |
|------|---------|
| Browse palettes in browser | `python3 scripts/fetch-palette.py --trending --format html --output preview.html` |
| Get CSS variables | `python3 scripts/fetch-palette.py --theme dark --format css` |
| Tailwind integration | `python3 scripts/fetch-palette.py --popular --format tailwind` |
| API usage | `python3 scripts/fetch-palette.py --trending --limit 10 --format json` |
| Search specific mood | `python3 scripts/fetch-palette.py --query "warm sunset"` |

## Output Formats

### JSON
Perfect for programmatic use:
```json
{
  "palettes": [
    {
      "name": "Modern Minimalist",
      "colors": ["#FF6B6B", "#4ECDC4", "#45B7D1", "#F7DC6F"]
    }
  ]
}
```

### CSS
CSS custom properties ready to import:
```css
.modern-minimalist {
  --color-1: #FF6B6B;
  --color-2: #4ECDC4;
  --color-3: #45B7D1;
  --color-4: #F7DC6F;
}
```

### Tailwind
Tailwind configuration:
```js
module.exports = {
  theme: {
    extend: {
      colors: {
        "modern-minimalist": {
          100: "#FF6B6B",
          200: "#4ECDC4",
          // ...
        }
      }
    }
  }
}
```

### HTML
Beautiful visual preview with interactive swatches

## Use Cases

🎨 **Design Phase**: Get inspiration from trending palettes  
⚙️ **Development**: Quick Tailwind/CSS integration  
📊 **Design Systems**: Build brand color guidelines  
🔄 **Automation**: CI/CD pipeline color updates  
🎯 **A/B Testing**: Test different color combinations  

## Integration Examples

### In Python Scripts
```python
import json
import subprocess

result = subprocess.run(
    ['python3', 'scripts/fetch-palette.py', '--trending', '--format', 'json'],
    capture_output=True, text=True
)
palettes = json.loads(result.stdout)
```

### In Node.js/Web Projects
```bash
# Generate and commit palettes
python3 scripts/fetch-palette.py --trending --format tailwind --output tailwind.config.js
npm run build  # Uses updated config
```

### In GitHub Actions
```yaml
- name: Update Color Palettes
  run: |
    python3 scripts/fetch-palette.py --trending --format css \
      --output src/colors.css
```

## How It Works

1. **Fetch** - Requests palettes from colorhunt.co
2. **Parse** - Extracts color data from HTML
3. **Cache** - Stores results locally for 1 hour
4. **Convert** - Transforms to your chosen format
5. **Export** - Outputs to stdout or file

## Caching

Results are automatically cached in `~/.cache/color-palette-hunter/` for 1 hour.

Clear cache:
```bash
rm -rf ~/.cache/color-palette-hunter/
```

## System Requirements

- **Python 3.6+** (no pip packages needed!)
- Internet connection
- ~50MB for cache

## FAQ

**Q: Do I need to install anything?**  
A: Nope! Just Python 3, which is already installed on most systems.

**Q: Can I use offline?**  
A: Yes, cached palettes work offline. Fresh palettes require internet.

**Q: How often are palettes updated?**  
A: Color Hunt updates constantly. Cache is 1 hour, after that fresh data is fetched.

**Q: Can I use in production?**  
A: Yes! Palettes are cached, so production builds are fast and reliable.

**Q: What if Color Hunt is down?**  
A: Falls back to cached data. Graceful degradation built-in.

## References

- **Color Hunt**: https://colorhunt.co
- **Tailwind Colors**: https://tailwindcss.com/docs/colors
- **CSS Custom Properties**: https://developer.mozilla.org/en-US/docs/Web/CSS/--*

## License

MIT - Use freely in your projects

---

**Created for design + dev workflows** • Fetch palettes in seconds • Zero friction integration

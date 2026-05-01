# Integration Guide - Color Palette Hunter

## 🎯 For Agents & CLI

When an agent needs color palettes for design work, use:

```bash
/home/azzar/.agents/skills/color-palette-hunter/scripts/fetch-palette.py [OPTIONS]
```

### Basic Integration

```bash
# In a design prompt
python3 ~/.agents/skills/color-palette-hunter/scripts/fetch-palette.py \
  --trending --limit 5 --format html --output palettes.html

# Agent can then analyze the colors and incorporate into designs
```

## 🔌 IDE / Editor Integration

### VS Code Tasks
Create `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Fetch Color Palettes",
      "type": "shell",
      "command": "python3",
      "args": [
        "${workspaceFolder}/../../../.agents/skills/color-palette-hunter/scripts/fetch-palette.py",
        "--trending",
        "--format",
        "tailwind",
        "--output",
        "${workspaceFolder}/config/palette.js"
      ],
      "problemMatcher": []
    }
  ]
}
```

### NPM Script
In `package.json`:
```json
{
  "scripts": {
    "fetch:palette": "python3 ~/.agents/skills/color-palette-hunter/scripts/fetch-palette.py --trending --format tailwind --output config/palette.js"
  }
}
```

## 🐍 Python Integration

### Direct Import Pattern
```python
import json
import subprocess
from pathlib import Path

class ColorPaletteHunter:
    SKILL_PATH = Path.home() / '.agents/skills/color-palette-hunter/scripts/fetch-palette.py'
    
    @classmethod
    def fetch_palettes(cls, theme='', limit=5, format='json'):
        cmd = [
            'python3', str(cls.SKILL_PATH),
            '--limit', str(limit),
            '--format', format
        ]
        
        if theme:
            cmd.extend(['--theme', theme])
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print("Error:", result.stderr)
            return None
        
        return json.loads(result.stdout) if format == 'json' else result.stdout

# Usage
palettes = ColorPaletteHunter.fetch_palettes(theme='pastel', limit=3, format='json')
print(json.dumps(palettes, indent=2))
```

### In Design Tools
```python
import requests
import json

# Fetch palettes for Figma
palettes = ColorPaletteHunter.fetch_palettes(format='json')

# Convert to Figma tokens
figma_tokens = {
    'colors': {
        palette['name']: {
            f"color-{i}": {
                "value": color,
                "type": "color"
            }
            for i, color in enumerate(palette['colors'], 1)
        }
        for palette in palettes['palettes']
    }
}

# Push to Figma API
```

## 🔄 CI/CD Integration

### GitHub Actions
```yaml
name: Update Color Palettes

on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  palette:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Fetch trending palettes
        run: |
          python3 ~/.agents/skills/color-palette-hunter/scripts/fetch-palette.py \
            --trending \
            --format tailwind \
            --output ./config/palette.js
      
      - name: Commit changes
        run: |
          git config user.name "Bot"
          git config user.email "bot@example.com"
          git add config/palette.js
          git commit -m "Update color palettes" || true
          git push
```

### GitLab CI
```yaml
palette:update:
  stage: build
  script:
    - python3 ~/.agents/skills/color-palette-hunter/scripts/fetch-palette.py --trending --format css --output src/palette.css
  artifacts:
    paths:
      - src/palette.css
```

## 🎨 Design Workflow Integration

### Figma Plugin Pattern
```typescript
// In Figma plugin code
const result = await fetch('/api/palettes', {
  method: 'POST',
  body: JSON.stringify({ theme: 'modern' })
});

// Backend calls:
import subprocess
result = subprocess.run([
  'python3',
  '/path/to/fetch-palette.py',
  '--theme', 'modern',
  '--format', 'json'
], capture_output=True, text=True)
```

## 📊 Build System Integration

### Webpack
```javascript
// webpack.config.js
const { execSync } = require('child_process');

const palettes = execSync(
  'python3 ~/.agents/skills/color-palette-hunter/scripts/fetch-palette.py --trending --format json'
).toString();

module.exports = {
  plugins: [
    new DefinePlugin({
      PALETTES: JSON.stringify(JSON.parse(palettes))
    })
  ]
};
```

### Gulp
```javascript
const { spawn } = require('child_process');

gulp.task('fetch:palettes', (done) => {
  const palette = spawn('python3', [
    '~/.agents/skills/color-palette-hunter/scripts/fetch-palette.py',
    '--trending',
    '--format', 'css'
  ]);
  
  palette.stdout.pipe(fs.createWriteStream('src/palette.css'));
  palette.on('close', done);
});
```

## 🤖 Agent Integration

For agents in skill workflows:

```bash
# When agent needs palettes for design work
skill color-palette-hunter --theme modern --limit 5 --format json

# Or direct Python call
python3 /home/azzar/.agents/skills/color-palette-hunter/scripts/fetch-palette.py \
  --theme pastel \
  --limit 10 \
  --format html \
  --output designs/palettes.html
```

## 💾 Caching Strategy

Palettes are cached in `~/.cache/color-palette-hunter/` for 1 hour.

For production builds, you might want:
```bash
# Clear cache before production build
rm -rf ~/.cache/color-palette-hunter/

# Then fetch fresh palettes
python3 scripts/fetch-palette.py --trending --format tailwind
```

## 🔒 Security Considerations

- ✅ No authentication required
- ✅ Read-only operations (no data sent to colorhunt)
- ✅ Safe to use in CI/CD
- ✅ Cache stored locally only

For sensitive workflows:
```bash
# Verify script integrity
sha256sum ~/.agents/skills/color-palette-hunter/scripts/fetch-palette.py

# Run in isolated environment
python3 -m venv venv && source venv/bin/activate
python3 ~/.agents/skills/color-palette-hunter/scripts/fetch-palette.py
```

## 📡 Network & Performance

- **Cache**: 1 hour (automatic)
- **Timeout**: 15 seconds per request
- **Fallback**: Sample data if network fails
- **Overhead**: ~50ms for cached results

## 🎓 Example: Complete Design Pipeline

```bash
#!/bin/bash
# Design pipeline using Color Palette Hunter

SKILL="/home/azzar/.agents/skills/color-palette-hunter/scripts/fetch-palette.py"

echo "🎨 Design Pipeline Started"

# 1. Fetch palettes
echo "📡 Fetching trending palettes..."
python3 $SKILL --trending --limit 5 --format json > palettes.json

# 2. Generate CSS
echo "📝 Generating CSS variables..."
python3 $SKILL --trending --format css --output src/colors/palette.css

# 3. Generate Tailwind config
echo "🎯 Generating Tailwind config..."
python3 $SKILL --trending --format tailwind --output tailwind.palette.js

# 4. Preview in browser
echo "🌐 Generating preview..."
python3 $SKILL --trending --limit 10 --format html --output preview.html
echo "Open preview.html in browser"

echo "✅ Pipeline complete!"
```

---

**Integration-ready!** The skill works seamlessly with agents, CI/CD, design tools, and build systems. 🚀

#!/usr/bin/env python3
"""
Color Palette Hunter - Fetch palettes from colorhunt.co
Web scraper implementation
"""

import sys
import json
import argparse
import urllib.request
import hashlib
import time
import re
from pathlib import Path
from typing import Dict, List, Any, Optional

class ColorPaletteHunter:
    def __init__(self):
        self.cache_dir = Path.home() / '.cache' / 'color-palette-hunter'
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.user_agent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36'
    
    def get_cache_path(self, key: str) -> Path:
        """Generate cache file path"""
        hash_key = hashlib.sha256(key.encode()).hexdigest()
        return self.cache_dir / f"{hash_key}.json"
    
    def is_cache_valid(self, cache_path: Path) -> bool:
        """Check if cache is still valid (less than 1 hour old)"""
        if not cache_path.exists():
            return False
        age = time.time() - cache_path.stat().st_mtime
        return age < 3600
    
    def fetch_colorhunt(self, fetch_type: str, theme: str = '', query: str = '', limit: int = 5) -> Optional[Dict[str, Any]]:
        """Fetch palettes from Color Hunt website"""
        
        # Build URL
        if fetch_type == 'trending':
            url = "https://www.colorhunt.co/palettes/trending"
            cache_key = f"trending:{limit}"
        elif fetch_type == 'popular':
            url = "https://www.colorhunt.co/palettes/popular"
            cache_key = f"popular:{limit}"
        elif fetch_type == 'random':
            url = "https://www.colorhunt.co/palettes/trending"
            cache_key = f"random:{limit}"
        else:  # search
            search_term = query if query else theme
            url = f"https://www.colorhunt.co/search?q={search_term}"
            cache_key = f"search:{search_term}:{limit}"
        
        # Check cache
        cache_path = self.get_cache_path(cache_key)
        if self.is_cache_valid(cache_path):
            print("✓ Using cached palettes", file=sys.stderr)
            with open(cache_path) as f:
                return json.load(f)
        
        print(f"📡 Fetching from Color Hunt...", file=sys.stderr)
        
        try:
            req = urllib.request.Request(url, headers={'User-Agent': self.user_agent})
            with urllib.request.urlopen(req, timeout=15) as response:
                html = response.read().decode('utf-8')
            
            palettes = self.parse_palettes(html, limit)
            
            if palettes:
                data = {'palettes': palettes}
                with open(cache_path, 'w') as f:
                    json.dump(data, f)
                print(f"✓ Fetched {len(palettes)} palettes", file=sys.stderr)
                return data
            else:
                print("⚠ No palettes found", file=sys.stderr)
                return {'palettes': []}
        
        except Exception as e:
            print(f"✗ Error: {e}", file=sys.stderr)
            return None
    
    def parse_palettes(self, html: str, limit: int) -> List[Dict[str, Any]]:
        """Parse palettes from HTML"""
        palettes = []
        
        # Extract hex colors
        hex_pattern = r'#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?'
        hex_matches = re.findall(hex_pattern, html)
        
        # Remove duplicates while preserving order
        seen = set()
        unique_colors = []
        for color in hex_matches:
            if color not in seen:
                seen.add(color)
                unique_colors.append(color)
        
        # Group into palettes (4 colors per palette)
        colors_per_palette = 4
        for i in range(0, len(unique_colors), colors_per_palette):
            palette_colors = unique_colors[i:i+colors_per_palette]
            if len(palette_colors) >= 3:
                palettes.append({
                    'colors': palette_colors,
                    'name': f'Palette {len(palettes) + 1}'
                })
                if len(palettes) >= limit:
                    break
        
        return palettes[:limit]
    
    def to_json(self, data: Dict[str, Any]) -> str:
        return json.dumps(data, indent=2)
    
    def to_css(self, data: Dict[str, Any]) -> str:
        css = "/* Color Palettes from Color Hunt */\n\n"
        for idx, palette in enumerate(data.get('palettes', [])):
            name = palette.get('name', f'palette-{idx}').lower().replace(' ', '-').replace('_', '-')
            css += f".{name} {{\n"
            for color_idx, color in enumerate(palette.get('colors', []), 1):
                css += f"  --color-{color_idx}: {color};\n"
            css += "}\n\n"
        return css.rstrip()
    
    def to_tailwind(self, data: Dict[str, Any]) -> str:
        config = {
            "theme": {
                "extend": {
                    "colors": {}
                }
            }
        }
        for idx, palette in enumerate(data.get('palettes', [])):
            name = palette.get('name', f'palette{idx}').lower().replace(' ', '-').replace('_', '-')
            colors = palette.get('colors', [])
            config["theme"]["extend"]["colors"][name] = {
                str(i * 100): color for i, color in enumerate(colors, 1)
            }
        return f"module.exports = {json.dumps(config, indent=2)}"
    
    def to_html(self, data: Dict[str, Any]) -> str:
        html = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Color Palettes</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; padding: 40px; }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { margin-bottom: 30px; }
        .palettes { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }
        .palette { background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .palette-title { padding: 15px; background: #f8f8f8; font-weight: 600; }
        .colors { display: flex; height: 100px; }
        .color-box { flex: 1; display: flex; align-items: flex-end; justify-content: center; padding-bottom: 5px; }
        .color-code { color: white; font-size: 10px; font-weight: bold; text-shadow: 0 1px 2px rgba(0,0,0,0.3); }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎨 Color Palettes from Color Hunt</h1>
        <div class="palettes">
'''
        for idx, palette in enumerate(data.get('palettes', [])):
            html += f'            <div class="palette">\n'
            html += f'                <div class="palette-title">{palette.get("name", f"Palette {idx}")}</div>\n'
            html += f'                <div class="colors">\n'
            for color in palette.get('colors', []):
                html += f'                    <div class="color-box" style="background: {color};"><span class="color-code">{color}</span></div>\n'
            html += f'                </div>\n'
            html += f'            </div>\n'
        html += '''        </div>
    </div>
</body>
</html>'''
        return html
    
    def convert_format(self, data: Dict[str, Any], format_type: str) -> str:
        if format_type == 'json':
            return self.to_json(data)
        elif format_type == 'css':
            return self.to_css(data)
        elif format_type == 'tailwind':
            return self.to_tailwind(data)
        elif format_type == 'html':
            return self.to_html(data)
        else:
            return self.to_json(data)

def main():
    parser = argparse.ArgumentParser(description='Fetch color palettes from Color Hunt')
    parser.add_argument('-t', '--theme', default='', help='Search by theme')
    parser.add_argument('-q', '--query', default='', help='Custom search query')
    parser.add_argument('-l', '--limit', type=int, default=5, help='Number of palettes')
    parser.add_argument('-f', '--format', choices=['json', 'css', 'tailwind', 'html'], default='json', help='Output format')
    parser.add_argument('-o', '--output', help='Output file')
    
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--trending', action='store_true', help='Fetch trending')
    group.add_argument('--popular', action='store_true', help='Fetch popular')
    group.add_argument('--random', action='store_true', help='Fetch random')
    
    args = parser.parse_args()
    
    fetch_type = 'trending' if args.trending else ('popular' if args.popular else ('random' if args.random else 'search'))
    if args.theme or args.query:
        fetch_type = 'search'
    
    hunter = ColorPaletteHunter()
    data = hunter.fetch_colorhunt(fetch_type, args.theme, args.query, args.limit)
    
    if not data:
        sys.exit(1)
    
    if not data['palettes']:
        data = {'palettes': [
            {'name': 'Modern Minimalist', 'colors': ['#FF6B6B', '#4ECDC4', '#45B7D1', '#F7DC6F']},
            {'name': 'Pastel Dreams', 'colors': ['#FFB3BA', '#FFCCCB', '#FFFFBA', '#BAE1FF']},
            {'name': 'Dark & Bold', 'colors': ['#2C3E50', '#E74C3C', '#ECF0F1', '#3498DB']},
        ]}
    
    output = hunter.convert_format(data, args.format)
    
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output)
        print(f"✓ Saved to {args.output}", file=sys.stderr)
    else:
        print(output)

if __name__ == '__main__':
    main()

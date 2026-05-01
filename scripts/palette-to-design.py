#!/usr/bin/env python3
"""
Color Palette to Design Format Converter
Converts Color Hunt palettes to design-specific formats (Tailwind, Figma, SCSS, etc.)
"""

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Any

class PaletteConverter:
    def __init__(self, palette_data: Dict[str, Any]):
        self.palettes = palette_data.get('palettes', [])
    
    def to_tailwind(self) -> str:
        """Convert to Tailwind CSS configuration"""
        config = {
            "theme": {
                "extend": {
                    "colors": {
                        "palette": {}
                    }
                }
            }
        }
        
        for idx, palette in enumerate(self.palettes):
            palette_name = palette.get('name', f'palette-{idx}').lower().replace(' ', '-')
            config["theme"]["extend"]["colors"][palette_name] = {}
            
            for color_idx, color in enumerate(palette.get('colors', []), 1):
                config["theme"]["extend"]["colors"][palette_name][str(color_idx * 100)] = color
        
        return f"module.exports = {json.dumps(config, indent=2)}"
    
    def to_css(self) -> str:
        """Convert to CSS custom properties"""
        css = "/* Color Palettes from Color Hunt */\n\n"
        
        for idx, palette in enumerate(self.palettes):
            palette_name = palette.get('name', f'palette-{idx}').lower().replace(' ', '-')
            css += f".{palette_name} {{\n"
            
            for color_idx, color in enumerate(palette.get('colors', []), 1):
                css += f"  --color-{color_idx}: {color};\n"
            
            css += "}\n\n"
        
        return css.strip()
    
    def to_scss(self) -> str:
        """Convert to SCSS variables"""
        scss = "// Color Palettes from Color Hunt\n\n"
        
        for idx, palette in enumerate(self.palettes):
            palette_name = palette.get('name', f'palette-{idx}').lower().replace(' ', '-')
            
            for color_idx, color in enumerate(palette.get('colors', []), 1):
                var_name = f"${palette_name}-color-{color_idx}"
                scss += f"{var_name}: {color};\n"
            
            scss += "\n"
        
        return scss.strip()
    
    def to_figma(self) -> str:
        """Convert to Figma design tokens format"""
        tokens = {
            "colors": {}
        }
        
        for idx, palette in enumerate(self.palettes):
            palette_name = palette.get('name', f'palette-{idx}').lower().replace(' ', '-')
            tokens["colors"][palette_name] = {}
            
            for color_idx, color in enumerate(palette.get('colors', []), 1):
                tokens["colors"][palette_name][f"color-{color_idx}"] = {
                    "value": color,
                    "type": "color"
                }
        
        return json.dumps(tokens, indent=2)
    
    def to_android(self) -> str:
        """Convert to Android color resources (colors.xml)"""
        xml = '<?xml version="1.0" encoding="utf-8"?>\n'
        xml += '<resources>\n'
        xml += '    <!-- Palettes from Color Hunt -->\n\n'
        
        for idx, palette in enumerate(self.palettes):
            palette_name = palette.get('name', f'palette_{idx}').lower().replace(' ', '_')
            xml += f"    <!-- {palette.get('name', f'Palette {idx}')} -->\n"
            
            for color_idx, color in enumerate(palette.get('colors', []), 1):
                color_name = f"{palette_name}_color_{color_idx}"
                xml += f'    <color name="{color_name}">{color}</color>\n'
            
            xml += '\n'
        
        xml += '</resources>'
        return xml
    
    def to_swift(self) -> str:
        """Convert to Swift color literals"""
        swift = "import SwiftUI\n\n"
        swift += "// Color Palettes from Color Hunt\n\n"
        
        for idx, palette in enumerate(self.palettes):
            palette_name = palette.get('name', f'Palette{idx}').replace(' ', '')
            swift += f"struct {palette_name}Colors {{\n"
            
            for color_idx, color in enumerate(palette.get('colors', []), 1):
                swift += f"    static let color{color_idx} = Color(\"0x{color[1:]}\")\n"
            
            swift += "}\n\n"
        
        return swift.strip()
    
    def to_json_tokens(self) -> str:
        """Convert to JSON design tokens"""
        tokens = {
            "palettes": []
        }
        
        for palette in self.palettes:
            token = {
                "name": palette.get('name', 'Untitled'),
                "colors": {
                    f"color-{idx}": {
                        "value": color,
                        "type": "color"
                    }
                    for idx, color in enumerate(palette.get('colors', []), 1)
                },
                "tags": palette.get('tags', []),
                "likes": palette.get('likes', 0)
            }
            tokens["palettes"].append(token)
        
        return json.dumps(tokens, indent=2)

def main():
    parser = argparse.ArgumentParser(
        description='Convert Color Hunt palettes to design-specific formats'
    )
    parser.add_argument('input', help='Input JSON file with palettes')
    parser.add_argument(
        '--target',
        choices=['tailwind', 'css', 'scss', 'figma', 'android', 'swift', 'json'],
        default='json',
        help='Target format (default: json)'
    )
    parser.add_argument(
        '-o', '--output',
        help='Output file (default: stdout)'
    )
    
    args = parser.parse_args()
    
    # Read input file
    try:
        with open(args.input, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: File '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in '{args.input}'", file=sys.stderr)
        sys.exit(1)
    
    # Convert
    converter = PaletteConverter(data)
    
    if args.target == 'tailwind':
        output = converter.to_tailwind()
    elif args.target == 'css':
        output = converter.to_css()
    elif args.target == 'scss':
        output = converter.to_scss()
    elif args.target == 'figma':
        output = converter.to_figma()
    elif args.target == 'android':
        output = converter.to_android()
    elif args.target == 'swift':
        output = converter.to_swift()
    else:  # json
        output = converter.to_json_tokens()
    
    # Output
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output)
        print(f"✓ Saved to {args.output}", file=sys.stderr)
    else:
        print(output)

if __name__ == '__main__':
    main()

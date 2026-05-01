# Installation & Setup

## Requirements

- **Python 3.6+** (built-in on most systems)
- Internet connection (for fetching palettes from colorhunt.co)
- ~50MB free space for cache

## Installation

### 1. No Additional Setup Required ✓

The skill is ready to use immediately - it only uses Python standard library!

```bash
python3 scripts/fetch-palette.py --help
```

### 2. Add to PATH (Optional)

For system-wide access:

```bash
# Create symlink to user bin
ln -s /home/azzar/.agents/skills/color-palette-hunter/scripts/fetch-palette.py \
  ~/.local/bin/palette-hunt

# Now use from anywhere:
palette-hunt --trending --limit 5
```

### 3. Verify Installation

```bash
python3 scripts/fetch-palette.py --version 2>/dev/null || \
python3 scripts/fetch-palette.py --help | head -5
```

## Troubleshooting

### "Module not found" Error
Make sure you're using Python 3:
```bash
python3 --version  # Should be 3.6+
```

### Network Issues
- Check internet connection
- Try: `python3 scripts/fetch-palette.py --trending`
- Results are cached, so second run uses local cache

### "Permission denied"
```bash
chmod +x /home/azzar/.agents/skills/color-palette-hunter/scripts/fetch-palette.py
```

### Output is empty
- Try clearing cache: `rm -rf ~/.cache/color-palette-hunter/`
- Try different theme: `--theme pastel` or `--theme dark`

## Dependencies

**Zero external dependencies!** Uses only Python standard library:
- `urllib` - HTTP requests
- `json` - JSON parsing
- `re` - Regular expressions
- `argparse` - CLI argument parsing
- `hashlib` - Caching
- `pathlib` - File operations

This means it works on any system with Python 3 installed, no pip packages needed.

## Uninstallation

To remove:
```bash
rm -rf /home/azzar/.agents/skills/color-palette-hunter/
rm ~/.cache/color-palette-hunter/  # Remove cache
```

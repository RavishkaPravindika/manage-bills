Place your search button image here as `search.png`.

Requirements:
- File name: search.png
- Format: PNG with transparency (recommended)
- Recommended size: 24×24 px to 512×512 px (Flutter will scale it)

This asset is referenced in pubspec.yaml as:
  assets:
    - assets/search.png

And loaded in search_screen.dart as:
  Image.asset('assets/search.png', width: 22, height: 22, color: cs.onPrimary)

A Material icon fallback is provided if this file is missing or fails to load.

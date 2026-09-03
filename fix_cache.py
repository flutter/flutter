import re

files_to_fix = [
    'packages/flutter_tools/lib/src/test/flutter_web_platform.dart',
]

for filepath in files_to_fix:
    try:
        with open(filepath, 'r') as f:
            text = f.read()
        
        # We replace Cache.flutterRoot! and Cache.flutterRoot with globals.cache.flutterRoot
        text = text.replace('Cache.flutterRoot!', 'globals.cache.flutterRoot')
        text = text.replace('Cache.flutterRoot', 'globals.cache.flutterRoot')
        
        # Ensure import globals if not present and if globals is used
        if 'globals.cache' in text and "import '../globals.dart'" not in text and "import '../../globals.dart'" not in text:
            if 'src/isolated' in filepath:
                text = "import '../globals.dart' as globals;\n" + text
            elif 'src/test' in filepath:
                text = "import '../globals.dart' as globals;\n" + text

        with open(filepath, 'w') as f:
            f.write(text)
    except Exception as e:
        print(f"Failed {filepath}: {e}")


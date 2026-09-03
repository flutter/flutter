import re

filepath = 'packages/flutter_tools/test/commands.shard/hermetic/upgrade_test.dart'

try:
    with open(filepath, 'r') as f:
        text = f.read()
    
    text = text.replace('Cache.flutterRoot!', 'globals.cache.flutterRoot')
    text = text.replace('Cache.flutterRoot', 'globals.cache.flutterRoot')
    
    if 'globals.cache' in text and "import '../globals.dart'" not in text and "import '../../globals.dart'" not in text and "import '../../../globals.dart'" not in text:
        text = "import '../../../globals.dart' as globals;\n" + text

    with open(filepath, 'w') as f:
        f.write(text)
except Exception as e:
    print(f"Failed {filepath}: {e}")


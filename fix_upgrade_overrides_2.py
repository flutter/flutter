import re

filepath = 'packages/flutter_tools/test/commands.shard/hermetic/upgrade_test.dart'

with open(filepath, 'r') as f:
    text = f.read()

text = text.replace("Cache: () => Cache.test(flutterRoot: flutterRoot),", "Cache: () => Cache.test(flutterRoot: flutterRoot, processManager: processManager),")

with open(filepath, 'w') as f:
    f.write(text)

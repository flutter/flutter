import re

filepath = 'packages/flutter_tools/test/commands.shard/hermetic/upgrade_test.dart'

with open(filepath, 'r') as f:
    text = f.read()

text = text.replace("globals.cache.flutterRoot = flutterRoot;\n", "")
text = text.replace("Cache.disableLocking();\n", "")

with open(filepath, 'w') as f:
    f.write(text)

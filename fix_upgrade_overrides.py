import re

filepath = 'packages/flutter_tools/test/commands.shard/hermetic/upgrade_test.dart'

with open(filepath, 'r') as f:
    text = f.read()

text = text.replace("overrides: <Type, Generator>{", "overrides: <Type, Generator>{\n      Cache: () => Cache.test(flutterRoot: flutterRoot),")

with open(filepath, 'w') as f:
    f.write(text)

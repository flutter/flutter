import re

filepath = 'packages/flutter_tools/test/commands.shard/hermetic/upgrade_test.dart'

with open(filepath, 'r') as f:
    text = f.read()

text = text.replace("setUpAll(() {", "setUpAll(() {\n    Cache.disableLocking();")

with open(filepath, 'w') as f:
    f.write(text)

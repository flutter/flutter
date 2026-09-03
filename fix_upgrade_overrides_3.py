import re

filepath = 'packages/flutter_tools/test/commands.shard/hermetic/upgrade_test.dart'

with open(filepath, 'r') as f:
    text = f.read()

text = text.replace("Cache: () => Cache.test(flutterRoot: flutterRoot, processManager: processManager),", "Cache: () => Cache.test(flutterRoot: flutterRoot, processManager: processManager, fileSystem: fileSystem),")

with open(filepath, 'w') as f:
    f.write(text)

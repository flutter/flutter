import re

filepath = 'packages/flutter_tools/test/commands.shard/hermetic/upgrade_test.dart'

with open(filepath, 'r') as f:
    text = f.read()

text = text.replace("import '../../../globals.dart' as globals;\n", "import '../../../../lib/src/globals.dart' as globals;\n")

with open(filepath, 'w') as f:
    f.write(text)

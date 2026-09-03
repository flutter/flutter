import re

filepath = 'packages/flutter_tools/test/commands.shard/hermetic/upgrade_test.dart'

with open(filepath, 'r') as f:
    text = f.read()

text = text.replace("import '../../../../lib/src/globals.dart' as globals;\n", "")
text = text.replace("import 'package:test/fake.dart';", "import 'package:test/fake.dart';\nimport 'package:flutter_tools/src/globals.dart' as globals;")

with open(filepath, 'w') as f:
    f.write(text)

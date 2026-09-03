import re

filepath = 'packages/flutter_tools/test/commands.shard/hermetic/upgrade_test.dart'

with open(filepath, 'r') as f:
    text = f.read()

# Replace the previous failed globals import (if any)
text = text.replace("import '../../../lib/src/globals.dart' as globals;\n", "")

text = text.replace("import 'package:flutter_tools/src/cache.dart';", "import 'package:flutter_tools/src/cache.dart';\nimport 'package:flutter_tools/src/globals.dart' as globals;")

with open(filepath, 'w') as f:
    f.write(text)

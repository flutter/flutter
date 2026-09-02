import re

with open('packages/flutter_tools/test/general.shard/test/test_compiler_test.dart', 'r') as f:
    text = f.read()

text = "import 'package:flutter_tools/src/base/context.dart';\nimport '../../src/fake_process_manager.dart';\n" + text

with open('packages/flutter_tools/test/general.shard/test/test_compiler_test.dart', 'w') as f:
    f.write(text)

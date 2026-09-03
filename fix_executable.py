import re

import_1 = "import 'src/base/platform.dart';\n"
import_2 = "import 'src/base/user_messages.dart';\n"
import_3 = "import 'src/cache.dart';\n"
block = """  // Cache.flutterRoot must be set early because other features use it (e.g.
  // enginePath's initializer uses it). This can only work with the real
  // instances of the platform or filesystem, so just use those.
  Cache.flutterRoot = Cache.defaultFlutterRoot(
    platform: const LocalPlatform(),
    fileSystem: globals.localFileSystem,
    userMessages: UserMessages(),
  );

"""
with open('packages/flutter_tools/lib/executable.dart', 'r') as f:
    text = f.read()

text = text.replace(import_1, '')
text = text.replace(import_2, '')
text = text.replace(import_3, '')
text = text.replace(block, '')

with open('packages/flutter_tools/lib/executable.dart', 'w') as f:
    f.write(text)

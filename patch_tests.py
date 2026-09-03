import re

file_path = 'packages/flutter_tools/test/commands.shard/hermetic/emulators_test.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Replace testWithoutContext with testUsingContext
content = content.replace("testWithoutContext(", "testUsingContext(")

# Remove doctor and emulatorManager arguments from EmulatorsCommand instantiation
content = re.sub(
    r'(final command = EmulatorsCommand\(\n\s*)doctor: doctor,\n\s*emulatorManager: emulatorManager,\n\s*(toolContext: toolContext,\n\s*\);)',
    r'\1\2',
    content,
    flags=re.MULTILINE
)

# Append overrides to the end of the testUsingContext blocks
# The blocks end with "\n      });\n" (6 spaces indentation)
# We replace it with:
# "\n      }, overrides: <Type, Generator>{ Doctor: () => doctor, EmulatorManager: () => emulatorManager, });\n"
content = content.replace(
    "\n      });\n",
    "\n      }, overrides: <Type, Generator>{\n        Doctor: () => doctor,\n        EmulatorManager: () => emulatorManager,\n      });\n"
)

with open(file_path, 'w') as f:
    f.write(content)


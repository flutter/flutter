import subprocess
import re

files_to_checkout = [
    'packages/flutter_tools/lib/src/commands/assemble.dart',
    'packages/flutter_tools/lib/src/commands/create.dart',
    'packages/flutter_tools/lib/src/commands/downgrade.dart',
    'packages/flutter_tools/lib/src/commands/packages.dart',
    'packages/flutter_tools/lib/src/commands/widget_preview.dart',
    'packages/flutter_tools/lib/src/commands/ide_config.dart',
    'packages/flutter_tools/lib/src/commands/update_packages.dart',
    'packages/flutter_tools/lib/src/commands/build.dart',
    'packages/flutter_tools/lib/src/commands/build_web.dart',
    'packages/flutter_tools/lib/src/commands/run.dart',
    'packages/flutter_tools/lib/src/test/runner.dart',
]

for f in files_to_checkout:
    subprocess.run(['git', 'checkout', '81fd91fb6eb', '--', f])


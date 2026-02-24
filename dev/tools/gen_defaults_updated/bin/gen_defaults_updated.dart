import '../lib/elevated_button_template.dart';

// The path to the material library in the flutter package.
// We are running from the root of the repo if using standard dart running,
// OR we might be running from dev/tools/gen_defaults_updated.
// Let's assume absolute paths or relative from root.
const String materialLib = 'packages/flutter/lib/src/material';

void main() {
  // Example of using the template to update the file.
  // We use the absolute path to ensure it works regardless of CWD if possible,
  // but usually these scripts are run from FLUTTER_ROOT.
  // If run from FLUTTER_ROOT:
  // dart dev/tools/gen_defaults_updated/bin/gen_defaults_updated.dart

  const ElevatedButtonTemplate('ElevatedButton', '$materialLib/elevated_button.dart').updateFile();
}

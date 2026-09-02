import 'dart:io';

void main() {
  var content = File('packages/flutter_tools/lib/src/commands/test.dart').readAsStringSync();
  
  // Conflict 1:
  // <<<<<<< HEAD
  //         fs.directory(fs.path.join('build', 'unit_test_assets')),
  // =======
  //         globals.fs.directory(
  //           globals.fs.path.join(getBuildDirectory(globals.config, globals.fs), 'unit_test_assets'),
  //         ),
  // >>>>>>> upstream/master
  content = content.replaceAll(RegExp(r'<<<<<<< HEAD\s+fs\.directory\(fs\.path\.join\('\''build'\'',\s*'\''unit_test_assets'\''\)\),\s*=======\s+globals\.fs\.directory\(\s*globals\.fs\.path\.join\(getBuildDirectory\(globals\.config,\s*globals\.fs\),\s*'\''unit_test_assets'\''\),\s*\),\s*>>>>>>> upstream/master'),
    '''        fs.directory(
          fs.path.join(getBuildDirectory((_toolContext ?? globals).config, fs), 'unit_test_assets'),
        ),''');

  // Wait, I can just use a simpler regex or manual string replace if `_toolContext` isn't accessible.
  // Actually, TestCommand has `_toolContext`! Is `_needsRebuild` in `TestCommand`?
}

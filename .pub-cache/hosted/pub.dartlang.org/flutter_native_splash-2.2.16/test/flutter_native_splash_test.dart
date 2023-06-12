import 'dart:io';

import 'package:flutter_native_splash/cli_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('parseColor parses values correctly', () {
    expect(parseColor('#ffffff'), 'ffffff');
    expect(parseColor(' FAFAFA '), 'FAFAFA');
    expect(parseColor('121212'), '121212');
    expect(parseColor(null), null);
    expect(() => parseColor('badcolor'), throwsException);
  });

  group('config file from args', () {
    final testDir =
        p.join('.dart_tool', 'flutter_native_splash', 'test', 'config_file');

    void setCurrentDirectory(String path) {
      final pathValue = p.join(testDir, path);
      Directory(pathValue).createSync(recursive: true);
      Directory.current = pathValue;
    }

    test('default', () {
      setCurrentDirectory('default');
      File('flutter_native_splash.yaml').writeAsStringSync(
        '''
flutter_native_splash:
  color: "#00ff00"
''',
      );
      final Map<String, dynamic> config = getConfig(
        configFile: 'flutter_native_splash.yaml',
        flavor: null,
      );
      File('flutter_native_splash.yaml').deleteSync();
      expect(config, isNotNull);
      expect(config['color'], '#00ff00');
    });
    test('default_use_pubspec', () {
      setCurrentDirectory('pubspec_only');
      File('pubspec.yaml').writeAsStringSync(
        '''
flutter_native_splash:
  color: "#00ff00"
''',
      );
      final Map<String, dynamic> config = getConfig(
        configFile: null,
        flavor: null,
      );
      File('pubspec.yaml').deleteSync();
      expect(config, isNotNull);
      expect(config['color'], '#00ff00');

      // fails if config file is missing
      expect(() => getConfig(configFile: null, flavor: null), throwsException);
    });
  });
}

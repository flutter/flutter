import 'package:test/test.dart';

import 'shorebird_tests.dart';

void main() {
  group('shorebird android projects', () {
    testWithShorebirdProject('can build an apk', (projectDirectory) async {
      await projectDirectory.runFlutterBuildApk();

      expect(projectDirectory.apkFile().existsSync(), isTrue);
      expect(projectDirectory.shorebirdFile.existsSync(), isTrue);
      expect(projectDirectory.getGeneratedAndroidShorebirdYaml(), completes);
    });

    group('when passing the public key through the environment variable', () {
      testWithShorebirdProject(
        'adds the public key on top of the original file',
        (projectDirectory) async {
          final originalYaml = projectDirectory.shorebirdYaml;

          const base64PublicKey = 'public_123';
          await projectDirectory.runFlutterBuildApk(
            environment: {
              'SHOREBIRD_PUBLIC_KEY': base64PublicKey,
            },
          );

          final generatedYaml =
              await projectDirectory.getGeneratedAndroidShorebirdYaml();

          expect(
            generatedYaml.keys,
            containsAll(originalYaml.keys),
          );

          expect(
            generatedYaml['patch_public_key'],
            equals(base64PublicKey),
          );
        },
      );
    });

    group('when building with a flavor', () {
      testWithShorebirdProject(
        'correctly changes the app id',
        (projectDirectory) async {
          await projectDirectory.addProjectFlavors();
          projectDirectory.addShorebirdFlavors();

          await projectDirectory.runFlutterBuildApk(flavor: 'internal');

          final generatedYaml =
              await projectDirectory.getGeneratedAndroidShorebirdYaml(
            flavor: 'internal',
          );

          expect(generatedYaml['app_id'], equals('internal_123'));
        },
      );

      group('when public key passed through environment variable', () {
        testWithShorebirdProject(
          'correctly changes the app id and adds the public key',
          (projectDirectory) async {
            const base64PublicKey = 'public_123';
            await projectDirectory.addProjectFlavors();
            projectDirectory.addShorebirdFlavors();

            await projectDirectory.runFlutterBuildApk(
              flavor: 'internal',
              environment: {
                'SHOREBIRD_PUBLIC_KEY': base64PublicKey,
              },
            );

            final generatedYaml =
                await projectDirectory.getGeneratedAndroidShorebirdYaml(
              flavor: 'internal',
            );

            expect(generatedYaml['app_id'], equals('internal_123'));
            expect(
              generatedYaml['patch_public_key'],
              equals(base64PublicKey),
            );
          },
        );
      });
    });
  });
}

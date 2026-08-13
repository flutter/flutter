import 'dart:io';

import 'package:args/args.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'dry-run',
      negatable: false,
      help: 'Print out the cipd commands without executing them.',
    );
  final argResults = parser.parse(args);
  final dryRun = argResults['dry-run'] as bool;

  // Define the list of versions to create in the format <version>-<distributionType>
  // This should be the list of gradle versions found in all
  // gradle-wrapper.properties files underneath the /dev folder (these
  // SHOULD be 'bin' distribution types) AND the default gradle
  // version defined in gradle_utils.dart (this SHOULD be the 'all'
  // distribution type).
  final versions = ['8.14-bin', '8.4-bin', '8.13-rc-1-bin', '9.3.1-bin', '9.3.1-all'];

  // Define the CIPD packages location
  final location = 'flutter/gradle_dists';

  // Resolve the gclient-synced Gradle binary from the flutter tree
  // Assuming the script is run from the root of the flutter checkout
  final isWindows = Platform.isWindows;
  final gradlePath = isWindows
      ? 'engine\\src\\flutter\\third_party\\gradle\\bin\\gradle.bat'
      : 'engine/src/flutter/third_party/gradle/bin/gradle';

  final gradleExecutable = File(gradlePath).absolute.path;

  if (!File(gradleExecutable).existsSync()) {
    print('Error: Could not find gradle binary at $gradleExecutable');
    print('Please run `gclient sync` and run this script from the root of the checkout.');
    exit(1);
  }

  // 1. Create a single reusable staging project for all iterations
  Directory stagingProject = await Directory.systemTemp.createTemp('staging_project_');

  try {
    // 2. Initialize a basic gradle project using the gclient-synced binary
    await _runCommand(gradleExecutable, [
      'init',
      '--type',
      'basic',
      '--dsl',
      'groovy',
      '--no-daemon',
    ], stagingProject!.path);
    final gradlewExecutable = isWindows ? '.\\gradlew.bat' : './gradlew';

    for (final versionStr in versions) {
      print('Processing Gradle Wrapper $versionStr...');

      // Parse version and dist type
      final parts = versionStr.split('-');
      final distType = parts.last;
      final version = parts.sublist(0, parts.length - 1).join('-');

      if (distType != 'bin' && distType != 'all') {
        print('Error: Invalid distribution type "$distType" in "$versionStr"');
        continue;
      }

      // 3. Skip if the package version already exists in CIPD
      // This makes the script idempotent so you can run it safely at any time.
      final searchResult = await Process.run('cipd', [
        'search',
        '$location/$versionStr',
        '-tag',
        'version:$versionStr',
      ]);
      if (searchResult.exitCode != 0) {
        throw Exception('Failed to search CIPD for $location/$versionStr: ${searchResult.stderr}');
      }
      if (searchResult.stdout.toString().contains('Instances:')) {
        print(
          'Notice: Package $location/$versionStr with tag version:$versionStr already exists in CIPD.',
        );
        print('Skipping to avoid overwriting...');
        continue;
      }

      // 4. Create an isolated Gradle home for this specific version download
      final Directory isolatedGradleHome = await Directory.systemTemp.createTemp('gradle_home_');

      try {
        // 5. Update the staging project to the target version
        await _runCommand(gradlewExecutable, [
          'wrapper',
          '--gradle-version',
          version,
          '--distribution-type',
          distType,
          '--no-daemon',
        ], stagingProject!.path);

        // 6. Trigger download into our isolated cache
        await _runCommand(
          gradlewExecutable,
          ['--version', '--no-daemon'],
          stagingProject.path,
          environment: {'GRADLE_USER_HOME': isolatedGradleHome.path},
        );

        // 7. Navigate into the dists folder and upload to CIPD
        final distsDirPath = '${isolatedGradleHome.path}/wrapper/dists';
        final distsDir = Directory(distsDirPath);

        final cipdYamlContent =
            '''
package: $location/$versionStr
description: Gradle $version $distType distribution
install_mode: copy
data:
- dir: .
''';
        if (await distsDir.exists()) {
          // Write the YAML file
          final yamlFile = File('${distsDir.path}/cipd.yaml');
          await yamlFile.writeAsString(cipdYamlContent);

          if (dryRun) {
            print('Working dir: ${distsDir.path}');
            print(
              'cipd create -in . -name $location/$versionStr -tag "version:$versionStr" -ref latest',
            );
          } else {
            // 8. Upload to CIPD
            await _runCommand('cipd', [
              'create',
              '-in',
              '.',
              '-name',
              '$location/$versionStr',
              '-tag',
              'version:$versionStr',
              '-ref',
              'latest',
            ], distsDir.path);
            print('Successfully uploaded $location/$versionStr');
          }
        } else {
          throw Exception('Dists directory not found at ${distsDir.path}');
        }
      } finally {
        // 9. Clean up the isolated Gradle home for this iteration
        if (await isolatedGradleHome.exists()) {
          await isolatedGradleHome.delete(recursive: true);
        }
      }
    }
  } finally {
    // 10. Clean up the shared staging project when script finishes
    if (await stagingProject.exists()) {
      await stagingProject.delete(recursive: true);
    }
  }
}

Future<void> _runCommand(
  String executable,
  List<String> arguments,
  String workingDirectory, {
  Map<String, String>? environment,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );
  if (result.exitCode != 0) {
    throw Exception('Command failed: $executable ${arguments.join(' ')}\n${result.stderr}');
  }
}

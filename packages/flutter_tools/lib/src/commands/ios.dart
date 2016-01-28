// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:path/path.dart" as path;

import "../artifacts.dart";
import "../base/context.dart";
import "../base/process.dart";
import "../runner/flutter_command.dart";
import "../runner/flutter_command_runner.dart";

class IOSCommand extends FlutterCommand {
  final String name = "ios";
  final String description = "Commands for creating and updating Flutter iOS projects.";

  final bool requiresProjectRoot = true;

  IOSCommand() {
    argParser.addFlag('init', help: 'Initialize the Xcode project for building the iOS application');
  }

  static Uri _xcodeProjectUri(String revision) {
    String uriString = "https://storage.googleapis.com/flutter_infra/flutter/$revision/ios/FlutterXcode.zip";
    return Uri.parse(uriString);
  }

  Future<List<int>> _fetchXcodeArchive() async {
    printStatus("Fetching the Xcode project archive from the cloud...");

    HttpClient client = new HttpClient();

    Uri xcodeProjectUri = _xcodeProjectUri(ArtifactStore.engineRevision);
    printStatus("Downloading $xcodeProjectUri...");
    HttpClientRequest request = await client.getUrl(xcodeProjectUri);
    HttpClientResponse response = await request.close();

    if (response.statusCode != 200)
      throw new Exception(response.reasonPhrase);

    BytesBuilder bytesBuilder = new BytesBuilder(copy: false);
    await for (List<int> chunk in response)
      bytesBuilder.add(chunk);

    return bytesBuilder.takeBytes();
  }

  Future<bool> _inflateXcodeArchive(String directory, List<int> archiveBytes) async {
    printStatus("Unzipping Xcode project to local directory...");

    // We cannot use ArchiveFile because this archive contains files that are exectuable
    // and there is currently no provision to modify file permissions during
    // or after creation. See https://github.com/dart-lang/sdk/issues/15078.
    // So we depend on the platform to unzip the archive for us.

    Directory tempDir = await Directory.systemTemp.create();
    File tempFile = new File(path.join(tempDir.path, "FlutterXcode.zip"))..createSync();
    tempFile.writeAsBytesSync(archiveBytes);

    try {
      runCheckedSync(['/usr/bin/unzip', tempFile.path, '-d', directory]);
    } catch (error) {
      return false;
    }

    // Cleanup the temp directory after unzipping
    runSync(['/bin/rm', '-rf', tempDir.path]);

    Directory flutterDir = new Directory(path.join(directory, 'Flutter'));
    bool flutterDirExists = await flutterDir.exists();
    if (!flutterDirExists)
      return false;

    // Move contents of the Flutter directory one level up
    // There is no dart:io API to do this. See https://github.com/dart-lang/sdk/issues/8148

    for (FileSystemEntity file in flutterDir.listSync()) {
      try {
        runCheckedSync(['/bin/mv', file.path, directory]);
      } catch (error) {
        return false;
      }
    }

    runSync(['/bin/rm', '-rf', flutterDir.path]);

    return true;
  }

  void _setupXcodeProjXcconfig(String filePath) {
    StringBuffer localsBuffer = new StringBuffer();

    localsBuffer.writeln("// Generated. Do not edit or check into version control!");
    localsBuffer.writeln("// Recreate using `flutter ios`.");

    String flutterRoot = path.normalize(Platform.environment[kFlutterRootEnvironmentVariableName]);
    localsBuffer.writeln("FLUTTER_ROOT=$flutterRoot");

    // This holds because requiresProjectRoot is true for this command
    String applicationRoot = path.normalize(Directory.current.path);
    localsBuffer.writeln("FLUTTER_APPLICATION_PATH=$applicationRoot");

    String dartSDKPath = path.normalize(path.join(Platform.resolvedExecutable, "..", ".."));
    localsBuffer.writeln("DART_SDK_PATH=$dartSDKPath");

    File localsFile = new File(filePath);
    localsFile.createSync(recursive: true);
    localsFile.writeAsStringSync(localsBuffer.toString());
  }

  Future<int> _runInitCommand() async {
    // Step 1: Fetch the archive from the cloud
    String xcodeprojPath = path.join(Directory.current.path, "ios");
    List<int> archiveBytes = await _fetchXcodeArchive();

    if (archiveBytes.isEmpty) {
      printError("Error: No archive bytes received.");
      return 1;
    }

    // Step 2: Inflate the archive into the user project directory
    bool result = await _inflateXcodeArchive(xcodeprojPath, archiveBytes);
    if (!result) {
      printError("Error: Could not init the Xcode project: the 'ios' directory already exists.");
      printError("To proceed, remove the 'ios' directory and try again.");
      printError("Warning: You may have made manual changes to files in the 'ios' directory.");
      return 1;
    }

    // Step 3: Populate the Local.xcconfig with project specific paths
    _setupXcodeProjXcconfig(path.join(xcodeprojPath, "Local.xcconfig"));

    // Step 4: Tell the user the location of the generated project.
    printStatus("An Xcode project has been placed in 'ios/'.");
    printStatus("You may edit it to modify iOS specific configuration.");
    return 0;
  }

  @override
  Future<int> runInProject() async {
    if (!Platform.isMacOS) {
      printStatus("iOS specific commands may only be run on a Mac.");
      return 1;
    }

    if (argResults['init'])
      return await _runInitCommand();

    printError("No flags specified.");
    return 1;
  }
}

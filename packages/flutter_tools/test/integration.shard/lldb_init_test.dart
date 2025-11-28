// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  const customLLDBInitFileSchemeSetting =
      r'customLLDBInitFile = "$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"';
  test(
    'Ensure lldb is added to Xcode project',
    () async {
      final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
        'lldb_test.',
      );
      try {
        final String workingDirectoryPath = workingDirectory.path;
        const appName = 'lldb_test';

        final ProcessResult createResult = await processManager.run(<String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'create',
          '--org',
          'io.flutter.devicelab',
          appName,
          '--platforms=ios',
        ], workingDirectory: workingDirectory.path);
        expect(
          createResult.exitCode,
          0,
          reason:
              'Failed to create app: \n'
              'stdout: \n${createResult.stdout}\n'
              'stderr: \n${createResult.stderr}\n',
        );

        final String appDirectoryPath = fileSystem.path.join(workingDirectoryPath, appName);

        final File schemeFile = fileSystem
            .directory(appDirectoryPath)
            .childDirectory('ios')
            .childDirectory('Runner.xcodeproj')
            .childDirectory('xcshareddata')
            .childDirectory('xcschemes')
            .childFile('Runner.xcscheme');
        expect(schemeFile.existsSync(), isTrue);

        // Remove customLLDBInitFile from the scheme so we can validate it
        // gets re-added if missing.
        expect(schemeFile.readAsStringSync(), contains(customLLDBInitFileSchemeSetting));
        schemeFile.writeAsStringSync(
          schemeFile.readAsStringSync().replaceAll(customLLDBInitFileSchemeSetting, ''),
        );

        final File lldbInitFile = fileSystem
            .directory(appDirectoryPath)
            .childDirectory('ios')
            .childDirectory('Flutter')
            .childDirectory('ephemeral')
            .childFile('flutter_lldbinit');
        expect(lldbInitFile.existsSync(), isTrue);

        final File lldbPythonFile = fileSystem
            .directory(appDirectoryPath)
            .childDirectory('ios')
            .childDirectory('Flutter')
            .childDirectory('ephemeral')
            .childFile('flutter_lldb_helper.py');
        expect(lldbPythonFile.existsSync(), isTrue);

        // Delete LLDB files so we can verify they get re-added if missing.
        lldbInitFile.deleteSync();
        lldbPythonFile.deleteSync();

        final ProcessResult buildResult = await processManager.run(<String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'ios',
          '--debug',
        ], workingDirectory: appDirectoryPath);
        expect(
          buildResult.exitCode,
          0,
          reason:
              'Failed to build the app: \n'
              'stdout: \n${buildResult.stdout}\n'
              'stderr: \n${buildResult.stderr}\n',
        );

        expect(schemeFile.readAsStringSync(), contains(customLLDBInitFileSchemeSetting));
        expect(lldbInitFile.existsSync(), isTrue);
        expect(lldbPythonFile.existsSync(), isTrue);
      } finally {
        ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
      }
    },
    skip: !platform.isMacOS, // [intended] Can only build on macOS.
  );

  test(
    'Ensure lldb is added to Xcode project when using flavor',
    () async {
      final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
        'lldb_test.',
      );
      try {
        final String workingDirectoryPath = workingDirectory.path;
        const appName = 'lldb_test';
        const flavor = 'vanilla';

        final ProcessResult createResult = await processManager.run(<String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'create',
          '--org',
          'io.flutter.devicelab',
          appName,
          '--platforms=ios',
        ], workingDirectory: workingDirectory.path);
        expect(
          createResult.exitCode,
          0,
          reason:
              'Failed to create app: \n'
              'stdout: \n${createResult.stdout}\n'
              'stderr: \n${createResult.stderr}\n',
        );

        final String appDirectoryPath = fileSystem.path.join(workingDirectoryPath, appName);
        final File schemeFile = fileSystem
            .directory(appDirectoryPath)
            .childDirectory('ios')
            .childDirectory('Runner.xcodeproj')
            .childDirectory('xcshareddata')
            .childDirectory('xcschemes')
            .childFile('Runner.xcscheme');
        expect(schemeFile.existsSync(), isTrue);

        final File pbxprojFile = fileSystem
            .directory(appDirectoryPath)
            .childDirectory('ios')
            .childDirectory('Runner.xcodeproj')
            .childFile('project.pbxproj');
        expect(pbxprojFile.existsSync(), isTrue);

        // Create flavor
        final File flavorSchemeFile = fileSystem
            .directory(appDirectoryPath)
            .childDirectory('ios')
            .childDirectory('Runner.xcodeproj')
            .childDirectory('xcshareddata')
            .childDirectory('xcschemes')
            .childFile('$flavor.xcscheme');
        flavorSchemeFile.createSync(recursive: true);
        flavorSchemeFile.writeAsStringSync(schemeFile.readAsStringSync());

        String pbxprojContents = pbxprojFile.readAsStringSync();
        pbxprojContents = pbxprojContents.replaceAll('97C147061CF9000F007C117D /* Debug */,', '''
97C147061CF9000F007C117D /* Debug */,
78624EC12D71262400FF7985 /* Debug-vanilla */,
''');
        pbxprojContents = pbxprojContents.replaceAll('97C147031CF9000F007C117D /* Debug */,', '''
97C147031CF9000F007C117D /* Debug */,
78624EC02D71262400FF7985 /* Debug-vanilla */,
''');

        pbxprojContents = pbxprojContents.replaceAll(
          '/* Begin XCBuildConfiguration section */',
          r'''
/* Begin XCBuildConfiguration section */
78624EC12D71262400FF7985 /* Debug-vanilla */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = 7AFA3C8E1D35360C0083082E /* Debug.xcconfig */;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CLANG_ENABLE_MODULES = YES;
				CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
				ENABLE_BITCODE = NO;
				INFOPLIST_FILE = Runner/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				PRODUCT_BUNDLE_IDENTIFIER = com.example.lldb_test;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_OBJC_BRIDGING_HEADER = "Runner/Runner-Bridging-Header.h";
				SWIFT_VERSION = 5.0;
				VERSIONING_SYSTEM = "apple-generic";
			};
			name = "Debug-vanilla";
		};
    		78624EC02D71262400FF7985 /* Debug-vanilla */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++0x";
				CLANG_CXX_LIBRARY = "libc++";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = NO;
				GCC_C_LANGUAGE_STANDARD = gnu99;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 12.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				TARGETED_DEVICE_FAMILY = "1,2";
				VALIDATE_PRODUCT = YES;
			};
			name = "Debug-vanilla";
		};
''',
        );
        pbxprojFile.writeAsStringSync(pbxprojContents);

        // Remove customLLDBInitFile from the flavor's scheme so we can validate
        // it gets re-added later.
        expect(flavorSchemeFile.readAsStringSync(), contains(customLLDBInitFileSchemeSetting));
        flavorSchemeFile.writeAsStringSync(
          flavorSchemeFile.readAsStringSync().replaceAll(customLLDBInitFileSchemeSetting, ''),
        );

        final ProcessResult buildResult = await processManager.run(<String>[
          flutterBin,
          ...getLocalEngineArguments(),
          'build',
          'ios',
          '--config-only',
          '--debug',
          '--flavor',
          flavor,
        ], workingDirectory: appDirectoryPath);
        expect(
          buildResult.exitCode,
          0,
          reason:
              'Failed to build config for the app: \n'
              'stdout: \n${buildResult.stdout}\n'
              'stderr: \n${buildResult.stderr}\n',
        );

        expect(flavorSchemeFile.readAsStringSync(), contains(customLLDBInitFileSchemeSetting));

        final File lldbInitFile = fileSystem
            .directory(appDirectoryPath)
            .childDirectory('ios')
            .childDirectory('Flutter')
            .childDirectory('ephemeral')
            .childFile('flutter_lldbinit');
        expect(lldbInitFile.existsSync(), isTrue);

        final File lldbPythonFile = fileSystem
            .directory(appDirectoryPath)
            .childDirectory('ios')
            .childDirectory('Flutter')
            .childDirectory('ephemeral')
            .childFile('flutter_lldb_helper.py');
        expect(lldbPythonFile.existsSync(), isTrue);
      } finally {
        ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
      }
    },
    skip: !platform.isMacOS, // [intended] Can only build on macOS.
  );
}

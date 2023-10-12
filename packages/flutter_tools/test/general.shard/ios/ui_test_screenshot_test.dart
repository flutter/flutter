// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/ios/core_devices.dart';
import 'package:flutter_tools/src/ios/ui_test_screenshot.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  const String flutterRoot = '/path/to/flutter';
  const String pathToXcodeProject = '$flutterRoot/dev/tools/UITestScreenshot';

  late MemoryFileSystem fileSystem;
  late BufferLogger logger;
  late FakeProcessManager fakeProcessManager;
  late FakeIOSCoreDeviceControl coreDeviceControl;
  late ProcessUtils processUtils;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    fakeProcessManager = FakeProcessManager.empty();
    processUtils = ProcessUtils(processManager: fakeProcessManager, logger: logger);
    coreDeviceControl = FakeIOSCoreDeviceControl();
  });

  group('uiTestScreenshotXcodeProject', () {
    testWithoutContext('returns path when found', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        coreDeviceControl: coreDeviceControl,
        flutterRoot: flutterRoot,
      );

      fileSystem.directory(pathToXcodeProject).createSync(recursive: true);

      expect(uiTestScreenshot.uiTestScreenshotXcodeProject, pathToXcodeProject);
    });

    testWithoutContext('throws error if not found', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        coreDeviceControl: coreDeviceControl,
        flutterRoot: flutterRoot,
      );

      expect(
        () => uiTestScreenshot.uiTestScreenshotXcodeProject,
        throwsToolExit(message: 'Unable to find UI Test Screenshot Xcode project at'),
      );
    });
  });

  group('takeScreenshot on iOS device', () {
    late File outputFile;
    const String deviceId = 'device-id-00000';
    const String resultBundlePath = '/.tmp_rand0/flutter_xcresult.rand0/result';

    setUp(() {
      outputFile = fileSystem.file('flutter_01.png');
      outputFile.createSync(recursive: true);
      fileSystem.directory(pathToXcodeProject).createSync(recursive: true);
    });

    testWithoutContext('throws error if device id not given', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        coreDeviceControl: coreDeviceControl,
        flutterRoot: flutterRoot,
      );

      expect(
        () => uiTestScreenshot.takeScreenshot(
          outputFile,
          target: UITestScreenshotCompatibleTargets.ios,
        ),
        throwsToolExit(message: 'A device id must be supplied for iOS devices.'),
      );
      expect(outputFile.readAsBytesSync(), isEmpty);
    });

    testWithoutContext('throws error if core device control not given', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        flutterRoot: flutterRoot,
      );

      expect(
        () => uiTestScreenshot.takeScreenshot(
          outputFile,
          target: UITestScreenshotCompatibleTargets.ios,
          deviceId: deviceId,
        ),
        throwsToolExit(message: 'CoreDeviceControl is required for iOS devices.'),
      );
      expect(outputFile.readAsBytesSync(), isEmpty);
    });

    testWithoutContext('throws error if test fails', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        coreDeviceControl: coreDeviceControl,
        flutterRoot: flutterRoot,
      );

      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-scheme',
            'UITestScreenshot',
            '-destination',
            'id=$deviceId',
            '-resultBundlePath',
            resultBundlePath,
            '-only-testing:UITestScreenshotUITests',
            'test',
            'COMPILER_INDEX_STORE_ENABLE=NO'
          ],
          exitCode: 1,
        ),
      ]);

      expect(
        () => uiTestScreenshot.takeScreenshot(
          outputFile,
          target: UITestScreenshotCompatibleTargets.ios,
          deviceId: deviceId,
        ),
        throwsToolExit(message: 'Failed to take screenshot:'),
      );
      expect(outputFile.readAsBytesSync(), isEmpty);
    });

    testWithoutContext('throws error if fails to get test results', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        coreDeviceControl: coreDeviceControl,
        flutterRoot: flutterRoot,
      );

      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-scheme',
            'UITestScreenshot',
            '-destination',
            'id=$deviceId',
            '-resultBundlePath',
            resultBundlePath,
            '-only-testing:UITestScreenshotUITests',
            'test',
            'COMPILER_INDEX_STORE_ENABLE=NO'
          ],
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--format',
            'json'
          ],
          exitCode: 1,
        ),
      ]);

      expect(
        () => uiTestScreenshot.takeScreenshot(
          outputFile,
          target: UITestScreenshotCompatibleTargets.ios,
          deviceId: deviceId,
        ),
        throwsToolExit(message: 'Failed to get test results:'),
      );
      expect(outputFile.readAsBytesSync(), isEmpty);
    });

    testWithoutContext('throws error if fails to parse ref', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        coreDeviceControl: coreDeviceControl,
        flutterRoot: flutterRoot,
      );

      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-scheme',
            'UITestScreenshot',
            '-destination',
            'id=$deviceId',
            '-resultBundlePath',
            resultBundlePath,
            '-only-testing:UITestScreenshotUITests',
            'test',
            'COMPILER_INDEX_STORE_ENABLE=NO'
          ],
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--format',
            'json'
          ],
          stdout: 'no ref',
        ),
      ]);

      expect(
        () => uiTestScreenshot.takeScreenshot(
          outputFile,
          target: UITestScreenshotCompatibleTargets.ios,
          deviceId: deviceId,
        ),
        throwsToolExit(message: 'Failed to parse'),
      );
      expect(outputFile.readAsBytesSync(), isEmpty);
    });

    testWithoutContext('throws error if fails to get ref results', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        coreDeviceControl: coreDeviceControl,
        flutterRoot: flutterRoot,
      );

      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-scheme',
            'UITestScreenshot',
            '-destination',
            'id=$deviceId',
            '-resultBundlePath',
            resultBundlePath,
            '-only-testing:UITestScreenshotUITests',
            'test',
            'COMPILER_INDEX_STORE_ENABLE=NO'
          ],
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--format',
            'json'
          ],
          stdout: resultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            testsRefId,
            '--format',
            'json'
          ],
          exitCode: 1,
        ),
      ]);

      expect(
        () => uiTestScreenshot.takeScreenshot(
          outputFile,
          target: UITestScreenshotCompatibleTargets.ios,
          deviceId: deviceId,
        ),
        throwsToolExit(message: 'Failed to get results for'),
      );
      expect(outputFile.readAsBytesSync(), isEmpty);
    });

    testWithoutContext('succeeds', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        coreDeviceControl: coreDeviceControl,
        flutterRoot: flutterRoot,
      );

      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-scheme',
            'UITestScreenshot',
            '-destination',
            'id=$deviceId',
            '-resultBundlePath',
            resultBundlePath,
            '-only-testing:UITestScreenshotUITests',
            'test',
            'COMPILER_INDEX_STORE_ENABLE=NO'
          ],
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--format',
            'json'
          ],
          stdout: resultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            testsRefId,
            '--format',
            'json'
          ],
          stdout: testRefResultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            summaryRefId,
            '--format',
            'json'
          ],
          stdout: summaryRefResultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            payloadRefId,
          ],
          stdout: payloadResult,
        ),
      ]);

      await uiTestScreenshot.takeScreenshot(
        outputFile,
        target: UITestScreenshotCompatibleTargets.ios,
        deviceId: deviceId,
      );
      expect(fakeProcessManager.hasRemainingExpectations, false);
      expect(coreDeviceControl.appUninstalled, true);
      expect(outputFile.readAsBytesSync(), isNotEmpty);
    });

    testWithoutContext('succeeds with codesigning flags', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        coreDeviceControl: coreDeviceControl,
        environment: <String, String>{
          'FLUTTER_XCODE_DEVELOPMENT_TEAM': 'TEAM_ID',
          'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Manual',
          'FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER': 'match Development *'
        },
        flutterRoot: flutterRoot,
      );

      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-scheme',
            'UITestScreenshot',
            '-destination',
            'id=$deviceId',
            '-resultBundlePath',
            resultBundlePath,
            '-only-testing:UITestScreenshotUITests',
            'test',
            'COMPILER_INDEX_STORE_ENABLE=NO',
            'DEVELOPMENT_TEAM=TEAM_ID',
            'CODE_SIGN_STYLE=Manual',
            'PROVISIONING_PROFILE_SPECIFIER=match Development *'
          ],
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--format',
            'json'
          ],
          stdout: resultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            testsRefId,
            '--format',
            'json'
          ],
          stdout: testRefResultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            summaryRefId,
            '--format',
            'json'
          ],
          stdout: summaryRefResultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            payloadRefId,
          ],
          stdout: payloadResult,
        ),
      ]);

      await uiTestScreenshot.takeScreenshot(
        outputFile,
        target: UITestScreenshotCompatibleTargets.ios,
        deviceId: deviceId,
      );
      expect(fakeProcessManager.hasRemainingExpectations, false);
      expect(coreDeviceControl.appUninstalled, true);
      expect(outputFile.readAsBytesSync(), isNotEmpty);
    });
  });

  group('takeScreenshot on macOS device', () {
    late File outputFile;
    const String resultBundlePath = '/.tmp_rand0/flutter_xcresult.rand0/result';

    setUp(() {
      outputFile = fileSystem.file('flutter_01.png');
      outputFile.createSync(recursive: true);
      fileSystem.directory(pathToXcodeProject).createSync(recursive: true);
    });

    testWithoutContext('succeeds', () async {
      final UITestScreenshot uiTestScreenshot = UITestScreenshot(
        fileSystem: fileSystem,
        processUtils: processUtils,
        flutterRoot: flutterRoot,
      );

      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-scheme',
            'UITestScreenshot',
            '-destination',
            'platform=macOS',
            '-resultBundlePath',
            resultBundlePath,
            '-only-testing:UITestScreenshotUITests',
            'test',
            'COMPILER_INDEX_STORE_ENABLE=NO'
          ],
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--format',
            'json'
          ],
          stdout: resultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            testsRefId,
            '--format',
            'json'
          ],
          stdout: testRefResultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            summaryRefId,
            '--format',
            'json'
          ],
          stdout: summaryRefResultJson,
        ),
        const FakeCommand(
          command: <String>[
            'xcrun',
            'xcresulttool',
            'get',
            '--path',
            resultBundlePath,
            '--id',
            payloadRefId,
          ],
          stdout: payloadResult,
        ),
      ]);

      await uiTestScreenshot.takeScreenshot(
        outputFile,
        target: UITestScreenshotCompatibleTargets.macos,
      );
      expect(fakeProcessManager.hasRemainingExpectations, false);
      expect(coreDeviceControl.appUninstalled, false);
      expect(outputFile.readAsBytesSync(), isNotEmpty);
    });
  });
}

class FakeIOSCoreDeviceControl extends Fake implements IOSCoreDeviceControl {
  bool appUninstalled = false;

  @override
  Future<bool> uninstallApp({
    required String deviceId,
    required String bundleId,
  }) async {
    appUninstalled = true;
    return true;
  }
}

const String testsRefId = '0~Rxb1AJbKkD7hKD2ixA0pR3mR2Wj9kfI-4aZbIMc_6Z_jAT7YYVA3jKHqcgBa8h_N2HMfzH0aXhWrPb3VKuPZ_A==';
const String summaryRefId = '0~mn1VqxPBvQY__NlGoI2dlTjh1S0kApupocSIgiu7qnJ7xjn5K32c2TR_1wyfwCrGHNvPff687YZk4gi_0C8acg==';
const String payloadRefId = '0~DuZQvRs9v8gFOGJiOVXNzuOev9naORI5jSm1GFbsw5XDSg_DY7zy2_Mv6I09jDh60EkBAsey_k4aDrtMOS87tg==';

const String resultJson = '''
{
  "_type" : {
    "_name" : "ActionsInvocationRecord"
  },
  "actions" : {
    "_type" : {
      "_name" : "Array"
    },
    "_values" : [
      {
        "_type" : {
          "_name" : "ActionRecord"
        },
        "actionResult" : {
          "_type" : {
            "_name" : "ActionResult"
          },
          "coverage" : {
            "_type" : {
              "_name" : "CodeCoverageInfo"
            },
            "archiveRef" : {
              "_type" : {
                "_name" : "Reference"
              },
              "id" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "0~J2k2wxE8hTCql6wQtCKzh8TCED5m5-534lUK_gjf51bWkH9EG93uJFl3RHjT8iQ8xs3Tr7V8JAkc8PcqlVRF6w=="
              }
            },
            "hasCoverageData" : {
              "_type" : {
                "_name" : "Bool"
              },
              "_value" : "true"
            },
            "reportRef" : {
              "_type" : {
                "_name" : "Reference"
              },
              "id" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "0~9zffEx-j71Uwzg0etc7KtDH9zoBZA7Rg-0vmZ9LPFHt6Hg7DO8UKKiITXvFn8ga6II1AlbSl2SH8LXYk3ei5Gg=="
              }
            }
          },
          "diagnosticsRef" : {
            "_type" : {
              "_name" : "Reference"
            },
            "id" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "0~L-El4lJEVbOxuCHyqnZD3sQa4BbT7KUlvlIHxmWb9dPhBFSt3exVmTntkeEMXn_nG-v1ce_J_WXTlo4lkLKWjQ=="
            }
          },
          "issues" : {
            "_type" : {
              "_name" : "ResultIssueSummaries"
            }
          },
          "logRef" : {
            "_type" : {
              "_name" : "Reference"
            },
            "id" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "0~guek-EO7FqZ_4DJ09C_k4WoIkVxa5JWERuErRK921Pd6IXHGAtj-8QZovGzSj2AcIzGjweVXvGXWXBd-sOX5Pg=="
            },
            "targetType" : {
              "_type" : {
                "_name" : "TypeDefinition"
              },
              "name" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "ActivityLogSection"
              }
            }
          },
          "metrics" : {
            "_type" : {
              "_name" : "ResultMetrics"
            },
            "testsCount" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "1"
            }
          },
          "resultName" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "action"
          },
          "status" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "succeeded"
          },
          "testsRef" : {
            "_type" : {
              "_name" : "Reference"
            },
            "id" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "$testsRefId"
            },
            "targetType" : {
              "_type" : {
                "_name" : "TypeDefinition"
              },
              "name" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "ActionTestPlanRunSummaries"
              }
            }
          }
        },
        "buildResult" : {
          "_type" : {
            "_name" : "ActionResult"
          },
          "coverage" : {
            "_type" : {
              "_name" : "CodeCoverageInfo"
            }
          },
          "issues" : {
            "_type" : {
              "_name" : "ResultIssueSummaries"
            }
          },
          "logRef" : {
            "_type" : {
              "_name" : "Reference"
            },
            "id" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "0~31pKtt1-YcGehUOLuEzLCMrVrOAJgiikmETFmNhdTsp_vppNWPxJeqQR3uZhhB-icmqNNeZ3wXHAedjxGQrnNw=="
            },
            "targetType" : {
              "_type" : {
                "_name" : "TypeDefinition"
              },
              "name" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "ActivityLogSection"
              }
            }
          },
          "metrics" : {
            "_type" : {
              "_name" : "ResultMetrics"
            }
          },
          "resultName" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "build"
          },
          "status" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "succeeded"
          }
        },
        "endedTime" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.991-0500"
        },
        "runDestination" : {
          "_type" : {
            "_name" : "ActionRunDestinationRecord"
          },
          "displayName" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "My iPad"
          },
          "localComputerRecord" : {
            "_type" : {
              "_name" : "ActionDeviceRecord"
            },
            "busSpeedInMHz" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "0"
            },
            "cpuCount" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "1"
            },
            "cpuKind" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "Apple M1 Pro"
            },
            "cpuSpeedInMHz" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "0"
            },
            "identifier" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "00006000-001A69441E7A401E"
            },
            "isConcreteDevice" : {
              "_type" : {
                "_name" : "Bool"
              },
              "_value" : "true"
            },
            "logicalCPUCoresPerPackage" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "10"
            },
            "modelCode" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "MacBookPro18,1"
            },
            "modelName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "MacBook Pro"
            },
            "modelUTI" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "com.apple.macbookpro-16-2021"
            },
            "name" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "My Mac"
            },
            "nativeArchitecture" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "arm64e"
            },
            "operatingSystemVersion" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "13.6"
            },
            "operatingSystemVersionWithBuildNumber" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "13.6 (22G120)"
            },
            "physicalCPUCoresPerPackage" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "10"
            },
            "platformRecord" : {
              "_type" : {
                "_name" : "ActionPlatformRecord"
              },
              "identifier" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "com.apple.platform.macosx"
              },
              "userDescription" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "macOS"
              }
            },
            "ramSizeInMegabytes" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "16384"
            }
          },
          "targetArchitecture" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "arm64"
          },
          "targetDeviceRecord" : {
            "_type" : {
              "_name" : "ActionDeviceRecord"
            },
            "busSpeedInMHz" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "0"
            },
            "cpuCount" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "0"
            },
            "cpuSpeedInMHz" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "0"
            },
            "identifier" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "00008112-0006112A3C03401E"
            },
            "isConcreteDevice" : {
              "_type" : {
                "_name" : "Bool"
              },
              "_value" : "true"
            },
            "logicalCPUCoresPerPackage" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "0"
            },
            "modelCode" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "iPad14,3"
            },
            "modelName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "iPad Pro (11-inch) (4th generation)""
            },
            "modelUTI" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "com.apple.ipad-pro-11-4th-1"
            },
            "name" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "My iPad"
            },
            "nativeArchitecture" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "arm64e"
            },
            "operatingSystemVersion" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "17.0.3"
            },
            "operatingSystemVersionWithBuildNumber" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "17.0.3 (21A360)"
            },
            "physicalCPUCoresPerPackage" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "0"
            },
            "platformRecord" : {
              "_type" : {
                "_name" : "ActionPlatformRecord"
              },
              "identifier" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "com.apple.platform.iphoneos"
              },
              "userDescription" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "iOS"
              }
            },
            "ramSizeInMegabytes" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "0"
            }
          },
          "targetSDKRecord" : {
            "_type" : {
              "_name" : "ActionSDKRecord"
            },
            "identifier" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "iphoneos17.0"
            },
            "name" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "iOS 17.0"
            },
            "operatingSystemVersion" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "17.0"
            }
          }
        },
        "schemeCommandName" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Test"
        },
        "schemeTaskName" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "BuildAndAction"
        },
        "startedTime" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:22:35.729-0500"
        },
        "testPlanName" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "UITestScreenshot"
        },
        "title" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Testing project UITestScreenshot with scheme UITestScreenshot"
        }
      }
    ]
  },
  "issues" : {
    "_type" : {
      "_name" : "ResultIssueSummaries"
    }
  },
  "metadataRef" : {
    "_type" : {
      "_name" : "Reference"
    },
    "id" : {
      "_type" : {
        "_name" : "String"
      },
      "_value" : "0~-dkd0RC6ReSKjIyawpkjezVxx5cQQTPPuhqsX3yGSBUBSmbKNSbPj7E3D7fTMQOMn3AkwL87aMtO-pFKliqSYg=="
    },
    "targetType" : {
      "_type" : {
        "_name" : "TypeDefinition"
      },
      "name" : {
        "_type" : {
          "_name" : "String"
        },
        "_value" : "ActionsInvocationMetadata"
      }
    }
  },
  "metrics" : {
    "_type" : {
      "_name" : "ResultMetrics"
    },
    "testsCount" : {
      "_type" : {
        "_name" : "Int"
      },
      "_value" : "1"
    },
    "totalCoveragePercentage" : {
      "_type" : {
        "_name" : "Double"
      },
      "_value" : "0.30303030303030304"
    }
  }
}
''';

const String testRefResultJson = '''
{
  "_type" : {
    "_name" : "ActionTestPlanRunSummaries"
  },
  "summaries" : {
    "_type" : {
      "_name" : "Array"
    },
    "_values" : [
      {
        "_type" : {
          "_name" : "ActionTestPlanRunSummary",
          "_supertype" : {
            "_name" : "ActionAbstractTestSummary"
          }
        },
        "name" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Test Scheme Action"
        },
        "testableSummaries" : {
          "_type" : {
            "_name" : "Array"
          },
          "_values" : [
            {
              "_type" : {
                "_name" : "ActionTestableSummary",
                "_supertype" : {
                  "_name" : "ActionAbstractTestSummary"
                }
              },
              "diagnosticsDirectoryName" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "UITestScreenshotUITests-906BD2EC-9A33-4F7C-BFF7-29D9EC777F72-Configuration-Test Scheme Action-Iteration-1"
              },
              "identifierURL" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "test://com.apple.xcode/UITestScreenshot/UITestScreenshotUITests"
              },
              "name" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "UITestScreenshotUITests"
              },
              "projectRelativePath" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "UITestScreenshot.xcodeproj"
              },
              "targetName" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "UITestScreenshotUITests"
              },
              "testKind" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "UI"
              },
              "testLanguage" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : ""
              },
              "testRegion" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : ""
              },
              "tests" : {
                "_type" : {
                  "_name" : "Array"
                },
                "_values" : [
                  {
                    "_type" : {
                      "_name" : "ActionTestSummaryGroup",
                      "_supertype" : {
                        "_name" : "ActionTestSummaryIdentifiableObject",
                        "_supertype" : {
                          "_name" : "ActionAbstractTestSummary"
                        }
                      }
                    },
                    "duration" : {
                      "_type" : {
                        "_name" : "Double"
                      },
                      "_value" : "0.21520698070526123"
                    },
                    "identifier" : {
                      "_type" : {
                        "_name" : "String"
                      },
                      "_value" : "All tests"
                    },
                    "identifierURL" : {
                      "_type" : {
                        "_name" : "String"
                      },
                      "_value" : "test://com.apple.xcode/UITestScreenshot/UITestScreenshotUITests/All%20tests"
                    },
                    "name" : {
                      "_type" : {
                        "_name" : "String"
                      },
                      "_value" : "All tests"
                    },
                    "subtests" : {
                      "_type" : {
                        "_name" : "Array"
                      },
                      "_values" : [
                        {
                          "_type" : {
                            "_name" : "ActionTestSummaryGroup",
                            "_supertype" : {
                              "_name" : "ActionTestSummaryIdentifiableObject",
                              "_supertype" : {
                                "_name" : "ActionAbstractTestSummary"
                              }
                            }
                          },
                          "duration" : {
                            "_type" : {
                              "_name" : "Double"
                            },
                            "_value" : "0.2143319845199585"
                          },
                          "identifier" : {
                            "_type" : {
                              "_name" : "String"
                            },
                            "_value" : "UITestScreenshotUITests.xctest"
                          },
                          "identifierURL" : {
                            "_type" : {
                              "_name" : "String"
                            },
                            "_value" : "test://com.apple.xcode/UITestScreenshot/UITestScreenshotUITests/UITestScreenshotUITests.xctest"
                          },
                          "name" : {
                            "_type" : {
                              "_name" : "String"
                            },
                            "_value" : "UITestScreenshotUITests.xctest"
                          },
                          "subtests" : {
                            "_type" : {
                              "_name" : "Array"
                            },
                            "_values" : [
                              {
                                "_type" : {
                                  "_name" : "ActionTestSummaryGroup",
                                  "_supertype" : {
                                    "_name" : "ActionTestSummaryIdentifiableObject",
                                    "_supertype" : {
                                      "_name" : "ActionAbstractTestSummary"
                                    }
                                  }
                                },
                                "duration" : {
                                  "_type" : {
                                    "_name" : "Double"
                                  },
                                  "_value" : "0.2138880491256714"
                                },
                                "identifier" : {
                                  "_type" : {
                                    "_name" : "String"
                                  },
                                  "_value" : "UITestScreenshotUITests"
                                },
                                "identifierURL" : {
                                  "_type" : {
                                    "_name" : "String"
                                  },
                                  "_value" : "test://com.apple.xcode/UITestScreenshot/UITestScreenshotUITests/UITestScreenshotUITests"
                                },
                                "name" : {
                                  "_type" : {
                                    "_name" : "String"
                                  },
                                  "_value" : "UITestScreenshotUITests"
                                },
                                "subtests" : {
                                  "_type" : {
                                    "_name" : "Array"
                                  },
                                  "_values" : [
                                    {
                                      "_type" : {
                                        "_name" : "ActionTestMetadata",
                                        "_supertype" : {
                                          "_name" : "ActionTestSummaryIdentifiableObject",
                                          "_supertype" : {
                                            "_name" : "ActionAbstractTestSummary"
                                          }
                                        }
                                      },
                                      "duration" : {
                                        "_type" : {
                                          "_name" : "Double"
                                        },
                                        "_value" : "0.2135469913482666"
                                      },
                                      "identifier" : {
                                        "_type" : {
                                          "_name" : "String"
                                        },
                                        "_value" : "UITestScreenshotUITests/testLaunch()"
                                      },
                                      "identifierURL" : {
                                        "_type" : {
                                          "_name" : "String"
                                        },
                                        "_value" : "test://com.apple.xcode/UITestScreenshot/UITestScreenshotUITests/UITestScreenshotUITests/testLaunch"
                                      },
                                      "name" : {
                                        "_type" : {
                                          "_name" : "String"
                                        },
                                        "_value" : "testLaunch()"
                                      },
                                      "summaryRef" : {
                                        "_type" : {
                                          "_name" : "Reference"
                                        },
                                        "id" : {
                                          "_type" : {
                                            "_name" : "String"
                                          },
                                          "_value" : "$summaryRefId"
                                        },
                                        "targetType" : {
                                          "_type" : {
                                            "_name" : "TypeDefinition"
                                          },
                                          "name" : {
                                            "_type" : {
                                              "_name" : "String"
                                            },
                                            "_value" : "ActionTestSummary"
                                          },
                                          "supertype" : {
                                            "_type" : {
                                              "_name" : "TypeDefinition"
                                            },
                                            "name" : {
                                              "_type" : {
                                                "_name" : "String"
                                              },
                                              "_value" : "ActionTestSummaryIdentifiableObject"
                                            },
                                            "supertype" : {
                                              "_type" : {
                                                "_name" : "TypeDefinition"
                                              },
                                              "name" : {
                                                "_type" : {
                                                  "_name" : "String"
                                                },
                                                "_value" : "ActionAbstractTestSummary"
                                              }
                                            }
                                          }
                                        }
                                      },
                                      "testStatus" : {
                                        "_type" : {
                                          "_name" : "String"
                                        },
                                        "_value" : "Success"
                                      }
                                    }
                                  ]
                                }
                              }
                            ]
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    ]
  }
}
''';

const String summaryRefResultJson = '''
{
  "_type" : {
    "_name" : "ActionTestSummary",
    "_supertype" : {
      "_name" : "ActionTestSummaryIdentifiableObject",
      "_supertype" : {
        "_name" : "ActionAbstractTestSummary"
      }
    }
  },
  "activitySummaries" : {
    "_type" : {
      "_name" : "Array"
    },
    "_values" : [
      {
        "_type" : {
          "_name" : "ActionTestActivitySummary"
        },
        "activityType" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "com.apple.dt.xctest.activity-type.internal"
        },
        "finish" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.445-0500"
        },
        "start" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.436-0500"
        },
        "title" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Start Test at 2023-10-12 11:23:29.436"
        },
        "uuid" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "E437F690-F7C3-4DA5-B672-38EB47319FEB"
        }
      },
      {
        "_type" : {
          "_name" : "ActionTestActivitySummary"
        },
        "activityType" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "com.apple.dt.xctest.activity-type.deletedAttachment"
        },
        "finish" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.436-0500"
        },
        "start" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.436-0500"
        },
        "title" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Some attachments were deleted because they were configured to be removed on success."
        },
        "uuid" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "EC8C1A0E-7922-4C63-8CDB-5C629BBFF67E"
        }
      },
      {
        "_type" : {
          "_name" : "ActionTestActivitySummary"
        },
        "activityType" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "com.apple.dt.xctest.activity-type.internal"
        },
        "finish" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.446-0500"
        },
        "start" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.446-0500"
        },
        "title" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Set Up"
        },
        "uuid" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "5E6FBA2A-22B3-416C-AE13-BBB9CF57EBB8"
        }
      },
      {
        "_type" : {
          "_name" : "ActionTestActivitySummary"
        },
        "activityType" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "com.apple.dt.xctest.activity-type.attachmentContainer"
        },
        "attachments" : {
          "_type" : {
            "_name" : "Array"
          },
          "_values" : [
            {
              "_type" : {
                "_name" : "ActionTestAttachment"
              },
              "filename" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "Screenshot_1_D421C1C1-7E61-4620-8179-D9D9353D03DD.png"
              },
              "inActivityIdentifier" : {
                "_type" : {
                  "_name" : "Int"
                },
                "_value" : "1"
              },
              "lifetime" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "keepAlways"
              },
              "name" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "Screenshot"
              },
              "payloadRef" : {
                "_type" : {
                  "_name" : "Reference"
                },
                "id" : {
                  "_type" : {
                    "_name" : "String"
                  },
                  "_value" : "$payloadRefId"
                }
              },
              "payloadSize" : {
                "_type" : {
                  "_name" : "Int"
                },
                "_value" : "3847070"
              },
              "timestamp" : {
                "_type" : {
                  "_name" : "Date"
                },
                "_value" : "2023-10-12T13:23:29.623-0500"
              },
              "uniformTypeIdentifier" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "public.png"
              },
              "userInfo" : {
                "_type" : {
                  "_name" : "SortedKeyValueArray"
                },
                "storage" : {
                  "_type" : {
                    "_name" : "Array"
                  },
                  "_values" : [
                    {
                      "_type" : {
                        "_name" : "SortedKeyValueArrayPair"
                      },
                      "key" : {
                        "_type" : {
                          "_name" : "String"
                        },
                        "_value" : "Scale"
                      },
                      "value" : {
                        "_type" : {
                          "_name" : "String"
                        },
                        "_value" : "2"
                      }
                    }
                  ]
                }
              },
              "uuid" : {
                "_type" : {
                  "_name" : "String"
                },
                "_value" : "BA6E46A3-ABDD-4AE0-98A5-2B9F50655993"
              }
            }
          ]
        },
        "finish" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.623-0500"
        },
        "start" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.623-0500"
        },
        "title" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Added attachment named 'Screenshot'"
        },
        "uuid" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "D421C1C1-7E61-4620-8179-D9D9353D03DD"
        }
      },
      {
        "_type" : {
          "_name" : "ActionTestActivitySummary"
        },
        "activityType" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "com.apple.dt.xctest.activity-type.internal"
        },
        "finish" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.648-0500"
        },
        "start" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2023-10-12T13:23:29.624-0500"
        },
        "title" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Tear Down"
        },
        "uuid" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "BC7F96BF-7115-455F-9953-D2E961C9ED15"
        }
      }
    ]
  },
  "duration" : {
    "_type" : {
      "_name" : "Double"
    },
    "_value" : "0.2135469913482666"
  },
  "identifier" : {
    "_type" : {
      "_name" : "String"
    },
    "_value" : "UITestScreenshotUITests/testLaunch()"
  },
  "identifierURL" : {
    "_type" : {
      "_name" : "String"
    },
    "_value" : "test://com.apple.xcode/UITestScreenshot/UITestScreenshotUITests/UITestScreenshotUITests/testLaunch"
  },
  "name" : {
    "_type" : {
      "_name" : "String"
    },
    "_value" : "testLaunch()"
  },
  "testStatus" : {
    "_type" : {
      "_name" : "String"
    },
    "_value" : "Success"
  }
}
''';

const String payloadResult = 'image as bytes';

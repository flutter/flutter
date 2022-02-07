// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/ios/xcresult.dart';
import 'package:flutter_tools/src/macos/xcode.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  // Creates a FakeCommand for the xcresult get call to build the app
  // in the given configuration.
  FakeCommand _setUpFakeXCResultGetCommand({
    required String stdout,
    required String tempResultPath,
    required Xcode xcode,
    int exitCode = 0,
    String stderr = '',
  }) {
    return FakeCommand(
      command: <String>[
        ...xcode.xcrunCommand(),
        'xcresulttool',
        'get',
        '--path',
        tempResultPath,
        '--format',
        'json',
      ],
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      onRun: () {},
    );
  }

  const FakeCommand _kWhichSysctlCommand = FakeCommand(
    command: <String>[
      'which',
      'sysctl',
    ],
  );

  const FakeCommand _kx64CheckCommand = FakeCommand(
    command: <String>[
      'sysctl',
      'hw.optional.arm64',
    ],
    exitCode: 1,
  );

  XCResultGenerator _setupGenerator({
    required String resultJson,
    int exitCode = 0,
    String stderr = '',
  }) {
    final FakeProcessManager fakeProcessManager =
        FakeProcessManager.list(<FakeCommand>[
      _kWhichSysctlCommand,
      _kx64CheckCommand,
    ]);
    final Xcode xcode = Xcode.test(
      processManager: fakeProcessManager,
      xcodeProjectInterpreter: XcodeProjectInterpreter.test(
        processManager: fakeProcessManager,
        version: null,
      ),
    );
    fakeProcessManager.addCommands(
      <FakeCommand>[
        _setUpFakeXCResultGetCommand(
          stdout: resultJson,
          tempResultPath: _tempResultPath,
          xcode: xcode,
          exitCode: exitCode,
          stderr: stderr,
        ),
      ],
    );
    final ProcessUtils processUtils = ProcessUtils(
      processManager: fakeProcessManager,
      logger: BufferLogger.test(),
    );
    return XCResultGenerator(
      resultPath: _tempResultPath,
      xcode: xcode,
      processUtils: processUtils,
    );
  }

  testWithoutContext(
      'correctly parse sample result json when there are issues.', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: _sampleResultJsonWithIssues);
    final XCResult result = await generator.generate();
    expect(result.issues.length, 2);
    expect(result.issues.first.type, XCResultIssueType.error);
    expect(result.issues.first.subType, 'Semantic Issue');
    expect(result.issues.first.message, "Use of undeclared identifier 'asdas'");
    expect(result.issues.last.type, XCResultIssueType.warning);
    expect(result.issues.last.subType, 'Warning');
    expect(result.issues.last.message,
        "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99.");
    expect(result.parseSuccess, isTrue);
    expect(result.parsingErrorMessage, isNull);
  });

  testWithoutContext('correctly parse sample result json when no issues.',
      () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: _sampleResultJsonNoIssues);
    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, isTrue);
    expect(result.parsingErrorMessage, isNull);
  });

  testWithoutContext(
      'error: `xcresulttool get` process fail should return an `XCResult` with stderr as `parsingErrorMessage`.',
      () async {
    const String fakeStderr = 'Fake: fail to parse result json.';
    final XCResultGenerator generator = _setupGenerator(
      resultJson: '',
      exitCode: 1,
      stderr: fakeStderr,
    );

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage, fakeStderr);
  });

  testWithoutContext('error: `xcresulttool get` no stdout', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: '');

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Unrecognized top level json format.');
  });

  testWithoutContext('error: wrong top level json format.', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: '[]');

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Unrecognized top level json format.');
  });

  testWithoutContext('error: fail to parse actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: '{}');

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the actions map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator =
        _setupGenerator(resultJson: _sampleResultJsonEmptyActionsMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the actions map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: _sampleResultJsonEmptyActionsMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the actions map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: _sampleResultJsonInvalidActionMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the first action map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: _sampleResultJsonInvalidBuildResultMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the buildResult map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: _sampleResultJsonInvalidIssuesMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the issues map.');
  });
}

const String _sampleResultJsonInvalidIssuesMap = r'''
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
        "buildResult": {
        }
      }
    ]
  }
}
''';

const String _sampleResultJsonInvalidBuildResultMap = r'''
{
  "_type" : {
    "_name" : "ActionsInvocationRecord"
  },
  "actions" : {
    "_type" : {
      "_name" : "Array"
    },
    "_values" : [
      {}
    ]
  }
}
''';

const String _sampleResultJsonInvalidActionMap = r'''
{
  "_type" : {
    "_name" : "ActionsInvocationRecord"
  },
  "actions" : {
    "_type" : {
      "_name" : "Array"
    },
    "_values" : [
      []
    ]
  }
}
''';

const String _sampleResultJsonEmptyActionsMap = r'''
{
  "_type" : {
    "_name" : "ActionsInvocationRecord"
  },
  "actions" : {
    "_type" : {
      "_name" : "Array"
    },
    "_values" : [
    ]
  }
}
''';

const String _sampleResultJsonWithIssues = r'''
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
            }
          },
          "issues" : {
            "_type" : {
              "_name" : "ResultIssueSummaries"
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
            "_value" : "action"
          },
          "status" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "notRequested"
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
            },
            "errorSummaries" : {
              "_type" : {
                "_name" : "Array"
              },
              "_values" : [
                {
                  "_type" : {
                    "_name" : "IssueSummary"
                  },
                  "documentLocationInCreatingWorkspace" : {
                    "_type" : {
                      "_name" : "DocumentLocation"
                    },
                    "concreteTypeName" : {
                      "_type" : {
                        "_name" : "String"
                      },
                      "_value" : "DVTTextDocumentLocation"
                    },
                    "url" : {
                      "_type" : {
                        "_name" : "String"
                      },
                      "_value" : "file:\/\/\/Users\/m\/Projects\/test_create\/ios\/Runner\/AppDelegate.m#CharacterRangeLen=0&CharacterRangeLoc=263&EndingColumnNumber=56&EndingLineNumber=7&LocationEncoding=1&StartingColumnNumber=56&StartingLineNumber=7"
                    }
                  },
                  "issueType" : {
                    "_type" : {
                      "_name" : "String"
                    },
                    "_value" : "Semantic Issue"
                  },
                  "message" : {
                    "_type" : {
                      "_name" : "String"
                    },
                    "_value" : "Use of undeclared identifier 'asdas'"
                  }
                }
              ]
            },
            "warningSummaries" : {
              "_type" : {
                "_name" : "Array"
              },
              "_values" : [
                {
                  "_type" : {
                    "_name" : "IssueSummary"
                  },
                  "issueType" : {
                    "_type" : {
                      "_name" : "String"
                    },
                    "_value" : "Warning"
                  },
                  "message" : {
                    "_type" : {
                      "_name" : "String"
                    },
                    "_value" : "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99."
                  }
                }
              ]
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
              "_value" : "0~bjiFq9EH53z6VfWSr47dakT0w_aGcY_GFqgPuexHq1JsoKMmvf_6GLglMcWBYRCSNufKEX6l1YgbFmnuobsw5w=="
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
            "errorCount" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "1"
            },
            "warningCount" : {
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
            "_value" : "build"
          },
          "status" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "failed"
          }
        },
        "endedTime" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2020-09-28T14:31:16.931-0700"
        },
        "runDestination" : {
          "_type" : {
            "_name" : "ActionRunDestinationRecord"
          },
          "displayName" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Any iOS Device"
          },
          "localComputerRecord" : {
            "_type" : {
              "_name" : "ActionDeviceRecord"
            },
            "busSpeedInMHz" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "100"
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
              "_value" : "8-Core Intel Xeon W"
            },
            "cpuSpeedInMHz" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "3200"
            },
            "identifier" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "87BE7059-56E3-5470-B52D-31A0F76402B3"
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
              "_value" : "16"
            },
            "modelCode" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "iMacPro1,1"
            },
            "modelName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "iMac Pro"
            },
            "modelUTI" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "com.apple.imacpro-2017"
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
              "_value" : "x86_64h"
            },
            "operatingSystemVersion" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "10.15.5"
            },
            "operatingSystemVersionWithBuildNumber" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "10.15.5 (19F101)"
            },
            "physicalCPUCoresPerPackage" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "8"
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
              "_value" : "65536"
            }
          },
          "targetArchitecture" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "arm64e"
          },
          "targetDeviceRecord" : {
            "_type" : {
              "_name" : "ActionDeviceRecord"
            },
            "identifier" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder"
            },
            "modelCode" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "GenericiOS"
            },
            "modelName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "GenericiOS"
            },
            "modelUTI" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "com.apple.dt.Xcode.device.GenericiOS"
            },
            "name" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "Any iOS Device"
            },
            "nativeArchitecture" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "arm64e"
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
              "_value" : "iphoneos14.0"
            },
            "name" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "iOS 14.0"
            },
            "operatingSystemVersion" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "14.0"
            }
          }
        },
        "schemeCommandName" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Run"
        },
        "schemeTaskName" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Build"
        },
        "startedTime" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2020-09-28T14:31:13.125-0700"
        },
        "title" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Build \"Runner\""
        }
      }
    ]
  },
  "issues" : {
    "_type" : {
      "_name" : "ResultIssueSummaries"
    },
    "errorSummaries" : {
      "_type" : {
        "_name" : "Array"
      },
      "_values" : [
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "documentLocationInCreatingWorkspace" : {
            "_type" : {
              "_name" : "DocumentLocation"
            },
            "concreteTypeName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "DVTTextDocumentLocation"
            },
            "url" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "file:\/\/\/Users\/m\/Projects\/test_create\/ios\/Runner\/AppDelegate.m#CharacterRangeLen=0&CharacterRangeLoc=263&EndingColumnNumber=56&EndingLineNumber=7&LocationEncoding=1&StartingColumnNumber=56&StartingLineNumber=7"
            }
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Semantic Issue"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Use of undeclared identifier 'asdas'"
          }
        }
      ]
    },
    "warningSummaries" : {
      "_type" : {
        "_name" : "Array"
      },
      "_values" : [
        {
          "_type" : {
            "_name" : "IssueSummary"
          },
          "issueType" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Warning"
          },
          "message" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99."
          }
        }
      ]
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
      "_value" : "0~hrKQOFMo2Ri-TrlvSpVK8vTHcYQxwuWYJuRHCjoxIleliOdh5fHOdfIALZV0S0FtjVmUB83FpKkPbWajga4wxA=="
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
    "errorCount" : {
      "_type" : {
        "_name" : "Int"
      },
      "_value" : "1"
    },
    "warningCount" : {
      "_type" : {
        "_name" : "Int"
      },
      "_value" : "1"
    }
  }
}
''';

const String _sampleResultJsonNoIssues = r'''
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
            }
          },
          "issues" : {
            "_type" : {
              "_name" : "ResultIssueSummaries"
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
            "_value" : "action"
          },
          "status" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "notRequested"
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
              "_value" : "0~XBP6QfgBACcao7crWD8_8W18SPIqMzlK0U0oBhSvElOM8k-vQKO4ZmCtUhL-BfTDFSylC3qEPStUI3jNsBPTXA=="
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
          "_value" : "2021-10-27T13:13:38.875-0700"
        },
        "runDestination" : {
          "_type" : {
            "_name" : "ActionRunDestinationRecord"
          },
          "displayName" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "Any iOS Device"
          },
          "localComputerRecord" : {
            "_type" : {
              "_name" : "ActionDeviceRecord"
            },
            "busSpeedInMHz" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "100"
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
              "_value" : "12-Core Intel Xeon E5"
            },
            "cpuSpeedInMHz" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "2700"
            },
            "identifier" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "2BE58010-D352-540B-92E6-9A945BA6D36D"
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
              "_value" : "24"
            },
            "modelCode" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "MacPro6,1"
            },
            "modelName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "Mac Pro"
            },
            "modelUTI" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "com.apple.macpro-cylinder"
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
              "_value" : "x86_64"
            },
            "operatingSystemVersion" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "11.6"
            },
            "operatingSystemVersionWithBuildNumber" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "11.6 (20G165)"
            },
            "physicalCPUCoresPerPackage" : {
              "_type" : {
                "_name" : "Int"
              },
              "_value" : "12"
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
              "_value" : "65536"
            }
          },
          "targetArchitecture" : {
            "_type" : {
              "_name" : "String"
            },
            "_value" : "arm64e"
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
              "_value" : "dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder"
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
              "_value" : "GenericiOS"
            },
            "modelName" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "GenericiOS"
            },
            "modelUTI" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "com.apple.dt.Xcode.device.GenericiOS"
            },
            "name" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "Any iOS Device"
            },
            "nativeArchitecture" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "arm64e"
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
              "_value" : "iphoneos15.0"
            },
            "name" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "iOS 15.0"
            },
            "operatingSystemVersion" : {
              "_type" : {
                "_name" : "String"
              },
              "_value" : "15.0"
            }
          }
        },
        "schemeCommandName" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Run"
        },
        "schemeTaskName" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Build"
        },
        "startedTime" : {
          "_type" : {
            "_name" : "Date"
          },
          "_value" : "2021-10-27T13:13:02.396-0700"
        },
        "title" : {
          "_type" : {
            "_name" : "String"
          },
          "_value" : "Build \"XCResultTestApp\""
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
      "_value" : "0~4PY3oMxYEC19JHgIcIfOFnFe-ngUSzJD4NzcBevC8Y2-5y41lCyXxYXhi9eObvKdlU14arnDn8ilaTw6B_bbQQ=="
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
    }
  }
}

''';

const String _tempResultPath = 'temp';

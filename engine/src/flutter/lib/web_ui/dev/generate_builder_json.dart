// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'felt_config.dart';

String generateBuilderJson(FeltConfig config) {
  final Map<String, dynamic> outputJson = <String, dynamic>{
    'builds': <dynamic>[
      _getArtifactBuildStep(),
      for (final TestBundle bundle in config.testBundles)
        _getBundleBuildStep(bundle),
    ],
    'tests': _getAllTestSteps(config.testSuites)
  };
  return const JsonEncoder.withIndent('  ').convert(outputJson);
}

Map<String, dynamic> _getArtifactBuildStep() {
  return <String, dynamic>{
    'name': 'web_tests/artifacts',
    'drone_dimensions': <String>[
      'device_type=none',
      'os=Linux',
      'cores=32'
    ],
    'gclient_variables': <String, dynamic>{
      'download_android_deps': false,
      'download_emsdk': true,
    },
    'gn': <String>[
      '--web',
      '--runtime-mode=release',
      '--no-goma',
    ],
    'ninja': <String, dynamic>{
      'config': 'wasm_release',
      'targets': <String>[
        'flutter/web_sdk:flutter_web_sdk_archive'
      ]
    },
    'archives': <dynamic>[
      <String, dynamic>{
        'name': 'wasm_release',
        'base_path': 'out/wasm_release/zip_archives/',
        'type': 'gcs',
        'include_paths': <String>[
          'out/wasm_release/zip_archives/flutter-web-sdk.zip'
        ],
        'realm': 'production',
      }
    ],
    'generators': <String, dynamic>{
      'tasks': <dynamic>[
        <String, dynamic>{
          'name': 'check licenses',
          'parameters': <String>[
            'check-licenses'
          ],
          'scripts': <String>[ 'flutter/lib/web_ui/dev/felt' ],

        },
        <String, dynamic>{
          'name': 'web engine analysis',
          'parameters': <String>[
            'analyze'
          ],
          'scripts': <String>[ 'flutter/lib/web_ui/dev/felt' ],
        },
        <String, dynamic>{
          'name': 'copy artifacts for web tests',
          'parameters': <String>[
            'test',
            '--copy-artifacts',
          ],
          'scripts': <String>[ 'flutter/lib/web_ui/dev/felt' ],
        },
      ]
    },
  };
}

Map<String, dynamic> _getBundleBuildStep(TestBundle bundle) {
  return <String, dynamic>{
    'name': 'web_tests/test_bundles/${bundle.name}',
    'drone_dimensions': <String>[
      'device_type=none',
      'os=Linux',
      'cores=32',
    ],
    'generators': <String, dynamic>{
      'tasks': <dynamic>[
        <String, dynamic>{
          'name': 'compile bundle ${bundle.name}',
          'parameters': <String>[
            'test',
            '--compile',
            '--bundle=${bundle.name}',
          ],
          'scripts': <String>[ 'flutter/lib/web_ui/dev/felt' ],
        }
      ]
    },
  };
}

Iterable<dynamic> _getAllTestSteps(List<TestSuite> suites) {
  return <dynamic>[
    ..._getTestStepsForPlatform(suites, 'Linux', <BrowserName>{
      BrowserName.chrome,
      BrowserName.firefox,
    }),
    ..._getTestStepsForPlatform(suites, 'Mac', <BrowserName>{
      BrowserName.safari,
    }),
    ..._getTestStepsForPlatform(suites, 'Windows', <BrowserName>{
      BrowserName.chrome,
    }),
  ];
}

Iterable<dynamic> _getTestStepsForPlatform(
  List<TestSuite> suites,
  String platform,
  Set<BrowserName> browsers) {
  return suites
    .where((TestSuite suite) => browsers.contains(suite.runConfig.browser))
    .map((TestSuite suite) => <String, dynamic>{
        'name': '$platform run ${suite.name} suite',
        'recipe': 'engine_v2/tester_engine',
        'drone_dimensions': <String>[
          'device_type=none',
          'os=$platform',
        ],
        'gclient_variables': <String, dynamic>{
          'download_android_deps': false,
        },
        'dependencies': <String>[
          'web_tests/artifacts',
          'web_tests/test_bundles/${suite.testBundle.name}',
        ],
        'test_dependencies': <dynamic>[
          <String, dynamic>{
            'dependency': 'goldctl',
            'version': 'git_revision:3a77d0b12c697a840ca0c7705208e8622dc94603',
          },
          if (suite.runConfig.browser == BrowserName.chrome)
            <String, dynamic>{
              'dependency': 'chrome_and_driver',
              'version': 'version:111.0',
            },
          if (suite.runConfig.browser == BrowserName.firefox)
            <String, dynamic>{
              'dependency': 'firefox',
              'version': 'version:106.0',
            }
        ],
        'tasks': <dynamic>[
          <String, dynamic>{
            'name': 'run suite ${suite.name}',
            'parameters': <String>[
              'test',
              '--run',
              '--suite=${suite.name}'
            ],
            'script': 'flutter/lib/web_ui/dev/felt',
          }
        ]
      }
    );
}

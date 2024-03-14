// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String testConfig(String os) => '''
{
  "builds": [
    {
      "archives": [
        {
          "name": "build_name",
          "base_path": "base/path",
          "type": "gcs",
          "include_paths": ["include/path"],
          "realm": "archive_realm"
        }
      ],
      "drone_dimensions": [
        "os=$os"
      ],
      "gclient_variables": {
        "variable": false
      },
      "gn": ["--gn-arg", "--lto", "--goma", "--no-rbe"],
      "name": "build_name",
      "ninja": {
        "config": "build_name",
        "targets": ["ninja_target"]
      },
      "tests": [
        {
          "language": "python3",
          "name": "build_name tests",
          "parameters": ["--test-params"],
          "script": "test/script.py",
          "contexts": ["context"]
        }
      ],
      "generators": {
        "tasks": [
          {
            "name": "generator_task",
            "language": "python",
            "parameters": ["--gen-param"],
            "scripts": ["gen/script.py"]
          }
        ]
      }
    },
    {},
    {},
    {
      "drone_dimensions": [
        "os=$os"
      ],
      "gn": ["--gn-arg", "--lto", "--goma", "--no-rbe"],
      "name": "host_debug",
      "ninja": {
        "config": "host_debug",
        "targets": ["ninja_target"]
      }
    },
    {
      "drone_dimensions": [
        "os=$os"
      ],
      "gn": ["--gn-arg", "--lto", "--goma", "--no-rbe"],
      "name": "android_debug_arm64",
      "ninja": {
        "config": "android_debug_arm64",
        "targets": ["ninja_target"]
      }
    },
    {
      "drone_dimensions": [
        "os=$os"
      ],
      "gn": ["--gn-arg", "--lto", "--no-goma", "--rbe"],
      "name": "android_debug_rbe_arm64",
      "ninja": {
        "config": "android_debug_rbe_arm64",
        "targets": ["ninja_target"]
      }
    }
  ],
  "generators": {
    "tasks": [
      {
        "name": "global generator task",
        "parameters": ["--global-gen-param"],
        "script": "global/gen_script.dart",
        "language": "dart"
      }
    ]
  },
  "tests": [
    {
      "name": "global test",
      "recipe": "engine_v2/tester_engine",
      "drone_dimensions": [
        "os=$os"
      ],
      "gclient_variables": {
        "variable": false
      },
      "dependencies": ["dependency"],
      "test_dependencies": [
        {
          "dependency": "test_dependency",
          "version": "git_revision:3a77d0b12c697a840ca0c7705208e8622dc94603"
        }
      ],
      "tasks": [
        {
          "name": "global test task",
          "parameters": ["--test-parameter"],
          "script": "global/test/script.py"
        }
      ]
    }
  ]
}
''';

String attachedDevices() => '''
[
  {
    "name": "sdk gphone64 arm64",
    "id": "emulator-5554",
    "isSupported": true,
    "targetPlatform": "android-arm64",
    "emulator": true,
    "sdk": "Android 14 (API 34)",
    "capabilities": {
      "hotReload": true,
      "hotRestart": true,
      "screenshot": true,
      "fastStart": true,
      "flutterExit": true,
      "hardwareRendering": true,
      "startPaused": true
    }
  },
  {
    "name": "macOS",
    "id": "macos",
    "isSupported": true,
    "targetPlatform": "darwin",
    "emulator": false,
    "sdk": "macOS 14.3.1 23D60 darwin-arm64",
    "capabilities": {
      "hotReload": true,
      "hotRestart": true,
      "screenshot": false,
      "fastStart": false,
      "flutterExit": true,
      "hardwareRendering": false,
      "startPaused": true
    }
  },
  {
    "name": "Mac Designed for iPad",
    "id": "mac-designed-for-ipad",
    "isSupported": true,
    "targetPlatform": "darwin",
    "emulator": false,
    "sdk": "macOS 14.3.1 23D60 darwin-arm64",
    "capabilities": {
      "hotReload": true,
      "hotRestart": true,
      "screenshot": false,
      "fastStart": false,
      "flutterExit": true,
      "hardwareRendering": false,
      "startPaused": true
    }
  },
  {
    "name": "Chrome",
    "id": "chrome",
    "isSupported": true,
    "targetPlatform": "web-javascript",
    "emulator": false,
    "sdk": "Google Chrome 122.0.6261.94",
    "capabilities": {
      "hotReload": true,
      "hotRestart": true,
      "screenshot": false,
      "fastStart": false,
      "flutterExit": false,
      "hardwareRendering": false,
      "startPaused": true
    }
  }
]
''';

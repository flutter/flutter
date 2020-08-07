// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// JSON template for the contents of the auth_opt.json file created by goldctl.
String authTemplate({
  bool gsutil = false,
}) {
  return '''
    {
      "Luci":false,
      "ServiceAccount":"${gsutil ? '' : '/packages/flutter/test/widgets/serviceAccount.json'}",
      "GSUtil":$gsutil
    }
  ''';
}

/// JSON response template for Skia Gold expectations request:
/// https://flutter-gold.skia.org/json/expectations/commit/HEAD
String rawExpectationsTemplate() {
  return '''
    {
      "md5": "a7489b00e03a1846e43500b7c14dd7b0",
      "master": {
        "flutter.golden_test.1": {
          "55109a4bed52acc780530f7a9aeff6c0": 1
        },
        "flutter.golden_test.3": {
          "87cb35131e6ad4b57d4d09d59ae743c3": 1,
          "dc94eb2c39c0c8ae11a4efd090b72f94": 1,
          "f2583c9003978a06b7888878bdc089e2": 1
        },
        "flutter.golden_test.2": {
          "eb03a5e3114c9ecad5e4f1178f285a49": 1,
          "f14631979de24fca6e14ad247d5f2bd6": 1
        }
      }
    }
  ''';
}

/// Decoded json response template for Skia Gold expectations request:
/// https://flutter-gold.skia.org/json/expectations/commit/HEAD
Map<String, List<String>> expectationsTemplate() {
  return <String, List<String>>{
    'flutter.golden_test.1': <String>[
      '55109a4bed52acc780530f7a9aeff6c0'
    ],
    'flutter.golden_test.3': <String>[
      '87cb35131e6ad4b57d4d09d59ae743c3',
      'dc94eb2c39c0c8ae11a4efd090b72f94',
      'f2583c9003978a06b7888878bdc089e2',
    ],
    'flutter.golden_test.2': <String>[
      'eb03a5e3114c9ecad5e4f1178f285a49',
      'f14631979de24fca6e14ad247d5f2bd6',
    ],
  };
}

/// Same as [rawExpectationsTemplate] but with the temporary key.
String rawExpectationsTemplateWithTemporaryKey() {
  return '''
    {
      "md5": "a7489b00e03a1846e43500b7c14dd7b0",
      "master_str": {
        "flutter.golden_test.1": {
          "55109a4bed52acc780530f7a9aeff6c0": 1
        },
        "flutter.golden_test.3": {
          "87cb35131e6ad4b57d4d09d59ae743c3": 1,
          "dc94eb2c39c0c8ae11a4efd090b72f94": 1,
          "f2583c9003978a06b7888878bdc089e2": 1
        },
        "flutter.golden_test.2": {
          "eb03a5e3114c9ecad5e4f1178f285a49": 1,
          "f14631979de24fca6e14ad247d5f2bd6": 1
        }
      }
    }
  ''';
}

/// Json response template for Skia Gold digest request:
/// https://flutter-gold.skia.org/json/details?test=[testName]&digest=[expectation]
String digestResponseTemplate({
  String testName = 'flutter.golden_test.1',
  String expectation = '55109a4bed52acc780530f7a9aeff6c0',
  String platform = 'macos',
  String status = 'positive',
}) {
  return '''
    {
  "digest": {
    "test": "$testName",
    "digest": "$expectation",
    "status": "$status",
    "paramset": {
      "Platform": [
        "$platform"
      ],
      "ext": [
        "png"
      ],
      "name": [
        "$testName"
      ],
      "source_type": [
        "flutter"
      ]
    },
    "traces": {
      "tileSize": 200,
      "traces": [
        {
          "data": [
            {
              "x": 0,
              "y": 0,
              "s": 0
            },
            {
              "x": 1,
              "y": 0,
              "s": 0
            },
            {
              "x": 199,
              "y": 0,
              "s": 0
            }
          ],
          "label": ",Platform=$platform,name=$testName,source_type=flutter,",
          "params": {
            "Platform": "$platform",
            "ext": "png",
            "name": "$testName",
            "source_type": "flutter"
          }
        }
      ],
      "digests": [
        {
          "digest": "$expectation",
          "status": "$status"
        }
      ]
    },
    "closestRef": "pos",
    "refDiffs": {
      "neg": null,
      "pos": {
        "numDiffPixels": 999,
        "pixelDiffPercent": 0.4995,
        "maxRGBADiffs": [
          86,
          86,
          86,
          0
        ],
        "dimDiffer": false,
        "diffs": {
          "combined": 0.381955,
          "percent": 0.4995,
          "pixel": 999
        },
        "digest": "aa748136c70cefdda646df5be0ae189d",
        "status": "positive",
        "paramset": {
          "Platform": [
            "macos"
          ],
          "ext": [
            "png"
          ],
          "name": [
            "$testName"
          ],
          "source_type": [
            "flutter"
          ]
        },
        "n": 197
      }
    }
  },
  "commits": [
    {
      "commit_time": 1568069344,
      "hash": "399bb04e2de41665320d3c888f40af6d8bc734a2",
      "author": "Contributor A (contributorA@getMail.com)"
    },
    {
      "commit_time": 1568078053,
      "hash": "0f365d3add253a65e5e5af1024f56c6169bf9739",
      "author": "Contributor B (contributorB@getMail.com)"
    },
    {
      "commit_time": 1569353925,
      "hash": "81e693a7fe3b808cc9ae2bb3a2cbe404e67ec773",
      "author": "Contributor C (contributorC@getMail.com)"
    }
  ]
}
  ''';
}

/// Json response template for Skia Gold ignore request:
/// https://flutter-gold.skia.org/json/ignores
String ignoreResponseTemplate({
  String pullRequestNumber = '0000',
  String testName = 'flutter.golden_test.1',
  String otherTestName = 'flutter.golden_test.1',
  String expires = '2019-09-06T21:28:18.815336Z',
  String otherExpires = '2019-09-06T21:28:18.815336Z',
}) {
  return '''
    [
      {
        "id": "7579425228619212078",
        "name": "contributor@getMail.com",
        "updatedBy": "contributor@getMail.com",
        "expires": "$expires",
        "query": "ext=png&name=$testName",
        "note": "https://github.com/flutter/flutter/pull/$pullRequestNumber"
      },
      {
        "id": "7579425228619212078",
        "name": "contributor@getMail.com",
        "updatedBy": "contributor@getMail.com",
        "expires": "$otherExpires",
        "query": "ext=png&name=$otherTestName",
        "note": "https://github.com/flutter/flutter/pull/99999"
      }
    ]
  ''';
}

/// Json response template for Skia Gold image request:
/// https://flutter-gold.skia.org/img/images/[imageHash].png
List<List<int>> imageResponseTemplate() {
  return <List<int>>[
    <int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73,
      72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0],
    <int>[0, 0, 11, 73, 68, 65, 84, 120, 1, 99, 97, 0, 2, 0,
      0, 25, 0, 5, 144, 240, 54, 245, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96,
      130],
  ];
}

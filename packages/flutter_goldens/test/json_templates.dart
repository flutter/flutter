// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Json respones template for Skia Gold digest request
String digestResponseTemplate({
  bool includeExtraDigests = false,
  bool returnEmptyDigest = false,
  String testName = 'flutter.golden_test.1',
}) {
  return '''{
    "digests": [${returnEmptyDigest ? '' : '''
      {
        "test": "$testName",
        "digest": "88e2cc3398bd55b55df35cfe14d557c1",
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
                  "x": 2,
                  "y": 0,
                  "s": 0
                },
                {
                  "x": 3,
                  "y": 0,
                  "s": 0
                }
              ],
              "label": ",Platform=macos,name=$testName,source_type=flutter,",
              "params": {
                "Platform": "macos",
                "ext": "png",
                "name": "$testName",
                "source_type": "flutter"
              }
            }
          ],
          "digests": [
            {
              "digest": "88e2cc3398bd55b55df35cfe14d557c1",
              "status": "positive"
            }
          ]
        },
        "closestRef": "pos",
        "refDiffs": {
          "neg": null,
          "pos": {
            "numDiffPixels": 541,
            "pixelDiffPercent": 4.663793,
            "maxRGBADiffs": [
              0,
              128,
              255,
              112
            ],
            "dimDiffer": false,
            "diffs": {
              "combined": 1.6742188,
              "percent": 4.663793,
              "pixel": 541
            },
            "digest": "e4ac039c7b3112d7dada8e7c0a4e0501",
            "status": "positive",
            "paramset": {
              "Platform": [
                "windows"
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
            "n": 191
          }
        }
      }${includeExtraDigests ? ''',
      {
        "test": "$testName",
        "digest": "88e2cc3398bd55b55df35cfe14d557c1",
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
        "traces": {
          "tileSize": 200,
          "traces": [
            {
              "data": [
                {
                  "x": 0,
                  "y": 0,
                  "s": 0
                }
              ],
              "label": ",Platform=macos,name=$testName,source_type=flutter,",
              "params": {
                "Platform": "macos",
                "ext": "png",
                "name": "$testName",
                "source_type": "flutter"
              }
            }
          ],
          "digests": [
            {
              "digest": "88e2cc3398bd55b55df35cfe14d557c1",
              "status": "positive"
            }
          ]
        },
        "closestRef": "pos",
        "refDiffs": {
          "neg": null,
          "pos": {
            "numDiffPixels": 541,
            "pixelDiffPercent": 4.663793,
            "maxRGBADiffs": [
              0,
              128,
              255,
              112
            ],
            "dimDiffer": false,
            "diffs": {
              "combined": 1.6742188,
              "percent": 4.663793,
              "pixel": 541
            },
            "digest": "e4ac039c7b3112d7dada8e7c0a4e0501",
            "status": "positive",
            "paramset": {
              "Platform": [
                "windows"
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
            "n": 191
          }
        }
      }
      ''' : ''} '''}
    ],
    "offset": 0,
    "size": 1,
    "commits": [
      {
        "commit_time": 1567412442,
        "hash": "2b7e59b9c0267d3f90ddd8b2cb10c1431c79137d",
        "author": "engine-flutter-autoroll (engine-flutter-autoroll@skia.org)"
      },
      {
        "commit_time": 1567418861,
        "hash": "ec1ea2b38ab1773f2c412e303a8cda0792a980ca",
        "author": "engine-flutter-autoroll (engine-flutter-autoroll@skia.org)"
      },
      {
        "commit_time": 1567434521,
        "hash": "d30e4228afd633e4f6d2ed217a926e8983161379",
        "author": "engine-flutter-autoroll (engine-flutter-autoroll@skia.org)"
      }
    ],
    "issue": null
  }''';
}

/// Json response template for Skia Gold ignore request
String ignoreResponseTemplate({
  String pullRequestNumber = '0000',
  String testName = 'flutter.golden_test.1',
}) {
  return '''
    [
      {
        "id": "7579425228619212078",
        "name": "contributor@getMail.com",
        "updatedBy": "contributor@getMail.com",
        "expires": "2019-09-06T21:28:18.815336Z",
        "query": "ext=png&name=$testName",
        "note": "https://github.com/flutter/flutter/pull/$pullRequestNumber"
      }
    ]
  ''';
}

/// Json response template for Skia Gold image request
List<List<int>> imageResponseTemplate() {
  return <List<int>>[
    <int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73,
      72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0],
    <int>[0, 0, 11, 73, 68, 65, 84, 120, 1, 99, 97, 0, 2, 0,
      0, 25, 0, 5, 144, 240, 54, 245, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96,
      130],
  ];
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/sdk/allowed_experiments.dart';
import 'package:test/test.dart';

main() {
  group('invalid', () {
    void assertFormalException(String text) {
      expect(() {
        return parseAllowedExperiments(text);
      }, throwsFormatException);
    }

    test('not map', () {
      assertFormalException('42');
    });

    test('no version', () {
      assertFormalException('{}');
    });

    test('version not int', () {
      assertFormalException('''
{
  "version": "abc"
}
''');
    });

    test('version not int 1', () {
      assertFormalException('''
{
  "version": 2
}
''');
    });

    test('no experiment sets', () {
      assertFormalException('''
{
  "version": 1,
}
''');
    });

    test('experimentSet: not map', () {
      assertFormalException('''
{
  "version": 1,
  "experimentSets": 42
}
''');
    });

    test('experimentSet entry: not list', () {
      assertFormalException('''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": 42
  }
}
''');
    });

    test('no sdk', () {
      assertFormalException('''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  }
}
''');
    });

    test('no sdk / default', () {
      assertFormalException('''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  },
  "sdk": {}
}
''');
    });

    test('experimentSet not string', () {
      assertFormalException('''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  },
  "sdk": {
    "default": {
      "experimentSet": 42
    }
  }
}
''');
    });

    test('experimentSet not defined', () {
      assertFormalException('''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  },
  "sdk": {
    "default": {
      "experimentSet": "notDefined"
    }
  }
}
''');
    });

    test('sdk libraries not map', () {
      assertFormalException('''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  },
  "sdk": {
    "default": {
      "experimentSet": "nullSafety"
    },
    "libraries": 42
  }
}
''');
    });

    test('packages not map', () {
      assertFormalException('''
{
  "version": 1,
  "experimentSets": {
    "nullSafety": ["non-nullable"]
  },
  "sdk": {
    "default": {
      "experimentSet": "nullSafety"
    }
  },
  "packages": 42
}
''');
    });
  });

  group('valid', () {
    void assertExperiments(
      AllowedExperiments experiments, {
      required List<String> sdkDefaultExperiments,
      required Map<String, List<String>> sdkLibraryExperiments,
      required Map<String, List<String>> packageExperiments,
    }) {
      expect(experiments.sdkDefaultExperiments, sdkDefaultExperiments);
      expect(experiments.sdkLibraryExperiments, sdkLibraryExperiments);
      expect(experiments.packageExperiments, packageExperiments);
    }

    test('sdk default, no sdk libraries, no packages', () {
      var experiments = parseAllowedExperiments('''
{
  "version": 1,
  "experimentSets": {
    "foo": ["foo1"]
  },
  "sdk": {
    "default": {
      "experimentSet": "foo"
    }
  }
}
''');
      assertExperiments(
        experiments,
        sdkDefaultExperiments: ['foo1'],
        sdkLibraryExperiments: {},
        packageExperiments: {},
      );
    });

    test('sdk default, sdk libraries, no packages', () {
      var experiments = parseAllowedExperiments('''
{
  "version": 1,
  "experimentSets": {
    "foo": ["foo1"],
    "bar": ["bar1", "bar2"]
  },
  "sdk": {
    "default": {
      "experimentSet": "foo"
    },
    "libraries": {
      "sdkA": {
        "experimentSet": "foo"
      },
      "sdkB": {
        "experimentSet": "bar"
      }
    }
  }
}
''');
      assertExperiments(
        experiments,
        sdkDefaultExperiments: ['foo1'],
        sdkLibraryExperiments: {
          "sdkA": ['foo1'],
          "sdkB": ['bar1', 'bar2'],
        },
        packageExperiments: {},
      );
    });

    test('sdk default, sdk libraries, packages', () {
      var experiments = parseAllowedExperiments('''
{
  "version": 1,
  "experimentSets": {
    "foo": ["foo1"],
    "bar": ["bar1", "bar2"],
    "baz": ["baz1", "baz2"]
  },
  "sdk": {
    "default": {
      "experimentSet": "foo"
    },
    "libraries": {
      "sdkA": {
        "experimentSet": "bar"
      },
      "sdkB": {
        "experimentSet": "baz"
      }
    }
  },
  "packages": {
    "pkgA": {
      "experimentSet": "bar"
    },
    "pkgB": {
      "experimentSet": "baz"
    }
  }
}
''');
      assertExperiments(
        experiments,
        sdkDefaultExperiments: ['foo1'],
        sdkLibraryExperiments: {
          "sdkA": ['bar1', 'bar2'],
          "sdkB": ['baz1', 'baz2'],
        },
        packageExperiments: {
          "pkgA": ['bar1', 'bar2'],
          "pkgB": ['baz1', 'baz2'],
        },
      );
      expect(experiments.forSdkLibrary('core'), ['foo1']);
      expect(experiments.forSdkLibrary('sdkA'), ['bar1', 'bar2']);
      expect(experiments.forSdkLibrary('sdkB'), ['baz1', 'baz2']);
      expect(experiments.forPackage('pkgA'), ['bar1', 'bar2']);
      expect(experiments.forPackage('pkgB'), ['baz1', 'baz2']);
      expect(experiments.forPackage('pkgC'), isNull);
    });
  });
}

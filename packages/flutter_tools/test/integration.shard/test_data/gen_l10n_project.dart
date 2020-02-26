// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../test_utils.dart';
import 'project.dart';

class GenL10nProject extends Project {
  @override
  Future<void> setUpIn(Directory dir) {
    this.dir = dir;
    writeFile(globals.fs.path.join(dir.path, 'lib', 'l10n', 'app_en.arb'), appEn);
    writeFile(globals.fs.path.join(dir.path, 'lib', 'l10n', 'app_en_CA.arb'), appEnCa);
    writeFile(globals.fs.path.join(dir.path, 'lib', 'l10n', 'app_en_GB.arb'), appEnGb);
    return super.setUpIn(dir);
  }

  @override
  final String pubspec = '''
name: test
environment:
  sdk: ">=2.0.0-dev.68.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: 0.16.1
  intl_translation: 0.17.8
''';

  @override
  final String main = r'''
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class LocaleBuilder extends StatelessWidget {
  const LocaleBuilder({ Key key, this.locale, this.callback }) : super(key: key);
  final Locale locale;
  final void Function (BuildContext context) callback;
  @override build(BuildContext context) {
    return Localizations.override(
      locale: locale,
      context: context,
      child: Builder(
        builder: (BuildContext context) {
          callback(context);
          return Container();
        },
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> results = [];
    return Row(
      children: <Widget>[
        LocaleBuilder(
          locale: Locale('en', 'CA'),
          callback: (BuildContext context) {
            results.add(AppLocalizations.of(context).helloWorld);
            results.add(AppLocalizations.of(context).hello("CA fallback World"));
          },
        ),
        LocaleBuilder(
          locale: Locale('en', 'GB'),
          callback: (BuildContext context) {
            results.add(AppLocalizations.of(context).helloWorld);
            results.add(AppLocalizations.of(context).hello("GB fallback World"));
          },
        ),
        LocaleBuilder(
          locale: Locale('en'),
          callback: (BuildContext context) {
            int n = 0;
            try {
              final AppLocalizations localizations = AppLocalizations.of(context);
              results.addAll(<String>[
                '${localizations.helloWorld}',
                '${localizations.hello("World")}',
                '${localizations.greeting("Hello", "World")}',
                '${localizations.helloWorldOn(DateTime(1960))}',
                '${localizations.helloOn("world argument", DateTime(1960), DateTime(1960))}',
                '${localizations.helloWorldDuring(DateTime(1960), DateTime(2020))}',
                '${localizations.helloFor(123)}',
                '${localizations.helloCost("price", 123)}',
                '${localizations.helloWorlds(0)}',
                '${localizations.helloWorlds(1)}',
                '${localizations.helloWorlds(2)}',
                '${localizations.helloAdjectiveWorlds(0, "new")}',
                '${localizations.helloAdjectiveWorlds(1, "new")}',
                '${localizations.helloAdjectiveWorlds(2, "new")}',
                '${localizations.helloWorldsOn(0, DateTime(1960))}',
                '${localizations.helloWorldsOn(1, DateTime(1960))}',
                '${localizations.helloWorldsOn(2, DateTime(1960))}',
                '${localizations.helloWorldPopulation(0, 100)}',
                '${localizations.helloWorldPopulation(1, 101)}',
                '${localizations.helloWorldPopulation(2, 102)}',
                '${localizations.helloWorldsInterpolation(123, "Hello", "World")}',
              ]);
              for (final String result in results) {
                print('#l10n $n ($result)\n');
                n += 1;
              }
            }
            finally {
              print('#l10n END\n');
            }
          },
        ),
      ],
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Home(),
    ),
  );
}
''';

  final String appEn = r'''
{
  "@@locale": "en",

  "helloWorld": "Hello World",
  "@helloWorld": {
    "description": "The conventional newborn programmer greeting"
  },

  "hello": "Hello {world}",
  "@hello": {
    "description": "A message with a single parameter",
    "placeholders": {
      "world": {}
    }
  },

  "greeting": "{hello} {world}",
  "@greeting": {
    "description": "A message with a two parameters",
    "placeholders": {
      "hello": {},
      "world": {}
    }
  },

  "helloWorldOn": "Hello World on {date}",
  "@helloWorldOn": {
    "description": "A message with a date parameter",
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "yMMMMEEEEd"
      }
    }
  },

  "helloWorldDuring": "Hello World from {startDate} to {endDate}",
  "@helloWorldDuring": {
    "description": "A message with two date parameters",
    "placeholders": {
      "startDate": {
        "type": "DateTime",
        "format": "y"
      },
      "endDate": {
        "type": "DateTime",
        "format": "y"
      }
    }
  },

  "helloOn": "Hello {world} on {date} at {time}",
  "@helloOn": {
    "description": "A message with date and string parameters",
    "placeholders": {
      "world": {
      },
      "date": {
        "type": "DateTime",
        "format": "yMd"
      },
      "time": {
        "type": "DateTime",
        "format": "Hm"
      }
    }
  },

  "helloFor": "Hello for {value}",
  "@helloFor": {
    "description": "A message with a double parameter",
    "placeholders": {
      "value": {
        "type": "double",
        "format": "compact"
      }
    }
  },

  "helloCost": "Hello for {price} {value}",
  "@helloCost": {
    "description": "A message with string and int (currency) parameters",
    "placeholders": {
      "price": {
      },
      "value": {
        "type": "int",
        "format": "currency"
      }
    }
  },

  "helloWorlds": "{count,plural, =0{Hello} =1{Hello World} =2{Hello two worlds} few{Hello {count} worlds} many{Hello all {count} worlds} other{Hello other {count} worlds}}",
  "@helloWorlds": {
    "description": "A plural message",
    "placeholders": {
      "count": {}
    }
  },

  "helloAdjectiveWorlds": "{count,plural, =0{Hello} =1{Hello {adjective} World} =2{Hello two {adjective} worlds} other{Hello other {count} {adjective} worlds}}",
  "@helloAdjectiveWorlds": {
    "description": "A plural message with an additional parameter",
    "placeholders": {
      "count": {},
      "adjective": {}
    }
  },

  "helloWorldsOn": "{count,plural, =0{Hello on {date}} =1{Hello World, on {date}} =2{Hello two worlds, on {date}} other{Hello other {count} worlds, on {date}}}",
  "@helloWorldsOn": {
    "description": "A plural message with an additional date parameter",
    "placeholders": {
      "count": {},
      "date": {
        "type": "DateTime",
        "format": "yMMMMEEEEd"
      }
    }
  },

  "helloWorldPopulation": "{count,plural, =1{Hello World of {population} citizens} =2{Hello two worlds with {population} total citizens} many{Hello all {count} worlds, with a total of {population} citizens} other{Hello other {count} worlds, with a total of {population} citizens}}",
  "@helloWorldPopulation": {
    "description": "A plural message with an additional integer parameter",
    "placeholders": {
      "count": {},
      "population": {
        "type": "int",
        "format": "compactLong"
      }
    }
  },

  "helloWorldInterpolation": "[{hello}] #{world}#",
  "@helloWorldInterpolation": {
    "description": "A message with parameters that need string interpolation braces",
    "placeholders": {
      "hello": {},
      "world": {}
    }
  },

  "helloWorldsInterpolation": "{count,plural, other {[{hello}] -{world}- #{count}#}}",
  "@helloWorldsInterpolation": {
    "description": "A plural message with parameters that need string interpolation braces",
    "placeholders": {
      "count": {},
      "hello": {},
      "world": {}
    }
  }
}
''';

  final String appEnCa = r'''
{
  "@@locale": "en_CA",
  "helloWorld": "CA Hello World"
}
''';

  final String appEnGb = r'''
{
  "@@locale": "en_GB",
  "helloWorld": "GB Hello World"
}
''';
}

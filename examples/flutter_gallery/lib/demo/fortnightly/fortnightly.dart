// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class FortnightlyDemo extends StatelessWidget {
  static const String routeName = '/fortnightly';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fortnightly Demo',
      theme: _fortnightlyTheme,
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            FruitPage(),
            SafeArea(
              child: ShortAppBar(
                onBackPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShortAppBar extends StatelessWidget {
  const ShortAppBar({ this.onBackPressed });

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 50,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 4,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(22)),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: onBackPressed,
            ),
            const SizedBox(width: 12),
            Image.asset(
              'logos/fortnightly/fortnightly_logo.png',
              package: 'flutter_gallery_assets',
            ),
          ],
        ),
      ),
    );
  }
}

class FruitPage extends StatelessWidget {
  static final String paragraph1 = '''Have you ever held a quince? It\'s strange;
 covered in a fuzz somewhere between peach skin and a spider web. And it\'s
 hard as soft lumber. You\'d be forgiven for thinking it\'s veneered Larch-wood.
 But inhale the aroma and you\'ll instantly know you have something wonderful.
 Its scent can fill a room for days. And all this before you\'ve even cooked it.
'''.replaceAll('\n', '');

  static final String paragraph2 = '''Pomegranates on the other hand have become
 almost ubiquitous. You can find its juice in any bodega, Walmart, and even some
 gas stations. But at what cost? The pomegranate juice craze of the aughts made
 \"megafarmers\" Lynda and Stewart Resnick billions. Unfortunately, it takes a lot
 of water to make that much pomegranate juice. Water the Resnicks get from their
 majority stake in the Kern Water Bank. How did one family come to hold control
 over water meant for the whole central valley of California? The story will shock you.
'''.replaceAll('\n', '');

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).primaryTextTheme;

    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: <Widget>[
              Container(
                constraints: const BoxConstraints.expand(height: 248),
                child: Image.asset(
                  'food/fruits.png',
                  package: 'flutter_gallery_assets',
                  fit: BoxFit.fitWidth,
                ),
              ),
              const SizedBox(height: 17),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'US',
                          style: textTheme.overline,
                        ),
                        Text(
                          ' ¬ ',
                          // TODO(larche): Replace textTheme.display3.color with a ColorScheme value when known.
                          style: textTheme.overline.apply(color: textTheme.display3.color),
                        ),
                        Text(
                          'CULTURE',
                          style: textTheme.overline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Quince for Wisdom, Persimmon for Luck, Pomegranate for Love',
                      style: textTheme.display1,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'How these crazy fruits sweetened our hearts, relationships,'
                          'and puffed pastries',
                      style: textTheme.body1,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: <Widget>[
                          const CircleAvatar(
                            backgroundImage: ExactAssetImage(
                              'people/square/trevor.png',
                              package: 'flutter_gallery_assets',
                            ),
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'by',
                            style: textTheme.display3,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Connor Eghan',
                            style: TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$paragraph1\n\n$paragraph2',
                      style: textTheme.body2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final ThemeData _fortnightlyTheme = _buildFortnightlyTheme();

ThemeData _buildFortnightlyTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
    scaffoldBackgroundColor: Colors.white,
  );
}

TextTheme _buildTextTheme(TextTheme base) {
  TextTheme theme = base.apply(bodyColor: Colors.black);
  theme = theme.apply(displayColor: Colors.black);

  theme = theme.copyWith(
    display1: base.display1.copyWith(
      fontFamily: 'Merriweather',
      fontStyle: FontStyle.italic,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: Colors.black,
      height: .88,
    ),
    display3: base.display3.copyWith(
      fontFamily: 'LibreFranklin',
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.black.withAlpha(153),
    ),
    headline: base.headline.copyWith(fontWeight: FontWeight.w500),
    body1: base.body1.copyWith(
      fontFamily: 'Merriweather',
      fontSize: 14,
      fontWeight: FontWeight.w300,
      color: const Color(0xFF666666),
      height: 1.11,
    ),
    body2: base.body2.copyWith(
      fontFamily: 'Merriweather',
      fontSize: 16,
      fontWeight: FontWeight.w300,
      color: const Color(0xFF666666),
      height: 1.4,
      letterSpacing: .25,
    ),
    overline: const TextStyle(
      fontFamily: 'LibreFranklin',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
  );

  return theme;
}

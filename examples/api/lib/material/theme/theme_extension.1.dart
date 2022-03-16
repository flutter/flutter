// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for ThemeExtension

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

@immutable
class MyColors extends ThemeExtension<MyColors> {
  const MyColors({
    required this.blue,
    required this.red,
  });

  final Color? blue;
  final Color? red;

  @override
  MyColors copyWith({Color? red, Color? blue}) {
    return MyColors(
      blue: blue ?? this.blue,
      red: red ?? this.red,
    );
  }

  @override
  MyColors lerp(ThemeExtension<MyColors>? other, double t) {
    if (other is! MyColors) {
      return this;
    }
    return MyColors(
      blue: Color.lerp(blue, other.blue, t),
      red: Color.lerp(red, other.red, t),
    );
  }

  // Optional
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MyColors
        && other.blue == blue
        && other.red == red;
  }

  // Optional
  @override
  int get hashCode {
    return hashList(<Object?>[
      blue,
      red,
    ]);
  }
}

void main() {
  // Slow down time to see lerping.
  timeDilation = 5.0;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLightTheme = true;

  void toggleTheme() {
    setState(() => isLightTheme = !isLightTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MyApp._title,
      theme: ThemeData.light().copyWith(
        extensions: const <Object, ThemeExtension<dynamic>>{
          MyColors: MyColors(
            blue: Color(0xFF1E88E5),
            red: Color(0xFFE53935),
          ),
        },
      ),
      darkTheme: ThemeData.dark().copyWith(
        extensions: const <Object, ThemeExtension<dynamic>>{
          MyColors: MyColors(
            blue: Color(0xFF90CAF9),
            red: Color(0xFFEF9A9A),
          ),
        },
      ),
      themeMode: isLightTheme ? ThemeMode.light : ThemeMode.dark,
      home: Home(
        isLightTheme: isLightTheme,
        toggleTheme: toggleTheme,
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({
    Key? key,
    required this.isLightTheme,
    required this.toggleTheme,
  }) : super(key: key);

  final bool isLightTheme;
  final void Function() toggleTheme;

  @override
  Widget build(BuildContext context) {
    final MyColors? myColors = Theme.of(context).extension<MyColors>();
    return Material(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(width: 100, height: 100, color: myColors?.blue),
            const SizedBox(width: 10),
            Container(width: 100, height: 100, color: myColors?.red),
            const SizedBox(width: 50),
            IconButton(
              icon: Icon(isLightTheme ? Icons.nightlight : Icons.wb_sunny),
              onPressed: toggleTheme,
            ),
          ],
        )
      ),
    );
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  // Changes made in https://github.com/flutter/flutter/pull/66482
  ThemeData(textSelectionColor: Colors.red);
  ThemeData(cursorColor: Colors.blue);
  ThemeData(textSelectionHandleColor: Colors.yellow);
  ThemeData(useTextSelectionTheme: false);
  ThemeData(textSelectionColor: Colors.red, useTextSelectionTheme: false);
  ThemeData(cursorColor: Colors.blue, useTextSelectionTheme: false);
  ThemeData(
      textSelectionHandleColor: Colors.yellow, useTextSelectionTheme: false);
  ThemeData(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
  );
  ThemeData(
    textSelectionHandleColor: Colors.yellow,
    cursorColor: Colors.blue,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    textSelectionHandleColor: Colors.yellow,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    useTextSelectionTheme: false,
  );
  ThemeData(
    textSelectionHandleColor: Colors.yellow,
    cursorColor: Colors.blue,
    useTextSelectionTheme: true,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    textSelectionHandleColor: Colors.yellow,
    useTextSelectionTheme: false,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    textSelectionHandleColor: Colors.yellow,
  );
  ThemeData(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    textSelectionHandleColor: Colors.yellow,
    useTextSelectionTheme: false,
  );
  ThemeData(error: '');
  ThemeData.raw(error: '');
  ThemeData.raw(textSelectionColor: Colors.red);
  ThemeData.raw(cursorColor: Colors.blue);
  ThemeData.raw(textSelectionHandleColor: Colors.yellow);
  ThemeData.raw(useTextSelectionTheme: false);
  ThemeData.raw(textSelectionColor: Colors.red, useTextSelectionTheme: false);
  ThemeData.raw(cursorColor: Colors.blue, useTextSelectionTheme: false);
  ThemeData.raw(
      textSelectionHandleColor: Colors.yellow, useTextSelectionTheme: false);
  ThemeData.raw(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
  );
  ThemeData.raw(
    textSelectionHandleColor: Colors.yellow,
    cursorColor: Colors.blue,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    textSelectionHandleColor: Colors.yellow,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    useTextSelectionTheme: false,
  );
  ThemeData.raw(
    textSelectionHandleColor: Colors.yellow,
    cursorColor: Colors.blue,
    useTextSelectionTheme: true,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    textSelectionHandleColor: Colors.yellow,
    useTextSelectionTheme: false,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    textSelectionHandleColor: Colors.yellow,
  );
  ThemeData.raw(
    textSelectionColor: Colors.red,
    cursorColor: Colors.blue,
    textSelectionHandleColor: Colors.yellow,
    useTextSelectionTheme: false,
  );

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(accentColor: Colors.red);
  themeData = ThemeData(accentColor: Colors.red, primarySwatch: Colors.blue);
  themeData = ThemeData(accentColor: Colors.red, colorScheme: ColorScheme.light());
  themeData = ThemeData(accentColor: Colors.red, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = ThemeData(error: '');
  themeData = ThemeData.raw(accentColor: Colors.red);
  themeData = ThemeData.raw(accentColor: Colors.red, primarySwatch: Colors.blue);
  themeData = ThemeData.raw(accentColor: Colors.red, colorScheme: ColorScheme.light());
  themeData = ThemeData.raw(accentColor: Colors.red, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = ThemeData.raw(error: '');
  themeData = themeData.copyWith(accentColor: Colors.red);
  themeData = themeData.copyWith(error: '');
  themeData = themeData.copyWith(accentColor: Colors.red, primarySwatch: Colors.blue);
  themeData = themeData.copyWith(accentColor: Colors.red, colorScheme: ColorScheme.light());
  themeData = themeData.copyWith(accentColor: Colors.red, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData.accentColor;

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(accentColorBrightness: Brightness.dark);
  themeData = ThemeData.raw(accentColorBrightness: Brightness.dark);
  themeData = themeData.copyWith(accentColorBrightness: Brightness.dark);
  themeData.accentColorBrightness; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(accentTextTheme: TextTheme());
  themeData = ThemeData.raw(accentTextTheme: TextTheme());
  themeData = themeData.copyWith(accentTextTheme: TextTheme());
  themeData.accentTextTheme; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(accentIconTheme: IconThemeData());
  themeData = ThemeData.raw(accentIconTheme: IconThemeData());
  themeData = themeData.copyWith(accentIconTheme: IconThemeData());
  themeData.accentIconTheme; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/81336
  ThemeData themeData = ThemeData();
  themeData = ThemeData(buttonColor: Colors.red);
  themeData = ThemeData.raw(buttonColor: Colors.red);
  themeData = themeData.copyWith(buttonColor: Colors.red);
  themeData.buttonColor; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/87281
  ThemeData themeData = ThemeData();
  themeData = ThemeData(fixTextFieldOutlineLabel: true);
  themeData = ThemeData.raw(fixTextFieldOutlineLabel: true);
  themeData = themeData.copyWith(fixTextFieldOutlineLabel: true);
  themeData.fixTextFieldOutlineLabel; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/93396
  ThemeData themeData = ThemeData();
  themeData = ThemeData(primaryColorBrightness: Brightness.dark);
  themeData = ThemeData.raw(primaryColorBrightness: Brightness.dark);
  themeData = themeData.copyWith(primaryColorBrightness: Brightness.dark);
  themeData.primaryColorBrightness; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/97972
  ThemeData themeData = ThemeData();
  themeData = ThemeData(toggleableActiveColor: Colors.black);
  themeData = ThemeData(
    toggleableActiveColor: Colors.black,
  );
  themeData = ThemeData.raw(toggleableActiveColor: Colors.black);
  themeData = ThemeData.raw(
    toggleableActiveColor: Colors.black,
  );
  themeData = themeData.copyWith(toggleableActiveColor: Colors.black);
  themeData = themeData.copyWith(
    toggleableActiveColor: Colors.black,
  );
  themeData.toggleableActiveColor; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/109070
  ThemeData themeData = ThemeData();
  themeData = ThemeData(selectedRowColor: Brightness.dark);
  themeData = ThemeData.raw(selectedRowColor: Brightness.dark);
  themeData = themeData.copyWith(selectedRowColor: Brightness.dark);
  themeData.selectedRowColor; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/110162
  ThemeData themeData = ThemeData();
  themeData = ThemeData(errorColor: Colors.red);
  themeData = ThemeData(errorColor: Colors.red, primarySwatch: Colors.blue);
  themeData = ThemeData(errorColor: Colors.red, colorScheme: ColorScheme.light());
  themeData = ThemeData(errorColor: Colors.red, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = ThemeData(otherParam: '');
  themeData = ThemeData.raw(errorColor: Colors.red);
  themeData = ThemeData.raw(errorColor: Colors.red, primarySwatch: Colors.blue);
  themeData = ThemeData.raw(errorColor: Colors.red, colorScheme: ColorScheme.light());
  themeData = ThemeData.raw(errorColor: Colors.red, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = ThemeData.raw(otherParam: '');
  themeData = themeData.copyWith(errorColor: Colors.red);
  themeData = themeData.copyWith(otherParam: '');
  themeData = themeData.copyWith(errorColor: Colors.red, primarySwatch: Colors.blue);
  themeData = themeData.copyWith(errorColor: Colors.red, colorScheme: ColorScheme.light());
  themeData = themeData.copyWith(errorColor: Colors.red, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData.errorColor;

  // Changes made in https://github.com/flutter/flutter/pull/110162
  ThemeData themeData = ThemeData();
  themeData = ThemeData(backgroundColor: Colors.grey);
  themeData = ThemeData(backgroundColor: Colors.grey, primarySwatch: Colors.blue);
  themeData = ThemeData(backgroundColor: Colors.grey, colorScheme: ColorScheme.light());
  themeData = ThemeData(backgroundColor: Colors.grey, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = ThemeData(otherParam: '');
  themeData = ThemeData.raw(backgroundColor: Colors.grey);
  themeData = ThemeData.raw(backgroundColor: Colors.grey, primarySwatch: Colors.blue);
  themeData = ThemeData.raw(backgroundColor: Colors.grey, colorScheme: ColorScheme.light());
  themeData = ThemeData.raw(backgroundColor: Colors.grey, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = ThemeData.raw(otherParam: '');
  themeData = themeData.copyWith(backgroundColor: Colors.grey);
  themeData = themeData.copyWith(otherParam: '');
  themeData = themeData.copyWith(backgroundColor: Colors.grey, primarySwatch: Colors.blue);
  themeData = themeData.copyWith(backgroundColor: Colors.grey, colorScheme: ColorScheme.light());
  themeData = themeData.copyWith(backgroundColor: Colors.grey, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData.backgroundColor;

  // Changes made in https://github.com/flutter/flutter/pull/110162
  ThemeData themeData = ThemeData();
  themeData = ThemeData(backgroundColor: Colors.grey, errorColor: Colors.red);
  themeData = ThemeData.raw(backgroundColor: Colors.grey, errorColor: Colors.red);
  themeData = themeData.copyWith(backgroundColor: Colors.grey, errorColor: Colors.red);

  // Changes made in https://github.com/flutter/flutter/pull/111080
  ThemeData themeData = ThemeData();
  themeData = ThemeData(bottomAppBarColor: Colors.green);
  themeData = ThemeData.raw(bottomAppBarColor: Colors.green);
  themeData = ThemeData.copyWith(bottomAppBarColor: Colors.green);

  // Changes made in https://github.com/flutter/flutter/pull/XXXXX
  ThemeData themeData = ThemeData();
  themeData = ThemeData(canvasColor: Colors.black);
  themeData = ThemeData.raw(canvasColor: Colors.black);
  themeData = themeData.copyWith(canvasColor: Colors.black);
  themeData.canvasColor;

  // Changes made in https://github.com/flutter/flutter/pull/XXXXX
  ThemeData themeData = ThemeData();
  themeData = ThemeData(cardColor: Colors.black);
  themeData = ThemeData(
    cardColor: Colors.black,
  );
  themeData = ThemeData(
    cardColor: Colors.black,
    cardTheme: CardTheme(),
  );
  themeData = ThemeData.raw(cardColor: Colors.black);
  themeData = ThemeData.raw(
    cardColor: Colors.black,
    cardTheme: CardTheme(),
  );
  themeData = themeData.copyWith(cardColor: Colors.black);
  themeData = themeData.copyWith(
    cardColor: Colors.black,
    cardTheme: CardTheme(),
  );
  themeData.cardColor;

  // Changes made in https://github.com/flutter/flutter/pull/XXXXX
  ThemeData themeData = ThemeData();
  themeData = ThemeData(dialogBackgroundColor: Colors.black);
  themeData = ThemeData(
    dialogBackgroundColor: Colors.black,
  );
  themeData = ThemeData(
    dialogBackgroundColor: Colors.black,
    dialogTheme: DialogTheme(),
  );
  themeData = ThemeData.raw(dialogBackgroundColor: Colors.black);
  themeData = ThemeData.raw(
    dialogBackgroundColor: Colors.black,
    dialogTheme: DialogTheme(),
  );
  themeData = themeData.copyWith(dialogBackgroundColor: Colors.black);
  themeData = themeData.copyWith(
    dialogBackgroundColor: Colors.black,
    dialogTheme: DialogTheme(),
  );
  themeData.dialogBackgroundColor;

  // Changes made in https://github.com/flutter/flutter/pull/XXXXX
  ThemeData themeData = ThemeData();
  themeData = ThemeData(dividerColor: Colors.black);
  themeData = ThemeData(
    dividerColor: Colors.black,
  );
  themeData = ThemeData(
    dividerColor: Colors.black,
    dividerTheme: DividerThemeData(),
  );
  themeData = ThemeData.raw(dividerColor: Colors.black);
  themeData = ThemeData.raw(
    dividerColor: Colors.black,
    dividerTheme: DividerThemeData(),
  );
  themeData = themeData.copyWith(dividerColor: Colors.black);
  themeData = themeData.copyWith(
    dividerColor: Colors.black,
    dividerTheme: DividerThemeData(),
  );
  themeData.dividerColor;

  // Changes made in https://github.com/flutter/flutter/pull/XXXXX
  ThemeData themeData = ThemeData();
  themeData = ThemeData(hintColor: Colors.black);
  themeData = ThemeData(
    hintColor: Colors.black,
  );
  themeData = ThemeData(
    hintColor: Colors.black,
    inputDecorationTheme: InputDecorationTheme(),
  );
  themeData = ThemeData.raw(hintColor: Colors.black);
  themeData = ThemeData.raw(
    hintColor: Colors.black,
    inputDecorationTheme: InputDecorationTheme(),
  );
  themeData = themeData.copyWith(hintColor: Colors.black);
  themeData = themeData.copyWith(
    hintColor: Colors.black,
    inputDecorationTheme: InputDecorationTheme(),
  );
  themeData.hintColor;

  // Changes made in https://github.com/flutter/flutter/pull/XXXXX
  ThemeData themeData = ThemeData();
  themeData = ThemeData(indicatorColor: Colors.black);
  themeData = ThemeData(
    indicatorColor: Colors.black,
  );
  themeData = ThemeData(
    indicatorColor: Colors.black,
    tabBarTheme: TabBarTheme(),
  );
  themeData = ThemeData.raw(indicatorColor: Colors.black);
  themeData = ThemeData.raw(
    indicatorColor: Colors.black,
    tabBarTheme: TabBarTheme(),
  );
  themeData = themeData.copyWith(indicatorColor: Colors.black);
  themeData = themeData.copyWith(
    indicatorColor: Colors.black,
    tabBarTheme: TabBarTheme(),
  );
  themeData.indicatorColor;

  // Changes made in https://github.com/flutter/flutter/pull/110848
  ThemeData themeData = ThemeData();
  themeData = ThemeData(primaryColorDark: Colors.red);
  themeData = ThemeData.raw(primaryColorDark: Colors.red);
  themeData = themeData.copyWith(primaryColorDark: Colors.red);
  themeData.primaryColorDark; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/110848
  ThemeData themeData = ThemeData();
  themeData = ThemeData(primaryColorLight: Colors.red);
  themeData = ThemeData.raw(primaryColorLight: Colors.red);
  themeData = themeData.copyWith(primaryColorLight: Colors.red);
  themeData.primaryColorLight; // Removing field reference not supported.

  // Changes made in https://github.com/flutter/flutter/pull/XXXXX
  // Simpler than other tests, because corresponding theme is newly introduced and does not need a fix.
  ThemeData themeData = ThemeData();
  themeData = ThemeData(scaffoldBackgroundColor: Colors.black);
  themeData = ThemeData.raw(scaffoldBackgroundColor: Colors.black);
  themeData = themeData.copyWith(scaffoldBackgroundColor: Colors.black);
  themeData.scaffoldBackgroundColor;

  // Changes made in https://github.com/flutter/flutter/pull/XXXXX
  ThemeData themeData = ThemeData();
  themeData = ThemeData(secondaryHeaderColor: Colors.black);
  themeData = ThemeData(
    secondaryHeaderColor: Colors.black,
  );
  themeData = ThemeData(
    secondaryHeaderColor: Colors.black,
    dataTableTheme: DataTableThemeData(),
  );
  themeData = ThemeData.raw(secondaryHeaderColor: Colors.black);
  themeData = ThemeData.raw(
    secondaryHeaderColor: Colors.black,
    dataTableTheme: DataTableThemeData(),
  );
  themeData = themeData.copyWith(secondaryHeaderColor: Colors.black);
  themeData = themeData.copyWith(
    secondaryHeaderColor: Colors.black,
    dataTableTheme: DataTableThemeData(),
  );
  themeData.secondaryHeaderColor;

  // Changes made in https://github.com/flutter/flutter/pull/XXXXX
  ThemeData themeData = ThemeData();
  themeData = ThemeData(shadowColor: Colors.grey);
  themeData = ThemeData(shadowColor: Colors.grey, primarySwatch: Colors.blue);
  themeData = ThemeData(shadowColor: Colors.grey, colorScheme: ColorScheme.light());
  themeData = ThemeData(shadowColor: Colors.grey, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = ThemeData(otherParam: '');
  themeData = ThemeData.raw(shadowColor: Colors.grey);
  themeData = ThemeData.raw(shadowColor: Colors.grey, primarySwatch: Colors.blue);
  themeData = ThemeData.raw(shadowColor: Colors.grey, colorScheme: ColorScheme.light());
  themeData = ThemeData.raw(shadowColor: Colors.grey, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData = ThemeData.raw(otherParam: '');
  themeData = themeData.copyWith(shadowColor: Colors.grey);
  themeData = themeData.copyWith(otherParam: '');
  themeData = themeData.copyWith(shadowColor: Colors.grey, primarySwatch: Colors.blue);
  themeData = themeData.copyWith(shadowColor: Colors.grey, colorScheme: ColorScheme.light());
  themeData = themeData.copyWith(shadowColor: Colors.grey, colorScheme: ColorScheme.light(), primarySwatch: Colors.blue);
  themeData.shadowColor;
}

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates usage of ANSI VT escape sequences to control the console. For a
// more comprehensive library that uses these functions, check out dart_console
// (https://pub.dev/packages/dart_console).

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const VT_ESC = '\x1b';
const VT_CSI = '\x1b[';

void ESC(String sequence) => stdout.write(VT_ESC + sequence);
void CSI(String command) => stdout.write(VT_CSI + command);
void printf(String output) => stdout.write(output);

class Coord {
  int X = 0;
  int Y = 0;
}

bool enableVTMode() {
  // Set output mode to handle virtual terminal sequences
  final hOut = GetStdHandle(STD_OUTPUT_HANDLE);
  if (hOut == INVALID_HANDLE_VALUE) {
    return false;
  }

  final dwMode = calloc<DWORD>();
  try {
    if (GetConsoleMode(hOut, dwMode) == 0) {
      return false;
    }

    dwMode.value |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    if (SetConsoleMode(hOut, dwMode.value) == 0) {
      return false;
    }
    return true;
  } finally {
    free(dwMode);
  }
}

void printVerticalBorder() {
  ESC('(0'); // Enter Line drawing mode
  CSI('104;93m'); // bright yellow on bright blue
  printf('x'); // in line drawing mode, \x78 -> \u2502 "Vertical Bar"
  CSI('0m'); // restore color
  ESC('(B'); // exit line drawing mode
}

void printHorizontalBorder(Coord size, bool isTop) {
  ESC("(0"); // Enter Line drawing mode
  CSI("104;93m"); // Make the border bright yellow on bright blue
  printf(isTop ? "l" : "m"); // print left corner

  for (var i = 1; i < size.X - 1; i++) {
    printf(
        "q"); // in line drawing mode, \x71 -> \u2500 "HORIZONTAL SCAN LINE-5"
  }

  printf(isTop ? "k" : "j"); // print right corner
  CSI("0m");
  ESC("(B"); // exit line drawing mode
}

void printStatusLine(String pszMessage, Coord Size) {
  CSI("${Size.Y};1H");
  CSI("K"); // clear the line
  printf(pszMessage);
}

void main() {
  //First, enable VT mode
  final fSuccess = enableVTMode();
  if (!fSuccess) {
    printf("Unable to enter VT processing mode. Quitting.\n");
    exit(-1);
  }
  final hOut = GetStdHandle(STD_OUTPUT_HANDLE);
  if (hOut == INVALID_HANDLE_VALUE) {
    printf("Couldn't get the console handle. Quitting.\n");
    exit(-1);
  }

  final ScreenBufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();
  GetConsoleScreenBufferInfo(hOut, ScreenBufferInfo);
  final size = Coord()
    ..X = ScreenBufferInfo.ref.srWindow.Right -
        ScreenBufferInfo.ref.srWindow.Left +
        1
    ..Y = ScreenBufferInfo.ref.srWindow.Bottom -
        ScreenBufferInfo.ref.srWindow.Top +
        1;
  free(ScreenBufferInfo);

  // Enter the alternate buffer
  CSI("?1049h");

  // Clear screen, tab stops, set, stop at columns 16, 32
  CSI("1;1H");
  CSI("2J"); // Clear screen

  final tabStopCount = 4; // (0, 20, 40, width)
  CSI("3g"); // clear all tab stops
  CSI("1;20H"); // Move to column 20
  ESC("H"); // set a tab stop

  CSI("1;40H"); // Move to column 40
  ESC("H"); // set a tab stop

  // Set scrolling margins to 3, h-2
  CSI("3;${size.Y - 2}r");
  final numLines = size.Y - 4;

  CSI("1;1H");
  CSI("102;30m");
  printf("Dart Win32 Package: VT Example");
  CSI("0m");

  // Print a top border - Yellow
  CSI("2;1H");
  printHorizontalBorder(size, true);

  // // Print a bottom border
  CSI(
    "${size.Y - 1};1H",
  );
  printHorizontalBorder(size, false);

  // draw columns
  CSI("3;1H");
  for (var line = 0; line < numLines * tabStopCount; line++) {
    printVerticalBorder();

    // don't advance to next line if this is the last line
    if (line + 1 != numLines * tabStopCount) {
      printf("\t"); // advance to next tab stop
    }
  }

  printStatusLine("Press enter to see text printed between tab stops.", size);
  stdin.readLineSync();

  // Fill columns with output
  CSI("3;1H");
  for (var line = 0; line < numLines; line++) {
    for (var tab = 0; tab < tabStopCount - 1; tab++) {
      printVerticalBorder();
      printf("line=$line");
      printf("\t"); // advance to next tab stop
    }
    printVerticalBorder(); // print border at right side
    if (line + 1 != numLines) {
      printf("\t"); // advance to next tab stop, (on the next line)
    }
  }

  printStatusLine("Press enter to demonstrate scroll margins", size);
  stdin.readLineSync();

  CSI("3;1H");
  for (var line = 0; line < numLines * 2; line++) {
    CSI("K"); // clear the line
    var tab = 0;
    for (tab = 0; tab < tabStopCount - 1; tab++) {
      printVerticalBorder();
      printf("line=$line");
      printf("\t"); // advance to next tab stop
    }
    printVerticalBorder(); // print border at right side
    if (line + 1 != numLines * 2) {
      // Advance to next line. If we're at the bottom of the margins, the text
      // will scroll.
      printf("\n");
      printf("\r"); // return to first col in buffer
    }
  }

  printStatusLine("Press enter to exit", size);
  stdin.readLineSync();

  // Exit the alternate buffer
  CSI("?1049l");
}

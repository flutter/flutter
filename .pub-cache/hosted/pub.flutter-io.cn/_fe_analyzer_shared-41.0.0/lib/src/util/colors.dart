// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ahe): Originally copied from sdk/pkg/compiler/lib/src/colors.dart,
// merge these two packages.
library colors;

import 'dart:convert' show jsonEncode;

import 'dart:io' show Platform, Process, ProcessResult, stderr, stdout;

/// ANSI/xterm termcap for setting default colors. Output from Unix
/// command-line program `tput op`.
const String DEFAULT_COLOR = "\x1b[39;49m";

/// ANSI/xterm termcap for setting black text color. Output from Unix
/// command-line program `tput setaf 0`.
const String BLACK_COLOR = "\x1b[30m";

/// ANSI/xterm termcap for setting red text color. Output from Unix
/// command-line program `tput setaf 1`.
const String RED_COLOR = "\x1b[31m";

/// ANSI/xterm termcap for setting green text color. Output from Unix
/// command-line program `tput setaf 2`.
const String GREEN_COLOR = "\x1b[32m";

/// ANSI/xterm termcap for setting yellow text color. Output from Unix
/// command-line program `tput setaf 3`.
const String YELLOW_COLOR = "\x1b[33m";

/// ANSI/xterm termcap for setting blue text color. Output from Unix
/// command-line program `tput setaf 4`.
const String BLUE_COLOR = "\x1b[34m";

/// ANSI/xterm termcap for setting magenta text color. Output from Unix
/// command-line program `tput setaf 5`.
const String MAGENTA_COLOR = "\x1b[35m";

/// ANSI/xterm termcap for setting cyan text color. Output from Unix
/// command-line program `tput setaf 6`.
const String CYAN_COLOR = "\x1b[36m";

/// ANSI/xterm termcap for setting white text color. Output from Unix
/// command-line program `tput setaf 7`.
const String WHITE_COLOR = "\x1b[37m";

/// All the above codes. This is used to compare the above codes to the
/// terminal's. Printing this string should have the same effect as just
/// printing [DEFAULT_COLOR].
const String ALL_CODES = BLACK_COLOR +
    RED_COLOR +
    GREEN_COLOR +
    YELLOW_COLOR +
    BLUE_COLOR +
    MAGENTA_COLOR +
    CYAN_COLOR +
    WHITE_COLOR +
    DEFAULT_COLOR;

const String TERMINAL_CAPABILITIES = """
colors
setaf 0
setaf 1
setaf 2
setaf 3
setaf 4
setaf 5
setaf 6
setaf 7
op
""";

/// Boolean value caching whether or not we should display ANSI colors.
///
/// If `null`, we haven't decided whether we should display ANSI colors or not.
bool? _enableColors;

/// Finds out whether we are displaying ANSI colors.
///
/// The first time this getter is invoked (either by a client or by an attempt
/// to use a color), it decides whether colors should be used based on the
/// logic in [_computeEnableColors] (unless a value has previously been set).
bool get enableColors => _enableColors ??= _computeEnableColors();

/// Allows the client to override the decision of whether to disable ANSI
/// colors.
void set enableColors(bool value) {
  // ignore: unnecessary_null_comparison
  assert(value != null);
  _enableColors = value;
}

String wrap(String string, String color) {
  return enableColors ? "${color}$string${DEFAULT_COLOR}" : string;
}

String black(String string) => wrap(string, BLACK_COLOR);
String red(String string) => wrap(string, RED_COLOR);
String green(String string) => wrap(string, GREEN_COLOR);
String yellow(String string) => wrap(string, YELLOW_COLOR);
String blue(String string) => wrap(string, BLUE_COLOR);
String magenta(String string) => wrap(string, MAGENTA_COLOR);
String cyan(String string) => wrap(string, CYAN_COLOR);
String white(String string) => wrap(string, WHITE_COLOR);

/// Returns whether [sink] supports ANSI escapes or `null` if it could not be
/// determined.
bool? _supportsAnsiEscapes(sink) {
  try {
    // ignore: undefined_getter
    return sink.supportsAnsiEscapes;
  } on NoSuchMethodError {
    // Ignored: We're running on an older version of the Dart VM which doesn't
    // implement `supportsAnsiEscapes`.
    return null;
  }
}

/// Callback used by [_computeEnableColors] to report why it has or hasn't
/// chosen to use ANSI colors.
void Function(String) printEnableColorsReason = (_) {};

/// True if we should enable colors in output.
///
/// We enable colors when both `stdout` and `stderr` support ANSI escapes.
///
/// On non-Windows platforms, this functions checks the terminal capabilities,
/// on Windows we only enable colors if the VM getters are present and returned
/// `true`.
///
/// Note: do not call this method directly, as it is expensive to
/// compute. Instead, use [CompilerContext.enableColors].
bool _computeEnableColors() {
  bool? stderrSupportsColors = _supportsAnsiEscapes(stdout);
  bool? stdoutSupportsColors = _supportsAnsiEscapes(stderr);

  if (stdoutSupportsColors == false) {
    printEnableColorsReason(
        "Not enabling colors, stdout does not support ANSI colors.");
    return false;
  }
  if (stderrSupportsColors == false) {
    printEnableColorsReason(
        "Not enabling colors, stderr does not support ANSI colors.");
    return false;
  }

  if (Platform.isWindows) {
    if (stderrSupportsColors != true || stdoutSupportsColors != true) {
      // In this case, either [stdout] or [stderr] did not support the
      // property `supportsAnsiEscapes`. Since we do not have another way
      // to determine support for colors, we disable them.
      printEnableColorsReason("Not enabling colors as ANSI is not supported.");
      return false;
    }
    printEnableColorsReason("Enabling colors as OS is Windows.");
    return true;
  }

  // We have to check if the terminal actually supports colors. Currently,
  // to avoid linking the Dart VM with ncurses, ANSI escape support is reduced
  // to `Platform.environment['TERM'].contains("xterm")`.

  // The `-S` option of `tput` allows us to query multiple capabilities at
  // once.
  ProcessResult result = Process.runSync(
      "/bin/sh", ["-c", "printf '%s' '$TERMINAL_CAPABILITIES' | tput -S"]);

  if (result.exitCode != 0) {
    printEnableColorsReason("Not enabling colors, running tput failed.");
    return false;
  }

  List<String> lines = result.stdout.split("\n");

  if (lines.length != 2) {
    printEnableColorsReason("Not enabling colors, unexpected output from tput: "
        "${jsonEncode(result.stdout)}.");
    return false;
  }

  String numberOfColors = lines[0];
  if ((int.tryParse(numberOfColors) ?? -1) < 8) {
    printEnableColorsReason(
        "Not enabling colors, less than 8 colors supported: "
        "${jsonEncode(numberOfColors)}.");
    return false;
  }

  String allCodes = lines[1].trim();
  if (ALL_CODES != allCodes) {
    printEnableColorsReason("Not enabling colors, color codes don't match: "
        "${jsonEncode(ALL_CODES)} != ${jsonEncode(allCodes)}.");
    return false;
  }

  printEnableColorsReason("Enabling colors.");
  return true;
}

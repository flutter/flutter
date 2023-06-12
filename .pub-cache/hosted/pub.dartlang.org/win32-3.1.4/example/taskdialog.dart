// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates a task dialog from the console.

// Requires a reference to comctl32.dll v6 in the manifest to work. An example
// is included in taskdialog.exe.manifest, but this will only be loaded if
// you first compile this example with a command such as:
//   dart compile exe taskdialog.dart
//
// An example of the manifest is found in the bin\ subdirectory as
// taskdialog.exe.manifest. Place the compiled taskdialog.exe in the same folder
// as the manifest and then when you run this it should display two task dialog
// samples.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void showSimpleTaskDialog() {
  final windowTitle = TEXT('Dart TaskDialog Sample');
  final mainInstruction = TEXT('Please read this important message');
  final content = TEXT(
      'Task dialogs are great for sharing a longer string of explanatory '
      'content, where you need a user to read an instruction before making a '
      'decision. Of course, you cannot guarantee that the user will actually '
      "read the text, so it's important that you also provide an undo function "
      'for when the wrong choice is selected.');
  final buttonSelected = calloc<Int32>();

  try {
    final hr = TaskDialog(
        NULL,
        NULL,
        windowTitle,
        mainInstruction,
        content,
        TASKDIALOG_COMMON_BUTTON_FLAGS.TDCBF_OK_BUTTON |
            TASKDIALOG_COMMON_BUTTON_FLAGS.TDCBF_CANCEL_BUTTON,
        TD_INFORMATION_ICON,
        buttonSelected);
    if (SUCCEEDED(hr)) {
      switch (buttonSelected.value) {
        case IDOK:
          print('User clicked on the OK button.');
          break;
        default:
          print('User canceled the task dialog.');
      }
    }
    // ignore: avoid_catching_errors
  } on ArgumentError {
    print('If you see an error "Failed to lookup symbol", it\'s likely because '
        'the app manifest\ndeclaring a dependency on comctl32.dll v6 is '
        'missing.\n\nSee the comment at the top of the sample source code.\n');
    rethrow;
  } finally {
    free(windowTitle);
    free(mainInstruction);
    free(content);
  }
}

void showCustomTaskDialog() {
  // Note that this example does not explicitly free allocated memory, since it
  // returns quickly to the command prompt. As part of a real app, you'd
  // certainly want to free each string here.
  final buttonSelected = calloc<Int32>();

  final buttons = calloc<TASKDIALOG_BUTTON>(2);
  buttons[0]
    ..nButtonID = 100
    ..pszButtonText =
        TEXT('Take the blue pill\nThe story ends, you wake up in your bed and '
            'believe whatever you want to believe.');
  buttons[1]
    ..nButtonID = 101
    ..pszButtonText = TEXT(
        'Take the red pill\nYou stay in Wonderland, and I show you how deep '
        'the rabbit hole goes.');

  const matrixDescription =
      'In The Matrix, the main character Neo is offered  the choice between '
      'a red pill and a blue pill by rebel leader Morpheus. The red pill '
      'represents an uncertain future: it would free him from the enslaving '
      'control of the machine-generated dream world and allow him to escape '
      'into the real world, but living the "truth of reality" is harsher and '
      'more difficult. On the other hand, the blue pill represents a '
      'beautiful prison: it would lead him back to ignorance, living in '
      'confined comfort without want or fear within '
      'the simulated reality of the Matrix.';

  final config = calloc<TASKDIALOGCONFIG>()
    ..ref.cbSize = sizeOf<TASKDIALOGCONFIG>()
    ..ref.pszWindowTitle = TEXT('TaskDialogIndirect Sample')
    ..ref.pszMainInstruction = TEXT('Which pill will you take?')
    ..ref.pszContent =
        TEXT('This is your last chance. There is no turning back.')
    ..ref.hMainIcon = TD_WARNING_ICON.address
    ..ref.pszCollapsedControlText = TEXT('See more details.')
    ..ref.pszExpandedControlText = matrixDescription.toNativeUtf16()
    ..ref.dwFlags = TASKDIALOG_FLAGS.TDF_USE_COMMAND_LINKS
    ..ref.cButtons = 2
    ..ref.pButtons = buttons;

  final hr = TaskDialogIndirect(config, buttonSelected, nullptr, nullptr);

  if (SUCCEEDED(hr)) {
    if (buttonSelected.value == 100) {
      print('Ignorance is bliss.');
    } else {
      print("I've been expecting you, Mr Anderson.");
    }
  } else {
    print('that failed.');
  }
}

void main() {
  showSimpleTaskDialog();
  showCustomTaskDialog();
}

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of using Windows built-in spellchecker.
//
// Try it with something like this:
//   dart example\spellcheck.dart "The rain inx Spain is very rar"
//
// You should see that the words 'inx' and 'rar' generate errors (and suggested
// corrections).

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main(List<String> args) {
  if (args.length != 1) {
    print('Provide text in the argument');
    return;
  }

  final text = args.first;

  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  final spellCheckerFactory = SpellCheckerFactory.createInstance();

  final supportedPtr = calloc<Int32>();
  final languageTagPtr = Platform.localeName.toNativeUtf16();

  spellCheckerFactory.isSupported(languageTagPtr, supportedPtr);

  if (supportedPtr.value == 1) {
    final spellCheckerPtr = calloc<COMObject>();
    spellCheckerFactory.createSpellChecker(
        languageTagPtr, spellCheckerPtr.cast());

    final spellChecker = ISpellChecker(spellCheckerPtr);

    // While ISpellChecker works fine for the needs of this example,
    // ISpellChecker2 extends it with the ability to remove words from the
    // custom dictionary. We cast to that purely as an example.
    final spellChecker2 = ISpellChecker2.from(spellChecker);

    final errorsPtr = calloc<COMObject>();
    final textPtr = text.toNativeUtf16();
    spellChecker2.check(textPtr, errorsPtr.cast());

    final errors = IEnumSpellingError(errorsPtr);
    final errorPtr = calloc<COMObject>();

    print('Input: "$text"');
    print('Errors:');

    var errorCount = 0;

    while (errors.next(errorPtr.cast()) == S_OK) {
      errorCount++;

      final error = ISpellingError(errorPtr);
      final word = text.substring(
        error.startIndex,
        error.startIndex + error.length,
      );

      stdout.write('$errorCount. $word');

      switch (error.correctiveAction) {
        case CORRECTIVE_ACTION.DELETE:
          print(' - delete');
          break;

        case CORRECTIVE_ACTION.NONE:
          print('\n');
          break;

        case CORRECTIVE_ACTION.REPLACE:
          final replacment = error.replacement;
          print(' - replace with "${replacment.toDartString()}"');
          WindowsDeleteString(replacment.address);
          break;

        case CORRECTIVE_ACTION.GET_SUGGESTIONS:
          print(' - suggestions:');

          final wordPtr = word.toNativeUtf16();
          final suggestionsPtr = calloc<COMObject>();
          spellChecker2.suggest(wordPtr, suggestionsPtr.cast());
          final suggestions = IEnumString(suggestionsPtr);

          final suggestionPtr = calloc<Pointer<Utf16>>();
          final suggestionResultPtr = calloc<Uint32>();

          while (
              suggestions.next(1, suggestionPtr, suggestionResultPtr) == S_OK) {
            print('\t${suggestionPtr.value.toDartString()}');
            WindowsDeleteString(suggestionPtr.value.address);
          }

          break;
      }

      error.release();
    }

    errors.release();
    free(textPtr);
    spellChecker2.release();
    spellChecker.release();
    free(spellCheckerPtr);
  }

  free(supportedPtr);
  free(languageTagPtr);

  spellCheckerFactory.release();

  CoUninitialize();
}

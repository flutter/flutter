// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:csslib/visitor.dart';
import 'package:source_span/source_span.dart';

/// Can be thrown on any Css runtime problem includes source location.
class CssSelectorException extends SourceSpanException {
  CssSelectorException(String message, [SourceSpan? span])
      : super(message, span);
}

List<String> classes = [];
List<String> ids = [];

class Validate {
  static int _classNameCheck(SimpleSelectorSequence selector, int matches) {
    if (selector.isCombinatorDescendant ||
        (selector.isCombinatorNone && matches == 0)) {
      if (matches < 0) {
        var tooMany = selector.simpleSelector.toString();
        throw CssSelectorException(
            'Can not mix Id selector with class selector(s). Id '
            'selector must be singleton too many starting at $tooMany');
      }

      return matches + 1;
    } else {
      var error = selector.toString();
      throw CssSelectorException(
          'Selectors can not have combinators (>, +, or ~) before $error');
    }
  }

  static int _elementIdCheck(SimpleSelectorSequence selector, int matches) {
    if (selector.isCombinatorNone && matches == 0) {
      // Perfect just one element id returns matches of -1.
      return -1;
    } else if (selector.isCombinatorDescendant) {
      var tooMany = selector.simpleSelector.toString();
      throw CssSelectorException(
          'Use of Id selector must be singleton starting at $tooMany');
    } else {
      var error = selector.simpleSelector.toString();
      throw CssSelectorException(
          'Selectors can not have combinators (>, +, or ~) before $error');
    }
  }

  // Validate the @{css expression} only .class and #elementId are valid inside
  // of @{...}.
  static void template(List<Selector> selectors) {
    var found = false; // signal if a selector is matched.
    var matches = 0; // < 0 IdSelectors, > 0 ClassSelector

    // At most one selector group (any number of simple selector sequences).
    assert(selectors.length <= 1);

    for (final sels in selectors) {
      for (final selector in sels.simpleSelectorSequences) {
        found = false;
        var simpleSelector = selector.simpleSelector;
        if (simpleSelector is ClassSelector) {
          // Any class name starting with an underscore is a private class name
          // that doesn't have to match the world of known classes.
          if (!simpleSelector.name.startsWith('_')) {
            // TODO(terry): For now iterate through all classes look for faster
            //              mechanism hash map, etc.
            for (final className in classes) {
              if (selector.simpleSelector.name == className) {
                matches = _classNameCheck(selector, matches);
                found = true; // .class found.
                break;
              }
              for (final className2 in classes) {
                print(className2);
              }
            }
          } else {
            // Don't check any class name that is prefixed with an underscore.
            // However, signal as found and bump up matches; it's a valid class
            // name.
            matches = _classNameCheck(selector, matches);
            found = true; // ._class are always okay.
          }
        } else if (simpleSelector is IdSelector) {
          // Any element id starting with an underscore is a private element id
          // that doesn't have to match the world of known elemtn ids.
          if (!simpleSelector.name.startsWith('_')) {
            for (final id in ids) {
              if (simpleSelector.name == id) {
                matches = _elementIdCheck(selector, matches);
                found = true; // #id found.
                break;
              }
            }
          } else {
            // Don't check any element ID that is prefixed with an underscore.
            // Signal as found and bump up matches; it's a valid element ID.
            matches = _elementIdCheck(selector, matches);
            found = true; // #_id are always okay
          }
        } else {
          var badSelector = simpleSelector.toString();
          throw CssSelectorException('Invalid template selector $badSelector');
        }

        if (!found) {
          var unknownName = simpleSelector.toString();
          throw CssSelectorException('Unknown selector name $unknownName');
        }
      }
    }

    // Every selector must match.
    var selector = selectors[0];
    assert((matches >= 0 ? matches : -matches) ==
        selector.simpleSelectorSequences.length);
  }
}

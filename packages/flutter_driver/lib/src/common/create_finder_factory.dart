// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'error.dart';
import 'find.dart';

/// A factory which creates [Finder]s from [SerializableFinder]s.
mixin CreateFinderFactory {
  /// Creates the flutter widget finder from [SerializableFinder].
  Finder createFinder(SerializableFinder finder) {
    final String finderType = finder.finderType;
    switch (finderType) {
      case 'ByText':
        return _createByTextFinder(finder as ByText);
      case 'ByTooltipMessage':
        return _createByTooltipMessageFinder(finder as ByTooltipMessage);
      case 'BySemanticsLabel':
        return _createBySemanticsLabelFinder(finder as BySemanticsLabel);
      case 'ByValueKey':
        return _createByValueKeyFinder(finder as ByValueKey);
      case 'ByType':
        return _createByTypeFinder(finder as ByType);
      case 'PageBack':
        return _createPageBackFinder();
      case 'Ancestor':
        return _createAncestorFinder(finder as Ancestor);
      case 'Descendant':
        return _createDescendantFinder(finder as Descendant);
      default:
        throw DriverError('Unsupported search specification type $finderType');
    }
  }

  Finder _createByTextFinder(ByText arguments) {
    return find.text(arguments.text);
  }

  Finder _createByTooltipMessageFinder(ByTooltipMessage arguments) {
    return find.byElementPredicate((Element element) {
      final Widget widget = element.widget;
      if (widget is Tooltip) {
        return widget.message == arguments.text;
      }
      return false;
    }, description: 'widget with text tooltip "${arguments.text}"');
  }

  Finder _createBySemanticsLabelFinder(BySemanticsLabel arguments) {
    return find.byElementPredicate((Element element) {
      if (element is! RenderObjectElement) {
        return false;
      }
      final String? semanticsLabel = element.renderObject.debugSemantics?.label;
      if (semanticsLabel == null) {
        return false;
      }
      final Pattern label = arguments.label;
      return label is RegExp
          ? label.hasMatch(semanticsLabel)
          : label == semanticsLabel;
    }, description: 'widget with semantic label "${arguments.label}"');
  }

  Finder _createByValueKeyFinder(ByValueKey arguments) {
    switch (arguments.keyValueType) {
      case 'int':
        return find.byKey(ValueKey<int>(arguments.keyValue as int));
      case 'String':
        return find.byKey(ValueKey<String>(arguments.keyValue as String));
      default:
        throw 'Unsupported ByValueKey type: ${arguments.keyValueType}';
    }
  }

  Finder _createByTypeFinder(ByType arguments) {
    return find.byElementPredicate((Element element) {
      return element.widget.runtimeType.toString() == arguments.type;
    }, description: 'widget with runtimeType "${arguments.type}"');
  }

  Finder _createPageBackFinder() {
    return find.byElementPredicate((Element element) {
      final Widget widget = element.widget;
      if (widget is Tooltip) {
        return widget.message == 'Back';
      }
      if (widget is CupertinoNavigationBarBackButton) {
        return true;
      }
      return false;
    }, description: 'Material or Cupertino back button');
  }

  Finder _createAncestorFinder(Ancestor arguments) {
    final Finder finder = find.ancestor(
      of: createFinder(arguments.of),
      matching: createFinder(arguments.matching),
      matchRoot: arguments.matchRoot,
    );
    return arguments.firstMatchOnly ? finder.first : finder;
  }

  Finder _createDescendantFinder(Descendant arguments) {
    final Finder finder = find.descendant(
      of: createFinder(arguments.of),
      matching: createFinder(arguments.matching),
      matchRoot: arguments.matchRoot,
    );
    return arguments.firstMatchOnly ? finder.first : finder;
  }
}

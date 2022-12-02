// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'framework.dart';

class LookupBoundary extends InheritedWidget {
  const LookupBoundary({super.key, required super.child});

  /// Behaves exactly like [BuildContext.findAncestorWidgetOfExactType], but
  /// only finds widgets of the specified type `T` between `context` and its
  /// closest [LookupBoundary] ancestor.
  static T? findAncestorWidgetOfExactType<T extends Widget>(BuildContext context) {
    Element? target;
    context.visitAncestorElements((Element element) {
      if (element.widget.runtimeType == T) {
        target = element;
        return false;
      }
      return element.widget.runtimeType != LookupBoundary;
    });
    return target?.widget as T?;
  }

  static T? findAncestorRenderObjectOfType<T extends RenderObject>(BuildContext context) {
    Element? target;
    context.visitAncestorElements((Element element) {
      if (element is RenderObjectElement && element.renderObject is T) {
        target = element;
        return false;
      }
      return element.widget.runtimeType != LookupBoundary;
    });
    return target?.renderObject as T?;
  }

  static T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>(BuildContext context, { Object? aspect }) {
    // Make sure context depends on something so Element.didChangeDependencies
    // is called when context moves in the tree even when requested dependency
    // remains unfulfilled.
    context.dependOnInheritedWidgetOfExactType<LookupBoundary>();
    final InheritedElement? target = context.getElementForInheritedWidgetOfExactType<T>();
    if (target == null) {
      return null;
    }
    final Element? boundary = context.getElementForInheritedWidgetOfExactType<LookupBoundary>();
    if (boundary != null && boundary.depth > target.depth) {
      return null;
    }
    context.dependOnInheritedElement(target, aspect: aspect);
    return target.widget as T;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

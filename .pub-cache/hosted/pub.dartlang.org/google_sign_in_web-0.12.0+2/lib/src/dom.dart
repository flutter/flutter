// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS()
@staticInterop
class DomConsole {}

extension DomConsoleExtension on DomConsole {
  void debug(String message, [List<Object?>? more]) =>
      js_util.callMethod(this, 'debug', <Object?>[message, ...?more]);
  void info(String message, [List<Object?>? more]) =>
      js_util.callMethod(this, 'info', <Object?>[message, ...?more]);
  void warn(String message, [List<Object?>? more]) =>
      js_util.callMethod(this, 'warn', <Object?>[message, ...?more]);
}

@JS()
@staticInterop
class DomWindow {}

@JS()
@staticInterop
class DomDocument {}

extension DomDocumentExtension on DomDocument {
  external DomElement? querySelector(String selectors);
  DomElement createElement(String name, [Object? options]) =>
      js_util.callMethod(this, 'createElement',
          <Object>[name, if (options != null) options]) as DomElement;
}

@JS()
@staticInterop
class DomElement {}

extension DomElementExtension on DomElement {
  external String get id;
  external set id(String id);
  external String? getAttribute(String attributeName);
  external void remove();
  external void setAttribute(String name, Object value);
  external void removeAttribute(String name);
  external set tabIndex(double? value);
  external double? get tabIndex;
  external set className(String value);
  external String get className;
  external bool hasAttribute(String name);
  external DomElement? get firstChild;
  external DomElement? querySelector(String selectors);
  external String get tagName;
}

@JS('window')
external DomWindow get domWindow;

@JS('document')
external DomDocument get domDocument;

@JS('console')
external DomConsole get domConsole;

DomElement createDomElement(String tag) => domDocument.createElement(tag);

/// DOM Observers: Mutation and Size
typedef DomMutationCallbackFn = void Function(
    List<DomMutationRecord> mutation, DomMutationObserver observer);

@JS()
@staticInterop
class DomMutationObserver {}

DomMutationObserver createDomMutationObserver(DomMutationCallbackFn fn) =>
    domCallConstructorString('MutationObserver', <Object>[
      allowInterop(
        (List<dynamic> mutations, DomMutationObserver observer) {
          fn(mutations.cast<DomMutationRecord>(), observer);
        },
      )
    ])! as DomMutationObserver;

extension DomMutationObserverExtension on DomMutationObserver {
  external void disconnect();
  void observe(DomElement target,
      {bool? childList,
      bool? attributes,
      bool? subtree,
      List<String>? attributeFilter}) {
    final Map<String, dynamic> options = <String, dynamic>{
      if (childList != null) 'childList': childList,
      if (attributes != null) 'attributes': attributes,
      if (subtree != null) 'subtree': subtree,
      if (attributeFilter != null) 'attributeFilter': attributeFilter
    };
    return js_util
        .callMethod(this, 'observe', <Object?>[target, js_util.jsify(options)]);
  }
}

@JS()
@staticInterop
class DomMutationRecord {}

extension DomMutationRecordExtension on DomMutationRecord {
  external List<DomElement>? get addedNodes;
  external List<DomElement>? get removedNodes;
  external String? get attributeName;
  external String? get type;
}

/// ResizeObserver JS binding.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver
@JS()
@staticInterop
abstract class DomResizeObserver {}

/// Creates a DomResizeObserver with a callback.
///
/// Internally converts the `List<dynamic>` of entries into the expected
/// `List<DomResizeObserverEntry>`
DomResizeObserver? createDomResizeObserver(DomResizeObserverCallbackFn fn) {
  return domCallConstructorString('ResizeObserver', <Object?>[
    allowInterop((List<dynamic> entries, DomResizeObserver observer) {
      fn(entries.cast<DomResizeObserverEntry>(), observer);
    }),
  ]) as DomResizeObserver?;
}

/// ResizeObserver instance methods.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver#instance_methods
extension DomResizeObserverExtension on DomResizeObserver {
  external void disconnect();
  external void observe(DomElement target,
      [DomResizeObserverObserveOptions options]);
  external void unobserve(DomElement target);
}

/// Options object passed to the `observe` method of a [DomResizeObserver].
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver/observe#parameters
@JS()
@staticInterop
@anonymous
abstract class DomResizeObserverObserveOptions {
  external factory DomResizeObserverObserveOptions({
    String box,
  });
}

/// Type of the function used to create a Resize Observer.
typedef DomResizeObserverCallbackFn = void Function(
    List<DomResizeObserverEntry> entries, DomResizeObserver observer);

/// The object passed to the [DomResizeObserverCallbackFn], which allows access to the new dimensions of the observed element.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserverEntry
@JS()
@staticInterop
abstract class DomResizeObserverEntry {}

/// ResizeObserverEntry instance properties.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserverEntry#instance_properties
extension DomResizeObserverEntryExtension on DomResizeObserverEntry {
  /// A DOMRectReadOnly object containing the new size of the observed element when the callback is run.
  ///
  /// Note that this is better supported than the above two properties, but it
  /// is left over from an earlier implementation of the Resize Observer API, is
  /// still included in the spec for web compat reasons, and may be deprecated
  /// in future versions.
  external DomRectReadOnly get contentRect;
  external DomElement get target;
  // Some more future getters:
  //
  // borderBoxSize
  // contentBoxSize
  // devicePixelContentBoxSize
}

@JS()
@staticInterop
class DomRectReadOnly {}

extension DomRectReadOnlyExtension on DomRectReadOnly {
  external double get x;
  external double get y;
  external double get width;
  external double get height;
  external double get top;
  external double get right;
  external double get bottom;
  external double get left;
}

Object? domGetConstructor(String constructorName) =>
    js_util.getProperty(domWindow, constructorName);

T? domCallConstructorString<T>(String constructorName, List<Object?> args) {
  final Object? constructor = domGetConstructor(constructorName);
  if (constructor == null) {
    return null;
  }
  return js_util.callConstructor<T>(constructor, args);
}

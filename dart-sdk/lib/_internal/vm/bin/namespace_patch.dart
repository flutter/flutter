// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'common_patch.dart';

@pragma("vm:entry-point")
base class _NamespaceImpl extends NativeFieldWrapperClass1
    implements _Namespace {
  _NamespaceImpl._();

  @pragma("vm:external-name", "Namespace_Create")
  external static _NamespaceImpl _create(_NamespaceImpl namespace, var n);
  @pragma("vm:external-name", "Namespace_GetPointer")
  external static int _getPointer(_NamespaceImpl namespace);
  @pragma("vm:external-name", "Namespace_GetDefault")
  external static int _getDefault();

  // If the platform supports "namespaces", this method is called by the
  // embedder with the platform-specific namespace information.
  static _NamespaceImpl? _cachedNamespace = null;
  static void _setupNamespace(var namespace) {
    _cachedNamespace = _create(new _NamespaceImpl._(), namespace);
  }

  static _NamespaceImpl get _namespace {
    if (_cachedNamespace == null) {
      // The embedder has not supplied a namespace before one is needed, so
      // instead use a safe-ish default value.
      _cachedNamespace = _create(new _NamespaceImpl._(), _getDefault());
    }
    return _cachedNamespace!;
  }

  static int get _namespacePointer => _getPointer(_namespace);
}

@patch
@pragma("vm:entry-point")
class _Namespace {
  @patch
  @pragma("vm:entry-point", "call")
  static void _setupNamespace(var namespace) {
    _NamespaceImpl._setupNamespace(namespace);
  }

  @patch
  static _Namespace get _namespace => _NamespaceImpl._namespace;

  @patch
  static int get _namespacePointer => _NamespaceImpl._namespacePointer;
}

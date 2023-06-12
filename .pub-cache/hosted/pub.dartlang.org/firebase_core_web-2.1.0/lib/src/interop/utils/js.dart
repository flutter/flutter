// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This class is a wrapper for the jsObject. All the specific JsObject
/// wrappers extend from it.
abstract class JsObjectWrapper<T> {
  /// Creates a new JsObjectWrapper type from a [jsObject].
  JsObjectWrapper.fromJsObject(this.jsObject);

  /// JS object.
  final T jsObject;
}

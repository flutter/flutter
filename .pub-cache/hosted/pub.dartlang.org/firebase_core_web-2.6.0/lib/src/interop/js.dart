// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*
// DOM shim. This file contains everything we need from the DOM API written as
// @staticInterop, so we don't need dart:html
// https://developer.mozilla.org/en-US/docs/Web/API/
*/

import 'package:js/js.dart';

/// console interface
@JS()
@staticInterop
@anonymous
abstract class DomConsole {}

/// The interface of window.console
extension DomConsoleExtension on DomConsole {
  /// console.debug
  external DomConsoleDumpFn get debug;

  /// console.info
  external DomConsoleDumpFn get info;

  /// console.log
  external DomConsoleDumpFn get log;

  /// console.warn
  external DomConsoleDumpFn get warn;

  /// console.error
  external DomConsoleDumpFn get error;
}

/// Fakey variadic-type for console-dumping methods (like console.log or info).
typedef DomConsoleDumpFn = void Function(
  Object? arg, [
  Object? arg2,
  Object? arg3,
  Object? arg4,
  Object? arg5,
  Object? arg6,
  Object? arg7,
  Object? arg8,
  Object? arg9,
  Object? arg10,
]);

/// Error object
@JS('Error')
@staticInterop
abstract class DomError {}

/// Methods on the error object
extension DomErrorExtension on DomError {
  /// Error message.
  external String? get message;

  /// Stack trace.
  external String? get stack;

  /// Error name. This is determined by the constructor function.
  external String get name;

  /// Error cause indicating the reason why the current error is thrown.
  ///
  /// This is usually another caught error, or the value provided as the `cause`
  /// property of the Error constructor's second argument.
  external Object? get cause;
}

/*
// Trusted Types API (TrustedTypePolicy, TrustedScript, TrustedScriptURL)
// https://developer.mozilla.org/en-US/docs/Web/API/TrustedTypesAPI
*/

/// A factory to create `TrustedTypePolicy` objects.
@JS()
@staticInterop
@anonymous
abstract class DomTrustedTypePolicyFactory {}

/// (Some) methods of the [DomTrustedTypePolicyFactory]:
extension DomTrustedTypePolicyFactoryExtension on DomTrustedTypePolicyFactory {
  /// createPolicy
  external DomTrustedTypePolicy createPolicy(
    String policyName,
    DomTrustedTypePolicyOptions? policyOptions,
  );
}

/// Options to create a trusted type policy.
@JS()
@staticInterop
@anonymous
abstract class DomTrustedTypePolicyOptions {
  /// Constructs a TrustedPolicyOptions object in JavaScript.
  ///
  /// The following properties need to be manually wrapped in [allowInterop]
  /// before being passed to this constructor: [createScriptURL].
  external factory DomTrustedTypePolicyOptions({
    DomCreateScriptUrlOptionFn? createScriptURL,
  });
}

/// Type of the function to configure createScriptURL
typedef DomCreateScriptUrlOptionFn = String Function(String input);

/// An instance of a TrustedTypePolicy
@JS()
@staticInterop
@anonymous
abstract class DomTrustedTypePolicy {}

/// (Some) methods of the [DomTrustedTypePolicy]
extension DomTrustedTypePolicyExtension on DomTrustedTypePolicy {
  /// Create a `TrustedScriptURL` for the given [input].
  external DomTrustedScriptUrl createScriptURL(String input);
}

/// An instance of a DomTrustedScriptUrl
@JS()
@staticInterop
@anonymous
abstract class DomTrustedScriptUrl {}

// Getters

/// window.trustedTypes (may or may not be supported by the browser)
@JS()
@staticInterop
@anonymous
external DomTrustedTypePolicyFactory? get trustedTypes;

/// window.console
@JS()
@staticInterop
@anonymous
external DomConsole get console;

// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

typedef HTMLString = String;
typedef ScriptString = String;
typedef ScriptURLString = String;
typedef TrustedType = JSObject;
typedef CreateHTMLCallback = JSFunction;
typedef CreateScriptCallback = JSFunction;
typedef CreateScriptURLCallback = JSFunction;

@JS('TrustedHTML')
@staticInterop
class TrustedHTML {
  external static TrustedHTML fromLiteral(JSObject templateStringsArray);
}

extension TrustedHTMLExtension on TrustedHTML {
  external String toJSON();
}

@JS('TrustedScript')
@staticInterop
class TrustedScript {
  external static TrustedScript fromLiteral(JSObject templateStringsArray);
}

extension TrustedScriptExtension on TrustedScript {
  external String toJSON();
}

@JS('TrustedScriptURL')
@staticInterop
class TrustedScriptURL {
  external static TrustedScriptURL fromLiteral(JSObject templateStringsArray);
}

extension TrustedScriptURLExtension on TrustedScriptURL {
  external String toJSON();
}

@JS('TrustedTypePolicyFactory')
@staticInterop
class TrustedTypePolicyFactory {}

extension TrustedTypePolicyFactoryExtension on TrustedTypePolicyFactory {
  external TrustedTypePolicy createPolicy(
    String policyName, [
    TrustedTypePolicyOptions policyOptions,
  ]);
  external bool isHTML(JSAny? value);
  external bool isScript(JSAny? value);
  external bool isScriptURL(JSAny? value);
  external String? getAttributeType(
    String tagName,
    String attribute, [
    String elementNs,
    String attrNs,
  ]);
  external String? getPropertyType(
    String tagName,
    String property, [
    String elementNs,
  ]);
  external TrustedHTML get emptyHTML;
  external TrustedScript get emptyScript;
  external TrustedTypePolicy? get defaultPolicy;
}

@JS('TrustedTypePolicy')
@staticInterop
class TrustedTypePolicy {}

extension TrustedTypePolicyExtension on TrustedTypePolicy {
  external TrustedHTML createHTML(
    String input,
    JSAny? arguments,
  );
  external TrustedScript createScript(
    String input,
    JSAny? arguments,
  );
  external TrustedScriptURL createScriptURL(
    String input,
    JSAny? arguments,
  );
  external String get name;
}

@JS()
@staticInterop
@anonymous
class TrustedTypePolicyOptions {
  external factory TrustedTypePolicyOptions({
    CreateHTMLCallback? createHTML,
    CreateScriptCallback? createScript,
    CreateScriptURLCallback? createScriptURL,
  });
}

extension TrustedTypePolicyOptionsExtension on TrustedTypePolicyOptions {
  external set createHTML(CreateHTMLCallback? value);
  external CreateHTMLCallback? get createHTML;
  external set createScript(CreateScriptCallback? value);
  external CreateScriptCallback? get createScript;
  external set createScriptURL(CreateScriptURLCallback? value);
  external CreateScriptURLCallback? get createScriptURL;
}

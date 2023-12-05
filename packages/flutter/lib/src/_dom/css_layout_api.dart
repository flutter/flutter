// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'css_typed_om.dart';
import 'html.dart';
import 'webidl.dart';

typedef ChildDisplayType = String;
typedef LayoutSizingMode = String;
typedef BlockFragmentationType = String;
typedef BreakType = String;

@JS('LayoutWorkletGlobalScope')
@staticInterop
class LayoutWorkletGlobalScope implements WorkletGlobalScope {}

extension LayoutWorkletGlobalScopeExtension on LayoutWorkletGlobalScope {
  external void registerLayout(
    String name,
    VoidFunction layoutCtor,
  );
}

@JS()
@staticInterop
@anonymous
class LayoutOptions {
  external factory LayoutOptions({
    ChildDisplayType childDisplay,
    LayoutSizingMode sizing,
  });
}

extension LayoutOptionsExtension on LayoutOptions {
  external set childDisplay(ChildDisplayType value);
  external ChildDisplayType get childDisplay;
  external set sizing(LayoutSizingMode value);
  external LayoutSizingMode get sizing;
}

@JS('LayoutChild')
@staticInterop
class LayoutChild {}

extension LayoutChildExtension on LayoutChild {
  external JSPromise intrinsicSizes();
  external JSPromise layoutNextFragment(
    LayoutConstraintsOptions constraints,
    ChildBreakToken breakToken,
  );
  external StylePropertyMapReadOnly get styleMap;
}

@JS('LayoutFragment')
@staticInterop
class LayoutFragment {}

extension LayoutFragmentExtension on LayoutFragment {
  external num get inlineSize;
  external num get blockSize;
  external set inlineOffset(num value);
  external num get inlineOffset;
  external set blockOffset(num value);
  external num get blockOffset;
  external JSAny? get data;
  external ChildBreakToken? get breakToken;
}

@JS('IntrinsicSizes')
@staticInterop
class IntrinsicSizes {}

extension IntrinsicSizesExtension on IntrinsicSizes {
  external num get minContentSize;
  external num get maxContentSize;
}

@JS('LayoutConstraints')
@staticInterop
class LayoutConstraints {}

extension LayoutConstraintsExtension on LayoutConstraints {
  external num get availableInlineSize;
  external num get availableBlockSize;
  external num? get fixedInlineSize;
  external num? get fixedBlockSize;
  external num get percentageInlineSize;
  external num get percentageBlockSize;
  external num? get blockFragmentationOffset;
  external BlockFragmentationType get blockFragmentationType;
  external JSAny? get data;
}

@JS()
@staticInterop
@anonymous
class LayoutConstraintsOptions {
  external factory LayoutConstraintsOptions({
    num availableInlineSize,
    num availableBlockSize,
    num fixedInlineSize,
    num fixedBlockSize,
    num percentageInlineSize,
    num percentageBlockSize,
    num blockFragmentationOffset,
    BlockFragmentationType blockFragmentationType,
    JSAny? data,
  });
}

extension LayoutConstraintsOptionsExtension on LayoutConstraintsOptions {
  external set availableInlineSize(num value);
  external num get availableInlineSize;
  external set availableBlockSize(num value);
  external num get availableBlockSize;
  external set fixedInlineSize(num value);
  external num get fixedInlineSize;
  external set fixedBlockSize(num value);
  external num get fixedBlockSize;
  external set percentageInlineSize(num value);
  external num get percentageInlineSize;
  external set percentageBlockSize(num value);
  external num get percentageBlockSize;
  external set blockFragmentationOffset(num value);
  external num get blockFragmentationOffset;
  external set blockFragmentationType(BlockFragmentationType value);
  external BlockFragmentationType get blockFragmentationType;
  external set data(JSAny? value);
  external JSAny? get data;
}

@JS('ChildBreakToken')
@staticInterop
class ChildBreakToken {}

extension ChildBreakTokenExtension on ChildBreakToken {
  external BreakType get breakType;
  external LayoutChild get child;
}

@JS('BreakToken')
@staticInterop
class BreakToken {}

extension BreakTokenExtension on BreakToken {
  external JSArray get childBreakTokens;
  external JSAny? get data;
}

@JS()
@staticInterop
@anonymous
class BreakTokenOptions {
  external factory BreakTokenOptions({
    JSArray childBreakTokens,
    JSAny? data,
  });
}

extension BreakTokenOptionsExtension on BreakTokenOptions {
  external set childBreakTokens(JSArray value);
  external JSArray get childBreakTokens;
  external set data(JSAny? value);
  external JSAny? get data;
}

@JS('LayoutEdges')
@staticInterop
class LayoutEdges {}

extension LayoutEdgesExtension on LayoutEdges {
  external num get inlineStart;
  external num get inlineEnd;
  external num get blockStart;
  external num get blockEnd;
  external num get inline;
  external num get block;
}

@JS()
@staticInterop
@anonymous
class FragmentResultOptions {
  external factory FragmentResultOptions({
    num inlineSize,
    num blockSize,
    num autoBlockSize,
    JSArray childFragments,
    JSAny? data,
    BreakTokenOptions breakToken,
  });
}

extension FragmentResultOptionsExtension on FragmentResultOptions {
  external set inlineSize(num value);
  external num get inlineSize;
  external set blockSize(num value);
  external num get blockSize;
  external set autoBlockSize(num value);
  external num get autoBlockSize;
  external set childFragments(JSArray value);
  external JSArray get childFragments;
  external set data(JSAny? value);
  external JSAny? get data;
  external set breakToken(BreakTokenOptions value);
  external BreakTokenOptions get breakToken;
}

@JS('FragmentResult')
@staticInterop
class FragmentResult {
  external factory FragmentResult([FragmentResultOptions options]);
}

extension FragmentResultExtension on FragmentResult {
  external num get inlineSize;
  external num get blockSize;
}

@JS()
@staticInterop
@anonymous
class IntrinsicSizesResultOptions {
  external factory IntrinsicSizesResultOptions({
    num maxContentSize,
    num minContentSize,
  });
}

extension IntrinsicSizesResultOptionsExtension on IntrinsicSizesResultOptions {
  external set maxContentSize(num value);
  external num get maxContentSize;
  external set minContentSize(num value);
  external num get minContentSize;
}

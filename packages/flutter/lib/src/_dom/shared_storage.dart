// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'html.dart';

typedef SharedStorageResponse = JSAny;
typedef SharedStorageOperationConstructor = JSFunction;

@JS('SharedStorageWorklet')
@staticInterop
class SharedStorageWorklet implements Worklet {}

@JS('SharedStorageWorkletGlobalScope')
@staticInterop
class SharedStorageWorkletGlobalScope implements WorkletGlobalScope {}

extension SharedStorageWorkletGlobalScopeExtension
    on SharedStorageWorkletGlobalScope {
  external void register(
    String name,
    SharedStorageOperationConstructor operationCtor,
  );
  external WorkletSharedStorage get sharedStorage;
}

@JS('SharedStorageOperation')
@staticInterop
class SharedStorageOperation {}

@JS()
@staticInterop
@anonymous
class SharedStorageRunOperationMethodOptions {
  external factory SharedStorageRunOperationMethodOptions({
    JSObject data,
    bool resolveToConfig,
    bool keepAlive,
  });
}

extension SharedStorageRunOperationMethodOptionsExtension
    on SharedStorageRunOperationMethodOptions {
  external set data(JSObject value);
  external JSObject get data;
  external set resolveToConfig(bool value);
  external bool get resolveToConfig;
  external set keepAlive(bool value);
  external bool get keepAlive;
}

@JS('SharedStorageRunOperation')
@staticInterop
class SharedStorageRunOperation implements SharedStorageOperation {}

extension SharedStorageRunOperationExtension on SharedStorageRunOperation {
  external JSPromise run(JSObject data);
}

@JS('SharedStorageSelectURLOperation')
@staticInterop
class SharedStorageSelectURLOperation implements SharedStorageOperation {}

extension SharedStorageSelectURLOperationExtension
    on SharedStorageSelectURLOperation {
  external JSPromise run(
    JSObject data,
    JSArray urls,
  );
}

@JS('SharedStorage')
@staticInterop
class SharedStorage {}

extension SharedStorageExtension on SharedStorage {
  external JSPromise set(
    String key,
    String value, [
    SharedStorageSetMethodOptions options,
  ]);
  external JSPromise append(
    String key,
    String value,
  );
  external JSPromise delete(String key);
  external JSPromise clear();
}

@JS()
@staticInterop
@anonymous
class SharedStorageSetMethodOptions {
  external factory SharedStorageSetMethodOptions({bool ignoreIfPresent});
}

extension SharedStorageSetMethodOptionsExtension
    on SharedStorageSetMethodOptions {
  external set ignoreIfPresent(bool value);
  external bool get ignoreIfPresent;
}

@JS('WindowSharedStorage')
@staticInterop
class WindowSharedStorage implements SharedStorage {}

extension WindowSharedStorageExtension on WindowSharedStorage {
  external JSPromise run(
    String name, [
    SharedStorageRunOperationMethodOptions options,
  ]);
  external JSPromise selectURL(
    String name,
    JSArray urls, [
    SharedStorageRunOperationMethodOptions options,
  ]);
  external SharedStorageWorklet get worklet;
}

@JS()
@staticInterop
@anonymous
class SharedStorageUrlWithMetadata {
  external factory SharedStorageUrlWithMetadata({
    required String url,
    JSObject reportingMetadata,
  });
}

extension SharedStorageUrlWithMetadataExtension
    on SharedStorageUrlWithMetadata {
  external set url(String value);
  external String get url;
  external set reportingMetadata(JSObject value);
  external JSObject get reportingMetadata;
}

@JS('WorkletSharedStorage')
@staticInterop
class WorkletSharedStorage implements SharedStorage {}

extension WorkletSharedStorageExtension on WorkletSharedStorage {
  external JSPromise get(String key);
  external JSPromise length();
  external JSPromise remainingBudget();
}

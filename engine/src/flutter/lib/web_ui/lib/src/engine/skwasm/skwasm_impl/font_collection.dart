// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:js_interop';

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

class SkwasmFontCollection implements FlutterFontCollection {
  SkwasmFontCollection() : _handle = fontCollectionCreate();

  FontCollectionHandle _handle;

  @override
  void clear() {
    fontCollectionDispose(_handle);
    _handle = fontCollectionCreate();
  }

  @override
  Future<AssetFontsResult> loadAssetFonts(FontManifest manifest) async {
    final List<Future<void>> fontFutures = <Future<void>>[];
    final List<String> loadedFonts = <String>[];
    final Map<String, FontLoadError> fontFailures = <String, FontLoadError>{};

    // We can't restore the pointers directly due to a bug in dart2wasm
    // https://github.com/dart-lang/sdk/issues/52142
    final List<int> familyHandles = <int>[];
    for (final FontFamily family in manifest.families) {
      final List<int> rawUtf8Bytes = utf8.encode(family.name);
      final SkStringHandle stringHandle = skStringAllocate(rawUtf8Bytes.length);
      final Pointer<Int8> stringDataPointer = skStringGetData(stringHandle);
      for (int i = 0; i < rawUtf8Bytes.length; i++) {
        stringDataPointer[i] = rawUtf8Bytes[i];
      }
      familyHandles.add(stringHandle.address);
      for (final FontAsset fontAsset in family.fontAssets) {
        fontFutures.add(() async {
          final FontLoadError? error = await _downloadFontAsset(fontAsset, stringHandle);
          if (error == null) {
            loadedFonts.add(fontAsset.asset);
          } else {
            fontFailures[fontAsset.asset] = error;
          }
        }());
      }
    }
    await Future.wait(fontFutures);

    // Wait until all the downloading and registering is complete before
    // freeing the handles to the family name strings.
    familyHandles
      .map((int address) => SkStringHandle.fromAddress(address))
      .forEach(skStringFree);
    return AssetFontsResult(loadedFonts, fontFailures);
  }

  Future<FontLoadError?> _downloadFontAsset(FontAsset asset, SkStringHandle familyNameHandle) async {
    final HttpFetchResponse response;
    try {
      response = await assetManager.loadAsset(asset.asset);
    } catch (error) {
      return FontDownloadError(assetManager.getAssetUrl(asset.asset), error);
    }
    if (!response.hasPayload) {
      return FontNotFoundError(assetManager.getAssetUrl(asset.asset));
    }
    int length = 0;
    final List<JSUint8Array1> chunks = <JSUint8Array1>[];
    await response.read((JSUint8Array1 chunk) {
      length += chunk.length.toDart.toInt();
      chunks.add(chunk);
    });
    final SkDataHandle fontData = skDataCreate(length);
    int dataAddress = skDataGetPointer(fontData).cast<Int8>().address;
    final JSUint8Array1 wasmMemory = createUint8ArrayFromBuffer(skwasmInstance.wasmMemory.buffer);
    for (final JSUint8Array1 chunk in chunks) {
      wasmMemory.set(chunk, dataAddress.toJS);
      dataAddress += chunk.length.toDart.toInt();
    }
    final bool result = fontCollectionRegisterFont(_handle, fontData, familyNameHandle);
    skDataDispose(fontData);
    if (!result) {
      return FontInvalidDataError(assetManager.getAssetUrl(asset.asset));
    }
    return null;
  }

  @override
  Future<bool> loadFontFromList(Uint8List list, {String? fontFamily}) async {
    final SkDataHandle dataHandle = skDataCreate(list.length);
    final Pointer<Int8> dataPointer = skDataGetPointer(dataHandle).cast<Int8>();
    for (int i = 0; i < list.length; i++) {
      dataPointer[i] = list[i];
    }
    bool success;
    if (fontFamily != null) {
      final List<int> rawUtf8Bytes = utf8.encode(fontFamily);
      final SkStringHandle stringHandle = skStringAllocate(rawUtf8Bytes.length);
      final Pointer<Int8> stringDataPointer = skStringGetData(stringHandle);
      for (int i = 0; i < rawUtf8Bytes.length; i++) {
        stringDataPointer[i] = rawUtf8Bytes[i];
      }
      success = fontCollectionRegisterFont(_handle, dataHandle, stringHandle);
      skStringFree(stringHandle);
    } else {
      success = fontCollectionRegisterFont(_handle, dataHandle, nullptr);
    }
    skDataDispose(dataHandle);
    return success;
  }
}

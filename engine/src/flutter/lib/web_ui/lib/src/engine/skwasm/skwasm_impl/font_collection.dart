// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

class SkwasmTypeface extends SkwasmObjectWrapper<RawTypeface> implements BackendTypeface {
  SkwasmTypeface(TypefaceHandle handle)
    : super(handle, (TypefaceHandle h) => typefaceDispose(h), 'Typeface');

  @override
  String get familyName {
    final SkStringHandle familyNameHandle = typefaceGetFamilyName(handle);
    final String familyName = skStringToDartString(familyNameHandle);
    skStringFree(familyNameHandle);
    return familyName;
  }
}

/// The Skwasm font registry behind [EngineFontCollection].
class SkwasmFontCollection implements BackendFontCollection {
  // Most of the time, when an object deals with native handles to skwasm objects,
  // we register it with a finalization registry so that it can clean up the handle
  // when the dart side of object gets GC'd. However, this object is basically a
  // singleton (the renderer creates one and just hangs onto it forever) so it's
  // not really worth it to do the finalization dance here.
  FontCollectionHandle handle = fontCollectionCreate();

  /// The text style every paragraph and text style starts from.
  ///
  /// Its font families are the fallback families set by
  /// [setFallbackFontFamilies]; styles prepend their own families to it.
  SkwasmNativeTextStyle defaultTextStyle = SkwasmNativeTextStyle.defaultTextStyle();

  @override
  void setFallbackFontFamilies(List<String> families) => withStackScope((StackScope scope) {
    final Pointer<SkStringHandle> familyPointers = scope
        .allocPointerArray(families.length)
        .cast<SkStringHandle>();
    for (var i = 0; i < families.length; i++) {
      familyPointers[i] = skStringFromDartString(families[i]);
    }
    textStyleClearFontFamilies(defaultTextStyle.handle);
    textStyleAddFontFamilies(defaultTextStyle.handle, familyPointers, families.length);
    for (var i = 0; i < families.length; i++) {
      skStringFree(familyPointers[i]);
    }
  });

  @override
  Future<BackendTypeface?> createTypeface(Uint8List bytes) async {
    final SkDataHandle fontData = skDataCreate(bytes.length);
    final int dataAddress = skDataGetPointer(fontData).cast<Int8>().address;
    final wasmMemory = JSUint8Array(skwasmInstance.wasmMemory.buffer);
    wasmMemory.set(bytes.toJS, dataAddress);
    final TypefaceHandle typefaceHandle = typefaceCreate(fontData);
    skDataDispose(fontData);
    if (typefaceHandle == nullptr) {
      return null;
    }
    return SkwasmTypeface(typefaceHandle);
  }

  @override
  void registerTypeface(BackendTypeface typeface, String family) {
    final SkStringHandle familyHandle = skStringFromDartString(family);
    fontCollectionRegisterTypeface(handle, (typeface as SkwasmTypeface).handle, familyHandle);
    skStringFree(familyHandle);
    // Paragraphs laid out before this registration may have cached a fallback
    // for this family.
    fontCollectionClearCaches(handle);
  }

  @override
  void clear() {
    fontCollectionDispose(handle);
    handle = fontCollectionCreate();
  }
}

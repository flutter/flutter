// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

// This URL was found by using the Google Fonts Developer API to find the URL
// for Roboto. The API warns that this URL is not stable. In order to update
// this, list out all of the fonts and find the URL for the regular
// Roboto font. The API reference is here:
// https://developers.google.com/fonts/docs/developer_api
String _robotoUrl =
    '${configuration.fontFallbackBaseUrl}roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2';

class SkwasmTypeface extends SkwasmObjectWrapper<RawTypeface> {
  SkwasmTypeface(SkDataHandle data)
    : super(typefaceCreate(data), (TypefaceHandle h) => typefaceDispose(h), 'Typeface');
}

class SkwasmFontCollection implements FlutterFontCollection {
  SkwasmFontCollection() {
    _fallbackRegistry = SkwasmFallbackRegistry(this);
    fontFallbackManager = FontFallbackManager(_fallbackRegistry);
    setDefaultFontFamilies(<String>['Roboto']);
  }

  // Most of the time, when an object deals with native handles to skwasm objects,
  // we register it with a finalization registry so that it can clean up the handle
  // when the dart side of object gets GC'd. However, this object is basically a
  // singleton (the renderer creates one and just hangs onto it forever) so it's
  // not really worth it to do the finalization dance here.
  FontCollectionHandle handle = fontCollectionCreate();
  SkwasmNativeTextStyle defaultTextStyle = SkwasmNativeTextStyle.defaultTextStyle();
  final Map<String, List<SkwasmTypeface>> registeredTypefaces = <String, List<SkwasmTypeface>>{};

  void setDefaultFontFamilies(List<String> families) => withStackScope((StackScope scope) {
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

  @visibleForTesting
  @override
  set fontFallbackManager(FontFallbackManager? value) {
    _fontFallbackManager = value;
  }

  FontFallbackManager? _fontFallbackManager;

  @override
  FontFallbackManager? get fontFallbackManager => _fontFallbackManager;

  late FallbackFontRegistry _fallbackRegistry;

  @override
  FallbackFontRegistry get fallbackFontRegistry => _fallbackRegistry;

  @visibleForTesting
  @override
  set fallbackFontRegistry(FallbackFontRegistry? registry) {
    _fallbackRegistry = registry!;
  }

  @override
  void clear() {
    fontCollectionDispose(handle);
    handle = fontCollectionCreate();
  }

  @override
  Future<AssetFontsResult> loadAssetFonts(FontManifest manifest) async {
    final fontFutures = <Future<void>>[];
    final fontFailures = <String, FontLoadError>{};

    /// We need a default fallback font for Skwasm, in order to avoid crashing
    /// while laying out text with an unregistered font. We chose Roboto to
    /// match Android.
    if (!manifest.families.any((FontFamily family) => family.name == 'Roboto')) {
      manifest.families.add(
        FontFamily('Roboto', <FontAsset>[FontAsset(_robotoUrl, <String, String>{})]),
      );
    }

    final loadedFonts = <String>[];
    for (final FontFamily family in manifest.families) {
      for (final FontAsset fontAsset in family.fontAssets) {
        loadedFonts.add(fontAsset.asset);
        fontFutures.add(() async {
          final FontLoadError? error = await _downloadFontAsset(fontAsset, family.name);
          if (error != null) {
            fontFailures[fontAsset.asset] = error;
          }
        }());
      }
    }

    await Future.wait(fontFutures);

    loadedFonts.removeWhere((String assetName) => fontFailures.containsKey(assetName));
    return AssetFontsResult(loadedFonts, fontFailures);
  }

  Future<FontLoadError?> _downloadFontAsset(FontAsset asset, String family) async {
    final HttpFetchResponse response;
    try {
      response = await ui_web.assetManager.loadAsset(asset.asset) as HttpFetchResponse;
    } catch (error) {
      return FontDownloadError(ui_web.assetManager.getAssetUrl(asset.asset), error);
    }
    if (!response.hasPayload) {
      return FontNotFoundError(ui_web.assetManager.getAssetUrl(asset.asset));
    }

    final SkDataHandle fontData = await _loadDataFromResponse(response);
    final bool success = _registerTypeface(family, fontData);
    skDataDispose(fontData);

    if (success) {
      return null;
    } else {
      return FontInvalidDataError(ui_web.assetManager.getAssetUrl(asset.asset));
    }
  }

  @override
  Future<bool> loadFontFromBytes(Uint8List list, {String? fontFamily}) async {
    final SkDataHandle fontData = skDataCreate(list.length);
    final int dataAddress = skDataGetPointer(fontData).cast<Int8>().address;
    final wasmMemory = JSUint8Array(skwasmInstance.wasmMemory.buffer);
    wasmMemory.set(list.toJS, dataAddress);

    final bool success = _registerTypeface(fontFamily, fontData);
    skDataDispose(fontData);

    if (success) {
      fontCollectionClearCaches(handle);
    }
    return success;
  }

  Future<SkDataHandle> _loadDataFromResponse(HttpFetchResponse response) async {
    var length = 0;
    final chunks = <JSUint8Array>[];
    await response.read((JSUint8Array chunk) {
      length += chunk.length;
      chunks.add(chunk);
    });
    final SkDataHandle fontData = skDataCreate(length);
    int dataAddress = skDataGetPointer(fontData).cast<Int8>().address;
    final wasmMemory = JSUint8Array(skwasmInstance.wasmMemory.buffer);
    for (final chunk in chunks) {
      wasmMemory.set(chunk, dataAddress);
      dataAddress += chunk.length;
    }
    return fontData;
  }

  bool _registerTypeface(String? familyName, SkDataHandle fontData) {
    final typeface = SkwasmTypeface(fontData);
    if (typeface.handle == nullptr) {
      return false;
    }
    final SkStringHandle familyNameHandle = familyName != null
        ? skStringFromDartString(familyName)
        : nullptr;
    fontCollectionRegisterTypeface(handle, typeface.handle, familyNameHandle);
    if (familyName != null) {
      registeredTypefaces.putIfAbsent(familyName, () => <SkwasmTypeface>[]).add(typeface);
      skStringFree(familyNameHandle);
    }
    return true;
  }

  @override
  void debugResetFallbackFonts() {
    // ignore: invalid_use_of_visible_for_testing_member
    FallbackFontService.instance.debugReset();
    setDefaultFontFamilies(<String>['Roboto']);
    fontFallbackManager = FontFallbackManager(SkwasmFallbackRegistry(this));
    fontCollectionClearCaches(handle);
  }
}

class SkwasmFallbackRegistry implements FallbackFontRegistry {
  SkwasmFallbackRegistry(this._fontCollection);

  final SkwasmFontCollection _fontCollection;

  @override
  Future<bool> loadFallbackFont(String familyName, Uint8List bytes) =>
      _fontCollection.loadFontFromBytes(bytes, fontFamily: familyName);

  @override
  void updateFallbackFontFamilies(List<String> families) =>
      _fontCollection.setDefaultFontFamilies(families);
}

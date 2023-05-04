// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:ffi';

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

final class RawFontCollection extends Opaque {}
typedef FontCollectionHandle = Pointer<RawFontCollection>;

@Native<FontCollectionHandle Function()>(symbol: 'fontCollection_create', isLeaf: true)
external FontCollectionHandle fontCollectionCreate();

@Native<Void Function(FontCollectionHandle)>(symbol: 'fontCollection_dispose', isLeaf: true)
external void fontCollectionDispose(FontCollectionHandle handle);

@Native<Bool Function(
  FontCollectionHandle,
  SkDataHandle,
  SkStringHandle,
)>(symbol: 'fontCollection_registerFont', isLeaf: true)
external bool fontCollectionRegisterFont(
  FontCollectionHandle handle,
  SkDataHandle fontData,
  SkStringHandle fontName,
);

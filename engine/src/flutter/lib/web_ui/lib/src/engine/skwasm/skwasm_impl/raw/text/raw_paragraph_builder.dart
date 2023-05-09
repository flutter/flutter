// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:ffi';

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

final class RawParagraphBuilder extends Opaque {}
typedef ParagraphBuilderHandle = Pointer<RawParagraphBuilder>;

@Native<ParagraphBuilderHandle Function(
  ParagraphStyleHandle,
  FontCollectionHandle,
)>(symbol: 'paragraphBuilder_create', isLeaf: true)
external ParagraphBuilderHandle paragraphBuilderCreate(
  ParagraphStyleHandle styleHandle,
  FontCollectionHandle fontCollectionHandle,
);

@Native<Void Function(ParagraphBuilderHandle)>(symbol: 'paragraphBuilder_dispose', isLeaf: true)
external void paragraphBuilderDispose(ParagraphBuilderHandle handle);

@Native<Void Function(
  ParagraphBuilderHandle,
  Float,
  Float,
  Int,
  Float,
  Int,
)>(symbol: 'paragraphBuilder_addPlaceholder', isLeaf: true)
external void paragraphBuilderAddPlaceholder(
  ParagraphBuilderHandle handle,
  double width,
  double height,
  int alignment,
  double baslineOffset,
  int baseline,
);

@Native<Void Function(
  ParagraphBuilderHandle,
  SkString16Handle,
)>(symbol: 'paragraphBuilder_addText', isLeaf: true)
external void paragraphBuilderAddText(
  ParagraphBuilderHandle handle,
  SkString16Handle text,
);

@Native<Void Function(
  ParagraphBuilderHandle,
  TextStyleHandle,
)>(symbol: 'paragraphBuilder_pushStyle', isLeaf: true)
external void paragraphBuilderPushStyle(
  ParagraphBuilderHandle handle,
  TextStyleHandle styleHandle,
);

@Native<Void Function(ParagraphBuilderHandle)>(symbol: 'paragraphBuilder_pop', isLeaf: true)
external void paragraphBuilderPop(ParagraphBuilderHandle handle);

@Native<ParagraphHandle Function(ParagraphBuilderHandle)>(symbol: 'paragraphBuilder_build', isLeaf: true)
external ParagraphHandle paragraphBuilderBuild(ParagraphBuilderHandle handle);

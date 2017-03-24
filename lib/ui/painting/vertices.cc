// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/vertices.h"

#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

namespace blink {

namespace {

std::unique_ptr<SkPoint[]> DecodePoints(
    const tonic::Float32List& coords) {
  std::unique_ptr<SkPoint[]> result;
  if (coords.data()) {
    result.reset(new SkPoint[coords.num_elements() / 2]);
    for (int i = 0; i < coords.num_elements(); i += 2)
      result[i / 2] = SkPoint::Make(coords[i], coords[i + 1]);
  }
  return result;
}

template <typename T> std::unique_ptr<T[]> DecodeInts(
    const tonic::Int32List& ints) {
  std::unique_ptr<T[]> result;
  if (ints.data()) {
    result.reset(new T[ints.num_elements()]);
    for (int i = 0; i < ints.num_elements(); i++)
      result[i] = ints[i];
  }
  return result;
}

}  // namespace

static void Vertices_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&Vertices::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, Vertices);

#define FOR_EACH_BINDING(V) \
  V(Vertices, init)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

Vertices::Vertices() {}

Vertices::~Vertices() {}

void Vertices::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"Vertices_constructor", Vertices_constructor, 1, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

ftl::RefPtr<Vertices> Vertices::Create() {
  return ftl::MakeRefCounted<Vertices>();
}

void Vertices::init(SkCanvas::VertexMode vertex_mode,
                    const tonic::Float32List& positions,
                    const tonic::Float32List& texture_coordinates,
                    const tonic::Int32List& colors,
                    const tonic::Int32List& indices) {
  std::unique_ptr<const SkPoint[]> sk_positions(DecodePoints(positions));
  std::unique_ptr<const SkPoint[]> sk_texs(DecodePoints(texture_coordinates));

  std::unique_ptr<const SkColor[]> sk_colors(DecodeInts<SkColor>(colors));
  std::unique_ptr<const uint16_t[]> sk_indices(DecodeInts<uint16_t>(indices));

  if (sk_indices) {
    vertices_ = SkVertices::MakeIndexed(vertex_mode,
                                        std::move(sk_positions),
                                        std::move(sk_colors),
                                        std::move(sk_texs),
                                        positions.num_elements() / 2,
                                        std::move(sk_indices),
                                        indices.num_elements());

  } else {
    vertices_ = SkVertices::Make(vertex_mode,
                                 std::move(sk_positions),
                                 std::move(sk_colors),
                                 std::move(sk_texs),
                                 positions.num_elements() / 2);
  }
}

}  // namespace blink

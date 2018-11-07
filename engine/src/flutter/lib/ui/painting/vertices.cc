// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/vertices.h"

#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace blink {

namespace {

void DecodePoints(const tonic::Float32List& coords, SkPoint* points) {
  for (int i = 0; i < coords.num_elements(); i += 2)
    points[i / 2] = SkPoint::Make(coords[i], coords[i + 1]);
}

template <typename T>
void DecodeInts(const tonic::Int32List& ints, T* out) {
  for (int i = 0; i < ints.num_elements(); i++)
    out[i] = ints[i];
}

}  // namespace

static void Vertices_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&Vertices::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, Vertices);

#define FOR_EACH_BINDING(V) V(Vertices, init)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

Vertices::Vertices() {}

Vertices::~Vertices() {}

void Vertices::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({{"Vertices_constructor", Vertices_constructor, 1, true},
                     FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<Vertices> Vertices::Create() {
  return fml::MakeRefCounted<Vertices>();
}

void Vertices::init(SkVertices::VertexMode vertex_mode,
                    const tonic::Float32List& positions,
                    const tonic::Float32List& texture_coordinates,
                    const tonic::Int32List& colors,
                    const tonic::Int32List& indices) {
  uint32_t builderFlags = 0;
  if (texture_coordinates.data())
    builderFlags |= SkVertices::kHasTexCoords_BuilderFlag;
  if (colors.data())
    builderFlags |= SkVertices::kHasColors_BuilderFlag;

  SkVertices::Builder builder(vertex_mode, positions.num_elements() / 2,
                              indices.num_elements(), builderFlags);

  // positions are required for SkVertices::Builder
  FML_DCHECK(positions.data());
  if (positions.data())
    DecodePoints(positions, builder.positions());

  if (texture_coordinates.data()) {
    // SkVertices::Builder assumes equal numbers of elements
    FML_DCHECK(positions.num_elements() == texture_coordinates.num_elements());
    DecodePoints(texture_coordinates, builder.texCoords());
  }
  if (colors.data()) {
    // SkVertices::Builder assumes equal numbers of elements
    FML_DCHECK(positions.num_elements() == colors.num_elements());
    DecodeInts<SkColor>(colors, builder.colors());
  }

  if (indices.data())
    DecodeInts<uint16_t>(indices, builder.indices());

  vertices_ = builder.detach();
}

}  // namespace blink

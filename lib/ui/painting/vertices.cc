// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/vertices.h"
#include "flutter/lib/ui/ui_dart_state.h"

#include <algorithm>

#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

namespace {

void DecodePoints(const tonic::Float32List& coords, SkPoint* points) {
  for (int i = 0; i < coords.num_elements(); i += 2) {
    points[i / 2] = SkPoint::Make(coords[i], coords[i + 1]);
  }
}

template <typename T>
void DecodeInts(const tonic::Int32List& ints, T* out) {
  for (int i = 0; i < ints.num_elements(); i++) {
    out[i] = ints[i];
  }
}

}  // namespace

IMPLEMENT_WRAPPERTYPEINFO(ui, Vertices);

#define FOR_EACH_BINDING(V) V(Vertices, init)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

Vertices::Vertices() {}

Vertices::~Vertices() {}

void Vertices::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

bool Vertices::init(Dart_Handle vertices_handle,
                    SkVertices::VertexMode vertex_mode,
                    const tonic::Float32List& positions,
                    const tonic::Float32List& texture_coordinates,
                    const tonic::Int32List& colors,
                    const tonic::Uint16List& indices) {
  UIDartState::ThrowIfUIOperationsProhibited();
  uint32_t builderFlags = 0;
  if (texture_coordinates.data()) {
    builderFlags |= SkVertices::kHasTexCoords_BuilderFlag;
  }
  if (colors.data()) {
    builderFlags |= SkVertices::kHasColors_BuilderFlag;
  }

  SkVertices::Builder builder(vertex_mode, positions.num_elements() / 2,
                              indices.num_elements(), builderFlags);

  if (!builder.isValid()) {
    return false;
  }

  // positions are required for SkVertices::Builder
  FML_DCHECK(positions.data());
  if (positions.data()) {
    DecodePoints(positions, builder.positions());
  }

  if (texture_coordinates.data()) {
    // SkVertices::Builder assumes equal numbers of elements
    FML_DCHECK(positions.num_elements() == texture_coordinates.num_elements());
    DecodePoints(texture_coordinates, builder.texCoords());
  }
  if (colors.data()) {
    // SkVertices::Builder assumes equal numbers of elements
    FML_DCHECK(positions.num_elements() / 2 == colors.num_elements());
    DecodeInts<SkColor>(colors, builder.colors());
  }

  if (indices.data()) {
    std::copy(indices.data(), indices.data() + indices.num_elements(),
              builder.indices());
  }

  auto vertices = fml::MakeRefCounted<Vertices>();
  vertices->vertices_ = builder.detach();
  vertices->AssociateWithDartWrapper(vertices_handle);

  return true;
}

size_t Vertices::GetAllocationSize() const {
  return sizeof(Vertices) + vertices_->approximateSize();
}

}  // namespace flutter

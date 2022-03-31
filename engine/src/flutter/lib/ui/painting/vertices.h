// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_VERTICES_H_
#define FLUTTER_LIB_UI_PAINTING_VERTICES_H_

#include "flutter/display_list/display_list_vertices.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/skia/include/core/SkVertices.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

class Vertices : public RefCountedDartWrappable<Vertices> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Vertices);

 public:
  ~Vertices() override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

  static bool init(Dart_Handle vertices_handle,
                   DlVertexMode vertex_mode,
                   tonic::Float32List& positions,
                   tonic::Float32List& texture_coordinates,
                   tonic::Int32List& colors,
                   tonic::Uint16List& indices);

  const DlVertices* vertices() const { return vertices_.get(); }

  size_t GetAllocationSize() const override;

 private:
  Vertices();

  std::shared_ptr<DlVertices> vertices_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_VERTICES_H_

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/flow/layers/layer.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "impeller/aiks/picture.h"  // nogncheck
#else                               // IMPELLER_SUPPORTS_RENDERING
namespace impeller {
struct Picture;
}  // namespace impeller
#endif                              // !IMPELLER_SUPPORTS_RENDERING

namespace flutter {

class AiksLayer : public Layer {
 public:
  AiksLayer(const SkPoint& offset,
            const std::shared_ptr<const impeller::Picture>& picture);

  const AiksLayer* as_aiks_layer() const override { return this; }

  bool IsReplacing(DiffContext* context, const Layer* layer) const override;

  void Diff(DiffContext* context, const Layer* old_layer) override;

  void Preroll(PrerollContext* frame) override;

  void Paint(PaintContext& context) const override;

 private:
  SkPoint offset_;
  SkRect bounds_;
  std::shared_ptr<const impeller::Picture> picture_;

  FML_DISALLOW_COPY_AND_ASSIGN(AiksLayer);
};

}  // namespace flutter

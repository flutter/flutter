// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/context.h"
#include "impeller/primitives/primitive.h"

namespace impeller {

class BoxPrimitive final : public Primitive {
 public:
  BoxPrimitive(std::shared_ptr<Context> context);

  ~BoxPrimitive() override;

  virtual bool Encode(RenderPass& pass) const override;

 private:
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(BoxPrimitive);
};

bool RenderBox(std::shared_ptr<Context> context);

}  // namespace impeller

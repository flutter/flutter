// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/compositor/context.h"
#include "impeller/compositor/pipeline.h"
#include "impeller/compositor/render_pass.h"

namespace impeller {

class Primitive {
 public:
  Primitive(std::shared_ptr<Context>);

  virtual std::shared_ptr<Pipeline> GetPipeline() const = 0;

  virtual ~Primitive();

  virtual bool IsValid() const = 0;

  std::shared_ptr<Context> GetContext() const;

  virtual bool Encode(RenderPass& pass) const = 0;

 private:
  std::shared_ptr<Context> context_;

  FML_DISALLOW_COPY_AND_ASSIGN(Primitive);
};

}  // namespace impeller

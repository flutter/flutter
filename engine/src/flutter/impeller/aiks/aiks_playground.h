// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/aiks/aiks_context.h"
#include "impeller/aiks/picture.h"
#include "impeller/playground/playground.h"

namespace impeller {

class AiksPlayground : public Playground {
 public:
  using AiksPlaygroundCallback =
      std::function<bool(AiksContext& renderer, RenderTarget& render_target)>;

  AiksPlayground();

  ~AiksPlayground();

  bool OpenPlaygroundHere(const Picture& picture);

  bool OpenPlaygroundHere(AiksPlaygroundCallback callback);

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(AiksPlayground);
};

}  // namespace impeller

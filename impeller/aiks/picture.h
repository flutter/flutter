// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_PICTURE_H_
#define FLUTTER_IMPELLER_AIKS_PICTURE_H_

#include <deque>
#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/aiks/aiks_context.h"
#include "impeller/aiks/image.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass.h"

namespace impeller {

struct Picture {
  std::unique_ptr<EntityPass> pass;

  std::optional<Snapshot> Snapshot(AiksContext& context);

  std::shared_ptr<Image> ToImage(AiksContext& context, ISize size) const;

 private:
  std::shared_ptr<Texture> RenderToTexture(
      AiksContext& context,
      ISize size,
      std::optional<const Matrix> translate = std::nullopt) const;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_PICTURE_H_

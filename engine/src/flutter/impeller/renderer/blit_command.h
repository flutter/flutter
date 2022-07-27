// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/renderer/texture.h"

namespace impeller {

struct BlitCommand {
  std::string label;
};

struct BlitCopyTextureToTextureCommand : public BlitCommand {
  std::shared_ptr<Texture> source;
  std::shared_ptr<Texture> destination;
  IRect source_region;
  IPoint destination_origin;
};

struct BlitGenerateMipmapCommand : public BlitCommand {
  std::shared_ptr<Texture> texture;
};

}  // namespace impeller

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/aiks/picture.h"
#include "impeller/playground/playground.h"

namespace impeller {

class AiksPlayground : public Playground {
 public:
  AiksPlayground();

  ~AiksPlayground();

  bool OpenPlaygroundHere(const Picture& picture);

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(AiksPlayground);
};

}  // namespace impeller

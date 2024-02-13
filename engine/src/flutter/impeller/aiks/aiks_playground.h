// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_AIKS_PLAYGROUND_H_
#define FLUTTER_IMPELLER_AIKS_AIKS_PLAYGROUND_H_

#include "flutter/fml/macros.h"
#include "impeller/aiks/aiks_context.h"
#include "impeller/aiks/aiks_playground_inspector.h"
#include "impeller/aiks/picture.h"
#include "impeller/playground/playground_test.h"
#include "impeller/typographer/typographer_context.h"
#include "third_party/imgui/imgui.h"

namespace impeller {

class AiksPlayground : public PlaygroundTest {
 public:
  using AiksPlaygroundCallback =
      std::function<std::optional<Picture>(AiksContext& renderer)>;

  AiksPlayground();

  ~AiksPlayground();

  void TearDown() override;

  void SetTypographerContext(
      std::shared_ptr<TypographerContext> typographer_context);

  bool OpenPlaygroundHere(Picture picture);

  bool OpenPlaygroundHere(AiksPlaygroundCallback callback);

  static bool ImGuiBegin(const char* name,
                         bool* p_open,
                         ImGuiWindowFlags flags);

 private:
  std::shared_ptr<TypographerContext> typographer_context_;
  AiksInspector inspector_;

  AiksPlayground(const AiksPlayground&) = delete;

  AiksPlayground& operator=(const AiksPlayground&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_AIKS_PLAYGROUND_H_

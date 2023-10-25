// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <functional>
#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/aiks/aiks_context.h"
#include "impeller/aiks/picture.h"
#include "impeller/core/capture.h"
#include "impeller/renderer/context.h"

namespace impeller {

class AiksInspector {
 public:
  AiksInspector();

  const std::optional<Picture>& RenderInspector(
      AiksContext& aiks_context,
      const std::function<std::optional<Picture>()>& picture_callback);

  // Resets (releases) the underlying |Picture| object.
  //
  // Underlying issue: <https://github.com/flutter/flutter/issues/134678>.
  //
  // The tear-down code is not running in the right order; we still have a
  // reference to the |Picture| object when the |Context| is being destroyed,
  // which causes the |Texture| objects to leak.
  //
  // TODO(matanlurey): https://github.com/flutter/flutter/issues/134748.
  void HackResetDueToTextureLeaks();

 private:
  void RenderCapture(CaptureContext& capture_context);
  void RenderCaptureElement(CaptureElement& element);

  bool capturing_ = false;
  bool wireframe_ = false;
  CaptureElement* hovered_element_ = nullptr;
  CaptureElement* selected_element_ = nullptr;
  std::optional<Picture> last_picture_;

  AiksInspector(const AiksInspector&) = delete;

  AiksInspector& operator=(const AiksInspector&) = delete;
};

};  // namespace impeller

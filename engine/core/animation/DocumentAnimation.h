// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_ANIMATION_DOCUMENTANIMATION_H_
#define SKY_ENGINE_CORE_ANIMATION_DOCUMENTANIMATION_H_

#include "sky/engine/core/dom/Document.h"

namespace blink {

class DocumentAnimation {
public:
    static AnimationTimeline* timeline(Document& document) { return &document.timeline(); }
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_ANIMATION_DOCUMENTANIMATION_H_

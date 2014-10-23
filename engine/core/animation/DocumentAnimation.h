// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef DocumentAnimation_h
#define DocumentAnimation_h

#include "core/dom/Document.h"

namespace blink {

class DocumentAnimation {
public:
    static AnimationTimeline* timeline(Document& document) { return &document.timeline(); }
};

} // namespace blink

#endif // DocumentAnimation_h

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_PARAGRAPHSTYLE_H_
#define SKY_ENGINE_CORE_TEXT_PARAGRAPHSTYLE_H_

#include "sky/engine/core/text/TextAlign.h"
#include "sky/engine/core/text/TextBaseline.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class ParagraphStyle : public RefCounted<ParagraphStyle>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<ParagraphStyle> create(int align = 0, double lineHeight = 0.0, int textBaseline = 0) {
      return adoptRef(new ParagraphStyle(align, lineHeight, textBaseline));
    }

    ~ParagraphStyle() override;

private:
    explicit ParagraphStyle(int align, double lineHeight, int textBaseline);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_PARAGRAPHSTYLE_H_

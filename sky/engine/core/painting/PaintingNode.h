// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PAINTINGNODE_H_
#define SKY_ENGINE_CORE_PAINTING_PAINTINGNODE_H_

#include "sky/engine/core/painting/Drawable.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkDrawable.h"

namespace blink {

class PaintingNodeDrawable;

class PaintingNode : public RefCounted<PaintingNode>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<PaintingNode> create();
    ~PaintingNode() override;

    void setBackingDrawable(PassRefPtr<Drawable> drawable);
    SkDrawable* toSkia();
    PassRefPtr<Picture> newPictureSnapshot();

private:
    PaintingNode();
    RefPtr<PaintingNodeDrawable> m_paintingNodeDrawable;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PAINTINGNODE_H_

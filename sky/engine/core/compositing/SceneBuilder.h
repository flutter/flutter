// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_
#define SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_

#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/core/compositing/Scene.h"
#include "sky/engine/core/painting/CanvasPath.h"
#include "sky/engine/core/painting/Offset.h"
#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/core/painting/Point.h"
#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/core/painting/RRect.h"
#include "sky/engine/core/painting/Size.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/tonic/float32_list.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace blink {

class SceneBuilder : public RefCounted<SceneBuilder>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<SceneBuilder> create(const Rect& bounds) {
      return adoptRef(new SceneBuilder(bounds));
    }

    ~SceneBuilder() override;

    void pushTransform(const Float32List& matrix4, ExceptionState&);
    void pushClipRect(const Rect& rect);
    void pushClipRRect(const RRect* rrect, const Rect& bounds);
    void pushClipPath(const CanvasPath* path, const Rect& bounds);
    void pushOpacity(int alpha, const Rect& bounds);
    void pushColorFilter(SkColor color, SkXfermode::Mode transferMode, const Rect& bounds);
    void pop();
    void addPicture(const Offset& offset, Picture* picture, const Rect& bounds);

    PassRefPtr<Scene> build();

private:
    explicit SceneBuilder(const Rect& bounds);

    SkRTreeFactory m_rtreeFactory;
    SkPictureRecorder m_pictureRecorder;
    SkCanvas* m_canvas;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_

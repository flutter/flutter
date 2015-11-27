// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_
#define SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_

#include <stdint.h>
#include <memory>

#include "sky/compositor/layer.h"
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
#include "sky/engine/tonic/float64_list.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class SceneBuilder : public RefCounted<SceneBuilder>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<SceneBuilder> create(const Rect& bounds) {
      return adoptRef(new SceneBuilder(bounds));
    }

    ~SceneBuilder() override;

    void pushTransform(const Float64List& matrix4, ExceptionState&);
    void pushClipRect(const Rect& rect);
    void pushClipRRect(const RRect& rrect, const Rect& bounds);
    void pushClipPath(const CanvasPath* path, const Rect& bounds);
    void pushOpacity(int alpha, const Rect& bounds);
    void pushColorFilter(CanvasColor color, TransferMode transferMode, const Rect& bounds);
    void pop();

    void addPicture(const Offset& offset, Picture* picture, const Rect& bounds);
    void addStatistics(uint64_t enabledOptions, const Rect& bounds);

    void setRasterizerTracingThreshold(uint32_t frameInterval);

    PassRefPtr<Scene> build();

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    explicit SceneBuilder(const Rect& bounds);

    void addLayer(std::unique_ptr<sky::compositor::ContainerLayer> layer);

    SkRect m_rootPaintBounds;
    std::unique_ptr<sky::compositor::ContainerLayer> m_rootLayer;
    sky::compositor::ContainerLayer* m_currentLayer;
    int32_t m_currentRasterizerTracingThreshold;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_

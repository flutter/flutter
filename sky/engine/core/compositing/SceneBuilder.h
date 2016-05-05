// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_
#define SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_

#include <stdint.h>
#include <memory>

#include "flow/layers/container_layer.h"
#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/core/compositing/Scene.h"
#include "sky/engine/core/painting/CanvasPath.h"
#include "sky/engine/core/painting/ImageFilter.h"
#include "sky/engine/core/painting/Offset.h"
#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/core/painting/Point.h"
#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/core/painting/RRect.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/tonic/float64_list.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/ThreadSafeRefCounted.h"

namespace blink {

class SceneBuilder : public ThreadSafeRefCounted<SceneBuilder>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<SceneBuilder> create() {
      return adoptRef(new SceneBuilder());
    }

    ~SceneBuilder() override;

    void pushTransform(const Float64List& matrix4, ExceptionState&);
    void pushClipRect(double left, double right, double top, double bottom);
    void pushClipRRect(const RRect& rrect);
    void pushClipPath(const CanvasPath* path);
    void pushOpacity(int alpha);
    void pushColorFilter(int color, int transferMode);
    void pushBackdropFilter(ImageFilter* filter);
    void pushShaderMask(Shader* shader,
                        double maskRectLeft,
                        double maskRectRight,
                        double maskRectTop,
                        double maskRectBottom,
                        int transferMode);
    void pop();

    void addPerformanceOverlay(uint64_t enabledOptions,
                               double left,
                               double right,
                               double top,
                               double bottom);
    void addPicture(double dx, double dy, Picture* picture);
    void addChildScene(double dx,
                       double dy,
                       double devicePixelRatio,
                       int physicalWidth,
                       int physicalHeight,
                       uint32_t sceneToken);

    void setRasterizerTracingThreshold(uint32_t frameInterval);

    PassRefPtr<Scene> build();

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    explicit SceneBuilder();

    void addLayer(std::unique_ptr<flow::ContainerLayer> layer);

    std::unique_ptr<flow::ContainerLayer> m_rootLayer;
    flow::ContainerLayer* m_currentLayer;
    int32_t m_currentRasterizerTracingThreshold;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_

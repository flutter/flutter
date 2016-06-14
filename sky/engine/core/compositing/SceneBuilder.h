// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_
#define SKY_ENGINE_CORE_COMPOSITING_SCENEBUILDER_H_

#include <stdint.h>
#include <memory>

#include "base/memory/ref_counted.h"
#include "flow/layers/container_layer.h"
#include "flutter/lib/ui/painting/image_filter.h"
#include "flutter/lib/ui/painting/path.h"
#include "flutter/lib/ui/painting/picture.h"
#include "flutter/lib/ui/painting/rrect.h"
#include "flutter/lib/ui/painting/shader.h"
#include "flutter/tonic/dart_wrappable.h"
#include "flutter/tonic/float64_list.h"
#include "sky/engine/core/compositing/Scene.h"
#include "sky/engine/core/painting/Paint.h"

namespace blink {

class SceneBuilder : public base::RefCountedThreadSafe<SceneBuilder>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static scoped_refptr<SceneBuilder> create() { return new SceneBuilder(); }

    ~SceneBuilder() override;

    void pushTransform(const Float64List& matrix4);
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

    scoped_refptr<Scene> build();

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

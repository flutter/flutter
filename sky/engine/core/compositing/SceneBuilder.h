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
#include "sky/engine/core/painting/Offset.h"
#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/core/painting/Point.h"
#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/core/painting/RRect.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/tonic/float64_list.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class SceneBuilder : public RefCounted<SceneBuilder>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<SceneBuilder> create() {
      return adoptRef(new SceneBuilder());
    }

    ~SceneBuilder() override;

    void pushTransform(const Float64List& matrix4, ExceptionState&);
    void pushClipRect(const Rect& rect);
    void pushClipRRect(const RRect& rrect);
    void pushClipPath(const CanvasPath* path);
    void pushOpacity(int alpha);
    void pushColorFilter(CanvasColor color, TransferMode transferMode);
    void pushShaderMask(Shader* shader, const Rect& maskRect, TransferMode transferMode);
    void pop();

    void addPerformanceOverlay(uint64_t enabledOptions, const Rect& bounds);
    void addPicture(const Offset& offset, Picture* picture);
    void addChildScene(const Offset& offset,
                       double device_pixel_ratio,
                       int physical_width,
                       int physical_height,
                       uint32_t scene_token);

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

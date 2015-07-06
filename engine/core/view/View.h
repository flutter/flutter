// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_VIEW_VIEW_H_
#define SKY_ENGINE_CORE_VIEW_VIEW_H_

#include "base/callback.h"
#include "base/time/time.h"
#include "sky/engine/core/html/VoidCallback.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/core/view/EventCallback.h"
#include "sky/engine/core/view/FrameCallback.h"
#include "sky/engine/public/platform/sky_display_metrics.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class View : public RefCounted<View>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~View() override;
    static PassRefPtr<View> create(const base::Closure& scheduleFrameCallback);

    double devicePixelRatio() const { return m_displayMetrics.device_pixel_ratio; }
    double width() const;
    double height() const;

    Picture* picture() const { return m_picture.get(); }
    void setPicture(Picture* picture) { m_picture = picture; }

    void setEventCallback(PassOwnPtr<EventCallback> callback);

    void setMetricsChangedCallback(PassOwnPtr<VoidCallback> callback);

    void setFrameCallback(PassOwnPtr<FrameCallback> callback);
    void scheduleFrame();

    void setDisplayMetrics(const SkyDisplayMetrics& metrics);
    void handleInputEvent(PassRefPtr<Event> event);
    void beginFrame(base::TimeTicks frameTime);

private:
    explicit View(const base::Closure& scheduleFrameCallback);

    base::Closure m_scheduleFrameCallback;
    SkyDisplayMetrics m_displayMetrics;
    OwnPtr<EventCallback> m_eventCallback;
    OwnPtr<VoidCallback> m_metricsChangedCallback;
    OwnPtr<FrameCallback> m_frameCallback;
    RefPtr<Picture> m_picture;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_VIEW_VIEW_H_

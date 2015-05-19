// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_VIEW_VIEW_H_
#define SKY_ENGINE_CORE_VIEW_VIEW_H_

#include "base/callback.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/public/platform/sky_display_metrics.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class View : public RefCounted<View>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~View() override;
    static PassRefPtr<View> create(const base::Closure& schedulePaintCallback);

    double devicePixelRatio() const { return m_displayMetrics.device_pixel_ratio; }
    double width() const;
    double height() const;

    Picture* picture() const { return m_picture.get(); }
    void setPicture(Picture* picture) { m_picture = picture; }

    void schedulePaint();

    void setDisplayMetrics(const SkyDisplayMetrics& metrics);

private:
    explicit View(const base::Closure& schedulePaintCallback);

    base::Closure m_schedulePaintCallback;
    SkyDisplayMetrics m_displayMetrics;
    RefPtr<Picture> m_picture;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_VIEW_VIEW_H_

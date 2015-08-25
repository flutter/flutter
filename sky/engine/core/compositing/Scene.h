// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_COMPOSITING_SCENE_H_
#define SKY_ENGINE_CORE_COMPOSITING_SCENE_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {

class Scene : public RefCounted<Scene>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~Scene() override;
    static PassRefPtr<Scene> create(PassRefPtr<SkPicture> skPicture);

    SkPicture* toSkia() const { return m_picture.get(); }

private:
    explicit Scene(PassRefPtr<SkPicture> skPicture);

    // While bootstraping the compositing system, we use an SkPicture instead
    // of a layer tree to back the scene.
    RefPtr<SkPicture> m_picture;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_COMPOSITING_SCENE_H_

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PICTURE_H_
#define SKY_ENGINE_CORE_PAINTING_PICTURE_H_

#include "sky/engine/platform/graphics/DisplayList.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class Picture : public RefCounted<Picture>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~Picture() override;
    static PassRefPtr<Picture> create(PassRefPtr<DisplayList>);

    DisplayList* displayList() const { return m_displayList.get(); }

private:
    Picture(PassRefPtr<DisplayList>);

    RefPtr<DisplayList> m_displayList;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PICTURE_H_

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_FRAME_TRACING_H_
#define SKY_ENGINE_CORE_FRAME_TRACING_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class Tracing : public RefCounted<Tracing>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~Tracing() override;
    static PassRefPtr<Tracing> create() { return adoptRef(new Tracing); }

    void begin(const String& name);
    void end(const String& name);

private:
    Tracing();
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_FRAME_TRACING_H_

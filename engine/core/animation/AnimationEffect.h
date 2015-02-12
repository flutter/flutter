/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_ANIMATION_ANIMATIONEFFECT_H_
#define SKY_ENGINE_CORE_ANIMATION_ANIMATIONEFFECT_H_

#include "gen/sky/core/CSSPropertyNames.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class Interpolation;

class AnimationEffect : public RefCounted<AnimationEffect>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    enum CompositeOperation {
        CompositeReplace,
        CompositeAdd,
    };

    AnimationEffect() { }

    virtual ~AnimationEffect() { }
    virtual PassOwnPtr<Vector<RefPtr<Interpolation> > > sample(int iteration, double fraction, double iterationDuration) const = 0;

    virtual bool affects(CSSPropertyID) { return false; };
    virtual bool isKeyframeEffectModel() const { return false; }
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_ANIMATION_ANIMATIONEFFECT_H_

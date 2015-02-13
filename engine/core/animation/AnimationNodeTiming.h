// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_ANIMATION_ANIMATIONNODETIMING_H_
#define SKY_ENGINE_CORE_ANIMATION_ANIMATIONNODETIMING_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/bindings/nullable.h"
#include "sky/engine/core/animation/AnimationNode.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class AnimationNodeTiming : public RefCounted<AnimationNodeTiming>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<AnimationNodeTiming> create(AnimationNode* parent);
    double delay();
    double endDelay();
    String fill();
    double iterationStart();
    double iterations();
    void getDuration(String propertyName, Nullable<double>& element0, String& element1);
    double playbackRate();
    String direction();
    String easing();

    void setDelay(double);
    void setEndDelay(double);
    void setFill(String);
    void setIterationStart(double);
    void setIterations(double);
    bool setDuration(String name, double duration);
    void setPlaybackRate(double);
    void setDirection(String);
    void setEasing(String);

private:
    RefPtr<AnimationNode> m_parent;
    explicit AnimationNodeTiming(AnimationNode*);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_ANIMATION_ANIMATIONNODETIMING_H_

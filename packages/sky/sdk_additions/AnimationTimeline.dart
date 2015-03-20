// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class AnimationTimeline extends NativeFieldWrapperClass2 {
    // Constructors

    // Attributes
    double get currentTime native "AnimationTimeline_currentTime_Getter";

    // Methods
    AnimationPlayer play(AnimationNode source) native "AnimationTimeline_play_Callback";
    List<AnimationPlayer> getAnimationPlayers() native "AnimationTimeline_getAnimationPlayers_Callback";

    // Operators
}

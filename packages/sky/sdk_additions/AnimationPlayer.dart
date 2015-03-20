// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: Do not edit - generated code.
part of dart.sky;

abstract class AnimationPlayer extends EventTarget {
    // Constructors

    // Attributes
    AnimationNode get source native "AnimationPlayer_source_Getter";
    void set source(AnimationNode value) native "AnimationPlayer_source_Setter";
    double get startTime native "AnimationPlayer_startTime_Getter";
    void set startTime(double value) native "AnimationPlayer_startTime_Setter";
    double get currentTime native "AnimationPlayer_currentTime_Getter";
    void set currentTime(double value) native "AnimationPlayer_currentTime_Setter";
    double get playbackRate native "AnimationPlayer_playbackRate_Getter";
    void set playbackRate(double value) native "AnimationPlayer_playbackRate_Setter";
    bool get paused native "AnimationPlayer_paused_Getter";
    bool get finished native "AnimationPlayer_finished_Getter";
    String get playState native "AnimationPlayer_playState_Getter";

    // Methods
    void finish() native "AnimationPlayer_finish_Callback";
    void play() native "AnimationPlayer_play_Callback";
    void pause() native "AnimationPlayer_pause_Callback";
    void reverse() native "AnimationPlayer_reverse_Callback";
    void cancel() native "AnimationPlayer_cancel_Callback";

    // Operators
}

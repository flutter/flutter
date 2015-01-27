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

#ifndef SKY_ENGINE_PUBLIC_WEB_WEBRUNTIMEFEATURES_H_
#define SKY_ENGINE_PUBLIC_WEB_WEBRUNTIMEFEATURES_H_

#include "../platform/WebCommon.h"

namespace blink {

// This class is used to enable runtime features of Blink.
// Stable features are enabled by default.
class WebRuntimeFeatures {
public:
    BLINK_EXPORT static void enableExperimentalFeatures(bool);
    BLINK_EXPORT static void enableTestOnlyFeatures(bool);

    BLINK_EXPORT static void enableDatabase(bool);

    BLINK_EXPORT static void enableBleedingEdgeFastPaths(bool);

    BLINK_EXPORT static void enableExperimentalCanvasFeatures(bool);

    BLINK_EXPORT static void enableFastMobileScrolling(bool);

    BLINK_EXPORT static void enableFileSystem(bool);

    BLINK_EXPORT static void enableMediaPlayer(bool);

    BLINK_EXPORT static void enableSubpixelFontScaling(bool);

    BLINK_EXPORT static void enableMediaCapture(bool);

    BLINK_EXPORT static void enableNotifications(bool);

    BLINK_EXPORT static void enableNavigatorContentUtils(bool);

    BLINK_EXPORT static void enableNavigationTransitions(bool);

    BLINK_EXPORT static void enableNetworkInformation(bool);

    BLINK_EXPORT static void enableOrientationEvent(bool);

    BLINK_EXPORT static void enableRequestAutocomplete(bool);

    BLINK_EXPORT static void enableScreenOrientation(bool);

    BLINK_EXPORT static void enableServiceWorker(bool);

    BLINK_EXPORT static void enableSessionStorage(bool);

    BLINK_EXPORT static void enableTouch(bool);

    BLINK_EXPORT static void enableTouchIconLoading(bool);

    BLINK_EXPORT static void enableWebGLDraftExtensions(bool);

    BLINK_EXPORT static void enableWebGLImageChromium(bool);

    BLINK_EXPORT static void enableOverlayFullscreenVideo(bool);

    BLINK_EXPORT static void enableSharedWorker(bool);

    BLINK_EXPORT static void enableTargetedStyleRecalc(bool);

    BLINK_EXPORT static void enablePreciseMemoryInfo(bool);

    BLINK_EXPORT static void enableLayerSquashing(bool);

    BLINK_EXPORT static void enableLaxMixedContentChecking(bool);

private:
    WebRuntimeFeatures();
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_WEB_WEBRUNTIMEFEATURES_H_

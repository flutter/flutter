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

#include "sky/engine/config.h"
#include "sky/engine/public/web/WebRuntimeFeatures.h"

#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/wtf/Assertions.h"

namespace blink {

void WebRuntimeFeatures::enableExperimentalFeatures(bool enable)
{
    RuntimeEnabledFeatures::setExperimentalFeaturesEnabled(enable);
}

void WebRuntimeFeatures::enableBleedingEdgeFastPaths(bool enable)
{
    ASSERT(enable);
    RuntimeEnabledFeatures::setBleedingEdgeFastPathsEnabled(enable);
    RuntimeEnabledFeatures::setSubpixelFontScalingEnabled(enable || RuntimeEnabledFeatures::subpixelFontScalingEnabled());
}

void WebRuntimeFeatures::enableTestOnlyFeatures(bool enable)
{
    RuntimeEnabledFeatures::setTestFeaturesEnabled(enable);
}

void WebRuntimeFeatures::enableDatabase(bool enable)
{
    RuntimeEnabledFeatures::setDatabaseEnabled(enable);
}

void WebRuntimeFeatures::enableExperimentalCanvasFeatures(bool enable)
{
    RuntimeEnabledFeatures::setExperimentalCanvasFeaturesEnabled(enable);
}

void WebRuntimeFeatures::enableFastMobileScrolling(bool enable)
{
    RuntimeEnabledFeatures::setFastMobileScrollingEnabled(enable);
}

void WebRuntimeFeatures::enableFileSystem(bool enable)
{
    RuntimeEnabledFeatures::setFileSystemEnabled(enable);
}

void WebRuntimeFeatures::enableMediaPlayer(bool enable)
{
    RuntimeEnabledFeatures::setMediaEnabled(enable);
}

void WebRuntimeFeatures::enableSubpixelFontScaling(bool enable)
{
    RuntimeEnabledFeatures::setSubpixelFontScalingEnabled(enable);
}

void WebRuntimeFeatures::enableMediaCapture(bool enable)
{
    RuntimeEnabledFeatures::setMediaCaptureEnabled(enable);
}

void WebRuntimeFeatures::enableNotifications(bool enable)
{
    RuntimeEnabledFeatures::setNotificationsEnabled(enable);
}

void WebRuntimeFeatures::enableNavigatorContentUtils(bool enable)
{
    RuntimeEnabledFeatures::setNavigatorContentUtilsEnabled(enable);
}

void WebRuntimeFeatures::enableNavigationTransitions(bool enable)
{
    RuntimeEnabledFeatures::setNavigationTransitionsEnabled(enable);
}

void WebRuntimeFeatures::enableNetworkInformation(bool enable)
{
    RuntimeEnabledFeatures::setNetworkInformationEnabled(enable);
}

void WebRuntimeFeatures::enableOrientationEvent(bool enable)
{
    RuntimeEnabledFeatures::setOrientationEventEnabled(enable);
}

void WebRuntimeFeatures::enableRequestAutocomplete(bool enable)
{
    RuntimeEnabledFeatures::setRequestAutocompleteEnabled(enable);
}

void WebRuntimeFeatures::enableScreenOrientation(bool enable)
{
    RuntimeEnabledFeatures::setScreenOrientationEnabled(enable);
}

void WebRuntimeFeatures::enableServiceWorker(bool enable)
{
}

void WebRuntimeFeatures::enableSessionStorage(bool enable)
{
    RuntimeEnabledFeatures::setSessionStorageEnabled(enable);
}

void WebRuntimeFeatures::enableTouch(bool enable)
{
    RuntimeEnabledFeatures::setTouchEnabled(enable);
}

void WebRuntimeFeatures::enableTouchIconLoading(bool enable)
{
    RuntimeEnabledFeatures::setTouchIconLoadingEnabled(enable);
}

void WebRuntimeFeatures::enableWebGLDraftExtensions(bool enable)
{
    RuntimeEnabledFeatures::setWebGLDraftExtensionsEnabled(enable);
}

void WebRuntimeFeatures::enableWebGLImageChromium(bool enable)
{
    RuntimeEnabledFeatures::setWebGLImageChromiumEnabled(enable);
}

void WebRuntimeFeatures::enableOverlayScrollbars(bool enable)
{
    RuntimeEnabledFeatures::setOverlayScrollbarsEnabled(enable);
}

void WebRuntimeFeatures::enableOverlayFullscreenVideo(bool enable)
{
    RuntimeEnabledFeatures::setOverlayFullscreenVideoEnabled(enable);
}

void WebRuntimeFeatures::enableSharedWorker(bool enable)
{
}

void WebRuntimeFeatures::enableTargetedStyleRecalc(bool enable)
{
    RuntimeEnabledFeatures::setTargetedStyleRecalcEnabled(enable);
}

void WebRuntimeFeatures::enablePreciseMemoryInfo(bool enable)
{
    RuntimeEnabledFeatures::setPreciseMemoryInfoEnabled(enable);
}

void WebRuntimeFeatures::enableLayerSquashing(bool enable)
{
    RuntimeEnabledFeatures::setLayerSquashingEnabled(enable);
}

void WebRuntimeFeatures::enableLaxMixedContentChecking(bool enable)
{
    RuntimeEnabledFeatures::setLaxMixedContentCheckingEnabled(enable);
}

} // namespace blink

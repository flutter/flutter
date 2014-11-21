/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_PUBLIC_WEB_SKY_H_
#define SKY_ENGINE_PUBLIC_WEB_SKY_H_

#include "../platform/Platform.h"

namespace v8 {
class Isolate;
}

namespace blink {

// Must be called on the thread that will be the main WebKit thread before
// using any other WebKit APIs. The provided Platform; must be
// non-null and must remain valid until the current thread calls shutdown.
BLINK_EXPORT void initialize(Platform*);

// Must be called on the thread that will be the main WebKit thread before
// using any other WebKit APIs. The provided Platform must be
// non-null and must remain valid until the current thread calls shutdown.
//
// This is a special variant of initialize that does not intitialize V8.
BLINK_EXPORT void initializeWithoutV8(Platform*);

// Get the V8 Isolate for the main thread.
// initialize must have been called first.
BLINK_EXPORT v8::Isolate* mainThreadIsolate();

// Once shutdown, the Platform passed to initialize will no longer
// be accessed. No other WebKit objects should be in use when this function is
// called. Any background threads created by WebKit are promised to be
// terminated by the time this function returns.
BLINK_EXPORT void shutdown();

// Once shutdown, the Platform passed to initializeWithoutV8 will no longer
// be accessed. No other WebKit objects should be in use when this function is
// called. Any background threads created by WebKit are promised to be
// terminated by the time this function returns.
//
// If initializeWithoutV8() was used to initialize WebKit, shutdownWithoutV8
// must be called to shut it down again.
BLINK_EXPORT void shutdownWithoutV8();

// Alters the rendering of content to conform to a fixed set of rules.
BLINK_EXPORT void setLayoutTestMode(bool);
BLINK_EXPORT bool layoutTestMode();

// Alters the rendering of fonts for layout tests.
BLINK_EXPORT void setFontAntialiasingEnabledForTest(bool);
BLINK_EXPORT bool fontAntialiasingEnabledForTest();

// Enables the named log channel. See WebCore/platform/Logging.h for details.
BLINK_EXPORT void enableLogChannel(const char*);

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_WEB_SKY_H_

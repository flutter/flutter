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

#include "config.h"
#include "public/web/Sky.h"

#include "base/message_loop/message_loop.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8GCController.h"
#include "bindings/core/v8/V8Initializer.h"
#include "core/Init.h"
#include "core/animation/AnimationClock.h"
#include "core/dom/Microtask.h"
#include "core/frame/Settings.h"
#include "core/page/Page.h"
#include "gin/public/v8_platform.h"
#include "mojo/common/message_pump_mojo.h"
#include "platform/LayoutTestSupport.h"
#include "platform/Logging.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/graphics/ImageDecodingStore.h"
#include "platform/graphics/media/MediaPlayer.h"
#include "platform/heap/Heap.h"
#include "public/platform/Platform.h"
#include "web/WebMediaPlayerClientImpl.h"
#include "wtf/Assertions.h"
#include "wtf/CryptographicallyRandomNumber.h"
#include "wtf/MainThread.h"
#include "wtf/WTF.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/TextEncoding.h"
#include <v8.h>

namespace blink {

namespace {

void willProcessTask()
{
    AnimationClock::notifyTaskStart();
}

void didProcessTask()
{
    Microtask::performCheckpoint();
    V8GCController::reportDOMMemoryUsageToV8(mainThreadIsolate());
}

class TaskObserver : public base::MessageLoop::TaskObserver {
public:
    void WillProcessTask(const base::PendingTask& pending_task) override { willProcessTask(); }
    void DidProcessTask(const base::PendingTask& pending_task) override { didProcessTask(); }
};

class SignalObserver : public mojo::common::MessagePumpMojo::Observer {
public:
    void WillSignalHandler() override { willProcessTask(); }
    void DidSignalHandler() override { didProcessTask(); }
};

static TaskObserver* s_taskObserver = 0;
static SignalObserver* s_signalObserver = 0;

void addMessageLoopObservers()
{
    ASSERT(!s_taskObserver);
    s_taskObserver = new TaskObserver;

    ASSERT(!s_signalObserver);
    s_signalObserver = new SignalObserver;

    base::MessageLoop::current()->AddTaskObserver(s_taskObserver);
    mojo::common::MessagePumpMojo::current()->AddObserver(s_signalObserver);
}

void removeMessageLoopObservers()
{
    base::MessageLoop::current()->RemoveTaskObserver(s_taskObserver);
    mojo::common::MessagePumpMojo::current()->RemoveObserver(s_signalObserver);

    ASSERT(s_taskObserver);
    delete s_taskObserver;
    s_taskObserver = 0;

    ASSERT(s_signalObserver);
    delete s_signalObserver;
    s_signalObserver = 0;
}

} // namespace

static ThreadState::Interruptor* s_isolateInterruptor = 0;

// Make sure we are not re-initialized in the same address space.
// Doing so may cause hard to reproduce crashes.
static bool s_webKitInitialized = false;

void initialize(Platform* platform)
{
    initializeWithoutV8(platform);

    V8Initializer::initializeMainThreadIfNeeded();

    s_isolateInterruptor = new V8IsolateInterruptor(V8PerIsolateData::mainThreadIsolate());
    ThreadState::current()->addInterruptor(s_isolateInterruptor);

    addMessageLoopObservers();
}

v8::Isolate* mainThreadIsolate()
{
    return V8PerIsolateData::mainThreadIsolate();
}

static double currentTimeFunction()
{
    return Platform::current()->currentTime();
}

static double monotonicallyIncreasingTimeFunction()
{
    return Platform::current()->monotonicallyIncreasingTime();
}

static void cryptographicallyRandomValues(unsigned char* buffer, size_t length)
{
    Platform::current()->cryptographicallyRandomValues(buffer, length);
}

static void callOnMainThreadFunction(WTF::MainThreadFunction function, void* context)
{
    Platform::current()->callOnMainThread(function, context);
}

void initializeWithoutV8(Platform* platform)
{
    ASSERT(!s_webKitInitialized);
    s_webKitInitialized = true;

    ASSERT(platform);
    Platform::initialize(platform);

    WTF::setRandomSource(cryptographicallyRandomValues);
    WTF::initialize(currentTimeFunction, monotonicallyIncreasingTimeFunction);
    WTF::initializeMainThread(callOnMainThreadFunction);
    Heap::init();

    ThreadState::attachMainThread();

    DEFINE_STATIC_LOCAL(CoreInitializer, initializer, ());
    initializer.init();

    // There are some code paths (for example, running WebKit in the browser
    // process and calling into LocalStorage before anything else) where the
    // UTF8 string encoding tables are used on a background thread before
    // they're set up.  This is a problem because their set up routines assert
    // they're running on the main WebKitThread.  It might be possible to make
    // the initialization thread-safe, but given that so many code paths use
    // this, initializing this lazily probably doesn't buy us much.
    WTF::UTF8Encoding();

    MediaPlayer::setMediaEngineCreateFunction(WebMediaPlayerClientImpl::create);
}

void shutdown()
{
    removeMessageLoopObservers();

    ASSERT(s_isolateInterruptor);
    ThreadState::current()->removeInterruptor(s_isolateInterruptor);

    // Detach the main thread before starting the shutdown sequence
    // so that the main thread won't get involved in a GC during the shutdown.
    ThreadState::detachMainThread();

    v8::Isolate* isolate = V8PerIsolateData::mainThreadIsolate();
    V8PerIsolateData::dispose(isolate);

    shutdownWithoutV8();
}

void shutdownWithoutV8()
{
    CoreInitializer::shutdown();
    Heap::shutdown();
    WTF::shutdown();
    Platform::shutdown();
}

void setLayoutTestMode(bool value)
{
    LayoutTestSupport::setIsRunningLayoutTest(value);
}

bool layoutTestMode()
{
    return LayoutTestSupport::isRunningLayoutTest();
}

void setFontAntialiasingEnabledForTest(bool value)
{
    LayoutTestSupport::setFontAntialiasingEnabledForTest(value);
}

bool fontAntialiasingEnabledForTest()
{
    return LayoutTestSupport::isFontAntialiasingEnabledForTest();
}

void enableLogChannel(const char* name)
{
#if !LOG_DISABLED
    WTFLogChannel* channel = getChannelFromName(name);
    if (channel)
        channel->state = WTFLogChannelOn;
#endif // !LOG_DISABLED
}

} // namespace blink

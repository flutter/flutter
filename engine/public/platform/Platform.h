/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef Platform_h
#define Platform_h

#ifdef WIN32
#include <windows.h>
#endif

#include "WebCommon.h"
#include "WebData.h"
#include "WebGestureDevice.h"
#include "WebGraphicsContext3D.h"
#include "WebLocalizedString.h"
#include "WebPlatformEventType.h"
#include "WebString.h"
#include "WebURLError.h"
#include "WebVector.h"

class GrContext;

namespace base {
class SingleThreadTaskRunner;
}

namespace mojo {
class NetworkService;
}

namespace blink {

class WebBlobRegistry;
class WebClipboard;
class WebCompositorSupport;
class WebConvertableToTraceFormat;
class WebDiscardableMemory;
class WebPlatformEventListener;
class WebFallbackThemeEngine;
class WebFlingAnimator;
class WebGestureCurveTarget;
class WebGestureCurve;
class WebGraphicsContext3DProvider;
class WebMimeRegistry;
class WebPublicSuffixList;
class WebSandboxSupport;
class WebScrollbarBehavior;
struct WebFloatPoint;
class WebThemeEngine;
class WebURL;
class WebURLLoader;
class WebUnitTestSupport;
struct WebLocalizedString;
struct WebSize;

class Platform {
public:
    // HTML5 Database ------------------------------------------------------

#ifdef WIN32
    typedef HANDLE FileHandle;
#else
    typedef int FileHandle;
#endif

    BLINK_PLATFORM_EXPORT static void initialize(Platform*);
    BLINK_PLATFORM_EXPORT static void shutdown();
    BLINK_PLATFORM_EXPORT static Platform* current();

    // Must return non-null.
    virtual WebClipboard* clipboard() { return 0; }

    // Must return non-null.
    virtual WebMimeRegistry* mimeRegistry() { return 0; }

    // May return null if sandbox support is not necessary
    virtual WebSandboxSupport* sandboxSupport() { return 0; }

    // May return null on some platforms.
    virtual WebThemeEngine* themeEngine() { return 0; }

    virtual WebFallbackThemeEngine* fallbackThemeEngine() { return 0; }

    // Blob ----------------------------------------------------------------

    // Must return non-null.
    virtual WebBlobRegistry* blobRegistry() { return 0; }

    // Keygen --------------------------------------------------------------

    // Handle the <keygen> tag for generating client certificates
    // Returns a base64 encoded signed copy of a public key from a newly
    // generated key pair and the supplied challenge string. keySizeindex
    // specifies the strength of the key.
    virtual WebString signedPublicKeyAndChallengeString(unsigned keySizeIndex,
                                                        const WebString& challenge,
                                                        const WebURL& url) { return WebString(); }


    // Memory --------------------------------------------------------------

    // Returns the current space allocated for the pagefile, in MB.
    // That is committed size for Windows and virtual memory size for POSIX
    virtual size_t memoryUsageMB() { return 0; }

    // Same as above, but always returns actual value, without any caches.
    virtual size_t actualMemoryUsageMB() { return 0; }

    // Return the physical memory of the current machine, in MB.
    virtual size_t physicalMemoryMB() { return 0; }

    // Return the available virtual memory of the current machine, in MB. Or
    // zero, if there is no limit.
    virtual size_t virtualMemoryLimitMB() { return 0; }

    // Return the number of of processors of the current machine.
    virtual size_t numberOfProcessors() { return 0; }

    // Returns private and shared usage, in bytes. Private bytes is the amount of
    // memory currently allocated to this process that cannot be shared. Returns
    // false on platform specific error conditions.
    virtual bool processMemorySizesInBytes(size_t* privateBytes, size_t* sharedBytes) { return false; }

    // Reports number of bytes used by memory allocator for internal needs.
    // Returns true if the size has been reported, or false otherwise.
    virtual bool memoryAllocatorWasteInBytes(size_t*) { return false; }

    // Allocates discardable memory. May return 0, even if the platform supports
    // discardable memory. If nonzero, however, then the WebDiscardableMmeory is
    // returned in an locked state. You may use its underlying data() member
    // directly, taking care to unlock it when you are ready to let it become
    // discardable.
    virtual WebDiscardableMemory* allocateAndLockDiscardableMemory(size_t bytes) { return 0; }

    // A wrapper for tcmalloc's HeapProfilerStart();
    virtual void startHeapProfiling(const WebString& /*prefix*/) { }
    // A wrapper for tcmalloc's HeapProfilerStop();
    virtual void stopHeapProfiling() { }
    // A wrapper for tcmalloc's HeapProfilerDump()
    virtual void dumpHeapProfiling(const WebString& /*reason*/) { }
    // A wrapper for tcmalloc's GetHeapProfile()
    virtual WebString getHeapProfile() { return WebString(); }

    static const size_t noDecodedImageByteLimit = static_cast<size_t>(-1);

    // Returns the maximum amount of memory a decoded image should be allowed.
    // See comments on ImageDecoder::m_maxDecodedBytes.
    virtual size_t maxDecodedImageBytes() { return noDecodedImageByteLimit; }

    // Network -------------------------------------------------------------

    virtual mojo::NetworkService* networkService() { return 0; }

    // Returns a new WebURLLoader instance.
    virtual WebURLLoader* createURLLoader() { return 0; }

    // A suggestion to cache this metadata in association with this URL.
    virtual void cacheMetadata(const WebURL&, double responseTime, const char* data, size_t dataSize) { }

    virtual WebURLError cancelledError(const WebURL&) const { return WebURLError(); }

    virtual bool isReservedIPAddress(const WebURL&) const { return false; }


    // Public Suffix List --------------------------------------------------

    // May return null on some platforms.
    virtual WebPublicSuffixList* publicSuffixList() { return 0; }


    // Resources -----------------------------------------------------------

    // Returns a localized string resource (with substitution parameters).
    virtual WebString queryLocalizedString(WebLocalizedString::Name) { return WebString(); }
    virtual WebString queryLocalizedString(WebLocalizedString::Name, const WebString& parameter) { return WebString(); }
    virtual WebString queryLocalizedString(WebLocalizedString::Name, const WebString& parameter1, const WebString& parameter2) { return WebString(); }


    // Profiling -----------------------------------------------------------

    virtual void decrementStatsCounter(const char* name) { }
    virtual void incrementStatsCounter(const char* name) { }


    // Resources -----------------------------------------------------------

    // Returns a blob of data corresponding to the named resource.
    virtual WebData loadResource(const char* name) { return WebData(); }


    // Screen -------------------------------------------------------------

    // Supplies the system monitor color profile.
    virtual void screenColorProfile(WebVector<char>* profile) { }


    // Scrollbar ----------------------------------------------------------

    // Must return non-null.
    virtual WebScrollbarBehavior* scrollbarBehavior() { return 0; }


    // Sudden Termination --------------------------------------------------

    // Disable/Enable sudden termination.
    virtual void suddenTerminationChanged(bool enabled) { }


    // System --------------------------------------------------------------

    // Returns a value such as "en-US".
    virtual WebString defaultLocale() { return WebString(); }

    // Wall clock time in seconds since the epoch.
    virtual double currentTime() { return 0; }

    // Monotonically increasing time in seconds from an arbitrary fixed point in the past.
    // This function is expected to return at least millisecond-precision values. For this reason,
    // it is recommended that the fixed point be no further in the past than the epoch.
    virtual double monotonicallyIncreasingTime() { return 0; }

    // Delayed work is driven by a shared timer.
    typedef void (*SharedTimerFunction)();
    virtual void setSharedTimerFiredFunction(SharedTimerFunction timerFunction) { }
    virtual void setSharedTimerFireInterval(double) { }
    virtual void stopSharedTimer() { }

    virtual base::SingleThreadTaskRunner* mainThreadTaskRunner() { return 0; }


    // Vibration -----------------------------------------------------------

    // Starts a vibration for the given duration in milliseconds. If there is currently an active
    // vibration it will be cancelled before the new one is started.
    virtual void vibrate(unsigned time) { }

    // Cancels the current vibration, if there is one.
    virtual void cancelVibration() { }


    // Testing -------------------------------------------------------------

    // Get a pointer to testing support interfaces. Will not be available in production builds.
    virtual WebUnitTestSupport* unitTestSupport() { return 0; }


    // Tracing -------------------------------------------------------------

    // Get a pointer to the enabled state of the given trace category. The
    // embedder can dynamically change the enabled state as trace event
    // recording is started and stopped by the application. Only long-lived
    // literal strings should be given as the category name. The implementation
    // expects the returned pointer to be held permanently in a local static. If
    // the unsigned char is non-zero, tracing is enabled. If tracing is enabled,
    // addTraceEvent is expected to be called by the trace event macros.
    virtual const unsigned char* getTraceCategoryEnabledFlag(const char* categoryName) { return 0; }

    typedef long int TraceEventAPIAtomicWord;

    // Get a pointer to a global state of the given thread. An embedder is
    // expected to update the global state as the state of the embedder changes.
    // A sampling thread in the Chromium side reads the global state periodically
    // and reflects the sampling profiled results into about:tracing.
    virtual TraceEventAPIAtomicWord* getTraceSamplingState(const unsigned bucketName) { return 0; }

    typedef uint64_t TraceEventHandle;

    // Add a trace event to the platform tracing system. Depending on the actual
    // enabled state, this event may be recorded or dropped.
    // - phase specifies the type of event:
    //   - BEGIN ('B'): Marks the beginning of a scoped event.
    //   - END ('E'): Marks the end of a scoped event.
    //   - COMPLETE ('X'): Marks the beginning of a scoped event, but doesn't
    //     need a matching END event. Instead, at the end of the scope,
    //     updateTraceEventDuration() must be called with the TraceEventHandle
    //     returned from addTraceEvent().
    //   - INSTANT ('I'): Standalone, instantaneous event.
    //   - START ('S'): Marks the beginning of an asynchronous event (the end
    //     event can occur in a different scope or thread). The id parameter is
    //     used to match START/FINISH pairs.
    //   - FINISH ('F'): Marks the end of an asynchronous event.
    //   - COUNTER ('C'): Used to trace integer quantities that change over
    //     time. The argument values are expected to be of type int.
    //   - METADATA ('M'): Reserved for internal use.
    // - categoryEnabled is the pointer returned by getTraceCategoryEnabledFlag.
    // - name is the name of the event. Also used to match BEGIN/END and
    //   START/FINISH pairs.
    // - id optionally allows events of the same name to be distinguished from
    //   each other. For example, to trace the consutruction and destruction of
    //   objects, specify the pointer as the id parameter.
    // - numArgs specifies the number of elements in argNames, argTypes, and
    //   argValues.
    // - argNames is the array of argument names. Use long-lived literal strings
    //   or specify the COPY flag.
    // - argTypes is the array of argument types:
    //   - BOOL (1): bool
    //   - UINT (2): unsigned long long
    //   - INT (3): long long
    //   - DOUBLE (4): double
    //   - POINTER (5): void*
    //   - STRING (6): char* (long-lived null-terminated char* string)
    //   - COPY_STRING (7): char* (temporary null-terminated char* string)
    //   - CONVERTABLE (8): WebConvertableToTraceFormat
    // - argValues is the array of argument values. Each value is the unsigned
    //   long long member of a union of all supported types.
    // - convertableValues is the array of WebConvertableToTraceFormat classes
    //   that may be converted to trace format by calling asTraceFormat method.
    //   ConvertableToTraceFormat interface.
    // - thresholdBeginId optionally specifies the value returned by a previous
    //   call to addTraceEvent with a BEGIN phase.
    // - threshold is used on an END phase event in conjunction with the
    //   thresholdBeginId of a prior BEGIN event. The threshold is the minimum
    //   number of microseconds that must have passed since the BEGIN event. If
    //   less than threshold microseconds has passed, the BEGIN/END pair is
    //   dropped.
    // - flags can be 0 or one or more of the following, ORed together:
    //   - COPY (0x1): treat all strings (name, argNames and argValues of type
    //     string) as temporary so that they will be copied by addTraceEvent.
    //   - HAS_ID (0x2): use the id argument to uniquely identify the event for
    //     matching with other events of the same name.
    //   - MANGLE_ID (0x4): specify this flag if the id parameter is the value
    //     of a pointer.
    virtual TraceEventHandle addTraceEvent(
        char phase,
        const unsigned char* categoryEnabledFlag,
        const char* name,
        unsigned long long id,
        int numArgs,
        const char** argNames,
        const unsigned char* argTypes,
        const unsigned long long* argValues,
        const WebConvertableToTraceFormat* convertableValues,
        unsigned char flags)
    {
        return 0;
    }

    // Set the duration field of a COMPLETE trace event.
    virtual void updateTraceEventDuration(const unsigned char* categoryEnabledFlag, const char* name, TraceEventHandle) { }

    // Callbacks for reporting histogram data.
    // CustomCounts histogram has exponential bucket sizes, so that min=1, max=1000000, bucketCount=50 would do.
    virtual void histogramCustomCounts(const char* name, int sample, int min, int max, int bucketCount) { }
    // Enumeration histogram buckets are linear, boundaryValue should be larger than any possible sample value.
    virtual void histogramEnumeration(const char* name, int sample, int boundaryValue) { }
    // Unlike enumeration histograms, sparse histograms only allocate memory for non-empty buckets.
    virtual void histogramSparse(const char* name, int sample) { }


    // GPU ----------------------------------------------------------------
    //
    // May return null if GPU is not supported.
    // Returns newly allocated and initialized offscreen WebGraphicsContext3D instance.
    // Passing an existing context to shareContext will create the new context in the same share group as the passed context.
    virtual WebGraphicsContext3D* createOffscreenGraphicsContext3D(const WebGraphicsContext3D::Attributes&, WebGraphicsContext3D* shareContext) { return 0; }
    virtual WebGraphicsContext3D* createOffscreenGraphicsContext3D(const WebGraphicsContext3D::Attributes&) { return 0; }

    // Returns a newly allocated and initialized offscreen context provider. The provider may return a null
    // graphics context if GPU is not supported.
    virtual WebGraphicsContext3DProvider* createSharedOffscreenGraphicsContext3DProvider() { return 0; }

    // Returns true if the platform is capable of producing an offscreen context suitable for accelerating 2d canvas.
    // This will return false if the platform cannot promise that contexts will be preserved across operations like
    // locking the screen or if the platform cannot provide a context with suitable performance characteristics.
    //
    // This value must be checked again after a context loss event as the platform's capabilities may have changed.
    virtual bool canAccelerate2dCanvas() { return false; }

    virtual bool isThreadedCompositingEnabled() { return false; }

    virtual WebCompositorSupport* compositorSupport() { return 0; }

    virtual WebFlingAnimator* createFlingAnimator() { return 0; }

    // Creates a new fling animation curve instance for device |deviceSource|
    // with |velocity| and already scrolled |cumulativeScroll| pixels.
    virtual WebGestureCurve* createFlingAnimationCurve(WebGestureDevice deviceSource, const WebFloatPoint& velocity, const WebSize& cumulativeScroll) { return 0; }


    // Platform events -----------------------------------------------------
    // Device Orientation, Device Motion, Device Light, Battery, Gamepad.

    // Request the platform to start listening to the events of the specified
    // type and notify the given listener (if not null) when there is an update.
    virtual void startListening(WebPlatformEventType type, WebPlatformEventListener* listener) { }

    // Request the platform to stop listening to the specified event and no
    // longer notify the listener, if any.
    virtual void stopListening(WebPlatformEventType type) { }

protected:
    virtual ~Platform() { }
};

} // namespace blink

#endif

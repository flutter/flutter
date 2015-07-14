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

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_PLATFORM_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_PLATFORM_H_

#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebData.h"
#include "sky/engine/public/platform/WebGestureDevice.h"
#include "sky/engine/public/platform/WebGraphicsContext3D.h"
#include "sky/engine/public/platform/WebLocalizedString.h"
#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/platform/WebVector.h"

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
class WebDiscardableMemory;
class WebFallbackThemeEngine;
class WebGraphicsContext3DProvider;
class WebSandboxSupport;
struct WebFloatPoint;
class WebURL;
class WebUnitTestSupport;
struct WebLocalizedString;
struct WebSize;

class Platform {
public:
    // HTML5 Database ------------------------------------------------------
    typedef int FileHandle;

    BLINK_PLATFORM_EXPORT static void initialize(Platform*);
    BLINK_PLATFORM_EXPORT static void shutdown();
    BLINK_PLATFORM_EXPORT static Platform* current();

    // Must return non-null.
    virtual WebClipboard* clipboard() { return 0; }

    // May return null if sandbox support is not necessary
    virtual WebSandboxSupport* sandboxSupport() { return 0; }


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

    // A suggestion to cache this metadata in association with this URL.
    virtual void cacheMetadata(const WebURL&, double responseTime, const char* data, size_t dataSize) { }

    // Resources -----------------------------------------------------------

    // Returns a localized string resource (with substitution parameters).
    virtual WebString queryLocalizedString(WebLocalizedString::Name) { return WebString(); }
    virtual WebString queryLocalizedString(WebLocalizedString::Name, const WebString& parameter) { return WebString(); }
    virtual WebString queryLocalizedString(WebLocalizedString::Name, const WebString& parameter1, const WebString& parameter2) { return WebString(); }


    // Profiling -----------------------------------------------------------

    virtual void decrementStatsCounter(const char* name) { }
    virtual void incrementStatsCounter(const char* name) { }

    // Screen -------------------------------------------------------------

    // Supplies the system monitor color profile.
    virtual void screenColorProfile(WebVector<char>* profile) { }


    // Sudden Termination --------------------------------------------------

    // Disable/Enable sudden termination.
    virtual void suddenTerminationChanged(bool enabled) { }


    // System --------------------------------------------------------------

    // Returns a value such as "en-US".
    virtual WebString defaultLocale() { return WebString(); }

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

protected:
    virtual ~Platform() { }
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_PLATFORM_H_

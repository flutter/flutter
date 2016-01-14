// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_EMBEDDER_H_
#define MOJO_EDK_EMBEDDER_EMBEDDER_H_

#include <functional>
#include <memory>

#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/public/c/system/types.h"

namespace mojo {

namespace embedder {

struct Configuration;
class PlatformSupport;

// Basic configuration/initialization ------------------------------------------

// |Init()| sets up the basic Mojo system environment, making the |Mojo...()|
// functions available and functional. This is never shut down (except in tests
// -- see test_embedder.h).

// Returns the global configuration. In general, you should not need to change
// the configuration, but if you do you must do it before calling |Init()|.
Configuration* GetConfiguration();

// Must be called first, or just after setting configuration parameters, to
// initialize the (global, singleton) system.
void Init(std::unique_ptr<PlatformSupport> platform_support);

// Basic functions -------------------------------------------------------------

// The functions in this section are available once |Init()| has been called.

// Start waiting on the handle asynchronously. On success, |callback| will be
// called exactly once, when |handle| satisfies a signal in |signals| or it
// becomes known that it will never do so. |callback| will be executed on an
// arbitrary thread, so it must not call any Mojo system or embedder functions.
MojoResult AsyncWait(MojoHandle handle,
                     MojoHandleSignals signals,
                     const std::function<void(MojoResult)>& callback);

// Creates a |MojoHandle| that wraps the given |PlatformHandle| (taking
// ownership of it). This |MojoHandle| can then, e.g., be passed through message
// pipes. Note: This takes ownership (and thus closes) |platform_handle| even on
// failure, which is different from what you'd expect from a Mojo API, but it
// makes for a more convenient embedder API.
MojoResult CreatePlatformHandleWrapper(
    platform::ScopedPlatformHandle platform_handle,
    MojoHandle* platform_handle_wrapper_handle);

// Retrieves the |PlatformHandle| that was wrapped into a |MojoHandle| (using
// |CreatePlatformHandleWrapper()| above). Note that the |MojoHandle| must still
// be closed separately.
MojoResult PassWrappedPlatformHandle(
    MojoHandle platform_handle_wrapper_handle,
    platform::ScopedPlatformHandle* platform_handle);

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_EMBEDDER_H_

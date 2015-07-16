// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// http://crbug.com/269623
// http://openradar.appspot.com/14999594
//
// When the default version of close used on Mac OS X fails with EINTR, the
// file descriptor is not in a deterministic state. It may have been closed,
// or it may not have been. This makes it impossible to gracefully recover
// from the error. If the close is retried after the FD has been closed, the
// subsequent close can report EBADF, or worse, it can close an unrelated FD
// opened by another thread. If the close is not retried after the FD has been
// left open, the FD is leaked. Neither of these are good options.
//
// Mac OS X provides an alternate version of close, close$NOCANCEL. This
// version will never fail with EINTR before the FD is actually closed. With
// this version, it is thus safe to call close without checking for EINTR (as
// the HANDLE_EINTR macro does) and not risk leaking the FD. In fact, mixing
// this verison of close with HANDLE_EINTR is hazardous.
//
// The $NOCANCEL variants of various system calls are activated by compiling
// with __DARWIN_NON_CANCELABLE, which prevents them from being pthread
// cancellation points. Rather than taking such a heavy-handed approach, this
// file implements an alternative: to use the $NOCANCEL variant of close (thus
// preventing it from being a pthread cancellation point) without affecting
// any other system calls.
//
// This file operates by providing a close function with the non-$NOCANCEL
// symbol name expected for the compilation environment as set by <unistd.h>
// and <sys/cdefs.h> (the DARWIN_ALIAS_C macro). That name is set by an asm
// label on the declaration of the close function, so the definition of that
// function receives that name. The function calls the $NOCANCEL variant, which
// is resolved from libsyscall. By linking with this version of close prior to
// the libsyscall version, close's implementation is overridden.

#include <sys/cdefs.h>
#include <unistd.h>

// If the non-cancelable variants of all system calls have already been
// chosen, do nothing.
#if !__DARWIN_NON_CANCELABLE

extern "C" {

#if !__DARWIN_ONLY_UNIX_CONFORMANCE

// When there's a choice between UNIX2003 and pre-UNIX2003. There's no
// close$NOCANCEL symbol in this case, so use close$NOCANCEL$UNIX2003 as the
// implementation. It does the same thing that close$NOCANCEL would do.
#define close_implementation close$NOCANCEL$UNIX2003

#else  // __DARWIN_ONLY_UNIX_CONFORMANCE

// When only UNIX2003 is supported:
#define close_implementation close$NOCANCEL

#endif

int close_implementation(int fd);

int close(int fd) {
  return close_implementation(fd);
}

#undef close_implementation

}  // extern "C"

#endif  // !__DARWIN_NON_CANCELABLE

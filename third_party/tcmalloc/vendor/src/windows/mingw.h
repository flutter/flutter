/* Copyright (c) 2007, Google Inc.
 * All rights reserved.
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
 *
 * ---
 * Author: Craig Silverstein
 *
 * MinGW is an interesting mix of unix and windows.  We use a normal
 * configure script, but still need the windows port.h to define some
 * stuff that MinGW doesn't support, like pthreads.
 */

#ifndef GOOGLE_PERFTOOLS_WINDOWS_MINGW_H_
#define GOOGLE_PERFTOOLS_WINDOWS_MINGW_H_

#ifdef __MINGW32__

// Older version of the mingw msvcrt don't define _aligned_malloc
#if __MSVCRT_VERSION__ < 0x0700
# define PERFTOOLS_NO_ALIGNED_MALLOC 1
#endif

// This must be defined before the windows.h is included.  We need at
// least 0x0400 for mutex.h to have access to TryLock, and at least
// 0x0501 for patch_functions.cc to have access to GetModuleHandleEx.
// (This latter is an optimization we could take out if need be.)
#ifndef _WIN32_WINNT
# define _WIN32_WINNT 0x0501
#endif

#define HAVE_SNPRINTF 1

// Some mingw distributions have a pthreads wrapper, but it doesn't
// work as well as native windows spinlocks (at least for us).  So
// pretend the pthreads wrapper doesn't exist, even when it does.
#undef HAVE_PTHREAD

#include "windows/port.h"

#endif  /* __MINGW32__ */

#endif  /* GOOGLE_PERFTOOLS_WINDOWS_MINGW_H_ */

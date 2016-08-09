// Copyright (c) 2007, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// All Rights Reserved.
//
// Author: Craig Silverstein
//
// This file is needed for windows -- unittests are not part of the
// perftools dll, but still want to include config.h just like the
// dll does, so they can use internal tools and APIs for testing.
//
// The problem is that config.h declares PERFTOOLS_DLL_DECL to be
// for exporting symbols, but the unittest needs to *import* symbols
// (since it's not the dll).
//
// The solution is to have this file, which is just like config.h but
// sets PERFTOOLS_DLL_DECL to do a dllimport instead of a dllexport.
//
// The reason we need this extra PERFTOOLS_DLL_DECL_FOR_UNITTESTS
// variable is in case people want to set PERFTOOLS_DLL_DECL explicitly
// to something other than __declspec(dllexport).  In that case, they
// may want to use something other than __declspec(dllimport) for the
// unittest case.  For that, we allow folks to define both
// PERFTOOLS_DLL_DECL and PERFTOOLS_DLL_DECL_FOR_UNITTESTS explicitly.
//
// NOTE: This file is equivalent to config.h on non-windows systems,
// which never defined PERFTOOLS_DLL_DECL_FOR_UNITTESTS and always
// define PERFTOOLS_DLL_DECL to the empty string.

#include "config.h"

#undef PERFTOOLS_DLL_DECL
#ifdef PERFTOOLS_DLL_DECL_FOR_UNITTESTS
# define PERFTOOLS_DLL_DECL  PERFTOOLS_DLL_DECL_FOR_UNITTESTS
#else
# define PERFTOOLS_DLL_DECL  // if DLL_DECL_FOR_UNITTESTS isn't defined, use ""
#endif

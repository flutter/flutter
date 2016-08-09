// Copyright (c) 2008, Google Inc.
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
// 
// ---
// Author: Craig Silverstein (opensource@google.com)

// When you are porting perftools to a new compiler or architecture
// (win64 vs win32) for instance, you'll need to change the mangled
// symbol names for operator new and friends at the top of
// patch_functions.cc.  This file helps you do that.
//
// It does this by defining these functions with the proper signature.
// All you need to do is compile this file and the run dumpbin on it.
// (See http://msdn.microsoft.com/en-us/library/5x49w699.aspx for more
// on dumpbin).  To do this in MSVC, use the MSVC commandline shell:
//    http://msdn.microsoft.com/en-us/library/ms235639(VS.80).aspx)
//
// The run:
//    cl /c get_mangled_names.cc
//    dumpbin /symbols get_mangled_names.obj
//
// It will print out the mangled (and associated unmangled) names of
// the 8 symbols you need to put at the top of patch_functions.cc

#include <sys/types.h>   // for size_t
#include <new>           // for nothrow_t

static char m;   // some dummy memory so new doesn't return NULL.

void* operator new(size_t size) { return &m; }
void operator delete(void* p) throw() { }
void* operator new[](size_t size) { return &m; }
void operator delete[](void* p) throw() { }

void* operator new(size_t size, const std::nothrow_t&) throw() { return &m; }
void operator delete(void* p, const std::nothrow_t&) throw() { }
void* operator new[](size_t size, const std::nothrow_t&) throw() { return &m; }
void operator delete[](void* p, const std::nothrow_t&) throw() { }

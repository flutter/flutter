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
// Author: Craig Silverstein

#ifndef TCMALLOC_TOOLS_TESTUTIL_H_
#define TCMALLOC_TOOLS_TESTUTIL_H_

// Run a function in a thread of its own and wait for it to finish.
// The function you pass in must have the signature
//    void MyFunction();
extern "C" void RunThread(void (*fn)());

// Run a function X times, in X threads, and wait for them all to finish.
// The function you pass in must have the signature
//    void MyFunction();
extern "C" void RunManyThreads(void (*fn)(), int count);

// The 'advanced' version: run a function X times, in X threads, and
// wait for them all to finish.  Give them all the specified stack-size.
// (If you're curious why this takes a stacksize and the others don't,
// it's because the one client of this fn wanted to specify stacksize. :-) )
// The function you pass in must have the signature
//    void MyFunction(int idx);
// where idx is the index of the thread (which of the X threads this is).
extern "C" void RunManyThreadsWithId(void (*fn)(int), int count, int stacksize);

// When compiled 64-bit and run on systems with swap several unittests will end
// up trying to consume all of RAM+swap, and that can take quite some time.  By
// limiting the address-space size we get sufficient coverage without blowing
// out job limits.
void SetTestResourceLimit();

#endif  // TCMALLOC_TOOLS_TESTUTIL_H_

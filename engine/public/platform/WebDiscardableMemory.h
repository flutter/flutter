/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebDiscardableMemory_h
#define WebDiscardableMemory_h

namespace blink {

// A memory allocation that can be automatically discarded by the operating
// system under memory pressure.
//
// Discardable usage is typically:
//    WebDiscardableMemory* mem = allocateAndLockedDiscardableMemory(1024*1024);
//    void* data = mem->data();
//    memset(data, 3, 1024*1024);
//    mem->unlock();
//
// Later, when you need it again:
//    if (!mem->lock()) {
//       ... handle the fact that the memory is gone...
//       delete mem; // Make sure to destroy it. It is never going to come back.
//       return;
//    }
//    ... use mem->data() as much as you want
//    mem->unlock();
//
class WebDiscardableMemory {
public:
    // Must not be called while locked.
    virtual ~WebDiscardableMemory() { }

    // Locks the memory, prevent it from being discarded. Once locked. you may
    // obtain a pointer to that memory using the data() method.
    //
    // lock() may return false, indicating that the underlying memory was
    // discarded and that the lock failed. In this case, the
    // WebDiscardableMemory is effectively dead.
    //
    // Nested calls to lock are not allowed.
    virtual bool lock() = 0;

    // Returns the current pointer for the discardable memory. This call is ONLY
    // valid when the discardable memory object is locked.
    virtual void* data() = 0;

    // Unlock the memory so that it can be purged by the system. Must be called
    // after every successful lock call.
    virtual void unlock() = 0;
};

} // namespace blink

#endif

/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#ifndef TestingPlatformSupport_h
#define TestingPlatformSupport_h

#include "public/platform/Platform.h"
#include "public/platform/WebDiscardableMemory.h"
#include "wtf/Vector.h"

namespace blink {

class TestingDiscardableMemory : public WebDiscardableMemory {
public:
    explicit TestingDiscardableMemory(size_t);
    virtual ~TestingDiscardableMemory();

    // WebDiscardableMemory:
    virtual bool lock() override;
    virtual void* data() override;
    virtual void unlock() override;

private:
    Vector<char> m_data;
    bool m_isLocked;
};

class TestingPlatformSupport : public Platform {
public:
    struct Config {
        Config() : hasDiscardableMemorySupport(false) { }

        bool hasDiscardableMemorySupport;
    };

    explicit TestingPlatformSupport(const Config&);

    virtual ~TestingPlatformSupport();

    // Platform:
    virtual WebDiscardableMemory* allocateAndLockDiscardableMemory(size_t bytes) override;
    virtual void cryptographicallyRandomValues(unsigned char* buffer, size_t length) override;
    virtual const unsigned char* getTraceCategoryEnabledFlag(const char* categoryName) override;

private:
    const Config m_config;
    Platform* const m_oldPlatform;
};

} // namespace blink

#endif // TestingPlatformSupport_h

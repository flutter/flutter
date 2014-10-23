/*
 * Copyright (c) 2013, Opera Software ASA. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Opera Software ASA nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/dom/DOMImplementation.h"

#include "wtf/text/WTFString.h"
#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(DOMImplementationTest, TextMIMEType)
{
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("text/plain"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("text/javascript"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("TEXT/JavaScript"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/json"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/jSON"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/json;foo=2"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/json  "));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/+json"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/x-javascript-like+json;a=2;c=4"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/javascript"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("Application/Javascript"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/x-custom+json;b=3"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/x-custom+json"));
    // Outside of RFC-2045 grammar, but robustly accept/allow.
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/x-what+json;"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/json;"));
    EXPECT_TRUE(DOMImplementation::isTextMIMEType("application/json "));

    EXPECT_FALSE(DOMImplementation::isTextMIMEType("application/x-custom;a=a+json"));
    EXPECT_FALSE(DOMImplementation::isTextMIMEType("application/x-custom;a=a+json ;"));
    EXPECT_FALSE(DOMImplementation::isTextMIMEType("application/x-custom+jsonsoup"));
    EXPECT_FALSE(DOMImplementation::isTextMIMEType("application/x-custom+jsonsoup  "));
    EXPECT_FALSE(DOMImplementation::isTextMIMEType("text/html"));
    EXPECT_FALSE(DOMImplementation::isTextMIMEType("text/xml"));
}

}

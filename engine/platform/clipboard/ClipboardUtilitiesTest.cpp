/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#include "config.h"
#include "platform/clipboard/ClipboardUtilities.h"

#include "wtf/StdLibExtras.h"
#include "wtf/text/WTFString.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

const char invalidCharacters[] =
    "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
    "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
    "\x7f/";
const char longString[] =
    "0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,10946,17711,28657,46368,"
    "75025,121393,196418,317811,514229,832040,1346269,2178309,3524578,5702887,9227465,14930352";

TEST(ClipboardUtilitiesTest, Normal)
{
    String name = "name";
    String extension = "ext";
    validateFilename(name, extension);
    EXPECT_EQ("name", name);
    EXPECT_EQ("ext", extension);
}

TEST(ClipboardUtilitiesTest, InvalidCharacters)
{
    String name = "na" + String(invalidCharacters, WTF_ARRAY_LENGTH(invalidCharacters)) + "me";
    String extension = "e" + String(invalidCharacters, WTF_ARRAY_LENGTH(invalidCharacters)) + "xt";
    validateFilename(name, extension);
    EXPECT_EQ("name", name);
    EXPECT_EQ("ext", extension);
}

TEST(ClipboardUtilitiesTest, ExtensionTooLong)
{
    String name;
    String extension = String(longString) + longString;
    validateFilename(name, extension);
    EXPECT_EQ(String(), extension);
}

TEST(ClipboardUtilitiesTest, NamePlusExtensionTooLong)
{
    String name = String(longString) + longString;
    String extension = longString;
    validateFilename(name, extension);
    EXPECT_EQ("0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,109", name);
    EXPECT_EQ(longString, extension);
    EXPECT_EQ(254u, name.length() + extension.length());
}

} // anonymous namespace

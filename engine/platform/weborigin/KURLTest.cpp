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

// Basic tests that verify our KURL's interface behaves the same as the
// original KURL's.

#include "config.h"
#include "platform/weborigin/KURL.h"

#include "wtf/testing/WTFTestHelpers.h"
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"
#include <gtest/gtest.h>

namespace {

struct ComponentCase {
    const char* url;
    const char* protocol;
    const char* host;
    const int port;
    const char* user;
    const char* pass;
    const char* lastPath;
    const char* query;
    const char* ref;
};

// Test the cases where we should be the same as WebKit's old KURL.
TEST(KURLTest, SameGetters)
{
    struct GetterCase {
        const char* url;
        const char* protocol;
        const char* host;
        int port;
        const char* user;
        const char* pass;
        const char* lastPathComponent;
        const char* query;
        const char* ref;
        bool hasRef;
    } cases[] = {
        {"http://www.google.com/foo/blah?bar=baz#ref", "http", "www.google.com", 0, "", 0, "blah", "bar=baz", "ref", true},
        {"http://foo.com:1234/foo/bar/", "http", "foo.com", 1234, "", 0, "bar", 0, 0, false},
        {"http://www.google.com?#", "http", "www.google.com", 0, "", 0, 0, "", "", true},
        {"https://me:pass@google.com:23#foo", "https", "google.com", 23, "me", "pass", 0, 0, "foo", true},
        {"javascript:hello!//world", "javascript", "", 0, "", 0, "world", 0, 0, false},
    };

    for (size_t i = 0; i < arraysize(cases); i++) {
        // UTF-8
        blink::KURL kurl(blink::ParsedURLString, cases[i].url);

        EXPECT_EQ(cases[i].protocol, kurl.protocol());
        EXPECT_EQ(cases[i].host, kurl.host());
        EXPECT_EQ(cases[i].port, kurl.port());
        EXPECT_EQ(cases[i].user, kurl.user());
        EXPECT_EQ(cases[i].pass, kurl.pass());
        EXPECT_EQ(cases[i].lastPathComponent, kurl.lastPathComponent());
        EXPECT_EQ(cases[i].query, kurl.query());
        EXPECT_EQ(cases[i].ref, kurl.fragmentIdentifier());
        EXPECT_EQ(cases[i].hasRef, kurl.hasFragmentIdentifier());

        // UTF-16
        WTF::String utf16(cases[i].url);
        kurl = blink::KURL(blink::ParsedURLString, utf16);

        EXPECT_EQ(cases[i].protocol, kurl.protocol());
        EXPECT_EQ(cases[i].host, kurl.host());
        EXPECT_EQ(cases[i].port, kurl.port());
        EXPECT_EQ(cases[i].user, kurl.user());
        EXPECT_EQ(cases[i].pass, kurl.pass());
        EXPECT_EQ(cases[i].lastPathComponent, kurl.lastPathComponent());
        EXPECT_EQ(cases[i].query, kurl.query());
        EXPECT_EQ(cases[i].ref, kurl.fragmentIdentifier());
        EXPECT_EQ(cases[i].hasRef, kurl.hasFragmentIdentifier());
    }
}

// Test a few cases where we're different just to make sure we give reasonable
// output.
TEST(KURLTest, DISABLED_DifferentGetters)
{
    ComponentCase cases[] = {
        // url                                    protocol      host        port  user  pass             lastPath  query      ref

        // Old WebKit allows references and queries in what we call "path" URLs
        // like javascript, so the path here will only consist of "hello!".
        {"javascript:hello!?#/\\world",           "javascript", "",         0,    "",   0,               "world",  0,         0},

        // Old WebKit doesn't handle "parameters" in paths, so will
        // disagree with us about where the path is for this URL.
        {"http://a.com/hello;world",              "http",       "a.com",    0,    "",   0,               "hello",  0,         0},

        // WebKit doesn't like UTF-8 or UTF-16 input.
        {"http://\xe4\xbd\xa0\xe5\xa5\xbd\xe4\xbd\xa0\xe5\xa5\xbd/", "http", "xn--6qqa088eba", 0, "", 0, 0,        0,         0},

        // WebKit %-escapes non-ASCII characters in reference, but we don't.
        {"http://www.google.com/foo/blah?bar=baz#\xce\xb1\xce\xb2", "http", "www.google.com", 0, "", 0,  "blah", "bar=baz", "\xce\xb1\xce\xb2"},
    };

    for (size_t i = 0; i < arraysize(cases); i++) {
        blink::KURL kurl(blink::ParsedURLString, cases[i].url);

        EXPECT_EQ(cases[i].protocol, kurl.protocol());
        EXPECT_EQ(cases[i].host, kurl.host());
        EXPECT_EQ(cases[i].port, kurl.port());
        EXPECT_EQ(cases[i].user, kurl.user());
        EXPECT_EQ(cases[i].pass, kurl.pass());
        EXPECT_EQ(cases[i].lastPath, kurl.lastPathComponent());
        EXPECT_EQ(cases[i].query, kurl.query());
        // Want to compare UCS-16 refs (or to null).
        if (cases[i].ref)
            EXPECT_EQ(WTF::String::fromUTF8(cases[i].ref), kurl.fragmentIdentifier());
        else
            EXPECT_TRUE(kurl.fragmentIdentifier().isNull());
    }
}

// Ensures that both ASCII and UTF-8 canonical URLs are handled properly and we
// get the correct string object out.
TEST(KURLTest, DISABLED_UTF8)
{
    const char asciiURL[] = "http://foo/bar#baz";
    blink::KURL asciiKURL(blink::ParsedURLString, asciiURL);
    EXPECT_TRUE(asciiKURL.string() == WTF::String(asciiURL));

    // When the result is ASCII, we should get an ASCII String. Some
    // code depends on being able to compare the result of the .string()
    // getter with another String, and the isASCIIness of the two
    // strings must match for these functions (like equalIgnoringCase).
    EXPECT_TRUE(WTF::equalIgnoringCase(asciiKURL, WTF::String(asciiURL)));

    // Reproduce code path in FrameLoader.cpp -- equalIgnoringCase implicitly
    // expects gkurl.protocol() to have been created as ascii.
    blink::KURL mailto(blink::ParsedURLString, "mailto:foo@foo.com");
    EXPECT_TRUE(WTF::equalIgnoringCase(mailto.protocol(), "mailto"));

    const char utf8URL[] = "http://foo/bar#\xe4\xbd\xa0\xe5\xa5\xbd";
    blink::KURL utf8KURL(blink::ParsedURLString, utf8URL);

    EXPECT_TRUE(utf8KURL.string() == WTF::String::fromUTF8(utf8URL));
}

TEST(KURLTest, Setters)
{
    // Replace the starting URL with the given components one at a time and
    // verify that we're always the same as the old KURL.
    //
    // Note that old KURL won't canonicalize the default port away, so we
    // can't set setting the http port to "80" (or even "0").
    //
    // We also can't test clearing the query.
    struct ExpectedComponentCase {
        const char* url;

        const char* protocol;
        const char* expectedProtocol;

        const char* host;
        const char* expectedHost;

        const int port;
        const char* expectedPort;

        const char* user;
        const char* expectedUser;

        const char* pass;
        const char* expectedPass;

        const char* path;
        const char* expectedPath;

        const char* query;
        const char* expectedQuery;
    } cases[] = {
        {
            "http://www.google.com/",
            // protocol
            "https", "https://www.google.com/",
            // host
            "news.google.com", "https://news.google.com/",
            // port
            8888, "https://news.google.com:8888/",
            // user
            "me", "https://me@news.google.com:8888/",
            // pass
            "pass", "https://me:pass@news.google.com:8888/",
            // path
            "/foo", "https://me:pass@news.google.com:8888/foo",
            // query
            "?q=asdf", "https://me:pass@news.google.com:8888/foo?q=asdf"
        }, {
            "https://me:pass@google.com:88/a?f#b",
            // protocol
            "http", "http://me:pass@google.com:88/a?f#b",
            // host
            "goo.com", "http://me:pass@goo.com:88/a?f#b",
            // port
            92, "http://me:pass@goo.com:92/a?f#b",
            // user
            "", "http://:pass@goo.com:92/a?f#b",
            // pass
            "", "http://goo.com:92/a?f#b",
            // path
            "/", "http://goo.com:92/?f#b",
            // query
            0, "http://goo.com:92/#b"
        },
    };

    for (size_t i = 0; i < arraysize(cases); i++) {
        blink::KURL kurl(blink::ParsedURLString, cases[i].url);

        kurl.setProtocol(cases[i].protocol);
        EXPECT_STREQ(cases[i].expectedProtocol, kurl.string().utf8().data());

        kurl.setHost(cases[i].host);
        EXPECT_STREQ(cases[i].expectedHost, kurl.string().utf8().data());

        kurl.setPort(cases[i].port);
        EXPECT_STREQ(cases[i].expectedPort, kurl.string().utf8().data());

        kurl.setUser(cases[i].user);
        EXPECT_STREQ(cases[i].expectedUser, kurl.string().utf8().data());

        kurl.setPass(cases[i].pass);
        EXPECT_STREQ(cases[i].expectedPass, kurl.string().utf8().data());

        kurl.setPath(cases[i].path);
        EXPECT_STREQ(cases[i].expectedPath, kurl.string().utf8().data());

        kurl.setQuery(cases[i].query);
        EXPECT_STREQ(cases[i].expectedQuery, kurl.string().utf8().data());

        // Refs are tested below. On the Safari 3.1 branch, we don't match their
        // KURL since we integrated a fix from their trunk.
    }
}

// Tests that KURL::decodeURLEscapeSequences works as expected
TEST(KURLTest, Decode)
{
    struct DecodeCase {
        const char* input;
        const char* output;
    } decodeCases[] = {
        {"hello, world", "hello, world"},
        {"%01%02%03%04%05%06%07%08%09%0a%0B%0C%0D%0e%0f/", "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0B\x0C\x0D\x0e\x0f/"},
        {"%10%11%12%13%14%15%16%17%18%19%1a%1B%1C%1D%1e%1f/", "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1B\x1C\x1D\x1e\x1f/"},
        {"%20%21%22%23%24%25%26%27%28%29%2a%2B%2C%2D%2e%2f/", " !\"#$%&'()*+,-.//"},
        {"%30%31%32%33%34%35%36%37%38%39%3a%3B%3C%3D%3e%3f/", "0123456789:;<=>?/"},
        {"%40%41%42%43%44%45%46%47%48%49%4a%4B%4C%4D%4e%4f/", "@ABCDEFGHIJKLMNO/"},
        {"%50%51%52%53%54%55%56%57%58%59%5a%5B%5C%5D%5e%5f/", "PQRSTUVWXYZ[\\]^_/"},
        {"%60%61%62%63%64%65%66%67%68%69%6a%6B%6C%6D%6e%6f/", "`abcdefghijklmno/"},
        {"%70%71%72%73%74%75%76%77%78%79%7a%7B%7C%7D%7e%7f/", "pqrstuvwxyz{|}~\x7f/"},
          // Test un-UTF-8-ization.
        {"%e4%bd%a0%e5%a5%bd", "\xe4\xbd\xa0\xe5\xa5\xbd"},
    };

    for (size_t i = 0; i < arraysize(decodeCases); i++) {
        WTF::String input(decodeCases[i].input);
        WTF::String str = blink::decodeURLEscapeSequences(input);
        EXPECT_STREQ(decodeCases[i].output, str.utf8().data());
    }

    // Our decode should decode %00
    WTF::String zero = blink::decodeURLEscapeSequences("%00");
    EXPECT_STRNE("%00", zero.utf8().data());

    // Test the error behavior for invalid UTF-8 (we differ from WebKit here).
    WTF::String invalid = blink::decodeURLEscapeSequences(
        "%e4%a0%e5%a5%bd");
    UChar invalidExpectedHelper[4] = { 0x00e4, 0x00a0, 0x597d, 0 };
    WTF::String invalidExpected(
        reinterpret_cast<const ::UChar*>(invalidExpectedHelper),
        3);
    EXPECT_EQ(invalidExpected, invalid);
}

TEST(KURLTest, Encode)
{
    struct EncodeCase {
        const char* input;
        const char* output;
    } encode_cases[] = {
        {"hello, world", "hello%2C%20world"},
        {"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F",
          "%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F"},
        {"\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F",
          "%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F"},
        {" !\"#$%&'()*+,-./", "%20!%22%23%24%25%26%27()*%2B%2C-./"},
        {"0123456789:;<=>?",
          "0123456789%3A%3B%3C%3D%3E%3F"},
        {"@ABCDEFGHIJKLMNO",
          "%40ABCDEFGHIJKLMNO"},
        {"PQRSTUVWXYZ[\\]^_",
          "PQRSTUVWXYZ%5B%5C%5D%5E_"},
        {"`abcdefghijklmno",
          "%60abcdefghijklmno"},
        {"pqrstuvwxyz{|}~\x7f",
          "pqrstuvwxyz%7B%7C%7D~%7F"},
    };

    for (size_t i = 0; i < arraysize(encode_cases); i++) {
        WTF::String input(encode_cases[i].input);
        WTF::String expectedOutput(encode_cases[i].output);
        WTF::String output = blink::encodeWithURLEscapeSequences(input);
        EXPECT_EQ(expectedOutput, output);
    }

    // Our encode escapes NULLs for safety, so we need to check that too.
    WTF::String input("\x00\x01", 2);
    WTF::String reference("%00%01");

    WTF::String output = blink::encodeWithURLEscapeSequences(input);
    EXPECT_EQ(reference, output);

    // Also test that it gets converted to UTF-8 properly.
    UChar wideInputHelper[3] = { 0x4f60, 0x597d, 0 };
    WTF::String wideInput(
        reinterpret_cast<const ::UChar*>(wideInputHelper), 2);
    WTF::String wideReference("%E4%BD%A0%E5%A5%BD");
    WTF::String wideOutput =
        blink::encodeWithURLEscapeSequences(wideInput);
    EXPECT_EQ(wideReference, wideOutput);
}

TEST(KURLTest, ResolveEmpty)
{
    blink::KURL emptyBase;

    // WebKit likes to be able to resolve absolute input agains empty base URLs,
    // which would normally be invalid since the base URL is invalid.
    const char abs[] = "http://www.google.com/";
    blink::KURL resolveAbs(emptyBase, abs);
    EXPECT_TRUE(resolveAbs.isValid());
    EXPECT_STREQ(abs, resolveAbs.string().utf8().data());

    // Resolving a non-relative URL agains the empty one should still error.
    const char rel[] = "foo.html";
    blink::KURL resolveErr(emptyBase, rel);
    EXPECT_FALSE(resolveErr.isValid());
}

// WebKit will make empty URLs and set components on them. kurl doesn't allow
// replacements on invalid URLs, but here we do.
TEST(KURLTest, ReplaceInvalid)
{
    blink::KURL kurl;

    EXPECT_FALSE(kurl.isValid());
    EXPECT_TRUE(kurl.isEmpty());
    EXPECT_STREQ("", kurl.string().utf8().data());

    kurl.setProtocol("http");
    // GKURL will say that a URL with just a scheme is invalid, KURL will not.
    EXPECT_FALSE(kurl.isValid());
    EXPECT_FALSE(kurl.isEmpty());
    // At this point, we do things slightly differently if there is only a scheme.
    // We check the results here to make it more obvious what is going on, but it
    // shouldn't be a big deal if these change.
    EXPECT_STREQ("http:", kurl.string().utf8().data());

    kurl.setHost("www.google.com");
    EXPECT_TRUE(kurl.isValid());
    EXPECT_FALSE(kurl.isEmpty());
    EXPECT_STREQ("http://www.google.com/", kurl.string().utf8().data());

    kurl.setPort(8000);
    EXPECT_TRUE(kurl.isValid());
    EXPECT_FALSE(kurl.isEmpty());
    EXPECT_STREQ("http://www.google.com:8000/", kurl.string().utf8().data());

    kurl.setPath("/favicon.ico");
    EXPECT_TRUE(kurl.isValid());
    EXPECT_FALSE(kurl.isEmpty());
    EXPECT_STREQ("http://www.google.com:8000/favicon.ico", kurl.string().utf8().data());

    // Now let's test that giving an invalid replacement fails. Invalid
    // protocols fail without modifying the URL, which should remain valid.
    EXPECT_FALSE(kurl.setProtocol("f/sj#@"));
    EXPECT_TRUE(kurl.isValid());
}

TEST(KURLTest, Path)
{
    const char initial[] = "http://www.google.com/path/foo";
    blink::KURL kurl(blink::ParsedURLString, initial);

    // Clear by setting a null string.
    WTF::String nullString;
    EXPECT_TRUE(nullString.isNull());
    kurl.setPath(nullString);
    EXPECT_STREQ("http://www.google.com/", kurl.string().utf8().data());
}

// Test that setting the query to different things works. Thq query is handled
// a littler differently than some of the other components.
TEST(KURLTest, Query)
{
    const char initial[] = "http://www.google.com/search?q=awesome";
    blink::KURL kurl(blink::ParsedURLString, initial);

    // Clear by setting a null string.
    WTF::String nullString;
    EXPECT_TRUE(nullString.isNull());
    kurl.setQuery(nullString);
    EXPECT_STREQ("http://www.google.com/search", kurl.string().utf8().data());

    // Clear by setting an empty string.
    kurl = blink::KURL(blink::ParsedURLString, initial);
    WTF::String emptyString("");
    EXPECT_FALSE(emptyString.isNull());
    kurl.setQuery(emptyString);
    EXPECT_STREQ("http://www.google.com/search?", kurl.string().utf8().data());

    // Set with something that begins in a question mark.
    const char question[] = "?foo=bar";
    kurl.setQuery(question);
    EXPECT_STREQ("http://www.google.com/search?foo=bar",
                 kurl.string().utf8().data());

    // Set with something that doesn't begin in a question mark.
    const char query[] = "foo=bar";
    kurl.setQuery(query);
    EXPECT_STREQ("http://www.google.com/search?foo=bar",
                 kurl.string().utf8().data());
}

TEST(KURLTest, Ref)
{
    blink::KURL kurl(blink::ParsedURLString, "http://foo/bar#baz");

    // Basic ref setting.
    blink::KURL cur(blink::ParsedURLString, "http://foo/bar");
    cur.setFragmentIdentifier("asdf");
    EXPECT_STREQ("http://foo/bar#asdf", cur.string().utf8().data());
    cur = kurl;
    cur.setFragmentIdentifier("asdf");
    EXPECT_STREQ("http://foo/bar#asdf", cur.string().utf8().data());

    // Setting a ref to the empty string will set it to "#".
    cur = blink::KURL(blink::ParsedURLString, "http://foo/bar");
    cur.setFragmentIdentifier("");
    EXPECT_STREQ("http://foo/bar#", cur.string().utf8().data());
    cur = kurl;
    cur.setFragmentIdentifier("");
    EXPECT_STREQ("http://foo/bar#", cur.string().utf8().data());

    // Setting the ref to the null string will clear it altogether.
    cur = blink::KURL(blink::ParsedURLString, "http://foo/bar");
    cur.setFragmentIdentifier(WTF::String());
    EXPECT_STREQ("http://foo/bar", cur.string().utf8().data());
    cur = kurl;
    cur.setFragmentIdentifier(WTF::String());
    EXPECT_STREQ("http://foo/bar", cur.string().utf8().data());
}

TEST(KURLTest, Empty)
{
    blink::KURL kurl;

    // First test that regular empty URLs are the same.
    EXPECT_TRUE(kurl.isEmpty());
    EXPECT_FALSE(kurl.isValid());
    EXPECT_TRUE(kurl.isNull());
    EXPECT_TRUE(kurl.string().isNull());
    EXPECT_TRUE(kurl.string().isEmpty());

    // Test resolving a null URL on an empty string.
    blink::KURL kurl2(kurl, "");
    EXPECT_FALSE(kurl2.isNull());
    EXPECT_TRUE(kurl2.isEmpty());
    EXPECT_FALSE(kurl2.isValid());
    EXPECT_FALSE(kurl2.string().isNull());
    EXPECT_TRUE(kurl2.string().isEmpty());
    EXPECT_FALSE(kurl2.string().isNull());
    EXPECT_TRUE(kurl2.string().isEmpty());

    // Resolve the null URL on a null string.
    blink::KURL kurl22(kurl, WTF::String());
    EXPECT_FALSE(kurl22.isNull());
    EXPECT_TRUE(kurl22.isEmpty());
    EXPECT_FALSE(kurl22.isValid());
    EXPECT_FALSE(kurl22.string().isNull());
    EXPECT_TRUE(kurl22.string().isEmpty());
    EXPECT_FALSE(kurl22.string().isNull());
    EXPECT_TRUE(kurl22.string().isEmpty());

    // Test non-hierarchical schemes resolving. The actual URLs will be different.
    // WebKit's one will set the string to "something.gif" and we'll set it to an
    // empty string. I think either is OK, so we just check our behavior.
    blink::KURL kurl3(blink::KURL(blink::ParsedURLString, "data:foo"),
                        "something.gif");
    EXPECT_TRUE(kurl3.isEmpty());
    EXPECT_FALSE(kurl3.isValid());

    // Test for weird isNull string input,
    // see: http://bugs.webkit.org/show_bug.cgi?id=16487
    blink::KURL kurl4(blink::ParsedURLString, kurl.string());
    EXPECT_TRUE(kurl4.isEmpty());
    EXPECT_FALSE(kurl4.isValid());
    EXPECT_TRUE(kurl4.string().isNull());
    EXPECT_TRUE(kurl4.string().isEmpty());

    // Resolving an empty URL on an invalid string.
    blink::KURL kurl5(blink::KURL(), "foo.js");
    // We'll be empty in this case, but KURL won't be. Should be OK.
    // EXPECT_EQ(kurl5.isEmpty(), kurl5.isEmpty());
    // EXPECT_EQ(kurl5.string().isEmpty(), kurl5.string().isEmpty());
    EXPECT_FALSE(kurl5.isValid());
    EXPECT_FALSE(kurl5.string().isNull());

    // Empty string as input
    blink::KURL kurl6(blink::ParsedURLString, "");
    EXPECT_TRUE(kurl6.isEmpty());
    EXPECT_FALSE(kurl6.isValid());
    EXPECT_FALSE(kurl6.string().isNull());
    EXPECT_TRUE(kurl6.string().isEmpty());

    // Non-empty but invalid C string as input.
    blink::KURL kurl7(blink::ParsedURLString, "foo.js");
    // WebKit will actually say this URL has the string "foo.js" but is invalid.
    // We don't do that.
    // EXPECT_EQ(kurl7.isEmpty(), kurl7.isEmpty());
    EXPECT_FALSE(kurl7.isValid());
    EXPECT_FALSE(kurl7.string().isNull());
}

TEST(KURLTest, UserPass)
{
    const char* src = "http://user:pass@google.com/";
    blink::KURL kurl(blink::ParsedURLString, src);

    // Clear just the username.
    kurl.setUser("");
    EXPECT_EQ("http://:pass@google.com/", kurl.string());

    // Clear just the password.
    kurl = blink::KURL(blink::ParsedURLString, src);
    kurl.setPass("");
    EXPECT_EQ("http://user@google.com/", kurl.string());

    // Now clear both.
    kurl.setUser("");
    EXPECT_EQ("http://google.com/", kurl.string());
}

TEST(KURLTest, Offsets)
{
    const char* src1 = "http://user:pass@google.com/foo/bar.html?baz=query#ref";
    blink::KURL kurl1(blink::ParsedURLString, src1);

    EXPECT_EQ(17u, kurl1.hostStart());
    EXPECT_EQ(27u, kurl1.hostEnd());
    EXPECT_EQ(27u, kurl1.pathStart());
    EXPECT_EQ(40u, kurl1.pathEnd());
    EXPECT_EQ(32u, kurl1.pathAfterLastSlash());

    const char* src2 = "http://google.com/foo/";
    blink::KURL kurl2(blink::ParsedURLString, src2);

    EXPECT_EQ(7u, kurl2.hostStart());
    EXPECT_EQ(17u, kurl2.hostEnd());
    EXPECT_EQ(17u, kurl2.pathStart());
    EXPECT_EQ(22u, kurl2.pathEnd());
    EXPECT_EQ(22u, kurl2.pathAfterLastSlash());

    const char* src3 = "javascript:foobar";
    blink::KURL kurl3(blink::ParsedURLString, src3);

    EXPECT_EQ(11u, kurl3.hostStart());
    EXPECT_EQ(11u, kurl3.hostEnd());
    EXPECT_EQ(11u, kurl3.pathStart());
    EXPECT_EQ(17u, kurl3.pathEnd());
    EXPECT_EQ(11u, kurl3.pathAfterLastSlash());
}

TEST(KURLTest, DeepCopy)
{
    const char url[] = "http://www.google.com/";
    blink::KURL src(blink::ParsedURLString, url);
    EXPECT_TRUE(src.string() == url); // This really just initializes the cache.
    blink::KURL dest = src.copy();
    EXPECT_TRUE(dest.string() == url); // This really just initializes the cache.

    // The pointers should be different for both UTF-8 and UTF-16.
    EXPECT_NE(dest.string().impl(), src.string().impl());
}

TEST(KURLTest, DeepCopyInnerURL)
{
    const char url[] = "filesystem:http://www.google.com/temporary/test.txt";
    const char innerURL[] = "http://www.google.com/temporary";
    blink::KURL src(blink::ParsedURLString, url);
    EXPECT_TRUE(src.string() == url);
    EXPECT_TRUE(src.innerURL()->string() == innerURL);
    blink::KURL dest = src.copy();
    EXPECT_TRUE(dest.string() == url);
    EXPECT_TRUE(dest.innerURL()->string() == innerURL);
}

TEST(KURLTest, LastPathComponent)
{
    blink::KURL url1(blink::ParsedURLString, "http://host/path/to/file.txt");
    EXPECT_EQ("file.txt", url1.lastPathComponent());

    blink::KURL invalidUTF8(blink::ParsedURLString, "http://a@9%aa%:/path/to/file.txt");
    EXPECT_EQ(String(), invalidUTF8.lastPathComponent());
}

TEST(KURLTest, IsHierarchical)
{
    blink::KURL url1(blink::ParsedURLString, "http://host/path/to/file.txt");
    EXPECT_TRUE(url1.isHierarchical());

    blink::KURL invalidUTF8(blink::ParsedURLString, "http://a@9%aa%:/path/to/file.txt");
    EXPECT_FALSE(invalidUTF8.isHierarchical());
}

TEST(KURLTest, PathAfterLastSlash)
{
    blink::KURL url1(blink::ParsedURLString, "http://host/path/to/file.txt");
    EXPECT_EQ(20u, url1.pathAfterLastSlash());

    blink::KURL invalidUTF8(blink::ParsedURLString, "http://a@9%aa%:/path/to/file.txt");
    EXPECT_EQ(0u, invalidUTF8.pathAfterLastSlash());
}

TEST(KURLTest, ProtocolIsInHTTPFamily)
{
    blink::KURL url1(blink::ParsedURLString, "http://host/path/to/file.txt");
    EXPECT_TRUE(url1.protocolIsInHTTPFamily());

    blink::KURL invalidUTF8(blink::ParsedURLString, "http://a@9%aa%:/path/to/file.txt");
    EXPECT_FALSE(invalidUTF8.protocolIsInHTTPFamily());
}

TEST(KURLTest, ProtocolIs)
{
    blink::KURL url1(blink::ParsedURLString, "foo://bar");
    EXPECT_TRUE(url1.protocolIs("foo"));
    EXPECT_FALSE(url1.protocolIs("foo-bar"));

    blink::KURL url2(blink::ParsedURLString, "foo-bar:");
    EXPECT_TRUE(url2.protocolIs("foo-bar"));
    EXPECT_FALSE(url2.protocolIs("foo"));

    blink::KURL invalidUTF8(blink::ParsedURLString, "http://a@9%aa%:");
    EXPECT_FALSE(invalidUTF8.protocolIs("http"));
    EXPECT_TRUE(invalidUTF8.protocolIs(""));
}

TEST(KURLTest, strippedForUseAsReferrer)
{
    struct ReferrerCase {
        const char* input;
        const char* output;
    } referrerCases[] = {
        {"data:text/html;charset=utf-8,<html></html>", ""},
        {"javascript:void(0);", ""},
        {"about:config", ""},
        {"https://www.google.com/", "https://www.google.com/"},
        {"http://me@news.google.com:8888/", "http://news.google.com:8888/"},
        {"http://:pass@news.google.com:8888/foo", "http://news.google.com:8888/foo"},
        {"http://me:pass@news.google.com:8888/", "http://news.google.com:8888/"},
        {"https://www.google.com/a?f#b", "https://www.google.com/a?f"},
    };

    for (size_t i = 0; i < arraysize(referrerCases); i++) {
        blink::KURL kurl(blink::ParsedURLString, referrerCases[i].input);
        WTF::String referrer = kurl.strippedForUseAsReferrer();
        EXPECT_STREQ(referrerCases[i].output, referrer.utf8().data());
    }
}

} // namespace

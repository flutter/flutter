// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/macros.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "url/gurl.h"
#include "url/url_canon.h"
#include "url/url_test_utils.h"

namespace url {

using test_utils::WStringToUTF16;
using test_utils::ConvertUTF8ToUTF16;

namespace {

template<typename CHAR>
void SetupReplacement(
    void (Replacements<CHAR>::*func)(const CHAR*, const Component&),
    Replacements<CHAR>* replacements,
    const CHAR* str) {
  if (str) {
    Component comp;
    if (str[0])
      comp.len = static_cast<int>(strlen(str));
    (replacements->*func)(str, comp);
  }
}

// Returns the canonicalized string for the given URL string for the
// GURLTest.Types test.
std::string TypesTestCase(const char* src) {
  GURL gurl(src);
  return gurl.possibly_invalid_spec();
}

}  // namespace

// Different types of URLs should be handled differently, and handed off to
// different canonicalizers.
TEST(GURLTest, Types) {
  // URLs with unknown schemes should be treated as path URLs, even when they
  // have things like "://".
  EXPECT_EQ("something:///HOSTNAME.com/",
            TypesTestCase("something:///HOSTNAME.com/"));

  // In the reverse, known schemes should always trigger standard URL handling.
  EXPECT_EQ("http://hostname.com/", TypesTestCase("http:HOSTNAME.com"));
  EXPECT_EQ("http://hostname.com/", TypesTestCase("http:/HOSTNAME.com"));
  EXPECT_EQ("http://hostname.com/", TypesTestCase("http://HOSTNAME.com"));
  EXPECT_EQ("http://hostname.com/", TypesTestCase("http:///HOSTNAME.com"));

#ifdef WIN32
  // URLs that look like absolute Windows drive specs.
  EXPECT_EQ("file:///C:/foo.txt", TypesTestCase("c:\\foo.txt"));
  EXPECT_EQ("file:///Z:/foo.txt", TypesTestCase("Z|foo.txt"));
  EXPECT_EQ("file://server/foo.txt", TypesTestCase("\\\\server\\foo.txt"));
  EXPECT_EQ("file://server/foo.txt", TypesTestCase("//server/foo.txt"));
#endif
}

// Test the basic creation and querying of components in a GURL. We assume
// the parser is already tested and works, so we are mostly interested if the
// object does the right thing with the results.
TEST(GURLTest, Components) {
  GURL url(WStringToUTF16(L"http://user:pass@google.com:99/foo;bar?q=a#ref"));
  EXPECT_TRUE(url.is_valid());
  EXPECT_TRUE(url.SchemeIs("http"));
  EXPECT_FALSE(url.SchemeIsFile());

  // This is the narrow version of the URL, which should match the wide input.
  EXPECT_EQ("http://user:pass@google.com:99/foo;bar?q=a#ref", url.spec());

  EXPECT_EQ("http", url.scheme());
  EXPECT_EQ("user", url.username());
  EXPECT_EQ("pass", url.password());
  EXPECT_EQ("google.com", url.host());
  EXPECT_EQ("99", url.port());
  EXPECT_EQ(99, url.IntPort());
  EXPECT_EQ("/foo;bar", url.path());
  EXPECT_EQ("q=a", url.query());
  EXPECT_EQ("ref", url.ref());

  // Test parsing userinfo with special characters.
  GURL url_special_pass("http://user:%40!$&'()*+,;=:@google.com:12345");
  EXPECT_TRUE(url_special_pass.is_valid());
  // GURL canonicalizes some delimiters.
  EXPECT_EQ("%40!$&%27()*+,%3B%3D%3A", url_special_pass.password());
  EXPECT_EQ("google.com", url_special_pass.host());
  EXPECT_EQ("12345", url_special_pass.port());
}

TEST(GURLTest, Empty) {
  GURL url;
  EXPECT_FALSE(url.is_valid());
  EXPECT_EQ("", url.spec());

  EXPECT_EQ("", url.scheme());
  EXPECT_EQ("", url.username());
  EXPECT_EQ("", url.password());
  EXPECT_EQ("", url.host());
  EXPECT_EQ("", url.port());
  EXPECT_EQ(PORT_UNSPECIFIED, url.IntPort());
  EXPECT_EQ("", url.path());
  EXPECT_EQ("", url.query());
  EXPECT_EQ("", url.ref());
}

TEST(GURLTest, Copy) {
  GURL url(WStringToUTF16(L"http://user:pass@google.com:99/foo;bar?q=a#ref"));

  GURL url2(url);
  EXPECT_TRUE(url2.is_valid());

  EXPECT_EQ("http://user:pass@google.com:99/foo;bar?q=a#ref", url2.spec());
  EXPECT_EQ("http", url2.scheme());
  EXPECT_EQ("user", url2.username());
  EXPECT_EQ("pass", url2.password());
  EXPECT_EQ("google.com", url2.host());
  EXPECT_EQ("99", url2.port());
  EXPECT_EQ(99, url2.IntPort());
  EXPECT_EQ("/foo;bar", url2.path());
  EXPECT_EQ("q=a", url2.query());
  EXPECT_EQ("ref", url2.ref());

  // Copying of invalid URL should be invalid
  GURL invalid;
  GURL invalid2(invalid);
  EXPECT_FALSE(invalid2.is_valid());
  EXPECT_EQ("", invalid2.spec());
  EXPECT_EQ("", invalid2.scheme());
  EXPECT_EQ("", invalid2.username());
  EXPECT_EQ("", invalid2.password());
  EXPECT_EQ("", invalid2.host());
  EXPECT_EQ("", invalid2.port());
  EXPECT_EQ(PORT_UNSPECIFIED, invalid2.IntPort());
  EXPECT_EQ("", invalid2.path());
  EXPECT_EQ("", invalid2.query());
  EXPECT_EQ("", invalid2.ref());
}

TEST(GURLTest, Assign) {
  GURL url(WStringToUTF16(L"http://user:pass@google.com:99/foo;bar?q=a#ref"));

  GURL url2;
  url2 = url;
  EXPECT_TRUE(url2.is_valid());

  EXPECT_EQ("http://user:pass@google.com:99/foo;bar?q=a#ref", url2.spec());
  EXPECT_EQ("http", url2.scheme());
  EXPECT_EQ("user", url2.username());
  EXPECT_EQ("pass", url2.password());
  EXPECT_EQ("google.com", url2.host());
  EXPECT_EQ("99", url2.port());
  EXPECT_EQ(99, url2.IntPort());
  EXPECT_EQ("/foo;bar", url2.path());
  EXPECT_EQ("q=a", url2.query());
  EXPECT_EQ("ref", url2.ref());

  // Assignment of invalid URL should be invalid
  GURL invalid;
  GURL invalid2;
  invalid2 = invalid;
  EXPECT_FALSE(invalid2.is_valid());
  EXPECT_EQ("", invalid2.spec());
  EXPECT_EQ("", invalid2.scheme());
  EXPECT_EQ("", invalid2.username());
  EXPECT_EQ("", invalid2.password());
  EXPECT_EQ("", invalid2.host());
  EXPECT_EQ("", invalid2.port());
  EXPECT_EQ(PORT_UNSPECIFIED, invalid2.IntPort());
  EXPECT_EQ("", invalid2.path());
  EXPECT_EQ("", invalid2.query());
  EXPECT_EQ("", invalid2.ref());
}

// This is a regression test for http://crbug.com/309975 .
TEST(GURLTest, SelfAssign) {
  GURL a("filesystem:http://example.com/temporary/");
  // This should not crash.
  a = a;
}

TEST(GURLTest, CopyFileSystem) {
  GURL url(WStringToUTF16(L"filesystem:https://user:pass@google.com:99/t/foo;bar?q=a#ref"));

  GURL url2(url);
  EXPECT_TRUE(url2.is_valid());

  EXPECT_EQ("filesystem:https://user:pass@google.com:99/t/foo;bar?q=a#ref", url2.spec());
  EXPECT_EQ("filesystem", url2.scheme());
  EXPECT_EQ("", url2.username());
  EXPECT_EQ("", url2.password());
  EXPECT_EQ("", url2.host());
  EXPECT_EQ("", url2.port());
  EXPECT_EQ(PORT_UNSPECIFIED, url2.IntPort());
  EXPECT_EQ("/foo;bar", url2.path());
  EXPECT_EQ("q=a", url2.query());
  EXPECT_EQ("ref", url2.ref());

  const GURL* inner = url2.inner_url();
  ASSERT_TRUE(inner);
  EXPECT_EQ("https", inner->scheme());
  EXPECT_EQ("user", inner->username());
  EXPECT_EQ("pass", inner->password());
  EXPECT_EQ("google.com", inner->host());
  EXPECT_EQ("99", inner->port());
  EXPECT_EQ(99, inner->IntPort());
  EXPECT_EQ("/t", inner->path());
  EXPECT_EQ("", inner->query());
  EXPECT_EQ("", inner->ref());
}

TEST(GURLTest, IsValid) {
  const char* valid_cases[] = {
    "http://google.com",
    "unknown://google.com",
    "http://user:pass@google.com",
    "http://google.com:12345",
    "http://google.com/path",
    "http://google.com//path",
    "http://google.com?k=v#fragment",
    "http://user:pass@google.com:12345/path?k=v#fragment",
    "http:/path",
    "http:path",
    "://google.com",
  };
  for (size_t i = 0; i < arraysize(valid_cases); i++) {
    EXPECT_TRUE(GURL(valid_cases[i]).is_valid())
        << "Case: " << valid_cases[i];
  }

  const char* invalid_cases[] = {
    "http://?k=v",
    "http:://google.com",
    "http//google.com",
    "http://google.com:12three45",
    "path",
  };
  for (size_t i = 0; i < arraysize(invalid_cases); i++) {
    EXPECT_FALSE(GURL(invalid_cases[i]).is_valid())
        << "Case: " << invalid_cases[i];
  }
}

TEST(GURLTest, ExtraSlashesBeforeAuthority) {
  // According to RFC3986, the hier-part for URI with an authority must use only
  // two slashes, GURL intentionally just ignores slashes more than 2 and parses
  // the following part as an authority.
  GURL url("http:///host");
  EXPECT_EQ("host", url.host());
  EXPECT_EQ("/", url.path());
}

// Given an invalid URL, we should still get most of the components.
TEST(GURLTest, ComponentGettersWorkEvenForInvalidURL) {
  GURL url("http:google.com:foo");
  EXPECT_FALSE(url.is_valid());
  EXPECT_EQ("http://google.com:foo/", url.possibly_invalid_spec());

  EXPECT_EQ("http", url.scheme());
  EXPECT_EQ("", url.username());
  EXPECT_EQ("", url.password());
  EXPECT_EQ("google.com", url.host());
  EXPECT_EQ("foo", url.port());
  EXPECT_EQ(PORT_INVALID, url.IntPort());
  EXPECT_EQ("/", url.path());
  EXPECT_EQ("", url.query());
  EXPECT_EQ("", url.ref());
}

TEST(GURLTest, Resolve) {
  // The tricky cases for relative URL resolving are tested in the
  // canonicalizer unit test. Here, we just test that the GURL integration
  // works properly.
  struct ResolveCase {
    const char* base;
    const char* relative;
    bool expected_valid;
    const char* expected;
  } resolve_cases[] = {
    {"http://www.google.com/", "foo.html", true, "http://www.google.com/foo.html"},
    {"http://www.google.com/foo/", "bar", true, "http://www.google.com/foo/bar"},
    {"http://www.google.com/foo/", "/bar", true, "http://www.google.com/bar"},
    {"http://www.google.com/foo", "bar", true, "http://www.google.com/bar"},
    {"http://www.google.com/", "http://images.google.com/foo.html", true, "http://images.google.com/foo.html"},
    {"http://www.google.com/blah/bloo?c#d", "../../../hello/./world.html?a#b", true, "http://www.google.com/hello/world.html?a#b"},
    {"http://www.google.com/foo#bar", "#com", true, "http://www.google.com/foo#com"},
    {"http://www.google.com/", "Https:images.google.com", true, "https://images.google.com/"},
      // A non-standard base can be replaced with a standard absolute URL.
    {"data:blahblah", "http://google.com/", true, "http://google.com/"},
    {"data:blahblah", "http:google.com", true, "http://google.com/"},
      // Filesystem URLs have different paths to test.
    {"filesystem:http://www.google.com/type/", "foo.html", true, "filesystem:http://www.google.com/type/foo.html"},
    {"filesystem:http://www.google.com/type/", "../foo.html", true, "filesystem:http://www.google.com/type/foo.html"},
  };

  for (size_t i = 0; i < arraysize(resolve_cases); i++) {
    // 8-bit code path.
    GURL input(resolve_cases[i].base);
    GURL output = input.Resolve(resolve_cases[i].relative);
    EXPECT_EQ(resolve_cases[i].expected_valid, output.is_valid()) << i;
    EXPECT_EQ(resolve_cases[i].expected, output.spec()) << i;
    EXPECT_EQ(output.SchemeIsFileSystem(), output.inner_url() != NULL);

    // Wide code path.
    GURL inputw(ConvertUTF8ToUTF16(resolve_cases[i].base));
    GURL outputw =
        input.Resolve(ConvertUTF8ToUTF16(resolve_cases[i].relative));
    EXPECT_EQ(resolve_cases[i].expected_valid, outputw.is_valid()) << i;
    EXPECT_EQ(resolve_cases[i].expected, outputw.spec()) << i;
    EXPECT_EQ(outputw.SchemeIsFileSystem(), outputw.inner_url() != NULL);
  }
}

TEST(GURLTest, GetOrigin) {
  struct TestCase {
    const char* input;
    const char* expected;
  } cases[] = {
    {"http://www.google.com", "http://www.google.com/"},
    {"javascript:window.alert(\"hello,world\");", ""},
    {"http://user:pass@www.google.com:21/blah#baz", "http://www.google.com:21/"},
    {"http://user@www.google.com", "http://www.google.com/"},
    {"http://:pass@www.google.com", "http://www.google.com/"},
    {"http://:@www.google.com", "http://www.google.com/"},
    {"filesystem:http://www.google.com/temp/foo?q#b", "http://www.google.com/"},
    {"filesystem:http://user:pass@google.com:21/blah#baz", "http://google.com:21/"},
  };
  for (size_t i = 0; i < arraysize(cases); i++) {
    GURL url(cases[i].input);
    GURL origin = url.GetOrigin();
    EXPECT_EQ(cases[i].expected, origin.spec());
  }
}

TEST(GURLTest, GetAsReferrer) {
  struct TestCase {
    const char* input;
    const char* expected;
  } cases[] = {
    {"http://www.google.com", "http://www.google.com/"},
    {"http://user:pass@www.google.com:21/blah#baz", "http://www.google.com:21/blah"},
    {"http://user@www.google.com", "http://www.google.com/"},
    {"http://:pass@www.google.com", "http://www.google.com/"},
    {"http://:@www.google.com", "http://www.google.com/"},
    {"http://www.google.com/temp/foo?q#b", "http://www.google.com/temp/foo?q"},
    {"not a url", ""},
    {"unknown-scheme://foo.html", ""},
    {"file:///tmp/test.html", ""},
    {"https://www.google.com", "https://www.google.com/"},
  };
  for (size_t i = 0; i < arraysize(cases); i++) {
    GURL url(cases[i].input);
    GURL origin = url.GetAsReferrer();
    EXPECT_EQ(cases[i].expected, origin.spec());
  }
}

TEST(GURLTest, GetWithEmptyPath) {
  struct TestCase {
    const char* input;
    const char* expected;
  } cases[] = {
    {"http://www.google.com", "http://www.google.com/"},
    {"javascript:window.alert(\"hello, world\");", ""},
    {"http://www.google.com/foo/bar.html?baz=22", "http://www.google.com/"},
    {"filesystem:http://www.google.com/temporary/bar.html?baz=22", "filesystem:http://www.google.com/temporary/"},
    {"filesystem:file:///temporary/bar.html?baz=22", "filesystem:file:///temporary/"},
  };

  for (size_t i = 0; i < arraysize(cases); i++) {
    GURL url(cases[i].input);
    GURL empty_path = url.GetWithEmptyPath();
    EXPECT_EQ(cases[i].expected, empty_path.spec());
  }
}

TEST(GURLTest, Replacements) {
  // The url canonicalizer replacement test will handle most of these case.
  // The most important thing to do here is to check that the proper
  // canonicalizer gets called based on the scheme of the input.
  struct ReplaceCase {
    const char* base;
    const char* scheme;
    const char* username;
    const char* password;
    const char* host;
    const char* port;
    const char* path;
    const char* query;
    const char* ref;
    const char* expected;
  } replace_cases[] = {
    {"http://www.google.com/foo/bar.html?foo#bar", NULL, NULL, NULL, NULL, NULL, "/", "", "", "http://www.google.com/"},
    {"http://www.google.com/foo/bar.html?foo#bar", "javascript", "", "", "", "", "window.open('foo');", "", "", "javascript:window.open('foo');"},
    {"file:///C:/foo/bar.txt", "http", NULL, NULL, "www.google.com", "99", "/foo","search", "ref", "http://www.google.com:99/foo?search#ref"},
#ifdef WIN32
    {"http://www.google.com/foo/bar.html?foo#bar", "file", "", "", "", "", "c:\\", "", "", "file:///C:/"},
#endif
    {"filesystem:http://www.google.com/foo/bar.html?foo#bar", NULL, NULL, NULL, NULL, NULL, "/", "", "", "filesystem:http://www.google.com/foo/"},
  };

  for (size_t i = 0; i < arraysize(replace_cases); i++) {
    const ReplaceCase& cur = replace_cases[i];
    GURL url(cur.base);
    GURL::Replacements repl;
    SetupReplacement(&GURL::Replacements::SetScheme, &repl, cur.scheme);
    SetupReplacement(&GURL::Replacements::SetUsername, &repl, cur.username);
    SetupReplacement(&GURL::Replacements::SetPassword, &repl, cur.password);
    SetupReplacement(&GURL::Replacements::SetHost, &repl, cur.host);
    SetupReplacement(&GURL::Replacements::SetPort, &repl, cur.port);
    SetupReplacement(&GURL::Replacements::SetPath, &repl, cur.path);
    SetupReplacement(&GURL::Replacements::SetQuery, &repl, cur.query);
    SetupReplacement(&GURL::Replacements::SetRef, &repl, cur.ref);
    GURL output = url.ReplaceComponents(repl);

    EXPECT_EQ(replace_cases[i].expected, output.spec());
    EXPECT_EQ(output.SchemeIsFileSystem(), output.inner_url() != NULL);
  }
}

TEST(GURLTest, ClearFragmentOnDataUrl) {
  // http://crbug.com/291747 - a data URL may legitimately have trailing
  // whitespace in the spec after the ref is cleared. Test this does not trigger
  // the Parsed importing validation DCHECK in GURL.
  GURL url(" data: one ? two # three ");

  // By default the trailing whitespace will have been stripped.
  EXPECT_EQ("data: one ? two # three", url.spec());
  GURL::Replacements repl;
  repl.ClearRef();
  GURL url_no_ref = url.ReplaceComponents(repl);

  EXPECT_EQ("data: one ? two ", url_no_ref.spec());

  // Importing a parsed url via this constructor overload will retain trailing
  // whitespace.
  GURL import_url(url_no_ref.spec(),
                  url_no_ref.parsed_for_possibly_invalid_spec(),
                  url_no_ref.is_valid());
  EXPECT_EQ(url_no_ref, import_url);
  EXPECT_EQ(import_url.query(), " two ");
}

TEST(GURLTest, PathForRequest) {
  struct TestCase {
    const char* input;
    const char* expected;
    const char* inner_expected;
  } cases[] = {
    {"http://www.google.com", "/", NULL},
    {"http://www.google.com/", "/", NULL},
    {"http://www.google.com/foo/bar.html?baz=22", "/foo/bar.html?baz=22", NULL},
    {"http://www.google.com/foo/bar.html#ref", "/foo/bar.html", NULL},
    {"http://www.google.com/foo/bar.html?query#ref", "/foo/bar.html?query", NULL},
    {"filesystem:http://www.google.com/temporary/foo/bar.html?query#ref", "/foo/bar.html?query", "/temporary"},
    {"filesystem:http://www.google.com/temporary/foo/bar.html?query", "/foo/bar.html?query", "/temporary"},
  };

  for (size_t i = 0; i < arraysize(cases); i++) {
    GURL url(cases[i].input);
    std::string path_request = url.PathForRequest();
    EXPECT_EQ(cases[i].expected, path_request);
    EXPECT_EQ(cases[i].inner_expected == NULL, url.inner_url() == NULL);
    if (url.inner_url() && cases[i].inner_expected)
      EXPECT_EQ(cases[i].inner_expected, url.inner_url()->PathForRequest());
  }
}

TEST(GURLTest, EffectiveIntPort) {
  struct PortTest {
    const char* spec;
    int expected_int_port;
  } port_tests[] = {
    // http
    {"http://www.google.com/", 80},
    {"http://www.google.com:80/", 80},
    {"http://www.google.com:443/", 443},

    // https
    {"https://www.google.com/", 443},
    {"https://www.google.com:443/", 443},
    {"https://www.google.com:80/", 80},

    // ftp
    {"ftp://www.google.com/", 21},
    {"ftp://www.google.com:21/", 21},
    {"ftp://www.google.com:80/", 80},

    // gopher
    {"gopher://www.google.com/", 70},
    {"gopher://www.google.com:70/", 70},
    {"gopher://www.google.com:80/", 80},

    // file - no port
    {"file://www.google.com/", PORT_UNSPECIFIED},
    {"file://www.google.com:443/", PORT_UNSPECIFIED},

    // data - no port
    {"data:www.google.com:90", PORT_UNSPECIFIED},
    {"data:www.google.com", PORT_UNSPECIFIED},

    // filesystem - no port
    {"filesystem:http://www.google.com:90/t/foo", PORT_UNSPECIFIED},
    {"filesystem:file:///t/foo", PORT_UNSPECIFIED},
  };

  for (size_t i = 0; i < arraysize(port_tests); i++) {
    GURL url(port_tests[i].spec);
    EXPECT_EQ(port_tests[i].expected_int_port, url.EffectiveIntPort());
  }
}

TEST(GURLTest, IPAddress) {
  struct IPTest {
    const char* spec;
    bool expected_ip;
  } ip_tests[] = {
    {"http://www.google.com/", false},
    {"http://192.168.9.1/", true},
    {"http://192.168.9.1.2/", false},
    {"http://192.168.m.1/", false},
    {"http://2001:db8::1/", false},
    {"http://[2001:db8::1]/", true},
    {"", false},
    {"some random input!", false},
  };

  for (size_t i = 0; i < arraysize(ip_tests); i++) {
    GURL url(ip_tests[i].spec);
    EXPECT_EQ(ip_tests[i].expected_ip, url.HostIsIPAddress());
  }
}

TEST(GURLTest, HostNoBrackets) {
  struct TestCase {
    const char* input;
    const char* expected_host;
    const char* expected_plainhost;
  } cases[] = {
    {"http://www.google.com", "www.google.com", "www.google.com"},
    {"http://[2001:db8::1]/", "[2001:db8::1]", "2001:db8::1"},
    {"http://[::]/", "[::]", "::"},

    // Don't require a valid URL, but don't crash either.
    {"http://[]/", "[]", ""},
    {"http://[x]/", "[x]", "x"},
    {"http://[x/", "[x", "[x"},
    {"http://x]/", "x]", "x]"},
    {"http://[/", "[", "["},
    {"http://]/", "]", "]"},
    {"", "", ""},
  };
  for (size_t i = 0; i < arraysize(cases); i++) {
    GURL url(cases[i].input);
    EXPECT_EQ(cases[i].expected_host, url.host());
    EXPECT_EQ(cases[i].expected_plainhost, url.HostNoBrackets());
  }
}

TEST(GURLTest, DomainIs) {
  const char google_domain[] = "google.com";

  GURL url_1("http://www.google.com:99/foo");
  EXPECT_TRUE(url_1.DomainIs(google_domain));

  GURL url_2("http://google.com:99/foo");
  EXPECT_TRUE(url_2.DomainIs(google_domain));

  GURL url_3("http://google.com./foo");
  EXPECT_TRUE(url_3.DomainIs(google_domain));

  GURL url_4("http://google.com/foo");
  EXPECT_FALSE(url_4.DomainIs("google.com."));

  GURL url_5("http://google.com./foo");
  EXPECT_TRUE(url_5.DomainIs("google.com."));

  GURL url_6("http://www.google.com./foo");
  EXPECT_TRUE(url_6.DomainIs(".com."));

  GURL url_7("http://www.balabala.com/foo");
  EXPECT_FALSE(url_7.DomainIs(google_domain));

  GURL url_8("http://www.google.com.cn/foo");
  EXPECT_FALSE(url_8.DomainIs(google_domain));

  GURL url_9("http://www.iamnotgoogle.com/foo");
  EXPECT_FALSE(url_9.DomainIs(google_domain));

  GURL url_10("http://www.iamnotgoogle.com../foo");
  EXPECT_FALSE(url_10.DomainIs(".com"));

  GURL url_11("filesystem:http://www.google.com:99/foo/");
  EXPECT_TRUE(url_11.DomainIs(google_domain));

  GURL url_12("filesystem:http://www.iamnotgoogle.com/foo/");
  EXPECT_FALSE(url_12.DomainIs(google_domain));
}

// Newlines should be stripped from inputs.
TEST(GURLTest, Newlines) {
  // Constructor.
  GURL url_1(" \t ht\ntp://\twww.goo\rgle.com/as\ndf \n ");
  EXPECT_EQ("http://www.google.com/asdf", url_1.spec());

  // Relative path resolver.
  GURL url_2 = url_1.Resolve(" \n /fo\to\r ");
  EXPECT_EQ("http://www.google.com/foo", url_2.spec());

  // Note that newlines are NOT stripped from ReplaceComponents.
}

TEST(GURLTest, IsStandard) {
  GURL a("http:foo/bar");
  EXPECT_TRUE(a.IsStandard());

  GURL b("foo:bar/baz");
  EXPECT_FALSE(b.IsStandard());

  GURL c("foo://bar/baz");
  EXPECT_FALSE(c.IsStandard());
}

TEST(GURLTest, SchemeIsHTTPOrHTTPS) {
  EXPECT_TRUE(GURL("http://bar/").SchemeIsHTTPOrHTTPS());
  EXPECT_TRUE(GURL("HTTPS://BAR").SchemeIsHTTPOrHTTPS());
  EXPECT_FALSE(GURL("ftp://bar/").SchemeIsHTTPOrHTTPS());
}

TEST(GURLTest, SchemeIsWSOrWSS) {
  EXPECT_TRUE(GURL("WS://BAR/").SchemeIsWSOrWSS());
  EXPECT_TRUE(GURL("wss://bar/").SchemeIsWSOrWSS());
  EXPECT_FALSE(GURL("http://bar/").SchemeIsWSOrWSS());
}

TEST(GURLTest, SchemeIsBlob) {
  EXPECT_TRUE(GURL("BLOB://BAR/").SchemeIsBlob());
  EXPECT_TRUE(GURL("blob://bar/").SchemeIsBlob());
  EXPECT_FALSE(GURL("http://bar/").SchemeIsBlob());
}

}  // namespace url

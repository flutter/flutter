// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "url/url_parse.h"

#include "base/macros.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "url/url_parse.h"

// Interesting IE file:isms...
//
//  file:/foo/bar              file:///foo/bar
//      The result here seems totally invalid!?!? This isn't UNC.
//
//  file:/
//  file:// or any other number of slashes
//      IE6 doesn't do anything at all if you click on this link. No error:
//      nothing. IE6's history system seems to always color this link, so I'm
//      guessing that it maps internally to the empty URL.
//
//  C:\                        file:///C:/
//  /                          file:///C:/
//  /foo                       file:///C:/foo
//      Interestingly, IE treats "/" as an alias for "c:\", which makes sense,
//      but is weird to think about on Windows.
//
//  file:foo/                  file:foo/  (invalid?!?!?)
//  file:/foo/                 file:///foo/  (invalid?!?!?)
//  file://foo/                file://foo/   (UNC to server "foo")
//  file:///foo/               file:///foo/  (invalid)
//  file:////foo/              file://foo/   (UNC to server "foo")
//      Any more than four slashes is also treated as UNC.
//
//  file:C:/                   file://C:/
//  file:/C:/                  file://C:/
//      The number of slashes after "file:" don't matter if the thing following
//      it looks like an absolute drive path. Also, slashes and backslashes are
//      equally valid here.

namespace url {
namespace {

// Used for regular URL parse cases.
struct URLParseCase {
  const char* input;

  const char* scheme;
  const char* username;
  const char* password;
  const char* host;
  int port;
  const char* path;
  const char* query;
  const char* ref;
};

// Simpler version of URLParseCase for testing path URLs.
struct PathURLParseCase {
  const char* input;

  const char* scheme;
  const char* path;
};

// Simpler version of URLParseCase for testing mailto URLs.
struct MailtoURLParseCase {
  const char* input;

  const char* scheme;
  const char* path;
  const char* query;
};

// More complicated version of URLParseCase for testing filesystem URLs.
struct FileSystemURLParseCase {
  const char* input;

  const char* inner_scheme;
  const char* inner_username;
  const char* inner_password;
  const char* inner_host;
  int inner_port;
  const char* inner_path;
  const char* path;
  const char* query;
  const char* ref;
};

bool ComponentMatches(const char* input,
                      const char* reference,
                      const Component& component) {
  // If the component is nonexistant (length == -1), it should begin at 0.
  EXPECT_TRUE(component.len >= 0 || component.len == -1);

  // Begin should be valid.
  EXPECT_LE(0, component.begin);

  // A NULL reference means the component should be nonexistant.
  if (!reference)
    return component.len == -1;
  if (component.len < 0)
    return false;  // Reference is not NULL but we don't have anything

  if (strlen(reference) != static_cast<size_t>(component.len))
    return false;  // Lengths don't match

  // Now check the actual characters.
  return strncmp(reference, &input[component.begin], component.len) == 0;
}

void ExpectInvalidComponent(const Component& component) {
  EXPECT_EQ(0, component.begin);
  EXPECT_EQ(-1, component.len);
}

// Parsed ----------------------------------------------------------------------

TEST(URLParser, Length) {
  const char* length_cases[] = {
      // One with everything in it.
    "http://user:pass@host:99/foo?bar#baz",
      // One with nothing in it.
    "",
      // Working backwards, let's start taking off stuff from the full one.
    "http://user:pass@host:99/foo?bar#",
    "http://user:pass@host:99/foo?bar",
    "http://user:pass@host:99/foo?",
    "http://user:pass@host:99/foo",
    "http://user:pass@host:99/",
    "http://user:pass@host:99",
    "http://user:pass@host:",
    "http://user:pass@host",
    "http://host",
    "http://user@",
    "http:",
  };
  for (size_t i = 0; i < arraysize(length_cases); i++) {
    int true_length = static_cast<int>(strlen(length_cases[i]));

    Parsed parsed;
    ParseStandardURL(length_cases[i], true_length, &parsed);

    EXPECT_EQ(true_length, parsed.Length());
  }
}

TEST(URLParser, CountCharactersBefore) {
  struct CountCase {
    const char* url;
    Parsed::ComponentType component;
    bool include_delimiter;
    int expected_count;
  } count_cases[] = {
  // Test each possibility in the case where all components are present.
  //    0         1         2
  //    0123456789012345678901
    {"http://u:p@h:8/p?q#r", Parsed::SCHEME, true, 0},
    {"http://u:p@h:8/p?q#r", Parsed::SCHEME, false, 0},
    {"http://u:p@h:8/p?q#r", Parsed::USERNAME, true, 7},
    {"http://u:p@h:8/p?q#r", Parsed::USERNAME, false, 7},
    {"http://u:p@h:8/p?q#r", Parsed::PASSWORD, true, 9},
    {"http://u:p@h:8/p?q#r", Parsed::PASSWORD, false, 9},
    {"http://u:p@h:8/p?q#r", Parsed::HOST, true, 11},
    {"http://u:p@h:8/p?q#r", Parsed::HOST, false, 11},
    {"http://u:p@h:8/p?q#r", Parsed::PORT, true, 12},
    {"http://u:p@h:8/p?q#r", Parsed::PORT, false, 13},
    {"http://u:p@h:8/p?q#r", Parsed::PATH, false, 14},
    {"http://u:p@h:8/p?q#r", Parsed::PATH, true, 14},
    {"http://u:p@h:8/p?q#r", Parsed::QUERY, true, 16},
    {"http://u:p@h:8/p?q#r", Parsed::QUERY, false, 17},
    {"http://u:p@h:8/p?q#r", Parsed::REF, true, 18},
    {"http://u:p@h:8/p?q#r", Parsed::REF, false, 19},
      // Now test when the requested component is missing.
    {"http://u:p@h:8/p?", Parsed::REF, true, 17},
    {"http://u:p@h:8/p?q", Parsed::REF, true, 18},
    {"http://u:p@h:8/p#r", Parsed::QUERY, true, 16},
    {"http://u:p@h:8#r", Parsed::PATH, true, 14},
    {"http://u:p@h/", Parsed::PORT, true, 12},
    {"http://u:p@/", Parsed::HOST, true, 11},
      // This case is a little weird. It will report that the password would
      // start where the host begins. This is arguably correct, although you
      // could also argue that it should start at the '@' sign. Doing it
      // starting with the '@' sign is actually harder, so we don't bother.
    {"http://u@h/", Parsed::PASSWORD, true, 9},
    {"http://h/", Parsed::USERNAME, true, 7},
    {"http:", Parsed::USERNAME, true, 5},
    {"", Parsed::SCHEME, true, 0},
      // Make sure a random component still works when there's nothing there.
    {"", Parsed::REF, true, 0},
      // File URLs are special with no host, so we test those.
    {"file:///c:/foo", Parsed::USERNAME, true, 7},
    {"file:///c:/foo", Parsed::PASSWORD, true, 7},
    {"file:///c:/foo", Parsed::HOST, true, 7},
    {"file:///c:/foo", Parsed::PATH, true, 7},
  };
  for (size_t i = 0; i < arraysize(count_cases); i++) {
    int length = static_cast<int>(strlen(count_cases[i].url));

    // Simple test to distinguish file and standard URLs.
    Parsed parsed;
    if (length > 0 && count_cases[i].url[0] == 'f')
      ParseFileURL(count_cases[i].url, length, &parsed);
    else
      ParseStandardURL(count_cases[i].url, length, &parsed);

    int chars_before = parsed.CountCharactersBefore(
        count_cases[i].component, count_cases[i].include_delimiter);
    EXPECT_EQ(count_cases[i].expected_count, chars_before);
  }
}

// Standard --------------------------------------------------------------------

// Input                               Scheme  Usrname Passwd     Host         Port Path       Query        Ref
// ------------------------------------ ------- ------- ---------- ------------ --- ---------- ------------ -----
static URLParseCase cases[] = {
  // Regular URL with all the parts
{"http://user:pass@foo:21/bar;par?b#c", "http", "user", "pass",    "foo",       21, "/bar;par","b",          "c"},

  // Known schemes should lean towards authority identification
{"http:foo.com",                        "http", NULL,  NULL,      "foo.com",    -1, NULL,      NULL,        NULL},

  // Spaces!
{"\t   :foo.com   \n",                  "",     NULL,  NULL,      "foo.com",    -1, NULL,      NULL,        NULL},
{" foo.com  ",                          NULL,   NULL,  NULL,      "foo.com",    -1, NULL,      NULL,        NULL},
{"a:\t foo.com",                        "a",    NULL,  NULL,      "\t foo.com", -1, NULL,      NULL,        NULL},
{"http://f:21/ b ? d # e ",             "http", NULL,  NULL,      "f",          21, "/ b ",    " d ",       " e"},

  // Invalid port numbers should be identified and turned into -2, empty port
  // numbers should be -1. Spaces aren't allowed in port numbers
{"http://f:/c",                         "http", NULL,  NULL,      "f",          -1, "/c",      NULL,        NULL},
{"http://f:0/c",                        "http", NULL,  NULL,      "f",           0, "/c",      NULL,        NULL},
{"http://f:00000000000000/c",           "http", NULL,  NULL,      "f",           0, "/c",      NULL,        NULL},
{"http://f:00000000000000000000080/c",  "http", NULL,  NULL,      "f",          80, "/c",      NULL,        NULL},
{"http://f:b/c",                        "http", NULL,  NULL,      "f",          -2, "/c",      NULL,        NULL},
{"http://f: /c",                        "http", NULL,  NULL,      "f",          -2, "/c",      NULL,        NULL},
{"http://f:\n/c",                       "http", NULL,  NULL,      "f",          -2, "/c",      NULL,        NULL},
{"http://f:fifty-two/c",                "http", NULL,  NULL,      "f",          -2, "/c",      NULL,        NULL},
{"http://f:999999/c",                   "http", NULL,  NULL,      "f",          -2, "/c",      NULL,        NULL},
{"http://f: 21 / b ? d # e ",           "http", NULL,  NULL,      "f",          -2, "/ b ",    " d ",       " e"},

  // Creative URLs missing key elements
{"",                                    NULL,   NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{"  \t",                                NULL,   NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{":foo.com/",                           "",     NULL,  NULL,      "foo.com",    -1, "/",       NULL,        NULL},
{":foo.com\\",                          "",     NULL,  NULL,      "foo.com",    -1, "\\",      NULL,        NULL},
{":",                                   "",     NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{":a",                                  "",     NULL,  NULL,      "a",          -1, NULL,      NULL,        NULL},
{":/",                                  "",     NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{":\\",                                 "",     NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{":#",                                  "",     NULL,  NULL,      NULL,         -1, NULL,      NULL,        ""},
{"#",                                   NULL,   NULL,  NULL,      NULL,         -1, NULL,      NULL,        ""},
{"#/",                                  NULL,   NULL,  NULL,      NULL,         -1, NULL,      NULL,        "/"},
{"#\\",                                 NULL,   NULL,  NULL,      NULL,         -1, NULL,      NULL,        "\\"},
{"#;?",                                 NULL,   NULL,  NULL,      NULL,         -1, NULL,      NULL,        ";?"},
{"?",                                   NULL,   NULL,  NULL,      NULL,         -1, NULL,      "",          NULL},
{"/",                                   NULL,   NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{":23",                                 "",     NULL,  NULL,      "23",         -1, NULL,      NULL,        NULL},
{"/:23",                                "/",    NULL,  NULL,      "23",         -1, NULL,      NULL,        NULL},
{"//",                                  NULL,   NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{"::",                                  "",     NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{"::23",                                "",     NULL,  NULL,      NULL,         23, NULL,      NULL,        NULL},
{"foo://",                              "foo",  NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},

  // Username/passwords and things that look like them
{"http://a:b@c:29/d",                   "http", "a",   "b",       "c",          29, "/d",      NULL,        NULL},
{"http::@c:29",                         "http", "",    "",        "c",          29, NULL,      NULL,        NULL},
  // ... "]" in the password field isn't allowed, but we tolerate it here...
{"http://&a:foo(b]c@d:2/",              "http", "&a",  "foo(b]c", "d",           2, "/",       NULL,        NULL},
{"http://::@c@d:2",                     "http", "",    ":@c",     "d",           2, NULL,      NULL,        NULL},
{"http://foo.com:b@d/",                 "http", "foo.com", "b",   "d",          -1, "/",       NULL,        NULL},

{"http://foo.com/\\@",                  "http", NULL,  NULL,      "foo.com",    -1, "/\\@",    NULL,        NULL},
{"http:\\\\foo.com\\",                  "http", NULL,  NULL,      "foo.com",    -1, "\\",      NULL,        NULL},
{"http:\\\\a\\b:c\\d@foo.com\\",        "http", NULL,  NULL,      "a",          -1, "\\b:c\\d@foo.com\\", NULL,   NULL},

  // Tolerate different numbers of slashes.
{"foo:/",                               "foo",  NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{"foo:/bar.com/",                       "foo",  NULL,  NULL,      "bar.com",    -1, "/",       NULL,        NULL},
{"foo://///////",                       "foo",  NULL,  NULL,      NULL,         -1, NULL,      NULL,        NULL},
{"foo://///////bar.com/",               "foo",  NULL,  NULL,      "bar.com",    -1, "/",       NULL,        NULL},
{"foo:////://///",                      "foo",  NULL,  NULL,      NULL,         -1, "/////",   NULL,        NULL},

  // Raw file paths on Windows aren't handled by the parser.
{"c:/foo",                              "c",    NULL,  NULL,      "foo",        -1, NULL,      NULL,        NULL},
{"//foo/bar",                           NULL,   NULL,  NULL,      "foo",        -1, "/bar",    NULL,        NULL},

  // Use the first question mark for the query and the ref.
{"http://foo/path;a??e#f#g",            "http", NULL,  NULL,      "foo",        -1, "/path;a", "?e",      "f#g"},
{"http://foo/abcd?efgh?ijkl",           "http", NULL,  NULL,      "foo",        -1, "/abcd",   "efgh?ijkl", NULL},
{"http://foo/abcd#foo?bar",             "http", NULL,  NULL,      "foo",        -1, "/abcd",   NULL,        "foo?bar"},

  // IPv6, check also interesting uses of colons.
{"[61:24:74]:98",                       "[61",  NULL,  NULL,      "24:74]",     98, NULL,      NULL,        NULL},
{"http://[61:27]:98",                   "http", NULL,  NULL,      "[61:27]",    98, NULL,      NULL,        NULL},
{"http:[61:27]/:foo",                   "http", NULL,  NULL,      "[61:27]",    -1, "/:foo",   NULL,        NULL},
{"http://[1::2]:3:4",                   "http", NULL,  NULL,      "[1::2]:3",    4, NULL,      NULL,        NULL},

  // Partially-complete IPv6 literals, and related cases.
{"http://2001::1",                      "http", NULL,  NULL,      "2001:",       1, NULL,      NULL,        NULL},
{"http://[2001::1",                     "http", NULL,  NULL,      "[2001::1",   -1, NULL,      NULL,        NULL},
{"http://2001::1]",                     "http", NULL,  NULL,      "2001::1]",   -1, NULL,      NULL,        NULL},
{"http://2001::1]:80",                  "http", NULL,  NULL,      "2001::1]",   80, NULL,      NULL,        NULL},
{"http://[2001::1]",                    "http", NULL,  NULL,      "[2001::1]",  -1, NULL,      NULL,        NULL},
{"http://[2001::1]:80",                 "http", NULL,  NULL,      "[2001::1]",  80, NULL,      NULL,        NULL},
{"http://[[::]]",                       "http", NULL,  NULL,      "[[::]]",     -1, NULL,      NULL,        NULL},

};

TEST(URLParser, Standard) {
  // Declared outside for loop to try to catch cases in init() where we forget
  // to reset something that is reset by the constructor.
  Parsed parsed;
  for (size_t i = 0; i < arraysize(cases); i++) {
    const char* url = cases[i].input;
    ParseStandardURL(url, static_cast<int>(strlen(url)), &parsed);
    int port = ParsePort(url, parsed.port);

    EXPECT_TRUE(ComponentMatches(url, cases[i].scheme, parsed.scheme));
    EXPECT_TRUE(ComponentMatches(url, cases[i].username, parsed.username));
    EXPECT_TRUE(ComponentMatches(url, cases[i].password, parsed.password));
    EXPECT_TRUE(ComponentMatches(url, cases[i].host, parsed.host));
    EXPECT_EQ(cases[i].port, port);
    EXPECT_TRUE(ComponentMatches(url, cases[i].path, parsed.path));
    EXPECT_TRUE(ComponentMatches(url, cases[i].query, parsed.query));
    EXPECT_TRUE(ComponentMatches(url, cases[i].ref, parsed.ref));
  }
}

// PathURL --------------------------------------------------------------------

// Various incarnations of path URLs.
static PathURLParseCase path_cases[] = {
{"",                                        NULL,          NULL},
{":",                                       "",            NULL},
{":/",                                      "",            "/"},
{"/",                                       NULL,          "/"},
{" This is \\interesting// \t",             NULL,          "This is \\interesting// \t"},
{"about:",                                  "about",       NULL},
{"about:blank",                             "about",       "blank"},
{"  about: blank ",                         "about",       " blank "},
{"javascript :alert(\"He:/l\\l#o?foo\"); ", "javascript ", "alert(\"He:/l\\l#o?foo\"); "},
};

TEST(URLParser, PathURL) {
  // Declared outside for loop to try to catch cases in init() where we forget
  // to reset something that is reset by the construtor.
  Parsed parsed;
  for (size_t i = 0; i < arraysize(path_cases); i++) {
    const char* url = path_cases[i].input;
    ParsePathURL(url, static_cast<int>(strlen(url)), false, &parsed);

    EXPECT_TRUE(ComponentMatches(url, path_cases[i].scheme, parsed.scheme))
        << i;
    EXPECT_TRUE(ComponentMatches(url, path_cases[i].path, parsed.GetContent()))
        << i;

    // The remaining components are never used for path urls.
    ExpectInvalidComponent(parsed.username);
    ExpectInvalidComponent(parsed.password);
    ExpectInvalidComponent(parsed.host);
    ExpectInvalidComponent(parsed.port);
  }
}

// Various incarnations of file URLs.
static URLParseCase file_cases[] = {
#ifdef WIN32
{"file:server",              "file", NULL, NULL, "server", -1, NULL,          NULL, NULL},
{"  file: server  \t",       "file", NULL, NULL, " server",-1, NULL,          NULL, NULL},
{"FiLe:c|",                  "FiLe", NULL, NULL, NULL,     -1, "c|",          NULL, NULL},
{"FILE:/\\\\/server/file",   "FILE", NULL, NULL, "server", -1, "/file",       NULL, NULL},
{"file://server/",           "file", NULL, NULL, "server", -1, "/",           NULL, NULL},
{"file://localhost/c:/",     "file", NULL, NULL, NULL,     -1, "/c:/",        NULL, NULL},
{"file://127.0.0.1/c|\\",    "file", NULL, NULL, NULL,     -1, "/c|\\",       NULL, NULL},
{"file:/",                   "file", NULL, NULL, NULL,     -1, NULL,          NULL, NULL},
{"file:",                    "file", NULL, NULL, NULL,     -1, NULL,          NULL, NULL},
  // If there is a Windows drive letter, treat any number of slashes as the
  // path part.
{"file:c:\\fo\\b",           "file", NULL, NULL, NULL,     -1, "c:\\fo\\b",   NULL, NULL},
{"file:/c:\\foo/bar",        "file", NULL, NULL, NULL,     -1, "/c:\\foo/bar",NULL, NULL},
{"file://c:/f\\b",           "file", NULL, NULL, NULL,     -1, "/c:/f\\b",    NULL, NULL},
{"file:///C:/foo",           "file", NULL, NULL, NULL,     -1, "/C:/foo",     NULL, NULL},
{"file://///\\/\\/c:\\f\\b", "file", NULL, NULL, NULL,     -1, "/c:\\f\\b",   NULL, NULL},
  // If there is not a drive letter, we should treat is as UNC EXCEPT for
  // three slashes, which we treat as a Unix style path.
{"file:server/file",         "file", NULL, NULL, "server", -1, "/file",       NULL, NULL},
{"file:/server/file",        "file", NULL, NULL, "server", -1, "/file",       NULL, NULL},
{"file://server/file",       "file", NULL, NULL, "server", -1, "/file",       NULL, NULL},
{"file:///server/file",      "file", NULL, NULL, NULL,     -1, "/server/file",NULL, NULL},
{"file://\\server/file",     "file", NULL, NULL, NULL,     -1, "\\server/file",NULL, NULL},
{"file:////server/file",     "file", NULL, NULL, "server", -1, "/file",       NULL, NULL},
  // Queries and refs are valid for file URLs as well.
{"file:///C:/foo.html?#",   "file", NULL, NULL,  NULL,     -1, "/C:/foo.html",  "",   ""},
{"file:///C:/foo.html?query=yes#ref", "file", NULL, NULL, NULL, -1, "/C:/foo.html", "query=yes", "ref"},
#else  // WIN32
  // No slashes.
  {"file:",                    "file", NULL, NULL, NULL,      -1, NULL,             NULL, NULL},
  {"file:path",                "file", NULL, NULL, NULL,      -1, "path",           NULL, NULL},
  {"file:path/",               "file", NULL, NULL, NULL,      -1, "path/",          NULL, NULL},
  {"file:path/f.txt",          "file", NULL, NULL, NULL,      -1, "path/f.txt",     NULL, NULL},
  // One slash.
  {"file:/",                   "file", NULL, NULL, NULL,      -1, "/",              NULL, NULL},
  {"file:/path",               "file", NULL, NULL, NULL,      -1, "/path",          NULL, NULL},
  {"file:/path/",              "file", NULL, NULL, NULL,      -1, "/path/",         NULL, NULL},
  {"file:/path/f.txt",         "file", NULL, NULL, NULL,      -1, "/path/f.txt",    NULL, NULL},
  // Two slashes.
  {"file://",                  "file", NULL, NULL, NULL,      -1, NULL,             NULL, NULL},
  {"file://server",            "file", NULL, NULL, "server",  -1, NULL,             NULL, NULL},
  {"file://server/",           "file", NULL, NULL, "server",  -1, "/",              NULL, NULL},
  {"file://server/f.txt",      "file", NULL, NULL, "server",  -1, "/f.txt",         NULL, NULL},
  // Three slashes.
  {"file:///",                 "file", NULL, NULL, NULL,      -1, "/",              NULL, NULL},
  {"file:///path",             "file", NULL, NULL, NULL,      -1, "/path",          NULL, NULL},
  {"file:///path/",            "file", NULL, NULL, NULL,      -1, "/path/",         NULL, NULL},
  {"file:///path/f.txt",       "file", NULL, NULL, NULL,      -1, "/path/f.txt",    NULL, NULL},
  // More than three slashes.
  {"file:////",                "file", NULL, NULL, NULL,      -1, "/",              NULL, NULL},
  {"file:////path",            "file", NULL, NULL, NULL,      -1, "/path",          NULL, NULL},
  {"file:////path/",           "file", NULL, NULL, NULL,      -1, "/path/",         NULL, NULL},
  {"file:////path/f.txt",      "file", NULL, NULL, NULL,      -1, "/path/f.txt",    NULL, NULL},
  // Schemeless URLs
  {"path/f.txt",               NULL,   NULL, NULL, NULL,       -1, "path/f.txt",    NULL, NULL},
  {"path:80/f.txt",            "path", NULL, NULL, NULL,       -1, "80/f.txt",      NULL, NULL},
  {"path/f.txt:80",            "path/f.txt",NULL, NULL, NULL,  -1, "80",            NULL, NULL}, // Wrong.
  {"/path/f.txt",              NULL,   NULL, NULL, NULL,       -1, "/path/f.txt",   NULL, NULL},
  {"/path:80/f.txt",           NULL,   NULL, NULL, NULL,       -1, "/path:80/f.txt",NULL, NULL},
  {"/path/f.txt:80",           NULL,   NULL, NULL, NULL,       -1, "/path/f.txt:80",NULL, NULL},
  {"//server/f.txt",           NULL,   NULL, NULL, "server",   -1, "/f.txt",        NULL, NULL},
  {"//server:80/f.txt",        NULL,   NULL, NULL, "server:80",-1, "/f.txt",        NULL, NULL},
  {"//server/f.txt:80",        NULL,   NULL, NULL, "server",   -1, "/f.txt:80",     NULL, NULL},
  {"///path/f.txt",            NULL,   NULL, NULL, NULL,       -1, "/path/f.txt",   NULL, NULL},
  {"///path:80/f.txt",         NULL,   NULL, NULL, NULL,       -1, "/path:80/f.txt",NULL, NULL},
  {"///path/f.txt:80",         NULL,   NULL, NULL, NULL,       -1, "/path/f.txt:80",NULL, NULL},
  {"////path/f.txt",           NULL,   NULL, NULL, NULL,       -1, "/path/f.txt",   NULL, NULL},
  {"////path:80/f.txt",        NULL,   NULL, NULL, NULL,       -1, "/path:80/f.txt",NULL, NULL},
  {"////path/f.txt:80",        NULL,   NULL, NULL, NULL,       -1, "/path/f.txt:80",NULL, NULL},
  // Queries and refs are valid for file URLs as well.
  {"file:///foo.html?#",       "file", NULL, NULL, NULL,       -1, "/foo.html",     "",   ""},
  {"file:///foo.html?q=y#ref", "file", NULL, NULL, NULL,       -1, "/foo.html",    "q=y", "ref"},
#endif  // WIN32
};

TEST(URLParser, ParseFileURL) {
  // Declared outside for loop to try to catch cases in init() where we forget
  // to reset something that is reset by the construtor.
  Parsed parsed;
  for (size_t i = 0; i < arraysize(file_cases); i++) {
    const char* url = file_cases[i].input;
    ParseFileURL(url, static_cast<int>(strlen(url)), &parsed);
    int port = ParsePort(url, parsed.port);

    EXPECT_TRUE(ComponentMatches(url, file_cases[i].scheme, parsed.scheme))
        << " for case #" << i << " [" << url << "] "
        << parsed.scheme.begin << ", " << parsed.scheme.len;

    EXPECT_TRUE(ComponentMatches(url, file_cases[i].username, parsed.username))
        << " for case #" << i << " [" << url << "] "
        << parsed.username.begin << ", " << parsed.username.len;

    EXPECT_TRUE(ComponentMatches(url, file_cases[i].password, parsed.password))
        << " for case #" << i << " [" << url << "] "
        << parsed.password.begin << ", " << parsed.password.len;

    EXPECT_TRUE(ComponentMatches(url, file_cases[i].host, parsed.host))
        << " for case #" << i << " [" << url << "] "
        << parsed.host.begin << ", " << parsed.host.len;

    EXPECT_EQ(file_cases[i].port, port)
        << " for case #" << i << " [ " << url << "] " << port;

    EXPECT_TRUE(ComponentMatches(url, file_cases[i].path, parsed.path))
        << " for case #" << i << " [" << url << "] "
        << parsed.path.begin << ", " << parsed.path.len;

    EXPECT_TRUE(ComponentMatches(url, file_cases[i].query, parsed.query))
        << " for case #" << i << " [" << url << "] "
        << parsed.query.begin << ", " << parsed.query.len;

    EXPECT_TRUE(ComponentMatches(url, file_cases[i].ref, parsed.ref))
        << " for case #" << i << " [ "<< url << "] "
        << parsed.query.begin << ", " << parsed.scheme.len;
  }
}


TEST(URLParser, ExtractFileName) {
  struct FileCase {
    const char* input;
    const char* expected;
  } file_cases[] = {
    {"http://www.google.com", NULL},
    {"http://www.google.com/", ""},
    {"http://www.google.com/search", "search"},
    {"http://www.google.com/search/", ""},
    {"http://www.google.com/foo/bar.html?baz=22", "bar.html"},
    {"http://www.google.com/foo/bar.html#ref", "bar.html"},
    {"http://www.google.com/search/;param", ""},
    {"http://www.google.com/foo/bar.html;param#ref", "bar.html"},
    {"http://www.google.com/foo/bar.html;foo;param#ref", "bar.html"},
    {"http://www.google.com/foo/bar.html?query#ref", "bar.html"},
    {"http://www.google.com/foo;/bar.html", "bar.html"},
    {"http://www.google.com/foo;/", ""},
    {"http://www.google.com/foo;", "foo"},
    {"http://www.google.com/;", ""},
    {"http://www.google.com/foo;bar;html", "foo"},
  };

  for (size_t i = 0; i < arraysize(file_cases); i++) {
    const char* url = file_cases[i].input;
    int len = static_cast<int>(strlen(url));

    Parsed parsed;
    ParseStandardURL(url, len, &parsed);

    Component file_name;
    ExtractFileName(url, parsed.path, &file_name);

    EXPECT_TRUE(ComponentMatches(url, file_cases[i].expected, file_name));
  }
}

// Returns true if the parameter with index |parameter| in the given URL's
// query string. The expected key can be NULL to indicate no such key index
// should exist. The parameter number is 1-based.
static bool NthParameterIs(const char* url,
                           int parameter,
                           const char* expected_key,
                           const char* expected_value) {
  Parsed parsed;
  ParseStandardURL(url, static_cast<int>(strlen(url)), &parsed);

  Component query = parsed.query;

  for (int i = 1; i <= parameter; i++) {
    Component key, value;
    if (!ExtractQueryKeyValue(url, &query, &key, &value)) {
      if (parameter >= i && !expected_key)
        return true;  // Expected nonexistant key, got one.
      return false;  // Not enough keys.
    }

    if (i == parameter) {
      if (!expected_key)
        return false;

      if (strncmp(&url[key.begin], expected_key, key.len) != 0)
        return false;
      if (strncmp(&url[value.begin], expected_value, value.len) != 0)
        return false;
      return true;
    }
  }
  return expected_key == NULL;  // We didn't find that many parameters.
}

TEST(URLParser, ExtractQueryKeyValue) {
  EXPECT_TRUE(NthParameterIs("http://www.google.com", 1, NULL, NULL));

  // Basic case.
  char a[] = "http://www.google.com?arg1=1&arg2=2&bar";
  EXPECT_TRUE(NthParameterIs(a, 1, "arg1", "1"));
  EXPECT_TRUE(NthParameterIs(a, 2, "arg2", "2"));
  EXPECT_TRUE(NthParameterIs(a, 3, "bar", ""));
  EXPECT_TRUE(NthParameterIs(a, 4, NULL, NULL));

  // Empty param at the end.
  char b[] = "http://www.google.com?foo=bar&";
  EXPECT_TRUE(NthParameterIs(b, 1, "foo", "bar"));
  EXPECT_TRUE(NthParameterIs(b, 2, NULL, NULL));

  // Empty param at the beginning.
  char c[] = "http://www.google.com?&foo=bar";
  EXPECT_TRUE(NthParameterIs(c, 1, "", ""));
  EXPECT_TRUE(NthParameterIs(c, 2, "foo", "bar"));
  EXPECT_TRUE(NthParameterIs(c, 3, NULL, NULL));

  // Empty key with value.
  char d[] = "http://www.google.com?=foo";
  EXPECT_TRUE(NthParameterIs(d, 1, "", "foo"));
  EXPECT_TRUE(NthParameterIs(d, 2, NULL, NULL));

  // Empty value with key.
  char e[] = "http://www.google.com?foo=";
  EXPECT_TRUE(NthParameterIs(e, 1, "foo", ""));
  EXPECT_TRUE(NthParameterIs(e, 2, NULL, NULL));

  // Empty key and values.
  char f[] = "http://www.google.com?&&==&=";
  EXPECT_TRUE(NthParameterIs(f, 1, "", ""));
  EXPECT_TRUE(NthParameterIs(f, 2, "", ""));
  EXPECT_TRUE(NthParameterIs(f, 3, "", "="));
  EXPECT_TRUE(NthParameterIs(f, 4, "", ""));
  EXPECT_TRUE(NthParameterIs(f, 5, NULL, NULL));
}

// MailtoURL --------------------------------------------------------------------

static MailtoURLParseCase mailto_cases[] = {
//|input                       |scheme   |path               |query
{"mailto:foo@gmail.com",        "mailto", "foo@gmail.com",    NULL},
{"  mailto: to  \t",            "mailto", " to",              NULL},
{"mailto:addr1%2C%20addr2 ",    "mailto", "addr1%2C%20addr2", NULL},
{"Mailto:addr1, addr2 ",        "Mailto", "addr1, addr2",     NULL},
{"mailto:addr1:addr2 ",         "mailto", "addr1:addr2",      NULL},
{"mailto:?to=addr1,addr2",      "mailto", NULL,               "to=addr1,addr2"},
{"mailto:?to=addr1%2C%20addr2", "mailto", NULL,               "to=addr1%2C%20addr2"},
{"mailto:addr1?to=addr2",       "mailto", "addr1",            "to=addr2"},
{"mailto:?body=#foobar#",       "mailto", NULL,               "body=#foobar#",},
{"mailto:#?body=#foobar#",      "mailto", "#",                "body=#foobar#"},
};

TEST(URLParser, MailtoUrl) {
  // Declared outside for loop to try to catch cases in init() where we forget
  // to reset something that is reset by the construtor.
  Parsed parsed;
  for (size_t i = 0; i < arraysize(mailto_cases); ++i) {
    const char* url = mailto_cases[i].input;
    ParseMailtoURL(url, static_cast<int>(strlen(url)), &parsed);
    int port = ParsePort(url, parsed.port);

    EXPECT_TRUE(ComponentMatches(url, mailto_cases[i].scheme, parsed.scheme));
    EXPECT_TRUE(ComponentMatches(url, mailto_cases[i].path, parsed.path));
    EXPECT_TRUE(ComponentMatches(url, mailto_cases[i].query, parsed.query));
    EXPECT_EQ(PORT_UNSPECIFIED, port);

    // The remaining components are never used for mailto urls.
    ExpectInvalidComponent(parsed.username);
    ExpectInvalidComponent(parsed.password);
    ExpectInvalidComponent(parsed.port);
    ExpectInvalidComponent(parsed.ref);
  }
}

// Various incarnations of filesystem URLs.
static FileSystemURLParseCase filesystem_cases[] = {
  // Regular URL with all the parts
{"filesystem:http://user:pass@foo:21/temporary/bar;par?b#c", "http",  "user", "pass", "foo", 21, "/temporary",  "/bar;par",  "b",  "c"},
{"filesystem:https://foo/persistent/bar;par/",               "https", NULL,   NULL,   "foo", -1, "/persistent", "/bar;par/", NULL, NULL},
{"filesystem:file:///persistent/bar;par/",                   "file", NULL,    NULL,   NULL,  -1, "/persistent", "/bar;par/", NULL, NULL},
{"filesystem:file:///persistent/bar;par/?query#ref",                   "file", NULL,    NULL,   NULL,  -1, "/persistent", "/bar;par/", "query", "ref"},
{"filesystem:file:///persistent",                            "file", NULL,    NULL,   NULL,  -1, "/persistent", "",        NULL, NULL},
};

TEST(URLParser, FileSystemURL) {
  // Declared outside for loop to try to catch cases in init() where we forget
  // to reset something that is reset by the construtor.
  Parsed parsed;
  for (size_t i = 0; i < arraysize(filesystem_cases); i++) {
    const FileSystemURLParseCase* parsecase = &filesystem_cases[i];
    const char* url = parsecase->input;
    ParseFileSystemURL(url, static_cast<int>(strlen(url)), &parsed);

    EXPECT_TRUE(ComponentMatches(url, "filesystem", parsed.scheme));
    EXPECT_EQ(!parsecase->inner_scheme, !parsed.inner_parsed());
    // Only check the inner_parsed if there is one.
    if (parsed.inner_parsed()) {
      EXPECT_TRUE(ComponentMatches(url, parsecase->inner_scheme,
          parsed.inner_parsed()->scheme));
      EXPECT_TRUE(ComponentMatches(url, parsecase->inner_username,
          parsed.inner_parsed()->username));
      EXPECT_TRUE(ComponentMatches(url, parsecase->inner_password,
          parsed.inner_parsed()->password));
      EXPECT_TRUE(ComponentMatches(url, parsecase->inner_host,
          parsed.inner_parsed()->host));
      int port = ParsePort(url, parsed.inner_parsed()->port);
      EXPECT_EQ(parsecase->inner_port, port);

      // The remaining components are never used for filesystem urls.
      ExpectInvalidComponent(parsed.inner_parsed()->query);
      ExpectInvalidComponent(parsed.inner_parsed()->ref);
    }

    EXPECT_TRUE(ComponentMatches(url, parsecase->path, parsed.path));
    EXPECT_TRUE(ComponentMatches(url, parsecase->query, parsed.query));
    EXPECT_TRUE(ComponentMatches(url, parsecase->ref, parsed.ref));

    // The remaining components are never used for filesystem urls.
    ExpectInvalidComponent(parsed.username);
    ExpectInvalidComponent(parsed.password);
    ExpectInvalidComponent(parsed.host);
    ExpectInvalidComponent(parsed.port);
  }
}

}  // namespace
}  // namespace url

// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "url/url_file.h"
#include "url/url_parse.h"
#include "url/url_parse_internal.h"

// Interesting IE file:isms...
//
//  INPUT                      OUTPUT
//  =========================  ==============================
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
//      When on a file: URL source page, this link will work. When over HTTP,
//      the file: URL will appear in the status bar but the link will not work
//      (security restriction for all file URLs).
//
//  file:foo/                  file:foo/     (invalid?!?!?)
//  file:/foo/                 file:///foo/  (invalid?!?!?)
//  file://foo/                file://foo/   (UNC to server "foo")
//  file:///foo/               file:///foo/  (invalid, seems to be a file)
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

// A subcomponent of DoInitFileURL, the input of this function should be a UNC
// path name, with the index of the first character after the slashes following
// the scheme given in |after_slashes|. This will initialize the host, path,
// query, and ref, and leave the other output components untouched
// (DoInitFileURL handles these for us).
template<typename CHAR>
void DoParseUNC(const CHAR* spec,
                int after_slashes,
                int spec_len,
               Parsed* parsed) {
  int next_slash = FindNextSlash(spec, after_slashes, spec_len);
  if (next_slash == spec_len) {
    // No additional slash found, as in "file://foo", treat the text as the
    // host with no path (this will end up being UNC to server "foo").
    int host_len = spec_len - after_slashes;
    if (host_len)
      parsed->host = Component(after_slashes, host_len);
    else
      parsed->host.reset();
    parsed->path.reset();
    return;
  }

#ifdef WIN32
  // See if we have something that looks like a path following the first
  // component. As in "file://localhost/c:/", we get "c:/" out. We want to
  // treat this as a having no host but the path given. Works on Windows only.
  if (DoesBeginWindowsDriveSpec(spec, next_slash + 1, spec_len)) {
    parsed->host.reset();
    ParsePathInternal(spec, MakeRange(next_slash, spec_len),
                      &parsed->path, &parsed->query, &parsed->ref);
    return;
  }
#endif

  // Otherwise, everything up until that first slash we found is the host name,
  // which will end up being the UNC host. For example "file://foo/bar.txt"
  // will get a server name of "foo" and a path of "/bar". Later, on Windows,
  // this should be treated as the filename "\\foo\bar.txt" in proper UNC
  // notation.
  int host_len = next_slash - after_slashes;
  if (host_len)
    parsed->host = MakeRange(after_slashes, next_slash);
  else
    parsed->host.reset();
  if (next_slash < spec_len) {
    ParsePathInternal(spec, MakeRange(next_slash, spec_len),
                      &parsed->path, &parsed->query, &parsed->ref);
  } else {
    parsed->path.reset();
  }
}

// A subcomponent of DoParseFileURL, the input should be a local file, with the
// beginning of the path indicated by the index in |path_begin|. This will
// initialize the host, path, query, and ref, and leave the other output
// components untouched (DoInitFileURL handles these for us).
template<typename CHAR>
void DoParseLocalFile(const CHAR* spec,
                      int path_begin,
                      int spec_len,
                      Parsed* parsed) {
  parsed->host.reset();
  ParsePathInternal(spec, MakeRange(path_begin, spec_len),
                    &parsed->path, &parsed->query, &parsed->ref);
}

// Backend for the external functions that operates on either char type.
// Handles cases where there is a scheme, but also when handed the first
// character following the "file:" at the beginning of the spec. If so,
// this is usually a slash, but needn't be; we allow paths like "file:c:\foo".
template<typename CHAR>
void DoParseFileURL(const CHAR* spec, int spec_len, Parsed* parsed) {
  DCHECK(spec_len >= 0);

  // Get the parts we never use for file URLs out of the way.
  parsed->username.reset();
  parsed->password.reset();
  parsed->port.reset();

  // Many of the code paths don't set these, so it's convenient to just clear
  // them. We'll write them in those cases we need them.
  parsed->query.reset();
  parsed->ref.reset();

  // Strip leading & trailing spaces and control characters.
  int begin = 0;
  TrimURL(spec, &begin, &spec_len);

  // Find the scheme, if any.
  int num_slashes = CountConsecutiveSlashes(spec, begin, spec_len);
  int after_scheme;
  int after_slashes;
#ifdef WIN32
  // See how many slashes there are. We want to handle cases like UNC but also
  // "/c:/foo". This is when there is no scheme, so we can allow pages to do
  // links like "c:/foo/bar" or "//foo/bar". This is also called by the
  // relative URL resolver when it determines there is an absolute URL, which
  // may give us input like "/c:/foo".
  after_slashes = begin + num_slashes;
  if (DoesBeginWindowsDriveSpec(spec, after_slashes, spec_len)) {
    // Windows path, don't try to extract the scheme (for example, "c:\foo").
    parsed->scheme.reset();
    after_scheme = after_slashes;
  } else if (DoesBeginUNCPath(spec, begin, spec_len, false)) {
    // Windows UNC path: don't try to extract the scheme, but keep the slashes.
    parsed->scheme.reset();
    after_scheme = begin;
  } else
#endif
  {
    // ExtractScheme doesn't understand the possibility of filenames with
    // colons in them, in which case it returns the entire spec up to the
    // colon as the scheme. So handle /foo.c:5 as a file but foo.c:5 as
    // the foo.c: scheme.
    if (!num_slashes &&
        ExtractScheme(&spec[begin], spec_len - begin, &parsed->scheme)) {
      // Offset the results since we gave ExtractScheme a substring.
      parsed->scheme.begin += begin;
      after_scheme = parsed->scheme.end() + 1;
    } else {
      // No scheme found, remember that.
      parsed->scheme.reset();
      after_scheme = begin;
    }
  }

  // Handle empty specs ones that contain only whitespace or control chars,
  // or that are just the scheme (for example "file:").
  if (after_scheme == spec_len) {
    parsed->host.reset();
    parsed->path.reset();
    return;
  }

  num_slashes = CountConsecutiveSlashes(spec, after_scheme, spec_len);
  after_slashes = after_scheme + num_slashes;
#ifdef WIN32
  // Check whether the input is a drive again. We checked above for windows
  // drive specs, but that's only at the very beginning to see if we have a
  // scheme at all. This test will be duplicated in that case, but will
  // additionally handle all cases with a real scheme such as "file:///C:/".
  if (!DoesBeginWindowsDriveSpec(spec, after_slashes, spec_len) &&
      num_slashes != 3) {
    // Anything not beginning with a drive spec ("c:\") on Windows is treated
    // as UNC, with the exception of three slashes which always means a file.
    // Even IE7 treats file:///foo/bar as "/foo/bar", which then fails.
    DoParseUNC(spec, after_slashes, spec_len, parsed);
    return;
  }
#else
  // file: URL with exactly 2 slashes is considered to have a host component.
  if (num_slashes == 2) {
    DoParseUNC(spec, after_slashes, spec_len, parsed);
    return;
  }
#endif  // WIN32

  // Easy and common case, the full path immediately follows the scheme
  // (modulo slashes), as in "file://c:/foo". Just treat everything from
  // there to the end as the path. Empty hosts have 0 length instead of -1.
  // We include the last slash as part of the path if there is one.
  DoParseLocalFile(spec,
      num_slashes > 0 ? after_scheme + num_slashes - 1 : after_scheme,
      spec_len, parsed);
}

}  // namespace

void ParseFileURL(const char* url, int url_len, Parsed* parsed) {
  DoParseFileURL(url, url_len, parsed);
}

void ParseFileURL(const base::char16* url, int url_len, Parsed* parsed) {
  DoParseFileURL(url, url_len, parsed);
}

}  // namespace url

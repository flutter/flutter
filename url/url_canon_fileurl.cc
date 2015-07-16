// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Functions for canonicalizing "file:" URLs.

#include "url/url_canon.h"
#include "url/url_canon_internal.h"
#include "url/url_file.h"
#include "url/url_parse_internal.h"

namespace url {

namespace {

#ifdef WIN32

// Given a pointer into the spec, this copies and canonicalizes the drive
// letter and colon to the output, if one is found. If there is not a drive
// spec, it won't do anything. The index of the next character in the input
// spec is returned (after the colon when a drive spec is found, the begin
// offset if one is not).
template<typename CHAR>
int FileDoDriveSpec(const CHAR* spec, int begin, int end,
                    CanonOutput* output) {
  // The path could be one of several things: /foo/bar, c:/foo/bar, /c:/foo,
  // (with backslashes instead of slashes as well).
  int num_slashes = CountConsecutiveSlashes(spec, begin, end);
  int after_slashes = begin + num_slashes;

  if (!DoesBeginWindowsDriveSpec(spec, after_slashes, end))
    return begin;  // Haven't consumed any characters

  // A drive spec is the start of a path, so we need to add a slash for the
  // authority terminator (typically the third slash).
  output->push_back('/');

  // DoesBeginWindowsDriveSpec will ensure that the drive letter is valid
  // and that it is followed by a colon/pipe.

  // Normalize Windows drive letters to uppercase
  if (spec[after_slashes] >= 'a' && spec[after_slashes] <= 'z')
    output->push_back(static_cast<char>(spec[after_slashes] - 'a' + 'A'));
  else
    output->push_back(static_cast<char>(spec[after_slashes]));

  // Normalize the character following it to a colon rather than pipe.
  output->push_back(':');
  return after_slashes + 2;
}

#endif  // WIN32

template<typename CHAR, typename UCHAR>
bool DoFileCanonicalizePath(const CHAR* spec,
                            const Component& path,
                            CanonOutput* output,
                            Component* out_path) {
  // Copies and normalizes the "c:" at the beginning, if present.
  out_path->begin = output->length();
  int after_drive;
#ifdef WIN32
  after_drive = FileDoDriveSpec(spec, path.begin, path.end(), output);
#else
  after_drive = path.begin;
#endif

  // Copies the rest of the path, starting from the slash following the
  // drive colon (if any, Windows only), or the first slash of the path.
  bool success = true;
  if (after_drive < path.end()) {
    // Use the regular path canonicalizer to canonicalize the rest of the
    // path. Give it a fake output component to write into. DoCanonicalizeFile
    // will compute the full path component.
    Component sub_path = MakeRange(after_drive, path.end());
    Component fake_output_path;
    success = CanonicalizePath(spec, sub_path, output, &fake_output_path);
  } else {
    // No input path, canonicalize to a slash.
    output->push_back('/');
  }

  out_path->len = output->length() - out_path->begin;
  return success;
}

template<typename CHAR, typename UCHAR>
bool DoCanonicalizeFileURL(const URLComponentSource<CHAR>& source,
                           const Parsed& parsed,
                           CharsetConverter* query_converter,
                           CanonOutput* output,
                           Parsed* new_parsed) {
  // Things we don't set in file: URLs.
  new_parsed->username = Component();
  new_parsed->password = Component();
  new_parsed->port = Component();

  // Scheme (known, so we don't bother running it through the more
  // complicated scheme canonicalizer).
  new_parsed->scheme.begin = output->length();
  output->Append("file://", 7);
  new_parsed->scheme.len = 4;

  // Append the host. For many file URLs, this will be empty. For UNC, this
  // will be present.
  // TODO(brettw) This doesn't do any checking for host name validity. We
  // should probably handle validity checking of UNC hosts differently than
  // for regular IP hosts.
  bool success = CanonicalizeHost(source.host, parsed.host,
                                  output, &new_parsed->host);
  success &= DoFileCanonicalizePath<CHAR, UCHAR>(source.path, parsed.path,
                                    output, &new_parsed->path);
  CanonicalizeQuery(source.query, parsed.query, query_converter,
                    output, &new_parsed->query);

  // Ignore failure for refs since the URL can probably still be loaded.
  CanonicalizeRef(source.ref, parsed.ref, output, &new_parsed->ref);

  return success;
}

} // namespace

bool CanonicalizeFileURL(const char* spec,
                         int spec_len,
                         const Parsed& parsed,
                         CharsetConverter* query_converter,
                         CanonOutput* output,
                         Parsed* new_parsed) {
  return DoCanonicalizeFileURL<char, unsigned char>(
      URLComponentSource<char>(spec), parsed, query_converter,
      output, new_parsed);
}

bool CanonicalizeFileURL(const base::char16* spec,
                         int spec_len,
                         const Parsed& parsed,
                         CharsetConverter* query_converter,
                         CanonOutput* output,
                         Parsed* new_parsed) {
  return DoCanonicalizeFileURL<base::char16, base::char16>(
      URLComponentSource<base::char16>(spec), parsed, query_converter,
      output, new_parsed);
}

bool FileCanonicalizePath(const char* spec,
                          const Component& path,
                          CanonOutput* output,
                          Component* out_path) {
  return DoFileCanonicalizePath<char, unsigned char>(spec, path,
                                                     output, out_path);
}

bool FileCanonicalizePath(const base::char16* spec,
                          const Component& path,
                          CanonOutput* output,
                          Component* out_path) {
  return DoFileCanonicalizePath<base::char16, base::char16>(spec, path,
                                                            output, out_path);
}

bool ReplaceFileURL(const char* base,
                    const Parsed& base_parsed,
                    const Replacements<char>& replacements,
                    CharsetConverter* query_converter,
                    CanonOutput* output,
                    Parsed* new_parsed) {
  URLComponentSource<char> source(base);
  Parsed parsed(base_parsed);
  SetupOverrideComponents(base, replacements, &source, &parsed);
  return DoCanonicalizeFileURL<char, unsigned char>(
      source, parsed, query_converter, output, new_parsed);
}

bool ReplaceFileURL(const char* base,
                    const Parsed& base_parsed,
                    const Replacements<base::char16>& replacements,
                    CharsetConverter* query_converter,
                    CanonOutput* output,
                    Parsed* new_parsed) {
  RawCanonOutput<1024> utf8;
  URLComponentSource<char> source(base);
  Parsed parsed(base_parsed);
  SetupUTF16OverrideComponents(base, replacements, &utf8, &source, &parsed);
  return DoCanonicalizeFileURL<char, unsigned char>(
      source, parsed, query_converter, output, new_parsed);
}

}  // namespace url

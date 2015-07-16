// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Functions for canonicalizing "filesystem:file:" URLs.

#include "url/url_canon.h"
#include "url/url_canon_internal.h"
#include "url/url_file.h"
#include "url/url_parse_internal.h"
#include "url/url_util.h"
#include "url/url_util_internal.h"

namespace url {

namespace {

// We use the URLComponentSource for the outer URL, as it can have replacements,
// whereas the inner_url can't, so it uses spec.
template<typename CHAR, typename UCHAR>
bool DoCanonicalizeFileSystemURL(const CHAR* spec,
                                 const URLComponentSource<CHAR>& source,
                                 const Parsed& parsed,
                                 CharsetConverter* charset_converter,
                                 CanonOutput* output,
                                 Parsed* new_parsed) {
  // filesystem only uses {scheme, path, query, ref} -- clear the rest.
  new_parsed->username.reset();
  new_parsed->password.reset();
  new_parsed->host.reset();
  new_parsed->port.reset();

  const Parsed* inner_parsed = parsed.inner_parsed();
  Parsed new_inner_parsed;

  // Scheme (known, so we don't bother running it through the more
  // complicated scheme canonicalizer).
  new_parsed->scheme.begin = output->length();
  output->Append("filesystem:", 11);
  new_parsed->scheme.len = 10;

  if (!parsed.inner_parsed() || !parsed.inner_parsed()->scheme.is_valid())
    return false;

  bool success = true;
  if (CompareSchemeComponent(spec, inner_parsed->scheme, url::kFileScheme)) {
    new_inner_parsed.scheme.begin = output->length();
    output->Append("file://", 7);
    new_inner_parsed.scheme.len = 4;
    success &= CanonicalizePath(spec, inner_parsed->path, output,
                                &new_inner_parsed.path);
  } else if (IsStandard(spec, inner_parsed->scheme)) {
    success = CanonicalizeStandardURL(spec, parsed.inner_parsed()->Length(),
                                      *parsed.inner_parsed(), charset_converter,
                                      output, &new_inner_parsed);
  } else {
    // TODO(ericu): The URL is wrong, but should we try to output more of what
    // we were given?  Echoing back filesystem:mailto etc. doesn't seem all that
    // useful.
    return false;
  }
  // The filesystem type must be more than just a leading slash for validity.
  success &= parsed.inner_parsed()->path.len > 1;

  success &= CanonicalizePath(source.path, parsed.path, output,
                              &new_parsed->path);

  // Ignore failures for query/ref since the URL can probably still be loaded.
  CanonicalizeQuery(source.query, parsed.query, charset_converter,
                    output, &new_parsed->query);
  CanonicalizeRef(source.ref, parsed.ref, output, &new_parsed->ref);
  if (success)
    new_parsed->set_inner_parsed(new_inner_parsed);

  return success;
}

}  // namespace

bool CanonicalizeFileSystemURL(const char* spec,
                               int spec_len,
                               const Parsed& parsed,
                               CharsetConverter* charset_converter,
                               CanonOutput* output,
                               Parsed* new_parsed) {
  return DoCanonicalizeFileSystemURL<char, unsigned char>(
      spec, URLComponentSource<char>(spec), parsed, charset_converter, output,
      new_parsed);
}

bool CanonicalizeFileSystemURL(const base::char16* spec,
                               int spec_len,
                               const Parsed& parsed,
                               CharsetConverter* charset_converter,
                               CanonOutput* output,
                               Parsed* new_parsed) {
  return DoCanonicalizeFileSystemURL<base::char16, base::char16>(
      spec, URLComponentSource<base::char16>(spec), parsed, charset_converter,
      output, new_parsed);
}

bool ReplaceFileSystemURL(const char* base,
                          const Parsed& base_parsed,
                          const Replacements<char>& replacements,
                          CharsetConverter* charset_converter,
                          CanonOutput* output,
                          Parsed* new_parsed) {
  URLComponentSource<char> source(base);
  Parsed parsed(base_parsed);
  SetupOverrideComponents(base, replacements, &source, &parsed);
  return DoCanonicalizeFileSystemURL<char, unsigned char>(
      base, source, parsed, charset_converter, output, new_parsed);
}

bool ReplaceFileSystemURL(const char* base,
                          const Parsed& base_parsed,
                          const Replacements<base::char16>& replacements,
                          CharsetConverter* charset_converter,
                          CanonOutput* output,
                          Parsed* new_parsed) {
  RawCanonOutput<1024> utf8;
  URLComponentSource<char> source(base);
  Parsed parsed(base_parsed);
  SetupUTF16OverrideComponents(base, replacements, &utf8, &source, &parsed);
  return DoCanonicalizeFileSystemURL<char, unsigned char>(
      base, source, parsed, charset_converter, output, new_parsed);
}

}  // namespace url

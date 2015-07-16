// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Functions for canonicalizing "path" URLs. Not to be confused with the path
// of a URL, these are URLs that have no authority section, only a path. For
// example, "javascript:" and "data:".

#include "url/url_canon.h"
#include "url/url_canon_internal.h"

namespace url {

namespace {

// Canonicalize the given |component| from |source| into |output| and
// |new_component|. If |separator| is non-zero, it is pre-pended to |ouput|
// prior to the canonicalized component; i.e. for the '?' or '#' characters.
template<typename CHAR, typename UCHAR>
bool DoCanonicalizePathComponent(const CHAR* source,
                                 const Component& component,
                                 char separator,
                                 CanonOutput* output,
                                 Component* new_component) {
  bool success = true;
  if (component.is_valid()) {
    if (separator)
      output->push_back(separator);
    // Copy the path using path URL's more lax escaping rules (think for
    // javascript:). We convert to UTF-8 and escape non-ASCII, but leave all
    // ASCII characters alone. This helps readability of JavaStript.
    new_component->begin = output->length();
    int end = component.end();
    for (int i = component.begin; i < end; i++) {
      UCHAR uch = static_cast<UCHAR>(source[i]);
      if (uch < 0x20 || uch >= 0x80)
        success &= AppendUTF8EscapedChar(source, &i, end, output);
      else
        output->push_back(static_cast<char>(uch));
    }
    new_component->len = output->length() - new_component->begin;
  } else {
    // Empty part.
    new_component->reset();
  }
  return success;
}

template <typename CHAR, typename UCHAR>
bool DoCanonicalizePathURL(const URLComponentSource<CHAR>& source,
                           const Parsed& parsed,
                           CanonOutput* output,
                           Parsed* new_parsed) {
  // Scheme: this will append the colon.
  bool success = CanonicalizeScheme(source.scheme, parsed.scheme,
                                    output, &new_parsed->scheme);

  // We assume there's no authority for path URLs. Note that hosts should never
  // have -1 length.
  new_parsed->username.reset();
  new_parsed->password.reset();
  new_parsed->host.reset();
  new_parsed->port.reset();
  // We allow path URLs to have the path, query and fragment components, but we
  // will canonicalize each of the via the weaker path URL rules.
  success &= DoCanonicalizePathComponent<CHAR, UCHAR>(
      source.path, parsed.path, '\0', output, &new_parsed->path);
  success &= DoCanonicalizePathComponent<CHAR, UCHAR>(
      source.query, parsed.query, '?', output, &new_parsed->query);
  success &= DoCanonicalizePathComponent<CHAR, UCHAR>(
      source.ref, parsed.ref, '#', output, &new_parsed->ref);

  return success;
}

}  // namespace

bool CanonicalizePathURL(const char* spec,
                         int spec_len,
                         const Parsed& parsed,
                         CanonOutput* output,
                         Parsed* new_parsed) {
  return DoCanonicalizePathURL<char, unsigned char>(
      URLComponentSource<char>(spec), parsed, output, new_parsed);
}

bool CanonicalizePathURL(const base::char16* spec,
                         int spec_len,
                         const Parsed& parsed,
                         CanonOutput* output,
                         Parsed* new_parsed) {
  return DoCanonicalizePathURL<base::char16, base::char16>(
      URLComponentSource<base::char16>(spec), parsed, output, new_parsed);
}

bool ReplacePathURL(const char* base,
                    const Parsed& base_parsed,
                    const Replacements<char>& replacements,
                    CanonOutput* output,
                    Parsed* new_parsed) {
  URLComponentSource<char> source(base);
  Parsed parsed(base_parsed);
  SetupOverrideComponents(base, replacements, &source, &parsed);
  return DoCanonicalizePathURL<char, unsigned char>(
      source, parsed, output, new_parsed);
}

bool ReplacePathURL(const char* base,
                    const Parsed& base_parsed,
                    const Replacements<base::char16>& replacements,
                    CanonOutput* output,
                    Parsed* new_parsed) {
  RawCanonOutput<1024> utf8;
  URLComponentSource<char> source(base);
  Parsed parsed(base_parsed);
  SetupUTF16OverrideComponents(base, replacements, &utf8, &source, &parsed);
  return DoCanonicalizePathURL<char, unsigned char>(
      source, parsed, output, new_parsed);
}

}  // namespace url

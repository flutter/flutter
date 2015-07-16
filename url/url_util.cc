// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "url/url_util.h"

#include <string.h>
#include <vector>

#include "base/debug/leak_annotations.h"
#include "base/logging.h"
#include "url/url_canon_internal.h"
#include "url/url_file.h"
#include "url/url_util_internal.h"

namespace url {

namespace {

// ASCII-specific tolower.  The standard library's tolower is locale sensitive,
// so we don't want to use it here.
template<class Char>
inline Char ToLowerASCII(Char c) {
  return (c >= 'A' && c <= 'Z') ? (c + ('a' - 'A')) : c;
}

// Backend for LowerCaseEqualsASCII.
template<typename Iter>
inline bool DoLowerCaseEqualsASCII(Iter a_begin, Iter a_end, const char* b) {
  for (Iter it = a_begin; it != a_end; ++it, ++b) {
    if (!*b || ToLowerASCII(*it) != *b)
      return false;
  }
  return *b == 0;
}

const int kNumStandardURLSchemes = 8;
const char* kStandardURLSchemes[kNumStandardURLSchemes] = {
  kHttpScheme,
  kHttpsScheme,
  kFileScheme,  // Yes, file urls can have a hostname!
  kFtpScheme,
  kGopherScheme,
  kWsScheme,    // WebSocket.
  kWssScheme,   // WebSocket secure.
  kFileSystemScheme,
};

// List of the currently installed standard schemes. This list is lazily
// initialized by InitStandardSchemes and is leaked on shutdown to prevent
// any destructors from being called that will slow us down or cause problems.
std::vector<const char*>* standard_schemes = NULL;

// See the LockStandardSchemes declaration in the header.
bool standard_schemes_locked = false;

// Ensures that the standard_schemes list is initialized, does nothing if it
// already has values.
void InitStandardSchemes() {
  if (standard_schemes)
    return;
  standard_schemes = new std::vector<const char*>;
  for (int i = 0; i < kNumStandardURLSchemes; i++)
    standard_schemes->push_back(kStandardURLSchemes[i]);
}

// Given a string and a range inside the string, compares it to the given
// lower-case |compare_to| buffer.
template<typename CHAR>
inline bool DoCompareSchemeComponent(const CHAR* spec,
                                     const Component& component,
                                     const char* compare_to) {
  if (!component.is_nonempty())
    return compare_to[0] == 0;  // When component is empty, match empty scheme.
  return LowerCaseEqualsASCII(&spec[component.begin],
                              &spec[component.end()],
                              compare_to);
}

// Returns true if the given scheme identified by |scheme| within |spec| is one
// of the registered "standard" schemes.
template<typename CHAR>
bool DoIsStandard(const CHAR* spec, const Component& scheme) {
  if (!scheme.is_nonempty())
    return false;  // Empty or invalid schemes are non-standard.

  InitStandardSchemes();
  for (size_t i = 0; i < standard_schemes->size(); i++) {
    if (LowerCaseEqualsASCII(&spec[scheme.begin], &spec[scheme.end()],
                             standard_schemes->at(i)))
      return true;
  }
  return false;
}

template<typename CHAR>
bool DoFindAndCompareScheme(const CHAR* str,
                            int str_len,
                            const char* compare,
                            Component* found_scheme) {
  // Before extracting scheme, canonicalize the URL to remove any whitespace.
  // This matches the canonicalization done in DoCanonicalize function.
  RawCanonOutputT<CHAR> whitespace_buffer;
  int spec_len;
  const CHAR* spec = RemoveURLWhitespace(str, str_len,
                                         &whitespace_buffer, &spec_len);

  Component our_scheme;
  if (!ExtractScheme(spec, spec_len, &our_scheme)) {
    // No scheme.
    if (found_scheme)
      *found_scheme = Component();
    return false;
  }
  if (found_scheme)
    *found_scheme = our_scheme;
  return DoCompareSchemeComponent(spec, our_scheme, compare);
}

template<typename CHAR>
bool DoCanonicalize(const CHAR* in_spec,
                    int in_spec_len,
                    bool trim_path_end,
                    CharsetConverter* charset_converter,
                    CanonOutput* output,
                    Parsed* output_parsed) {
  // Remove any whitespace from the middle of the relative URL, possibly
  // copying to the new buffer.
  RawCanonOutputT<CHAR> whitespace_buffer;
  int spec_len;
  const CHAR* spec = RemoveURLWhitespace(in_spec, in_spec_len,
                                         &whitespace_buffer, &spec_len);

  Parsed parsed_input;
#ifdef WIN32
  // For Windows, we allow things that look like absolute Windows paths to be
  // fixed up magically to file URLs. This is done for IE compatability. For
  // example, this will change "c:/foo" into a file URL rather than treating
  // it as a URL with the protocol "c". It also works for UNC ("\\foo\bar.txt").
  // There is similar logic in url_canon_relative.cc for
  //
  // For Max & Unix, we don't do this (the equivalent would be "/foo/bar" which
  // has no meaning as an absolute path name. This is because browsers on Mac
  // & Unix don't generally do this, so there is no compatibility reason for
  // doing so.
  if (DoesBeginUNCPath(spec, 0, spec_len, false) ||
      DoesBeginWindowsDriveSpec(spec, 0, spec_len)) {
    ParseFileURL(spec, spec_len, &parsed_input);
    return CanonicalizeFileURL(spec, spec_len, parsed_input, charset_converter,
                               output, output_parsed);
  }
#endif

  Component scheme;
  if (!ExtractScheme(spec, spec_len, &scheme))
    return false;

  // This is the parsed version of the input URL, we have to canonicalize it
  // before storing it in our object.
  bool success;
  if (DoCompareSchemeComponent(spec, scheme, url::kFileScheme)) {
    // File URLs are special.
    ParseFileURL(spec, spec_len, &parsed_input);
    success = CanonicalizeFileURL(spec, spec_len, parsed_input,
                                  charset_converter, output, output_parsed);
  } else if (DoCompareSchemeComponent(spec, scheme, url::kFileSystemScheme)) {
    // Filesystem URLs are special.
    ParseFileSystemURL(spec, spec_len, &parsed_input);
    success = CanonicalizeFileSystemURL(spec, spec_len, parsed_input,
                                        charset_converter, output,
                                        output_parsed);

  } else if (DoIsStandard(spec, scheme)) {
    // All "normal" URLs.
    ParseStandardURL(spec, spec_len, &parsed_input);
    success = CanonicalizeStandardURL(spec, spec_len, parsed_input,
                                      charset_converter, output, output_parsed);

  } else if (DoCompareSchemeComponent(spec, scheme, url::kMailToScheme)) {
    // Mailto are treated like a standard url with only a scheme, path, query
    ParseMailtoURL(spec, spec_len, &parsed_input);
    success = CanonicalizeMailtoURL(spec, spec_len, parsed_input, output,
                                    output_parsed);

  } else {
    // "Weird" URLs like data: and javascript:
    ParsePathURL(spec, spec_len, trim_path_end, &parsed_input);
    success = CanonicalizePathURL(spec, spec_len, parsed_input, output,
                                  output_parsed);
  }
  return success;
}

template<typename CHAR>
bool DoResolveRelative(const char* base_spec,
                       int base_spec_len,
                       const Parsed& base_parsed,
                       const CHAR* in_relative,
                       int in_relative_length,
                       CharsetConverter* charset_converter,
                       CanonOutput* output,
                       Parsed* output_parsed) {
  // Remove any whitespace from the middle of the relative URL, possibly
  // copying to the new buffer.
  RawCanonOutputT<CHAR> whitespace_buffer;
  int relative_length;
  const CHAR* relative = RemoveURLWhitespace(in_relative, in_relative_length,
                                             &whitespace_buffer,
                                             &relative_length);
  bool base_is_authority_based = false;
  bool base_is_hierarchical = false;
  if (base_spec &&
      base_parsed.scheme.is_nonempty()) {
    int after_scheme = base_parsed.scheme.end() + 1;  // Skip past the colon.
    int num_slashes = CountConsecutiveSlashes(base_spec, after_scheme,
                                              base_spec_len);
    base_is_authority_based = num_slashes > 1;
    base_is_hierarchical = num_slashes > 0;
  }

  bool standard_base_scheme =
      base_parsed.scheme.is_nonempty() &&
      DoIsStandard(base_spec, base_parsed.scheme);

  bool is_relative;
  Component relative_component;
  if (!IsRelativeURL(base_spec, base_parsed, relative, relative_length,
                     (base_is_hierarchical || standard_base_scheme),
                     &is_relative, &relative_component)) {
    // Error resolving.
    return false;
  }

  // Pretend for a moment that |base_spec| is a standard URL. Normally
  // non-standard URLs are treated as PathURLs, but if the base has an
  // authority we would like to preserve it.
  if (is_relative && base_is_authority_based && !standard_base_scheme) {
    Parsed base_parsed_authority;
    ParseStandardURL(base_spec, base_spec_len, &base_parsed_authority);
    if (base_parsed_authority.host.is_nonempty()) {
      RawCanonOutputT<char> temporary_output;
      bool did_resolve_succeed =
          ResolveRelativeURL(base_spec, base_parsed_authority, false, relative,
                             relative_component, charset_converter,
                             &temporary_output, output_parsed);
      // The output_parsed is incorrect at this point (because it was built
      // based on base_parsed_authority instead of base_parsed) and needs to be
      // re-created.
      DoCanonicalize(temporary_output.data(), temporary_output.length(), true,
                     charset_converter, output, output_parsed);
      return did_resolve_succeed;
    }
  } else if (is_relative) {
    // Relative, resolve and canonicalize.
    bool file_base_scheme = base_parsed.scheme.is_nonempty() &&
        DoCompareSchemeComponent(base_spec, base_parsed.scheme, kFileScheme);
    return ResolveRelativeURL(base_spec, base_parsed, file_base_scheme, relative,
                              relative_component, charset_converter, output,
                              output_parsed);
  }

  // Not relative, canonicalize the input.
  return DoCanonicalize(relative, relative_length, true, charset_converter,
                        output, output_parsed);
}

template<typename CHAR>
bool DoReplaceComponents(const char* spec,
                         int spec_len,
                         const Parsed& parsed,
                         const Replacements<CHAR>& replacements,
                         CharsetConverter* charset_converter,
                         CanonOutput* output,
                         Parsed* out_parsed) {
  // If the scheme is overridden, just do a simple string substitution and
  // reparse the whole thing. There are lots of edge cases that we really don't
  // want to deal with. Like what happens if I replace "http://e:8080/foo"
  // with a file. Does it become "file:///E:/8080/foo" where the port number
  // becomes part of the path? Parsing that string as a file URL says "yes"
  // but almost no sane rule for dealing with the components individually would
  // come up with that.
  //
  // Why allow these crazy cases at all? Programatically, there is almost no
  // case for replacing the scheme. The most common case for hitting this is
  // in JS when building up a URL using the location object. In this case, the
  // JS code expects the string substitution behavior:
  //   http://www.w3.org/TR/2008/WD-html5-20080610/structured.html#common3
  if (replacements.IsSchemeOverridden()) {
    // Canonicalize the new scheme so it is 8-bit and can be concatenated with
    // the existing spec.
    RawCanonOutput<128> scheme_replaced;
    Component scheme_replaced_parsed;
    CanonicalizeScheme(replacements.sources().scheme,
                       replacements.components().scheme,
                       &scheme_replaced, &scheme_replaced_parsed);

    // We can assume that the input is canonicalized, which means it always has
    // a colon after the scheme (or where the scheme would be).
    int spec_after_colon = parsed.scheme.is_valid() ? parsed.scheme.end() + 1
                                                    : 1;
    if (spec_len - spec_after_colon > 0) {
      scheme_replaced.Append(&spec[spec_after_colon],
                             spec_len - spec_after_colon);
    }

    // We now need to completely re-parse the resulting string since its meaning
    // may have changed with the different scheme.
    RawCanonOutput<128> recanonicalized;
    Parsed recanonicalized_parsed;
    DoCanonicalize(scheme_replaced.data(), scheme_replaced.length(), true,
                   charset_converter,
                   &recanonicalized, &recanonicalized_parsed);

    // Recurse using the version with the scheme already replaced. This will now
    // use the replacement rules for the new scheme.
    //
    // Warning: this code assumes that ReplaceComponents will re-check all
    // components for validity. This is because we can't fail if DoCanonicalize
    // failed above since theoretically the thing making it fail could be
    // getting replaced here. If ReplaceComponents didn't re-check everything,
    // we wouldn't know if something *not* getting replaced is a problem.
    // If the scheme-specific replacers are made more intelligent so they don't
    // re-check everything, we should instead recanonicalize the whole thing
    // after this call to check validity (this assumes replacing the scheme is
    // much much less common than other types of replacements, like clearing the
    // ref).
    Replacements<CHAR> replacements_no_scheme = replacements;
    replacements_no_scheme.SetScheme(NULL, Component());
    return DoReplaceComponents(recanonicalized.data(), recanonicalized.length(),
                               recanonicalized_parsed, replacements_no_scheme,
                               charset_converter, output, out_parsed);
  }

  // If we get here, then we know the scheme doesn't need to be replaced, so can
  // just key off the scheme in the spec to know how to do the replacements.
  if (DoCompareSchemeComponent(spec, parsed.scheme, url::kFileScheme)) {
    return ReplaceFileURL(spec, parsed, replacements, charset_converter, output,
                          out_parsed);
  }
  if (DoCompareSchemeComponent(spec, parsed.scheme, url::kFileSystemScheme)) {
    return ReplaceFileSystemURL(spec, parsed, replacements, charset_converter,
                                output, out_parsed);
  }
  if (DoIsStandard(spec, parsed.scheme)) {
    return ReplaceStandardURL(spec, parsed, replacements, charset_converter,
                              output, out_parsed);
  }
  if (DoCompareSchemeComponent(spec, parsed.scheme, url::kMailToScheme)) {
    return ReplaceMailtoURL(spec, parsed, replacements, output, out_parsed);
  }

  // Default is a path URL.
  return ReplacePathURL(spec, parsed, replacements, output, out_parsed);
}

}  // namespace

void Initialize() {
  InitStandardSchemes();
}

void Shutdown() {
  if (standard_schemes) {
    delete standard_schemes;
    standard_schemes = NULL;
  }
}

void AddStandardScheme(const char* new_scheme) {
  // If this assert triggers, it means you've called AddStandardScheme after
  // LockStandardSchemes have been called (see the header file for
  // LockStandardSchemes for more).
  //
  // This normally means you're trying to set up a new standard scheme too late
  // in your application's init process. Locate where your app does this
  // initialization and calls LockStandardScheme, and add your new standard
  // scheme there.
  DCHECK(!standard_schemes_locked) <<
      "Trying to add a standard scheme after the list has been locked.";

  size_t scheme_len = strlen(new_scheme);
  if (scheme_len == 0)
    return;

  // Dulicate the scheme into a new buffer and add it to the list of standard
  // schemes. This pointer will be leaked on shutdown.
  char* dup_scheme = new char[scheme_len + 1];
  ANNOTATE_LEAKING_OBJECT_PTR(dup_scheme);
  memcpy(dup_scheme, new_scheme, scheme_len + 1);

  InitStandardSchemes();
  standard_schemes->push_back(dup_scheme);
}

void LockStandardSchemes() {
  standard_schemes_locked = true;
}

bool IsStandard(const char* spec, const Component& scheme) {
  return DoIsStandard(spec, scheme);
}

bool IsStandard(const base::char16* spec, const Component& scheme) {
  return DoIsStandard(spec, scheme);
}

bool FindAndCompareScheme(const char* str,
                          int str_len,
                          const char* compare,
                          Component* found_scheme) {
  return DoFindAndCompareScheme(str, str_len, compare, found_scheme);
}

bool FindAndCompareScheme(const base::char16* str,
                          int str_len,
                          const char* compare,
                          Component* found_scheme) {
  return DoFindAndCompareScheme(str, str_len, compare, found_scheme);
}

bool Canonicalize(const char* spec,
                  int spec_len,
                  bool trim_path_end,
                  CharsetConverter* charset_converter,
                  CanonOutput* output,
                  Parsed* output_parsed) {
  return DoCanonicalize(spec, spec_len, trim_path_end, charset_converter,
                        output, output_parsed);
}

bool Canonicalize(const base::char16* spec,
                  int spec_len,
                  bool trim_path_end,
                  CharsetConverter* charset_converter,
                  CanonOutput* output,
                  Parsed* output_parsed) {
  return DoCanonicalize(spec, spec_len, trim_path_end, charset_converter,
                        output, output_parsed);
}

bool ResolveRelative(const char* base_spec,
                     int base_spec_len,
                     const Parsed& base_parsed,
                     const char* relative,
                     int relative_length,
                     CharsetConverter* charset_converter,
                     CanonOutput* output,
                     Parsed* output_parsed) {
  return DoResolveRelative(base_spec, base_spec_len, base_parsed,
                           relative, relative_length,
                           charset_converter, output, output_parsed);
}

bool ResolveRelative(const char* base_spec,
                     int base_spec_len,
                     const Parsed& base_parsed,
                     const base::char16* relative,
                     int relative_length,
                     CharsetConverter* charset_converter,
                     CanonOutput* output,
                     Parsed* output_parsed) {
  return DoResolveRelative(base_spec, base_spec_len, base_parsed,
                           relative, relative_length,
                           charset_converter, output, output_parsed);
}

bool ReplaceComponents(const char* spec,
                       int spec_len,
                       const Parsed& parsed,
                       const Replacements<char>& replacements,
                       CharsetConverter* charset_converter,
                       CanonOutput* output,
                       Parsed* out_parsed) {
  return DoReplaceComponents(spec, spec_len, parsed, replacements,
                             charset_converter, output, out_parsed);
}

bool ReplaceComponents(const char* spec,
                       int spec_len,
                       const Parsed& parsed,
                       const Replacements<base::char16>& replacements,
                       CharsetConverter* charset_converter,
                       CanonOutput* output,
                       Parsed* out_parsed) {
  return DoReplaceComponents(spec, spec_len, parsed, replacements,
                             charset_converter, output, out_parsed);
}

// Front-ends for LowerCaseEqualsASCII.
bool LowerCaseEqualsASCII(const char* a_begin,
                          const char* a_end,
                          const char* b) {
  return DoLowerCaseEqualsASCII(a_begin, a_end, b);
}

bool LowerCaseEqualsASCII(const char* a_begin,
                          const char* a_end,
                          const char* b_begin,
                          const char* b_end) {
  while (a_begin != a_end && b_begin != b_end &&
         ToLowerASCII(*a_begin) == *b_begin) {
    a_begin++;
    b_begin++;
  }
  return a_begin == a_end && b_begin == b_end;
}

bool LowerCaseEqualsASCII(const base::char16* a_begin,
                          const base::char16* a_end,
                          const char* b) {
  return DoLowerCaseEqualsASCII(a_begin, a_end, b);
}

void DecodeURLEscapeSequences(const char* input,
                              int length,
                              CanonOutputW* output) {
  RawCanonOutputT<char> unescaped_chars;
  for (int i = 0; i < length; i++) {
    if (input[i] == '%') {
      unsigned char ch;
      if (DecodeEscaped(input, &i, length, &ch)) {
        unescaped_chars.push_back(ch);
      } else {
        // Invalid escape sequence, copy the percent literal.
        unescaped_chars.push_back('%');
      }
    } else {
      // Regular non-escaped 8-bit character.
      unescaped_chars.push_back(input[i]);
    }
  }

  // Convert that 8-bit to UTF-16. It's not clear IE does this at all to
  // JavaScript URLs, but Firefox and Safari do.
  for (int i = 0; i < unescaped_chars.length(); i++) {
    unsigned char uch = static_cast<unsigned char>(unescaped_chars.at(i));
    if (uch < 0x80) {
      // Non-UTF-8, just append directly
      output->push_back(uch);
    } else {
      // next_ch will point to the last character of the decoded
      // character.
      int next_character = i;
      unsigned code_point;
      if (ReadUTFChar(unescaped_chars.data(), &next_character,
                      unescaped_chars.length(), &code_point)) {
        // Valid UTF-8 character, convert to UTF-16.
        AppendUTF16Value(code_point, output);
        i = next_character;
      } else {
        // If there are any sequences that are not valid UTF-8, we keep
        // invalid code points and promote to UTF-16. We copy all characters
        // from the current position to the end of the identified sequence.
        while (i < next_character) {
          output->push_back(static_cast<unsigned char>(unescaped_chars.at(i)));
          i++;
        }
        output->push_back(static_cast<unsigned char>(unescaped_chars.at(i)));
      }
    }
  }
}

void EncodeURIComponent(const char* input, int length, CanonOutput* output) {
  for (int i = 0; i < length; ++i) {
    unsigned char c = static_cast<unsigned char>(input[i]);
    if (IsComponentChar(c))
      output->push_back(c);
    else
      AppendEscapedChar(c, output);
  }
}

bool CompareSchemeComponent(const char* spec,
                            const Component& component,
                            const char* compare_to) {
  return DoCompareSchemeComponent(spec, component, compare_to);
}

bool CompareSchemeComponent(const base::char16* spec,
                            const Component& component,
                            const char* compare_to) {
  return DoCompareSchemeComponent(spec, component, compare_to);
}

}  // namespace url

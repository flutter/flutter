/* Based on nsURLParsers.cc from Mozilla
 * -------------------------------------
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is mozilla.org code.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 1998
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Darin Fisher (original author)
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

#include "url/third_party/mozilla/url_parse.h"

#include <stdlib.h>

#include "base/logging.h"
#include "url/url_parse_internal.h"
#include "url/url_util.h"
#include "url/url_util_internal.h"

namespace url {

namespace {

// Returns true if the given character is a valid digit to use in a port.
inline bool IsPortDigit(base::char16 ch) {
  return ch >= '0' && ch <= '9';
}

// Returns the offset of the next authority terminator in the input starting
// from start_offset. If no terminator is found, the return value will be equal
// to spec_len.
template<typename CHAR>
int FindNextAuthorityTerminator(const CHAR* spec,
                                int start_offset,
                                int spec_len) {
  for (int i = start_offset; i < spec_len; i++) {
    if (IsAuthorityTerminator(spec[i]))
      return i;
  }
  return spec_len;  // Not found.
}

template<typename CHAR>
void ParseUserInfo(const CHAR* spec,
                   const Component& user,
                   Component* username,
                   Component* password) {
  // Find the first colon in the user section, which separates the username and
  // password.
  int colon_offset = 0;
  while (colon_offset < user.len && spec[user.begin + colon_offset] != ':')
    colon_offset++;

  if (colon_offset < user.len) {
    // Found separator: <username>:<password>
    *username = Component(user.begin, colon_offset);
    *password = MakeRange(user.begin + colon_offset + 1,
                          user.begin + user.len);
  } else {
    // No separator, treat everything as the username
    *username = user;
    *password = Component();
  }
}

template<typename CHAR>
void ParseServerInfo(const CHAR* spec,
                     const Component& serverinfo,
                     Component* hostname,
                     Component* port_num) {
  if (serverinfo.len == 0) {
    // No server info, host name is empty.
    hostname->reset();
    port_num->reset();
    return;
  }

  // If the host starts with a left-bracket, assume the entire host is an
  // IPv6 literal.  Otherwise, assume none of the host is an IPv6 literal.
  // This assumption will be overridden if we find a right-bracket.
  //
  // Our IPv6 address canonicalization code requires both brackets to exist,
  // but the ability to locate an incomplete address can still be useful.
  int ipv6_terminator = spec[serverinfo.begin] == '[' ? serverinfo.end() : -1;
  int colon = -1;

  // Find the last right-bracket, and the last colon.
  for (int i = serverinfo.begin; i < serverinfo.end(); i++) {
    switch (spec[i]) {
      case ']':
        ipv6_terminator = i;
        break;
      case ':':
        colon = i;
        break;
    }
  }

  if (colon > ipv6_terminator) {
    // Found a port number: <hostname>:<port>
    *hostname = MakeRange(serverinfo.begin, colon);
    if (hostname->len == 0)
      hostname->reset();
    *port_num = MakeRange(colon + 1, serverinfo.end());
  } else {
    // No port: <hostname>
    *hostname = serverinfo;
    port_num->reset();
  }
}

// Given an already-identified auth section, breaks it into its consituent
// parts. The port number will be parsed and the resulting integer will be
// filled into the given *port variable, or -1 if there is no port number or it
// is invalid.
template<typename CHAR>
void DoParseAuthority(const CHAR* spec,
                      const Component& auth,
                      Component* username,
                      Component* password,
                      Component* hostname,
                      Component* port_num) {
  DCHECK(auth.is_valid()) << "We should always get an authority";
  if (auth.len == 0) {
    username->reset();
    password->reset();
    hostname->reset();
    port_num->reset();
    return;
  }

  // Search backwards for @, which is the separator between the user info and
  // the server info.
  int i = auth.begin + auth.len - 1;
  while (i > auth.begin && spec[i] != '@')
    i--;

  if (spec[i] == '@') {
    // Found user info: <user-info>@<server-info>
    ParseUserInfo(spec, Component(auth.begin, i - auth.begin),
                  username, password);
    ParseServerInfo(spec, MakeRange(i + 1, auth.begin + auth.len),
                    hostname, port_num);
  } else {
    // No user info, everything is server info.
    username->reset();
    password->reset();
    ParseServerInfo(spec, auth, hostname, port_num);
  }
}

template<typename CHAR>
void ParsePath(const CHAR* spec,
               const Component& path,
               Component* filepath,
               Component* query,
               Component* ref) {
  // path = [/]<segment1>/<segment2>/<...>/<segmentN>;<param>?<query>#<ref>

  // Special case when there is no path.
  if (path.len == -1) {
    filepath->reset();
    query->reset();
    ref->reset();
    return;
  }
  DCHECK(path.len > 0) << "We should never have 0 length paths";

  // Search for first occurrence of either ? or #.
  int path_end = path.begin + path.len;

  int query_separator = -1;  // Index of the '?'
  int ref_separator = -1;    // Index of the '#'
  for (int i = path.begin; i < path_end; i++) {
    switch (spec[i]) {
      case '?':
        // Only match the query string if it precedes the reference fragment
        // and when we haven't found one already.
        if (ref_separator < 0 && query_separator < 0)
          query_separator = i;
        break;
      case '#':
        // Record the first # sign only.
        if (ref_separator < 0)
          ref_separator = i;
        break;
    }
  }

  // Markers pointing to the character after each of these corresponding
  // components. The code below words from the end back to the beginning,
  // and will update these indices as it finds components that exist.
  int file_end, query_end;

  // Ref fragment: from the # to the end of the path.
  if (ref_separator >= 0) {
    file_end = query_end = ref_separator;
    *ref = MakeRange(ref_separator + 1, path_end);
  } else {
    file_end = query_end = path_end;
    ref->reset();
  }

  // Query fragment: everything from the ? to the next boundary (either the end
  // of the path or the ref fragment).
  if (query_separator >= 0) {
    file_end = query_separator;
    *query = MakeRange(query_separator + 1, query_end);
  } else {
    query->reset();
  }

  // File path: treat an empty file path as no file path.
  if (file_end != path.begin)
    *filepath = MakeRange(path.begin, file_end);
  else
    filepath->reset();
}

template<typename CHAR>
bool DoExtractScheme(const CHAR* url,
                     int url_len,
                     Component* scheme) {
  // Skip leading whitespace and control characters.
  int begin = 0;
  while (begin < url_len && ShouldTrimFromURL(url[begin]))
    begin++;
  if (begin == url_len)
    return false;  // Input is empty or all whitespace.

  // Find the first colon character.
  for (int i = begin; i < url_len; i++) {
    if (url[i] == ':') {
      *scheme = MakeRange(begin, i);
      return true;
    }
  }
  return false;  // No colon found: no scheme
}

// Fills in all members of the Parsed structure except for the scheme.
//
// |spec| is the full spec being parsed, of length |spec_len|.
// |after_scheme| is the character immediately following the scheme (after the
//   colon) where we'll begin parsing.
//
// Compatability data points. I list "host", "path" extracted:
// Input                IE6             Firefox                Us
// -----                --------------  --------------         --------------
// http://foo.com/      "foo.com", "/"  "foo.com", "/"         "foo.com", "/"
// http:foo.com/        "foo.com", "/"  "foo.com", "/"         "foo.com", "/"
// http:/foo.com/       fail(*)         "foo.com", "/"         "foo.com", "/"
// http:\foo.com/       fail(*)         "\foo.com", "/"(fail)  "foo.com", "/"
// http:////foo.com/    "foo.com", "/"  "foo.com", "/"         "foo.com", "/"
//
// (*) Interestingly, although IE fails to load these URLs, its history
// canonicalizer handles them, meaning if you've been to the corresponding
// "http://foo.com/" link, it will be colored.
template <typename CHAR>
void DoParseAfterScheme(const CHAR* spec,
                        int spec_len,
                        int after_scheme,
                        Parsed* parsed) {
  int num_slashes = CountConsecutiveSlashes(spec, after_scheme, spec_len);
  int after_slashes = after_scheme + num_slashes;

  // First split into two main parts, the authority (username, password, host,
  // and port) and the full path (path, query, and reference).
  Component authority;
  Component full_path;

  // Found "//<some data>", looks like an authority section. Treat everything
  // from there to the next slash (or end of spec) to be the authority. Note
  // that we ignore the number of slashes and treat it as the authority.
  int end_auth = FindNextAuthorityTerminator(spec, after_slashes, spec_len);
  authority = Component(after_slashes, end_auth - after_slashes);

  if (end_auth == spec_len)  // No beginning of path found.
    full_path = Component();
  else  // Everything starting from the slash to the end is the path.
    full_path = Component(end_auth, spec_len - end_auth);

  // Now parse those two sub-parts.
  DoParseAuthority(spec, authority, &parsed->username, &parsed->password,
                   &parsed->host, &parsed->port);
  ParsePath(spec, full_path, &parsed->path, &parsed->query, &parsed->ref);
}

// The main parsing function for standard URLs. Standard URLs have a scheme,
// host, path, etc.
template<typename CHAR>
void DoParseStandardURL(const CHAR* spec, int spec_len, Parsed* parsed) {
  DCHECK(spec_len >= 0);

  // Strip leading & trailing spaces and control characters.
  int begin = 0;
  TrimURL(spec, &begin, &spec_len);

  int after_scheme;
  if (DoExtractScheme(spec, spec_len, &parsed->scheme)) {
    after_scheme = parsed->scheme.end() + 1;  // Skip past the colon.
  } else {
    // Say there's no scheme when there is no colon. We could also say that
    // everything is the scheme. Both would produce an invalid URL, but this way
    // seems less wrong in more cases.
    parsed->scheme.reset();
    after_scheme = begin;
  }
  DoParseAfterScheme(spec, spec_len, after_scheme, parsed);
}

template<typename CHAR>
void DoParseFileSystemURL(const CHAR* spec, int spec_len, Parsed* parsed) {
  DCHECK(spec_len >= 0);

  // Get the unused parts of the URL out of the way.
  parsed->username.reset();
  parsed->password.reset();
  parsed->host.reset();
  parsed->port.reset();
  parsed->path.reset();   // May use this; reset for convenience.
  parsed->ref.reset();    // May use this; reset for convenience.
  parsed->query.reset();  // May use this; reset for convenience.
  parsed->clear_inner_parsed();  // May use this; reset for convenience.

  // Strip leading & trailing spaces and control characters.
  int begin = 0;
  TrimURL(spec, &begin, &spec_len);

  // Handle empty specs or ones that contain only whitespace or control chars.
  if (begin == spec_len) {
    parsed->scheme.reset();
    return;
  }

  int inner_start = -1;

  // Extract the scheme.  We also handle the case where there is no scheme.
  if (DoExtractScheme(&spec[begin], spec_len - begin, &parsed->scheme)) {
    // Offset the results since we gave ExtractScheme a substring.
    parsed->scheme.begin += begin;

    if (parsed->scheme.end() == spec_len - 1)
      return;

    inner_start = parsed->scheme.end() + 1;
  } else {
    // No scheme found; that's not valid for filesystem URLs.
    parsed->scheme.reset();
    return;
  }

  Component inner_scheme;
  const CHAR* inner_spec = &spec[inner_start];
  int inner_spec_len = spec_len - inner_start;

  if (DoExtractScheme(inner_spec, inner_spec_len, &inner_scheme)) {
    // Offset the results since we gave ExtractScheme a substring.
    inner_scheme.begin += inner_start;

    if (inner_scheme.end() == spec_len - 1)
      return;
  } else {
    // No scheme found; that's not valid for filesystem URLs.
    // The best we can do is return "filesystem://".
    return;
  }

  Parsed inner_parsed;

  if (CompareSchemeComponent(spec, inner_scheme, kFileScheme)) {
    // File URLs are special.
    ParseFileURL(inner_spec, inner_spec_len, &inner_parsed);
  } else if (CompareSchemeComponent(spec, inner_scheme, kFileSystemScheme)) {
    // Filesystem URLs don't nest.
    return;
  } else if (IsStandard(spec, inner_scheme)) {
    // All "normal" URLs.
    DoParseStandardURL(inner_spec, inner_spec_len, &inner_parsed);
  } else {
    return;
  }

  // All members of inner_parsed need to be offset by inner_start.
  // If we had any scheme that supported nesting more than one level deep,
  // we'd have to recurse into the inner_parsed's inner_parsed when
  // adjusting by inner_start.
  inner_parsed.scheme.begin += inner_start;
  inner_parsed.username.begin += inner_start;
  inner_parsed.password.begin += inner_start;
  inner_parsed.host.begin += inner_start;
  inner_parsed.port.begin += inner_start;
  inner_parsed.query.begin += inner_start;
  inner_parsed.ref.begin += inner_start;
  inner_parsed.path.begin += inner_start;

  // Query and ref move from inner_parsed to parsed.
  parsed->query = inner_parsed.query;
  inner_parsed.query.reset();
  parsed->ref = inner_parsed.ref;
  inner_parsed.ref.reset();

  parsed->set_inner_parsed(inner_parsed);
  if (!inner_parsed.scheme.is_valid() || !inner_parsed.path.is_valid() ||
      inner_parsed.inner_parsed()) {
    return;
  }

  // The path in inner_parsed should start with a slash, then have a filesystem
  // type followed by a slash.  From the first slash up to but excluding the
  // second should be what it keeps; the rest goes to parsed.  If the path ends
  // before the second slash, it's still pretty clear what the user meant, so
  // we'll let that through.
  if (!IsURLSlash(spec[inner_parsed.path.begin])) {
    return;
  }
  int inner_path_end = inner_parsed.path.begin + 1;  // skip the leading slash
  while (inner_path_end < spec_len &&
      !IsURLSlash(spec[inner_path_end]))
    ++inner_path_end;
  parsed->path.begin = inner_path_end;
  int new_inner_path_length = inner_path_end - inner_parsed.path.begin;
  parsed->path.len = inner_parsed.path.len - new_inner_path_length;
  parsed->inner_parsed()->path.len = new_inner_path_length;
}

// Initializes a path URL which is merely a scheme followed by a path. Examples
// include "about:foo" and "javascript:alert('bar');"
template<typename CHAR>
void DoParsePathURL(const CHAR* spec, int spec_len,
                    bool trim_path_end,
                    Parsed* parsed) {
  // Get the non-path and non-scheme parts of the URL out of the way, we never
  // use them.
  parsed->username.reset();
  parsed->password.reset();
  parsed->host.reset();
  parsed->port.reset();
  parsed->path.reset();
  parsed->query.reset();
  parsed->ref.reset();

  // Strip leading & trailing spaces and control characters.
  int scheme_begin = 0;
  TrimURL(spec, &scheme_begin, &spec_len, trim_path_end);

  // Handle empty specs or ones that contain only whitespace or control chars.
  if (scheme_begin == spec_len) {
    parsed->scheme.reset();
    parsed->path.reset();
    return;
  }

  int path_begin;
  // Extract the scheme, with the path being everything following. We also
  // handle the case where there is no scheme.
  if (ExtractScheme(&spec[scheme_begin], spec_len - scheme_begin,
                    &parsed->scheme)) {
    // Offset the results since we gave ExtractScheme a substring.
    parsed->scheme.begin += scheme_begin;
    path_begin = parsed->scheme.end() + 1;
  } else {
    // No scheme case.
    parsed->scheme.reset();
    path_begin = scheme_begin;
  }

  if (path_begin == spec_len)
    return;
  DCHECK_LT(path_begin, spec_len);

  ParsePath(spec,
            MakeRange(path_begin, spec_len),
            &parsed->path,
            &parsed->query,
            &parsed->ref);
}

template<typename CHAR>
void DoParseMailtoURL(const CHAR* spec, int spec_len, Parsed* parsed) {
  DCHECK(spec_len >= 0);

  // Get the non-path and non-scheme parts of the URL out of the way, we never
  // use them.
  parsed->username.reset();
  parsed->password.reset();
  parsed->host.reset();
  parsed->port.reset();
  parsed->ref.reset();
  parsed->query.reset();  // May use this; reset for convenience.

  // Strip leading & trailing spaces and control characters.
  int begin = 0;
  TrimURL(spec, &begin, &spec_len);

  // Handle empty specs or ones that contain only whitespace or control chars.
  if (begin == spec_len) {
    parsed->scheme.reset();
    parsed->path.reset();
    return;
  }

  int path_begin = -1;
  int path_end = -1;

  // Extract the scheme, with the path being everything following. We also
  // handle the case where there is no scheme.
  if (ExtractScheme(&spec[begin], spec_len - begin, &parsed->scheme)) {
    // Offset the results since we gave ExtractScheme a substring.
    parsed->scheme.begin += begin;

    if (parsed->scheme.end() != spec_len - 1) {
      path_begin = parsed->scheme.end() + 1;
      path_end = spec_len;
    }
  } else {
    // No scheme found, just path.
    parsed->scheme.reset();
    path_begin = begin;
    path_end = spec_len;
  }

  // Split [path_begin, path_end) into a path + query.
  for (int i = path_begin; i < path_end; ++i) {
    if (spec[i] == '?') {
      parsed->query = MakeRange(i + 1, path_end);
      path_end = i;
      break;
    }
  }

  // For compatability with the standard URL parser, treat no path as
  // -1, rather than having a length of 0
  if (path_begin == path_end) {
    parsed->path.reset();
  } else {
    parsed->path = MakeRange(path_begin, path_end);
  }
}

// Converts a port number in a string to an integer. We'd like to just call
// sscanf but our input is not NULL-terminated, which sscanf requires. Instead,
// we copy the digits to a small stack buffer (since we know the maximum number
// of digits in a valid port number) that we can NULL terminate.
template<typename CHAR>
int DoParsePort(const CHAR* spec, const Component& component) {
  // Easy success case when there is no port.
  const int kMaxDigits = 5;
  if (!component.is_nonempty())
    return PORT_UNSPECIFIED;

  // Skip over any leading 0s.
  Component digits_comp(component.end(), 0);
  for (int i = 0; i < component.len; i++) {
    if (spec[component.begin + i] != '0') {
      digits_comp = MakeRange(component.begin + i, component.end());
      break;
    }
  }
  if (digits_comp.len == 0)
    return 0;  // All digits were 0.

  // Verify we don't have too many digits (we'll be copying to our buffer so
  // we need to double-check).
  if (digits_comp.len > kMaxDigits)
    return PORT_INVALID;

  // Copy valid digits to the buffer.
  char digits[kMaxDigits + 1];  // +1 for null terminator
  for (int i = 0; i < digits_comp.len; i++) {
    CHAR ch = spec[digits_comp.begin + i];
    if (!IsPortDigit(ch)) {
      // Invalid port digit, fail.
      return PORT_INVALID;
    }
    digits[i] = static_cast<char>(ch);
  }

  // Null-terminate the string and convert to integer. Since we guarantee
  // only digits, atoi's lack of error handling is OK.
  digits[digits_comp.len] = 0;
  int port = atoi(digits);
  if (port > 65535)
    return PORT_INVALID;  // Out of range.
  return port;
}

template<typename CHAR>
void DoExtractFileName(const CHAR* spec,
                       const Component& path,
                       Component* file_name) {
  // Handle empty paths: they have no file names.
  if (!path.is_nonempty()) {
    file_name->reset();
    return;
  }

  // Extract the filename range from the path which is between
  // the last slash and the following semicolon.
  int file_end = path.end();
  for (int i = path.end() - 1; i >= path.begin; i--) {
    if (spec[i] == ';') {
      file_end = i;
    } else if (IsURLSlash(spec[i])) {
      // File name is everything following this character to the end
      *file_name = MakeRange(i + 1, file_end);
      return;
    }
  }

  // No slash found, this means the input was degenerate (generally paths
  // will start with a slash). Let's call everything the file name.
  *file_name = MakeRange(path.begin, file_end);
  return;
}

template<typename CHAR>
bool DoExtractQueryKeyValue(const CHAR* spec,
                            Component* query,
                            Component* key,
                            Component* value) {
  if (!query->is_nonempty())
    return false;

  int start = query->begin;
  int cur = start;
  int end = query->end();

  // We assume the beginning of the input is the beginning of the "key" and we
  // skip to the end of it.
  key->begin = cur;
  while (cur < end && spec[cur] != '&' && spec[cur] != '=')
    cur++;
  key->len = cur - key->begin;

  // Skip the separator after the key (if any).
  if (cur < end && spec[cur] == '=')
    cur++;

  // Find the value part.
  value->begin = cur;
  while (cur < end && spec[cur] != '&')
    cur++;
  value->len = cur - value->begin;

  // Finally skip the next separator if any
  if (cur < end && spec[cur] == '&')
    cur++;

  // Save the new query
  *query = MakeRange(cur, end);
  return true;
}

}  // namespace

Parsed::Parsed() : inner_parsed_(NULL) {
}

Parsed::Parsed(const Parsed& other) :
    scheme(other.scheme),
    username(other.username),
    password(other.password),
    host(other.host),
    port(other.port),
    path(other.path),
    query(other.query),
    ref(other.ref),
    inner_parsed_(NULL) {
  if (other.inner_parsed_)
    set_inner_parsed(*other.inner_parsed_);
}

Parsed& Parsed::operator=(const Parsed& other) {
  if (this != &other) {
    scheme = other.scheme;
    username = other.username;
    password = other.password;
    host = other.host;
    port = other.port;
    path = other.path;
    query = other.query;
    ref = other.ref;
    if (other.inner_parsed_)
      set_inner_parsed(*other.inner_parsed_);
    else
      clear_inner_parsed();
  }
  return *this;
}

Parsed::~Parsed() {
  delete inner_parsed_;
}

int Parsed::Length() const {
  if (ref.is_valid())
    return ref.end();
  return CountCharactersBefore(REF, false);
}

int Parsed::CountCharactersBefore(ComponentType type,
                                  bool include_delimiter) const {
  if (type == SCHEME)
    return scheme.begin;

  // There will be some characters after the scheme like "://" and we don't
  // know how many. Search forwards for the next thing until we find one.
  int cur = 0;
  if (scheme.is_valid())
    cur = scheme.end() + 1;  // Advance over the ':' at the end of the scheme.

  if (username.is_valid()) {
    if (type <= USERNAME)
      return username.begin;
    cur = username.end() + 1;  // Advance over the '@' or ':' at the end.
  }

  if (password.is_valid()) {
    if (type <= PASSWORD)
      return password.begin;
    cur = password.end() + 1;  // Advance over the '@' at the end.
  }

  if (host.is_valid()) {
    if (type <= HOST)
      return host.begin;
    cur = host.end();
  }

  if (port.is_valid()) {
    if (type < PORT || (type == PORT && include_delimiter))
      return port.begin - 1;  // Back over delimiter.
    if (type == PORT)
      return port.begin;  // Don't want delimiter counted.
    cur = port.end();
  }

  if (path.is_valid()) {
    if (type <= PATH)
      return path.begin;
    cur = path.end();
  }

  if (query.is_valid()) {
    if (type < QUERY || (type == QUERY && include_delimiter))
      return query.begin - 1;  // Back over delimiter.
    if (type == QUERY)
      return query.begin;  // Don't want delimiter counted.
    cur = query.end();
  }

  if (ref.is_valid()) {
    if (type == REF && !include_delimiter)
      return ref.begin;  // Back over delimiter.

    // When there is a ref and we get here, the component we wanted was before
    // this and not found, so we always know the beginning of the ref is right.
    return ref.begin - 1;  // Don't want delimiter counted.
  }

  return cur;
}

Component Parsed::GetContent() const {
  const int begin = CountCharactersBefore(USERNAME, false);
  const int len = Length() - begin;
  // For compatability with the standard URL parser, we treat no content as
  // -1, rather than having a length of 0 (we normally wouldn't care so
  // much for these non-standard URLs).
  return len ? Component(begin, len) : Component();
}

bool ExtractScheme(const char* url, int url_len, Component* scheme) {
  return DoExtractScheme(url, url_len, scheme);
}

bool ExtractScheme(const base::char16* url, int url_len, Component* scheme) {
  return DoExtractScheme(url, url_len, scheme);
}

// This handles everything that may be an authority terminator, including
// backslash. For special backslash handling see DoParseAfterScheme.
bool IsAuthorityTerminator(base::char16 ch) {
  return IsURLSlash(ch) || ch == '?' || ch == '#';
}

void ExtractFileName(const char* url,
                     const Component& path,
                     Component* file_name) {
  DoExtractFileName(url, path, file_name);
}

void ExtractFileName(const base::char16* url,
                     const Component& path,
                     Component* file_name) {
  DoExtractFileName(url, path, file_name);
}

bool ExtractQueryKeyValue(const char* url,
                          Component* query,
                          Component* key,
                          Component* value) {
  return DoExtractQueryKeyValue(url, query, key, value);
}

bool ExtractQueryKeyValue(const base::char16* url,
                          Component* query,
                          Component* key,
                          Component* value) {
  return DoExtractQueryKeyValue(url, query, key, value);
}

void ParseAuthority(const char* spec,
                    const Component& auth,
                    Component* username,
                    Component* password,
                    Component* hostname,
                    Component* port_num) {
  DoParseAuthority(spec, auth, username, password, hostname, port_num);
}

void ParseAuthority(const base::char16* spec,
                    const Component& auth,
                    Component* username,
                    Component* password,
                    Component* hostname,
                    Component* port_num) {
  DoParseAuthority(spec, auth, username, password, hostname, port_num);
}

int ParsePort(const char* url, const Component& port) {
  return DoParsePort(url, port);
}

int ParsePort(const base::char16* url, const Component& port) {
  return DoParsePort(url, port);
}

void ParseStandardURL(const char* url, int url_len, Parsed* parsed) {
  DoParseStandardURL(url, url_len, parsed);
}

void ParseStandardURL(const base::char16* url, int url_len, Parsed* parsed) {
  DoParseStandardURL(url, url_len, parsed);
}

void ParsePathURL(const char* url,
                  int url_len,
                  bool trim_path_end,
                  Parsed* parsed) {
  DoParsePathURL(url, url_len, trim_path_end, parsed);
}

void ParsePathURL(const base::char16* url,
                  int url_len,
                  bool trim_path_end,
                  Parsed* parsed) {
  DoParsePathURL(url, url_len, trim_path_end, parsed);
}

void ParseFileSystemURL(const char* url, int url_len, Parsed* parsed) {
  DoParseFileSystemURL(url, url_len, parsed);
}

void ParseFileSystemURL(const base::char16* url, int url_len, Parsed* parsed) {
  DoParseFileSystemURL(url, url_len, parsed);
}

void ParseMailtoURL(const char* url, int url_len, Parsed* parsed) {
  DoParseMailtoURL(url, url_len, parsed);
}

void ParseMailtoURL(const base::char16* url, int url_len, Parsed* parsed) {
  DoParseMailtoURL(url, url_len, parsed);
}

void ParsePathInternal(const char* spec,
                       const Component& path,
                       Component* filepath,
                       Component* query,
                       Component* ref) {
  ParsePath(spec, path, filepath, query, ref);
}

void ParsePathInternal(const base::char16* spec,
                       const Component& path,
                       Component* filepath,
                       Component* query,
                       Component* ref) {
  ParsePath(spec, path, filepath, query, ref);
}

void ParseAfterScheme(const char* spec,
                      int spec_len,
                      int after_scheme,
                      Parsed* parsed) {
  DoParseAfterScheme(spec, spec_len, after_scheme, parsed);
}

void ParseAfterScheme(const base::char16* spec,
                      int spec_len,
                      int after_scheme,
                      Parsed* parsed) {
  DoParseAfterScheme(spec, spec_len, after_scheme, parsed);
}

}  // namespace url

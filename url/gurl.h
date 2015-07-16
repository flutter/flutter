// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_GURL_H_
#define URL_GURL_H_

#include <iosfwd>
#include <string>

#include "base/memory/scoped_ptr.h"
#include "base/strings/string16.h"
#include "url/url_canon.h"
#include "url/url_canon_stdstring.h"
#include "url/url_constants.h"
#include "url/url_export.h"
#include "url/url_parse.h"

class URL_EXPORT GURL {
 public:
  typedef url::StringPieceReplacements<std::string> Replacements;
  typedef url::StringPieceReplacements<base::string16> ReplacementsW;

  // Creates an empty, invalid URL.
  GURL();

  // Copy construction is relatively inexpensive, with most of the time going
  // to reallocating the string. It does not re-parse.
  GURL(const GURL& other);

  // The narrow version requires the input be UTF-8. Invalid UTF-8 input will
  // result in an invalid URL.
  //
  // The wide version should also take an encoding parameter so we know how to
  // encode the query parameters. It is probably sufficient for the narrow
  // version to assume the query parameter encoding should be the same as the
  // input encoding.
  explicit GURL(const std::string& url_string /*, output_param_encoding*/);
  explicit GURL(const base::string16& url_string /*, output_param_encoding*/);

  // Constructor for URLs that have already been parsed and canonicalized. This
  // is used for conversions from KURL, for example. The caller must supply all
  // information associated with the URL, which must be correct and consistent.
  GURL(const char* canonical_spec,
       size_t canonical_spec_len,
       const url::Parsed& parsed,
       bool is_valid);
  // Notice that we take the canonical_spec by value so that we can convert
  // from WebURL without copying the string. When we call this constructor
  // we pass in a temporary std::string, which lets the compiler skip the
  // copy and just move the std::string into the function argument. In the
  // implementation, we use swap to move the data into the GURL itself,
  // which means we end up with zero copies.
  GURL(std::string canonical_spec, const url::Parsed& parsed, bool is_valid);

  ~GURL();

  GURL& operator=(GURL other);

  // Returns true when this object represents a valid parsed URL. When not
  // valid, other functions will still succeed, but you will not get canonical
  // data out in the format you may be expecting. Instead, we keep something
  // "reasonable looking" so that the user can see how it's busted if
  // displayed to them.
  bool is_valid() const {
    return is_valid_;
  }

  // Returns true if the URL is zero-length. Note that empty URLs are also
  // invalid, and is_valid() will return false for them. This is provided
  // because some users may want to treat the empty case differently.
  bool is_empty() const {
    return spec_.empty();
  }

  // Returns the raw spec, i.e., the full text of the URL, in canonical UTF-8,
  // if the URL is valid. If the URL is not valid, this will assert and return
  // the empty string (for safety in release builds, to keep them from being
  // misused which might be a security problem).
  //
  // The URL will be ASCII except the reference fragment, which may be UTF-8.
  // It is guaranteed to be valid UTF-8.
  //
  // The exception is for empty() URLs (which are !is_valid()) but this will
  // return the empty string without asserting.
  //
  // Used invalid_spec() below to get the unusable spec of an invalid URL. This
  // separation is designed to prevent errors that may cause security problems
  // that could result from the mistaken use of an invalid URL.
  const std::string& spec() const;

  // Returns the potentially invalid spec for a the URL. This spec MUST NOT be
  // modified or sent over the network. It is designed to be displayed in error
  // messages to the user, as the apperance of the spec may explain the error.
  // If the spec is valid, the valid spec will be returned.
  //
  // The returned string is guaranteed to be valid UTF-8.
  const std::string& possibly_invalid_spec() const {
    return spec_;
  }

  // Getter for the raw parsed structure. This allows callers to locate parts
  // of the URL within the spec themselves. Most callers should consider using
  // the individual component getters below.
  //
  // The returned parsed structure will reference into the raw spec, which may
  // or may not be valid. If you are using this to index into the spec, BE
  // SURE YOU ARE USING possibly_invalid_spec() to get the spec, and that you
  // don't do anything "important" with invalid specs.
  const url::Parsed& parsed_for_possibly_invalid_spec() const {
    return parsed_;
  }

  // Defiant equality operator!
  bool operator==(const GURL& other) const;
  bool operator!=(const GURL& other) const;

  // Allows GURL to used as a key in STL (for example, a std::set or std::map).
  bool operator<(const GURL& other) const;
  bool operator>(const GURL& other) const;

  // Resolves a URL that's possibly relative to this object's URL, and returns
  // it. Absolute URLs are also handled according to the rules of URLs on web
  // pages.
  //
  // It may be impossible to resolve the URLs properly. If the input is not
  // "standard" (SchemeIsStandard() == false) and the input looks relative, we
  // can't resolve it. In these cases, the result will be an empty, invalid
  // GURL.
  //
  // The result may also be a nonempty, invalid URL if the input has some kind
  // of encoding error. In these cases, we will try to construct a "good" URL
  // that may have meaning to the user, but it will be marked invalid.
  //
  // It is an error to resolve a URL relative to an invalid URL. The result
  // will be the empty URL.
  GURL Resolve(const std::string& relative) const;
  GURL Resolve(const base::string16& relative) const;

  // Like Resolve() above but takes a character set encoder which will be used
  // for any query text specified in the input. The charset converter parameter
  // may be NULL, in which case it will be treated as UTF-8.
  //
  // TODO(brettw): These should be replaced with versions that take something
  // more friendly than a raw CharsetConverter (maybe like an ICU character set
  // name).
  GURL ResolveWithCharsetConverter(
      const std::string& relative,
      url::CharsetConverter* charset_converter) const;
  GURL ResolveWithCharsetConverter(
      const base::string16& relative,
      url::CharsetConverter* charset_converter) const;

  // Creates a new GURL by replacing the current URL's components with the
  // supplied versions. See the Replacements class in url_canon.h for more.
  //
  // These are not particularly quick, so avoid doing mutations when possible.
  // Prefer the 8-bit version when possible.
  //
  // It is an error to replace components of an invalid URL. The result will
  // be the empty URL.
  //
  // Note that we use the more general url::Replacements type to give
  // callers extra flexibility rather than our override.
  GURL ReplaceComponents(const url::Replacements<char>& replacements) const;
  GURL ReplaceComponents(
      const url::Replacements<base::char16>& replacements) const;

  // A helper function that is equivalent to replacing the path with a slash
  // and clearing out everything after that. We sometimes need to know just the
  // scheme and the authority. If this URL is not a standard URL (it doesn't
  // have the regular authority and path sections), then the result will be
  // an empty, invalid GURL. Note that this *does* work for file: URLs, which
  // some callers may want to filter out before calling this.
  //
  // It is an error to get an empty path on an invalid URL. The result
  // will be the empty URL.
  GURL GetWithEmptyPath() const;

  // A helper function to return a GURL containing just the scheme, host,
  // and port from a URL. Equivalent to clearing any username and password,
  // replacing the path with a slash, and clearing everything after that. If
  // this URL is not a standard URL, then the result will be an empty,
  // invalid GURL. If the URL has neither username nor password, this
  // degenerates to GetWithEmptyPath().
  //
  // It is an error to get the origin of an invalid URL. The result
  // will be the empty URL.
  GURL GetOrigin() const;

  // A helper function to return a GURL stripped from the elements that are not
  // supposed to be sent as HTTP referrer: username, password and ref fragment.
  // For invalid URLs or URLs that no valid referrers, an empty URL will be
  // returned.
  GURL GetAsReferrer() const;

  // Returns true if the scheme for the current URL is a known "standard"
  // scheme. Standard schemes have an authority and a path section. This
  // includes file: and filesystem:, which some callers may want to filter out
  // explicitly by calling SchemeIsFile[System].
  bool IsStandard() const;

  // Returns true if the given parameter (should be lower-case ASCII to match
  // the canonicalized scheme) is the scheme for this URL. This call is more
  // efficient than getting the scheme and comparing it because no copies or
  // object constructions are done.
  bool SchemeIs(const char* lower_ascii_scheme) const;

  // Returns true if the scheme is "http" or "https".
  bool SchemeIsHTTPOrHTTPS() const;

  // Returns true is the scheme is "ws" or "wss".
  bool SchemeIsWSOrWSS() const;

  // We often need to know if this is a file URL. File URLs are "standard", but
  // are often treated separately by some programs.
  bool SchemeIsFile() const {
    return SchemeIs(url::kFileScheme);
  }

  // FileSystem URLs need to be treated differently in some cases.
  bool SchemeIsFileSystem() const {
    return SchemeIs(url::kFileSystemScheme);
  }

  // If the scheme indicates a secure connection
  bool SchemeIsSecure() const {
    return SchemeIs(url::kHttpsScheme) || SchemeIs(url::kWssScheme) ||
        (SchemeIsFileSystem() && inner_url() && inner_url()->SchemeIsSecure());
  }

  // Returns true if the scheme is "blob".
  bool SchemeIsBlob() const {
    return SchemeIs(url::kBlobScheme);
  }

  // The "content" of the URL is everything after the scheme (skipping the
  // scheme delimiting colon). It is an error to get the origin of an invalid
  // URL. The result will be an empty string.
  std::string GetContent() const;

  // Returns true if the hostname is an IP address. Note: this function isn't
  // as cheap as a simple getter because it re-parses the hostname to verify.
  // This currently identifies only IPv4 addresses (bug 822685).
  bool HostIsIPAddress() const;

  // Getters for various components of the URL. The returned string will be
  // empty if the component is empty or is not present.
  std::string scheme() const {  // Not including the colon. See also SchemeIs.
    return ComponentString(parsed_.scheme);
  }
  std::string username() const {
    return ComponentString(parsed_.username);
  }
  std::string password() const {
    return ComponentString(parsed_.password);
  }
  // Note that this may be a hostname, an IPv4 address, or an IPv6 literal
  // surrounded by square brackets, like "[2001:db8::1]".  To exclude these
  // brackets, use HostNoBrackets() below.
  std::string host() const {
    return ComponentString(parsed_.host);
  }
  std::string port() const {  // Returns -1 if "default"
    return ComponentString(parsed_.port);
  }
  std::string path() const {  // Including first slash following host
    return ComponentString(parsed_.path);
  }
  std::string query() const {  // Stuff following '?'
    return ComponentString(parsed_.query);
  }
  std::string ref() const {  // Stuff following '#'
    return ComponentString(parsed_.ref);
  }

  // Existance querying. These functions will return true if the corresponding
  // URL component exists in this URL. Note that existance is different than
  // being nonempty. http://www.google.com/? has a query that just happens to
  // be empty, and has_query() will return true.
  bool has_scheme() const {
    return parsed_.scheme.len >= 0;
  }
  bool has_username() const {
    return parsed_.username.len >= 0;
  }
  bool has_password() const {
    return parsed_.password.len >= 0;
  }
  bool has_host() const {
    // Note that hosts are special, absense of host means length 0.
    return parsed_.host.len > 0;
  }
  bool has_port() const {
    return parsed_.port.len >= 0;
  }
  bool has_path() const {
    // Note that http://www.google.com/" has a path, the path is "/". This can
    // return false only for invalid or nonstandard URLs.
    return parsed_.path.len >= 0;
  }
  bool has_query() const {
    return parsed_.query.len >= 0;
  }
  bool has_ref() const {
    return parsed_.ref.len >= 0;
  }

  // Returns a parsed version of the port. Can also be any of the special
  // values defined in Parsed for ExtractPort.
  int IntPort() const;

  // Returns the port number of the url, or the default port number.
  // If the scheme has no concept of port (or unknown default) returns
  // PORT_UNSPECIFIED.
  int EffectiveIntPort() const;

  // Extracts the filename portion of the path and returns it. The filename
  // is everything after the last slash in the path. This may be empty.
  std::string ExtractFileName() const;

  // Returns the path that should be sent to the server. This is the path,
  // parameter, and query portions of the URL. It is guaranteed to be ASCII.
  std::string PathForRequest() const;

  // Returns the host, excluding the square brackets surrounding IPv6 address
  // literals.  This can be useful for passing to getaddrinfo().
  std::string HostNoBrackets() const;

  // Returns true if this URL's host matches or is in the same domain as
  // the given input string. For example if this URL was "www.google.com",
  // this would match "com", "google.com", and "www.google.com
  // (input domain should be lower-case ASCII to match the canonicalized
  // scheme). This call is more efficient than getting the host and check
  // whether host has the specific domain or not because no copies or
  // object constructions are done.
  //
  // If function DomainIs has parameter domain_len, which means the parameter
  // lower_ascii_domain does not gurantee to terminate with NULL character.
  bool DomainIs(const char* lower_ascii_domain, int domain_len) const;

  // If function DomainIs only has parameter lower_ascii_domain, which means
  // domain string should be terminate with NULL character.
  bool DomainIs(const char* lower_ascii_domain) const {
    return DomainIs(lower_ascii_domain,
                    static_cast<int>(strlen(lower_ascii_domain)));
  }

  // Swaps the contents of this GURL object with the argument without doing
  // any memory allocations.
  void Swap(GURL* other);

  // Returns a reference to a singleton empty GURL. This object is for callers
  // who return references but don't have anything to return in some cases.
  // This function may be called from any thread.
  static const GURL& EmptyGURL();

  // Returns the inner URL of a nested URL [currently only non-null for
  // filesystem: URLs].
  const GURL* inner_url() const {
    return inner_url_.get();
  }

 private:
  // Variant of the string parsing constructor that allows the caller to elect
  // retain trailing whitespace, if any, on the passed URL spec but only  if the
  // scheme is one that allows trailing whitespace. The primary use-case is
  // for data: URLs. In most cases, you want to use the single parameter
  // constructor above.
  enum RetainWhiteSpaceSelector { RETAIN_TRAILING_PATH_WHITEPACE };
  GURL(const std::string& url_string, RetainWhiteSpaceSelector);

  template<typename STR>
  void InitCanonical(const STR& input_spec, bool trim_path_end);

  void InitializeFromCanonicalSpec();

  // Returns the substring of the input identified by the given component.
  std::string ComponentString(const url::Component& comp) const {
    if (comp.len <= 0)
      return std::string();
    return std::string(spec_, comp.begin, comp.len);
  }

  // The actual text of the URL, in canonical ASCII form.
  std::string spec_;

  // Set when the given URL is valid. Otherwise, we may still have a spec and
  // components, but they may not identify valid resources (for example, an
  // invalid port number, invalid characters in the scheme, etc.).
  bool is_valid_;

  // Identified components of the canonical spec.
  url::Parsed parsed_;

  // Used for nested schemes [currently only filesystem:].
  scoped_ptr<GURL> inner_url_;

  // TODO bug 684583: Add encoding for query params.
};

// Stream operator so GURL can be used in assertion statements.
URL_EXPORT std::ostream& operator<<(std::ostream& out, const GURL& url);

#endif  // URL_GURL_H_

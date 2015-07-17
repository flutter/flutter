// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_SCHEME_HOST_PORT_H_
#define URL_SCHEME_HOST_PORT_H_

#include <string>

#include "base/basictypes.h"
#include "base/strings/string_piece.h"
#include "url/url_export.h"

class GURL;

namespace url {

// This class represents a (scheme, host, port) tuple extracted from a URL.
//
// The primary purpose of this class is to represent relevant network-authority
// information for a URL. It is _not_ an Origin, as described in RFC 6454. In
// particular, it is generally NOT the right thing to use for security
// decisions.
//
// Instead, this class is a mechanism for simplifying URLs with standard schemes
// (that is, those which follow the generic syntax of RFC 3986) down to the
// uniquely identifying information necessary for network fetches. This makes it
// suitable as a cache key for a collection of active connections, for instance.
// It may, however, be inappropriate to use as a cache key for persistent
// storage associated with a host.
//
// In particular, note that:
//
// * SchemeHostPort can only represent schemes which follow the RFC 3986 syntax
//   (e.g. those registered with GURL as "standard schemes"). Non-standard
//   schemes such as "blob", "filesystem", "data", and "javascript" can only be
//   represented as invalid SchemeHostPort objects.
//
// * The "file" scheme follows the standard syntax, but it is important to note
//   that the authority portion (host, port) is optional. URLs without an
//   authority portion will be represented with an empty string for the host,
//   and a port of 0 (e.g. "file:///etc/hosts" => ("file", "", 0)), and URLs
//   with a host-only authority portion will be represented with a port of 0
//   (e.g. "file://example.com/etc/hosts" => ("file", "example.com", 0)). See
//   Section 3 of RFC 3986 to better understand these constructs.
//
// * SchemeHostPort has no notion of the Origin concept (RFC 6454), and in
//   particular, it has no notion of a "unique" Origin. If you need to take
//   uniqueness into account (and, if you're making security-relevant decisions
//   then you absolutely do), please use 'url::Origin' instead[1].
//
// [1]: // TODO(mkwst): Land 'url::Origin'. :)
//
// Usage:
//
// * SchemeHostPort objects are commonly created from GURL objects:
//
//     GURL url("https://example.com/");
//     url::SchemeHostPort tuple(url);
//     tuple.scheme(); // "https"
//     tuple.host(); // "example.com"
//     tuple.port(); // 443
//
// * Objects may also be explicitly created and compared:
//
//     url::SchemeHostPort tuple(url::kHttpsScheme, "example.com", 443);
//     tuple.scheme(); // "https"
//     tuple.host(); // "example.com"
//     tuple.port(); // 443
//
//     GURL url("https://example.com/");
//     tuple.Equals(url::SchemeHostPort(url)); // true
class URL_EXPORT SchemeHostPort {
 public:
  // Creates an invalid (scheme, host, port) tuple, which represents an invalid
  // or non-standard URL.
  SchemeHostPort();

  // Creates a (scheme, host, port) tuple. |host| must be a canonicalized
  // A-label (that is, '☃.net' must be provided as 'xn--n3h.net'). |scheme|
  // must be a standard scheme. |port| must not be 0, unless |scheme| does not
  // support ports (e.g. 'file'). In that case, |port| must be 0.
  //
  // Copies the data in |scheme| and |host|.
  SchemeHostPort(base::StringPiece scheme, base::StringPiece host, uint16 port);

  // Creates a (scheme, host, port) tuple from |url|, as described at
  // https://tools.ietf.org/html/rfc6454#section-4
  //
  // If |url| is invalid or non-standard, the result will be an invalid
  // SchemeHostPort object.
  explicit SchemeHostPort(const GURL& url);

  ~SchemeHostPort();

  // Returns the host component, in URL form. That is all IDN domain names will
  // be expressed as A-Labels ('☃.net' will be returned as 'xn--n3h.net'), and
  // and all IPv6 addresses will be enclosed in brackets ("[2001:db8::1]").
  std::string host() const { return host_; }
  std::string scheme() const { return scheme_; }
  uint16 port() const { return port_; }
  bool IsInvalid() const;

  // Serializes the SchemeHostPort tuple to a canonical form.
  //
  // While this string form resembles the Origin serialization specified in
  // Section 6.2 of RFC 6454, it is important to note that invalid
  // SchemeHostPort tuples serialize to the empty string, rather than being
  // serialized as a unique Origin.
  std::string Serialize() const;

  // Two SchemeHostPort objects are "equal" iff their schemes, hosts, and ports
  // are exact matches.
  //
  // Note that this comparison is _not_ the same as an origin-based comparison.
  // In particular, invalid SchemeHostPort objects match each other (and
  // themselves). Unique origins, on the other hand, would not.
  bool Equals(const SchemeHostPort& other) const;

  // Allows SchemeHostPort to used as a key in STL (for example, a std::set or
  // std::map).
  bool operator<(const SchemeHostPort& other) const;

 private:
  std::string scheme_;
  std::string host_;
  uint16 port_;
};

}  // namespace url

#endif  // URL_SCHEME_HOST_PORT_H_

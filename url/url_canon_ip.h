// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_URL_CANON_IP_H_
#define URL_URL_CANON_IP_H_

#include "base/strings/string16.h"
#include "url/url_canon.h"
#include "url/url_export.h"
#include "url/url_parse.h"

namespace url {

// Writes the given IPv4 address to |output|.
URL_EXPORT void AppendIPv4Address(const unsigned char address[4],
                                  CanonOutput* output);

// Writes the given IPv6 address to |output|.
URL_EXPORT void AppendIPv6Address(const unsigned char address[16],
                                  CanonOutput* output);

// Searches the host name for the portions of the IPv4 address. On success,
// each component will be placed into |components| and it will return true.
// It will return false if the host can not be separated as an IPv4 address
// or if there are any non-7-bit characters or other characters that can not
// be in an IP address. (This is important so we fail as early as possible for
// common non-IP hostnames.)
//
// Not all components may exist. If there are only 3 components, for example,
// the last one will have a length of -1 or 0 to indicate it does not exist.
//
// Note that many platform's inet_addr will ignore everything after a space
// in certain curcumstances if the stuff before the space looks like an IP
// address. IE6 is included in this. We do NOT handle this case. In many cases,
// the browser's canonicalization will get run before this which converts
// spaces to %20 (in the case of IE7) or rejects them (in the case of
// Mozilla), so this code path never gets hit. Our host canonicalization will
// notice these spaces and escape them, which will make IP address finding
// fail. This seems like better behavior than stripping after a space.
URL_EXPORT bool FindIPv4Components(const char* spec,
                                   const Component& host,
                                   Component components[4]);
URL_EXPORT bool FindIPv4Components(const base::char16* spec,
                                   const Component& host,
                                   Component components[4]);

// Converts an IPv4 address to a 32-bit number (network byte order).
//
// Possible return values:
//   IPV4    - IPv4 address was successfully parsed.
//   BROKEN  - Input was formatted like an IPv4 address, but overflow occurred
//             during parsing.
//   NEUTRAL - Input couldn't possibly be interpreted as an IPv4 address.
//             It might be an IPv6 address, or a hostname.
//
// On success, |num_ipv4_components| will be populated with the number of
// components in the IPv4 address.
URL_EXPORT CanonHostInfo::Family IPv4AddressToNumber(const char* spec,
                                                     const Component& host,
                                                     unsigned char address[4],
                                                     int* num_ipv4_components);
URL_EXPORT CanonHostInfo::Family IPv4AddressToNumber(const base::char16* spec,
                                                     const Component& host,
                                                     unsigned char address[4],
                                                     int* num_ipv4_components);

// Converts an IPv6 address to a 128-bit number (network byte order), returning
// true on success. False means that the input was not a valid IPv6 address.
//
// NOTE that |host| is expected to be surrounded by square brackets.
// i.e. "[::1]" rather than "::1".
URL_EXPORT bool IPv6AddressToNumber(const char* spec,
                                    const Component& host,
                                    unsigned char address[16]);
URL_EXPORT bool IPv6AddressToNumber(const base::char16* spec,
                                    const Component& host,
                                    unsigned char address[16]);

}  // namespace url

#endif  // URL_URL_CANON_IP_H_

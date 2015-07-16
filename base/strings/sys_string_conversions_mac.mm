// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/sys_string_conversions.h"

#import <Foundation/Foundation.h>

#include <vector>

#include "base/mac/foundation_util.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/strings/string_piece.h"

namespace base {

namespace {

// Convert the supplied CFString into the specified encoding, and return it as
// an STL string of the template type.  Returns an empty string on failure.
//
// Do not assert in this function since it is used by the asssertion code!
template<typename StringType>
static StringType CFStringToSTLStringWithEncodingT(CFStringRef cfstring,
                                                   CFStringEncoding encoding) {
  CFIndex length = CFStringGetLength(cfstring);
  if (length == 0)
    return StringType();

  CFRange whole_string = CFRangeMake(0, length);
  CFIndex out_size;
  CFIndex converted = CFStringGetBytes(cfstring,
                                       whole_string,
                                       encoding,
                                       0,      // lossByte
                                       false,  // isExternalRepresentation
                                       NULL,   // buffer
                                       0,      // maxBufLen
                                       &out_size);
  if (converted == 0 || out_size == 0)
    return StringType();

  // out_size is the number of UInt8-sized units needed in the destination.
  // A buffer allocated as UInt8 units might not be properly aligned to
  // contain elements of StringType::value_type.  Use a container for the
  // proper value_type, and convert out_size by figuring the number of
  // value_type elements per UInt8.  Leave room for a NUL terminator.
  typename StringType::size_type elements =
      out_size * sizeof(UInt8) / sizeof(typename StringType::value_type) + 1;

  std::vector<typename StringType::value_type> out_buffer(elements);
  converted = CFStringGetBytes(cfstring,
                               whole_string,
                               encoding,
                               0,      // lossByte
                               false,  // isExternalRepresentation
                               reinterpret_cast<UInt8*>(&out_buffer[0]),
                               out_size,
                               NULL);  // usedBufLen
  if (converted == 0)
    return StringType();

  out_buffer[elements - 1] = '\0';
  return StringType(&out_buffer[0], elements - 1);
}

// Given an STL string |in| with an encoding specified by |in_encoding|,
// convert it to |out_encoding| and return it as an STL string of the
// |OutStringType| template type.  Returns an empty string on failure.
//
// Do not assert in this function since it is used by the asssertion code!
template<typename InStringType, typename OutStringType>
static OutStringType STLStringToSTLStringWithEncodingsT(
    const InStringType& in,
    CFStringEncoding in_encoding,
    CFStringEncoding out_encoding) {
  typename InStringType::size_type in_length = in.length();
  if (in_length == 0)
    return OutStringType();

  base::ScopedCFTypeRef<CFStringRef> cfstring(CFStringCreateWithBytesNoCopy(
      NULL,
      reinterpret_cast<const UInt8*>(in.data()),
      in_length * sizeof(typename InStringType::value_type),
      in_encoding,
      false,
      kCFAllocatorNull));
  if (!cfstring)
    return OutStringType();

  return CFStringToSTLStringWithEncodingT<OutStringType>(cfstring,
                                                         out_encoding);
}

// Given an STL string |in| with an encoding specified by |in_encoding|,
// return it as a CFStringRef.  Returns NULL on failure.
template<typename StringType>
static CFStringRef STLStringToCFStringWithEncodingsT(
    const StringType& in,
    CFStringEncoding in_encoding) {
  typename StringType::size_type in_length = in.length();
  if (in_length == 0)
    return CFSTR("");

  return CFStringCreateWithBytes(kCFAllocatorDefault,
                                 reinterpret_cast<const UInt8*>(in.data()),
                                 in_length *
                                   sizeof(typename StringType::value_type),
                                 in_encoding,
                                 false);
}

// Specify the byte ordering explicitly, otherwise CFString will be confused
// when strings don't carry BOMs, as they typically won't.
static const CFStringEncoding kNarrowStringEncoding = kCFStringEncodingUTF8;
#ifdef __BIG_ENDIAN__
static const CFStringEncoding kMediumStringEncoding = kCFStringEncodingUTF16BE;
static const CFStringEncoding kWideStringEncoding = kCFStringEncodingUTF32BE;
#elif defined(__LITTLE_ENDIAN__)
static const CFStringEncoding kMediumStringEncoding = kCFStringEncodingUTF16LE;
static const CFStringEncoding kWideStringEncoding = kCFStringEncodingUTF32LE;
#endif  // __LITTLE_ENDIAN__

}  // namespace

// Do not assert in this function since it is used by the asssertion code!
std::string SysWideToUTF8(const std::wstring& wide) {
  return STLStringToSTLStringWithEncodingsT<std::wstring, std::string>(
      wide, kWideStringEncoding, kNarrowStringEncoding);
}

// Do not assert in this function since it is used by the asssertion code!
std::wstring SysUTF8ToWide(const StringPiece& utf8) {
  return STLStringToSTLStringWithEncodingsT<StringPiece, std::wstring>(
      utf8, kNarrowStringEncoding, kWideStringEncoding);
}

std::string SysWideToNativeMB(const std::wstring& wide) {
  return SysWideToUTF8(wide);
}

std::wstring SysNativeMBToWide(const StringPiece& native_mb) {
  return SysUTF8ToWide(native_mb);
}

CFStringRef SysUTF8ToCFStringRef(const std::string& utf8) {
  return STLStringToCFStringWithEncodingsT(utf8, kNarrowStringEncoding);
}

CFStringRef SysUTF16ToCFStringRef(const string16& utf16) {
  return STLStringToCFStringWithEncodingsT(utf16, kMediumStringEncoding);
}

NSString* SysUTF8ToNSString(const std::string& utf8) {
  return (NSString*)base::mac::CFTypeRefToNSObjectAutorelease(
      SysUTF8ToCFStringRef(utf8));
}

NSString* SysUTF16ToNSString(const string16& utf16) {
  return (NSString*)base::mac::CFTypeRefToNSObjectAutorelease(
      SysUTF16ToCFStringRef(utf16));
}

std::string SysCFStringRefToUTF8(CFStringRef ref) {
  return CFStringToSTLStringWithEncodingT<std::string>(ref,
                                                       kNarrowStringEncoding);
}

string16 SysCFStringRefToUTF16(CFStringRef ref) {
  return CFStringToSTLStringWithEncodingT<string16>(ref,
                                                    kMediumStringEncoding);
}

std::string SysNSStringToUTF8(NSString* nsstring) {
  if (!nsstring)
    return std::string();
  return SysCFStringRefToUTF8(reinterpret_cast<CFStringRef>(nsstring));
}

string16 SysNSStringToUTF16(NSString* nsstring) {
  if (!nsstring)
    return string16();
  return SysCFStringRefToUTF16(reinterpret_cast<CFStringRef>(nsstring));
}

}  // namespace base

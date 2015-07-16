// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_FOUNDATION_UTIL_H_
#define BASE_MAC_FOUNDATION_UTIL_H_

#include <CoreFoundation/CoreFoundation.h>

#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/logging.h"
#include "base/mac/scoped_cftyperef.h"

#if defined(__OBJC__)
#import <Foundation/Foundation.h>
@class NSFont;
@class UIFont;
#else  // __OBJC__
#include <CoreFoundation/CoreFoundation.h>
class NSBundle;
class NSFont;
class NSString;
class UIFont;
#endif  // __OBJC__

#if defined(OS_IOS)
#include <CoreText/CoreText.h>
#else
#include <ApplicationServices/ApplicationServices.h>
#endif

// Adapted from NSObjCRuntime.h NS_ENUM definition (used in Foundation starting
// with the OS X 10.8 SDK and the iOS 6.0 SDK).
#if __has_extension(cxx_strong_enums) && \
    (defined(OS_IOS) || (defined(MAC_OS_X_VERSION_10_8) && \
                         MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8))
#define CR_FORWARD_ENUM(_type, _name) enum _name : _type _name
#else
#define CR_FORWARD_ENUM(_type, _name) _type _name
#endif

// Adapted from NSPathUtilities.h and NSObjCRuntime.h.
#if __LP64__ || NS_BUILD_32_LIKE_64
typedef CR_FORWARD_ENUM(unsigned long, NSSearchPathDirectory);
typedef unsigned long NSSearchPathDomainMask;
#else
typedef CR_FORWARD_ENUM(unsigned int, NSSearchPathDirectory);
typedef unsigned int NSSearchPathDomainMask;
#endif

typedef struct OpaqueSecTrustRef* SecACLRef;
typedef struct OpaqueSecTrustedApplicationRef* SecTrustedApplicationRef;

namespace base {

class FilePath;

namespace mac {

// Returns true if the application is running from a bundle
BASE_EXPORT bool AmIBundled();
BASE_EXPORT void SetOverrideAmIBundled(bool value);

#if defined(UNIT_TEST)
// This is required because instantiating some tests requires checking the
// directory structure, which sets the AmIBundled cache state. Individual tests
// may or may not be bundled, and this would trip them up if the cache weren't
// cleared. This should not be called from individual tests, just from test
// instantiation code that gets a path from PathService.
BASE_EXPORT void ClearAmIBundledCache();
#endif

// Returns true if this process is marked as a "Background only process".
BASE_EXPORT bool IsBackgroundOnlyProcess();

// Returns the path to a resource within the framework bundle.
BASE_EXPORT FilePath PathForFrameworkBundleResource(CFStringRef resourceName);

// Returns the creator code associated with the CFBundleRef at bundle.
OSType CreatorCodeForCFBundleRef(CFBundleRef bundle);

// Returns the creator code associated with this application, by calling
// CreatorCodeForCFBundleRef for the application's main bundle.  If this
// information cannot be determined, returns kUnknownType ('????').  This
// does not respect the override app bundle because it's based on CFBundle
// instead of NSBundle, and because callers probably don't want the override
// app bundle's creator code anyway.
BASE_EXPORT OSType CreatorCodeForApplication();

// Searches for directories for the given key in only the given |domain_mask|.
// If found, fills result (which must always be non-NULL) with the
// first found directory and returns true.  Otherwise, returns false.
BASE_EXPORT bool GetSearchPathDirectory(NSSearchPathDirectory directory,
                                        NSSearchPathDomainMask domain_mask,
                                        FilePath* result);

// Searches for directories for the given key in only the local domain.
// If found, fills result (which must always be non-NULL) with the
// first found directory and returns true.  Otherwise, returns false.
BASE_EXPORT bool GetLocalDirectory(NSSearchPathDirectory directory,
                                   FilePath* result);

// Searches for directories for the given key in only the user domain.
// If found, fills result (which must always be non-NULL) with the
// first found directory and returns true.  Otherwise, returns false.
BASE_EXPORT bool GetUserDirectory(NSSearchPathDirectory directory,
                                  FilePath* result);

// Returns the ~/Library directory.
BASE_EXPORT FilePath GetUserLibraryPath();

// Takes a path to an (executable) binary and tries to provide the path to an
// application bundle containing it. It takes the outermost bundle that it can
// find (so for "/Foo/Bar.app/.../Baz.app/..." it produces "/Foo/Bar.app").
//   |exec_name| - path to the binary
//   returns - path to the application bundle, or empty on error
BASE_EXPORT FilePath GetAppBundlePath(const FilePath& exec_name);

#define TYPE_NAME_FOR_CF_TYPE_DECL(TypeCF) \
BASE_EXPORT std::string TypeNameForCFType(TypeCF##Ref);

TYPE_NAME_FOR_CF_TYPE_DECL(CFArray);
TYPE_NAME_FOR_CF_TYPE_DECL(CFBag);
TYPE_NAME_FOR_CF_TYPE_DECL(CFBoolean);
TYPE_NAME_FOR_CF_TYPE_DECL(CFData);
TYPE_NAME_FOR_CF_TYPE_DECL(CFDate);
TYPE_NAME_FOR_CF_TYPE_DECL(CFDictionary);
TYPE_NAME_FOR_CF_TYPE_DECL(CFNull);
TYPE_NAME_FOR_CF_TYPE_DECL(CFNumber);
TYPE_NAME_FOR_CF_TYPE_DECL(CFSet);
TYPE_NAME_FOR_CF_TYPE_DECL(CFString);
TYPE_NAME_FOR_CF_TYPE_DECL(CFURL);
TYPE_NAME_FOR_CF_TYPE_DECL(CFUUID);

TYPE_NAME_FOR_CF_TYPE_DECL(CGColor);

TYPE_NAME_FOR_CF_TYPE_DECL(CTFont);
TYPE_NAME_FOR_CF_TYPE_DECL(CTRun);

#undef TYPE_NAME_FOR_CF_TYPE_DECL

// Retain/release calls for memory management in C++.
BASE_EXPORT void NSObjectRetain(void* obj);
BASE_EXPORT void NSObjectRelease(void* obj);

// CFTypeRefToNSObjectAutorelease transfers ownership of a Core Foundation
// object (one derived from CFTypeRef) to the Foundation memory management
// system.  In a traditional managed-memory environment, cf_object is
// autoreleased and returned as an NSObject.  In a garbage-collected
// environment, cf_object is marked as eligible for garbage collection.
//
// This function should only be used to convert a concrete CFTypeRef type to
// its equivalent "toll-free bridged" NSObject subclass, for example,
// converting a CFStringRef to NSString.
//
// By calling this function, callers relinquish any ownership claim to
// cf_object.  In a managed-memory environment, the object's ownership will be
// managed by the innermost NSAutoreleasePool, so after this function returns,
// callers should not assume that cf_object is valid any longer than the
// returned NSObject.
//
// Returns an id, typed here for C++'s sake as a void*.
BASE_EXPORT void* CFTypeRefToNSObjectAutorelease(CFTypeRef cf_object);

// Returns the base bundle ID, which can be set by SetBaseBundleID but
// defaults to a reasonable string. This never returns NULL. BaseBundleID
// returns a pointer to static storage that must not be freed.
BASE_EXPORT const char* BaseBundleID();

// Sets the base bundle ID to override the default. The implementation will
// make its own copy of new_base_bundle_id.
BASE_EXPORT void SetBaseBundleID(const char* new_base_bundle_id);

}  // namespace mac
}  // namespace base

#if !defined(__OBJC__)
#define OBJC_CPP_CLASS_DECL(x) class x;
#else  // __OBJC__
#define OBJC_CPP_CLASS_DECL(x)
#endif  // __OBJC__

// Convert toll-free bridged CFTypes to NSTypes and vice-versa. This does not
// autorelease |cf_val|. This is useful for the case where there is a CFType in
// a call that expects an NSType and the compiler is complaining about const
// casting problems.
// The calls are used like this:
// NSString *foo = CFToNSCast(CFSTR("Hello"));
// CFStringRef foo2 = NSToCFCast(@"Hello");
// The macro magic below is to enforce safe casting. It could possibly have
// been done using template function specialization, but template function
// specialization doesn't always work intuitively,
// (http://www.gotw.ca/publications/mill17.htm) so the trusty combination
// of macros and function overloading is used instead.

#define CF_TO_NS_CAST_DECL(TypeCF, TypeNS) \
OBJC_CPP_CLASS_DECL(TypeNS) \
\
namespace base { \
namespace mac { \
BASE_EXPORT TypeNS* CFToNSCast(TypeCF##Ref cf_val); \
BASE_EXPORT TypeCF##Ref NSToCFCast(TypeNS* ns_val); \
} \
}

#define CF_TO_NS_MUTABLE_CAST_DECL(name) \
CF_TO_NS_CAST_DECL(CF##name, NS##name) \
OBJC_CPP_CLASS_DECL(NSMutable##name) \
\
namespace base { \
namespace mac { \
BASE_EXPORT NSMutable##name* CFToNSCast(CFMutable##name##Ref cf_val); \
BASE_EXPORT CFMutable##name##Ref NSToCFCast(NSMutable##name* ns_val); \
} \
}

// List of toll-free bridged types taken from:
// http://www.cocoadev.com/index.pl?TollFreeBridged

CF_TO_NS_MUTABLE_CAST_DECL(Array);
CF_TO_NS_MUTABLE_CAST_DECL(AttributedString);
CF_TO_NS_CAST_DECL(CFCalendar, NSCalendar);
CF_TO_NS_MUTABLE_CAST_DECL(CharacterSet);
CF_TO_NS_MUTABLE_CAST_DECL(Data);
CF_TO_NS_CAST_DECL(CFDate, NSDate);
CF_TO_NS_MUTABLE_CAST_DECL(Dictionary);
CF_TO_NS_CAST_DECL(CFError, NSError);
CF_TO_NS_CAST_DECL(CFLocale, NSLocale);
CF_TO_NS_CAST_DECL(CFNumber, NSNumber);
CF_TO_NS_CAST_DECL(CFRunLoopTimer, NSTimer);
CF_TO_NS_CAST_DECL(CFTimeZone, NSTimeZone);
CF_TO_NS_MUTABLE_CAST_DECL(Set);
CF_TO_NS_CAST_DECL(CFReadStream, NSInputStream);
CF_TO_NS_CAST_DECL(CFWriteStream, NSOutputStream);
CF_TO_NS_MUTABLE_CAST_DECL(String);
CF_TO_NS_CAST_DECL(CFURL, NSURL);

#if defined(OS_IOS)
CF_TO_NS_CAST_DECL(CTFont, UIFont);
#else
CF_TO_NS_CAST_DECL(CTFont, NSFont);
#endif

#undef CF_TO_NS_CAST_DECL
#undef CF_TO_NS_MUTABLE_CAST_DECL
#undef OBJC_CPP_CLASS_DECL

namespace base {
namespace mac {

// CFCast<>() and CFCastStrict<>() cast a basic CFTypeRef to a more
// specific CoreFoundation type. The compatibility of the passed
// object is found by comparing its opaque type against the
// requested type identifier. If the supplied object is not
// compatible with the requested return type, CFCast<>() returns
// NULL and CFCastStrict<>() will DCHECK. Providing a NULL pointer
// to either variant results in NULL being returned without
// triggering any DCHECK.
//
// Example usage:
// CFNumberRef some_number = base::mac::CFCast<CFNumberRef>(
//     CFArrayGetValueAtIndex(array, index));
//
// CFTypeRef hello = CFSTR("hello world");
// CFStringRef some_string = base::mac::CFCastStrict<CFStringRef>(hello);

template<typename T>
T CFCast(const CFTypeRef& cf_val);

template<typename T>
T CFCastStrict(const CFTypeRef& cf_val);

#define CF_CAST_DECL(TypeCF) \
template<> BASE_EXPORT TypeCF##Ref \
CFCast<TypeCF##Ref>(const CFTypeRef& cf_val);\
\
template<> BASE_EXPORT TypeCF##Ref \
CFCastStrict<TypeCF##Ref>(const CFTypeRef& cf_val);

CF_CAST_DECL(CFArray);
CF_CAST_DECL(CFBag);
CF_CAST_DECL(CFBoolean);
CF_CAST_DECL(CFData);
CF_CAST_DECL(CFDate);
CF_CAST_DECL(CFDictionary);
CF_CAST_DECL(CFNull);
CF_CAST_DECL(CFNumber);
CF_CAST_DECL(CFSet);
CF_CAST_DECL(CFString);
CF_CAST_DECL(CFURL);
CF_CAST_DECL(CFUUID);

CF_CAST_DECL(CGColor);

CF_CAST_DECL(CTFont);
CF_CAST_DECL(CTFontDescriptor);
CF_CAST_DECL(CTRun);

CF_CAST_DECL(SecACL);
CF_CAST_DECL(SecTrustedApplication);

#undef CF_CAST_DECL

#if defined(__OBJC__)

// ObjCCast<>() and ObjCCastStrict<>() cast a basic id to a more
// specific (NSObject-derived) type. The compatibility of the passed
// object is found by checking if it's a kind of the requested type
// identifier. If the supplied object is not compatible with the
// requested return type, ObjCCast<>() returns nil and
// ObjCCastStrict<>() will DCHECK. Providing a nil pointer to either
// variant results in nil being returned without triggering any DCHECK.
//
// The strict variant is useful when retrieving a value from a
// collection which only has values of a specific type, e.g. an
// NSArray of NSStrings. The non-strict variant is useful when
// retrieving values from data that you can't fully control. For
// example, a plist read from disk may be beyond your exclusive
// control, so you'd only want to check that the values you retrieve
// from it are of the expected types, but not crash if they're not.
//
// Example usage:
// NSString* version = base::mac::ObjCCast<NSString>(
//     [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
//
// NSString* str = base::mac::ObjCCastStrict<NSString>(
//     [ns_arr_of_ns_strs objectAtIndex:0]);
template<typename T>
T* ObjCCast(id objc_val) {
  if ([objc_val isKindOfClass:[T class]]) {
    return reinterpret_cast<T*>(objc_val);
  }
  return nil;
}

template<typename T>
T* ObjCCastStrict(id objc_val) {
  T* rv = ObjCCast<T>(objc_val);
  DCHECK(objc_val == nil || rv);
  return rv;
}

#endif  // defined(__OBJC__)

// Helper function for GetValueFromDictionary to create the error message
// that appears when a type mismatch is encountered.
BASE_EXPORT std::string GetValueFromDictionaryErrorMessage(
    CFStringRef key, const std::string& expected_type, CFTypeRef value);

// Utility function to pull out a value from a dictionary, check its type, and
// return it. Returns NULL if the key is not present or of the wrong type.
template<typename T>
T GetValueFromDictionary(CFDictionaryRef dict, CFStringRef key) {
  CFTypeRef value = CFDictionaryGetValue(dict, key);
  T value_specific = CFCast<T>(value);

  if (value && !value_specific) {
    std::string expected_type = TypeNameForCFType(value_specific);
    DLOG(WARNING) << GetValueFromDictionaryErrorMessage(key,
                                                        expected_type,
                                                        value);
  }

  return value_specific;
}

// Converts |path| to an autoreleased NSString. Returns nil if |path| is empty.
BASE_EXPORT NSString* FilePathToNSString(const FilePath& path);

// Converts |str| to a FilePath. Returns an empty path if |str| is nil.
BASE_EXPORT FilePath NSStringToFilePath(NSString* str);

}  // namespace mac
}  // namespace base

// Stream operations for CFTypes. They can be used with NSTypes as well
// by using the NSToCFCast methods above.
// e.g. LOG(INFO) << base::mac::NSToCFCast(@"foo");
// Operator << can not be overloaded for ObjectiveC types as the compiler
// can not distinguish between overloads for id with overloads for void*.
BASE_EXPORT extern std::ostream& operator<<(std::ostream& o,
                                            const CFErrorRef err);
BASE_EXPORT extern std::ostream& operator<<(std::ostream& o,
                                            const CFStringRef str);

#endif  // BASE_MAC_FOUNDATION_UTIL_H_

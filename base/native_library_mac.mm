// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/native_library.h"

#include <dlfcn.h>
#include <mach-o/getsect.h>

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "base/threading/thread_restrictions.h"

namespace base {

static NativeLibraryObjCStatus GetObjCStatusForImage(
    const void* function_pointer) {
  Dl_info info;
  if (!dladdr(function_pointer, &info))
    return OBJC_UNKNOWN;

  // See if the the image contains an "ObjC image info" segment. This method
  // of testing is used in _CFBundleGrokObjcImageInfoFromFile in
  // CF-744/CFBundle.c, around lines 2447-2474.
  //
  // In 32-bit images, ObjC can be recognized in __OBJC,__image_info, whereas
  // in 64-bit, the data is in __DATA,__objc_imageinfo.
#if __LP64__
  const section_64* section = getsectbynamefromheader_64(
      reinterpret_cast<const struct mach_header_64*>(info.dli_fbase),
      SEG_DATA, "__objc_imageinfo");
#else
  const section* section = getsectbynamefromheader(
      reinterpret_cast<const struct mach_header*>(info.dli_fbase),
      SEG_OBJC, "__image_info");
#endif
  return section == NULL ? OBJC_NOT_PRESENT : OBJC_PRESENT;
}

std::string NativeLibraryLoadError::ToString() const {
  return message;
}

// static
NativeLibrary LoadNativeLibrary(const base::FilePath& library_path,
                                NativeLibraryLoadError* error) {
  // dlopen() etc. open the file off disk.
  if (library_path.Extension() == "dylib" || !DirectoryExists(library_path)) {
    void* dylib = dlopen(library_path.value().c_str(), RTLD_LAZY);
    if (!dylib) {
      error->message = dlerror();
      return NULL;
    }
    NativeLibrary native_lib = new NativeLibraryStruct();
    native_lib->type = DYNAMIC_LIB;
    native_lib->dylib = dylib;
    native_lib->objc_status = OBJC_UNKNOWN;
    return native_lib;
  }
  base::ScopedCFTypeRef<CFURLRef> url(CFURLCreateFromFileSystemRepresentation(
      kCFAllocatorDefault,
      (const UInt8*)library_path.value().c_str(),
      library_path.value().length(),
      true));
  if (!url)
    return NULL;
  CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, url.get());
  if (!bundle)
    return NULL;

  NativeLibrary native_lib = new NativeLibraryStruct();
  native_lib->type = BUNDLE;
  native_lib->bundle = bundle;
  native_lib->bundle_resource_ref = CFBundleOpenBundleResourceMap(bundle);
  native_lib->objc_status = OBJC_UNKNOWN;
  return native_lib;
}

// static
void UnloadNativeLibrary(NativeLibrary library) {
  if (library->objc_status == OBJC_NOT_PRESENT) {
    if (library->type == BUNDLE) {
      CFBundleCloseBundleResourceMap(library->bundle,
                                     library->bundle_resource_ref);
      CFRelease(library->bundle);
    } else {
      dlclose(library->dylib);
    }
  } else {
    VLOG(2) << "Not unloading NativeLibrary because it may contain an ObjC "
               "segment. library->objc_status = " << library->objc_status;
    // Deliberately do not CFRelease the bundle or dlclose the dylib because
    // doing so can corrupt the ObjC runtime method caches. See
    // http://crbug.com/172319 for details.
  }
  delete library;
}

// static
void* GetFunctionPointerFromNativeLibrary(NativeLibrary library,
                                          const char* name) {
  void* function_pointer = NULL;

  // Get the function pointer using the right API for the type.
  if (library->type == BUNDLE) {
    base::ScopedCFTypeRef<CFStringRef> symbol_name(CFStringCreateWithCString(
        kCFAllocatorDefault, name, kCFStringEncodingUTF8));
    function_pointer = CFBundleGetFunctionPointerForName(library->bundle,
                                                         symbol_name);
  } else {
    function_pointer = dlsym(library->dylib, name);
  }

  // If this library hasn't been tested for having ObjC, use the function
  // pointer to look up the section information for the library.
  if (function_pointer && library->objc_status == OBJC_UNKNOWN)
    library->objc_status = GetObjCStatusForImage(function_pointer);

  return function_pointer;
}

// static
string16 GetNativeLibraryName(const string16& name) {
  return name + ASCIIToUTF16(".dylib");
}

}  // namespace base

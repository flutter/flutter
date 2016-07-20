/*
 * Copyright (c) 2016, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

#include "sky/engine/platform/fonts/FontCache.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "base/mac/scoped_nsobject.h"
#include "base/lazy_instance.h"
#include "base/macros.h"
#include "base/logging.h"

namespace blink {

template <class T>
class CFRef {
 public:
  CFRef() : _ref(nullptr) {}

  CFRef(T t) : _ref(t) {}

  CFRef(const CFRef&) = delete;

  void operator=(const CFRef&) = delete;

  CFRef(CFRef&& o) : _ref(o._ref) { o._ref = nullptr; }

  void operator=(CFRef&& o) {
    _ref = o._ref;
    o._ref = nullptr;
  }

  operator bool() const { return _ref != nullptr; }

  T get() const { return _ref; }

  ~CFRef() {
    if (_ref != nullptr) {
      CFRelease(reinterpret_cast<CFTypeRef>(_ref));
    }
  }

 private:
  T _ref;
};

class FontFallbackSelector {
 public:
  FontFallbackSelector() {
    base::mac::ScopedNSAutoreleasePool pool;

    UIFontDescriptor* ui_desc =
        [UIFont systemFontOfSize:[UIFont systemFontSize]].fontDescriptor;

    CFRef<CTFontDescriptorRef> desc(CTFontDescriptorCreateWithNameAndSize(
        reinterpret_cast<CFStringRef>(ui_desc.postscriptName),
        ui_desc.pointSize));

    if (!desc) {
      return;
    }

    _prototype = CFRef<CTFontRef>{
        CTFontCreateWithFontDescriptor(desc.get(), ui_desc.pointSize, nullptr)};
  }

  CFRef<CTFontDescriptorRef> fallbackFont(UChar32 codepoint) {
    if (!_prototype) {
      return {};
    }

    base::mac::ScopedNSAutoreleasePool pool;

    codepoint = CFSwapInt32HostToLittle(codepoint);

    CFRef<CFStringRef> unicode_string(CFStringCreateWithBytes(
        kCFAllocatorDefault,                         // allocator
        reinterpret_cast<const UInt8*>(&codepoint),  // buffer
        sizeof(codepoint),                           // size
        kCFStringEncodingUTF32LE,                    // excoding
        false                                        // external representation
        ));

    if (!unicode_string) {
      return {};
    }

    CFRef<CTFontRef> font(CTFontCreateForString(
        _prototype.get(), unicode_string.get(),
        CFRangeMake(0, CFStringGetLength(unicode_string.get()))));

    if (!font) {
      return {};
    }

    return CTFontCopyFontDescriptor(font.get());
  }

 private:
  CFRef<CTFontRef> _prototype;

  DISALLOW_COPY_AND_ASSIGN(FontFallbackSelector);
};

static base::LazyInstance<FontFallbackSelector> g_fallback_selector =
    LAZY_INSTANCE_INITIALIZER;

void FontCache::getFontForCharacter(
    UChar32 c,
    const char*,
    FontCache::PlatformFallbackFont* fallbackFont) {
  if (fallbackFont == nullptr) {
    return;
  }

  base::mac::ScopedNSAutoreleasePool pool;

  fallbackFont->name = "";
  fallbackFont->filename = "";
  fallbackFont->ttcIndex = 0;
  fallbackFont->fontconfigInterfaceId = 0;
  fallbackFont->isBold = false;
  fallbackFont->isItalic = false;

  CFRef<CTFontDescriptorRef> font =
      g_fallback_selector.Pointer()->fallbackFont(c);

  if (!font) {
    return;
  }

  CFRef<CFURLRef> cf_url(reinterpret_cast<CFURLRef>(
      CTFontDescriptorCopyAttribute(font.get(), kCTFontURLAttribute)));

  if (!cf_url) {
    return;
  }

  CFRef<CFURLRef> cf_absolute_url(CFURLCopyAbsoluteURL(cf_url.get()));

  if (!cf_absolute_url) {
    return;
  }

  const NSURL* url = reinterpret_cast<const NSURL*>(cf_absolute_url.get());

  fallbackFont->filename = [url fileSystemRepresentation];

  CFRef<CFStringRef> cf_name(reinterpret_cast<CFStringRef>(
      CTFontDescriptorCopyAttribute(font.get(), kCTFontNameAttribute)));

  if (!cf_name) {
    return;
  }

  const NSString* name = reinterpret_cast<const NSString*>(cf_name.get());
  fallbackFont->name = [name UTF8String];
}

}  // namespace  blink

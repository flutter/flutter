// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/platform/fonts/fuchsia/FontCacheFuchsia.h"

#include <limits>
#include <magenta/process.h>
#include <magenta/syscalls.h>
#include <utility>

#include "flutter/sky/engine/platform/fonts/AlternateFontFamily.h"
#include "flutter/sky/engine/platform/fonts/FontCache.h"
#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "lib/ftl/logging.h"
#include "mojo/services/ui/fonts/interfaces/font_provider.mojom.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "third_party/skia/include/ports/SkFontMgr.h"

namespace blink {
namespace {

uint32_t ToMojoWeight(FontWeight weight) {
  switch (weight) {
    case FontWeight100:
      return 100;
    case FontWeight200:
      return 200;
    case FontWeight300:
      return 300;
    case FontWeight400:
      return 400;
    case FontWeight500:
      return 500;
    case FontWeight600:
      return 600;
    case FontWeight700:
      return 700;
    case FontWeight800:
      return 800;
    case FontWeight900:
      return 900;
  }
  ASSERT_NOT_REACHED();
  return 400;
}

mojo::FontSlant ToMojoSlant(FontStyle style) {
  switch (style) {
    case FontStyleNormal:
      return mojo::FontSlant::UPRIGHT;
    case FontStyleItalic:
      return mojo::FontSlant::ITALIC;
  }
  ASSERT_NOT_REACHED();
  return mojo::FontSlant::UPRIGHT;
}

void UnmapMemory(const void* buffer, void* context) {
  mx_process_unmap_vm(mx_process_self(), reinterpret_cast<uintptr_t>(buffer),
                      0);
}

sk_sp<SkData> MakeSkDataFromVMO(mx_handle_t vmo) {
  uint64_t size = 0;
  mx_status_t status = mx_vmo_get_size(vmo, &size);
  if (status != NO_ERROR || size > std::numeric_limits<mx_size_t>::max())
    return nullptr;
  uintptr_t buffer = 0;
  status = mx_process_map_vm(mx_process_self(), vmo, 0, size, &buffer,
                             MX_VM_FLAG_PERM_READ);
  if (status != NO_ERROR)
    return nullptr;
  return SkData::MakeWithProc(reinterpret_cast<void*>(buffer), size,
                              UnmapMemory, nullptr);
}

mojo::FontProviderPtr* g_font_provider = nullptr;

mojo::FontProviderPtr& GetFontProvider() {
  FTL_CHECK(g_font_provider);
  return *g_font_provider;
}

}  // namespace

void SetFontProvider(mojo::FontProviderPtr provider) {
  FTL_CHECK(!g_font_provider);
  g_font_provider = new mojo::FontProviderPtr;
  *g_font_provider = std::move(provider);
}

void FontCache::getFontForCharacter(UChar32 c,
                                    const char* preferredLocale,
                                    PlatformFallbackFont* font) {}

sk_sp<SkTypeface> FontCache::createTypeface(
    const FontDescription& fontDescription,
    const FontFaceCreationParams& creationParams,
    CString& name) {
  AtomicString family = creationParams.family();

  if (family.isEmpty()) {
    name = getFallbackFontFamily(fontDescription).string().utf8();
  } else {
    name = family.utf8();
  }

  auto request = mojo::FontRequest::New();
  request->family = name.data();
  request->weight = ToMojoWeight(fontDescription.weight());
  request->width = static_cast<uint32_t>(fontDescription.stretch());
  request->slant = ToMojoSlant(fontDescription.style());

  mojo::FontResponsePtr response;
  auto& font_provider = GetFontProvider();
  font_provider->GetFont(
      std::move(request),
      [&response](mojo::FontResponsePtr r) { response = std::move(r); });
  font_provider.WaitForIncomingResponse();

  if (!response)
    return nullptr;

  sk_sp<SkData> data = MakeSkDataFromVMO(
      static_cast<mx_handle_t>(response->data->vmo.get().value()));
  if (!data)
    return nullptr;

  return sk_sp<SkTypeface>(SkFontMgr::RefDefault()->createFromData(data.get()));
}

}  // namespace blink

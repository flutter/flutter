// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fuchsia_font_manager.h"

#include <lib/fit/function.h>
#include <lib/zx/vmar.h>

#include <unordered_map>

#include "flutter/fml/trace_event.h"
#include "logging.h"
#include "runtime/dart/utils/inlines.h"
#include "runtime/dart/utils/vmo.h"
#include "third_party/icu/source/common/unicode/uchar.h"

namespace txt {

namespace {

constexpr char kDefaultFontFamily[] = "Roboto";

void UnmapMemory(const void* buffer, uint64_t size) {
  static_assert(sizeof(void*) == sizeof(uint64_t), "pointers aren't 64-bit");
  zx::vmar::root_self()->unmap(reinterpret_cast<uintptr_t>(buffer), size);
}

struct ReleaseSkDataContext {
  uint64_t buffer_size;
  int buffer_id;
  fit::function<void()> release_proc;

  ReleaseSkDataContext(uint64_t buffer_size,
                       int buffer_id,
                       fit::function<void()> release_proc)
      : buffer_size(buffer_size),
        buffer_id(buffer_id),
        release_proc(std::move(release_proc)) {}
};

void ReleaseSkData(const void* buffer, void* context) {
  auto skdata_context = reinterpret_cast<ReleaseSkDataContext*>(context);
  DEBUG_CHECK(skdata_context != nullptr, LOG_TAG, "");
  UnmapMemory(buffer, skdata_context->buffer_size);
  skdata_context->release_proc();
  delete skdata_context;
}

sk_sp<SkData> MakeSkDataFromBuffer(const fuchsia::mem::Buffer& data,
                                   int buffer_id,
                                   fit::function<void()> release_proc) {
  bool is_valid;
  zx_status_t status = dart_utils::IsSizeValid(data, &is_valid);
  if (!is_valid || data.size > std::numeric_limits<size_t>::max()) {
    return nullptr;
  }
  uint64_t size = data.size;
  uintptr_t buffer = 0;
  status = zx::vmar::root_self()->map(0, data.vmo, 0, size, ZX_VM_PERM_READ,
                                      &buffer);
  if (status != ZX_OK)
    return nullptr;
  auto context =
      new ReleaseSkDataContext(size, buffer_id, std::move(release_proc));
  return SkData::MakeWithProc(reinterpret_cast<void*>(buffer), size,
                              ReleaseSkData, context);
}

fuchsia::fonts::Slant SkToFuchsiaSlant(SkFontStyle::Slant slant) {
  switch (slant) {
    case SkFontStyle::kOblique_Slant:
      return fuchsia::fonts::Slant::OBLIQUE;
    case SkFontStyle::kItalic_Slant:
      return fuchsia::fonts::Slant::ITALIC;
    case SkFontStyle::kUpright_Slant:
    default:
      return fuchsia::fonts::Slant::UPRIGHT;
  }
}

SkFontStyle::Slant FuchsiaToSkSlant(fuchsia::fonts::Slant slant) {
  switch (slant) {
    case fuchsia::fonts::Slant::OBLIQUE:
      return SkFontStyle::kOblique_Slant;
    case fuchsia::fonts::Slant::ITALIC:
      return SkFontStyle::kItalic_Slant;
    case fuchsia::fonts::Slant::UPRIGHT:
    default:
      return SkFontStyle::kUpright_Slant;
  }
}

fidl::VectorPtr<std::string> BuildLanguageList(const char* bcp47[],
                                               int bcp47_count) {
  DEBUG_CHECK(bcp47 != nullptr || bcp47_count == 0, LOG_TAG, "");
  auto languages = fidl::VectorPtr<std::string>::New(0);
  for (int i = 0; i < bcp47_count; i++) {
    languages.push_back(bcp47[i]);
  }
  return languages;
}

sk_sp<SkTypeface> CreateTypefaceFromSkData(sk_sp<SkData> data, int font_index) {
  return SkFontMgr::RefDefault()->makeFromData(std::move(data), font_index);
}

}  // anonymous namespace

class FuchsiaFontManager::TypefaceCache {
 public:
  TypefaceCache() {}
  ~TypefaceCache();

  // Get an SkTypeface with the given buffer id, font index, and buffer
  // data. Creates a new SkTypeface if one does not already exist.
  sk_sp<SkTypeface> GetOrCreateTypeface(
      int buffer_id,
      int font_index,
      const fuchsia::mem::Buffer& buffer) const;

  // Callback called when an SkData with the given buffer id is deleted.
  void OnSkDataDeleted(int buffer_id) const;

 private:
  // Used to identify an SkTypeface in the cache.
  struct TypefaceId {
    int buffer_id;
    int font_index;

    // Needed by std::unordered_map.
    bool operator==(const TypefaceId& other) const {
      return (buffer_id == other.buffer_id && font_index == other.font_index);
    }

    // Used for debugging.
    friend std::ostream& operator<<(std::ostream& os, const TypefaceId& id) {
      return os << "TypfaceId: [buffer_id: " << id.buffer_id
                << ", font_index: " << id.font_index << "]";
    }
  };

  // Needed by std::unordered_map.
  struct TypefaceIdHash {
    std::size_t operator()(const TypefaceId& id) const {
      return std::hash<int>()(id.buffer_id) ^
             (std::hash<int>()(id.font_index) << 1);
    }
  };

  // Try to get an SkData with the given buffer id from the cache. If an
  // SkData is not found, create it and add it to the cache.
  sk_sp<SkData> GetOrCreateSkData(int buffer_id,
                                  const fuchsia::mem::Buffer& buffer) const;

  // Create a new SkTypeface for the given TypefaceId and SkData and add it to
  // the cache.
  sk_sp<SkTypeface> CreateSkTypeface(TypefaceId id, sk_sp<SkData> buffer) const;

  mutable std::unordered_map<TypefaceId, SkTypeface*, TypefaceIdHash>
      typeface_cache_;
  mutable std::unordered_map<int, std::shared_ptr<BufferHolder>> buffer_cache_;

  // Disallow copy and assignment.
  TypefaceCache(const TypefaceCache&) = delete;
  TypefaceCache& operator=(const TypefaceCache&) = delete;
};

class FuchsiaFontManager::BufferHolder {
 public:
  BufferHolder(const TypefaceCache* cache, int buffer_id)
      : cache_(cache), buffer_id_(buffer_id) {}
  ~BufferHolder() {}

  void SetData(SkData* data) { data_ = data; }

  SkData* GetData() const { return data_; }

  void OnDataDeleted() { cache_->OnSkDataDeleted(buffer_id_); }

 private:
  const TypefaceCache* cache_;
  int buffer_id_;
  SkData* data_;

  // Disallow copy and assignment.
  BufferHolder(const BufferHolder&) = delete;
  BufferHolder& operator=(const BufferHolder&) = delete;
};

FuchsiaFontManager::TypefaceCache::~TypefaceCache() {
  for (const auto& entry : typeface_cache_) {
    entry.second->weak_unref();
  }
}

void FuchsiaFontManager::TypefaceCache::OnSkDataDeleted(int buffer_id) const {
  bool was_found = buffer_cache_.erase(buffer_id) != 0;
  DEBUG_CHECK(was_found, LOG_TAG, "");
}

sk_sp<SkData> FuchsiaFontManager::TypefaceCache::GetOrCreateSkData(
    int buffer_id,
    const fuchsia::mem::Buffer& buffer) const {
  auto iter = buffer_cache_.find(buffer_id);
  if (iter != buffer_cache_.end()) {
    return sk_ref_sp(iter->second->GetData());
  }
  auto holder = std::make_shared<BufferHolder>(this, buffer_id);
  std::weak_ptr<BufferHolder> weak_holder = holder;
  auto data = MakeSkDataFromBuffer(buffer, buffer_id, [weak_holder]() {
    if (auto holder = weak_holder.lock()) {
      holder->OnDataDeleted();
    }
  });
  if (!data) {
    return nullptr;
  }
  holder->SetData(data.get());
  buffer_cache_[buffer_id] = std::move(holder);
  return data;
}

sk_sp<SkTypeface> FuchsiaFontManager::TypefaceCache::CreateSkTypeface(
    TypefaceId id,
    sk_sp<SkData> buffer) const {
  auto result = CreateTypefaceFromSkData(std::move(buffer), id.font_index);
  result->weak_ref();
  typeface_cache_[id] = result.get();
  return result;
}

sk_sp<SkTypeface> FuchsiaFontManager::TypefaceCache::GetOrCreateTypeface(
    int buffer_id,
    int font_index,
    const fuchsia::mem::Buffer& buffer) const {
  auto id = TypefaceId{buffer_id, font_index};
  auto iter = typeface_cache_.find(id);
  if (iter != typeface_cache_.end()) {
    if (iter->second->try_ref()) {
      return sk_ref_sp(iter->second);
    } else {
      iter->second->weak_unref();
      typeface_cache_.erase(iter);
    }
  }
  sk_sp<SkData> data = GetOrCreateSkData(buffer_id, buffer);
  if (!data) {
    return nullptr;
  }
  return CreateSkTypeface(id, std::move(data));
}

class FuchsiaFontManager::FontStyleSet : public SkFontStyleSet {
 public:
  FontStyleSet(sk_sp<FuchsiaFontManager> font_manager,
               std::string family_name,
               std::vector<SkFontStyle> styles)
      : font_manager_(font_manager),
        family_name_(family_name),
        styles_(styles) {}

  ~FontStyleSet() override = default;

  int count() override { return styles_.size(); }

  void getStyle(int index, SkFontStyle* style, SkString* style_name) override {
    DEBUG_CHECK(index >= 0 && index < static_cast<int>(styles_.size()), LOG_TAG,
                "");
    if (style)
      *style = styles_[index];

    // We don't have style names. Return an empty name.
    if (style_name)
      style_name->reset();
  }

  SkTypeface* createTypeface(int index) override {
    DEBUG_CHECK(index >= 0 && index < static_cast<int>(styles_.size()), LOG_TAG,
                "");

    if (typefaces_.empty())
      typefaces_.resize(styles_.size());

    if (!typefaces_[index]) {
      typefaces_[index] = font_manager_->FetchTypeface(
          family_name_.c_str(), styles_[index], /*bcp47=*/nullptr,
          /*bcp47_count=*/0, /*character=*/0,
          fuchsia::fonts::REQUEST_FLAG_NO_FALLBACK |
              fuchsia::fonts::REQUEST_FLAG_EXACT_MATCH);
    }

    return SkSafeRef(typefaces_[index].get());
  }

  SkTypeface* matchStyle(const SkFontStyle& pattern) override {
    return matchStyleCSS3(pattern);
  }

 private:
  sk_sp<FuchsiaFontManager> font_manager_;
  std::string family_name_;
  std::vector<SkFontStyle> styles_;
  std::vector<sk_sp<SkTypeface>> typefaces_;

  // Disallow copy and assignment.
  FontStyleSet(const FontStyleSet&) = delete;
  FontStyleSet& operator=(const FontStyleSet&) = delete;
};

FuchsiaFontManager::FuchsiaFontManager(fuchsia::fonts::ProviderSyncPtr provider)
    : font_provider_(std::move(provider)),
      typeface_cache_(new FuchsiaFontManager::TypefaceCache()) {}

FuchsiaFontManager::~FuchsiaFontManager() = default;

int FuchsiaFontManager::onCountFamilies() const {
  DEBUG_CHECK(false, LOG_TAG, "");
  return 0;
}

void FuchsiaFontManager::onGetFamilyName(int index,
                                         SkString* familyName) const {
  DEBUG_CHECK(false, LOG_TAG, "");
}

SkFontStyleSet* FuchsiaFontManager::onCreateStyleSet(int index) const {
  DEBUG_CHECK(false, LOG_TAG, "");
  return nullptr;
}

SkFontStyleSet* FuchsiaFontManager::onMatchFamily(
    const char family_name[]) const {
  fuchsia::fonts::FamilyInfoPtr family_info;
  int err = font_provider_->GetFamilyInfo(family_name, &family_info);
  if (err != ZX_OK) {
#ifndef NDEBUG
    FX_LOGF(ERROR, LOG_TAG,
            "Error fetching family from provider [err=%d]. Did "
            "you run Flutter in an environment that has a font manager?",
            err);
#endif
    return nullptr;
  }

  if (!family_info)
    return nullptr;

  std::vector<SkFontStyle> styles;
  for (auto& style : family_info->styles) {
    styles.push_back(
        SkFontStyle(style.weight, style.width, FuchsiaToSkSlant(style.slant)));
  }

  return new FontStyleSet(sk_ref_sp(this), family_info->name,
                          std::move(styles));
}

SkTypeface* FuchsiaFontManager::onMatchFamilyStyle(
    const char familyName[],
    const SkFontStyle& style) const {
  sk_sp<SkTypeface> typeface = FetchTypeface(familyName, style, nullptr, 0, 0);
  return typeface.release();
}

SkTypeface* FuchsiaFontManager::onMatchFamilyStyleCharacter(
    const char familyName[],
    const SkFontStyle& style,
    const char* bcp47[],
    int bcp47_count,
    SkUnichar character) const {
  sk_sp<SkTypeface> typeface =
      FetchTypeface(kDefaultFontFamily, style, bcp47, bcp47_count, character);
  return typeface.release();
}

SkTypeface* FuchsiaFontManager::onMatchFaceStyle(const SkTypeface*,
                                                 const SkFontStyle&) const {
  DEBUG_CHECK(false, LOG_TAG, "");
  return nullptr;
}

sk_sp<SkTypeface> FuchsiaFontManager::onMakeFromData(sk_sp<SkData>,
                                                     int ttcIndex) const {
  DEBUG_CHECK(false, LOG_TAG, "");
  return nullptr;
}

sk_sp<SkTypeface> FuchsiaFontManager::onMakeFromStreamIndex(
    std::unique_ptr<SkStreamAsset>,
    int ttcIndex) const {
  DEBUG_CHECK(false, LOG_TAG, "");
  return nullptr;
}

sk_sp<SkTypeface> FuchsiaFontManager::onMakeFromStreamArgs(
    std::unique_ptr<SkStreamAsset>,
    const SkFontArguments&) const {
  DEBUG_CHECK(false, LOG_TAG, "");
  return nullptr;
}

sk_sp<SkTypeface> FuchsiaFontManager::onMakeFromFile(const char path[],
                                                     int ttcIndex) const {
  DEBUG_CHECK(false, LOG_TAG, "");
  return nullptr;
}

sk_sp<SkTypeface> FuchsiaFontManager::onLegacyMakeTypeface(
    const char familyName[],
    SkFontStyle) const {
  DEBUG_CHECK(false, LOG_TAG, "");
  return nullptr;
}

sk_sp<SkTypeface> FuchsiaFontManager::FetchTypeface(const char family_name[],
                                                    const SkFontStyle& style,
                                                    const char* bcp47[],
                                                    int bcp47_count,
                                                    SkUnichar character,
                                                    uint32_t flags) const {
  TRACE_EVENT0("flutter", "FuchsiaFontManager::FetchTypeface");
  fuchsia::fonts::Request request;
  request.family = family_name;
  request.weight = style.weight();
  request.width = style.width();
  request.slant = SkToFuchsiaSlant(style.slant());
  request.language = BuildLanguageList(bcp47, bcp47_count);
  request.character = character;
  request.flags = flags;

  fuchsia::fonts::ResponsePtr response;
  int err = font_provider_->GetFont(std::move(request), &response);
  if (err != ZX_OK) {
#ifndef NDEBUG
    FX_LOGF(ERROR, LOG_TAG,
            "Error fetching font from provider [err=%d]. Did "
            "you run Flutter in an environment that has a font manager?",
            err);
#endif
    return nullptr;
  }

  // The service may return null response if there is no font matching the
  // request.
  if (!response) {
    return nullptr;
  }

  return typeface_cache_->GetOrCreateTypeface(
      response->buffer_id, response->font_index, response->buffer);
}

}  // namespace txt

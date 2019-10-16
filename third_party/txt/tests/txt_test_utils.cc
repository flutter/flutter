/*
 * Copyright 2017 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "txt_test_utils.h"

#include <sstream>

#include "third_party/skia/include/core/SkTypeface.h"
#include "txt/asset_font_manager.h"
#include "txt/typeface_font_asset_provider.h"
#include "utils/MacUtils.h"
#include "utils/WindowsUtils.h"

#if !defined(_WIN32)
#include <dirent.h>
#endif

namespace txt {

static std::string gFontDir;
static fml::CommandLine gCommandLine;

const std::string& GetFontDir() {
  return gFontDir;
}

void SetFontDir(const std::string& dir) {
  gFontDir = dir;
}

const fml::CommandLine& GetCommandLineForProcess() {
  return gCommandLine;
}

void SetCommandLine(fml::CommandLine cmd) {
  gCommandLine = std::move(cmd);
}

void RegisterFontsFromPath(TypefaceFontAssetProvider& font_provider,
                           std::string directory_path) {
#if defined(_WIN32)
  std::string path = directory_path + "\\*";
  WIN32_FIND_DATAA ffd;
  HANDLE directory = FindFirstFileA(path.c_str(), &ffd);
  if (directory == INVALID_HANDLE_VALUE) {
    return;
  }

  do {
    if ((ffd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
      continue;
    }

    std::string file_name(ffd.cFileName);

    std::stringstream file_path;
    file_path << directory_path << "/" << file_name;

    font_provider.RegisterTypeface(
        SkTypeface::MakeFromFile(file_path.str().c_str()));
  } while (FindNextFileA(directory, &ffd) != 0);

  // TODO(bkonyi): check for error here?
  FindClose(directory);
#else
  auto directory_closer = [](DIR* directory) {
    if (directory != nullptr) {
      ::closedir(directory);
    }
  };

  std::unique_ptr<DIR, decltype(directory_closer)> directory(
      ::opendir(directory_path.c_str()), directory_closer);

  if (directory == nullptr) {
    return;
  }

  for (struct dirent* entry = ::readdir(directory.get()); entry != nullptr;
       entry = ::readdir(directory.get())) {
    if (entry->d_type != DT_REG) {
      continue;
    }

    std::string file_name(entry->d_name);

    std::stringstream file_path;
    file_path << directory_path << "/" << file_name;

    font_provider.RegisterTypeface(
        SkTypeface::MakeFromFile(file_path.str().c_str()));
  }
#endif
}

std::shared_ptr<FontCollection> GetTestFontCollection() {
  std::unique_ptr<TypefaceFontAssetProvider> font_provider =
      std::make_unique<TypefaceFontAssetProvider>();
  RegisterFontsFromPath(*font_provider, GetFontDir());

  std::shared_ptr<FontCollection> collection =
      std::make_shared<FontCollection>();
  collection->SetAssetFontManager(
      sk_make_sp<AssetFontManager>(std::move(font_provider)));

  return collection;
}

// Build a paragraph and return it as a ParagraphTxt usable by tests that need
// access to ParagraphTxt internals.
std::unique_ptr<ParagraphTxt> BuildParagraph(
    txt::ParagraphBuilderTxt& builder) {
  return std::unique_ptr<txt::ParagraphTxt>(
      static_cast<txt::ParagraphTxt*>(builder.Build().release()));
}

}  // namespace txt

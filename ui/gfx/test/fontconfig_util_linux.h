// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_TEST_FONTCONFIG_UTIL_LINUX_H_
#define UI_GFX_TEST_FONTCONFIG_UTIL_LINUX_H_

#include <string>

#include "base/files/file_path.h"

namespace gfx {

// Array of paths to font files that are expected to exist on machines where
// tests are run.
extern const char* const kSystemFontsForFontconfig[];
extern const size_t kNumSystemFontsForFontconfig;

// Strings appearing at the beginning and end of Fontconfig XML files.
extern const char kFontconfigFileHeader[];
extern const char kFontconfigFileFooter[];

// Strings appearing at the beginning and end of Fontconfig <match> stanzas.
extern const char kFontconfigMatchHeader[];
extern const char kFontconfigMatchFooter[];

// Initializes Fontconfig and creates and swaps in a new, empty config.
void SetUpFontconfig();

// Deinitializes Fontconfig.
void TearDownFontconfig();

// Loads the font file at |path| into the current config, returning true on
// success.
bool LoadFontIntoFontconfig(const base::FilePath& path);

// Instructs Fontconfig to load |path|, an XML configuration file, into the
// current config, returning true on success.
bool LoadConfigFileIntoFontconfig(const base::FilePath& path);

// Writes |data| to a file in |temp_dir| and passes it to
// LoadConfigFileIntoFontconfig().
bool LoadConfigDataIntoFontconfig(const base::FilePath& temp_dir,
                                  const std::string& data);

// Returns a Fontconfig <edit> stanza.
std::string CreateFontconfigEditStanza(const std::string& name,
                                       const std::string& type,
                                       const std::string& value);

// Returns a Fontconfig <test> stanza.
std::string CreateFontconfigTestStanza(const std::string& name,
                                       const std::string& op,
                                       const std::string& type,
                                       const std::string& value);

// Returns a Fontconfig <alias> stanza.
std::string CreateFontconfigAliasStanza(const std::string& original_family,
                                        const std::string& preferred_family);

}  // namespace gfx

#endif  // UI_GFX_TEST_FONTCONFIG_UTIL_LINUX_H_

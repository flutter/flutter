// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// File utilities that use the ICU library go in this file.

#include "base/i18n/file_util_icu.h"

#include "base/files/file_path.h"
#include "base/i18n/icu_string_conversions.h"
#include "base/i18n/string_compare.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/singleton.h"
#include "base/strings/string_util.h"
#include "base/strings/sys_string_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include "build/build_config.h"
#include "third_party/icu/source/common/unicode/uniset.h"
#include "third_party/icu/source/i18n/unicode/coll.h"

namespace base {
namespace i18n {

namespace {

class IllegalCharacters {
 public:
  static IllegalCharacters* GetInstance() {
    return Singleton<IllegalCharacters>::get();
  }

  bool DisallowedEverywhere(UChar32 ucs4) {
    return !!illegal_anywhere_->contains(ucs4);
  }

  bool DisallowedLeadingOrTrailing(UChar32 ucs4) {
    return !!illegal_at_ends_->contains(ucs4);
  }

  bool IsAllowedName(const string16& s) {
    return s.empty() || (!!illegal_anywhere_->containsNone(
                             icu::UnicodeString(s.c_str(), s.size())) &&
                         !illegal_at_ends_->contains(*s.begin()) &&
                         !illegal_at_ends_->contains(*s.rbegin()));
  }

 private:
  friend class Singleton<IllegalCharacters>;
  friend struct DefaultSingletonTraits<IllegalCharacters>;

  IllegalCharacters();
  ~IllegalCharacters() { }

  // set of characters considered invalid anywhere inside a filename.
  scoped_ptr<icu::UnicodeSet> illegal_anywhere_;

  // set of characters considered invalid at either end of a filename.
  scoped_ptr<icu::UnicodeSet> illegal_at_ends_;

  DISALLOW_COPY_AND_ASSIGN(IllegalCharacters);
};

IllegalCharacters::IllegalCharacters() {
  UErrorCode everywhere_status = U_ZERO_ERROR;
  UErrorCode ends_status = U_ZERO_ERROR;
  // Control characters, formatting characters, non-characters, path separators,
  // and some printable ASCII characters regarded as dangerous ('"*/:<>?\\').
  // See  http://blogs.msdn.com/michkap/archive/2006/11/03/941420.aspx
  // and http://msdn2.microsoft.com/en-us/library/Aa365247.aspx
  // Note that code points in the "Other, Format" (Cf) category are ignored on
  // HFS+ despite the ZERO_WIDTH_JOINER and ZERO_WIDTH_NON-JOINER being
  // legitimate in Arabic and some S/SE Asian scripts. In addition tilde (~) is
  // also excluded due to the possibility of interacting poorly with short
  // filenames on VFAT. (Related to CVE-2014-9390)
  illegal_anywhere_.reset(new icu::UnicodeSet(
      UNICODE_STRING_SIMPLE("[[\"~*/:<>?\\\\|][:Cc:][:Cf:]]"),
      everywhere_status));
  illegal_at_ends_.reset(new icu::UnicodeSet(
      UNICODE_STRING_SIMPLE("[[:WSpace:][.]]"), ends_status));
  DCHECK(U_SUCCESS(everywhere_status));
  DCHECK(U_SUCCESS(ends_status));

  // Add non-characters. If this becomes a performance bottleneck by
  // any chance, do not add these to |set| and change IsFilenameLegal()
  // to check |ucs4 & 0xFFFEu == 0xFFFEu|, in addiition to calling
  // IsAllowedName().
  illegal_anywhere_->add(0xFDD0, 0xFDEF);
  for (int i = 0; i <= 0x10; ++i) {
    int plane_base = 0x10000 * i;
    illegal_anywhere_->add(plane_base + 0xFFFE, plane_base + 0xFFFF);
  }
  illegal_anywhere_->freeze();
  illegal_at_ends_->freeze();
}

}  // namespace

bool IsFilenameLegal(const string16& file_name) {
  return IllegalCharacters::GetInstance()->IsAllowedName(file_name);
}

void ReplaceIllegalCharactersInPath(FilePath::StringType* file_name,
                                    char replace_char) {
  IllegalCharacters* illegal = IllegalCharacters::GetInstance();

  DCHECK(!(illegal->DisallowedEverywhere(replace_char)));
  DCHECK(!(illegal->DisallowedLeadingOrTrailing(replace_char)));

  int cursor = 0;  // The ICU macros expect an int.
  while (cursor < static_cast<int>(file_name->size())) {
    int char_begin = cursor;
    uint32 code_point;
#if defined(OS_MACOSX)
    // Mac uses UTF-8 encoding for filenames.
    U8_NEXT(file_name->data(), cursor, static_cast<int>(file_name->length()),
            code_point);
#elif defined(OS_WIN)
    // Windows uses UTF-16 encoding for filenames.
    U16_NEXT(file_name->data(), cursor, static_cast<int>(file_name->length()),
             code_point);
#elif defined(OS_POSIX)
    // Linux doesn't actually define an encoding. It basically allows anything
    // except for a few special ASCII characters.
    unsigned char cur_char = static_cast<unsigned char>((*file_name)[cursor++]);
    if (cur_char >= 0x80)
      continue;
    code_point = cur_char;
#else
    NOTREACHED();
#endif

    if (illegal->DisallowedEverywhere(code_point) ||
        ((char_begin == 0 || cursor == static_cast<int>(file_name->length())) &&
         illegal->DisallowedLeadingOrTrailing(code_point))) {
      file_name->replace(char_begin, cursor - char_begin, 1, replace_char);
      // We just made the potentially multi-byte/word char into one that only
      // takes one byte/word, so need to adjust the cursor to point to the next
      // character again.
      cursor = char_begin + 1;
    }
  }
}

bool LocaleAwareCompareFilenames(const FilePath& a, const FilePath& b) {
  UErrorCode error_code = U_ZERO_ERROR;
  // Use the default collator. The default locale should have been properly
  // set by the time this constructor is called.
  scoped_ptr<icu::Collator> collator(icu::Collator::createInstance(error_code));
  DCHECK(U_SUCCESS(error_code));
  // Make it case-sensitive.
  collator->setStrength(icu::Collator::TERTIARY);

#if defined(OS_WIN)
  return CompareString16WithCollator(*collator, WideToUTF16(a.value()),
                                     WideToUTF16(b.value())) == UCOL_LESS;

#elif defined(OS_POSIX)
  // On linux, the file system encoding is not defined. We assume
  // SysNativeMBToWide takes care of it.
  return CompareString16WithCollator(
             *collator, WideToUTF16(SysNativeMBToWide(a.value().c_str())),
             WideToUTF16(SysNativeMBToWide(b.value().c_str()))) == UCOL_LESS;
#else
  #error Not implemented on your system
#endif
}

void NormalizeFileNameEncoding(FilePath* file_name) {
#if defined(OS_CHROMEOS)
  std::string normalized_str;
  if (ConvertToUtf8AndNormalize(file_name->BaseName().value(),
                                kCodepageUTF8,
                                &normalized_str)) {
    *file_name = file_name->DirName().Append(FilePath(normalized_str));
  }
#endif
}

}  // namespace i18n
}  // namespace base

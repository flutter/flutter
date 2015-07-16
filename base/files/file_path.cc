// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path.h"

#include <string.h>
#include <algorithm>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/pickle.h"

// These includes are just for the *Hack functions, and should be removed
// when those functions are removed.
#include "base/strings/string_piece.h"
#include "base/strings/string_util.h"
#include "base/strings/sys_string_conversions.h"
#include "base/strings/utf_string_conversions.h"

#if defined(OS_MACOSX)
#include "base/mac/scoped_cftyperef.h"
#include "base/third_party/icu/icu_utf.h"
#endif

#if defined(OS_WIN)
#include <windows.h>
#elif defined(OS_MACOSX)
#include <CoreFoundation/CoreFoundation.h>
#endif

namespace base {

typedef FilePath::StringType StringType;

namespace {

const char* const kCommonDoubleExtensionSuffixes[] = { "gz", "z", "bz2", "bz" };
const char* const kCommonDoubleExtensions[] = { "user.js" };

const FilePath::CharType kStringTerminator = FILE_PATH_LITERAL('\0');

// If this FilePath contains a drive letter specification, returns the
// position of the last character of the drive letter specification,
// otherwise returns npos.  This can only be true on Windows, when a pathname
// begins with a letter followed by a colon.  On other platforms, this always
// returns npos.
StringType::size_type FindDriveLetter(const StringType& path) {
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
  // This is dependent on an ASCII-based character set, but that's a
  // reasonable assumption.  iswalpha can be too inclusive here.
  if (path.length() >= 2 && path[1] == L':' &&
      ((path[0] >= L'A' && path[0] <= L'Z') ||
       (path[0] >= L'a' && path[0] <= L'z'))) {
    return 1;
  }
#endif  // FILE_PATH_USES_DRIVE_LETTERS
  return StringType::npos;
}

#if defined(FILE_PATH_USES_DRIVE_LETTERS)
bool EqualDriveLetterCaseInsensitive(const StringType& a,
                                     const StringType& b) {
  size_t a_letter_pos = FindDriveLetter(a);
  size_t b_letter_pos = FindDriveLetter(b);

  if (a_letter_pos == StringType::npos || b_letter_pos == StringType::npos)
    return a == b;

  StringType a_letter(a.substr(0, a_letter_pos + 1));
  StringType b_letter(b.substr(0, b_letter_pos + 1));
  if (!StartsWith(a_letter, b_letter, false))
    return false;

  StringType a_rest(a.substr(a_letter_pos + 1));
  StringType b_rest(b.substr(b_letter_pos + 1));
  return a_rest == b_rest;
}
#endif  // defined(FILE_PATH_USES_DRIVE_LETTERS)

bool IsPathAbsolute(const StringType& path) {
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
  StringType::size_type letter = FindDriveLetter(path);
  if (letter != StringType::npos) {
    // Look for a separator right after the drive specification.
    return path.length() > letter + 1 &&
        FilePath::IsSeparator(path[letter + 1]);
  }
  // Look for a pair of leading separators.
  return path.length() > 1 &&
      FilePath::IsSeparator(path[0]) && FilePath::IsSeparator(path[1]);
#else  // FILE_PATH_USES_DRIVE_LETTERS
  // Look for a separator in the first position.
  return path.length() > 0 && FilePath::IsSeparator(path[0]);
#endif  // FILE_PATH_USES_DRIVE_LETTERS
}

bool AreAllSeparators(const StringType& input) {
  for (StringType::const_iterator it = input.begin();
      it != input.end(); ++it) {
    if (!FilePath::IsSeparator(*it))
      return false;
  }

  return true;
}

// Find the position of the '.' that separates the extension from the rest
// of the file name. The position is relative to BaseName(), not value().
// Returns npos if it can't find an extension.
StringType::size_type FinalExtensionSeparatorPosition(const StringType& path) {
  // Special case "." and ".."
  if (path == FilePath::kCurrentDirectory || path == FilePath::kParentDirectory)
    return StringType::npos;

  return path.rfind(FilePath::kExtensionSeparator);
}

// Same as above, but allow a second extension component of up to 4
// characters when the rightmost extension component is a common double
// extension (gz, bz2, Z).  For example, foo.tar.gz or foo.tar.Z would have
// extension components of '.tar.gz' and '.tar.Z' respectively.
StringType::size_type ExtensionSeparatorPosition(const StringType& path) {
  const StringType::size_type last_dot = FinalExtensionSeparatorPosition(path);

  // No extension, or the extension is the whole filename.
  if (last_dot == StringType::npos || last_dot == 0U)
    return last_dot;

  const StringType::size_type penultimate_dot =
      path.rfind(FilePath::kExtensionSeparator, last_dot - 1);
  const StringType::size_type last_separator =
      path.find_last_of(FilePath::kSeparators, last_dot - 1,
                        FilePath::kSeparatorsLength - 1);

  if (penultimate_dot == StringType::npos ||
      (last_separator != StringType::npos &&
       penultimate_dot < last_separator)) {
    return last_dot;
  }

  for (size_t i = 0; i < arraysize(kCommonDoubleExtensions); ++i) {
    StringType extension(path, penultimate_dot + 1);
    if (LowerCaseEqualsASCII(extension, kCommonDoubleExtensions[i]))
      return penultimate_dot;
  }

  StringType extension(path, last_dot + 1);
  for (size_t i = 0; i < arraysize(kCommonDoubleExtensionSuffixes); ++i) {
    if (LowerCaseEqualsASCII(extension, kCommonDoubleExtensionSuffixes[i])) {
      if ((last_dot - penultimate_dot) <= 5U &&
          (last_dot - penultimate_dot) > 1U) {
        return penultimate_dot;
      }
    }
  }

  return last_dot;
}

// Returns true if path is "", ".", or "..".
bool IsEmptyOrSpecialCase(const StringType& path) {
  // Special cases "", ".", and ".."
  if (path.empty() || path == FilePath::kCurrentDirectory ||
      path == FilePath::kParentDirectory) {
    return true;
  }

  return false;
}

}  // namespace

FilePath::FilePath() {
}

FilePath::FilePath(const FilePath& that) : path_(that.path_) {
}

FilePath::FilePath(const StringType& path) : path_(path) {
  StringType::size_type nul_pos = path_.find(kStringTerminator);
  if (nul_pos != StringType::npos)
    path_.erase(nul_pos, StringType::npos);
}

FilePath::~FilePath() {
}

FilePath& FilePath::operator=(const FilePath& that) {
  path_ = that.path_;
  return *this;
}

bool FilePath::operator==(const FilePath& that) const {
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
  return EqualDriveLetterCaseInsensitive(this->path_, that.path_);
#else  // defined(FILE_PATH_USES_DRIVE_LETTERS)
  return path_ == that.path_;
#endif  // defined(FILE_PATH_USES_DRIVE_LETTERS)
}

bool FilePath::operator!=(const FilePath& that) const {
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
  return !EqualDriveLetterCaseInsensitive(this->path_, that.path_);
#else  // defined(FILE_PATH_USES_DRIVE_LETTERS)
  return path_ != that.path_;
#endif  // defined(FILE_PATH_USES_DRIVE_LETTERS)
}

// static
bool FilePath::IsSeparator(CharType character) {
  for (size_t i = 0; i < kSeparatorsLength - 1; ++i) {
    if (character == kSeparators[i]) {
      return true;
    }
  }

  return false;
}

void FilePath::GetComponents(std::vector<StringType>* components) const {
  DCHECK(components);
  if (!components)
    return;
  components->clear();
  if (value().empty())
    return;

  std::vector<StringType> ret_val;
  FilePath current = *this;
  FilePath base;

  // Capture path components.
  while (current != current.DirName()) {
    base = current.BaseName();
    if (!AreAllSeparators(base.value()))
      ret_val.push_back(base.value());
    current = current.DirName();
  }

  // Capture root, if any.
  base = current.BaseName();
  if (!base.value().empty() && base.value() != kCurrentDirectory)
    ret_val.push_back(current.BaseName().value());

  // Capture drive letter, if any.
  FilePath dir = current.DirName();
  StringType::size_type letter = FindDriveLetter(dir.value());
  if (letter != StringType::npos) {
    ret_val.push_back(StringType(dir.value(), 0, letter + 1));
  }

  *components = std::vector<StringType>(ret_val.rbegin(), ret_val.rend());
}

bool FilePath::IsParent(const FilePath& child) const {
  return AppendRelativePath(child, NULL);
}

bool FilePath::AppendRelativePath(const FilePath& child,
                                  FilePath* path) const {
  std::vector<StringType> parent_components;
  std::vector<StringType> child_components;
  GetComponents(&parent_components);
  child.GetComponents(&child_components);

  if (parent_components.empty() ||
      parent_components.size() >= child_components.size())
    return false;

  std::vector<StringType>::const_iterator parent_comp =
      parent_components.begin();
  std::vector<StringType>::const_iterator child_comp =
      child_components.begin();

#if defined(FILE_PATH_USES_DRIVE_LETTERS)
  // Windows can access case sensitive filesystems, so component
  // comparisions must be case sensitive, but drive letters are
  // never case sensitive.
  if ((FindDriveLetter(*parent_comp) != StringType::npos) &&
      (FindDriveLetter(*child_comp) != StringType::npos)) {
    if (!StartsWith(*parent_comp, *child_comp, false))
      return false;
    ++parent_comp;
    ++child_comp;
  }
#endif  // defined(FILE_PATH_USES_DRIVE_LETTERS)

  while (parent_comp != parent_components.end()) {
    if (*parent_comp != *child_comp)
      return false;
    ++parent_comp;
    ++child_comp;
  }

  if (path != NULL) {
    for (; child_comp != child_components.end(); ++child_comp) {
      *path = path->Append(*child_comp);
    }
  }
  return true;
}

// libgen's dirname and basename aren't guaranteed to be thread-safe and aren't
// guaranteed to not modify their input strings, and in fact are implemented
// differently in this regard on different platforms.  Don't use them, but
// adhere to their behavior.
FilePath FilePath::DirName() const {
  FilePath new_path(path_);
  new_path.StripTrailingSeparatorsInternal();

  // The drive letter, if any, always needs to remain in the output.  If there
  // is no drive letter, as will always be the case on platforms which do not
  // support drive letters, letter will be npos, or -1, so the comparisons and
  // resizes below using letter will still be valid.
  StringType::size_type letter = FindDriveLetter(new_path.path_);

  StringType::size_type last_separator =
      new_path.path_.find_last_of(kSeparators, StringType::npos,
                                  kSeparatorsLength - 1);
  if (last_separator == StringType::npos) {
    // path_ is in the current directory.
    new_path.path_.resize(letter + 1);
  } else if (last_separator == letter + 1) {
    // path_ is in the root directory.
    new_path.path_.resize(letter + 2);
  } else if (last_separator == letter + 2 &&
             IsSeparator(new_path.path_[letter + 1])) {
    // path_ is in "//" (possibly with a drive letter); leave the double
    // separator intact indicating alternate root.
    new_path.path_.resize(letter + 3);
  } else if (last_separator != 0) {
    // path_ is somewhere else, trim the basename.
    new_path.path_.resize(last_separator);
  }

  new_path.StripTrailingSeparatorsInternal();
  if (!new_path.path_.length())
    new_path.path_ = kCurrentDirectory;

  return new_path;
}

FilePath FilePath::BaseName() const {
  FilePath new_path(path_);
  new_path.StripTrailingSeparatorsInternal();

  // The drive letter, if any, is always stripped.
  StringType::size_type letter = FindDriveLetter(new_path.path_);
  if (letter != StringType::npos) {
    new_path.path_.erase(0, letter + 1);
  }

  // Keep everything after the final separator, but if the pathname is only
  // one character and it's a separator, leave it alone.
  StringType::size_type last_separator =
      new_path.path_.find_last_of(kSeparators, StringType::npos,
                                  kSeparatorsLength - 1);
  if (last_separator != StringType::npos &&
      last_separator < new_path.path_.length() - 1) {
    new_path.path_.erase(0, last_separator + 1);
  }

  return new_path;
}

StringType FilePath::Extension() const {
  FilePath base(BaseName());
  const StringType::size_type dot = ExtensionSeparatorPosition(base.path_);
  if (dot == StringType::npos)
    return StringType();

  return base.path_.substr(dot, StringType::npos);
}

StringType FilePath::FinalExtension() const {
  FilePath base(BaseName());
  const StringType::size_type dot = FinalExtensionSeparatorPosition(base.path_);
  if (dot == StringType::npos)
    return StringType();

  return base.path_.substr(dot, StringType::npos);
}

FilePath FilePath::RemoveExtension() const {
  if (Extension().empty())
    return *this;

  const StringType::size_type dot = ExtensionSeparatorPosition(path_);
  if (dot == StringType::npos)
    return *this;

  return FilePath(path_.substr(0, dot));
}

FilePath FilePath::RemoveFinalExtension() const {
  if (FinalExtension().empty())
    return *this;

  const StringType::size_type dot = FinalExtensionSeparatorPosition(path_);
  if (dot == StringType::npos)
    return *this;

  return FilePath(path_.substr(0, dot));
}

FilePath FilePath::InsertBeforeExtension(const StringType& suffix) const {
  if (suffix.empty())
    return FilePath(path_);

  if (IsEmptyOrSpecialCase(BaseName().value()))
    return FilePath();

  StringType ext = Extension();
  StringType ret = RemoveExtension().value();
  ret.append(suffix);
  ret.append(ext);
  return FilePath(ret);
}

FilePath FilePath::InsertBeforeExtensionASCII(const StringPiece& suffix)
    const {
  DCHECK(IsStringASCII(suffix));
#if defined(OS_WIN)
  return InsertBeforeExtension(ASCIIToUTF16(suffix.as_string()));
#elif defined(OS_POSIX)
  return InsertBeforeExtension(suffix.as_string());
#endif
}

FilePath FilePath::AddExtension(const StringType& extension) const {
  if (IsEmptyOrSpecialCase(BaseName().value()))
    return FilePath();

  // If the new extension is "" or ".", then just return the current FilePath.
  if (extension.empty() || extension == StringType(1, kExtensionSeparator))
    return *this;

  StringType str = path_;
  if (extension[0] != kExtensionSeparator &&
      *(str.end() - 1) != kExtensionSeparator) {
    str.append(1, kExtensionSeparator);
  }
  str.append(extension);
  return FilePath(str);
}

FilePath FilePath::ReplaceExtension(const StringType& extension) const {
  if (IsEmptyOrSpecialCase(BaseName().value()))
    return FilePath();

  FilePath no_ext = RemoveExtension();
  // If the new extension is "" or ".", then just remove the current extension.
  if (extension.empty() || extension == StringType(1, kExtensionSeparator))
    return no_ext;

  StringType str = no_ext.value();
  if (extension[0] != kExtensionSeparator)
    str.append(1, kExtensionSeparator);
  str.append(extension);
  return FilePath(str);
}

bool FilePath::MatchesExtension(const StringType& extension) const {
  DCHECK(extension.empty() || extension[0] == kExtensionSeparator);

  StringType current_extension = Extension();

  if (current_extension.length() != extension.length())
    return false;

  return FilePath::CompareEqualIgnoreCase(extension, current_extension);
}

FilePath FilePath::Append(const StringType& component) const {
  const StringType* appended = &component;
  StringType without_nuls;

  StringType::size_type nul_pos = component.find(kStringTerminator);
  if (nul_pos != StringType::npos) {
    without_nuls = component.substr(0, nul_pos);
    appended = &without_nuls;
  }

  DCHECK(!IsPathAbsolute(*appended));

  if (path_.compare(kCurrentDirectory) == 0) {
    // Append normally doesn't do any normalization, but as a special case,
    // when appending to kCurrentDirectory, just return a new path for the
    // component argument.  Appending component to kCurrentDirectory would
    // serve no purpose other than needlessly lengthening the path, and
    // it's likely in practice to wind up with FilePath objects containing
    // only kCurrentDirectory when calling DirName on a single relative path
    // component.
    return FilePath(*appended);
  }

  FilePath new_path(path_);
  new_path.StripTrailingSeparatorsInternal();

  // Don't append a separator if the path is empty (indicating the current
  // directory) or if the path component is empty (indicating nothing to
  // append).
  if (appended->length() > 0 && new_path.path_.length() > 0) {
    // Don't append a separator if the path still ends with a trailing
    // separator after stripping (indicating the root directory).
    if (!IsSeparator(new_path.path_[new_path.path_.length() - 1])) {
      // Don't append a separator if the path is just a drive letter.
      if (FindDriveLetter(new_path.path_) + 1 != new_path.path_.length()) {
        new_path.path_.append(1, kSeparators[0]);
      }
    }
  }

  new_path.path_.append(*appended);
  return new_path;
}

FilePath FilePath::Append(const FilePath& component) const {
  return Append(component.value());
}

FilePath FilePath::AppendASCII(const StringPiece& component) const {
  DCHECK(base::IsStringASCII(component));
#if defined(OS_WIN)
  return Append(ASCIIToUTF16(component.as_string()));
#elif defined(OS_POSIX)
  return Append(component.as_string());
#endif
}

bool FilePath::IsAbsolute() const {
  return IsPathAbsolute(path_);
}

bool FilePath::EndsWithSeparator() const {
  if (empty())
    return false;
  return IsSeparator(path_[path_.size() - 1]);
}

FilePath FilePath::AsEndingWithSeparator() const {
  if (EndsWithSeparator() || path_.empty())
    return *this;

  StringType path_str;
  path_str.reserve(path_.length() + 1);  // Only allocate string once.

  path_str = path_;
  path_str.append(&kSeparators[0], 1);
  return FilePath(path_str);
}

FilePath FilePath::StripTrailingSeparators() const {
  FilePath new_path(path_);
  new_path.StripTrailingSeparatorsInternal();

  return new_path;
}

bool FilePath::ReferencesParent() const {
  std::vector<StringType> components;
  GetComponents(&components);

  std::vector<StringType>::const_iterator it = components.begin();
  for (; it != components.end(); ++it) {
    const StringType& component = *it;
    // Windows has odd, undocumented behavior with path components containing
    // only whitespace and . characters. So, if all we see is . and
    // whitespace, then we treat any .. sequence as referencing parent.
    // For simplicity we enforce this on all platforms.
    if (component.find_first_not_of(FILE_PATH_LITERAL(". \n\r\t")) ==
            std::string::npos &&
        component.find(kParentDirectory) != std::string::npos) {
      return true;
    }
  }
  return false;
}

#if defined(OS_POSIX)
// See file_path.h for a discussion of the encoding of paths on POSIX
// platforms.  These encoding conversion functions are not quite correct.

string16 FilePath::LossyDisplayName() const {
  return WideToUTF16(SysNativeMBToWide(path_));
}

std::string FilePath::MaybeAsASCII() const {
  if (base::IsStringASCII(path_))
    return path_;
  return std::string();
}

std::string FilePath::AsUTF8Unsafe() const {
#if defined(SYSTEM_NATIVE_UTF8)
  return value();
#else
  return WideToUTF8(SysNativeMBToWide(value()));
#endif
}

string16 FilePath::AsUTF16Unsafe() const {
#if defined(SYSTEM_NATIVE_UTF8)
  return UTF8ToUTF16(value());
#else
  return WideToUTF16(SysNativeMBToWide(value()));
#endif
}

// static
FilePath FilePath::FromUTF8Unsafe(const std::string& utf8) {
#if defined(SYSTEM_NATIVE_UTF8)
  return FilePath(utf8);
#else
  return FilePath(SysWideToNativeMB(UTF8ToWide(utf8)));
#endif
}

// static
FilePath FilePath::FromUTF16Unsafe(const string16& utf16) {
#if defined(SYSTEM_NATIVE_UTF8)
  return FilePath(UTF16ToUTF8(utf16));
#else
  return FilePath(SysWideToNativeMB(UTF16ToWide(utf16)));
#endif
}

#elif defined(OS_WIN)
string16 FilePath::LossyDisplayName() const {
  return path_;
}

std::string FilePath::MaybeAsASCII() const {
  if (base::IsStringASCII(path_))
    return UTF16ToASCII(path_);
  return std::string();
}

std::string FilePath::AsUTF8Unsafe() const {
  return WideToUTF8(value());
}

string16 FilePath::AsUTF16Unsafe() const {
  return value();
}

// static
FilePath FilePath::FromUTF8Unsafe(const std::string& utf8) {
  return FilePath(UTF8ToWide(utf8));
}

// static
FilePath FilePath::FromUTF16Unsafe(const string16& utf16) {
  return FilePath(utf16);
}
#endif

void FilePath::WriteToPickle(Pickle* pickle) const {
#if defined(OS_WIN)
  pickle->WriteString16(path_);
#else
  pickle->WriteString(path_);
#endif
}

bool FilePath::ReadFromPickle(PickleIterator* iter) {
#if defined(OS_WIN)
  if (!iter->ReadString16(&path_))
    return false;
#else
  if (!iter->ReadString(&path_))
    return false;
#endif

  if (path_.find(kStringTerminator) != StringType::npos)
    return false;

  return true;
}

#if defined(OS_WIN)
// Windows specific implementation of file string comparisons

int FilePath::CompareIgnoreCase(const StringType& string1,
                                const StringType& string2) {
  // Perform character-wise upper case comparison rather than using the
  // fully Unicode-aware CompareString(). For details see:
  // http://blogs.msdn.com/michkap/archive/2005/10/17/481600.aspx
  StringType::const_iterator i1 = string1.begin();
  StringType::const_iterator i2 = string2.begin();
  StringType::const_iterator string1end = string1.end();
  StringType::const_iterator string2end = string2.end();
  for ( ; i1 != string1end && i2 != string2end; ++i1, ++i2) {
    wchar_t c1 =
        (wchar_t)LOWORD(::CharUpperW((LPWSTR)(DWORD_PTR)MAKELONG(*i1, 0)));
    wchar_t c2 =
        (wchar_t)LOWORD(::CharUpperW((LPWSTR)(DWORD_PTR)MAKELONG(*i2, 0)));
    if (c1 < c2)
      return -1;
    if (c1 > c2)
      return 1;
  }
  if (i1 != string1end)
    return 1;
  if (i2 != string2end)
    return -1;
  return 0;
}

#elif defined(OS_MACOSX)
// Mac OS X specific implementation of file string comparisons

// cf. http://developer.apple.com/mac/library/technotes/tn/tn1150.html#UnicodeSubtleties
//
// "When using CreateTextEncoding to create a text encoding, you should set
// the TextEncodingBase to kTextEncodingUnicodeV2_0, set the
// TextEncodingVariant to kUnicodeCanonicalDecompVariant, and set the
// TextEncodingFormat to kUnicode16BitFormat. Using these values ensures that
// the Unicode will be in the same form as on an HFS Plus volume, even as the
// Unicode standard evolves."
//
// Another technical article for X 10.4 updates this: one should use
// the new (unambiguous) kUnicodeHFSPlusDecompVariant.
// cf. http://developer.apple.com/mac/library/releasenotes/TextFonts/RN-TEC/index.html
//
// This implementation uses CFStringGetFileSystemRepresentation() to get the
// decomposed form, and an adapted version of the FastUnicodeCompare as
// described in the tech note to compare the strings.

// Character conversion table for FastUnicodeCompare()
//
// The lower case table consists of a 256-entry high-byte table followed by
// some number of 256-entry subtables. The high-byte table contains either an
// offset to the subtable for characters with that high byte or zero, which
// means that there are no case mappings or ignored characters in that block.
// Ignored characters are mapped to zero.
//
// cf. downloadable file linked in
// http://developer.apple.com/mac/library/technotes/tn/tn1150.html#StringComparisonAlgorithm

namespace {

const UInt16 lower_case_table[] = {
  // High-byte indices ( == 0 iff no case mapping and no ignorables )

  /* 0 */ 0x0100, 0x0200, 0x0000, 0x0300, 0x0400, 0x0500, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 1 */ 0x0600, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 2 */ 0x0700, 0x0800, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 3 */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 4 */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 5 */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 6 */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 7 */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 8 */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 9 */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* A */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* B */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* C */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* D */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* E */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* F */ 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
          0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0900, 0x0A00,

  // Table 1 (for high byte 0x00)

  /* 0 */ 0xFFFF, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007,
          0x0008, 0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F,
  /* 1 */ 0x0010, 0x0011, 0x0012, 0x0013, 0x0014, 0x0015, 0x0016, 0x0017,
          0x0018, 0x0019, 0x001A, 0x001B, 0x001C, 0x001D, 0x001E, 0x001F,
  /* 2 */ 0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027,
          0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
  /* 3 */ 0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
          0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
  /* 4 */ 0x0040, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067,
          0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
  /* 5 */ 0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077,
          0x0078, 0x0079, 0x007A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
  /* 6 */ 0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067,
          0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
  /* 7 */ 0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077,
          0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, 0x007F,
  /* 8 */ 0x0080, 0x0081, 0x0082, 0x0083, 0x0084, 0x0085, 0x0086, 0x0087,
          0x0088, 0x0089, 0x008A, 0x008B, 0x008C, 0x008D, 0x008E, 0x008F,
  /* 9 */ 0x0090, 0x0091, 0x0092, 0x0093, 0x0094, 0x0095, 0x0096, 0x0097,
          0x0098, 0x0099, 0x009A, 0x009B, 0x009C, 0x009D, 0x009E, 0x009F,
  /* A */ 0x00A0, 0x00A1, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7,
          0x00A8, 0x00A9, 0x00AA, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF,
  /* B */ 0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7,
          0x00B8, 0x00B9, 0x00BA, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x00BF,
  /* C */ 0x00C0, 0x00C1, 0x00C2, 0x00C3, 0x00C4, 0x00C5, 0x00E6, 0x00C7,
          0x00C8, 0x00C9, 0x00CA, 0x00CB, 0x00CC, 0x00CD, 0x00CE, 0x00CF,
  /* D */ 0x00F0, 0x00D1, 0x00D2, 0x00D3, 0x00D4, 0x00D5, 0x00D6, 0x00D7,
          0x00F8, 0x00D9, 0x00DA, 0x00DB, 0x00DC, 0x00DD, 0x00FE, 0x00DF,
  /* E */ 0x00E0, 0x00E1, 0x00E2, 0x00E3, 0x00E4, 0x00E5, 0x00E6, 0x00E7,
          0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x00EC, 0x00ED, 0x00EE, 0x00EF,
  /* F */ 0x00F0, 0x00F1, 0x00F2, 0x00F3, 0x00F4, 0x00F5, 0x00F6, 0x00F7,
          0x00F8, 0x00F9, 0x00FA, 0x00FB, 0x00FC, 0x00FD, 0x00FE, 0x00FF,

  // Table 2 (for high byte 0x01)

  /* 0 */ 0x0100, 0x0101, 0x0102, 0x0103, 0x0104, 0x0105, 0x0106, 0x0107,
          0x0108, 0x0109, 0x010A, 0x010B, 0x010C, 0x010D, 0x010E, 0x010F,
  /* 1 */ 0x0111, 0x0111, 0x0112, 0x0113, 0x0114, 0x0115, 0x0116, 0x0117,
          0x0118, 0x0119, 0x011A, 0x011B, 0x011C, 0x011D, 0x011E, 0x011F,
  /* 2 */ 0x0120, 0x0121, 0x0122, 0x0123, 0x0124, 0x0125, 0x0127, 0x0127,
          0x0128, 0x0129, 0x012A, 0x012B, 0x012C, 0x012D, 0x012E, 0x012F,
  /* 3 */ 0x0130, 0x0131, 0x0133, 0x0133, 0x0134, 0x0135, 0x0136, 0x0137,
          0x0138, 0x0139, 0x013A, 0x013B, 0x013C, 0x013D, 0x013E, 0x0140,
  /* 4 */ 0x0140, 0x0142, 0x0142, 0x0143, 0x0144, 0x0145, 0x0146, 0x0147,
          0x0148, 0x0149, 0x014B, 0x014B, 0x014C, 0x014D, 0x014E, 0x014F,
  /* 5 */ 0x0150, 0x0151, 0x0153, 0x0153, 0x0154, 0x0155, 0x0156, 0x0157,
          0x0158, 0x0159, 0x015A, 0x015B, 0x015C, 0x015D, 0x015E, 0x015F,
  /* 6 */ 0x0160, 0x0161, 0x0162, 0x0163, 0x0164, 0x0165, 0x0167, 0x0167,
          0x0168, 0x0169, 0x016A, 0x016B, 0x016C, 0x016D, 0x016E, 0x016F,
  /* 7 */ 0x0170, 0x0171, 0x0172, 0x0173, 0x0174, 0x0175, 0x0176, 0x0177,
          0x0178, 0x0179, 0x017A, 0x017B, 0x017C, 0x017D, 0x017E, 0x017F,
  /* 8 */ 0x0180, 0x0253, 0x0183, 0x0183, 0x0185, 0x0185, 0x0254, 0x0188,
          0x0188, 0x0256, 0x0257, 0x018C, 0x018C, 0x018D, 0x01DD, 0x0259,
  /* 9 */ 0x025B, 0x0192, 0x0192, 0x0260, 0x0263, 0x0195, 0x0269, 0x0268,
          0x0199, 0x0199, 0x019A, 0x019B, 0x026F, 0x0272, 0x019E, 0x0275,
  /* A */ 0x01A0, 0x01A1, 0x01A3, 0x01A3, 0x01A5, 0x01A5, 0x01A6, 0x01A8,
          0x01A8, 0x0283, 0x01AA, 0x01AB, 0x01AD, 0x01AD, 0x0288, 0x01AF,
  /* B */ 0x01B0, 0x028A, 0x028B, 0x01B4, 0x01B4, 0x01B6, 0x01B6, 0x0292,
          0x01B9, 0x01B9, 0x01BA, 0x01BB, 0x01BD, 0x01BD, 0x01BE, 0x01BF,
  /* C */ 0x01C0, 0x01C1, 0x01C2, 0x01C3, 0x01C6, 0x01C6, 0x01C6, 0x01C9,
          0x01C9, 0x01C9, 0x01CC, 0x01CC, 0x01CC, 0x01CD, 0x01CE, 0x01CF,
  /* D */ 0x01D0, 0x01D1, 0x01D2, 0x01D3, 0x01D4, 0x01D5, 0x01D6, 0x01D7,
          0x01D8, 0x01D9, 0x01DA, 0x01DB, 0x01DC, 0x01DD, 0x01DE, 0x01DF,
  /* E */ 0x01E0, 0x01E1, 0x01E2, 0x01E3, 0x01E5, 0x01E5, 0x01E6, 0x01E7,
          0x01E8, 0x01E9, 0x01EA, 0x01EB, 0x01EC, 0x01ED, 0x01EE, 0x01EF,
  /* F */ 0x01F0, 0x01F3, 0x01F3, 0x01F3, 0x01F4, 0x01F5, 0x01F6, 0x01F7,
          0x01F8, 0x01F9, 0x01FA, 0x01FB, 0x01FC, 0x01FD, 0x01FE, 0x01FF,

  // Table 3 (for high byte 0x03)

  /* 0 */ 0x0300, 0x0301, 0x0302, 0x0303, 0x0304, 0x0305, 0x0306, 0x0307,
          0x0308, 0x0309, 0x030A, 0x030B, 0x030C, 0x030D, 0x030E, 0x030F,
  /* 1 */ 0x0310, 0x0311, 0x0312, 0x0313, 0x0314, 0x0315, 0x0316, 0x0317,
          0x0318, 0x0319, 0x031A, 0x031B, 0x031C, 0x031D, 0x031E, 0x031F,
  /* 2 */ 0x0320, 0x0321, 0x0322, 0x0323, 0x0324, 0x0325, 0x0326, 0x0327,
          0x0328, 0x0329, 0x032A, 0x032B, 0x032C, 0x032D, 0x032E, 0x032F,
  /* 3 */ 0x0330, 0x0331, 0x0332, 0x0333, 0x0334, 0x0335, 0x0336, 0x0337,
          0x0338, 0x0339, 0x033A, 0x033B, 0x033C, 0x033D, 0x033E, 0x033F,
  /* 4 */ 0x0340, 0x0341, 0x0342, 0x0343, 0x0344, 0x0345, 0x0346, 0x0347,
          0x0348, 0x0349, 0x034A, 0x034B, 0x034C, 0x034D, 0x034E, 0x034F,
  /* 5 */ 0x0350, 0x0351, 0x0352, 0x0353, 0x0354, 0x0355, 0x0356, 0x0357,
          0x0358, 0x0359, 0x035A, 0x035B, 0x035C, 0x035D, 0x035E, 0x035F,
  /* 6 */ 0x0360, 0x0361, 0x0362, 0x0363, 0x0364, 0x0365, 0x0366, 0x0367,
          0x0368, 0x0369, 0x036A, 0x036B, 0x036C, 0x036D, 0x036E, 0x036F,
  /* 7 */ 0x0370, 0x0371, 0x0372, 0x0373, 0x0374, 0x0375, 0x0376, 0x0377,
          0x0378, 0x0379, 0x037A, 0x037B, 0x037C, 0x037D, 0x037E, 0x037F,
  /* 8 */ 0x0380, 0x0381, 0x0382, 0x0383, 0x0384, 0x0385, 0x0386, 0x0387,
          0x0388, 0x0389, 0x038A, 0x038B, 0x038C, 0x038D, 0x038E, 0x038F,
  /* 9 */ 0x0390, 0x03B1, 0x03B2, 0x03B3, 0x03B4, 0x03B5, 0x03B6, 0x03B7,
          0x03B8, 0x03B9, 0x03BA, 0x03BB, 0x03BC, 0x03BD, 0x03BE, 0x03BF,
  /* A */ 0x03C0, 0x03C1, 0x03A2, 0x03C3, 0x03C4, 0x03C5, 0x03C6, 0x03C7,
          0x03C8, 0x03C9, 0x03AA, 0x03AB, 0x03AC, 0x03AD, 0x03AE, 0x03AF,
  /* B */ 0x03B0, 0x03B1, 0x03B2, 0x03B3, 0x03B4, 0x03B5, 0x03B6, 0x03B7,
          0x03B8, 0x03B9, 0x03BA, 0x03BB, 0x03BC, 0x03BD, 0x03BE, 0x03BF,
  /* C */ 0x03C0, 0x03C1, 0x03C2, 0x03C3, 0x03C4, 0x03C5, 0x03C6, 0x03C7,
          0x03C8, 0x03C9, 0x03CA, 0x03CB, 0x03CC, 0x03CD, 0x03CE, 0x03CF,
  /* D */ 0x03D0, 0x03D1, 0x03D2, 0x03D3, 0x03D4, 0x03D5, 0x03D6, 0x03D7,
          0x03D8, 0x03D9, 0x03DA, 0x03DB, 0x03DC, 0x03DD, 0x03DE, 0x03DF,
  /* E */ 0x03E0, 0x03E1, 0x03E3, 0x03E3, 0x03E5, 0x03E5, 0x03E7, 0x03E7,
          0x03E9, 0x03E9, 0x03EB, 0x03EB, 0x03ED, 0x03ED, 0x03EF, 0x03EF,
  /* F */ 0x03F0, 0x03F1, 0x03F2, 0x03F3, 0x03F4, 0x03F5, 0x03F6, 0x03F7,
          0x03F8, 0x03F9, 0x03FA, 0x03FB, 0x03FC, 0x03FD, 0x03FE, 0x03FF,

  // Table 4 (for high byte 0x04)

  /* 0 */ 0x0400, 0x0401, 0x0452, 0x0403, 0x0454, 0x0455, 0x0456, 0x0407,
          0x0458, 0x0459, 0x045A, 0x045B, 0x040C, 0x040D, 0x040E, 0x045F,
  /* 1 */ 0x0430, 0x0431, 0x0432, 0x0433, 0x0434, 0x0435, 0x0436, 0x0437,
          0x0438, 0x0419, 0x043A, 0x043B, 0x043C, 0x043D, 0x043E, 0x043F,
  /* 2 */ 0x0440, 0x0441, 0x0442, 0x0443, 0x0444, 0x0445, 0x0446, 0x0447,
          0x0448, 0x0449, 0x044A, 0x044B, 0x044C, 0x044D, 0x044E, 0x044F,
  /* 3 */ 0x0430, 0x0431, 0x0432, 0x0433, 0x0434, 0x0435, 0x0436, 0x0437,
          0x0438, 0x0439, 0x043A, 0x043B, 0x043C, 0x043D, 0x043E, 0x043F,
  /* 4 */ 0x0440, 0x0441, 0x0442, 0x0443, 0x0444, 0x0445, 0x0446, 0x0447,
          0x0448, 0x0449, 0x044A, 0x044B, 0x044C, 0x044D, 0x044E, 0x044F,
  /* 5 */ 0x0450, 0x0451, 0x0452, 0x0453, 0x0454, 0x0455, 0x0456, 0x0457,
          0x0458, 0x0459, 0x045A, 0x045B, 0x045C, 0x045D, 0x045E, 0x045F,
  /* 6 */ 0x0461, 0x0461, 0x0463, 0x0463, 0x0465, 0x0465, 0x0467, 0x0467,
          0x0469, 0x0469, 0x046B, 0x046B, 0x046D, 0x046D, 0x046F, 0x046F,
  /* 7 */ 0x0471, 0x0471, 0x0473, 0x0473, 0x0475, 0x0475, 0x0476, 0x0477,
          0x0479, 0x0479, 0x047B, 0x047B, 0x047D, 0x047D, 0x047F, 0x047F,
  /* 8 */ 0x0481, 0x0481, 0x0482, 0x0483, 0x0484, 0x0485, 0x0486, 0x0487,
          0x0488, 0x0489, 0x048A, 0x048B, 0x048C, 0x048D, 0x048E, 0x048F,
  /* 9 */ 0x0491, 0x0491, 0x0493, 0x0493, 0x0495, 0x0495, 0x0497, 0x0497,
          0x0499, 0x0499, 0x049B, 0x049B, 0x049D, 0x049D, 0x049F, 0x049F,
  /* A */ 0x04A1, 0x04A1, 0x04A3, 0x04A3, 0x04A5, 0x04A5, 0x04A7, 0x04A7,
          0x04A9, 0x04A9, 0x04AB, 0x04AB, 0x04AD, 0x04AD, 0x04AF, 0x04AF,
  /* B */ 0x04B1, 0x04B1, 0x04B3, 0x04B3, 0x04B5, 0x04B5, 0x04B7, 0x04B7,
          0x04B9, 0x04B9, 0x04BB, 0x04BB, 0x04BD, 0x04BD, 0x04BF, 0x04BF,
  /* C */ 0x04C0, 0x04C1, 0x04C2, 0x04C4, 0x04C4, 0x04C5, 0x04C6, 0x04C8,
          0x04C8, 0x04C9, 0x04CA, 0x04CC, 0x04CC, 0x04CD, 0x04CE, 0x04CF,
  /* D */ 0x04D0, 0x04D1, 0x04D2, 0x04D3, 0x04D4, 0x04D5, 0x04D6, 0x04D7,
          0x04D8, 0x04D9, 0x04DA, 0x04DB, 0x04DC, 0x04DD, 0x04DE, 0x04DF,
  /* E */ 0x04E0, 0x04E1, 0x04E2, 0x04E3, 0x04E4, 0x04E5, 0x04E6, 0x04E7,
          0x04E8, 0x04E9, 0x04EA, 0x04EB, 0x04EC, 0x04ED, 0x04EE, 0x04EF,
  /* F */ 0x04F0, 0x04F1, 0x04F2, 0x04F3, 0x04F4, 0x04F5, 0x04F6, 0x04F7,
          0x04F8, 0x04F9, 0x04FA, 0x04FB, 0x04FC, 0x04FD, 0x04FE, 0x04FF,

  // Table 5 (for high byte 0x05)

  /* 0 */ 0x0500, 0x0501, 0x0502, 0x0503, 0x0504, 0x0505, 0x0506, 0x0507,
          0x0508, 0x0509, 0x050A, 0x050B, 0x050C, 0x050D, 0x050E, 0x050F,
  /* 1 */ 0x0510, 0x0511, 0x0512, 0x0513, 0x0514, 0x0515, 0x0516, 0x0517,
          0x0518, 0x0519, 0x051A, 0x051B, 0x051C, 0x051D, 0x051E, 0x051F,
  /* 2 */ 0x0520, 0x0521, 0x0522, 0x0523, 0x0524, 0x0525, 0x0526, 0x0527,
          0x0528, 0x0529, 0x052A, 0x052B, 0x052C, 0x052D, 0x052E, 0x052F,
  /* 3 */ 0x0530, 0x0561, 0x0562, 0x0563, 0x0564, 0x0565, 0x0566, 0x0567,
          0x0568, 0x0569, 0x056A, 0x056B, 0x056C, 0x056D, 0x056E, 0x056F,
  /* 4 */ 0x0570, 0x0571, 0x0572, 0x0573, 0x0574, 0x0575, 0x0576, 0x0577,
          0x0578, 0x0579, 0x057A, 0x057B, 0x057C, 0x057D, 0x057E, 0x057F,
  /* 5 */ 0x0580, 0x0581, 0x0582, 0x0583, 0x0584, 0x0585, 0x0586, 0x0557,
          0x0558, 0x0559, 0x055A, 0x055B, 0x055C, 0x055D, 0x055E, 0x055F,
  /* 6 */ 0x0560, 0x0561, 0x0562, 0x0563, 0x0564, 0x0565, 0x0566, 0x0567,
          0x0568, 0x0569, 0x056A, 0x056B, 0x056C, 0x056D, 0x056E, 0x056F,
  /* 7 */ 0x0570, 0x0571, 0x0572, 0x0573, 0x0574, 0x0575, 0x0576, 0x0577,
          0x0578, 0x0579, 0x057A, 0x057B, 0x057C, 0x057D, 0x057E, 0x057F,
  /* 8 */ 0x0580, 0x0581, 0x0582, 0x0583, 0x0584, 0x0585, 0x0586, 0x0587,
          0x0588, 0x0589, 0x058A, 0x058B, 0x058C, 0x058D, 0x058E, 0x058F,
  /* 9 */ 0x0590, 0x0591, 0x0592, 0x0593, 0x0594, 0x0595, 0x0596, 0x0597,
          0x0598, 0x0599, 0x059A, 0x059B, 0x059C, 0x059D, 0x059E, 0x059F,
  /* A */ 0x05A0, 0x05A1, 0x05A2, 0x05A3, 0x05A4, 0x05A5, 0x05A6, 0x05A7,
          0x05A8, 0x05A9, 0x05AA, 0x05AB, 0x05AC, 0x05AD, 0x05AE, 0x05AF,
  /* B */ 0x05B0, 0x05B1, 0x05B2, 0x05B3, 0x05B4, 0x05B5, 0x05B6, 0x05B7,
          0x05B8, 0x05B9, 0x05BA, 0x05BB, 0x05BC, 0x05BD, 0x05BE, 0x05BF,
  /* C */ 0x05C0, 0x05C1, 0x05C2, 0x05C3, 0x05C4, 0x05C5, 0x05C6, 0x05C7,
          0x05C8, 0x05C9, 0x05CA, 0x05CB, 0x05CC, 0x05CD, 0x05CE, 0x05CF,
  /* D */ 0x05D0, 0x05D1, 0x05D2, 0x05D3, 0x05D4, 0x05D5, 0x05D6, 0x05D7,
          0x05D8, 0x05D9, 0x05DA, 0x05DB, 0x05DC, 0x05DD, 0x05DE, 0x05DF,
  /* E */ 0x05E0, 0x05E1, 0x05E2, 0x05E3, 0x05E4, 0x05E5, 0x05E6, 0x05E7,
          0x05E8, 0x05E9, 0x05EA, 0x05EB, 0x05EC, 0x05ED, 0x05EE, 0x05EF,
  /* F */ 0x05F0, 0x05F1, 0x05F2, 0x05F3, 0x05F4, 0x05F5, 0x05F6, 0x05F7,
          0x05F8, 0x05F9, 0x05FA, 0x05FB, 0x05FC, 0x05FD, 0x05FE, 0x05FF,

  // Table 6 (for high byte 0x10)

  /* 0 */ 0x1000, 0x1001, 0x1002, 0x1003, 0x1004, 0x1005, 0x1006, 0x1007,
          0x1008, 0x1009, 0x100A, 0x100B, 0x100C, 0x100D, 0x100E, 0x100F,
  /* 1 */ 0x1010, 0x1011, 0x1012, 0x1013, 0x1014, 0x1015, 0x1016, 0x1017,
          0x1018, 0x1019, 0x101A, 0x101B, 0x101C, 0x101D, 0x101E, 0x101F,
  /* 2 */ 0x1020, 0x1021, 0x1022, 0x1023, 0x1024, 0x1025, 0x1026, 0x1027,
          0x1028, 0x1029, 0x102A, 0x102B, 0x102C, 0x102D, 0x102E, 0x102F,
  /* 3 */ 0x1030, 0x1031, 0x1032, 0x1033, 0x1034, 0x1035, 0x1036, 0x1037,
          0x1038, 0x1039, 0x103A, 0x103B, 0x103C, 0x103D, 0x103E, 0x103F,
  /* 4 */ 0x1040, 0x1041, 0x1042, 0x1043, 0x1044, 0x1045, 0x1046, 0x1047,
          0x1048, 0x1049, 0x104A, 0x104B, 0x104C, 0x104D, 0x104E, 0x104F,
  /* 5 */ 0x1050, 0x1051, 0x1052, 0x1053, 0x1054, 0x1055, 0x1056, 0x1057,
          0x1058, 0x1059, 0x105A, 0x105B, 0x105C, 0x105D, 0x105E, 0x105F,
  /* 6 */ 0x1060, 0x1061, 0x1062, 0x1063, 0x1064, 0x1065, 0x1066, 0x1067,
          0x1068, 0x1069, 0x106A, 0x106B, 0x106C, 0x106D, 0x106E, 0x106F,
  /* 7 */ 0x1070, 0x1071, 0x1072, 0x1073, 0x1074, 0x1075, 0x1076, 0x1077,
          0x1078, 0x1079, 0x107A, 0x107B, 0x107C, 0x107D, 0x107E, 0x107F,
  /* 8 */ 0x1080, 0x1081, 0x1082, 0x1083, 0x1084, 0x1085, 0x1086, 0x1087,
          0x1088, 0x1089, 0x108A, 0x108B, 0x108C, 0x108D, 0x108E, 0x108F,
  /* 9 */ 0x1090, 0x1091, 0x1092, 0x1093, 0x1094, 0x1095, 0x1096, 0x1097,
          0x1098, 0x1099, 0x109A, 0x109B, 0x109C, 0x109D, 0x109E, 0x109F,
  /* A */ 0x10D0, 0x10D1, 0x10D2, 0x10D3, 0x10D4, 0x10D5, 0x10D6, 0x10D7,
          0x10D8, 0x10D9, 0x10DA, 0x10DB, 0x10DC, 0x10DD, 0x10DE, 0x10DF,
  /* B */ 0x10E0, 0x10E1, 0x10E2, 0x10E3, 0x10E4, 0x10E5, 0x10E6, 0x10E7,
          0x10E8, 0x10E9, 0x10EA, 0x10EB, 0x10EC, 0x10ED, 0x10EE, 0x10EF,
  /* C */ 0x10F0, 0x10F1, 0x10F2, 0x10F3, 0x10F4, 0x10F5, 0x10C6, 0x10C7,
          0x10C8, 0x10C9, 0x10CA, 0x10CB, 0x10CC, 0x10CD, 0x10CE, 0x10CF,
  /* D */ 0x10D0, 0x10D1, 0x10D2, 0x10D3, 0x10D4, 0x10D5, 0x10D6, 0x10D7,
          0x10D8, 0x10D9, 0x10DA, 0x10DB, 0x10DC, 0x10DD, 0x10DE, 0x10DF,
  /* E */ 0x10E0, 0x10E1, 0x10E2, 0x10E3, 0x10E4, 0x10E5, 0x10E6, 0x10E7,
          0x10E8, 0x10E9, 0x10EA, 0x10EB, 0x10EC, 0x10ED, 0x10EE, 0x10EF,
  /* F */ 0x10F0, 0x10F1, 0x10F2, 0x10F3, 0x10F4, 0x10F5, 0x10F6, 0x10F7,
          0x10F8, 0x10F9, 0x10FA, 0x10FB, 0x10FC, 0x10FD, 0x10FE, 0x10FF,

  // Table 7 (for high byte 0x20)

  /* 0 */ 0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006, 0x2007,
          0x2008, 0x2009, 0x200A, 0x200B, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 1 */ 0x2010, 0x2011, 0x2012, 0x2013, 0x2014, 0x2015, 0x2016, 0x2017,
          0x2018, 0x2019, 0x201A, 0x201B, 0x201C, 0x201D, 0x201E, 0x201F,
  /* 2 */ 0x2020, 0x2021, 0x2022, 0x2023, 0x2024, 0x2025, 0x2026, 0x2027,
          0x2028, 0x2029, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x202F,
  /* 3 */ 0x2030, 0x2031, 0x2032, 0x2033, 0x2034, 0x2035, 0x2036, 0x2037,
          0x2038, 0x2039, 0x203A, 0x203B, 0x203C, 0x203D, 0x203E, 0x203F,
  /* 4 */ 0x2040, 0x2041, 0x2042, 0x2043, 0x2044, 0x2045, 0x2046, 0x2047,
          0x2048, 0x2049, 0x204A, 0x204B, 0x204C, 0x204D, 0x204E, 0x204F,
  /* 5 */ 0x2050, 0x2051, 0x2052, 0x2053, 0x2054, 0x2055, 0x2056, 0x2057,
          0x2058, 0x2059, 0x205A, 0x205B, 0x205C, 0x205D, 0x205E, 0x205F,
  /* 6 */ 0x2060, 0x2061, 0x2062, 0x2063, 0x2064, 0x2065, 0x2066, 0x2067,
          0x2068, 0x2069, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
  /* 7 */ 0x2070, 0x2071, 0x2072, 0x2073, 0x2074, 0x2075, 0x2076, 0x2077,
          0x2078, 0x2079, 0x207A, 0x207B, 0x207C, 0x207D, 0x207E, 0x207F,
  /* 8 */ 0x2080, 0x2081, 0x2082, 0x2083, 0x2084, 0x2085, 0x2086, 0x2087,
          0x2088, 0x2089, 0x208A, 0x208B, 0x208C, 0x208D, 0x208E, 0x208F,
  /* 9 */ 0x2090, 0x2091, 0x2092, 0x2093, 0x2094, 0x2095, 0x2096, 0x2097,
          0x2098, 0x2099, 0x209A, 0x209B, 0x209C, 0x209D, 0x209E, 0x209F,
  /* A */ 0x20A0, 0x20A1, 0x20A2, 0x20A3, 0x20A4, 0x20A5, 0x20A6, 0x20A7,
          0x20A8, 0x20A9, 0x20AA, 0x20AB, 0x20AC, 0x20AD, 0x20AE, 0x20AF,
  /* B */ 0x20B0, 0x20B1, 0x20B2, 0x20B3, 0x20B4, 0x20B5, 0x20B6, 0x20B7,
          0x20B8, 0x20B9, 0x20BA, 0x20BB, 0x20BC, 0x20BD, 0x20BE, 0x20BF,
  /* C */ 0x20C0, 0x20C1, 0x20C2, 0x20C3, 0x20C4, 0x20C5, 0x20C6, 0x20C7,
          0x20C8, 0x20C9, 0x20CA, 0x20CB, 0x20CC, 0x20CD, 0x20CE, 0x20CF,
  /* D */ 0x20D0, 0x20D1, 0x20D2, 0x20D3, 0x20D4, 0x20D5, 0x20D6, 0x20D7,
          0x20D8, 0x20D9, 0x20DA, 0x20DB, 0x20DC, 0x20DD, 0x20DE, 0x20DF,
  /* E */ 0x20E0, 0x20E1, 0x20E2, 0x20E3, 0x20E4, 0x20E5, 0x20E6, 0x20E7,
          0x20E8, 0x20E9, 0x20EA, 0x20EB, 0x20EC, 0x20ED, 0x20EE, 0x20EF,
  /* F */ 0x20F0, 0x20F1, 0x20F2, 0x20F3, 0x20F4, 0x20F5, 0x20F6, 0x20F7,
          0x20F8, 0x20F9, 0x20FA, 0x20FB, 0x20FC, 0x20FD, 0x20FE, 0x20FF,

  // Table 8 (for high byte 0x21)

  /* 0 */ 0x2100, 0x2101, 0x2102, 0x2103, 0x2104, 0x2105, 0x2106, 0x2107,
          0x2108, 0x2109, 0x210A, 0x210B, 0x210C, 0x210D, 0x210E, 0x210F,
  /* 1 */ 0x2110, 0x2111, 0x2112, 0x2113, 0x2114, 0x2115, 0x2116, 0x2117,
          0x2118, 0x2119, 0x211A, 0x211B, 0x211C, 0x211D, 0x211E, 0x211F,
  /* 2 */ 0x2120, 0x2121, 0x2122, 0x2123, 0x2124, 0x2125, 0x2126, 0x2127,
          0x2128, 0x2129, 0x212A, 0x212B, 0x212C, 0x212D, 0x212E, 0x212F,
  /* 3 */ 0x2130, 0x2131, 0x2132, 0x2133, 0x2134, 0x2135, 0x2136, 0x2137,
          0x2138, 0x2139, 0x213A, 0x213B, 0x213C, 0x213D, 0x213E, 0x213F,
  /* 4 */ 0x2140, 0x2141, 0x2142, 0x2143, 0x2144, 0x2145, 0x2146, 0x2147,
          0x2148, 0x2149, 0x214A, 0x214B, 0x214C, 0x214D, 0x214E, 0x214F,
  /* 5 */ 0x2150, 0x2151, 0x2152, 0x2153, 0x2154, 0x2155, 0x2156, 0x2157,
          0x2158, 0x2159, 0x215A, 0x215B, 0x215C, 0x215D, 0x215E, 0x215F,
  /* 6 */ 0x2170, 0x2171, 0x2172, 0x2173, 0x2174, 0x2175, 0x2176, 0x2177,
          0x2178, 0x2179, 0x217A, 0x217B, 0x217C, 0x217D, 0x217E, 0x217F,
  /* 7 */ 0x2170, 0x2171, 0x2172, 0x2173, 0x2174, 0x2175, 0x2176, 0x2177,
          0x2178, 0x2179, 0x217A, 0x217B, 0x217C, 0x217D, 0x217E, 0x217F,
  /* 8 */ 0x2180, 0x2181, 0x2182, 0x2183, 0x2184, 0x2185, 0x2186, 0x2187,
          0x2188, 0x2189, 0x218A, 0x218B, 0x218C, 0x218D, 0x218E, 0x218F,
  /* 9 */ 0x2190, 0x2191, 0x2192, 0x2193, 0x2194, 0x2195, 0x2196, 0x2197,
          0x2198, 0x2199, 0x219A, 0x219B, 0x219C, 0x219D, 0x219E, 0x219F,
  /* A */ 0x21A0, 0x21A1, 0x21A2, 0x21A3, 0x21A4, 0x21A5, 0x21A6, 0x21A7,
          0x21A8, 0x21A9, 0x21AA, 0x21AB, 0x21AC, 0x21AD, 0x21AE, 0x21AF,
  /* B */ 0x21B0, 0x21B1, 0x21B2, 0x21B3, 0x21B4, 0x21B5, 0x21B6, 0x21B7,
          0x21B8, 0x21B9, 0x21BA, 0x21BB, 0x21BC, 0x21BD, 0x21BE, 0x21BF,
  /* C */ 0x21C0, 0x21C1, 0x21C2, 0x21C3, 0x21C4, 0x21C5, 0x21C6, 0x21C7,
          0x21C8, 0x21C9, 0x21CA, 0x21CB, 0x21CC, 0x21CD, 0x21CE, 0x21CF,
  /* D */ 0x21D0, 0x21D1, 0x21D2, 0x21D3, 0x21D4, 0x21D5, 0x21D6, 0x21D7,
          0x21D8, 0x21D9, 0x21DA, 0x21DB, 0x21DC, 0x21DD, 0x21DE, 0x21DF,
  /* E */ 0x21E0, 0x21E1, 0x21E2, 0x21E3, 0x21E4, 0x21E5, 0x21E6, 0x21E7,
          0x21E8, 0x21E9, 0x21EA, 0x21EB, 0x21EC, 0x21ED, 0x21EE, 0x21EF,
  /* F */ 0x21F0, 0x21F1, 0x21F2, 0x21F3, 0x21F4, 0x21F5, 0x21F6, 0x21F7,
          0x21F8, 0x21F9, 0x21FA, 0x21FB, 0x21FC, 0x21FD, 0x21FE, 0x21FF,

  // Table 9 (for high byte 0xFE)

  /* 0 */ 0xFE00, 0xFE01, 0xFE02, 0xFE03, 0xFE04, 0xFE05, 0xFE06, 0xFE07,
          0xFE08, 0xFE09, 0xFE0A, 0xFE0B, 0xFE0C, 0xFE0D, 0xFE0E, 0xFE0F,
  /* 1 */ 0xFE10, 0xFE11, 0xFE12, 0xFE13, 0xFE14, 0xFE15, 0xFE16, 0xFE17,
          0xFE18, 0xFE19, 0xFE1A, 0xFE1B, 0xFE1C, 0xFE1D, 0xFE1E, 0xFE1F,
  /* 2 */ 0xFE20, 0xFE21, 0xFE22, 0xFE23, 0xFE24, 0xFE25, 0xFE26, 0xFE27,
          0xFE28, 0xFE29, 0xFE2A, 0xFE2B, 0xFE2C, 0xFE2D, 0xFE2E, 0xFE2F,
  /* 3 */ 0xFE30, 0xFE31, 0xFE32, 0xFE33, 0xFE34, 0xFE35, 0xFE36, 0xFE37,
          0xFE38, 0xFE39, 0xFE3A, 0xFE3B, 0xFE3C, 0xFE3D, 0xFE3E, 0xFE3F,
  /* 4 */ 0xFE40, 0xFE41, 0xFE42, 0xFE43, 0xFE44, 0xFE45, 0xFE46, 0xFE47,
          0xFE48, 0xFE49, 0xFE4A, 0xFE4B, 0xFE4C, 0xFE4D, 0xFE4E, 0xFE4F,
  /* 5 */ 0xFE50, 0xFE51, 0xFE52, 0xFE53, 0xFE54, 0xFE55, 0xFE56, 0xFE57,
          0xFE58, 0xFE59, 0xFE5A, 0xFE5B, 0xFE5C, 0xFE5D, 0xFE5E, 0xFE5F,
  /* 6 */ 0xFE60, 0xFE61, 0xFE62, 0xFE63, 0xFE64, 0xFE65, 0xFE66, 0xFE67,
          0xFE68, 0xFE69, 0xFE6A, 0xFE6B, 0xFE6C, 0xFE6D, 0xFE6E, 0xFE6F,
  /* 7 */ 0xFE70, 0xFE71, 0xFE72, 0xFE73, 0xFE74, 0xFE75, 0xFE76, 0xFE77,
          0xFE78, 0xFE79, 0xFE7A, 0xFE7B, 0xFE7C, 0xFE7D, 0xFE7E, 0xFE7F,
  /* 8 */ 0xFE80, 0xFE81, 0xFE82, 0xFE83, 0xFE84, 0xFE85, 0xFE86, 0xFE87,
          0xFE88, 0xFE89, 0xFE8A, 0xFE8B, 0xFE8C, 0xFE8D, 0xFE8E, 0xFE8F,
  /* 9 */ 0xFE90, 0xFE91, 0xFE92, 0xFE93, 0xFE94, 0xFE95, 0xFE96, 0xFE97,
          0xFE98, 0xFE99, 0xFE9A, 0xFE9B, 0xFE9C, 0xFE9D, 0xFE9E, 0xFE9F,
  /* A */ 0xFEA0, 0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4, 0xFEA5, 0xFEA6, 0xFEA7,
          0xFEA8, 0xFEA9, 0xFEAA, 0xFEAB, 0xFEAC, 0xFEAD, 0xFEAE, 0xFEAF,
  /* B */ 0xFEB0, 0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4, 0xFEB5, 0xFEB6, 0xFEB7,
          0xFEB8, 0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC, 0xFEBD, 0xFEBE, 0xFEBF,
  /* C */ 0xFEC0, 0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4, 0xFEC5, 0xFEC6, 0xFEC7,
          0xFEC8, 0xFEC9, 0xFECA, 0xFECB, 0xFECC, 0xFECD, 0xFECE, 0xFECF,
  /* D */ 0xFED0, 0xFED1, 0xFED2, 0xFED3, 0xFED4, 0xFED5, 0xFED6, 0xFED7,
          0xFED8, 0xFED9, 0xFEDA, 0xFEDB, 0xFEDC, 0xFEDD, 0xFEDE, 0xFEDF,
  /* E */ 0xFEE0, 0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4, 0xFEE5, 0xFEE6, 0xFEE7,
          0xFEE8, 0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC, 0xFEED, 0xFEEE, 0xFEEF,
  /* F */ 0xFEF0, 0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4, 0xFEF5, 0xFEF6, 0xFEF7,
          0xFEF8, 0xFEF9, 0xFEFA, 0xFEFB, 0xFEFC, 0xFEFD, 0xFEFE, 0x0000,

  // Table 10 (for high byte 0xFF)

  /* 0 */ 0xFF00, 0xFF01, 0xFF02, 0xFF03, 0xFF04, 0xFF05, 0xFF06, 0xFF07,
          0xFF08, 0xFF09, 0xFF0A, 0xFF0B, 0xFF0C, 0xFF0D, 0xFF0E, 0xFF0F,
  /* 1 */ 0xFF10, 0xFF11, 0xFF12, 0xFF13, 0xFF14, 0xFF15, 0xFF16, 0xFF17,
          0xFF18, 0xFF19, 0xFF1A, 0xFF1B, 0xFF1C, 0xFF1D, 0xFF1E, 0xFF1F,
  /* 2 */ 0xFF20, 0xFF41, 0xFF42, 0xFF43, 0xFF44, 0xFF45, 0xFF46, 0xFF47,
          0xFF48, 0xFF49, 0xFF4A, 0xFF4B, 0xFF4C, 0xFF4D, 0xFF4E, 0xFF4F,
  /* 3 */ 0xFF50, 0xFF51, 0xFF52, 0xFF53, 0xFF54, 0xFF55, 0xFF56, 0xFF57,
          0xFF58, 0xFF59, 0xFF5A, 0xFF3B, 0xFF3C, 0xFF3D, 0xFF3E, 0xFF3F,
  /* 4 */ 0xFF40, 0xFF41, 0xFF42, 0xFF43, 0xFF44, 0xFF45, 0xFF46, 0xFF47,
          0xFF48, 0xFF49, 0xFF4A, 0xFF4B, 0xFF4C, 0xFF4D, 0xFF4E, 0xFF4F,
  /* 5 */ 0xFF50, 0xFF51, 0xFF52, 0xFF53, 0xFF54, 0xFF55, 0xFF56, 0xFF57,
          0xFF58, 0xFF59, 0xFF5A, 0xFF5B, 0xFF5C, 0xFF5D, 0xFF5E, 0xFF5F,
  /* 6 */ 0xFF60, 0xFF61, 0xFF62, 0xFF63, 0xFF64, 0xFF65, 0xFF66, 0xFF67,
          0xFF68, 0xFF69, 0xFF6A, 0xFF6B, 0xFF6C, 0xFF6D, 0xFF6E, 0xFF6F,
  /* 7 */ 0xFF70, 0xFF71, 0xFF72, 0xFF73, 0xFF74, 0xFF75, 0xFF76, 0xFF77,
          0xFF78, 0xFF79, 0xFF7A, 0xFF7B, 0xFF7C, 0xFF7D, 0xFF7E, 0xFF7F,
  /* 8 */ 0xFF80, 0xFF81, 0xFF82, 0xFF83, 0xFF84, 0xFF85, 0xFF86, 0xFF87,
          0xFF88, 0xFF89, 0xFF8A, 0xFF8B, 0xFF8C, 0xFF8D, 0xFF8E, 0xFF8F,
  /* 9 */ 0xFF90, 0xFF91, 0xFF92, 0xFF93, 0xFF94, 0xFF95, 0xFF96, 0xFF97,
          0xFF98, 0xFF99, 0xFF9A, 0xFF9B, 0xFF9C, 0xFF9D, 0xFF9E, 0xFF9F,
  /* A */ 0xFFA0, 0xFFA1, 0xFFA2, 0xFFA3, 0xFFA4, 0xFFA5, 0xFFA6, 0xFFA7,
          0xFFA8, 0xFFA9, 0xFFAA, 0xFFAB, 0xFFAC, 0xFFAD, 0xFFAE, 0xFFAF,
  /* B */ 0xFFB0, 0xFFB1, 0xFFB2, 0xFFB3, 0xFFB4, 0xFFB5, 0xFFB6, 0xFFB7,
          0xFFB8, 0xFFB9, 0xFFBA, 0xFFBB, 0xFFBC, 0xFFBD, 0xFFBE, 0xFFBF,
  /* C */ 0xFFC0, 0xFFC1, 0xFFC2, 0xFFC3, 0xFFC4, 0xFFC5, 0xFFC6, 0xFFC7,
          0xFFC8, 0xFFC9, 0xFFCA, 0xFFCB, 0xFFCC, 0xFFCD, 0xFFCE, 0xFFCF,
  /* D */ 0xFFD0, 0xFFD1, 0xFFD2, 0xFFD3, 0xFFD4, 0xFFD5, 0xFFD6, 0xFFD7,
          0xFFD8, 0xFFD9, 0xFFDA, 0xFFDB, 0xFFDC, 0xFFDD, 0xFFDE, 0xFFDF,
  /* E */ 0xFFE0, 0xFFE1, 0xFFE2, 0xFFE3, 0xFFE4, 0xFFE5, 0xFFE6, 0xFFE7,
          0xFFE8, 0xFFE9, 0xFFEA, 0xFFEB, 0xFFEC, 0xFFED, 0xFFEE, 0xFFEF,
  /* F */ 0xFFF0, 0xFFF1, 0xFFF2, 0xFFF3, 0xFFF4, 0xFFF5, 0xFFF6, 0xFFF7,
          0xFFF8, 0xFFF9, 0xFFFA, 0xFFFB, 0xFFFC, 0xFFFD, 0xFFFE, 0xFFFF,
};

// Returns the next non-ignorable codepoint within string starting from the
// position indicated by index, or zero if there are no more.
// The passed-in index is automatically advanced as the characters in the input
// HFS-decomposed UTF-8 strings are read.
inline int HFSReadNextNonIgnorableCodepoint(const char* string,
                                            int length,
                                            int* index) {
  int codepoint = 0;
  while (*index < length && codepoint == 0) {
    // CBU8_NEXT returns a value < 0 in error cases. For purposes of string
    // comparison, we just use that value and flag it with DCHECK.
    CBU8_NEXT(string, *index, length, codepoint);
    DCHECK_GT(codepoint, 0);
    if (codepoint > 0) {
      // Check if there is a subtable for this upper byte.
      int lookup_offset = lower_case_table[codepoint >> 8];
      if (lookup_offset != 0)
        codepoint = lower_case_table[lookup_offset + (codepoint & 0x00FF)];
      // Note: codepoint1 may be again 0 at this point if the character was
      // an ignorable.
    }
  }
  return codepoint;
}

}  // anonymous namespace

// Special UTF-8 version of FastUnicodeCompare. Cf:
// http://developer.apple.com/mac/library/technotes/tn/tn1150.html#StringComparisonAlgorithm
// The input strings must be in the special HFS decomposed form.
int FilePath::HFSFastUnicodeCompare(const StringType& string1,
                                    const StringType& string2) {
  int length1 = string1.length();
  int length2 = string2.length();
  int index1 = 0;
  int index2 = 0;

  for (;;) {
    int codepoint1 = HFSReadNextNonIgnorableCodepoint(string1.c_str(),
                                                      length1,
                                                      &index1);
    int codepoint2 = HFSReadNextNonIgnorableCodepoint(string2.c_str(),
                                                      length2,
                                                      &index2);
    if (codepoint1 != codepoint2)
      return (codepoint1 < codepoint2) ? -1 : 1;
    if (codepoint1 == 0) {
      DCHECK_EQ(index1, length1);
      DCHECK_EQ(index2, length2);
      return 0;
    }
  }
}

StringType FilePath::GetHFSDecomposedForm(const StringType& string) {
  ScopedCFTypeRef<CFStringRef> cfstring(
      CFStringCreateWithBytesNoCopy(
          NULL,
          reinterpret_cast<const UInt8*>(string.c_str()),
          string.length(),
          kCFStringEncodingUTF8,
          false,
          kCFAllocatorNull));
  // Query the maximum length needed to store the result. In most cases this
  // will overestimate the required space. The return value also already
  // includes the space needed for a terminating 0.
  CFIndex length = CFStringGetMaximumSizeOfFileSystemRepresentation(cfstring);
  DCHECK_GT(length, 0);  // should be at least 1 for the 0-terminator.
  // Reserve enough space for CFStringGetFileSystemRepresentation to write into.
  // Also set the length to the maximum so that we can shrink it later.
  // (Increasing rather than decreasing it would clobber the string contents!)
  StringType result;
  result.reserve(length);
  result.resize(length - 1);
  Boolean success = CFStringGetFileSystemRepresentation(cfstring,
                                                        &result[0],
                                                        length);
  if (success) {
    // Reduce result.length() to actual string length.
    result.resize(strlen(result.c_str()));
  } else {
    // An error occurred -> clear result.
    result.clear();
  }
  return result;
}

int FilePath::CompareIgnoreCase(const StringType& string1,
                                const StringType& string2) {
  // Quick checks for empty strings - these speed things up a bit and make the
  // following code cleaner.
  if (string1.empty())
    return string2.empty() ? 0 : -1;
  if (string2.empty())
    return 1;

  StringType hfs1 = GetHFSDecomposedForm(string1);
  StringType hfs2 = GetHFSDecomposedForm(string2);

  // GetHFSDecomposedForm() returns an empty string in an error case.
  if (hfs1.empty() || hfs2.empty()) {
    NOTREACHED();
    ScopedCFTypeRef<CFStringRef> cfstring1(
        CFStringCreateWithBytesNoCopy(
            NULL,
            reinterpret_cast<const UInt8*>(string1.c_str()),
            string1.length(),
            kCFStringEncodingUTF8,
            false,
            kCFAllocatorNull));
    ScopedCFTypeRef<CFStringRef> cfstring2(
        CFStringCreateWithBytesNoCopy(
            NULL,
            reinterpret_cast<const UInt8*>(string2.c_str()),
            string2.length(),
            kCFStringEncodingUTF8,
            false,
            kCFAllocatorNull));
    return CFStringCompare(cfstring1,
                           cfstring2,
                           kCFCompareCaseInsensitive);
  }

  return HFSFastUnicodeCompare(hfs1, hfs2);
}

#else  // << WIN. MACOSX | other (POSIX) >>

// Generic (POSIX) implementation of file string comparison.
// TODO(rolandsteiner) check if this is sufficient/correct.
int FilePath::CompareIgnoreCase(const StringType& string1,
                                const StringType& string2) {
  int comparison = strcasecmp(string1.c_str(), string2.c_str());
  if (comparison < 0)
    return -1;
  if (comparison > 0)
    return 1;
  return 0;
}

#endif  // OS versions of CompareIgnoreCase()


void FilePath::StripTrailingSeparatorsInternal() {
  // If there is no drive letter, start will be 1, which will prevent stripping
  // the leading separator if there is only one separator.  If there is a drive
  // letter, start will be set appropriately to prevent stripping the first
  // separator following the drive letter, if a separator immediately follows
  // the drive letter.
  StringType::size_type start = FindDriveLetter(path_) + 2;

  StringType::size_type last_stripped = StringType::npos;
  for (StringType::size_type pos = path_.length();
       pos > start && IsSeparator(path_[pos - 1]);
       --pos) {
    // If the string only has two separators and they're at the beginning,
    // don't strip them, unless the string began with more than two separators.
    if (pos != start + 1 || last_stripped == start + 2 ||
        !IsSeparator(path_[start - 1])) {
      path_.resize(pos - 1);
      last_stripped = pos;
    }
  }
}

FilePath FilePath::NormalizePathSeparators() const {
  return NormalizePathSeparatorsTo(kSeparators[0]);
}

FilePath FilePath::NormalizePathSeparatorsTo(CharType separator) const {
#if defined(FILE_PATH_USES_WIN_SEPARATORS)
  DCHECK_NE(kSeparators + kSeparatorsLength,
            std::find(kSeparators, kSeparators + kSeparatorsLength, separator));
  StringType copy = path_;
  for (size_t i = 0; i < kSeparatorsLength; ++i) {
    std::replace(copy.begin(), copy.end(), kSeparators[i], separator);
  }
  return FilePath(copy);
#else
  return *this;
#endif
}

#if defined(OS_ANDROID)
bool FilePath::IsContentUri() const {
  return StartsWithASCII(path_, "content://", false /*case_sensitive*/);
}
#endif

}  // namespace base

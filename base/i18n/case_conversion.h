// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_I18N_CASE_CONVERSION_H_
#define BASE_I18N_CASE_CONVERSION_H_

#include "base/i18n/base_i18n_export.h"
#include "base/strings/string16.h"
#include "base/strings/string_piece.h"

namespace base {
namespace i18n {

// UNICODE CASE-HANDLING ADVICE
//
// In English it's always safe to convert to upper-case or lower-case text
// and get a good answer. But some languages have rules specific to those
// locales. One example is the Turkish I:
//   http://www.i18nguy.com/unicode/turkish-i18n.html
//
// ToLower/ToUpper use the current ICU locale which will take into account
// the user language preference. Use this when dealing with user typing.
//
// FoldCase canonicalizes to a standardized form independent of the current
// locale. Use this when comparing general Unicode strings that don't
// necessarily belong in the user's current locale (like commands, protocol
// names, other strings from the web) for case-insensitive equality.
//
// Note that case conversions will change the length of the string in some
// not-uncommon cases. Never assume that the output is the same length as
// the input.

// Returns the lower case equivalent of string. Uses ICU's current locale.
BASE_I18N_EXPORT string16 ToLower(StringPiece16 string);

// Returns the upper case equivalent of string. Uses ICU's current locale.
BASE_I18N_EXPORT string16 ToUpper(StringPiece16 string);

// Convert the given string to a canonical case, independent of the current
// locale. For ASCII the canonical form is lower case.
// See http://unicode.org/faq/casemap_charprop.html#2
BASE_I18N_EXPORT string16 FoldCase(StringPiece16 string);

}  // namespace i18n
}  // namespace base

#endif  // BASE_I18N_CASE_CONVERSION_H_

// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_URL_CANON_STDSTRING_H_
#define URL_URL_CANON_STDSTRING_H_

// This header file defines a canonicalizer output method class for STL
// strings. Because the canonicalizer tries not to be dependent on the STL,
// we have segregated it here.

#include <string>

#include "base/compiler_specific.h"
#include "base/strings/string_piece.h"
#include "url/url_canon.h"
#include "url/url_export.h"

namespace url {

// Write into a std::string given in the constructor. This object does not own
// the string itself, and the user must ensure that the string stays alive
// throughout the lifetime of this object.
//
// The given string will be appended to; any existing data in the string will
// be preserved. The caller should reserve() the amount of data in the string
// they expect to be written. We will resize if necessary, but that's slow.
//
// Note that when canonicalization is complete, the string will likely have
// unused space at the end because we make the string very big to start out
// with (by |initial_size|). This ends up being important because resize
// operations are slow, and because the base class needs to write directly
// into the buffer.
//
// Therefore, the user should call Complete() before using the string that
// this class wrote into.
class URL_EXPORT StdStringCanonOutput : public CanonOutput {
 public:
  StdStringCanonOutput(std::string* str);
  ~StdStringCanonOutput() override;

  // Must be called after writing has completed but before the string is used.
  void Complete();

  void Resize(int sz) override;

 protected:
  std::string* str_;
};

// An extension of the Replacements class that allows the setters to use
// StringPieces (implicitly allowing strings or char*s).
//
// The contents of the StringPieces are not copied and must remain valid until
// the StringPieceReplacements object goes out of scope.
template<typename STR>
class StringPieceReplacements : public Replacements<typename STR::value_type> {
 public:
  void SetSchemeStr(const base::BasicStringPiece<STR>& s) {
    this->SetScheme(s.data(), Component(0, static_cast<int>(s.length())));
  }
  void SetUsernameStr(const base::BasicStringPiece<STR>& s) {
    this->SetUsername(s.data(), Component(0, static_cast<int>(s.length())));
  }
  void SetPasswordStr(const base::BasicStringPiece<STR>& s) {
    this->SetPassword(s.data(), Component(0, static_cast<int>(s.length())));
  }
  void SetHostStr(const base::BasicStringPiece<STR>& s) {
    this->SetHost(s.data(), Component(0, static_cast<int>(s.length())));
  }
  void SetPortStr(const base::BasicStringPiece<STR>& s) {
    this->SetPort(s.data(), Component(0, static_cast<int>(s.length())));
  }
  void SetPathStr(const base::BasicStringPiece<STR>& s) {
    this->SetPath(s.data(), Component(0, static_cast<int>(s.length())));
  }
  void SetQueryStr(const base::BasicStringPiece<STR>& s) {
    this->SetQuery(s.data(), Component(0, static_cast<int>(s.length())));
  }
  void SetRefStr(const base::BasicStringPiece<STR>& s) {
    this->SetRef(s.data(), Component(0, static_cast<int>(s.length())));
  }
};

}  // namespace url

#endif  // URL_URL_CANON_STDSTRING_H_

/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "wtf/testing/WTFTestHelpers.h"

#include <ios>      // NOLINT
#include <ostream>  // NOLINT
#include "flutter/sky/engine/wtf/text/WTFString.h"

namespace WTF {

std::ostream& operator<<(std::ostream& out, const String& string) {
  if (string.isNull())
    return out << "<null>";

  out << '"';
  for (unsigned index = 0; index < string.length(); ++index) {
    // Print shorthands for select cases.
    UChar character = string[index];
    switch (character) {
      case '\t':
        out << "\\t";
        break;
      case '\n':
        out << "\\n";
        break;
      case '\r':
        out << "\\r";
        break;
      case '"':
        out << "\\\"";
        break;
      case '\\':
        out << "\\\\";
        break;
      default:
        if (character >= 0x20 && character < 0x7F) {
          out << static_cast<char>(character);
        } else {
          // Print "\uXXXX" for control or non-ASCII characters.
          out << "\\u";
          out.width(4);
          out.fill('0');
          out.setf(std::ios_base::hex, std::ios_base::basefield);
          out.setf(std::ios::uppercase);
          out << character;
        }
        break;
    }
  }
  return out << '"';
}

}  // namespace WTF

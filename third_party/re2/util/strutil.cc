// Copyright 1999-2005 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "util/util.h"
#include "re2/stringpiece.h"

namespace re2 {

// ----------------------------------------------------------------------
// CEscapeString()
//    Copies 'src' to 'dest', escaping dangerous characters using
//    C-style escape sequences.  'src' and 'dest' should not overlap.
//    Returns the number of bytes written to 'dest' (not including the \0)
//    or -1 if there was insufficient space.
// ----------------------------------------------------------------------
int CEscapeString(const char* src, int src_len, char* dest,
                  int dest_len) {
  const char* src_end = src + src_len;
  int used = 0;

  for (; src < src_end; src++) {
    if (dest_len - used < 2)   // Need space for two letter escape
      return -1;

    unsigned char c = *src;
    switch (c) {
      case '\n': dest[used++] = '\\'; dest[used++] = 'n';  break;
      case '\r': dest[used++] = '\\'; dest[used++] = 'r';  break;
      case '\t': dest[used++] = '\\'; dest[used++] = 't';  break;
      case '\"': dest[used++] = '\\'; dest[used++] = '\"'; break;
      case '\'': dest[used++] = '\\'; dest[used++] = '\''; break;
      case '\\': dest[used++] = '\\'; dest[used++] = '\\'; break;
      default:
        // Note that if we emit \xNN and the src character after that is a hex
        // digit then that digit must be escaped too to prevent it being
        // interpreted as part of the character code by C.
        if (c < ' ' || c > '~') {
          if (dest_len - used < 4) // need space for 4 letter escape
            return -1;
          sprintf(dest + used, "\\%03o", c);
          used += 4;
        } else {
          dest[used++] = c; break;
        }
    }
  }

  if (dest_len - used < 1)   // make sure that there is room for \0
    return -1;

  dest[used] = '\0';   // doesn't count towards return value though
  return used;
}


// ----------------------------------------------------------------------
// CEscape()
//    Copies 'src' to result, escaping dangerous characters using
//    C-style escape sequences.  'src' and 'dest' should not overlap. 
// ----------------------------------------------------------------------
string CEscape(const StringPiece& src) {
  const int dest_length = src.size() * 4 + 1; // Maximum possible expansion
  char* dest = new char[dest_length];
  const int len = CEscapeString(src.data(), src.size(),
                                dest, dest_length);
  string s = string(dest, len);
  delete[] dest;
  return s;
}

string PrefixSuccessor(const StringPiece& prefix) {
  // We can increment the last character in the string and be done
  // unless that character is 255, in which case we have to erase the
  // last character and increment the previous character, unless that
  // is 255, etc. If the string is empty or consists entirely of
  // 255's, we just return the empty string.
  bool done = false;
  string limit(prefix.data(), prefix.size());
  int index = limit.length() - 1;
  while (!done && index >= 0) {
    if ((limit[index]&255) == 255) {
      limit.erase(index);
      index--;
    } else {
      limit[index]++;
      done = true;
    }
  }
  if (!done) {
    return "";
  } else {
    return limit;
  }
}

}  // namespace re2

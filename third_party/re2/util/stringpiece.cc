// Copyright 2004 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "re2/stringpiece.h"
#include "util/util.h"

using re2::StringPiece;

std::ostream& operator<<(std::ostream& o, const StringPiece& piece) {
  o.write(piece.data(), piece.size());
  return o;
}

bool StringPiece::_equal(const StringPiece& x, const StringPiece& y) {
  int len = x.size();
  if (len != y.size()) {
    return false;
  }
  const char* p = x.data();
  const char* p2 = y.data();
  // Test last byte in case strings share large common prefix
  if ((len > 0) && (p[len-1] != p2[len-1])) return false;
  const char* p_limit = p + len;
  for (; p < p_limit; p++, p2++) {
    if (*p != *p2)
      return false;
  }
  return true;
}

void StringPiece::CopyToString(string* target) const {
  target->assign(ptr_, length_);
}

int StringPiece::copy(char* buf, size_type n, size_type pos) const {
  int ret = min(length_ - pos, n);
  memcpy(buf, ptr_ + pos, ret);
  return ret;
}

int StringPiece::find(const StringPiece& s, size_type pos) const {
  if (length_ < 0 || pos > static_cast<size_type>(length_))
    return npos;

  const char* result = std::search(ptr_ + pos, ptr_ + length_,
                                   s.ptr_, s.ptr_ + s.length_);
  const size_type xpos = result - ptr_;
  return xpos + s.length_ <= length_ ? xpos : npos;
}

int StringPiece::find(char c, size_type pos) const {
  if (length_ <= 0 || pos >= static_cast<size_type>(length_)) {
    return npos;
  }
  const char* result = std::find(ptr_ + pos, ptr_ + length_, c);
  return result != ptr_ + length_ ? result - ptr_ : npos;
}

int StringPiece::rfind(const StringPiece& s, size_type pos) const {
  if (length_ < s.length_) return npos;
  const size_t ulen = length_;
  if (s.length_ == 0) return min(ulen, pos);

  const char* last = ptr_ + min(ulen - s.length_, pos) + s.length_;
  const char* result = std::find_end(ptr_, last, s.ptr_, s.ptr_ + s.length_);
  return result != last ? result - ptr_ : npos;
}

int StringPiece::rfind(char c, size_type pos) const {
  if (length_ <= 0) return npos;
  for (int i = min(pos, static_cast<size_type>(length_ - 1));
       i >= 0; --i) {
    if (ptr_[i] == c) {
      return i;
    }
  }
  return npos;
}

StringPiece StringPiece::substr(size_type pos, size_type n) const {
  if (pos > length_) pos = length_;
  if (n > length_ - pos) n = length_ - pos;
  return StringPiece(ptr_ + pos, n);
}

const StringPiece::size_type StringPiece::npos = size_type(-1);

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/string_view.h"

#include <string.h>

#include <algorithm>
#include <limits>

namespace fml {

constexpr size_t StringView::npos;

namespace {

// For each character in characters_wanted, sets the index corresponding
// to the code for that character to 1 in table.  This is used by the
// find_.*_of methods below to tell whether or not a character is in the lookup
// table in constant time.
// The argument `table' must be an array that is large enough to hold all
// the possible values of an unsigned char.  Thus it should be be declared
// as follows:
//   bool table[std::numeric_limits<unsigned char>::max() + 1]
inline void BuildLookupTable(StringView characters_wanted, bool* table) {
  size_t length = characters_wanted.size();
  const char* data = characters_wanted.data();
  for (size_t i = 0; i < length; ++i) {
    table[static_cast<unsigned char>(data[i])] = true;
  }
}

}  // namespace

int StringView::compare(StringView other) {
  size_t len = std::min(size_, other.size_);
  int retval = memcmp(data_, other.data_, len);
  if (retval == 0) {
    if (size_ == other.size_) {
      return 0;
    }
    return size_ < other.size_ ? -1 : 1;
  }
  return retval;
}

bool operator==(StringView lhs, StringView rhs) {
  if (lhs.size() != rhs.size())
    return false;
  return lhs.compare(rhs) == 0;
}

bool operator!=(StringView lhs, StringView rhs) {
  if (lhs.size() != rhs.size())
    return true;
  return lhs.compare(rhs) != 0;
}

bool operator<(StringView lhs, StringView rhs) {
  return lhs.compare(rhs) < 0;
}

bool operator>(StringView lhs, StringView rhs) {
  return lhs.compare(rhs) > 0;
}

bool operator<=(StringView lhs, StringView rhs) {
  return lhs.compare(rhs) <= 0;
}

bool operator>=(StringView lhs, StringView rhs) {
  return lhs.compare(rhs) >= 0;
}

std::ostream& operator<<(std::ostream& o, StringView string_view) {
  o.write(string_view.data(), static_cast<std::streamsize>(string_view.size()));
  return o;
}

size_t StringView::find(StringView s, size_t pos) const {
  if (pos > size_)
    return npos;
  if (s.empty())
    return pos;

  auto* result = std::search(begin() + pos, end(), s.begin(), s.end());
  if (result == end())
    return npos;
  return result - begin();
}

size_t StringView::find(char c, size_t pos) const {
  if (pos > size_)
    return npos;

  auto* result = std::find(begin() + pos, end(), c);
  if (result == end())
    return npos;
  return result - begin();
}

size_t StringView::rfind(StringView s, size_t pos) const {
  if (size_ < s.size())
    return npos;
  if (s.empty())
    return std::min(pos, size_);

  auto* last = begin() + std::min(size_ - s.size(), pos) + s.size();
  auto* result = std::find_end(begin(), last, s.begin(), s.end());
  if (result == last)
    return npos;
  return result - begin();
}

size_t StringView::rfind(char c, size_t pos) const {
  if (size_ == 0)
    return npos;

  auto begin = rend() - std::min(size_ - 1, pos) - 1;
  auto result = std::find(begin, rend(), c);
  if (result == rend())
    return npos;
  return rend() - result - 1;
}

size_t StringView::find_first_of(StringView s, size_t pos) const {
  if (pos >= size_ || s.size() == 0)
    return npos;

  // Avoid the cost of BuildLookupTable() for a single-character search.
  if (s.size() == 1)
    return find(s.data()[0], pos);

  bool lookup[std::numeric_limits<unsigned char>::max() + 1] = {false};
  BuildLookupTable(s, lookup);
  for (size_t i = pos; i < size_; ++i) {
    if (lookup[static_cast<unsigned char>(data_[i])]) {
      return i;
    }
  }
  return npos;
}

size_t StringView::find_last_of(StringView s, size_t pos) const {
  if (size_ == 0 || s.size() == 0)
    return npos;

  // Avoid the cost of BuildLookupTable() for a single-character search.
  if (s.size() == 1)
    return rfind(s.data()[0], pos);

  bool lookup[std::numeric_limits<unsigned char>::max() + 1] = {false};
  BuildLookupTable(s, lookup);
  for (size_t i = std::min(pos, size_ - 1);; --i) {
    if (lookup[static_cast<unsigned char>(data_[i])])
      return i;
    if (i == 0)
      break;
  }
  return npos;
}

size_t StringView::find_first_not_of(StringView s, size_t pos) const {
  if (pos >= size_)
    return npos;

  // Avoid the cost of BuildLookupTable() for a single-character search.
  if (s.size() == 1) {
    for (size_t i = pos; i < size_; ++i) {
      if (data_[i] != s[0])
        return i;
    }
    return npos;
  }

  bool lookup[std::numeric_limits<unsigned char>::max() + 1] = {false};
  BuildLookupTable(s, lookup);
  for (size_t i = pos; i < size_; ++i) {
    if (!lookup[static_cast<unsigned char>(data_[i])]) {
      return i;
    }
  }
  return npos;
}

size_t StringView::find_last_not_of(StringView s, size_t pos) const {
  if (size_ == 0)
    return npos;

  // Avoid the cost of BuildLookupTable() for a single-character search.
  if (s.size() == 1) {
    for (size_t i = std::min(pos, size_ - 1);; --i) {
      if (data_[i] != s[0])
        return i;
      if (i == 0)
        break;
    }
  }

  bool lookup[std::numeric_limits<unsigned char>::max() + 1] = {false};
  BuildLookupTable(s, lookup);
  for (size_t i = std::min(pos, size_ - 1);; --i) {
    if (!lookup[static_cast<unsigned char>(data_[i])])
      return i;
    if (i == 0)
      break;
  }
  return npos;
}

}  // namespace fml

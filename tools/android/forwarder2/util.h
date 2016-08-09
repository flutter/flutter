// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_FORWARDER2_UTIL_H_
#define TOOLS_ANDROID_FORWARDER2_UTIL_H_

#include "base/logging.h"

namespace forwarder2 {

// Safely deletes a ref-counted value in a provided map by unlinking the object
// from the map before deleting it in case its destructor would access the map.
// Deletion will only happen by definition if the object's refcount is set to 1
// before this function gets called. Returns whether the element could be found
// in the map.
template <typename Map, typename K>
bool DeleteRefCountedValueInMap(const K& key, Map* map) {
  const typename Map::iterator it = map->find(key);
  if (it == map->end())
    return false;
  DeleteRefCountedValueInMapFromIterator(it, map);
  return true;
}

// See DeleteRefCountedValuetInMap() above.
template <typename Map, typename Iterator>
void DeleteRefCountedValueInMapFromIterator(Iterator it, Map* map) {
  DCHECK(it != map->end());
  const typename Map::value_type::second_type shared_ptr_copy = it->second;
  map->erase(it);
}

}  // namespace forwarder2

#endif  // TOOLS_ANDROID_FORWARDER2_UTIL_H_

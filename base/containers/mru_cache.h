// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains a template for a Most Recently Used cache that allows
// constant-time access to items using a key, but easy identification of the
// least-recently-used items for removal.  Each key can only be associated with
// one payload item at a time.
//
// The key object will be stored twice, so it should support efficient copying.
//
// NOTE: While all operations are O(1), this code is written for
// legibility rather than optimality. If future profiling identifies this as
// a bottleneck, there is room for smaller values of 1 in the O(1). :]

#ifndef BASE_CONTAINERS_MRU_CACHE_H_
#define BASE_CONTAINERS_MRU_CACHE_H_

#include <list>
#include <map>
#include <utility>

#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/logging.h"

namespace base {

// MRUCacheBase ----------------------------------------------------------------

// This template is used to standardize map type containers that can be used
// by MRUCacheBase. This level of indirection is necessary because of the way
// that template template params and default template params interact.
template <class KeyType, class ValueType>
struct MRUCacheStandardMap {
  typedef std::map<KeyType, ValueType> Type;
};

// Base class for the MRU cache specializations defined below.
// The deletor will get called on all payloads that are being removed or
// replaced.
template <class KeyType, class PayloadType, class DeletorType,
          template <typename, typename> class MapType = MRUCacheStandardMap>
class MRUCacheBase {
 public:
  // The payload of the list. This maintains a copy of the key so we can
  // efficiently delete things given an element of the list.
  typedef std::pair<KeyType, PayloadType> value_type;

 private:
  typedef std::list<value_type> PayloadList;
  typedef typename MapType<KeyType,
                           typename PayloadList::iterator>::Type KeyIndex;

 public:
  typedef typename PayloadList::size_type size_type;

  typedef typename PayloadList::iterator iterator;
  typedef typename PayloadList::const_iterator const_iterator;
  typedef typename PayloadList::reverse_iterator reverse_iterator;
  typedef typename PayloadList::const_reverse_iterator const_reverse_iterator;

  enum { NO_AUTO_EVICT = 0 };

  // The max_size is the size at which the cache will prune its members to when
  // a new item is inserted. If the caller wants to manager this itself (for
  // example, maybe it has special work to do when something is evicted), it
  // can pass NO_AUTO_EVICT to not restrict the cache size.
  explicit MRUCacheBase(size_type max_size) : max_size_(max_size) {
  }

  MRUCacheBase(size_type max_size, const DeletorType& deletor)
      : max_size_(max_size), deletor_(deletor) {
  }

  virtual ~MRUCacheBase() {
    iterator i = begin();
    while (i != end())
      i = Erase(i);
  }

  size_type max_size() const { return max_size_; }

  // Inserts a payload item with the given key. If an existing item has
  // the same key, it is removed prior to insertion. An iterator indicating the
  // inserted item will be returned (this will always be the front of the list).
  //
  // The payload will be copied. In the case of an OwningMRUCache, this function
  // will take ownership of the pointer.
  iterator Put(const KeyType& key, const PayloadType& payload) {
    // Remove any existing payload with that key.
    typename KeyIndex::iterator index_iter = index_.find(key);
    if (index_iter != index_.end()) {
      // Erase the reference to it. This will call the deletor on the removed
      // element. The index reference will be replaced in the code below.
      Erase(index_iter->second);
    } else if (max_size_ != NO_AUTO_EVICT) {
      // New item is being inserted which might make it larger than the maximum
      // size: kick the oldest thing out if necessary.
      ShrinkToSize(max_size_ - 1);
    }

    ordering_.push_front(value_type(key, payload));
    index_.insert(std::make_pair(key, ordering_.begin()));
    return ordering_.begin();
  }

  // Retrieves the contents of the given key, or end() if not found. This method
  // has the side effect of moving the requested item to the front of the
  // recency list.
  //
  // TODO(brettw) We may want a const version of this function in the future.
  iterator Get(const KeyType& key) {
    typename KeyIndex::iterator index_iter = index_.find(key);
    if (index_iter == index_.end())
      return end();
    typename PayloadList::iterator iter = index_iter->second;

    // Move the touched item to the front of the recency ordering.
    ordering_.splice(ordering_.begin(), ordering_, iter);
    return ordering_.begin();
  }

  // Retrieves the payload associated with a given key and returns it via
  // result without affecting the ordering (unlike Get).
  iterator Peek(const KeyType& key) {
    typename KeyIndex::const_iterator index_iter = index_.find(key);
    if (index_iter == index_.end())
      return end();
    return index_iter->second;
  }

  const_iterator Peek(const KeyType& key) const {
    typename KeyIndex::const_iterator index_iter = index_.find(key);
    if (index_iter == index_.end())
      return end();
    return index_iter->second;
  }

  // Erases the item referenced by the given iterator. An iterator to the item
  // following it will be returned. The iterator must be valid.
  iterator Erase(iterator pos) {
    deletor_(pos->second);
    index_.erase(pos->first);
    return ordering_.erase(pos);
  }

  // MRUCache entries are often processed in reverse order, so we add this
  // convenience function (not typically defined by STL containers).
  reverse_iterator Erase(reverse_iterator pos) {
    // We have to actually give it the incremented iterator to delete, since
    // the forward iterator that base() returns is actually one past the item
    // being iterated over.
    return reverse_iterator(Erase((++pos).base()));
  }

  // Shrinks the cache so it only holds |new_size| items. If |new_size| is
  // bigger or equal to the current number of items, this will do nothing.
  void ShrinkToSize(size_type new_size) {
    for (size_type i = size(); i > new_size; i--)
      Erase(rbegin());
  }

  // Deletes everything from the cache.
  void Clear() {
    for (typename PayloadList::iterator i(ordering_.begin());
         i != ordering_.end(); ++i)
      deletor_(i->second);
    index_.clear();
    ordering_.clear();
  }

  // Returns the number of elements in the cache.
  size_type size() const {
    // We don't use ordering_.size() for the return value because
    // (as a linked list) it can be O(n).
    DCHECK(index_.size() == ordering_.size());
    return index_.size();
  }

  // Allows iteration over the list. Forward iteration starts with the most
  // recent item and works backwards.
  //
  // Note that since these iterators are actually iterators over a list, you
  // can keep them as you insert or delete things (as long as you don't delete
  // the one you are pointing to) and they will still be valid.
  iterator begin() { return ordering_.begin(); }
  const_iterator begin() const { return ordering_.begin(); }
  iterator end() { return ordering_.end(); }
  const_iterator end() const { return ordering_.end(); }

  reverse_iterator rbegin() { return ordering_.rbegin(); }
  const_reverse_iterator rbegin() const { return ordering_.rbegin(); }
  reverse_iterator rend() { return ordering_.rend(); }
  const_reverse_iterator rend() const { return ordering_.rend(); }

  bool empty() const { return ordering_.empty(); }

 private:
  PayloadList ordering_;
  KeyIndex index_;

  size_type max_size_;

  DeletorType deletor_;

  DISALLOW_COPY_AND_ASSIGN(MRUCacheBase);
};

// MRUCache --------------------------------------------------------------------

// A functor that does nothing. Used by the MRUCache.
template<class PayloadType>
class MRUCacheNullDeletor {
 public:
  void operator()(const PayloadType& payload) {}
};

// A container that does not do anything to free its data. Use this when storing
// value types (as opposed to pointers) in the list.
template <class KeyType, class PayloadType>
class MRUCache : public MRUCacheBase<KeyType,
                                     PayloadType,
                                     MRUCacheNullDeletor<PayloadType> > {
 private:
  typedef MRUCacheBase<KeyType, PayloadType,
      MRUCacheNullDeletor<PayloadType> > ParentType;

 public:
  // See MRUCacheBase, noting the possibility of using NO_AUTO_EVICT.
  explicit MRUCache(typename ParentType::size_type max_size)
      : ParentType(max_size) {
  }
  virtual ~MRUCache() {
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(MRUCache);
};

// OwningMRUCache --------------------------------------------------------------

template<class PayloadType>
class MRUCachePointerDeletor {
 public:
  void operator()(const PayloadType& payload) { delete payload; }
};

// A cache that owns the payload type, which must be a non-const pointer type.
// The pointers will be deleted when they are removed, replaced, or when the
// cache is destroyed.
template <class KeyType, class PayloadType>
class OwningMRUCache
    : public MRUCacheBase<KeyType,
                          PayloadType,
                          MRUCachePointerDeletor<PayloadType> > {
 private:
  typedef MRUCacheBase<KeyType, PayloadType,
      MRUCachePointerDeletor<PayloadType> > ParentType;

 public:
  // See MRUCacheBase, noting the possibility of using NO_AUTO_EVICT.
  explicit OwningMRUCache(typename ParentType::size_type max_size)
      : ParentType(max_size) {
  }
  virtual ~OwningMRUCache() {
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(OwningMRUCache);
};

// HashingMRUCache ------------------------------------------------------------

template <class KeyType, class ValueType>
struct MRUCacheHashMap {
  typedef base::hash_map<KeyType, ValueType> Type;
};

// This class is similar to MRUCache, except that it uses base::hash_map as
// the map type instead of std::map. Note that your KeyType must be hashable
// to use this cache.
template <class KeyType, class PayloadType>
class HashingMRUCache : public MRUCacheBase<KeyType,
                                            PayloadType,
                                            MRUCacheNullDeletor<PayloadType>,
                                            MRUCacheHashMap> {
 private:
  typedef MRUCacheBase<KeyType, PayloadType,
                       MRUCacheNullDeletor<PayloadType>,
                       MRUCacheHashMap> ParentType;

 public:
  // See MRUCacheBase, noting the possibility of using NO_AUTO_EVICT.
  explicit HashingMRUCache(typename ParentType::size_type max_size)
      : ParentType(max_size) {
  }
  virtual ~HashingMRUCache() {
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(HashingMRUCache);
};

}  // namespace base

#endif  // BASE_CONTAINERS_MRU_CACHE_H_

// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_CONTAINERS_SMALL_MAP_H_
#define BASE_CONTAINERS_SMALL_MAP_H_

#include <map>
#include <string>
#include <utility>

#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/logging.h"
#include "base/memory/manual_constructor.h"

namespace base {

// An STL-like associative container which starts out backed by a simple
// array but switches to some other container type if it grows beyond a
// fixed size.
//
// WHAT TYPE OF MAP SHOULD YOU USE?
// --------------------------------
//
//  - std::map should be the default if you're not sure, since it's the most
//    difficult to mess up. Generally this is backed by a red-black tree. It
//    will generate a lot of code (if you use a common key type like int or
//    string the linker will probably emiminate the duplicates). It will
//    do heap allocations for each element.
//
//  - If you only ever keep a couple of items and have very simple usage,
//    consider whether a using a vector and brute-force searching it will be
//    the most efficient. It's not a lot of generated code (less then a
//    red-black tree if your key is "weird" and not eliminated as duplicate of
//    something else) and will probably be faster and do fewer heap allocations
//    than std::map if you have just a couple of items.
//
//  - base::hash_map should be used if you need O(1) lookups. It may waste
//    space in the hash table, and it can be easy to write correct-looking
//    code with the default hash function being wrong or poorly-behaving.
//
//  - SmallMap combines the performance benefits of the brute-force-searched
//    vector for small cases (no extra heap allocations), but can efficiently
//    fall back if you end up adding many items. It will generate more code
//    than std::map (at least 160 bytes for operator[]) which is bad if you
//    have a "weird" key where map functions can't be
//    duplicate-code-eliminated. If you have a one-off key and aren't in
//    performance-critical code, this bloat may negate some of the benefits and
//    you should consider on of the other options.
//
// SmallMap will pick up the comparator from the underlying map type. In
// std::map (and in MSVC additionally hash_map) only a "less" operator is
// defined, which requires us to do two comparisons per element when doing the
// brute-force search in the simple array.
//
// We define default overrides for the common map types to avoid this
// double-compare, but you should be aware of this if you use your own
// operator< for your map and supply yor own version of == to the SmallMap.
// You can use regular operator== by just doing:
//
//   base::SmallMap<std::map<MyKey, MyValue>, 4, std::equal_to<KyKey> >
//
//
// USAGE
// -----
//
// NormalMap:  The map type to fall back to.  This also defines the key
//             and value types for the SmallMap.
// kArraySize:  The size of the initial array of results. This will be
//              allocated with the SmallMap object rather than separately on
//              the heap. Once the map grows beyond this size, the map type
//              will be used instead.
// EqualKey:  A functor which tests two keys for equality.  If the wrapped
//            map type has a "key_equal" member (hash_map does), then that will
//            be used by default. If the wrapped map type has a strict weak
//            ordering "key_compare" (std::map does), that will be used to
//            implement equality by default.
// MapInit: A functor that takes a ManualConstructor<NormalMap>* and uses it to
//          initialize the map. This functor will be called at most once per
//          SmallMap, when the map exceeds the threshold of kArraySize and we
//          are about to copy values from the array to the map. The functor
//          *must* call one of the Init() methods provided by
//          ManualConstructor, since after it runs we assume that the NormalMap
//          has been initialized.
//
// example:
//   base::SmallMap< std::map<string, int> > days;
//   days["sunday"   ] = 0;
//   days["monday"   ] = 1;
//   days["tuesday"  ] = 2;
//   days["wednesday"] = 3;
//   days["thursday" ] = 4;
//   days["friday"   ] = 5;
//   days["saturday" ] = 6;
//
// You should assume that SmallMap might invalidate all the iterators
// on any call to erase(), insert() and operator[].

namespace internal {

template <typename NormalMap>
class SmallMapDefaultInit {
 public:
  void operator()(ManualConstructor<NormalMap>* map) const {
    map->Init();
  }
};

// has_key_equal<M>::value is true iff there exists a type M::key_equal. This is
// used to dispatch to one of the select_equal_key<> metafunctions below.
template <typename M>
struct has_key_equal {
  typedef char sml;  // "small" is sometimes #defined so we use an abbreviation.
  typedef struct { char dummy[2]; } big;
  // Two functions, one accepts types that have a key_equal member, and one that
  // accepts anything. They each return a value of a different size, so we can
  // determine at compile-time which function would have been called.
  template <typename U> static big test(typename U::key_equal*);
  template <typename> static sml test(...);
  // Determines if M::key_equal exists by looking at the size of the return
  // type of the compiler-chosen test() function.
  static const bool value = (sizeof(test<M>(0)) == sizeof(big));
};
template <typename M> const bool has_key_equal<M>::value;

// Base template used for map types that do NOT have an M::key_equal member,
// e.g., std::map<>. These maps have a strict weak ordering comparator rather
// than an equality functor, so equality will be implemented in terms of that
// comparator.
//
// There's a partial specialization of this template below for map types that do
// have an M::key_equal member.
template <typename M, bool has_key_equal_value>
struct select_equal_key {
  struct equal_key {
    bool operator()(const typename M::key_type& left,
                    const typename M::key_type& right) {
      // Implements equality in terms of a strict weak ordering comparator.
      typename M::key_compare comp;
      return !comp(left, right) && !comp(right, left);
    }
  };
};

// Provide overrides to use operator== for key compare for the "normal" map and
// hash map types. If you override the default comparator or allocator for a
// map or hash_map, or use another type of map, this won't get used.
//
// If we switch to using std::unordered_map for base::hash_map, then the
// hash_map specialization can be removed.
template <typename KeyType, typename ValueType>
struct select_equal_key< std::map<KeyType, ValueType>, false> {
  struct equal_key {
    bool operator()(const KeyType& left, const KeyType& right) {
      return left == right;
    }
  };
};
template <typename KeyType, typename ValueType>
struct select_equal_key< base::hash_map<KeyType, ValueType>, false> {
  struct equal_key {
    bool operator()(const KeyType& left, const KeyType& right) {
      return left == right;
    }
  };
};

// Partial template specialization handles case where M::key_equal exists, e.g.,
// hash_map<>.
template <typename M>
struct select_equal_key<M, true> {
  typedef typename M::key_equal equal_key;
};

}  // namespace internal

template <typename NormalMap,
          int kArraySize = 4,
          typename EqualKey =
              typename internal::select_equal_key<
                  NormalMap,
                  internal::has_key_equal<NormalMap>::value>::equal_key,
          typename MapInit = internal::SmallMapDefaultInit<NormalMap> >
class SmallMap {
  // We cannot rely on the compiler to reject array of size 0.  In
  // particular, gcc 2.95.3 does it but later versions allow 0-length
  // arrays.  Therefore, we explicitly reject non-positive kArraySize
  // here.
  COMPILE_ASSERT(kArraySize > 0, default_initial_size_should_be_positive);

 public:
  typedef typename NormalMap::key_type key_type;
  typedef typename NormalMap::mapped_type data_type;
  typedef typename NormalMap::mapped_type mapped_type;
  typedef typename NormalMap::value_type value_type;
  typedef EqualKey key_equal;

  SmallMap() : size_(0), functor_(MapInit()) {}

  explicit SmallMap(const MapInit& functor) : size_(0), functor_(functor) {}

  // Allow copy-constructor and assignment, since STL allows them too.
  SmallMap(const SmallMap& src) {
    // size_ and functor_ are initted in InitFrom()
    InitFrom(src);
  }
  void operator=(const SmallMap& src) {
    if (&src == this) return;

    // This is not optimal. If src and dest are both using the small
    // array, we could skip the teardown and reconstruct. One problem
    // to be resolved is that the value_type itself is pair<const K,
    // V>, and const K is not assignable.
    Destroy();
    InitFrom(src);
  }
  ~SmallMap() {
    Destroy();
  }

  class const_iterator;

  class iterator {
   public:
    typedef typename NormalMap::iterator::iterator_category iterator_category;
    typedef typename NormalMap::iterator::value_type value_type;
    typedef typename NormalMap::iterator::difference_type difference_type;
    typedef typename NormalMap::iterator::pointer pointer;
    typedef typename NormalMap::iterator::reference reference;

    inline iterator(): array_iter_(NULL) {}

    inline iterator& operator++() {
      if (array_iter_ != NULL) {
        ++array_iter_;
      } else {
        ++hash_iter_;
      }
      return *this;
    }
    inline iterator operator++(int /*unused*/) {
      iterator result(*this);
      ++(*this);
      return result;
    }
    inline iterator& operator--() {
      if (array_iter_ != NULL) {
        --array_iter_;
      } else {
        --hash_iter_;
      }
      return *this;
    }
    inline iterator operator--(int /*unused*/) {
      iterator result(*this);
      --(*this);
      return result;
    }
    inline value_type* operator->() const {
      if (array_iter_ != NULL) {
        return array_iter_->get();
      } else {
        return hash_iter_.operator->();
      }
    }

    inline value_type& operator*() const {
      if (array_iter_ != NULL) {
        return *array_iter_->get();
      } else {
        return *hash_iter_;
      }
    }

    inline bool operator==(const iterator& other) const {
      if (array_iter_ != NULL) {
        return array_iter_ == other.array_iter_;
      } else {
        return other.array_iter_ == NULL && hash_iter_ == other.hash_iter_;
      }
    }

    inline bool operator!=(const iterator& other) const {
      return !(*this == other);
    }

    bool operator==(const const_iterator& other) const;
    bool operator!=(const const_iterator& other) const;

   private:
    friend class SmallMap;
    friend class const_iterator;
    inline explicit iterator(ManualConstructor<value_type>* init)
      : array_iter_(init) {}
    inline explicit iterator(const typename NormalMap::iterator& init)
      : array_iter_(NULL), hash_iter_(init) {}

    ManualConstructor<value_type>* array_iter_;
    typename NormalMap::iterator hash_iter_;
  };

  class const_iterator {
   public:
    typedef typename NormalMap::const_iterator::iterator_category
        iterator_category;
    typedef typename NormalMap::const_iterator::value_type value_type;
    typedef typename NormalMap::const_iterator::difference_type difference_type;
    typedef typename NormalMap::const_iterator::pointer pointer;
    typedef typename NormalMap::const_iterator::reference reference;

    inline const_iterator(): array_iter_(NULL) {}
    // Non-explicit ctor lets us convert regular iterators to const iterators
    inline const_iterator(const iterator& other)
      : array_iter_(other.array_iter_), hash_iter_(other.hash_iter_) {}

    inline const_iterator& operator++() {
      if (array_iter_ != NULL) {
        ++array_iter_;
      } else {
        ++hash_iter_;
      }
      return *this;
    }
    inline const_iterator operator++(int /*unused*/) {
      const_iterator result(*this);
      ++(*this);
      return result;
    }

    inline const_iterator& operator--() {
      if (array_iter_ != NULL) {
        --array_iter_;
      } else {
        --hash_iter_;
      }
      return *this;
    }
    inline const_iterator operator--(int /*unused*/) {
      const_iterator result(*this);
      --(*this);
      return result;
    }

    inline const value_type* operator->() const {
      if (array_iter_ != NULL) {
        return array_iter_->get();
      } else {
        return hash_iter_.operator->();
      }
    }

    inline const value_type& operator*() const {
      if (array_iter_ != NULL) {
        return *array_iter_->get();
      } else {
        return *hash_iter_;
      }
    }

    inline bool operator==(const const_iterator& other) const {
      if (array_iter_ != NULL) {
        return array_iter_ == other.array_iter_;
      } else {
        return other.array_iter_ == NULL && hash_iter_ == other.hash_iter_;
      }
    }

    inline bool operator!=(const const_iterator& other) const {
      return !(*this == other);
    }

   private:
    friend class SmallMap;
    inline explicit const_iterator(
        const ManualConstructor<value_type>* init)
      : array_iter_(init) {}
    inline explicit const_iterator(
        const typename NormalMap::const_iterator& init)
      : array_iter_(NULL), hash_iter_(init) {}

    const ManualConstructor<value_type>* array_iter_;
    typename NormalMap::const_iterator hash_iter_;
  };

  iterator find(const key_type& key) {
    key_equal compare;
    if (size_ >= 0) {
      for (int i = 0; i < size_; i++) {
        if (compare(array_[i]->first, key)) {
          return iterator(array_ + i);
        }
      }
      return iterator(array_ + size_);
    } else {
      return iterator(map()->find(key));
    }
  }

  const_iterator find(const key_type& key) const {
    key_equal compare;
    if (size_ >= 0) {
      for (int i = 0; i < size_; i++) {
        if (compare(array_[i]->first, key)) {
          return const_iterator(array_ + i);
        }
      }
      return const_iterator(array_ + size_);
    } else {
      return const_iterator(map()->find(key));
    }
  }

  // Invalidates iterators.
  data_type& operator[](const key_type& key) {
    key_equal compare;

    if (size_ >= 0) {
      // operator[] searches backwards, favoring recently-added
      // elements.
      for (int i = size_-1; i >= 0; --i) {
        if (compare(array_[i]->first, key)) {
          return array_[i]->second;
        }
      }
      if (size_ == kArraySize) {
        ConvertToRealMap();
        return (*map_)[key];
      } else {
        array_[size_].Init(key, data_type());
        return array_[size_++]->second;
      }
    } else {
      return (*map_)[key];
    }
  }

  // Invalidates iterators.
  std::pair<iterator, bool> insert(const value_type& x) {
    key_equal compare;

    if (size_ >= 0) {
      for (int i = 0; i < size_; i++) {
        if (compare(array_[i]->first, x.first)) {
          return std::make_pair(iterator(array_ + i), false);
        }
      }
      if (size_ == kArraySize) {
        ConvertToRealMap();  // Invalidates all iterators!
        std::pair<typename NormalMap::iterator, bool> ret = map_->insert(x);
        return std::make_pair(iterator(ret.first), ret.second);
      } else {
        array_[size_].Init(x);
        return std::make_pair(iterator(array_ + size_++), true);
      }
    } else {
      std::pair<typename NormalMap::iterator, bool> ret = map_->insert(x);
      return std::make_pair(iterator(ret.first), ret.second);
    }
  }

  // Invalidates iterators.
  template <class InputIterator>
  void insert(InputIterator f, InputIterator l) {
    while (f != l) {
      insert(*f);
      ++f;
    }
  }

  iterator begin() {
    if (size_ >= 0) {
      return iterator(array_);
    } else {
      return iterator(map_->begin());
    }
  }
  const_iterator begin() const {
    if (size_ >= 0) {
      return const_iterator(array_);
    } else {
      return const_iterator(map_->begin());
    }
  }

  iterator end() {
    if (size_ >= 0) {
      return iterator(array_ + size_);
    } else {
      return iterator(map_->end());
    }
  }
  const_iterator end() const {
    if (size_ >= 0) {
      return const_iterator(array_ + size_);
    } else {
      return const_iterator(map_->end());
    }
  }

  void clear() {
    if (size_ >= 0) {
      for (int i = 0; i < size_; i++) {
        array_[i].Destroy();
      }
    } else {
      map_.Destroy();
    }
    size_ = 0;
  }

  // Invalidates iterators.
  void erase(const iterator& position) {
    if (size_ >= 0) {
      int i = position.array_iter_ - array_;
      array_[i].Destroy();
      --size_;
      if (i != size_) {
        array_[i].Init(*array_[size_]);
        array_[size_].Destroy();
      }
    } else {
      map_->erase(position.hash_iter_);
    }
  }

  size_t erase(const key_type& key) {
    iterator iter = find(key);
    if (iter == end()) return 0u;
    erase(iter);
    return 1u;
  }

  size_t count(const key_type& key) const {
    return (find(key) == end()) ? 0 : 1;
  }

  size_t size() const {
    if (size_ >= 0) {
      return static_cast<size_t>(size_);
    } else {
      return map_->size();
    }
  }

  bool empty() const {
    if (size_ >= 0) {
      return (size_ == 0);
    } else {
      return map_->empty();
    }
  }

  // Returns true if we have fallen back to using the underlying map
  // representation.
  bool UsingFullMap() const {
    return size_ < 0;
  }

  inline NormalMap* map() {
    CHECK(UsingFullMap());
    return map_.get();
  }
  inline const NormalMap* map() const {
    CHECK(UsingFullMap());
    return map_.get();
  }

 private:
  int size_;  // negative = using hash_map

  MapInit functor_;

  // We want to call constructors and destructors manually, but we don't
  // want to allocate and deallocate the memory used for them separately.
  // So, we use this crazy ManualConstructor class.
  //
  // Since array_ and map_ are mutually exclusive, we'll put them in a
  // union, too.  We add in a dummy_ value which quiets MSVC from otherwise
  // giving an erroneous "union member has copy constructor" error message
  // (C2621). This dummy member has to come before array_ to quiet the
  // compiler.
  //
  // TODO(brettw) remove this and use C++11 unions when we require C++11.
  union {
    ManualConstructor<value_type> dummy_;
    ManualConstructor<value_type> array_[kArraySize];
    ManualConstructor<NormalMap> map_;
  };

  void ConvertToRealMap() {
    // Move the current elements into a temporary array.
    ManualConstructor<value_type> temp_array[kArraySize];

    for (int i = 0; i < kArraySize; i++) {
      temp_array[i].Init(*array_[i]);
      array_[i].Destroy();
    }

    // Initialize the map.
    size_ = -1;
    functor_(&map_);

    // Insert elements into it.
    for (int i = 0; i < kArraySize; i++) {
      map_->insert(*temp_array[i]);
      temp_array[i].Destroy();
    }
  }

  // Helpers for constructors and destructors.
  void InitFrom(const SmallMap& src) {
    functor_ = src.functor_;
    size_ = src.size_;
    if (src.size_ >= 0) {
      for (int i = 0; i < size_; i++) {
        array_[i].Init(*src.array_[i]);
      }
    } else {
      functor_(&map_);
      (*map_.get()) = (*src.map_.get());
    }
  }
  void Destroy() {
    if (size_ >= 0) {
      for (int i = 0; i < size_; i++) {
        array_[i].Destroy();
      }
    } else {
      map_.Destroy();
    }
  }
};

template <typename NormalMap, int kArraySize, typename EqualKey,
          typename Functor>
inline bool SmallMap<NormalMap, kArraySize, EqualKey,
                     Functor>::iterator::operator==(
    const const_iterator& other) const {
  return other == *this;
}
template <typename NormalMap, int kArraySize, typename EqualKey,
          typename Functor>
inline bool SmallMap<NormalMap, kArraySize, EqualKey,
                     Functor>::iterator::operator!=(
    const const_iterator& other) const {
  return other != *this;
}

}  // namespace base

#endif  // BASE_CONTAINERS_SMALL_MAP_H_

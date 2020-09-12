/*
 * Copyright (C) 2005 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef ANDROID_TYPE_HELPERS_H
#define ANDROID_TYPE_HELPERS_H

#include <sys/types.h>

#include <cstdint>
#include <cstring>
#include <new>
#include <type_traits>

// ---------------------------------------------------------------------------

namespace android {

/*
 * Types traits
 */

template <typename T>
struct trait_trivial_ctor {
  enum { value = false };
};
template <typename T>
struct trait_trivial_dtor {
  enum { value = false };
};
template <typename T>
struct trait_trivial_copy {
  enum { value = false };
};
template <typename T>
struct trait_trivial_move {
  enum { value = false };
};
template <typename T>
struct trait_pointer {
  enum { value = false };
};
template <typename T>
struct trait_pointer<T*> {
  enum { value = true };
};

template <typename TYPE>
struct traits {
  enum {
    // whether this type is a pointer
    is_pointer = trait_pointer<TYPE>::value,
    // whether this type's constructor is a no-op
    has_trivial_ctor = is_pointer || trait_trivial_ctor<TYPE>::value,
    // whether this type's destructor is a no-op
    has_trivial_dtor = is_pointer || trait_trivial_dtor<TYPE>::value,
    // whether this type type can be copy-constructed with memcpy
    has_trivial_copy = is_pointer || trait_trivial_copy<TYPE>::value,
    // whether this type can be moved with memmove
    has_trivial_move = is_pointer || trait_trivial_move<TYPE>::value
  };
};

template <typename T, typename U>
struct aggregate_traits {
  enum {
    is_pointer = false,
    has_trivial_ctor =
        traits<T>::has_trivial_ctor && traits<U>::has_trivial_ctor,
    has_trivial_dtor =
        traits<T>::has_trivial_dtor && traits<U>::has_trivial_dtor,
    has_trivial_copy =
        traits<T>::has_trivial_copy && traits<U>::has_trivial_copy,
    has_trivial_move =
        traits<T>::has_trivial_move && traits<U>::has_trivial_move
  };
};

#define ANDROID_TRIVIAL_CTOR_TRAIT(T) \
  template <>                         \
  struct trait_trivial_ctor<T> {      \
    enum { value = true };            \
  };

#define ANDROID_TRIVIAL_DTOR_TRAIT(T) \
  template <>                         \
  struct trait_trivial_dtor<T> {      \
    enum { value = true };            \
  };

#define ANDROID_TRIVIAL_COPY_TRAIT(T) \
  template <>                         \
  struct trait_trivial_copy<T> {      \
    enum { value = true };            \
  };

#define ANDROID_TRIVIAL_MOVE_TRAIT(T) \
  template <>                         \
  struct trait_trivial_move<T> {      \
    enum { value = true };            \
  };

#define ANDROID_BASIC_TYPES_TRAITS(T) \
  ANDROID_TRIVIAL_CTOR_TRAIT(T)       \
  ANDROID_TRIVIAL_DTOR_TRAIT(T)       \
  ANDROID_TRIVIAL_COPY_TRAIT(T)       \
  ANDROID_TRIVIAL_MOVE_TRAIT(T)

// ---------------------------------------------------------------------------

/*
 * basic types traits
 */

ANDROID_BASIC_TYPES_TRAITS(void)
ANDROID_BASIC_TYPES_TRAITS(bool)
ANDROID_BASIC_TYPES_TRAITS(char)
ANDROID_BASIC_TYPES_TRAITS(unsigned char)
ANDROID_BASIC_TYPES_TRAITS(short)
ANDROID_BASIC_TYPES_TRAITS(unsigned short)
ANDROID_BASIC_TYPES_TRAITS(int)
ANDROID_BASIC_TYPES_TRAITS(unsigned int)
ANDROID_BASIC_TYPES_TRAITS(long)
ANDROID_BASIC_TYPES_TRAITS(unsigned long)
ANDROID_BASIC_TYPES_TRAITS(long long)
ANDROID_BASIC_TYPES_TRAITS(unsigned long long)
ANDROID_BASIC_TYPES_TRAITS(float)
ANDROID_BASIC_TYPES_TRAITS(double)

// ---------------------------------------------------------------------------

/*
 * compare and order types
 */

template <typename TYPE>
inline int strictly_order_type(const TYPE& lhs, const TYPE& rhs) {
  return (lhs < rhs) ? 1 : 0;
}

template <typename TYPE>
inline int compare_type(const TYPE& lhs, const TYPE& rhs) {
  return strictly_order_type(rhs, lhs) - strictly_order_type(lhs, rhs);
}

/*
 * create, destroy, copy and move types...
 */

template <typename TYPE>
inline void construct_type(TYPE* p, size_t n) {
  if (!traits<TYPE>::has_trivial_ctor) {
    while (n > 0) {
      n--;
      new (p++) TYPE;
    }
  }
}

template <typename TYPE>
inline void destroy_type(TYPE* p, size_t n) {
  if (!traits<TYPE>::has_trivial_dtor) {
    while (n > 0) {
      n--;
      p->~TYPE();
      p++;
    }
  }
}

template <typename TYPE>
typename std::enable_if<traits<TYPE>::has_trivial_copy>::type inline copy_type(
    TYPE* d,
    const TYPE* s,
    size_t n) {
  memcpy(d, s, n * sizeof(TYPE));
}

template <typename TYPE>
typename std::enable_if<!traits<TYPE>::has_trivial_copy>::type inline copy_type(
    TYPE* d,
    const TYPE* s,
    size_t n) {
  while (n > 0) {
    n--;
    new (d) TYPE(*s);
    d++, s++;
  }
}

template <typename TYPE>
inline void splat_type(TYPE* where, const TYPE* what, size_t n) {
  if (!traits<TYPE>::has_trivial_copy) {
    while (n > 0) {
      n--;
      new (where) TYPE(*what);
      where++;
    }
  } else {
    while (n > 0) {
      n--;
      *where++ = *what;
    }
  }
}

template <typename TYPE>
struct use_trivial_move
    : public std::integral_constant<bool,
                                    (traits<TYPE>::has_trivial_dtor &&
                                     traits<TYPE>::has_trivial_copy) ||
                                        traits<TYPE>::has_trivial_move> {};

template <typename TYPE>
typename std::enable_if<use_trivial_move<TYPE>::value>::
    type inline move_forward_type(TYPE* d, const TYPE* s, size_t n = 1) {
  memmove(d, s, n * sizeof(TYPE));
}

template <typename TYPE>
typename std::enable_if<!use_trivial_move<TYPE>::value>::
    type inline move_forward_type(TYPE* d, const TYPE* s, size_t n = 1) {
  d += n;
  s += n;
  while (n > 0) {
    n--;
    --d, --s;
    if (!traits<TYPE>::has_trivial_copy) {
      new (d) TYPE(*s);
    } else {
      *d = *s;
    }
    if (!traits<TYPE>::has_trivial_dtor) {
      s->~TYPE();
    }
  }
}

template <typename TYPE>
typename std::enable_if<use_trivial_move<TYPE>::value>::
    type inline move_backward_type(TYPE* d, const TYPE* s, size_t n = 1) {
  memmove(d, s, n * sizeof(TYPE));
}

template <typename TYPE>
typename std::enable_if<!use_trivial_move<TYPE>::value>::
    type inline move_backward_type(TYPE* d, const TYPE* s, size_t n = 1) {
  while (n > 0) {
    n--;
    if (!traits<TYPE>::has_trivial_copy) {
      new (d) TYPE(*s);
    } else {
      *d = *s;
    }
    if (!traits<TYPE>::has_trivial_dtor) {
      s->~TYPE();
    }
    d++, s++;
  }
}

// ---------------------------------------------------------------------------

/*
 * a key/value pair
 */

template <typename KEY, typename VALUE>
struct key_value_pair_t {
  typedef KEY key_t;
  typedef VALUE value_t;

  KEY key;
  VALUE value;
  key_value_pair_t() {}
  key_value_pair_t(const key_value_pair_t& o) : key(o.key), value(o.value) {}
  key_value_pair_t& operator=(const key_value_pair_t& o) {
    key = o.key;
    value = o.value;
    return *this;
  }
  key_value_pair_t(const KEY& k, const VALUE& v) : key(k), value(v) {}
  explicit key_value_pair_t(const KEY& k) : key(k) {}
  inline bool operator<(const key_value_pair_t& o) const {
    return strictly_order_type(key, o.key);
  }
  inline const KEY& getKey() const { return key; }
  inline const VALUE& getValue() const { return value; }
};

template <typename K, typename V>
struct trait_trivial_ctor<key_value_pair_t<K, V>> {
  enum { value = aggregate_traits<K, V>::has_trivial_ctor };
};
template <typename K, typename V>
struct trait_trivial_dtor<key_value_pair_t<K, V>> {
  enum { value = aggregate_traits<K, V>::has_trivial_dtor };
};
template <typename K, typename V>
struct trait_trivial_copy<key_value_pair_t<K, V>> {
  enum { value = aggregate_traits<K, V>::has_trivial_copy };
};
template <typename K, typename V>
struct trait_trivial_move<key_value_pair_t<K, V>> {
  enum { value = aggregate_traits<K, V>::has_trivial_move };
};

// ---------------------------------------------------------------------------

/*
 * Hash codes.
 */
typedef uint32_t hash_t;

template <typename TKey>
hash_t hash_type(const TKey& key);

/* Built-in hash code specializations */
#define ANDROID_INT32_HASH(T)               \
  template <>                               \
  inline hash_t hash_type(const T& value) { \
    return hash_t(value);                   \
  }
#define ANDROID_INT64_HASH(T)               \
  template <>                               \
  inline hash_t hash_type(const T& value) { \
    return hash_t((value >> 32) ^ value);   \
  }
#define ANDROID_REINTERPRET_HASH(T, R)                                 \
  template <>                                                          \
  inline hash_t hash_type(const T& value) {                            \
    R newValue;                                                        \
    static_assert(sizeof(newValue) == sizeof(value), "size mismatch"); \
    memcpy(&newValue, &value, sizeof(newValue));                       \
    return hash_type(newValue);                                        \
  }

ANDROID_INT32_HASH(bool)
ANDROID_INT32_HASH(int8_t)
ANDROID_INT32_HASH(uint8_t)
ANDROID_INT32_HASH(int16_t)
ANDROID_INT32_HASH(uint16_t)
ANDROID_INT32_HASH(int32_t)
ANDROID_INT32_HASH(uint32_t)
ANDROID_INT64_HASH(int64_t)
ANDROID_INT64_HASH(uint64_t)
ANDROID_REINTERPRET_HASH(float, uint32_t)
ANDROID_REINTERPRET_HASH(double, uint64_t)

template <typename T>
inline hash_t hash_type(T* const& value) {
  return hash_type(uintptr_t(value));
}

};  // namespace android

// ---------------------------------------------------------------------------

#endif  // ANDROID_TYPE_HELPERS_H

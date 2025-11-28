// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_BASE_MASK_H_
#define FLUTTER_IMPELLER_BASE_MASK_H_

#include <type_traits>

namespace impeller {

template <typename EnumType_>
struct MaskTraits {
  static constexpr bool kIsMask = false;
};

//------------------------------------------------------------------------------
/// @brief      Declare this in the "impeller" namespace to make the enum
///             maskable.
///
#define IMPELLER_ENUM_IS_MASK(enum_name)  \
  template <>                             \
  struct MaskTraits<enum_name> {          \
    static constexpr bool kIsMask = true; \
  };

//------------------------------------------------------------------------------
/// @brief      A mask of typed enums.
///
/// @tparam     EnumType_  The type of the enum. Must be an enum class.
///
template <typename EnumType_>
struct Mask {
  using EnumType = EnumType_;
  using MaskType = typename std::underlying_type<EnumType>::type;

  constexpr Mask() = default;

  constexpr Mask(const Mask<EnumType>& other) = default;

  constexpr Mask(Mask<EnumType>&& other) = default;

  constexpr Mask(EnumType type)  // NOLINT(google-explicit-constructor)
      : mask_(static_cast<MaskType>(type)) {}

  explicit constexpr Mask(MaskType mask) : mask_(static_cast<MaskType>(mask)) {}

  // All casts must be explicit.

  explicit constexpr operator MaskType() const { return mask_; }

  explicit constexpr operator bool() const { return !!mask_; }

  // Comparison operators.

  constexpr auto operator<=>(const Mask<EnumType>& other) const = default;

  // Logical operators.

  constexpr bool operator!() const { return !mask_; }

  // Bitwise operators.

  constexpr Mask<EnumType> operator&(const Mask<EnumType>& other) const {
    return Mask<EnumType>{mask_ & other.mask_};
  }

  constexpr Mask<EnumType> operator|(const Mask<EnumType>& other) const {
    return Mask<EnumType>{mask_ | other.mask_};
  }

  constexpr Mask<EnumType> operator^(const Mask<EnumType>& other) const {
    return Mask<EnumType>{mask_ ^ other.mask_};
  }

  constexpr Mask<EnumType> operator~() const { return Mask<EnumType>{~mask_}; }

  // Assignment operators.

  constexpr Mask<EnumType>& operator=(const Mask<EnumType>&) = default;

  constexpr Mask<EnumType>& operator=(Mask<EnumType>&&) = default;

  constexpr Mask<EnumType>& operator|=(const Mask<EnumType>& other) {
    mask_ |= other.mask_;
    return *this;
  }

  constexpr Mask<EnumType>& operator&=(const Mask<EnumType>& other) {
    mask_ &= other.mask_;
    return *this;
  }

  constexpr Mask<EnumType>& operator^=(const Mask<EnumType>& other) {
    mask_ ^= other.mask_;
    return *this;
  }

 private:
  MaskType mask_ = {};
};

// Construction from Enum Types

template <
    typename EnumType,
    typename std::enable_if<MaskTraits<EnumType>::kIsMask, bool>::type = true>
inline constexpr Mask<EnumType> operator|(const EnumType& lhs,
                                          const EnumType& rhs) {
  return Mask<EnumType>{lhs} | rhs;
}

template <
    typename EnumType,
    typename std::enable_if<MaskTraits<EnumType>::kIsMask, bool>::type = true>
inline constexpr Mask<EnumType> operator&(const EnumType& lhs,
                                          const EnumType& rhs) {
  return Mask<EnumType>{lhs} & rhs;
}

template <
    typename EnumType,
    typename std::enable_if<MaskTraits<EnumType>::kIsMask, bool>::type = true>
inline constexpr Mask<EnumType> operator^(const EnumType& lhs,
                                          const EnumType& rhs) {
  return Mask<EnumType>{lhs} ^ rhs;
}

template <
    typename EnumType,
    typename std::enable_if<MaskTraits<EnumType>::kIsMask, bool>::type = true>
inline constexpr Mask<EnumType> operator~(const EnumType& other) {
  return ~Mask<EnumType>{other};
}

template <
    typename EnumType,
    typename std::enable_if<MaskTraits<EnumType>::kIsMask, bool>::type = true>
inline constexpr Mask<EnumType> operator|(const EnumType& lhs,
                                          const Mask<EnumType>& rhs) {
  return Mask<EnumType>{lhs} | rhs;
}

template <
    typename EnumType,
    typename std::enable_if<MaskTraits<EnumType>::kIsMask, bool>::type = true>
inline constexpr Mask<EnumType> operator&(const EnumType& lhs,
                                          const Mask<EnumType>& rhs) {
  return Mask<EnumType>{lhs} & rhs;
}

template <
    typename EnumType,
    typename std::enable_if<MaskTraits<EnumType>::kIsMask, bool>::type = true>
inline constexpr Mask<EnumType> operator^(const EnumType& lhs,
                                          const Mask<EnumType>& rhs) {
  return Mask<EnumType>{lhs} ^ rhs;
}

// Relational operators with EnumType promotion.

template <typename EnumType,
          typename std::enable_if_t<MaskTraits<EnumType>::kIsMask, bool> = true>
inline constexpr auto operator<=>(const EnumType& lhs,
                                  const Mask<EnumType>& rhs) {
  return Mask<EnumType>{lhs} <=> rhs;
}

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_BASE_MASK_H_

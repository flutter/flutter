// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_ENCODABLE_VALUE_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_ENCODABLE_VALUE_H_

#include <assert.h>
#include <cstdint>
#include <map>
#include <string>
#include <utility>
#include <vector>

namespace flutter {

static_assert(sizeof(double) == 8, "EncodableValue requires a 64-bit double");

class EncodableValue;
// Convenience type aliases for list and map EncodableValue types.
using EncodableList = std::vector<EncodableValue>;
using EncodableMap = std::map<EncodableValue, EncodableValue>;

// An object that can contain any value or collection type supported by
// Flutter's standard method codec.
//
// For details, see:
// https://api.flutter.dev/flutter/services/StandardMessageCodec-class.html
//
// As an example, the following Dart structure:
//   {
//     'flag': true,
//     'name': 'Thing',
//     'values': [1, 2.0, 4],
//   }
// would correspond to:
//   EncodableValue(EncodableMap{
//       {EncodableValue("flag"), EncodableValue(true)},
//       {EncodableValue("name"), EncodableValue("Thing")},
//       {EncodableValue("values"), EncodableValue(EncodableList{
//                                      EncodableValue(1),
//                                      EncodableValue(2.0),
//                                      EncodableValue(4),
//                                  })},
//   })
class EncodableValue {
 public:
  // Possible types for an EncodableValue to reperesent.
  enum class Type {
    kNull,        // A null value.
    kBool,        // A boolean value.
    kInt,         // A 32-bit integer.
    kLong,        // A 64-bit integer.
    kDouble,      // A 64-bit floating point number.
    kString,      // A string.
    kByteList,    // A list of bytes.
    kIntList,     // A list of 32-bit integers.
    kLongList,    // A list of 64-bit integers.
    kDoubleList,  // A list of 64-bit floating point numbers.
    kList,        // A list of EncodableValues.
    kMap,         // A mapping from EncodableValues to EncodableValues.
  };

  // Creates an instance representing a null value.
  EncodableValue() {}

  // Creates an instance representing a bool value.
  explicit EncodableValue(bool value) : bool_(value), type_(Type::kBool) {}

  // Creates an instance representing a 32-bit integer value.
  explicit EncodableValue(int32_t value) : int_(value), type_(Type::kInt) {}

  // Creates an instance representing a 64-bit integer value.
  explicit EncodableValue(int64_t value) : long_(value), type_(Type::kLong) {}

  // Creates an instance representing a 64-bit floating point value.
  explicit EncodableValue(double value)
      : double_(value), type_(Type::kDouble) {}

  // Creates an instance representing a string value.
  explicit EncodableValue(const char* value)
      : string_(new std::string(value)), type_(Type::kString) {}

  // Creates an instance representing a string value.
  explicit EncodableValue(const std::string& value)
      : string_(new std::string(value)), type_(Type::kString) {}

  // Creates an instance representing a list of bytes.
  explicit EncodableValue(std::vector<uint8_t> list)
      : byte_list_(new std::vector<uint8_t>(std::move(list))),
        type_(Type::kByteList) {}

  // Creates an instance representing a list of 32-bit integers.
  explicit EncodableValue(std::vector<int32_t> list)
      : int_list_(new std::vector<int32_t>(std::move(list))),
        type_(Type::kIntList) {}

  // Creates an instance representing a list of 64-bit integers.
  explicit EncodableValue(std::vector<int64_t> list)
      : long_list_(new std::vector<int64_t>(std::move(list))),
        type_(Type::kLongList) {}

  // Creates an instance representing a list of 64-bit floating point values.
  explicit EncodableValue(std::vector<double> list)
      : double_list_(new std::vector<double>(std::move(list))),
        type_(Type::kDoubleList) {}

  // Creates an instance representing a list of EncodableValues.
  explicit EncodableValue(EncodableList list)
      : list_(new EncodableList(std::move(list))), type_(Type::kList) {}

  // Creates an instance representing a map from EncodableValues to
  // EncodableValues.
  explicit EncodableValue(EncodableMap map)
      : map_(new EncodableMap(std::move(map))), type_(Type::kMap) {}

  // Convience constructor for creating default value of the given type.
  //
  // Collections types will be empty, numeric types will be 0, strings will be
  // empty, and booleans will be false. For non-collection types, prefer using
  // the value-based constructor with an explicit value for clarity.
  explicit EncodableValue(Type type) : type_(type) {
    switch (type_) {
      case Type::kNull:
        break;
      case Type::kBool:
        bool_ = false;
        break;
      case Type::kInt:
        int_ = 0;
        break;
      case Type::kLong:
        long_ = 0;
        break;
      case Type::kDouble:
        double_ = 0.0;
        break;
      case Type::kString:
        string_ = new std::string();
        break;
      case Type::kByteList:
        byte_list_ = new std::vector<uint8_t>();
        break;
      case Type::kIntList:
        int_list_ = new std::vector<int32_t>();
        break;
      case Type::kLongList:
        long_list_ = new std::vector<int64_t>();
        break;
      case Type::kDoubleList:
        double_list_ = new std::vector<double>();
        break;
      case Type::kList:
        list_ = new std::vector<EncodableValue>();
        break;
      case Type::kMap:
        map_ = new std::map<EncodableValue, EncodableValue>();
        break;
    }
  }

  ~EncodableValue() { DestroyValue(); }

  EncodableValue(const EncodableValue& other) {
    DestroyValue();

    type_ = other.type_;
    switch (type_) {
      case Type::kNull:
        break;
      case Type::kBool:
        bool_ = other.bool_;
        break;
      case Type::kInt:
        int_ = other.int_;
        break;
      case Type::kLong:
        long_ = other.long_;
        break;
      case Type::kDouble:
        double_ = other.double_;
        break;
      case Type::kString:
        string_ = new std::string(*other.string_);
        break;
      case Type::kByteList:
        byte_list_ = new std::vector<uint8_t>(*other.byte_list_);
        break;
      case Type::kIntList:
        int_list_ = new std::vector<int32_t>(*other.int_list_);
        break;
      case Type::kLongList:
        long_list_ = new std::vector<int64_t>(*other.long_list_);
        break;
      case Type::kDoubleList:
        double_list_ = new std::vector<double>(*other.double_list_);
        break;
      case Type::kList:
        list_ = new std::vector<EncodableValue>(*other.list_);
        break;
      case Type::kMap:
        map_ = new std::map<EncodableValue, EncodableValue>(*other.map_);
        break;
    }
  }

  EncodableValue(EncodableValue&& other) noexcept { *this = std::move(other); }

  EncodableValue& operator=(const EncodableValue& other) {
    if (&other == this) {
      return *this;
    }
    using std::swap;
    EncodableValue temp(other);
    swap(*this, temp);
    return *this;
  }

  EncodableValue& operator=(EncodableValue&& other) noexcept {
    if (&other == this) {
      return *this;
    }
    DestroyValue();

    type_ = other.type_;
    switch (type_) {
      case Type::kNull:
        break;
      case Type::kBool:
        bool_ = other.bool_;
        break;
      case Type::kInt:
        int_ = other.int_;
        break;
      case Type::kLong:
        long_ = other.long_;
        break;
      case Type::kDouble:
        double_ = other.double_;
        break;
      case Type::kString:
        string_ = other.string_;
        break;
      case Type::kByteList:
        byte_list_ = other.byte_list_;
        break;
      case Type::kIntList:
        int_list_ = other.int_list_;
        break;
      case Type::kLongList:
        long_list_ = other.long_list_;
        break;
      case Type::kDoubleList:
        double_list_ = other.double_list_;
        break;
      case Type::kList:
        list_ = other.list_;
        break;
      case Type::kMap:
        map_ = other.map_;
        break;
    }
    // Ensure that destruction doesn't run on the source of the move.
    other.type_ = Type::kNull;
    return *this;
  }

  // Allow assigning any value type that can be used for a constructor.
  template <typename T>
  EncodableValue& operator=(const T& value) {
    *this = EncodableValue(value);
    return *this;
  }

  // This operator exists only to provide a stable ordering for use as a
  // std::map key. It does not attempt to provide useful ordering semantics.
  // Notably:
  // - Numeric values are not guaranteed any ordering across numeric types.
  //   E.g., 1 as a Long may sort after 100 as an Int.
  // - Collection types use pointer equality, rather than value. This means that
  //   multiple collections with the same values will end up as separate keys
  //   in a map (consistent with default Dart Map behavior).
  bool operator<(const EncodableValue& other) const {
    if (type_ != other.type_) {
      return type_ < other.type_;
    }
    switch (type_) {
      case Type::kNull:
        return false;
      case Type::kBool:
        return bool_ < other.bool_;
      case Type::kInt:
        return int_ < other.int_;
      case Type::kLong:
        return long_ < other.long_;
      case Type::kDouble:
        return double_ < other.double_;
      case Type::kString:
        return *string_ < *other.string_;
      case Type::kByteList:
      case Type::kIntList:
      case Type::kLongList:
      case Type::kDoubleList:
      case Type::kList:
      case Type::kMap:
        return this < &other;
    }
    assert(false);
    return false;
  }

  // Returns the bool value this object represents.
  //
  // It is a programming error to call this unless IsBool() is true.
  bool BoolValue() const {
    assert(IsBool());
    return bool_;
  }

  // Returns the 32-bit integer value this object represents.
  //
  // It is a programming error to call this unless IsInt() is true.
  int32_t IntValue() const {
    assert(IsInt());
    return int_;
  }

  // Returns the 64-bit integer value this object represents.
  //
  // It is a programming error to call this unless IsLong() or IsInt() is true.
  //
  // Note that calling this function on an Int value is the only case where
  // a *Value() function can be called without the corresponding Is*() being
  // true. This is to simplify handling objects received from Flutter where the
  // values may be larger than 32-bit, since they have the same type on the Dart
  // side, but will be either 32-bit or 64-bit here depending on the value.
  int64_t LongValue() const {
    assert(IsLong() || IsInt());
    if (IsLong()) {
      return long_;
    }
    return int_;
  }

  // Returns the double value this object represents.
  //
  // It is a programming error to call this unless IsDouble() is true.
  double DoubleValue() const {
    assert(IsDouble());
    return double_;
  }

  // Returns the string value this object represents.
  //
  // It is a programming error to call this unless IsString() is true.
  const std::string& StringValue() const {
    assert(IsString());
    return *string_;
  }

  // Returns the byte list this object represents.
  //
  // It is a programming error to call this unless IsByteList() is true.
  const std::vector<uint8_t>& ByteListValue() const {
    assert(IsByteList());
    return *byte_list_;
  }

  // Returns the byte list this object represents.
  //
  // It is a programming error to call this unless IsByteList() is true.
  std::vector<uint8_t>& ByteListValue() {
    assert(IsByteList());
    return *byte_list_;
  }

  // Returns the 32-bit integer list this object represents.
  //
  // It is a programming error to call this unless IsIntList() is true.
  const std::vector<int32_t>& IntListValue() const {
    assert(IsIntList());
    return *int_list_;
  }

  // Returns the 32-bit integer list this object represents.
  //
  // It is a programming error to call this unless IsIntList() is true.
  std::vector<int32_t>& IntListValue() {
    assert(IsIntList());
    return *int_list_;
  }

  // Returns the 64-bit integer list this object represents.
  //
  // It is a programming error to call this unless IsLongList() is true.
  const std::vector<int64_t>& LongListValue() const {
    assert(IsLongList());
    return *long_list_;
  }

  // Returns the 64-bit integer list this object represents.
  //
  // It is a programming error to call this unless IsLongList() is true.
  std::vector<int64_t>& LongListValue() {
    assert(IsLongList());
    return *long_list_;
  }

  // Returns the double list this object represents.
  //
  // It is a programming error to call this unless IsDoubleList() is true.
  const std::vector<double>& DoubleListValue() const {
    assert(IsDoubleList());
    return *double_list_;
  }

  // Returns the double list this object represents.
  //
  // It is a programming error to call this unless IsDoubleList() is true.
  std::vector<double>& DoubleListValue() {
    assert(IsDoubleList());
    return *double_list_;
  }

  // Returns the list of EncodableValues this object represents.
  //
  // It is a programming error to call this unless IsList() is true.
  const EncodableList& ListValue() const {
    assert(IsList());
    return *list_;
  }

  // Returns the list of EncodableValues this object represents.
  //
  // It is a programming error to call this unless IsList() is true.
  EncodableList& ListValue() {
    assert(IsList());
    return *list_;
  }

  // Returns the map of EncodableValue : EncodableValue pairs this object
  // represent.
  //
  // It is a programming error to call this unless IsMap() is true.
  const EncodableMap& MapValue() const {
    assert(IsMap());
    return *map_;
  }

  // Returns the map of EncodableValue : EncodableValue pairs this object
  // represent.
  //
  // It is a programming error to call this unless IsMap() is true.
  EncodableMap& MapValue() {
    assert(IsMap());
    return *map_;
  }

  // Returns true if this represents a null value.
  bool IsNull() const { return type_ == Type::kNull; }

  // Returns true if this represents a bool value.
  bool IsBool() const { return type_ == Type::kBool; }

  // Returns true if this represents a 32-bit integer value.
  bool IsInt() const { return type_ == Type::kInt; }

  // Returns true if this represents a 64-bit integer value.
  bool IsLong() const { return type_ == Type::kLong; }

  // Returns true if this represents a double value.
  bool IsDouble() const { return type_ == Type::kDouble; }

  // Returns true if this represents a string value.
  bool IsString() const { return type_ == Type::kString; }

  // Returns true if this represents a list of bytes.
  bool IsByteList() const { return type_ == Type::kByteList; }

  // Returns true if this represents a list of 32-bit integers.
  bool IsIntList() const { return type_ == Type::kIntList; }

  // Returns true if this represents a list of 64-bit integers.
  bool IsLongList() const { return type_ == Type::kLongList; }

  // Returns true if this represents a list of doubles.
  bool IsDoubleList() const { return type_ == Type::kDoubleList; }

  // Returns true if this represents a list of EncodableValues.
  bool IsList() const { return type_ == Type::kList; }

  // Returns true if this represents a map of EncodableValue : EncodableValue
  // pairs.
  bool IsMap() const { return type_ == Type::kMap; }

  // Returns the type this value represents.
  //
  // This is primarily intended for use with switch(); for individual checks,
  // prefer an Is*() call.
  Type type() const { return type_; }

 private:
  // Performs any cleanup necessary for the active union value. This must be
  // called before assigning a new value, and on object destruction.
  //
  // After calling this, type_ will alway be kNull.
  void DestroyValue() {
    switch (type_) {
      case Type::kNull:
      case Type::kBool:
      case Type::kInt:
      case Type::kLong:
      case Type::kDouble:
        break;
      case Type::kString:
        delete string_;
        break;
      case Type::kByteList:
        delete byte_list_;
        break;
      case Type::kIntList:
        delete int_list_;
        break;
      case Type::kLongList:
        delete long_list_;
        break;
      case Type::kDoubleList:
        delete double_list_;
        break;
      case Type::kList:
        delete list_;
        break;
      case Type::kMap:
        delete map_;
        break;
    }

    type_ = Type::kNull;
  }

  // The anonymous union that stores the represented value. Accessing any of
  // these entries other than the one that corresponds to the current value of
  // |type_| has undefined behavior.
  //
  // Pointers are used for the non-POD types to avoid making the overall size
  // of the union unnecessarily large.
  //
  // TODO: Replace this with std::variant once c++17 is available.
  union {
    bool bool_;
    int32_t int_;
    int64_t long_;
    double double_;
    std::string* string_;
    std::vector<uint8_t>* byte_list_;
    std::vector<int32_t>* int_list_;
    std::vector<int64_t>* long_list_;
    std::vector<double>* double_list_;
    std::vector<EncodableValue>* list_;
    std::map<EncodableValue, EncodableValue>* map_;
  };

  // The currently active union entry.
  Type type_ = Type::kNull;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_ENCODABLE_VALUE_H_

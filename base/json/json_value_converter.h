// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_JSON_JSON_VALUE_CONVERTER_H_
#define BASE_JSON_JSON_VALUE_CONVERTER_H_

#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/scoped_vector.h"
#include "base/stl_util.h"
#include "base/strings/string16.h"
#include "base/strings/string_piece.h"
#include "base/values.h"

// JSONValueConverter converts a JSON value into a C++ struct in a
// lightweight way.
//
// Usage:
// For real examples, you may want to refer to _unittest.cc file.
//
// Assume that you have a struct like this:
//   struct Message {
//     int foo;
//     std::string bar;
//     static void RegisterJSONConverter(
//         JSONValueConverter<Message>* converter);
//   };
//
// And you want to parse a json data into this struct.  First, you
// need to declare RegisterJSONConverter() method in your struct.
//   // static
//   void Message::RegisterJSONConverter(
//       JSONValueConverter<Message>* converter) {
//     converter->RegisterIntField("foo", &Message::foo);
//     converter->RegisterStringField("bar", &Message::bar);
//   }
//
// Then, you just instantiate your JSONValueConverter of your type and call
// Convert() method.
//   Message message;
//   JSONValueConverter<Message> converter;
//   converter.Convert(json, &message);
//
// Convert() returns false when it fails.  Here "fail" means that the value is
// structurally different from expected, such like a string value appears
// for an int field.  Do not report failures for missing fields.
// Also note that Convert() will modify the passed |message| even when it
// fails for performance reason.
//
// For nested field, the internal message also has to implement the registration
// method.  Then, just use RegisterNestedField() from the containing struct's
// RegisterJSONConverter method.
//   struct Nested {
//     Message foo;
//     static void RegisterJSONConverter(...) {
//       ...
//       converter->RegisterNestedField("foo", &Nested::foo);
//     }
//   };
//
// For repeated field, we just assume ScopedVector for its container
// and you can put RegisterRepeatedInt or some other types.  Use
// RegisterRepeatedMessage for nested repeated fields.
//
// Sometimes JSON format uses string representations for other types such
// like enum, timestamp, or URL.  You can use RegisterCustomField method
// and specify a function to convert a StringPiece to your type.
//   bool ConvertFunc(const StringPiece& s, YourEnum* result) {
//     // do something and return true if succeed...
//   }
//   struct Message {
//     YourEnum ye;
//     ...
//     static void RegisterJSONConverter(...) {
//       ...
//       converter->RegsiterCustomField<YourEnum>(
//           "your_enum", &Message::ye, &ConvertFunc);
//     }
//   };

namespace base {

template <typename StructType>
class JSONValueConverter;

namespace internal {

template<typename StructType>
class FieldConverterBase {
 public:
  explicit FieldConverterBase(const std::string& path) : field_path_(path) {}
  virtual ~FieldConverterBase() {}
  virtual bool ConvertField(const base::Value& value, StructType* obj)
      const = 0;
  const std::string& field_path() const { return field_path_; }

 private:
  std::string field_path_;
  DISALLOW_COPY_AND_ASSIGN(FieldConverterBase);
};

template <typename FieldType>
class ValueConverter {
 public:
  virtual ~ValueConverter() {}
  virtual bool Convert(const base::Value& value, FieldType* field) const = 0;
};

template <typename StructType, typename FieldType>
class FieldConverter : public FieldConverterBase<StructType> {
 public:
  explicit FieldConverter(const std::string& path,
                          FieldType StructType::* field,
                          ValueConverter<FieldType>* converter)
      : FieldConverterBase<StructType>(path),
        field_pointer_(field),
        value_converter_(converter) {
  }

  bool ConvertField(const base::Value& value, StructType* dst) const override {
    return value_converter_->Convert(value, &(dst->*field_pointer_));
  }

 private:
  FieldType StructType::* field_pointer_;
  scoped_ptr<ValueConverter<FieldType> > value_converter_;
  DISALLOW_COPY_AND_ASSIGN(FieldConverter);
};

template <typename FieldType>
class BasicValueConverter;

template <>
class BASE_EXPORT BasicValueConverter<int> : public ValueConverter<int> {
 public:
  BasicValueConverter() {}

  bool Convert(const base::Value& value, int* field) const override;

 private:
  DISALLOW_COPY_AND_ASSIGN(BasicValueConverter);
};

template <>
class BASE_EXPORT BasicValueConverter<std::string>
    : public ValueConverter<std::string> {
 public:
  BasicValueConverter() {}

  bool Convert(const base::Value& value, std::string* field) const override;

 private:
  DISALLOW_COPY_AND_ASSIGN(BasicValueConverter);
};

template <>
class BASE_EXPORT BasicValueConverter<string16>
    : public ValueConverter<string16> {
 public:
  BasicValueConverter() {}

  bool Convert(const base::Value& value, string16* field) const override;

 private:
  DISALLOW_COPY_AND_ASSIGN(BasicValueConverter);
};

template <>
class BASE_EXPORT BasicValueConverter<double> : public ValueConverter<double> {
 public:
  BasicValueConverter() {}

  bool Convert(const base::Value& value, double* field) const override;

 private:
  DISALLOW_COPY_AND_ASSIGN(BasicValueConverter);
};

template <>
class BASE_EXPORT BasicValueConverter<bool> : public ValueConverter<bool> {
 public:
  BasicValueConverter() {}

  bool Convert(const base::Value& value, bool* field) const override;

 private:
  DISALLOW_COPY_AND_ASSIGN(BasicValueConverter);
};

template <typename FieldType>
class ValueFieldConverter : public ValueConverter<FieldType> {
 public:
  typedef bool(*ConvertFunc)(const base::Value* value, FieldType* field);

  ValueFieldConverter(ConvertFunc convert_func)
      : convert_func_(convert_func) {}

  bool Convert(const base::Value& value, FieldType* field) const override {
    return convert_func_(&value, field);
  }

 private:
  ConvertFunc convert_func_;

  DISALLOW_COPY_AND_ASSIGN(ValueFieldConverter);
};

template <typename FieldType>
class CustomFieldConverter : public ValueConverter<FieldType> {
 public:
  typedef bool(*ConvertFunc)(const StringPiece& value, FieldType* field);

  CustomFieldConverter(ConvertFunc convert_func)
      : convert_func_(convert_func) {}

  bool Convert(const base::Value& value, FieldType* field) const override {
    std::string string_value;
    return value.GetAsString(&string_value) &&
        convert_func_(string_value, field);
  }

 private:
  ConvertFunc convert_func_;

  DISALLOW_COPY_AND_ASSIGN(CustomFieldConverter);
};

template <typename NestedType>
class NestedValueConverter : public ValueConverter<NestedType> {
 public:
  NestedValueConverter() {}

  bool Convert(const base::Value& value, NestedType* field) const override {
    return converter_.Convert(value, field);
  }

 private:
  JSONValueConverter<NestedType> converter_;
  DISALLOW_COPY_AND_ASSIGN(NestedValueConverter);
};

template <typename Element>
class RepeatedValueConverter : public ValueConverter<ScopedVector<Element> > {
 public:
  RepeatedValueConverter() {}

  bool Convert(const base::Value& value,
               ScopedVector<Element>* field) const override {
    const base::ListValue* list = NULL;
    if (!value.GetAsList(&list)) {
      // The field is not a list.
      return false;
    }

    field->reserve(list->GetSize());
    for (size_t i = 0; i < list->GetSize(); ++i) {
      const base::Value* element = NULL;
      if (!list->Get(i, &element))
        continue;

      scoped_ptr<Element> e(new Element);
      if (basic_converter_.Convert(*element, e.get())) {
        field->push_back(e.release());
      } else {
        DVLOG(1) << "failure at " << i << "-th element";
        return false;
      }
    }
    return true;
  }

 private:
  BasicValueConverter<Element> basic_converter_;
  DISALLOW_COPY_AND_ASSIGN(RepeatedValueConverter);
};

template <typename NestedType>
class RepeatedMessageConverter
    : public ValueConverter<ScopedVector<NestedType> > {
 public:
  RepeatedMessageConverter() {}

  bool Convert(const base::Value& value,
               ScopedVector<NestedType>* field) const override {
    const base::ListValue* list = NULL;
    if (!value.GetAsList(&list))
      return false;

    field->reserve(list->GetSize());
    for (size_t i = 0; i < list->GetSize(); ++i) {
      const base::Value* element = NULL;
      if (!list->Get(i, &element))
        continue;

      scoped_ptr<NestedType> nested(new NestedType);
      if (converter_.Convert(*element, nested.get())) {
        field->push_back(nested.release());
      } else {
        DVLOG(1) << "failure at " << i << "-th element";
        return false;
      }
    }
    return true;
  }

 private:
  JSONValueConverter<NestedType> converter_;
  DISALLOW_COPY_AND_ASSIGN(RepeatedMessageConverter);
};

template <typename NestedType>
class RepeatedCustomValueConverter
    : public ValueConverter<ScopedVector<NestedType> > {
 public:
  typedef bool(*ConvertFunc)(const base::Value* value, NestedType* field);

  RepeatedCustomValueConverter(ConvertFunc convert_func)
      : convert_func_(convert_func) {}

  bool Convert(const base::Value& value,
               ScopedVector<NestedType>* field) const override {
    const base::ListValue* list = NULL;
    if (!value.GetAsList(&list))
      return false;

    field->reserve(list->GetSize());
    for (size_t i = 0; i < list->GetSize(); ++i) {
      const base::Value* element = NULL;
      if (!list->Get(i, &element))
        continue;

      scoped_ptr<NestedType> nested(new NestedType);
      if ((*convert_func_)(element, nested.get())) {
        field->push_back(nested.release());
      } else {
        DVLOG(1) << "failure at " << i << "-th element";
        return false;
      }
    }
    return true;
  }

 private:
  ConvertFunc convert_func_;
  DISALLOW_COPY_AND_ASSIGN(RepeatedCustomValueConverter);
};


}  // namespace internal

template <class StructType>
class JSONValueConverter {
 public:
  JSONValueConverter() {
    StructType::RegisterJSONConverter(this);
  }

  void RegisterIntField(const std::string& field_name,
                        int StructType::* field) {
    fields_.push_back(new internal::FieldConverter<StructType, int>(
        field_name, field, new internal::BasicValueConverter<int>));
  }

  void RegisterStringField(const std::string& field_name,
                           std::string StructType::* field) {
    fields_.push_back(new internal::FieldConverter<StructType, std::string>(
        field_name, field, new internal::BasicValueConverter<std::string>));
  }

  void RegisterStringField(const std::string& field_name,
                           string16 StructType::* field) {
    fields_.push_back(new internal::FieldConverter<StructType, string16>(
        field_name, field, new internal::BasicValueConverter<string16>));
  }

  void RegisterBoolField(const std::string& field_name,
                         bool StructType::* field) {
    fields_.push_back(new internal::FieldConverter<StructType, bool>(
        field_name, field, new internal::BasicValueConverter<bool>));
  }

  void RegisterDoubleField(const std::string& field_name,
                           double StructType::* field) {
    fields_.push_back(new internal::FieldConverter<StructType, double>(
        field_name, field, new internal::BasicValueConverter<double>));
  }

  template <class NestedType>
  void RegisterNestedField(
      const std::string& field_name, NestedType StructType::* field) {
    fields_.push_back(new internal::FieldConverter<StructType, NestedType>(
            field_name,
            field,
            new internal::NestedValueConverter<NestedType>));
  }

  template <typename FieldType>
  void RegisterCustomField(
      const std::string& field_name,
      FieldType StructType::* field,
      bool (*convert_func)(const StringPiece&, FieldType*)) {
    fields_.push_back(new internal::FieldConverter<StructType, FieldType>(
        field_name,
        field,
        new internal::CustomFieldConverter<FieldType>(convert_func)));
  }

  template <typename FieldType>
  void RegisterCustomValueField(
      const std::string& field_name,
      FieldType StructType::* field,
      bool (*convert_func)(const base::Value*, FieldType*)) {
    fields_.push_back(new internal::FieldConverter<StructType, FieldType>(
        field_name,
        field,
        new internal::ValueFieldConverter<FieldType>(convert_func)));
  }

  void RegisterRepeatedInt(const std::string& field_name,
                           ScopedVector<int> StructType::* field) {
    fields_.push_back(
        new internal::FieldConverter<StructType, ScopedVector<int> >(
            field_name, field, new internal::RepeatedValueConverter<int>));
  }

  void RegisterRepeatedString(const std::string& field_name,
                              ScopedVector<std::string> StructType::* field) {
    fields_.push_back(
        new internal::FieldConverter<StructType, ScopedVector<std::string> >(
            field_name,
            field,
            new internal::RepeatedValueConverter<std::string>));
  }

  void RegisterRepeatedString(const std::string& field_name,
                              ScopedVector<string16> StructType::* field) {
    fields_.push_back(
        new internal::FieldConverter<StructType, ScopedVector<string16> >(
            field_name,
            field,
            new internal::RepeatedValueConverter<string16>));
  }

  void RegisterRepeatedDouble(const std::string& field_name,
                              ScopedVector<double> StructType::* field) {
    fields_.push_back(
        new internal::FieldConverter<StructType, ScopedVector<double> >(
            field_name, field, new internal::RepeatedValueConverter<double>));
  }

  void RegisterRepeatedBool(const std::string& field_name,
                            ScopedVector<bool> StructType::* field) {
    fields_.push_back(
        new internal::FieldConverter<StructType, ScopedVector<bool> >(
            field_name, field, new internal::RepeatedValueConverter<bool>));
  }

  template <class NestedType>
  void RegisterRepeatedCustomValue(
      const std::string& field_name,
      ScopedVector<NestedType> StructType::* field,
      bool (*convert_func)(const base::Value*, NestedType*)) {
    fields_.push_back(
        new internal::FieldConverter<StructType, ScopedVector<NestedType> >(
            field_name,
            field,
            new internal::RepeatedCustomValueConverter<NestedType>(
                convert_func)));
  }

  template <class NestedType>
  void RegisterRepeatedMessage(const std::string& field_name,
                               ScopedVector<NestedType> StructType::* field) {
    fields_.push_back(
        new internal::FieldConverter<StructType, ScopedVector<NestedType> >(
            field_name,
            field,
            new internal::RepeatedMessageConverter<NestedType>));
  }

  bool Convert(const base::Value& value, StructType* output) const {
    const DictionaryValue* dictionary_value = NULL;
    if (!value.GetAsDictionary(&dictionary_value))
      return false;

    for(size_t i = 0; i < fields_.size(); ++i) {
      const internal::FieldConverterBase<StructType>* field_converter =
          fields_[i];
      const base::Value* field = NULL;
      if (dictionary_value->Get(field_converter->field_path(), &field)) {
        if (!field_converter->ConvertField(*field, output)) {
          DVLOG(1) << "failure at field " << field_converter->field_path();
          return false;
        }
      }
    }
    return true;
  }

 private:
  ScopedVector<internal::FieldConverterBase<StructType> > fields_;

  DISALLOW_COPY_AND_ASSIGN(JSONValueConverter);
};

}  // namespace base

#endif  // BASE_JSON_JSON_VALUE_CONVERTER_H_

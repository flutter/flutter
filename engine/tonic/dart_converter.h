// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_CONVERTER_H_
#define SKY_ENGINE_TONIC_DART_CONVERTER_H_

#include <string>
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/tonic/dart_string.h"
#include "sky/engine/tonic/dart_string_cache.h"
#include "sky/engine/tonic/dart_value.h"
#include "sky/engine/wtf/text/StringUTF8Adaptor.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

// DartConvert converts types back and forth from Sky to Dart. The template
// parameter |T| determines what kind of type conversion to perform.
template <typename T, typename Enable = void>
struct DartConverter {};

////////////////////////////////////////////////////////////////////////////////
// Boolean

template <>
struct DartConverter<bool> {
  static Dart_Handle ToDart(bool val) { return Dart_NewBoolean(val); }

  static void SetReturnValue(Dart_NativeArguments args, bool val) {
    Dart_SetBooleanReturnValue(args, val);
  }

  static bool FromDart(Dart_Handle handle) {
    bool result = 0;
    Dart_BooleanValue(handle, &result);
    return result;
  }

  static bool FromArguments(Dart_NativeArguments args,
                            int index,
                            Dart_Handle& exception) {
    bool result = false;
    Dart_GetNativeBooleanArgument(args, index, &result);
    return result;
  }
};

////////////////////////////////////////////////////////////////////////////////
// Numbers

template <typename T>
struct DartConverterInteger {
  static Dart_Handle ToDart(T val) { return Dart_NewInteger(val); }

  static void SetReturnValue(Dart_NativeArguments args, T val) {
    Dart_SetIntegerReturnValue(args, val);
  }

  static T FromDart(Dart_Handle handle) {
    int64_t result = 0;
    Dart_IntegerToInt64(handle, &result);
    return result;
  }

  static T FromArguments(Dart_NativeArguments args,
                         int index,
                         Dart_Handle& exception) {
    int64_t result = 0;
    Dart_GetNativeIntegerArgument(args, index, &result);
    return result;
  }
};

template <>
struct DartConverter<int> : public DartConverterInteger<int> {};

template <>
struct DartConverter<unsigned> : public DartConverterInteger<unsigned> {};

template <>
struct DartConverter<long long> : public DartConverterInteger<long long> {};

template <>
struct DartConverter<unsigned long long> {
  static Dart_Handle ToDart(unsigned long long val) {
    // FIXME: WebIDL unsigned long long is guaranteed to fit into 64-bit
    // unsigned,
    // so we need a dart API for constructing an integer from uint64_t.
    DCHECK(val <= 0x7fffffffffffffffLL);
    return Dart_NewInteger(static_cast<int64_t>(val));
  }

  static void SetReturnValue(Dart_NativeArguments args,
                             unsigned long long val) {
    DCHECK(val <= 0x7fffffffffffffffLL);
    Dart_SetIntegerReturnValue(args, val);
  }

  static unsigned long long FromDart(Dart_Handle handle) {
    int64_t result = 0;
    Dart_IntegerToInt64(handle, &result);
    return result;
  }

  static unsigned long long FromArguments(Dart_NativeArguments args,
                                          int index,
                                          Dart_Handle& exception) {
    int64_t result = 0;
    Dart_GetNativeIntegerArgument(args, index, &result);
    return result;
  }
};

template <typename T>
struct DartConverterFloatingPoint {
  static Dart_Handle ToDart(T val) { return Dart_NewDouble(val); }

  static void SetReturnValue(Dart_NativeArguments args, T val) {
    Dart_SetDoubleReturnValue(args, val);
  }

  static T FromDart(Dart_Handle handle) {
    double result = 0;
    Dart_DoubleValue(handle, &result);
    return result;
  }

  static T FromArguments(Dart_NativeArguments args,
                         int index,
                         Dart_Handle& exception) {
    double result = 0;
    Dart_GetNativeDoubleArgument(args, index, &result);
    return result;
  }
};

template <>
struct DartConverter<float> : public DartConverterFloatingPoint<float> {};

template <>
struct DartConverter<double> : public DartConverterFloatingPoint<double> {};

////////////////////////////////////////////////////////////////////////////////
// Strings

template <>
struct DartConverter<String> {
  static Dart_Handle ToDart(DartState* state, const String& val) {
    if (val.isEmpty())
      return Dart_EmptyString();
    return Dart_HandleFromWeakPersistent(state->string_cache().Get(val.impl()));
  }

  static void SetReturnValue(Dart_NativeArguments args,
                             const String& val,
                             bool auto_scope = true) {
    // TODO(abarth): What should we do with auto_scope?
    if (val.isEmpty()) {
      Dart_SetReturnValue(args, Dart_EmptyString());
      return;
    }
    DartState* state = DartState::Current();
    Dart_SetWeakHandleReturnValue(args, state->string_cache().Get(val.impl()));
  }

  static void SetReturnValueWithNullCheck(Dart_NativeArguments args,
                                          const String& val,
                                          bool auto_scope = true) {
    if (val.isNull())
      Dart_SetReturnValue(args, Dart_Null());
    else
      SetReturnValue(args, val, auto_scope);
  }

  static String FromDart(Dart_Handle handle) {
    intptr_t char_size = 0;
    intptr_t length = 0;
    void* peer = nullptr;
    Dart_Handle result =
        Dart_StringGetProperties(handle, &char_size, &length, &peer);
    if (peer)
      return String(static_cast<StringImpl*>(peer));
    if (Dart_IsError(result))
      return String();
    return ExternalizeDartString(handle);
  }

  static String FromArguments(Dart_NativeArguments args,
                              int index,
                              Dart_Handle& exception,
                              bool auto_scope = true) {
    // TODO(abarth): What should we do with auto_scope?
    void* peer = nullptr;
    Dart_Handle handle = Dart_GetNativeStringArgument(args, index, &peer);
    if (peer)
      return reinterpret_cast<StringImpl*>(peer);
    if (Dart_IsError(handle))
      return String();
    return ExternalizeDartString(handle);
  }

  static String FromArgumentsWithNullCheck(Dart_NativeArguments args,
                                           int index,
                                           Dart_Handle& exception,
                                           bool auto_scope = true) {
    // TODO(abarth): What should we do with auto_scope?
    void* peer = nullptr;
    Dart_Handle handle = Dart_GetNativeStringArgument(args, index, &peer);
    if (peer)
      return reinterpret_cast<StringImpl*>(peer);
    if (Dart_IsError(handle) || Dart_IsNull(handle))
      return String();
    return ExternalizeDartString(handle);
  }
};

template <>
struct DartConverter<AtomicString> {
  static Dart_Handle ToDart(DartState* state, const AtomicString& val) {
    return DartConverter<String>::ToDart(state, val.string());
  }
};

////////////////////////////////////////////////////////////////////////////////
// Collections

template <typename T>
struct DartConverter<Vector<T>> {
  static Dart_Handle ToDart(const Vector<T>& val) {
    Dart_Handle list = Dart_NewList(val.size());
    if (Dart_IsError(list))
      return list;
    for (size_t i = 0; i < val.size(); i++) {
      Dart_Handle result =
          Dart_ListSetAt(list, i, DartConverter<T>::ToDart(val[i]));
      if (Dart_IsError(result))
        return result;
    }
    return list;
  }

  static Vector<T> FromDart(Dart_Handle handle) {
    Vector<T> result;
    if (!Dart_IsList(handle))
      return result;
    intptr_t length = 0;
    Dart_ListLength(handle, &length);
    result.reserveCapacity(length);
    for (intptr_t i = 0; i < length; ++i) {
      Dart_Handle item = Dart_ListGetAt(handle, i);
      DCHECK(!Dart_IsError(item));
      DCHECK(item);
      result.append(DartConverter<T>::FromDart(item));
    }
    return result;
  }

  static Vector<T> FromArguments(Dart_NativeArguments args,
                                 int index,
                                 Dart_Handle& exception,
                                 bool auto_scope = true) {
    // TODO(abarth): What should we do with auto_scope?
    return FromDart(Dart_GetNativeArgument(args, index));
  }
};

////////////////////////////////////////////////////////////////////////////////
// DartValue

template <>
struct DartConverter<DartValue> {
  static Dart_Handle ToDart(DartState* state, DartValue* val) {
    return val->dart_value();
  }

  static void SetReturnValue(Dart_NativeArguments args, DartValue* val) {
    Dart_SetReturnValue(args, val->dart_value());
  }
};

////////////////////////////////////////////////////////////////////////////////
// Convience wrappers for commonly used conversions

inline Dart_Handle StringToDart(DartState* state, const String& val) {
  return DartConverter<String>::ToDart(state, val);
}

inline Dart_Handle StringToDart(DartState* state, const AtomicString& val) {
  return DartConverter<AtomicString>::ToDart(state, val);
}

inline String StringFromDart(Dart_Handle handle) {
  return DartConverter<String>::FromDart(handle);
}

////////////////////////////////////////////////////////////////////////////////
// Convience wrappers using type inference for ease of code generation

template <typename T>
inline Dart_Handle VectorToDart(const Vector<T>& val) {
  return DartConverter<Vector<T>>::ToDart(val);
}

template<typename T>
Dart_Handle ToDart(const T& object) {
  return DartConverter<T>::ToDart(object);
}

////////////////////////////////////////////////////////////////////////////////
// std::string support (slower, but more convienent for some clients)

inline Dart_Handle StdStringToDart(const std::string& val) {
  return Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(val.data()),
                                val.length());
}

inline std::string StdStringFromDart(Dart_Handle handle) {
  String string = StringFromDart(handle);
  StringUTF8Adaptor utf8(string);
  return std::string(utf8.data(), utf8.length());
}


// Alias Dart_NewStringFromCString for less typing.
inline Dart_Handle ToDart(const char* val) {
  return Dart_NewStringFromCString(val);
}

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_CONVERTER_H_

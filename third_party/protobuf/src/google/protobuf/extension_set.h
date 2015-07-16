// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.
//
// This header is logically internal, but is made public because it is used
// from protocol-compiler-generated code, which may reside in other components.

#ifndef GOOGLE_PROTOBUF_EXTENSION_SET_H__
#define GOOGLE_PROTOBUF_EXTENSION_SET_H__

#include <vector>
#include <map>
#include <utility>
#include <string>


#include <google/protobuf/stubs/common.h>

namespace google {

namespace protobuf {
  class Descriptor;                                    // descriptor.h
  class FieldDescriptor;                               // descriptor.h
  class DescriptorPool;                                // descriptor.h
  class MessageLite;                                   // message_lite.h
  class Message;                                       // message.h
  class MessageFactory;                                // message.h
  class UnknownFieldSet;                               // unknown_field_set.h
  namespace io {
    class CodedInputStream;                              // coded_stream.h
    class CodedOutputStream;                             // coded_stream.h
  }
  namespace internal {
    class FieldSkipper;                                  // wire_format_lite.h
    class RepeatedPtrFieldBase;                          // repeated_field.h
  }
  template <typename Element> class RepeatedField;     // repeated_field.h
  template <typename Element> class RepeatedPtrField;  // repeated_field.h
}

namespace protobuf {
namespace internal {

// Used to store values of type WireFormatLite::FieldType without having to
// #include wire_format_lite.h.  Also, ensures that we use only one byte to
// store these values, which is important to keep the layout of
// ExtensionSet::Extension small.
typedef uint8 FieldType;

// A function which, given an integer value, returns true if the number
// matches one of the defined values for the corresponding enum type.  This
// is used with RegisterEnumExtension, below.
typedef bool EnumValidityFunc(int number);

// Version of the above which takes an argument.  This is needed to deal with
// extensions that are not compiled in.
typedef bool EnumValidityFuncWithArg(const void* arg, int number);

// Information about a registered extension.
struct ExtensionInfo {
  inline ExtensionInfo() {}
  inline ExtensionInfo(FieldType type_param, bool isrepeated, bool ispacked)
      : type(type_param), is_repeated(isrepeated), is_packed(ispacked),
        descriptor(NULL) {}

  FieldType type;
  bool is_repeated;
  bool is_packed;

  struct EnumValidityCheck {
    EnumValidityFuncWithArg* func;
    const void* arg;
  };

  union {
    EnumValidityCheck enum_validity_check;
    const MessageLite* message_prototype;
  };

  // The descriptor for this extension, if one exists and is known.  May be
  // NULL.  Must not be NULL if the descriptor for the extension does not
  // live in the same pool as the descriptor for the containing type.
  const FieldDescriptor* descriptor;
};

// Abstract interface for an object which looks up extension definitions.  Used
// when parsing.
class LIBPROTOBUF_EXPORT ExtensionFinder {
 public:
  virtual ~ExtensionFinder();

  // Find the extension with the given containing type and number.
  virtual bool Find(int number, ExtensionInfo* output) = 0;
};

// Implementation of ExtensionFinder which finds extensions defined in .proto
// files which have been compiled into the binary.
class LIBPROTOBUF_EXPORT GeneratedExtensionFinder : public ExtensionFinder {
 public:
  GeneratedExtensionFinder(const MessageLite* containing_type)
      : containing_type_(containing_type) {}
  virtual ~GeneratedExtensionFinder() {}

  // Returns true and fills in *output if found, otherwise returns false.
  virtual bool Find(int number, ExtensionInfo* output);

 private:
  const MessageLite* containing_type_;
};

// Note:  extension_set_heavy.cc defines DescriptorPoolExtensionFinder for
// finding extensions from a DescriptorPool.

// This is an internal helper class intended for use within the protocol buffer
// library and generated classes.  Clients should not use it directly.  Instead,
// use the generated accessors such as GetExtension() of the class being
// extended.
//
// This class manages extensions for a protocol message object.  The
// message's HasExtension(), GetExtension(), MutableExtension(), and
// ClearExtension() methods are just thin wrappers around the embedded
// ExtensionSet.  When parsing, if a tag number is encountered which is
// inside one of the message type's extension ranges, the tag is passed
// off to the ExtensionSet for parsing.  Etc.
class LIBPROTOBUF_EXPORT ExtensionSet {
 public:
  ExtensionSet();
  ~ExtensionSet();

  // These are called at startup by protocol-compiler-generated code to
  // register known extensions.  The registrations are used by ParseField()
  // to look up extensions for parsed field numbers.  Note that dynamic parsing
  // does not use ParseField(); only protocol-compiler-generated parsing
  // methods do.
  static void RegisterExtension(const MessageLite* containing_type,
                                int number, FieldType type,
                                bool is_repeated, bool is_packed);
  static void RegisterEnumExtension(const MessageLite* containing_type,
                                    int number, FieldType type,
                                    bool is_repeated, bool is_packed,
                                    EnumValidityFunc* is_valid);
  static void RegisterMessageExtension(const MessageLite* containing_type,
                                       int number, FieldType type,
                                       bool is_repeated, bool is_packed,
                                       const MessageLite* prototype);

  // =================================================================

  // Add all fields which are currently present to the given vector.  This
  // is useful to implement Reflection::ListFields().
  void AppendToList(const Descriptor* containing_type,
                    const DescriptorPool* pool,
                    std::vector<const FieldDescriptor*>* output) const;

  // =================================================================
  // Accessors
  //
  // Generated message classes include type-safe templated wrappers around
  // these methods.  Generally you should use those rather than call these
  // directly, unless you are doing low-level memory management.
  //
  // When calling any of these accessors, the extension number requested
  // MUST exist in the DescriptorPool provided to the constructor.  Otheriwse,
  // the method will fail an assert.  Normally, though, you would not call
  // these directly; you would either call the generated accessors of your
  // message class (e.g. GetExtension()) or you would call the accessors
  // of the reflection interface.  In both cases, it is impossible to
  // trigger this assert failure:  the generated accessors only accept
  // linked-in extension types as parameters, while the Reflection interface
  // requires you to provide the FieldDescriptor describing the extension.
  //
  // When calling any of these accessors, a protocol-compiler-generated
  // implementation of the extension corresponding to the number MUST
  // be linked in, and the FieldDescriptor used to refer to it MUST be
  // the one generated by that linked-in code.  Otherwise, the method will
  // die on an assert failure.  The message objects returned by the message
  // accessors are guaranteed to be of the correct linked-in type.
  //
  // These methods pretty much match Reflection except that:
  // - They're not virtual.
  // - They identify fields by number rather than FieldDescriptors.
  // - They identify enum values using integers rather than descriptors.
  // - Strings provide Mutable() in addition to Set() accessors.

  bool Has(int number) const;
  int ExtensionSize(int number) const;   // Size of a repeated extension.
  int NumExtensions() const;  // The number of extensions
  FieldType ExtensionType(int number) const;
  void ClearExtension(int number);

  // singular fields -------------------------------------------------

  int32  GetInt32 (int number, int32  default_value) const;
  int64  GetInt64 (int number, int64  default_value) const;
  uint32 GetUInt32(int number, uint32 default_value) const;
  uint64 GetUInt64(int number, uint64 default_value) const;
  float  GetFloat (int number, float  default_value) const;
  double GetDouble(int number, double default_value) const;
  bool   GetBool  (int number, bool   default_value) const;
  int    GetEnum  (int number, int    default_value) const;
  const string & GetString (int number, const string&  default_value) const;
  const MessageLite& GetMessage(int number,
                                const MessageLite& default_value) const;
  const MessageLite& GetMessage(int number, const Descriptor* message_type,
                                MessageFactory* factory) const;

  // |descriptor| may be NULL so long as it is known that the descriptor for
  // the extension lives in the same pool as the descriptor for the containing
  // type.
#define desc const FieldDescriptor* descriptor  // avoid line wrapping
  void SetInt32 (int number, FieldType type, int32  value, desc);
  void SetInt64 (int number, FieldType type, int64  value, desc);
  void SetUInt32(int number, FieldType type, uint32 value, desc);
  void SetUInt64(int number, FieldType type, uint64 value, desc);
  void SetFloat (int number, FieldType type, float  value, desc);
  void SetDouble(int number, FieldType type, double value, desc);
  void SetBool  (int number, FieldType type, bool   value, desc);
  void SetEnum  (int number, FieldType type, int    value, desc);
  void SetString(int number, FieldType type, const string& value, desc);
  string * MutableString (int number, FieldType type, desc);
  MessageLite* MutableMessage(int number, FieldType type,
                              const MessageLite& prototype, desc);
  MessageLite* MutableMessage(const FieldDescriptor* decsriptor,
                              MessageFactory* factory);
  // Adds the given message to the ExtensionSet, taking ownership of the
  // message object. Existing message with the same number will be deleted.
  // If "message" is NULL, this is equivalent to "ClearExtension(number)".
  void SetAllocatedMessage(int number, FieldType type,
                           const FieldDescriptor* descriptor,
                           MessageLite* message);
  MessageLite* ReleaseMessage(int number, const MessageLite& prototype);
  MessageLite* ReleaseMessage(const FieldDescriptor* descriptor,
                              MessageFactory* factory);
#undef desc

  // repeated fields -------------------------------------------------

  void* MutableRawRepeatedField(int number);

  int32  GetRepeatedInt32 (int number, int index) const;
  int64  GetRepeatedInt64 (int number, int index) const;
  uint32 GetRepeatedUInt32(int number, int index) const;
  uint64 GetRepeatedUInt64(int number, int index) const;
  float  GetRepeatedFloat (int number, int index) const;
  double GetRepeatedDouble(int number, int index) const;
  bool   GetRepeatedBool  (int number, int index) const;
  int    GetRepeatedEnum  (int number, int index) const;
  const string & GetRepeatedString (int number, int index) const;
  const MessageLite& GetRepeatedMessage(int number, int index) const;

  void SetRepeatedInt32 (int number, int index, int32  value);
  void SetRepeatedInt64 (int number, int index, int64  value);
  void SetRepeatedUInt32(int number, int index, uint32 value);
  void SetRepeatedUInt64(int number, int index, uint64 value);
  void SetRepeatedFloat (int number, int index, float  value);
  void SetRepeatedDouble(int number, int index, double value);
  void SetRepeatedBool  (int number, int index, bool   value);
  void SetRepeatedEnum  (int number, int index, int    value);
  void SetRepeatedString(int number, int index, const string& value);
  string * MutableRepeatedString (int number, int index);
  MessageLite* MutableRepeatedMessage(int number, int index);

#define desc const FieldDescriptor* descriptor  // avoid line wrapping
  void AddInt32 (int number, FieldType type, bool packed, int32  value, desc);
  void AddInt64 (int number, FieldType type, bool packed, int64  value, desc);
  void AddUInt32(int number, FieldType type, bool packed, uint32 value, desc);
  void AddUInt64(int number, FieldType type, bool packed, uint64 value, desc);
  void AddFloat (int number, FieldType type, bool packed, float  value, desc);
  void AddDouble(int number, FieldType type, bool packed, double value, desc);
  void AddBool  (int number, FieldType type, bool packed, bool   value, desc);
  void AddEnum  (int number, FieldType type, bool packed, int    value, desc);
  void AddString(int number, FieldType type, const string& value, desc);
  string * AddString (int number, FieldType type, desc);
  MessageLite* AddMessage(int number, FieldType type,
                          const MessageLite& prototype, desc);
  MessageLite* AddMessage(const FieldDescriptor* descriptor,
                          MessageFactory* factory);
#undef desc

  void RemoveLast(int number);
  MessageLite* ReleaseLast(int number);
  void SwapElements(int number, int index1, int index2);

  // -----------------------------------------------------------------
  // TODO(kenton):  Hardcore memory management accessors

  // =================================================================
  // convenience methods for implementing methods of Message
  //
  // These could all be implemented in terms of the other methods of this
  // class, but providing them here helps keep the generated code size down.

  void Clear();
  void MergeFrom(const ExtensionSet& other);
  void Swap(ExtensionSet* other);
  bool IsInitialized() const;

  // Parses a single extension from the input. The input should start out
  // positioned immediately after the tag.
  bool ParseField(uint32 tag, io::CodedInputStream* input,
                  ExtensionFinder* extension_finder,
                  FieldSkipper* field_skipper);

  // Specific versions for lite or full messages (constructs the appropriate
  // FieldSkipper automatically).  |containing_type| is the default
  // instance for the containing message; it is used only to look up the
  // extension by number.  See RegisterExtension(), above.  Unlike the other
  // methods of ExtensionSet, this only works for generated message types --
  // it looks up extensions registered using RegisterExtension().
  bool ParseField(uint32 tag, io::CodedInputStream* input,
                  const MessageLite* containing_type,
                  UnknownFieldSet* unknown_fields);
  bool ParseFieldHeavy(uint32 tag, io::CodedInputStream* input,
                       const Message* containing_type,
                       UnknownFieldSet* unknown_fields);

  // Parse an entire message in MessageSet format.  Such messages have no
  // fields, only extensions.
  bool ParseMessageSet(io::CodedInputStream* input,
                       ExtensionFinder* extension_finder,
                       FieldSkipper* field_skipper);

  // Specific versions for lite or full messages (constructs the appropriate
  // FieldSkipper automatically).
  bool ParseMessageSet(io::CodedInputStream* input,
                       const MessageLite* containing_type,
                       UnknownFieldSet* unknown_fields);
  bool ParseMessageSetHeavy(io::CodedInputStream* input,
                            const Message* containing_type,
                            UnknownFieldSet* unknown_fields);

  // Write all extension fields with field numbers in the range
  //   [start_field_number, end_field_number)
  // to the output stream, using the cached sizes computed when ByteSize() was
  // last called.  Note that the range bounds are inclusive-exclusive.
  void SerializeWithCachedSizes(int start_field_number,
                                int end_field_number,
                                io::CodedOutputStream* output) const;

  // Same as SerializeWithCachedSizes, but without any bounds checking.
  // The caller must ensure that target has sufficient capacity for the
  // serialized extensions.
  //
  // Returns a pointer past the last written byte.
  uint8* SerializeWithCachedSizesToArray(int start_field_number,
                                         int end_field_number,
                                         uint8* target) const;

  // Like above but serializes in MessageSet format.
  void SerializeMessageSetWithCachedSizes(io::CodedOutputStream* output) const;
  uint8* SerializeMessageSetWithCachedSizesToArray(uint8* target) const;

  // Returns the total serialized size of all the extensions.
  int ByteSize() const;

  // Like ByteSize() but uses MessageSet format.
  int MessageSetByteSize() const;

  // Returns (an estimate of) the total number of bytes used for storing the
  // extensions in memory, excluding sizeof(*this).  If the ExtensionSet is
  // for a lite message (and thus possibly contains lite messages), the results
  // are undefined (might work, might crash, might corrupt data, might not even
  // be linked in).  It's up to the protocol compiler to avoid calling this on
  // such ExtensionSets (easy enough since lite messages don't implement
  // SpaceUsed()).
  int SpaceUsedExcludingSelf() const;

 private:

  // Interface of a lazily parsed singular message extension.
  class LIBPROTOBUF_EXPORT LazyMessageExtension {
   public:
    LazyMessageExtension() {}
    virtual ~LazyMessageExtension() {}

    virtual LazyMessageExtension* New() const = 0;
    virtual const MessageLite& GetMessage(
        const MessageLite& prototype) const = 0;
    virtual MessageLite* MutableMessage(const MessageLite& prototype) = 0;
    virtual void SetAllocatedMessage(MessageLite *message) = 0;
    virtual MessageLite* ReleaseMessage(const MessageLite& prototype) = 0;

    virtual bool IsInitialized() const = 0;
    virtual int ByteSize() const = 0;
    virtual int SpaceUsed() const = 0;

    virtual void MergeFrom(const LazyMessageExtension& other) = 0;
    virtual void Clear() = 0;

    virtual bool ReadMessage(const MessageLite& prototype,
                             io::CodedInputStream* input) = 0;
    virtual void WriteMessage(int number,
                              io::CodedOutputStream* output) const = 0;
    virtual uint8* WriteMessageToArray(int number, uint8* target) const = 0;
   private:
    GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(LazyMessageExtension);
  };
  struct Extension {
    // The order of these fields packs Extension into 24 bytes when using 8
    // byte alignment. Consider this when adding or removing fields here.
    union {
      int32                 int32_value;
      int64                 int64_value;
      uint32                uint32_value;
      uint64                uint64_value;
      float                 float_value;
      double                double_value;
      bool                  bool_value;
      int                   enum_value;
      string*               string_value;
      MessageLite*          message_value;
      LazyMessageExtension* lazymessage_value;

      RepeatedField   <int32      >* repeated_int32_value;
      RepeatedField   <int64      >* repeated_int64_value;
      RepeatedField   <uint32     >* repeated_uint32_value;
      RepeatedField   <uint64     >* repeated_uint64_value;
      RepeatedField   <float      >* repeated_float_value;
      RepeatedField   <double     >* repeated_double_value;
      RepeatedField   <bool       >* repeated_bool_value;
      RepeatedField   <int        >* repeated_enum_value;
      RepeatedPtrField<string     >* repeated_string_value;
      RepeatedPtrField<MessageLite>* repeated_message_value;
    };

    FieldType type;
    bool is_repeated;

    // For singular types, indicates if the extension is "cleared".  This
    // happens when an extension is set and then later cleared by the caller.
    // We want to keep the Extension object around for reuse, so instead of
    // removing it from the map, we just set is_cleared = true.  This has no
    // meaning for repeated types; for those, the size of the RepeatedField
    // simply becomes zero when cleared.
    bool is_cleared : 4;

    // For singular message types, indicates whether lazy parsing is enabled
    // for this extension. This field is only valid when type == TYPE_MESSAGE
    // and !is_repeated because we only support lazy parsing for singular
    // message types currently. If is_lazy = true, the extension is stored in
    // lazymessage_value. Otherwise, the extension will be message_value.
    bool is_lazy : 4;

    // For repeated types, this indicates if the [packed=true] option is set.
    bool is_packed;

    // For packed fields, the size of the packed data is recorded here when
    // ByteSize() is called then used during serialization.
    // TODO(kenton):  Use atomic<int> when C++ supports it.
    mutable int cached_size;

    // The descriptor for this extension, if one exists and is known.  May be
    // NULL.  Must not be NULL if the descriptor for the extension does not
    // live in the same pool as the descriptor for the containing type.
    const FieldDescriptor* descriptor;

    // Some helper methods for operations on a single Extension.
    void SerializeFieldWithCachedSizes(
        int number,
        io::CodedOutputStream* output) const;
    uint8* SerializeFieldWithCachedSizesToArray(
        int number,
        uint8* target) const;
    void SerializeMessageSetItemWithCachedSizes(
        int number,
        io::CodedOutputStream* output) const;
    uint8* SerializeMessageSetItemWithCachedSizesToArray(
        int number,
        uint8* target) const;
    int ByteSize(int number) const;
    int MessageSetItemByteSize(int number) const;
    void Clear();
    int GetSize() const;
    void Free();
    int SpaceUsedExcludingSelf() const;
  };


  // Returns true and fills field_number and extension if extension is found.
  bool FindExtensionInfoFromTag(uint32 tag, ExtensionFinder* extension_finder,
                                int* field_number, ExtensionInfo* extension);

  // Parses a single extension from the input. The input should start out
  // positioned immediately after the wire tag. This method is called in
  // ParseField() after field number is extracted from the wire tag and
  // ExtensionInfo is found by the field number.
  bool ParseFieldWithExtensionInfo(int field_number,
                                   const ExtensionInfo& extension,
                                   io::CodedInputStream* input,
                                   FieldSkipper* field_skipper);

  // Like ParseField(), but this method may parse singular message extensions
  // lazily depending on the value of FLAGS_eagerly_parse_message_sets.
  bool ParseFieldMaybeLazily(uint32 tag, io::CodedInputStream* input,
                             ExtensionFinder* extension_finder,
                             FieldSkipper* field_skipper);

  // Gets the extension with the given number, creating it if it does not
  // already exist.  Returns true if the extension did not already exist.
  bool MaybeNewExtension(int number, const FieldDescriptor* descriptor,
                         Extension** result);

  // Parse a single MessageSet item -- called just after the item group start
  // tag has been read.
  bool ParseMessageSetItem(io::CodedInputStream* input,
                           ExtensionFinder* extension_finder,
                           FieldSkipper* field_skipper);


  // Hack:  RepeatedPtrFieldBase declares ExtensionSet as a friend.  This
  //   friendship should automatically extend to ExtensionSet::Extension, but
  //   unfortunately some older compilers (e.g. GCC 3.4.4) do not implement this
  //   correctly.  So, we must provide helpers for calling methods of that
  //   class.

  // Defined in extension_set_heavy.cc.
  static inline int RepeatedMessage_SpaceUsedExcludingSelf(
      RepeatedPtrFieldBase* field);

  // The Extension struct is small enough to be passed by value, so we use it
  // directly as the value type in the map rather than use pointers.  We use
  // a map rather than hash_map here because we expect most ExtensionSets will
  // only contain a small number of extensions whereas hash_map is optimized
  // for 100 elements or more.  Also, we want AppendToList() to order fields
  // by field number.
  std::map<int, Extension> extensions_;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(ExtensionSet);
};

// These are just for convenience...
inline void ExtensionSet::SetString(int number, FieldType type,
                                    const string& value,
                                    const FieldDescriptor* descriptor) {
  MutableString(number, type, descriptor)->assign(value);
}
inline void ExtensionSet::SetRepeatedString(int number, int index,
                                            const string& value) {
  MutableRepeatedString(number, index)->assign(value);
}
inline void ExtensionSet::AddString(int number, FieldType type,
                                    const string& value,
                                    const FieldDescriptor* descriptor) {
  AddString(number, type, descriptor)->assign(value);
}

// ===================================================================
// Glue for generated extension accessors

// -------------------------------------------------------------------
// Template magic

// First we have a set of classes representing "type traits" for different
// field types.  A type traits class knows how to implement basic accessors
// for extensions of a particular type given an ExtensionSet.  The signature
// for a type traits class looks like this:
//
//   class TypeTraits {
//    public:
//     typedef ? ConstType;
//     typedef ? MutableType;
//
//     static inline ConstType Get(int number, const ExtensionSet& set);
//     static inline void Set(int number, ConstType value, ExtensionSet* set);
//     static inline MutableType Mutable(int number, ExtensionSet* set);
//
//     // Variants for repeated fields.
//     static inline ConstType Get(int number, const ExtensionSet& set,
//                                 int index);
//     static inline void Set(int number, int index,
//                            ConstType value, ExtensionSet* set);
//     static inline MutableType Mutable(int number, int index,
//                                       ExtensionSet* set);
//     static inline void Add(int number, ConstType value, ExtensionSet* set);
//     static inline MutableType Add(int number, ExtensionSet* set);
//   };
//
// Not all of these methods make sense for all field types.  For example, the
// "Mutable" methods only make sense for strings and messages, and the
// repeated methods only make sense for repeated types.  So, each type
// traits class implements only the set of methods from this signature that it
// actually supports.  This will cause a compiler error if the user tries to
// access an extension using a method that doesn't make sense for its type.
// For example, if "foo" is an extension of type "optional int32", then if you
// try to write code like:
//   my_message.MutableExtension(foo)
// you will get a compile error because PrimitiveTypeTraits<int32> does not
// have a "Mutable()" method.

// -------------------------------------------------------------------
// PrimitiveTypeTraits

// Since the ExtensionSet has different methods for each primitive type,
// we must explicitly define the methods of the type traits class for each
// known type.
template <typename Type>
class PrimitiveTypeTraits {
 public:
  typedef Type ConstType;

  static inline ConstType Get(int number, const ExtensionSet& set,
                              ConstType default_value);
  static inline void Set(int number, FieldType field_type,
                         ConstType value, ExtensionSet* set);
};

template <typename Type>
class RepeatedPrimitiveTypeTraits {
 public:
  typedef Type ConstType;

  static inline Type Get(int number, const ExtensionSet& set, int index);
  static inline void Set(int number, int index, Type value, ExtensionSet* set);
  static inline void Add(int number, FieldType field_type,
                         bool is_packed, Type value, ExtensionSet* set);
};

#define PROTOBUF_DEFINE_PRIMITIVE_TYPE(TYPE, METHOD)                       \
template<> inline TYPE PrimitiveTypeTraits<TYPE>::Get(                     \
    int number, const ExtensionSet& set, TYPE default_value) {             \
  return set.Get##METHOD(number, default_value);                           \
}                                                                          \
template<> inline void PrimitiveTypeTraits<TYPE>::Set(                     \
    int number, FieldType field_type, TYPE value, ExtensionSet* set) {     \
  set->Set##METHOD(number, field_type, value, NULL);                       \
}                                                                          \
                                                                           \
template<> inline TYPE RepeatedPrimitiveTypeTraits<TYPE>::Get(             \
    int number, const ExtensionSet& set, int index) {                      \
  return set.GetRepeated##METHOD(number, index);                           \
}                                                                          \
template<> inline void RepeatedPrimitiveTypeTraits<TYPE>::Set(             \
    int number, int index, TYPE value, ExtensionSet* set) {                \
  set->SetRepeated##METHOD(number, index, value);                          \
}                                                                          \
template<> inline void RepeatedPrimitiveTypeTraits<TYPE>::Add(             \
    int number, FieldType field_type, bool is_packed,                      \
    TYPE value, ExtensionSet* set) {                                       \
  set->Add##METHOD(number, field_type, is_packed, value, NULL);            \
}

PROTOBUF_DEFINE_PRIMITIVE_TYPE( int32,  Int32)
PROTOBUF_DEFINE_PRIMITIVE_TYPE( int64,  Int64)
PROTOBUF_DEFINE_PRIMITIVE_TYPE(uint32, UInt32)
PROTOBUF_DEFINE_PRIMITIVE_TYPE(uint64, UInt64)
PROTOBUF_DEFINE_PRIMITIVE_TYPE( float,  Float)
PROTOBUF_DEFINE_PRIMITIVE_TYPE(double, Double)
PROTOBUF_DEFINE_PRIMITIVE_TYPE(  bool,   Bool)

#undef PROTOBUF_DEFINE_PRIMITIVE_TYPE

// -------------------------------------------------------------------
// StringTypeTraits

// Strings support both Set() and Mutable().
class LIBPROTOBUF_EXPORT StringTypeTraits {
 public:
  typedef const string& ConstType;
  typedef string* MutableType;

  static inline const string& Get(int number, const ExtensionSet& set,
                                  ConstType default_value) {
    return set.GetString(number, default_value);
  }
  static inline void Set(int number, FieldType field_type,
                         const string& value, ExtensionSet* set) {
    set->SetString(number, field_type, value, NULL);
  }
  static inline string* Mutable(int number, FieldType field_type,
                                ExtensionSet* set) {
    return set->MutableString(number, field_type, NULL);
  }
};

class LIBPROTOBUF_EXPORT RepeatedStringTypeTraits {
 public:
  typedef const string& ConstType;
  typedef string* MutableType;

  static inline const string& Get(int number, const ExtensionSet& set,
                                  int index) {
    return set.GetRepeatedString(number, index);
  }
  static inline void Set(int number, int index,
                         const string& value, ExtensionSet* set) {
    set->SetRepeatedString(number, index, value);
  }
  static inline string* Mutable(int number, int index, ExtensionSet* set) {
    return set->MutableRepeatedString(number, index);
  }
  static inline void Add(int number, FieldType field_type,
                         bool /*is_packed*/, const string& value,
                         ExtensionSet* set) {
    set->AddString(number, field_type, value, NULL);
  }
  static inline string* Add(int number, FieldType field_type,
                            ExtensionSet* set) {
    return set->AddString(number, field_type, NULL);
  }
};

// -------------------------------------------------------------------
// EnumTypeTraits

// ExtensionSet represents enums using integers internally, so we have to
// static_cast around.
template <typename Type, bool IsValid(int)>
class EnumTypeTraits {
 public:
  typedef Type ConstType;

  static inline ConstType Get(int number, const ExtensionSet& set,
                              ConstType default_value) {
    return static_cast<Type>(set.GetEnum(number, default_value));
  }
  static inline void Set(int number, FieldType field_type,
                         ConstType value, ExtensionSet* set) {
    GOOGLE_DCHECK(IsValid(value));
    set->SetEnum(number, field_type, value, NULL);
  }
};

template <typename Type, bool IsValid(int)>
class RepeatedEnumTypeTraits {
 public:
  typedef Type ConstType;

  static inline ConstType Get(int number, const ExtensionSet& set, int index) {
    return static_cast<Type>(set.GetRepeatedEnum(number, index));
  }
  static inline void Set(int number, int index,
                         ConstType value, ExtensionSet* set) {
    GOOGLE_DCHECK(IsValid(value));
    set->SetRepeatedEnum(number, index, value);
  }
  static inline void Add(int number, FieldType field_type,
                         bool is_packed, ConstType value, ExtensionSet* set) {
    GOOGLE_DCHECK(IsValid(value));
    set->AddEnum(number, field_type, is_packed, value, NULL);
  }
};

// -------------------------------------------------------------------
// MessageTypeTraits

// ExtensionSet guarantees that when manipulating extensions with message
// types, the implementation used will be the compiled-in class representing
// that type.  So, we can static_cast down to the exact type we expect.
template <typename Type>
class MessageTypeTraits {
 public:
  typedef const Type& ConstType;
  typedef Type* MutableType;

  static inline ConstType Get(int number, const ExtensionSet& set,
                              ConstType default_value) {
    return static_cast<const Type&>(
        set.GetMessage(number, default_value));
  }
  static inline MutableType Mutable(int number, FieldType field_type,
                                    ExtensionSet* set) {
    return static_cast<Type*>(
      set->MutableMessage(number, field_type, Type::default_instance(), NULL));
  }
  static inline void SetAllocated(int number, FieldType field_type,
                                  MutableType message, ExtensionSet* set) {
    set->SetAllocatedMessage(number, field_type, NULL, message);
  }
  static inline MutableType Release(int number, FieldType field_type,
                                    ExtensionSet* set) {
    return static_cast<Type*>(set->ReleaseMessage(
        number, Type::default_instance()));
  }
};

template <typename Type>
class RepeatedMessageTypeTraits {
 public:
  typedef const Type& ConstType;
  typedef Type* MutableType;

  static inline ConstType Get(int number, const ExtensionSet& set, int index) {
    return static_cast<const Type&>(set.GetRepeatedMessage(number, index));
  }
  static inline MutableType Mutable(int number, int index, ExtensionSet* set) {
    return static_cast<Type*>(set->MutableRepeatedMessage(number, index));
  }
  static inline MutableType Add(int number, FieldType field_type,
                                ExtensionSet* set) {
    return static_cast<Type*>(
        set->AddMessage(number, field_type, Type::default_instance(), NULL));
  }
};

// -------------------------------------------------------------------
// ExtensionIdentifier

// This is the type of actual extension objects.  E.g. if you have:
//   extends Foo with optional int32 bar = 1234;
// then "bar" will be defined in C++ as:
//   ExtensionIdentifier<Foo, PrimitiveTypeTraits<int32>, 1, false> bar(1234);
//
// Note that we could, in theory, supply the field number as a template
// parameter, and thus make an instance of ExtensionIdentifier have no
// actual contents.  However, if we did that, then using at extension
// identifier would not necessarily cause the compiler to output any sort
// of reference to any simple defined in the extension's .pb.o file.  Some
// linkers will actually drop object files that are not explicitly referenced,
// but that would be bad because it would cause this extension to not be
// registered at static initialization, and therefore using it would crash.

template <typename ExtendeeType, typename TypeTraitsType,
          FieldType field_type, bool is_packed>
class ExtensionIdentifier {
 public:
  typedef TypeTraitsType TypeTraits;
  typedef ExtendeeType Extendee;

  ExtensionIdentifier(int number, typename TypeTraits::ConstType default_value)
      : number_(number), default_value_(default_value) {}
  inline int number() const { return number_; }
  typename TypeTraits::ConstType default_value() const {
    return default_value_;
  }

 private:
  const int number_;
  typename TypeTraits::ConstType default_value_;
};

// -------------------------------------------------------------------
// Generated accessors

// This macro should be expanded in the context of a generated type which
// has extensions.
//
// We use "_proto_TypeTraits" as a type name below because "TypeTraits"
// causes problems if the class has a nested message or enum type with that
// name and "_TypeTraits" is technically reserved for the C++ library since
// it starts with an underscore followed by a capital letter.
//
// For similar reason, we use "_field_type" and "_is_packed" as parameter names
// below, so that "field_type" and "is_packed" can be used as field names.
#define GOOGLE_PROTOBUF_EXTENSION_ACCESSORS(CLASSNAME)                        \
  /* Has, Size, Clear */                                                      \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline bool HasExtension(                                                   \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id) const {   \
    return _extensions_.Has(id.number());                                     \
  }                                                                           \
                                                                              \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline void ClearExtension(                                                 \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id) {         \
    _extensions_.ClearExtension(id.number());                                 \
  }                                                                           \
                                                                              \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline int ExtensionSize(                                                   \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id) const {   \
    return _extensions_.ExtensionSize(id.number());                           \
  }                                                                           \
                                                                              \
  /* Singular accessors */                                                    \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline typename _proto_TypeTraits::ConstType GetExtension(                  \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id) const {   \
    return _proto_TypeTraits::Get(id.number(), _extensions_,                  \
                                  id.default_value());                        \
  }                                                                           \
                                                                              \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline typename _proto_TypeTraits::MutableType MutableExtension(            \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id) {         \
    return _proto_TypeTraits::Mutable(id.number(), _field_type,               \
                                      &_extensions_);                         \
  }                                                                           \
                                                                              \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline void SetExtension(                                                   \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id,           \
      typename _proto_TypeTraits::ConstType value) {                          \
    _proto_TypeTraits::Set(id.number(), _field_type, value, &_extensions_);   \
  }                                                                           \
                                                                              \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline void SetAllocatedExtension(                                          \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id,           \
      typename _proto_TypeTraits::MutableType value) {                        \
    _proto_TypeTraits::SetAllocated(id.number(), _field_type,                 \
                                    value, &_extensions_);                    \
  }                                                                           \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline typename _proto_TypeTraits::MutableType ReleaseExtension(            \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id) {         \
    return _proto_TypeTraits::Release(id.number(), _field_type,               \
                                      &_extensions_);                         \
  }                                                                           \
                                                                              \
  /* Repeated accessors */                                                    \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline typename _proto_TypeTraits::ConstType GetExtension(                  \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id,           \
      int index) const {                                                      \
    return _proto_TypeTraits::Get(id.number(), _extensions_, index);          \
  }                                                                           \
                                                                              \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline typename _proto_TypeTraits::MutableType MutableExtension(            \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id,           \
      int index) {                                                            \
    return _proto_TypeTraits::Mutable(id.number(), index, &_extensions_);     \
  }                                                                           \
                                                                              \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline void SetExtension(                                                   \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id,           \
      int index, typename _proto_TypeTraits::ConstType value) {               \
    _proto_TypeTraits::Set(id.number(), index, value, &_extensions_);         \
  }                                                                           \
                                                                              \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline typename _proto_TypeTraits::MutableType AddExtension(                \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id) {         \
    return _proto_TypeTraits::Add(id.number(), _field_type, &_extensions_);   \
  }                                                                           \
                                                                              \
  template <typename _proto_TypeTraits,                                       \
            ::google::protobuf::internal::FieldType _field_type,                        \
            bool _is_packed>                                                  \
  inline void AddExtension(                                                   \
      const ::google::protobuf::internal::ExtensionIdentifier<                          \
        CLASSNAME, _proto_TypeTraits, _field_type, _is_packed>& id,           \
      typename _proto_TypeTraits::ConstType value) {                          \
    _proto_TypeTraits::Add(id.number(), _field_type, _is_packed,              \
                           value, &_extensions_);                             \
  }

}  // namespace internal
}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_EXTENSION_SET_H__

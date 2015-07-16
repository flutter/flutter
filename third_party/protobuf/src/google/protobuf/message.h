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
// Defines Message, the abstract interface implemented by non-lite
// protocol message objects.  Although it's possible to implement this
// interface manually, most users will use the protocol compiler to
// generate implementations.
//
// Example usage:
//
// Say you have a message defined as:
//
//   message Foo {
//     optional string text = 1;
//     repeated int32 numbers = 2;
//   }
//
// Then, if you used the protocol compiler to generate a class from the above
// definition, you could use it like so:
//
//   string data;  // Will store a serialized version of the message.
//
//   {
//     // Create a message and serialize it.
//     Foo foo;
//     foo.set_text("Hello World!");
//     foo.add_numbers(1);
//     foo.add_numbers(5);
//     foo.add_numbers(42);
//
//     foo.SerializeToString(&data);
//   }
//
//   {
//     // Parse the serialized message and check that it contains the
//     // correct data.
//     Foo foo;
//     foo.ParseFromString(data);
//
//     assert(foo.text() == "Hello World!");
//     assert(foo.numbers_size() == 3);
//     assert(foo.numbers(0) == 1);
//     assert(foo.numbers(1) == 5);
//     assert(foo.numbers(2) == 42);
//   }
//
//   {
//     // Same as the last block, but do it dynamically via the Message
//     // reflection interface.
//     Message* foo = new Foo;
//     const Descriptor* descriptor = foo->GetDescriptor();
//
//     // Get the descriptors for the fields we're interested in and verify
//     // their types.
//     const FieldDescriptor* text_field = descriptor->FindFieldByName("text");
//     assert(text_field != NULL);
//     assert(text_field->type() == FieldDescriptor::TYPE_STRING);
//     assert(text_field->label() == FieldDescriptor::LABEL_OPTIONAL);
//     const FieldDescriptor* numbers_field = descriptor->
//                                            FindFieldByName("numbers");
//     assert(numbers_field != NULL);
//     assert(numbers_field->type() == FieldDescriptor::TYPE_INT32);
//     assert(numbers_field->label() == FieldDescriptor::LABEL_REPEATED);
//
//     // Parse the message.
//     foo->ParseFromString(data);
//
//     // Use the reflection interface to examine the contents.
//     const Reflection* reflection = foo->GetReflection();
//     assert(reflection->GetString(foo, text_field) == "Hello World!");
//     assert(reflection->FieldSize(foo, numbers_field) == 3);
//     assert(reflection->GetRepeatedInt32(foo, numbers_field, 0) == 1);
//     assert(reflection->GetRepeatedInt32(foo, numbers_field, 1) == 5);
//     assert(reflection->GetRepeatedInt32(foo, numbers_field, 2) == 42);
//
//     delete foo;
//   }

#ifndef GOOGLE_PROTOBUF_MESSAGE_H__
#define GOOGLE_PROTOBUF_MESSAGE_H__

#include <vector>
#include <string>

#ifdef __DECCXX
// HP C++'s iosfwd doesn't work.
#include <iostream>
#else
#include <iosfwd>
#endif

#include <google/protobuf/message_lite.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/descriptor.h>


namespace google {
namespace protobuf {

// Defined in this file.
class Message;
class Reflection;
class MessageFactory;

// Defined in other files.
class UnknownFieldSet;         // unknown_field_set.h
namespace io {
  class ZeroCopyInputStream;   // zero_copy_stream.h
  class ZeroCopyOutputStream;  // zero_copy_stream.h
  class CodedInputStream;      // coded_stream.h
  class CodedOutputStream;     // coded_stream.h
}


template<typename T>
class RepeatedField;     // repeated_field.h

template<typename T>
class RepeatedPtrField;  // repeated_field.h

// A container to hold message metadata.
struct Metadata {
  const Descriptor* descriptor;
  const Reflection* reflection;
};

// Abstract interface for protocol messages.
//
// See also MessageLite, which contains most every-day operations.  Message
// adds descriptors and reflection on top of that.
//
// The methods of this class that are virtual but not pure-virtual have
// default implementations based on reflection.  Message classes which are
// optimized for speed will want to override these with faster implementations,
// but classes optimized for code size may be happy with keeping them.  See
// the optimize_for option in descriptor.proto.
class LIBPROTOBUF_EXPORT Message : public MessageLite {
 public:
  inline Message() {}
  virtual ~Message();

  // Basic Operations ------------------------------------------------

  // Construct a new instance of the same type.  Ownership is passed to the
  // caller.  (This is also defined in MessageLite, but is defined again here
  // for return-type covariance.)
  virtual Message* New() const = 0;

  // Make this message into a copy of the given message.  The given message
  // must have the same descriptor, but need not necessarily be the same class.
  // By default this is just implemented as "Clear(); MergeFrom(from);".
  virtual void CopyFrom(const Message& from);

  // Merge the fields from the given message into this message.  Singular
  // fields will be overwritten, except for embedded messages which will
  // be merged.  Repeated fields will be concatenated.  The given message
  // must be of the same type as this message (i.e. the exact same class).
  virtual void MergeFrom(const Message& from);

  // Verifies that IsInitialized() returns true.  GOOGLE_CHECK-fails otherwise, with
  // a nice error message.
  void CheckInitialized() const;

  // Slowly build a list of all required fields that are not set.
  // This is much, much slower than IsInitialized() as it is implemented
  // purely via reflection.  Generally, you should not call this unless you
  // have already determined that an error exists by calling IsInitialized().
  void FindInitializationErrors(vector<string>* errors) const;

  // Like FindInitializationErrors, but joins all the strings, delimited by
  // commas, and returns them.
  string InitializationErrorString() const;

  // Clears all unknown fields from this message and all embedded messages.
  // Normally, if unknown tag numbers are encountered when parsing a message,
  // the tag and value are stored in the message's UnknownFieldSet and
  // then written back out when the message is serialized.  This allows servers
  // which simply route messages to other servers to pass through messages
  // that have new field definitions which they don't yet know about.  However,
  // this behavior can have security implications.  To avoid it, call this
  // method after parsing.
  //
  // See Reflection::GetUnknownFields() for more on unknown fields.
  virtual void DiscardUnknownFields();

  // Computes (an estimate of) the total number of bytes currently used for
  // storing the message in memory.  The default implementation calls the
  // Reflection object's SpaceUsed() method.
  virtual int SpaceUsed() const;

  // Debugging & Testing----------------------------------------------

  // Generates a human readable form of this message, useful for debugging
  // and other purposes.
  string DebugString() const;
  // Like DebugString(), but with less whitespace.
  string ShortDebugString() const;
  // Like DebugString(), but do not escape UTF-8 byte sequences.
  string Utf8DebugString() const;
  // Convenience function useful in GDB.  Prints DebugString() to stdout.
  void PrintDebugString() const;

  // Heavy I/O -------------------------------------------------------
  // Additional parsing and serialization methods not implemented by
  // MessageLite because they are not supported by the lite library.

  // Parse a protocol buffer from a file descriptor.  If successful, the entire
  // input will be consumed.
  bool ParseFromFileDescriptor(int file_descriptor);
  // Like ParseFromFileDescriptor(), but accepts messages that are missing
  // required fields.
  bool ParsePartialFromFileDescriptor(int file_descriptor);
  // Parse a protocol buffer from a C++ istream.  If successful, the entire
  // input will be consumed.
  bool ParseFromIstream(istream* input);
  // Like ParseFromIstream(), but accepts messages that are missing
  // required fields.
  bool ParsePartialFromIstream(istream* input);

  // Serialize the message and write it to the given file descriptor.  All
  // required fields must be set.
  bool SerializeToFileDescriptor(int file_descriptor) const;
  // Like SerializeToFileDescriptor(), but allows missing required fields.
  bool SerializePartialToFileDescriptor(int file_descriptor) const;
  // Serialize the message and write it to the given C++ ostream.  All
  // required fields must be set.
  bool SerializeToOstream(ostream* output) const;
  // Like SerializeToOstream(), but allows missing required fields.
  bool SerializePartialToOstream(ostream* output) const;


  // Reflection-based methods ----------------------------------------
  // These methods are pure-virtual in MessageLite, but Message provides
  // reflection-based default implementations.

  virtual string GetTypeName() const;
  virtual void Clear();
  virtual bool IsInitialized() const;
  virtual void CheckTypeAndMergeFrom(const MessageLite& other);
  virtual bool MergePartialFromCodedStream(io::CodedInputStream* input);
  virtual int ByteSize() const;
  virtual void SerializeWithCachedSizes(io::CodedOutputStream* output) const;

 private:
  // This is called only by the default implementation of ByteSize(), to
  // update the cached size.  If you override ByteSize(), you do not need
  // to override this.  If you do not override ByteSize(), you MUST override
  // this; the default implementation will crash.
  //
  // The method is private because subclasses should never call it; only
  // override it.  Yes, C++ lets you do that.  Crazy, huh?
  virtual void SetCachedSize(int size) const;

 public:

  // Introspection ---------------------------------------------------

  // Typedef for backwards-compatibility.
  typedef google::protobuf::Reflection Reflection;

  // Get a Descriptor for this message's type.  This describes what
  // fields the message contains, the types of those fields, etc.
  const Descriptor* GetDescriptor() const { return GetMetadata().descriptor; }

  // Get the Reflection interface for this Message, which can be used to
  // read and modify the fields of the Message dynamically (in other words,
  // without knowing the message type at compile time).  This object remains
  // property of the Message.
  //
  // This method remains virtual in case a subclass does not implement
  // reflection and wants to override the default behavior.
  virtual const Reflection* GetReflection() const {
    return GetMetadata().reflection;
  }

 protected:
  // Get a struct containing the metadata for the Message. Most subclasses only
  // need to implement this method, rather than the GetDescriptor() and
  // GetReflection() wrappers.
  virtual Metadata GetMetadata() const  = 0;


 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(Message);
};

// This interface contains methods that can be used to dynamically access
// and modify the fields of a protocol message.  Their semantics are
// similar to the accessors the protocol compiler generates.
//
// To get the Reflection for a given Message, call Message::GetReflection().
//
// This interface is separate from Message only for efficiency reasons;
// the vast majority of implementations of Message will share the same
// implementation of Reflection (GeneratedMessageReflection,
// defined in generated_message.h), and all Messages of a particular class
// should share the same Reflection object (though you should not rely on
// the latter fact).
//
// There are several ways that these methods can be used incorrectly.  For
// example, any of the following conditions will lead to undefined
// results (probably assertion failures):
// - The FieldDescriptor is not a field of this message type.
// - The method called is not appropriate for the field's type.  For
//   each field type in FieldDescriptor::TYPE_*, there is only one
//   Get*() method, one Set*() method, and one Add*() method that is
//   valid for that type.  It should be obvious which (except maybe
//   for TYPE_BYTES, which are represented using strings in C++).
// - A Get*() or Set*() method for singular fields is called on a repeated
//   field.
// - GetRepeated*(), SetRepeated*(), or Add*() is called on a non-repeated
//   field.
// - The Message object passed to any method is not of the right type for
//   this Reflection object (i.e. message.GetReflection() != reflection).
//
// You might wonder why there is not any abstract representation for a field
// of arbitrary type.  E.g., why isn't there just a "GetField()" method that
// returns "const Field&", where "Field" is some class with accessors like
// "GetInt32Value()".  The problem is that someone would have to deal with
// allocating these Field objects.  For generated message classes, having to
// allocate space for an additional object to wrap every field would at least
// double the message's memory footprint, probably worse.  Allocating the
// objects on-demand, on the other hand, would be expensive and prone to
// memory leaks.  So, instead we ended up with this flat interface.
//
// TODO(kenton):  Create a utility class which callers can use to read and
//   write fields from a Reflection without paying attention to the type.
class LIBPROTOBUF_EXPORT Reflection {
 public:
  inline Reflection() {}
  virtual ~Reflection();

  // Get the UnknownFieldSet for the message.  This contains fields which
  // were seen when the Message was parsed but were not recognized according
  // to the Message's definition.
  virtual const UnknownFieldSet& GetUnknownFields(
      const Message& message) const = 0;
  // Get a mutable pointer to the UnknownFieldSet for the message.  This
  // contains fields which were seen when the Message was parsed but were not
  // recognized according to the Message's definition.
  virtual UnknownFieldSet* MutableUnknownFields(Message* message) const = 0;

  // Estimate the amount of memory used by the message object.
  virtual int SpaceUsed(const Message& message) const = 0;

  // Check if the given non-repeated field is set.
  virtual bool HasField(const Message& message,
                        const FieldDescriptor* field) const = 0;

  // Get the number of elements of a repeated field.
  virtual int FieldSize(const Message& message,
                        const FieldDescriptor* field) const = 0;

  // Clear the value of a field, so that HasField() returns false or
  // FieldSize() returns zero.
  virtual void ClearField(Message* message,
                          const FieldDescriptor* field) const = 0;

  // Removes the last element of a repeated field.
  // We don't provide a way to remove any element other than the last
  // because it invites inefficient use, such as O(n^2) filtering loops
  // that should have been O(n).  If you want to remove an element other
  // than the last, the best way to do it is to re-arrange the elements
  // (using Swap()) so that the one you want removed is at the end, then
  // call RemoveLast().
  virtual void RemoveLast(Message* message,
                          const FieldDescriptor* field) const = 0;
  // Removes the last element of a repeated message field, and returns the
  // pointer to the caller.  Caller takes ownership of the returned pointer.
  virtual Message* ReleaseLast(Message* message,
                               const FieldDescriptor* field) const = 0;

  // Swap the complete contents of two messages.
  virtual void Swap(Message* message1, Message* message2) const = 0;

  // Swap two elements of a repeated field.
  virtual void SwapElements(Message* message,
                    const FieldDescriptor* field,
                    int index1,
                    int index2) const = 0;

  // List all fields of the message which are currently set.  This includes
  // extensions.  Singular fields will only be listed if HasField(field) would
  // return true and repeated fields will only be listed if FieldSize(field)
  // would return non-zero.  Fields (both normal fields and extension fields)
  // will be listed ordered by field number.
  virtual void ListFields(const Message& message,
                          vector<const FieldDescriptor*>* output) const = 0;

  // Singular field getters ------------------------------------------
  // These get the value of a non-repeated field.  They return the default
  // value for fields that aren't set.

  virtual int32  GetInt32 (const Message& message,
                           const FieldDescriptor* field) const = 0;
  virtual int64  GetInt64 (const Message& message,
                           const FieldDescriptor* field) const = 0;
  virtual uint32 GetUInt32(const Message& message,
                           const FieldDescriptor* field) const = 0;
  virtual uint64 GetUInt64(const Message& message,
                           const FieldDescriptor* field) const = 0;
  virtual float  GetFloat (const Message& message,
                           const FieldDescriptor* field) const = 0;
  virtual double GetDouble(const Message& message,
                           const FieldDescriptor* field) const = 0;
  virtual bool   GetBool  (const Message& message,
                           const FieldDescriptor* field) const = 0;
  virtual string GetString(const Message& message,
                           const FieldDescriptor* field) const = 0;
  virtual const EnumValueDescriptor* GetEnum(
      const Message& message, const FieldDescriptor* field) const = 0;
  // See MutableMessage() for the meaning of the "factory" parameter.
  virtual const Message& GetMessage(const Message& message,
                                    const FieldDescriptor* field,
                                    MessageFactory* factory = NULL) const = 0;

  // Get a string value without copying, if possible.
  //
  // GetString() necessarily returns a copy of the string.  This can be
  // inefficient when the string is already stored in a string object in the
  // underlying message.  GetStringReference() will return a reference to the
  // underlying string in this case.  Otherwise, it will copy the string into
  // *scratch and return that.
  //
  // Note:  It is perfectly reasonable and useful to write code like:
  //     str = reflection->GetStringReference(field, &str);
  //   This line would ensure that only one copy of the string is made
  //   regardless of the field's underlying representation.  When initializing
  //   a newly-constructed string, though, it's just as fast and more readable
  //   to use code like:
  //     string str = reflection->GetString(field);
  virtual const string& GetStringReference(const Message& message,
                                           const FieldDescriptor* field,
                                           string* scratch) const = 0;


  // Singular field mutators -----------------------------------------
  // These mutate the value of a non-repeated field.

  virtual void SetInt32 (Message* message,
                         const FieldDescriptor* field, int32  value) const = 0;
  virtual void SetInt64 (Message* message,
                         const FieldDescriptor* field, int64  value) const = 0;
  virtual void SetUInt32(Message* message,
                         const FieldDescriptor* field, uint32 value) const = 0;
  virtual void SetUInt64(Message* message,
                         const FieldDescriptor* field, uint64 value) const = 0;
  virtual void SetFloat (Message* message,
                         const FieldDescriptor* field, float  value) const = 0;
  virtual void SetDouble(Message* message,
                         const FieldDescriptor* field, double value) const = 0;
  virtual void SetBool  (Message* message,
                         const FieldDescriptor* field, bool   value) const = 0;
  virtual void SetString(Message* message,
                         const FieldDescriptor* field,
                         const string& value) const = 0;
  virtual void SetEnum  (Message* message,
                         const FieldDescriptor* field,
                         const EnumValueDescriptor* value) const = 0;
  // Get a mutable pointer to a field with a message type.  If a MessageFactory
  // is provided, it will be used to construct instances of the sub-message;
  // otherwise, the default factory is used.  If the field is an extension that
  // does not live in the same pool as the containing message's descriptor (e.g.
  // it lives in an overlay pool), then a MessageFactory must be provided.
  // If you have no idea what that meant, then you probably don't need to worry
  // about it (don't provide a MessageFactory).  WARNING:  If the
  // FieldDescriptor is for a compiled-in extension, then
  // factory->GetPrototype(field->message_type() MUST return an instance of the
  // compiled-in class for this type, NOT DynamicMessage.
  virtual Message* MutableMessage(Message* message,
                                  const FieldDescriptor* field,
                                  MessageFactory* factory = NULL) const = 0;
  // Releases the message specified by 'field' and returns the pointer,
  // ReleaseMessage() will return the message the message object if it exists.
  // Otherwise, it may or may not return NULL.  In any case, if the return value
  // is non-NULL, the caller takes ownership of the pointer.
  // If the field existed (HasField() is true), then the returned pointer will
  // be the same as the pointer returned by MutableMessage().
  // This function has the same effect as ClearField().
  virtual Message* ReleaseMessage(Message* message,
                                  const FieldDescriptor* field,
                                  MessageFactory* factory = NULL) const = 0;


  // Repeated field getters ------------------------------------------
  // These get the value of one element of a repeated field.

  virtual int32  GetRepeatedInt32 (const Message& message,
                                   const FieldDescriptor* field,
                                   int index) const = 0;
  virtual int64  GetRepeatedInt64 (const Message& message,
                                   const FieldDescriptor* field,
                                   int index) const = 0;
  virtual uint32 GetRepeatedUInt32(const Message& message,
                                   const FieldDescriptor* field,
                                   int index) const = 0;
  virtual uint64 GetRepeatedUInt64(const Message& message,
                                   const FieldDescriptor* field,
                                   int index) const = 0;
  virtual float  GetRepeatedFloat (const Message& message,
                                   const FieldDescriptor* field,
                                   int index) const = 0;
  virtual double GetRepeatedDouble(const Message& message,
                                   const FieldDescriptor* field,
                                   int index) const = 0;
  virtual bool   GetRepeatedBool  (const Message& message,
                                   const FieldDescriptor* field,
                                   int index) const = 0;
  virtual string GetRepeatedString(const Message& message,
                                   const FieldDescriptor* field,
                                   int index) const = 0;
  virtual const EnumValueDescriptor* GetRepeatedEnum(
      const Message& message,
      const FieldDescriptor* field, int index) const = 0;
  virtual const Message& GetRepeatedMessage(
      const Message& message,
      const FieldDescriptor* field, int index) const = 0;

  // See GetStringReference(), above.
  virtual const string& GetRepeatedStringReference(
      const Message& message, const FieldDescriptor* field,
      int index, string* scratch) const = 0;


  // Repeated field mutators -----------------------------------------
  // These mutate the value of one element of a repeated field.

  virtual void SetRepeatedInt32 (Message* message,
                                 const FieldDescriptor* field,
                                 int index, int32  value) const = 0;
  virtual void SetRepeatedInt64 (Message* message,
                                 const FieldDescriptor* field,
                                 int index, int64  value) const = 0;
  virtual void SetRepeatedUInt32(Message* message,
                                 const FieldDescriptor* field,
                                 int index, uint32 value) const = 0;
  virtual void SetRepeatedUInt64(Message* message,
                                 const FieldDescriptor* field,
                                 int index, uint64 value) const = 0;
  virtual void SetRepeatedFloat (Message* message,
                                 const FieldDescriptor* field,
                                 int index, float  value) const = 0;
  virtual void SetRepeatedDouble(Message* message,
                                 const FieldDescriptor* field,
                                 int index, double value) const = 0;
  virtual void SetRepeatedBool  (Message* message,
                                 const FieldDescriptor* field,
                                 int index, bool   value) const = 0;
  virtual void SetRepeatedString(Message* message,
                                 const FieldDescriptor* field,
                                 int index, const string& value) const = 0;
  virtual void SetRepeatedEnum(Message* message,
                               const FieldDescriptor* field, int index,
                               const EnumValueDescriptor* value) const = 0;
  // Get a mutable pointer to an element of a repeated field with a message
  // type.
  virtual Message* MutableRepeatedMessage(
      Message* message, const FieldDescriptor* field, int index) const = 0;


  // Repeated field adders -------------------------------------------
  // These add an element to a repeated field.

  virtual void AddInt32 (Message* message,
                         const FieldDescriptor* field, int32  value) const = 0;
  virtual void AddInt64 (Message* message,
                         const FieldDescriptor* field, int64  value) const = 0;
  virtual void AddUInt32(Message* message,
                         const FieldDescriptor* field, uint32 value) const = 0;
  virtual void AddUInt64(Message* message,
                         const FieldDescriptor* field, uint64 value) const = 0;
  virtual void AddFloat (Message* message,
                         const FieldDescriptor* field, float  value) const = 0;
  virtual void AddDouble(Message* message,
                         const FieldDescriptor* field, double value) const = 0;
  virtual void AddBool  (Message* message,
                         const FieldDescriptor* field, bool   value) const = 0;
  virtual void AddString(Message* message,
                         const FieldDescriptor* field,
                         const string& value) const = 0;
  virtual void AddEnum  (Message* message,
                         const FieldDescriptor* field,
                         const EnumValueDescriptor* value) const = 0;
  // See MutableMessage() for comments on the "factory" parameter.
  virtual Message* AddMessage(Message* message,
                              const FieldDescriptor* field,
                              MessageFactory* factory = NULL) const = 0;


  // Repeated field accessors  -------------------------------------------------
  // The methods above, e.g. GetRepeatedInt32(msg, fd, index), provide singular
  // access to the data in a RepeatedField.  The methods below provide aggregate
  // access by exposing the RepeatedField object itself with the Message.
  // Applying these templates to inappropriate types will lead to an undefined
  // reference at link time (e.g. GetRepeatedField<***double>), or possibly a
  // template matching error at compile time (e.g. GetRepeatedPtrField<File>).
  //
  // Usage example: my_doubs = refl->GetRepeatedField<double>(msg, fd);

  // for T = Cord and all protobuf scalar types except enums.
  template<typename T>
  const RepeatedField<T>& GetRepeatedField(
      const Message&, const FieldDescriptor*) const;

  // for T = Cord and all protobuf scalar types except enums.
  template<typename T>
  RepeatedField<T>* MutableRepeatedField(
      Message*, const FieldDescriptor*) const;

  // for T = string, google::protobuf::internal::StringPieceField
  //         google::protobuf::Message & descendants.
  template<typename T>
  const RepeatedPtrField<T>& GetRepeatedPtrField(
      const Message&, const FieldDescriptor*) const;

  // for T = string, google::protobuf::internal::StringPieceField
  //         google::protobuf::Message & descendants.
  template<typename T>
  RepeatedPtrField<T>* MutableRepeatedPtrField(
      Message*, const FieldDescriptor*) const;

  // Extensions ----------------------------------------------------------------

  // Try to find an extension of this message type by fully-qualified field
  // name.  Returns NULL if no extension is known for this name or number.
  virtual const FieldDescriptor* FindKnownExtensionByName(
      const string& name) const = 0;

  // Try to find an extension of this message type by field number.
  // Returns NULL if no extension is known for this name or number.
  virtual const FieldDescriptor* FindKnownExtensionByNumber(
      int number) const = 0;

  // ---------------------------------------------------------------------------

 protected:
  // Obtain a pointer to a Repeated Field Structure and do some type checking:
  //   on field->cpp_type(),
  //   on field->field_option().ctype() (if ctype >= 0)
  //   of field->message_type() (if message_type != NULL).
  // We use 1 routine rather than 4 (const vs mutable) x (scalar vs pointer).
  virtual void* MutableRawRepeatedField(
      Message* message, const FieldDescriptor* field, FieldDescriptor::CppType,
      int ctype, const Descriptor* message_type) const = 0;

 private:
  // Special version for specialized implementations of string.  We can't call
  // MutableRawRepeatedField directly here because we don't have access to
  // FieldOptions::* which are defined in descriptor.pb.h.  Including that
  // file here is not possible because it would cause a circular include cycle.
  void* MutableRawRepeatedString(
      Message* message, const FieldDescriptor* field, bool is_string) const;

  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(Reflection);
};

// Abstract interface for a factory for message objects.
class LIBPROTOBUF_EXPORT MessageFactory {
 public:
  inline MessageFactory() {}
  virtual ~MessageFactory();

  // Given a Descriptor, gets or constructs the default (prototype) Message
  // of that type.  You can then call that message's New() method to construct
  // a mutable message of that type.
  //
  // Calling this method twice with the same Descriptor returns the same
  // object.  The returned object remains property of the factory.  Also, any
  // objects created by calling the prototype's New() method share some data
  // with the prototype, so these must be destoyed before the MessageFactory
  // is destroyed.
  //
  // The given descriptor must outlive the returned message, and hence must
  // outlive the MessageFactory.
  //
  // Some implementations do not support all types.  GetPrototype() will
  // return NULL if the descriptor passed in is not supported.
  //
  // This method may or may not be thread-safe depending on the implementation.
  // Each implementation should document its own degree thread-safety.
  virtual const Message* GetPrototype(const Descriptor* type) = 0;

  // Gets a MessageFactory which supports all generated, compiled-in messages.
  // In other words, for any compiled-in type FooMessage, the following is true:
  //   MessageFactory::generated_factory()->GetPrototype(
  //     FooMessage::descriptor()) == FooMessage::default_instance()
  // This factory supports all types which are found in
  // DescriptorPool::generated_pool().  If given a descriptor from any other
  // pool, GetPrototype() will return NULL.  (You can also check if a
  // descriptor is for a generated message by checking if
  // descriptor->file()->pool() == DescriptorPool::generated_pool().)
  //
  // This factory is 100% thread-safe; calling GetPrototype() does not modify
  // any shared data.
  //
  // This factory is a singleton.  The caller must not delete the object.
  static MessageFactory* generated_factory();

  // For internal use only:  Registers a .proto file at static initialization
  // time, to be placed in generated_factory.  The first time GetPrototype()
  // is called with a descriptor from this file, |register_messages| will be
  // called, with the file name as the parameter.  It must call
  // InternalRegisterGeneratedMessage() (below) to register each message type
  // in the file.  This strange mechanism is necessary because descriptors are
  // built lazily, so we can't register types by their descriptor until we
  // know that the descriptor exists.  |filename| must be a permanent string.
  static void InternalRegisterGeneratedFile(
      const char* filename, void (*register_messages)(const string&));

  // For internal use only:  Registers a message type.  Called only by the
  // functions which are registered with InternalRegisterGeneratedFile(),
  // above.
  static void InternalRegisterGeneratedMessage(const Descriptor* descriptor,
                                               const Message* prototype);


 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(MessageFactory);
};

#define DECLARE_GET_REPEATED_FIELD(TYPE)                         \
template<>                                                       \
LIBPROTOBUF_EXPORT                                               \
const RepeatedField<TYPE>& Reflection::GetRepeatedField<TYPE>(   \
    const Message& message, const FieldDescriptor* field) const; \
                                                                 \
template<>                                                       \
LIBPROTOBUF_EXPORT                                               \
RepeatedField<TYPE>* Reflection::MutableRepeatedField<TYPE>(     \
    Message* message, const FieldDescriptor* field) const;

DECLARE_GET_REPEATED_FIELD(int32)
DECLARE_GET_REPEATED_FIELD(int64)
DECLARE_GET_REPEATED_FIELD(uint32)
DECLARE_GET_REPEATED_FIELD(uint64)
DECLARE_GET_REPEATED_FIELD(float)
DECLARE_GET_REPEATED_FIELD(double)
DECLARE_GET_REPEATED_FIELD(bool)

#undef DECLARE_GET_REPEATED_FIELD

// =============================================================================
// Implementation details for {Get,Mutable}RawRepeatedPtrField.  We provide
// specializations for <string>, <StringPieceField> and <Message> and handle
// everything else with the default template which will match any type having
// a method with signature "static const google::protobuf::Descriptor* descriptor()".
// Such a type presumably is a descendant of google::protobuf::Message.

template<>
inline const RepeatedPtrField<string>& Reflection::GetRepeatedPtrField<string>(
    const Message& message, const FieldDescriptor* field) const {
  return *static_cast<RepeatedPtrField<string>* >(
      MutableRawRepeatedString(const_cast<Message*>(&message), field, true));
}

template<>
inline RepeatedPtrField<string>* Reflection::MutableRepeatedPtrField<string>(
    Message* message, const FieldDescriptor* field) const {
  return static_cast<RepeatedPtrField<string>* >(
      MutableRawRepeatedString(message, field, true));
}


// -----

template<>
inline const RepeatedPtrField<Message>& Reflection::GetRepeatedPtrField(
    const Message& message, const FieldDescriptor* field) const {
  return *static_cast<RepeatedPtrField<Message>* >(
      MutableRawRepeatedField(const_cast<Message*>(&message), field,
          FieldDescriptor::CPPTYPE_MESSAGE, -1,
          NULL));
}

template<>
inline RepeatedPtrField<Message>* Reflection::MutableRepeatedPtrField(
    Message* message, const FieldDescriptor* field) const {
  return static_cast<RepeatedPtrField<Message>* >(
      MutableRawRepeatedField(message, field,
          FieldDescriptor::CPPTYPE_MESSAGE, -1,
          NULL));
}

template<typename PB>
inline const RepeatedPtrField<PB>& Reflection::GetRepeatedPtrField(
    const Message& message, const FieldDescriptor* field) const {
  return *static_cast<RepeatedPtrField<PB>* >(
      MutableRawRepeatedField(const_cast<Message*>(&message), field,
          FieldDescriptor::CPPTYPE_MESSAGE, -1,
          PB::default_instance().GetDescriptor()));
}

template<typename PB>
inline RepeatedPtrField<PB>* Reflection::MutableRepeatedPtrField(
    Message* message, const FieldDescriptor* field) const {
  return static_cast<RepeatedPtrField<PB>* >(
      MutableRawRepeatedField(message, field,
          FieldDescriptor::CPPTYPE_MESSAGE, -1,
          PB::default_instance().GetDescriptor()));
}

}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_MESSAGE_H__

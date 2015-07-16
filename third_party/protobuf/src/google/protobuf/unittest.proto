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
// A proto file we will use for unit testing.


// Some generic_services option(s) added automatically.
// See:  http://go/proto2-generic-services-default
option cc_generic_services = true;     // auto-added
option java_generic_services = true;   // auto-added
option py_generic_services = true;     // auto-added

import "google/protobuf/unittest_import.proto";

// We don't put this in a package within proto2 because we need to make sure
// that the generated code doesn't depend on being in the proto2 namespace.
// In test_util.h we do "using namespace unittest = protobuf_unittest".
package protobuf_unittest;

// Protos optimized for SPEED use a strict superset of the generated code
// of equivalent ones optimized for CODE_SIZE, so we should optimize all our
// tests for speed unless explicitly testing code size optimization.
option optimize_for = SPEED;

option java_outer_classname = "UnittestProto";

// This proto includes every type of field in both singular and repeated
// forms.
message TestAllTypes {
  message NestedMessage {
    // The field name "b" fails to compile in proto1 because it conflicts with
    // a local variable named "b" in one of the generated methods.  Doh.
    // This file needs to compile in proto1 to test backwards-compatibility.
    optional int32 bb = 1;
  }

  enum NestedEnum {
    FOO = 1;
    BAR = 2;
    BAZ = 3;
  }

  // Singular
  optional    int32 optional_int32    =  1;
  optional    int64 optional_int64    =  2;
  optional   uint32 optional_uint32   =  3;
  optional   uint64 optional_uint64   =  4;
  optional   sint32 optional_sint32   =  5;
  optional   sint64 optional_sint64   =  6;
  optional  fixed32 optional_fixed32  =  7;
  optional  fixed64 optional_fixed64  =  8;
  optional sfixed32 optional_sfixed32 =  9;
  optional sfixed64 optional_sfixed64 = 10;
  optional    float optional_float    = 11;
  optional   double optional_double   = 12;
  optional     bool optional_bool     = 13;
  optional   string optional_string   = 14;
  optional    bytes optional_bytes    = 15;

  optional group OptionalGroup = 16 {
    optional int32 a = 17;
  }

  optional NestedMessage                        optional_nested_message  = 18;
  optional ForeignMessage                       optional_foreign_message = 19;
  optional protobuf_unittest_import.ImportMessage optional_import_message  = 20;

  optional NestedEnum                           optional_nested_enum     = 21;
  optional ForeignEnum                          optional_foreign_enum    = 22;
  optional protobuf_unittest_import.ImportEnum    optional_import_enum     = 23;

  optional string optional_string_piece = 24 [ctype=STRING_PIECE];
  optional string optional_cord = 25 [ctype=CORD];

  // Defined in unittest_import_public.proto
  optional protobuf_unittest_import.PublicImportMessage
      optional_public_import_message = 26;

  optional NestedMessage optional_lazy_message = 27 [lazy=true];

  // Repeated
  repeated    int32 repeated_int32    = 31;
  repeated    int64 repeated_int64    = 32;
  repeated   uint32 repeated_uint32   = 33;
  repeated   uint64 repeated_uint64   = 34;
  repeated   sint32 repeated_sint32   = 35;
  repeated   sint64 repeated_sint64   = 36;
  repeated  fixed32 repeated_fixed32  = 37;
  repeated  fixed64 repeated_fixed64  = 38;
  repeated sfixed32 repeated_sfixed32 = 39;
  repeated sfixed64 repeated_sfixed64 = 40;
  repeated    float repeated_float    = 41;
  repeated   double repeated_double   = 42;
  repeated     bool repeated_bool     = 43;
  repeated   string repeated_string   = 44;
  repeated    bytes repeated_bytes    = 45;

  repeated group RepeatedGroup = 46 {
    optional int32 a = 47;
  }

  repeated NestedMessage                        repeated_nested_message  = 48;
  repeated ForeignMessage                       repeated_foreign_message = 49;
  repeated protobuf_unittest_import.ImportMessage repeated_import_message  = 50;

  repeated NestedEnum                           repeated_nested_enum     = 51;
  repeated ForeignEnum                          repeated_foreign_enum    = 52;
  repeated protobuf_unittest_import.ImportEnum    repeated_import_enum     = 53;

  repeated string repeated_string_piece = 54 [ctype=STRING_PIECE];
  repeated string repeated_cord = 55 [ctype=CORD];

  repeated NestedMessage repeated_lazy_message = 57 [lazy=true];

  // Singular with defaults
  optional    int32 default_int32    = 61 [default =  41    ];
  optional    int64 default_int64    = 62 [default =  42    ];
  optional   uint32 default_uint32   = 63 [default =  43    ];
  optional   uint64 default_uint64   = 64 [default =  44    ];
  optional   sint32 default_sint32   = 65 [default = -45    ];
  optional   sint64 default_sint64   = 66 [default =  46    ];
  optional  fixed32 default_fixed32  = 67 [default =  47    ];
  optional  fixed64 default_fixed64  = 68 [default =  48    ];
  optional sfixed32 default_sfixed32 = 69 [default =  49    ];
  optional sfixed64 default_sfixed64 = 70 [default = -50    ];
  optional    float default_float    = 71 [default =  51.5  ];
  optional   double default_double   = 72 [default =  52e3  ];
  optional     bool default_bool     = 73 [default = true   ];
  optional   string default_string   = 74 [default = "hello"];
  optional    bytes default_bytes    = 75 [default = "world"];

  optional NestedEnum  default_nested_enum  = 81 [default = BAR        ];
  optional ForeignEnum default_foreign_enum = 82 [default = FOREIGN_BAR];
  optional protobuf_unittest_import.ImportEnum
      default_import_enum = 83 [default = IMPORT_BAR];

  optional string default_string_piece = 84 [ctype=STRING_PIECE,default="abc"];
  optional string default_cord = 85 [ctype=CORD,default="123"];
}

message TestDeprecatedFields {
  optional int32 deprecated_int32 = 1 [deprecated=true];
}

// Define these after TestAllTypes to make sure the compiler can handle
// that.
message ForeignMessage {
  optional int32 c = 1;
}

enum ForeignEnum {
  FOREIGN_FOO = 4;
  FOREIGN_BAR = 5;
  FOREIGN_BAZ = 6;
}

message TestAllExtensions {
  extensions 1 to max;
}

extend TestAllExtensions {
  // Singular
  optional    int32 optional_int32_extension    =  1;
  optional    int64 optional_int64_extension    =  2;
  optional   uint32 optional_uint32_extension   =  3;
  optional   uint64 optional_uint64_extension   =  4;
  optional   sint32 optional_sint32_extension   =  5;
  optional   sint64 optional_sint64_extension   =  6;
  optional  fixed32 optional_fixed32_extension  =  7;
  optional  fixed64 optional_fixed64_extension  =  8;
  optional sfixed32 optional_sfixed32_extension =  9;
  optional sfixed64 optional_sfixed64_extension = 10;
  optional    float optional_float_extension    = 11;
  optional   double optional_double_extension   = 12;
  optional     bool optional_bool_extension     = 13;
  optional   string optional_string_extension   = 14;
  optional    bytes optional_bytes_extension    = 15;

  optional group OptionalGroup_extension = 16 {
    optional int32 a = 17;
  }

  optional TestAllTypes.NestedMessage optional_nested_message_extension = 18;
  optional ForeignMessage optional_foreign_message_extension = 19;
  optional protobuf_unittest_import.ImportMessage
    optional_import_message_extension = 20;

  optional TestAllTypes.NestedEnum optional_nested_enum_extension = 21;
  optional ForeignEnum optional_foreign_enum_extension = 22;
  optional protobuf_unittest_import.ImportEnum
    optional_import_enum_extension = 23;

  optional string optional_string_piece_extension = 24 [ctype=STRING_PIECE];
  optional string optional_cord_extension = 25 [ctype=CORD];

  optional protobuf_unittest_import.PublicImportMessage
    optional_public_import_message_extension = 26;

  optional TestAllTypes.NestedMessage
    optional_lazy_message_extension = 27 [lazy=true];

  // Repeated
  repeated    int32 repeated_int32_extension    = 31;
  repeated    int64 repeated_int64_extension    = 32;
  repeated   uint32 repeated_uint32_extension   = 33;
  repeated   uint64 repeated_uint64_extension   = 34;
  repeated   sint32 repeated_sint32_extension   = 35;
  repeated   sint64 repeated_sint64_extension   = 36;
  repeated  fixed32 repeated_fixed32_extension  = 37;
  repeated  fixed64 repeated_fixed64_extension  = 38;
  repeated sfixed32 repeated_sfixed32_extension = 39;
  repeated sfixed64 repeated_sfixed64_extension = 40;
  repeated    float repeated_float_extension    = 41;
  repeated   double repeated_double_extension   = 42;
  repeated     bool repeated_bool_extension     = 43;
  repeated   string repeated_string_extension   = 44;
  repeated    bytes repeated_bytes_extension    = 45;

  repeated group RepeatedGroup_extension = 46 {
    optional int32 a = 47;
  }

  repeated TestAllTypes.NestedMessage repeated_nested_message_extension = 48;
  repeated ForeignMessage repeated_foreign_message_extension = 49;
  repeated protobuf_unittest_import.ImportMessage
    repeated_import_message_extension = 50;

  repeated TestAllTypes.NestedEnum repeated_nested_enum_extension = 51;
  repeated ForeignEnum repeated_foreign_enum_extension = 52;
  repeated protobuf_unittest_import.ImportEnum
    repeated_import_enum_extension = 53;

  repeated string repeated_string_piece_extension = 54 [ctype=STRING_PIECE];
  repeated string repeated_cord_extension = 55 [ctype=CORD];

  repeated TestAllTypes.NestedMessage
    repeated_lazy_message_extension = 57 [lazy=true];

  // Singular with defaults
  optional    int32 default_int32_extension    = 61 [default =  41    ];
  optional    int64 default_int64_extension    = 62 [default =  42    ];
  optional   uint32 default_uint32_extension   = 63 [default =  43    ];
  optional   uint64 default_uint64_extension   = 64 [default =  44    ];
  optional   sint32 default_sint32_extension   = 65 [default = -45    ];
  optional   sint64 default_sint64_extension   = 66 [default =  46    ];
  optional  fixed32 default_fixed32_extension  = 67 [default =  47    ];
  optional  fixed64 default_fixed64_extension  = 68 [default =  48    ];
  optional sfixed32 default_sfixed32_extension = 69 [default =  49    ];
  optional sfixed64 default_sfixed64_extension = 70 [default = -50    ];
  optional    float default_float_extension    = 71 [default =  51.5  ];
  optional   double default_double_extension   = 72 [default =  52e3  ];
  optional     bool default_bool_extension     = 73 [default = true   ];
  optional   string default_string_extension   = 74 [default = "hello"];
  optional    bytes default_bytes_extension    = 75 [default = "world"];

  optional TestAllTypes.NestedEnum
    default_nested_enum_extension = 81 [default = BAR];
  optional ForeignEnum
    default_foreign_enum_extension = 82 [default = FOREIGN_BAR];
  optional protobuf_unittest_import.ImportEnum
    default_import_enum_extension = 83 [default = IMPORT_BAR];

  optional string default_string_piece_extension = 84 [ctype=STRING_PIECE,
                                                       default="abc"];
  optional string default_cord_extension = 85 [ctype=CORD, default="123"];
}

message TestNestedExtension {
  extend TestAllExtensions {
    // Check for bug where string extensions declared in tested scope did not
    // compile.
    optional string test = 1002 [default="test"];
  }
}

// We have separate messages for testing required fields because it's
// annoying to have to fill in required fields in TestProto in order to
// do anything with it.  Note that we don't need to test every type of
// required filed because the code output is basically identical to
// optional fields for all types.
message TestRequired {
  required int32 a = 1;
  optional int32 dummy2 = 2;
  required int32 b = 3;

  extend TestAllExtensions {
    optional TestRequired single = 1000;
    repeated TestRequired multi  = 1001;
  }

  // Pad the field count to 32 so that we can test that IsInitialized()
  // properly checks multiple elements of has_bits_.
  optional int32 dummy4  =  4;
  optional int32 dummy5  =  5;
  optional int32 dummy6  =  6;
  optional int32 dummy7  =  7;
  optional int32 dummy8  =  8;
  optional int32 dummy9  =  9;
  optional int32 dummy10 = 10;
  optional int32 dummy11 = 11;
  optional int32 dummy12 = 12;
  optional int32 dummy13 = 13;
  optional int32 dummy14 = 14;
  optional int32 dummy15 = 15;
  optional int32 dummy16 = 16;
  optional int32 dummy17 = 17;
  optional int32 dummy18 = 18;
  optional int32 dummy19 = 19;
  optional int32 dummy20 = 20;
  optional int32 dummy21 = 21;
  optional int32 dummy22 = 22;
  optional int32 dummy23 = 23;
  optional int32 dummy24 = 24;
  optional int32 dummy25 = 25;
  optional int32 dummy26 = 26;
  optional int32 dummy27 = 27;
  optional int32 dummy28 = 28;
  optional int32 dummy29 = 29;
  optional int32 dummy30 = 30;
  optional int32 dummy31 = 31;
  optional int32 dummy32 = 32;

  required int32 c = 33;
}

message TestRequiredForeign {
  optional TestRequired optional_message = 1;
  repeated TestRequired repeated_message = 2;
  optional int32 dummy = 3;
}

// Test that we can use NestedMessage from outside TestAllTypes.
message TestForeignNested {
  optional TestAllTypes.NestedMessage foreign_nested = 1;
}

// TestEmptyMessage is used to test unknown field support.
message TestEmptyMessage {
}

// Like above, but declare all field numbers as potential extensions.  No
// actual extensions should ever be defined for this type.
message TestEmptyMessageWithExtensions {
  extensions 1 to max;
}

message TestMultipleExtensionRanges {
  extensions 42;
  extensions 4143 to 4243;
  extensions 65536 to max;
}

// Test that really large tag numbers don't break anything.
message TestReallyLargeTagNumber {
  // The largest possible tag number is 2^28 - 1, since the wire format uses
  // three bits to communicate wire type.
  optional int32 a = 1;
  optional int32 bb = 268435455;
}

message TestRecursiveMessage {
  optional TestRecursiveMessage a = 1;
  optional int32 i = 2;
}

// Test that mutual recursion works.
message TestMutualRecursionA {
  optional TestMutualRecursionB bb = 1;
}

message TestMutualRecursionB {
  optional TestMutualRecursionA a = 1;
  optional int32 optional_int32 = 2;
}

// Test that groups have disjoint field numbers from their siblings and
// parents.  This is NOT possible in proto1; only proto2.  When attempting
// to compile with proto1, this will emit an error; so we only include it
// in protobuf_unittest_proto.
message TestDupFieldNumber {                        // NO_PROTO1
  optional int32 a = 1;                             // NO_PROTO1
  optional group Foo = 2 { optional int32 a = 1; }  // NO_PROTO1
  optional group Bar = 3 { optional int32 a = 1; }  // NO_PROTO1
}                                                   // NO_PROTO1

// Additional messages for testing lazy fields.
message TestEagerMessage {
  optional TestAllTypes sub_message = 1 [lazy=false];
}
message TestLazyMessage {
  optional TestAllTypes sub_message = 1 [lazy=true];
}

// Needed for a Python test.
message TestNestedMessageHasBits {
  message NestedMessage {
    repeated int32 nestedmessage_repeated_int32 = 1;
    repeated ForeignMessage nestedmessage_repeated_foreignmessage = 2;
  }
  optional NestedMessage optional_nested_message = 1;
}


// Test an enum that has multiple values with the same number.
enum TestEnumWithDupValue {
  option allow_alias = true;
  FOO1 = 1;
  BAR1 = 2;
  BAZ = 3;
  FOO2 = 1;
  BAR2 = 2;
}

// Test an enum with large, unordered values.
enum TestSparseEnum {
  SPARSE_A = 123;
  SPARSE_B = 62374;
  SPARSE_C = 12589234;
  SPARSE_D = -15;
  SPARSE_E = -53452;
  SPARSE_F = 0;
  SPARSE_G = 2;
}

// Test message with CamelCase field names.  This violates Protocol Buffer
// standard style.
message TestCamelCaseFieldNames {
  optional int32 PrimitiveField = 1;
  optional string StringField = 2;
  optional ForeignEnum EnumField = 3;
  optional ForeignMessage MessageField = 4;
  optional string StringPieceField = 5 [ctype=STRING_PIECE];
  optional string CordField = 6 [ctype=CORD];

  repeated int32 RepeatedPrimitiveField = 7;
  repeated string RepeatedStringField = 8;
  repeated ForeignEnum RepeatedEnumField = 9;
  repeated ForeignMessage RepeatedMessageField = 10;
  repeated string RepeatedStringPieceField = 11 [ctype=STRING_PIECE];
  repeated string RepeatedCordField = 12 [ctype=CORD];
}


// We list fields out of order, to ensure that we're using field number and not
// field index to determine serialization order.
message TestFieldOrderings {
  optional string my_string = 11;
  extensions 2 to 10;
  optional int64 my_int = 1;
  extensions 12 to 100;
  optional float my_float = 101;
}


extend TestFieldOrderings {
  optional string my_extension_string = 50;
  optional int32 my_extension_int = 5;
}


message TestExtremeDefaultValues {
  optional bytes escaped_bytes = 1 [default = "\0\001\a\b\f\n\r\t\v\\\'\"\xfe"];
  optional uint32 large_uint32 = 2 [default = 0xFFFFFFFF];
  optional uint64 large_uint64 = 3 [default = 0xFFFFFFFFFFFFFFFF];
  optional  int32 small_int32  = 4 [default = -0x7FFFFFFF];
  optional  int64 small_int64  = 5 [default = -0x7FFFFFFFFFFFFFFF];
  optional  int32 really_small_int32 = 21 [default = -0x80000000];
  optional  int64 really_small_int64 = 22 [default = -0x8000000000000000];

  // The default value here is UTF-8 for "\u1234".  (We could also just type
  // the UTF-8 text directly into this text file rather than escape it, but
  // lots of people use editors that would be confused by this.)
  optional string utf8_string = 6 [default = "\341\210\264"];

  // Tests for single-precision floating-point values.
  optional float zero_float = 7 [default = 0];
  optional float one_float = 8 [default = 1];
  optional float small_float = 9 [default = 1.5];
  optional float negative_one_float = 10 [default = -1];
  optional float negative_float = 11 [default = -1.5];
  // Using exponents
  optional float large_float = 12 [default = 2E8];
  optional float small_negative_float = 13 [default = -8e-28];

  // Text for nonfinite floating-point values.
  optional double inf_double = 14 [default = inf];
  optional double neg_inf_double = 15 [default = -inf];
  optional double nan_double = 16 [default = nan];
  optional float inf_float = 17 [default = inf];
  optional float neg_inf_float = 18 [default = -inf];
  optional float nan_float = 19 [default = nan];

  // Tests for C++ trigraphs.
  // Trigraphs should be escaped in C++ generated files, but they should not be
  // escaped for other languages.
  // Note that in .proto file, "\?" is a valid way to escape ? in string
  // literals.
  optional string cpp_trigraph = 20 [default = "? \? ?? \?? \??? ??/ ?\?-"];

  // String defaults containing the character '\000'
  optional string string_with_zero       = 23 [default = "hel\000lo"];
  optional  bytes bytes_with_zero        = 24 [default = "wor\000ld"];
  optional string string_piece_with_zero = 25 [ctype=STRING_PIECE,
                                               default="ab\000c"];
  optional string cord_with_zero         = 26 [ctype=CORD,
                                               default="12\0003"];
}

message SparseEnumMessage {
  optional TestSparseEnum sparse_enum = 1;
}

// Test String and Bytes: string is for valid UTF-8 strings
message OneString {
  optional string data = 1;
}

message MoreString {
  repeated string data = 1;
}

message OneBytes {
  optional bytes data = 1;
}

message MoreBytes {
  repeated bytes data = 1;
}


// Test messages for packed fields

message TestPackedTypes {
  repeated    int32 packed_int32    =  90 [packed = true];
  repeated    int64 packed_int64    =  91 [packed = true];
  repeated   uint32 packed_uint32   =  92 [packed = true];
  repeated   uint64 packed_uint64   =  93 [packed = true];
  repeated   sint32 packed_sint32   =  94 [packed = true];
  repeated   sint64 packed_sint64   =  95 [packed = true];
  repeated  fixed32 packed_fixed32  =  96 [packed = true];
  repeated  fixed64 packed_fixed64  =  97 [packed = true];
  repeated sfixed32 packed_sfixed32 =  98 [packed = true];
  repeated sfixed64 packed_sfixed64 =  99 [packed = true];
  repeated    float packed_float    = 100 [packed = true];
  repeated   double packed_double   = 101 [packed = true];
  repeated     bool packed_bool     = 102 [packed = true];
  repeated ForeignEnum packed_enum  = 103 [packed = true];
}

// A message with the same fields as TestPackedTypes, but without packing. Used
// to test packed <-> unpacked wire compatibility.
message TestUnpackedTypes {
  repeated    int32 unpacked_int32    =  90 [packed = false];
  repeated    int64 unpacked_int64    =  91 [packed = false];
  repeated   uint32 unpacked_uint32   =  92 [packed = false];
  repeated   uint64 unpacked_uint64   =  93 [packed = false];
  repeated   sint32 unpacked_sint32   =  94 [packed = false];
  repeated   sint64 unpacked_sint64   =  95 [packed = false];
  repeated  fixed32 unpacked_fixed32  =  96 [packed = false];
  repeated  fixed64 unpacked_fixed64  =  97 [packed = false];
  repeated sfixed32 unpacked_sfixed32 =  98 [packed = false];
  repeated sfixed64 unpacked_sfixed64 =  99 [packed = false];
  repeated    float unpacked_float    = 100 [packed = false];
  repeated   double unpacked_double   = 101 [packed = false];
  repeated     bool unpacked_bool     = 102 [packed = false];
  repeated ForeignEnum unpacked_enum  = 103 [packed = false];
}

message TestPackedExtensions {
  extensions 1 to max;
}

extend TestPackedExtensions {
  repeated    int32 packed_int32_extension    =  90 [packed = true];
  repeated    int64 packed_int64_extension    =  91 [packed = true];
  repeated   uint32 packed_uint32_extension   =  92 [packed = true];
  repeated   uint64 packed_uint64_extension   =  93 [packed = true];
  repeated   sint32 packed_sint32_extension   =  94 [packed = true];
  repeated   sint64 packed_sint64_extension   =  95 [packed = true];
  repeated  fixed32 packed_fixed32_extension  =  96 [packed = true];
  repeated  fixed64 packed_fixed64_extension  =  97 [packed = true];
  repeated sfixed32 packed_sfixed32_extension =  98 [packed = true];
  repeated sfixed64 packed_sfixed64_extension =  99 [packed = true];
  repeated    float packed_float_extension    = 100 [packed = true];
  repeated   double packed_double_extension   = 101 [packed = true];
  repeated     bool packed_bool_extension     = 102 [packed = true];
  repeated ForeignEnum packed_enum_extension  = 103 [packed = true];
}

// Used by ExtensionSetTest/DynamicExtensions.  The test actually builds
// a set of extensions to TestAllExtensions dynamically, based on the fields
// of this message type.
message TestDynamicExtensions {
  enum DynamicEnumType {
    DYNAMIC_FOO = 2200;
    DYNAMIC_BAR = 2201;
    DYNAMIC_BAZ = 2202;
  }
  message DynamicMessageType {
    optional int32 dynamic_field = 2100;
  }

  optional fixed32 scalar_extension = 2000;
  optional ForeignEnum enum_extension = 2001;
  optional DynamicEnumType dynamic_enum_extension = 2002;

  optional ForeignMessage message_extension = 2003;
  optional DynamicMessageType dynamic_message_extension = 2004;

  repeated string repeated_extension = 2005;
  repeated sint32 packed_extension = 2006 [packed = true];
}

message TestRepeatedScalarDifferentTagSizes {
  // Parsing repeated fixed size values used to fail. This message needs to be
  // used in order to get a tag of the right size; all of the repeated fields
  // in TestAllTypes didn't trigger the check.
  repeated fixed32 repeated_fixed32 = 12;
  // Check for a varint type, just for good measure.
  repeated int32   repeated_int32   = 13;

  // These have two-byte tags.
  repeated fixed64 repeated_fixed64 = 2046;
  repeated int64   repeated_int64   = 2047;

  // Three byte tags.
  repeated float   repeated_float   = 262142;
  repeated uint64  repeated_uint64  = 262143;
}

// Test that if an optional or required message/group field appears multiple
// times in the input, they need to be merged.
message TestParsingMerge {
  // RepeatedFieldsGenerator defines matching field types as TestParsingMerge,
  // except that all fields are repeated. In the tests, we will serialize the
  // RepeatedFieldsGenerator to bytes, and parse the bytes to TestParsingMerge.
  // Repeated fields in RepeatedFieldsGenerator are expected to be merged into
  // the corresponding required/optional fields in TestParsingMerge.
  message RepeatedFieldsGenerator {
    repeated TestAllTypes field1 = 1;
    repeated TestAllTypes field2 = 2;
    repeated TestAllTypes field3 = 3;
    repeated group Group1 = 10 {
      optional TestAllTypes field1 = 11;
    }
    repeated group Group2 = 20 {
      optional TestAllTypes field1 = 21;
    }
    repeated TestAllTypes ext1 = 1000;
    repeated TestAllTypes ext2 = 1001;
  }
  required TestAllTypes required_all_types = 1;
  optional TestAllTypes optional_all_types = 2;
  repeated TestAllTypes repeated_all_types = 3;
  optional group OptionalGroup = 10 {
    optional TestAllTypes optional_group_all_types = 11;
  }
  repeated group RepeatedGroup = 20 {
    optional TestAllTypes repeated_group_all_types = 21;
  }
  extensions 1000 to max;
  extend TestParsingMerge {
    optional TestAllTypes optional_ext = 1000;
    repeated TestAllTypes repeated_ext = 1001;
  }
}

message TestCommentInjectionMessage {
  // */ <- This should not close the generated doc comment
  optional string a = 1 [default="*/ <- Neither should this."];
}


// Test that RPC services work.
message FooRequest  {}
message FooResponse {}

message FooClientMessage {}
message FooServerMessage{}

service TestService {
  rpc Foo(FooRequest) returns (FooResponse);
  rpc Bar(BarRequest) returns (BarResponse);
}


message BarRequest  {}
message BarResponse {}

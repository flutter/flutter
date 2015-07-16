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

#include <google/protobuf/test_util_lite.h>
#include <google/protobuf/stubs/common.h>


#define EXPECT_TRUE GOOGLE_CHECK
#define ASSERT_TRUE GOOGLE_CHECK
#define EXPECT_FALSE(COND) GOOGLE_CHECK(!(COND))
#define EXPECT_EQ GOOGLE_CHECK_EQ
#define ASSERT_EQ GOOGLE_CHECK_EQ

namespace google {
namespace protobuf {

void TestUtilLite::SetAllFields(unittest::TestAllTypesLite* message) {
  message->set_optional_int32   (101);
  message->set_optional_int64   (102);
  message->set_optional_uint32  (103);
  message->set_optional_uint64  (104);
  message->set_optional_sint32  (105);
  message->set_optional_sint64  (106);
  message->set_optional_fixed32 (107);
  message->set_optional_fixed64 (108);
  message->set_optional_sfixed32(109);
  message->set_optional_sfixed64(110);
  message->set_optional_float   (111);
  message->set_optional_double  (112);
  message->set_optional_bool    (true);
  message->set_optional_string  ("115");
  message->set_optional_bytes   ("116");

  message->mutable_optionalgroup                 ()->set_a(117);
  message->mutable_optional_nested_message       ()->set_bb(118);
  message->mutable_optional_foreign_message      ()->set_c(119);
  message->mutable_optional_import_message       ()->set_d(120);
  message->mutable_optional_public_import_message()->set_e(126);
  message->mutable_optional_lazy_message         ()->set_bb(127);

  message->set_optional_nested_enum (unittest::TestAllTypesLite::BAZ );
  message->set_optional_foreign_enum(unittest::FOREIGN_LITE_BAZ      );
  message->set_optional_import_enum (unittest_import::IMPORT_LITE_BAZ);


  // -----------------------------------------------------------------

  message->add_repeated_int32   (201);
  message->add_repeated_int64   (202);
  message->add_repeated_uint32  (203);
  message->add_repeated_uint64  (204);
  message->add_repeated_sint32  (205);
  message->add_repeated_sint64  (206);
  message->add_repeated_fixed32 (207);
  message->add_repeated_fixed64 (208);
  message->add_repeated_sfixed32(209);
  message->add_repeated_sfixed64(210);
  message->add_repeated_float   (211);
  message->add_repeated_double  (212);
  message->add_repeated_bool    (true);
  message->add_repeated_string  ("215");
  message->add_repeated_bytes   ("216");

  message->add_repeatedgroup           ()->set_a(217);
  message->add_repeated_nested_message ()->set_bb(218);
  message->add_repeated_foreign_message()->set_c(219);
  message->add_repeated_import_message ()->set_d(220);
  message->add_repeated_lazy_message   ()->set_bb(227);

  message->add_repeated_nested_enum (unittest::TestAllTypesLite::BAR );
  message->add_repeated_foreign_enum(unittest::FOREIGN_LITE_BAR      );
  message->add_repeated_import_enum (unittest_import::IMPORT_LITE_BAR);


  // Add a second one of each field.
  message->add_repeated_int32   (301);
  message->add_repeated_int64   (302);
  message->add_repeated_uint32  (303);
  message->add_repeated_uint64  (304);
  message->add_repeated_sint32  (305);
  message->add_repeated_sint64  (306);
  message->add_repeated_fixed32 (307);
  message->add_repeated_fixed64 (308);
  message->add_repeated_sfixed32(309);
  message->add_repeated_sfixed64(310);
  message->add_repeated_float   (311);
  message->add_repeated_double  (312);
  message->add_repeated_bool    (false);
  message->add_repeated_string  ("315");
  message->add_repeated_bytes   ("316");

  message->add_repeatedgroup           ()->set_a(317);
  message->add_repeated_nested_message ()->set_bb(318);
  message->add_repeated_foreign_message()->set_c(319);
  message->add_repeated_import_message ()->set_d(320);
  message->add_repeated_lazy_message   ()->set_bb(327);

  message->add_repeated_nested_enum (unittest::TestAllTypesLite::BAZ );
  message->add_repeated_foreign_enum(unittest::FOREIGN_LITE_BAZ      );
  message->add_repeated_import_enum (unittest_import::IMPORT_LITE_BAZ);


  // -----------------------------------------------------------------

  message->set_default_int32   (401);
  message->set_default_int64   (402);
  message->set_default_uint32  (403);
  message->set_default_uint64  (404);
  message->set_default_sint32  (405);
  message->set_default_sint64  (406);
  message->set_default_fixed32 (407);
  message->set_default_fixed64 (408);
  message->set_default_sfixed32(409);
  message->set_default_sfixed64(410);
  message->set_default_float   (411);
  message->set_default_double  (412);
  message->set_default_bool    (false);
  message->set_default_string  ("415");
  message->set_default_bytes   ("416");

  message->set_default_nested_enum (unittest::TestAllTypesLite::FOO );
  message->set_default_foreign_enum(unittest::FOREIGN_LITE_FOO      );
  message->set_default_import_enum (unittest_import::IMPORT_LITE_FOO);

}

// -------------------------------------------------------------------

void TestUtilLite::ModifyRepeatedFields(unittest::TestAllTypesLite* message) {
  message->set_repeated_int32   (1, 501);
  message->set_repeated_int64   (1, 502);
  message->set_repeated_uint32  (1, 503);
  message->set_repeated_uint64  (1, 504);
  message->set_repeated_sint32  (1, 505);
  message->set_repeated_sint64  (1, 506);
  message->set_repeated_fixed32 (1, 507);
  message->set_repeated_fixed64 (1, 508);
  message->set_repeated_sfixed32(1, 509);
  message->set_repeated_sfixed64(1, 510);
  message->set_repeated_float   (1, 511);
  message->set_repeated_double  (1, 512);
  message->set_repeated_bool    (1, true);
  message->set_repeated_string  (1, "515");
  message->set_repeated_bytes   (1, "516");

  message->mutable_repeatedgroup           (1)->set_a(517);
  message->mutable_repeated_nested_message (1)->set_bb(518);
  message->mutable_repeated_foreign_message(1)->set_c(519);
  message->mutable_repeated_import_message (1)->set_d(520);
  message->mutable_repeated_lazy_message   (1)->set_bb(527);

  message->set_repeated_nested_enum (1, unittest::TestAllTypesLite::FOO );
  message->set_repeated_foreign_enum(1, unittest::FOREIGN_LITE_FOO      );
  message->set_repeated_import_enum (1, unittest_import::IMPORT_LITE_FOO);

}

// -------------------------------------------------------------------

void TestUtilLite::ExpectAllFieldsSet(
    const unittest::TestAllTypesLite& message) {
  EXPECT_TRUE(message.has_optional_int32   ());
  EXPECT_TRUE(message.has_optional_int64   ());
  EXPECT_TRUE(message.has_optional_uint32  ());
  EXPECT_TRUE(message.has_optional_uint64  ());
  EXPECT_TRUE(message.has_optional_sint32  ());
  EXPECT_TRUE(message.has_optional_sint64  ());
  EXPECT_TRUE(message.has_optional_fixed32 ());
  EXPECT_TRUE(message.has_optional_fixed64 ());
  EXPECT_TRUE(message.has_optional_sfixed32());
  EXPECT_TRUE(message.has_optional_sfixed64());
  EXPECT_TRUE(message.has_optional_float   ());
  EXPECT_TRUE(message.has_optional_double  ());
  EXPECT_TRUE(message.has_optional_bool    ());
  EXPECT_TRUE(message.has_optional_string  ());
  EXPECT_TRUE(message.has_optional_bytes   ());

  EXPECT_TRUE(message.has_optionalgroup                 ());
  EXPECT_TRUE(message.has_optional_nested_message       ());
  EXPECT_TRUE(message.has_optional_foreign_message      ());
  EXPECT_TRUE(message.has_optional_import_message       ());
  EXPECT_TRUE(message.has_optional_public_import_message());
  EXPECT_TRUE(message.has_optional_lazy_message         ());

  EXPECT_TRUE(message.optionalgroup                 ().has_a());
  EXPECT_TRUE(message.optional_nested_message       ().has_bb());
  EXPECT_TRUE(message.optional_foreign_message      ().has_c());
  EXPECT_TRUE(message.optional_import_message       ().has_d());
  EXPECT_TRUE(message.optional_public_import_message().has_e());
  EXPECT_TRUE(message.optional_lazy_message         ().has_bb());

  EXPECT_TRUE(message.has_optional_nested_enum ());
  EXPECT_TRUE(message.has_optional_foreign_enum());
  EXPECT_TRUE(message.has_optional_import_enum ());


  EXPECT_EQ(101  , message.optional_int32   ());
  EXPECT_EQ(102  , message.optional_int64   ());
  EXPECT_EQ(103  , message.optional_uint32  ());
  EXPECT_EQ(104  , message.optional_uint64  ());
  EXPECT_EQ(105  , message.optional_sint32  ());
  EXPECT_EQ(106  , message.optional_sint64  ());
  EXPECT_EQ(107  , message.optional_fixed32 ());
  EXPECT_EQ(108  , message.optional_fixed64 ());
  EXPECT_EQ(109  , message.optional_sfixed32());
  EXPECT_EQ(110  , message.optional_sfixed64());
  EXPECT_EQ(111  , message.optional_float   ());
  EXPECT_EQ(112  , message.optional_double  ());
  EXPECT_EQ(true , message.optional_bool    ());
  EXPECT_EQ("115", message.optional_string  ());
  EXPECT_EQ("116", message.optional_bytes   ());

  EXPECT_EQ(117, message.optionalgroup                 ().a());
  EXPECT_EQ(118, message.optional_nested_message       ().bb());
  EXPECT_EQ(119, message.optional_foreign_message      ().c());
  EXPECT_EQ(120, message.optional_import_message       ().d());
  EXPECT_EQ(126, message.optional_public_import_message().e());
  EXPECT_EQ(127, message.optional_lazy_message         ().bb());

  EXPECT_EQ(unittest::TestAllTypesLite::BAZ , message.optional_nested_enum ());
  EXPECT_EQ(unittest::FOREIGN_LITE_BAZ      , message.optional_foreign_enum());
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAZ, message.optional_import_enum ());


  // -----------------------------------------------------------------

  ASSERT_EQ(2, message.repeated_int32_size   ());
  ASSERT_EQ(2, message.repeated_int64_size   ());
  ASSERT_EQ(2, message.repeated_uint32_size  ());
  ASSERT_EQ(2, message.repeated_uint64_size  ());
  ASSERT_EQ(2, message.repeated_sint32_size  ());
  ASSERT_EQ(2, message.repeated_sint64_size  ());
  ASSERT_EQ(2, message.repeated_fixed32_size ());
  ASSERT_EQ(2, message.repeated_fixed64_size ());
  ASSERT_EQ(2, message.repeated_sfixed32_size());
  ASSERT_EQ(2, message.repeated_sfixed64_size());
  ASSERT_EQ(2, message.repeated_float_size   ());
  ASSERT_EQ(2, message.repeated_double_size  ());
  ASSERT_EQ(2, message.repeated_bool_size    ());
  ASSERT_EQ(2, message.repeated_string_size  ());
  ASSERT_EQ(2, message.repeated_bytes_size   ());

  ASSERT_EQ(2, message.repeatedgroup_size           ());
  ASSERT_EQ(2, message.repeated_nested_message_size ());
  ASSERT_EQ(2, message.repeated_foreign_message_size());
  ASSERT_EQ(2, message.repeated_import_message_size ());
  ASSERT_EQ(2, message.repeated_lazy_message_size   ());
  ASSERT_EQ(2, message.repeated_nested_enum_size    ());
  ASSERT_EQ(2, message.repeated_foreign_enum_size   ());
  ASSERT_EQ(2, message.repeated_import_enum_size    ());


  EXPECT_EQ(201  , message.repeated_int32   (0));
  EXPECT_EQ(202  , message.repeated_int64   (0));
  EXPECT_EQ(203  , message.repeated_uint32  (0));
  EXPECT_EQ(204  , message.repeated_uint64  (0));
  EXPECT_EQ(205  , message.repeated_sint32  (0));
  EXPECT_EQ(206  , message.repeated_sint64  (0));
  EXPECT_EQ(207  , message.repeated_fixed32 (0));
  EXPECT_EQ(208  , message.repeated_fixed64 (0));
  EXPECT_EQ(209  , message.repeated_sfixed32(0));
  EXPECT_EQ(210  , message.repeated_sfixed64(0));
  EXPECT_EQ(211  , message.repeated_float   (0));
  EXPECT_EQ(212  , message.repeated_double  (0));
  EXPECT_EQ(true , message.repeated_bool    (0));
  EXPECT_EQ("215", message.repeated_string  (0));
  EXPECT_EQ("216", message.repeated_bytes   (0));

  EXPECT_EQ(217, message.repeatedgroup           (0).a());
  EXPECT_EQ(218, message.repeated_nested_message (0).bb());
  EXPECT_EQ(219, message.repeated_foreign_message(0).c());
  EXPECT_EQ(220, message.repeated_import_message (0).d());
  EXPECT_EQ(227, message.repeated_lazy_message   (0).bb());


  EXPECT_EQ(unittest::TestAllTypesLite::BAR , message.repeated_nested_enum (0));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR      , message.repeated_foreign_enum(0));
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAR, message.repeated_import_enum (0));

  EXPECT_EQ(301  , message.repeated_int32   (1));
  EXPECT_EQ(302  , message.repeated_int64   (1));
  EXPECT_EQ(303  , message.repeated_uint32  (1));
  EXPECT_EQ(304  , message.repeated_uint64  (1));
  EXPECT_EQ(305  , message.repeated_sint32  (1));
  EXPECT_EQ(306  , message.repeated_sint64  (1));
  EXPECT_EQ(307  , message.repeated_fixed32 (1));
  EXPECT_EQ(308  , message.repeated_fixed64 (1));
  EXPECT_EQ(309  , message.repeated_sfixed32(1));
  EXPECT_EQ(310  , message.repeated_sfixed64(1));
  EXPECT_EQ(311  , message.repeated_float   (1));
  EXPECT_EQ(312  , message.repeated_double  (1));
  EXPECT_EQ(false, message.repeated_bool    (1));
  EXPECT_EQ("315", message.repeated_string  (1));
  EXPECT_EQ("316", message.repeated_bytes   (1));

  EXPECT_EQ(317, message.repeatedgroup           (1).a());
  EXPECT_EQ(318, message.repeated_nested_message (1).bb());
  EXPECT_EQ(319, message.repeated_foreign_message(1).c());
  EXPECT_EQ(320, message.repeated_import_message (1).d());
  EXPECT_EQ(327, message.repeated_lazy_message   (1).bb());

  EXPECT_EQ(unittest::TestAllTypesLite::BAZ , message.repeated_nested_enum (1));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAZ      , message.repeated_foreign_enum(1));
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAZ, message.repeated_import_enum (1));


  // -----------------------------------------------------------------

  EXPECT_TRUE(message.has_default_int32   ());
  EXPECT_TRUE(message.has_default_int64   ());
  EXPECT_TRUE(message.has_default_uint32  ());
  EXPECT_TRUE(message.has_default_uint64  ());
  EXPECT_TRUE(message.has_default_sint32  ());
  EXPECT_TRUE(message.has_default_sint64  ());
  EXPECT_TRUE(message.has_default_fixed32 ());
  EXPECT_TRUE(message.has_default_fixed64 ());
  EXPECT_TRUE(message.has_default_sfixed32());
  EXPECT_TRUE(message.has_default_sfixed64());
  EXPECT_TRUE(message.has_default_float   ());
  EXPECT_TRUE(message.has_default_double  ());
  EXPECT_TRUE(message.has_default_bool    ());
  EXPECT_TRUE(message.has_default_string  ());
  EXPECT_TRUE(message.has_default_bytes   ());

  EXPECT_TRUE(message.has_default_nested_enum ());
  EXPECT_TRUE(message.has_default_foreign_enum());
  EXPECT_TRUE(message.has_default_import_enum ());


  EXPECT_EQ(401  , message.default_int32   ());
  EXPECT_EQ(402  , message.default_int64   ());
  EXPECT_EQ(403  , message.default_uint32  ());
  EXPECT_EQ(404  , message.default_uint64  ());
  EXPECT_EQ(405  , message.default_sint32  ());
  EXPECT_EQ(406  , message.default_sint64  ());
  EXPECT_EQ(407  , message.default_fixed32 ());
  EXPECT_EQ(408  , message.default_fixed64 ());
  EXPECT_EQ(409  , message.default_sfixed32());
  EXPECT_EQ(410  , message.default_sfixed64());
  EXPECT_EQ(411  , message.default_float   ());
  EXPECT_EQ(412  , message.default_double  ());
  EXPECT_EQ(false, message.default_bool    ());
  EXPECT_EQ("415", message.default_string  ());
  EXPECT_EQ("416", message.default_bytes   ());

  EXPECT_EQ(unittest::TestAllTypesLite::FOO , message.default_nested_enum ());
  EXPECT_EQ(unittest::FOREIGN_LITE_FOO      , message.default_foreign_enum());
  EXPECT_EQ(unittest_import::IMPORT_LITE_FOO, message.default_import_enum ());

}

// -------------------------------------------------------------------

void TestUtilLite::ExpectClear(const unittest::TestAllTypesLite& message) {
  // has_blah() should initially be false for all optional fields.
  EXPECT_FALSE(message.has_optional_int32   ());
  EXPECT_FALSE(message.has_optional_int64   ());
  EXPECT_FALSE(message.has_optional_uint32  ());
  EXPECT_FALSE(message.has_optional_uint64  ());
  EXPECT_FALSE(message.has_optional_sint32  ());
  EXPECT_FALSE(message.has_optional_sint64  ());
  EXPECT_FALSE(message.has_optional_fixed32 ());
  EXPECT_FALSE(message.has_optional_fixed64 ());
  EXPECT_FALSE(message.has_optional_sfixed32());
  EXPECT_FALSE(message.has_optional_sfixed64());
  EXPECT_FALSE(message.has_optional_float   ());
  EXPECT_FALSE(message.has_optional_double  ());
  EXPECT_FALSE(message.has_optional_bool    ());
  EXPECT_FALSE(message.has_optional_string  ());
  EXPECT_FALSE(message.has_optional_bytes   ());

  EXPECT_FALSE(message.has_optionalgroup                 ());
  EXPECT_FALSE(message.has_optional_nested_message       ());
  EXPECT_FALSE(message.has_optional_foreign_message      ());
  EXPECT_FALSE(message.has_optional_import_message       ());
  EXPECT_FALSE(message.has_optional_public_import_message());
  EXPECT_FALSE(message.has_optional_lazy_message         ());

  EXPECT_FALSE(message.has_optional_nested_enum ());
  EXPECT_FALSE(message.has_optional_foreign_enum());
  EXPECT_FALSE(message.has_optional_import_enum ());


  // Optional fields without defaults are set to zero or something like it.
  EXPECT_EQ(0    , message.optional_int32   ());
  EXPECT_EQ(0    , message.optional_int64   ());
  EXPECT_EQ(0    , message.optional_uint32  ());
  EXPECT_EQ(0    , message.optional_uint64  ());
  EXPECT_EQ(0    , message.optional_sint32  ());
  EXPECT_EQ(0    , message.optional_sint64  ());
  EXPECT_EQ(0    , message.optional_fixed32 ());
  EXPECT_EQ(0    , message.optional_fixed64 ());
  EXPECT_EQ(0    , message.optional_sfixed32());
  EXPECT_EQ(0    , message.optional_sfixed64());
  EXPECT_EQ(0    , message.optional_float   ());
  EXPECT_EQ(0    , message.optional_double  ());
  EXPECT_EQ(false, message.optional_bool    ());
  EXPECT_EQ(""   , message.optional_string  ());
  EXPECT_EQ(""   , message.optional_bytes   ());

  // Embedded messages should also be clear.
  EXPECT_FALSE(message.optionalgroup                 ().has_a());
  EXPECT_FALSE(message.optional_nested_message       ().has_bb());
  EXPECT_FALSE(message.optional_foreign_message      ().has_c());
  EXPECT_FALSE(message.optional_import_message       ().has_d());
  EXPECT_FALSE(message.optional_public_import_message().has_e());
  EXPECT_FALSE(message.optional_lazy_message         ().has_bb());

  EXPECT_EQ(0, message.optionalgroup           ().a());
  EXPECT_EQ(0, message.optional_nested_message ().bb());
  EXPECT_EQ(0, message.optional_foreign_message().c());
  EXPECT_EQ(0, message.optional_import_message ().d());

  // Enums without defaults are set to the first value in the enum.
  EXPECT_EQ(unittest::TestAllTypesLite::FOO , message.optional_nested_enum ());
  EXPECT_EQ(unittest::FOREIGN_LITE_FOO      , message.optional_foreign_enum());
  EXPECT_EQ(unittest_import::IMPORT_LITE_FOO, message.optional_import_enum ());


  // Repeated fields are empty.
  EXPECT_EQ(0, message.repeated_int32_size   ());
  EXPECT_EQ(0, message.repeated_int64_size   ());
  EXPECT_EQ(0, message.repeated_uint32_size  ());
  EXPECT_EQ(0, message.repeated_uint64_size  ());
  EXPECT_EQ(0, message.repeated_sint32_size  ());
  EXPECT_EQ(0, message.repeated_sint64_size  ());
  EXPECT_EQ(0, message.repeated_fixed32_size ());
  EXPECT_EQ(0, message.repeated_fixed64_size ());
  EXPECT_EQ(0, message.repeated_sfixed32_size());
  EXPECT_EQ(0, message.repeated_sfixed64_size());
  EXPECT_EQ(0, message.repeated_float_size   ());
  EXPECT_EQ(0, message.repeated_double_size  ());
  EXPECT_EQ(0, message.repeated_bool_size    ());
  EXPECT_EQ(0, message.repeated_string_size  ());
  EXPECT_EQ(0, message.repeated_bytes_size   ());

  EXPECT_EQ(0, message.repeatedgroup_size           ());
  EXPECT_EQ(0, message.repeated_nested_message_size ());
  EXPECT_EQ(0, message.repeated_foreign_message_size());
  EXPECT_EQ(0, message.repeated_import_message_size ());
  EXPECT_EQ(0, message.repeated_lazy_message_size   ());
  EXPECT_EQ(0, message.repeated_nested_enum_size    ());
  EXPECT_EQ(0, message.repeated_foreign_enum_size   ());
  EXPECT_EQ(0, message.repeated_import_enum_size    ());


  // has_blah() should also be false for all default fields.
  EXPECT_FALSE(message.has_default_int32   ());
  EXPECT_FALSE(message.has_default_int64   ());
  EXPECT_FALSE(message.has_default_uint32  ());
  EXPECT_FALSE(message.has_default_uint64  ());
  EXPECT_FALSE(message.has_default_sint32  ());
  EXPECT_FALSE(message.has_default_sint64  ());
  EXPECT_FALSE(message.has_default_fixed32 ());
  EXPECT_FALSE(message.has_default_fixed64 ());
  EXPECT_FALSE(message.has_default_sfixed32());
  EXPECT_FALSE(message.has_default_sfixed64());
  EXPECT_FALSE(message.has_default_float   ());
  EXPECT_FALSE(message.has_default_double  ());
  EXPECT_FALSE(message.has_default_bool    ());
  EXPECT_FALSE(message.has_default_string  ());
  EXPECT_FALSE(message.has_default_bytes   ());

  EXPECT_FALSE(message.has_default_nested_enum ());
  EXPECT_FALSE(message.has_default_foreign_enum());
  EXPECT_FALSE(message.has_default_import_enum ());


  // Fields with defaults have their default values (duh).
  EXPECT_EQ( 41    , message.default_int32   ());
  EXPECT_EQ( 42    , message.default_int64   ());
  EXPECT_EQ( 43    , message.default_uint32  ());
  EXPECT_EQ( 44    , message.default_uint64  ());
  EXPECT_EQ(-45    , message.default_sint32  ());
  EXPECT_EQ( 46    , message.default_sint64  ());
  EXPECT_EQ( 47    , message.default_fixed32 ());
  EXPECT_EQ( 48    , message.default_fixed64 ());
  EXPECT_EQ( 49    , message.default_sfixed32());
  EXPECT_EQ(-50    , message.default_sfixed64());
  EXPECT_EQ( 51.5  , message.default_float   ());
  EXPECT_EQ( 52e3  , message.default_double  ());
  EXPECT_EQ(true   , message.default_bool    ());
  EXPECT_EQ("hello", message.default_string  ());
  EXPECT_EQ("world", message.default_bytes   ());

  EXPECT_EQ(unittest::TestAllTypesLite::BAR , message.default_nested_enum ());
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR      , message.default_foreign_enum());
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAR, message.default_import_enum ());

}

// -------------------------------------------------------------------

void TestUtilLite::ExpectRepeatedFieldsModified(
    const unittest::TestAllTypesLite& message) {
  // ModifyRepeatedFields only sets the second repeated element of each
  // field.  In addition to verifying this, we also verify that the first
  // element and size were *not* modified.
  ASSERT_EQ(2, message.repeated_int32_size   ());
  ASSERT_EQ(2, message.repeated_int64_size   ());
  ASSERT_EQ(2, message.repeated_uint32_size  ());
  ASSERT_EQ(2, message.repeated_uint64_size  ());
  ASSERT_EQ(2, message.repeated_sint32_size  ());
  ASSERT_EQ(2, message.repeated_sint64_size  ());
  ASSERT_EQ(2, message.repeated_fixed32_size ());
  ASSERT_EQ(2, message.repeated_fixed64_size ());
  ASSERT_EQ(2, message.repeated_sfixed32_size());
  ASSERT_EQ(2, message.repeated_sfixed64_size());
  ASSERT_EQ(2, message.repeated_float_size   ());
  ASSERT_EQ(2, message.repeated_double_size  ());
  ASSERT_EQ(2, message.repeated_bool_size    ());
  ASSERT_EQ(2, message.repeated_string_size  ());
  ASSERT_EQ(2, message.repeated_bytes_size   ());

  ASSERT_EQ(2, message.repeatedgroup_size           ());
  ASSERT_EQ(2, message.repeated_nested_message_size ());
  ASSERT_EQ(2, message.repeated_foreign_message_size());
  ASSERT_EQ(2, message.repeated_import_message_size ());
  ASSERT_EQ(2, message.repeated_lazy_message_size   ());
  ASSERT_EQ(2, message.repeated_nested_enum_size    ());
  ASSERT_EQ(2, message.repeated_foreign_enum_size   ());
  ASSERT_EQ(2, message.repeated_import_enum_size    ());


  EXPECT_EQ(201  , message.repeated_int32   (0));
  EXPECT_EQ(202  , message.repeated_int64   (0));
  EXPECT_EQ(203  , message.repeated_uint32  (0));
  EXPECT_EQ(204  , message.repeated_uint64  (0));
  EXPECT_EQ(205  , message.repeated_sint32  (0));
  EXPECT_EQ(206  , message.repeated_sint64  (0));
  EXPECT_EQ(207  , message.repeated_fixed32 (0));
  EXPECT_EQ(208  , message.repeated_fixed64 (0));
  EXPECT_EQ(209  , message.repeated_sfixed32(0));
  EXPECT_EQ(210  , message.repeated_sfixed64(0));
  EXPECT_EQ(211  , message.repeated_float   (0));
  EXPECT_EQ(212  , message.repeated_double  (0));
  EXPECT_EQ(true , message.repeated_bool    (0));
  EXPECT_EQ("215", message.repeated_string  (0));
  EXPECT_EQ("216", message.repeated_bytes   (0));

  EXPECT_EQ(217, message.repeatedgroup           (0).a());
  EXPECT_EQ(218, message.repeated_nested_message (0).bb());
  EXPECT_EQ(219, message.repeated_foreign_message(0).c());
  EXPECT_EQ(220, message.repeated_import_message (0).d());
  EXPECT_EQ(227, message.repeated_lazy_message   (0).bb());

  EXPECT_EQ(unittest::TestAllTypesLite::BAR , message.repeated_nested_enum (0));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR      , message.repeated_foreign_enum(0));
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAR, message.repeated_import_enum (0));


  // Actually verify the second (modified) elements now.
  EXPECT_EQ(501  , message.repeated_int32   (1));
  EXPECT_EQ(502  , message.repeated_int64   (1));
  EXPECT_EQ(503  , message.repeated_uint32  (1));
  EXPECT_EQ(504  , message.repeated_uint64  (1));
  EXPECT_EQ(505  , message.repeated_sint32  (1));
  EXPECT_EQ(506  , message.repeated_sint64  (1));
  EXPECT_EQ(507  , message.repeated_fixed32 (1));
  EXPECT_EQ(508  , message.repeated_fixed64 (1));
  EXPECT_EQ(509  , message.repeated_sfixed32(1));
  EXPECT_EQ(510  , message.repeated_sfixed64(1));
  EXPECT_EQ(511  , message.repeated_float   (1));
  EXPECT_EQ(512  , message.repeated_double  (1));
  EXPECT_EQ(true , message.repeated_bool    (1));
  EXPECT_EQ("515", message.repeated_string  (1));
  EXPECT_EQ("516", message.repeated_bytes   (1));

  EXPECT_EQ(517, message.repeatedgroup           (1).a());
  EXPECT_EQ(518, message.repeated_nested_message (1).bb());
  EXPECT_EQ(519, message.repeated_foreign_message(1).c());
  EXPECT_EQ(520, message.repeated_import_message (1).d());
  EXPECT_EQ(527, message.repeated_lazy_message   (1).bb());

  EXPECT_EQ(unittest::TestAllTypesLite::FOO , message.repeated_nested_enum (1));
  EXPECT_EQ(unittest::FOREIGN_LITE_FOO      , message.repeated_foreign_enum(1));
  EXPECT_EQ(unittest_import::IMPORT_LITE_FOO, message.repeated_import_enum (1));

}

// -------------------------------------------------------------------

void TestUtilLite::SetPackedFields(unittest::TestPackedTypesLite* message) {
  message->add_packed_int32   (601);
  message->add_packed_int64   (602);
  message->add_packed_uint32  (603);
  message->add_packed_uint64  (604);
  message->add_packed_sint32  (605);
  message->add_packed_sint64  (606);
  message->add_packed_fixed32 (607);
  message->add_packed_fixed64 (608);
  message->add_packed_sfixed32(609);
  message->add_packed_sfixed64(610);
  message->add_packed_float   (611);
  message->add_packed_double  (612);
  message->add_packed_bool    (true);
  message->add_packed_enum    (unittest::FOREIGN_LITE_BAR);
  // add a second one of each field
  message->add_packed_int32   (701);
  message->add_packed_int64   (702);
  message->add_packed_uint32  (703);
  message->add_packed_uint64  (704);
  message->add_packed_sint32  (705);
  message->add_packed_sint64  (706);
  message->add_packed_fixed32 (707);
  message->add_packed_fixed64 (708);
  message->add_packed_sfixed32(709);
  message->add_packed_sfixed64(710);
  message->add_packed_float   (711);
  message->add_packed_double  (712);
  message->add_packed_bool    (false);
  message->add_packed_enum    (unittest::FOREIGN_LITE_BAZ);
}

// -------------------------------------------------------------------

void TestUtilLite::ModifyPackedFields(unittest::TestPackedTypesLite* message) {
  message->set_packed_int32   (1, 801);
  message->set_packed_int64   (1, 802);
  message->set_packed_uint32  (1, 803);
  message->set_packed_uint64  (1, 804);
  message->set_packed_sint32  (1, 805);
  message->set_packed_sint64  (1, 806);
  message->set_packed_fixed32 (1, 807);
  message->set_packed_fixed64 (1, 808);
  message->set_packed_sfixed32(1, 809);
  message->set_packed_sfixed64(1, 810);
  message->set_packed_float   (1, 811);
  message->set_packed_double  (1, 812);
  message->set_packed_bool    (1, true);
  message->set_packed_enum    (1, unittest::FOREIGN_LITE_FOO);
}

// -------------------------------------------------------------------

void TestUtilLite::ExpectPackedFieldsSet(
    const unittest::TestPackedTypesLite& message) {
  ASSERT_EQ(2, message.packed_int32_size   ());
  ASSERT_EQ(2, message.packed_int64_size   ());
  ASSERT_EQ(2, message.packed_uint32_size  ());
  ASSERT_EQ(2, message.packed_uint64_size  ());
  ASSERT_EQ(2, message.packed_sint32_size  ());
  ASSERT_EQ(2, message.packed_sint64_size  ());
  ASSERT_EQ(2, message.packed_fixed32_size ());
  ASSERT_EQ(2, message.packed_fixed64_size ());
  ASSERT_EQ(2, message.packed_sfixed32_size());
  ASSERT_EQ(2, message.packed_sfixed64_size());
  ASSERT_EQ(2, message.packed_float_size   ());
  ASSERT_EQ(2, message.packed_double_size  ());
  ASSERT_EQ(2, message.packed_bool_size    ());
  ASSERT_EQ(2, message.packed_enum_size    ());

  EXPECT_EQ(601  , message.packed_int32   (0));
  EXPECT_EQ(602  , message.packed_int64   (0));
  EXPECT_EQ(603  , message.packed_uint32  (0));
  EXPECT_EQ(604  , message.packed_uint64  (0));
  EXPECT_EQ(605  , message.packed_sint32  (0));
  EXPECT_EQ(606  , message.packed_sint64  (0));
  EXPECT_EQ(607  , message.packed_fixed32 (0));
  EXPECT_EQ(608  , message.packed_fixed64 (0));
  EXPECT_EQ(609  , message.packed_sfixed32(0));
  EXPECT_EQ(610  , message.packed_sfixed64(0));
  EXPECT_EQ(611  , message.packed_float   (0));
  EXPECT_EQ(612  , message.packed_double  (0));
  EXPECT_EQ(true , message.packed_bool    (0));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR, message.packed_enum(0));

  EXPECT_EQ(701  , message.packed_int32   (1));
  EXPECT_EQ(702  , message.packed_int64   (1));
  EXPECT_EQ(703  , message.packed_uint32  (1));
  EXPECT_EQ(704  , message.packed_uint64  (1));
  EXPECT_EQ(705  , message.packed_sint32  (1));
  EXPECT_EQ(706  , message.packed_sint64  (1));
  EXPECT_EQ(707  , message.packed_fixed32 (1));
  EXPECT_EQ(708  , message.packed_fixed64 (1));
  EXPECT_EQ(709  , message.packed_sfixed32(1));
  EXPECT_EQ(710  , message.packed_sfixed64(1));
  EXPECT_EQ(711  , message.packed_float   (1));
  EXPECT_EQ(712  , message.packed_double  (1));
  EXPECT_EQ(false, message.packed_bool    (1));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAZ, message.packed_enum(1));
}

// -------------------------------------------------------------------

void TestUtilLite::ExpectPackedClear(
    const unittest::TestPackedTypesLite& message) {
  // Packed repeated fields are empty.
  EXPECT_EQ(0, message.packed_int32_size   ());
  EXPECT_EQ(0, message.packed_int64_size   ());
  EXPECT_EQ(0, message.packed_uint32_size  ());
  EXPECT_EQ(0, message.packed_uint64_size  ());
  EXPECT_EQ(0, message.packed_sint32_size  ());
  EXPECT_EQ(0, message.packed_sint64_size  ());
  EXPECT_EQ(0, message.packed_fixed32_size ());
  EXPECT_EQ(0, message.packed_fixed64_size ());
  EXPECT_EQ(0, message.packed_sfixed32_size());
  EXPECT_EQ(0, message.packed_sfixed64_size());
  EXPECT_EQ(0, message.packed_float_size   ());
  EXPECT_EQ(0, message.packed_double_size  ());
  EXPECT_EQ(0, message.packed_bool_size    ());
  EXPECT_EQ(0, message.packed_enum_size    ());
}

// -------------------------------------------------------------------

void TestUtilLite::ExpectPackedFieldsModified(
    const unittest::TestPackedTypesLite& message) {
  // Do the same for packed repeated fields.
  ASSERT_EQ(2, message.packed_int32_size   ());
  ASSERT_EQ(2, message.packed_int64_size   ());
  ASSERT_EQ(2, message.packed_uint32_size  ());
  ASSERT_EQ(2, message.packed_uint64_size  ());
  ASSERT_EQ(2, message.packed_sint32_size  ());
  ASSERT_EQ(2, message.packed_sint64_size  ());
  ASSERT_EQ(2, message.packed_fixed32_size ());
  ASSERT_EQ(2, message.packed_fixed64_size ());
  ASSERT_EQ(2, message.packed_sfixed32_size());
  ASSERT_EQ(2, message.packed_sfixed64_size());
  ASSERT_EQ(2, message.packed_float_size   ());
  ASSERT_EQ(2, message.packed_double_size  ());
  ASSERT_EQ(2, message.packed_bool_size    ());
  ASSERT_EQ(2, message.packed_enum_size    ());

  EXPECT_EQ(601  , message.packed_int32   (0));
  EXPECT_EQ(602  , message.packed_int64   (0));
  EXPECT_EQ(603  , message.packed_uint32  (0));
  EXPECT_EQ(604  , message.packed_uint64  (0));
  EXPECT_EQ(605  , message.packed_sint32  (0));
  EXPECT_EQ(606  , message.packed_sint64  (0));
  EXPECT_EQ(607  , message.packed_fixed32 (0));
  EXPECT_EQ(608  , message.packed_fixed64 (0));
  EXPECT_EQ(609  , message.packed_sfixed32(0));
  EXPECT_EQ(610  , message.packed_sfixed64(0));
  EXPECT_EQ(611  , message.packed_float   (0));
  EXPECT_EQ(612  , message.packed_double  (0));
  EXPECT_EQ(true , message.packed_bool    (0));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR, message.packed_enum(0));
  // Actually verify the second (modified) elements now.
  EXPECT_EQ(801  , message.packed_int32   (1));
  EXPECT_EQ(802  , message.packed_int64   (1));
  EXPECT_EQ(803  , message.packed_uint32  (1));
  EXPECT_EQ(804  , message.packed_uint64  (1));
  EXPECT_EQ(805  , message.packed_sint32  (1));
  EXPECT_EQ(806  , message.packed_sint64  (1));
  EXPECT_EQ(807  , message.packed_fixed32 (1));
  EXPECT_EQ(808  , message.packed_fixed64 (1));
  EXPECT_EQ(809  , message.packed_sfixed32(1));
  EXPECT_EQ(810  , message.packed_sfixed64(1));
  EXPECT_EQ(811  , message.packed_float   (1));
  EXPECT_EQ(812  , message.packed_double  (1));
  EXPECT_EQ(true , message.packed_bool    (1));
  EXPECT_EQ(unittest::FOREIGN_LITE_FOO, message.packed_enum(1));
}

// ===================================================================
// Extensions
//
// All this code is exactly equivalent to the above code except that it's
// manipulating extension fields instead of normal ones.
//
// I gave up on the 80-char limit here.  Sorry.

void TestUtilLite::SetAllExtensions(unittest::TestAllExtensionsLite* message) {
  message->SetExtension(unittest::optional_int32_extension_lite   , 101);
  message->SetExtension(unittest::optional_int64_extension_lite   , 102);
  message->SetExtension(unittest::optional_uint32_extension_lite  , 103);
  message->SetExtension(unittest::optional_uint64_extension_lite  , 104);
  message->SetExtension(unittest::optional_sint32_extension_lite  , 105);
  message->SetExtension(unittest::optional_sint64_extension_lite  , 106);
  message->SetExtension(unittest::optional_fixed32_extension_lite , 107);
  message->SetExtension(unittest::optional_fixed64_extension_lite , 108);
  message->SetExtension(unittest::optional_sfixed32_extension_lite, 109);
  message->SetExtension(unittest::optional_sfixed64_extension_lite, 110);
  message->SetExtension(unittest::optional_float_extension_lite   , 111);
  message->SetExtension(unittest::optional_double_extension_lite  , 112);
  message->SetExtension(unittest::optional_bool_extension_lite    , true);
  message->SetExtension(unittest::optional_string_extension_lite  , "115");
  message->SetExtension(unittest::optional_bytes_extension_lite   , "116");

  message->MutableExtension(unittest::optionalgroup_extension_lite                 )->set_a(117);
  message->MutableExtension(unittest::optional_nested_message_extension_lite       )->set_bb(118);
  message->MutableExtension(unittest::optional_foreign_message_extension_lite      )->set_c(119);
  message->MutableExtension(unittest::optional_import_message_extension_lite       )->set_d(120);
  message->MutableExtension(unittest::optional_public_import_message_extension_lite)->set_e(126);
  message->MutableExtension(unittest::optional_lazy_message_extension_lite         )->set_bb(127);

  message->SetExtension(unittest::optional_nested_enum_extension_lite , unittest::TestAllTypesLite::BAZ );
  message->SetExtension(unittest::optional_foreign_enum_extension_lite, unittest::FOREIGN_LITE_BAZ      );
  message->SetExtension(unittest::optional_import_enum_extension_lite , unittest_import::IMPORT_LITE_BAZ);


  // -----------------------------------------------------------------

  message->AddExtension(unittest::repeated_int32_extension_lite   , 201);
  message->AddExtension(unittest::repeated_int64_extension_lite   , 202);
  message->AddExtension(unittest::repeated_uint32_extension_lite  , 203);
  message->AddExtension(unittest::repeated_uint64_extension_lite  , 204);
  message->AddExtension(unittest::repeated_sint32_extension_lite  , 205);
  message->AddExtension(unittest::repeated_sint64_extension_lite  , 206);
  message->AddExtension(unittest::repeated_fixed32_extension_lite , 207);
  message->AddExtension(unittest::repeated_fixed64_extension_lite , 208);
  message->AddExtension(unittest::repeated_sfixed32_extension_lite, 209);
  message->AddExtension(unittest::repeated_sfixed64_extension_lite, 210);
  message->AddExtension(unittest::repeated_float_extension_lite   , 211);
  message->AddExtension(unittest::repeated_double_extension_lite  , 212);
  message->AddExtension(unittest::repeated_bool_extension_lite    , true);
  message->AddExtension(unittest::repeated_string_extension_lite  , "215");
  message->AddExtension(unittest::repeated_bytes_extension_lite   , "216");

  message->AddExtension(unittest::repeatedgroup_extension_lite           )->set_a(217);
  message->AddExtension(unittest::repeated_nested_message_extension_lite )->set_bb(218);
  message->AddExtension(unittest::repeated_foreign_message_extension_lite)->set_c(219);
  message->AddExtension(unittest::repeated_import_message_extension_lite )->set_d(220);
  message->AddExtension(unittest::repeated_lazy_message_extension_lite   )->set_bb(227);

  message->AddExtension(unittest::repeated_nested_enum_extension_lite , unittest::TestAllTypesLite::BAR );
  message->AddExtension(unittest::repeated_foreign_enum_extension_lite, unittest::FOREIGN_LITE_BAR      );
  message->AddExtension(unittest::repeated_import_enum_extension_lite , unittest_import::IMPORT_LITE_BAR);


  // Add a second one of each field.
  message->AddExtension(unittest::repeated_int32_extension_lite   , 301);
  message->AddExtension(unittest::repeated_int64_extension_lite   , 302);
  message->AddExtension(unittest::repeated_uint32_extension_lite  , 303);
  message->AddExtension(unittest::repeated_uint64_extension_lite  , 304);
  message->AddExtension(unittest::repeated_sint32_extension_lite  , 305);
  message->AddExtension(unittest::repeated_sint64_extension_lite  , 306);
  message->AddExtension(unittest::repeated_fixed32_extension_lite , 307);
  message->AddExtension(unittest::repeated_fixed64_extension_lite , 308);
  message->AddExtension(unittest::repeated_sfixed32_extension_lite, 309);
  message->AddExtension(unittest::repeated_sfixed64_extension_lite, 310);
  message->AddExtension(unittest::repeated_float_extension_lite   , 311);
  message->AddExtension(unittest::repeated_double_extension_lite  , 312);
  message->AddExtension(unittest::repeated_bool_extension_lite    , false);
  message->AddExtension(unittest::repeated_string_extension_lite  , "315");
  message->AddExtension(unittest::repeated_bytes_extension_lite   , "316");

  message->AddExtension(unittest::repeatedgroup_extension_lite           )->set_a(317);
  message->AddExtension(unittest::repeated_nested_message_extension_lite )->set_bb(318);
  message->AddExtension(unittest::repeated_foreign_message_extension_lite)->set_c(319);
  message->AddExtension(unittest::repeated_import_message_extension_lite )->set_d(320);
  message->AddExtension(unittest::repeated_lazy_message_extension_lite   )->set_bb(327);

  message->AddExtension(unittest::repeated_nested_enum_extension_lite , unittest::TestAllTypesLite::BAZ );
  message->AddExtension(unittest::repeated_foreign_enum_extension_lite, unittest::FOREIGN_LITE_BAZ      );
  message->AddExtension(unittest::repeated_import_enum_extension_lite , unittest_import::IMPORT_LITE_BAZ);


  // -----------------------------------------------------------------

  message->SetExtension(unittest::default_int32_extension_lite   , 401);
  message->SetExtension(unittest::default_int64_extension_lite   , 402);
  message->SetExtension(unittest::default_uint32_extension_lite  , 403);
  message->SetExtension(unittest::default_uint64_extension_lite  , 404);
  message->SetExtension(unittest::default_sint32_extension_lite  , 405);
  message->SetExtension(unittest::default_sint64_extension_lite  , 406);
  message->SetExtension(unittest::default_fixed32_extension_lite , 407);
  message->SetExtension(unittest::default_fixed64_extension_lite , 408);
  message->SetExtension(unittest::default_sfixed32_extension_lite, 409);
  message->SetExtension(unittest::default_sfixed64_extension_lite, 410);
  message->SetExtension(unittest::default_float_extension_lite   , 411);
  message->SetExtension(unittest::default_double_extension_lite  , 412);
  message->SetExtension(unittest::default_bool_extension_lite    , false);
  message->SetExtension(unittest::default_string_extension_lite  , "415");
  message->SetExtension(unittest::default_bytes_extension_lite   , "416");

  message->SetExtension(unittest::default_nested_enum_extension_lite , unittest::TestAllTypesLite::FOO );
  message->SetExtension(unittest::default_foreign_enum_extension_lite, unittest::FOREIGN_LITE_FOO      );
  message->SetExtension(unittest::default_import_enum_extension_lite , unittest_import::IMPORT_LITE_FOO);

}

// -------------------------------------------------------------------

void TestUtilLite::ModifyRepeatedExtensions(
    unittest::TestAllExtensionsLite* message) {
  message->SetExtension(unittest::repeated_int32_extension_lite   , 1, 501);
  message->SetExtension(unittest::repeated_int64_extension_lite   , 1, 502);
  message->SetExtension(unittest::repeated_uint32_extension_lite  , 1, 503);
  message->SetExtension(unittest::repeated_uint64_extension_lite  , 1, 504);
  message->SetExtension(unittest::repeated_sint32_extension_lite  , 1, 505);
  message->SetExtension(unittest::repeated_sint64_extension_lite  , 1, 506);
  message->SetExtension(unittest::repeated_fixed32_extension_lite , 1, 507);
  message->SetExtension(unittest::repeated_fixed64_extension_lite , 1, 508);
  message->SetExtension(unittest::repeated_sfixed32_extension_lite, 1, 509);
  message->SetExtension(unittest::repeated_sfixed64_extension_lite, 1, 510);
  message->SetExtension(unittest::repeated_float_extension_lite   , 1, 511);
  message->SetExtension(unittest::repeated_double_extension_lite  , 1, 512);
  message->SetExtension(unittest::repeated_bool_extension_lite    , 1, true);
  message->SetExtension(unittest::repeated_string_extension_lite  , 1, "515");
  message->SetExtension(unittest::repeated_bytes_extension_lite   , 1, "516");

  message->MutableExtension(unittest::repeatedgroup_extension_lite           , 1)->set_a(517);
  message->MutableExtension(unittest::repeated_nested_message_extension_lite , 1)->set_bb(518);
  message->MutableExtension(unittest::repeated_foreign_message_extension_lite, 1)->set_c(519);
  message->MutableExtension(unittest::repeated_import_message_extension_lite , 1)->set_d(520);
  message->MutableExtension(unittest::repeated_lazy_message_extension_lite   , 1)->set_bb(527);

  message->SetExtension(unittest::repeated_nested_enum_extension_lite , 1, unittest::TestAllTypesLite::FOO );
  message->SetExtension(unittest::repeated_foreign_enum_extension_lite, 1, unittest::FOREIGN_LITE_FOO      );
  message->SetExtension(unittest::repeated_import_enum_extension_lite , 1, unittest_import::IMPORT_LITE_FOO);

}

// -------------------------------------------------------------------

void TestUtilLite::ExpectAllExtensionsSet(
    const unittest::TestAllExtensionsLite& message) {
  EXPECT_TRUE(message.HasExtension(unittest::optional_int32_extension_lite   ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_int64_extension_lite   ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_uint32_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_uint64_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_sint32_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_sint64_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_fixed32_extension_lite ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_fixed64_extension_lite ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_sfixed32_extension_lite));
  EXPECT_TRUE(message.HasExtension(unittest::optional_sfixed64_extension_lite));
  EXPECT_TRUE(message.HasExtension(unittest::optional_float_extension_lite   ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_double_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_bool_extension_lite    ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_string_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_bytes_extension_lite   ));

  EXPECT_TRUE(message.HasExtension(unittest::optionalgroup_extension_lite                 ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_nested_message_extension_lite       ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_foreign_message_extension_lite      ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_import_message_extension_lite       ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_public_import_message_extension_lite));
  EXPECT_TRUE(message.HasExtension(unittest::optional_lazy_message_extension_lite         ));

  EXPECT_TRUE(message.GetExtension(unittest::optionalgroup_extension_lite                 ).has_a());
  EXPECT_TRUE(message.GetExtension(unittest::optional_nested_message_extension_lite       ).has_bb());
  EXPECT_TRUE(message.GetExtension(unittest::optional_foreign_message_extension_lite      ).has_c());
  EXPECT_TRUE(message.GetExtension(unittest::optional_import_message_extension_lite       ).has_d());
  EXPECT_TRUE(message.GetExtension(unittest::optional_public_import_message_extension_lite).has_e());
  EXPECT_TRUE(message.GetExtension(unittest::optional_lazy_message_extension_lite         ).has_bb());

  EXPECT_TRUE(message.HasExtension(unittest::optional_nested_enum_extension_lite ));
  EXPECT_TRUE(message.HasExtension(unittest::optional_foreign_enum_extension_lite));
  EXPECT_TRUE(message.HasExtension(unittest::optional_import_enum_extension_lite ));


  EXPECT_EQ(101  , message.GetExtension(unittest::optional_int32_extension_lite   ));
  EXPECT_EQ(102  , message.GetExtension(unittest::optional_int64_extension_lite   ));
  EXPECT_EQ(103  , message.GetExtension(unittest::optional_uint32_extension_lite  ));
  EXPECT_EQ(104  , message.GetExtension(unittest::optional_uint64_extension_lite  ));
  EXPECT_EQ(105  , message.GetExtension(unittest::optional_sint32_extension_lite  ));
  EXPECT_EQ(106  , message.GetExtension(unittest::optional_sint64_extension_lite  ));
  EXPECT_EQ(107  , message.GetExtension(unittest::optional_fixed32_extension_lite ));
  EXPECT_EQ(108  , message.GetExtension(unittest::optional_fixed64_extension_lite ));
  EXPECT_EQ(109  , message.GetExtension(unittest::optional_sfixed32_extension_lite));
  EXPECT_EQ(110  , message.GetExtension(unittest::optional_sfixed64_extension_lite));
  EXPECT_EQ(111  , message.GetExtension(unittest::optional_float_extension_lite   ));
  EXPECT_EQ(112  , message.GetExtension(unittest::optional_double_extension_lite  ));
  EXPECT_EQ(true , message.GetExtension(unittest::optional_bool_extension_lite    ));
  EXPECT_EQ("115", message.GetExtension(unittest::optional_string_extension_lite  ));
  EXPECT_EQ("116", message.GetExtension(unittest::optional_bytes_extension_lite   ));

  EXPECT_EQ(117, message.GetExtension(unittest::optionalgroup_extension_lite                 ).a());
  EXPECT_EQ(118, message.GetExtension(unittest::optional_nested_message_extension_lite       ).bb());
  EXPECT_EQ(119, message.GetExtension(unittest::optional_foreign_message_extension_lite      ).c());
  EXPECT_EQ(120, message.GetExtension(unittest::optional_import_message_extension_lite       ).d());
  EXPECT_EQ(126, message.GetExtension(unittest::optional_public_import_message_extension_lite).e());
  EXPECT_EQ(127, message.GetExtension(unittest::optional_lazy_message_extension_lite         ).bb());

  EXPECT_EQ(unittest::TestAllTypesLite::BAZ , message.GetExtension(unittest::optional_nested_enum_extension_lite ));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAZ      , message.GetExtension(unittest::optional_foreign_enum_extension_lite));
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAZ, message.GetExtension(unittest::optional_import_enum_extension_lite ));


  // -----------------------------------------------------------------

  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_int32_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_int64_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_uint32_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_uint64_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_sint32_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_sint64_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_fixed32_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_fixed64_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_sfixed32_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_sfixed64_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_float_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_double_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_bool_extension_lite    ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_string_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_bytes_extension_lite   ));

  ASSERT_EQ(2, message.ExtensionSize(unittest::repeatedgroup_extension_lite           ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_nested_message_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_foreign_message_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_import_message_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_lazy_message_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_nested_enum_extension_lite    ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_foreign_enum_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_import_enum_extension_lite    ));


  EXPECT_EQ(201  , message.GetExtension(unittest::repeated_int32_extension_lite   , 0));
  EXPECT_EQ(202  , message.GetExtension(unittest::repeated_int64_extension_lite   , 0));
  EXPECT_EQ(203  , message.GetExtension(unittest::repeated_uint32_extension_lite  , 0));
  EXPECT_EQ(204  , message.GetExtension(unittest::repeated_uint64_extension_lite  , 0));
  EXPECT_EQ(205  , message.GetExtension(unittest::repeated_sint32_extension_lite  , 0));
  EXPECT_EQ(206  , message.GetExtension(unittest::repeated_sint64_extension_lite  , 0));
  EXPECT_EQ(207  , message.GetExtension(unittest::repeated_fixed32_extension_lite , 0));
  EXPECT_EQ(208  , message.GetExtension(unittest::repeated_fixed64_extension_lite , 0));
  EXPECT_EQ(209  , message.GetExtension(unittest::repeated_sfixed32_extension_lite, 0));
  EXPECT_EQ(210  , message.GetExtension(unittest::repeated_sfixed64_extension_lite, 0));
  EXPECT_EQ(211  , message.GetExtension(unittest::repeated_float_extension_lite   , 0));
  EXPECT_EQ(212  , message.GetExtension(unittest::repeated_double_extension_lite  , 0));
  EXPECT_EQ(true , message.GetExtension(unittest::repeated_bool_extension_lite    , 0));
  EXPECT_EQ("215", message.GetExtension(unittest::repeated_string_extension_lite  , 0));
  EXPECT_EQ("216", message.GetExtension(unittest::repeated_bytes_extension_lite   , 0));

  EXPECT_EQ(217, message.GetExtension(unittest::repeatedgroup_extension_lite           , 0).a());
  EXPECT_EQ(218, message.GetExtension(unittest::repeated_nested_message_extension_lite , 0).bb());
  EXPECT_EQ(219, message.GetExtension(unittest::repeated_foreign_message_extension_lite, 0).c());
  EXPECT_EQ(220, message.GetExtension(unittest::repeated_import_message_extension_lite , 0).d());
  EXPECT_EQ(227, message.GetExtension(unittest::repeated_lazy_message_extension_lite   , 0).bb());

  EXPECT_EQ(unittest::TestAllTypesLite::BAR , message.GetExtension(unittest::repeated_nested_enum_extension_lite , 0));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR      , message.GetExtension(unittest::repeated_foreign_enum_extension_lite, 0));
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAR, message.GetExtension(unittest::repeated_import_enum_extension_lite , 0));


  EXPECT_EQ(301  , message.GetExtension(unittest::repeated_int32_extension_lite   , 1));
  EXPECT_EQ(302  , message.GetExtension(unittest::repeated_int64_extension_lite   , 1));
  EXPECT_EQ(303  , message.GetExtension(unittest::repeated_uint32_extension_lite  , 1));
  EXPECT_EQ(304  , message.GetExtension(unittest::repeated_uint64_extension_lite  , 1));
  EXPECT_EQ(305  , message.GetExtension(unittest::repeated_sint32_extension_lite  , 1));
  EXPECT_EQ(306  , message.GetExtension(unittest::repeated_sint64_extension_lite  , 1));
  EXPECT_EQ(307  , message.GetExtension(unittest::repeated_fixed32_extension_lite , 1));
  EXPECT_EQ(308  , message.GetExtension(unittest::repeated_fixed64_extension_lite , 1));
  EXPECT_EQ(309  , message.GetExtension(unittest::repeated_sfixed32_extension_lite, 1));
  EXPECT_EQ(310  , message.GetExtension(unittest::repeated_sfixed64_extension_lite, 1));
  EXPECT_EQ(311  , message.GetExtension(unittest::repeated_float_extension_lite   , 1));
  EXPECT_EQ(312  , message.GetExtension(unittest::repeated_double_extension_lite  , 1));
  EXPECT_EQ(false, message.GetExtension(unittest::repeated_bool_extension_lite    , 1));
  EXPECT_EQ("315", message.GetExtension(unittest::repeated_string_extension_lite  , 1));
  EXPECT_EQ("316", message.GetExtension(unittest::repeated_bytes_extension_lite   , 1));

  EXPECT_EQ(317, message.GetExtension(unittest::repeatedgroup_extension_lite           , 1).a());
  EXPECT_EQ(318, message.GetExtension(unittest::repeated_nested_message_extension_lite , 1).bb());
  EXPECT_EQ(319, message.GetExtension(unittest::repeated_foreign_message_extension_lite, 1).c());
  EXPECT_EQ(320, message.GetExtension(unittest::repeated_import_message_extension_lite , 1).d());
  EXPECT_EQ(327, message.GetExtension(unittest::repeated_lazy_message_extension_lite   , 1).bb());

  EXPECT_EQ(unittest::TestAllTypesLite::BAZ , message.GetExtension(unittest::repeated_nested_enum_extension_lite , 1));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAZ      , message.GetExtension(unittest::repeated_foreign_enum_extension_lite, 1));
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAZ, message.GetExtension(unittest::repeated_import_enum_extension_lite , 1));


  // -----------------------------------------------------------------

  EXPECT_TRUE(message.HasExtension(unittest::default_int32_extension_lite   ));
  EXPECT_TRUE(message.HasExtension(unittest::default_int64_extension_lite   ));
  EXPECT_TRUE(message.HasExtension(unittest::default_uint32_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::default_uint64_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::default_sint32_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::default_sint64_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::default_fixed32_extension_lite ));
  EXPECT_TRUE(message.HasExtension(unittest::default_fixed64_extension_lite ));
  EXPECT_TRUE(message.HasExtension(unittest::default_sfixed32_extension_lite));
  EXPECT_TRUE(message.HasExtension(unittest::default_sfixed64_extension_lite));
  EXPECT_TRUE(message.HasExtension(unittest::default_float_extension_lite   ));
  EXPECT_TRUE(message.HasExtension(unittest::default_double_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::default_bool_extension_lite    ));
  EXPECT_TRUE(message.HasExtension(unittest::default_string_extension_lite  ));
  EXPECT_TRUE(message.HasExtension(unittest::default_bytes_extension_lite   ));

  EXPECT_TRUE(message.HasExtension(unittest::default_nested_enum_extension_lite ));
  EXPECT_TRUE(message.HasExtension(unittest::default_foreign_enum_extension_lite));
  EXPECT_TRUE(message.HasExtension(unittest::default_import_enum_extension_lite ));


  EXPECT_EQ(401  , message.GetExtension(unittest::default_int32_extension_lite   ));
  EXPECT_EQ(402  , message.GetExtension(unittest::default_int64_extension_lite   ));
  EXPECT_EQ(403  , message.GetExtension(unittest::default_uint32_extension_lite  ));
  EXPECT_EQ(404  , message.GetExtension(unittest::default_uint64_extension_lite  ));
  EXPECT_EQ(405  , message.GetExtension(unittest::default_sint32_extension_lite  ));
  EXPECT_EQ(406  , message.GetExtension(unittest::default_sint64_extension_lite  ));
  EXPECT_EQ(407  , message.GetExtension(unittest::default_fixed32_extension_lite ));
  EXPECT_EQ(408  , message.GetExtension(unittest::default_fixed64_extension_lite ));
  EXPECT_EQ(409  , message.GetExtension(unittest::default_sfixed32_extension_lite));
  EXPECT_EQ(410  , message.GetExtension(unittest::default_sfixed64_extension_lite));
  EXPECT_EQ(411  , message.GetExtension(unittest::default_float_extension_lite   ));
  EXPECT_EQ(412  , message.GetExtension(unittest::default_double_extension_lite  ));
  EXPECT_EQ(false, message.GetExtension(unittest::default_bool_extension_lite    ));
  EXPECT_EQ("415", message.GetExtension(unittest::default_string_extension_lite  ));
  EXPECT_EQ("416", message.GetExtension(unittest::default_bytes_extension_lite   ));

  EXPECT_EQ(unittest::TestAllTypesLite::FOO , message.GetExtension(unittest::default_nested_enum_extension_lite ));
  EXPECT_EQ(unittest::FOREIGN_LITE_FOO      , message.GetExtension(unittest::default_foreign_enum_extension_lite));
  EXPECT_EQ(unittest_import::IMPORT_LITE_FOO, message.GetExtension(unittest::default_import_enum_extension_lite ));

}

// -------------------------------------------------------------------

void TestUtilLite::ExpectExtensionsClear(
    const unittest::TestAllExtensionsLite& message) {
  string serialized;
  ASSERT_TRUE(message.SerializeToString(&serialized));
  EXPECT_EQ("", serialized);
  EXPECT_EQ(0, message.ByteSize());

  // has_blah() should initially be false for all optional fields.
  EXPECT_FALSE(message.HasExtension(unittest::optional_int32_extension_lite   ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_int64_extension_lite   ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_uint32_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_uint64_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_sint32_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_sint64_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_fixed32_extension_lite ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_fixed64_extension_lite ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_sfixed32_extension_lite));
  EXPECT_FALSE(message.HasExtension(unittest::optional_sfixed64_extension_lite));
  EXPECT_FALSE(message.HasExtension(unittest::optional_float_extension_lite   ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_double_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_bool_extension_lite    ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_string_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_bytes_extension_lite   ));

  EXPECT_FALSE(message.HasExtension(unittest::optionalgroup_extension_lite                 ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_nested_message_extension_lite       ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_foreign_message_extension_lite      ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_import_message_extension_lite       ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_public_import_message_extension_lite));
  EXPECT_FALSE(message.HasExtension(unittest::optional_lazy_message_extension_lite         ));

  EXPECT_FALSE(message.HasExtension(unittest::optional_nested_enum_extension_lite ));
  EXPECT_FALSE(message.HasExtension(unittest::optional_foreign_enum_extension_lite));
  EXPECT_FALSE(message.HasExtension(unittest::optional_import_enum_extension_lite ));


  // Optional fields without defaults are set to zero or something like it.
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_int32_extension_lite   ));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_int64_extension_lite   ));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_uint32_extension_lite  ));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_uint64_extension_lite  ));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_sint32_extension_lite  ));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_sint64_extension_lite  ));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_fixed32_extension_lite ));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_fixed64_extension_lite ));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_sfixed32_extension_lite));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_sfixed64_extension_lite));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_float_extension_lite   ));
  EXPECT_EQ(0    , message.GetExtension(unittest::optional_double_extension_lite  ));
  EXPECT_EQ(false, message.GetExtension(unittest::optional_bool_extension_lite    ));
  EXPECT_EQ(""   , message.GetExtension(unittest::optional_string_extension_lite  ));
  EXPECT_EQ(""   , message.GetExtension(unittest::optional_bytes_extension_lite   ));

  // Embedded messages should also be clear.
  EXPECT_FALSE(message.GetExtension(unittest::optionalgroup_extension_lite                 ).has_a());
  EXPECT_FALSE(message.GetExtension(unittest::optional_nested_message_extension_lite       ).has_bb());
  EXPECT_FALSE(message.GetExtension(unittest::optional_foreign_message_extension_lite      ).has_c());
  EXPECT_FALSE(message.GetExtension(unittest::optional_import_message_extension_lite       ).has_d());
  EXPECT_FALSE(message.GetExtension(unittest::optional_public_import_message_extension_lite).has_e());
  EXPECT_FALSE(message.GetExtension(unittest::optional_lazy_message_extension_lite         ).has_bb());

  EXPECT_EQ(0, message.GetExtension(unittest::optionalgroup_extension_lite                 ).a());
  EXPECT_EQ(0, message.GetExtension(unittest::optional_nested_message_extension_lite       ).bb());
  EXPECT_EQ(0, message.GetExtension(unittest::optional_foreign_message_extension_lite      ).c());
  EXPECT_EQ(0, message.GetExtension(unittest::optional_import_message_extension_lite       ).d());
  EXPECT_EQ(0, message.GetExtension(unittest::optional_public_import_message_extension_lite).e());
  EXPECT_EQ(0, message.GetExtension(unittest::optional_lazy_message_extension_lite         ).bb());

  // Enums without defaults are set to the first value in the enum.
  EXPECT_EQ(unittest::TestAllTypesLite::FOO , message.GetExtension(unittest::optional_nested_enum_extension_lite ));
  EXPECT_EQ(unittest::FOREIGN_LITE_FOO      , message.GetExtension(unittest::optional_foreign_enum_extension_lite));
  EXPECT_EQ(unittest_import::IMPORT_LITE_FOO, message.GetExtension(unittest::optional_import_enum_extension_lite ));


  // Repeated fields are empty.
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_int32_extension_lite   ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_int64_extension_lite   ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_uint32_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_uint64_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_sint32_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_sint64_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_fixed32_extension_lite ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_fixed64_extension_lite ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_sfixed32_extension_lite));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_sfixed64_extension_lite));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_float_extension_lite   ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_double_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_bool_extension_lite    ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_string_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_bytes_extension_lite   ));

  EXPECT_EQ(0, message.ExtensionSize(unittest::repeatedgroup_extension_lite           ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_nested_message_extension_lite ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_foreign_message_extension_lite));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_import_message_extension_lite ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_lazy_message_extension_lite   ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_nested_enum_extension_lite    ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_foreign_enum_extension_lite   ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::repeated_import_enum_extension_lite    ));


  // has_blah() should also be false for all default fields.
  EXPECT_FALSE(message.HasExtension(unittest::default_int32_extension_lite   ));
  EXPECT_FALSE(message.HasExtension(unittest::default_int64_extension_lite   ));
  EXPECT_FALSE(message.HasExtension(unittest::default_uint32_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::default_uint64_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::default_sint32_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::default_sint64_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::default_fixed32_extension_lite ));
  EXPECT_FALSE(message.HasExtension(unittest::default_fixed64_extension_lite ));
  EXPECT_FALSE(message.HasExtension(unittest::default_sfixed32_extension_lite));
  EXPECT_FALSE(message.HasExtension(unittest::default_sfixed64_extension_lite));
  EXPECT_FALSE(message.HasExtension(unittest::default_float_extension_lite   ));
  EXPECT_FALSE(message.HasExtension(unittest::default_double_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::default_bool_extension_lite    ));
  EXPECT_FALSE(message.HasExtension(unittest::default_string_extension_lite  ));
  EXPECT_FALSE(message.HasExtension(unittest::default_bytes_extension_lite   ));

  EXPECT_FALSE(message.HasExtension(unittest::default_nested_enum_extension_lite ));
  EXPECT_FALSE(message.HasExtension(unittest::default_foreign_enum_extension_lite));
  EXPECT_FALSE(message.HasExtension(unittest::default_import_enum_extension_lite ));


  // Fields with defaults have their default values (duh).
  EXPECT_EQ( 41    , message.GetExtension(unittest::default_int32_extension_lite   ));
  EXPECT_EQ( 42    , message.GetExtension(unittest::default_int64_extension_lite   ));
  EXPECT_EQ( 43    , message.GetExtension(unittest::default_uint32_extension_lite  ));
  EXPECT_EQ( 44    , message.GetExtension(unittest::default_uint64_extension_lite  ));
  EXPECT_EQ(-45    , message.GetExtension(unittest::default_sint32_extension_lite  ));
  EXPECT_EQ( 46    , message.GetExtension(unittest::default_sint64_extension_lite  ));
  EXPECT_EQ( 47    , message.GetExtension(unittest::default_fixed32_extension_lite ));
  EXPECT_EQ( 48    , message.GetExtension(unittest::default_fixed64_extension_lite ));
  EXPECT_EQ( 49    , message.GetExtension(unittest::default_sfixed32_extension_lite));
  EXPECT_EQ(-50    , message.GetExtension(unittest::default_sfixed64_extension_lite));
  EXPECT_EQ( 51.5  , message.GetExtension(unittest::default_float_extension_lite   ));
  EXPECT_EQ( 52e3  , message.GetExtension(unittest::default_double_extension_lite  ));
  EXPECT_EQ(true   , message.GetExtension(unittest::default_bool_extension_lite    ));
  EXPECT_EQ("hello", message.GetExtension(unittest::default_string_extension_lite  ));
  EXPECT_EQ("world", message.GetExtension(unittest::default_bytes_extension_lite   ));

  EXPECT_EQ(unittest::TestAllTypesLite::BAR , message.GetExtension(unittest::default_nested_enum_extension_lite ));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR      , message.GetExtension(unittest::default_foreign_enum_extension_lite));
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAR, message.GetExtension(unittest::default_import_enum_extension_lite ));

}

// -------------------------------------------------------------------

void TestUtilLite::ExpectRepeatedExtensionsModified(
    const unittest::TestAllExtensionsLite& message) {
  // ModifyRepeatedFields only sets the second repeated element of each
  // field.  In addition to verifying this, we also verify that the first
  // element and size were *not* modified.
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_int32_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_int64_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_uint32_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_uint64_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_sint32_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_sint64_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_fixed32_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_fixed64_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_sfixed32_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_sfixed64_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_float_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_double_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_bool_extension_lite    ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_string_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_bytes_extension_lite   ));

  ASSERT_EQ(2, message.ExtensionSize(unittest::repeatedgroup_extension_lite           ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_nested_message_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_foreign_message_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_import_message_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_lazy_message_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_nested_enum_extension_lite    ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_foreign_enum_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::repeated_import_enum_extension_lite    ));


  EXPECT_EQ(201  , message.GetExtension(unittest::repeated_int32_extension_lite   , 0));
  EXPECT_EQ(202  , message.GetExtension(unittest::repeated_int64_extension_lite   , 0));
  EXPECT_EQ(203  , message.GetExtension(unittest::repeated_uint32_extension_lite  , 0));
  EXPECT_EQ(204  , message.GetExtension(unittest::repeated_uint64_extension_lite  , 0));
  EXPECT_EQ(205  , message.GetExtension(unittest::repeated_sint32_extension_lite  , 0));
  EXPECT_EQ(206  , message.GetExtension(unittest::repeated_sint64_extension_lite  , 0));
  EXPECT_EQ(207  , message.GetExtension(unittest::repeated_fixed32_extension_lite , 0));
  EXPECT_EQ(208  , message.GetExtension(unittest::repeated_fixed64_extension_lite , 0));
  EXPECT_EQ(209  , message.GetExtension(unittest::repeated_sfixed32_extension_lite, 0));
  EXPECT_EQ(210  , message.GetExtension(unittest::repeated_sfixed64_extension_lite, 0));
  EXPECT_EQ(211  , message.GetExtension(unittest::repeated_float_extension_lite   , 0));
  EXPECT_EQ(212  , message.GetExtension(unittest::repeated_double_extension_lite  , 0));
  EXPECT_EQ(true , message.GetExtension(unittest::repeated_bool_extension_lite    , 0));
  EXPECT_EQ("215", message.GetExtension(unittest::repeated_string_extension_lite  , 0));
  EXPECT_EQ("216", message.GetExtension(unittest::repeated_bytes_extension_lite   , 0));

  EXPECT_EQ(217, message.GetExtension(unittest::repeatedgroup_extension_lite           , 0).a());
  EXPECT_EQ(218, message.GetExtension(unittest::repeated_nested_message_extension_lite , 0).bb());
  EXPECT_EQ(219, message.GetExtension(unittest::repeated_foreign_message_extension_lite, 0).c());
  EXPECT_EQ(220, message.GetExtension(unittest::repeated_import_message_extension_lite , 0).d());
  EXPECT_EQ(227, message.GetExtension(unittest::repeated_lazy_message_extension_lite   , 0).bb());

  EXPECT_EQ(unittest::TestAllTypesLite::BAR , message.GetExtension(unittest::repeated_nested_enum_extension_lite , 0));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR      , message.GetExtension(unittest::repeated_foreign_enum_extension_lite, 0));
  EXPECT_EQ(unittest_import::IMPORT_LITE_BAR, message.GetExtension(unittest::repeated_import_enum_extension_lite , 0));


  // Actually verify the second (modified) elements now.
  EXPECT_EQ(501  , message.GetExtension(unittest::repeated_int32_extension_lite   , 1));
  EXPECT_EQ(502  , message.GetExtension(unittest::repeated_int64_extension_lite   , 1));
  EXPECT_EQ(503  , message.GetExtension(unittest::repeated_uint32_extension_lite  , 1));
  EXPECT_EQ(504  , message.GetExtension(unittest::repeated_uint64_extension_lite  , 1));
  EXPECT_EQ(505  , message.GetExtension(unittest::repeated_sint32_extension_lite  , 1));
  EXPECT_EQ(506  , message.GetExtension(unittest::repeated_sint64_extension_lite  , 1));
  EXPECT_EQ(507  , message.GetExtension(unittest::repeated_fixed32_extension_lite , 1));
  EXPECT_EQ(508  , message.GetExtension(unittest::repeated_fixed64_extension_lite , 1));
  EXPECT_EQ(509  , message.GetExtension(unittest::repeated_sfixed32_extension_lite, 1));
  EXPECT_EQ(510  , message.GetExtension(unittest::repeated_sfixed64_extension_lite, 1));
  EXPECT_EQ(511  , message.GetExtension(unittest::repeated_float_extension_lite   , 1));
  EXPECT_EQ(512  , message.GetExtension(unittest::repeated_double_extension_lite  , 1));
  EXPECT_EQ(true , message.GetExtension(unittest::repeated_bool_extension_lite    , 1));
  EXPECT_EQ("515", message.GetExtension(unittest::repeated_string_extension_lite  , 1));
  EXPECT_EQ("516", message.GetExtension(unittest::repeated_bytes_extension_lite   , 1));

  EXPECT_EQ(517, message.GetExtension(unittest::repeatedgroup_extension_lite           , 1).a());
  EXPECT_EQ(518, message.GetExtension(unittest::repeated_nested_message_extension_lite , 1).bb());
  EXPECT_EQ(519, message.GetExtension(unittest::repeated_foreign_message_extension_lite, 1).c());
  EXPECT_EQ(520, message.GetExtension(unittest::repeated_import_message_extension_lite , 1).d());
  EXPECT_EQ(527, message.GetExtension(unittest::repeated_lazy_message_extension_lite   , 1).bb());

  EXPECT_EQ(unittest::TestAllTypesLite::FOO , message.GetExtension(unittest::repeated_nested_enum_extension_lite , 1));
  EXPECT_EQ(unittest::FOREIGN_LITE_FOO      , message.GetExtension(unittest::repeated_foreign_enum_extension_lite, 1));
  EXPECT_EQ(unittest_import::IMPORT_LITE_FOO, message.GetExtension(unittest::repeated_import_enum_extension_lite , 1));

}

// -------------------------------------------------------------------

void TestUtilLite::SetPackedExtensions(
    unittest::TestPackedExtensionsLite* message) {
  message->AddExtension(unittest::packed_int32_extension_lite   , 601);
  message->AddExtension(unittest::packed_int64_extension_lite   , 602);
  message->AddExtension(unittest::packed_uint32_extension_lite  , 603);
  message->AddExtension(unittest::packed_uint64_extension_lite  , 604);
  message->AddExtension(unittest::packed_sint32_extension_lite  , 605);
  message->AddExtension(unittest::packed_sint64_extension_lite  , 606);
  message->AddExtension(unittest::packed_fixed32_extension_lite , 607);
  message->AddExtension(unittest::packed_fixed64_extension_lite , 608);
  message->AddExtension(unittest::packed_sfixed32_extension_lite, 609);
  message->AddExtension(unittest::packed_sfixed64_extension_lite, 610);
  message->AddExtension(unittest::packed_float_extension_lite   , 611);
  message->AddExtension(unittest::packed_double_extension_lite  , 612);
  message->AddExtension(unittest::packed_bool_extension_lite    , true);
  message->AddExtension(unittest::packed_enum_extension_lite, unittest::FOREIGN_LITE_BAR);
  // add a second one of each field
  message->AddExtension(unittest::packed_int32_extension_lite   , 701);
  message->AddExtension(unittest::packed_int64_extension_lite   , 702);
  message->AddExtension(unittest::packed_uint32_extension_lite  , 703);
  message->AddExtension(unittest::packed_uint64_extension_lite  , 704);
  message->AddExtension(unittest::packed_sint32_extension_lite  , 705);
  message->AddExtension(unittest::packed_sint64_extension_lite  , 706);
  message->AddExtension(unittest::packed_fixed32_extension_lite , 707);
  message->AddExtension(unittest::packed_fixed64_extension_lite , 708);
  message->AddExtension(unittest::packed_sfixed32_extension_lite, 709);
  message->AddExtension(unittest::packed_sfixed64_extension_lite, 710);
  message->AddExtension(unittest::packed_float_extension_lite   , 711);
  message->AddExtension(unittest::packed_double_extension_lite  , 712);
  message->AddExtension(unittest::packed_bool_extension_lite    , false);
  message->AddExtension(unittest::packed_enum_extension_lite, unittest::FOREIGN_LITE_BAZ);
}

// -------------------------------------------------------------------

void TestUtilLite::ModifyPackedExtensions(
    unittest::TestPackedExtensionsLite* message) {
  message->SetExtension(unittest::packed_int32_extension_lite   , 1, 801);
  message->SetExtension(unittest::packed_int64_extension_lite   , 1, 802);
  message->SetExtension(unittest::packed_uint32_extension_lite  , 1, 803);
  message->SetExtension(unittest::packed_uint64_extension_lite  , 1, 804);
  message->SetExtension(unittest::packed_sint32_extension_lite  , 1, 805);
  message->SetExtension(unittest::packed_sint64_extension_lite  , 1, 806);
  message->SetExtension(unittest::packed_fixed32_extension_lite , 1, 807);
  message->SetExtension(unittest::packed_fixed64_extension_lite , 1, 808);
  message->SetExtension(unittest::packed_sfixed32_extension_lite, 1, 809);
  message->SetExtension(unittest::packed_sfixed64_extension_lite, 1, 810);
  message->SetExtension(unittest::packed_float_extension_lite   , 1, 811);
  message->SetExtension(unittest::packed_double_extension_lite  , 1, 812);
  message->SetExtension(unittest::packed_bool_extension_lite    , 1, true);
  message->SetExtension(unittest::packed_enum_extension_lite    , 1,
                        unittest::FOREIGN_LITE_FOO);
}

// -------------------------------------------------------------------

void TestUtilLite::ExpectPackedExtensionsSet(
    const unittest::TestPackedExtensionsLite& message) {
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_int32_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_int64_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_uint32_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_uint64_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_sint32_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_sint64_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_fixed32_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_fixed64_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_sfixed32_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_sfixed64_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_float_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_double_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_bool_extension_lite    ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_enum_extension_lite    ));

  EXPECT_EQ(601  , message.GetExtension(unittest::packed_int32_extension_lite   , 0));
  EXPECT_EQ(602  , message.GetExtension(unittest::packed_int64_extension_lite   , 0));
  EXPECT_EQ(603  , message.GetExtension(unittest::packed_uint32_extension_lite  , 0));
  EXPECT_EQ(604  , message.GetExtension(unittest::packed_uint64_extension_lite  , 0));
  EXPECT_EQ(605  , message.GetExtension(unittest::packed_sint32_extension_lite  , 0));
  EXPECT_EQ(606  , message.GetExtension(unittest::packed_sint64_extension_lite  , 0));
  EXPECT_EQ(607  , message.GetExtension(unittest::packed_fixed32_extension_lite , 0));
  EXPECT_EQ(608  , message.GetExtension(unittest::packed_fixed64_extension_lite , 0));
  EXPECT_EQ(609  , message.GetExtension(unittest::packed_sfixed32_extension_lite, 0));
  EXPECT_EQ(610  , message.GetExtension(unittest::packed_sfixed64_extension_lite, 0));
  EXPECT_EQ(611  , message.GetExtension(unittest::packed_float_extension_lite   , 0));
  EXPECT_EQ(612  , message.GetExtension(unittest::packed_double_extension_lite  , 0));
  EXPECT_EQ(true , message.GetExtension(unittest::packed_bool_extension_lite    , 0));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR,
            message.GetExtension(unittest::packed_enum_extension_lite, 0));
  EXPECT_EQ(701  , message.GetExtension(unittest::packed_int32_extension_lite   , 1));
  EXPECT_EQ(702  , message.GetExtension(unittest::packed_int64_extension_lite   , 1));
  EXPECT_EQ(703  , message.GetExtension(unittest::packed_uint32_extension_lite  , 1));
  EXPECT_EQ(704  , message.GetExtension(unittest::packed_uint64_extension_lite  , 1));
  EXPECT_EQ(705  , message.GetExtension(unittest::packed_sint32_extension_lite  , 1));
  EXPECT_EQ(706  , message.GetExtension(unittest::packed_sint64_extension_lite  , 1));
  EXPECT_EQ(707  , message.GetExtension(unittest::packed_fixed32_extension_lite , 1));
  EXPECT_EQ(708  , message.GetExtension(unittest::packed_fixed64_extension_lite , 1));
  EXPECT_EQ(709  , message.GetExtension(unittest::packed_sfixed32_extension_lite, 1));
  EXPECT_EQ(710  , message.GetExtension(unittest::packed_sfixed64_extension_lite, 1));
  EXPECT_EQ(711  , message.GetExtension(unittest::packed_float_extension_lite   , 1));
  EXPECT_EQ(712  , message.GetExtension(unittest::packed_double_extension_lite  , 1));
  EXPECT_EQ(false, message.GetExtension(unittest::packed_bool_extension_lite    , 1));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAZ,
            message.GetExtension(unittest::packed_enum_extension_lite, 1));
}

// -------------------------------------------------------------------

void TestUtilLite::ExpectPackedExtensionsClear(
    const unittest::TestPackedExtensionsLite& message) {
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_int32_extension_lite   ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_int64_extension_lite   ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_uint32_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_uint64_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_sint32_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_sint64_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_fixed32_extension_lite ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_fixed64_extension_lite ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_sfixed32_extension_lite));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_sfixed64_extension_lite));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_float_extension_lite   ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_double_extension_lite  ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_bool_extension_lite    ));
  EXPECT_EQ(0, message.ExtensionSize(unittest::packed_enum_extension_lite    ));
}

// -------------------------------------------------------------------

void TestUtilLite::ExpectPackedExtensionsModified(
    const unittest::TestPackedExtensionsLite& message) {
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_int32_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_int64_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_uint32_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_uint64_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_sint32_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_sint64_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_fixed32_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_fixed64_extension_lite ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_sfixed32_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_sfixed64_extension_lite));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_float_extension_lite   ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_double_extension_lite  ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_bool_extension_lite    ));
  ASSERT_EQ(2, message.ExtensionSize(unittest::packed_enum_extension_lite    ));
  EXPECT_EQ(601  , message.GetExtension(unittest::packed_int32_extension_lite   , 0));
  EXPECT_EQ(602  , message.GetExtension(unittest::packed_int64_extension_lite   , 0));
  EXPECT_EQ(603  , message.GetExtension(unittest::packed_uint32_extension_lite  , 0));
  EXPECT_EQ(604  , message.GetExtension(unittest::packed_uint64_extension_lite  , 0));
  EXPECT_EQ(605  , message.GetExtension(unittest::packed_sint32_extension_lite  , 0));
  EXPECT_EQ(606  , message.GetExtension(unittest::packed_sint64_extension_lite  , 0));
  EXPECT_EQ(607  , message.GetExtension(unittest::packed_fixed32_extension_lite , 0));
  EXPECT_EQ(608  , message.GetExtension(unittest::packed_fixed64_extension_lite , 0));
  EXPECT_EQ(609  , message.GetExtension(unittest::packed_sfixed32_extension_lite, 0));
  EXPECT_EQ(610  , message.GetExtension(unittest::packed_sfixed64_extension_lite, 0));
  EXPECT_EQ(611  , message.GetExtension(unittest::packed_float_extension_lite   , 0));
  EXPECT_EQ(612  , message.GetExtension(unittest::packed_double_extension_lite  , 0));
  EXPECT_EQ(true , message.GetExtension(unittest::packed_bool_extension_lite    , 0));
  EXPECT_EQ(unittest::FOREIGN_LITE_BAR,
            message.GetExtension(unittest::packed_enum_extension_lite, 0));

  // Actually verify the second (modified) elements now.
  EXPECT_EQ(801  , message.GetExtension(unittest::packed_int32_extension_lite   , 1));
  EXPECT_EQ(802  , message.GetExtension(unittest::packed_int64_extension_lite   , 1));
  EXPECT_EQ(803  , message.GetExtension(unittest::packed_uint32_extension_lite  , 1));
  EXPECT_EQ(804  , message.GetExtension(unittest::packed_uint64_extension_lite  , 1));
  EXPECT_EQ(805  , message.GetExtension(unittest::packed_sint32_extension_lite  , 1));
  EXPECT_EQ(806  , message.GetExtension(unittest::packed_sint64_extension_lite  , 1));
  EXPECT_EQ(807  , message.GetExtension(unittest::packed_fixed32_extension_lite , 1));
  EXPECT_EQ(808  , message.GetExtension(unittest::packed_fixed64_extension_lite , 1));
  EXPECT_EQ(809  , message.GetExtension(unittest::packed_sfixed32_extension_lite, 1));
  EXPECT_EQ(810  , message.GetExtension(unittest::packed_sfixed64_extension_lite, 1));
  EXPECT_EQ(811  , message.GetExtension(unittest::packed_float_extension_lite   , 1));
  EXPECT_EQ(812  , message.GetExtension(unittest::packed_double_extension_lite  , 1));
  EXPECT_EQ(true , message.GetExtension(unittest::packed_bool_extension_lite    , 1));
  EXPECT_EQ(unittest::FOREIGN_LITE_FOO,
            message.GetExtension(unittest::packed_enum_extension_lite, 1));
}

}  // namespace protobuf
}  // namespace google

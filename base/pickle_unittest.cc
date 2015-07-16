// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/pickle.h"
#include "base/strings/string16.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

const bool testbool1 = false;
const bool testbool2 = true;
const int testint = 2093847192;
const long testlong = 1093847192;
const uint16 testuint16 = 32123;
const uint32 testuint32 = 1593847192;
const int64 testint64 = -0x7E8CA9253104BDFCLL;
const uint64 testuint64 = 0xCE8CA9253104BDF7ULL;
const size_t testsizet = 0xFEDC7654;
const float testfloat = 3.1415926935f;
const double testdouble = 2.71828182845904523;
const std::string teststring("Hello world");  // note non-aligned string length
const std::wstring testwstring(L"Hello, world");
const string16 teststring16(ASCIIToUTF16("Hello, world"));
const char testrawstring[] = "Hello new world"; // Test raw string writing
// Test raw char16 writing, assumes UTF16 encoding is ANSI for alpha chars.
const char16 testrawstring16[] = {'A', 'l', 'o', 'h', 'a', 0};
const char testdata[] = "AAA\0BBB\0";
const int testdatalen = arraysize(testdata) - 1;

// checks that the results can be read correctly from the Pickle
void VerifyResult(const Pickle& pickle) {
  PickleIterator iter(pickle);

  bool outbool;
  EXPECT_TRUE(iter.ReadBool(&outbool));
  EXPECT_FALSE(outbool);
  EXPECT_TRUE(iter.ReadBool(&outbool));
  EXPECT_TRUE(outbool);

  int outint;
  EXPECT_TRUE(iter.ReadInt(&outint));
  EXPECT_EQ(testint, outint);

  long outlong;
  EXPECT_TRUE(iter.ReadLong(&outlong));
  EXPECT_EQ(testlong, outlong);

  uint16 outuint16;
  EXPECT_TRUE(iter.ReadUInt16(&outuint16));
  EXPECT_EQ(testuint16, outuint16);

  uint32 outuint32;
  EXPECT_TRUE(iter.ReadUInt32(&outuint32));
  EXPECT_EQ(testuint32, outuint32);

  int64 outint64;
  EXPECT_TRUE(iter.ReadInt64(&outint64));
  EXPECT_EQ(testint64, outint64);

  uint64 outuint64;
  EXPECT_TRUE(iter.ReadUInt64(&outuint64));
  EXPECT_EQ(testuint64, outuint64);

  size_t outsizet;
  EXPECT_TRUE(iter.ReadSizeT(&outsizet));
  EXPECT_EQ(testsizet, outsizet);

  float outfloat;
  EXPECT_TRUE(iter.ReadFloat(&outfloat));
  EXPECT_EQ(testfloat, outfloat);

  double outdouble;
  EXPECT_TRUE(iter.ReadDouble(&outdouble));
  EXPECT_EQ(testdouble, outdouble);

  std::string outstring;
  EXPECT_TRUE(iter.ReadString(&outstring));
  EXPECT_EQ(teststring, outstring);

  string16 outstring16;
  EXPECT_TRUE(iter.ReadString16(&outstring16));
  EXPECT_EQ(teststring16, outstring16);

  StringPiece outstringpiece;
  EXPECT_TRUE(iter.ReadStringPiece(&outstringpiece));
  EXPECT_EQ(testrawstring, outstringpiece);

  StringPiece16 outstringpiece16;
  EXPECT_TRUE(iter.ReadStringPiece16(&outstringpiece16));
  EXPECT_EQ(testrawstring16, outstringpiece16);

  const char* outdata;
  int outdatalen;
  EXPECT_TRUE(iter.ReadData(&outdata, &outdatalen));
  EXPECT_EQ(testdatalen, outdatalen);
  EXPECT_EQ(memcmp(testdata, outdata, outdatalen), 0);

  // reads past the end should fail
  EXPECT_FALSE(iter.ReadInt(&outint));
}

}  // namespace

TEST(PickleTest, EncodeDecode) {
  Pickle pickle;

  EXPECT_TRUE(pickle.WriteBool(testbool1));
  EXPECT_TRUE(pickle.WriteBool(testbool2));
  EXPECT_TRUE(pickle.WriteInt(testint));
  EXPECT_TRUE(
      pickle.WriteLongUsingDangerousNonPortableLessPersistableForm(testlong));
  EXPECT_TRUE(pickle.WriteUInt16(testuint16));
  EXPECT_TRUE(pickle.WriteUInt32(testuint32));
  EXPECT_TRUE(pickle.WriteInt64(testint64));
  EXPECT_TRUE(pickle.WriteUInt64(testuint64));
  EXPECT_TRUE(pickle.WriteSizeT(testsizet));
  EXPECT_TRUE(pickle.WriteFloat(testfloat));
  EXPECT_TRUE(pickle.WriteDouble(testdouble));
  EXPECT_TRUE(pickle.WriteString(teststring));
  EXPECT_TRUE(pickle.WriteString16(teststring16));
  EXPECT_TRUE(pickle.WriteString(testrawstring));
  EXPECT_TRUE(pickle.WriteString16(testrawstring16));
  EXPECT_TRUE(pickle.WriteData(testdata, testdatalen));
  VerifyResult(pickle);

  // test copy constructor
  Pickle pickle2(pickle);
  VerifyResult(pickle2);

  // test operator=
  Pickle pickle3;
  pickle3 = pickle;
  VerifyResult(pickle3);
}

// Tests that reading/writing a size_t works correctly when the source process
// is 64-bit.  We rely on having both 32- and 64-bit trybots to validate both
// arms of the conditional in this test.
TEST(PickleTest, SizeTFrom64Bit) {
  Pickle pickle;
  // Under the hood size_t is always written as a 64-bit value, so simulate a
  // 64-bit size_t even on 32-bit architectures by explicitly writing a uint64.
  EXPECT_TRUE(pickle.WriteUInt64(testuint64));

  PickleIterator iter(pickle);
  size_t outsizet;
  if (sizeof(size_t) < sizeof(uint64)) {
    // ReadSizeT() should return false when the original written value can't be
    // represented as a size_t.
    EXPECT_FALSE(iter.ReadSizeT(&outsizet));
  } else {
    EXPECT_TRUE(iter.ReadSizeT(&outsizet));
    EXPECT_EQ(testuint64, outsizet);
  }
}

// Tests that we can handle really small buffers.
TEST(PickleTest, SmallBuffer) {
  scoped_ptr<char[]> buffer(new char[1]);

  // We should not touch the buffer.
  Pickle pickle(buffer.get(), 1);

  PickleIterator iter(pickle);
  int data;
  EXPECT_FALSE(iter.ReadInt(&data));
}

// Tests that we can handle improper headers.
TEST(PickleTest, BigSize) {
  int buffer[] = { 0x56035200, 25, 40, 50 };

  Pickle pickle(reinterpret_cast<char*>(buffer), sizeof(buffer));

  PickleIterator iter(pickle);
  int data;
  EXPECT_FALSE(iter.ReadInt(&data));
}

TEST(PickleTest, UnalignedSize) {
  int buffer[] = { 10, 25, 40, 50 };

  Pickle pickle(reinterpret_cast<char*>(buffer), sizeof(buffer));

  PickleIterator iter(pickle);
  int data;
  EXPECT_FALSE(iter.ReadInt(&data));
}

TEST(PickleTest, ZeroLenStr) {
  Pickle pickle;
  EXPECT_TRUE(pickle.WriteString(std::string()));

  PickleIterator iter(pickle);
  std::string outstr;
  EXPECT_TRUE(iter.ReadString(&outstr));
  EXPECT_EQ("", outstr);
}

TEST(PickleTest, ZeroLenStr16) {
  Pickle pickle;
  EXPECT_TRUE(pickle.WriteString16(string16()));

  PickleIterator iter(pickle);
  std::string outstr;
  EXPECT_TRUE(iter.ReadString(&outstr));
  EXPECT_EQ("", outstr);
}

TEST(PickleTest, BadLenStr) {
  Pickle pickle;
  EXPECT_TRUE(pickle.WriteInt(-2));

  PickleIterator iter(pickle);
  std::string outstr;
  EXPECT_FALSE(iter.ReadString(&outstr));
}

TEST(PickleTest, BadLenStr16) {
  Pickle pickle;
  EXPECT_TRUE(pickle.WriteInt(-1));

  PickleIterator iter(pickle);
  string16 outstr;
  EXPECT_FALSE(iter.ReadString16(&outstr));
}

TEST(PickleTest, FindNext) {
  Pickle pickle;
  EXPECT_TRUE(pickle.WriteInt(1));
  EXPECT_TRUE(pickle.WriteString("Domo"));

  const char* start = reinterpret_cast<const char*>(pickle.data());
  const char* end = start + pickle.size();

  EXPECT_TRUE(end == Pickle::FindNext(pickle.header_size_, start, end));
  EXPECT_TRUE(NULL == Pickle::FindNext(pickle.header_size_, start, end - 1));
  EXPECT_TRUE(end == Pickle::FindNext(pickle.header_size_, start, end + 1));
}

TEST(PickleTest, FindNextWithIncompleteHeader) {
  size_t header_size = sizeof(Pickle::Header);
  scoped_ptr<char[]> buffer(new char[header_size - 1]);
  memset(buffer.get(), 0x1, header_size - 1);

  const char* start = buffer.get();
  const char* end = start + header_size - 1;

  EXPECT_TRUE(NULL == Pickle::FindNext(header_size, start, end));
}

#if defined(COMPILER_MSVC)
#pragma warning(push)
#pragma warning(disable: 4146)
#endif
TEST(PickleTest, FindNextOverflow) {
  size_t header_size = sizeof(Pickle::Header);
  size_t header_size2 = 2 * header_size;
  size_t payload_received = 100;
  scoped_ptr<char[]> buffer(new char[header_size2 + payload_received]);
  const char* start = buffer.get();
  Pickle::Header* header = reinterpret_cast<Pickle::Header*>(buffer.get());
  const char* end = start + header_size2 + payload_received;
  // It is impossible to construct an overflow test otherwise.
  if (sizeof(size_t) > sizeof(header->payload_size) ||
      sizeof(uintptr_t) > sizeof(header->payload_size))
    return;

  header->payload_size = -(reinterpret_cast<uintptr_t>(start) + header_size2);
  EXPECT_TRUE(NULL == Pickle::FindNext(header_size2, start, end));

  header->payload_size = -header_size2;
  EXPECT_TRUE(NULL == Pickle::FindNext(header_size2, start, end));

  header->payload_size = 0;
  end = start + header_size;
  EXPECT_TRUE(NULL == Pickle::FindNext(header_size2, start, end));
}
#if defined(COMPILER_MSVC)
#pragma warning(pop)
#endif

TEST(PickleTest, GetReadPointerAndAdvance) {
  Pickle pickle;

  PickleIterator iter(pickle);
  EXPECT_FALSE(iter.GetReadPointerAndAdvance(1));

  EXPECT_TRUE(pickle.WriteInt(1));
  EXPECT_TRUE(pickle.WriteInt(2));
  int bytes = sizeof(int) * 2;

  EXPECT_TRUE(PickleIterator(pickle).GetReadPointerAndAdvance(0));
  EXPECT_TRUE(PickleIterator(pickle).GetReadPointerAndAdvance(1));
  EXPECT_FALSE(PickleIterator(pickle).GetReadPointerAndAdvance(-1));
  EXPECT_TRUE(PickleIterator(pickle).GetReadPointerAndAdvance(bytes));
  EXPECT_FALSE(PickleIterator(pickle).GetReadPointerAndAdvance(bytes + 1));
  EXPECT_FALSE(PickleIterator(pickle).GetReadPointerAndAdvance(INT_MAX));
  EXPECT_FALSE(PickleIterator(pickle).GetReadPointerAndAdvance(INT_MIN));
}

TEST(PickleTest, Resize) {
  size_t unit = Pickle::kPayloadUnit;
  scoped_ptr<char[]> data(new char[unit]);
  char* data_ptr = data.get();
  for (size_t i = 0; i < unit; i++)
    data_ptr[i] = 'G';

  // construct a message that will be exactly the size of one payload unit,
  // note that any data will have a 4-byte header indicating the size
  const size_t payload_size_after_header = unit - sizeof(uint32);
  Pickle pickle;
  pickle.WriteData(data_ptr,
      static_cast<int>(payload_size_after_header - sizeof(uint32)));
  size_t cur_payload = payload_size_after_header;

  // note: we assume 'unit' is a power of 2
  EXPECT_EQ(unit, pickle.capacity_after_header());
  EXPECT_EQ(pickle.payload_size(), payload_size_after_header);

  // fill out a full page (noting data header)
  pickle.WriteData(data_ptr, static_cast<int>(unit - sizeof(uint32)));
  cur_payload += unit;
  EXPECT_EQ(unit * 2, pickle.capacity_after_header());
  EXPECT_EQ(cur_payload, pickle.payload_size());

  // one more byte should double the capacity
  pickle.WriteData(data_ptr, 1);
  cur_payload += 8;
  EXPECT_EQ(unit * 4, pickle.capacity_after_header());
  EXPECT_EQ(cur_payload, pickle.payload_size());
}

namespace {

struct CustomHeader : Pickle::Header {
  int blah;
};

}  // namespace

TEST(PickleTest, HeaderPadding) {
  const uint32 kMagic = 0x12345678;

  Pickle pickle(sizeof(CustomHeader));
  pickle.WriteInt(kMagic);

  // this should not overwrite the 'int' payload
  pickle.headerT<CustomHeader>()->blah = 10;

  PickleIterator iter(pickle);
  int result;
  ASSERT_TRUE(iter.ReadInt(&result));

  EXPECT_EQ(static_cast<uint32>(result), kMagic);
}

TEST(PickleTest, EqualsOperator) {
  Pickle source;
  source.WriteInt(1);

  Pickle copy_refs_source_buffer(static_cast<const char*>(source.data()),
                                 source.size());
  Pickle copy;
  copy = copy_refs_source_buffer;
  ASSERT_EQ(source.size(), copy.size());
}

TEST(PickleTest, EvilLengths) {
  Pickle source;
  std::string str(100000, 'A');
  EXPECT_TRUE(source.WriteData(str.c_str(), 100000));
  // ReadString16 used to have its read buffer length calculation wrong leading
  // to out-of-bounds reading.
  PickleIterator iter(source);
  string16 str16;
  EXPECT_FALSE(iter.ReadString16(&str16));

  // And check we didn't break ReadString16.
  str16 = (wchar_t) 'A';
  Pickle str16_pickle;
  EXPECT_TRUE(str16_pickle.WriteString16(str16));
  iter = PickleIterator(str16_pickle);
  EXPECT_TRUE(iter.ReadString16(&str16));
  EXPECT_EQ(1U, str16.length());

  // Check we don't fail in a length check with invalid String16 size.
  // (1<<31) * sizeof(char16) == 0, so this is particularly evil.
  Pickle bad_len;
  EXPECT_TRUE(bad_len.WriteInt(1 << 31));
  iter = PickleIterator(bad_len);
  EXPECT_FALSE(iter.ReadString16(&str16));
}

// Check we can write zero bytes of data and 'data' can be NULL.
TEST(PickleTest, ZeroLength) {
  Pickle pickle;
  EXPECT_TRUE(pickle.WriteData(NULL, 0));

  PickleIterator iter(pickle);
  const char* outdata;
  int outdatalen;
  EXPECT_TRUE(iter.ReadData(&outdata, &outdatalen));
  EXPECT_EQ(0, outdatalen);
  // We can't assert that outdata is NULL.
}

// Check that ReadBytes works properly with an iterator initialized to NULL.
TEST(PickleTest, ReadBytes) {
  Pickle pickle;
  int data = 0x7abcd;
  EXPECT_TRUE(pickle.WriteBytes(&data, sizeof(data)));

  PickleIterator iter(pickle);
  const char* outdata_char = NULL;
  EXPECT_TRUE(iter.ReadBytes(&outdata_char, sizeof(data)));

  int outdata;
  memcpy(&outdata, outdata_char, sizeof(outdata));
  EXPECT_EQ(data, outdata);
}

}  // namespace base

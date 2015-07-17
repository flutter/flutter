// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/pickle.h"

#include <stdlib.h>

#include <algorithm>  // for max()

namespace base {

// static
const int Pickle::kPayloadUnit = 64;

static const size_t kCapacityReadOnly = static_cast<size_t>(-1);

PickleIterator::PickleIterator(const Pickle& pickle)
    : payload_(pickle.payload()),
      read_index_(0),
      end_index_(pickle.payload_size()) {
}

template <typename Type>
inline bool PickleIterator::ReadBuiltinType(Type* result) {
  const char* read_from = GetReadPointerAndAdvance<Type>();
  if (!read_from)
    return false;
  if (sizeof(Type) > sizeof(uint32))
    memcpy(result, read_from, sizeof(*result));
  else
    *result = *reinterpret_cast<const Type*>(read_from);
  return true;
}

inline void PickleIterator::Advance(size_t size) {
  size_t aligned_size = AlignInt(size, sizeof(uint32_t));
  if (end_index_ - read_index_ < aligned_size) {
    read_index_ = end_index_;
  } else {
    read_index_ += aligned_size;
  }
}

template<typename Type>
inline const char* PickleIterator::GetReadPointerAndAdvance() {
  if (sizeof(Type) > end_index_ - read_index_) {
    read_index_ = end_index_;
    return NULL;
  }
  const char* current_read_ptr = payload_ + read_index_;
  Advance(sizeof(Type));
  return current_read_ptr;
}

const char* PickleIterator::GetReadPointerAndAdvance(int num_bytes) {
  if (num_bytes < 0 ||
      end_index_ - read_index_ < static_cast<size_t>(num_bytes)) {
    read_index_ = end_index_;
    return NULL;
  }
  const char* current_read_ptr = payload_ + read_index_;
  Advance(num_bytes);
  return current_read_ptr;
}

inline const char* PickleIterator::GetReadPointerAndAdvance(
    int num_elements,
    size_t size_element) {
  // Check for int32 overflow.
  int64 num_bytes = static_cast<int64>(num_elements) * size_element;
  int num_bytes32 = static_cast<int>(num_bytes);
  if (num_bytes != static_cast<int64>(num_bytes32))
    return NULL;
  return GetReadPointerAndAdvance(num_bytes32);
}

bool PickleIterator::ReadBool(bool* result) {
  return ReadBuiltinType(result);
}

bool PickleIterator::ReadInt(int* result) {
  return ReadBuiltinType(result);
}

bool PickleIterator::ReadLong(long* result) {
  return ReadBuiltinType(result);
}

bool PickleIterator::ReadUInt16(uint16* result) {
  return ReadBuiltinType(result);
}

bool PickleIterator::ReadUInt32(uint32* result) {
  return ReadBuiltinType(result);
}

bool PickleIterator::ReadInt64(int64* result) {
  return ReadBuiltinType(result);
}

bool PickleIterator::ReadUInt64(uint64* result) {
  return ReadBuiltinType(result);
}

bool PickleIterator::ReadSizeT(size_t* result) {
  // Always read size_t as a 64-bit value to ensure compatibility between 32-bit
  // and 64-bit processes.
  uint64 result_uint64 = 0;
  bool success = ReadBuiltinType(&result_uint64);
  *result = static_cast<size_t>(result_uint64);
  // Fail if the cast above truncates the value.
  return success && (*result == result_uint64);
}

bool PickleIterator::ReadFloat(float* result) {
  // crbug.com/315213
  // The source data may not be properly aligned, and unaligned float reads
  // cause SIGBUS on some ARM platforms, so force using memcpy to copy the data
  // into the result.
  const char* read_from = GetReadPointerAndAdvance<float>();
  if (!read_from)
    return false;
  memcpy(result, read_from, sizeof(*result));
  return true;
}

bool PickleIterator::ReadDouble(double* result) {
  // crbug.com/315213
  // The source data may not be properly aligned, and unaligned double reads
  // cause SIGBUS on some ARM platforms, so force using memcpy to copy the data
  // into the result.
  const char* read_from = GetReadPointerAndAdvance<double>();
  if (!read_from)
    return false;
  memcpy(result, read_from, sizeof(*result));
  return true;
}

bool PickleIterator::ReadString(std::string* result) {
  int len;
  if (!ReadInt(&len))
    return false;
  const char* read_from = GetReadPointerAndAdvance(len);
  if (!read_from)
    return false;

  result->assign(read_from, len);
  return true;
}

bool PickleIterator::ReadStringPiece(StringPiece* result) {
  int len;
  if (!ReadInt(&len))
    return false;
  const char* read_from = GetReadPointerAndAdvance(len);
  if (!read_from)
    return false;

  *result = StringPiece(read_from, len);
  return true;
}

bool PickleIterator::ReadString16(string16* result) {
  int len;
  if (!ReadInt(&len))
    return false;
  const char* read_from = GetReadPointerAndAdvance(len, sizeof(char16));
  if (!read_from)
    return false;

  result->assign(reinterpret_cast<const char16*>(read_from), len);
  return true;
}

bool PickleIterator::ReadStringPiece16(StringPiece16* result) {
  int len;
  if (!ReadInt(&len))
    return false;
  const char* read_from = GetReadPointerAndAdvance(len, sizeof(char16));
  if (!read_from)
    return false;

  *result = StringPiece16(reinterpret_cast<const char16*>(read_from), len);
  return true;
}

bool PickleIterator::ReadData(const char** data, int* length) {
  *length = 0;
  *data = 0;

  if (!ReadInt(length))
    return false;

  return ReadBytes(data, *length);
}

bool PickleIterator::ReadBytes(const char** data, int length) {
  const char* read_from = GetReadPointerAndAdvance(length);
  if (!read_from)
    return false;
  *data = read_from;
  return true;
}

// Payload is uint32 aligned.

Pickle::Pickle()
    : header_(NULL),
      header_size_(sizeof(Header)),
      capacity_after_header_(0),
      write_offset_(0) {
  Resize(kPayloadUnit);
  header_->payload_size = 0;
}

Pickle::Pickle(int header_size)
    : header_(NULL),
      header_size_(AlignInt(header_size, sizeof(uint32))),
      capacity_after_header_(0),
      write_offset_(0) {
  DCHECK_GE(static_cast<size_t>(header_size), sizeof(Header));
  DCHECK_LE(header_size, kPayloadUnit);
  Resize(kPayloadUnit);
  header_->payload_size = 0;
}

Pickle::Pickle(const char* data, int data_len)
    : header_(reinterpret_cast<Header*>(const_cast<char*>(data))),
      header_size_(0),
      capacity_after_header_(kCapacityReadOnly),
      write_offset_(0) {
  if (data_len >= static_cast<int>(sizeof(Header)))
    header_size_ = data_len - header_->payload_size;

  if (header_size_ > static_cast<unsigned int>(data_len))
    header_size_ = 0;

  if (header_size_ != AlignInt(header_size_, sizeof(uint32)))
    header_size_ = 0;

  // If there is anything wrong with the data, we're not going to use it.
  if (!header_size_)
    header_ = NULL;
}

Pickle::Pickle(const Pickle& other)
    : header_(NULL),
      header_size_(other.header_size_),
      capacity_after_header_(0),
      write_offset_(other.write_offset_) {
  size_t payload_size = header_size_ + other.header_->payload_size;
  Resize(payload_size);
  memcpy(header_, other.header_, payload_size);
}

Pickle::~Pickle() {
  if (capacity_after_header_ != kCapacityReadOnly)
    free(header_);
}

Pickle& Pickle::operator=(const Pickle& other) {
  if (this == &other) {
    NOTREACHED();
    return *this;
  }
  if (capacity_after_header_ == kCapacityReadOnly) {
    header_ = NULL;
    capacity_after_header_ = 0;
  }
  if (header_size_ != other.header_size_) {
    free(header_);
    header_ = NULL;
    header_size_ = other.header_size_;
  }
  Resize(other.header_->payload_size);
  memcpy(header_, other.header_,
         other.header_size_ + other.header_->payload_size);
  write_offset_ = other.write_offset_;
  return *this;
}

bool Pickle::WriteString(const StringPiece& value) {
  if (!WriteInt(static_cast<int>(value.size())))
    return false;

  return WriteBytes(value.data(), static_cast<int>(value.size()));
}

bool Pickle::WriteString16(const StringPiece16& value) {
  if (!WriteInt(static_cast<int>(value.size())))
    return false;

  return WriteBytes(value.data(),
                    static_cast<int>(value.size()) * sizeof(char16));
}

bool Pickle::WriteData(const char* data, int length) {
  return length >= 0 && WriteInt(length) && WriteBytes(data, length);
}

bool Pickle::WriteBytes(const void* data, int length) {
  WriteBytesCommon(data, length);
  return true;
}

void Pickle::Reserve(size_t length) {
  size_t data_len = AlignInt(length, sizeof(uint32));
  DCHECK_GE(data_len, length);
#ifdef ARCH_CPU_64_BITS
  DCHECK_LE(data_len, kuint32max);
#endif
  DCHECK_LE(write_offset_, kuint32max - data_len);
  size_t new_size = write_offset_ + data_len;
  if (new_size > capacity_after_header_)
    Resize(capacity_after_header_ * 2 + new_size);
}

void Pickle::Resize(size_t new_capacity) {
  CHECK_NE(capacity_after_header_, kCapacityReadOnly);
  capacity_after_header_ = AlignInt(new_capacity, kPayloadUnit);
  void* p = realloc(header_, GetTotalAllocatedSize());
  CHECK(p);
  header_ = reinterpret_cast<Header*>(p);
}

size_t Pickle::GetTotalAllocatedSize() const {
  if (capacity_after_header_ == kCapacityReadOnly)
    return 0;
  return header_size_ + capacity_after_header_;
}

// static
const char* Pickle::FindNext(size_t header_size,
                             const char* start,
                             const char* end) {
  DCHECK_EQ(header_size, AlignInt(header_size, sizeof(uint32)));
  DCHECK_LE(header_size, static_cast<size_t>(kPayloadUnit));

  size_t length = static_cast<size_t>(end - start);
  if (length < sizeof(Header))
    return NULL;

  const Header* hdr = reinterpret_cast<const Header*>(start);
  if (length < header_size || length - header_size < hdr->payload_size)
    return NULL;
  return start + header_size + hdr->payload_size;
}

template <size_t length> void Pickle::WriteBytesStatic(const void* data) {
  WriteBytesCommon(data, length);
}

template void Pickle::WriteBytesStatic<2>(const void* data);
template void Pickle::WriteBytesStatic<4>(const void* data);
template void Pickle::WriteBytesStatic<8>(const void* data);

inline void Pickle::WriteBytesCommon(const void* data, size_t length) {
  DCHECK_NE(kCapacityReadOnly, capacity_after_header_)
      << "oops: pickle is readonly";
  MSAN_CHECK_MEM_IS_INITIALIZED(data, length);
  size_t data_len = AlignInt(length, sizeof(uint32));
  DCHECK_GE(data_len, length);
#ifdef ARCH_CPU_64_BITS
  DCHECK_LE(data_len, kuint32max);
#endif
  DCHECK_LE(write_offset_, kuint32max - data_len);
  size_t new_size = write_offset_ + data_len;
  if (new_size > capacity_after_header_) {
    Resize(std::max(capacity_after_header_ * 2, new_size));
  }

  char* write = mutable_payload() + write_offset_;
  memcpy(write, data, length);
  memset(write + length, 0, data_len - length);
  header_->payload_size = static_cast<uint32>(new_size);
  write_offset_ = new_size;
}

}  // namespace base

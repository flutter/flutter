// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_H_
#define OTS_H_

#include <stddef.h>
#include <cstdarg>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>

#include "opentype-sanitiser.h"

// arraysize borrowed from base/basictypes.h
template <typename T, size_t N>
char (&ArraySizeHelper(T (&array)[N]))[N];
#define arraysize(array) (sizeof(ArraySizeHelper(array)))

namespace ots {

#if !defined(OTS_DEBUG)
#define OTS_FAILURE() false
#else
#define OTS_FAILURE() \
  (\
    std::fprintf(stderr, "ERROR at %s:%d (%s)\n", \
                 __FILE__, __LINE__, __FUNCTION__) \
    && false\
  )
#endif

// All OTS_FAILURE_* macros ultimately evaluate to 'false', just like the original
// message-less OTS_FAILURE(), so that the current parser will return 'false' as
// its result (indicating a failure).

#if !defined(OTS_DEBUG)
#define OTS_MESSAGE_(level,otf_,...) \
  (otf_)->context->Message(level,__VA_ARGS__)
#else
#define OTS_MESSAGE_(level,otf_,...) \
  OTS_FAILURE(), \
  (otf_)->context->Message(level,__VA_ARGS__)
#endif

// Generate a simple message
#define OTS_FAILURE_MSG_(otf_,...) \
  (OTS_MESSAGE_(0,otf_,__VA_ARGS__), false)

#define OTS_WARNING_MSG_(otf_,...) \
  OTS_MESSAGE_(1,otf_,__VA_ARGS__)

// Generate a message with an associated table tag
#define OTS_FAILURE_MSG_TAG_(otf_,msg_,tag_) \
  (OTS_MESSAGE_(0,otf_,"%4.4s: %s", tag_, msg_), false)

// Convenience macros for use in files that only handle a single table tag,
// defined as TABLE_NAME at the top of the file; the 'file' variable is
// expected to be the current OpenTypeFile pointer.
#define OTS_FAILURE_MSG(...) OTS_FAILURE_MSG_(file, TABLE_NAME ": " __VA_ARGS__)

#define OTS_WARNING(...) OTS_WARNING_MSG_(file, TABLE_NAME ": " __VA_ARGS__)

// -----------------------------------------------------------------------------
// Buffer helper class
//
// This class perform some trival buffer operations while checking for
// out-of-bounds errors. As a family they return false if anything is amiss,
// updating the current offset otherwise.
// -----------------------------------------------------------------------------
class Buffer {
 public:
  Buffer(const uint8_t *buf, size_t len)
      : buffer_(buf),
        length_(len),
        offset_(0) { }

  bool Skip(size_t n_bytes) {
    return Read(NULL, n_bytes);
  }

  bool Read(uint8_t *buf, size_t n_bytes) {
    if (n_bytes > 1024 * 1024 * 1024) {
      return OTS_FAILURE();
    }
    if ((offset_ + n_bytes > length_) ||
        (offset_ > length_ - n_bytes)) {
      return OTS_FAILURE();
    }
    if (buf) {
      std::memcpy(buf, buffer_ + offset_, n_bytes);
    }
    offset_ += n_bytes;
    return true;
  }

  inline bool ReadU8(uint8_t *value) {
    if (offset_ + 1 > length_) {
      return OTS_FAILURE();
    }
    *value = buffer_[offset_];
    ++offset_;
    return true;
  }

  bool ReadU16(uint16_t *value) {
    if (offset_ + 2 > length_) {
      return OTS_FAILURE();
    }
    std::memcpy(value, buffer_ + offset_, sizeof(uint16_t));
    *value = ntohs(*value);
    offset_ += 2;
    return true;
  }

  bool ReadS16(int16_t *value) {
    return ReadU16(reinterpret_cast<uint16_t*>(value));
  }

  bool ReadU24(uint32_t *value) {
    if (offset_ + 3 > length_) {
      return OTS_FAILURE();
    }
    *value = static_cast<uint32_t>(buffer_[offset_]) << 16 |
        static_cast<uint32_t>(buffer_[offset_ + 1]) << 8 |
        static_cast<uint32_t>(buffer_[offset_ + 2]);
    offset_ += 3;
    return true;
  }

  bool ReadU32(uint32_t *value) {
    if (offset_ + 4 > length_) {
      return OTS_FAILURE();
    }
    std::memcpy(value, buffer_ + offset_, sizeof(uint32_t));
    *value = ntohl(*value);
    offset_ += 4;
    return true;
  }

  bool ReadS32(int32_t *value) {
    return ReadU32(reinterpret_cast<uint32_t*>(value));
  }

  bool ReadTag(uint32_t *value) {
    if (offset_ + 4 > length_) {
      return OTS_FAILURE();
    }
    std::memcpy(value, buffer_ + offset_, sizeof(uint32_t));
    offset_ += 4;
    return true;
  }

  bool ReadR64(uint64_t *value) {
    if (offset_ + 8 > length_) {
      return OTS_FAILURE();
    }
    std::memcpy(value, buffer_ + offset_, sizeof(uint64_t));
    offset_ += 8;
    return true;
  }

  const uint8_t *buffer() const { return buffer_; }
  size_t offset() const { return offset_; }
  size_t length() const { return length_; }

  void set_offset(size_t newoffset) { offset_ = newoffset; }

 private:
  const uint8_t * const buffer_;
  const size_t length_;
  size_t offset_;
};

// Round a value up to the nearest multiple of 4. Don't round the value in the
// case that rounding up overflows.
template<typename T> T Round4(T value) {
  if (std::numeric_limits<T>::max() - value < 3) {
    return value;
  }
  return (value + 3) & ~3;
}

template<typename T> T Round2(T value) {
  if (value == std::numeric_limits<T>::max()) {
    return value;
  }
  return (value + 1) & ~1;
}

bool IsValidVersionTag(uint32_t tag);

#define FOR_EACH_TABLE_TYPE \
  F(cff, CFF) \
  F(cmap, CMAP) \
  F(cvt, CVT) \
  F(fpgm, FPGM) \
  F(gasp, GASP) \
  F(gdef, GDEF) \
  F(glyf, GLYF) \
  F(gpos, GPOS) \
  F(gsub, GSUB) \
  F(hdmx, HDMX) \
  F(head, HEAD) \
  F(hhea, HHEA) \
  F(hmtx, HMTX) \
  F(kern, KERN) \
  F(loca, LOCA) \
  F(ltsh, LTSH) \
  F(math, MATH) \
  F(maxp, MAXP) \
  F(name, NAME) \
  F(os2, OS2) \
  F(post, POST) \
  F(prep, PREP) \
  F(vdmx, VDMX) \
  F(vorg, VORG) \
  F(vhea, VHEA) \
  F(vmtx, VMTX)

#define F(name, capname) struct OpenType##capname;
FOR_EACH_TABLE_TYPE
#undef F

struct OpenTypeFile {
  OpenTypeFile() {
#define F(name, capname) name = NULL;
    FOR_EACH_TABLE_TYPE
#undef F
  }

  uint32_t version;
  uint16_t num_tables;
  uint16_t search_range;
  uint16_t entry_selector;
  uint16_t range_shift;

  OTSContext *context;

#define F(name, capname) OpenType##capname *name;
FOR_EACH_TABLE_TYPE
#undef F
};

#define F(name, capname) \
bool ots_##name##_parse(OpenTypeFile *f, const uint8_t *d, size_t l); \
bool ots_##name##_should_serialise(OpenTypeFile *f); \
bool ots_##name##_serialise(OTSStream *s, OpenTypeFile *f); \
void ots_##name##_free(OpenTypeFile *f);
// TODO(yusukes): change these function names to follow Chromium coding rule.
FOR_EACH_TABLE_TYPE
#undef F

}  // namespace ots

#endif  // OTS_H_

// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OPENTYPE_SANITISER_H_
#define OPENTYPE_SANITISER_H_

#if defined(_WIN32)
#include <stdlib.h>
typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef short int16_t;
typedef unsigned short uint16_t;
typedef int int32_t;
typedef unsigned int uint32_t;
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#define ntohl(x) _byteswap_ulong (x)
#define ntohs(x) _byteswap_ushort (x)
#define htonl(x) _byteswap_ulong (x)
#define htons(x) _byteswap_ushort (x)
#else
#include <arpa/inet.h>
#include <stdint.h>
#endif

#include <algorithm>
#include <cassert>
#include <cstddef>
#include <cstring>

#define OTS_TAG(c1,c2,c3,c4) ((uint32_t)((((uint8_t)(c1))<<24)|(((uint8_t)(c2))<<16)|(((uint8_t)(c3))<<8)|((uint8_t)(c4))))
#define OTS_UNTAG(tag)       ((uint8_t)((tag)>>24)), ((uint8_t)((tag)>>16)), ((uint8_t)((tag)>>8)), ((uint8_t)(tag))

namespace ots {

// -----------------------------------------------------------------------------
// This is an interface for an abstract stream class which is used for writing
// the serialised results out.
// -----------------------------------------------------------------------------
class OTSStream {
 public:
  OTSStream() : chksum_(0) {}

  virtual ~OTSStream() {}

  // This should be implemented to perform the actual write.
  virtual bool WriteRaw(const void *data, size_t length) = 0;

  bool Write(const void *data, size_t length) {
    if (!length) return false;

    const size_t orig_length = length;
    size_t offset = 0;

    size_t chksum_offset = Tell() & 3;
    if (chksum_offset) {
      const size_t l = std::min(length, static_cast<size_t>(4) - chksum_offset);
      uint32_t tmp = 0;
      std::memcpy(reinterpret_cast<uint8_t *>(&tmp) + chksum_offset, data, l);
      chksum_ += ntohl(tmp);
      length -= l;
      offset += l;
    }

    while (length >= 4) {
      uint32_t tmp;
      std::memcpy(&tmp, reinterpret_cast<const uint8_t *>(data) + offset,
        sizeof(uint32_t));
      chksum_ += ntohl(tmp);
      length -= 4;
      offset += 4;
    }

    if (length) {
      if (length > 4) return false;  // not reached
      uint32_t tmp = 0;
      std::memcpy(&tmp,
                  reinterpret_cast<const uint8_t*>(data) + offset, length);
      chksum_ += ntohl(tmp);
    }

    return WriteRaw(data, orig_length);
  }

  virtual bool Seek(off_t position) = 0;
  virtual off_t Tell() const = 0;

  virtual bool Pad(size_t bytes) {
    static const uint32_t kZero = 0;
    while (bytes >= 4) {
      if (!WriteTag(kZero)) return false;
      bytes -= 4;
    }
    while (bytes) {
      static const uint8_t kZerob = 0;
      if (!Write(&kZerob, 1)) return false;
      bytes--;
    }
    return true;
  }

  bool WriteU8(uint8_t v) {
    return Write(&v, sizeof(v));
  }

  bool WriteU16(uint16_t v) {
    v = htons(v);
    return Write(&v, sizeof(v));
  }

  bool WriteS16(int16_t v) {
    v = htons(v);
    return Write(&v, sizeof(v));
  }

  bool WriteU24(uint32_t v) {
    v = htonl(v);
    return Write(reinterpret_cast<uint8_t*>(&v)+1, 3);
  }

  bool WriteU32(uint32_t v) {
    v = htonl(v);
    return Write(&v, sizeof(v));
  }

  bool WriteS32(int32_t v) {
    v = htonl(v);
    return Write(&v, sizeof(v));
  }

  bool WriteR64(uint64_t v) {
    return Write(&v, sizeof(v));
  }

  bool WriteTag(uint32_t v) {
    return Write(&v, sizeof(v));
  }

  void ResetChecksum() {
    assert((Tell() & 3) == 0);
    chksum_ = 0;
  }

  uint32_t chksum() const {
    return chksum_;
  }

 protected:
  uint32_t chksum_;
};

#ifdef __GCC__
#define MSGFUNC_FMT_ATTR __attribute__((format(printf, 2, 3)))
#else
#define MSGFUNC_FMT_ATTR
#endif

enum TableAction {
  TABLE_ACTION_DEFAULT,  // Use OTS's default action for that table
  TABLE_ACTION_SANITIZE, // Sanitize the table, potentially droping it
  TABLE_ACTION_PASSTHRU, // Serialize the table unchanged
  TABLE_ACTION_DROP      // Drop the table
};

class OTSContext {
  public:
    OTSContext() {}
    virtual ~OTSContext() {}

    // Process a given OpenType file and write out a sanitised version
    //   output: a pointer to an object implementing the OTSStream interface. The
    //     sanitisied output will be written to this. In the even of a failure,
    //     partial output may have been written.
    //   input: the OpenType file
    //   length: the size, in bytes, of |input|
    bool Process(OTSStream *output, const uint8_t *input, size_t length);

    // This function will be called when OTS is reporting an error.
    //   level: the severity of the generated message:
    //     0: error messages in case OTS fails to sanitize the font.
    //     1: warning messages about issue OTS fixed in the sanitized font.
    virtual void Message(int level, const char *format, ...) MSGFUNC_FMT_ATTR {}

    // This function will be called when OTS needs to decide what to do for a
    // font table.
    //   tag: table tag as an integer in big-endian byte order, independent of
    //   platform endianness
    virtual TableAction GetTableAction(uint32_t tag) { return ots::TABLE_ACTION_DEFAULT; }
};

}  // namespace ots

#endif  // OPENTYPE_SANITISER_H_

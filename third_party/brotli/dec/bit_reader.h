/* Copyright 2013 Google Inc. All Rights Reserved.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

/* Bit reading helpers */

#ifndef BROTLI_DEC_BIT_READER_H_
#define BROTLI_DEC_BIT_READER_H_

#include <string.h>
#include "./streams.h"
#include "./types.h"

#if defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

#if (defined(__x86_64__) || defined(_M_X64))
/* This should be set to 1 only on little-endian machines. */
#define BROTLI_USE_64_BITS 1
#else
#define BROTLI_USE_64_BITS 0
#endif
#define BROTLI_MAX_NUM_BIT_READ   25
#define BROTLI_READ_SIZE          4096
#define BROTLI_IBUF_SIZE          (2 * BROTLI_READ_SIZE + 32)
#define BROTLI_IBUF_MASK          (2 * BROTLI_READ_SIZE - 1)

#define UNALIGNED_COPY64(dst, src) memcpy(dst, src, 8)
#define UNALIGNED_MOVE64(dst, src) memmove(dst, src, 8)

static const uint32_t kBitMask[BROTLI_MAX_NUM_BIT_READ] = {
  0, 1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383, 32767,
  65535, 131071, 262143, 524287, 1048575, 2097151, 4194303, 8388607, 16777215
};

typedef struct {
  /* Input byte buffer, consist of a ringbuffer and a "slack" region where */
  /* bytes from the start of the ringbuffer are copied. */
  uint8_t buf_[BROTLI_IBUF_SIZE];
  uint8_t*    buf_ptr_;      /* next input will write here */
  BrotliInput input_;        /* input callback */
#if (BROTLI_USE_64_BITS)
  uint64_t    val_;          /* pre-fetched bits */
#else
  uint32_t    val_;          /* pre-fetched bits */
#endif
  uint32_t    pos_;          /* byte position in stream */
  uint32_t    bit_pos_;      /* current bit-reading position in val_ */
  uint32_t    bit_end_pos_;  /* bit-reading end position from LSB of val_ */
  int         eos_;          /* input stream is finished */

  /* Set to 0 to support partial data streaming. Set to 1 to expect full data or
     for the last chunk of partial data. */
  int         finish_;
  /* indicates how much bytes already read when reading partial data */
  int         tmp_bytes_read_;
} BrotliBitReader;

/* Initializes the bitreader fields. After this, BrotliWarmupBitReader must
   be used. */
void BrotliInitBitReader(BrotliBitReader* const br,
                         BrotliInput input, int finish);

/* Fetches data to fill up internal buffers. Returns 0 if there wasn't enough */
/* data to read. It then buffers the read data and can be called again with */
/* more data. If br->finish_ is 1, never fails. */
int BrotliWarmupBitReader(BrotliBitReader* const br);

/* Return the prefetched bits, so they can be looked up. */
static BROTLI_INLINE uint32_t BrotliPrefetchBits(BrotliBitReader* const br) {
  return (uint32_t)(br->val_ >> br->bit_pos_);
}

/* For jumping over a number of bits in the bit stream when accessed with */
/* BrotliPrefetchBits and BrotliFillBitWindow. */
static BROTLI_INLINE void BrotliSetBitPos(BrotliBitReader* const br,
                                          uint32_t val) {
#ifdef BROTLI_DECODE_DEBUG
  uint32_t n_bits = val - br->bit_pos_;
  const uint32_t bval = (uint32_t)(br->val_ >> br->bit_pos_) & kBitMask[n_bits];
  printf("[BrotliReadBits]  %010d %2d  val: %6x\n",
         (br->pos_ << 3) + br->bit_pos_ - 64, n_bits, bval);
#endif
  br->bit_pos_ = val;
}

/*
 * Reload up to 32 bits byte-by-byte.
 * This function works on both little and big endian.
 */
static BROTLI_INLINE void ShiftBytes32(BrotliBitReader* const br) {
  while (br->bit_pos_ >= 8) {
    br->val_ >>= 8;
    br->val_ |= ((uint32_t)br->buf_[br->pos_ & BROTLI_IBUF_MASK]) << 24;
    ++br->pos_;
    br->bit_pos_ -= 8;
    br->bit_end_pos_ -= 8;
  }
}

/* Fills up the input ringbuffer by calling the input callback.

   Does nothing if there are at least 32 bytes present after current position.

   Returns 0 if one of:
    - the input callback returned an error, or
    - there is no more input and the position is past the end of the stream.
    - finish is false and less than BROTLI_READ_SIZE are available - a next call
      when more data is available makes it continue including the partially read
      data

   After encountering the end of the input stream, 32 additional zero bytes are
   copied to the ringbuffer, therefore it is safe to call this function after
   every 32 bytes of input is read.
*/
static BROTLI_INLINE int BrotliReadMoreInput(BrotliBitReader* const br) {
  if (br->bit_end_pos_ > 256) {
    return 1;
  } else if (br->eos_) {
    return br->bit_pos_ <= br->bit_end_pos_;
  } else {
    uint8_t* dst = br->buf_ptr_;
    int bytes_read = BrotliRead(br->input_, dst + br->tmp_bytes_read_,
        (size_t) (BROTLI_READ_SIZE - br->tmp_bytes_read_));
    if (bytes_read < 0) {
      return 0;
    }
    bytes_read += br->tmp_bytes_read_;
    br->tmp_bytes_read_ = 0;
    if (bytes_read < BROTLI_READ_SIZE) {
      if (!br->finish_) {
        br->tmp_bytes_read_ = bytes_read;
        return 0;
      }
      br->eos_ = 1;
      /* Store 32 bytes of zero after the stream end. */
#if (BROTLI_USE_64_BITS)
      *(uint64_t*)(dst + bytes_read) = 0;
      *(uint64_t*)(dst + bytes_read + 8) = 0;
      *(uint64_t*)(dst + bytes_read + 16) = 0;
      *(uint64_t*)(dst + bytes_read + 24) = 0;
#else
      memset(dst + bytes_read, 0, 32);
#endif
    }
    if (dst == br->buf_) {
      /* Copy the head of the ringbuffer to the slack region. */
#if (BROTLI_USE_64_BITS)
      UNALIGNED_COPY64(br->buf_ + BROTLI_IBUF_SIZE - 32, br->buf_);
      UNALIGNED_COPY64(br->buf_ + BROTLI_IBUF_SIZE - 24, br->buf_ + 8);
      UNALIGNED_COPY64(br->buf_ + BROTLI_IBUF_SIZE - 16, br->buf_ + 16);
      UNALIGNED_COPY64(br->buf_ + BROTLI_IBUF_SIZE - 8, br->buf_ + 24);
#else
      memcpy(br->buf_ + (BROTLI_READ_SIZE << 1), br->buf_, 32);
#endif
      br->buf_ptr_ = br->buf_ + BROTLI_READ_SIZE;
    } else {
      br->buf_ptr_ = br->buf_;
    }
    br->bit_end_pos_ += ((uint32_t)bytes_read << 3);
    return 1;
  }
}

/* Guarantees that there are at least 24 bits in the buffer. */
static BROTLI_INLINE void BrotliFillBitWindow(BrotliBitReader* const br) {
#if (BROTLI_USE_64_BITS)
  if (br->bit_pos_ >= 40) {
    /*
     * Advances the Read buffer by 5 bytes to make room for reading next
     * 24 bits.
     * The expression below needs a little-endian arch to work correctly.
     * This gives a large speedup for decoding speed.
     */
    br->val_ >>= 40;
    br->val_ |= *(const uint64_t*)(
        br->buf_ + (br->pos_ & BROTLI_IBUF_MASK)) << 24;
    br->pos_ += 5;
    br->bit_pos_ -= 40;
    br->bit_end_pos_ -= 40;
  }
#else
  ShiftBytes32(br);
#endif
}

/* Reads the specified number of bits from Read Buffer. */
static BROTLI_INLINE uint32_t BrotliReadBits(
    BrotliBitReader* const br, int n_bits) {
  uint32_t val;
#if (BROTLI_USE_64_BITS)
  BrotliFillBitWindow(br);
  val = (uint32_t)(br->val_ >> br->bit_pos_) & kBitMask[n_bits];
#else
  /*
   * The if statement gives 2-4% speed boost on Canterbury data set with
   * asm.js/firefox/x86-64.
   */
  if ((32 - br->bit_pos_) < ((uint32_t) n_bits)) {
    BrotliFillBitWindow(br);
  }
  val = (br->val_ >> br->bit_pos_) & kBitMask[n_bits];
#endif
#ifdef BROTLI_DECODE_DEBUG
  printf("[BrotliReadBits]  %010d %2d  val: %6x\n",
         (br->pos_ << 3) + br->bit_pos_ - 64, n_bits, val);
#endif
  br->bit_pos_ += (uint32_t)n_bits;
  return val;
}

#if defined(__cplusplus) || defined(c_plusplus)
}    /* extern "C" */
#endif

#endif  /* BROTLI_DEC_BIT_READER_H_ */

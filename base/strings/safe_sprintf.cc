// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/safe_sprintf.h"

#include <limits>

#if !defined(NDEBUG)
// In debug builds, we use RAW_CHECK() to print useful error messages, if
// SafeSPrintf() is called with broken arguments.
// As our contract promises that SafeSPrintf() can be called from any
// restricted run-time context, it is not actually safe to call logging
// functions from it; and we only ever do so for debug builds and hope for the
// best. We should _never_ call any logging function other than RAW_CHECK(),
// and we should _never_ include any logging code that is active in production
// builds. Most notably, we should not include these logging functions in
// unofficial release builds, even though those builds would otherwise have
// DCHECKS() enabled.
// In other words; please do not remove the #ifdef around this #include.
// Instead, in production builds we opt for returning a degraded result,
// whenever an error is encountered.
// E.g. The broken function call
//        SafeSPrintf("errno = %d (%x)", errno, strerror(errno))
//      will print something like
//        errno = 13, (%x)
//      instead of
//        errno = 13 (Access denied)
//      In most of the anticipated use cases, that's probably the preferred
//      behavior.
#include "base/logging.h"
#define DEBUG_CHECK RAW_CHECK
#else
#define DEBUG_CHECK(x) do { if (x) { } } while (0)
#endif

namespace base {
namespace strings {

// The code in this file is extremely careful to be async-signal-safe.
//
// Most obviously, we avoid calling any code that could dynamically allocate
// memory. Doing so would almost certainly result in bugs and dead-locks.
// We also avoid calling any other STL functions that could have unintended
// side-effects involving memory allocation or access to other shared
// resources.
//
// But on top of that, we also avoid calling other library functions, as many
// of them have the side-effect of calling getenv() (in order to deal with
// localization) or accessing errno. The latter sounds benign, but there are
// several execution contexts where it isn't even possible to safely read let
// alone write errno.
//
// The stated design goal of the SafeSPrintf() function is that it can be
// called from any context that can safely call C or C++ code (i.e. anything
// that doesn't require assembly code).
//
// For a brief overview of some but not all of the issues with async-signal-
// safety, refer to:
// http://pubs.opengroup.org/onlinepubs/009695399/functions/xsh_chap02_04.html

namespace {
const size_t kSSizeMaxConst = ((size_t)(ssize_t)-1) >> 1;

const char kUpCaseHexDigits[]   = "0123456789ABCDEF";
const char kDownCaseHexDigits[] = "0123456789abcdef";
}

#if defined(NDEBUG)
// We would like to define kSSizeMax as std::numeric_limits<ssize_t>::max(),
// but C++ doesn't allow us to do that for constants. Instead, we have to
// use careful casting and shifting. We later use a COMPILE_ASSERT to
// verify that this worked correctly.
namespace {
const size_t kSSizeMax = kSSizeMaxConst;
}
#else  // defined(NDEBUG)
// For efficiency, we really need kSSizeMax to be a constant. But for unit
// tests, it should be adjustable. This allows us to verify edge cases without
// having to fill the entire available address space. As a compromise, we make
// kSSizeMax adjustable in debug builds, and then only compile that particular
// part of the unit test in debug builds.
namespace {
static size_t kSSizeMax = kSSizeMaxConst;
}

namespace internal {
void SetSafeSPrintfSSizeMaxForTest(size_t max) {
  kSSizeMax = max;
}

size_t GetSafeSPrintfSSizeMaxForTest() {
  return kSSizeMax;
}
}
#endif  // defined(NDEBUG)

namespace {
class Buffer {
 public:
  // |buffer| is caller-allocated storage that SafeSPrintf() writes to. It
  // has |size| bytes of writable storage. It is the caller's responsibility
  // to ensure that the buffer is at least one byte in size, so that it fits
  // the trailing NUL that will be added by the destructor. The buffer also
  // must be smaller or equal to kSSizeMax in size.
  Buffer(char* buffer, size_t size)
      : buffer_(buffer),
        size_(size - 1),  // Account for trailing NUL byte
        count_(0) {
// The following assertion does not build on Mac and Android. This is because
// static_assert only works with compile-time constants, but mac uses
// libstdc++4.2 and android uses stlport, which both don't mark
// numeric_limits::max() as constexp.  Likewise, MSVS2013's standard library
// also doesn't mark max() as constexpr yet. cl.exe supports static_cast but
// doesn't really implement constexpr yet so it doesn't complain, but clang
// does.
#if __cplusplus >= 201103 && !defined(OS_ANDROID) && !defined(OS_MACOSX) && \
    !defined(OS_IOS) && !(defined(__clang__) && defined(OS_WIN))
    COMPILE_ASSERT(kSSizeMaxConst == \
                   static_cast<size_t>(std::numeric_limits<ssize_t>::max()),
                   kSSizeMax_is_the_max_value_of_an_ssize_t);
#endif
    DEBUG_CHECK(size > 0);
    DEBUG_CHECK(size <= kSSizeMax);
  }

  ~Buffer() {
    // The code calling the constructor guaranteed that there was enough space
    // to store a trailing NUL -- and in debug builds, we are actually
    // verifying this with DEBUG_CHECK()s in the constructor. So, we can
    // always unconditionally write the NUL byte in the destructor.  We do not
    // need to adjust the count_, as SafeSPrintf() copies snprintf() in not
    // including the NUL byte in its return code.
    *GetInsertionPoint() = '\000';
  }

  // Returns true, iff the buffer is filled all the way to |kSSizeMax-1|. The
  // caller can now stop adding more data, as GetCount() has reached its
  // maximum possible value.
  inline bool OutOfAddressableSpace() const {
    return count_ == static_cast<size_t>(kSSizeMax - 1);
  }

  // Returns the number of bytes that would have been emitted to |buffer_|
  // if it was sized sufficiently large. This number can be larger than
  // |size_|, if the caller provided an insufficiently large output buffer.
  // But it will never be bigger than |kSSizeMax-1|.
  inline ssize_t GetCount() const {
    DEBUG_CHECK(count_ < kSSizeMax);
    return static_cast<ssize_t>(count_);
  }

  // Emits one |ch| character into the |buffer_| and updates the |count_| of
  // characters that are currently supposed to be in the buffer.
  // Returns "false", iff the buffer was already full.
  // N.B. |count_| increases even if no characters have been written. This is
  // needed so that GetCount() can return the number of bytes that should
  // have been allocated for the |buffer_|.
  inline bool Out(char ch) {
    if (size_ >= 1 && count_ < size_) {
      buffer_[count_] = ch;
      return IncrementCountByOne();
    }
    // |count_| still needs to be updated, even if the buffer has been
    // filled completely. This allows SafeSPrintf() to return the number of
    // bytes that should have been emitted.
    IncrementCountByOne();
    return false;
  }

  // Inserts |padding|-|len| bytes worth of padding into the |buffer_|.
  // |count_| will also be incremented by the number of bytes that were meant
  // to be emitted. The |pad| character is typically either a ' ' space
  // or a '0' zero, but other non-NUL values are legal.
  // Returns "false", iff the the |buffer_| filled up (i.e. |count_|
  // overflowed |size_|) at any time during padding.
  inline bool Pad(char pad, size_t padding, size_t len) {
    DEBUG_CHECK(pad);
    DEBUG_CHECK(padding <= kSSizeMax);
    for (; padding > len; --padding) {
      if (!Out(pad)) {
        if (--padding) {
          IncrementCount(padding-len);
        }
        return false;
      }
    }
    return true;
  }

  // POSIX doesn't define any async-signal-safe function for converting
  // an integer to ASCII. Define our own version.
  //
  // This also gives us the ability to make the function a little more
  // powerful and have it deal with |padding|, with truncation, and with
  // predicting the length of the untruncated output.
  //
  // IToASCII() converts an integer |i| to ASCII.
  //
  // Unlike similar functions in the standard C library, it never appends a
  // NUL character. This is left for the caller to do.
  //
  // While the function signature takes a signed int64_t, the code decides at
  // run-time whether to treat the argument as signed (int64_t) or as unsigned
  // (uint64_t) based on the value of |sign|.
  //
  // It supports |base|s 2 through 16. Only a |base| of 10 is allowed to have
  // a |sign|. Otherwise, |i| is treated as unsigned.
  //
  // For bases larger than 10, |upcase| decides whether lower-case or upper-
  // case letters should be used to designate digits greater than 10.
  //
  // Padding can be done with either '0' zeros or ' ' spaces. Padding has to
  // be positive and will always be applied to the left of the output.
  //
  // Prepends a |prefix| to the number (e.g. "0x"). This prefix goes to
  // the left of |padding|, if |pad| is '0'; and to the right of |padding|
  // if |pad| is ' '.
  //
  // Returns "false", if the |buffer_| overflowed at any time.
  bool IToASCII(bool sign, bool upcase, int64_t i, int base,
                char pad, size_t padding, const char* prefix);

 private:
  // Increments |count_| by |inc| unless this would cause |count_| to
  // overflow |kSSizeMax-1|. Returns "false", iff an overflow was detected;
  // it then clamps |count_| to |kSSizeMax-1|.
  inline bool IncrementCount(size_t inc) {
    // "inc" is either 1 or a "padding" value. Padding is clamped at
    // run-time to at most kSSizeMax-1. So, we know that "inc" is always in
    // the range 1..kSSizeMax-1.
    // This allows us to compute "kSSizeMax - 1 - inc" without incurring any
    // integer overflows.
    DEBUG_CHECK(inc <= kSSizeMax - 1);
    if (count_ > kSSizeMax - 1 - inc) {
      count_ = kSSizeMax - 1;
      return false;
    } else {
      count_ += inc;
      return true;
    }
  }

  // Convenience method for the common case of incrementing |count_| by one.
  inline bool IncrementCountByOne() {
    return IncrementCount(1);
  }

  // Return the current insertion point into the buffer. This is typically
  // at |buffer_| + |count_|, but could be before that if truncation
  // happened. It always points to one byte past the last byte that was
  // successfully placed into the |buffer_|.
  inline char* GetInsertionPoint() const {
    size_t idx = count_;
    if (idx > size_) {
      idx = size_;
    }
    return buffer_ + idx;
  }

  // User-provided buffer that will receive the fully formatted output string.
  char* buffer_;

  // Number of bytes that are available in the buffer excluding the trailing
  // NUL byte that will be added by the destructor.
  const size_t size_;

  // Number of bytes that would have been emitted to the buffer, if the buffer
  // was sufficiently big. This number always excludes the trailing NUL byte
  // and it is guaranteed to never grow bigger than kSSizeMax-1.
  size_t count_;

  DISALLOW_COPY_AND_ASSIGN(Buffer);
};


bool Buffer::IToASCII(bool sign, bool upcase, int64_t i, int base,
                      char pad, size_t padding, const char* prefix) {
  // Sanity check for parameters. None of these should ever fail, but see
  // above for the rationale why we can't call CHECK().
  DEBUG_CHECK(base >= 2);
  DEBUG_CHECK(base <= 16);
  DEBUG_CHECK(!sign || base == 10);
  DEBUG_CHECK(pad == '0' || pad == ' ');
  DEBUG_CHECK(padding <= kSSizeMax);
  DEBUG_CHECK(!(sign && prefix && *prefix));

  // Handle negative numbers, if the caller indicated that |i| should be
  // treated as a signed number; otherwise treat |i| as unsigned (even if the
  // MSB is set!)
  // Details are tricky, because of limited data-types, but equivalent pseudo-
  // code would look like:
  //   if (sign && i < 0)
  //     prefix = "-";
  //   num = abs(i);
  int minint = 0;
  uint64_t num;
  if (sign && i < 0) {
    prefix = "-";

    // Turn our number positive.
    if (i == std::numeric_limits<int64_t>::min()) {
      // The most negative integer needs special treatment.
      minint = 1;
      num = static_cast<uint64_t>(-(i + 1));
    } else {
      // "Normal" negative numbers are easy.
      num = static_cast<uint64_t>(-i);
    }
  } else {
    num = static_cast<uint64_t>(i);
  }

  // If padding with '0' zero, emit the prefix or '-' character now. Otherwise,
  // make the prefix accessible in reverse order, so that we can later output
  // it right between padding and the number.
  // We cannot choose the easier approach of just reversing the number, as that
  // fails in situations where we need to truncate numbers that have padding
  // and/or prefixes.
  const char* reverse_prefix = NULL;
  if (prefix && *prefix) {
    if (pad == '0') {
      while (*prefix) {
        if (padding) {
          --padding;
        }
        Out(*prefix++);
      }
      prefix = NULL;
    } else {
      for (reverse_prefix = prefix; *reverse_prefix; ++reverse_prefix) {
      }
    }
  } else
    prefix = NULL;
  const size_t prefix_length = reverse_prefix - prefix;

  // Loop until we have converted the entire number. Output at least one
  // character (i.e. '0').
  size_t start = count_;
  size_t discarded = 0;
  bool started = false;
  do {
    // Make sure there is still enough space left in our output buffer.
    if (count_ >= size_) {
      if (start < size_) {
        // It is rare that we need to output a partial number. But if asked
        // to do so, we will still make sure we output the correct number of
        // leading digits.
        // Since we are generating the digits in reverse order, we actually
        // have to discard digits in the order that we have already emitted
        // them. This is essentially equivalent to:
        //   memmove(buffer_ + start, buffer_ + start + 1, size_ - start - 1)
        for (char* move = buffer_ + start, *end = buffer_ + size_ - 1;
             move < end;
             ++move) {
          *move = move[1];
        }
        ++discarded;
        --count_;
      } else if (count_ - size_ > 1) {
        // Need to increment either |count_| or |discarded| to make progress.
        // The latter is more efficient, as it eventually triggers fast
        // handling of padding. But we have to ensure we don't accidentally
        // change the overall state (i.e. switch the state-machine from
        // discarding to non-discarding). |count_| needs to always stay
        // bigger than |size_|.
        --count_;
        ++discarded;
      }
    }

    // Output the next digit and (if necessary) compensate for the most
    // negative integer needing special treatment. This works because,
    // no matter the bit width of the integer, the lowest-most decimal
    // integer always ends in 2, 4, 6, or 8.
    if (!num && started) {
      if (reverse_prefix > prefix) {
        Out(*--reverse_prefix);
      } else {
        Out(pad);
      }
    } else {
      started = true;
      Out((upcase ? kUpCaseHexDigits : kDownCaseHexDigits)[num%base + minint]);
    }

    minint = 0;
    num /= base;

    // Add padding, if requested.
    if (padding > 0) {
      --padding;

      // Performance optimization for when we are asked to output excessive
      // padding, but our output buffer is limited in size.  Even if we output
      // a 64bit number in binary, we would never write more than 64 plus
      // prefix non-padding characters. So, once this limit has been passed,
      // any further state change can be computed arithmetically; we know that
      // by this time, our entire final output consists of padding characters
      // that have all already been output.
      if (discarded > 8*sizeof(num) + prefix_length) {
        IncrementCount(padding);
        padding = 0;
      }
    }
  } while (num || padding || (reverse_prefix > prefix));

  // Conversion to ASCII actually resulted in the digits being in reverse
  // order. We can't easily generate them in forward order, as we can't tell
  // the number of characters needed until we are done converting.
  // So, now, we reverse the string (except for the possible '-' sign).
  char* front = buffer_ + start;
  char* back = GetInsertionPoint();
  while (--back > front) {
    char ch = *back;
    *back = *front;
    *front++ = ch;
  }

  IncrementCount(discarded);
  return !discarded;
}

}  // anonymous namespace

namespace internal {

ssize_t SafeSNPrintf(char* buf, size_t sz, const char* fmt, const Arg* args,
                     const size_t max_args) {
  // Make sure that at least one NUL byte can be written, and that the buffer
  // never overflows kSSizeMax. Not only does that use up most or all of the
  // address space, it also would result in a return code that cannot be
  // represented.
  if (static_cast<ssize_t>(sz) < 1) {
    return -1;
  } else if (sz > kSSizeMax) {
    sz = kSSizeMax;
  }

  // Iterate over format string and interpret '%' arguments as they are
  // encountered.
  Buffer buffer(buf, sz);
  size_t padding;
  char pad;
  for (unsigned int cur_arg = 0; *fmt && !buffer.OutOfAddressableSpace(); ) {
    if (*fmt++ == '%') {
      padding = 0;
      pad = ' ';
      char ch = *fmt++;
    format_character_found:
      switch (ch) {
      case '0': case '1': case '2': case '3': case '4':
      case '5': case '6': case '7': case '8': case '9':
        // Found a width parameter. Convert to an integer value and store in
        // "padding". If the leading digit is a zero, change the padding
        // character from a space ' ' to a zero '0'.
        pad = ch == '0' ? '0' : ' ';
        for (;;) {
          // The maximum allowed padding fills all the available address
          // space and leaves just enough space to insert the trailing NUL.
          const size_t max_padding = kSSizeMax - 1;
          if (padding > max_padding/10 ||
              10*padding > max_padding - (ch - '0')) {
            DEBUG_CHECK(padding <= max_padding/10 &&
                        10*padding <= max_padding - (ch - '0'));
            // Integer overflow detected. Skip the rest of the width until
            // we find the format character, then do the normal error handling.
          padding_overflow:
            padding = max_padding;
            while ((ch = *fmt++) >= '0' && ch <= '9') {
            }
            if (cur_arg < max_args) {
              ++cur_arg;
            }
            goto fail_to_expand;
          }
          padding = 10*padding + ch - '0';
          if (padding > max_padding) {
            // This doesn't happen for "sane" values of kSSizeMax. But once
            // kSSizeMax gets smaller than about 10, our earlier range checks
            // are incomplete. Unittests do trigger this artificial corner
            // case.
            DEBUG_CHECK(padding <= max_padding);
            goto padding_overflow;
          }
          ch = *fmt++;
          if (ch < '0' || ch > '9') {
            // Reached the end of the width parameter. This is where the format
            // character is found.
            goto format_character_found;
          }
        }
        break;
      case 'c': {  // Output an ASCII character.
        // Check that there are arguments left to be inserted.
        if (cur_arg >= max_args) {
          DEBUG_CHECK(cur_arg < max_args);
          goto fail_to_expand;
        }

        // Check that the argument has the expected type.
        const Arg& arg = args[cur_arg++];
        if (arg.type != Arg::INT && arg.type != Arg::UINT) {
          DEBUG_CHECK(arg.type == Arg::INT || arg.type == Arg::UINT);
          goto fail_to_expand;
        }

        // Apply padding, if needed.
        buffer.Pad(' ', padding, 1);

        // Convert the argument to an ASCII character and output it.
        char as_char = static_cast<char>(arg.integer.i);
        if (!as_char) {
          goto end_of_output_buffer;
        }
        buffer.Out(as_char);
        break; }
      case 'd':    // Output a possibly signed decimal value.
      case 'o':    // Output an unsigned octal value.
      case 'x':    // Output an unsigned hexadecimal value.
      case 'X':
      case 'p': {  // Output a pointer value.
        // Check that there are arguments left to be inserted.
        if (cur_arg >= max_args) {
          DEBUG_CHECK(cur_arg < max_args);
          goto fail_to_expand;
        }

        const Arg& arg = args[cur_arg++];
        int64_t i;
        const char* prefix = NULL;
        if (ch != 'p') {
          // Check that the argument has the expected type.
          if (arg.type != Arg::INT && arg.type != Arg::UINT) {
            DEBUG_CHECK(arg.type == Arg::INT || arg.type == Arg::UINT);
            goto fail_to_expand;
          }
          i = arg.integer.i;

          if (ch != 'd') {
            // The Arg() constructor automatically performed sign expansion on
            // signed parameters. This is great when outputting a %d decimal
            // number, but can result in unexpected leading 0xFF bytes when
            // outputting a %x hexadecimal number. Mask bits, if necessary.
            // We have to do this here, instead of in the Arg() constructor, as
            // the Arg() constructor cannot tell whether we will output a %d
            // or a %x. Only the latter should experience masking.
            if (arg.integer.width < sizeof(int64_t)) {
              i &= (1LL << (8*arg.integer.width)) - 1;
            }
          }
        } else {
          // Pointer values require an actual pointer or a string.
          if (arg.type == Arg::POINTER) {
            i = reinterpret_cast<uintptr_t>(arg.ptr);
          } else if (arg.type == Arg::STRING) {
            i = reinterpret_cast<uintptr_t>(arg.str);
          } else if (arg.type == Arg::INT &&
                     arg.integer.width == sizeof(NULL) &&
                     arg.integer.i == 0) {  // Allow C++'s version of NULL
            i = 0;
          } else {
            DEBUG_CHECK(arg.type == Arg::POINTER || arg.type == Arg::STRING);
            goto fail_to_expand;
          }

          // Pointers always include the "0x" prefix.
          prefix = "0x";
        }

        // Use IToASCII() to convert to ASCII representation. For decimal
        // numbers, optionally print a sign. For hexadecimal numbers,
        // distinguish between upper and lower case. %p addresses are always
        // printed as upcase. Supports base 8, 10, and 16. Prints padding
        // and/or prefixes, if so requested.
        buffer.IToASCII(ch == 'd' && arg.type == Arg::INT,
                        ch != 'x', i,
                        ch == 'o' ? 8 : ch == 'd' ? 10 : 16,
                        pad, padding, prefix);
        break; }
      case 's': {
        // Check that there are arguments left to be inserted.
        if (cur_arg >= max_args) {
          DEBUG_CHECK(cur_arg < max_args);
          goto fail_to_expand;
        }

        // Check that the argument has the expected type.
        const Arg& arg = args[cur_arg++];
        const char *s;
        if (arg.type == Arg::STRING) {
          s = arg.str ? arg.str : "<NULL>";
        } else if (arg.type == Arg::INT && arg.integer.width == sizeof(NULL) &&
                   arg.integer.i == 0) {  // Allow C++'s version of NULL
          s = "<NULL>";
        } else {
          DEBUG_CHECK(arg.type == Arg::STRING);
          goto fail_to_expand;
        }

        // Apply padding, if needed. This requires us to first check the
        // length of the string that we are outputting.
        if (padding) {
          size_t len = 0;
          for (const char* src = s; *src++; ) {
            ++len;
          }
          buffer.Pad(' ', padding, len);
        }

        // Printing a string involves nothing more than copying it into the
        // output buffer and making sure we don't output more bytes than
        // available space; Out() takes care of doing that.
        for (const char* src = s; *src; ) {
          buffer.Out(*src++);
        }
        break; }
      case '%':
        // Quoted percent '%' character.
        goto copy_verbatim;
      fail_to_expand:
        // C++ gives us tools to do type checking -- something that snprintf()
        // could never really do. So, whenever we see arguments that don't
        // match up with the format string, we refuse to output them. But
        // since we have to be extremely conservative about being async-
        // signal-safe, we are limited in the type of error handling that we
        // can do in production builds (in debug builds we can use
        // DEBUG_CHECK() and hope for the best). So, all we do is pass the
        // format string unchanged. That should eventually get the user's
        // attention; and in the meantime, it hopefully doesn't lose too much
        // data.
      default:
        // Unknown or unsupported format character. Just copy verbatim to
        // output.
        buffer.Out('%');
        DEBUG_CHECK(ch);
        if (!ch) {
          goto end_of_format_string;
        }
        buffer.Out(ch);
        break;
      }
    } else {
  copy_verbatim:
    buffer.Out(fmt[-1]);
    }
  }
 end_of_format_string:
 end_of_output_buffer:
  return buffer.GetCount();
}

}  // namespace internal

ssize_t SafeSNPrintf(char* buf, size_t sz, const char* fmt) {
  // Make sure that at least one NUL byte can be written, and that the buffer
  // never overflows kSSizeMax. Not only does that use up most or all of the
  // address space, it also would result in a return code that cannot be
  // represented.
  if (static_cast<ssize_t>(sz) < 1) {
    return -1;
  } else if (sz > kSSizeMax) {
    sz = kSSizeMax;
  }

  Buffer buffer(buf, sz);

  // In the slow-path, we deal with errors by copying the contents of
  // "fmt" unexpanded. This means, if there are no arguments passed, the
  // SafeSPrintf() function always degenerates to a version of strncpy() that
  // de-duplicates '%' characters.
  const char* src = fmt;
  for (; *src; ++src) {
    buffer.Out(*src);
    DEBUG_CHECK(src[0] != '%' || src[1] == '%');
    if (src[0] == '%' && src[1] == '%') {
      ++src;
    }
  }
  return buffer.GetCount();
}

}  // namespace strings
}  // namespace base

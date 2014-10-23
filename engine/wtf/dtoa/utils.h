// Copyright 2010 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
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

#ifndef DOUBLE_CONVERSION_UTILS_H_
#define DOUBLE_CONVERSION_UTILS_H_

#include "wtf/Assertions.h"
#include <string.h>

#define UNIMPLEMENTED ASSERT_NOT_REACHED
#define UNREACHABLE ASSERT_NOT_REACHED

// Double operations detection based on target architecture.
// Linux uses a 80bit wide floating point stack on x86. This induces double
// rounding, which in turn leads to wrong results.
// An easy way to test if the floating-point operations are correct is to
// evaluate: 89255.0/1e22. If the floating-point stack is 64 bits wide then
// the result is equal to 89255e-22.
// The best way to test this, is to create a division-function and to compare
// the output of the division with the expected result. (Inlining must be
// disabled.)
// On Linux,x86 89255e-22 != Div_double(89255.0/1e22)
#if defined(_M_X64) || defined(__x86_64__) || \
defined(__ARMEL__) || defined(__aarch64__) || \
defined(__MIPSEL__)
#define DOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS 1
#elif defined(_M_IX86) || defined(__i386__)
#if defined(_WIN32)
// Windows uses a 64bit wide floating point stack.
#define DOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS 1
#else
#undef DOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS
#endif  // _WIN32
#else
#error Target architecture was not detected as supported by Double-Conversion.
#endif


#if defined(_WIN32) && !defined(__MINGW32__)

typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef short int16_t;  // NOLINT
typedef unsigned short uint16_t;  // NOLINT
typedef int int32_t;
typedef unsigned int uint32_t;
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
// intptr_t and friends are defined in crtdefs.h through stdio.h.

#else

#include <stdint.h>

#endif

// The following macro works on both 32 and 64-bit platforms.
// Usage: instead of writing 0x1234567890123456
//      write UINT64_2PART_C(0x12345678,90123456);
#define UINT64_2PART_C(a, b) (((static_cast<uint64_t>(a) << 32) + 0x##b##u))


// The expression ARRAY_SIZE(a) is a compile-time constant of type
// size_t which represents the number of elements of the given
// array. You should only use ARRAY_SIZE on statically allocated
// arrays.
#define ARRAY_SIZE(a)                                   \
((sizeof(a) / sizeof(*(a))) /                         \
static_cast<size_t>(!(sizeof(a) % sizeof(*(a)))))

// A macro to disallow the evil copy constructor and operator= functions
// This should be used in the private: declarations for a class
#define DISALLOW_COPY_AND_ASSIGN(TypeName)      \
TypeName(const TypeName&);                    \
void operator=(const TypeName&)

// A macro to disallow all the implicit constructors, namely the
// default constructor, copy constructor and operator= functions.
//
// This should be used in the private: declarations for a class
// that wants to prevent anyone from instantiating it. This is
// especially useful for classes containing only static methods.
#define DISALLOW_IMPLICIT_CONSTRUCTORS(TypeName) \
TypeName();                                    \
DISALLOW_COPY_AND_ASSIGN(TypeName)

namespace WTF {

namespace double_conversion {

    static const int kCharSize = sizeof(char);

    // Returns the maximum of the two parameters.
    template <typename T>
    static T Max(T a, T b) {
        return a < b ? b : a;
    }


    // Returns the minimum of the two parameters.
    template <typename T>
    static T Min(T a, T b) {
        return a < b ? a : b;
    }


    inline int StrLength(const char* string) {
        size_t length = strlen(string);
        ASSERT(length == static_cast<size_t>(static_cast<int>(length)));
        return static_cast<int>(length);
    }

    // This is a simplified version of V8's Vector class.
    template <typename T>
    class Vector {
    public:
        Vector() : start_(NULL), length_(0) {}
        Vector(T* data, int length) : start_(data), length_(length) {
            ASSERT(length == 0 || (length > 0 && data != NULL));
        }

        // Returns a vector using the same backing storage as this one,
        // spanning from and including 'from', to but not including 'to'.
        Vector<T> SubVector(int from, int to) {
            ASSERT(to <= length_);
            ASSERT(from < to);
            ASSERT(0 <= from);
            return Vector<T>(start() + from, to - from);
        }

        // Returns the length of the vector.
        int length() const { return length_; }

        // Returns whether or not the vector is empty.
        bool is_empty() const { return length_ == 0; }

        // Returns the pointer to the start of the data in the vector.
        T* start() const { return start_; }

        // Access individual vector elements - checks bounds in debug mode.
        T& operator[](int index) const {
            ASSERT(0 <= index && index < length_);
            return start_[index];
        }

        T& first() { return start_[0]; }

        T& last() { return start_[length_ - 1]; }

    private:
        T* start_;
        int length_;
    };


    // Helper class for building result strings in a character buffer. The
    // purpose of the class is to use safe operations that checks the
    // buffer bounds on all operations in debug mode.
    class StringBuilder {
    public:
        StringBuilder(char* buffer, int size)
        : buffer_(buffer, size), position_(0) { }

        ~StringBuilder() { if (!is_finalized()) Finalize(); }

        int size() const { return buffer_.length(); }

        // Get the current position in the builder.
        int position() const {
            ASSERT(!is_finalized());
            return position_;
        }

        // Set the current position in the builder.
        void SetPosition(int position)
        {
            ASSERT(!is_finalized());
            ASSERT_WITH_SECURITY_IMPLICATION(position < size());
            position_ = position;
        }

        // Reset the position.
        void Reset() { position_ = 0; }

        // Add a single character to the builder. It is not allowed to add
        // 0-characters; use the Finalize() method to terminate the string
        // instead.
        void AddCharacter(char c) {
            ASSERT(c != '\0');
            ASSERT(!is_finalized() && position_ < buffer_.length());
            buffer_[position_++] = c;
        }

        // Add an entire string to the builder. Uses strlen() internally to
        // compute the length of the input string.
        void AddString(const char* s) {
            AddSubstring(s, StrLength(s));
        }

        // Add the first 'n' characters of the given string 's' to the
        // builder. The input string must have enough characters.
        void AddSubstring(const char* s, int n) {
            ASSERT(!is_finalized() && position_ + n < buffer_.length());
            ASSERT_WITH_SECURITY_IMPLICATION(static_cast<size_t>(n) <= strlen(s));
            memcpy(&buffer_[position_], s, n * kCharSize);
            position_ += n;
        }


        // Add character padding to the builder. If count is non-positive,
        // nothing is added to the builder.
        void AddPadding(char c, int count) {
            for (int i = 0; i < count; i++) {
                AddCharacter(c);
            }
        }

        // Finalize the string by 0-terminating it and returning the buffer.
        char* Finalize() {
            ASSERT(!is_finalized() && position_ < buffer_.length());
            buffer_[position_] = '\0';
            // Make sure nobody managed to add a 0-character to the
            // buffer while building the string.
            ASSERT(strlen(buffer_.start()) == static_cast<size_t>(position_));
            position_ = -1;
            ASSERT(is_finalized());
            return buffer_.start();
        }

    private:
        Vector<char> buffer_;
        int position_;

        bool is_finalized() const { return position_ < 0; }

        DISALLOW_IMPLICIT_CONSTRUCTORS(StringBuilder);
    };

    // The type-based aliasing rule allows the compiler to assume that pointers of
    // different types (for some definition of different) never alias each other.
    // Thus the following code does not work:
    //
    // float f = foo();
    // int fbits = *(int*)(&f);
    //
    // The compiler 'knows' that the int pointer can't refer to f since the types
    // don't match, so the compiler may cache f in a register, leaving random data
    // in fbits.  Using C++ style casts makes no difference, however a pointer to
    // char data is assumed to alias any other pointer.  This is the 'memcpy
    // exception'.
    //
    // Bit_cast uses the memcpy exception to move the bits from a variable of one
    // type of a variable of another type.  Of course the end result is likely to
    // be implementation dependent.  Most compilers (gcc-4.2 and MSVC 2005)
    // will completely optimize BitCast away.
    //
    // There is an additional use for BitCast.
    // Recent gccs will warn when they see casts that may result in breakage due to
    // the type-based aliasing rule.  If you have checked that there is no breakage
    // you can use BitCast to cast one pointer type to another.  This confuses gcc
    // enough that it can no longer see that you have cast one pointer type to
    // another thus avoiding the warning.
    template <class Dest, class Source>
    inline Dest BitCast(const Source& source) {
        // Compile time assertion: sizeof(Dest) == sizeof(Source)
        // A compile error here means your Dest and Source have different sizes.
        COMPILE_ASSERT(sizeof(Dest) == sizeof(Source), VerifySizesAreEqual);

        Dest dest;
        memcpy(&dest, &source, sizeof(dest));
        return dest;
    }

    template <class Dest, class Source>
    inline Dest BitCast(Source* source) {
        return BitCast<Dest>(reinterpret_cast<uintptr_t>(source));
    }

}  // namespace double_conversion

} // namespace WTF

#endif  // DOUBLE_CONVERSION_UTILS_H_

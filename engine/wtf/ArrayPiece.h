// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ArrayPiece_h
#define ArrayPiece_h

#include "wtf/Forward.h"
#include "wtf/WTFExport.h"

namespace WTF {

// This class is for passing around un-owned bytes as a pointer + length.
// It supports implicit conversion from several other data types.
//
// ArrayPiece has the concept of being "null". This is different from an empty
// byte range. It is invalid to call methods other than isNull() on such
// instances.
//
// IMPORTANT: The data contained by ArrayPiece is NOT OWNED, so caution must be
//            taken to ensure it is kept alive.
class WTF_EXPORT ArrayPiece {
public:
    // Constructs a "null" ArrayPiece object.
    ArrayPiece();

    ArrayPiece(void* data, unsigned byteLength);

    // Constructs an ArrayPiece from the given ArrayBuffer. If the input is a
    // nullptr, then the constructed instance will be isNull().
    ArrayPiece(ArrayBuffer*);
    ArrayPiece(ArrayBufferView*);

    bool isNull() const;
    void* data() const;
    unsigned char* bytes() const;
    unsigned byteLength() const;

private:
    void initWithData(void* data, unsigned byteLength);
    void initNull();

    void* m_data;
    unsigned m_byteLength;
    bool m_isNull;
};

} // namespace WTF

using WTF::ArrayPiece;

#endif // ArrayPiece_h

// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RefVector_h
#define RefVector_h

#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"

namespace blink {

template <typename T>
class RefVector : public RefCounted<RefVector<T> > {
public:
    static PassRefPtr<RefVector> create() { return adoptRef(new RefVector<T>); }
    PassRefPtr<RefVector> copy() { return adoptRef(new RefVector<T>(*this)); }

    const T& operator[](size_t i) const { return m_vector[i]; }
    T& operator[](size_t i) { return m_vector[i]; }
    const T& at(size_t i) const { return m_vector.at(i); }
    T& at(size_t i) { return m_vector.at(i); }

    bool operator==(const RefVector& o) const { return m_vector == o.m_vector; }
    bool operator!=(const RefVector& o) const { return m_vector != o.m_vector; }

    size_t size() const { return m_vector.size(); }
    void append(const T& decoration) { m_vector.append(decoration); }
    const Vector<T>& vector() const { return m_vector; }

private:
    Vector<T> m_vector;
    RefVector() { }
    RefVector(const RefVector& o) : m_vector(o.m_vector) { }
};

} // namespace blink

#endif // RefVector_h

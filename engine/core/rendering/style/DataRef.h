/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2008 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef DataRef_h
#define DataRef_h

#include "wtf/RefPtr.h"

namespace blink {

template <typename T> class DataRef {
public:
    const T* get() const { return m_data.get(); }

    const T& operator*() const { return *get(); }
    const T* operator->() const { return get(); }

    T* access()
    {
        if (!m_data->hasOneRef())
            m_data = m_data->copy();
        return m_data.get();
    }

    void init()
    {
        ASSERT(!m_data);
        m_data = T::create();
    }

    bool operator==(const DataRef<T>& o) const
    {
        ASSERT(m_data);
        ASSERT(o.m_data);
        return m_data == o.m_data || *m_data == *o.m_data;
    }

    bool operator!=(const DataRef<T>& o) const
    {
        ASSERT(m_data);
        ASSERT(o.m_data);
        return m_data != o.m_data && *m_data != *o.m_data;
    }

private:
    RefPtr<T> m_data;
};

} // namespace blink

#endif // DataRef_h

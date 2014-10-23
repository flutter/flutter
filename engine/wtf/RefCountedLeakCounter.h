/*
 *  Copyright (C) 2008 Apple Inc. All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 */

#ifndef RefCountedLeakCounter_h
#define RefCountedLeakCounter_h

#include "wtf/Assertions.h"
#include "wtf/WTFExport.h"

namespace WTF {

    struct WTF_EXPORT RefCountedLeakCounter {
        static void suppressMessages(const char*);
        static void cancelMessageSuppression(const char*);

        explicit RefCountedLeakCounter(const char* description);
        ~RefCountedLeakCounter();

        void increment();
        void decrement();

#if ENABLE(ASSERT)
    private:
        volatile int m_count;
        const char* m_description;
#endif
    };

}  // namespace WTF

#endif

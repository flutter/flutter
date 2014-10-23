/*
 * Copyright (C) 2006 Apple Computer, Inc.
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

#ifndef StaticConstructors_h
#define StaticConstructors_h

// We need to avoid having static constructors. This is accomplished by defining
// a static array of the appropriate size and alignment, and defining a const
// reference that points to the buffer. During initialization, the object will
// be constructed with placement new into the buffer. This works with MSVC, GCC,
// and Clang without producing dynamic initialization code even at -O0. The only
// downside is that all external translation units will have to emit one more
// load, while a real global could be referenced directly by absolute or
// relative addressing.

// Use an array of pointers instead of an array of char in case there is some alignment issue.
#define DEFINE_GLOBAL(type, name, ...) \
    void* name##Storage[(sizeof(type) + sizeof(void *) - 1) / sizeof(void *)]; \
    const type& name = *reinterpret_cast<type*>(&name##Storage);

#endif // StaticConstructors_h

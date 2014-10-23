/*
 * Copyright (C) 2004, 2005, 2006, 2013 Apple Inc.
 * Copyright (C) 2009 Google Inc. All rights reserved.
 * Copyright (C) 2007-2009 Torch Mobile, Inc.
 * Copyright (C) 2010, 2011 Research In Motion Limited. All rights reserved.
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

/* Include compiler specific macros */
#include "wtf/Compiler.h"

#if COMPILER(MSVC)
#define _USE_MATH_DEFINES // Make math.h behave like other platforms.
#endif

/* ==== Platform adaptation macros: these describe properties of the target environment. ==== */

/* HAVE() - specific system features (headers, functions or similar) that are present or not */
#define HAVE(WTF_FEATURE) (defined HAVE_##WTF_FEATURE  && HAVE_##WTF_FEATURE)
/* OS() - underlying operating system; only to be used for mandated low-level services like
   virtual memory, not to choose a GUI toolkit */
#define OS(WTF_FEATURE) (defined WTF_OS_##WTF_FEATURE  && WTF_OS_##WTF_FEATURE)

/* ==== Policy decision macros: these define policy choices for a particular port. ==== */

/* USE() - use a particular third-party library or optional OS service */
#define USE(WTF_FEATURE) (defined WTF_USE_##WTF_FEATURE  && WTF_USE_##WTF_FEATURE)
/* ENABLE() - turn on a specific feature of WebKit */
#define ENABLE(WTF_FEATURE) (defined ENABLE_##WTF_FEATURE  && ENABLE_##WTF_FEATURE)

/* ==== OS() - underlying operating system; only to be used for mandated low-level services like
   virtual memory, not to choose a GUI toolkit ==== */

/* OS(ANDROID) - Android */
#ifdef ANDROID
#define WTF_OS_ANDROID 1
/* OS(MACOSX) - Any Darwin-based OS, including Mac OS X and iPhone OS */
#elif defined(__APPLE__)
#define WTF_OS_MACOSX 1
/* OS(FREEBSD) - FreeBSD */
#elif defined(__FreeBSD__) || defined(__DragonFly__) || defined(__FreeBSD_kernel__)
#define WTF_OS_FREEBSD 1
/* OS(LINUX) - Linux */
#elif defined(__linux__)
#define WTF_OS_LINUX 1
/* OS(OPENBSD) - OpenBSD */
#elif defined(__OpenBSD__)
#define WTF_OS_OPENBSD 1
/* OS(WIN) - Any version of Windows */
#elif defined(WIN32) || defined(_WIN32)
#define WTF_OS_WIN 1
#endif

/* OS(POSIX) - Any Unix-like system */
#if OS(ANDROID)          \
    || OS(MACOSX)           \
    || OS(FREEBSD)          \
    || OS(LINUX)            \
    || OS(OPENBSD)          \
    || defined(unix)        \
    || defined(__unix)      \
    || defined(__unix__)
#define WTF_OS_POSIX 1
#endif

/* There is an assumption in the project that either OS(WIN) or OS(POSIX) is set. */
#if !OS(WIN) && !OS(POSIX)
#error Either OS(WIN) or OS(POSIX) needs to be set.
#endif

/* Operating environments */

#if OS(ANDROID)
#define WTF_USE_LOW_QUALITY_IMAGE_INTERPOLATION 1
#define WTF_USE_LOW_QUALITY_IMAGE_NO_JPEG_DITHERING 1
#define WTF_USE_LOW_QUALITY_IMAGE_NO_JPEG_FANCY_UPSAMPLING 1
#else
#define WTF_USE_ICCJPEG 1
#define WTF_USE_QCMSLIB 1
#endif

#if OS(MACOSX)
#define WTF_USE_CF 1
#endif /* OS(MACOSX) */

#if OS(POSIX)
#define HAVE_SIGNAL_H 1
#define HAVE_SYS_TIME_H 1
#define WTF_USE_PTHREADS 1
#endif /* OS(POSIX) */

#if !OS(WIN) && !OS(ANDROID)
#define HAVE_TM_GMTOFF 1
#define HAVE_TM_ZONE 1
#define HAVE_TIMEGM 1
#endif

#if OS(MACOSX)
#define WTF_USE_NEW_THEME 1
#endif /* OS(MACOSX) */

#if OS(WIN)

// If we don't define these, they get defined in windef.h.
// We want to use std::min and std::max.
#ifndef max
#define max max
#endif
#ifndef min
#define min min
#endif

#endif /* OS(WIN) */

#ifdef __cplusplus

// These undefs match up with defines in build/mac/Prefix.h for Mac OS X.
// Helps us catch if anyone uses new or delete by accident in code and doesn't include "config.h".
#undef new
#undef delete
#include <ciso646>
#include <cstddef>

#endif

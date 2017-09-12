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

#ifndef SKY_ENGINE_WTF_OPERATING_SYSTEM_H_
#define SKY_ENGINE_WTF_OPERATING_SYSTEM_H_

/* ==== Platform adaptation macros: these describe properties of the target
 * environment. ==== */

/* HAVE() - specific system features (headers, functions or similar) that are
 * present or not */
#define HAVE(WTF_FEATURE) (defined HAVE_##WTF_FEATURE && HAVE_##WTF_FEATURE)
/* OS() - underlying operating system; only to be used for mandated low-level
   services like virtual memory, not to choose a GUI toolkit */
#define OS(WTF_FEATURE) (defined WTF_OS_##WTF_FEATURE && WTF_OS_##WTF_FEATURE)

/* ==== Policy decision macros: these define policy choices for a particular
 * port. ==== */

/* USE() - use a particular third-party library or optional OS service */
#define USE(WTF_FEATURE) \
  (defined WTF_USE_##WTF_FEATURE && WTF_USE_##WTF_FEATURE)
/* ENABLE() - turn on a specific feature of WebKit */
#define ENABLE(WTF_FEATURE) \
  (defined ENABLE_##WTF_FEATURE && ENABLE_##WTF_FEATURE)

/* ==== OS() - underlying operating system; only to be used for mandated
   low-level services like virtual memory, not to choose a GUI toolkit ==== */

/* OS(ANDROID) - Android */
#ifdef ANDROID
#define WTF_OS_ANDROID 1
/* OS(LINUX) - Linux */
#elif defined(__linux__)
#define WTF_OS_LINUX 1
#endif

#ifdef __Fuchsia__
#define WTF_OS_FUCHSIA 1
#endif

/* Always OS(POSIX) */
#define WTF_OS_POSIX 1

#ifdef __APPLE__
/* OS(MACOSX) - Mac and iOS */
#define WTF_OS_MACOSX 1
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
/* OS(IOS) - iOS */
#define WTF_OS_IOS 1
#endif
#endif /* __APPLE__ */

/* Operating environments */

#if OS(ANDROID) || OS(IOS) || OS(MACOSX) || OS(LINUX)
#define WTF_USE_LOW_QUALITY_IMAGE_INTERPOLATION 1
#define WTF_USE_LOW_QUALITY_IMAGE_NO_JPEG_DITHERING 1
#define WTF_USE_LOW_QUALITY_IMAGE_NO_JPEG_FANCY_UPSAMPLING 1
#else
#define WTF_USE_ICCJPEG 1
#define WTF_USE_QCMSLIB 1
#endif

#if OS(POSIX)
#define HAVE_SIGNAL_H 1
#define HAVE_SYS_TIME_H 1
#define WTF_USE_PTHREADS 1
#endif

#endif  // SKY_ENGINE_WTF_OPERATING_SYSTEM_H_

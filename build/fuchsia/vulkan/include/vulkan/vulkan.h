#ifndef VULKAN_H_
#define VULKAN_H_ 1

/*
** Copyright (c) 2015-2018 The Khronos Group Inc.
**
** Licensed under the Apache License, Version 2.0 (the "License");
** you may not use this file except in compliance with the License.
** You may obtain a copy of the License at
**
**     http://www.apache.org/licenses/LICENSE-2.0
**
** Unless required by applicable law or agreed to in writing, software
** distributed under the License is distributed on an "AS IS" BASIS,
** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
** See the License for the specific language governing permissions and
** limitations under the License.
*/

#include "vk_platform.h"
#include "vulkan_core.h"

#ifdef VK_USE_PLATFORM_ANDROID_KHR
#include "vulkan_android.h"
#endif

#if defined(VK_USE_PLATFORM_FUCHSIA) || defined(VK_USE_PLATFORM_MAGMA_KHR)
#include <zircon/types.h>
#include "vulkan_fuchsia.h"
#endif

#ifdef VK_USE_PLATFORM_IOS_MVK
#include "vulkan_ios.h"
#endif


#ifdef VK_USE_PLATFORM_MACOS_MVK
#include "vulkan_macos.h"
#endif


#ifdef VK_USE_PLATFORM_MIR_KHR
#include <mir_toolkit/client_types.h>
#include "vulkan_mir.h"
#endif


#ifdef VK_USE_PLATFORM_VI_NN
#include "vulkan_vi.h"
#endif


#ifdef VK_USE_PLATFORM_WAYLAND_KHR
#include <wayland-client.h>
#include "vulkan_wayland.h"
#endif


#ifdef VK_USE_PLATFORM_WIN32_KHR
#include <windows.h>
#include "vulkan_win32.h"
#endif


#ifdef VK_USE_PLATFORM_XCB_KHR
#include <xcb/xcb.h>
#include "vulkan_xcb.h"
#endif


#ifdef VK_USE_PLATFORM_XLIB_KHR
#include <X11/Xlib.h>
#include "vulkan_xlib.h"
#endif


#ifdef VK_USE_PLATFORM_XLIB_XRANDR_EXT
#include <X11/Xlib.h>
#include <X11/extensions/Xrandr.h>
#include "vulkan_xlib_xrandr.h"
#endif

#endif // VULKAN_H_

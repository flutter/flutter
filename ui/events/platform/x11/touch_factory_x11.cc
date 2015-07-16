// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/x11/touch_factory_x11.h"

#include <X11/cursorfont.h>
#include <X11/extensions/XInput.h>
#include <X11/extensions/XInput2.h>
#include <X11/extensions/XIproto.h>
#include <X11/Xatom.h>

#include "base/basictypes.h"
#include "base/command_line.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/memory/singleton.h"
#include "base/message_loop/message_loop.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/sys_info.h"
#include "ui/events/event_switches.h"
#include "ui/events/platform/x11/device_data_manager_x11.h"
#include "ui/events/platform/x11/device_list_cache_x.h"
#include "ui/gfx/x/x11_types.h"

namespace ui {

TouchFactory::TouchFactory()
    : pointer_device_lookup_(),
      touch_events_disabled_(false),
      touch_device_list_(),
      max_touch_points_(-1),
      virtual_core_keyboard_device_(-1),
      id_generator_(0) {
  if (!DeviceDataManagerX11::GetInstance()->IsXInput2Available())
    return;

  XDisplay* display = gfx::GetXDisplay();
  UpdateDeviceList(display);

  base::CommandLine* cmdline = base::CommandLine::ForCurrentProcess();
  touch_events_disabled_ =
      cmdline->HasSwitch(switches::kTouchEvents) &&
      cmdline->GetSwitchValueASCII(switches::kTouchEvents) ==
          switches::kTouchEventsDisabled;
}

TouchFactory::~TouchFactory() {
}

// static
TouchFactory* TouchFactory::GetInstance() {
  return Singleton<TouchFactory>::get();
}

// static
void TouchFactory::SetTouchDeviceListFromCommandLine() {
  // Get a list of pointer-devices that should be treated as touch-devices.
  // This is primarily used for testing/debugging touch-event processing when a
  // touch-device isn't available.
  std::string touch_devices =
      base::CommandLine::ForCurrentProcess()->GetSwitchValueASCII(
          switches::kTouchDevices);

  if (!touch_devices.empty()) {
    std::vector<std::string> devs;
    std::vector<unsigned int> device_ids;
    unsigned int devid;
    base::SplitString(touch_devices, ',', &devs);
    for (std::vector<std::string>::iterator iter = devs.begin();
         iter != devs.end(); ++iter) {
      if (base::StringToInt(*iter, reinterpret_cast<int*>(&devid)))
        device_ids.push_back(devid);
      else
        DLOG(WARNING) << "Invalid touch-device id: " << *iter;
    }
    ui::TouchFactory::GetInstance()->SetTouchDeviceList(device_ids);
  }
}

void TouchFactory::UpdateDeviceList(Display* display) {
  // Detect touch devices.
  touch_device_lookup_.reset();
  touch_device_list_.clear();
  touchscreen_ids_.clear();
  max_touch_points_ = -1;

#if !defined(USE_XI2_MT)
  // NOTE: The new API for retrieving the list of devices (XIQueryDevice) does
  // not provide enough information to detect a touch device. As a result, the
  // old version of query function (XListInputDevices) is used instead.
  // If XInput2 is not supported, this will return null (with count of -1) so
  // we assume there cannot be any touch devices.
  // With XI2.1 or older, we allow only single touch devices.
  XDeviceList dev_list =
      DeviceListCacheX::GetInstance()->GetXDeviceList(display);
  Atom xi_touchscreen = XInternAtom(display, XI_TOUCHSCREEN, false);
  for (int i = 0; i < dev_list.count; i++) {
    if (dev_list[i].type == xi_touchscreen) {
      touch_device_lookup_[dev_list[i].id] = true;
      touch_device_list_[dev_list[i].id] = false;
    }
  }
#endif

  if (!DeviceDataManagerX11::GetInstance()->IsXInput2Available())
    return;

  // Instead of asking X for the list of devices all the time, let's maintain a
  // list of pointer devices we care about.
  // It should not be necessary to select for slave devices. XInput2 provides
  // enough information to the event callback to decide which slave device
  // triggered the event, thus decide whether the 'pointer event' is a
  // 'mouse event' or a 'touch event'.
  // However, on some desktops, some events from a master pointer are
  // not delivered to the client. So we select for slave devices instead.
  // If the touch device has 'GrabDevice' set and 'SendCoreEvents' unset (which
  // is possible), then the device is detected as a floating device, and a
  // floating device is not connected to a master device. So it is necessary to
  // also select on the floating devices.
  pointer_device_lookup_.reset();
  XIDeviceList xi_dev_list =
      DeviceListCacheX::GetInstance()->GetXI2DeviceList(display);
  for (int i = 0; i < xi_dev_list.count; i++) {
    XIDeviceInfo* devinfo = xi_dev_list.devices + i;
    if (devinfo->use == XIFloatingSlave || devinfo->use == XIMasterPointer) {
#if defined(USE_XI2_MT)
      for (int k = 0; k < devinfo->num_classes; ++k) {
        XIAnyClassInfo* xiclassinfo = devinfo->classes[k];
        if (xiclassinfo->type == XITouchClass) {
          XITouchClassInfo* tci =
              reinterpret_cast<XITouchClassInfo*>(xiclassinfo);
          // Only care direct touch device (such as touch screen) right now
          if (tci->mode == XIDirectTouch) {
            touch_device_lookup_[devinfo->deviceid] = true;
            touch_device_list_[devinfo->deviceid] = true;
            if (tci->num_touches > 0 && tci->num_touches > max_touch_points_)
              max_touch_points_ = tci->num_touches;
          }
        }
      }
#endif
      pointer_device_lookup_[devinfo->deviceid] = true;
    } else if (devinfo->use == XIMasterKeyboard) {
      virtual_core_keyboard_device_ = devinfo->deviceid;
    }

#if defined(USE_XI2_MT)
    if (devinfo->use == XIFloatingSlave || devinfo->use == XISlavePointer) {
      for (int k = 0; k < devinfo->num_classes; ++k) {
        XIAnyClassInfo* xiclassinfo = devinfo->classes[k];
        if (xiclassinfo->type == XITouchClass) {
          XITouchClassInfo* tci =
              reinterpret_cast<XITouchClassInfo*>(xiclassinfo);
          // Only care direct touch device (such as touch screen) right now
          if (tci->mode == XIDirectTouch)
            CacheTouchscreenIds(display, devinfo->deviceid);
        }
      }
    }
#endif
  }
}

bool TouchFactory::ShouldProcessXI2Event(XEvent* xev) {
  DCHECK_EQ(GenericEvent, xev->type);
  XIEvent* event = static_cast<XIEvent*>(xev->xcookie.data);
  XIDeviceEvent* xiev = reinterpret_cast<XIDeviceEvent*>(event);

#if defined(USE_XI2_MT)
  if (event->evtype == XI_TouchBegin || event->evtype == XI_TouchUpdate ||
      event->evtype == XI_TouchEnd) {
    return !touch_events_disabled_ && IsTouchDevice(xiev->deviceid);
  }
#endif
  // Make sure only key-events from the virtual core keyboard are processed.
  if (event->evtype == XI_KeyPress || event->evtype == XI_KeyRelease) {
    return (virtual_core_keyboard_device_ < 0) ||
           (virtual_core_keyboard_device_ == xiev->deviceid);
  }

  if (event->evtype != XI_ButtonPress && event->evtype != XI_ButtonRelease &&
      event->evtype != XI_Motion)
    return true;

  if (!pointer_device_lookup_[xiev->deviceid])
    return false;

  return IsTouchDevice(xiev->deviceid) ? !touch_events_disabled_ : true;
}

void TouchFactory::SetupXI2ForXWindow(Window window) {
  // Setup mask for mouse events. It is possible that a device is loaded/plugged
  // in after we have setup XInput2 on a window. In such cases, we need to
  // either resetup XInput2 for the window, so that we get events from the new
  // device, or we need to listen to events from all devices, and then filter
  // the events from uninteresting devices. We do the latter because that's
  // simpler.

  XDisplay* display = gfx::GetXDisplay();

  unsigned char mask[XIMaskLen(XI_LASTEVENT)];
  memset(mask, 0, sizeof(mask));

#if defined(USE_XI2_MT)
  XISetMask(mask, XI_TouchBegin);
  XISetMask(mask, XI_TouchUpdate);
  XISetMask(mask, XI_TouchEnd);
#endif
  XISetMask(mask, XI_ButtonPress);
  XISetMask(mask, XI_ButtonRelease);
  XISetMask(mask, XI_Motion);
#if defined(OS_CHROMEOS)
  if (base::SysInfo::IsRunningOnChromeOS()) {
    XISetMask(mask, XI_KeyPress);
    XISetMask(mask, XI_KeyRelease);
  }
#endif

  XIEventMask evmask;
  evmask.deviceid = XIAllDevices;
  evmask.mask_len = sizeof(mask);
  evmask.mask = mask;
  XISelectEvents(display, window, &evmask, 1);
  XFlush(display);
}

void TouchFactory::SetTouchDeviceList(
    const std::vector<unsigned int>& devices) {
  touch_device_lookup_.reset();
  touch_device_list_.clear();
  for (std::vector<unsigned int>::const_iterator iter = devices.begin();
       iter != devices.end(); ++iter) {
    DCHECK(*iter < touch_device_lookup_.size());
    touch_device_lookup_[*iter] = true;
    touch_device_list_[*iter] = false;
  }
}

bool TouchFactory::IsTouchDevice(unsigned deviceid) const {
  return deviceid < touch_device_lookup_.size() ? touch_device_lookup_[deviceid]
                                                : false;
}

bool TouchFactory::IsMultiTouchDevice(unsigned int deviceid) const {
  return (deviceid < touch_device_lookup_.size() &&
          touch_device_lookup_[deviceid])
             ? touch_device_list_.find(deviceid)->second
             : false;
}

bool TouchFactory::QuerySlotForTrackingID(uint32 tracking_id, int* slot) {
  if (!id_generator_.HasGeneratedIDFor(tracking_id))
    return false;
  *slot = static_cast<int>(id_generator_.GetGeneratedID(tracking_id));
  return true;
}

int TouchFactory::GetSlotForTrackingID(uint32 tracking_id) {
  return id_generator_.GetGeneratedID(tracking_id);
}

void TouchFactory::AcquireSlotForTrackingID(uint32 tracking_id) {
  tracking_id_refcounts_[tracking_id]++;
}

void TouchFactory::ReleaseSlotForTrackingID(uint32 tracking_id) {
  tracking_id_refcounts_[tracking_id]--;
  if (tracking_id_refcounts_[tracking_id] == 0)
    id_generator_.ReleaseNumber(tracking_id);
}

bool TouchFactory::IsTouchDevicePresent() {
  return !touch_events_disabled_ && touch_device_lookup_.any();
}

int TouchFactory::GetMaxTouchPoints() const {
  return max_touch_points_;
}

void TouchFactory::ResetForTest() {
  pointer_device_lookup_.reset();
  touch_device_lookup_.reset();
  touch_events_disabled_ = false;
  touch_device_list_.clear();
  touchscreen_ids_.clear();
  tracking_id_refcounts_.clear();
  max_touch_points_ = -1;
  id_generator_.ResetForTest();
}

void TouchFactory::SetTouchDeviceForTest(
    const std::vector<unsigned int>& devices) {
  touch_device_lookup_.reset();
  touch_device_list_.clear();
  for (std::vector<unsigned int>::const_iterator iter = devices.begin();
       iter != devices.end(); ++iter) {
    DCHECK(*iter < touch_device_lookup_.size());
    touch_device_lookup_[*iter] = true;
    touch_device_list_[*iter] = true;
  }
  touch_events_disabled_ = false;
}

void TouchFactory::SetPointerDeviceForTest(
    const std::vector<unsigned int>& devices) {
  pointer_device_lookup_.reset();
  for (std::vector<unsigned int>::const_iterator iter = devices.begin();
       iter != devices.end(); ++iter) {
    pointer_device_lookup_[*iter] = true;
  }
}

void TouchFactory::CacheTouchscreenIds(Display* display, int device_id) {
  XDevice* device = XOpenDevice(display, device_id);
  if (!device)
    return;

  Atom actual_type_return;
  int actual_format_return;
  unsigned long nitems_return;
  unsigned long bytes_after_return;
  unsigned char* prop_return;

  const char kDeviceProductIdString[] = "Device Product ID";
  Atom device_product_id_atom =
      XInternAtom(display, kDeviceProductIdString, false);

  if (device_product_id_atom != None &&
      XGetDeviceProperty(display, device, device_product_id_atom, 0, 2, False,
                         XA_INTEGER, &actual_type_return, &actual_format_return,
                         &nitems_return, &bytes_after_return,
                         &prop_return) == Success) {
    if (actual_type_return == XA_INTEGER && actual_format_return == 32 &&
        nitems_return == 2) {
      // An actual_format_return of 32 implies that the returned data is an
      // array of longs. See the description of |prop_return| in `man
      // XGetDeviceProperty` for details.
      long* ptr = reinterpret_cast<long*>(prop_return);

      // Internal displays will have a vid and pid of 0. Ignore them.
      // ptr[0] is the vid, and ptr[1] is the pid.
      if (ptr[0] || ptr[1])
        touchscreen_ids_.insert(std::make_pair(ptr[0], ptr[1]));
    }
    XFree(prop_return);
  }

  XCloseDevice(display, device);
}

}  // namespace ui

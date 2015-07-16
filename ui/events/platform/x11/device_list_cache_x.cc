// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/x11/device_list_cache_x.h"

#include <algorithm>

#include "base/memory/singleton.h"
#include "base/message_loop/message_loop.h"
#include "ui/events/platform/x11/device_data_manager_x11.h"

namespace {

bool IsXI2Available() {
  return false;
}
}

namespace ui {

DeviceListCacheX::DeviceListCacheX() {
}

DeviceListCacheX::~DeviceListCacheX() {
  std::map<Display*, XDeviceList>::iterator xp;
  for (xp = x_dev_list_map_.begin(); xp != x_dev_list_map_.end(); xp++) {
    if (xp->second.devices)
      XFreeDeviceList(xp->second.devices);
  }
  std::map<Display*, XIDeviceList>::iterator xip;
  for (xip = xi_dev_list_map_.begin(); xip != xi_dev_list_map_.end(); xip++) {
    if (xip->second.devices)
      XIFreeDeviceInfo(xip->second.devices);
  }
}

DeviceListCacheX* DeviceListCacheX::GetInstance() {
  return Singleton<DeviceListCacheX>::get();
}

void DeviceListCacheX::UpdateDeviceList(Display* display) {
  XDeviceList& new_x_dev_list = x_dev_list_map_[display];
  if (new_x_dev_list.devices)
    XFreeDeviceList(new_x_dev_list.devices);
  new_x_dev_list.devices = XListInputDevices(display, &new_x_dev_list.count);

  XIDeviceList& new_xi_dev_list = xi_dev_list_map_[display];
  if (new_xi_dev_list.devices)
    XIFreeDeviceInfo(new_xi_dev_list.devices);
  new_xi_dev_list.devices =
      IsXI2Available()
          ? XIQueryDevice(display, XIAllDevices, &new_xi_dev_list.count)
          : NULL;
}

const XDeviceList& DeviceListCacheX::GetXDeviceList(Display* display) {
  XDeviceList& x_dev_list = x_dev_list_map_[display];
  // Note that the function can be called before any update has taken place.
  if (!x_dev_list.devices && !x_dev_list.count)
    x_dev_list.devices = XListInputDevices(display, &x_dev_list.count);
  return x_dev_list;
}

const XIDeviceList& DeviceListCacheX::GetXI2DeviceList(Display* display) {
  XIDeviceList& xi_dev_list = xi_dev_list_map_[display];
  if (!xi_dev_list.devices && !xi_dev_list.count) {
    xi_dev_list.devices =
        XIQueryDevice(display, XIAllDevices, &xi_dev_list.count);
  }
  return xi_dev_list;
}

}  // namespace ui

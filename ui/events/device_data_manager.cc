// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/device_data_manager.h"

#include "base/at_exit.h"
#include "base/bind.h"
#include "base/logging.h"
#include "ui/events/input_device_event_observer.h"
#include "ui/gfx/display.h"
#include "ui/gfx/geometry/point3_f.h"

namespace ui {

// static
DeviceDataManager* DeviceDataManager::instance_ = NULL;

DeviceDataManager::DeviceDataManager() {
  CHECK(!instance_) << "Can not create multiple instances of DeviceDataManager";
  instance_ = this;

  base::AtExitManager::RegisterTask(
      base::Bind(&base::DeletePointer<DeviceDataManager>, this));

  for (int i = 0; i < kMaxDeviceNum; ++i) {
    touch_device_to_display_map_[i] = gfx::Display::kInvalidDisplayID;
    touch_radius_scale_map_[i] = 1.0;
  }
}

DeviceDataManager::~DeviceDataManager() {
  CHECK_EQ(this, instance_);
  instance_ = NULL;
}

// static
DeviceDataManager* DeviceDataManager::instance() { return instance_; }

// static
void DeviceDataManager::CreateInstance() {
  if (instance())
    return;

  new DeviceDataManager();
}

// static
DeviceDataManager* DeviceDataManager::GetInstance() {
  CHECK(instance_) << "DeviceDataManager was not created.";
  return instance_;
}

// static
bool DeviceDataManager::HasInstance() {
  return instance_ != NULL;
}

void DeviceDataManager::ClearTouchTransformerRecord() {
  for (int i = 0; i < kMaxDeviceNum; i++) {
    touch_device_transformer_map_[i] = gfx::Transform();
    touch_device_to_display_map_[i] = gfx::Display::kInvalidDisplayID;
    touch_radius_scale_map_[i] = 1.0;
  }
}

bool DeviceDataManager::IsTouchDeviceIdValid(int touch_device_id) const {
  return (touch_device_id > 0 && touch_device_id < kMaxDeviceNum);
}

void DeviceDataManager::UpdateTouchInfoForDisplay(
    int64_t display_id,
    int touch_device_id,
    const gfx::Transform& touch_transformer) {
  if (IsTouchDeviceIdValid(touch_device_id)) {
    touch_device_to_display_map_[touch_device_id] = display_id;
    touch_device_transformer_map_[touch_device_id] = touch_transformer;
  }
}

void DeviceDataManager::UpdateTouchRadiusScale(int touch_device_id,
                                               double scale) {
  if (IsTouchDeviceIdValid(touch_device_id))
    touch_radius_scale_map_[touch_device_id] = scale;
}

void DeviceDataManager::ApplyTouchRadiusScale(int touch_device_id,
                                              double* radius) {
  if (IsTouchDeviceIdValid(touch_device_id))
    *radius = (*radius) * touch_radius_scale_map_[touch_device_id];
}

void DeviceDataManager::ApplyTouchTransformer(int touch_device_id,
                                              float* x,
                                              float* y) {
  if (IsTouchDeviceIdValid(touch_device_id)) {
    gfx::Point3F point(*x, *y, 0.0);
    const gfx::Transform& trans =
        touch_device_transformer_map_[touch_device_id];
    trans.TransformPoint(&point);
    *x = point.x();
    *y = point.y();
  }
}

int64_t DeviceDataManager::GetDisplayForTouchDevice(int touch_device_id) const {
  if (IsTouchDeviceIdValid(touch_device_id))
    return touch_device_to_display_map_[touch_device_id];
  return gfx::Display::kInvalidDisplayID;
}

void DeviceDataManager::OnTouchscreenDevicesUpdated(
    const std::vector<TouchscreenDevice>& devices) {
  touchscreen_devices_ = devices;

  FOR_EACH_OBSERVER(InputDeviceEventObserver,
                    observers_,
                    OnInputDeviceConfigurationChanged());
}

void DeviceDataManager::AddObserver(InputDeviceEventObserver* observer) {
  observers_.AddObserver(observer);
}

void DeviceDataManager::RemoveObserver(InputDeviceEventObserver* observer) {
  observers_.RemoveObserver(observer);
}

}  // namespace ui

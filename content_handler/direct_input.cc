// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/direct_input.h"

#include <dirent.h>
#include <fcntl.h>
#include <hid/acer12.h>
#include <hid/usages.h>
#include <magenta/device/device.h>
#include <magenta/device/input.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

#include "lib/fidl/cpp/waiter/default.h"
#include "lib/ftl/time/time_point.h"

namespace flutter_runner {

static constexpr char kDevInput[] = "/dev/class/input";

DirectInput::DirectInput(DirectInputCallback callback)
    : callback_(callback), valid_(false), last_wait_(0) {
  FTL_DCHECK(callback_ != nullptr);

  // Setup the touch file descriptor.

  touch_fd_ = GetTouchFileDescriptor();

  if (!touch_fd_.is_valid()) {
    FTL_DLOG(INFO) << "Could not get the touch file descriptor on the Acer.";
    return;
  }

  // Get device event handle.

  mx_handle_t input_event = 0;
  ssize_t ret = mxio_ioctl(touch_fd_.get(), IOCTL_DEVICE_GET_EVENT_HANDLE,
                           nullptr, 0, &input_event, sizeof(input_event));

  if (ret < 0) {
    FTL_DLOG(INFO) << "Could not get device event handle.";
    return;
  }

  input_event_.reset(input_event);

  // Prepare buffer that we read into from the touch file descriptor.

  size_t max_report_len = 0;
  ret = mxio_ioctl(touch_fd_.get(), IOCTL_INPUT_GET_MAX_REPORTSIZE, nullptr, 0,
                   &max_report_len, sizeof(max_report_len));
  if (ret < 0) {
    FTL_DLOG(INFO)
        << "Could not read the max report size on the touch file descriptor";
    return;
  }

  read_buffer_.resize(max_report_len);

  valid_ = true;
}

DirectInput::~DirectInput() {
  CancelWaitForReadAvailability();
}

bool DirectInput::IsValid() const {
  return valid_;
}

void DirectInput::WaitForReadAvailability() {
  CancelWaitForReadAvailability();

  FidlAsyncWaitCallback callback = [](mx_status_t result, mx_signals_t pending,
                                      void* baton) {
    if (result != NO_ERROR) {
      FTL_DLOG(INFO) << "Error while waiting on read availablility.";
      return;
    }

    if (!(pending & DEVICE_SIGNAL_READABLE)) {
      FTL_DLOG(INFO) << "Wait callback fired but not read pending.";
      return;
    }

    reinterpret_cast<DirectInput*>(baton)->OnReadAvailable();
  };

  last_wait_ = fidl::GetDefaultAsyncWaiter()->AsyncWait(
      input_event_.get(), DEVICE_SIGNAL_READABLE, MX_TIME_INFINITE, callback,
      this);
}

void DirectInput::CancelWaitForReadAvailability() {
  if (last_wait_ == 0) {
    return;
  }

  fidl::GetDefaultAsyncWaiter()->CancelWait(last_wait_);
  last_wait_ = 0;
}

void DirectInput::OnReadAvailable() {
  last_wait_ = 0;
  PerformRead();
  WaitForReadAvailability();
}

void DirectInput::PerformRead() {
  ssize_t ret =
      ::read(touch_fd_.get(), read_buffer_.data(), read_buffer_.size());

  if (ret < 0) {
    return;
  }

  if (read_buffer_[0] != ACER12_RPT_ID_TOUCH) {
    return;
  }

  acer12_touch_t* report =
      reinterpret_cast<acer12_touch_t*>(read_buffer_.data());

  size_t fingers_count = std::min<size_t>(5, report->contact_count);

  int64_t timestamp = ftl::TimePoint::Now().ToEpochDelta().ToMilliseconds();

  if (fingers_count == 0) {
    return;
  }

  blink::PointerDataPacket packet(fingers_count);

  for (uint8_t i = 0; i < fingers_count; i++) {
    const acer12_finger& finger = report->fingers[i];

    int64_t touch_identifier = acer12_finger_id_contact(finger.finger_id);

    blink::PointerData pointer_data;
    pointer_data.Clear();

    pointer_data.time_stamp = timestamp;
    pointer_data.kind = blink::PointerData::DeviceKind::kTouch;
    pointer_data.device = touch_identifier;

    pointer_data.physical_x = ((static_cast<float>(finger.x) / ACER12_X_MAX) *
                               viewport_metrics_.physical_width);
    pointer_data.physical_y = ((static_cast<float>(finger.y) / ACER12_Y_MAX) *
                               viewport_metrics_.physical_height);

    bool down = !!acer12_finger_id_tswitch(finger.finger_id);

    if (down) {
      auto insertion_result = touch_ids_.insert(touch_identifier);
      // If we could add the touch indentifier to the set of tracked touches, it
      // means that we were not already tracking it before. That means it is
      // kDown. In not, it is a kMove of a previous report.
      pointer_data.change = insertion_result.second
                                ? blink::PointerData::Change::kDown
                                : blink::PointerData::Change::kMove;
    } else {
      touch_ids_.erase(touch_identifier);
      pointer_data.change = blink::PointerData::Change::kUp;
    }

    packet.SetPointerData(i, pointer_data);
  }

  callback_(packet);
}

ftl::UniqueFD DirectInput::GetTouchFileDescriptor() {
  DIR* dir = ::opendir(kDevInput);

  if (!dir) {
    return {};
  }

  std::string device_dir = kDevInput;

  device_dir += "/";

  struct dirent* dir_entry = nullptr;

  while ((dir_entry = readdir(dir)) != nullptr) {
    std::string device_path = device_dir + dir_entry->d_name;

    ftl::UniqueFD fd(::open(device_path.c_str(), O_RDONLY));

    if (!fd.is_valid()) {
      continue;
    }

    size_t report_desc_len = 0;

    ssize_t ret =
        mxio_ioctl(fd.get(), IOCTL_INPUT_GET_REPORT_DESC_SIZE, nullptr, 0,
                   &report_desc_len, sizeof(report_desc_len));

    if (ret < 0) {
      continue;
    }

    if (report_desc_len != ACER12_RPT_DESC_LEN) {
      continue;
    }

    std::vector<uint8_t> report_desc(report_desc_len);

    ret = mxio_ioctl(fd.get(), IOCTL_INPUT_GET_REPORT_DESC, nullptr, 0,
                     report_desc.data(), report_desc.size());

    if (ret < 0) {
      continue;
    }

    if (!memcmp(report_desc.data(), acer12_touch_report_desc,
                ACER12_RPT_DESC_LEN)) {
      ::closedir(dir);
      return fd;
    }
  }

  ::closedir(dir);
  return {};
}

void DirectInput::SetViewportMetrics(blink::ViewportMetrics metrics) {
  viewport_metrics_ = metrics;
}

}  // namespace flutter_runner

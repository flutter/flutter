// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gpu_switching_manager.h"

#include "base/command_line.h"
#include "base/logging.h"
#include "ui/gl/gl_switches.h"

namespace ui {

// static
GpuSwitchingManager* GpuSwitchingManager::GetInstance() {
  return Singleton<GpuSwitchingManager>::get();
}

GpuSwitchingManager::GpuSwitchingManager()
    : gpu_switching_option_(gfx::PreferIntegratedGpu),
      gpu_switching_option_set_(false),
      supports_dual_gpus_(false),
      supports_dual_gpus_set_(false),
      gpu_count_(0) {
}

GpuSwitchingManager::~GpuSwitchingManager() {
}

void GpuSwitchingManager::ForceUseOfIntegratedGpu() {
  DCHECK(SupportsDualGpus());
  if (gpu_switching_option_set_) {
    DCHECK_EQ(gpu_switching_option_, gfx::PreferIntegratedGpu);
  } else {
    gpu_switching_option_ = gfx::PreferIntegratedGpu;
    gpu_switching_option_set_ = true;
  }
}

void GpuSwitchingManager::ForceUseOfDiscreteGpu() {
  DCHECK(SupportsDualGpus());
  if (gpu_switching_option_set_) {
    DCHECK_EQ(gpu_switching_option_, gfx::PreferDiscreteGpu);
  } else {
    gpu_switching_option_ = gfx::PreferDiscreteGpu;
    gpu_switching_option_set_ = true;
  }
}

bool GpuSwitchingManager::SupportsDualGpus() {
  if (!supports_dual_gpus_set_) {
    const base::CommandLine& command_line =
        *base::CommandLine::ForCurrentProcess();
    bool flag = false;
    if (command_line.HasSwitch(switches::kSupportsDualGpus)) {
      // GPU process, flag is passed down from browser process.
      std::string flag_string = command_line.GetSwitchValueASCII(
          switches::kSupportsDualGpus);
      if (flag_string == "true") {
        flag = true;
      } else if (flag_string == "false") {
        flag = false;
      } else {
        NOTIMPLEMENTED();
      }
    }
    supports_dual_gpus_ = flag;
    supports_dual_gpus_set_ = true;
  }
  return supports_dual_gpus_;
}

void GpuSwitchingManager::SetGpuCount(size_t gpu_count) {
  gpu_count_ = gpu_count;
}

void GpuSwitchingManager::AddObserver(GpuSwitchingObserver* observer) {
  observer_list_.AddObserver(observer);
}

void GpuSwitchingManager::RemoveObserver(GpuSwitchingObserver* observer) {
  observer_list_.RemoveObserver(observer);
}

void GpuSwitchingManager::NotifyGpuSwitched() {
  FOR_EACH_OBSERVER(GpuSwitchingObserver, observer_list_, OnGpuSwitched());
}

gfx::GpuPreference GpuSwitchingManager::AdjustGpuPreference(
    gfx::GpuPreference gpu_preference) {
  if (!gpu_switching_option_set_)
    return gpu_preference;
  return gpu_switching_option_;
}

}  // namespace ui

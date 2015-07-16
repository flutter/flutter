// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_info.h"

namespace {

void EnumerateGPUDevice(gpu::GPUInfo::Enumerator* enumerator,
                        const gpu::GPUInfo::GPUDevice& device) {
  enumerator->BeginGPUDevice();
  enumerator->AddInt("vendorId", device.vendor_id);
  enumerator->AddInt("deviceId", device.device_id);
  enumerator->AddBool("active", device.active);
  enumerator->AddString("vendorString", device.vendor_string);
  enumerator->AddString("deviceString", device.device_string);
  enumerator->EndGPUDevice();
}

void EnumerateVideoEncodeAcceleratorSupportedProfile(
    gpu::GPUInfo::Enumerator* enumerator,
    const gpu::VideoEncodeAcceleratorSupportedProfile profile) {
  enumerator->BeginVideoEncodeAcceleratorSupportedProfile();
  enumerator->AddInt("profile", profile.profile);
  enumerator->AddInt("maxResolutionWidth", profile.max_resolution.width());
  enumerator->AddInt("maxResolutionHeight", profile.max_resolution.height());
  enumerator->AddInt("maxFramerateNumerator", profile.max_framerate_numerator);
  enumerator->AddInt("maxFramerateDenominator",
                     profile.max_framerate_denominator);
  enumerator->EndVideoEncodeAcceleratorSupportedProfile();
}

}  // namespace

namespace gpu {

GPUInfo::GPUDevice::GPUDevice()
    : vendor_id(0),
      device_id(0),
      active(false) {
}

GPUInfo::GPUDevice::~GPUDevice() { }

GPUInfo::GPUInfo()
    : optimus(false),
      amd_switchable(false),
      lenovo_dcute(false),
      adapter_luid(0),
      gl_reset_notification_strategy(0),
      can_lose_context(false),
      software_rendering(false),
      direct_rendering(true),
      sandboxed(false),
      process_crash_count(0),
      basic_info_state(kCollectInfoNone),
#if defined(OS_WIN)
      context_info_state(kCollectInfoNone),
      dx_diagnostics_info_state(kCollectInfoNone) {
#else
      context_info_state(kCollectInfoNone) {
#endif
}

GPUInfo::~GPUInfo() { }

void GPUInfo::EnumerateFields(Enumerator* enumerator) const {
  struct GPUInfoKnownFields {
    base::TimeDelta initialization_time;
    bool optimus;
    bool amd_switchable;
    bool lenovo_dcute;
    Version display_link_version;
    GPUDevice gpu;
    std::vector<GPUDevice> secondary_gpus;
    uint64 adapter_luid;
    std::string driver_vendor;
    std::string driver_version;
    std::string driver_date;
    std::string pixel_shader_version;
    std::string vertex_shader_version;
    std::string machine_model_name;
    std::string machine_model_version;
    std::string gl_version_string;
    std::string gl_vendor;
    std::string gl_renderer;
    std::string gl_extensions;
    std::string gl_ws_vendor;
    std::string gl_ws_version;
    std::string gl_ws_extensions;
    uint32 gl_reset_notification_strategy;
    bool can_lose_context;
    bool software_rendering;
    bool direct_rendering;
    bool sandboxed;
    int process_crash_count;
    CollectInfoResult basic_info_state;
    CollectInfoResult context_info_state;
#if defined(OS_WIN)
    CollectInfoResult dx_diagnostics_info_state;
    DxDiagNode dx_diagnostics;
#endif
    std::vector<VideoEncodeAcceleratorSupportedProfile>
        video_encode_accelerator_supported_profiles;
  };

  // If this assert fails then most likely something below needs to be updated.
  // Note that this assert is only approximate. If a new field is added to
  // GPUInfo which fits within the current padding then it will not be caught.
  static_assert(
      sizeof(GPUInfo) == sizeof(GPUInfoKnownFields),
      "fields have changed in GPUInfo, GPUInfoKnownFields must be updated");

  // Required fields (according to DevTools protocol) first.
  enumerator->AddString("machineModelName", machine_model_name);
  enumerator->AddString("machineModelVersion", machine_model_version);
  EnumerateGPUDevice(enumerator, gpu);
  for (size_t ii = 0; ii < secondary_gpus.size(); ++ii) {
    EnumerateGPUDevice(enumerator, secondary_gpus[ii]);
  }

  enumerator->BeginAuxAttributes();
  enumerator->AddTimeDeltaInSecondsF("initializationTime",
                                     initialization_time);
  enumerator->AddBool("optimus", optimus);
  enumerator->AddBool("amdSwitchable", amd_switchable);
  enumerator->AddBool("lenovoDcute", lenovo_dcute);
  if (display_link_version.IsValid()) {
    enumerator->AddString("displayLinkVersion",
                          display_link_version.GetString());
  }
  enumerator->AddInt64("adapterLuid", adapter_luid);
  enumerator->AddString("driverVendor", driver_vendor);
  enumerator->AddString("driverVersion", driver_version);
  enumerator->AddString("driverDate", driver_date);
  enumerator->AddString("pixelShaderVersion", pixel_shader_version);
  enumerator->AddString("vertexShaderVersion", vertex_shader_version);
  enumerator->AddString("glVersion", gl_version);
  enumerator->AddString("glVendor", gl_vendor);
  enumerator->AddString("glRenderer", gl_renderer);
  enumerator->AddString("glExtensions", gl_extensions);
  enumerator->AddString("glWsVendor", gl_ws_vendor);
  enumerator->AddString("glWsVersion", gl_ws_version);
  enumerator->AddString("glWsExtensions", gl_ws_extensions);
  enumerator->AddInt(
      "glResetNotificationStrategy",
      static_cast<int>(gl_reset_notification_strategy));
  enumerator->AddBool("can_lose_context", can_lose_context);
  // TODO(kbr): add performance_stats.
  enumerator->AddBool("softwareRendering", software_rendering);
  enumerator->AddBool("directRendering", direct_rendering);
  enumerator->AddBool("sandboxed", sandboxed);
  enumerator->AddInt("processCrashCount", process_crash_count);
  enumerator->AddInt("basicInfoState", basic_info_state);
  enumerator->AddInt("contextInfoState", context_info_state);
#if defined(OS_WIN)
  enumerator->AddInt("DxDiagnosticsInfoState", dx_diagnostics_info_state);
#endif
  // TODO(kbr): add dx_diagnostics on Windows.
  for (size_t ii = 0; ii < video_encode_accelerator_supported_profiles.size();
       ++ii) {
    EnumerateVideoEncodeAcceleratorSupportedProfile(
        enumerator, video_encode_accelerator_supported_profiles[ii]);
  }
  enumerator->EndAuxAttributes();
}

}  // namespace gpu

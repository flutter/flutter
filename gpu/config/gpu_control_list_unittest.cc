// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "base/memory/scoped_ptr.h"
#include "gpu/config/gpu_control_list.h"
#include "gpu/config/gpu_info.h"
#include "testing/gtest/include/gtest/gtest.h"

const char kOsVersion[] = "10.6.4";
const uint32 kIntelVendorId = 0x8086;
const uint32 kNvidiaVendorId = 0x10de;
const uint32 kAmdVendorId = 0x10de;

#define LONG_STRING_CONST(...) #__VA_ARGS__

#define EXPECT_EMPTY_SET(feature_set) EXPECT_EQ(0u, feature_set.size())
#define EXPECT_SINGLE_FEATURE(feature_set, feature) \
    EXPECT_TRUE(feature_set.size() == 1 && feature_set.count(feature) == 1)

namespace gpu {

enum TestFeatureType {
  TEST_FEATURE_0 = 1,
  TEST_FEATURE_1 = 1 << 2,
  TEST_FEATURE_2 = 1 << 3,
};

class GpuControlListTest : public testing::Test {
 public:
  GpuControlListTest() { }

  ~GpuControlListTest() override {}

  const GPUInfo& gpu_info() const {
    return gpu_info_;
  }

  GpuControlList* Create() {
    GpuControlList* rt = new GpuControlList();
    rt->AddSupportedFeature("test_feature_0", TEST_FEATURE_0);
    rt->AddSupportedFeature("test_feature_1", TEST_FEATURE_1);
    rt->AddSupportedFeature("test_feature_2", TEST_FEATURE_2);
    return rt;
  }

 protected:
  void SetUp() override {
    gpu_info_.gpu.vendor_id = kNvidiaVendorId;
    gpu_info_.gpu.device_id = 0x0640;
    gpu_info_.driver_vendor = "NVIDIA";
    gpu_info_.driver_version = "1.6.18";
    gpu_info_.driver_date = "7-14-2009";
    gpu_info_.machine_model_name = "MacBookPro";
    gpu_info_.machine_model_version = "7.1";
    gpu_info_.gl_vendor = "NVIDIA Corporation";
    gpu_info_.gl_renderer = "NVIDIA GeForce GT 120 OpenGL Engine";
  }

  void TearDown() override {}

 private:
  GPUInfo gpu_info_;
};

TEST_F(GpuControlListTest, DefaultControlListSettings) {
  scoped_ptr<GpuControlList> control_list(Create());
  // Default control list settings: all feature are allowed.
  std::set<int> features = control_list->MakeDecision(
      GpuControlList::kOsMacosx, kOsVersion, gpu_info());
  EXPECT_EMPTY_SET(features);
}

TEST_F(GpuControlListTest, EmptyControlList) {
  // Empty list: all features are allowed.
  const std::string empty_list_json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "2.5",
        "entries": [
        ]
      }
  );
  scoped_ptr<GpuControlList> control_list(Create());

  EXPECT_TRUE(control_list->LoadList(empty_list_json,
                                     GpuControlList::kAllOs));
  EXPECT_EQ("2.5", control_list->version());
  std::set<int> features = control_list->MakeDecision(
      GpuControlList::kOsMacosx, kOsVersion, gpu_info());
  EXPECT_EMPTY_SET(features);
}

TEST_F(GpuControlListTest, DetailedEntryAndInvalidJson) {
  // exact setting.
  const std::string exact_list_json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "0.1",
        "entries": [
          {
            "id": 5,
            "os": {
              "type": "macosx",
              "version": {
                "op": "=",
                "value": "10.6.4"
              }
            },
            "vendor_id": "0x10de",
            "device_id": ["0x0640"],
            "driver_version": {
              "op": "=",
              "value": "1.6.18"
            },
            "features": [
              "test_feature_0"
            ]
          }
        ]
      }
  );
  scoped_ptr<GpuControlList> control_list(Create());

  EXPECT_TRUE(control_list->LoadList(exact_list_json, GpuControlList::kAllOs));
  std::set<int> features = control_list->MakeDecision(
      GpuControlList::kOsMacosx, kOsVersion, gpu_info());
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);

  // Invalid json input should not change the current control_list settings.
  const std::string invalid_json = "invalid";

  EXPECT_FALSE(control_list->LoadList(invalid_json, GpuControlList::kAllOs));
  features = control_list->MakeDecision(
      GpuControlList::kOsMacosx, kOsVersion, gpu_info());
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
  std::vector<uint32> entries;
  control_list->GetDecisionEntries(&entries, false);
  ASSERT_EQ(1u, entries.size());
  EXPECT_EQ(5u, entries[0]);
  EXPECT_EQ(5u, control_list->max_entry_id());
}

TEST_F(GpuControlListTest, VendorOnAllOsEntry) {
  // ControlList a vendor on all OS.
  const std::string vendor_json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "0.1",
        "entries": [
          {
            "id": 1,
            "vendor_id": "0x10de",
            "features": [
              "test_feature_0"
            ]
          }
        ]
      }
  );
  scoped_ptr<GpuControlList> control_list(Create());

  // ControlList entries won't be filtered to the current OS only upon loading.
  EXPECT_TRUE(control_list->LoadList(vendor_json, GpuControlList::kAllOs));
  std::set<int> features = control_list->MakeDecision(
      GpuControlList::kOsMacosx, kOsVersion, gpu_info());
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
  features = control_list->MakeDecision(
      GpuControlList::kOsWin, kOsVersion, gpu_info());
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
  features = control_list->MakeDecision(
      GpuControlList::kOsLinux, kOsVersion, gpu_info());
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
#if defined(OS_WIN) || defined(OS_LINUX) || defined(OS_MACOSX) || \
    defined(OS_OPENBSD)
  // ControlList entries will be filtered to the current OS only upon loading.
  EXPECT_TRUE(control_list->LoadList(
      vendor_json, GpuControlList::kCurrentOsOnly));
  features = control_list->MakeDecision(
      GpuControlList::kOsMacosx, kOsVersion, gpu_info());
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
  features = control_list->MakeDecision(
      GpuControlList::kOsWin, kOsVersion, gpu_info());
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
  features = control_list->MakeDecision(
      GpuControlList::kOsLinux, kOsVersion, gpu_info());
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
#endif
}

TEST_F(GpuControlListTest, UnknownField) {
  const std::string unknown_field_json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "0.1",
        "entries": [
          {
            "id": 1,
            "unknown_field": 0,
            "features": [
              "test_feature_1"
            ]
          },
          {
            "id": 2,
            "features": [
              "test_feature_0"
            ]
          }
        ]
      }
  );
  scoped_ptr<GpuControlList> control_list(Create());

  EXPECT_FALSE(control_list->LoadList(
      unknown_field_json, GpuControlList::kAllOs));
}

TEST_F(GpuControlListTest, UnknownExceptionField) {
  const std::string unknown_exception_field_json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "0.1",
        "entries": [
          {
            "id": 1,
            "unknown_field": 0,
            "features": [
              "test_feature_2"
            ]
          },
          {
            "id": 2,
            "exceptions": [
              {
                "unknown_field": 0
              }
            ],
            "features": [
              "test_feature_1"
            ]
          },
          {
            "id": 3,
            "features": [
              "test_feature_0"
            ]
          }
        ]
      }
  );
  scoped_ptr<GpuControlList> control_list(Create());

  EXPECT_FALSE(control_list->LoadList(
      unknown_exception_field_json, GpuControlList::kAllOs));
}

TEST_F(GpuControlListTest, DisabledEntry) {
  const std::string disabled_json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "0.1",
        "entries": [
          {
            "id": 1,
            "disabled": true,
            "features": [
              "test_feature_0"
            ]
          }
        ]
      }
  );
  scoped_ptr<GpuControlList> control_list(Create());
  EXPECT_TRUE(control_list->LoadList(disabled_json, GpuControlList::kAllOs));
  std::set<int> features = control_list->MakeDecision(
      GpuControlList::kOsWin, kOsVersion, gpu_info());
  EXPECT_EMPTY_SET(features);
  std::vector<uint32> flag_entries;
  control_list->GetDecisionEntries(&flag_entries, false);
  EXPECT_EQ(0u, flag_entries.size());
  control_list->GetDecisionEntries(&flag_entries, true);
  EXPECT_EQ(1u, flag_entries.size());
}

TEST_F(GpuControlListTest, NeedsMoreInfo) {
  const std::string json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "0.1",
        "entries": [
          {
            "id": 1,
            "os": {
              "type": "win"
            },
            "vendor_id": "0x10de",
            "driver_version": {
              "op": "<",
              "value": "12"
            },
            "features": [
              "test_feature_0"
            ]
          }
        ]
      }
  );
  GPUInfo gpu_info;
  gpu_info.gpu.vendor_id = kNvidiaVendorId;

  scoped_ptr<GpuControlList> control_list(Create());
  EXPECT_TRUE(control_list->LoadList(json, GpuControlList::kAllOs));

  std::set<int> features = control_list->MakeDecision(
      GpuControlList::kOsWin, kOsVersion, gpu_info);
  EXPECT_EMPTY_SET(features);
  EXPECT_TRUE(control_list->needs_more_info());
  std::vector<uint32> decision_entries;
  control_list->GetDecisionEntries(&decision_entries, false);
  EXPECT_EQ(0u, decision_entries.size());

  gpu_info.driver_version = "11";
  features = control_list->MakeDecision(
      GpuControlList::kOsWin, kOsVersion, gpu_info);
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
  EXPECT_FALSE(control_list->needs_more_info());
  control_list->GetDecisionEntries(&decision_entries, false);
  EXPECT_EQ(1u, decision_entries.size());
}

TEST_F(GpuControlListTest, NeedsMoreInfoForExceptions) {
  const std::string json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "0.1",
        "entries": [
          {
            "id": 1,
            "os": {
              "type": "linux"
            },
            "vendor_id": "0x8086",
            "exceptions": [
              {
                "gl_renderer": ".*mesa.*"
              }
            ],
            "features": [
              "test_feature_0"
            ]
          }
        ]
      }
  );
  GPUInfo gpu_info;
  gpu_info.gpu.vendor_id = kIntelVendorId;

  scoped_ptr<GpuControlList> control_list(Create());
  EXPECT_TRUE(control_list->LoadList(json, GpuControlList::kAllOs));

  // The case this entry does not apply.
  std::set<int> features = control_list->MakeDecision(
      GpuControlList::kOsMacosx, kOsVersion, gpu_info);
  EXPECT_EMPTY_SET(features);
  EXPECT_FALSE(control_list->needs_more_info());

  // The case this entry might apply, but need more info.
  features = control_list->MakeDecision(
      GpuControlList::kOsLinux, kOsVersion, gpu_info);
  EXPECT_EMPTY_SET(features);
  EXPECT_TRUE(control_list->needs_more_info());

  // The case we have full info, and the exception applies (so the entry
  // does not apply).
  gpu_info.gl_renderer = "mesa";
  features = control_list->MakeDecision(
      GpuControlList::kOsLinux, kOsVersion, gpu_info);
  EXPECT_EMPTY_SET(features);
  EXPECT_FALSE(control_list->needs_more_info());

  // The case we have full info, and this entry applies.
  gpu_info.gl_renderer = "my renderer";
  features = control_list->MakeDecision(GpuControlList::kOsLinux, kOsVersion,
      gpu_info);
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
  EXPECT_FALSE(control_list->needs_more_info());
}

TEST_F(GpuControlListTest, IgnorableEntries) {
  // If an entry will not change the control_list decisions, then it should not
  // trigger the needs_more_info flag.
  const std::string json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "0.1",
        "entries": [
          {
            "id": 1,
            "os": {
              "type": "linux"
            },
            "vendor_id": "0x8086",
            "features": [
              "test_feature_0"
            ]
          },
          {
            "id": 2,
            "os": {
              "type": "linux"
            },
            "vendor_id": "0x8086",
            "driver_version": {
              "op": "<",
              "value": "10.7"
            },
            "features": [
              "test_feature_0"
            ]
          }
        ]
      }
  );
  GPUInfo gpu_info;
  gpu_info.gpu.vendor_id = kIntelVendorId;

  scoped_ptr<GpuControlList> control_list(Create());
  EXPECT_TRUE(control_list->LoadList(json, GpuControlList::kAllOs));
  std::set<int> features = control_list->MakeDecision(
      GpuControlList::kOsLinux, kOsVersion, gpu_info);
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
  EXPECT_FALSE(control_list->needs_more_info());
}

TEST_F(GpuControlListTest, ExceptionWithoutVendorId) {
  const std::string json = LONG_STRING_CONST(
      {
        "name": "gpu control list",
        "version": "0.1",
        "entries": [
          {
            "id": 1,
            "os": {
              "type": "linux"
            },
            "vendor_id": "0x8086",
            "exceptions": [
              {
                "device_id": ["0x2a06"],
                "driver_version": {
                  "op": ">=",
                  "value": "8.1"
                }
              },
              {
                "device_id": ["0x2a02"],
                "driver_version": {
                  "op": ">=",
                  "value": "9.1"
                }
              }
            ],
            "features": [
              "test_feature_0"
            ]
          }
        ]
      }
  );
  GPUInfo gpu_info;
  gpu_info.gpu.vendor_id = kIntelVendorId;
  gpu_info.gpu.device_id = 0x2a02;
  gpu_info.driver_version = "9.1";

  scoped_ptr<GpuControlList> control_list(Create());
  EXPECT_TRUE(control_list->LoadList(json, GpuControlList::kAllOs));

  std::set<int> features = control_list->MakeDecision(
      GpuControlList::kOsLinux, kOsVersion, gpu_info);
  EXPECT_EMPTY_SET(features);

  gpu_info.driver_version = "9.0";
  features = control_list->MakeDecision(
      GpuControlList::kOsLinux, kOsVersion, gpu_info);
  EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
}

TEST_F(GpuControlListTest, AMDSwitchable) {
  GPUInfo gpu_info;
  gpu_info.amd_switchable = true;
  gpu_info.gpu.vendor_id = kAmdVendorId;
  gpu_info.gpu.device_id = 0x6760;
  GPUInfo::GPUDevice integrated_gpu;
  integrated_gpu.vendor_id = kIntelVendorId;
  integrated_gpu.device_id = 0x0116;
  gpu_info.secondary_gpus.push_back(integrated_gpu);

  {  // amd_switchable_discrete entry
    const std::string json= LONG_STRING_CONST(
        {
          "name": "gpu control list",
          "version": "0.1",
          "entries": [
            {
              "id": 1,
              "os": {
                "type": "win"
              },
              "multi_gpu_style": "amd_switchable_discrete",
              "features": [
                "test_feature_0"
              ]
            }
          ]
        }
    );

    scoped_ptr<GpuControlList> control_list(Create());
    EXPECT_TRUE(control_list->LoadList(json, GpuControlList::kAllOs));

    // Integrated GPU is active
    gpu_info.gpu.active = false;
    gpu_info.secondary_gpus[0].active = true;
    std::set<int> features = control_list->MakeDecision(
        GpuControlList::kOsWin, kOsVersion, gpu_info);
    EXPECT_EMPTY_SET(features);

    // Discrete GPU is active
    gpu_info.gpu.active = true;
    gpu_info.secondary_gpus[0].active = false;
    features = control_list->MakeDecision(
        GpuControlList::kOsWin, kOsVersion, gpu_info);
    EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);
  }

  {  // amd_switchable_integrated entry
    const std::string json= LONG_STRING_CONST(
        {
          "name": "gpu control list",
          "version": "0.1",
          "entries": [
            {
              "id": 1,
              "os": {
                "type": "win"
              },
              "multi_gpu_style": "amd_switchable_integrated",
              "features": [
                "test_feature_0"
              ]
            }
          ]
        }
    );

    scoped_ptr<GpuControlList> control_list(Create());
    EXPECT_TRUE(control_list->LoadList(json, GpuControlList::kAllOs));

    // Discrete GPU is active
    gpu_info.gpu.active = true;
    gpu_info.secondary_gpus[0].active = false;
    std::set<int> features = control_list->MakeDecision(
        GpuControlList::kOsWin, kOsVersion, gpu_info);
    EXPECT_EMPTY_SET(features);

    // Integrated GPU is active
    gpu_info.gpu.active = false;
    gpu_info.secondary_gpus[0].active = true;
    features = control_list->MakeDecision(
        GpuControlList::kOsWin, kOsVersion, gpu_info);
    EXPECT_SINGLE_FEATURE(features, TEST_FEATURE_0);

    // For non AMD switchable
    gpu_info.amd_switchable = false;
    features = control_list->MakeDecision(
        GpuControlList::kOsWin, kOsVersion, gpu_info);
    EXPECT_EMPTY_SET(features);
  }
}

}  // namespace gpu


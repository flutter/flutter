// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/json/json_reader.h"
#include "gpu/config/gpu_control_list.h"
#include "gpu/config/gpu_info.h"
#include "testing/gtest/include/gtest/gtest.h"

#define LONG_STRING_CONST(...) #__VA_ARGS__

namespace gpu {

enum TestFeatureType {
  TEST_FEATURE_0 = 0,
  TEST_FEATURE_1,
  TEST_FEATURE_2
};

class GpuControlListEntryTest : public testing::Test {
 public:
  GpuControlListEntryTest() { }
  ~GpuControlListEntryTest() override {}

  const GPUInfo& gpu_info() const {
    return gpu_info_;
  }

  typedef GpuControlList::ScopedGpuControlListEntry ScopedEntry;

  static ScopedEntry GetEntryFromString(
      const std::string& json, bool supports_feature_type_all) {
    scoped_ptr<base::Value> root;
    root.reset(base::JSONReader::Read(json));
    base::DictionaryValue* value = NULL;
    if (root.get() == NULL || !root->GetAsDictionary(&value))
      return NULL;

    GpuControlList::FeatureMap feature_map;
    feature_map["test_feature_0"] = TEST_FEATURE_0;
    feature_map["test_feature_1"] = TEST_FEATURE_1;
    feature_map["test_feature_2"] = TEST_FEATURE_2;

    return GpuControlList::GpuControlListEntry::GetEntryFromValue(
        value, true, feature_map, supports_feature_type_all);
  }

  static ScopedEntry GetEntryFromString(const std::string& json) {
    return GetEntryFromString(json, false);
  }

  void SetUp() override {
    gpu_info_.gpu.vendor_id = 0x10de;
    gpu_info_.gpu.device_id = 0x0640;
    gpu_info_.gpu.active = true;
    gpu_info_.driver_vendor = "NVIDIA";
    gpu_info_.driver_version = "1.6.18";
    gpu_info_.driver_date = "7-14-2009";
    gpu_info_.gl_version = "2.1 NVIDIA-8.24.11 310.90.9b01";
    gpu_info_.gl_vendor = "NVIDIA Corporation";
    gpu_info_.gl_renderer = "NVIDIA GeForce GT 120 OpenGL Engine";
  }

 protected:
  GPUInfo gpu_info_;
};

TEST_F(GpuControlListEntryTest, DetailedEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 5,
        "description": "test entry",
        "cr_bugs": [1024, 678],
        "webkit_bugs": [1950],
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
  );

  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsMacosx, entry->GetOsType());
  EXPECT_FALSE(entry->disabled());
  EXPECT_EQ(5u, entry->id());
  EXPECT_STREQ("test entry", entry->description().c_str());
  EXPECT_EQ(2u, entry->cr_bugs().size());
  EXPECT_EQ(1024, entry->cr_bugs()[0]);
  EXPECT_EQ(678, entry->cr_bugs()[1]);
  EXPECT_EQ(1u, entry->webkit_bugs().size());
  EXPECT_EQ(1950, entry->webkit_bugs()[0]);
  EXPECT_EQ(1u, entry->features().size());
  EXPECT_EQ(1u, entry->features().count(TEST_FEATURE_0));
  EXPECT_FALSE(entry->NeedsMoreInfo(gpu_info()));
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.6.4", gpu_info()));
}

TEST_F(GpuControlListEntryTest, VendorOnAllOsEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "vendor_id": "0x10de",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsAny, entry->GetOsType());

  const GpuControlList::OsType os_type[] = {
    GpuControlList::kOsMacosx,
    GpuControlList::kOsWin,
    GpuControlList::kOsLinux,
    GpuControlList::kOsChromeOS,
    GpuControlList::kOsAndroid
  };
  for (size_t i = 0; i < arraysize(os_type); ++i)
    EXPECT_TRUE(entry->Contains(os_type[i], "10.6", gpu_info()));
}

TEST_F(GpuControlListEntryTest, VendorOnLinuxEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "linux"
        },
        "vendor_id": "0x10de",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsLinux, entry->GetOsType());

  const GpuControlList::OsType os_type[] = {
    GpuControlList::kOsMacosx,
    GpuControlList::kOsWin,
    GpuControlList::kOsChromeOS,
    GpuControlList::kOsAndroid
  };
  for (size_t i = 0; i < arraysize(os_type); ++i)
    EXPECT_FALSE(entry->Contains(os_type[i], "10.6", gpu_info()));
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "10.6", gpu_info()));
}

TEST_F(GpuControlListEntryTest, AllExceptNVidiaOnLinuxEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "linux"
        },
        "exceptions": [
          {
            "vendor_id": "0x10de"
          }
        ],
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsLinux, entry->GetOsType());

  const GpuControlList::OsType os_type[] = {
    GpuControlList::kOsMacosx,
    GpuControlList::kOsWin,
    GpuControlList::kOsLinux,
    GpuControlList::kOsChromeOS,
    GpuControlList::kOsAndroid
  };
  for (size_t i = 0; i < arraysize(os_type); ++i)
    EXPECT_FALSE(entry->Contains(os_type[i], "10.6", gpu_info()));
}

TEST_F(GpuControlListEntryTest, AllExceptIntelOnLinuxEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "linux"
        },
        "exceptions": [
          {
            "vendor_id": "0x8086"
          }
        ],
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsLinux, entry->GetOsType());

  const GpuControlList::OsType os_type[] = {
    GpuControlList::kOsMacosx,
    GpuControlList::kOsWin,
    GpuControlList::kOsChromeOS,
    GpuControlList::kOsAndroid
  };
  for (size_t i = 0; i < arraysize(os_type); ++i)
    EXPECT_FALSE(entry->Contains(os_type[i], "10.6", gpu_info()));
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "10.6", gpu_info()));
}

TEST_F(GpuControlListEntryTest, DateOnWindowsEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "win"
        },
        "driver_date": {
          "op": "<",
          "value": "2010.5.8"
        },
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsWin, entry->GetOsType());

  GPUInfo gpu_info;
  gpu_info.driver_date = "4-12-2010";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsWin, "10.6", gpu_info));
  gpu_info.driver_date = "5-8-2010";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsWin, "10.6", gpu_info));
  gpu_info.driver_date = "5-9-2010";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsWin, "10.6", gpu_info));
}

TEST_F(GpuControlListEntryTest, MultipleDevicesEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "vendor_id": "0x10de",
        "device_id": ["0x1023", "0x0640"],
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsAny, entry->GetOsType());

  const GpuControlList::OsType os_type[] = {
    GpuControlList::kOsMacosx,
    GpuControlList::kOsWin,
    GpuControlList::kOsLinux,
    GpuControlList::kOsChromeOS,
    GpuControlList::kOsAndroid
  };
  for (size_t i = 0; i < arraysize(os_type); ++i)
    EXPECT_TRUE(entry->Contains(os_type[i], "10.6", gpu_info()));
}

TEST_F(GpuControlListEntryTest, ChromeOSEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "chromeos"
        },
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsChromeOS, entry->GetOsType());

  const GpuControlList::OsType os_type[] = {
    GpuControlList::kOsMacosx,
    GpuControlList::kOsWin,
    GpuControlList::kOsLinux,
    GpuControlList::kOsAndroid
  };
  for (size_t i = 0; i < arraysize(os_type); ++i)
    EXPECT_FALSE(entry->Contains(os_type[i], "10.6", gpu_info()));
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsChromeOS, "10.6", gpu_info()));
}

TEST_F(GpuControlListEntryTest, MalformedVendor) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "vendor_id": "[0x10de]",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() == NULL);
}

TEST_F(GpuControlListEntryTest, UnknownFieldEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "unknown_field": 0,
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() == NULL);
}

TEST_F(GpuControlListEntryTest, UnknownExceptionFieldEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 2,
        "exceptions": [
          {
            "unknown_field": 0
          }
        ],
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() == NULL);
}

TEST_F(GpuControlListEntryTest, UnknownFeatureEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "features": [
          "some_unknown_feature",
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() == NULL);
}

TEST_F(GpuControlListEntryTest, GlVersionGLESEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "gl_type": "gles",
        "gl_version": {
          "op": "=",
          "value": "3.0"
        },
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gl_version = "OpenGL ES 3.0 V@66.0 AU@ (CL@)";
  EXPECT_TRUE(entry->Contains(GpuControlList::kOsAndroid, "4.4.2", gpu_info));

  gpu_info.gl_version = "OpenGL ES 3.0V@66.0 AU@ (CL@)";
  EXPECT_TRUE(entry->Contains(GpuControlList::kOsAndroid, "4.4.2", gpu_info));

  gpu_info.gl_version = "OpenGL ES 3.1 V@66.0 AU@ (CL@)";
  EXPECT_FALSE(entry->Contains(GpuControlList::kOsAndroid, "4.4.2", gpu_info));

  gpu_info.gl_version = "3.0 NVIDIA-8.24.11 310.90.9b01";
  EXPECT_FALSE(entry->Contains(GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_version = "OpenGL ES 3.0 (ANGLE 1.2.0.2450)";
  EXPECT_FALSE(entry->Contains(GpuControlList::kOsWin, "6.1", gpu_info));
}

TEST_F(GpuControlListEntryTest, GlVersionANGLEEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "gl_type": "angle",
        "gl_version": {
          "op": ">",
          "value": "2.0"
        },
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gl_version = "OpenGL ES 3.0 V@66.0 AU@ (CL@)";
  EXPECT_FALSE(entry->Contains(GpuControlList::kOsAndroid, "4.4.2", gpu_info));

  gpu_info.gl_version = "3.0 NVIDIA-8.24.11 310.90.9b01";
  EXPECT_FALSE(entry->Contains(GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_version = "OpenGL ES 3.0 (ANGLE 1.2.0.2450)";
  EXPECT_TRUE(entry->Contains(GpuControlList::kOsWin, "6.1", gpu_info));

  gpu_info.gl_version = "OpenGL ES 2.0 (ANGLE 1.2.0.2450)";
  EXPECT_FALSE(entry->Contains(GpuControlList::kOsWin, "6.1", gpu_info));
}

TEST_F(GpuControlListEntryTest, GlVersionGLEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "gl_type": "gl",
        "gl_version": {
          "op": "<",
          "value": "4.0"
        },
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gl_version = "OpenGL ES 3.0 V@66.0 AU@ (CL@)";
  EXPECT_FALSE(entry->Contains(GpuControlList::kOsAndroid, "4.4.2", gpu_info));

  gpu_info.gl_version = "3.0 NVIDIA-8.24.11 310.90.9b01";
  EXPECT_TRUE(entry->Contains(GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_version = "4.0 NVIDIA-8.24.11 310.90.9b01";
  EXPECT_FALSE(entry->Contains(GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_version = "OpenGL ES 3.0 (ANGLE 1.2.0.2450)";
  EXPECT_FALSE(entry->Contains(GpuControlList::kOsWin, "6.1", gpu_info));
}

TEST_F(GpuControlListEntryTest, GlVendorEqual) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "gl_vendor": "NVIDIA",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gl_vendor = "NVIDIA";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  // Case sensitive.
  gpu_info.gl_vendor = "NVidia";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_vendor = "NVIDIA-x";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));
}

TEST_F(GpuControlListEntryTest, GlVendorWithDot) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "gl_vendor": "X\\.Org.*",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gl_vendor = "X.Org R300 Project";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "", gpu_info));

  gpu_info.gl_vendor = "X.Org";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "", gpu_info));
}

TEST_F(GpuControlListEntryTest, GlRendererContains) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "gl_renderer": ".*GeForce.*",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gl_renderer = "NVIDIA GeForce GT 120 OpenGL Engine";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  // Case sensitive.
  gpu_info.gl_renderer = "NVIDIA GEFORCE GT 120 OpenGL Engine";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_renderer = "GeForce GT 120 OpenGL Engine";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_renderer = "NVIDIA GeForce";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_renderer = "NVIDIA Ge Force";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));
}

TEST_F(GpuControlListEntryTest, GlRendererCaseInsensitive) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "gl_renderer": "(?i).*software.*",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gl_renderer = "software rasterizer";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_renderer = "Software Rasterizer";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));
}

TEST_F(GpuControlListEntryTest, GlExtensionsEndWith) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "gl_extensions": ".*GL_SUN_slice_accum",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gl_extensions = "GL_SGIS_generate_mipmap "
                           "GL_SGIX_shadow "
                           "GL_SUN_slice_accum";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.gl_extensions = "GL_SGIS_generate_mipmap "
                           "GL_SUN_slice_accum "
                           "GL_SGIX_shadow";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));
}

TEST_F(GpuControlListEntryTest, DisabledEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "disabled": true,
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_TRUE(entry->disabled());
}

TEST_F(GpuControlListEntryTest, OptimusEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "linux"
        },
        "multi_gpu_style": "optimus",
        "features": [
          "test_feature_0"
        ]
      }
  );
  GPUInfo gpu_info;
  gpu_info.optimus = true;

  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsLinux, entry->GetOsType());
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "10.6", gpu_info));
}

TEST_F(GpuControlListEntryTest, AMDSwitchableEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "multi_gpu_style": "amd_switchable",
        "features": [
          "test_feature_0"
        ]
      }
  );
  GPUInfo gpu_info;
  gpu_info.amd_switchable = true;

  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsMacosx, entry->GetOsType());
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.6", gpu_info));
}

TEST_F(GpuControlListEntryTest, DriverVendorBeginWith) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "driver_vendor": "NVIDIA.*",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.driver_vendor = "NVIDIA Corporation";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  // Case sensitive.
  gpu_info.driver_vendor = "NVidia Corporation";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.driver_vendor = "NVIDIA";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));

  gpu_info.driver_vendor = "USA NVIDIA";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsMacosx, "10.9", gpu_info));
}

TEST_F(GpuControlListEntryTest, LexicalDriverVersionEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "linux"
        },
        "vendor_id": "0x1002",
        "driver_version": {
          "op": "=",
          "style": "lexical",
          "value": "8.76"
        },
        "features": [
          "test_feature_0"
        ]
      }
  );
  GPUInfo gpu_info;
  gpu_info.gpu.vendor_id = 0x1002;

  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsLinux, entry->GetOsType());

  gpu_info.driver_version = "8.76";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "10.6", gpu_info));

  gpu_info.driver_version = "8.768";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "10.6", gpu_info));

  gpu_info.driver_version = "8.76.8";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "10.6", gpu_info));
}

TEST_F(GpuControlListEntryTest, NeedsMoreInfoEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "vendor_id": "0x8086",
        "driver_version": {
          "op": "<",
          "value": "10.7"
        },
        "features": [
          "test_feature_1"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gpu.vendor_id = 0x8086;
  EXPECT_TRUE(entry->NeedsMoreInfo(gpu_info));

  gpu_info.driver_version = "10.6";
  EXPECT_FALSE(entry->NeedsMoreInfo(gpu_info));
}

TEST_F(GpuControlListEntryTest, NeedsMoreInfoForExceptionsEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "vendor_id": "0x8086",
        "exceptions": [
          {
            "gl_renderer": ".*mesa.*"
          }
        ],
        "features": [
          "test_feature_1"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);

  GPUInfo gpu_info;
  gpu_info.gpu.vendor_id = 0x8086;
  EXPECT_TRUE(entry->NeedsMoreInfo(gpu_info));

  gpu_info.gl_renderer = "mesa";
  EXPECT_FALSE(entry->NeedsMoreInfo(gpu_info));
}

TEST_F(GpuControlListEntryTest, FeatureTypeAllEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "features": [
          "all"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json, true));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(3u, entry->features().size());
  EXPECT_EQ(1u, entry->features().count(TEST_FEATURE_0));
  EXPECT_EQ(1u, entry->features().count(TEST_FEATURE_1));
  EXPECT_EQ(1u, entry->features().count(TEST_FEATURE_2));
}

TEST_F(GpuControlListEntryTest, InvalidVendorIdEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "vendor_id": "0x0000",
        "features": [
          "test_feature_1"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() == NULL);
}

TEST_F(GpuControlListEntryTest, InvalidDeviceIdEntry) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "vendor_id": "0x10de",
        "device_id": ["0x1023", "0x0000"],
        "features": [
          "test_feature_1"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() == NULL);
}

TEST_F(GpuControlListEntryTest, SingleActiveGPU) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x10de",
        "device_id": ["0x0640"],
        "multi_gpu_category": "active",
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsMacosx, entry->GetOsType());
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.6", gpu_info()));
}

TEST_F(GpuControlListEntryTest, MachineModelName) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "android"
        },
        "machine_model_name": [
          "Nexus 4", "XT1032", "GT-.*", "SCH-.*"
        ],
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsAndroid, entry->GetOsType());
  GPUInfo gpu_info;

  gpu_info.machine_model_name = "Nexus 4";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));

  gpu_info.machine_model_name = "XT1032";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));

  gpu_info.machine_model_name = "XT1032i";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));

  gpu_info.machine_model_name = "Nexus 5";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));

  gpu_info.machine_model_name = "Nexus";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));

  gpu_info.machine_model_name = "";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));

  gpu_info.machine_model_name = "GT-N7100";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));

  gpu_info.machine_model_name = "GT-I9300";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));

  gpu_info.machine_model_name = "SCH-I545";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));
}

TEST_F(GpuControlListEntryTest, MachineModelNameException) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "exceptions": [
          {
            "os": {
              "type": "android"
            },
            "machine_model_name": ["Nexus.*"]
          }
        ],
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsAny, entry->GetOsType());
  GPUInfo gpu_info;

  gpu_info.machine_model_name = "Nexus 4";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "4.1", gpu_info));

  gpu_info.machine_model_name = "Nexus 7";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "4.1", gpu_info));

  gpu_info.machine_model_name = "";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsAndroid, "4.1", gpu_info));
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsLinux, "4.1", gpu_info));
}

TEST_F(GpuControlListEntryTest, MachineModelVersion) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "machine_model_name": ["MacBookPro"],
        "machine_model_version": {
          "op": "=",
          "value": "7.1"
        },
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  GPUInfo gpu_info;
  gpu_info.machine_model_name = "MacBookPro";
  gpu_info.machine_model_version = "7.1";
  EXPECT_EQ(GpuControlList::kOsMacosx, entry->GetOsType());
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.6", gpu_info));
}

TEST_F(GpuControlListEntryTest, MachineModelVersionException) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "machine_model_name": ["MacBookPro"],
        "exceptions": [
          {
            "machine_model_version": {
              "op": ">",
              "value": "7.1"
            }
          }
        ],
        "features": [
          "test_feature_0"
        ]
      }
  );
  ScopedEntry entry(GetEntryFromString(json));
  EXPECT_TRUE(entry.get() != NULL);
  EXPECT_EQ(GpuControlList::kOsMacosx, entry->GetOsType());

  GPUInfo gpu_info;
  gpu_info.machine_model_name = "MacBookPro";
  gpu_info.machine_model_version = "7.0";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.6", gpu_info));

  gpu_info.machine_model_version = "7.2";
  EXPECT_FALSE(entry->Contains(
      GpuControlList::kOsMacosx, "10.6", gpu_info));

  gpu_info.machine_model_version = "";
  EXPECT_TRUE(entry->Contains(
      GpuControlList::kOsMacosx, "10.6", gpu_info));
}

class GpuControlListEntryDualGPUTest : public GpuControlListEntryTest {
 public:
  GpuControlListEntryDualGPUTest() { }
  ~GpuControlListEntryDualGPUTest() override {}

  void SetUp() override {
    // Set up a NVIDIA/Intel dual, with NVIDIA as primary and Intel as
    // secondary, and initially Intel is active.
    gpu_info_.gpu.vendor_id = 0x10de;
    gpu_info_.gpu.device_id = 0x0640;
    gpu_info_.gpu.active = false;
    GPUInfo::GPUDevice second_gpu;
    second_gpu.vendor_id = 0x8086;
    second_gpu.device_id = 0x0166;
    second_gpu.active = true;
    gpu_info_.secondary_gpus.push_back(second_gpu);
  }

  void ActivatePrimaryGPU() {
    gpu_info_.gpu.active = true;
    gpu_info_.secondary_gpus[0].active = false;
  }

  void EntryShouldApply(const std::string& entry_json) const {
    EXPECT_TRUE(EntryApplies(entry_json));
  }

  void EntryShouldNotApply(const std::string& entry_json) const {
    EXPECT_FALSE(EntryApplies(entry_json));
  }

 private:
  bool EntryApplies(const std::string& entry_json) const {
    ScopedEntry entry(GetEntryFromString(entry_json));
    EXPECT_TRUE(entry.get());
    EXPECT_EQ(GpuControlList::kOsMacosx, entry->GetOsType());
    return entry->Contains(GpuControlList::kOsMacosx, "10.6", gpu_info());
  }
};

TEST_F(GpuControlListEntryDualGPUTest, CategoryAny) {
  const std::string json_intel = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x8086",
        "device_id": ["0x0166"],
        "multi_gpu_category": "any",
        "features": [
          "test_feature_0"
        ]
      }
  );
  EntryShouldApply(json_intel);

  const std::string json_nvidia = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x10de",
        "device_id": ["0x0640"],
        "multi_gpu_category": "any",
        "features": [
          "test_feature_0"
        ]
      }
  );
  EntryShouldApply(json_nvidia);
}

TEST_F(GpuControlListEntryDualGPUTest, CategoryPrimarySecondary) {
  const std::string json_secondary = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x8086",
        "device_id": ["0x0166"],
        "multi_gpu_category": "secondary",
        "features": [
          "test_feature_0"
        ]
      }
  );
  EntryShouldApply(json_secondary);

  const std::string json_primary = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x8086",
        "device_id": ["0x0166"],
        "multi_gpu_category": "primary",
        "features": [
          "test_feature_0"
        ]
      }
  );
  EntryShouldNotApply(json_primary);

  const std::string json_default = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x8086",
        "device_id": ["0x0166"],
        "features": [
          "test_feature_0"
        ]
      }
  );
  // Default is primary.
  EntryShouldNotApply(json_default);
}

TEST_F(GpuControlListEntryDualGPUTest, ActiveSecondaryGPU) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x8086",
        "device_id": ["0x0166", "0x0168"],
        "multi_gpu_category": "active",
        "features": [
          "test_feature_0"
        ]
      }
  );
  // By default, secondary GPU is active.
  EntryShouldApply(json);

  ActivatePrimaryGPU();
  EntryShouldNotApply(json);
}

TEST_F(GpuControlListEntryDualGPUTest, VendorOnlyActiveSecondaryGPU) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x8086",
        "multi_gpu_category": "active",
        "features": [
          "test_feature_0"
        ]
      }
  );
  // By default, secondary GPU is active.
  EntryShouldApply(json);

  ActivatePrimaryGPU();
  EntryShouldNotApply(json);
}

TEST_F(GpuControlListEntryDualGPUTest, ActivePrimaryGPU) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x10de",
        "device_id": ["0x0640"],
        "multi_gpu_category": "active",
        "features": [
          "test_feature_0"
        ]
      }
  );
  // By default, secondary GPU is active.
  EntryShouldNotApply(json);

  ActivatePrimaryGPU();
  EntryShouldApply(json);
}

TEST_F(GpuControlListEntryDualGPUTest, VendorOnlyActivePrimaryGPU) {
  const std::string json = LONG_STRING_CONST(
      {
        "id": 1,
        "os": {
          "type": "macosx"
        },
        "vendor_id": "0x10de",
        "multi_gpu_category": "active",
        "features": [
          "test_feature_0"
        ]
      }
  );
  // By default, secondary GPU is active.
  EntryShouldNotApply(json);

  ActivatePrimaryGPU();
  EntryShouldApply(json);
}

}  // namespace gpu


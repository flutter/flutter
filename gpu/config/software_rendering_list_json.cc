// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Determines whether certain gpu-related features are blacklisted or not.
// The format of a valid software_rendering_list.json file is defined in
// <gpu/config/gpu_control_list_format.txt>.
// The supported "features" can be found in <gpu/config/gpu_blacklist.cc>.

#include "gpu/config/gpu_control_list_jsons.h"

#define LONG_STRING_CONST(...) #__VA_ARGS__

namespace gpu {

const char kSoftwareRenderingListJson[] = LONG_STRING_CONST(

{
  "name": "software rendering list",
  // Please update the version number whenever you change this file.
  "version": "10.3",
  "entries": [
    {
      "id": 1,
      "description": "ATI Radeon X1900 is not compatible with WebGL on the Mac",
      "webkit_bugs": [47028],
      "os": {
        "type": "macosx"
      },
      "vendor_id": "0x1002",
      "device_id": ["0x7249"],
      "features": [
        "webgl",
        "flash_3d",
        "flash_stage3d"
      ]
    },
    {
      "id": 3,
      "description": "GL driver is software rendered. GPU acceleration is disabled",
      "cr_bugs": [59302, 315217],
      "os": {
        "type": "linux"
      },
      "gl_renderer": "(?i).*software.*",
      "features": [
        "all"
      ]
    },
    {
      "id": 4,
      "description": "The Intel Mobile 945 Express family of chipsets is not compatible with WebGL",
      "cr_bugs": [232035],
      "os": {
        "type": "any"
      },
      "vendor_id": "0x8086",
      "device_id": ["0x27AE", "0x27A2"],
      "features": [
        "webgl",
        "flash_3d",
        "flash_stage3d",
        "accelerated_2d_canvas"
      ]
    },
    {
      "id": 5,
      "description": "ATI/AMD cards with older drivers in Linux are crash-prone",
      "cr_bugs": [71381, 76428, 73910, 101225, 136240, 357314],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x1002",
      "exceptions": [
        {
          "driver_vendor": ".*AMD.*",
          "driver_version": {
            "op": ">=",
            "style": "lexical",
            "value": "8.98"
          }
        },
        {
          "driver_vendor": "Mesa",
          "driver_version": {
            "op": ">=",
            "value": "10.0.4"
          }
        }
      ],
      "features": [
        "all"
      ]
    },
    {
      "id": 8,
      "description": "NVIDIA GeForce FX Go5200 is assumed to be buggy",
      "cr_bugs": [72938],
      "os": {
        "type": "any"
      },
      "vendor_id": "0x10de",
      "device_id": ["0x0324"],
      "features": [
        "all"
      ]
    },
    {
      "id": 10,
      "description": "NVIDIA GeForce 7300 GT on Mac does not support WebGL",
      "cr_bugs": [73794],
      "os": {
        "type": "macosx"
      },
      "vendor_id": "0x10de",
      "device_id": ["0x0393"],
      "features": [
        "webgl",
        "flash_3d",
        "flash_stage3d"
      ]
    },
    {
      "id": 12,
      "description": "Drivers older than 2009-01 on Windows are possibly unreliable",
      "cr_bugs": [72979, 89802, 315205],
      "os": {
        "type": "win"
      },
      "driver_date": {
        "op": "<",
        "value": "2009.1"
      },
      "exceptions": [
        {
          "vendor_id": "0x8086",
          "device_id": ["0x29a2"],
          "driver_version": {
            "op": ">=",
            "value": "7.15.10.1624"
          }
        },
        {
          "driver_vendor": "osmesa"
        },
        {
          "vendor_id": "0x1414",
          "device_id": ["0x02c1"]
        }
      ],
      "features": [
        "all"
      ]
    },
    {
      "id": 17,
      "description": "Older Intel mesa drivers are crash-prone",
      "cr_bugs": [76703, 164555, 225200, 340886],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x8086",
      "driver_vendor": "Mesa",
      "driver_version": {
        "op": "<",
        "value": "10.1"
      },
      "exceptions": [
        {
          "device_id": ["0x0102", "0x0106", "0x0112", "0x0116", "0x0122", "0x0126", "0x010a", "0x0152", "0x0156", "0x015a", "0x0162", "0x0166"],
          "driver_version": {
            "op": ">=",
            "value": "8.0"
          }
        },
        {
          "device_id": ["0xa001", "0xa002", "0xa011", "0xa012", "0x29a2", "0x2992", "0x2982", "0x2972", "0x2a12", "0x2a42", "0x2e02", "0x2e12", "0x2e22", "0x2e32", "0x2e42", "0x2e92"],
          "driver_version": {
            "op": ">",
            "value": "8.0.2"
          }
        },
        {
          "device_id": ["0x0042", "0x0046"],
          "driver_version": {
            "op": ">",
            "value": "8.0.4"
          }
        },
        {
          "device_id": ["0x2a02"],
          "driver_version": {
            "op": ">=",
            "value": "9.1"
          }
        },
        {
          "device_id": ["0x0a16", "0x0a26"],
          "driver_version": {
            "op": ">=",
            "value": "10.0.1"
          }
        }
      ],
      "features": [
        "all"
      ]
    },
    {
      "id": 18,
      "description": "NVIDIA Quadro FX 1500 is buggy",
      "cr_bugs": [84701],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x10de",
      "device_id": ["0x029e"],
      "features": [
        "all"
      ]
    },
    {
      "id": 23,
      "description": "Mesa drivers in linux older than 7.11 are assumed to be buggy",
      "os": {
        "type": "linux"
      },
      "driver_vendor": "Mesa",
      "driver_version": {
        "op": "<",
        "value": "7.11"
      },
      "exceptions": [
        {
          "driver_vendor": "osmesa"
        }
      ],
      "features": [
        "all"
      ]
    },
    {
      "id": 24,
      "description": "Accelerated 2d canvas is unstable in Linux at the moment",
      "os": {
        "type": "linux"
      },
      "features": [
        "accelerated_2d_canvas"
      ]
    },
    {
      "id": 27,
      "description": "ATI/AMD cards with older drivers in Linux are crash-prone",
      "cr_bugs": [95934, 94973, 136240, 357314],
      "os": {
        "type": "linux"
      },
      "gl_vendor": "ATI.*",
      "exceptions": [
        {
          "driver_vendor": ".*AMD.*",
          "driver_version": {
            "op": ">=",
            "style": "lexical",
            "value": "8.98"
          }
        },
        {
          "driver_vendor": "Mesa",
          "driver_version": {
            "op": ">=",
            "value": "10.0.4"
          }
        }
      ],
      "features": [
        "all"
      ]
    },
    {
      "id": 28,
      "description": "ATI/AMD cards with third-party drivers in Linux are crash-prone",
      "cr_bugs": [95934, 94973, 357314],
      "os": {
        "type": "linux"
      },
      "gl_vendor": "X\\.Org.*",
      "gl_renderer": ".*AMD.*",
      "exceptions": [
        {
          "driver_vendor": "Mesa",
          "driver_version": {
            "op": ">=",
            "value": "10.0.4"
          }
        }
      ],
      "features": [
        "all"
      ]
    },
    {
      "id": 29,
      "description": "ATI/AMD cards with third-party drivers in Linux are crash-prone",
      "cr_bugs": [95934, 94973, 357314],
      "os": {
        "type": "linux"
      },
      "gl_vendor": "X\\.Org.*",
      "gl_renderer": ".*ATI.*",
      "exceptions": [
        {
          "driver_vendor": "Mesa",
          "driver_version": {
            "op": ">=",
            "value": "10.0.4"
          }
        }
      ],
      "features": [
        "all"
      ]
    },
    {
      "id": 30,
      "description": "NVIDIA cards with nouveau drivers in Linux are crash-prone",
      "cr_bugs": [94103],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x10de",
      "gl_vendor": "(?i)nouveau.*",
      "features": [
        "all"
      ]
    },
    {
      "id": 34,
      "description": "S3 Trio (used in Virtual PC) is not compatible",
      "cr_bugs": [119948],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x5333",
      "device_id": ["0x8811"],
      "features": [
        "all"
      ]
    },
    {
      "id": 35,
      "description": "Stage3D is not supported on Linux",
      "cr_bugs": [129848],
      "os": {
        "type": "linux"
      },
      "features": [
        "flash_stage3d"
      ]
    },
    {
      "id": 37,
      "description": "Older drivers are unreliable for Optimus on Linux",
      "cr_bugs": [131308, 363418],
      "os": {
        "type": "linux"
      },
      "multi_gpu_style": "optimus",
      "exceptions": [
        {
          "driver_vendor": "Mesa",
          "driver_version": {
            "op": ">=",
            "value": "10.1"
          },
          "gl_vendor": "Intel.*"
        }
      ],
      "features": [
        "all"
      ]
    },
    {
      "id": 38,
      "description": "Accelerated 2D canvas is unstable for NVidia GeForce 9400M on Lion",
      "cr_bugs": [130495],
      "os": {
        "type": "macosx",
        "version": {
          "op": "=",
          "value": "10.7"
        }
      },
      "vendor_id": "0x10de",
      "device_id": ["0x0863"],
      "features": [
        "accelerated_2d_canvas"
      ]
    },
    {
      "id": 42,
      "description": "AMD Radeon HD 6490M and 6970M on Snow Leopard are buggy",
      "cr_bugs": [137307, 285350],
      "os": {
        "type": "macosx",
        "version": {
          "op": "=",
          "value": "10.6"
        }
      },
      "vendor_id": "0x1002",
      "device_id": ["0x6760", "0x6720"],
      "features": [
        "webgl"
      ]
    },
    {
      "id": 44,
      "description": "Intel HD 4000 causes kernel panic on Lion",
      "cr_bugs": [134015],
      "os": {
        "type": "macosx",
        "version": {
          "op": "between",
          "value": "10.7.0",
          "value2": "10.7.4"
        }
      },
      "vendor_id": "0x8086",
      "device_id": ["0x0166"],
      "multi_gpu_category": "any",
      "features": [
        "all"
      ]
    },
    {
      "id": 45,
      "description": "Parallels drivers older than 7 are buggy",
      "cr_bugs": [138105],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x1ab8",
      "driver_version": {
        "op": "<",
        "value": "7"
      },
      "features": [
        "all"
      ]
    },
    {
      "id": 46,
      "description": "ATI FireMV 2400 cards on Windows are buggy",
      "cr_bugs": [124152],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x1002",
      "device_id": ["0x3151"],
      "features": [
        "all"
      ]
    },
    {
      "id": 47,
      "description": "NVIDIA linux drivers older than 295.* are assumed to be buggy",
      "cr_bugs": [78497],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x10de",
      "driver_vendor": "NVIDIA",
      "driver_version": {
        "op": "<",
        "value": "295"
      },
      "features": [
        "all"
      ]
    },
    {
      "id": 48,
      "description": "Accelerated video decode is unavailable on Linux",
      "cr_bugs": [137247],
      "os": {
        "type": "linux"
      },
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 49,
      "description": "NVidia GeForce GT 650M can cause the system to hang with flash 3D",
      "cr_bugs": [140175],
      "os": {
        "type": "macosx",
        "version": {
          "op": "between",
          "value": "10.8.0",
          "value2": "10.8.1"
        }
      },
      "multi_gpu_style": "optimus",
      "vendor_id": "0x10de",
      "device_id": ["0x0fd5"],
      "features": [
        "flash_3d",
        "flash_stage3d"
      ]
    },
    {
      "id": 50,
      "description": "Disable VMware software renderer on older Mesa",
      "cr_bugs": [145531, 332596],
      "os": {
        "type": "linux"
      },
      "gl_vendor": "VMware.*",
      "exceptions": [
        {
          "driver_vendor": "Mesa",
          "driver_version": {
            "op": ">=",
            "value": "9.2.1"
          },
          "gl_renderer": ".*SVGA3D.*"
        }
      ],
      "features": [
        "all"
      ]
    },
    {
      "id": 53,
      "description": "The Intel GMA500 is too slow for Stage3D",
      "cr_bugs": [152096],
      "vendor_id": "0x8086",
      "device_id": ["0x8108", "0x8109"],
      "features": [
        "flash_stage3d"
      ]
    },
    {
      "id": 56,
      "description": "NVIDIA linux drivers are unstable when using multiple Open GL contexts and with low memory",
      "cr_bugs": [145600],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x10de",
      "driver_vendor": "NVIDIA",
      "features": [
        "accelerated_video_decode",
        "flash_3d",
        "flash_stage3d"
      ]
    },
    {
      // Panel fitting is only used with OS_CHROMEOS. To avoid displaying an
      // error in chrome:gpu on every other platform, this blacklist entry needs
      // to only match on chromeos. The drawback is that panel_fitting will not
      // appear to be blacklisted if accidentally queried on non-chromeos.
      "id": 57,
      "description": "Chrome OS panel fitting is only supported for Intel IVB and SNB Graphics Controllers",
      "os": {
        "type": "chromeos"
      },
      "exceptions": [
        {
          "vendor_id": "0x8086",
          "device_id": ["0x0106", "0x0116", "0x0166"]
        }
      ],
      "features": [
        "panel_fitting"
      ]
    },
    {
      "id": 59,
      "description": "NVidia driver 8.15.11.8593 is crashy on Windows",
      "cr_bugs": [155749],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x10de",
      "driver_version": {
        "op": "=",
        "value": "8.15.11.8593"
      },
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 64,
      "description": "Hardware video decode is only supported in win7+",
      "cr_bugs": [159458],
      "os": {
        "type": "win",
        "version": {
          "op": "<",
          "value": "6.1"
        }
      },
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 68,
      "description": "VMware Fusion 4 has corrupt rendering with Win Vista+",
      "cr_bugs": [169470],
      "os": {
        "type": "win",
        "version": {
          "op": ">=",
          "value": "6.0"
        }
      },
      "vendor_id": "0x15ad",
      "driver_version": {
        "op": "<=",
        "value": "7.14.1.1134"
      },
      "features": [
        "all"
      ]
    },
    {
      "id": 69,
      "description": "NVIDIA driver 8.17.11.9621 is buggy with Stage3D baseline mode",
      "cr_bugs": [172771],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x10de",
      "driver_version": {
        "op": "=",
        "value": "8.17.11.9621"
      },
      "features": [
        "flash_stage3d_baseline"
      ]
    },
    {
      "id": 70,
      "description": "NVIDIA driver 8.17.11.8267 is buggy with Stage3D baseline mode",
      "cr_bugs": [172771],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x10de",
      "driver_version": {
        "op": "=",
        "value": "8.17.11.8267"
      },
      "features": [
        "flash_stage3d_baseline"
      ]
    },
    {
      "id": 71,
      "description": "All Intel drivers before 8.15.10.2021 are buggy with Stage3D baseline mode",
      "cr_bugs": [172771],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x8086",
      "driver_version": {
        "op": "<",
        "value": "8.15.10.2021"
      },
      "features": [
        "flash_stage3d_baseline"
      ]
    },
    {
      "id": 72,
      "description": "NVIDIA GeForce 6200 LE is buggy with WebGL",
      "cr_bugs": [232529],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x10de",
      "device_id": ["0x0163"],
      "features": [
        "webgl"
      ]
    },
    {
      "id": 73,
      "description": "WebGL is buggy with the NVIDIA GeForce GT 330M, 9400, and 9400M on MacOSX earlier than 10.8",
      "cr_bugs": [233523],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.8"
        }
      },
      "vendor_id": "0x10de",
      "device_id": ["0x0a29", "0x0861", "0x0863"],
      "features": [
        "webgl"
      ]
    },
    {
      "id": 74,
      "description": "GPU access is blocked if users don't have proper graphics driver installed after Windows installation",
      "cr_bugs": [248178],
      "os": {
        "type": "win"
      },
      "driver_vendor": "Microsoft",
      "exceptions": [
        {
          "vendor_id": "0x1414",
          "device_id": ["0x02c1"]
        }
      ],
      "features": [
        "all"
      ]
    },
)  // String split to avoid MSVC char limit.
LONG_STRING_CONST(
    {
      "id": 76,
      "description": "WebGL is disabled on Android unless GPU reset notification is supported",
      "os": {
        "type": "android"
      },
      "exceptions": [
        {
          "gl_reset_notification_strategy": {
            "op": "=",
            "value": "33362"
          }
        },
        {
          "gl_renderer": "Mali-400.*",
          "gl_extensions": ".*EXT_robustness.*"
        }
      ],
      "features": [
        "webgl"
      ]
    },
    {
      "id": 78,
      "description": "Accelerated video decode interferes with GPU sandbox on older Intel drivers",
      "cr_bugs": [180695, 298968, 436968],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x8086",
      "driver_version": {
        "op": "<=",
        "value": "8.15.10.2702"
      },
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 79,
      "description": "Disable GPU on all Windows versions prior to and including Vista",
      "cr_bugs": [315199],
      "os": {
        "type": "win",
        "version": {
          "op": "<=",
          "value": "6.0"
        }
      },
      "features": [
        "all"
      ]
    },
    {
      "id": 81,
      "description": "Apple software renderer used under VMWare hangs on Mac OS 10.6 and 10.7",
      "cr_bugs": [230931],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<=",
          "value": "10.7"
        }
      },
      "vendor_id": "0x15ad",
      "features": [
        "all"
      ]
    },
    {
      "id": 82,
      "description": "MediaCodec is still too buggy to use for encoding (b/11536167)",
      "os": {
        "type": "android"
      },
      "features": [
        "accelerated_video_encode"
      ]
    },
    {
      "id": 83,
      "description": "Samsung Galaxy NOTE is too buggy to use for video decoding",
      "cr_bugs": [308721],
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "4.4"
        }
      },
      "machine_model_name": ["GT-.*"],
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 85,
      "description": "Samsung Galaxy S4 is too buggy to use for video decoding",
      "cr_bugs": [329072],
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "4.4"
        }
      },
      "machine_model_name": ["SCH-.*"],
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 86,
      "description": "Intel Graphics Media Accelerator 3150 causes the GPU process to hang running WebGL",
      "cr_bugs": [305431],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x8086",
      "device_id": ["0xa011"],
      "features": [
        "webgl"
      ]
    },
    {
      "id": 87,
      "description": "Accelerated video decode on Intel driver 10.18.10.3308 is incompatible with the GPU sandbox",
      "cr_bugs": [298968],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x8086",
      "driver_version": {
        "op": "=",
        "value": "10.18.10.3308"
      },
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 88,
      "description": "Accelerated video decode on AMD driver 13.152.1.8000 is incompatible with the GPU sandbox",
      "cr_bugs": [298968],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x1002",
      "driver_version": {
        "op": "=",
        "value": "13.152.1.8000"
      },
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 89,
      "description": "Accelerated video decode interferes with GPU sandbox on certain AMD drivers",
      "cr_bugs": [298968],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x1002",
      "driver_version": {
        "op": "between",
        "value": "8.810.4.5000",
        "value2": "8.970.100.1100"
      },
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 90,
      "description": "Accelerated video decode interferes with GPU sandbox on certain NVIDIA drivers",
      "cr_bugs": [298968],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x10de",
      "driver_version": {
        "op": "between",
        "value": "8.17.12.5729",
        "value2": "8.17.12.8026"
      },
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 91,
      "description": "Accelerated video decode interferes with GPU sandbox on certain NVIDIA drivers",
      "cr_bugs": [298968],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x10de",
      "driver_version": {
        "op": "between",
        "value": "9.18.13.783",
        "value2": "9.18.13.1090"
      },
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 92,
      "description": "Accelerated video decode does not work with the discrete GPU on AMD switchables",
      "cr_bugs": [298968],
      "os": {
        "type": "win"
      },
      "multi_gpu_style": "amd_switchable_discrete",
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 93,
      "description": "GLX indirect rendering (X remoting) is not supported",
      "cr_bugs": [72373],
      "os": {
        "type": "linux"
      },
      "direct_rendering": false,
      "features": [
        "all"
      ]
    },
    {
      "id": 94,
      "description": "Intel driver version 8.15.10.1749 causes GPU process hangs.",
      "cr_bugs": [350566],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x8086",
      "driver_version": {
        "op": "=",
        "value": "8.15.10.1749"
      },
      "features": [
        "all"
      ]
    },
    {
      "id": 95,
      "description": "AMD driver version 13.101 is unstable on linux.",
      "cr_bugs": [363378],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x1002",
      "driver_vendor": ".*AMD.*",
      "driver_version": {
        "op": "=",
        "value": "13.101"
      },
      "features": [
        "all"
      ]
    },
    {
      "id": 96,
      "description": "Blacklist GPU raster/canvas on all except known good GPUs and newer Android releases",
      "cr_bugs": [362779,424970],
      "os": {
        "type": "android"
      },
      "exceptions": [
        {
          "os": {
            "type": "android"
          },
          "gl_renderer": "Adreno (TM) 3.*"
        },
        {
          "os": {
            "type": "android"
          },
          "gl_renderer": "NVIDIA.*"
        },
        {
          "os": {
            "type": "android"
          },
          "gl_renderer": "VideoCore IV.*"
        },
        {
          "os": {
            "type": "android"
          },
          "gl_renderer": "Immersion.*"
        },
        {
          "os": {
            "type": "android",
            "version": {
              "op": ">=",
              "value": "4.4"
            }
          },
          "gl_type": "gles",
          "gl_version": {
            "op": ">=",
            "value": "3.0"
          }
        }
      ],
      "features": [
        "gpu_rasterization",
        "accelerated_2d_canvas"
      ]
    },
    {
      "id": 99,
      "description": "GPU rasterization is blacklisted on non-Android",
      "cr_bugs": [362779],
      "exceptions": [
        {
          "os": {
            "type": "android"
          }
        }
      ],
      "features": [
        "gpu_rasterization"
      ]
    },
    {
      "id": 100,
      "description": "GPU rasterization and canvas is blacklisted on Nexus 10",
      "cr_bugs": [407144],
      "os": {
        "type": "android"
      },
      "gl_renderer": ".*Mali-T604.*",
      "features": [
        "gpu_rasterization",
        "accelerated_2d_canvas"
      ]
    },
    {
      "id": 101,
      "description": "Samsung Galaxy Tab is too buggy to use for video decoding",
      "cr_bugs": [408353],
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "4.4"
        }
      },
      "machine_model_name": ["SM-.*"],
      "features": [
        "accelerated_video_decode"
      ]
    },
    {
      "id": 102,
      "description": "Accelerated 2D canvas and Ganesh broken on Galaxy Tab 2",
      "cr_bugs": [416910],
      "os": {
        "type": "android"
      },
      "gl_renderer": "PowerVR SGX 540",
      "features": [
        "accelerated_2d_canvas",
        "gpu_rasterization"
      ]
    },
    {
      "id": 103,
      "description": "Intel GM965/GL960 crash often on Mac OS 10.6",
      "cr_bugs": [421641],
      "os": {
        "type": "macosx",
        "version": {
          "op": "=",
          "value": "10.6"
        }
      },
      "vendor_id": "0x8086",
      "device_id": ["0x2a02"],
      "features": [
        "all"
      ]
    },
    {
      "id": 104,
      "description": "GPU raster broken on PowerVR Rogue",
      "cr_bugs": [436331],
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "5.0"
        }
      },
      "gl_renderer": "PowerVR Rogue.*",
      "features": [
        "accelerated_2d_canvas",
        "gpu_rasterization"
      ]
    },
    {
      "id": 105,
      "description": "GPU raster broken on PowerVR SGX even on Lollipop",
      "cr_bugs": [461456],
      "os": {
        "type": "android"
      },
      "gl_renderer": "PowerVR SGX.*",
      "features": [
        "accelerated_2d_canvas",
        "gpu_rasterization"
      ]
    }
  ]
}

);  // LONG_STRING_CONST macro

}  // namespace gpu

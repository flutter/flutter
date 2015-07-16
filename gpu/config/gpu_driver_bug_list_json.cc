// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Determines whether a certain driver bug exists in the current system.
// The format of a valid gpu_driver_bug_list.json file is defined in
// <gpu/config/gpu_control_list_format.txt>.
// The supported "features" can be found in
// <gpu/config/gpu_driver_bug_workaround_type.h>.

#include "gpu/config/gpu_control_list_jsons.h"

#define LONG_STRING_CONST(...) #__VA_ARGS__

namespace gpu {

const char kGpuDriverBugListJson[] = LONG_STRING_CONST(

{
  "name": "gpu driver bug list",
  // Please update the version number whenever you change this file.
  "version": "7.18",
  "entries": [
    {
      "id": 1,
      "description": "Imagination driver doesn't like uploading lots of buffer data constantly",
      "os": {
        "type": "android"
      },
      "gl_vendor": "Imagination.*",
      "features": [
        "use_client_side_arrays_for_stream_buffers"
      ]
    },
    {
      "id": 2,
      "description": "ARM driver doesn't like uploading lots of buffer data constantly",
      "os": {
        "type": "android"
      },
      "gl_vendor": "ARM.*",
      "features": [
        "use_client_side_arrays_for_stream_buffers"
      ]
    },
    {
      "id": 3,
      "description": "glGenerateMipmap leaks vram without setting texture filters on some Mac drivers",
      "webkit_bugs": [48489],
      "cr_bugs": [349137],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.9"
        }
      },
      "features": [
        "set_texture_filter_before_generating_mipmap"
      ]
    },
    {
      "id": 4,
      "description": "glReadPixels incorrectly sets alpha to 0 on some drivers from a drawing buffer without alpha channel",
      "webkit_bugs": [33416],
      "cr_bugs": [349137],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.9"
        }
      },
      "features": [
        "clear_alpha_in_readpixels"
      ]
    },
    {
      "id": 5,
      "description": "Always call glUseProgram after a successful link to avoid a driver bug",
      "cr_bugs": [349137],
      "vendor_id": "0x10de",
      "exceptions": [
        {
          "os": {
            "type": "macosx",
            "version": {
              "op": ">=",
              "value": "10.9"
            }
          }
        }
      ],
      "features": [
        "use_current_program_after_successful_link"
      ]
    },
    {
      "id": 6,
      "description": "Restore scissor on FBO change with Qualcomm GPUs on older versions of Android",
      "cr_bugs": [165493, 222018],
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "4.3"
        }
      },
      "gl_vendor": "Qualcomm.*",
      "features": [
        "restore_scissor_on_fbo_change"
      ]
    },
    {
      "id": 7,
      "cr_bugs": [89557],
      "description": "Work around a bug in offscreen buffers on NVIDIA GPUs on Macs",
      "os": {
        "type": "macosx"
      },
      "vendor_id": "0x10de",
      "features": [
        "needs_offscreen_buffer_workaround"
      ]
    },
    {
      "id": 8,
      "description": "A few built-in glsl functions on Mac behave incorrectly",
      "cr_bugs": [349137],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.9"
        }
      },
      "vendor_id": "0x1002",
      "features": [
        "needs_glsl_built_in_function_emulation"
      ]
    },
    {
      "id": 9,
      "description": "AMD drivers get gl_PointCoord backward on OS X 10.8 or earlier",
      "cr_bugs": [256349],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.9"
        }
      },
      "vendor_id": "0x1002",
      "features": [
        "reverse_point_sprite_coord_origin"
      ]
    },
    {
      "id": 10,
      "description": "Intel drivers get gl_PointCoord backward on OS X 10.8 or earlier",
      "cr_bugs": [256349],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.9"
        }
      },
      "vendor_id": "0x8086",
      "features": [
        "reverse_point_sprite_coord_origin"
      ]
    },
    {
      "id": 11,
      "description": "Limit max texure size to 4096 on Macs with Intel GPUs",
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.9"
        }
      },
      "vendor_id": "0x8086",
      "features": [
        "max_texture_size_limit_4096"
      ]
    },
    {
      "id": 12,
      "description": "Limit max cube map texure size to 1024 on Macs with Intel GPUs",
      "os": {
        "type": "macosx"
      },
      "vendor_id": "0x8086",
      "features": [
        "max_cube_map_texture_size_limit_1024"
      ]
    },
    {
      "id": 13,
      "description": "Limit max cube map texure size to 512 on older Macs with Intel GPUs",
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.7.3"
        }
      },
      "vendor_id": "0x8086",
      "features": [
        "max_cube_map_texture_size_limit_512"
      ]
    },
    {
      "id": 14,
      "description": "Limit max texure size and cube map texture size to 4096 on Macs with AMD GPUs",
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.9"
        }
      },
      "vendor_id": "0x1002",
      "features": [
        "max_texture_size_limit_4096",
        "max_cube_map_texture_size_limit_4096"
      ]
    },
    {
      "id": 16,
      "description": "EXT_occlusion_query appears to be buggy with Intel GPUs on Linux",
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x8086",
      "features": [
        "disable_ext_occlusion_query"
      ]
    },
    {
      "id": 17,
      "description": "Some drivers are unable to reset the D3D device in the GPU process sandbox",
      "os": {
        "type": "win"
      },
      "features": [
        "exit_on_context_lost"
      ]
    },
    {
      "id": 19,
      "description": "Disable depth textures on Android with Qualcomm GPUs",
      "os": {
        "type": "android"
      },
      "gl_vendor": "Qualcomm.*",
      "features": [
        "disable_depth_texture"
      ]
    },
    {
      "id": 20,
      "description": "Disable EXT_draw_buffers on GeForce GT 650M on Mac OS X due to driver bugs",
      "os": {
        "type": "macosx"
      },
      "vendor_id": "0x10de",
      "device_id": ["0x0fd5"],
      "multi_gpu_category": "any",
      "features": [
        "disable_ext_draw_buffers"
      ]
    },
    {
      "id": 21,
      "description": "Vivante GPUs are buggy with context switching",
      "cr_bugs": [179250, 235935],
      "os": {
        "type": "android"
      },
      "gl_extensions": ".*GL_VIV_shader_binary.*",
      "features": [
        "unbind_fbo_on_context_switch"
      ]
    },
    {
      "id": 22,
      "description": "Imagination drivers are buggy with context switching",
      "cr_bugs": [230896],
      "os": {
        "type": "android"
      },
      "gl_vendor": "Imagination.*",
      "features": [
        "unbind_fbo_on_context_switch"
      ]
    },
    {
      "id": 23,
      "cr_bugs": [243038],
      "description": "Disable OES_standard_derivative on Intel Pineview M Gallium drivers",
      "os": {
        "type": "chromeos"
      },
      "vendor_id": "0x8086",
      "device_id": ["0xa011", "0xa012"],
      "features": [
        "disable_oes_standard_derivatives"
      ]
    },
    {
      "id": 24,
      "cr_bugs": [231082],
      "description": "Mali-400 drivers throw an error when a buffer object's size is set to 0",
      "os": {
        "type": "android"
      },
      "gl_vendor": "ARM.*",
      "gl_renderer": ".*Mali-400.*",
      "features": [
        "use_non_zero_size_for_client_side_stream_buffers"
      ]
    },
    {
      "id": 25,
      "cr_bugs": [152225],
      "description": "PBO + Readpixels don't work on OS X 10.7",
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.8"
        }
      },
      "features": [
        "disable_async_readpixels"
      ]
    },
    {
      "id": 26,
      "description": "Disable use of Direct3D 11 on Windows Vista and lower",
      "os": {
        "type": "win",
        "version": {
          "op": "<=",
          "value": "6.0"
        }
      },
      "features": [
        "disable_d3d11"
      ]
    },
    {
      "id": 27,
      "cr_bugs": [265115],
      "description": "Async Readpixels with GL_BGRA format is broken on Haswell chipset on Macs",
      "os": {
        "type": "macosx"
      },
      "vendor_id": "0x8086",
      "device_id": ["0x0402", "0x0406", "0x040a", "0x0412", "0x0416", "0x041a",
                    "0x0a04", "0x0a16", "0x0a22", "0x0a26", "0x0a2a"],
      "features": [
        "swizzle_rgba_for_async_readpixels"
      ]
    },
    {
      "id": 30,
      "cr_bugs": [237931],
      "description": "Multisampling is buggy on OSX when multiple monitors are connected",
      "os": {
        "type": "macosx"
      },
      "features": [
        "disable_multimonitor_multisampling"
      ]
    },
    {
      "id": 31,
      "cr_bugs": [154715, 10068, 269829, 294779, 285292],
      "description": "The Mali-Txxx driver does not guarantee flush ordering",
      "gl_vendor": "ARM.*",
      "gl_renderer": "Mali-T.*",
      "features": [
        "use_virtualized_gl_contexts"
      ]
    },
    {
      "id": 32,
      "cr_bugs": [179815],
      "description": "Share groups are not working on (older?) Broadcom drivers",
      "os": {
        "type": "android"
      },
      "gl_vendor": "Broadcom.*",
      "features": [
        "use_virtualized_gl_contexts"
      ]
    },
    {
      "id": 33,
      "description": "Share group-related crashes and poor context switching perf on Galaxy Nexus",
      "os": {
        "type": "android"
      },
      "gl_vendor": "Imagination.*",
      "features": [
        "use_virtualized_gl_contexts"
      ]
    },
    {
      "id": 34,
      "cr_bugs": [179250, 229643, 230896],
      "description": "Share groups are not working on (older?) Vivante drivers",
      "os": {
        "type": "android"
      },
      "gl_extensions": ".*GL_VIV_shader_binary.*",
      "features": [
        "use_virtualized_gl_contexts"
      ]
    },
    {
      "id": 35,
      "cr_bugs": [163464],
      "description": "Share-group related crashes on older NVIDIA drivers",
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "4.3"
        }
      },
      "gl_vendor": "NVIDIA.*",
      "features": [
        "use_virtualized_gl_contexts"
      ]
    },
    {
      "id": 36,
      "cr_bugs": [163464, 233612],
      "description": "Share-group related crashes on Qualcomm drivers",
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "4.3"
        }
      },
      "gl_vendor": "Qualcomm.*",
      "features": [
        "use_virtualized_gl_contexts"
      ]
    },
    {
      "id": 37,
      "cr_bugs": [286468],
      "description": "Program link fails in NVIDIA Linux if gl_Position is not set",
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x10de",
      "features": [
        "init_gl_position_in_vertex_shader"
      ]
    },
    {
      "id": 38,
      "cr_bugs": [289461],
      "description": "Non-virtual contexts on Qualcomm sometimes cause out-of-order frames",
      "os": {
        "type": "android"
      },
      "gl_vendor": "Qualcomm.*",
      "features": [
        "use_virtualized_gl_contexts"
      ]
    },
    {
      "id": 39,
      "cr_bugs": [290391],
      "description": "Multisampled renderbuffer allocation must be validated on some Macs",
      "os": {
        "type": "macosx"
      },
      "features": [
        "validate_multisample_buffer_allocation"
      ]
    },
    {
      "id": 40,
      "cr_bugs": [290876],
      "description": "Framebuffer discarding causes flickering on old ARM drivers",
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "4.4"
        }
      },
      "gl_vendor": "ARM.*",
      "features": [
        "disable_discard_framebuffer"
      ]
    },
    {
      "id": 42,
      "cr_bugs": [290876],
      "description": "Framebuffer discarding causes flickering on older IMG drivers",
      "os": {
        "type": "android"
      },
      "gl_vendor": "Imagination.*",
      "gl_renderer": "PowerVR SGX 540",
      "features": [
        "disable_discard_framebuffer"
      ]
    },
    {
      "id": 43,
      "cr_bugs": [299494],
      "description": "Framebuffer discarding doesn't accept trivial attachments on Vivante",
      "os": {
        "type": "android"
      },
      "gl_extensions": ".*GL_VIV_shader_binary.*",
      "features": [
        "disable_discard_framebuffer"
      ]
    },
    {
      "id": 44,
      "cr_bugs": [301988],
      "description": "Framebuffer discarding causes jumpy scrolling on Mali drivers",
      "os": {
        "type": "chromeos"
      },
      "features": [
        "disable_discard_framebuffer"
      ]
    },
    {
      "id": 45,
      "cr_bugs": [307751],
      "description": "Unfold short circuit on Mac OS X",
      "os": {
        "type": "macosx"
      },
      "features": [
        "unfold_short_circuit_as_ternary_operation"
      ]
    },
    {
      "id": 48,
      "description": "Force to use discrete GPU on older MacBookPro models",
      "cr_bugs": [113703],
      "os": {
        "type": "macosx",
        "version": {
          "op": ">=",
          "value": "10.7"
        }
      },
      "machine_model_name": ["MacBookPro"],
      "machine_model_version": {
        "op": "<",
        "value": "8"
      },
      "gpu_count": {
        "op": "=",
        "value": "2"
      },
      "features": [
        "force_discrete_gpu"
      ]
    },
    {
      "id": 49,
      "cr_bugs": [309734],
      "description": "The first draw operation from an idle state is slow",
      "os": {
        "type": "android"
      },
      "gl_vendor": "Qualcomm.*",
      "features": [
        "wake_up_gpu_before_drawing"
      ]
    },
    {
      "id": 51,
      "description": "TexSubImage2D() is faster for full uploads on ANGLE",
      "os": {
        "type": "win"
      },
      "gl_renderer": "ANGLE.*",
      "features": [
        "texsubimage2d_faster_than_teximage2d"
      ]
    },
    {
      "id": 52,
      "description": "ES3 MSAA is broken on Qualcomm",
      "os": {
        "type": "android"
      },
      "gl_vendor": "Qualcomm.*",
      "features": [
        "disable_multisampling"
      ]
    },
    {
      "id": 54,
      "cr_bugs": [124764, 349137],
      "description": "Clear uniforms before first program use on all platforms",
      "exceptions": [
        {
          "os": {
            "type": "macosx",
            "version": {
              "op": ">=",
              "value": "10.9"
            }
          }
        }
      ],
      "features": [
        "clear_uniforms_before_first_program_use"
      ]
    },
    {
      "id": 55,
      "cr_bugs": [333885],
      "description": "Mesa drivers in Linux handle varyings without static use incorrectly",
      "os": {
        "type": "linux"
      },
      "driver_vendor": "Mesa",
      "features": [
        "count_all_in_varyings_packing"
      ]
    },
    {
      "id": 56,
      "cr_bugs": [333885],
      "description": "Mesa drivers in ChromeOS handle varyings without static use incorrectly",
      "os": {
        "type": "chromeos"
      },
      "driver_vendor": "Mesa",
      "features": [
        "count_all_in_varyings_packing"
      ]
    },
    {
      "id": 57,
      "cr_bugs": [322760],
      "description": "Mac drivers handle varyings without static use incorrectly",
      "os": {
        "type": "macosx"
      },
      "features": [
        "init_varyings_without_static_use"
      ]
    },
    {
      "id": 58,
      "description": "Multisampling is buggy in ATI cards on older Mac OS X",
      "cr_bugs": [67752, 83153],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.7.2"
        }
      },
      "vendor_id": "0x1002",
      "features": [
        "disable_multisampling"
      ]
    },
    {
      "id": 59,
      "description": "Multisampling is buggy in Intel IvyBridge",
      "cr_bugs": [116370],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x8086",
      "device_id": ["0x0152", "0x0156", "0x015a", "0x0162", "0x0166"],
      "features": [
        "disable_multisampling"
      ]
    },
    {
      "id": 60,
      "description": "Multisampling is buggy on Mac OS X prior to 10.8.3",
      "cr_bugs": [137303, 162466],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.8.3"
        }
      },
      "features": [
        "disable_multisampling"
      ]
    },
    {
      "id": 63,
      "description": "Shaders with sampler arrays indexing for-loop indices cause the GLSL compiler to crash on OS X",
      "cr_bugs": [348198, 349137],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<",
          "value": "10.9"
        }
      },
      "features": [
        "unroll_for_loop_with_sampler_array_index"
      ]
    },
    {
      "id": 64,
      "description": "Linux AMD drivers incorrectly return initial value of 1 for TEXTURE_MAX_ANISOTROPY",
      "cr_bugs": [348237],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x1002",
      "features": [
        "init_texture_max_anisotropy"
      ]
    },
    {
      "id": 65,
      "description": "Linux NVIDIA drivers don't have the correct defaults for vertex attributes",
      "cr_bugs": [351528],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x10de",
      "features": [
        "init_vertex_attributes"
      ]
    },
    {
      "id": 66,
      "description": "Force glFinish() after compositing on older OS X on Intel GPU",
      "cr_bugs": [123409],
      "os": {
        "type": "macosx",
        "version": {
          "op": "<=",
          "value": "10.7"
        }
      },
      "vendor_id": "0x8086",
      "multi_gpu_category": "active",
      "features": [
        "force_gl_finish_after_compositing"
      ]
    },
    {
      "id": 68,
      "description": "Disable partial swaps on linux drivers",
      "cr_bugs": [339493],
      "os": {
        "type": "linux"
      },
      "driver_vendor": "Mesa",
      "features": [
        "disable_post_sub_buffers_for_onscreen_surfaces"
      ]
    },
    {
      "id": 69,
      "description": "Some shaders in Skia need more than the min available vertex and fragment shader uniform vectors in case of OSMesa",
      "cr_bugs": [174845],
      "driver_vendor": "osmesa",
      "features": [
       "max_fragment_uniform_vectors_32",
       "max_varying_vectors_16",
       "max_vertex_uniform_vectors_256"
      ]
    },
    {
      "id": 70,
      "description": "Disable D3D11 on older nVidia drivers",
      "cr_bugs": [349929],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x10de",
      "driver_version": {
        "op": "<=",
        "value": "8.17.12.6973"
      },
      "features": [
        "disable_d3d11"
      ]
    },
    {
      "id": 71,
      "description": "Vivante's support of OES_standard_derivatives is buggy",
      "cr_bugs": [368005],
      "os": {
        "type": "android"
      },
      "gl_extensions": ".*GL_VIV_shader_binary.*",
      "features": [
        "disable_oes_standard_derivatives"
      ]
    },
    {
      "id": 72,
      "description": "Use virtual contexts on NVIDIA with GLES 3.1",
      "cr_bugs": [369316],
      "os": {
        "type": "android"
      },
      "gl_type": "gles",
      "gl_version": {
        "op": "=",
        "value": "3.1"
      },
      "gl_vendor": "NVIDIA.*",
      "features": [
        "use_virtualized_gl_contexts"
      ]
    },
)  // LONG_STRING_CONST macro
// Avoid C2026 (string too big) error on VisualStudio.
LONG_STRING_CONST(
    {
      "id": 74,
      "cr_bugs": [278606, 382686],
      "description": "Testing EGL sync fences was broken on most Qualcomm drivers",
      "os": {
        "type": "android",
        "version": {
          "op": "<=",
          "value": "4.4.4"
        }
      },
      "gl_vendor": "Qualcomm.*",
      "features": [
        "disable_egl_khr_fence_sync"
      ]
    },
    {
      "id": 75,
      "description": "Mali-400 support of EXT_multisampled_render_to_texture is buggy on Android < 4.3",
      "cr_bugs": [362435],
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "4.3"
        }
      },
      "gl_vendor": "ARM.*",
      "gl_renderer": ".*Mali-400.*",
      "features": [
        "disable_multisampling"
      ]
    },
    {
      "id": 76,
      "cr_bugs": [371530],
      "description": "Testing EGL sync fences was broken on IMG",
      "os": {
        "type": "android",
        "version": {
          "op": "<=",
          "value": "4.4.4"
        }
      },
      "gl_vendor": "Imagination Technologies.*",
      "features": [
        "disable_egl_khr_fence_sync"
      ]
    },
    {
      "id": 77,
      "cr_bugs": [378691, 373360, 371530, 398964],
      "description": "Testing fences was broken on Mali ES2 drivers",
      "os": {
        "type": "android",
        "version": {
          "op": "<=",
          "value": "4.4.4"
        }
      },
      "gl_vendor": "ARM.*",
      "gl_renderer": "Mali.*",
      "gl_type": "gles",
      "gl_version": {
        "op": "<",
        "value": "3.0"
      },
      "features": [
        "disable_egl_khr_fence_sync"
      ]
    },
    {
      "id": 78,
      "cr_bugs": [378691, 373360, 371530],
      "description": "Testing fences was broken on Broadcom drivers",
      "os": {
        "type": "android",
        "version": {
          "op": "<=",
          "value": "4.4.4"
        }
      },
      "gl_vendor": "Broadcom.*",
      "features": [
        "disable_egl_khr_fence_sync"
      ]
    },
    {
      "id": 82,
      "description": "PBO mappings segfault on certain older Qualcomm drivers",
      "cr_bugs": [394510],
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "4.3"
        }
      },
      "gl_vendor": "Qualcomm.*",
      "features": [
        "disable_async_readpixels"
      ]
    },
    {
      "id": 86,
      "description": "Disable use of Direct3D 11 on Matrox video cards",
      "cr_bugs": [395861],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x102b",
      "features": [
        "disable_d3d11"
      ]
    },
    {
      "id": 87,
      "description": "Disable use of Direct3D 11 on older AMD drivers",
      "cr_bugs": [402134],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x1002",
      "driver_date": {
        "op": "<",
        "value": "2011.1"
      },
      "features": [
        "disable_d3d11"
      ]
    },
    {
      "id": 88,
      "description": "Always rewrite vec/mat constructors to be consistent",
      "cr_bugs": [398694],
      "features": [
        "scalarize_vec_and_mat_constructor_args"
      ]
    },
    {
      "id": 89,
      "description": "Mac drivers handle struct scopes incorrectly",
      "cr_bugs": [403957],
      "os": {
        "type": "macosx"
      },
      "features": [
        "regenerate_struct_names"
      ]
    },
    {
      "id": 90,
      "description": "Linux AMD drivers handle struct scopes incorrectly",
      "cr_bugs": [403957],
      "os": {
        "type": "linux"
      },
      "vendor_id": "0x1002",
      "features": [
        "regenerate_struct_names"
      ]
    },
    {
      "id": 91,
      "cr_bugs": [150500, 414816],
      "description": "ETC1 non-power-of-two sized textures crash older IMG drivers",
      "os": {
        "type": "android"
      },
      "gl_vendor": "Imagination.*",
      "gl_renderer": "PowerVR SGX 5.*",
      "features": [
        "etc1_power_of_two_only"
      ]
    },
    {
      "id": 92,
      "description": "Old Intel drivers cannot reliably support D3D11",
      "cr_bugs": [363721],
      "os": {
        "type": "win"
      },
      "vendor_id": "0x8086",
      "driver_version": {
        "op": "<",
        "value": "8.16"
      },
      "features": [
        "disable_d3d11"
      ]
    },
    {
      "id": 93,
      "description": "The GL implementation on the Android emulator has problems with PBOs.",
      "cr_bugs": [340882],
      "os": {
        "type": "android"
      },
      "gl_vendor": "VMware.*",
      "gl_renderer": "Gallium.*",
      "gl_type": "gles",
      "gl_version": {
        "op": "=",
        "value": "3.0"
      },
      "features": [
        "disable_async_readpixels"
      ]
    },
    {
      "id": 94,
      "description": "Disable EGL_KHR_wait_sync on NVIDIA with GLES 3.1",
      "cr_bugs": [433057],
      "os": {
        "type": "android",
        "version": {
          "op": "<=",
          "value": "5.0.2"
        }
      },
      "gl_vendor": "NVIDIA.*",
      "gl_type": "gles",
      "gl_version": {
        "op": "=",
        "value": "3.1"
      },
      "features": [
        "disable_egl_khr_wait_sync"
      ]
    },
    {
      "id": 95,
      "cr_bugs": [421271],
      "description": "glClear does not always work on these drivers",
      "os": {
        "type": "android"
      },
      "gl_type": "gles",
      "gl_version": {
        "op": "<",
        "value": "3.0"
      },
      "gl_vendor": "Imagination.*",
      "features": [
        "gl_clear_broken"
      ]
    },
    {
      "id": 96,
      "description": "glBindFramebuffer sometimes requires a glBegin/End to take effect",
      "cr_bugs": [435786],
      "os": {
        "type": "macosx"
      },
      "features": [
        "gl_begin_gl_end_on_fbo_change_to_backbuffer"
      ]
    },
    {
      "id": 97,
      "description": "Multisampling has poor performance in Intel BayTrail",
      "cr_bugs": [443517],
      "os": {
        "type": "android"
      },
      "gl_vendor": "Intel",
      "gl_renderer": "Intel.*BayTrail",
      "features": [
        "disable_multisampling"
      ]
    },
    {
      "id": 98,
      "description": "PowerVR SGX 540 drivers throw GL_OUT_OF_MEMORY error when a buffer object's size is set to 0",
      "cr_bugs": [451501],
      "os": {
        "type": "android"
      },
      "gl_vendor": "Imagination.*",
      "gl_renderer": "PowerVR SGX 540",
      "features": [
        "use_non_zero_size_for_client_side_stream_buffers"
      ]
    },
    {
      "id": 99,
      "description": "Qualcomm driver before Lollipop deletes egl sync objects after context destruction",
      "cr_bugs": [453857],
      "os": {
        "type": "android",
        "version": {
          "op": "<",
          "value": "5.0.0"
        }
      },
      "gl_vendor": "Qualcomm.*",
      "features": [
        "ignore_egl_sync_failures"
      ]
    },
    {
      "id": 100,
      "description": "Disable Direct3D11 on systems with AMD switchable graphics",
      "cr_bugs": [451420],
      "os": {
        "type": "win"
      },
      "multi_gpu_style": "amd_switchable",
      "features": [
        "disable_d3d11"
      ]
    },
    {
      "id": 101,
      "description": "The Mali-Txxx driver hangs when reading from currently displayed buffer",
      "cr_bugs": [457511],
      "os": {
        "type": "chromeos"
      },
      "gl_vendor": "ARM.*",
      "gl_renderer": "Mali-T.*",
      "features": [
        "disable_post_sub_buffers_for_onscreen_surfaces"
      ]
    },
    {
      "id": 102,
      "description": "Adreno 420 driver loses FBO attachment contents on bound FBO deletion",
      "cr_bugs": [457027],
      "os": {
        "type": "android",
        "version": {
          "op": ">",
          "value": "5.0.2"
        }
      },
      "gl_vendor": "Qualcomm.*",
      "gl_renderer": ".*420",
      "features": [
        "unbind_attachments_on_bound_render_fbo_delete"
      ]
    },
    {
      "id": 103,
      "description": "Adreno 420 driver drops draw calls after FBO invalidation",
      "cr_bugs": [443060],
      "os": {
        "type": "android"
      },
      "gl_vendor": "Qualcomm.*",
      "gl_renderer": ".*420",
      "features": [
        "disable_discard_framebuffer"
      ]
    }
  ]
}

);  // LONG_STRING_CONST macro

}  // namespace gpu

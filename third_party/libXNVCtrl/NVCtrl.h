/*
 * Copyright (c) 2010 NVIDIA, Corporation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice (including the next
 * paragraph) shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef __NVCTRL_H
#define __NVCTRL_H

#include <stdint.h>

/**************************************************************************/

/*
 * Attribute Targets
 *
 * Targets define attribute groups.  For example, some attributes are only
 * valid to set on a GPU, others are only valid when talking about an
 * X Screen.  Target types are then what is used to identify the target
 * group of the attribute you wish to set/query.
 *
 * Here are the supported target types:
 */

#define NV_CTRL_TARGET_TYPE_X_SCREEN       0
#define NV_CTRL_TARGET_TYPE_GPU            1
#define NV_CTRL_TARGET_TYPE_FRAMELOCK      2
#define NV_CTRL_TARGET_TYPE_VCSC           3 /* Visual Computing System */
#define NV_CTRL_TARGET_TYPE_GVI            4
#define NV_CTRL_TARGET_TYPE_COOLER         5 /* e.g., fan */
#define NV_CTRL_TARGET_TYPE_THERMAL_SENSOR 6
#define NV_CTRL_TARGET_TYPE_3D_VISION_PRO_TRANSCEIVER 7
#define NV_CTRL_TARGET_TYPE_DISPLAY        8

/**************************************************************************/

/*
 * Attributes
 *
 * Some attributes may only be read; some may require a display_mask
 * argument and others may be valid only for specific target types.
 * This information is encoded in the "permission" comment after each
 * attribute #define, and can be queried at run time with
 * XNVCTRLQueryValidAttributeValues() and/or
 * XNVCTRLQueryValidTargetAttributeValues()
 *
 * Key to Integer Attribute "Permissions":
 *
 * R: The attribute is readable (in general, all attributes will be
 *    readable)
 *
 * W: The attribute is writable (attributes may not be writable for
 *    various reasons: they represent static system information, they
 *    can only be changed by changing an XF86Config option, etc).
 *
 * D: The attribute requires the display mask argument.  The
 *    attributes NV_CTRL_CONNECTED_DISPLAYS and NV_CTRL_ENABLED_DISPLAYS
 *    will be a bitmask of what display devices are connected and what
 *    display devices are enabled for use in X, respectively.  Each bit
 *    in the bitmask represents a display device; it is these bits which
 *    should be used as the display_mask when dealing with attributes
 *    designated with "D" below.  For attributes that do not require the
 *    display mask, the argument is ignored.
 *
 *    Alternatively, NV-CONTROL versions 1.27 and greater allow these
 *    attributes to be accessed via display target types, in which case
 *    the display_mask is ignored.
 *
 * G: The attribute may be queried using an NV_CTRL_TARGET_TYPE_GPU
 *    target type via XNVCTRLQueryTargetAttribute().
 *
 * F: The attribute may be queried using an NV_CTRL_TARGET_TYPE_FRAMELOCK
 *    target type via XNVCTRLQueryTargetAttribute().
 *
 * X: When Xinerama is enabled, this attribute is kept consistent across
 *    all Physical X Screens;  assignment of this attribute will be
 *    broadcast by the NVIDIA X Driver to all X Screens.
 *
 * V: The attribute may be queried using an NV_CTRL_TARGET_TYPE_VCSC
 *    target type via XNVCTRLQueryTargetAttribute().
 *
 * I: The attribute may be queried using an NV_CTRL_TARGET_TYPE_GVI target type
 *    via XNVCTRLQueryTargetAttribute().
 *
 * Q: The attribute is a 64-bit integer attribute;  use the 64-bit versions
 *    of the appropriate query interfaces.
 *
 * C: The attribute may be queried using an NV_CTRL_TARGET_TYPE_COOLER target
 *    type via XNVCTRLQueryTargetAttribute().
 *
 * S: The attribute may be queried using an NV_CTRL_TARGET_TYPE_THERMAL_SENSOR
 *    target type via XNVCTRLQueryTargetAttribute().
 *
 * T: The attribute may be queried using an
 *    NV_CTRL_TARGET_TYPE_3D_VISION_PRO_TRANSCEIVER target type
 *    via XNVCTRLQueryTargetAttribute().
 *
 * NOTE: Unless mentioned otherwise, all attributes may be queried using
 *       an NV_CTRL_TARGET_TYPE_X_SCREEN target type via
 *       XNVCTRLQueryTargetAttribute().
 */


/**************************************************************************/

/*
 * Integer attributes:
 *
 * Integer attributes can be queried through the XNVCTRLQueryAttribute() and
 * XNVCTRLQueryTargetAttribute() function calls.
 * 
 * Integer attributes can be set through the XNVCTRLSetAttribute() and
 * XNVCTRLSetTargetAttribute() function calls.
 *
 * Unless otherwise noted, all integer attributes can be queried/set
 * using an NV_CTRL_TARGET_TYPE_X_SCREEN target.  Attributes that cannot
 * take an NV_CTRL_TARGET_TYPE_X_SCREEN also cannot be queried/set through
 * XNVCTRLQueryAttribute()/XNVCTRLSetAttribute() (Since these assume
 * an X Screen target).
 */


/*
 * NV_CTRL_FLATPANEL_SCALING - not supported
 */

#define NV_CTRL_FLATPANEL_SCALING                               2  /* RWDG */
#define NV_CTRL_FLATPANEL_SCALING_DEFAULT                       0
#define NV_CTRL_FLATPANEL_SCALING_NATIVE                        1
#define NV_CTRL_FLATPANEL_SCALING_SCALED                        2
#define NV_CTRL_FLATPANEL_SCALING_CENTERED                      3
#define NV_CTRL_FLATPANEL_SCALING_ASPECT_SCALED                 4


/*
 * NV_CTRL_FLATPANEL_DITHERING is deprecated; NV_CTRL_DITHERING should
 * be used instead.
 */

#define NV_CTRL_FLATPANEL_DITHERING                             3  /* RWDG */
#define NV_CTRL_FLATPANEL_DITHERING_DEFAULT                     0
#define NV_CTRL_FLATPANEL_DITHERING_ENABLED                     1
#define NV_CTRL_FLATPANEL_DITHERING_DISABLED                    2

/*
 * NV_CTRL_DITHERING - the requested dithering configuration;
 * possible values are:
 *
 * 0: auto     (the driver will decide when to dither)
 * 1: enabled  (the driver will always dither when possible)
 * 2: disabled (the driver will never dither)
 */

#define NV_CTRL_DITHERING                                       3  /* RWDG */
#define NV_CTRL_DITHERING_AUTO                                  0
#define NV_CTRL_DITHERING_ENABLED                               1
#define NV_CTRL_DITHERING_DISABLED                              2


/*
 * NV_CTRL_DIGITAL_VIBRANCE - sets the digital vibrance level for the
 * specified display device.
 */

#define NV_CTRL_DIGITAL_VIBRANCE                                4  /* RWDG */


/*
 * NV_CTRL_BUS_TYPE - returns the bus type through which the specified device
 * is connected to the computer.
 * When this attribute is queried on an X screen target, the bus type of the
 * GPU driving the X screen is returned.
 */

#define NV_CTRL_BUS_TYPE                                        5  /* R--GI */
#define NV_CTRL_BUS_TYPE_AGP                                    0
#define NV_CTRL_BUS_TYPE_PCI                                    1
#define NV_CTRL_BUS_TYPE_PCI_EXPRESS                            2
#define NV_CTRL_BUS_TYPE_INTEGRATED                             3


/*
 * NV_CTRL_VIDEO_RAM - returns the total amount of memory available
 * to the specified GPU (or the GPU driving the specified X
 * screen).  Note: if the GPU supports TurboCache(TM), the value
 * reported may exceed the amount of video memory installed on the
 * GPU.  The value reported for integrated GPUs may likewise exceed
 * the amount of dedicated system memory set aside by the system
 * BIOS for use by the integrated GPU.
 */

#define NV_CTRL_VIDEO_RAM                                       6  /* R--G */


/*
 * NV_CTRL_IRQ - returns the interrupt request line used by the specified
 * device.
 * When this attribute is queried on an X screen target, the IRQ of the GPU
 * driving the X screen is returned.
 */

#define NV_CTRL_IRQ                                             7  /* R--GI */


/*
 * NV_CTRL_OPERATING_SYSTEM - returns the operating system on which
 * the X server is running.
 */

#define NV_CTRL_OPERATING_SYSTEM                                8  /* R--G */
#define NV_CTRL_OPERATING_SYSTEM_LINUX                          0
#define NV_CTRL_OPERATING_SYSTEM_FREEBSD                        1
#define NV_CTRL_OPERATING_SYSTEM_SUNOS                          2


/*
 * NV_CTRL_SYNC_TO_VBLANK - enables sync to vblank for OpenGL clients.
 * This setting is only applied to OpenGL clients that are started
 * after this setting is applied.
 */

#define NV_CTRL_SYNC_TO_VBLANK                                  9  /* RW-X */
#define NV_CTRL_SYNC_TO_VBLANK_OFF                              0
#define NV_CTRL_SYNC_TO_VBLANK_ON                               1


/*
 * NV_CTRL_LOG_ANISO - enables anisotropic filtering for OpenGL
 * clients; on some NVIDIA hardware, this can only be enabled or
 * disabled; on other hardware different levels of anisotropic
 * filtering can be specified.  This setting is only applied to OpenGL
 * clients that are started after this setting is applied.
 */

#define NV_CTRL_LOG_ANISO                                       10 /* RW-X */


/*
 * NV_CTRL_FSAA_MODE - the FSAA setting for OpenGL clients; possible
 * FSAA modes:
 * 
 * NV_CTRL_FSAA_MODE_2x     "2x Bilinear Multisampling"
 * NV_CTRL_FSAA_MODE_2x_5t  "2x Quincunx Multisampling"
 * NV_CTRL_FSAA_MODE_15x15  "1.5 x 1.5 Supersampling"
 * NV_CTRL_FSAA_MODE_2x2    "2 x 2 Supersampling"
 * NV_CTRL_FSAA_MODE_4x     "4x Bilinear Multisampling"
 * NV_CTRL_FSAA_MODE_4x_9t  "4x Gaussian Multisampling"
 * NV_CTRL_FSAA_MODE_8x     "2x Bilinear Multisampling by 4x Supersampling"
 * NV_CTRL_FSAA_MODE_16x    "4x Bilinear Multisampling by 4x Supersampling"
 * NV_CTRL_FSAA_MODE_8xS    "4x Multisampling by 2x Supersampling"
 *
 * This setting is only applied to OpenGL clients that are started
 * after this setting is applied.
 */

#define NV_CTRL_FSAA_MODE                                       11 /* RW-X */
#define NV_CTRL_FSAA_MODE_NONE                                  0
#define NV_CTRL_FSAA_MODE_2x                                    1
#define NV_CTRL_FSAA_MODE_2x_5t                                 2
#define NV_CTRL_FSAA_MODE_15x15                                 3
#define NV_CTRL_FSAA_MODE_2x2                                   4
#define NV_CTRL_FSAA_MODE_4x                                    5
#define NV_CTRL_FSAA_MODE_4x_9t                                 6
#define NV_CTRL_FSAA_MODE_8x                                    7
#define NV_CTRL_FSAA_MODE_16x                                   8
#define NV_CTRL_FSAA_MODE_8xS                                   9
#define NV_CTRL_FSAA_MODE_8xQ                                  10
#define NV_CTRL_FSAA_MODE_16xS                                 11
#define NV_CTRL_FSAA_MODE_16xQ                                 12
#define NV_CTRL_FSAA_MODE_32xS                                 13
#define NV_CTRL_FSAA_MODE_32x                                  14
#define NV_CTRL_FSAA_MODE_64xS                                 15
#define NV_CTRL_FSAA_MODE_MAX NV_CTRL_FSAA_MODE_64xS


/*
 * NV_CTRL_TEXTURE_SHARPEN - enables texture sharpening for OpenGL
 * clients.  This setting is only applied to OpenGL clients that are
 * started after this setting is applied.
 */

#define NV_CTRL_TEXTURE_SHARPEN                                 12 /* RW-X */
#define NV_CTRL_TEXTURE_SHARPEN_OFF                             0
#define NV_CTRL_TEXTURE_SHARPEN_ON                              1


/*
 * NV_CTRL_UBB - returns whether UBB is enabled for the specified X
 * screen.
 */

#define NV_CTRL_UBB                                             13 /* R-- */
#define NV_CTRL_UBB_OFF                                         0
#define NV_CTRL_UBB_ON                                          1


/*
 * NV_CTRL_OVERLAY - returns whether the RGB overlay is enabled for
 * the specified X screen.
 */

#define NV_CTRL_OVERLAY                                         14 /* R-- */
#define NV_CTRL_OVERLAY_OFF                                     0
#define NV_CTRL_OVERLAY_ON                                      1


/*
 * NV_CTRL_STEREO - returns whether stereo (and what type) is enabled
 * for the specified X screen.
 */

#define NV_CTRL_STEREO                                          16 /* R-- */
#define NV_CTRL_STEREO_OFF                                      0
#define NV_CTRL_STEREO_DDC                                      1
#define NV_CTRL_STEREO_BLUELINE                                 2
#define NV_CTRL_STEREO_DIN                                      3
#define NV_CTRL_STEREO_PASSIVE_EYE_PER_DPY                      4
#define NV_CTRL_STEREO_VERTICAL_INTERLACED                      5
#define NV_CTRL_STEREO_COLOR_INTERLACED                         6
#define NV_CTRL_STEREO_HORIZONTAL_INTERLACED                    7
#define NV_CTRL_STEREO_CHECKERBOARD_PATTERN                     8
#define NV_CTRL_STEREO_INVERSE_CHECKERBOARD_PATTERN             9
#define NV_CTRL_STEREO_3D_VISION                                10
#define NV_CTRL_STEREO_3D_VISION_PRO                            11

/*
 * NV_CTRL_EMULATE - controls OpenGL software emulation of future
 * NVIDIA GPUs.
 */

#define NV_CTRL_EMULATE                                         17 /* RW- */
#define NV_CTRL_EMULATE_NONE                                    0


/*
 * NV_CTRL_TWINVIEW - returns whether TwinView is enabled for the
 * specified X screen.
 */

#define NV_CTRL_TWINVIEW                                        18 /* R-- */
#define NV_CTRL_TWINVIEW_NOT_ENABLED                            0
#define NV_CTRL_TWINVIEW_ENABLED                                1


/*
 * NV_CTRL_CONNECTED_DISPLAYS - returns a display mask indicating the last
 * cached state of the display devices connected to the GPU or GPU driving
 * the specified X screen.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_CONNECTED_DISPLAYS                              19 /* R--G */


/*
 * NV_CTRL_ENABLED_DISPLAYS - returns a display mask indicating what
 * display devices are enabled for use on the specified X screen or
 * GPU.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_ENABLED_DISPLAYS                                20 /* R--G */

/**************************************************************************/
/*
 * Integer attributes specific to configuring Frame Lock on boards that
 * support it.
 */


/*
 * NV_CTRL_FRAMELOCK - returns whether the underlying GPU supports
 * Frame Lock.  All of the other frame lock attributes are only
 * applicable if NV_CTRL_FRAMELOCK is _SUPPORTED.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_FRAMELOCK                                       21 /* R--G */
#define NV_CTRL_FRAMELOCK_NOT_SUPPORTED                         0
#define NV_CTRL_FRAMELOCK_SUPPORTED                             1


/*
 * NV_CTRL_FRAMELOCK_MASTER - get/set which display device to use
 * as the frame lock master for the entire sync group.  Note that only
 * one node in the sync group should be configured as the master.
 *
 * This attribute can only be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN.
 */

#define NV_CTRL_FRAMELOCK_MASTER                                22 /* RW-G */

/* These are deprecated.  NV_CTRL_FRAMELOCK_MASTER now takes and
   returns a display mask as value. */
#define NV_CTRL_FRAMELOCK_MASTER_FALSE                          0
#define NV_CTRL_FRAMELOCK_MASTER_TRUE                           1


/*
 * NV_CTRL_FRAMELOCK_POLARITY - sync either to the rising edge of the
 * frame lock pulse, the falling edge of the frame lock pulse or both.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_POLARITY                              23 /* RW-F */
#define NV_CTRL_FRAMELOCK_POLARITY_RISING_EDGE                  0x1
#define NV_CTRL_FRAMELOCK_POLARITY_FALLING_EDGE                 0x2
#define NV_CTRL_FRAMELOCK_POLARITY_BOTH_EDGES                   0x3


/*
 * NV_CTRL_FRAMELOCK_SYNC_DELAY - delay between the frame lock pulse
 * and the GPU sync.  This value must be multiplied by 
 * NV_CTRL_FRAMELOCK_SYNC_DELAY_RESOLUTION to determine the sync delay in
 * nanoseconds.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 *
 * USAGE NODE: NV_CTRL_FRAMELOCK_SYNC_DELAY_MAX and
 *             NV_CTRL_FRAMELOCK_SYNC_DELAY_FACTOR are deprecated.
 *             The Sync Delay _MAX and _FACTOR are different for different
 *             GSync products and so, to be correct, the valid values for
 *             NV_CTRL_FRAMELOCK_SYNC_DELAY must be queried to get the range
 *             of acceptable sync delay values, and 
 *             NV_CTRL_FRAMELOCK_SYNC_DELAY_RESOLUTION must be queried to
 *             obtain the correct factor.
 */

#define NV_CTRL_FRAMELOCK_SYNC_DELAY                            24 /* RW-F */
#define NV_CTRL_FRAMELOCK_SYNC_DELAY_MAX                        2047 // deprecated
#define NV_CTRL_FRAMELOCK_SYNC_DELAY_FACTOR                     7.81 // deprecated


/*
 * NV_CTRL_FRAMELOCK_SYNC_INTERVAL - how many house sync pulses
 * between the frame lock sync generation (0 == sync every house sync);
 * this only applies to the master when receiving house sync.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_SYNC_INTERVAL                         25 /* RW-F */


/*
 * NV_CTRL_FRAMELOCK_PORT0_STATUS - status of the rj45 port0.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_PORT0_STATUS                          26 /* R--F */
#define NV_CTRL_FRAMELOCK_PORT0_STATUS_INPUT                    0
#define NV_CTRL_FRAMELOCK_PORT0_STATUS_OUTPUT                   1


/*
 * NV_CTRL_FRAMELOCK_PORT1_STATUS - status of the rj45 port1.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_PORT1_STATUS                          27 /* R--F */
#define NV_CTRL_FRAMELOCK_PORT1_STATUS_INPUT                    0
#define NV_CTRL_FRAMELOCK_PORT1_STATUS_OUTPUT                   1


/*
 * NV_CTRL_FRAMELOCK_HOUSE_STATUS - returns whether or not the house
 * sync signal was detected on the BNC connector of the frame lock
 * board.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_HOUSE_STATUS                          28 /* R--F */
#define NV_CTRL_FRAMELOCK_HOUSE_STATUS_NOT_DETECTED             0
#define NV_CTRL_FRAMELOCK_HOUSE_STATUS_DETECTED                 1


/*
 * NV_CTRL_FRAMELOCK_SYNC - enable/disable the syncing of display
 * devices to the frame lock pulse as specified by previous calls to
 * NV_CTRL_FRAMELOCK_MASTER and NV_CTRL_FRAMELOCK_SLAVES.
 *
 * This attribute can only be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN.
 */

#define NV_CTRL_FRAMELOCK_SYNC                                  29 /* RW-G */
#define NV_CTRL_FRAMELOCK_SYNC_DISABLE                          0
#define NV_CTRL_FRAMELOCK_SYNC_ENABLE                           1


/*
 * NV_CTRL_FRAMELOCK_SYNC_READY - reports whether a frame lock
 * board is receiving sync (regardless of whether or not any display
 * devices are using the sync).
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_SYNC_READY                            30 /* R--F */
#define NV_CTRL_FRAMELOCK_SYNC_READY_FALSE                      0
#define NV_CTRL_FRAMELOCK_SYNC_READY_TRUE                       1


/*
 * NV_CTRL_FRAMELOCK_STEREO_SYNC - this indicates that the GPU stereo
 * signal is in sync with the frame lock stereo signal.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_STEREO_SYNC                           31 /* R--G */
#define NV_CTRL_FRAMELOCK_STEREO_SYNC_FALSE                     0
#define NV_CTRL_FRAMELOCK_STEREO_SYNC_TRUE                      1


/*
 * NV_CTRL_FRAMELOCK_TEST_SIGNAL - to test the connections in the sync
 * group, tell the master to enable a test signal, then query port[01]
 * status and sync_ready on all slaves.  When done, tell the master to
 * disable the test signal.  Test signal should only be manipulated
 * while NV_CTRL_FRAMELOCK_SYNC is enabled.
 *
 * The TEST_SIGNAL is also used to reset the Universal Frame Count (as
 * returned by the glXQueryFrameCountNV() function in the
 * GLX_NV_swap_group extension).  Note: for best accuracy of the
 * Universal Frame Count, it is recommended to toggle the TEST_SIGNAL
 * on and off after enabling frame lock.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_FRAMELOCK_TEST_SIGNAL                           32 /* RW-G */
#define NV_CTRL_FRAMELOCK_TEST_SIGNAL_DISABLE                   0
#define NV_CTRL_FRAMELOCK_TEST_SIGNAL_ENABLE                    1


/*
 * NV_CTRL_FRAMELOCK_ETHERNET_DETECTED - The frame lock boards are
 * cabled together using regular cat5 cable, connecting to rj45 ports
 * on the backplane of the card.  There is some concern that users may
 * think these are ethernet ports and connect them to a
 * router/hub/etc.  The hardware can detect this and will shut off to
 * prevent damage (either to itself or to the router).
 * NV_CTRL_FRAMELOCK_ETHERNET_DETECTED may be called to find out if
 * ethernet is connected to one of the rj45 ports.  An appropriate
 * error message should then be displayed.  The _PORT0 and _PORT1
 * values may be or'ed together.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_ETHERNET_DETECTED                     33 /* R--F */
#define NV_CTRL_FRAMELOCK_ETHERNET_DETECTED_NONE                0
#define NV_CTRL_FRAMELOCK_ETHERNET_DETECTED_PORT0               0x1
#define NV_CTRL_FRAMELOCK_ETHERNET_DETECTED_PORT1               0x2


/*
 * NV_CTRL_FRAMELOCK_VIDEO_MODE - get/set what video mode is used
 * to interperate the house sync signal.  This should only be set
 * on the master.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_VIDEO_MODE                            34 /* RW-F */
#define NV_CTRL_FRAMELOCK_VIDEO_MODE_NONE                       0
#define NV_CTRL_FRAMELOCK_VIDEO_MODE_TTL                        1
#define NV_CTRL_FRAMELOCK_VIDEO_MODE_NTSCPALSECAM               2
#define NV_CTRL_FRAMELOCK_VIDEO_MODE_HDTV                       3

/*
 * During FRAMELOCK bring-up, the above values were redefined to
 * these:
 */

#define NV_CTRL_FRAMELOCK_VIDEO_MODE_COMPOSITE_AUTO             0
#define NV_CTRL_FRAMELOCK_VIDEO_MODE_TTL                        1
#define NV_CTRL_FRAMELOCK_VIDEO_MODE_COMPOSITE_BI_LEVEL         2
#define NV_CTRL_FRAMELOCK_VIDEO_MODE_COMPOSITE_TRI_LEVEL        3


/*
 * NV_CTRL_FRAMELOCK_SYNC_RATE - this is the refresh rate that the
 * frame lock board is sending to the GPU, in milliHz.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_FRAMELOCK_SYNC_RATE                             35 /* R--F */



/**************************************************************************/

/*
 * NV_CTRL_FORCE_GENERIC_CPU - inhibit the use of CPU specific
 * features such as MMX, SSE, or 3DNOW! for OpenGL clients; this
 * option may result in performance loss, but may be useful in
 * conjunction with software such as the Valgrind memory debugger.
 * This setting is only applied to OpenGL clients that are started
 * after this setting is applied.
 *
 * USAGE NOTE: This attribute is deprecated. CPU compatibility is now
 *             checked each time during initialization.
 */

#define NV_CTRL_FORCE_GENERIC_CPU                               37 /* RW-X */
#define NV_CTRL_FORCE_GENERIC_CPU_DISABLE                        0
#define NV_CTRL_FORCE_GENERIC_CPU_ENABLE                         1


/*
 * NV_CTRL_OPENGL_AA_LINE_GAMMA - for OpenGL clients, allow
 * Gamma-corrected antialiased lines to consider variances in the
 * color display capabilities of output devices when rendering smooth
 * lines.  Only available on recent Quadro GPUs.  This setting is only
 * applied to OpenGL clients that are started after this setting is
 * applied.
 */

#define NV_CTRL_OPENGL_AA_LINE_GAMMA                            38 /* RW-X */
#define NV_CTRL_OPENGL_AA_LINE_GAMMA_DISABLE                     0
#define NV_CTRL_OPENGL_AA_LINE_GAMMA_ENABLE                      1


/*
 * NV_CTRL_FRAMELOCK_TIMING - this is TRUE when the gpu is both receiving
 * and locked to an input timing signal. Timing information may come from
 * the following places: Another frame lock device that is set to master, 
 * the house sync signal, or the GPU's internal timing from a display
 * device.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_FRAMELOCK_TIMING                                39 /* R--G */
#define NV_CTRL_FRAMELOCK_TIMING_FALSE                           0
#define NV_CTRL_FRAMELOCK_TIMING_TRUE                            1

/*
 * NV_CTRL_FLIPPING_ALLOWED - when TRUE, OpenGL will swap by flipping
 * when possible; when FALSE, OpenGL will alway swap by blitting.
 */

#define NV_CTRL_FLIPPING_ALLOWED                                40 /* RW-X */
#define NV_CTRL_FLIPPING_ALLOWED_FALSE                           0
#define NV_CTRL_FLIPPING_ALLOWED_TRUE                            1

/*
 * NV_CTRL_ARCHITECTURE - returns the architecture on which the X server is
 * running.
 */

#define NV_CTRL_ARCHITECTURE                                    41  /* R-- */
#define NV_CTRL_ARCHITECTURE_X86                                 0
#define NV_CTRL_ARCHITECTURE_X86_64                              1
#define NV_CTRL_ARCHITECTURE_IA64                                2


/*
 * NV_CTRL_TEXTURE_CLAMPING - texture clamping mode in OpenGL.  By
 * default, _SPEC is used, which forces OpenGL texture clamping to
 * conform with the OpenGL specification.  _EDGE forces NVIDIA's
 * OpenGL implementation to remap GL_CLAMP to GL_CLAMP_TO_EDGE,
 * which is not strictly conformant, but some applications rely on
 * the non-conformant behavior.
 */

#define NV_CTRL_TEXTURE_CLAMPING                                42  /* RW-X */
#define NV_CTRL_TEXTURE_CLAMPING_EDGE                            0
#define NV_CTRL_TEXTURE_CLAMPING_SPEC                            1



#define NV_CTRL_CURSOR_SHADOW                                   43  /* RW- */
#define NV_CTRL_CURSOR_SHADOW_DISABLE                            0
#define NV_CTRL_CURSOR_SHADOW_ENABLE                             1

#define NV_CTRL_CURSOR_SHADOW_ALPHA                             44  /* RW- */
#define NV_CTRL_CURSOR_SHADOW_RED                               45  /* RW- */
#define NV_CTRL_CURSOR_SHADOW_GREEN                             46  /* RW- */
#define NV_CTRL_CURSOR_SHADOW_BLUE                              47  /* RW- */

#define NV_CTRL_CURSOR_SHADOW_X_OFFSET                          48  /* RW- */
#define NV_CTRL_CURSOR_SHADOW_Y_OFFSET                          49  /* RW- */



/*
 * When Application Control for FSAA is enabled, then what the
 * application requests is used, and NV_CTRL_FSAA_MODE is ignored.  If
 * this is disabled, then any application setting is overridden with
 * NV_CTRL_FSAA_MODE
 */

#define NV_CTRL_FSAA_APPLICATION_CONTROLLED                     50  /* RW-X */
#define NV_CTRL_FSAA_APPLICATION_CONTROLLED_ENABLED              1
#define NV_CTRL_FSAA_APPLICATION_CONTROLLED_DISABLED             0


/*
 * When Application Control for LogAniso is enabled, then what the
 * application requests is used, and NV_CTRL_LOG_ANISO is ignored.  If
 * this is disabled, then any application setting is overridden with
 * NV_CTRL_LOG_ANISO
 */

#define NV_CTRL_LOG_ANISO_APPLICATION_CONTROLLED                51  /* RW-X */
#define NV_CTRL_LOG_ANISO_APPLICATION_CONTROLLED_ENABLED         1
#define NV_CTRL_LOG_ANISO_APPLICATION_CONTROLLED_DISABLED        0


/*
 * IMAGE_SHARPENING adjusts the sharpness of the display's image
 * quality by amplifying high frequency content.  Valid values will
 * normally be in the range [0,32).  Only available on GeForceFX or
 * newer.
 */

#define NV_CTRL_IMAGE_SHARPENING                                52  /* RWDG */


/*
 * NV_CTRL_TV_OVERSCAN adjusts the amount of overscan on the specified
 * display device.
 */

#define NV_CTRL_TV_OVERSCAN                                     53  /* RWDG */


/*
 * NV_CTRL_TV_FLICKER_FILTER adjusts the amount of flicker filter on
 * the specified display device.
 */

#define NV_CTRL_TV_FLICKER_FILTER                               54  /* RWDG */


/*
 * NV_CTRL_TV_BRIGHTNESS adjusts the amount of brightness on the
 * specified display device.
 */

#define NV_CTRL_TV_BRIGHTNESS                                   55  /* RWDG */


/*
 * NV_CTRL_TV_HUE adjusts the amount of hue on the specified display
 * device.
 */

#define NV_CTRL_TV_HUE                                          56  /* RWDG */


/*
 * NV_CTRL_TV_CONTRAST adjusts the amount of contrast on the specified
 * display device.
 */

#define NV_CTRL_TV_CONTRAST                                     57  /* RWDG */


/*
 * NV_CTRL_TV_SATURATION adjusts the amount of saturation on the
 * specified display device.
 */

#define NV_CTRL_TV_SATURATION                                   58  /* RWDG */


/*
 * NV_CTRL_TV_RESET_SETTINGS - this write-only attribute can be used
 * to request that all TV Settings be reset to their default values;
 * typical usage would be that this attribute be sent, and then all
 * the TV attributes be queried to retrieve their new values.
 */

#define NV_CTRL_TV_RESET_SETTINGS                               59  /* -WDG */


/*
 * NV_CTRL_GPU_CORE_TEMPERATURE reports the current core temperature
 * of the GPU driving the X screen.
 */

#define NV_CTRL_GPU_CORE_TEMPERATURE                            60  /* R--G */


/*
 * NV_CTRL_GPU_CORE_THRESHOLD reports the current GPU core slowdown
 * threshold temperature, NV_CTRL_GPU_DEFAULT_CORE_THRESHOLD and
 * NV_CTRL_GPU_MAX_CORE_THRESHOLD report the default and MAX core
 * slowdown threshold temperatures.
 *
 * NV_CTRL_GPU_CORE_THRESHOLD reflects the temperature at which the
 * GPU is throttled to prevent overheating.
 */

#define NV_CTRL_GPU_CORE_THRESHOLD                              61  /* R--G */
#define NV_CTRL_GPU_DEFAULT_CORE_THRESHOLD                      62  /* R--G */
#define NV_CTRL_GPU_MAX_CORE_THRESHOLD                          63  /* R--G */


/*
 * NV_CTRL_AMBIENT_TEMPERATURE reports the current temperature in the
 * immediate neighbourhood of the GPU driving the X screen.
 */

#define NV_CTRL_AMBIENT_TEMPERATURE                             64  /* R--G */


/*
 * NV_CTRL_PBUFFER_SCANOUT_SUPPORTED - returns whether this X screen
 * supports scanout of FP pbuffers;
 * 
 * if this screen does not support PBUFFER_SCANOUT, then all other
 * PBUFFER_SCANOUT attributes are unavailable.
 *
 * PBUFFER_SCANOUT is supported if and only if:
 * - Twinview is configured with clone mode.  The secondary screen is used to 
 *   scanout the pbuffer.  
 * - The desktop is running in with 16 bits per pixel.
 */
#define NV_CTRL_PBUFFER_SCANOUT_SUPPORTED                       65  /* R-- */
#define NV_CTRL_PBUFFER_SCANOUT_FALSE                           0
#define NV_CTRL_PBUFFER_SCANOUT_TRUE                            1

/*
 * NV_CTRL_PBUFFER_SCANOUT_XID indicates the XID of the pbuffer used for
 * scanout.
 */
#define NV_CTRL_PBUFFER_SCANOUT_XID                             66  /* RW- */

/**************************************************************************/
/*
 * The NV_CTRL_GVO_* integer attributes are used to configure GVO
 * (Graphics to Video Out).  This functionality is available, for
 * example, on the Quadro FX 4000 SDI graphics board.
 *
 * The following is a typical usage pattern for the GVO attributes:
 *
 * - query NV_CTRL_GVO_SUPPORTED to determine if the X screen supports GV0.
 *
 * - specify NV_CTRL_GVO_SYNC_MODE (one of FREE_RUNNING, GENLOCK, or
 * FRAMELOCK); if you specify GENLOCK or FRAMELOCK, you should also
 * specify NV_CTRL_GVO_SYNC_SOURCE.
 * 
 * - Use NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECTED and
 * NV_CTRL_GVO_SDI_SYNC_INPUT_DETECTED to detect what input syncs are
 * present.
 * 
 * (If no analog sync is detected but it is known that a valid
 * bi-level or tri-level sync is connected set
 * NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECT_MODE appropriately and
 * retest with NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECTED).
 *
 * - if syncing to input sync, query the
 * NV_CTRL_GVIO_DETECTED_VIDEO_FORMAT attribute; note that Input video
 * format can only be queried after SYNC_SOURCE is specified.
 *
 * - specify the NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT
 *
 * - specify the NV_CTRL_GVO_DATA_FORMAT
 *
 * - specify any custom Color Space Conversion (CSC) matrix, offset,
 * and scale with XNVCTRLSetGvoColorConversion().
 *
 * - if using the GLX_NV_video_out extension to display one or more
 * pbuffers, call glXGetVideoDeviceNV() to lock the GVO output for use
 * by the GLX client; then bind the pbuffer(s) to the GVO output with
 * glXBindVideoImageNV() and send pbuffers to the GVO output with
 * glXSendPbufferToVideoNV(); see the GLX_NV_video_out spec for more
 * details.
 *
 * - if using the GLX_NV_present_video extension, call
 * glXBindVideoDeviceNV() to bind the GVO video device to current
 * OpenGL context.
 *
 * Note that setting most GVO attributes only causes the value to be
 * cached in the X server.  The values will be flushed to the hardware
 * either when the next MetaMode is set that uses the GVO display
 * device, or when a GLX pbuffer is bound to the GVO output (with
 * glXBindVideoImageNV()).
 *
 * Note that GLX_NV_video_out/GLX_NV_present_video and X screen use
 * are mutually exclusive.  If a MetaMode is currently using the GVO
 * device, then glXGetVideoDeviceNV and glXBindVideoImageNV() will
 * fail.  Similarly, if a GLX client has locked the GVO output (via
 * glXGetVideoDeviceNV or glXBindVideoImageNV), then setting a
 * MetaMode that uses the GVO device will fail.  The
 * NV_CTRL_GVO_GLX_LOCKED event will be sent when a GLX client locks
 * the GVO output.
 *
 */


/*
 * NV_CTRL_GVO_SUPPORTED - returns whether this X screen supports GVO;
 * if this screen does not support GVO output, then all other GVO
 * attributes are unavailable.
 */

#define NV_CTRL_GVO_SUPPORTED                                   67  /* R-- */
#define NV_CTRL_GVO_SUPPORTED_FALSE                             0
#define NV_CTRL_GVO_SUPPORTED_TRUE                              1


/*
 * NV_CTRL_GVO_SYNC_MODE - selects the GVO sync mode; possible values
 * are:
 *
 * FREE_RUNNING - GVO does not sync to any external signal
 *
 * GENLOCK - the GVO output is genlocked to an incoming sync signal;
 * genlocking locks at hsync.  This requires that the output video
 * format exactly match the incoming sync video format.
 *
 * FRAMELOCK - the GVO output is frame locked to an incoming sync
 * signal; frame locking locks at vsync.  This requires that the output
 * video format have the same refresh rate as the incoming sync video
 * format.
 */

#define NV_CTRL_GVO_SYNC_MODE                                   68  /* RW- */
#define NV_CTRL_GVO_SYNC_MODE_FREE_RUNNING                      0
#define NV_CTRL_GVO_SYNC_MODE_GENLOCK                           1
#define NV_CTRL_GVO_SYNC_MODE_FRAMELOCK                         2


/*
 * NV_CTRL_GVO_SYNC_SOURCE - if NV_CTRL_GVO_SYNC_MODE is set to either
 * GENLOCK or FRAMELOCK, this controls which sync source is used as
 * the incoming sync signal (either Composite or SDI).  If
 * NV_CTRL_GVO_SYNC_MODE is FREE_RUNNING, this attribute has no
 * effect.
 */

#define NV_CTRL_GVO_SYNC_SOURCE                                 69  /* RW- */
#define NV_CTRL_GVO_SYNC_SOURCE_COMPOSITE                       0
#define NV_CTRL_GVO_SYNC_SOURCE_SDI                             1


/*
 * NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT - specifies the desired output video
 * format for GVO devices or the desired input video format for GVI devices.
 *
 * Note that for GVO, the valid video formats may vary depending on
 * the NV_CTRL_GVO_SYNC_MODE and the incoming sync video format.  See
 * the definition of NV_CTRL_GVO_SYNC_MODE.
 *
 * Note that when querying the ValidValues for this data type, the
 * values are reported as bits within a bitmask
 * (ATTRIBUTE_TYPE_INT_BITS); unfortunately, there are more valid
 * value bits than will fit in a single 32-bit value.  To solve this,
 * query the ValidValues for NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT to
 * check which of the first 31 VIDEO_FORMATS are valid, query the
 * ValidValues for NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT2 to check which
 * of the 32-63 VIDEO_FORMATS are valid, and query the ValidValues of
 * NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT3 to check which of the 64-95
 * VIDEO_FORMATS are valid.
 *
 * Note: Setting this attribute on a GVI device may also result in the
 *       following NV-CONTROL attributes being reset on that device (to
 *       ensure the configuration remains valid):
 *           NV_CTRL_GVI_REQUESTED_STREAM_BITS_PER_COMPONENT
 *           NV_CTRL_GVI_REQUESTED_STREAM_COMPONENT_SAMPLING
 */

#define NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT                     70  /* RW--I */

#define NV_CTRL_GVIO_VIDEO_FORMAT_NONE                          0
#define NV_CTRL_GVIO_VIDEO_FORMAT_487I_59_94_SMPTE259_NTSC      1
#define NV_CTRL_GVIO_VIDEO_FORMAT_576I_50_00_SMPTE259_PAL       2
#define NV_CTRL_GVIO_VIDEO_FORMAT_720P_59_94_SMPTE296           3
#define NV_CTRL_GVIO_VIDEO_FORMAT_720P_60_00_SMPTE296           4
#define NV_CTRL_GVIO_VIDEO_FORMAT_1035I_59_94_SMPTE260          5
#define NV_CTRL_GVIO_VIDEO_FORMAT_1035I_60_00_SMPTE260          6
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_50_00_SMPTE295          7
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_50_00_SMPTE274          8
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_59_94_SMPTE274          9
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_60_00_SMPTE274          10
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_23_976_SMPTE274         11
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_24_00_SMPTE274          12
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_25_00_SMPTE274          13
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_29_97_SMPTE274          14
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_30_00_SMPTE274          15
#define NV_CTRL_GVIO_VIDEO_FORMAT_720P_50_00_SMPTE296           16
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_48_00_SMPTE274          17
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_47_96_SMPTE274          18
#define NV_CTRL_GVIO_VIDEO_FORMAT_720P_30_00_SMPTE296           19 
#define NV_CTRL_GVIO_VIDEO_FORMAT_720P_29_97_SMPTE296           20  
#define NV_CTRL_GVIO_VIDEO_FORMAT_720P_25_00_SMPTE296           21 
#define NV_CTRL_GVIO_VIDEO_FORMAT_720P_24_00_SMPTE296           22 
#define NV_CTRL_GVIO_VIDEO_FORMAT_720P_23_98_SMPTE296           23  
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080PSF_25_00_SMPTE274        24
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080PSF_29_97_SMPTE274        25
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080PSF_30_00_SMPTE274        26
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080PSF_24_00_SMPTE274        27
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080PSF_23_98_SMPTE274        28
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_30_00_SMPTE372          29
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_29_97_SMPTE372          30
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_60_00_SMPTE372          31
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_59_94_SMPTE372          32
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_25_00_SMPTE372          33
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_50_00_SMPTE372          34
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_24_00_SMPTE372          35
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_23_98_SMPTE372          36
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_48_00_SMPTE372          37
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_47_96_SMPTE372          38
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_50_00_3G_LEVEL_A_SMPTE274  39
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_59_94_3G_LEVEL_A_SMPTE274  40
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_60_00_3G_LEVEL_A_SMPTE274  41
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_60_00_3G_LEVEL_B_SMPTE274  42
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_60_00_3G_LEVEL_B_SMPTE274  43
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_60_00_3G_LEVEL_B_SMPTE372  44
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_50_00_3G_LEVEL_B_SMPTE274  45
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_50_00_3G_LEVEL_B_SMPTE274  46
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_50_00_3G_LEVEL_B_SMPTE372  47
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_30_00_3G_LEVEL_B_SMPTE274  48
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_30_00_3G_LEVEL_B_SMPTE372  49
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_25_00_3G_LEVEL_B_SMPTE274  50
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_25_00_3G_LEVEL_B_SMPTE372  51
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_24_00_3G_LEVEL_B_SMPTE274  52
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_24_00_3G_LEVEL_B_SMPTE372  53
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_48_00_3G_LEVEL_B_SMPTE274  54
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_48_00_3G_LEVEL_B_SMPTE372  55
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_59_94_3G_LEVEL_B_SMPTE274  56
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_59_94_3G_LEVEL_B_SMPTE274  57
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_59_94_3G_LEVEL_B_SMPTE372  58
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_29_97_3G_LEVEL_B_SMPTE274  59
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_29_97_3G_LEVEL_B_SMPTE372  60
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080P_23_98_3G_LEVEL_B_SMPTE274  61
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048P_23_98_3G_LEVEL_B_SMPTE372  62
#define NV_CTRL_GVIO_VIDEO_FORMAT_1080I_47_96_3G_LEVEL_B_SMPTE274  63
#define NV_CTRL_GVIO_VIDEO_FORMAT_2048I_47_96_3G_LEVEL_B_SMPTE372  64


/* 
 * The following are deprecated; NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT and the
 * corresponding NV_CTRL_GVIO_* formats should be used instead.
 */
#define NV_CTRL_GVO_OUTPUT_VIDEO_FORMAT                         70  /* RW- */

#define NV_CTRL_GVO_VIDEO_FORMAT_NONE                           0
#define NV_CTRL_GVO_VIDEO_FORMAT_487I_59_94_SMPTE259_NTSC       1
#define NV_CTRL_GVO_VIDEO_FORMAT_576I_50_00_SMPTE259_PAL        2
#define NV_CTRL_GVO_VIDEO_FORMAT_720P_59_94_SMPTE296            3
#define NV_CTRL_GVO_VIDEO_FORMAT_720P_60_00_SMPTE296            4
#define NV_CTRL_GVO_VIDEO_FORMAT_1035I_59_94_SMPTE260           5
#define NV_CTRL_GVO_VIDEO_FORMAT_1035I_60_00_SMPTE260           6
#define NV_CTRL_GVO_VIDEO_FORMAT_1080I_50_00_SMPTE295           7
#define NV_CTRL_GVO_VIDEO_FORMAT_1080I_50_00_SMPTE274           8
#define NV_CTRL_GVO_VIDEO_FORMAT_1080I_59_94_SMPTE274           9
#define NV_CTRL_GVO_VIDEO_FORMAT_1080I_60_00_SMPTE274           10
#define NV_CTRL_GVO_VIDEO_FORMAT_1080P_23_976_SMPTE274          11
#define NV_CTRL_GVO_VIDEO_FORMAT_1080P_24_00_SMPTE274           12
#define NV_CTRL_GVO_VIDEO_FORMAT_1080P_25_00_SMPTE274           13
#define NV_CTRL_GVO_VIDEO_FORMAT_1080P_29_97_SMPTE274           14
#define NV_CTRL_GVO_VIDEO_FORMAT_1080P_30_00_SMPTE274           15
#define NV_CTRL_GVO_VIDEO_FORMAT_720P_50_00_SMPTE296            16
#define NV_CTRL_GVO_VIDEO_FORMAT_1080I_48_00_SMPTE274           17
#define NV_CTRL_GVO_VIDEO_FORMAT_1080I_47_96_SMPTE274           18
#define NV_CTRL_GVO_VIDEO_FORMAT_720P_30_00_SMPTE296            19 
#define NV_CTRL_GVO_VIDEO_FORMAT_720P_29_97_SMPTE296            20  
#define NV_CTRL_GVO_VIDEO_FORMAT_720P_25_00_SMPTE296            21 
#define NV_CTRL_GVO_VIDEO_FORMAT_720P_24_00_SMPTE296            22 
#define NV_CTRL_GVO_VIDEO_FORMAT_720P_23_98_SMPTE296            23  
#define NV_CTRL_GVO_VIDEO_FORMAT_1080PSF_25_00_SMPTE274         24
#define NV_CTRL_GVO_VIDEO_FORMAT_1080PSF_29_97_SMPTE274         25
#define NV_CTRL_GVO_VIDEO_FORMAT_1080PSF_30_00_SMPTE274         26
#define NV_CTRL_GVO_VIDEO_FORMAT_1080PSF_24_00_SMPTE274         27
#define NV_CTRL_GVO_VIDEO_FORMAT_1080PSF_23_98_SMPTE274         28
#define NV_CTRL_GVO_VIDEO_FORMAT_2048P_30_00_SMPTE372           29
#define NV_CTRL_GVO_VIDEO_FORMAT_2048P_29_97_SMPTE372           30
#define NV_CTRL_GVO_VIDEO_FORMAT_2048I_60_00_SMPTE372           31
#define NV_CTRL_GVO_VIDEO_FORMAT_2048I_59_94_SMPTE372           32
#define NV_CTRL_GVO_VIDEO_FORMAT_2048P_25_00_SMPTE372           33
#define NV_CTRL_GVO_VIDEO_FORMAT_2048I_50_00_SMPTE372           34
#define NV_CTRL_GVO_VIDEO_FORMAT_2048P_24_00_SMPTE372           35
#define NV_CTRL_GVO_VIDEO_FORMAT_2048P_23_98_SMPTE372           36
#define NV_CTRL_GVO_VIDEO_FORMAT_2048I_48_00_SMPTE372           37
#define NV_CTRL_GVO_VIDEO_FORMAT_2048I_47_96_SMPTE372           38

/*
 * NV_CTRL_GVIO_DETECTED_VIDEO_FORMAT - indicates the input video format
 * detected for GVO or GVI devices; the possible values are the
 * NV_CTRL_GVIO_VIDEO_FORMAT constants.
 *
 * For GVI devices, the jack number should be specified in the lower
 * 16 bits of the "display_mask" parameter, while the channel number should be
 * specified in the upper 16 bits.
 */

#define NV_CTRL_GVIO_DETECTED_VIDEO_FORMAT                      71  /* R--I */

/*
 * The following is deprecated.  Use NV_CTRL_GVIO_DETECTED_VIDEO_FORMAT,
 * instead.
 */
#define NV_CTRL_GVO_INPUT_VIDEO_FORMAT                          71  /* R-- */

/*
 * NV_CTRL_GVO_DATA_FORMAT - This controls how the data in the source
 * (either the X screen or the GLX pbuffer) is interpretted and
 * displayed.
 *
 * Note: some of the below DATA_FORMATS have been renamed.  For
 * example, R8G8B8_TO_RGB444 has been renamed to X8X8X8_444_PASSTHRU.
 * This is to more accurately reflect DATA_FORMATS where the
 * per-channel data could be either RGB or YCrCb -- the point is that
 * the driver and GVO hardware do not perform any implicit color space
 * conversion on the data; it is passed through to the SDI out.
 */

#define NV_CTRL_GVO_DATA_FORMAT                                 72  /* RW- */
#define NV_CTRL_GVO_DATA_FORMAT_R8G8B8_TO_YCRCB444              0
#define NV_CTRL_GVO_DATA_FORMAT_R8G8B8A8_TO_YCRCBA4444          1
#define NV_CTRL_GVO_DATA_FORMAT_R8G8B8Z10_TO_YCRCBZ4444         2
#define NV_CTRL_GVO_DATA_FORMAT_R8G8B8_TO_YCRCB422              3
#define NV_CTRL_GVO_DATA_FORMAT_R8G8B8A8_TO_YCRCBA4224          4
#define NV_CTRL_GVO_DATA_FORMAT_R8G8B8Z10_TO_YCRCBZ4224         5
#define NV_CTRL_GVO_DATA_FORMAT_R8G8B8_TO_RGB444                6 // renamed
#define NV_CTRL_GVO_DATA_FORMAT_X8X8X8_444_PASSTHRU             6
#define NV_CTRL_GVO_DATA_FORMAT_R8G8B8A8_TO_RGBA4444            7 // renamed
#define NV_CTRL_GVO_DATA_FORMAT_X8X8X8A8_4444_PASSTHRU          7
#define NV_CTRL_GVO_DATA_FORMAT_R8G8B8Z10_TO_RGBZ4444           8 // renamed
#define NV_CTRL_GVO_DATA_FORMAT_X8X8X8Z8_4444_PASSTHRU          8
#define NV_CTRL_GVO_DATA_FORMAT_Y10CR10CB10_TO_YCRCB444         9 // renamed
#define NV_CTRL_GVO_DATA_FORMAT_X10X10X10_444_PASSTHRU          9
#define NV_CTRL_GVO_DATA_FORMAT_Y10CR8CB8_TO_YCRCB444           10 // renamed
#define NV_CTRL_GVO_DATA_FORMAT_X10X8X8_444_PASSTHRU            10
#define NV_CTRL_GVO_DATA_FORMAT_Y10CR8CB8A10_TO_YCRCBA4444      11 // renamed
#define NV_CTRL_GVO_DATA_FORMAT_X10X8X8A10_4444_PASSTHRU        11
#define NV_CTRL_GVO_DATA_FORMAT_Y10CR8CB8Z10_TO_YCRCBZ4444      12 // renamed
#define NV_CTRL_GVO_DATA_FORMAT_X10X8X8Z10_4444_PASSTHRU        12
#define NV_CTRL_GVO_DATA_FORMAT_DUAL_R8G8B8_TO_DUAL_YCRCB422    13
#define NV_CTRL_GVO_DATA_FORMAT_DUAL_Y8CR8CB8_TO_DUAL_YCRCB422  14 // renamed
#define NV_CTRL_GVO_DATA_FORMAT_DUAL_X8X8X8_TO_DUAL_422_PASSTHRU 14
#define NV_CTRL_GVO_DATA_FORMAT_R10G10B10_TO_YCRCB422           15
#define NV_CTRL_GVO_DATA_FORMAT_R10G10B10_TO_YCRCB444           16
#define NV_CTRL_GVO_DATA_FORMAT_Y12CR12CB12_TO_YCRCB444         17 // renamed
#define NV_CTRL_GVO_DATA_FORMAT_X12X12X12_444_PASSTHRU          17
#define NV_CTRL_GVO_DATA_FORMAT_R12G12B12_TO_YCRCB444           18
#define NV_CTRL_GVO_DATA_FORMAT_X8X8X8_422_PASSTHRU             19
#define NV_CTRL_GVO_DATA_FORMAT_X8X8X8A8_4224_PASSTHRU          20
#define NV_CTRL_GVO_DATA_FORMAT_X8X8X8Z8_4224_PASSTHRU          21
#define NV_CTRL_GVO_DATA_FORMAT_X10X10X10_422_PASSTHRU          22
#define NV_CTRL_GVO_DATA_FORMAT_X10X8X8_422_PASSTHRU            23
#define NV_CTRL_GVO_DATA_FORMAT_X10X8X8A10_4224_PASSTHRU        24
#define NV_CTRL_GVO_DATA_FORMAT_X10X8X8Z10_4224_PASSTHRU        25
#define NV_CTRL_GVO_DATA_FORMAT_X12X12X12_422_PASSTHRU          26
#define NV_CTRL_GVO_DATA_FORMAT_R12G12B12_TO_YCRCB422           27

/*
 * NV_CTRL_GVO_DISPLAY_X_SCREEN - no longer supported
 */

#define NV_CTRL_GVO_DISPLAY_X_SCREEN                            73  /* RW- */
#define NV_CTRL_GVO_DISPLAY_X_SCREEN_ENABLE                     1
#define NV_CTRL_GVO_DISPLAY_X_SCREEN_DISABLE                    0


/*
 * NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECTED - indicates whether
 * Composite Sync input is detected.
 */

#define NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECTED               74  /* R-- */
#define NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECTED_FALSE         0
#define NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECTED_TRUE          1


/*
 * NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECT_MODE - get/set the
 * Composite Sync input detect mode.
 */

#define NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECT_MODE            75  /* RW- */
#define NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECT_MODE_AUTO       0
#define NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECT_MODE_BI_LEVEL   1
#define NV_CTRL_GVO_COMPOSITE_SYNC_INPUT_DETECT_MODE_TRI_LEVEL  2


/*
 * NV_CTRL_GVO_SYNC_INPUT_DETECTED - indicates whether SDI Sync input
 * is detected, and what type.
 */

#define NV_CTRL_GVO_SDI_SYNC_INPUT_DETECTED                     76  /* R-- */
#define NV_CTRL_GVO_SDI_SYNC_INPUT_DETECTED_NONE                0
#define NV_CTRL_GVO_SDI_SYNC_INPUT_DETECTED_HD                  1
#define NV_CTRL_GVO_SDI_SYNC_INPUT_DETECTED_SD                  2


/*
 * NV_CTRL_GVO_VIDEO_OUTPUTS - indicates which GVO video output
 * connectors are currently outputing data.
 */

#define NV_CTRL_GVO_VIDEO_OUTPUTS                               77  /* R-- */
#define NV_CTRL_GVO_VIDEO_OUTPUTS_NONE                          0
#define NV_CTRL_GVO_VIDEO_OUTPUTS_VIDEO1                        1
#define NV_CTRL_GVO_VIDEO_OUTPUTS_VIDEO2                        2
#define NV_CTRL_GVO_VIDEO_OUTPUTS_VIDEO_BOTH                    3


/*
 * NV_CTRL_GVO_FPGA_VERSION - indicates the version of the Firmware on
 * the GVO device.  Deprecated; use
 * NV_CTRL_STRING_GVIO_FIRMWARE_VERSION instead.
 */

#define NV_CTRL_GVO_FIRMWARE_VERSION                            78  /* R-- */


/*
 * NV_CTRL_GVO_SYNC_DELAY_PIXELS - controls the delay between the
 * input sync and the output sync in numbers of pixels from hsync;
 * this is a 12 bit value.
 *
 * If the NV_CTRL_GVO_CAPABILITIES_ADVANCE_SYNC_SKEW bit is set,
 * then setting this value will set an advance instead of a delay.
 */

#define NV_CTRL_GVO_SYNC_DELAY_PIXELS                           79  /* RW- */


/*
 * NV_CTRL_GVO_SYNC_DELAY_LINES - controls the delay between the input
 * sync and the output sync in numbers of lines from vsync; this is a
 * 12 bit value.
 *
 * If the NV_CTRL_GVO_CAPABILITIES_ADVANCE_SYNC_SKEW bit is set,
 * then setting this value will set an advance instead of a delay.
 */

#define NV_CTRL_GVO_SYNC_DELAY_LINES                            80  /* RW- */


/*
 * NV_CTRL_GVO_INPUT_VIDEO_FORMAT_REACQUIRE - must be set for a period
 * of about 2 seconds for the new InputVideoFormat to be properly
 * locked to.  In nvidia-settings, we do a reacquire whenever genlock
 * or frame lock mode is entered into, when the user clicks the
 * "detect" button.  This value can be written, but always reads back
 * _FALSE.
 */

#define NV_CTRL_GVO_INPUT_VIDEO_FORMAT_REACQUIRE                81  /* -W- */
#define NV_CTRL_GVO_INPUT_VIDEO_FORMAT_REACQUIRE_FALSE          0
#define NV_CTRL_GVO_INPUT_VIDEO_FORMAT_REACQUIRE_TRUE           1


/*
 * NV_CTRL_GVO_GLX_LOCKED - indicates that GVO configurability is
 * locked by GLX; this occurs when either glXGetVideoDeviceNV (part of
 * GLX_NV_video_out) or glXBindVideoDeviceNV (part of
 * GLX_NV_present_video) is called.  All GVO output resources are
 * locked until released by the GLX_NV_video_out/GLX_NV_present_video
 * client.
 *
 * When GVO is locked, setting of the following GVO NV-CONTROL attributes will
 * not happen immediately and will instead be cached.  The GVO resource will
 * need to be disabled/released and re-enabled/claimed for the values to be
 * flushed. These attributes are:
 *    NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT
 *    NV_CTRL_GVO_DATA_FORMAT
 *    NV_CTRL_GVO_FLIP_QUEUE_SIZE
 *
 * This attribute is deprecated and may be removed in a future release.  Its
 * functionality has been replaced by NV_CTRL_GVO_LOCK_OWNER.
 */

#define NV_CTRL_GVO_GLX_LOCKED                                  82  /* R-- */
#define NV_CTRL_GVO_GLX_LOCKED_FALSE                            0
#define NV_CTRL_GVO_GLX_LOCKED_TRUE                             1


/*
 * NV_CTRL_GVIO_VIDEO_FORMAT_{WIDTH,HEIGHT,REFRESH_RATE} - query the
 * width, height, and refresh rate for the specified
 * NV_CTRL_GVIO_VIDEO_FORMAT_*.  So that this can be queried with
 * existing interfaces, XNVCTRLQueryAttribute() should be used, and
 * the video format specified in the display_mask field; eg:
 *
 * XNVCTRLQueryAttribute (dpy,
 *                        screen, 
 *                        NV_CTRL_GVIO_VIDEO_FORMAT_487I_59_94_SMPTE259_NTSC,
 *                        NV_CTRL_GVIO_VIDEO_FORMAT_WIDTH,
 *                        &value);
 *
 * Note that Refresh Rate is in milliHertz values
 */

#define NV_CTRL_GVIO_VIDEO_FORMAT_WIDTH                         83  /* R--I */
#define NV_CTRL_GVIO_VIDEO_FORMAT_HEIGHT                        84  /* R--I */
#define NV_CTRL_GVIO_VIDEO_FORMAT_REFRESH_RATE                  85  /* R--I */

/* The following are deprecated; use the NV_CTRL_GVIO_* versions, instead */
#define NV_CTRL_GVO_VIDEO_FORMAT_WIDTH                          83  /* R-- */
#define NV_CTRL_GVO_VIDEO_FORMAT_HEIGHT                         84  /* R-- */
#define NV_CTRL_GVO_VIDEO_FORMAT_REFRESH_RATE                   85  /* R-- */


/*
 * NV_CTRL_GVO_X_SCREEN_PAN_[XY] - no longer supported
 */

#define NV_CTRL_GVO_X_SCREEN_PAN_X                              86  /* RW- */
#define NV_CTRL_GVO_X_SCREEN_PAN_Y                              87  /* RW- */


/*
 * NV_CTRL_GPU_OVERCLOCKING_STATE - query the current or set a new
 * overclocking state; the value of this attribute controls the
 * availability of additional overclocking attributes (see below).
 *
 * Note: this attribute is unavailable unless overclocking support
 * has been enabled in the X server (by the user).
 */

#define NV_CTRL_GPU_OVERCLOCKING_STATE                          88  /* RW-G */
#define NV_CTRL_GPU_OVERCLOCKING_STATE_NONE                     0
#define NV_CTRL_GPU_OVERCLOCKING_STATE_MANUAL                   1


/*
 * NV_CTRL_GPU_{2,3}D_CLOCK_FREQS - query or set the GPU and memory
 * clocks of the device driving the X screen.  New clock frequencies
 * are tested before being applied, and may be rejected.
 *
 * Note: if the target clocks are too aggressive, their testing may
 * render the system unresponsive.
 *
 * Note: while this attribute can always be queried, it can't be set
 * unless NV_CTRL_GPU_OVERCLOCKING_STATE is set to _MANUAL.  Since
 * the target clocks may be rejected, the requester should read this
 * attribute after the set to determine success or failure.
 *
 * NV_CTRL_GPU_{2,3}D_CLOCK_FREQS are "packed" integer attributes; the
 * GPU clock is stored in the upper 16 bits of the integer, and the
 * memory clock is stored in the lower 16 bits of the integer.  All
 * clock values are in MHz.
 */

#define NV_CTRL_GPU_2D_CLOCK_FREQS                              89  /* RW-G */
#define NV_CTRL_GPU_3D_CLOCK_FREQS                              90  /* RW-G */


/*
 * NV_CTRL_GPU_DEFAULT_{2,3}D_CLOCK_FREQS - query the default memory
 * and GPU core clocks of the device driving the X screen.
 *
 * NV_CTRL_GPU_DEFAULT_{2,3}D_CLOCK_FREQS are "packed" integer
 * attributes; the GPU clock is stored in the upper 16 bits of the
 * integer, and the memory clock is stored in the lower 16 bits of the
 * integer.  All clock values are in MHz.
 */

#define NV_CTRL_GPU_DEFAULT_2D_CLOCK_FREQS                      91  /* R--G */
#define NV_CTRL_GPU_DEFAULT_3D_CLOCK_FREQS                      92  /* R--G */


/*
 * NV_CTRL_GPU_CURRENT_CLOCK_FREQS - query the current GPU and memory
 * clocks of the graphics device driving the X screen.
 *
 * NV_CTRL_GPU_CURRENT_CLOCK_FREQS is a "packed" integer attribute;
 * the GPU clock is stored in the upper 16 bits of the integer, and
 * the memory clock is stored in the lower 16 bits of the integer.
 * All clock values are in MHz.  All clock values are in MHz.
 */

#define NV_CTRL_GPU_CURRENT_CLOCK_FREQS                         93  /* R--G */


/*
 * NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS - Holds the last calculated
 * optimal 3D clock frequencies found by the
 * NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION process.  Querying this
 * attribute before having probed for the optimal clocks will return
 * NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_INVALID
 *
 * Note: unless NV_CTRL_GPU_OVERCLOCKING_STATE is set to _MANUAL, the
 * optimal clock detection process is unavailable.
 */

#define NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS                         94  /* R--G */
#define NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_INVALID                  0


/*
 * NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION - set to _START to
 * initiate testing for the optimal 3D clock frequencies.  Once
 * found, the optimal clock frequencies will be returned by the
 * NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS attribute asynchronously
 * (using an X event, see XNVCtrlSelectNotify).
 *
 * To cancel an ongoing test for the optimal clocks, set the
 * NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION attribute to _CANCEL
 *
 * Note: unless NV_CTRL_GPU_OVERCLOCKING_STATE is set to _MANUAL, the
 * optimal clock detection process is unavailable.
 */

#define NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION               95  /* -W-G */
#define NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION_START          0
#define NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION_CANCEL         1


/*
 * NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION_STATE - query this
 * variable to know if a test is currently being run to
 * determine the optimal 3D clock frequencies.  _BUSY means a
 * test is currently running, _IDLE means the test is not running.
 *
 * Note: unless NV_CTRL_GPU_OVERCLOCKING_STATE is set to _MANUAL, the
 * optimal clock detection process is unavailable.
 */

#define NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION_STATE         96  /* R--G */
#define NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION_STATE_IDLE     0
#define NV_CTRL_GPU_OPTIMAL_CLOCK_FREQS_DETECTION_STATE_BUSY     1


/*
 * NV_CTRL_FLATPANEL_CHIP_LOCATION - for the specified display device,
 * report whether the flat panel is driven by the on-chip controller,
 * or a separate controller chip elsewhere on the graphics board.
 * This attribute is only available for flat panels.
 */

#define NV_CTRL_FLATPANEL_CHIP_LOCATION                         215/* R-DG */
#define NV_CTRL_FLATPANEL_CHIP_LOCATION_INTERNAL                  0
#define NV_CTRL_FLATPANEL_CHIP_LOCATION_EXTERNAL                  1

/*
 * NV_CTRL_FLATPANEL_LINK - report the number of links for a DVI connection, or
 * the main link's active lane count for DisplayPort.
 * This attribute is only available for flat panels.
 */

#define NV_CTRL_FLATPANEL_LINK                                  216/* R-DG */
#define NV_CTRL_FLATPANEL_LINK_SINGLE                             0
#define NV_CTRL_FLATPANEL_LINK_DUAL                               1
#define NV_CTRL_FLATPANEL_LINK_QUAD                               3

/*
 * NV_CTRL_FLATPANEL_SIGNAL - for the specified display device, report
 * whether the flat panel is driven by an LVDS, TMDS, or DisplayPort signal.
 * This attribute is only available for flat panels.
 */

#define NV_CTRL_FLATPANEL_SIGNAL                                217/* R-DG */
#define NV_CTRL_FLATPANEL_SIGNAL_LVDS                             0
#define NV_CTRL_FLATPANEL_SIGNAL_TMDS                             1
#define NV_CTRL_FLATPANEL_SIGNAL_DISPLAYPORT                      2


/*
 * NV_CTRL_USE_HOUSE_SYNC - when TRUE, the server (master) frame lock
 * device will propagate the incoming house sync signal as the outgoing
 * frame lock sync signal.  If the frame lock device cannot detect a
 * frame lock sync signal, it will default to using the internal timings
 * from the GPU connected to the primary connector.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_USE_HOUSE_SYNC                                  218/* RW-F */
#define NV_CTRL_USE_HOUSE_SYNC_FALSE                            0
#define NV_CTRL_USE_HOUSE_SYNC_TRUE                             1

/*
 * NV_CTRL_EDID_AVAILABLE - report if an EDID is available for the
 * specified display device.
 *
 * This attribute may also be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN
 * target.
 */

#define NV_CTRL_EDID_AVAILABLE                                  219 /* R-DG */
#define NV_CTRL_EDID_AVAILABLE_FALSE                            0
#define NV_CTRL_EDID_AVAILABLE_TRUE                             1

/*
 * NV_CTRL_FORCE_STEREO - when TRUE, OpenGL will force stereo flipping
 * even when no stereo drawables are visible (if the device is configured
 * to support it, see the "Stereo" X config option).
 * When false, fall back to the default behavior of only flipping when a
 * stereo drawable is visible.
 */

#define NV_CTRL_FORCE_STEREO                                    220 /* RW- */
#define NV_CTRL_FORCE_STEREO_FALSE                              0
#define NV_CTRL_FORCE_STEREO_TRUE                               1


/*
 * NV_CTRL_IMAGE_SETTINGS - the image quality setting for OpenGL clients.
 *
 * This setting is only applied to OpenGL clients that are started
 * after this setting is applied.
 */

#define NV_CTRL_IMAGE_SETTINGS                                  221 /* RW-X */
#define NV_CTRL_IMAGE_SETTINGS_HIGH_QUALITY                     0
#define NV_CTRL_IMAGE_SETTINGS_QUALITY                          1
#define NV_CTRL_IMAGE_SETTINGS_PERFORMANCE                      2
#define NV_CTRL_IMAGE_SETTINGS_HIGH_PERFORMANCE                 3


/*
 * NV_CTRL_XINERAMA - return whether xinerama is enabled
 */

#define NV_CTRL_XINERAMA                                        222 /* R--G */
#define NV_CTRL_XINERAMA_OFF                                    0
#define NV_CTRL_XINERAMA_ON                                     1

/*
 * NV_CTRL_XINERAMA_STEREO - when TRUE, OpenGL will allow stereo flipping
 * on multiple X screens configured with Xinerama.
 * When FALSE, flipping is allowed only on one X screen at a time.
 */

#define NV_CTRL_XINERAMA_STEREO                                  223 /* RW- */
#define NV_CTRL_XINERAMA_STEREO_FALSE                            0
#define NV_CTRL_XINERAMA_STEREO_TRUE                             1

/*
 * NV_CTRL_BUS_RATE - if the bus type of the specified device is AGP, then
 * NV_CTRL_BUS_RATE returns the configured AGP transfer rate.  If the bus type
 * is PCI Express, then this attribute returns the maximum link width.
 * When this attribute is queried on an X screen target, the bus rate of the
 * GPU driving the X screen is returned.
 */

#define NV_CTRL_BUS_RATE                                        224  /* R--GI */

/*
 * NV_CTRL_GPU_PCIE_MAX_LINK_WIDTH - returns the maximum
 * PCIe link width, in number of lanes.
 */
#define NV_CTRL_GPU_PCIE_MAX_LINK_WIDTH  NV_CTRL_BUS_RATE

/*
 * NV_CTRL_SHOW_SLI_HUD - when TRUE, OpenGL will draw information about the
 * current SLI mode.
 * Renamed this attribute to NV_CTRL_SHOW_SLI_VISUAL_INDICATOR
 */

#define NV_CTRL_SHOW_SLI_HUD         NV_CTRL_SHOW_SLI_VISUAL_INDICATOR
#define NV_CTRL_SHOW_SLI_HUD_FALSE   NV_CTRL_SHOW_SLI_VISUAL_INDICATOR_FALSE
#define NV_CTRL_SHOW_SLI_HUD_TRUE    NV_CTRL_SHOW_SLI_VISUAL_INDICATOR_TRUE

/*
 * NV_CTRL_SHOW_SLI_VISUAL_INDICATOR - when TRUE, OpenGL will draw information
 * about the current SLI mode.
 */

#define NV_CTRL_SHOW_SLI_VISUAL_INDICATOR                       225  /* RW-X */
#define NV_CTRL_SHOW_SLI_VISUAL_INDICATOR_FALSE                   0
#define NV_CTRL_SHOW_SLI_VISUAL_INDICATOR_TRUE                    1

/*
 * NV_CTRL_XV_SYNC_TO_DISPLAY - this control is valid when TwinView and 
 * XVideo Sync To VBlank are enabled.
 * It controls which display device will be synched to.
 */

#define NV_CTRL_XV_SYNC_TO_DISPLAY                               226  /* RW- */

/*
 * NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT2 - this attribute is only
 * intended to be used to query the ValidValues for
 * NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT for VIDEO_FORMAT values between
 * 31 and 63.  See NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT for details.
 */

#define NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT2                    227  /* ---GI */

/* 
 * The following is deprecated; use NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT2,
 * instead
 */
#define NV_CTRL_GVO_OUTPUT_VIDEO_FORMAT2                         227  /* --- */


/*
 * NV_CTRL_GVO_OVERRIDE_HW_CSC - Override the SDI hardware's Color Space
 * Conversion with the values controlled through
 * XNVCTRLSetGvoColorConversion() and XNVCTRLGetGvoColorConversion().  If
 * this attribute is FALSE, then the values specified through
 * XNVCTRLSetGvoColorConversion() are ignored.
 */

#define NV_CTRL_GVO_OVERRIDE_HW_CSC                              228  /* RW- */
#define NV_CTRL_GVO_OVERRIDE_HW_CSC_FALSE                        0
#define NV_CTRL_GVO_OVERRIDE_HW_CSC_TRUE                         1


/*
 * NV_CTRL_GVO_CAPABILITIES - this read-only attribute describes GVO
 * capabilities that differ between NVIDIA SDI products.  This value
 * is a bitmask where each bit indicates whether that capability is
 * available.
 *
 * APPLY_CSC_IMMEDIATELY - whether the CSC matrix, offset, and scale
 * specified through XNVCTRLSetGvoColorConversion() will take affect
 * immediately, or only after SDI output is disabled and enabled
 * again.
 *
 * APPLY_CSC_TO_X_SCREEN - whether the CSC matrix, offset, and scale
 * specified through XNVCTRLSetGvoColorConversion() will also apply
 * to GVO output of an X screen, or only to OpenGL GVO output, as
 * enabled through the GLX_NV_video_out extension.
 *
 * COMPOSITE_TERMINATION - whether the 75 ohm termination of the
 * SDI composite input signal can be programmed through the
 * NV_CTRL_GVO_COMPOSITE_TERMINATION attribute.
 *
 * SHARED_SYNC_BNC - whether the SDI device has a single BNC
 * connector used for both (SDI & Composite) incoming signals.
 *
 * MULTIRATE_SYNC - whether the SDI device supports synchronization
 * of input and output video modes that match in being odd or even
 * modes (ie, AA.00 Hz modes can be synched to other BB.00 Hz modes and
 * AA.XX Hz can match to BB.YY Hz where .XX and .YY are not .00)
 */

#define NV_CTRL_GVO_CAPABILITIES                                 229  /* R-- */
#define NV_CTRL_GVO_CAPABILITIES_APPLY_CSC_IMMEDIATELY           0x00000001
#define NV_CTRL_GVO_CAPABILITIES_APPLY_CSC_TO_X_SCREEN           0x00000002
#define NV_CTRL_GVO_CAPABILITIES_COMPOSITE_TERMINATION           0x00000004
#define NV_CTRL_GVO_CAPABILITIES_SHARED_SYNC_BNC                 0x00000008
#define NV_CTRL_GVO_CAPABILITIES_MULTIRATE_SYNC                  0x00000010
#define NV_CTRL_GVO_CAPABILITIES_ADVANCE_SYNC_SKEW               0x00000020


/*
 * NV_CTRL_GVO_COMPOSITE_TERMINATION - enable or disable 75 ohm
 * termination of the SDI composite input signal.
 */

#define NV_CTRL_GVO_COMPOSITE_TERMINATION                        230  /* RW- */
#define NV_CTRL_GVO_COMPOSITE_TERMINATION_ENABLE                   1
#define NV_CTRL_GVO_COMPOSITE_TERMINATION_DISABLE                  0


/*
 * NV_CTRL_ASSOCIATED_DISPLAY_DEVICES - display device mask indicating
 * which display devices are "associated" with the specified X screen
 * (ie: are available to the X screen for displaying the X screen).
 */
 
#define NV_CTRL_ASSOCIATED_DISPLAY_DEVICES                       231 /* RW- */

/*
 * NV_CTRL_FRAMELOCK_SLAVES - get/set whether the display device(s)
 * given should listen or ignore the master's sync signal.
 *
 * This attribute can only be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN.
 */

#define NV_CTRL_FRAMELOCK_SLAVES                                 232 /* RW-G */

/*
 * NV_CTRL_FRAMELOCK_MASTERABLE - Can any of the given display devices
 * be set as master of the frame lock group.  Returns a bitmask of the
 * corresponding display devices that can be set as master.
 *
 * This attribute can only be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN.
 */

#define NV_CTRL_FRAMELOCK_MASTERABLE                             233 /* R-DG */

/*
 * NV_CTRL_PROBE_DISPLAYS - re-probes the hardware to detect what
 * display devices are connected to the GPU or GPU driving the
 * specified X screen.  Returns a display mask.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_PROBE_DISPLAYS                                   234 /* R--G */


/*
 * NV_CTRL_REFRESH_RATE - Returns the refresh rate of the specified
 * display device in 100 * Hz (ie. to get the refresh rate in Hz, divide
 * the returned value by 100.)
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_REFRESH_RATE                                     235 /* R-DG */


/*
 * NV_CTRL_GVO_FLIP_QUEUE_SIZE - The Graphics to Video Out interface
 * exposed through NV-CONTROL and the GLX_NV_video_out extension uses
 * an internal flip queue when pbuffers are sent to the video device
 * (via glXSendPbufferToVideoNV()).  The NV_CTRL_GVO_FLIP_QUEUE_SIZE
 * can be used to query and assign the flip queue size.  This
 * attribute is applied to GLX when glXGetVideoDeviceNV() is called by
 * the application.
 */

#define NV_CTRL_GVO_FLIP_QUEUE_SIZE                              236 /* RW- */


/*
 * NV_CTRL_CURRENT_SCANLINE - query the current scanline for the
 * specified display device.
 */

#define NV_CTRL_CURRENT_SCANLINE                                 237 /* R-DG */


/*
 * NV_CTRL_INITIAL_PIXMAP_PLACEMENT - Controls where X pixmaps are initially
 * created.
 *
 * NV_CTRL_INITIAL_PIXMAP_PLACEMENT_FORCE_SYSMEM causes pixmaps to stay in
 * system memory. These pixmaps can't be accelerated by the NVIDIA driver; this
 * will cause blank windows if used with an OpenGL compositing manager.
 * NV_CTRL_INITIAL_PIXMAP_PLACEMENT_SYSMEM creates pixmaps in system memory
 * initially, but allows them to migrate to video memory.
 * NV_CTRL_INITIAL_PIXMAP_PLACEMENT_VIDMEM creates pixmaps in video memory
 * when enough resources are available.
 * NV_CTRL_INITIAL_PIXMAP_PLACEMENT_RESERVED is currently reserved for future
 * use.  Behavior is undefined.
 * NV_CTRL_INITIAL_PIXMAP_PLACEMENT_GPU_SYSMEM creates pixmaps in GPU accessible
 * system memory when enough resources are available.
 */

#define NV_CTRL_INITIAL_PIXMAP_PLACEMENT                         238 /* RW- */
#define NV_CTRL_INITIAL_PIXMAP_PLACEMENT_FORCE_SYSMEM            0
#define NV_CTRL_INITIAL_PIXMAP_PLACEMENT_SYSMEM                  1
#define NV_CTRL_INITIAL_PIXMAP_PLACEMENT_VIDMEM                  2
#define NV_CTRL_INITIAL_PIXMAP_PLACEMENT_RESERVED                3
#define NV_CTRL_INITIAL_PIXMAP_PLACEMENT_GPU_SYSMEM              4


/*
 * NV_CTRL_PCI_BUS - Returns the PCI bus number the specified device is using.
 */

#define NV_CTRL_PCI_BUS                                          239 /* R--GI */


/*
 * NV_CTRL_PCI_DEVICE - Returns the PCI device number the specified device is
 * using.
 */

#define NV_CTRL_PCI_DEVICE                                       240 /* R--GI */


/*
 * NV_CTRL_PCI_FUNCTION - Returns the PCI function number the specified device
 * is using.
 */

#define NV_CTRL_PCI_FUNCTION                                     241 /* R--GI */


/*
 * NV_CTRL_FRAMELOCK_FPGA_REVISION - Querys the FPGA revision of the
 * Frame Lock device.
 *
 * This attribute must be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK target.
 */

#define NV_CTRL_FRAMELOCK_FPGA_REVISION                          242 /* R--F */

/*
 * NV_CTRL_MAX_SCREEN_{WIDTH,HEIGHT} - the maximum allowable size, in
 * pixels, of either the specified X screen (if the target_type of the
 * query is an X screen), or any X screen on the specified GPU (if the
 * target_type of the query is a GPU).
 */

#define NV_CTRL_MAX_SCREEN_WIDTH                                 243 /* R--G */
#define NV_CTRL_MAX_SCREEN_HEIGHT                                244 /* R--G */


/*
 * NV_CTRL_MAX_DISPLAYS - the maximum number of display devices that
 * can be driven simultaneously on a GPU (e.g., that can be used in a
 * MetaMode at once).  Note that this does not indicate the maximum
 * number of bits that can be set in NV_CTRL_CONNECTED_DISPLAYS,
 * because more display devices can be connected than are actively in
 * use.
 */

#define NV_CTRL_MAX_DISPLAYS                                     245 /* R--G */


/*
 * NV_CTRL_DYNAMIC_TWINVIEW - Returns whether or not the screen
 * supports dynamic twinview.
 */

#define NV_CTRL_DYNAMIC_TWINVIEW                                 246 /* R-- */


/*
 * NV_CTRL_MULTIGPU_DISPLAY_OWNER - Returns the (NV-CONTROL) GPU ID of
 * the GPU that has the display device(s) used for showing the X Screen.
 */

#define NV_CTRL_MULTIGPU_DISPLAY_OWNER                           247 /* R-- */


/*
 * NV_CTRL_GPU_SCALING - not supported
 */

#define NV_CTRL_GPU_SCALING                                      248 /* RWDG */

#define NV_CTRL_GPU_SCALING_TARGET_INVALID                       0
#define NV_CTRL_GPU_SCALING_TARGET_FLATPANEL_BEST_FIT            1
#define NV_CTRL_GPU_SCALING_TARGET_FLATPANEL_NATIVE              2

#define NV_CTRL_GPU_SCALING_METHOD_INVALID                       0
#define NV_CTRL_GPU_SCALING_METHOD_STRETCHED                     1
#define NV_CTRL_GPU_SCALING_METHOD_CENTERED                      2
#define NV_CTRL_GPU_SCALING_METHOD_ASPECT_SCALED                 3


/*
 * NV_CTRL_FRONTEND_RESOLUTION - not supported
 */

#define NV_CTRL_FRONTEND_RESOLUTION                              249 /* R-DG */


/*
 * NV_CTRL_BACKEND_RESOLUTION - not supported
 */

#define NV_CTRL_BACKEND_RESOLUTION                               250 /* R-DG */


/*
 * NV_CTRL_FLATPANEL_NATIVE_RESOLUTION - Returns the dimensions of the
 * native resolution of the flat panel as determined by the
 * NVIDIA X Driver.
 *
 * The native resolution is the resolution at which a flat panel
 * must display any image.  All other resolutions must be scaled to this
 * resolution through GPU scaling or the DFP's native scaling capabilities 
 * in order to be displayed.
 *
 * This attribute is only valid for flat panel (DFP) display devices.
 *
 * This attribute is a packed integer; the width is packed in the upper
 * 16-bits and the height is packed in the lower 16-bits.
 */

#define NV_CTRL_FLATPANEL_NATIVE_RESOLUTION                      251 /* R-DG */


/*
 * NV_CTRL_FLATPANEL_BEST_FIT_RESOLUTION - not supported
 */

#define NV_CTRL_FLATPANEL_BEST_FIT_RESOLUTION                    252 /* R-DG */


/*
 * NV_CTRL_GPU_SCALING_ACTIVE - not supported
 */

#define NV_CTRL_GPU_SCALING_ACTIVE                               253 /* R-DG */


/*
 * NV_CTRL_DFP_SCALING_ACTIVE - not supported
 */

#define NV_CTRL_DFP_SCALING_ACTIVE                               254 /* R-DG */


/*
 * NV_CTRL_FSAA_APPLICATION_ENHANCED - Controls how the NV_CTRL_FSAA_MODE
 * is applied when NV_CTRL_FSAA_APPLICATION_CONTROLLED is set to
 * NV_CTRL_APPLICATION_CONTROLLED_DISABLED.  When
 * NV_CTRL_FSAA_APPLICATION_ENHANCED is _DISABLED, OpenGL applications will
 * be forced to use the FSAA mode specified by NV_CTRL_FSAA_MODE.  when set
 * to _ENABLED, only those applications that have selected a multisample
 * FBConfig will be made to use the NV_CTRL_FSAA_MODE specified.
 *
 * This attribute is ignored when NV_CTRL_FSAA_APPLICATION_CONTROLLED is
 * set to NV_CTRL_FSAA_APPLICATION_CONTROLLED_ENABLED.
 */

#define NV_CTRL_FSAA_APPLICATION_ENHANCED                       255  /* RW-X */
#define NV_CTRL_FSAA_APPLICATION_ENHANCED_ENABLED                 1
#define NV_CTRL_FSAA_APPLICATION_ENHANCED_DISABLED                0


/*
 * NV_CTRL_FRAMELOCK_SYNC_RATE_4 - This is the refresh rate that the
 * frame lock board is sending to the GPU with 4 digits of precision.
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK.
 */

#define NV_CTRL_FRAMELOCK_SYNC_RATE_4                           256 /* R--F */


/*
 * NV_CTRL_GVO_LOCK_OWNER - indicates that the GVO device is available
 * or in use (by GLX or an X screen).
 *
 * The GVO device is locked by GLX when either glXGetVideoDeviceNV
 * (part of GLX_NV_video_out) or glXBindVideoDeviceNV (part of
 * GLX_NV_present_video) is called.  All GVO output resources are
 * locked until released by the GLX_NV_video_out/GLX_NV_present_video
 * client.
 *
 * The GVO device is locked/unlocked by an X screen, when the GVO device is
 * used in a MetaMode on an X screen.
 *
 * When the GVO device is locked, setting of the following GVO NV-CONTROL
 * attributes will not happen immediately and will instead be cached.  The
 * GVO resource will need to be disabled/released and re-enabled/claimed for
 * the values to be flushed. These attributes are:
 *
 *    NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT
 *    NV_CTRL_GVO_DATA_FORMAT
 *    NV_CTRL_GVO_FLIP_QUEUE_SIZE
 */

#define NV_CTRL_GVO_LOCK_OWNER                                  257 /* R-- */
#define NV_CTRL_GVO_LOCK_OWNER_NONE                               0
#define NV_CTRL_GVO_LOCK_OWNER_GLX                                1
#define NV_CTRL_GVO_LOCK_OWNER_CLONE /* no longer supported */    2
#define NV_CTRL_GVO_LOCK_OWNER_X_SCREEN                           3


/*
 * NV_CTRL_HWOVERLAY - when a workstation overlay is in use, reports
 * whether the hardware overlay is used, or if the overlay is emulated.
 */

#define NV_CTRL_HWOVERLAY                                       258 /* R-- */
#define NV_CTRL_HWOVERLAY_FALSE                                   0
#define NV_CTRL_HWOVERLAY_TRUE                                    1

/*
 * NV_CTRL_NUM_GPU_ERRORS_RECOVERED - Returns the number of GPU errors
 * occured. This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_NUM_GPU_ERRORS_RECOVERED                        259 /* R--- */


/*
 * NV_CTRL_REFRESH_RATE_3 - Returns the refresh rate of the specified
 * display device in 1000 * Hz (ie. to get the refresh rate in Hz, divide
 * the returned value by 1000.)
 *
 * This attribute may be queried through XNVCTRLQueryTargetAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_REFRESH_RATE_3                                  260 /* R-DG */


/*
 * NV_CTRL_ONDEMAND_VBLANK_INTERRUPTS - if the OnDemandVBlankInterrupts
 * X driver option is set to true, this attribute can be used to
 * determine if on-demand VBlank interrupt control is enabled on the
 * specified GPU, as well as to enable or disable this feature.
 */

#define NV_CTRL_ONDEMAND_VBLANK_INTERRUPTS                      261 /* RW-G */
#define NV_CTRL_ONDEMAND_VBLANK_INTERRUPTS_OFF                    0
#define NV_CTRL_ONDEMAND_VBLANK_INTERRUPTS_ON                     1


/*
 * NV_CTRL_GPU_POWER_SOURCE reports the type of power source
 * of the GPU driving the X screen.
 */

#define NV_CTRL_GPU_POWER_SOURCE                                262 /* R--G */
#define NV_CTRL_GPU_POWER_SOURCE_AC                               0
#define NV_CTRL_GPU_POWER_SOURCE_BATTERY                          1


/*
 * NV_CTRL_GPU_CURRENT_PERFORMANCE_MODE is deprecated
 */

#define NV_CTRL_GPU_CURRENT_PERFORMANCE_MODE                    263 /* R--G */
#define NV_CTRL_GPU_CURRENT_PERFORMANCE_MODE_DESKTOP              0
#define NV_CTRL_GPU_CURRENT_PERFORMANCE_MODE_MAXPERF              1


/* NV_CTRL_GLYPH_CACHE - Enables RENDER Glyph Caching to VRAM */

#define NV_CTRL_GLYPH_CACHE                                     264 /* RW- */
#define NV_CTRL_GLYPH_CACHE_DISABLED                              0
#define NV_CTRL_GLYPH_CACHE_ENABLED                               1


/*
 * NV_CTRL_GPU_CURRENT_PERFORMANCE_LEVEL reports the current
 * Performance level of the GPU driving the X screen.  Each
 * Performance level has associated NVClock and Mem Clock values.
 */

#define NV_CTRL_GPU_CURRENT_PERFORMANCE_LEVEL                   265 /* R--G */


/*
 * NV_CTRL_GPU_ADAPTIVE_CLOCK_STATE reports if Adaptive Clocking
 * is Enabled on the GPU driving the X screen.
 */

#define NV_CTRL_GPU_ADAPTIVE_CLOCK_STATE                        266 /* R--G */
#define NV_CTRL_GPU_ADAPTIVE_CLOCK_STATE_DISABLED                 0
#define NV_CTRL_GPU_ADAPTIVE_CLOCK_STATE_ENABLED                  1


/*
 * NV_CTRL_GVO_OUTPUT_VIDEO_LOCKED - Returns whether or not the GVO output
 * video is locked to the GPU.
 */

#define NV_CTRL_GVO_OUTPUT_VIDEO_LOCKED                         267 /* R--- */
#define NV_CTRL_GVO_OUTPUT_VIDEO_LOCKED_FALSE                     0
#define NV_CTRL_GVO_OUTPUT_VIDEO_LOCKED_TRUE                      1


/*
 * NV_CTRL_GVO_SYNC_LOCK_STATUS - Returns whether or not the GVO device
 * is locked to the input ref signal.  If the sync mode is set to
 * NV_CTRL_GVO_SYNC_MODE_GENLOCK, then this returns the genlock
 * sync status, and if the sync mode is set to NV_CTRL_GVO_SYNC_MODE_FRAMELOCK,
 * then this reports the frame lock status.
 */

#define NV_CTRL_GVO_SYNC_LOCK_STATUS                            268 /* R--- */
#define NV_CTRL_GVO_SYNC_LOCK_STATUS_UNLOCKED                     0
#define NV_CTRL_GVO_SYNC_LOCK_STATUS_LOCKED                       1


/*
 * NV_CTRL_GVO_ANC_TIME_CODE_GENERATION - Allows SDI device to generate
 * time codes in the ANC region of the SDI video output stream.
 */

#define NV_CTRL_GVO_ANC_TIME_CODE_GENERATION                    269 /* RW-- */
#define NV_CTRL_GVO_ANC_TIME_CODE_GENERATION_DISABLE              0
#define NV_CTRL_GVO_ANC_TIME_CODE_GENERATION_ENABLE               1


/*
 * NV_CTRL_GVO_COMPOSITE - Enables/Disables SDI compositing.  This attribute
 * is only available when an SDI input source is detected and is in genlock
 * mode.
 */

#define NV_CTRL_GVO_COMPOSITE                                   270 /* RW-- */
#define NV_CTRL_GVO_COMPOSITE_DISABLE                             0
#define NV_CTRL_GVO_COMPOSITE_ENABLE                              1


/*
 * NV_CTRL_GVO_COMPOSITE_ALPHA_KEY - When compositing is enabled, this
 * enables/disables alpha blending.
 */

#define NV_CTRL_GVO_COMPOSITE_ALPHA_KEY                         271 /* RW-- */
#define NV_CTRL_GVO_COMPOSITE_ALPHA_KEY_DISABLE                   0
#define NV_CTRL_GVO_COMPOSITE_ALPHA_KEY_ENABLE                    1


/*
 * NV_CTRL_GVO_COMPOSITE_LUMA_KEY_RANGE - Set the values of a luma
 * channel range.  This is a packed int that has the following format
 * (in order of high-bits to low bits):
 *
 * Range # (11 bits), (Enabled 1 bit), min value (10 bits), max value (10 bits)
 *
 * To query the current values, pass the range # throught the display_mask
 * variable.
 */

#define NV_CTRL_GVO_COMPOSITE_LUMA_KEY_RANGE                    272 /* RW-- */

#define NV_CTRL_GVO_COMPOSITE_MAKE_RANGE(range, enable, min, max) \
    ((((min) & 0x3FF)   <<  0) |  \
     (((max) & 0x3FF)   << 10) |  \
     (((enable) & 0x1)  << 20) |  \
     (((range) & 0x7FF) << 21))

#define NV_CTRL_GVO_COMPOSITE_GET_RANGE(val, range, enable, min, max) \
    (min)    = ((val) >> 0)  & 0x3FF; \
    (max)    = ((val) >> 10) & 0x3FF; \
    (enable) = ((val) >> 20) & 0x1;   \
    (range)  = ((val) >> 21) & 0x7FF;


/*
 * NV_CTRL_GVO_COMPOSITE_CR_KEY_RANGE - Set the values of a CR
 * channel range.  This is a packed int that has the following format
 * (in order of high-bits to low bits):
 *
 * Range # (11 bits), (Enabled 1 bit), min value (10 bits), max value (10 bits)
 *
 * To query the current values, pass the range # throught he display_mask
 * variable.
 */

#define NV_CTRL_GVO_COMPOSITE_CR_KEY_RANGE                      273 /* RW-- */


/*
 * NV_CTRL_GVO_COMPOSITE_CB_KEY_RANGE - Set the values of a CB
 * channel range.  This is a packed int that has the following format
 * (in order of high-bits to low bits):
 *
 * Range # (11 bits), (Enabled 1 bit), min value (10 bits), max value (10 bits)
 *
 * To query the current values, pass the range # throught he display_mask
 * variable.
 */

#define NV_CTRL_GVO_COMPOSITE_CB_KEY_RANGE                      274 /* RW-- */


/*
 * NV_CTRL_GVO_COMPOSITE_NUM_KEY_RANGES - Returns the number of ranges
 * available for each channel (Y/Luma, Cr, and Cb.)
 */

#define NV_CTRL_GVO_COMPOSITE_NUM_KEY_RANGES                    275 /* R--- */


/*
 * NV_CTRL_SWITCH_TO_DISPLAYS - Can be used to select which displays
 * to switch to (as a hotkey event).
 */

#define NV_CTRL_SWITCH_TO_DISPLAYS                              276 /* -W- */


/*
 * NV_CTRL_NOTEBOOK_DISPLAY_CHANGE_LID_EVENT - Event that notifies
 * when a notebook lid change occurs (i.e. when the lid is opened or
 * closed.)  This attribute can be queried to retrieve the current
 * notebook lid status (opened/closed.)
 */

#define NV_CTRL_NOTEBOOK_DISPLAY_CHANGE_LID_EVENT               277 /* RW- */
#define NV_CTRL_NOTEBOOK_DISPLAY_CHANGE_LID_EVENT_CLOSE           0
#define NV_CTRL_NOTEBOOK_DISPLAY_CHANGE_LID_EVENT_OPEN            1

/*
 * NV_CTRL_NOTEBOOK_INTERNAL_LCD - Returns the display device mask of
 * the intenal LCD of a notebook.
 */

#define NV_CTRL_NOTEBOOK_INTERNAL_LCD                           278 /* R-- */

/*
 * NV_CTRL_DEPTH_30_ALLOWED - returns whether the NVIDIA X driver supports
 * depth 30 on the specified X screen or GPU.
 */

#define NV_CTRL_DEPTH_30_ALLOWED                                279 /* R--G */


/*
 * NV_CTRL_MODE_SET_EVENT This attribute is sent as an event
 * when hotkey, ctrl-alt-+/- or randr event occurs.  Note that
 * This attribute cannot be set or queried and is meant to
 * be received by clients that wish to be notified of when
 * mode set events occur.
 */

#define NV_CTRL_MODE_SET_EVENT                                  280 /* --- */


/*
 * NV_CTRL_OPENGL_AA_LINE_GAMMA_VALUE - the gamma value used by
 * OpenGL when NV_CTRL_OPENGL_AA_LINE_GAMMA is enabled
 */

#define NV_CTRL_OPENGL_AA_LINE_GAMMA_VALUE                      281 /* RW-X */


/*
 * NV_CTRL_VCSC_HIGH_PERF_MODE - Is used to both query High Performance Mode
 * status on the Visual Computing System, and also to enable or disable High
 * Performance Mode.
 */

#define NV_CTRL_VCSC_HIGH_PERF_MODE                             282 /* RW-V */
#define NV_CTRL_VCSC_HIGH_PERF_MODE_DISABLE                       0
#define NV_CTRL_VCSC_HIGH_PERF_MODE_ENABLE                        1

/*
 * NV_CTRL_DISPLAYPORT_LINK_RATE - returns the negotiated lane bandwidth of the
 * DisplayPort main link.
 * This attribute is only available for DisplayPort flat panels.
 */

#define NV_CTRL_DISPLAYPORT_LINK_RATE                           291 /* R-DG */
#define NV_CTRL_DISPLAYPORT_LINK_RATE_DISABLED                  0x0
#define NV_CTRL_DISPLAYPORT_LINK_RATE_1_62GBPS                  0x6
#define NV_CTRL_DISPLAYPORT_LINK_RATE_2_70GBPS                  0xA

/*
 * NV_CTRL_STEREO_EYES_EXCHANGE - Controls whether or not the left and right
 * eyes of a stereo image are flipped.
 */

#define NV_CTRL_STEREO_EYES_EXCHANGE                            292  /* RW-X */
#define NV_CTRL_STEREO_EYES_EXCHANGE_OFF                          0
#define NV_CTRL_STEREO_EYES_EXCHANGE_ON                           1

/*
 * NV_CTRL_NO_SCANOUT - returns whether the special "NoScanout" mode is
 * enabled on the specified X screen or GPU; for details on this mode,
 * see the description of the "none" value for the "UseDisplayDevice"
 * X configuration option in the NVIDIA driver README.
 */

#define NV_CTRL_NO_SCANOUT                                      293 /* R--G */
#define NV_CTRL_NO_SCANOUT_DISABLED                             0
#define NV_CTRL_NO_SCANOUT_ENABLED                              1

/*
 * NV_CTRL_GVO_CSC_CHANGED_EVENT This attribute is sent as an event
 * when the color space conversion matrix has been altered by another
 * client.
 */

#define NV_CTRL_GVO_CSC_CHANGED_EVENT                           294 /* --- */

/* 
 * NV_CTRL_FRAMELOCK_SLAVEABLE - Returns a bitmask of the display devices
 * that are (currently) allowed to be selected as slave devices for the
 * given GPU
 */

#define NV_CTRL_FRAMELOCK_SLAVEABLE                             295 /* R-DG */

/*
 * NV_CTRL_GVO_SYNC_TO_DISPLAY This attribute controls whether or not
 * the non-SDI display device will be sync'ed to the SDI display device
 * (when configured in TwinView, Clone Mode or when using the SDI device
 * with OpenGL).
 */

#define NV_CTRL_GVO_SYNC_TO_DISPLAY                             296 /* --- */
#define NV_CTRL_GVO_SYNC_TO_DISPLAY_DISABLE                     0
#define NV_CTRL_GVO_SYNC_TO_DISPLAY_ENABLE                      1

/*
 * NV_CTRL_X_SERVER_UNIQUE_ID - returns a pseudo-unique identifier for this
 * X server. Intended for use in cases where an NV-CONTROL client communicates
 * with multiple X servers, and wants some level of confidence that two
 * X Display connections correspond to the same or different X servers.
 */

#define NV_CTRL_X_SERVER_UNIQUE_ID                              297 /* R--- */

/*
 * NV_CTRL_PIXMAP_CACHE - This attribute controls whether the driver attempts to
 * store video memory pixmaps in a cache.  The cache speeds up allocation and
 * deallocation of pixmaps, but could use more memory than when the cache is
 * disabled.
 */

#define NV_CTRL_PIXMAP_CACHE                                    298 /* RW-X */
#define NV_CTRL_PIXMAP_CACHE_DISABLE                              0
#define NV_CTRL_PIXMAP_CACHE_ENABLE                               1

/*
 * NV_CTRL_PIXMAP_CACHE_ROUNDING_SIZE_KB - When the pixmap cache is enabled and
 * there is not enough free space in the cache to fit a new pixmap, the driver
 * will round up to the next multiple of this number of kilobytes when
 * allocating more memory for the cache.
 */

#define NV_CTRL_PIXMAP_CACHE_ROUNDING_SIZE_KB                   299 /* RW-X */

/*
 * NV_CTRL_IS_GVO_DISPLAY - returns whether or not a given display is an
 * SDI device.
 */

#define NV_CTRL_IS_GVO_DISPLAY                                  300 /* R-D */
#define NV_CTRL_IS_GVO_DISPLAY_FALSE                              0
#define NV_CTRL_IS_GVO_DISPLAY_TRUE                               1

/*
 * NV_CTRL_PCI_ID - Returns the PCI vendor and device ID of the specified
 * device.
 *
 * NV_CTRL_PCI_ID is a "packed" integer attribute; the PCI vendor ID is stored
 * in the upper 16 bits of the integer, and the PCI device ID is stored in the
 * lower 16 bits of the integer.
 */

#define NV_CTRL_PCI_ID                                          301 /* R--GI */

/*
 * NV_CTRL_GVO_FULL_RANGE_COLOR - Allow full range color data [4-1019]
 * without clamping to [64-940].
 */

#define NV_CTRL_GVO_FULL_RANGE_COLOR                            302 /* RW- */
#define NV_CTRL_GVO_FULL_RANGE_COLOR_DISABLED                     0
#define NV_CTRL_GVO_FULL_RANGE_COLOR_ENABLED                      1

/*
 * NV_CTRL_SLI_MOSAIC_MODE_AVAILABLE - Returns whether or not
 * SLI Mosaic Mode supported.
 */

#define NV_CTRL_SLI_MOSAIC_MODE_AVAILABLE                       303 /* R-- */
#define NV_CTRL_SLI_MOSAIC_MODE_AVAILABLE_FALSE                   0
#define NV_CTRL_SLI_MOSAIC_MODE_AVAILABLE_TRUE                    1

/*
 * NV_CTRL_GVO_ENABLE_RGB_DATA - Allows clients to specify when
 * the GVO board should process colors as RGB when the output data
 * format is one of the NV_CTRL_GVO_DATA_FORMAT_???_PASSTRHU modes.
 */

#define NV_CTRL_GVO_ENABLE_RGB_DATA                             304 /* RW- */
#define NV_CTRL_GVO_ENABLE_RGB_DATA_DISABLE                       0
#define NV_CTRL_GVO_ENABLE_RGB_DATA_ENABLE                        1

/*
 * NV_CTRL_IMAGE_SHARPENING_DEFAULT - Returns default value of
 * Image Sharpening.
 */

#define NV_CTRL_IMAGE_SHARPENING_DEFAULT                        305 /* R-- */

/*
 * NV_CTRL_PCI_DOMAIN - Returns the PCI domain number the specified device is
 * using.
 */

#define NV_CTRL_PCI_DOMAIN                                      306 /* R--GI */

/*
 * NV_CTRL_GVI_NUM_JACKS - Returns the number of input BNC jacks available
 * on a GVI device.
 */

#define NV_CTRL_GVI_NUM_JACKS                                   307 /* R--I */

/* 
 * NV_CTRL_GVI_MAX_LINKS_PER_STREAM - Returns the maximum supported number of
 * links that can be tied to one stream.
 */

#define NV_CTRL_GVI_MAX_LINKS_PER_STREAM                        308 /* R--I */

/*
 * NV_CTRL_GVI_DETECTED_CHANNEL_BITS_PER_COMPONENT - Returns the detected
 * number of bits per component (BPC) of data on the given input jack+
 * channel.
 *
 * The jack number should be specified in the lower 16 bits of the
 * "display_mask" parameter, while the channel number should be specified in
 * the upper 16 bits.
 */

#define NV_CTRL_GVI_DETECTED_CHANNEL_BITS_PER_COMPONENT         309 /* R--I */
#define NV_CTRL_GVI_BITS_PER_COMPONENT_UNKNOWN                    0
#define NV_CTRL_GVI_BITS_PER_COMPONENT_8                          1
#define NV_CTRL_GVI_BITS_PER_COMPONENT_10                         2
#define NV_CTRL_GVI_BITS_PER_COMPONENT_12                         3

/*
 * NV_CTRL_GVI_REQUESTED_STREAM_BITS_PER_COMPONENT - Specify the number of
 * bits per component (BPC) of data for the captured stream.
 * The stream number should be specified in the "display_mask" parameter.
 *
 * Note: Setting this attribute may also result in the following
 *       NV-CONTROL attributes being reset on the GVI device (to ensure
 *       the configuration remains valid):
 *           NV_CTRL_GVI_REQUESTED_STREAM_COMPONENT_SAMPLING
 */

#define NV_CTRL_GVI_REQUESTED_STREAM_BITS_PER_COMPONENT         310 /* RW-I */

/*
 * NV_CTRL_GVI_DETECTED_CHANNEL_COMPONENT_SAMPLING - Returns the detected
 * sampling format for the input jack+channel.
 *
 * The jack number should be specified in the lower 16 bits of the
 * "display_mask" parameter, while the channel number should be specified in
 * the upper 16 bits.
 */

#define NV_CTRL_GVI_DETECTED_CHANNEL_COMPONENT_SAMPLING         311 /* R--I */
#define NV_CTRL_GVI_COMPONENT_SAMPLING_UNKNOWN                    0
#define NV_CTRL_GVI_COMPONENT_SAMPLING_4444                       1
#define NV_CTRL_GVI_COMPONENT_SAMPLING_4224                       2
#define NV_CTRL_GVI_COMPONENT_SAMPLING_444                        3
#define NV_CTRL_GVI_COMPONENT_SAMPLING_422                        4
#define NV_CTRL_GVI_COMPONENT_SAMPLING_420                        5

/*
 * NV_CTRL_GVI_REQUESTED_COMPONENT_SAMPLING - Specify the sampling format for
 * the captured stream.
 * The possible values are the NV_CTRL_GVI_DETECTED_COMPONENT_SAMPLING
 * constants.
 * The stream number should be specified in the "display_mask" parameter.
 */

#define NV_CTRL_GVI_REQUESTED_STREAM_COMPONENT_SAMPLING         312 /* RW-I */

/*
 * NV_CTRL_GVI_CHROMA_EXPAND - Enable or disable 4:2:2 -> 4:4:4 chroma
 * expansion for the captured stream.  This value is ignored when a
 * COMPONENT_SAMPLING format is selected that does not use chroma subsampling,
 * or if a BITS_PER_COMPONENT value is selected that is not supported.
 * The stream number should be specified in the "display_mask" parameter.
 */

#define NV_CTRL_GVI_REQUESTED_STREAM_CHROMA_EXPAND              313 /* RW-I */
#define NV_CTRL_GVI_CHROMA_EXPAND_FALSE                           0
#define NV_CTRL_GVI_CHROMA_EXPAND_TRUE                            1

/*
 * NV_CTRL_GVI_DETECTED_CHANNEL_COLOR_SPACE - Returns the detected color space
 * of the input jack+channel.
 *
 * The jack number should be specified in the lower 16 bits of the
 * "display_mask" parameter, while the channel number should be specified in
 * the upper 16 bits.
 */

#define NV_CTRL_GVI_DETECTED_CHANNEL_COLOR_SPACE                314 /* R--I */
#define NV_CTRL_GVI_COLOR_SPACE_UNKNOWN                           0
#define NV_CTRL_GVI_COLOR_SPACE_GBR                               1
#define NV_CTRL_GVI_COLOR_SPACE_GBRA                              2
#define NV_CTRL_GVI_COLOR_SPACE_GBRD                              3
#define NV_CTRL_GVI_COLOR_SPACE_YCBCR                             4
#define NV_CTRL_GVI_COLOR_SPACE_YCBCRA                            5
#define NV_CTRL_GVI_COLOR_SPACE_YCBCRD                            6

/*
 * NV_CTRL_GVI_DETECTED_CHANNEL_LINK_ID - Returns the detected link identifier
 * for the given input jack+channel.
 *
 * The jack number should be specified in the lower 16 bits of the
 * "display_mask" parameter, while the channel number should be specified in
 * the upper 16 bits.
 */

#define NV_CTRL_GVI_DETECTED_CHANNEL_LINK_ID                    315 /* R--I */
#define NV_CTRL_GVI_LINK_ID_UNKNOWN                          0xFFFF

/*
 * NV_CTRL_GVI_DETECTED_CHANNEL_SMPTE352_IDENTIFIER - Returns the 4-byte
 * SMPTE 352 identifier from the given input jack+channel.
 *
 * The jack number should be specified in the lower 16 bits of the
 * "display_mask" parameter, while the channel number should be specified in
 * the upper 16 bits.
 */

#define NV_CTRL_GVI_DETECTED_CHANNEL_SMPTE352_IDENTIFIER        316 /* R--I */

/*
 * NV_CTRL_GVI_GLOBAL_IDENTIFIER - Returns a global identifier for the
 * GVI device.  This identifier can be used to relate GVI devices named
 * in NV-CONTROL with those enumerated in OpenGL.
 */

#define NV_CTRL_GVI_GLOBAL_IDENTIFIER                           317 /* R--I */

/*
 * NV_CTRL_FRAMELOCK_SYNC_DELAY_RESOLUTION - Returns the number of nanoseconds
 * that one unit of NV_CTRL_FRAMELOCK_SYNC_DELAY corresponds to.
 */
#define NV_CTRL_FRAMELOCK_SYNC_DELAY_RESOLUTION                 318 /* R-- */

/*
 * NV_CTRL_GPU_COOLER_MANUAL_CONTROL - Query the current or set a new
 * cooler control state; the value of this attribute controls the
 * availability of additional cooler control attributes (see below).
 *
 * Note: this attribute is unavailable unless cooler control support
 * has been enabled in the X server (by the user).
 */

#define NV_CTRL_GPU_COOLER_MANUAL_CONTROL                       319 /* RW-G */
#define NV_CTRL_GPU_COOLER_MANUAL_CONTROL_FALSE                   0
#define NV_CTRL_GPU_COOLER_MANUAL_CONTROL_TRUE                    1

/* 
 * NV_CTRL_THERMAL_COOLER_LEVEL - Returns cooler's current operating 
 * level.
 */

#define NV_CTRL_THERMAL_COOLER_LEVEL                            320 /* RW-C */

/* NV_CTRL_THERMAL_COOLER_LEVEL_SET_DEFAULT - Sets default values of  
 * cooler.
 */

#define NV_CTRL_THERMAL_COOLER_LEVEL_SET_DEFAULT                321 /* -W-C */

/* 
 * NV_CTRL_THERMAL_COOLER_CONTROL_TYPE - 
 * Returns a cooler's control signal characteristics.
 * The possible types are restricted, Variable and Toggle.
 */

#define NV_CTRL_THERMAL_COOLER_CONTROL_TYPE                     322 /* R--C */
#define NV_CTRL_THERMAL_COOLER_CONTROL_TYPE_NONE                  0
#define NV_CTRL_THERMAL_COOLER_CONTROL_TYPE_TOGGLE                1 
#define NV_CTRL_THERMAL_COOLER_CONTROL_TYPE_VARIABLE              2

/* 
 * NV_CTRL_THERMAL_COOLER_TARGET - Returns objects that cooler cools.
 * Targets may be GPU, Memory, Power Supply or All of these.
 * GPU_RELATED = GPU | MEMORY | POWER_SUPPLY
 * 
 */

#define NV_CTRL_THERMAL_COOLER_TARGET                           323 /* R--C */
#define NV_CTRL_THERMAL_COOLER_TARGET_NONE                        0
#define NV_CTRL_THERMAL_COOLER_TARGET_GPU                         1
#define NV_CTRL_THERMAL_COOLER_TARGET_MEMORY                      2
#define NV_CTRL_THERMAL_COOLER_TARGET_POWER_SUPPLY                4
#define NV_CTRL_THERMAL_COOLER_TARGET_GPU_RELATED   \
        (NV_CTRL_THERMAL_COOLER_TARGET_GPU |        \
         NV_CTRL_THERMAL_COOLER_TARGET_MEMORY |     \
         NV_CTRL_THERMAL_COOLER_TARGET_POWER_SUPPLY) 

/*
 * NV_CTRL_GPU_ECC_SUPPORTED - Reports whether ECC is supported by the
 * targeted GPU.
 */
#define NV_CTRL_GPU_ECC_SUPPORTED                               324 /* R--G */
#define NV_CTRL_GPU_ECC_SUPPORTED_FALSE                           0
#define NV_CTRL_GPU_ECC_SUPPORTED_TRUE                            1

/*
 * NV_CTRL_GPU_ECC_STATUS - Returns the current hardware ECC setting
 * for the targeted GPU.
 */
#define NV_CTRL_GPU_ECC_STATUS                                  325 /* R--G */
#define NV_CTRL_GPU_ECC_STATUS_DISABLED                           0
#define NV_CTRL_GPU_ECC_STATUS_ENABLED                            1

/*
 * NV_CTRL_GPU_ECC_CONFIGURATION - Reports whether ECC can be configured
 * dynamically for the GPU in question.
 */
#define NV_CTRL_GPU_ECC_CONFIGURATION_SUPPORTED                 326 /* R--G */
#define NV_CTRL_GPU_ECC_CONFIGURATION_SUPPORTED_FALSE             0
#define NV_CTRL_GPU_ECC_CONFIGURATION_SUPPORTED_TRUE              1

/*
 * NV_CTRL_GPU_ECC_CONFIGURATION_SETTING - Returns the current ECC
 * configuration setting or specifies new settings.  New settings do not
 * take effect until the next POST.
 */
#define NV_CTRL_GPU_ECC_CONFIGURATION                           327 /* RW-G */
#define NV_CTRL_GPU_ECC_CONFIGURATION_DISABLED                    0
#define NV_CTRL_GPU_ECC_CONFIGURATION_ENABLED                     1

/*
 * NV_CTRL_GPU_ECC_DEFAULT_CONFIGURATION_SETTING - Returns the default
 * ECC configuration setting.
 */
#define NV_CTRL_GPU_ECC_DEFAULT_CONFIGURATION                   328 /* R--G */
#define NV_CTRL_GPU_ECC_DEFAULT_CONFIGURATION_DISABLED            0
#define NV_CTRL_GPU_ECC_DEFAULT_CONFIGURATION_ENABLED             1

/*
 * NV_CTRL_GPU_ECC_SINGLE_BIT_ERRORS - Returns the number of single-bit
 * ECC errors detected by the targeted GPU since the last POST.
 * Note: this attribute is a 64-bit integer attribute.
 */
#define NV_CTRL_GPU_ECC_SINGLE_BIT_ERRORS                       329 /* R--GQ */

/*
 * NV_CTRL_GPU_ECC_DOUBLE_BIT_ERRORS - Returns the number of double-bit
 * ECC errors detected by the targeted GPU since the last POST.
 * Note: this attribute is a 64-bit integer attribute.
 */
#define NV_CTRL_GPU_ECC_DOUBLE_BIT_ERRORS                       330 /* R--GQ */

/*
 * NV_CTRL_GPU_ECC_AGGREGATE_SINGLE_BIT_ERRORS - Returns the number of
 * single-bit ECC errors detected by the targeted GPU since the
 * last counter reset.
 * Note: this attribute is a 64-bit integer attribute.
 */
#define NV_CTRL_GPU_ECC_AGGREGATE_SINGLE_BIT_ERRORS             331 /* R--GQ */

/*
 * NV_CTRL_GPU_ECC_AGGREGATE_DOUBLE_BIT_ERRORS - Returns the number of
 * double-bit ECC errors detected by the targeted GPU since the
 * last counter reset.
 * Note: this attribute is a 64-bit integer attribute.
 */
#define NV_CTRL_GPU_ECC_AGGREGATE_DOUBLE_BIT_ERRORS             332 /* R--GQ */

/*
 * NV_CTRL_GPU_ECC_RESET_ERROR_STATUS - Resets the volatile/aggregate
 * single-bit and double-bit error counters.  This attribute is a
 * bitmask attribute.
 */
#define NV_CTRL_GPU_ECC_RESET_ERROR_STATUS                      333 /* -W-G */
#define NV_CTRL_GPU_ECC_RESET_ERROR_STATUS_VOLATILE             0x00000001
#define NV_CTRL_GPU_ECC_RESET_ERROR_STATUS_AGGREGATE            0x00000002

/*
 * NV_CTRL_GPU_POWER_MIZER_MODE - Provides a hint to the driver
 * as to how to manage the performance of the GPU.
 *
 * ADAPTIVE                     - adjust GPU clocks based on GPU
 *                                utilization
 * PREFER_MAXIMUM_PERFORMANCE   - raise GPU clocks to favor
 *                                maximum performance, to the extent
 *                                that thermal and other constraints
 *                                allow
 */
#define NV_CTRL_GPU_POWER_MIZER_MODE                            334 /* RW-G */
#define NV_CTRL_GPU_POWER_MIZER_MODE_ADAPTIVE                     0
#define NV_CTRL_GPU_POWER_MIZER_MODE_PREFER_MAXIMUM_PERFORMANCE   1

/*
 * NV_CTRL_GVI_SYNC_OUTPUT_FORMAT - Returns the output sync signal
 * from the GVI device.
 */

#define NV_CTRL_GVI_SYNC_OUTPUT_FORMAT                          335 /* R--I */

/*
 * NV_CTRL_GVI_MAX_CHANNELS_PER_JACK  - Returns the maximum
 * supported number of (logical) channels within a single physical jack of
 * a GVI device.  For most SDI video formats, there is only one channel
 * (channel 0).  But for 3G video formats (as specified in SMPTE 425),
 * as an example, there are two channels (channel 0 and channel 1) per
 * physical jack.
 */

#define NV_CTRL_GVI_MAX_CHANNELS_PER_JACK                       336 /* R--I */

/*
 * NV_CTRL_GVI_MAX_STREAMS  - Returns the maximum number of streams
 * that can be configured on the GVI device.
 */

#define NV_CTRL_GVI_MAX_STREAMS                                 337 /* R--I */

/*
 * NV_CTRL_GVI_NUM_CAPTURE_SURFACES - The GVI interface exposed through
 * NV-CONTROL and the GLX_NV_video_input extension uses internal capture
 * surfaces when frames are read from the GVI device.  The
 * NV_CTRL_GVI_NUM_CAPTURE_SURFACES can be used to query and assign the
 * number of capture surfaces.  This attribute is applied when
 * glXBindVideoCaptureDeviceNV() is called by the application.
 *
 * A lower number of capture surfaces will mean less video memory is used,
 * but can result in frames being dropped if the application cannot keep up
 * with the capture device.  A higher number will prevent frames from being
 * dropped, making capture more reliable but will consume move video memory.
 */
#define NV_CTRL_GVI_NUM_CAPTURE_SURFACES                        338 /* RW-I */

/*
 * NV_CTRL_OVERSCAN_COMPENSATION - not supported
 */
#define NV_CTRL_OVERSCAN_COMPENSATION                           339 /* RWDG */

/*
 * NV_CTRL_GPU_PCIE_GENERATION - Reports the current PCIe generation.
 */
#define NV_CTRL_GPU_PCIE_GENERATION                             341 /* R--GI */
#define NV_CTRL_GPU_PCIE_GENERATION1                            0x00000001
#define NV_CTRL_GPU_PCIE_GENERATION2                            0x00000002
#define NV_CTRL_GPU_PCIE_GENERATION3                            0x00000003

/*
 * NV_CTRL_GVI_BOUND_GPU - Returns the NV_CTRL_TARGET_TYPE_GPU target_id of
 * the GPU currently bound to the GVI device.  Returns -1 if no GPU is
 * currently bound to the GVI device.
 */
#define NV_CTRL_GVI_BOUND_GPU                                   342 /* R--I */

/*
 * NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT3 - this attribute is only
 * intended to be used to query the ValidValues for
 * NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT for VIDEO_FORMAT values between
 * 64 and 95.  See NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT for details.
 */

#define NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT3                    343 /* ---GI */

/*
 * NV_CTRL_ACCELERATE_TRAPEZOIDS - Toggles RENDER Trapezoid acceleration
 */

#define NV_CTRL_ACCELERATE_TRAPEZOIDS                           344 /* RW- */
#define NV_CTRL_ACCELERATE_TRAPEZOIDS_DISABLE                   0
#define NV_CTRL_ACCELERATE_TRAPEZOIDS_ENABLE                    1

/*
 * NV_CTRL_GPU_CORES - Returns number of GPU cores supported by the graphics
 * pipeline.
 */

#define NV_CTRL_GPU_CORES                                       345 /* R--G */

/*
 * NV_CTRL_GPU_MEMORY_BUS_WIDTH - Returns memory bus bandwidth on the associated
 * subdevice.
 */

#define NV_CTRL_GPU_MEMORY_BUS_WIDTH                            346 /* R--G */

/*
 * NV_CTRL_GVI_TEST_MODE - This attribute controls the GVI test mode.  When
 * enabled, the GVI device will generate fake data as quickly as possible.  All
 * GVI settings are still valid when this is enabled (e.g., the requested video
 * format is honored and sets the video size).
 * This may be used to test the pipeline.
 */

#define NV_CTRL_GVI_TEST_MODE                                   347 /* R--I */
#define NV_CTRL_GVI_TEST_MODE_DISABLE                             0
#define NV_CTRL_GVI_TEST_MODE_ENABLE                              1

/*
 * NV_CTRL_COLOR_SPACE - This option sets color space of the video
 * signal.
 */
#define NV_CTRL_COLOR_SPACE                                     348 /* RWDG */
#define NV_CTRL_COLOR_SPACE_RGB                                   0
#define NV_CTRL_COLOR_SPACE_YCbCr422                              1
#define NV_CTRL_COLOR_SPACE_YCbCr444                              2

/*
 * NV_CTRL_COLOR_RANGE - This option sets color range of the video
 * signal.
 */
#define NV_CTRL_COLOR_RANGE                                     349 /* RWDG */
#define NV_CTRL_COLOR_RANGE_FULL                                  0
#define NV_CTRL_COLOR_RANGE_LIMITED                               1

/*
 * NV_CTRL_GPU_SCALING_DEFAULT_TARGET - not supported
 *
 * NV_CTRL_GPU_SCALING_DEFAULT_METHOD - not supported
 */
#define NV_CTRL_GPU_SCALING_DEFAULT_TARGET                      350 /* R-DG */
#define NV_CTRL_GPU_SCALING_DEFAULT_METHOD                      351 /* R-DG */

/*
 * NV_CTRL_DITHERING_MODE - Controls the dithering mode, when
 * NV_CTRL_CURRENT_DITHERING is Enabled.
 *
 * AUTO: allow the driver to choose the dithering mode automatically.
 *
 * DYNAMIC_2X2: use a 2x2 matrix to dither from the GPU's pixel
 * pipeline to the bit depth of the flat panel.  The matrix values
 * are changed from frame to frame.
 *
 * STATIC_2X2: use a 2x2 matrix to dither from the GPU's pixel
 * pipeline to the bit depth of the flat panel.  The matrix values
 * do not change from frame to frame.
 *
 * TEMPORAL: use a pseudorandom value from a uniform distribution calculated at
 * every pixel to achieve stochastic dithering.  This method produces a better
 * visual result than 2x2 matrix approaches.
 */
#define NV_CTRL_DITHERING_MODE                                  352 /* RWDG */
#define NV_CTRL_DITHERING_MODE_AUTO                               0
#define NV_CTRL_DITHERING_MODE_DYNAMIC_2X2                        1
#define NV_CTRL_DITHERING_MODE_STATIC_2X2                         2
#define NV_CTRL_DITHERING_MODE_TEMPORAL                           3

/*
 * NV_CTRL_CURRENT_DITHERING - Returns the current dithering state.
 */
#define NV_CTRL_CURRENT_DITHERING                               353 /* R-DG */
#define NV_CTRL_CURRENT_DITHERING_DISABLED                        0
#define NV_CTRL_CURRENT_DITHERING_ENABLED                         1

/*
 * NV_CTRL_CURRENT_DITHERING_MODE - Returns the current dithering
 * mode.
 */
#define NV_CTRL_CURRENT_DITHERING_MODE                          354 /* R-DG */
#define NV_CTRL_CURRENT_DITHERING_MODE_NONE                       0
#define NV_CTRL_CURRENT_DITHERING_MODE_DYNAMIC_2X2                1
#define NV_CTRL_CURRENT_DITHERING_MODE_STATIC_2X2                 2
#define NV_CTRL_CURRENT_DITHERING_MODE_TEMPORAL                   3

/* 
 * NV_CTRL_THERMAL_SENSOR_READING - Returns the thermal sensor's current
 * reading.
 */
#define NV_CTRL_THERMAL_SENSOR_READING                          355 /* R--S */

/* 
 * NV_CTRL_THERMAL_SENSOR_PROVIDER - Returns the hardware device that
 * provides the thermal sensor.
 */
#define NV_CTRL_THERMAL_SENSOR_PROVIDER                         356 /* R--S */
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_NONE                      0
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_GPU_INTERNAL              1
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_ADM1032                   2
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_ADT7461                   3
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_MAX6649                   4
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_MAX1617                   5
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_LM99                      6
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_LM89                      7
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_LM64                      8
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_G781                      9
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_ADT7473                  10
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_SBMAX6649                11
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_VBIOSEVT                 12
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_OS                       13
#define NV_CTRL_THERMAL_SENSOR_PROVIDER_UNKNOWN          0xFFFFFFFF

/* 
 * NV_CTRL_THERMAL_SENSOR_TARGET - Returns what hardware component
 * the thermal sensor is measuring.
 */
#define NV_CTRL_THERMAL_SENSOR_TARGET                           357 /* R--S */
#define NV_CTRL_THERMAL_SENSOR_TARGET_NONE                        0
#define NV_CTRL_THERMAL_SENSOR_TARGET_GPU                         1
#define NV_CTRL_THERMAL_SENSOR_TARGET_MEMORY                      2
#define NV_CTRL_THERMAL_SENSOR_TARGET_POWER_SUPPLY                4
#define NV_CTRL_THERMAL_SENSOR_TARGET_BOARD                       8
#define NV_CTRL_THERMAL_SENSOR_TARGET_UNKNOWN            0xFFFFFFFF

/*
 * NV_CTRL_SHOW_MULTIGPU_VISUAL_INDICATOR - when TRUE, OpenGL will
 * draw information about the current MULTIGPU mode.
 */
#define NV_CTRL_SHOW_MULTIGPU_VISUAL_INDICATOR                  358  /* RW-X */
#define NV_CTRL_SHOW_MULTIGPU_VISUAL_INDICATOR_FALSE              0
#define NV_CTRL_SHOW_MULTIGPU_VISUAL_INDICATOR_TRUE               1

/*
 * NV_CTRL_GPU_CURRENT_PROCESSOR_CLOCK_FREQS - Returns GPU's processor
 * clock freqs.
 */
#define NV_CTRL_GPU_CURRENT_PROCESSOR_CLOCK_FREQS               359 /* RW-G */

/*
 * NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS - query the flags (various information
 * for the specified NV_CTRL_GVIO_VIDEO_FORMAT_*.  So that this can be
 * queried with existing interfaces, the video format should be specified
 * in the display_mask field; eg:
 *
 * XNVCTRLQueryTargetAttribute(dpy,
 *                             NV_CTRL_TARGET_TYPE_GVI,
 *                             gvi,
 *                             NV_CTRL_GVIO_VIDEO_FORMAT_720P_60_00_SMPTE296,
 *                             NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS,
 *                             &flags);
 *
 * Note: The NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_3G_1080P_NO_12BPC flag is set
 *       for those 1080P 3G modes (level A and B) that do not support
 *       12 bits per component (when configuring a GVI stream.)
 */

#define NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS                         360  /* R--I */
#define NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_NONE              0x00000000
#define NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_INTERLACED        0x00000001
#define NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_PROGRESSIVE       0x00000002
#define NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_PSF               0x00000004
#define NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_3G_LEVEL_A        0x00000008
#define NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_3G_LEVEL_B        0x00000010
#define NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_3G          \
    ((NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_3G_LEVEL_A) | \
     (NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_3G_LEVEL_B))
#define NV_CTRL_GVIO_VIDEO_FORMAT_FLAGS_3G_1080P_NO_12BPC 0x00000020

/*
 * NV_CTRL_GPU_PCIE_MAX_LINK_SPEED - returns maximum PCIe link speed,
 * in gigatransfers per second (GT/s).
 */

#define NV_CTRL_GPU_PCIE_MAX_LINK_SPEED                         361 /* R--GI */

/*
 * NV_CTRL_3D_VISION_PRO_RESET_TRANSCEIVER_TO_FACTORY_SETTINGS - Resets the
 * 3D Vision Pro transceiver to its factory settings.
 */
#define NV_CTRL_3D_VISION_PRO_RESET_TRANSCEIVER_TO_FACTORY_SETTINGS 363 /* -W-T */

/*
 * NV_CTRL_3D_VISION_PRO_TRANSCEIVER_CHANNEL - Controls the channel that is
 * currently used by the 3D Vision Pro transceiver.
 */
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_CHANNEL                   364 /* RW-T */

/*
 * NV_CTRL_3D_VISION_PRO_TRANSCEIVER_MODE - Controls the mode in which the
 * 3D Vision Pro transceiver operates.
 * NV_CTRL_3D_VISION_PRO_TM_LOW_RANGE is bidirectional
 * NV_CTRL_3D_VISION_PRO_TM_MEDIUM_RANGE is bidirectional
 * NV_CTRL_3D_VISION_PRO_TM_HIGH_RANGE may be bidirectional just up to a
 *     given range, and unidirectional beyond it
 * NV_CTRL_3D_VISION_PRO_TM_COUNT is the total number of
 *     3D Vision Pro transceiver modes
 */
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_MODE                      365 /* RW-T */
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_MODE_INVALID              0
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_MODE_LOW_RANGE            1
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_MODE_MEDIUM_RANGE         2
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_MODE_HIGH_RANGE           3
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_MODE_COUNT                4

/*
 * NV_CTRL_SYNCHRONOUS_PALETTE_UPDATES - controls whether updates to the color
 * lookup table (LUT) are synchronous with respect to X rendering.  For example,
 * if an X client sends XStoreColors followed by XFillRectangle, the driver will
 * guarantee that the FillRectangle request is not processed until after the
 * updated LUT colors are actually visible on the screen if
 * NV_CTRL_SYNCHRONOUS_PALETTE_UPDATES is enabled.  Otherwise, the rendering may
 * occur first.
 *
 * This makes a difference for applications that use the LUT to animate, such as
 * XPilot.  If you experience flickering in applications that use LUT
 * animations, try enabling this attribute.
 *
 * When synchronous updates are enabled, XStoreColors requests will be processed
 * at your screen's refresh rate.
 */

#define NV_CTRL_SYNCHRONOUS_PALETTE_UPDATES                     367  /* RWDG */
#define NV_CTRL_SYNCHRONOUS_PALETTE_UPDATES_DISABLE             0
#define NV_CTRL_SYNCHRONOUS_PALETTE_UPDATES_ENABLE              1

/*
 * NV_CTRL_DITHERING_DEPTH - Controls the dithering depth when
 * NV_CTRL_CURRENT_DITHERING is ENABLED.  Some displays connected
 * to the GPU via the DVI or LVDS interfaces cannot display the
 * full color range of ten bits per channel, so the GPU will
 * dither to either 6 or 8 bits per channel.
 */
#define NV_CTRL_DITHERING_DEPTH                                 368 /* RWDG */
#define NV_CTRL_DITHERING_DEPTH_AUTO                            0
#define NV_CTRL_DITHERING_DEPTH_6_BITS                          1
#define NV_CTRL_DITHERING_DEPTH_8_BITS                          2

/*
 * NV_CTRL_CURRENT_DITHERING_DEPTH - Returns the current dithering
 * depth value.
 */
#define NV_CTRL_CURRENT_DITHERING_DEPTH                         369 /* R-DG */
#define NV_CTRL_CURRENT_DITHERING_DEPTH_NONE                    0
#define NV_CTRL_CURRENT_DITHERING_DEPTH_6_BITS                  1
#define NV_CTRL_CURRENT_DITHERING_DEPTH_8_BITS                  2

/*
 * NV_CTRL_3D_VISION_PRO_TRANSCEIVER_CHANNEL_FREQUENCY - Returns the
 * frequency of the channel(in kHz) of the 3D Vision Pro transceiver.
 * Use the display_mask parameter to specify the channel number.
 */
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_CHANNEL_FREQUENCY     370 /* R--T */

/*
 * NV_CTRL_3D_VISION_PRO_TRANSCEIVER_CHANNEL_QUALITY - Returns the
 * quality of the channel(in percentage) of the 3D Vision Pro transceiver.
 * Use the display_mask parameter to specify the channel number.
 */
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_CHANNEL_QUALITY       371 /* R--T */

/*
 * NV_CTRL_3D_VISION_PRO_TRANSCEIVER_CHANNEL_COUNT - Returns the number of
 * channels on the 3D Vision Pro transceiver.
 */
#define NV_CTRL_3D_VISION_PRO_TRANSCEIVER_CHANNEL_COUNT         372 /* R--T */

/*
 * NV_CTRL_3D_VISION_PRO_PAIR_GLASSES - Puts the 3D Vision Pro
 * transceiver into pairing mode to gather additional glasses.
 * NV_CTRL_3D_VISION_PRO_PAIR_GLASSES_STOP - stops any pairing
 * NV_CTRL_3D_VISION_PRO_PAIR_GLASSES_BEACON - starts continuous
 *     pairing via beacon mode
 * Any other value, N - Puts the 3D Vision Pro transceiver into
 *     authenticated pairing mode for N seconds.
 */
#define NV_CTRL_3D_VISION_PRO_PAIR_GLASSES                      373 /* -W-T */
#define NV_CTRL_3D_VISION_PRO_PAIR_GLASSES_STOP                 0
#define NV_CTRL_3D_VISION_PRO_PAIR_GLASSES_BEACON               0xFFFFFFFF

/*
 * NV_CTRL_3D_VISION_PRO_UNPAIR_GLASSES - Tells a specific pair
 * of glasses to unpair. The glasses will "forget" the address
 * of the 3D Vision Pro transceiver to which they have been paired.
 * To unpair all the currently paired glasses, specify
 * the glasses id as 0.
 */
#define NV_CTRL_3D_VISION_PRO_UNPAIR_GLASSES                    374 /* -W-T */

/*
 * NV_CTRL_3D_VISION_PRO_DISCOVER_GLASSES - Tells the 3D Vision Pro
 * transceiver about the glasses that have been paired using
 * NV_CTRL_3D_VISION_PRO_PAIR_GLASSES_BEACON. Unless this is done,
 * the 3D Vision Pro transceiver will not know about glasses paired in
 * beacon mode.
 */
#define NV_CTRL_3D_VISION_PRO_DISCOVER_GLASSES                  375 /* -W-T */

/*
 * NV_CTRL_3D_VISION_PRO_IDENTIFY_GLASSES - Causes glasses LEDs to
 * flash for a short period of time.
 */
#define NV_CTRL_3D_VISION_PRO_IDENTIFY_GLASSES                  376 /* -W-T */

/*
 * NV_CTRL_3D_VISION_PRO_GLASSES_SYNC_CYCLE - Controls the
 * sync cycle duration(in milliseconds) of the glasses.
 * Use the display_mask parameter to specify the glasses id.
 */
#define NV_CTRL_3D_VISION_PRO_GLASSES_SYNC_CYCLE                378 /* RW-T */

/*
 * NV_CTRL_3D_VISION_PRO_GLASSES_MISSED_SYNC_CYCLES - Returns the
 * number of state sync cycles recently missed by the glasses.
 * Use the display_mask parameter to specify the glasses id.
 */
#define NV_CTRL_3D_VISION_PRO_GLASSES_MISSED_SYNC_CYCLES        379 /* R--T */

/*
 * NV_CTRL_3D_VISION_PRO_GLASSES_BATTERY_LEVEL - Returns the
 * battery level(in percentage) of the glasses.
 * Use the display_mask parameter to specify the glasses id.
 */
#define NV_CTRL_3D_VISION_PRO_GLASSES_BATTERY_LEVEL             380 /* R--T */


/*
 * NV_CTRL_GVO_ANC_PARITY_COMPUTATION - Controls the SDI device's computation
 * of the parity bit (bit 8) for ANC data words.
 */

#define NV_CTRL_GVO_ANC_PARITY_COMPUTATION                      381 /* RW--- */
#define NV_CTRL_GVO_ANC_PARITY_COMPUTATION_AUTO                   0
#define NV_CTRL_GVO_ANC_PARITY_COMPUTATION_ON                     1
#define NV_CTRL_GVO_ANC_PARITY_COMPUTATION_OFF                    2

/*
 * NV_CTRL_3D_VISION_PRO_GLASSES_PAIR_EVENT - This attribute is sent
 * as an event when glasses get paired in response to pair command 
 * from any of the clients.
 */
#define NV_CTRL_3D_VISION_PRO_GLASSES_PAIR_EVENT                382 /* ---T */

/*
 * NV_CTRL_3D_VISION_PRO_GLASSES_UNPAIR_EVENT - This attribute is sent
 * as an event when glasses get unpaired in response to unpair command
 * from any of the clients.
 */
#define NV_CTRL_3D_VISION_PRO_GLASSES_UNPAIR_EVENT              383 /* ---T */

/* 
 * NV_CTRL_GPU_PCIE_CURRENT_LINK_WIDTH - returns the current
 * PCIe link width, in number of lanes.
 */
#define NV_CTRL_GPU_PCIE_CURRENT_LINK_WIDTH                     384 /* R--GI */

/* 
 * NV_CTRL_GPU_PCIE_CURRENT_LINK_SPEED - returns the current
 * PCIe link speed, in megatransfers per second (GT/s).
 */
#define NV_CTRL_GPU_PCIE_CURRENT_LINK_SPEED                     385 /* R--GI */

/*
 * NV_CTRL_GVO_AUDIO_BLANKING - specifies whether the GVO device should delete
 * audio ancillary data packets when frames are repeated.
 *
 * When a new frame is not ready in time, the current frame, including all
 * ancillary data packets, is repeated.  When this data includes audio packets,
 * this can result in stutters or clicks.  When this option is enabled, the GVO
 * device will detect when frames are repeated, identify audio ancillary data
 * packets, and mark them for deletion.
 *
 * This option is applied when the GVO device is bound.
 */
#define NV_CTRL_GVO_AUDIO_BLANKING                              386 /* RW- */
#define NV_CTRL_GVO_AUDIO_BLANKING_DISABLE                        0
#define NV_CTRL_GVO_AUDIO_BLANKING_ENABLE                         1

/*
 * NV_CTRL_CURRENT_METAMODE_ID - switch modes to the MetaMode with
 * the specified ID.
 */
#define NV_CTRL_CURRENT_METAMODE_ID                             387 /* RW- */

/*
 * NV_CTRL_DISPLAY_ENABLED - Returns whether or not the display device
 * is currently enabled.
 */
#define NV_CTRL_DISPLAY_ENABLED                                 388 /* R-D */
#define NV_CTRL_DISPLAY_ENABLED_TRUE                              1
#define NV_CTRL_DISPLAY_ENABLED_FALSE                             0


#define NV_CTRL_LAST_ATTRIBUTE NV_CTRL_DISPLAY_ENABLED

/**************************************************************************/

/*
 * String Attributes:
 *
 * String attributes can be queryied through the XNVCTRLQueryStringAttribute()
 * and XNVCTRLQueryTargetStringAttribute() function calls.
 * 
 * String attributes can be set through the XNVCTRLSetStringAttribute()
 * function call.  (There are currently no string attributes that can be
 * set on non-X Screen targets.)
 *
 * Unless otherwise noted, all string attributes can be queried/set using an
 * NV_CTRL_TARGET_TYPE_X_SCREEN target.  Attributes that cannot take an
 * NV_CTRL_TARGET_TYPE_X_SCREEN target also cannot be queried/set through
 * XNVCTRLQueryStringAttribute()/XNVCTRLSetStringAttribute() (Since
 * these assume an X Screen target).
 */


/*
 * NV_CTRL_STRING_PRODUCT_NAME - the GPU product name on which the
 * specified X screen is running.
 *
 * This attribute may be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_STRING_PRODUCT_NAME                             0  /* R--G */


/*
 * NV_CTRL_STRING_VBIOS_VERSION - the video bios version on the GPU on
 * which the specified X screen is running.
 */

#define NV_CTRL_STRING_VBIOS_VERSION                            1  /* R--G */


/*
 * NV_CTRL_STRING_NVIDIA_DRIVER_VERSION - string representation of the
 * NVIDIA driver version number for the NVIDIA X driver in use.
 */

#define NV_CTRL_STRING_NVIDIA_DRIVER_VERSION                    3  /* R--G */


/*
 * NV_CTRL_STRING_DISPLAY_DEVICE_NAME - name of the display device
 * specified in the display_mask argument.
 *
 * This attribute may be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_STRING_DISPLAY_DEVICE_NAME                      4  /* R-DG */


/*
 * NV_CTRL_STRING_TV_ENCODER_NAME - name of the TV encoder used by the
 * specified display device; only valid if the display device is a TV.
 */

#define NV_CTRL_STRING_TV_ENCODER_NAME                          5  /* R-DG */


/*
 * NV_CTRL_STRING_GVIO_FIRMWARE_VERSION - indicates the version of the
 * Firmware on the GVIO device.
 */

#define NV_CTRL_STRING_GVIO_FIRMWARE_VERSION                    8  /* R--I */

/*
 * The following is deprecated; use NV_CTRL_STRING_GVIO_FIRMWARE_VERSION,
 * instead
 */
#define NV_CTRL_STRING_GVO_FIRMWARE_VERSION                     8  /* R-- */


/* 
 * NV_CTRL_STRING_CURRENT_MODELINE - Return the ModeLine currently
 * being used by the specified display device.
 *
 * This attribute may be queried through XNVCTRLQueryTargetStringAttribute()
 * using an NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 *
 * The ModeLine string may be prepended with a comma-separated list of
 * "token=value" pairs, separated from the ModeLine string by "::".
 * This "token=value" syntax is the same as that used in
 * NV_CTRL_BINARY_DATA_MODELINES
 */

#define NV_CTRL_STRING_CURRENT_MODELINE                         9   /* R-DG */


/* 
 * NV_CTRL_STRING_ADD_MODELINE - Adds a ModeLine to the specified
 * display device.  The ModeLine is not added if validation fails.
 *
 * The ModeLine string should have the same syntax as a ModeLine in
 * the X configuration file; e.g.,
 *
 * "1600x1200"  229.5  1600 1664 1856 2160  1200 1201 1204 1250  +HSync +VSync
 */

#define NV_CTRL_STRING_ADD_MODELINE                            10   /* -WDG */


/*
 * NV_CTRL_STRING_DELETE_MODELINE - Deletes an existing ModeLine
 * from the specified display device.  The currently selected
 * ModeLine cannot be deleted.  (This also means you cannot delete
 * the last ModeLine.)
 *
 * The ModeLine string should have the same syntax as a ModeLine in
 * the X configuration file; e.g.,
 *
 * "1600x1200"  229.5  1600 1664 1856 2160  1200 1201 1204 1250  +HSync +VSync
 */

#define NV_CTRL_STRING_DELETE_MODELINE                         11   /* -WDG */


/* 
 * NV_CTRL_STRING_CURRENT_METAMODE - Returns the metamode currently
 * being used by the specified X screen.  The MetaMode string has the
 * same syntax as the MetaMode X configuration option, as documented
 * in the NVIDIA driver README.
 *
 * The returned string may be prepended with a comma-separated list of
 * "token=value" pairs, separated from the MetaMode string by "::".
 * This "token=value" syntax is the same as that used in
 * NV_CTRL_BINARY_DATA_METAMODES.
 */

#define NV_CTRL_STRING_CURRENT_METAMODE                        12   /* RW-- */
#define NV_CTRL_STRING_CURRENT_METAMODE_VERSION_1 \
    NV_CTRL_STRING_CURRENT_METAMODE



/* 
 * NV_CTRL_STRING_ADD_METAMODE - Adds a MetaMode to the specified
 * X Screen.
 *
 * It is recommended to not use this attribute, but instead use
 * NV_CTRL_STRING_OPERATION_ADD_METAMODE.
 */

#define NV_CTRL_STRING_ADD_METAMODE                            13   /* -W-- */


/*
 * NV_CTRL_STRING_DELETE_METAMODE - Deletes an existing MetaMode from
 * the specified X Screen.  The currently selected MetaMode cannot be
 * deleted.  (This also means you cannot delete the last MetaMode).
 * The MetaMode string should have the same syntax as the MetaMode X
 * configuration option, as documented in the NVIDIA driver README.
 */

#define NV_CTRL_STRING_DELETE_METAMODE                         14   /* -WD-- */


/*
 * NV_CTRL_STRING_VCSC_PRODUCT_NAME - Querys the product name of the
 * VCSC device.
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 */

#define NV_CTRL_STRING_VCSC_PRODUCT_NAME                       15   /* R---V */


/*
 * NV_CTRL_STRING_VCSC_PRODUCT_ID - Querys the product ID of the VCSC device.
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 */

#define NV_CTRL_STRING_VCSC_PRODUCT_ID                         16   /* R---V */


/*
 * NV_CTRL_STRING_VCSC_SERIAL_NUMBER - Querys the unique serial number
 * of the VCS device.
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 */

#define NV_CTRL_STRING_VCSC_SERIAL_NUMBER                      17   /* R---V */


/*
 * NV_CTRL_STRING_VCSC_BUILD_DATE - Querys the date of the VCS device.
 * the returned string is in the following format: "Week.Year"
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 */

#define NV_CTRL_STRING_VCSC_BUILD_DATE                         18   /* R---V */


/*
 * NV_CTRL_STRING_VCSC_FIRMWARE_VERSION - Querys the firmware version
 * of the VCS device.
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 */

#define NV_CTRL_STRING_VCSC_FIRMWARE_VERSION                   19   /* R---V */


/*
 * NV_CTRL_STRING_VCSC_FIRMWARE_REVISION - Querys the firmware revision
 * of the VCS device.
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCS target.
 */

#define NV_CTRL_STRING_VCSC_FIRMWARE_REVISION                  20   /* R---V */


/*
 * NV_CTRL_STRING_VCSC_HARDWARE_VERSION - Querys the hardware version
 * of the VCS device.
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 */

#define NV_CTRL_STRING_VCSC_HARDWARE_VERSION                   21   /* R---V */


/*
 * NV_CTRL_STRING_VCSC_HARDWARE_REVISION - Querys the hardware revision
 * of the VCS device.
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 */

#define NV_CTRL_STRING_VCSC_HARDWARE_REVISION                  22   /* R---V */


/* 
 * NV_CTRL_STRING_MOVE_METAMODE - Moves a MetaMode to the specified
 * index location.  The MetaMode must already exist in the X Screen's
 * list of MetaModes (as returned by the NV_CTRL_BINARY_DATA_METAMODES
 * attribute).  If the index is larger than the number of MetaModes in
 * the list, the MetaMode is moved to the end of the list.  The
 * MetaMode string should have the same syntax as the MetaMode X
 * configuration option, as documented in the NVIDIA driver README.

 * The MetaMode string must be prepended with a comma-separated list
 * of "token=value" pairs, separated from the MetaMode string by "::".
 * Currently, the only valid token is "index", which indicates where
 * in the MetaMode list the MetaMode should be moved to.
 *
 * Other tokens may be added in the future.
 *
 * E.g.,
 *  "index=5 :: CRT-0: 1024x768 @1024x768 +0+0"
 */

#define NV_CTRL_STRING_MOVE_METAMODE                           23   /* -W-- */


/*
 * NV_CTRL_STRING_VALID_HORIZ_SYNC_RANGES - returns the valid
 * horizontal sync ranges used to perform mode validation for the
 * specified display device.  The ranges are in the same format as the
 * "HorizSync" X config option:
 *
 *   "horizsync-range may be a comma separated list of either discrete
 *   values or ranges of values.  A range of values is two values
 *   separated by a dash."
 *
 * The values are in kHz.
 *
 * Additionally, the string may be prepended with a comma-separated
 * list of "token=value" pairs, separated from the HorizSync string by
 * "::".  Valid tokens:
 *
 *    Token     Value
 *   "source"  "edid"     - HorizSync is from the display device's EDID
 *             "xconfig"  - HorizSync is from the "HorizSync" entry in
 *                          the Monitor section of the X config file
 *             "option"   - HorizSync is from the "HorizSync" NVIDIA X
 *                          config option
 *             "twinview" - HorizSync is from the "SecondMonitorHorizSync"
 *                          NVIDIA X config option
 *             "builtin"  - HorizSync is from NVIDIA X driver builtin
 *                          default values
 *
 * Additional tokens and/or values may be added in the future.
 *
 * Example: "source=edid :: 30.000-62.000"
 */

#define NV_CTRL_STRING_VALID_HORIZ_SYNC_RANGES                 24   /* R-DG */


/*
 * NV_CTRL_STRING_VALID_VERT_REFRESH_RANGES - returns the valid
 * vertical refresh ranges used to perform mode validation for the
 * specified display device.  The ranges are in the same format as the
 * "VertRefresh" X config option:
 *
 *   "vertrefresh-range may be a comma separated list of either discrete
 *    values or ranges of values.  A range of values is two values
 *    separated by a dash."
 *
 * The values are in Hz.
 *
 * Additionally, the string may be prepended with a comma-separated
 * list of "token=value" pairs, separated from the VertRefresh string by
 * "::".  Valid tokens:
 *
 *    Token     Value
 *   "source"  "edid"     - VertRefresh is from the display device's EDID
 *             "xconfig"  - VertRefresh is from the "VertRefresh" entry in
 *                          the Monitor section of the X config file
 *             "option"   - VertRefresh is from the "VertRefresh" NVIDIA X
 *                          config option
 *             "twinview" - VertRefresh is from the "SecondMonitorVertRefresh"
 *                          NVIDIA X config option
 *             "builtin"  - VertRefresh is from NVIDIA X driver builtin
 *                          default values
 *
 * Additional tokens and/or values may be added in the future.
 *
 * Example: "source=edid :: 50.000-75.000"
 */

#define NV_CTRL_STRING_VALID_VERT_REFRESH_RANGES               25   /* R-DG */


/*
 * NV_CTRL_STRING_XINERAMA_SCREEN_INFO - returns the physical X Screen's
 * initial position and size (in absolute coordinates) within the Xinerama
 * desktop as the "token=value" string:  "x=#, y=#, width=#, height=#"
 *
 * Querying this attribute returns FALSE if NV_CTRL_XINERAMA is not
 * NV_CTRL_XINERAMA_ON.
 */

#define NV_CTRL_STRING_XINERAMA_SCREEN_INFO                    26   /* R--- */


/*
 * NV_CTRL_STRING_TWINVIEW_XINERAMA_INFO_ORDER - used to specify the
 * order that display devices will be returned via Xinerama when
 * nvidiaXineramaInfo is enabled.  Follows the same syntax as the
 * nvidiaXineramaInfoOrder X config option.
 */

#define NV_CTRL_STRING_NVIDIA_XINERAMA_INFO_ORDER              27   /* RW-- */

#define NV_CTRL_STRING_TWINVIEW_XINERAMA_INFO_ORDER \
    NV_CTRL_STRING_NVIDIA_XINERAMA_INFO_ORDER /* for backwards compatibility: */

/*
 * NV_CTRL_STRING_SLI_MODE - returns a string describing the current
 * SLI mode, if any, or FALSE if SLI is not currently enabled.
 *
 * This string should be used for informational purposes only, and
 * should not be used to distinguish between SLI modes, other than to
 * recognize when SLI is disabled (FALSE is returned) or
 * enabled (the returned string is non-NULL and describes the current
 * SLI configuration).
 */

#define NV_CTRL_STRING_SLI_MODE                                28   /* R---*/


/*
 * NV_CTRL_STRING_PERFORMANCE_MODES - returns a string with all the
 * performance modes defined for this GPU along with their associated
 * NV Clock and Memory Clock values.
 *
 * Each performance modes are returned as a comma-separated list of
 * "token=value" pairs.  Each set of performance mode tokens are separated
 * by a ";".  Valid tokens:
 *
 *    Token      Value
 *   "perf"      integer   - the Performance level
 *   "nvclock"   integer   - the GPU clocks (in MHz) for the perf level
 *   "memclock"  integer   - the memory clocks (in MHz) for the perf level
 *
 *
 * Example:
 *
 *   perf=0, nvclock=500, memclock=505 ; perf=1, nvclock=650, memclock=505
 *
 * This attribute may be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_STRING_PERFORMANCE_MODES                      29   /* R--G */


/*
 * NV_CTRL_STRING_VCSC_FAN_STATUS - returns a string with status of all the
 * fans in the Visual Computing System, if such a query is supported.  Fan
 * information is reported along with its tachometer reading (in RPM) and a 
 * flag indicating whether the fan has failed or not.
 * 
 * Valid tokens:
 *
 *    Token      Value
 *   "fan"       integer   - the Fan index
 *   "speed"     integer   - the tachometer reading of the fan in rpm
 *   "fail"      integer   - flag to indicate whether the fan has failed
 *
 * Example:
 *
 *   fan=0, speed=694, fail=0 ; fan=1, speed=693, fail=0
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 *
 */

#define NV_CTRL_STRING_VCSC_FAN_STATUS                         30   /* R---V */


/*
 * NV_CTRL_STRING_VCSC_TEMPERATURES - returns a string with all Temperature
 * readings in the Visual Computing System, if such a query is supported.  
 * Intake, Exhaust and Board Temperature values are reported in Celcius.
 * 
 * Valid tokens:
 *
 *    Token      Value
 *   "intake"    integer   - the intake temperature for the VCS
 *   "exhaust"   integer   - the exhaust temperature for the VCS
 *   "board"     integer   - the board temperature of the VCS
 *
 * Example:
 *
 *   intake=29, exhaust=46, board=41
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 *
 */

#define NV_CTRL_STRING_VCSC_TEMPERATURES                       31   /* R---V */


/*
 * NV_CTRL_STRING_VCSC_PSU_INFO - returns a string with all Power Supply Unit
 * related readings in the Visual Computing System, if such a query is 
 * supported.  Current in amperes, Power in watts, Voltage in volts and PSU 
 * state may be reported.  Not all PSU types support all of these values, and
 * therefore some readings may be unknown.
 * 
 * Valid tokens:
 *
 *    Token      Value
 *   "current"   integer   - the current drawn in amperes by the VCS
 *   "power"     integer   - the power drawn in watts by the VCS
 *   "voltage"   integer   - the voltage reading of the VCS
 *   "state"     integer   - flag to indicate whether PSU is operating normally
 *
 * Example:
 *
 *   current=10, power=15, voltage=unknown, state=normal
 *
 * This attribute must be queried through XNVCTRLQueryTargetStringAttribute()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.
 *
 */


#define NV_CTRL_STRING_VCSC_PSU_INFO                           32   /* R---V */


/*
 * NV_CTRL_STRING_GVIO_VIDEO_FORMAT_NAME - query the name for the specified
 * NV_CTRL_GVIO_VIDEO_FORMAT_*.  So that this can be queried with existing
 * interfaces, XNVCTRLQueryStringAttribute() should be used, and the video
 * format specified in the display_mask field; eg:
 *
 * XNVCTRLQueryStringAttribute(dpy,
 *                             screen, 
 *                             NV_CTRL_GVIO_VIDEO_FORMAT_720P_60_00_SMPTE296,
 *                             NV_CTRL_GVIO_VIDEO_FORMAT_NAME,
 *                             &name);
 */

#define NV_CTRL_STRING_GVIO_VIDEO_FORMAT_NAME                  33  /* R--GI */

/*
 * The following is deprecated; use NV_CTRL_STRING_GVIO_VIDEO_FORMAT_NAME,
 * instead
 */
#define NV_CTRL_STRING_GVO_VIDEO_FORMAT_NAME                   33  /* R--- */


/*
 * NV_CTRL_STRING_GPU_CURRENT_CLOCK_FREQS - returns a string with the
 * associated NV Clock, Memory Clock and Processor Clock values.
 * 
 * Current valid tokens are "nvclock", "memclock", and "processorclock".
 * Not all tokens will be reported on all GPUs, and additional tokens
 * may be added in the future.
 *
 * Clock values are returned as a comma-separated list of
 * "token=value" pairs.
 * Valid tokens:
 *
 *    Token           Value
 *   "nvclock"        integer - the GPU clocks (in MHz) for the current
 *                              perf level
 *   "memclock"       integer - the memory clocks (in MHz) for the current
 *                              perf level
 *   "processorclock" integer - the processor clocks (in MHz) for the perf level
 *
 *
 * Example:
 *
 *    nvclock=459, memclock=400, processorclock=918
 *
 * This attribute may be queried through XNVCTRLQueryTargetStringAttribute()
 * using an NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_STRING_GPU_CURRENT_CLOCK_FREQS                 34  /* RW-G */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_HARDWARE_REVISION - Returns the
 * hardware revision of the 3D Vision Pro transceiver.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_HARDWARE_REVISION  35 /* R--T */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_FIRMWARE_VERSION_A - Returns the
 * firmware version of chip A of the 3D Vision Pro transceiver.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_FIRMWARE_VERSION_A 36 /* R--T */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_FIRMWARE_DATE_A - Returns the
 * date of the firmware of chip A of the 3D Vision Pro transceiver.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_FIRMWARE_DATE_A    37 /* R--T */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_FIRMWARE_VERSION_B - Returns the
 * firmware version of chip B of the 3D Vision Pro transceiver.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_FIRMWARE_VERSION_B 38 /* R--T */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_FIRMWARE_DATE_B - Returns the
 * date of the firmware of chip B of the 3D Vision Pro transceiver.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_FIRMWARE_DATE_B    39 /* R--T */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_ADDRESS - Returns the RF address
 * of the 3D Vision Pro transceiver.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_TRANSCEIVER_ADDRESS            40 /* R--T */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_GLASSES_FIRMWARE_VERSION_A - Returns the
 * firmware version of chip A of the glasses.
 * Use the display_mask parameter to specify the glasses id.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_GLASSES_FIRMWARE_VERSION_A     41 /* R--T */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_GLASSES_FIRMWARE_DATE_A - Returns the
 * date of the firmware of chip A of the glasses.
 * Use the display_mask parameter to specify the glasses id.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_GLASSES_FIRMWARE_DATE_A        42 /* R--T */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_GLASSES_ADDRESS - Returns the RF address
 * of the glasses.
 * Use the display_mask parameter to specify the glasses id.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_GLASSES_ADDRESS                43 /* R--T */

/*
 * NV_CTRL_STRING_3D_VISION_PRO_GLASSES_NAME - Controls the name the
 * glasses should use.
 * Use the display_mask parameter to specify the glasses id.
 * Glasses' name should start and end with an alpha-numeric character.
 */
#define NV_CTRL_STRING_3D_VISION_PRO_GLASSES_NAME                   44 /* RW-T */

/*
 * NV_CTRL_STRING_CURRENT_METAMODE_VERSION_2 - Returns the metamode currently
 * being used by the specified X screen.  The MetaMode string has the same
 * syntax as the MetaMode X configuration option, as documented in the NVIDIA
 * driver README.  Also, see NV_CTRL_BINARY_DATA_METAMODES_VERSION_2 for more
 * details on the base syntax.
 *
 * The returned string may also be prepended with a comma-separated list of
 * "token=value" pairs, separated from the MetaMode string by "::".
 */
#define NV_CTRL_STRING_CURRENT_METAMODE_VERSION_2                   45 /* RW-- */

/*
 * NV_CTRL_STRING_DISPLAY_NAME_TYPE_BASENAME - Returns a type name for the
 * display device ("CRT", "DFP", or "TV").  However, note that the determination
 * of the name is based on the protocol through which the X driver communicates
 * to the display device.  E.g., if the driver communicates using VGA ,then the
 * basename is "CRT"; if the driver communicates using TMDS, LVDS, or DP, then
 * the name is "DFP".
 */
#define NV_CTRL_STRING_DISPLAY_NAME_TYPE_BASENAME                   46 /* R-D- */

/*
 * NV_CTRL_STRING_DISPLAY_NAME_TYPE_ID - Returns the type-based name + ID for
 * the display device, e.g. "CRT-0", "DFP-1", "TV-2".  If this device is a
 * DisplayPort 1.2 device, then this name will also be prepended with the
 * device's port address like so: "DFP-1.0.1.2.3".  See
 * NV_CTRL_STRING_DISPLAY_NAME_TYPE_BASENAME for more information about the
 * construction of type-based names.
 */
#define NV_CTRL_STRING_DISPLAY_NAME_TYPE_ID                         47 /* R-D- */

/*
 * NV_CTRL_STRING_DISPLAY_NAME_DP_GUID - Returns the GUID of the DisplayPort
 * display device.  e.g. "DP-GUID-f16a5bde-79f3-11e1-b2ae-8b5a8969ba9c"
 *
 * The display device must be a DisplayPort 1.2 device.
 */
#define NV_CTRL_STRING_DISPLAY_NAME_DP_GUID                         48 /* R-D- */

/*
 * NV_CTRL_STRING_DISPLAY_NAME_EDID_HASH - Returns the SHA-1 hash of the
 * display device's EDID in 8-4-4-4-12 UID format. e.g.
 * "DPY-EDID-f16a5bde-79f3-11e1-b2ae-8b5a8969ba9c"
 *
 * The display device must have a valid EDID.
 */
#define NV_CTRL_STRING_DISPLAY_NAME_EDID_HASH                       49 /* R-D- */

/*
 * NV_CTRL_STRING_DISPLAY_NAME_TARGET_INDEX - Returns the current NV-CONTROL
 * target ID (name) of the display device.  e.g. "DPY-1", "DPY-4"
 *
 * This name for the display device is not guarenteed to be the same between
 * different runs of the X server.
 */
#define NV_CTRL_STRING_DISPLAY_NAME_TARGET_INDEX                    50 /* R-D- */

/*
 * NV_CTRL_STRING_DISPLAY_NAME_RANDR - Returns the RandR output name for the
 * display device.  e.g.  "VGA-1", "DVI-I-0", "DVI-D-3", "LVDS-1", "DP-2",
 * "HDMI-3", "eDP-6".  This name should match  If this device is a DisplayPort
 * 1.2 device, then this name will also be prepended with the device's port
 * address like so: "DVI-I-3.0.1.2.3"
 */
#define NV_CTRL_STRING_DISPLAY_NAME_RANDR                           51 /* R-D- */

#define NV_CTRL_STRING_LAST_ATTRIBUTE \
    NV_CTRL_STRING_DISPLAY_NAME_RANDR


/**************************************************************************/

/*
 * Binary Data Attributes:
 *
 * Binary data attributes can be queryied through the XNVCTRLQueryBinaryData()
 * and XNVCTRLQueryTargetBinaryData() function calls.
 * 
 * There are currently no binary data attributes that can be set.
 *
 * Unless otherwise noted, all Binary data attributes can be queried
 * using an NV_CTRL_TARGET_TYPE_X_SCREEN target.  Attributes that cannot take
 * an NV_CTRL_TARGET_TYPE_X_SCREEN target also cannot be queried through
 * XNVCTRLQueryBinaryData() (Since an X Screen target is assumed).
 */


/*
 * NV_CTRL_BINARY_DATA_EDID - Returns a display device's EDID information
 * data.
 *
 * This attribute may be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_BINARY_DATA_EDID                                0  /* R-DG */


/* 
 * NV_CTRL_BINARY_DATA_MODELINES - Returns a display device's supported
 * ModeLines.  ModeLines are returned in a buffer, separated by a single
 * '\0' and terminated by two consecutive '\0' s like so:
 *
 *  "ModeLine 1\0ModeLine 2\0ModeLine 3\0Last ModeLine\0\0"
 *
 * This attribute may be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_GPU or NV_CTRL_TARGET_TYPE_X_SCREEN target.
 *
 * Each ModeLine string may be prepended with a comma-separated list
 * of "token=value" pairs, separated from the ModeLine string with a
 * "::".  Valid tokens:
 *
 *    Token    Value
 *   "source" "xserver"    - the ModeLine is from the core X server
 *            "xconfig"    - the ModeLine was specified in the X config file
 *            "builtin"    - the NVIDIA driver provided this builtin ModeLine
 *            "vesa"       - this is a VESA standard ModeLine
 *            "edid"       - the ModeLine was in the display device's EDID
 *            "nv-control" - the ModeLine was specified via NV-CONTROL
 *            
 *   "xconfig-name"        - for ModeLines that were specified in the X config
 *                           file, this is the name the X config file
 *                           gave for the ModeLine.
 *
 * Note that a ModeLine can have several sources; the "source" token
 * can appear multiple times in the "token=value" pairs list.
 * Additional source values may be specified in the future.
 *
 * Additional tokens may be added in the future, so it is recommended
 * that any token parser processing the returned string from
 * NV_CTRL_BINARY_DATA_MODELINES be implemented to gracefully ignore
 * unrecognized tokens.
 *
 * E.g.,
 *
 * "source=xserver, source=vesa, source=edid :: "1024x768_70"  75.0  1024 1048 1184 1328  768 771 777 806  -HSync -VSync"
 * "source=xconfig, xconfig-name=1600x1200_60.00 :: "1600x1200_60_0"  161.0  1600 1704 1880 2160  1200 1201 1204 1242  -HSync +VSync"
 */

#define NV_CTRL_BINARY_DATA_MODELINES                           1   /* R-DG */


/* 
 * NV_CTRL_BINARY_DATA_METAMODES - Returns an X Screen's supported
 * MetaModes.  MetaModes are returned in a buffer separated by a
 * single '\0' and terminated by two consecutive '\0' s like so:
 *
 *  "MetaMode 1\0MetaMode 2\0MetaMode 3\0Last MetaMode\0\0"
 *
 * The MetaMode string should have the same syntax as the MetaMode X
 * configuration option, as documented in the NVIDIA driver README.

 * Each MetaMode string may be prepended with a comma-separated list
 * of "token=value" pairs, separated from the MetaMode string with
 * "::".  Currently, valid tokens are:
 *
 *    Token        Value
 *   "id"         <number>     - the id of this MetaMode; this is stored in
 *                               the Vertical Refresh field, as viewed
 *                               by the XRandR and XF86VidMode X *
 *                               extensions.
 *
 *   "switchable" "yes"/"no"   - whether this MetaMode may be switched to via
 *                               ctrl-alt-+/-; Implicit MetaModes (see
 *                               the "IncludeImplicitMetaModes" X
 *                               config option), for example, are not
 *                               normally made available through
 *                               ctrl-alt-+/-.
 *
 *   "source"     "xconfig"    - the MetaMode was specified in the X
 *                               config file.
 *                "implicit"   - the MetaMode was implicitly added; see the
 *                               "IncludeImplicitMetaModes" X config option
 *                               for details.
 *                "nv-control" - the MetaMode was added via the NV-CONTROL X
 *                               extension to the currently running X server.
 *                "RandR"      - the MetaMode was modified in response to an
 *                               RandR RRSetCrtcConfig request.
 *
 * Additional tokens may be added in the future, so it is recommended
 * that any token parser processing the returned string from
 * NV_CTRL_BINARY_DATA_METAMODES be implemented to gracefully ignore
 * unrecognized tokens.
 *
 * E.g.,
 *
 *   "id=50, switchable=yes, source=xconfig :: CRT-0: 1024x768 @1024x768 +0+0"
 */

#define NV_CTRL_BINARY_DATA_METAMODES                           2   /* R-D- */
#define NV_CTRL_BINARY_DATA_METAMODES_VERSION_1 \
    NV_CTRL_BINARY_DATA_METAMODES


/*
 * NV_CTRL_BINARY_DATA_XSCREENS_USING_GPU - Returns the list of X
 * screens currently driven by the given GPU.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of screens
 *     4 * n   CARD32 screen indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_GPU target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN.
 */

#define NV_CTRL_BINARY_DATA_XSCREENS_USING_GPU                  3   /* R-DG */


/*
 * NV_CTRL_BINARY_DATA_GPUS_USED_BY_XSCREEN - Returns the list of GPUs
 * currently in use by the given X screen.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of GPUs
 *     4 * n   CARD32 GPU indices
 */

#define NV_CTRL_BINARY_DATA_GPUS_USED_BY_XSCREEN                4   /* R--- */


/*
 * NV_CTRL_BINARY_DATA_GPUS_USING_FRAMELOCK - Returns the list of
 * GPUs currently connected to the given frame lock board.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of GPUs
 *     4 * n   CARD32 GPU indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_FRAMELOCK target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN.
 */

#define NV_CTRL_BINARY_DATA_GPUS_USING_FRAMELOCK                5   /* R-DF */


/*
 * NV_CTRL_BINARY_DATA_DISPLAY_VIEWPORT - Returns the Display Device's
 * viewport box into the given X Screen (in X Screen coordinates.)
 *
 * The format of the returned data is:
 *
 *     4       CARD32 Offset X
 *     4       CARD32 Offset Y
 *     4       CARD32 Width
 *     4       CARD32 Height
 */

#define NV_CTRL_BINARY_DATA_DISPLAY_VIEWPORT                    6   /* R-DG */


/*
 * NV_CTRL_BINARY_DATA_FRAMELOCKS_USED_BY_GPU - Returns the list of
 * Framelock devices currently connected to the given GPU.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of Framelocks
 *     4 * n   CARD32 Framelock indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_GPU target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN.
 */

#define NV_CTRL_BINARY_DATA_FRAMELOCKS_USED_BY_GPU              7   /* R-DG */


/*
 * NV_CTRL_BINARY_DATA_GPUS_USING_VCSC - Returns the list of
 * GPU devices connected to the given VCS.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of GPUs
 *     4 * n   CARD32 GPU indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_VCSC target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN and cannot be queried using
 * a  NV_CTRL_TARGET_TYPE_X_GPU
 */

#define NV_CTRL_BINARY_DATA_GPUS_USING_VCSC                    8   /* R-DV */


/*
 * NV_CTRL_BINARY_DATA_VCSCS_USED_BY_GPU - Returns the VCSC device
 * that is controlling the given GPU.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of VCS (always 1)
 *     4 * n   CARD32 VCS indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_GPU target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN
 */

#define NV_CTRL_BINARY_DATA_VCSCS_USED_BY_GPU                  9   /* R-DG */


/*
 * NV_CTRL_BINARY_DATA_COOLERS_USED_BY_GPU - Returns the coolers that
 * are cooling the given GPU.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of COOLER
 *     4 * n   CARD32 COOLER indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_GPU target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN
 */

#define NV_CTRL_BINARY_DATA_COOLERS_USED_BY_GPU                10  /* R-DG */


/*
 * NV_CTRL_BINARY_DATA_GPUS_USED_BY_LOGICAL_XSCREEN - Returns the list of
 * GPUs currently driving the given X screen.  If Xinerama is enabled, this
 * will return all GPUs that are driving any X screen.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of GPUs
 *     4 * n   CARD32 GPU indices
 */

#define NV_CTRL_BINARY_DATA_GPUS_USED_BY_LOGICAL_XSCREEN     11   /* R--- */

/*
 * NV_CTRL_BINARY_DATA_THERMAL_SENSORS_USED_BY_GPU - Returns the sensors that
 * are attached to the given GPU.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of SENSOR
 *     4 * n   CARD32 SENSOR indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_GPU target.  This attribute cannot be
 * queried using a NV_CTRL_TARGET_TYPE_X_SCREEN
 */

#define NV_CTRL_BINARY_DATA_THERMAL_SENSORS_USED_BY_GPU      12  /* R--G */

/*
 * NV_CTRL_BINARY_DATA_GLASSES_PAIRED_TO_3D_VISION_PRO_TRANSCEIVER - Returns
 * the id of the glasses that are currently paired to the given
 * 3D Vision Pro transceiver.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of glasses
 *     4 * n   CARD32 id of glasses
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_3D_VISION_PRO_TRANSCEIVER target.
 */
#define NV_CTRL_BINARY_DATA_GLASSES_PAIRED_TO_3D_VISION_PRO_TRANSCEIVER 13 /* R--T */

/*
 * NV_CTRL_BINARY_DATA_DISPLAY_TARGETS - Returns all the display devices
 * currently connected to any GPU on the X server.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of display devices
 *     4 * n   CARD32 display device indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData().
 */

#define NV_CTRL_BINARY_DATA_DISPLAY_TARGETS                  14  /* R--- */

/*
 * NV_CTRL_BINARY_DATA_DISPLAYS_CONNECTED_TO_GPU - Returns the list of
 * display devices that are connected to the GPU target.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of display devices
 *     4 * n   CARD32 display device indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_GPU target.
 */

#define NV_CTRL_BINARY_DATA_DISPLAYS_CONNECTED_TO_GPU        15  /* R--G */

/*
 * NV_CTRL_BINARY_DATA_METAMODES_VERSION_2  - Returns values similar to
 * NV_CTRL_BINARY_DATA_METAMODES(_VERSION_1) but also returns extended syntax
 * information to indicate a specific display device, as well as other per-
 * display deviceflags as "token=value" pairs.  For example:
 *
 *   "DPY-1: 1280x1024 {Stereo=PassiveLeft},
 *    DPY-2: 1280x1024 {Stereo=PassiveRight},"
 *
 * The display device names have the form "DPY-%d", where the integer
 * part of the name is the NV-CONTROL target ID for that display device
 * for this instance of the X server.  Note that display device NV-CONTROL
 * target IDs are not guaranteed to be the same from one run of the X
 * server to the next.
 */

#define NV_CTRL_BINARY_DATA_METAMODES_VERSION_2              16  /* R-D- */

/*
 * NV_CTRL_BINARY_DATA_DISPLAYS_ENABLED_ON_XSCREEN - Returns the list of
 * display devices that are currently scanning out the X screen target.
 *
 * The format of the returned data is:
 *
 *     4       CARD32 number of display devices
 *     4 * n   CARD32 display device indices
 *
 * This attribute can only be queried through XNVCTRLQueryTargetBinaryData()
 * using a NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */

#define NV_CTRL_BINARY_DATA_DISPLAYS_ENABLED_ON_XSCREEN      17  /* R--- */


#define NV_CTRL_BINARY_DATA_LAST_ATTRIBUTE \
        NV_CTRL_BINARY_DATA_DISPLAYS_ENABLED_ON_XSCREEN


/**************************************************************************/

/*
 * String Operation Attributes:
 *
 * These attributes are used with the XNVCTRLStringOperation()
 * function; a string is specified as input, and a string is returned
 * as output.
 *
 * Unless otherwise noted, all attributes can be operated upon using
 * an NV_CTRL_TARGET_TYPE_X_SCREEN target.
 */


/*
 * NV_CTRL_STRING_OPERATION_ADD_METAMODE - provide a MetaMode string
 * as input, and returns a string containing comma-separated list of
 * "token=value" pairs as output.  Currently, the only output token is
 * "id", which indicates the id that was assigned to the MetaMode.
 *
 * All ModeLines referenced in the MetaMode must already exist for
 * each display device (as returned by the
 * NV_CTRL_BINARY_DATA_MODELINES attribute).
 *
 * The MetaMode string should have the same syntax as the MetaMode X
 * configuration option, as documented in the NVIDIA driver README.
 *
 * The input string can optionally be prepended with a string of
 * comma-separated "token=value" pairs, separated from the MetaMode
 * string by "::".  Currently, the only valid token is "index" which
 * indicates the insertion index for the MetaMode.
 *
 * E.g.,
 *
 * Input: "index=5 :: 1600x1200+0+0, 1600x1200+1600+0"
 * Output: "id=58"
 *
 * which causes the MetaMode to be inserted at position 5 in the
 * MetaMode list (all entries after 5 will be shifted down one slot in
 * the list), and the X server's containing mode stores 58 as the
 * VRefresh, so that the MetaMode can be uniquely identifed through
 * XRandR and XF86VidMode.
 */

#define NV_CTRL_STRING_OPERATION_ADD_METAMODE                  0


/*
 * NV_CTRL_STRING_OPERATION_GTF_MODELINE - provide as input a string
 * of comma-separated "token=value" pairs, and returns a ModeLine
 * string, computed using the GTF formula using the parameters from
 * the input string.  Valid tokens for the input string are "width",
 * "height", and "refreshrate".
 *
 * E.g.,
 *
 * Input: "width=1600, height=1200, refreshrate=60"
 * Output: "160.96  1600 1704 1880 2160  1200 1201 1204 1242  -HSync +VSync"
 *
 * This operation does not have any impact on any display device's
 * modePool, and the ModeLine is not validated; it is simply intended
 * for generating ModeLines.
 */

#define NV_CTRL_STRING_OPERATION_GTF_MODELINE                  1


/*
 * NV_CTRL_STRING_OPERATION_CVT_MODELINE - provide as input a string
 * of comma-separated "token=value" pairs, and returns a ModeLine
 * string, computed using the CVT formula using the parameters from
 * the input string.  Valid tokens for the input string are "width",
 * "height", "refreshrate", and "reduced-blanking".  The
 * "reduced-blanking" argument can be "0" or "1", to enable or disable
 * use of reduced blanking for the CVT formula.
 *
 * E.g.,
 *
 * Input: "width=1600, height=1200, refreshrate=60, reduced-blanking=1"
 * Output: "130.25  1600 1648 1680 1760  1200 1203 1207 1235  +HSync -VSync"
 *
 * This operation does not have any impact on any display device's
 * modePool, and the ModeLine is not validated; it is simply intended
 * for generating ModeLines.
 */

#define NV_CTRL_STRING_OPERATION_CVT_MODELINE                  2


/*
 * NV_CTRL_STRING_OPERATION_BUILD_MODEPOOL - build a ModePool for the
 * specified display device on the specified target (either an X
 * screen or a GPU).  This is typically used to generate a ModePool
 * for a display device on a GPU on which no X screens are present.
 *
 * Currently, a display device's ModePool is static for the life of
 * the X server, so XNVCTRLStringOperation will return FALSE if
 * requested to build a ModePool on a display device that already has
 * a ModePool.
 *
 * The string input to BUILD_MODEPOOL may be NULL.  If it is not NULL,
 * then it is interpreted as a double-colon ("::") separated list
 * of "option=value" pairs, where the options and the syntax of their
 * values are the X configuration options that impact the behavior of
 * modePool construction; namely:
 *
 *    "ModeValidation"
 *    "HorizSync"
 *    "VertRefresh"
 *    "FlatPanelProperties"
 *    "TVStandard"
 *    "ExactModeTimingsDVI"
 *    "UseEdidFreqs"
 *
 * An example input string might look like:
 *
 *   "ModeValidation=NoVesaModes :: HorizSync=50-110 :: VertRefresh=50-150"
 *
 * This request currently does not return a string.
 */

#define NV_CTRL_STRING_OPERATION_BUILD_MODEPOOL                3 /* DG */


/*
 * NV_CTRL_STRING_OPERATION_GVI_CONFIGURE_STREAMS - Configure the streams-
 * to-jack+channel topology for a GVI (Graphics capture board).
 *
 * The string input to GVI_CONFIGURE_STREAMS may be NULL.  If this is the
 * case, then the current topology is returned.
 *
 * If the input string to GVI_CONFIGURE_STREAMS is not NULL, the string
 * is interpreted as a semicolon (";") separated list of comma-separated
 * lists of "option=value" pairs that define a stream's composition.  The
 * available options and their values are:
 *
 *   "stream": Defines which stream this comma-separated list describes.
 *             Valid values are the integers between 0 and
 *             NV_CTRL_GVI_NUM_STREAMS-1 (inclusive).
 *
 *   "linkN":  Defines a jack+channel pair to use for the given link N.
 *             Valid options are the string "linkN", where N is an integer
 *             between 0 and NV_CTRL_GVI_MAX_LINKS_PER_STREAM-1 (inclusive).
 *             Valid values for these options are strings of the form
 *             "jackX" and/or "jackX.Y", where X is an integer between 0 and
 *             NV_CTRL_GVI_NUM_JACKS-1 (inclusive), and Y (optional) is an
 *             integer between 0 and NV_CTRL_GVI_MAX_CHANNELS_PER_JACK-1
 *             (inclusive).
 *
 * An example input string might look like:
 *
 *   "stream=0, link0=jack0, link1=jack1; stream=1, link0=jack2.1"
 * 
 *   This example specifies two streams, stream 0 and stream 1.  Stream 0
 *   is defined to capture link0 data from the first channel (channel 0) of
 *   BNC jack 0 and link1 data from the first channel of BNC jack 1.  The
 *   second stream (Stream 1) is defined to capture link0 data from channel 1
 *   (second channel) of BNC jack 2.
 *
 * This example shows a possible configuration for capturing 3G input:
 *
 *   "stream=0, link0=jack0.0, link1=jack0.1"
 *
 * Applications should query the following attributes to determine
 * possible combinations:
 * 
 *   NV_CTRL_GVI_MAX_STREAMS
 *   NV_CTRL_GVI_MAX_LINKS_PER_STREAM
 *   NV_CTRL_GVI_NUM_JACKS
 *   NV_CTRL_GVI_MAX_CHANNELS_PER_JACK
 *
 * Note: A jack+channel pair can only be tied to one link/stream.
 *
 * Upon successful configuration or querying of this attribute, a string
 * representing the current topology for all known streams on the device
 * will be returned.  On failure, NULL is returned.
 *
 * Note: Setting this attribute may also result in the following
 *       NV-CONTROL attributes being reset on the GVI device (to ensure
 *       the configuration remains valid):
 *           NV_CTRL_GVIO_REQUESTED_VIDEO_FORMAT
 *           NV_CTRL_GVI_REQUESTED_STREAM_BITS_PER_COMPONENT
 *           NV_CTRL_GVI_REQUESTED_STREAM_COMPONENT_SAMPLING
 */

#define NV_CTRL_STRING_OPERATION_GVI_CONFIGURE_STREAMS         4 /* RW-I */


#define NV_CTRL_STRING_OPERATION_LAST_ATTRIBUTE \
        NV_CTRL_STRING_OPERATION_GVI_CONFIGURE_STREAMS




/**************************************************************************/

/*
 * CTRLAttributeValidValuesRec -
 *
 * structure and related defines used by
 * XNVCTRLQueryValidAttributeValues() to describe the valid values of
 * a particular attribute.  The type field will be one of:
 *
 * ATTRIBUTE_TYPE_INTEGER : the attribute is an integer value; there
 * is no fixed range of valid values.
 *
 * ATTRIBUTE_TYPE_BITMASK : the attribute is an integer value,
 * interpretted as a bitmask.
 *
 * ATTRIBUTE_TYPE_BOOL : the attribute is a boolean, valid values are
 * either 1 (on/true) or 0 (off/false).
 *
 * ATTRIBUTE_TYPE_RANGE : the attribute can have any integer value
 * between NVCTRLAttributeValidValues.u.range.min and
 * NVCTRLAttributeValidValues.u.range.max (inclusive).
 *
 * ATTRIBUTE_TYPE_INT_BITS : the attribute can only have certain
 * integer values, indicated by which bits in
 * NVCTRLAttributeValidValues.u.bits.ints are on (for example: if bit
 * 0 is on, then 0 is a valid value; if bit 5 is on, then 5 is a valid
 * value, etc).  This is useful for attributes like NV_CTRL_FSAA_MODE,
 * which can only have certain values, depending on GPU.
 *
 * ATTRIBUTE_TYPE_64BIT_INTEGER : the attribute is a 64 bit integer value;
 * there is no fixed range of valid values.
 *
 * ATTRIBUTE_TYPE_STRING : the attribute is a string value; there is no fixed
 * range of valid values.
 *
 * ATTRIBUTE_TYPE_BINARY_DATA : the attribute is binary data; there is
 * no fixed range of valid values.
 *
 * ATTRIBUTE_TYPE_STRING_OPERATION : the attribute is a string; there is
 * no fixed range of valid values.
 *
 *
 * The permissions field of NVCTRLAttributeValidValuesRec is a bitmask
 * that may contain:
 *
 * ATTRIBUTE_TYPE_READ      - Attribute may be read (queried.)
 * ATTRIBUTE_TYPE_WRITE     - Attribute may be written to (set.)
 * ATTRIBUTE_TYPE_DISPLAY   - Attribute is valid for display target types
 *                            (requires a display_mask if queried via
 *                            a GPU or X screen.)
 * ATTRIBUTE_TYPE_GPU       - Attribute is valid for GPU target types.
 * ATTRIBUTE_TYPE_FRAMELOCK - Attribute is valid for Frame Lock target types.
 * ATTRIBUTE_TYPE_X_SCREEN  - Attribute is valid for X Screen target types.
 * ATTRIBUTE_TYPE_XINERAMA  - Attribute will be made consistent for all
 *                            X Screens when the Xinerama extension is enabled.
 * ATTRIBUTE_TYPE_VCSC      - Attribute is valid for Visual Computing System
 *                            target types.
 * ATTRIBUTE_TYPE_GVI       - Attribute is valid for Graphics Video In target
 *                            types.
 * ATTRIBUTE_TYPE_COOLER    - Attribute is valid for Cooler target types.
 * ATTRIBUTE_TYPE_3D_VISION_PRO_TRANSCEIVER - Attribute is valid for 3D Vision
 *                                            Pro Transceiver target types.
 *
 * See 'Key to Integer Attribute "Permissions"' at the top of this
 * file for a description of what these permission bits mean.
 */

#define ATTRIBUTE_TYPE_UNKNOWN           0
#define ATTRIBUTE_TYPE_INTEGER           1
#define ATTRIBUTE_TYPE_BITMASK           2
#define ATTRIBUTE_TYPE_BOOL              3
#define ATTRIBUTE_TYPE_RANGE             4
#define ATTRIBUTE_TYPE_INT_BITS          5
#define ATTRIBUTE_TYPE_64BIT_INTEGER     6
#define ATTRIBUTE_TYPE_STRING            7
#define ATTRIBUTE_TYPE_BINARY_DATA       8
#define ATTRIBUTE_TYPE_STRING_OPERATION  9

#define ATTRIBUTE_TYPE_READ       0x001
#define ATTRIBUTE_TYPE_WRITE      0x002
#define ATTRIBUTE_TYPE_DISPLAY    0x004
#define ATTRIBUTE_TYPE_GPU        0x008
#define ATTRIBUTE_TYPE_FRAMELOCK  0x010
#define ATTRIBUTE_TYPE_X_SCREEN   0x020
#define ATTRIBUTE_TYPE_XINERAMA   0x040
#define ATTRIBUTE_TYPE_VCSC       0x080
#define ATTRIBUTE_TYPE_GVI        0x100
#define ATTRIBUTE_TYPE_COOLER     0x200
#define ATTRIBUTE_TYPE_THERMAL_SENSOR 0x400
#define ATTRIBUTE_TYPE_3D_VISION_PRO_TRANSCEIVER 0x800

#define ATTRIBUTE_TYPE_ALL_TARGETS                \
    ((ATTRIBUTE_TYPE_DISPLAY)                   | \
     (ATTRIBUTE_TYPE_GPU)                       | \
     (ATTRIBUTE_TYPE_FRAMELOCK)                 | \
     (ATTRIBUTE_TYPE_X_SCREEN)                  | \
     (ATTRIBUTE_TYPE_VCSC)                      | \
     (ATTRIBUTE_TYPE_GVI)                       | \
     (ATTRIBUTE_TYPE_COOLER)                    | \
     (ATTRIBUTE_TYPE_THERMAL_SENSOR)            | \
     (ATTRIBUTE_TYPE_3D_VISION_PRO_TRANSCEIVER))

typedef struct _NVCTRLAttributeValidValues {
    int type;
    union {
        struct {
            int64_t min;
            int64_t max;
        } range;
        struct {
            unsigned int ints;
        } bits;
    } u;
    unsigned int permissions;
} NVCTRLAttributeValidValuesRec;

typedef struct _NVCTRLAttributePermissions {
    int type;
    unsigned int permissions;
} NVCTRLAttributePermissionsRec;


/**************************************************************************/

/*
 * NV-CONTROL X event notification.
 *
 * To receive X event notifications dealing with NV-CONTROL, you should
 * call XNVCtrlSelectNotify() with one of the following set as the type
 * of event to receive (see NVCtrlLib.h for more information):
 */

#define ATTRIBUTE_CHANGED_EVENT                     0
#define TARGET_ATTRIBUTE_CHANGED_EVENT              1
#define TARGET_ATTRIBUTE_AVAILABILITY_CHANGED_EVENT 2
#define TARGET_STRING_ATTRIBUTE_CHANGED_EVENT       3
#define TARGET_BINARY_ATTRIBUTE_CHANGED_EVENT       4


#endif /* __NVCTRL_H */

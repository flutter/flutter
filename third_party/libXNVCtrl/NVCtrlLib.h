/*
 * Copyright (c) 2008 NVIDIA, Corporation
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

#ifndef __NVCTRLLIB_H
#define __NVCTRLLIB_H

#include "NVCtrl.h"

#if defined __cplusplus
extern "C" {
#endif 

/*
 *  XNVCTRLQueryExtension -
 *
 *  Returns True if the extension exists, returns False otherwise.
 *  event_basep and error_basep are the extension event and error
 *  bases.  Currently, no extension specific errors or events are
 *  defined.
 */

Bool XNVCTRLQueryExtension (
    Display *dpy,
    int *event_basep,
    int *error_basep
);


/*
 *  XNVCTRLQueryVersion -
 *
 *  Returns True if the extension exists, returns False otherwise.
 *  major and minor are the extension's major and minor version
 *  numbers.
 */

Bool XNVCTRLQueryVersion (
    Display *dpy,
    int *major,
    int *minor
);


/*
 *  XNVCTRLIsNvScreen
 *
 *  Returns True is the specified screen is controlled by the NVIDIA
 *  driver.  Returns False otherwise.
 */

Bool XNVCTRLIsNvScreen (
    Display *dpy,
    int screen
);


/*
 *  XNVCTRLQueryTargetCount -
 *
 *  Returns True if the target type exists.  Returns False otherwise.
 *  If XNVCTRLQueryTargetCount returns True, value will contain the
 *  count of existing targets on the server of the specified target
 *  type.
 *
 *  Please see "Attribute Targets" in NVCtrl.h for the list of valid
 *  target types.
 *
 *  Possible errors:
 *     BadValue - The target doesn't exist.
 */

Bool XNVCTRLQueryTargetCount (
    Display *dpy,
    int target_type,
    int *value
);


/*
 *  XNVCTRLSetAttribute -
 *
 *  Sets the attribute to the given value.  The attributes and their
 *  possible values are listed in NVCtrl.h.
 *
 *  Not all attributes require the display_mask parameter; see
 *  NVCtrl.h for details.
 *
 *  Calling this function is equivalent to calling XNVCTRLSetTargetAttribute()
 *  with the target_type set to NV_CTRL_TARGET_TYPE_X_SCREEN and
 *  target_id set to 'screen'.
 *
 *  Possible errors:
 *     BadValue - The screen or attribute doesn't exist.
 *     BadMatch - The NVIDIA driver is not present on that screen.
 */

void XNVCTRLSetAttribute (
    Display *dpy,
    int screen,
    unsigned int display_mask,
    unsigned int attribute,
    int value
);


/*
 *  XNVCTRLSetTargetAttribute -
 *
 *  Sets the attribute to the given value.  The attributes and their
 *  possible values are listed in NVCtrl.h.
 *
 *  Not all attributes require the display_mask parameter; see
 *  NVCtrl.h for details.
 *
 *  Possible errors:
 *     BadValue - The target or attribute doesn't exist.
 *     BadMatch - The NVIDIA driver is not present on that target.
 */

void XNVCTRLSetTargetAttribute (
    Display *dpy,
    int target_type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,
    int value
);


/*
 *  XNVCTRLSetAttributeAndGetStatus -
 *
 * Same as XNVCTRLSetAttribute().
 * In addition, XNVCTRLSetAttributeAndGetStatus() returns 
 * True if the operation succeeds, False otherwise.
 *
 */

Bool XNVCTRLSetAttributeAndGetStatus (
    Display *dpy,
    int screen,
    unsigned int display_mask,
    unsigned int attribute,
    int value
);


/*
 *  XNVCTRLSetTargetAttributeAndGetStatus -
 *
 * Same as XNVCTRLSetTargetAttribute().
 * In addition, XNVCTRLSetTargetAttributeAndGetStatus() returns 
 * True if the operation succeeds, False otherwise.
 *
 */

Bool XNVCTRLSetTargetAttributeAndGetStatus (
    Display *dpy,
    int target_type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,
    int value
);


/*
 *  XNVCTRLQueryAttribute -
 *
 *  Returns True if the attribute exists.  Returns False otherwise.
 *  If XNVCTRLQueryAttribute returns True, value will contain the
 *  value of the specified attribute.
 *
 *  Not all attributes require the display_mask parameter; see
 *  NVCtrl.h for details.
 *
 *  Calling this function is equivalent to calling
 *  XNVCTRLQueryTargetAttribute() with the target_type set to
 *  NV_CTRL_TARGET_TYPE_X_SCREEN and target_id set to 'screen'.
 *
 *  Possible errors:
 *     BadValue - The screen doesn't exist.
 *     BadMatch - The NVIDIA driver is not present on that screen.
 */

Bool XNVCTRLQueryAttribute (
    Display *dpy,
    int screen,
    unsigned int display_mask,
    unsigned int attribute,
    int *value
);


/*
 * XNVCTRLQueryTargetAttribute -
 *
 *  Returns True if the attribute exists.  Returns False otherwise.
 *  If XNVCTRLQueryTargetAttribute returns True, value will contain the
 *  value of the specified attribute.
 *
 *  Not all attributes require the display_mask parameter; see
 *  NVCtrl.h for details.
 *
 *  Possible errors:
 *     BadValue - The target doesn't exist.
 *     BadMatch - The NVIDIA driver does not control the target.
 */

Bool XNVCTRLQueryTargetAttribute (
    Display *dpy,
    int target_Type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,
    int *value
);


/*
 * XNVCTRLQueryTargetAttribute64 -
 *
 *  Returns True if the attribute exists.  Returns False otherwise.
 *  If XNVCTRLQueryTargetAttribute returns True, value will contain the
 *  value of the specified attribute.
 *
 *  Not all attributes require the display_mask parameter; see
 *  NVCtrl.h for details.
 *
 *  Note: this function behaves like XNVCTRLQueryTargetAttribute(),
 *  but supports 64-bit integer attributes.
 *
 *  Possible errors:
 *     BadValue - The target doesn't exist.
 *     BadMatch - The NVIDIA driver does not control the target.
 */

Bool XNVCTRLQueryTargetAttribute64 (
    Display *dpy,
    int target_Type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,
    int64_t *value
);


/*
 *  XNVCTRLQueryStringAttribute -
 *
 *  Returns True if the attribute exists.  Returns False otherwise.
 *  If XNVCTRLQueryStringAttribute returns True, *ptr will point to an
 *  allocated string containing the string attribute requested.  It is
 *  the caller's responsibility to free the string when done.
 *
 *  Calling this function is equivalent to calling
 *  XNVCTRLQueryTargetStringAttribute() with the target_type set to
 *  NV_CTRL_TARGET_TYPE_X_SCREEN and target_id set to 'screen'.
 *
 *  Possible errors:
 *     BadValue - The screen doesn't exist.
 *     BadMatch - The NVIDIA driver is not present on that screen.
 *     BadAlloc - Insufficient resources to fulfill the request.
 */

Bool XNVCTRLQueryStringAttribute (
    Display *dpy,
    int screen,
    unsigned int display_mask,
    unsigned int attribute,
    char **ptr
);


/*
 *  XNVCTRLQueryTargetStringAttribute -
 *
 *  Returns True if the attribute exists.  Returns False otherwise.
 *  If XNVCTRLQueryTargetStringAttribute returns True, *ptr will point
 *  to an allocated string containing the string attribute requested.
 *  It is the caller's responsibility to free the string when done.
 *
 *  Possible errors:
 *     BadValue - The target doesn't exist.
 *     BadMatch - The NVIDIA driver does not control the target.
 *     BadAlloc - Insufficient resources to fulfill the request.
 */

Bool XNVCTRLQueryTargetStringAttribute (
    Display *dpy,
    int target_type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,
    char **ptr
);


/*
 *  XNVCTRLSetStringAttribute -
 *
 *  Returns True if the operation succeded.  Returns False otherwise.
 *
 *  Possible X errors:
 *     BadValue - The screen doesn't exist.
 *     BadMatch - The NVIDIA driver is not present on that screen.
 *     BadAlloc - Insufficient resources to fulfill the request.
 */
 
Bool XNVCTRLSetStringAttribute (
    Display *dpy,
    int screen,
    unsigned int display_mask,
    unsigned int attribute,
    char *ptr
);


/*
 *  XNVCTRLSetTargetStringAttribute -
 *
 *  Returns True if the operation succeded.  Returns False otherwise.
 *
 *  Possible X errors:
 *     BadValue - The screen doesn't exist.
 *     BadMatch - The NVIDIA driver is not present on that screen.
 *     BadAlloc - Insufficient resources to fulfill the request.
 */
 
Bool XNVCTRLSetTargetStringAttribute (
    Display *dpy,
    int target_type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,
    char *ptr
);


/*
 * XNVCTRLQueryValidAttributeValues -
 *
 * Returns True if the attribute exists.  Returns False otherwise.  If
 * XNVCTRLQueryValidAttributeValues returns True, values will indicate
 * the valid values for the specified attribute; see the description
 * of NVCTRLAttributeValidValues in NVCtrl.h.
 *
 *  Calling this function is equivalent to calling
 *  XNVCTRLQueryValidTargetAttributeValues() with the target_type set to
 *  NV_CTRL_TARGET_TYPE_X_SCREEN and target_id set to 'screen'.
 */

Bool XNVCTRLQueryValidAttributeValues (
    Display *dpy,
    int screen,
    unsigned int display_mask,
    unsigned int attribute,                                 
    NVCTRLAttributeValidValuesRec *values
);



/*
 * XNVCTRLQueryValidTargetAttributeValues -
 *
 * Returns True if the attribute exists.  Returns False otherwise.  If
 * XNVCTRLQueryValidTargetAttributeValues returns True, values will indicate
 * the valid values for the specified attribute.
 */

Bool XNVCTRLQueryValidTargetAttributeValues (
    Display *dpy,
    int target_type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,                                 
    NVCTRLAttributeValidValuesRec *values
);


/*
 * XNVCTRLQueryValidTargetStringAttributeValues -
 *
 * Returns True if the attribute exists.  Returns False otherwise.  If
 * XNVCTRLQueryValidTargetStringAttributeValues returns True, values will
 * indicate the valid values for the specified attribute.
 */

 Bool XNVCTRLQueryValidTargetStringAttributeValues (
    Display *dpy,
    int target_type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,
    NVCTRLAttributeValidValuesRec *values
);


/*
 * XNVCTRLQueryAttributePermissions -
 *
 * Returns True if the attribute exists.  Returns False otherwise.  If
 * XNVCTRLQueryAttributePermissions returns True, permissions will
 * indicate the permission flags for the attribute.
 */

Bool XNVCTRLQueryAttributePermissions (
    Display *dpy,
    unsigned int attribute,
    NVCTRLAttributePermissionsRec *permissions
);


/*
 * XNVCTRLQueryStringAttributePermissions -
 *
 * Returns True if the attribute exists.  Returns False otherwise.  If
 * XNVCTRLQueryStringAttributePermissions returns True, permissions will
 * indicate the permission flags for the attribute.
 */

 Bool XNVCTRLQueryStringAttributePermissions (
    Display *dpy,
    unsigned int attribute,
    NVCTRLAttributePermissionsRec *permissions
);


/*
 * XNVCTRLQueryBinaryDataAttributePermissions -
 *
 * Returns True if the attribute exists.  Returns False otherwise.  If
 * XNVCTRLQueryBinaryDataAttributePermissions returns True, permissions
 * will indicate the permission flags for the attribute.
 */

 Bool XNVCTRLQueryBinaryDataAttributePermissions (
    Display *dpy,
    unsigned int attribute,
    NVCTRLAttributePermissionsRec *permissions
);


/*
 * XNVCTRLQueryStringOperationAttributePermissions -
 *
 * Returns True if the attribute exists.  Returns False otherwise.  If
 * XNVCTRLQueryStringOperationAttributePermissions returns True,
 * permissions will indicate the permission flags for the attribute.
 */

 Bool XNVCTRLQueryStringOperationAttributePermissions (
    Display *dpy,
    unsigned int attribute,
    NVCTRLAttributePermissionsRec *permissions
);


/*
 *  XNVCTRLSetGvoColorConversion -
 *
 *  Sets the color conversion matrix, offset, and scale that should be
 *  used for GVO (Graphic to Video Out).
 *
 *  The Color Space Conversion data is ordered like this:
 *
 *   colorMatrix[0][0] // r.Y
 *   colorMatrix[0][1] // g.Y
 *   colorMatrix[0][2] // b.Y
 *
 *   colorMatrix[1][0] // r.Cr
 *   colorMatrix[1][1] // g.Cr
 *   colorMatrix[1][2] // b.Cr
 *
 *   colorMatrix[2][0] // r.Cb
 *   colorMatrix[2][1] // g.Cb
 *   colorMatrix[2][2] // b.Cb
 *
 *   colorOffset[0]    // Y
 *   colorOffset[1]    // Cr
 *   colorOffset[2]    // Cb
 *
 *   colorScale[0]     // Y
 *   colorScale[1]     // Cr
 *   colorScale[2]     // Cb
 *
 *  where the data is used according to the following formulae:
 *
 *   Y  =  colorOffset[0] + colorScale[0] *
 *           (R * colorMatrix[0][0] +
 *            G * colorMatrix[0][1] +
 *            B * colorMatrix[0][2]);
 *
 *   Cr =  colorOffset[1] + colorScale[1] *
 *           (R * colorMatrix[1][0] +
 *            G * colorMatrix[1][1] +
 *            B * colorMatrix[1][2]);
 *
 *   Cb =  colorOffset[2] + colorScale[2] *
 *           (R * colorMatrix[2][0] +
 *            G * colorMatrix[2][1] +
 *            B * colorMatrix[2][2]);
 *
 *  Possible errors:
 *     BadMatch - The NVIDIA driver is not present on that screen.
 *     BadImplementation - GVO is not available on that screen.
 */

void XNVCTRLSetGvoColorConversion (
    Display *dpy,
    int screen,
    float colorMatrix[3][3],
    float colorOffset[3],
    float colorScale[3]
);



/*
 *  XNVCTRLQueryGvoColorConversion -
 *
 *  Retrieves the color conversion matrix and color offset
 *  that are currently being used for GVO (Graphic to Video Out).
 *
 *  The values are ordered within the arrays according to the comments
 *  for XNVCTRLSetGvoColorConversion().
 *
 *  Possible errors:
 *     BadMatch - The NVIDIA driver is not present on that screen.
 *     BadImplementation - GVO is not available on that screen.
 */

Bool XNVCTRLQueryGvoColorConversion (
    Display *dpy,
    int screen,
    float colorMatrix[3][3],
    float colorOffset[3],
    float colorScale[3]
);


/*
 *  XNVCTRLQueryBinaryData -
 *
 *  Returns True if the attribute exists.  Returns False otherwise.
 *  If XNVCTRLQueryBinaryData returns True, *ptr will point to an
 *  allocated block of memory containing the binary data attribute
 *  requested.  It is the caller's responsibility to free the data
 *  when done.  len will list the length of the binary data.
 *
 *  Calling this function is equivalent to calling
 *  XNVCTRLQueryTargetBinaryData() with the target_type set to
 *  NV_CTRL_TARGET_TYPE_X_SCREEN and target_id set to 'screen'.
 *
 *  Possible errors:
 *     BadValue - The screen doesn't exist.
 *     BadMatch - The NVIDIA driver is not present on that screen.
 *     BadAlloc - Insufficient resources to fulfill the request.
 */

Bool XNVCTRLQueryBinaryData (
    Display *dpy,
    int screen,
    unsigned int display_mask,
    unsigned int attribute,
    unsigned char **ptr,
    int *len
);


/*
 * XNVCTRLQueryTargetBinaryData -
 *
 *  Returns True if the attribute exists.  Returns False otherwise.
 *  If XNVCTRLQueryTargetBinaryData returns True, *ptr will point to an
 *  allocated block of memory containing the binary data attribute
 *  requested.  It is the caller's responsibility to free the data
 *  when done.  len will list the length of the binary data.
 *
 *  Possible errors:
 *     BadValue - The target doesn't exist.
 *     BadMatch - The NVIDIA driver does not control the target.
 *     BadAlloc - Insufficient resources to fulfill the request.
 */

Bool XNVCTRLQueryTargetBinaryData (
    Display *dpy,
    int target_type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,
    unsigned char **ptr,
    int *len
);


/*
 * XNVCTRLStringOperation -
 *
 * Takes a string as input and returns a Xmalloc'ed string as output.
 * Returns True on success and False on failure.
 */

Bool XNVCTRLStringOperation (
    Display *dpy,
    int target_type,
    int target_id,
    unsigned int display_mask,
    unsigned int attribute,
    char *pIn,
    char **ppOut
);



/*
 * XNVCtrlSelectNotify -
 *
 * This enables/disables receiving of NV-CONTROL events.  The type
 * specifies the type of event to enable (currently, the only
 * type that can be requested per-screen with XNVCtrlSelectNotify()
 * is ATTRIBUTE_CHANGED_EVENT); onoff controls whether receiving this
 * type of event should be enabled (True) or disabled (False).
 *
 * Returns True if successful, or False if the screen is not
 * controlled by the NVIDIA driver.
 */

Bool XNVCtrlSelectNotify (
    Display *dpy,
    int screen,
    int type,
    Bool onoff
);


/*
 * XNVCtrlSelectTargetNotify -
 *
 * This enables/disables receiving of NV-CONTROL events that happen on
 * the specified target.  The notify_type specifies the type of event to
 * enable (currently, the only type that can be requested per-target with
 * XNVCtrlSelectTargetNotify() is TARGET_ATTRIBUTE_CHANGED_EVENT); onoff
 * controls whether receiving this type of event should be enabled (True)
 * or disabled (False).
 *
 * Returns True if successful, or False if the target is not
 * controlled by the NVIDIA driver.
 */

Bool XNVCtrlSelectTargetNotify (
    Display *dpy,
    int target_type,
    int target_id,
    int notify_type,
    Bool onoff
);


/*
 * XNVCtrlEvent structure
 */

typedef struct {
    int type;
    unsigned long serial;
    Bool send_event;  /* always FALSE, we don't allow send_events */
    Display *display;
    Time time;
    int screen;
    unsigned int display_mask;
    unsigned int attribute;
    int value;
} XNVCtrlAttributeChangedEvent;

typedef union {
    int type;
    XNVCtrlAttributeChangedEvent attribute_changed;
    long pad[24];
} XNVCtrlEvent;


/*
 * XNVCtrlEventTarget structure
 */

typedef struct {
    int type;
    unsigned long serial;
    Bool send_event;  /* always FALSE, we don't allow send_events */
    Display *display;
    Time time;
    int target_type;
    int target_id;
    unsigned int display_mask;
    unsigned int attribute;
    int value;
} XNVCtrlAttributeChangedEventTarget;

typedef union {
    int type;
    XNVCtrlAttributeChangedEventTarget attribute_changed;
    long pad[24];
} XNVCtrlEventTarget;


/*
 * XNVCtrlEventTargetAvailability structure
 */

typedef struct {
    int type;
    unsigned long serial;
    Bool send_event;  /* always FALSE, we don't allow send_events */
    Display *display;
    Time time;
    int target_type;
    int target_id;
    unsigned int display_mask;
    unsigned int attribute;
    int value;
    Bool availability;
} XNVCtrlAttributeChangedEventTargetAvailability;

typedef union {
    int type;
    XNVCtrlAttributeChangedEventTargetAvailability attribute_changed;
    long pad[24];
} XNVCtrlEventTargetAvailability;


/*
 * XNVCtrlStringEventTarget structure
 */

typedef struct {
    int type;
    unsigned long serial;
    Bool send_event;  /* always FALSE, we don't allow send_events */
    Display *display;
    Time time;
    int target_type;
    int target_id;
    unsigned int display_mask;
    unsigned int attribute;
} XNVCtrlStringAttributeChangedEventTarget;

typedef union {
    int type;
    XNVCtrlStringAttributeChangedEventTarget attribute_changed;
    long pad[24];
} XNVCtrlStringEventTarget;



/*
 * XNVCtrlBinaryEventTarget structure
 */

typedef struct {
    int type;
    unsigned long serial;
    Bool send_event;  /* always FALSE, we don't allow send_events */
    Display *display;
    Time time;
    int target_type;
    int target_id;
    unsigned int display_mask;
    unsigned int attribute;
} XNVCtrlBinaryAttributeChangedEventTarget;

typedef union {
    int type;
    XNVCtrlBinaryAttributeChangedEventTarget attribute_changed;
    long pad[24];
} XNVCtrlBinaryEventTarget;

#if defined __cplusplus
} /* extern "C" */
#endif 

#endif /* __NVCTRLLIB_H */

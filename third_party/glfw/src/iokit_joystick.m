//========================================================================
// GLFW 3.1 IOKit - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2009-2010 Camilla Berglund <elmindreda@elmindreda.org>
// Copyright (c) 2012 Torsten Walluhn <tw@mad-cad.net>
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.
//
//========================================================================

#include "internal.h"

#include <unistd.h>
#include <ctype.h>

#include <mach/mach.h>
#include <mach/mach_error.h>

#include <CoreFoundation/CoreFoundation.h>
#include <Kernel/IOKit/hidsystem/IOHIDUsageTables.h>


//------------------------------------------------------------------------
// Joystick element information
//------------------------------------------------------------------------
typedef struct
{
    IOHIDElementRef elementRef;

    long min;
    long max;

    long minReport;
    long maxReport;

} _GLFWjoyelement;


static void getElementsCFArrayHandler(const void* value, void* parameter);

// Adds an element to the specified joystick
//
static void addJoystickElement(_GLFWjoydevice* joystick,
                               IOHIDElementRef elementRef)
{
    IOHIDElementType elementType;
    long usagePage, usage;
    CFMutableArrayRef elementsArray = NULL;

    elementType = IOHIDElementGetType(elementRef);
    usagePage = IOHIDElementGetUsagePage(elementRef);
    usage = IOHIDElementGetUsage(elementRef);

    if ((elementType != kIOHIDElementTypeInput_Axis) &&
        (elementType != kIOHIDElementTypeInput_Button) &&
        (elementType != kIOHIDElementTypeInput_Misc))
    {
        return;
    }

    switch (usagePage)
    {
        case kHIDPage_GenericDesktop:
        {
            switch (usage)
            {
                case kHIDUsage_GD_X:
                case kHIDUsage_GD_Y:
                case kHIDUsage_GD_Z:
                case kHIDUsage_GD_Rx:
                case kHIDUsage_GD_Ry:
                case kHIDUsage_GD_Rz:
                case kHIDUsage_GD_Slider:
                case kHIDUsage_GD_Dial:
                case kHIDUsage_GD_Wheel:
                    elementsArray = joystick->axisElements;
                    break;
                case kHIDUsage_GD_Hatswitch:
                    elementsArray = joystick->hatElements;
                    break;
            }

            break;
        }

        case kHIDPage_Button:
            elementsArray = joystick->buttonElements;
            break;
        default:
            break;
    }

    if (elementsArray)
    {
        _GLFWjoyelement* element = calloc(1, sizeof(_GLFWjoyelement));

        CFArrayAppendValue(elementsArray, element);

        element->elementRef = elementRef;

        element->minReport = IOHIDElementGetLogicalMin(elementRef);
        element->maxReport = IOHIDElementGetLogicalMax(elementRef);
    }
}

// Adds an element to the specified joystick
//
static void getElementsCFArrayHandler(const void* value, void* parameter)
{
    if (CFGetTypeID(value) == IOHIDElementGetTypeID())
    {
        addJoystickElement((_GLFWjoydevice*) parameter,
                           (IOHIDElementRef) value);
    }
}

// Returns the value of the specified element of the specified joystick
//
static long getElementValue(_GLFWjoydevice* joystick, _GLFWjoyelement* element)
{
    IOReturn result = kIOReturnSuccess;
    IOHIDValueRef valueRef;
    long value = 0;

    if (joystick && element && joystick->deviceRef)
    {
        result = IOHIDDeviceGetValue(joystick->deviceRef,
                                     element->elementRef,
                                     &valueRef);

        if (kIOReturnSuccess == result)
        {
            value = IOHIDValueGetIntegerValue(valueRef);

            // Record min and max for auto calibration
            if (value < element->minReport)
                element->minReport = value;
            if (value > element->maxReport)
                element->maxReport = value;
        }
    }

    // Auto user scale
    return value;
}

// Removes the specified joystick
//
static void removeJoystick(_GLFWjoydevice* joystick)
{
    int i;

    if (!joystick->present)
        return;

    for (i = 0;  i < CFArrayGetCount(joystick->axisElements);  i++)
        free((void*) CFArrayGetValueAtIndex(joystick->axisElements, i));
    CFArrayRemoveAllValues(joystick->axisElements);
    CFRelease(joystick->axisElements);

    for (i = 0;  i < CFArrayGetCount(joystick->buttonElements);  i++)
        free((void*) CFArrayGetValueAtIndex(joystick->buttonElements, i));
    CFArrayRemoveAllValues(joystick->buttonElements);
    CFRelease(joystick->buttonElements);

    for (i = 0;  i < CFArrayGetCount(joystick->hatElements);  i++)
        free((void*) CFArrayGetValueAtIndex(joystick->hatElements, i));
    CFArrayRemoveAllValues(joystick->hatElements);
    CFRelease(joystick->hatElements);

    free(joystick->axes);
    free(joystick->buttons);

    memset(joystick, 0, sizeof(_GLFWjoydevice));
}

// Polls for joystick events and updates GLFW state
//
static void pollJoystickEvents(void)
{
    int joy;

    for (joy = 0;  joy <= GLFW_JOYSTICK_LAST;  joy++)
    {
        CFIndex i;
        int buttonIndex = 0;
        _GLFWjoydevice* joystick = _glfw.iokit_js.devices + joy;

        if (!joystick->present)
            continue;

        for (i = 0;  i < CFArrayGetCount(joystick->buttonElements);  i++)
        {
            _GLFWjoyelement* button = (_GLFWjoyelement*)
                CFArrayGetValueAtIndex(joystick->buttonElements, i);

            if (getElementValue(joystick, button))
                joystick->buttons[buttonIndex++] = GLFW_PRESS;
            else
                joystick->buttons[buttonIndex++] = GLFW_RELEASE;
        }

        for (i = 0;  i < CFArrayGetCount(joystick->axisElements);  i++)
        {
            _GLFWjoyelement* axis = (_GLFWjoyelement*)
                CFArrayGetValueAtIndex(joystick->axisElements, i);

            long value = getElementValue(joystick, axis);
            long readScale = axis->maxReport - axis->minReport;

            if (readScale == 0)
                joystick->axes[i] = value;
            else
                joystick->axes[i] = (2.f * (value - axis->minReport) / readScale) - 1.f;
        }

        for (i = 0;  i < CFArrayGetCount(joystick->hatElements);  i++)
        {
            _GLFWjoyelement* hat = (_GLFWjoyelement*)
                CFArrayGetValueAtIndex(joystick->hatElements, i);

            // Bit fields of button presses for each direction, including nil
            const int directions[9] = { 1, 3, 2, 6, 4, 12, 8, 9, 0 };

            long j, value = getElementValue(joystick, hat);
            if (value < 0 || value > 8)
                value = 8;

            for (j = 0;  j < 4;  j++)
            {
                if (directions[value] & (1 << j))
                    joystick->buttons[buttonIndex++] = GLFW_PRESS;
                else
                    joystick->buttons[buttonIndex++] = GLFW_RELEASE;
            }
        }
    }
}

// Callback for user-initiated joystick addition
//
static void matchCallback(void* context,
                          IOReturn result,
                          void* sender,
                          IOHIDDeviceRef deviceRef)
{
    _GLFWjoydevice* joystick;
    int joy;

    for (joy = GLFW_JOYSTICK_1;  joy <= GLFW_JOYSTICK_LAST;  joy++)
    {
        joystick = _glfw.iokit_js.devices + joy;

        if (!joystick->present)
            continue;

        if (joystick->deviceRef == deviceRef)
            return;
    }

    for (joy = GLFW_JOYSTICK_1;  joy <= GLFW_JOYSTICK_LAST;  joy++)
    {
        joystick = _glfw.iokit_js.devices + joy;

        if (!joystick->present)
            break;
    }

    if (joy > GLFW_JOYSTICK_LAST)
        return;

    joystick->present = GL_TRUE;
    joystick->deviceRef = deviceRef;

    CFStringRef name = IOHIDDeviceGetProperty(deviceRef,
                                              CFSTR(kIOHIDProductKey));
    CFStringGetCString(name,
                       joystick->name,
                       sizeof(joystick->name),
                       kCFStringEncodingUTF8);

    joystick->axisElements = CFArrayCreateMutable(NULL, 0, NULL);
    joystick->buttonElements = CFArrayCreateMutable(NULL, 0, NULL);
    joystick->hatElements = CFArrayCreateMutable(NULL, 0, NULL);

    CFArrayRef arrayRef = IOHIDDeviceCopyMatchingElements(deviceRef,
                                                          NULL,
                                                          kIOHIDOptionsTypeNone);
    CFRange range = { 0, CFArrayGetCount(arrayRef) };
    CFArrayApplyFunction(arrayRef,
                         range,
                         getElementsCFArrayHandler,
                         (void*) joystick);

    CFRelease(arrayRef);

    joystick->axes = calloc(CFArrayGetCount(joystick->axisElements),
                            sizeof(float));
    joystick->buttons = calloc(CFArrayGetCount(joystick->buttonElements) +
                               CFArrayGetCount(joystick->hatElements) * 4, 1);
}

// Callback for user-initiated joystick removal
//
static void removeCallback(void* context,
                           IOReturn result,
                           void* sender,
                           IOHIDDeviceRef deviceRef)
{
    int joy;

    for (joy = GLFW_JOYSTICK_1;  joy <= GLFW_JOYSTICK_LAST;  joy++)
    {
        _GLFWjoydevice* joystick = _glfw.iokit_js.devices + joy;
        if (joystick->deviceRef == deviceRef)
        {
            removeJoystick(joystick);
            break;
        }
    }
}

// Creates a dictionary to match against devices with the specified usage page
// and usage
//
static CFMutableDictionaryRef createMatchingDictionary(long usagePage,
                                                       long usage)
{
    CFMutableDictionaryRef result =
        CFDictionaryCreateMutable(kCFAllocatorDefault,
                                  0,
                                  &kCFTypeDictionaryKeyCallBacks,
                                  &kCFTypeDictionaryValueCallBacks);

    if (result)
    {
        CFNumberRef pageRef = CFNumberCreate(kCFAllocatorDefault,
                                             kCFNumberLongType,
                                             &usagePage);
        if (pageRef)
        {
            CFDictionarySetValue(result,
                                 CFSTR(kIOHIDDeviceUsagePageKey),
                                 pageRef);
            CFRelease(pageRef);

            CFNumberRef usageRef = CFNumberCreate(kCFAllocatorDefault,
                                                  kCFNumberLongType,
                                                  &usage);
            if (usageRef)
            {
                CFDictionarySetValue(result,
                                     CFSTR(kIOHIDDeviceUsageKey),
                                     usageRef);
                CFRelease(usageRef);
            }
        }
    }

    return result;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialize joystick interface
//
void _glfwInitJoysticks(void)
{
    CFMutableArrayRef matchingCFArrayRef;

    _glfw.iokit_js.managerRef = IOHIDManagerCreate(kCFAllocatorDefault,
                                                   kIOHIDOptionsTypeNone);

    matchingCFArrayRef = CFArrayCreateMutable(kCFAllocatorDefault,
                                              0,
                                              &kCFTypeArrayCallBacks);
    if (matchingCFArrayRef)
    {
        CFDictionaryRef matchingCFDictRef =
            createMatchingDictionary(kHIDPage_GenericDesktop,
                                     kHIDUsage_GD_Joystick);
        if (matchingCFDictRef)
        {
            CFArrayAppendValue(matchingCFArrayRef, matchingCFDictRef);
            CFRelease(matchingCFDictRef);
        }

        matchingCFDictRef = createMatchingDictionary(kHIDPage_GenericDesktop,
                                                     kHIDUsage_GD_GamePad);
        if (matchingCFDictRef)
        {
            CFArrayAppendValue(matchingCFArrayRef, matchingCFDictRef);
            CFRelease(matchingCFDictRef);
        }

        matchingCFDictRef =
            createMatchingDictionary(kHIDPage_GenericDesktop,
                                     kHIDUsage_GD_MultiAxisController);
        if (matchingCFDictRef)
        {
            CFArrayAppendValue(matchingCFArrayRef, matchingCFDictRef);
            CFRelease(matchingCFDictRef);
        }

        IOHIDManagerSetDeviceMatchingMultiple(_glfw.iokit_js.managerRef,
                                              matchingCFArrayRef);
        CFRelease(matchingCFArrayRef);
    }

    IOHIDManagerRegisterDeviceMatchingCallback(_glfw.iokit_js.managerRef,
                                               &matchCallback, NULL);
    IOHIDManagerRegisterDeviceRemovalCallback(_glfw.iokit_js.managerRef,
                                              &removeCallback, NULL);

    IOHIDManagerScheduleWithRunLoop(_glfw.iokit_js.managerRef,
                                    CFRunLoopGetMain(),
                                    kCFRunLoopDefaultMode);

    IOHIDManagerOpen(_glfw.iokit_js.managerRef, kIOHIDOptionsTypeNone);

    // Execute the run loop once in order to register any initially-attached
    // joysticks
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, false);
}

// Close all opened joystick handles
//
void _glfwTerminateJoysticks(void)
{
    int joy;

    for (joy = 0;  joy <= GLFW_JOYSTICK_LAST;  joy++)
    {
        _GLFWjoydevice* joystick = _glfw.iokit_js.devices + joy;
        removeJoystick(joystick);
    }

    CFRelease(_glfw.iokit_js.managerRef);
    _glfw.iokit_js.managerRef = NULL;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformJoystickPresent(int joy)
{
    pollJoystickEvents();

    return _glfw.iokit_js.devices[joy].present;
}

const float* _glfwPlatformGetJoystickAxes(int joy, int* count)
{
    _GLFWjoydevice* joystick = _glfw.iokit_js.devices + joy;

    pollJoystickEvents();

    if (!joystick->present)
        return NULL;

    *count = (int) CFArrayGetCount(joystick->axisElements);
    return joystick->axes;
}

const unsigned char* _glfwPlatformGetJoystickButtons(int joy, int* count)
{
    _GLFWjoydevice* joystick = _glfw.iokit_js.devices + joy;

    pollJoystickEvents();

    if (!joystick->present)
        return NULL;

    *count = (int) CFArrayGetCount(joystick->buttonElements) +
             (int) CFArrayGetCount(joystick->hatElements) * 4;
    return joystick->buttons;
}

const char* _glfwPlatformGetJoystickName(int joy)
{
    pollJoystickEvents();

    return _glfw.iokit_js.devices[joy].name;
}


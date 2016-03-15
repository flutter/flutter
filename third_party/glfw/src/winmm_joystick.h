//========================================================================
// GLFW 3.1 WinMM - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2006-2014 Camilla Berglund <elmindreda@elmindreda.org>
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

#ifndef _glfw3_winmm_joystick_h_
#define _glfw3_winmm_joystick_h_

#define _GLFW_PLATFORM_LIBRARY_JOYSTICK_STATE \
    _GLFWjoystickWinMM winmm_js[GLFW_JOYSTICK_LAST + 1]


// WinMM-specific per-joystick data
//
typedef struct _GLFWjoystickWinMM
{
    float           axes[6];
    unsigned char   buttons[36]; // 32 buttons plus one hat
    char*           name;
} _GLFWjoystickWinMM;


void _glfwInitJoysticks(void);
void _glfwTerminateJoysticks(void);

#endif // _glfw3_winmm_joystick_h_

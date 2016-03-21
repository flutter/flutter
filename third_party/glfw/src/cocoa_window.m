//========================================================================
// GLFW 3.1 OS X - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2009-2010 Camilla Berglund <elmindreda@elmindreda.org>
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

#include <string.h>

// Needed for _NSGetProgname
#include <crt_externs.h>


// Returns the specified standard cursor
//
static NSCursor* getStandardCursor(int shape)
{
    switch (shape)
    {
        case GLFW_ARROW_CURSOR:
            return [NSCursor arrowCursor];
        case GLFW_IBEAM_CURSOR:
            return [NSCursor IBeamCursor];
        case GLFW_CROSSHAIR_CURSOR:
            return [NSCursor crosshairCursor];
        case GLFW_HAND_CURSOR:
            return [NSCursor pointingHandCursor];
        case GLFW_HRESIZE_CURSOR:
            return [NSCursor resizeLeftRightCursor];
        case GLFW_VRESIZE_CURSOR:
            return [NSCursor resizeUpDownCursor];
    }

    return nil;
}

// Center the cursor in the view of the window
//
static void centerCursor(_GLFWwindow *window)
{
    int width, height;
    _glfwPlatformGetWindowSize(window, &width, &height);
    _glfwPlatformSetCursorPos(window, width / 2.0, height / 2.0);
}

// Update the cursor to match the specified cursor mode
//
static void updateModeCursor(_GLFWwindow* window)
{
    if (window->cursorMode == GLFW_CURSOR_NORMAL)
    {
        if (window->cursor)
            [(NSCursor*) window->cursor->ns.object set];
        else
            [[NSCursor arrowCursor] set];
    }
    else
        [(NSCursor*) _glfw.ns.cursor set];
}

// Enter full screen mode
//
static GLboolean enterFullscreenMode(_GLFWwindow* window)
{
    GLFWvidmode mode;
    GLboolean status;
    int xpos, ypos;

    status = _glfwSetVideoMode(window->monitor, &window->videoMode);

    _glfwPlatformGetVideoMode(window->monitor, &mode);
    _glfwPlatformGetMonitorPos(window->monitor, &xpos, &ypos);

    [window->ns.object setFrame:NSMakeRect(xpos, ypos, mode.width, mode.height)
                        display:YES];

    return status;
}

// Leave full screen mode
//
static void leaveFullscreenMode(_GLFWwindow* window)
{
    _glfwRestoreVideoMode(window->monitor);
}

// Transforms the specified y-coordinate between the CG display and NS screen
// coordinate systems
//
static float transformY(float y)
{
    const float height = CGDisplayBounds(CGMainDisplayID()).size.height;
    return height - y;
}

// Returns the backing rect of the specified window
//
static NSRect convertRectToBacking(_GLFWwindow* window, NSRect contentRect)
{
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
        return [window->ns.view convertRectToBacking:contentRect];
    else
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/
        return contentRect;
}

// Translates OS X key modifiers into GLFW ones
//
static int translateFlags(NSUInteger flags)
{
    int mods = 0;

    if (flags & NSShiftKeyMask)
        mods |= GLFW_MOD_SHIFT;
    if (flags & NSControlKeyMask)
        mods |= GLFW_MOD_CONTROL;
    if (flags & NSAlternateKeyMask)
        mods |= GLFW_MOD_ALT;
    if (flags & NSCommandKeyMask)
        mods |= GLFW_MOD_SUPER;

    return mods;
}

// Translates a OS X keycode to a GLFW keycode
//
static int translateKey(unsigned int key)
{
    if (key >= sizeof(_glfw.ns.publicKeys) / sizeof(_glfw.ns.publicKeys[0]))
        return GLFW_KEY_UNKNOWN;

    return _glfw.ns.publicKeys[key];
}


//------------------------------------------------------------------------
// Delegate for window related notifications
//------------------------------------------------------------------------

@interface GLFWWindowDelegate : NSObject
{
    _GLFWwindow* window;
}

- (id)initWithGlfwWindow:(_GLFWwindow *)initWindow;

@end

@implementation GLFWWindowDelegate

- (id)initWithGlfwWindow:(_GLFWwindow *)initWindow
{
    self = [super init];
    if (self != nil)
        window = initWindow;

    return self;
}

- (BOOL)windowShouldClose:(id)sender
{
    _glfwInputWindowCloseRequest(window);
    return NO;
}

- (void)windowDidResize:(NSNotification *)notification
{
    [window->nsgl.context update];

    if (_glfw.cursorWindow == window &&
        window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        centerCursor(window);
    }

    const NSRect contentRect = [window->ns.view frame];
    const NSRect fbRect = convertRectToBacking(window, contentRect);

    _glfwInputFramebufferSize(window, fbRect.size.width, fbRect.size.height);
    _glfwInputWindowSize(window, contentRect.size.width, contentRect.size.height);
}

- (void)windowDidMove:(NSNotification *)notification
{
    [window->nsgl.context update];

    if (_glfw.cursorWindow == window &&
        window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        centerCursor(window);
    }

    int x, y;
    _glfwPlatformGetWindowPos(window, &x, &y);
    _glfwInputWindowPos(window, x, y);
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
    if (window->monitor)
        leaveFullscreenMode(window);

    _glfwInputWindowIconify(window, GL_TRUE);
}

- (void)windowDidDeminiaturize:(NSNotification *)notification
{
    if (window->monitor)
        enterFullscreenMode(window);

    _glfwInputWindowIconify(window, GL_FALSE);
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    if (_glfw.cursorWindow == window &&
        window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        centerCursor(window);
    }

    _glfwInputWindowFocus(window, GL_TRUE);
    _glfwPlatformApplyCursorMode(window);
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    if (window->monitor && window->autoIconify)
        _glfwPlatformIconifyWindow(window);

    _glfwInputWindowFocus(window, GL_FALSE);
}

@end


//------------------------------------------------------------------------
// Delegate for application related notifications
//------------------------------------------------------------------------

@interface GLFWApplicationDelegate : NSObject
@end

@implementation GLFWApplicationDelegate

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    _GLFWwindow* window;

    for (window = _glfw.windowListHead;  window;  window = window->next)
        _glfwInputWindowCloseRequest(window);

    return NSTerminateCancel;
}

- (void)applicationDidChangeScreenParameters:(NSNotification *) notification
{
    _glfwInputMonitorChange();
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [NSApp stop:nil];

    _glfwPlatformPostEmptyEvent();
}

- (void)applicationDidHide:(NSNotification *)notification
{
    int i;

    for (i = 0;  i < _glfw.monitorCount;  i++)
        _glfwRestoreVideoMode(_glfw.monitors[i]);
}

@end


//------------------------------------------------------------------------
// Content view class for the GLFW window
//------------------------------------------------------------------------

@interface GLFWContentView : NSView
{
    _GLFWwindow* window;
    NSTrackingArea* trackingArea;
}

- (id)initWithGlfwWindow:(_GLFWwindow *)initWindow;

@end

@implementation GLFWContentView

+ (void)initialize
{
    if (self == [GLFWContentView class])
    {
        if (_glfw.ns.cursor == nil)
        {
            NSImage* data = [[NSImage alloc] initWithSize:NSMakeSize(16, 16)];
            _glfw.ns.cursor = [[NSCursor alloc] initWithImage:data
                                                      hotSpot:NSZeroPoint];
            [data release];
        }
    }
}

- (id)initWithGlfwWindow:(_GLFWwindow *)initWindow
{
    self = [super init];
    if (self != nil)
    {
        window = initWindow;
        trackingArea = nil;

        [self updateTrackingAreas];
        [self registerForDraggedTypes:[NSArray arrayWithObjects:
                                       NSFilenamesPboardType, nil]];
    }

    return self;
}

-(void)dealloc
{
    [trackingArea release];
    [super dealloc];
}

- (BOOL)isOpaque
{
    return YES;
}

- (BOOL)canBecomeKeyView
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)cursorUpdate:(NSEvent *)event
{
    updateModeCursor(window);
}

- (void)mouseDown:(NSEvent *)event
{
    _glfwInputMouseClick(window,
                         GLFW_MOUSE_BUTTON_LEFT,
                         GLFW_PRESS,
                         translateFlags([event modifierFlags]));
}

- (void)mouseDragged:(NSEvent *)event
{
    [self mouseMoved:event];
}

- (void)mouseUp:(NSEvent *)event
{
    _glfwInputMouseClick(window,
                         GLFW_MOUSE_BUTTON_LEFT,
                         GLFW_RELEASE,
                         translateFlags([event modifierFlags]));
}

- (void)mouseMoved:(NSEvent *)event
{
    if (window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        _glfwInputCursorMotion(window,
                               [event deltaX] - window->ns.warpDeltaX,
                               [event deltaY] - window->ns.warpDeltaY);
    }
    else
    {
        const NSRect contentRect = [window->ns.view frame];
        const NSPoint pos = [event locationInWindow];

        _glfwInputCursorMotion(window, pos.x, contentRect.size.height - pos.y);
    }

    window->ns.warpDeltaX = 0;
    window->ns.warpDeltaY = 0;
}

- (void)rightMouseDown:(NSEvent *)event
{
    _glfwInputMouseClick(window,
                         GLFW_MOUSE_BUTTON_RIGHT,
                         GLFW_PRESS,
                         translateFlags([event modifierFlags]));
}

- (void)rightMouseDragged:(NSEvent *)event
{
    [self mouseMoved:event];
}

- (void)rightMouseUp:(NSEvent *)event
{
    _glfwInputMouseClick(window,
                         GLFW_MOUSE_BUTTON_RIGHT,
                         GLFW_RELEASE,
                         translateFlags([event modifierFlags]));
}

- (void)otherMouseDown:(NSEvent *)event
{
    _glfwInputMouseClick(window,
                         (int) [event buttonNumber],
                         GLFW_PRESS,
                         translateFlags([event modifierFlags]));
}

- (void)otherMouseDragged:(NSEvent *)event
{
    [self mouseMoved:event];
}

- (void)otherMouseUp:(NSEvent *)event
{
    _glfwInputMouseClick(window,
                         (int) [event buttonNumber],
                         GLFW_RELEASE,
                         translateFlags([event modifierFlags]));
}

- (void)mouseExited:(NSEvent *)event
{
    _glfwInputCursorEnter(window, GL_FALSE);
}

- (void)mouseEntered:(NSEvent *)event
{
    _glfwInputCursorEnter(window, GL_TRUE);
}

- (void)viewDidChangeBackingProperties
{
    const NSRect contentRect = [window->ns.view frame];
    const NSRect fbRect = convertRectToBacking(window, contentRect);

    _glfwInputFramebufferSize(window, fbRect.size.width, fbRect.size.height);
}

- (void)drawRect:(NSRect)rect
{
    _glfwInputWindowDamage(window);
}

- (void)updateTrackingAreas
{
    if (trackingArea != nil)
    {
        [self removeTrackingArea:trackingArea];
        [trackingArea release];
    }

    const NSTrackingAreaOptions options = NSTrackingMouseEnteredAndExited |
                                          NSTrackingActiveInKeyWindow |
                                          NSTrackingEnabledDuringMouseDrag |
                                          NSTrackingCursorUpdate |
                                          NSTrackingInVisibleRect |
                                          NSTrackingAssumeInside;

    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                options:options
                                                  owner:self
                                               userInfo:nil];

    [self addTrackingArea:trackingArea];
    [super updateTrackingAreas];
}

- (void)keyDown:(NSEvent *)event
{
    const int key = translateKey([event keyCode]);
    const int mods = translateFlags([event modifierFlags]);

    _glfwInputKey(window, key, [event keyCode], GLFW_PRESS, mods);

    NSString* characters = [event characters];
    NSUInteger i, length = [characters length];
    const int plain = !(mods & GLFW_MOD_SUPER);

    for (i = 0;  i < length;  i++)
    {
        const unichar codepoint = [characters characterAtIndex:i];
        if ((codepoint & 0xff00) == 0xf700)
            continue;

        _glfwInputChar(window, codepoint, mods, plain);
    }
}

- (void)flagsChanged:(NSEvent *)event
{
    int action;
    const unsigned int modifierFlags =
        [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    const int key = translateKey([event keyCode]);
    const int mods = translateFlags(modifierFlags);

    if (modifierFlags == window->ns.modifierFlags)
    {
        if (window->keys[key] == GLFW_PRESS)
            action = GLFW_RELEASE;
        else
            action = GLFW_PRESS;
    }
    else if (modifierFlags > window->ns.modifierFlags)
        action = GLFW_PRESS;
    else
        action = GLFW_RELEASE;

    window->ns.modifierFlags = modifierFlags;

    _glfwInputKey(window, key, [event keyCode], action, mods);
}

- (void)keyUp:(NSEvent *)event
{
    const int key = translateKey([event keyCode]);
    const int mods = translateFlags([event modifierFlags]);
    _glfwInputKey(window, key, [event keyCode], GLFW_RELEASE, mods);
}

- (void)scrollWheel:(NSEvent *)event
{
    double deltaX, deltaY;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
    {
        deltaX = [event scrollingDeltaX];
        deltaY = [event scrollingDeltaY];

        if ([event hasPreciseScrollingDeltas])
        {
            deltaX *= 0.1;
            deltaY *= 0.1;
        }
    }
    else
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/
    {
        deltaX = [event deltaX];
        deltaY = [event deltaY];
    }

    if (fabs(deltaX) > 0.0 || fabs(deltaY) > 0.0)
        _glfwInputScroll(window, deltaX, deltaY);
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask])
        == NSDragOperationGeneric)
    {
        [self setNeedsDisplay:YES];
        return NSDragOperationGeneric;
    }

    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard* pasteboard = [sender draggingPasteboard];
    NSArray* files = [pasteboard propertyListForType:NSFilenamesPboardType];

    const NSRect contentRect = [window->ns.view frame];
    _glfwInputCursorMotion(window,
                           [sender draggingLocation].x,
                           contentRect.size.height - [sender draggingLocation].y);

    const int count = [files count];
    if (count)
    {
        NSEnumerator* e = [files objectEnumerator];
        char** paths = calloc(count, sizeof(char*));
        int i;

        for (i = 0;  i < count;  i++)
            paths[i] = strdup([[e nextObject] UTF8String]);

        _glfwInputDrop(window, count, (const char**) paths);

        for (i = 0;  i < count;  i++)
            free(paths[i]);
        free(paths);
    }

    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    [self setNeedsDisplay:YES];
}

@end


//------------------------------------------------------------------------
// GLFW window class
//------------------------------------------------------------------------

@interface GLFWWindow : NSWindow {}
@end

@implementation GLFWWindow

- (BOOL)canBecomeKeyWindow
{
    // Required for NSBorderlessWindowMask windows
    return YES;
}

@end


//------------------------------------------------------------------------
// GLFW application class
//------------------------------------------------------------------------

@interface GLFWApplication : NSApplication
@end

@implementation GLFWApplication

// From http://cocoadev.com/index.pl?GameKeyboardHandlingAlmost
// This works around an AppKit bug, where key up events while holding
// down the command key don't get sent to the key window.
- (void)sendEvent:(NSEvent *)event
{
    if ([event type] == NSKeyUp && ([event modifierFlags] & NSCommandKeyMask))
        [[self keyWindow] sendEvent:event];
    else
        [super sendEvent:event];
}

@end

#if defined(_GLFW_USE_MENUBAR)

// Try to figure out what the calling application is called
//
static NSString* findAppName(void)
{
    size_t i;
    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];

    // Keys to search for as potential application names
    NSString* GLFWNameKeys[] =
    {
        @"CFBundleDisplayName",
        @"CFBundleName",
        @"CFBundleExecutable",
    };

    for (i = 0;  i < sizeof(GLFWNameKeys) / sizeof(GLFWNameKeys[0]);  i++)
    {
        id name = [infoDictionary objectForKey:GLFWNameKeys[i]];
        if (name &&
            [name isKindOfClass:[NSString class]] &&
            ![name isEqualToString:@""])
        {
            return name;
        }
    }

    char** progname = _NSGetProgname();
    if (progname && *progname)
        return [NSString stringWithUTF8String:*progname];

    // Really shouldn't get here
    return @"GLFW Application";
}

// Set up the menu bar (manually)
// This is nasty, nasty stuff -- calls to undocumented semi-private APIs that
// could go away at any moment, lots of stuff that really should be
// localize(d|able), etc.  Loading a nib would save us this horror, but that
// doesn't seem like a good thing to require of GLFW users.
//
static void createMenuBar(void)
{
    NSString* appName = findAppName();

    NSMenu* bar = [[NSMenu alloc] init];
    [NSApp setMainMenu:bar];

    NSMenuItem* appMenuItem =
        [bar addItemWithTitle:@"" action:NULL keyEquivalent:@""];
    NSMenu* appMenu = [[NSMenu alloc] init];
    [appMenuItem setSubmenu:appMenu];

    [appMenu addItemWithTitle:[NSString stringWithFormat:@"About %@", appName]
                       action:@selector(orderFrontStandardAboutPanel:)
                keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    NSMenu* servicesMenu = [[NSMenu alloc] init];
    [NSApp setServicesMenu:servicesMenu];
    [[appMenu addItemWithTitle:@"Services"
                       action:NULL
                keyEquivalent:@""] setSubmenu:servicesMenu];
    [servicesMenu release];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:[NSString stringWithFormat:@"Hide %@", appName]
                       action:@selector(hide:)
                keyEquivalent:@"h"];
    [[appMenu addItemWithTitle:@"Hide Others"
                       action:@selector(hideOtherApplications:)
                keyEquivalent:@"h"]
        setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];
    [appMenu addItemWithTitle:@"Show All"
                       action:@selector(unhideAllApplications:)
                keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:[NSString stringWithFormat:@"Quit %@", appName]
                       action:@selector(terminate:)
                keyEquivalent:@"q"];

    NSMenuItem* windowMenuItem =
        [bar addItemWithTitle:@"" action:NULL keyEquivalent:@""];
    [bar release];
    NSMenu* windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [NSApp setWindowsMenu:windowMenu];
    [windowMenuItem setSubmenu:windowMenu];

    [windowMenu addItemWithTitle:@"Minimize"
                          action:@selector(performMiniaturize:)
                   keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom"
                          action:@selector(performZoom:)
                   keyEquivalent:@""];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItemWithTitle:@"Bring All to Front"
                          action:@selector(arrangeInFront:)
                   keyEquivalent:@""];

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
    {
        // TODO: Make this appear at the bottom of the menu (for consistency)

        [windowMenu addItem:[NSMenuItem separatorItem]];
        [[windowMenu addItemWithTitle:@"Enter Full Screen"
                               action:@selector(toggleFullScreen:)
                        keyEquivalent:@"f"]
            setKeyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask];
    }
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/

    // Prior to Snow Leopard, we need to use this oddly-named semi-private API
    // to get the application menu working properly.
    SEL setAppleMenuSelector = NSSelectorFromString(@"setAppleMenu:");
    [NSApp performSelector:setAppleMenuSelector withObject:appMenu];
}

#endif /* _GLFW_USE_MENUBAR */

// Initialize the Cocoa Application Kit
//
static GLboolean initializeAppKit(void)
{
    if (NSApp)
        return GL_TRUE;

    // Implicitly create shared NSApplication instance
    [GLFWApplication sharedApplication];

    // In case we are unbundled, make us a proper UI application
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

#if defined(_GLFW_USE_MENUBAR)
    // Menu bar setup must go between sharedApplication above and
    // finishLaunching below, in order to properly emulate the behavior
    // of NSApplicationMain
    createMenuBar();
#endif

    // There can only be one application delegate, but we allocate it the
    // first time a window is created to keep all window code in this file
    _glfw.ns.delegate = [[GLFWApplicationDelegate alloc] init];
    if (_glfw.ns.delegate == nil)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Cocoa: Failed to create application delegate");
        return GL_FALSE;
    }

    [NSApp setDelegate:_glfw.ns.delegate];
    [NSApp run];

    return GL_TRUE;
}

// Create the Cocoa window
//
static GLboolean createWindow(_GLFWwindow* window,
                              const _GLFWwndconfig* wndconfig)
{
    window->ns.delegate = [[GLFWWindowDelegate alloc] initWithGlfwWindow:window];
    if (window->ns.delegate == nil)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Cocoa: Failed to create window delegate");
        return GL_FALSE;
    }

    unsigned int styleMask = 0;

    if (wndconfig->monitor || !wndconfig->decorated)
        styleMask = NSBorderlessWindowMask;
    else
    {
        styleMask = NSTitledWindowMask | NSClosableWindowMask |
                    NSMiniaturizableWindowMask;

        if (wndconfig->resizable)
            styleMask |= NSResizableWindowMask;
    }

    NSRect contentRect;

    if (wndconfig->monitor)
    {
        GLFWvidmode mode;
        int xpos, ypos;

        _glfwPlatformGetVideoMode(window->monitor, &mode);
        _glfwPlatformGetMonitorPos(window->monitor, &xpos, &ypos);

        contentRect = NSMakeRect(xpos, ypos, mode.width, mode.height);
    }
    else
        contentRect = NSMakeRect(0, 0, wndconfig->width, wndconfig->height);

    window->ns.object = [[GLFWWindow alloc]
        initWithContentRect:contentRect
                  styleMask:styleMask
                    backing:NSBackingStoreBuffered
                      defer:NO];

    if (window->ns.object == nil)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "Cocoa: Failed to create window");
        return GL_FALSE;
    }

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
    {
        if (wndconfig->resizable)
            [window->ns.object setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    }
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/

    if (wndconfig->monitor)
    {
        [window->ns.object setLevel:NSMainMenuWindowLevel + 1];
    }
    else
    {
        [window->ns.object center];

        if (wndconfig->floating)
            [window->ns.object setLevel:NSFloatingWindowLevel];
    }

    window->ns.view = [[GLFWContentView alloc] initWithGlfwWindow:window];

#if defined(_GLFW_USE_RETINA)
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
        [window->ns.view setWantsBestResolutionOpenGLSurface:YES];
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/
#endif /*_GLFW_USE_RETINA*/

    [window->ns.object setTitle:[NSString stringWithUTF8String:wndconfig->title]];
    [window->ns.object setDelegate:window->ns.delegate];
    [window->ns.object setAcceptsMouseMovedEvents:YES];
    [window->ns.object setContentView:window->ns.view];

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
        [window->ns.object setRestorable:NO];
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/

    return GL_TRUE;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformCreateWindow(_GLFWwindow* window,
                              const _GLFWwndconfig* wndconfig,
                              const _GLFWctxconfig* ctxconfig,
                              const _GLFWfbconfig* fbconfig)
{
    if (!initializeAppKit())
        return GL_FALSE;

    if (!createWindow(window, wndconfig))
        return GL_FALSE;

    if (!_glfwCreateContext(window, ctxconfig, fbconfig))
        return GL_FALSE;

    [window->nsgl.context setView:window->ns.view];

    if (wndconfig->monitor)
    {
        _glfwPlatformShowWindow(window);
        if (!enterFullscreenMode(window))
            return GL_FALSE;
    }

    return GL_TRUE;
}

void _glfwPlatformDestroyWindow(_GLFWwindow* window)
{
    [window->ns.object orderOut:nil];

    if (window->monitor)
        leaveFullscreenMode(window);

    _glfwDestroyContext(window);

    [window->ns.object setDelegate:nil];
    [window->ns.delegate release];
    window->ns.delegate = nil;

    [window->ns.view release];
    window->ns.view = nil;

    [window->ns.object close];
    window->ns.object = nil;
}

void _glfwPlatformSetWindowTitle(_GLFWwindow* window, const char *title)
{
    [window->ns.object setTitle:[NSString stringWithUTF8String:title]];
}

void _glfwPlatformGetWindowPos(_GLFWwindow* window, int* xpos, int* ypos)
{
    const NSRect contentRect =
        [window->ns.object contentRectForFrameRect:[window->ns.object frame]];

    if (xpos)
        *xpos = contentRect.origin.x;
    if (ypos)
        *ypos = transformY(contentRect.origin.y + contentRect.size.height);
}

void _glfwPlatformSetWindowPos(_GLFWwindow* window, int x, int y)
{
    const NSRect contentRect = [window->ns.view frame];
    const NSRect dummyRect = NSMakeRect(x, transformY(y + contentRect.size.height), 0, 0);
    const NSRect frameRect = [window->ns.object frameRectForContentRect:dummyRect];
    [window->ns.object setFrameOrigin:frameRect.origin];
}

void _glfwPlatformGetWindowSize(_GLFWwindow* window, int* width, int* height)
{
    const NSRect contentRect = [window->ns.view frame];

    if (width)
        *width = contentRect.size.width;
    if (height)
        *height = contentRect.size.height;
}

void _glfwPlatformSetWindowSize(_GLFWwindow* window, int width, int height)
{
    if (window->monitor)
        enterFullscreenMode(window);
    else
        [window->ns.object setContentSize:NSMakeSize(width, height)];
}

void _glfwPlatformGetFramebufferSize(_GLFWwindow* window, int* width, int* height)
{
    const NSRect contentRect = [window->ns.view frame];
    const NSRect fbRect = convertRectToBacking(window, contentRect);

    if (width)
        *width = (int) fbRect.size.width;
    if (height)
        *height = (int) fbRect.size.height;
}

void _glfwPlatformGetWindowFrameSize(_GLFWwindow* window,
                                     int* left, int* top,
                                     int* right, int* bottom)
{
    const NSRect contentRect = [window->ns.view frame];
    const NSRect frameRect = [window->ns.object frameRectForContentRect:contentRect];

    if (left)
        *left = contentRect.origin.x - frameRect.origin.x;
    if (top)
        *top = frameRect.origin.y + frameRect.size.height -
               contentRect.origin.y - contentRect.size.height;
    if (right)
        *right = frameRect.origin.x + frameRect.size.width -
                 contentRect.origin.x - contentRect.size.width;
    if (bottom)
        *bottom = contentRect.origin.y - frameRect.origin.y;
}

void _glfwPlatformIconifyWindow(_GLFWwindow* window)
{
    [window->ns.object miniaturize:nil];
}

void _glfwPlatformRestoreWindow(_GLFWwindow* window)
{
    [window->ns.object deminiaturize:nil];
}

void _glfwPlatformShowWindow(_GLFWwindow* window)
{
    // Make us the active application
    // HACK: This has been moved here from initializeAppKit to prevent
    //       applications using only hidden windows from being activated, but
    //       should probably not be done every time any window is shown
    [NSApp activateIgnoringOtherApps:YES];

    [window->ns.object makeKeyAndOrderFront:nil];
}

void _glfwPlatformUnhideWindow(_GLFWwindow* window)
{
    [window->ns.object orderFront:nil];
}

void _glfwPlatformHideWindow(_GLFWwindow* window)
{
    [window->ns.object orderOut:nil];
}

int _glfwPlatformWindowFocused(_GLFWwindow* window)
{
    return [window->ns.object isKeyWindow];
}

int _glfwPlatformWindowIconified(_GLFWwindow* window)
{
    return [window->ns.object isMiniaturized];
}

int _glfwPlatformWindowVisible(_GLFWwindow* window)
{
    return [window->ns.object isVisible];
}

void _glfwPlatformPollEvents(void)
{
    for (;;)
    {
        NSEvent* event = [NSApp nextEventMatchingMask:NSAnyEventMask
                                            untilDate:[NSDate distantPast]
                                               inMode:NSDefaultRunLoopMode
                                              dequeue:YES];
        if (event == nil)
            break;

        [NSApp sendEvent:event];
    }

    [_glfw.ns.autoreleasePool drain];
    _glfw.ns.autoreleasePool = [[NSAutoreleasePool alloc] init];
}

void _glfwPlatformWaitEvents(void)
{
    // I wanted to pass NO to dequeue:, and rely on PollEvents to
    // dequeue and send.  For reasons not at all clear to me, passing
    // NO to dequeue: causes this method never to return.
    NSEvent *event = [NSApp nextEventMatchingMask:NSAnyEventMask
                                        untilDate:[NSDate distantFuture]
                                           inMode:NSDefaultRunLoopMode
                                          dequeue:YES];
    [NSApp sendEvent:event];

    _glfwPlatformPollEvents();
}

void _glfwPlatformPostEmptyEvent(void)
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSEvent* event = [NSEvent otherEventWithType:NSApplicationDefined
                                        location:NSMakePoint(0, 0)
                                   modifierFlags:0
                                       timestamp:0
                                    windowNumber:0
                                         context:nil
                                         subtype:0
                                           data1:0
                                           data2:0];
    [NSApp postEvent:event atStart:YES];
    [pool drain];
}

void _glfwPlatformGetCursorPos(_GLFWwindow* window, double* xpos, double* ypos)
{
    const NSRect contentRect = [window->ns.view frame];
    const NSPoint pos = [window->ns.object mouseLocationOutsideOfEventStream];

    if (xpos)
        *xpos = pos.x;
    if (ypos)
        *ypos = contentRect.size.height - pos.y - 1;
}

void _glfwPlatformSetCursorPos(_GLFWwindow* window, double x, double y)
{
    updateModeCursor(window);

    const NSRect contentRect = [window->ns.view frame];
    const NSPoint pos = [window->ns.object mouseLocationOutsideOfEventStream];

    window->ns.warpDeltaX += x - pos.x;
    window->ns.warpDeltaY += y - contentRect.size.height + pos.y;

    if (window->monitor)
    {
        CGDisplayMoveCursorToPoint(window->monitor->ns.displayID,
                                   CGPointMake(x, y));
    }
    else
    {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
        const NSRect localRect = NSMakeRect(x, contentRect.size.height - y - 1, 0, 0);
        const NSRect globalRect = [window->ns.object convertRectToScreen:localRect];
        const NSPoint globalPoint = globalRect.origin;
#else
        const NSPoint localPoint = NSMakePoint(x, contentRect.size.height - y - 1);
        const NSPoint globalPoint = [window->ns.object convertBaseToScreen:localPoint];
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/

        CGWarpMouseCursorPosition(CGPointMake(globalPoint.x,
                                              transformY(globalPoint.y)));
    }
}

void _glfwPlatformApplyCursorMode(_GLFWwindow* window)
{
    updateModeCursor(window);

    if (window->cursorMode == GLFW_CURSOR_DISABLED)
        CGAssociateMouseAndMouseCursorPosition(false);
    else
        CGAssociateMouseAndMouseCursorPosition(true);
}

int _glfwPlatformCreateCursor(_GLFWcursor* cursor,
                              const GLFWimage* image,
                              int xhot, int yhot)
{
    NSImage* native;
    NSBitmapImageRep* rep;

    if (!initializeAppKit())
        return GL_FALSE;

    rep = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL
                      pixelsWide:image->width
                      pixelsHigh:image->height
                   bitsPerSample:8
                 samplesPerPixel:4
                        hasAlpha:YES
                        isPlanar:NO
                  colorSpaceName:NSCalibratedRGBColorSpace
                    bitmapFormat:NSAlphaNonpremultipliedBitmapFormat
                     bytesPerRow:image->width * 4
                    bitsPerPixel:32];

    if (rep == nil)
        return GL_FALSE;

    memcpy([rep bitmapData], image->pixels, image->width * image->height * 4);

    native = [[NSImage alloc] initWithSize:NSMakeSize(image->width, image->height)];
    [native addRepresentation: rep];

    cursor->ns.object = [[NSCursor alloc] initWithImage:native
                                                hotSpot:NSMakePoint(xhot, yhot)];

    [native release];
    [rep release];

    if (cursor->ns.object == nil)
        return GL_FALSE;

    return GL_TRUE;
}

int _glfwPlatformCreateStandardCursor(_GLFWcursor* cursor, int shape)
{
    if (!initializeAppKit())
        return GL_FALSE;

    cursor->ns.object = getStandardCursor(shape);
    if (!cursor->ns.object)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Cocoa: Failed to retrieve standard cursor");
        return GL_FALSE;
    }

    [cursor->ns.object retain];
    return GL_TRUE;
}

void _glfwPlatformDestroyCursor(_GLFWcursor* cursor)
{
    if (cursor->ns.object)
        [(NSCursor*) cursor->ns.object release];
}

void _glfwPlatformSetCursor(_GLFWwindow* window, _GLFWcursor* cursor)
{
    const NSPoint pos = [window->ns.object mouseLocationOutsideOfEventStream];

    if (window->cursorMode == GLFW_CURSOR_NORMAL &&
        [window->ns.view mouse:pos inRect:[window->ns.view frame]])
    {
        if (cursor)
            [(NSCursor*) cursor->ns.object set];
        else
            [[NSCursor arrowCursor] set];
    }
}

void _glfwPlatformSetClipboardString(_GLFWwindow* window, const char* string)
{
    NSArray* types = [NSArray arrayWithObjects:NSStringPboardType, nil];

    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:types owner:nil];
    [pasteboard setString:[NSString stringWithUTF8String:string]
                  forType:NSStringPboardType];
}

const char* _glfwPlatformGetClipboardString(_GLFWwindow* window)
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];

    if (![[pasteboard types] containsObject:NSStringPboardType])
    {
        _glfwInputError(GLFW_FORMAT_UNAVAILABLE,
                        "Cocoa: Failed to retrieve string from pasteboard");
        return NULL;
    }

    NSString* object = [pasteboard stringForType:NSStringPboardType];
    if (!object)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Cocoa: Failed to retrieve object from pasteboard");
        return NULL;
    }

    free(_glfw.ns.clipboardString);
    _glfw.ns.clipboardString = strdup([object UTF8String]);

    return _glfw.ns.clipboardString;
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI id glfwGetCocoaWindow(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(nil);
    return window->ns.object;
}


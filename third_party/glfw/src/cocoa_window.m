//========================================================================
// GLFW 3.2 OS X - www.glfw.org
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

#include <float.h>
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

// Returns the style mask corresponding to the window settings
//
static NSUInteger getStyleMask(_GLFWwindow* window)
{
    NSUInteger styleMask = 0;

    if (window->monitor || !window->decorated)
        styleMask |= NSBorderlessWindowMask;
    else
    {
        styleMask |= NSTitledWindowMask | NSClosableWindowMask |
                     NSMiniaturizableWindowMask;

        if (window->resizable)
            styleMask |= NSResizableWindowMask;
    }

    return styleMask;
}

// Center the cursor in the view of the window
//
static void centerCursor(_GLFWwindow *window)
{
    int width, height;
    _glfwPlatformGetWindowSize(window, &width, &height);
    _glfwPlatformSetCursorPos(window, width / 2.0, height / 2.0);
}

// Transforms the specified y-coordinate between the CG display and NS screen
// coordinate systems
//
static float transformY(float y)
{
    return CGDisplayBounds(CGMainDisplayID()).size.height - y;
}

// Make the specified window and its video mode active on its monitor
//
static GLFWbool acquireMonitor(_GLFWwindow* window)
{
    const GLFWbool status = _glfwSetVideoModeNS(window->monitor, &window->videoMode);
    const CGRect bounds = CGDisplayBounds(window->monitor->ns.displayID);
    const NSRect frame = NSMakeRect(bounds.origin.x,
                                    transformY(bounds.origin.y + bounds.size.height),
                                    bounds.size.width,
                                    bounds.size.height);

    [window->ns.object setFrame:frame display:YES];

    _glfwInputMonitorWindowChange(window->monitor, window);
    return status;
}

// Remove the window and restore the original video mode
//
static void releaseMonitor(_GLFWwindow* window)
{
    if (window->monitor->window != window)
        return;

    _glfwInputMonitorWindowChange(window->monitor, NULL);
    _glfwRestoreVideoModeNS(window->monitor);
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

// Translate a GLFW keycode to a Cocoa modifier flag
//
static NSUInteger translateKeyToModifierFlag(int key)
{
    switch (key)
    {
        case GLFW_KEY_LEFT_SHIFT:
        case GLFW_KEY_RIGHT_SHIFT:
            return NSShiftKeyMask;
        case GLFW_KEY_LEFT_CONTROL:
        case GLFW_KEY_RIGHT_CONTROL:
            return NSControlKeyMask;
        case GLFW_KEY_LEFT_ALT:
        case GLFW_KEY_RIGHT_ALT:
            return NSAlternateKeyMask;
        case GLFW_KEY_LEFT_SUPER:
        case GLFW_KEY_RIGHT_SUPER:
            return NSCommandKeyMask;
    }

    return 0;
}

// Defines a constant for empty ranges in NSTextInputClient
//
static const NSRange kEmptyRange = { NSNotFound, 0 };


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
    if (window->context.api != GLFW_NO_API)
        [window->context.nsgl.object update];

    if (_glfw.cursorWindow == window &&
        window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        centerCursor(window);
    }

    const NSRect contentRect = [window->ns.view frame];
    const NSRect fbRect = [window->ns.view convertRectToBacking:contentRect];

    _glfwInputFramebufferSize(window, fbRect.size.width, fbRect.size.height);
    _glfwInputWindowSize(window, contentRect.size.width, contentRect.size.height);
}

- (void)windowDidMove:(NSNotification *)notification
{
    if (window->context.api != GLFW_NO_API)
        [window->context.nsgl.object update];

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
        releaseMonitor(window);

    _glfwInputWindowIconify(window, GLFW_TRUE);
}

- (void)windowDidDeminiaturize:(NSNotification *)notification
{
    if (window->monitor)
        acquireMonitor(window);

    _glfwInputWindowIconify(window, GLFW_FALSE);
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    if (_glfw.cursorWindow == window &&
        window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        centerCursor(window);
    }

    _glfwInputWindowFocus(window, GLFW_TRUE);
    _glfwPlatformSetCursorMode(window, window->cursorMode);
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    if (window->monitor && window->autoIconify)
        _glfwPlatformIconifyWindow(window);

    _glfwInputWindowFocus(window, GLFW_FALSE);
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
        _glfwRestoreVideoModeNS(_glfw.monitors[i]);
}

@end


//------------------------------------------------------------------------
// Content view class for the GLFW window
//------------------------------------------------------------------------

@interface GLFWContentView : NSView <NSTextInputClient>
{
    _GLFWwindow* window;
    NSTrackingArea* trackingArea;
    NSMutableAttributedString* markedText;
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
        markedText = [[NSMutableAttributedString alloc] init];

        [self updateTrackingAreas];
        [self registerForDraggedTypes:[NSArray arrayWithObjects:
                                       NSFilenamesPboardType, nil]];
    }

    return self;
}

- (void)dealloc
{
    [trackingArea release];
    [markedText release];
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
    _glfwPlatformSetCursorMode(window, window->cursorMode);
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
    _glfwInputCursorEnter(window, GLFW_FALSE);
}

- (void)mouseEntered:(NSEvent *)event
{
    _glfwInputCursorEnter(window, GLFW_TRUE);
}

- (void)viewDidChangeBackingProperties
{
    const NSRect contentRect = [window->ns.view frame];
    const NSRect fbRect = [window->ns.view convertRectToBacking:contentRect];

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

    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

- (void)flagsChanged:(NSEvent *)event
{
    int action;
    const unsigned int modifierFlags =
        [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    const int key = translateKey([event keyCode]);
    const int mods = translateFlags(modifierFlags);
    const NSUInteger keyFlag = translateKeyToModifierFlag(key);

    if (keyFlag & modifierFlags)
    {
        if (window->keys[key] == GLFW_PRESS)
            action = GLFW_RELEASE;
        else
            action = GLFW_PRESS;
    }
    else
        action = GLFW_RELEASE;

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

    deltaX = [event scrollingDeltaX];
    deltaY = [event scrollingDeltaY];

    if ([event hasPreciseScrollingDeltas])
    {
        deltaX *= 0.1;
        deltaY *= 0.1;
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

- (BOOL)hasMarkedText
{
    return [markedText length] > 0;
}

- (NSRange)markedRange
{
    if ([markedText length] > 0)
        return NSMakeRange(0, [markedText length] - 1);
    else
        return kEmptyRange;
}

- (NSRange)selectedRange
{
    return kEmptyRange;
}

- (void)setMarkedText:(id)string
        selectedRange:(NSRange)selectedRange
     replacementRange:(NSRange)replacementRange
{
    if ([string isKindOfClass:[NSAttributedString class]])
        [markedText initWithAttributedString:string];
    else
        [markedText initWithString:string];
}

- (void)unmarkText
{
    [[markedText mutableString] setString:@""];
}

- (NSArray*)validAttributesForMarkedText
{
    return [NSArray array];
}

- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)range
                                               actualRange:(NSRangePointer)actualRange
{
    return nil;
}

- (NSUInteger)characterIndexForPoint:(NSPoint)point
{
    return 0;
}

- (NSRect)firstRectForCharacterRange:(NSRange)range
                         actualRange:(NSRangePointer)actualRange
{
    int xpos, ypos;
    _glfwPlatformGetWindowPos(window, &xpos, &ypos);
    const NSRect contentRect = [window->ns.view frame];
    return NSMakeRect(xpos, transformY(ypos + contentRect.size.height), 0.0, 0.0);
}

- (void)insertText:(id)string replacementRange:(NSRange)replacementRange
{
    NSString* characters;
    NSEvent* event = [NSApp currentEvent];
    const int mods = translateFlags([event modifierFlags]);
    const int plain = !(mods & GLFW_MOD_SUPER);

    if ([string isKindOfClass:[NSAttributedString class]])
        characters = [string string];
    else
        characters = (NSString*) string;

    NSUInteger i, length = [characters length];

    for (i = 0;  i < length;  i++)
    {
        const unichar codepoint = [characters characterAtIndex:i];
        if ((codepoint & 0xff00) == 0xf700)
            continue;

        _glfwInputChar(window, codepoint, mods, plain);
    }
}

- (void)doCommandBySelector:(SEL)selector
{
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

    // TODO: Make this appear at the bottom of the menu (for consistency)
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [[windowMenu addItemWithTitle:@"Enter Full Screen"
                           action:@selector(toggleFullScreen:)
                    keyEquivalent:@"f"]
     setKeyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask];

    // Prior to Snow Leopard, we need to use this oddly-named semi-private API
    // to get the application menu working properly.
    SEL setAppleMenuSelector = NSSelectorFromString(@"setAppleMenu:");
    [NSApp performSelector:setAppleMenuSelector withObject:appMenu];
}

#endif /* _GLFW_USE_MENUBAR */

// Initialize the Cocoa Application Kit
//
static GLFWbool initializeAppKit(void)
{
    if (NSApp)
        return GLFW_TRUE;

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
        return GLFW_FALSE;
    }

    [NSApp setDelegate:_glfw.ns.delegate];
    [NSApp run];

    return GLFW_TRUE;
}

// Create the Cocoa window
//
static GLFWbool createWindow(_GLFWwindow* window,
                             const _GLFWwndconfig* wndconfig)
{
    window->ns.delegate = [[GLFWWindowDelegate alloc] initWithGlfwWindow:window];
    if (window->ns.delegate == nil)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Cocoa: Failed to create window delegate");
        return GLFW_FALSE;
    }

    NSRect contentRect;

    if (window->monitor)
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
                  styleMask:getStyleMask(window)
                    backing:NSBackingStoreBuffered
                      defer:NO];

    if (window->ns.object == nil)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "Cocoa: Failed to create window");
        return GLFW_FALSE;
    }

    if (window->monitor)
        [window->ns.object setLevel:NSMainMenuWindowLevel + 1];
    else
    {
        [window->ns.object center];

        if (wndconfig->resizable)
            [window->ns.object setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];

        if (wndconfig->floating)
            [window->ns.object setLevel:NSFloatingWindowLevel];

        if (wndconfig->maximized)
            [window->ns.object zoom:nil];
    }

    window->ns.view = [[GLFWContentView alloc] initWithGlfwWindow:window];

#if defined(_GLFW_USE_RETINA)
    [window->ns.view setWantsBestResolutionOpenGLSurface:YES];
#endif /*_GLFW_USE_RETINA*/

    [window->ns.object makeFirstResponder:window->ns.view];
    [window->ns.object setTitle:[NSString stringWithUTF8String:wndconfig->title]];
    [window->ns.object setDelegate:window->ns.delegate];
    [window->ns.object setAcceptsMouseMovedEvents:YES];
    [window->ns.object setContentView:window->ns.view];
    [window->ns.object setRestorable:NO];

    return GLFW_TRUE;
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
        return GLFW_FALSE;

    if (!createWindow(window, wndconfig))
        return GLFW_FALSE;

    if (ctxconfig->api != GLFW_NO_API)
    {
        if (!_glfwCreateContextNSGL(window, ctxconfig, fbconfig))
            return GLFW_FALSE;
    }

    if (window->monitor)
    {
        _glfwPlatformShowWindow(window);
        _glfwPlatformFocusWindow(window);
        if (!acquireMonitor(window))
            return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

void _glfwPlatformDestroyWindow(_GLFWwindow* window)
{
    [window->ns.object orderOut:nil];

    if (window->monitor)
        releaseMonitor(window);

    if (window->context.api != GLFW_NO_API)
        _glfwDestroyContextNSGL(window);

    [window->ns.object setDelegate:nil];
    [window->ns.delegate release];
    window->ns.delegate = nil;

    [window->ns.view release];
    window->ns.view = nil;

    [window->ns.object close];
    window->ns.object = nil;

    [_glfw.ns.autoreleasePool drain];
    _glfw.ns.autoreleasePool = [[NSAutoreleasePool alloc] init];
}

void _glfwPlatformSetWindowTitle(_GLFWwindow* window, const char *title)
{
    [window->ns.object setTitle:[NSString stringWithUTF8String:title]];
}

void _glfwPlatformSetWindowIcon(_GLFWwindow* window,
                                int count, const GLFWimage* images)
{
    // Regular windows do not have icons
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
    {
        if (window->monitor->window == window)
            acquireMonitor(window);
    }
    else
        [window->ns.object setContentSize:NSMakeSize(width, height)];
}

void _glfwPlatformSetWindowSizeLimits(_GLFWwindow* window,
                                      int minwidth, int minheight,
                                      int maxwidth, int maxheight)
{
    if (minwidth == GLFW_DONT_CARE || minheight == GLFW_DONT_CARE)
        [window->ns.object setContentMinSize:NSMakeSize(0, 0)];
    else
        [window->ns.object setContentMinSize:NSMakeSize(minwidth, minheight)];

    if (maxwidth == GLFW_DONT_CARE || maxheight == GLFW_DONT_CARE)
        [window->ns.object setContentMaxSize:NSMakeSize(DBL_MAX, DBL_MAX)];
    else
        [window->ns.object setContentMaxSize:NSMakeSize(maxwidth, maxheight)];
}

void _glfwPlatformSetWindowAspectRatio(_GLFWwindow* window, int numer, int denom)
{
    if (numer == GLFW_DONT_CARE || denom == GLFW_DONT_CARE)
        [window->ns.object setContentAspectRatio:NSMakeSize(0, 0)];
    else
        [window->ns.object setContentAspectRatio:NSMakeSize(numer, denom)];
}

void _glfwPlatformGetFramebufferSize(_GLFWwindow* window, int* width, int* height)
{
    const NSRect contentRect = [window->ns.view frame];
    const NSRect fbRect = [window->ns.view convertRectToBacking:contentRect];

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
    if ([window->ns.object isMiniaturized])
        [window->ns.object deminiaturize:nil];
    else if ([window->ns.object isZoomed])
        [window->ns.object zoom:nil];
}

void _glfwPlatformMaximizeWindow(_GLFWwindow* window)
{
    if (![window->ns.object isZoomed])
        [window->ns.object zoom:nil];
}

void _glfwPlatformShowWindow(_GLFWwindow* window)
{
    [window->ns.object orderFront:nil];
}

void _glfwPlatformHideWindow(_GLFWwindow* window)
{
    [window->ns.object orderOut:nil];
}

void _glfwPlatformFocusWindow(_GLFWwindow* window)
{
    // Make us the active application
    // HACK: This has been moved here from initializeAppKit to prevent
    //       applications using only hidden windows from being activated, but
    //       should probably not be done every time any window is shown
    [NSApp activateIgnoringOtherApps:YES];

    [window->ns.object makeKeyAndOrderFront:nil];
}

void _glfwPlatformSetWindowMonitor(_GLFWwindow* window,
                                   _GLFWmonitor* monitor,
                                   int xpos, int ypos,
                                   int width, int height,
                                   int refreshRate)
{
    if (window->monitor == monitor)
    {
        if (monitor)
        {
            if (monitor->window == window)
                acquireMonitor(window);
        }
        else
        {
            const NSRect contentRect =
                NSMakeRect(xpos, transformY(ypos + height), width, height);
            const NSRect frameRect =
                [window->ns.object frameRectForContentRect:contentRect
                                                 styleMask:getStyleMask(window)];

            [window->ns.object setFrame:frameRect display:YES];
        }

        return;
    }

    if (window->monitor)
        releaseMonitor(window);

    _glfwInputWindowMonitorChange(window, monitor);

    const NSUInteger styleMask = getStyleMask(window);
    [window->ns.object setStyleMask:styleMask];
    [window->ns.object makeFirstResponder:window->ns.view];

    NSRect contentRect;

    if (monitor)
    {
        GLFWvidmode mode;

        _glfwPlatformGetVideoMode(window->monitor, &mode);
        _glfwPlatformGetMonitorPos(window->monitor, &xpos, &ypos);

        contentRect = NSMakeRect(xpos, transformY(ypos + mode.height),
                                    mode.width, mode.height);
    }
    else
    {
        contentRect = NSMakeRect(xpos, transformY(ypos + height),
                                    width, height);
    }

    NSRect frameRect = [window->ns.object frameRectForContentRect:contentRect
                                                        styleMask:styleMask];
    [window->ns.object setFrame:frameRect display:YES];

    if (monitor)
    {
        [window->ns.object setLevel:NSMainMenuWindowLevel + 1];
        [window->ns.object setHasShadow:NO];

        acquireMonitor(window);
    }
    else
    {
        if (window->numer != GLFW_DONT_CARE &&
            window->denom != GLFW_DONT_CARE)
        {
            [window->ns.object setContentAspectRatio:NSMakeSize(window->numer,
                                                                window->denom)];
        }

        if (window->minwidth != GLFW_DONT_CARE &&
            window->minheight != GLFW_DONT_CARE)
        {
            [window->ns.object setContentMinSize:NSMakeSize(window->minwidth,
                                                            window->minheight)];
        }

        if (window->maxwidth != GLFW_DONT_CARE &&
            window->maxheight != GLFW_DONT_CARE)
        {
            [window->ns.object setContentMaxSize:NSMakeSize(window->maxwidth,
                                                            window->maxheight)];
        }

        if (window->floating)
            [window->ns.object setLevel:NSFloatingWindowLevel];
        else
            [window->ns.object setLevel:NSNormalWindowLevel];

        [window->ns.object setHasShadow:YES];
    }
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

int _glfwPlatformWindowMaximized(_GLFWwindow* window)
{
    return [window->ns.object isZoomed];
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

void _glfwPlatformWaitEventsTimeout(double timeout)
{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:timeout];
    NSEvent* event = [NSApp nextEventMatchingMask:NSAnyEventMask
                                        untilDate:date
                                           inMode:NSDefaultRunLoopMode
                                          dequeue:YES];
    if (event)
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
    _glfwPlatformSetCursorMode(window, window->cursorMode);

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
        const NSRect localRect = NSMakeRect(x, contentRect.size.height - y - 1, 0, 0);
        const NSRect globalRect = [window->ns.object convertRectToScreen:localRect];
        const NSPoint globalPoint = globalRect.origin;

        CGWarpMouseCursorPosition(CGPointMake(globalPoint.x,
                                              transformY(globalPoint.y)));
    }
}

void _glfwPlatformSetCursorMode(_GLFWwindow* window, int mode)
{
    if (mode == GLFW_CURSOR_NORMAL)
    {
        if (window->cursor)
            [(NSCursor*) window->cursor->ns.object set];
        else
            [[NSCursor arrowCursor] set];
    }
    else
        [(NSCursor*) _glfw.ns.cursor set];

    if (mode == GLFW_CURSOR_DISABLED)
        CGAssociateMouseAndMouseCursorPosition(false);
    else
        CGAssociateMouseAndMouseCursorPosition(true);
}

const char* _glfwPlatformGetKeyName(int key, int scancode)
{
    if (key != GLFW_KEY_UNKNOWN)
        scancode = _glfw.ns.nativeKeys[key];

    if (!_glfwIsPrintable(_glfw.ns.publicKeys[scancode]))
        return NULL;

    UInt32 deadKeyState = 0;
    UniChar characters[8];
    UniCharCount characterCount = 0;

    if (UCKeyTranslate([(NSData*) _glfw.ns.unicodeData bytes],
                       scancode,
                       kUCKeyActionDisplay,
                       0,
                       LMGetKbdType(),
                       kUCKeyTranslateNoDeadKeysBit,
                       &deadKeyState,
                       sizeof(characters) / sizeof(characters[0]),
                       &characterCount,
                       characters) != noErr)
    {
        return NULL;
    }

    if (!characterCount)
        return NULL;

    CFStringRef string = CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault,
                                                            characters,
                                                            characterCount,
                                                            kCFAllocatorNull);
    CFStringGetCString(string,
                       _glfw.ns.keyName,
                       sizeof(_glfw.ns.keyName),
                       kCFStringEncodingUTF8);
    CFRelease(string);

    return _glfw.ns.keyName;
}

int _glfwPlatformCreateCursor(_GLFWcursor* cursor,
                              const GLFWimage* image,
                              int xhot, int yhot)
{
    NSImage* native;
    NSBitmapImageRep* rep;

    if (!initializeAppKit())
        return GLFW_FALSE;

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
        return GLFW_FALSE;

    memcpy([rep bitmapData], image->pixels, image->width * image->height * 4);

    native = [[NSImage alloc] initWithSize:NSMakeSize(image->width, image->height)];
    [native addRepresentation: rep];

    cursor->ns.object = [[NSCursor alloc] initWithImage:native
                                                hotSpot:NSMakePoint(xhot, yhot)];

    [native release];
    [rep release];

    if (cursor->ns.object == nil)
        return GLFW_FALSE;

    return GLFW_TRUE;
}

int _glfwPlatformCreateStandardCursor(_GLFWcursor* cursor, int shape)
{
    if (!initializeAppKit())
        return GLFW_FALSE;

    cursor->ns.object = getStandardCursor(shape);
    if (!cursor->ns.object)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Cocoa: Failed to retrieve standard cursor");
        return GLFW_FALSE;
    }

    [cursor->ns.object retain];
    return GLFW_TRUE;
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

char** _glfwPlatformGetRequiredInstanceExtensions(unsigned int* count)
{
    *count = 0;
    return NULL;
}

int _glfwPlatformGetPhysicalDevicePresentationSupport(VkInstance instance,
                                                      VkPhysicalDevice device,
                                                      unsigned int queuefamily)
{
    return GLFW_FALSE;
}

VkResult _glfwPlatformCreateWindowSurface(VkInstance instance,
                                          _GLFWwindow* window,
                                          const VkAllocationCallbacks* allocator,
                                          VkSurfaceKHR* surface)
{
    return VK_ERROR_EXTENSION_NOT_PRESENT;
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


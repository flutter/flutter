/*
 * Copyright (c) 2005, 2014, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

/*
 * Header file for packages of paramaters passed between Java Accessibility
 * and native Assistive Technologies
 */

#ifndef __AccessBridgePackages_H__
#define __AccessBridgePackages_H__

#include <jni.h>
#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef ACCESSBRIDGE_ARCH_LEGACY
typedef jobject JOBJECT64;
typedef HWND ABHWND64;
#define ABHandleToLong
#define ABLongToHandle
#else
typedef jlong JOBJECT64;
typedef long ABHWND64;
#define ABHandleToLong HandleToLong
#define ABLongToHandle LongToHandle
#endif

#define MAX_BUFFER_SIZE   10240
#define MAX_STRING_SIZE   1024
#define SHORT_STRING_SIZE   256

    // object types
    typedef JOBJECT64 AccessibleContext;
    typedef JOBJECT64 AccessibleText;
    typedef JOBJECT64 AccessibleValue;
    typedef JOBJECT64 AccessibleSelection;
    typedef JOBJECT64 Java_Object;
    typedef JOBJECT64 PropertyChangeEvent;
    typedef JOBJECT64 FocusEvent;
    typedef JOBJECT64 CaretEvent;
    typedef JOBJECT64 MouseEvent;
    typedef JOBJECT64 MenuEvent;
    typedef JOBJECT64 AccessibleTable;
    typedef JOBJECT64 AccessibleHyperlink;
    typedef JOBJECT64 AccessibleHypertext;

    /**
     ******************************************************
     *  Java event types
     ******************************************************
     */

#define cPropertyChangeEvent (jlong) 1          // 1
#define cFocusGainedEvent (jlong) 2             // 2
#define cFocusLostEvent (jlong) 4               // 4
#define cCaretUpdateEvent (jlong) 8             // 8
#define cMouseClickedEvent (jlong) 16           // 10
#define cMouseEnteredEvent (jlong) 32           // 20
#define cMouseExitedEvent (jlong) 64            // 40
#define cMousePressedEvent (jlong) 128          // 80
#define cMouseReleasedEvent (jlong) 256         // 100
#define cMenuCanceledEvent (jlong) 512          // 200
#define cMenuDeselectedEvent (jlong) 1024       // 400
#define cMenuSelectedEvent (jlong) 2048         // 800
#define cPopupMenuCanceledEvent (jlong) 4096    // 1000
#define cPopupMenuWillBecomeInvisibleEvent (jlong) 8192         // 2000
#define cPopupMenuWillBecomeVisibleEvent (jlong) 16384          // 4000
#define cJavaShutdownEvent (jlong) 32768        // 8000

    /**
     ******************************************************
     *  Accessible Roles
     *      Defines all AccessibleRoles in Local.US
     ******************************************************
     */

    /**
     * Object is used to alert the user about something.
     */
#define ACCESSIBLE_ALERT L"alert"

    /**
     * The header for a column of data.
     */
#define ACCESSIBLE_COLUMN_HEADER L"column header"

    /**
     * Object that can be drawn into and is used to trap
     * events.
     * see ACCESSIBLE_FRAME
     * see ACCESSIBLE_GLASS_PANE
     * see ACCESSIBLE_LAYERED_PANE
     */
#define ACCESSIBLE_CANVAS L"canvas"

    /**
     * A list of choices the user can select from.  Also optionally
     * allows the user to enter a choice of their own.
     */
#define ACCESSIBLE_COMBO_BOX L"combo box"

    /**
     * An iconified internal frame in a DESKTOP_PANE.
     * see ACCESSIBLE_DESKTOP_PANE
     * see ACCESSIBLE_INTERNAL_FRAME
     */
#define ACCESSIBLE_DESKTOP_ICON L"desktop icon"

    /**
     * A frame-like object that is clipped by a desktop pane.  The
     * desktop pane, internal frame, and desktop icon objects are
     * often used to create multiple document interfaces within an
     * application.
     * see ACCESSIBLE_DESKTOP_ICON
     * see ACCESSIBLE_DESKTOP_PANE
     * see ACCESSIBLE_FRAME
     */
#define ACCESSIBLE_INTERNAL_FRAME L"internal frame"

    /**
     * A pane that supports internal frames and
     * iconified versions of those internal frames.
     * see ACCESSIBLE_DESKTOP_ICON
     * see ACCESSIBLE_INTERNAL_FRAME
     */
#define ACCESSIBLE_DESKTOP_PANE L"desktop pane"

    /**
     * A specialized pane whose primary use is inside a DIALOG
     * see ACCESSIBLE_DIALOG
     */
#define ACCESSIBLE_OPTION_PANE L"option pane"

    /**
     * A top level window with no title or border.
     * see ACCESSIBLE_FRAME
     * see ACCESSIBLE_DIALOG
     */
#define ACCESSIBLE_WINDOW L"window"

    /**
     * A top level window with a title bar, border, menu bar, etc.  It is
     * often used as the primary window for an application.
     * see ACCESSIBLE_DIALOG
     * see ACCESSIBLE_CANVAS
     * see ACCESSIBLE_WINDOW
     */
#define ACCESSIBLE_FRAME L"frame"

    /**
     * A top level window with title bar and a border.  A dialog is similar
     * to a frame, but it has fewer properties and is often used as a
     * secondary window for an application.
     * see ACCESSIBLE_FRAME
     * see ACCESSIBLE_WINDOW
     */
#define ACCESSIBLE_DIALOG L"dialog"

    /**
     * A specialized dialog that lets the user choose a color.
     */
#define ACCESSIBLE_COLOR_CHOOSER L"color chooser"


    /**
     * A pane that allows the user to navigate through
     * and select the contents of a directory.  May be used
     * by a file chooser.
     * see ACCESSIBLE_FILE_CHOOSER
     */
#define ACCESSIBLE_DIRECTORY_PANE L"directory pane"

    /**
     * A specialized dialog that displays the files in the directory
     * and lets the user select a file, browse a different directory,
     * or specify a filename.  May use the directory pane to show the
     * contents of a directory.
     * see ACCESSIBLE_DIRECTORY_PANE
     */
#define ACCESSIBLE_FILE_CHOOSER L"file chooser"

    /**
     * An object that fills up space in a user interface.  It is often
     * used in interfaces to tweak the spacing between components,
     * but serves no other purpose.
     */
#define ACCESSIBLE_FILLER L"filler"

    /**
     * A hypertext anchor
     */
#define ACCESSIBLE_HYPERLINK L"hyperlink"

    /**
     * A small fixed size picture, typically used to decorate components.
     */
#define ACCESSIBLE_ICON L"icon"

    /**
     * An object used to present an icon or short string in an interface.
     */
#define ACCESSIBLE_LABEL L"label"

    /**
     * A specialized pane that has a glass pane and a layered pane as its
     * children.
     * see ACCESSIBLE_GLASS_PANE
     * see ACCESSIBLE_LAYERED_PANE
     */
#define ACCESSIBLE_ROOT_PANE L"root pane"

    /**
     * A pane that is guaranteed to be painted on top
     * of all panes beneath it.
     * see ACCESSIBLE_ROOT_PANE
     * see ACCESSIBLE_CANVAS
     */
#define ACCESSIBLE_GLASS_PANE L"glass pane"

    /**
     * A specialized pane that allows its children to be drawn in layers,
     * providing a form of stacking order.  This is usually the pane that
     * holds the menu bar as well as the pane that contains most of the
     * visual components in a window.
     * see ACCESSIBLE_GLASS_PANE
     * see ACCESSIBLE_ROOT_PANE
     */
#define ACCESSIBLE_LAYERED_PANE L"layered pane"

    /**
     * An object that presents a list of objects to the user and allows the
     * user to select one or more of them.  A list is usually contained
     * within a scroll pane.
     * see ACCESSIBLE_SCROLL_PANE
     * see ACCESSIBLE_LIST_ITEM
     */
#define ACCESSIBLE_LIST L"list"

    /**
     * An object that presents an element in a list.  A list is usually
     * contained within a scroll pane.
     * see ACCESSIBLE_SCROLL_PANE
     * see ACCESSIBLE_LIST
     */
#define ACCESSIBLE_LIST_ITEM L"list item"

    /**
     * An object usually drawn at the top of the primary dialog box of
     * an application that contains a list of menus the user can choose
     * from.  For example, a menu bar might contain menus for "File,"
     * "Edit," and "Help."
     * see ACCESSIBLE_MENU
     * see ACCESSIBLE_POPUP_MENU
     * see ACCESSIBLE_LAYERED_PANE
     */
#define ACCESSIBLE_MENU_BAR L"menu bar"

    /**
     * A temporary window that is usually used to offer the user a
     * list of choices, and then hides when the user selects one of
     * those choices.
     * see ACCESSIBLE_MENU
     * see ACCESSIBLE_MENU_ITEM
     */
#define ACCESSIBLE_POPUP_MENU L"popup menu"

    /**
     * An object usually found inside a menu bar that contains a list
     * of actions the user can choose from.  A menu can have any object
     * as its children, but most often they are menu items, other menus,
     * or rudimentary objects such as radio buttons, check boxes, or
     * separators.  For example, an application may have an "Edit" menu
     * that contains menu items for "Cut" and "Paste."
     * see ACCESSIBLE_MENU_BAR
     * see ACCESSIBLE_MENU_ITEM
     * see ACCESSIBLE_SEPARATOR
     * see ACCESSIBLE_RADIO_BUTTON
     * see ACCESSIBLE_CHECK_BOX
     * see ACCESSIBLE_POPUP_MENU
     */
#define ACCESSIBLE_MENU L"menu"

    /**
     * An object usually contained in a menu that presents an action
     * the user can choose.  For example, the "Cut" menu item in an
     * "Edit" menu would be an action the user can select to cut the
     * selected area of text in a document.
     * see ACCESSIBLE_MENU_BAR
     * see ACCESSIBLE_SEPARATOR
     * see ACCESSIBLE_POPUP_MENU
     */
#define ACCESSIBLE_MENU_ITEM L"menu item"

    /**
     * An object usually contained in a menu to provide a visual
     * and logical separation of the contents in a menu.  For example,
     * the "File" menu of an application might contain menu items for
     * "Open," "Close," and "Exit," and will place a separator between
     * "Close" and "Exit" menu items.
     * see ACCESSIBLE_MENU
     * see ACCESSIBLE_MENU_ITEM
     */
#define ACCESSIBLE_SEPARATOR L"separator"

    /**
     * An object that presents a series of panels (or page tabs), one at a
     * time, through some mechanism provided by the object.  The most common
     * mechanism is a list of tabs at the top of the panel.  The children of
     * a page tab list are all page tabs.
     * see ACCESSIBLE_PAGE_TAB
     */
#define ACCESSIBLE_PAGE_TAB_LIST L"page tab list"

    /**
     * An object that is a child of a page tab list.  Its sole child is
     * the panel that is to be presented to the user when the user
     * selects the page tab from the list of tabs in the page tab list.
     * see ACCESSIBLE_PAGE_TAB_LIST
     */
#define ACCESSIBLE_PAGE_TAB L"page tab"

    /**
     * A generic container that is often used to group objects.
     */
#define ACCESSIBLE_PANEL L"panel"

    /**
     * An object used to indicate how much of a task has been completed.
     */
#define ACCESSIBLE_PROGRESS_BAR L"progress bar"

    /**
     * A text object used for passwords, or other places where the
     * text contents is not shown visibly to the user
     */
#define ACCESSIBLE_PASSWORD_TEXT L"password text"

    /**
     * An object the user can manipulate to tell the application to do
     * something.
     * see ACCESSIBLE_CHECK_BOX
     * see ACCESSIBLE_TOGGLE_BUTTON
     * see ACCESSIBLE_RADIO_BUTTON
     */
#define ACCESSIBLE_PUSH_BUTTON L"push button"

    /**
     * A specialized push button that can be checked or unchecked, but
     * does not provide a separate indicator for the current state.
     * see ACCESSIBLE_PUSH_BUTTON
     * see ACCESSIBLE_CHECK_BOX
     * see ACCESSIBLE_RADIO_BUTTON
     */
#define ACCESSIBLE_TOGGLE_BUTTON L"toggle button"

    /**
     * A choice that can be checked or unchecked and provides a
     * separate indicator for the current state.
     * see ACCESSIBLE_PUSH_BUTTON
     * see ACCESSIBLE_TOGGLE_BUTTON
     * see ACCESSIBLE_RADIO_BUTTON
     */
#define ACCESSIBLE_CHECK_BOX L"check box"

    /**
     * A specialized check box that will cause other radio buttons in the
     * same group to become unchecked when this one is checked.
     * see ACCESSIBLE_PUSH_BUTTON
     * see ACCESSIBLE_TOGGLE_BUTTON
     * see ACCESSIBLE_CHECK_BOX
     */
#define ACCESSIBLE_RADIO_BUTTON L"radio button"

    /**
     * The header for a row of data.
     */
#define ACCESSIBLE_ROW_HEADER L"row header"

    /**
     * An object that allows a user to incrementally view a large amount
     * of information.  Its children can include scroll bars and a viewport.
     * see ACCESSIBLE_SCROLL_BAR
     * see ACCESSIBLE_VIEWPORT
     */
#define ACCESSIBLE_SCROLL_PANE L"scroll pane"

    /**
     * An object usually used to allow a user to incrementally view a
     * large amount of data.  Usually used only by a scroll pane.
     * see ACCESSIBLE_SCROLL_PANE
     */
#define ACCESSIBLE_SCROLL_BAR L"scroll bar"

    /**
     * An object usually used in a scroll pane.  It represents the portion
     * of the entire data that the user can see.  As the user manipulates
     * the scroll bars, the contents of the viewport can change.
     * see ACCESSIBLE_SCROLL_PANE
     */
#define ACCESSIBLE_VIEWPORT L"viewport"

    /**
     * An object that allows the user to select from a bounded range.  For
     * example, a slider might be used to select a number between 0 and 100.
     */
#define ACCESSIBLE_SLIDER L"slider"

    /**
     * A specialized panel that presents two other panels at the same time.
     * Between the two panels is a divider the user can manipulate to make
     * one panel larger and the other panel smaller.
     */
#define ACCESSIBLE_SPLIT_PANE L"split pane"

    /**
     * An object used to present information in terms of rows and columns.
     * An example might include a spreadsheet application.
     */
#define ACCESSIBLE_TABLE L"table"

    /**
     * An object that presents text to the user.  The text is usually
     * editable by the user as opposed to a label.
     * see ACCESSIBLE_LABEL
     */
#define ACCESSIBLE_TEXT L"text"

    /**
     * An object used to present hierarchical information to the user.
     * The individual nodes in the tree can be collapsed and expanded
     * to provide selective disclosure of the tree's contents.
     */
#define ACCESSIBLE_TREE L"tree"

    /**
     * A bar or palette usually composed of push buttons or toggle buttons.
     * It is often used to provide the most frequently used functions for an
     * application.
     */
#define ACCESSIBLE_TOOL_BAR L"tool bar"

    /**
     * An object that provides information about another object.  The
     * accessibleDescription property of the tool tip is often displayed
     * to the user in a small L"help bubble" when the user causes the
     * mouse to hover over the object associated with the tool tip.
     */
#define ACCESSIBLE_TOOL_TIP L"tool tip"

    /**
     * An AWT component, but nothing else is known about it.
     * see ACCESSIBLE_SWING_COMPONENT
     * see ACCESSIBLE_UNKNOWN
     */
#define ACCESSIBLE_AWT_COMPONENT L"awt component"

    /**
     * A Swing component, but nothing else is known about it.
     * see ACCESSIBLE_AWT_COMPONENT
     * see ACCESSIBLE_UNKNOWN
     */
#define ACCESSIBLE_SWING_COMPONENT L"swing component"

    /**
     * The object contains some Accessible information, but its role is
     * not known.
     * see ACCESSIBLE_AWT_COMPONENT
     * see ACCESSIBLE_SWING_COMPONENT
     */
#define ACCESSIBLE_UNKNOWN L"unknown"

    /**
     * A STATUS_BAR is an simple component that can contain
     * multiple labels of status information to the user.
     */
#define ACCESSIBLE_STATUS_BAR L"status bar"

    /**
     * A DATE_EDITOR is a component that allows users to edit
     * java.util.Date and java.util.Time objects
     */
#define ACCESSIBLE_DATE_EDITOR L"date editor"

    /**
     * A SPIN_BOX is a simple spinner component and its main use
     * is for simple numbers.
     */
#define ACCESSIBLE_SPIN_BOX L"spin box"

    /**
     * A FONT_CHOOSER is a component that lets the user pick various
     * attributes for fonts.
     */
#define ACCESSIBLE_FONT_CHOOSER L"font chooser"

    /**
     * A GROUP_BOX is a simple container that contains a border
     * around it and contains components inside it.
     */
#define ACCESSIBLE_GROUP_BOX L"group box"

    /**
     * A text header
     */
#define ACCESSIBLE_HEADER L"header"

    /**
     * A text footer
     */
#define ACCESSIBLE_FOOTER L"footer"

    /**
     * A text paragraph
     */
#define ACCESSIBLE_PARAGRAPH L"paragraph"

    /**
     * A ruler is an object used to measure distance
     */
#define ACCESSIBLE_RULER L"ruler"

    /**
     * A role indicating the object acts as a formula for
     * calculating a value.  An example is a formula in
     * a spreadsheet cell.
     */
#define ACCESSIBLE_EDITBAR L"editbar"

    /**
     * A role indicating the object monitors the progress
     * of some operation.
     */
#define PROGRESS_MONITOR L"progress monitor"


    /**
     ******************************************************
     *  Accessibility event types
     ******************************************************
     */

#define cPropertyNameChangeEvent (jlong) 1              // 1
#define cPropertyDescriptionChangeEvent (jlong) 2       // 2
#define cPropertyStateChangeEvent (jlong) 4             // 4
#define cPropertyValueChangeEvent (jlong) 8             // 8
#define cPropertySelectionChangeEvent (jlong) 16        // 10
#define cPropertyTextChangeEvent (jlong) 32             // 20
#define cPropertyCaretChangeEvent (jlong) 64            // 40
#define cPropertyVisibleDataChangeEvent (jlong) 128     // 80
#define cPropertyChildChangeEvent (jlong) 256           // 100
#define cPropertyActiveDescendentChangeEvent (jlong) 512 // 200
#define cPropertyTableModelChangeEvent (jlong) 1024     // 400

    /**
     ******************************************************
     *  optional AccessibleContext interfaces
     *
     * This version of the bridge reuses the accessibleValue
     * field in the AccessibleContextInfo struct to represent
     * additional optional interfaces that are supported by
     * the Java AccessibleContext.  This is backwardly compatable
     * because the old accessibleValue was set to the BOOL
     * value TRUE (i.e., 1) if the AccessibleValue interface is
     * supported.
     ******************************************************
     */

#define cAccessibleValueInterface (jlong) 1             // 1 << 1 (TRUE)
#define cAccessibleActionInterface (jlong) 2            // 1 << 2
#define cAccessibleComponentInterface (jlong) 4         // 1 << 3
#define cAccessibleSelectionInterface (jlong) 8         // 1 << 4
#define cAccessibleTableInterface (jlong) 16            // 1 << 5
#define cAccessibleTextInterface (jlong) 32             // 1 << 6
#define cAccessibleHypertextInterface (jlong) 64        // 1 << 7


    /**
     ******************************************************
     *  Accessibility information bundles
     ******************************************************
     */

    typedef struct AccessBridgeVersionInfoTag {
        wchar_t VMversion[SHORT_STRING_SIZE];               // output of "java -version"
        wchar_t bridgeJavaClassVersion[SHORT_STRING_SIZE];  // version of the AccessBridge.class
        wchar_t bridgeJavaDLLVersion[SHORT_STRING_SIZE];    // version of JavaAccessBridge.dll
        wchar_t bridgeWinDLLVersion[SHORT_STRING_SIZE];     // version of WindowsAccessBridge.dll
    } AccessBridgeVersionInfo;


    typedef struct AccessibleContextInfoTag {
        wchar_t name[MAX_STRING_SIZE];          // the AccessibleName of the object
        wchar_t description[MAX_STRING_SIZE];   // the AccessibleDescription of the object

        wchar_t role[SHORT_STRING_SIZE];        // localized AccesibleRole string
        wchar_t role_en_US[SHORT_STRING_SIZE];  // AccesibleRole string in the en_US locale
        wchar_t states[SHORT_STRING_SIZE];      // localized AccesibleStateSet string (comma separated)
        wchar_t states_en_US[SHORT_STRING_SIZE]; // AccesibleStateSet string in the en_US locale (comma separated)

        jint indexInParent;                     // index of object in parent
        jint childrenCount;                     // # of children, if any

        jint x;                                 // screen coords in pixels
        jint y;                                 // "
        jint width;                             // pixel width of object
        jint height;                            // pixel height of object

        BOOL accessibleComponent;               // flags for various additional
        BOOL accessibleAction;                  //  Java Accessibility interfaces
        BOOL accessibleSelection;               //  FALSE if this object doesn't
        BOOL accessibleText;                    //  implement the additional interface
                                                //  in question

        // BOOL accessibleValue;                // old BOOL indicating whether AccessibleValue is supported
        BOOL accessibleInterfaces;              // new bitfield containing additional interface flags

    } AccessibleContextInfo;



    // AccessibleText packages
    typedef struct AccessibleTextInfoTag {
        jint charCount;                 // # of characters in this text object
        jint caretIndex;                // index of caret
        jint indexAtPoint;              // index at the passsed in point
    } AccessibleTextInfo;

    typedef struct AccessibleTextItemsInfoTag {
        wchar_t letter;
        wchar_t word[SHORT_STRING_SIZE];
        wchar_t sentence[MAX_STRING_SIZE];
    } AccessibleTextItemsInfo;

    typedef struct AccessibleTextSelectionInfoTag {
        jint selectionStartIndex;
        jint selectionEndIndex;
        wchar_t selectedText[MAX_STRING_SIZE];
    } AccessibleTextSelectionInfo;

    typedef struct AccessibleTextRectInfoTag {
        jint x;                     // bounding rect of char at index
        jint y;                     // "
        jint width;                 // "
        jint height;                // "
    } AccessibleTextRectInfo;

    // standard attributes for text; note: tabstops are not supported
    typedef struct AccessibleTextAttributesInfoTag {
        BOOL bold;
        BOOL italic;
        BOOL underline;
        BOOL strikethrough;
        BOOL superscript;
        BOOL subscript;

        wchar_t backgroundColor[SHORT_STRING_SIZE];
        wchar_t foregroundColor[SHORT_STRING_SIZE];
        wchar_t fontFamily[SHORT_STRING_SIZE];
        jint fontSize;

        jint alignment;
        jint bidiLevel;

        jfloat firstLineIndent;
        jfloat leftIndent;
        jfloat rightIndent;
        jfloat lineSpacing;
        jfloat spaceAbove;
        jfloat spaceBelow;

        wchar_t fullAttributesString[MAX_STRING_SIZE];
    } AccessibleTextAttributesInfo;

    /**
     ******************************************************
     *  IPC management typedefs
     ******************************************************
     */

#define cMemoryMappedNameSize   255

    /**
     * sent by the WindowsDLL -> the memory-mapped file is setup
     *
     */
    typedef struct MemoryMappedFileCreatedPackageTag {
//      HWND bridgeWindow;              // redundant, but easier to get to here...
        ABHWND64 bridgeWindow;          // redundant, but easier to get to here...
        char filename[cMemoryMappedNameSize];
    } MemoryMappedFileCreatedPackage;




    /**
     * sent when a new JavaVM attaches to the Bridge
     *
     */
    typedef struct JavaVMCreatedPackageTag {
        ABHWND64 bridgeWindow;
        long vmID;
    } JavaVMCreatedPackage;

    /**
     * sent when a JavaVM detatches from the Bridge
     *
     */
    typedef struct JavaVMDestroyedPackageTag {
        ABHWND64 bridgeWindow;
    } JavaVMDestroyedPackage;

    /**
     * sent when a new AT attaches to the Bridge
     *
     */
    typedef struct WindowsATCreatedPackageTag {
        ABHWND64 bridgeWindow;
    } WindowsATCreatedPackage;

    /**
     * sent when an AT detatches from the Bridge
     *
     */
    typedef struct WindowsATDestroyedPackageTag {
        ABHWND64 bridgeWindow;
    } WindowsATDestroyedPackage;


    /**
     * sent by JVM Bridges in response to a WindowsATCreate
     * message; saying "howdy, welcome to the neighborhood"
     *
     */
    typedef struct JavaVMPresentNotificationPackageTag {
        ABHWND64 bridgeWindow;
        long vmID;
    } JavaVMPresentNotificationPackage;

    /**
     * sent by AT Bridges in response to a JavaVMCreate
     * message; saying "howdy, welcome to the neighborhood"
     *
     */
    typedef struct WindowsATPresentNotificationPackageTag {
        ABHWND64 bridgeWindow;
    } WindowsATPresentNotificationPackage;


    /**
     ******************************************************
     *  Core packages
     ******************************************************
     */

    typedef struct ReleaseJavaObjectPackageTag {
        long vmID;
        JOBJECT64 object;
    } ReleaseJavaObjectPackage;

    typedef struct GetAccessBridgeVersionPackageTag {
        long vmID;                    // can't get VM info w/out a VM!
        AccessBridgeVersionInfo rVersionInfo;
    } GetAccessBridgeVersionPackage;

    typedef struct IsSameObjectPackageTag {
        long vmID;
        JOBJECT64 obj1;
        JOBJECT64 obj2;
        jboolean rResult;
    } IsSameObjectPackage;

    /**
     ******************************************************
     *  Windows packages
     ******************************************************
     */

    typedef struct IsJavaWindowPackageTag {
        jint window;
        jboolean rResult;
    } IsJavaWindowPackage;

    typedef struct GetAccessibleContextFromHWNDPackageTag {
        jint window;
        long rVMID;
        JOBJECT64 rAccessibleContext;
    } GetAccessibleContextFromHWNDPackage;

    typedef struct GetHWNDFromAccessibleContextPackageTag {
        JOBJECT64 accessibleContext;
        ABHWND64 rHWND;
    } GetHWNDFromAccessibleContextPackage;

    /**
******************************************************
*  AccessibleContext packages
******************************************************
*/

    typedef struct GetAccessibleContextAtPackageTag {
        jint x;
        jint y;
        long vmID;
        JOBJECT64 AccessibleContext;            // look within this AC
        JOBJECT64 rAccessibleContext;
    } GetAccessibleContextAtPackage;

    typedef struct GetAccessibleContextWithFocusPackageTag {
        long rVMID;
        JOBJECT64 rAccessibleContext;
    } GetAccessibleContextWithFocusPackage;

    typedef struct GetAccessibleContextInfoPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        AccessibleContextInfo rAccessibleContextInfo;
    } GetAccessibleContextInfoPackage;

    typedef struct GetAccessibleChildFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint childIndex;
        JOBJECT64 rAccessibleContext;
    } GetAccessibleChildFromContextPackage;

    typedef struct GetAccessibleParentFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        JOBJECT64 rAccessibleContext;
    } GetAccessibleParentFromContextPackage;

    /**
******************************************************
*  AccessibleTable packages
******************************************************
*/

#define MAX_TABLE_SELECTIONS 64

    // table information
    typedef struct AccessibleTableInfoTag {
        JOBJECT64 caption;  // AccesibleContext
        JOBJECT64 summary;  // AccessibleContext
        jint rowCount;
        jint columnCount;
        JOBJECT64 accessibleContext;
        JOBJECT64 accessibleTable;
    } AccessibleTableInfo;

    typedef struct GetAccessibleTableInfoPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        AccessibleTableInfo rTableInfo;
    } GetAccessibleTableInfoPackage;

    // table cell information
    typedef struct AccessibleTableCellInfoTag {
        JOBJECT64  accessibleContext;
        jint     index;
        jint     row;
        jint     column;
        jint     rowExtent;
        jint     columnExtent;
        jboolean isSelected;
    } AccessibleTableCellInfo;

    typedef struct GetAccessibleTableCellInfoPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint row;
        jint column;
        AccessibleTableCellInfo rTableCellInfo;
    } GetAccessibleTableCellInfoPackage;

    typedef struct GetAccessibleTableRowHeaderPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        AccessibleTableInfo rTableInfo;
    } GetAccessibleTableRowHeaderPackage;

    typedef struct GetAccessibleTableColumnHeaderPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        AccessibleTableInfo rTableInfo;
    } GetAccessibleTableColumnHeaderPackage;

    typedef struct GetAccessibleTableRowDescriptionPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        jint row;
        JOBJECT64 rAccessibleContext;
    } GetAccessibleTableRowDescriptionPackage;

    typedef struct GetAccessibleTableColumnDescriptionPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        jint column;
        JOBJECT64 rAccessibleContext;
    } GetAccessibleTableColumnDescriptionPackage;

    typedef struct GetAccessibleTableRowSelectionCountPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint rCount;
    } GetAccessibleTableRowSelectionCountPackage;

    typedef struct IsAccessibleTableRowSelectedPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint row;
        jboolean rResult;
    } IsAccessibleTableRowSelectedPackage;

    typedef struct GetAccessibleTableRowSelectionsPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint count;
        jint rSelections[MAX_TABLE_SELECTIONS];
    } GetAccessibleTableRowSelectionsPackage;

    typedef struct GetAccessibleTableColumnSelectionCountPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint rCount;
    } GetAccessibleTableColumnSelectionCountPackage;

    typedef struct IsAccessibleTableColumnSelectedPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint column;
        jboolean rResult;
    } IsAccessibleTableColumnSelectedPackage;

    typedef struct GetAccessibleTableColumnSelectionsPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint count;
        jint rSelections[MAX_TABLE_SELECTIONS];
    } GetAccessibleTableColumnSelectionsPackage;


    typedef struct GetAccessibleTableRowPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint index;
        jint rRow;
    } GetAccessibleTableRowPackage;

    typedef struct GetAccessibleTableColumnPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint index;
        jint rColumn;
    } GetAccessibleTableColumnPackage;

    typedef struct GetAccessibleTableIndexPackageTag {
        long vmID;
        JOBJECT64 accessibleTable;
        jint row;
        jint column;
        jint rIndex;
    } GetAccessibleTableIndexPackage;


    /**
     ******************************************************
     *  AccessibleRelationSet packages
     ******************************************************
     */

#define MAX_RELATION_TARGETS 25
#define MAX_RELATIONS 5

    typedef struct AccessibleRelationInfoTag {
        wchar_t key[SHORT_STRING_SIZE];
        jint targetCount;
        JOBJECT64 targets[MAX_RELATION_TARGETS];  // AccessibleContexts
    } AccessibleRelationInfo;

    typedef struct AccessibleRelationSetInfoTag {
        jint relationCount;
        AccessibleRelationInfo relations[MAX_RELATIONS];
    } AccessibleRelationSetInfo;

    typedef struct GetAccessibleRelationSetPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        AccessibleRelationSetInfo rAccessibleRelationSetInfo;
    } GetAccessibleRelationSetPackage;

    /**
     ******************************************************
     *  AccessibleHypertext packagess
     ******************************************************
     */

#define MAX_HYPERLINKS          64      // maximum number of hyperlinks returned

    // hyperlink information
    typedef struct AccessibleHyperlinkInfoTag {
        wchar_t text[SHORT_STRING_SIZE]; // the hyperlink text
        jint startIndex;        //index in the hypertext document where the link begins
        jint endIndex;          //index in the hypertext document where the link ends
        JOBJECT64 accessibleHyperlink; // AccessibleHyperlink object
    } AccessibleHyperlinkInfo;

    // hypertext information
    typedef struct AccessibleHypertextInfoTag {
        jint linkCount;         // number of hyperlinks
        AccessibleHyperlinkInfo links[MAX_HYPERLINKS];  // the hyperlinks
        JOBJECT64 accessibleHypertext; // AccessibleHypertext object
    } AccessibleHypertextInfo;

    // struct for sending a message to get the hypertext for an AccessibleContext
    typedef struct GetAccessibleHypertextPackageTag {
        long vmID;              // the virtual machine ID
        JOBJECT64 accessibleContext; // AccessibleContext with hypertext
        AccessibleHypertextInfo rAccessibleHypertextInfo; // returned hypertext
    } GetAccessibleHypertextPackage;

    // struct for sending an message to activate a hyperlink
    typedef struct ActivateAccessibleHyperlinkPackageTag {
        long vmID;              // the virtual machine ID
        JOBJECT64 accessibleContext; // AccessibleContext containing the link
        JOBJECT64 accessibleHyperlink; // the link to activate
        BOOL rResult;           // hyperlink activation return value
    } ActivateAccessibleHyperlinkPackage;

    // struct for sending a message to get the number of hyperlinks in a component
    typedef struct GetAccessibleHyperlinkCountPackageTag {
        long vmID;              // the virtual machine ID
        JOBJECT64 accessibleContext;    // AccessibleContext containing AccessibleHypertext
        jint rLinkCount;        // link count return value
    } GetAccessibleHyperlinkCountPackage;

    // struct for sending a message to get the hypertext for an AccessibleContext
    // starting at a specified index in the document
    typedef struct GetAccessibleHypertextExtPackageTag {
        long vmID;              // the virtual machine ID
        JOBJECT64 accessibleContext; // AccessibleContext with hypertext
        jint startIndex;        // start index in document
        AccessibleHypertextInfo rAccessibleHypertextInfo; // returned hypertext
        BOOL rSuccess;          // whether call succeeded
    } GetAccessibleHypertextExtPackage;

    // struct for sending a message to get the nth hyperlink in a document;
    // maps to AccessibleHypertext.getLink
    typedef struct GetAccessibleHyperlinkPackageTag {
        long vmID;              // the virtual machine ID
        JOBJECT64 hypertext;    // AccessibleHypertext
        jint linkIndex;         // hyperlink index
        AccessibleHyperlinkInfo rAccessibleHyperlinkInfo; // returned hyperlink
    } GetAccessibleHyperlinkPackage;

    // struct for sending a message to get the index into an array
    // of hyperlinks that is associated with a character index in a
    // document; maps to AccessibleHypertext.getLinkIndex
    typedef struct GetAccessibleHypertextLinkIndexPackageTag {
        long vmID;              // the virtual machine ID
        JOBJECT64 hypertext;    // AccessibleHypertext
        jint charIndex;         // character index in document
        jint rLinkIndex;        // returned hyperlink index
    } GetAccessibleHypertextLinkIndexPackage;

    /**
     ******************************************************
     *  Accessible Key Bindings packages
     ******************************************************
     */

#define MAX_KEY_BINDINGS        10

    // keyboard character modifiers
#define ACCESSIBLE_SHIFT_KEYSTROKE              1
#define ACCESSIBLE_CONTROL_KEYSTROKE            2
#define ACCESSIBLE_META_KEYSTROKE               4
#define ACCESSIBLE_ALT_KEYSTROKE                8
#define ACCESSIBLE_ALT_GRAPH_KEYSTROKE          16
#define ACCESSIBLE_BUTTON1_KEYSTROKE            32
#define ACCESSIBLE_BUTTON2_KEYSTROKE            64
#define ACCESSIBLE_BUTTON3_KEYSTROKE            128
#define ACCESSIBLE_FKEY_KEYSTROKE               256  // F key pressed, character contains 1-24
#define ACCESSIBLE_CONTROLCODE_KEYSTROKE        512  // Control code key pressed, character contains control code.

// The supported control code keys are:
#define ACCESSIBLE_VK_BACK_SPACE    8
#define ACCESSIBLE_VK_DELETE        127
#define ACCESSIBLE_VK_DOWN          40
#define ACCESSIBLE_VK_END           35
#define ACCESSIBLE_VK_HOME          36
#define ACCESSIBLE_VK_INSERT        155
#define ACCESSIBLE_VK_KP_DOWN       225
#define ACCESSIBLE_VK_KP_LEFT       226
#define ACCESSIBLE_VK_KP_RIGHT      227
#define ACCESSIBLE_VK_KP_UP         224
#define ACCESSIBLE_VK_LEFT          37
#define ACCESSIBLE_VK_PAGE_DOWN     34
#define ACCESSIBLE_VK_PAGE_UP       33
#define ACCESSIBLE_VK_RIGHT         39
#define ACCESSIBLE_VK_UP            38

    // a key binding associates with a component
    typedef struct AccessibleKeyBindingInfoTag {
        jchar character;                // the key character
        jint modifiers;                 // the key modifiers
    } AccessibleKeyBindingInfo;

    // all of the key bindings associated with a component
    typedef struct AccessibleKeyBindingsTag {
        int keyBindingsCount;   // number of key bindings
        AccessibleKeyBindingInfo keyBindingInfo[MAX_KEY_BINDINGS];
    } AccessibleKeyBindings;

    // struct to get the key bindings associated with a component
    typedef struct GetAccessibleKeyBindingsPackageTag {
        long vmID;                                      // the virtual machine id
        JOBJECT64 accessibleContext;                    // the component
        AccessibleKeyBindings rAccessibleKeyBindings;   // the key bindings
    } GetAccessibleKeyBindingsPackage;

    /**
******************************************************
*  AccessibleIcon packages
******************************************************
*/
#define MAX_ICON_INFO 8

    // an icon assocated with a component
    typedef struct AccessibleIconInfoTag {
        wchar_t description[SHORT_STRING_SIZE]; // icon description
        jint height;                            // icon height
        jint width;                             // icon width
    } AccessibleIconInfo;

    // all of the icons associated with a component
    typedef struct AccessibleIconsTag {
        jint iconsCount;                // number of icons
        AccessibleIconInfo iconInfo[MAX_ICON_INFO];     // the icons
    } AccessibleIcons;

    // struct to get the icons associated with a component
    typedef struct GetAccessibleIconsPackageTag {
        long vmID;                              // the virtual machine id
        JOBJECT64 accessibleContext;            // the component
        AccessibleIcons rAccessibleIcons;       // the icons
    } GetAccessibleIconsPackage;


    /**
******************************************************
*  AccessibleAction packages
******************************************************
*/
#define MAX_ACTION_INFO 256
#define MAX_ACTIONS_TO_DO 32

    // an action assocated with a component
    typedef struct AccessibleActionInfoTag {
        wchar_t name[SHORT_STRING_SIZE];        // action name
    } AccessibleActionInfo;

    // all of the actions associated with a component
    typedef struct AccessibleActionsTag {
        jint actionsCount;              // number of actions
        AccessibleActionInfo actionInfo[MAX_ACTION_INFO];       // the action information
    } AccessibleActions;

    // struct for requesting the actions associated with a component
    typedef struct GetAccessibleActionsPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;                                    // the component
        AccessibleActions rAccessibleActions;           // the actions
    } GetAccessibleActionsPackage;

    // list of AccessibleActions to do
    typedef struct AccessibleActionsToDoTag {
        jint actionsCount;                              // number of actions to do
        AccessibleActionInfo actions[MAX_ACTIONS_TO_DO];// the accessible actions to do
    } AccessibleActionsToDo;

    // struct for sending an message to do one or more actions
    typedef struct DoAccessibleActionsPackageTag {
        long vmID;                         // the virtual machine ID
        JOBJECT64 accessibleContext;       // component to do the action
        AccessibleActionsToDo actionsToDo; // the accessible actions to do
        BOOL rResult;                      // action return value
        jint failure;                      // index of action that failed if rResult is FALSE
    } DoAccessibleActionsPackage;

    /**
******************************************************
*  AccessibleText packages
******************************************************
*/

    typedef struct GetAccessibleTextInfoPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint x;
        jint y;
        AccessibleTextInfo rTextInfo;
    } GetAccessibleTextInfoPackage;

    typedef struct GetAccessibleTextItemsPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint index;
        AccessibleTextItemsInfo rTextItemsInfo;
    } GetAccessibleTextItemsPackage;

    typedef struct GetAccessibleTextSelectionInfoPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        AccessibleTextSelectionInfo rTextSelectionItemsInfo;
    } GetAccessibleTextSelectionInfoPackage;

    typedef struct GetAccessibleTextAttributeInfoPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint index;
        AccessibleTextAttributesInfo rAttributeInfo;
    } GetAccessibleTextAttributeInfoPackage;

    typedef struct GetAccessibleTextRectInfoPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint index;
        AccessibleTextRectInfo rTextRectInfo;
    } GetAccessibleTextRectInfoPackage;

    typedef struct GetCaretLocationPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint index;
        AccessibleTextRectInfo rTextRectInfo;
    } GetCaretLocationPackage;

    typedef struct GetAccessibleTextLineBoundsPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint index;
        jint rLineStart;
        jint rLineEnd;
    } GetAccessibleTextLineBoundsPackage;

    typedef struct GetAccessibleTextRangePackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint start;
        jint end;
        wchar_t rText[MAX_BUFFER_SIZE];
    } GetAccessibleTextRangePackage;

    /**
******************************************************
*
* Utility method packages
******************************************************
*/

    typedef struct SetTextContentsPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;    // the text field
        wchar_t text[MAX_STRING_SIZE];  // the text
        BOOL rResult;
    } SetTextContentsPackage;

    typedef struct GetParentWithRolePackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        wchar_t role[SHORT_STRING_SIZE];  // one of Accessible Roles above
        JOBJECT64 rAccessibleContext;
    } GetParentWithRolePackage;

    typedef struct GetTopLevelObjectPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        JOBJECT64 rAccessibleContext;
    } GetTopLevelObjectPackage;

    typedef struct GetParentWithRoleElseRootPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        wchar_t role[SHORT_STRING_SIZE];  // one of Accessible Roles above
        JOBJECT64 rAccessibleContext;
    } GetParentWithRoleElseRootPackage;

    typedef struct GetObjectDepthPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        jint rResult;
    } GetObjectDepthPackage;

    typedef struct GetActiveDescendentPackageTag {
        long vmID;
        JOBJECT64 accessibleContext;
        JOBJECT64 rAccessibleContext;
    } GetActiveDescendentPackage;

    /**
******************************************************
*  AccessibleValue packages
******************************************************
*/

    typedef struct GetCurrentAccessibleValueFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        wchar_t rValue[SHORT_STRING_SIZE];
    } GetCurrentAccessibleValueFromContextPackage;

    typedef struct GetMaximumAccessibleValueFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        wchar_t rValue[SHORT_STRING_SIZE];
    } GetMaximumAccessibleValueFromContextPackage;

    typedef struct GetMinimumAccessibleValueFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        wchar_t rValue[SHORT_STRING_SIZE];
    } GetMinimumAccessibleValueFromContextPackage;


    /**
******************************************************
*  AccessibleSelection packages
******************************************************
*/

    typedef struct AddAccessibleSelectionFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint index;
    } AddAccessibleSelectionFromContextPackage;

    typedef struct ClearAccessibleSelectionFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
    } ClearAccessibleSelectionFromContextPackage;

    typedef struct GetAccessibleSelectionFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint index;
        JOBJECT64 rAccessibleContext;
    } GetAccessibleSelectionFromContextPackage;

    typedef struct GetAccessibleSelectionCountFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint rCount;
    } GetAccessibleSelectionCountFromContextPackage;

    typedef struct IsAccessibleChildSelectedFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint index;
        jboolean rResult;
    } IsAccessibleChildSelectedFromContextPackage;

    typedef struct RemoveAccessibleSelectionFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
        jint index;
    } RemoveAccessibleSelectionFromContextPackage;

    typedef struct SelectAllAccessibleSelectionFromContextPackageTag {
        long vmID;
        JOBJECT64 AccessibleContext;
    } SelectAllAccessibleSelectionFromContextPackage;


    /**
******************************************************
*  Java Event Notification Registration packages
******************************************************
*/

    typedef struct AddJavaEventNotificationPackageTag {
        jlong type;
        //HWND DLLwindow;
        ABHWND64 DLLwindow;
    } AddJavaEventNotificationPackage;

    typedef struct RemoveJavaEventNotificationPackageTag {
        jlong type;
        //HWND DLLwindow;
        ABHWND64 DLLwindow;
    } RemoveJavaEventNotificationPackage;


    /**
******************************************************
*  Accessibility Event Notification Registration packages
******************************************************
*/

    typedef struct AddAccessibilityEventNotificationPackageTag {
        jlong type;
        //HWND DLLwindow;
        ABHWND64 DLLwindow;
    } AddAccessibilityEventNotificationPackage;

    typedef struct RemoveAccessibilityEventNotificationPackageTag {
        jlong type;
        //HWND DLLwindow;
        ABHWND64 DLLwindow;
    } RemoveAccessibilityEventNotificationPackage;


    /**
******************************************************
*  Accessibility Property Change Event packages
******************************************************
*/

    typedef struct PropertyCaretChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
        jint oldPosition;
        jint newPosition;
    } PropertyCaretChangePackage;

    typedef struct PropertyDescriptionChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
        wchar_t oldDescription[SHORT_STRING_SIZE];
        wchar_t newDescription[SHORT_STRING_SIZE];
    } PropertyDescriptionChangePackage;

    typedef struct PropertyNameChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
        wchar_t oldName[SHORT_STRING_SIZE];
        wchar_t newName[SHORT_STRING_SIZE];
    } PropertyNameChangePackage;

    typedef struct PropertySelectionChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } PropertySelectionChangePackage;

    typedef struct PropertyStateChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
        wchar_t oldState[SHORT_STRING_SIZE];
        wchar_t newState[SHORT_STRING_SIZE];
    } PropertyStateChangePackage;

    typedef struct PropertyTextChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } PropertyTextChangePackage;

    typedef struct PropertyValueChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
        wchar_t oldValue[SHORT_STRING_SIZE];
        wchar_t newValue[SHORT_STRING_SIZE];
    } PropertyValueChangePackage;

    typedef struct PropertyVisibleDataChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } PropertyVisibleDataChangePackage;

    typedef struct PropertyChildChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
        JOBJECT64 oldChildAccessibleContext;
        JOBJECT64 newChildAccessibleContext;
    } PropertyChildChangePackage;

    typedef struct PropertyActiveDescendentChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
        JOBJECT64 oldActiveDescendentAccessibleContext;
        JOBJECT64 newActiveDescendentAccessibleContext;
    } PropertyActiveDescendentChangePackage;


    // String format for newValue is:
    //  "type" one of "INSERT", "UPDATE" or "DELETE"
    //  "firstRow"
    //  "lastRow"
    //  "firstColumn"
    //  "lastColumn"
    //
    // oldValue is currently unused
    //
    typedef struct PropertyTableModelChangePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
        wchar_t oldValue[SHORT_STRING_SIZE];
        wchar_t newValue[SHORT_STRING_SIZE];
    } PropertyTableModelChangePackage;


    /**
******************************************************
*  Property Change Event packages
******************************************************
*/

    /*
      typedef struct PropertyChangePackageTag {
      long vmID;
      jobject Event;
      jobject AccessibleContextSource;
      char propertyName[SHORT_STRING_SIZE];
      char oldValue[SHORT_STRING_SIZE]; // PropertyChangeEvent().getOldValue().toString()
      char newValue[SHORT_STRING_SIZE]; // PropertyChangeEvent().getNewValue().toString()
      } PropertyChangePackage;
    */

    /*
     * Java shutdown event package
     */
    typedef struct JavaShutdownPackageTag {
        long vmID;
    } JavaShutdownPackage;


    /**
******************************************************
*  Focus Event packages
******************************************************
*/

    typedef struct FocusGainedPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } FocusGainedPackage;

    typedef struct FocusLostPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } FocusLostPackage;


    /**
******************************************************
*  Caret Event packages
******************************************************
*/

    typedef struct CaretUpdatePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } CaretUpdatePackage;


    /**
******************************************************
*  Mouse Event packages
******************************************************
*/

    typedef struct MouseClickedPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } MouseClickedPackage;

    typedef struct MouseEnteredPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } MouseEnteredPackage;

    typedef struct MouseExitedPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } MouseExitedPackage;

    typedef struct MousePressedPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } MousePressedPackage;

    typedef struct MouseReleasedPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } MouseReleasedPackage;


    /**
******************************************************
*  Menu/PopupMenu Event packages
******************************************************
*/

    typedef struct MenuCanceledPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } MenuCanceledPackage;

    typedef struct MenuDeselectedPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } MenuDeselectedPackage;

    typedef struct MenuSelectedPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } MenuSelectedPackage;


    typedef struct PopupMenuCanceledPackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } PopupMenuCanceledPackage;

    typedef struct PopupMenuWillBecomeInvisiblePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } PopupMenuWillBecomeInvisiblePackage;

    typedef struct PopupMenuWillBecomeVisiblePackageTag {
        long vmID;
        JOBJECT64 Event;
        JOBJECT64 AccessibleContextSource;
    } PopupMenuWillBecomeVisiblePackage;

    /**
******************************************************
*  Additional methods for Teton
******************************************************
*/

    /**
     * Gets the AccessibleName for a component based upon the JAWS algorithm. Returns
     * whether successful.
     *
     * Bug ID 4916682 - Implement JAWS AccessibleName policy
     */
    typedef struct GetVirtualAccessibleNamePackageTag {
        long vmID;
        AccessibleContext accessibleContext;
        wchar_t rName[MAX_STRING_SIZE];
        int len;
    } GetVirtualAccessibleNamePackage;

    /**
     * Request focus for a component. Returns whether successful;
     *
     * Bug ID 4944757 - requestFocus method needed
     */
    typedef struct RequestFocusPackageTag {
        long vmID;
        AccessibleContext accessibleContext;
    } RequestFocusPackage;

    /**
     * Selects text between two indices.  Selection includes the text at the start index
     * and the text at the end index. Returns whether successful;
     *
     * Bug ID 4944758 - selectTextRange method needed
     */
    typedef struct SelectTextRangePackageTag {
        long vmID;
        AccessibleContext accessibleContext;
        jint startIndex;
        jint endIndex;
    } SelectTextRangePackage;

    /**
     * Gets the number of contiguous characters with the same attributes.
     *
     * Bug ID 4944761 - getTextAttributes between two indices method needed
     */
    typedef struct GetTextAttributesInRangePackageTag {
        long vmID;
        AccessibleContext accessibleContext;
        jint startIndex;        // start index (inclusive)
        jint endIndex;          // end index (inclusive)
        AccessibleTextAttributesInfo attributes; // character attributes to match
        short rLength;          // number of contiguous characters with matching attributes
    } GetTextAttributesInRangePackage;

#define MAX_VISIBLE_CHILDREN 256

    // visible children information
    typedef struct VisibleChildenInfoTag {
        int returnedChildrenCount; // number of children returned
        AccessibleContext children[MAX_VISIBLE_CHILDREN]; // the visible children
    } VisibleChildrenInfo;

    // struct for sending a message to get the number of visible children
    typedef struct GetVisibleChildrenCountPackageTag {
        long vmID;              // the virtual machine ID
        JOBJECT64 accessibleContext; // AccessibleContext of parent component
        jint rChildrenCount;    // visible children count return value
    } GetVisibleChildrenCountPackage;

    // struct for sending a message to get the hypertext for an AccessibleContext
    // starting at a specified index in the document
    typedef struct GetVisibleChildrenPackageTag {
        long vmID;              // the virtual machine ID
        JOBJECT64 accessibleContext; // AccessibleContext of parent component
        jint startIndex;        // start index for retrieving children
        VisibleChildrenInfo rVisibleChildrenInfo; // returned info
        BOOL rSuccess;          // whether call succeeded
    } GetVisibleChildrenPackage;

    /**
     * Set the caret to a text position. Returns whether successful;
     *
     * Bug ID 4944770 - setCaretPosition method needed
     */
    typedef struct SetCaretPositionPackageTag {
        long vmID;
        AccessibleContext accessibleContext;
        jint position;
    } SetCaretPositionPackage;


    /**
     ******************************************************
     *  Wrapping up all of the packages
     ******************************************************
     */

    /**
     *  What is the type of this package
     */
    typedef enum PackageType {

        cMemoryMappedFileCreatedPackage = 0x11000,

        // many of these will go away...
        cJavaVMCreatedPackage = 0x10000,
        cJavaVMDestroyedPackage,
        cWindowsATCreatedPackage,
        cWindowsATDestroyedPackage,
        cJavaVMPresentNotificationPackage,
        cWindowsATPresentNotificationPackage,

        cReleaseJavaObjectPackage = 1,
        cGetAccessBridgeVersionPackage = 2,

        cGetAccessibleContextFromHWNDPackage = 0x10,
        cIsJavaWindowPackage,
        cGetHWNDFromAccessibleContextPackage,

        cGetAccessibleContextAtPackage = 0x100,
        cGetAccessibleContextWithFocusPackage,
        cGetAccessibleContextInfoPackage,
        cGetAccessibleChildFromContextPackage,
        cGetAccessibleParentFromContextPackage,
        cIsSameObjectPackage,

        cGetAccessibleTextInfoPackage = 0x200,
        cGetAccessibleTextItemsPackage,
        cGetAccessibleTextSelectionInfoPackage,
        cGetAccessibleTextAttributeInfoPackage,
        cGetAccessibleTextRectInfoPackage,
        cGetAccessibleTextLineBoundsPackage,
        cGetAccessibleTextRangePackage,

        cGetCurrentAccessibleValueFromContextPackage = 0x300,
        cGetMaximumAccessibleValueFromContextPackage,
        cGetMinimumAccessibleValueFromContextPackage,

        cAddAccessibleSelectionFromContextPackage = 0x400,
        cClearAccessibleSelectionFromContextPackage,
        cGetAccessibleSelectionFromContextPackage,
        cGetAccessibleSelectionCountFromContextPackage,
        cIsAccessibleChildSelectedFromContextPackage,
        cRemoveAccessibleSelectionFromContextPackage,
        cSelectAllAccessibleSelectionFromContextPackage,

        cAddJavaEventNotificationPackage = 0x900,
        cRemoveJavaEventNotificationPackage,
        cAddAccessibilityEventNotificationPackage,
        cRemoveAccessibilityEventNotificationPackage,

        cPropertyChangePackage = 0x1000,

        cJavaShutdownPackage = 0x1010,
        cFocusGainedPackage,
        cFocusLostPackage,

        cCaretUpdatePackage = 0x1020,

        cMouseClickedPackage = 0x1030,
        cMouseEnteredPackage,
        cMouseExitedPackage,
        cMousePressedPackage,
        cMouseReleasedPackage,

        cMenuCanceledPackage = 0x1040,
        cMenuDeselectedPackage,
        cMenuSelectedPackage,
        cPopupMenuCanceledPackage,
        cPopupMenuWillBecomeInvisiblePackage,
        cPopupMenuWillBecomeVisiblePackage,

        cPropertyCaretChangePackage = 0x1100,
        cPropertyDescriptionChangePackage,
        cPropertyNameChangePackage,
        cPropertySelectionChangePackage,
        cPropertyStateChangePackage,
        cPropertyTextChangePackage,
        cPropertyValueChangePackage,
        cPropertyVisibleDataChangePackage,
        cPropertyChildChangePackage,
        cPropertyActiveDescendentChangePackage,


        // AccessibleTable
        cGetAccessibleTableInfoPackage = 0x1200,
        cGetAccessibleTableCellInfoPackage,

        cGetAccessibleTableRowHeaderPackage,
        cGetAccessibleTableColumnHeaderPackage,

        cGetAccessibleTableRowDescriptionPackage,
        cGetAccessibleTableColumnDescriptionPackage,

        cGetAccessibleTableRowSelectionCountPackage,
        cIsAccessibleTableRowSelectedPackage,
        cGetAccessibleTableRowSelectionsPackage,

        cGetAccessibleTableColumnSelectionCountPackage,
        cIsAccessibleTableColumnSelectedPackage,
        cGetAccessibleTableColumnSelectionsPackage,

        cGetAccessibleTableRowPackage,
        cGetAccessibleTableColumnPackage,
        cGetAccessibleTableIndexPackage,

        cPropertyTableModelChangePackage,


        // AccessibleRelationSet
        cGetAccessibleRelationSetPackage = 0x1300,

        // AccessibleHypertext
        cGetAccessibleHypertextPackage = 0x1400,
        cActivateAccessibleHyperlinkPackage,
        cGetAccessibleHyperlinkCountPackage,
        cGetAccessibleHypertextExtPackage,
        cGetAccessibleHypertextLinkIndexPackage,
        cGetAccessibleHyperlinkPackage,

        // Accessible KeyBinding, Icon and Action
        cGetAccessibleKeyBindingsPackage = 0x1500,
        cGetAccessibleIconsPackage,
        cGetAccessibleActionsPackage,
        cDoAccessibleActionsPackage,

        // Utility methods
        cSetTextContentsPackage = 0x1600,
        cGetParentWithRolePackage,
        cGetTopLevelObjectPackage,
        cGetParentWithRoleElseRootPackage,
        cGetObjectDepthPackage,
        cGetActiveDescendentPackage,

        // Additional methods for Teton
        cGetVirtualAccessibleNamePackage = 0x1700,
        cRequestFocusPackage,
        cSelectTextRangePackage,
        cGetTextAttributesInRangePackage,
        cGetSameTextAttributesInRangePackage,
        cGetVisibleChildrenCountPackage,
        cGetVisibleChildrenPackage,
        cSetCaretPositionPackage,
        cGetCaretLocationPackage


    } PackageType;


    /**
     *  Union of all package contents
     */
    typedef union AllPackagesTag {

        // Initial Rendezvous packages
        MemoryMappedFileCreatedPackage memoryMappedFileCreatedPackage;

        JavaVMCreatedPackage javaVMCreatedPackage;
        JavaVMDestroyedPackage javaVMDestroyedPackage;
        WindowsATCreatedPackage windowsATCreatedPackage;
        WindowsATDestroyedPackage windowsATDestroyedPackage;
        JavaVMPresentNotificationPackage javaVMPresentNotificationPackage;
        WindowsATPresentNotificationPackage windowsATPresentNotificationPackage;

        // Core packages
        ReleaseJavaObjectPackage releaseJavaObject;
        GetAccessBridgeVersionPackage getAccessBridgeVersion;

        // Window packages
        GetAccessibleContextFromHWNDPackage getAccessibleContextFromHWND;
        GetHWNDFromAccessibleContextPackage getHWNDFromAccessibleContext;

        // AccessibleContext packages
        GetAccessibleContextAtPackage getAccessibleContextAt;
        GetAccessibleContextWithFocusPackage getAccessibleContextWithFocus;
        GetAccessibleContextInfoPackage getAccessibleContextInfo;
        GetAccessibleChildFromContextPackage getAccessibleChildFromContext;
        GetAccessibleParentFromContextPackage getAccessibleParentFromContext;

        // AccessibleText packages
        GetAccessibleTextInfoPackage getAccessibleTextInfo;
        GetAccessibleTextItemsPackage getAccessibleTextItems;
        GetAccessibleTextSelectionInfoPackage getAccessibleTextSelectionInfo;
        GetAccessibleTextAttributeInfoPackage getAccessibleTextAttributeInfo;
        GetAccessibleTextRectInfoPackage getAccessibleTextRectInfo;
        GetAccessibleTextLineBoundsPackage getAccessibleTextLineBounds;
        GetAccessibleTextRangePackage getAccessibleTextRange;

        // AccessibleValue packages
        GetCurrentAccessibleValueFromContextPackage getCurrentAccessibleValueFromContext;
        GetMaximumAccessibleValueFromContextPackage getMaximumAccessibleValueFromContext;
        GetMinimumAccessibleValueFromContextPackage getMinimumAccessibleValueFromContext;

        // AccessibleSelection packages
        AddAccessibleSelectionFromContextPackage addAccessibleSelectionFromContext;
        ClearAccessibleSelectionFromContextPackage clearAccessibleSelectionFromContext;
        GetAccessibleSelectionFromContextPackage getAccessibleSelectionFromContext;
        GetAccessibleSelectionCountFromContextPackage getAccessibleSelectionCountFromContext;
        IsAccessibleChildSelectedFromContextPackage isAccessibleChildSelectedFromContext;
        RemoveAccessibleSelectionFromContextPackage removeAccessibleSelectionFromContext;
        SelectAllAccessibleSelectionFromContextPackage selectAllAccessibleSelectionFromContext;

        // Event Notification Registration packages
        AddJavaEventNotificationPackage addJavaEventNotification;
        RemoveJavaEventNotificationPackage removeJavaEventNotification;
        AddAccessibilityEventNotificationPackage addAccessibilityEventNotification;
        RemoveAccessibilityEventNotificationPackage removeAccessibilityEventNotification;

        // Event contents packages
        //      PropertyChangePackage propertyChange;
        PropertyCaretChangePackage propertyCaretChangePackage;
        PropertyDescriptionChangePackage propertyDescriptionChangePackage;
        PropertyNameChangePackage propertyNameChangePackage;
        PropertySelectionChangePackage propertySelectionChangePackage;
        PropertyStateChangePackage propertyStateChangePackage;
        PropertyTextChangePackage propertyTextChangePackage;
        PropertyValueChangePackage propertyValueChangePackage;
        PropertyVisibleDataChangePackage propertyVisibleDataChangePackage;
        PropertyChildChangePackage propertyChildChangePackage;
        PropertyActiveDescendentChangePackage propertyActiveDescendentChangePackage;

        PropertyTableModelChangePackage propertyTableModelChangePackage;

        JavaShutdownPackage JavaShutdown;
        FocusGainedPackage focusGained;
        FocusLostPackage focusLost;

        CaretUpdatePackage caretUpdate;

        MouseClickedPackage mouseClicked;
        MouseEnteredPackage mouseEntered;
        MouseExitedPackage mouseExited;
        MousePressedPackage mousePressed;
        MouseReleasedPackage mouseReleased;

        MenuCanceledPackage menuCanceled;
        MenuDeselectedPackage menuDeselected;
        MenuSelectedPackage menuSelected;
        PopupMenuCanceledPackage popupMenuCanceled;
        PopupMenuWillBecomeInvisiblePackage popupMenuWillBecomeInvisible;
        PopupMenuWillBecomeVisiblePackage popupMenuWillBecomeVisible;

        // AccessibleRelationSet
        GetAccessibleRelationSetPackage getAccessibleRelationSet;

        // AccessibleHypertext
        GetAccessibleHypertextPackage _getAccessibleHypertext;
        ActivateAccessibleHyperlinkPackage _activateAccessibleHyperlink;
        GetAccessibleHyperlinkCountPackage _getAccessibleHyperlinkCount;
        GetAccessibleHypertextExtPackage _getAccessibleHypertextExt;
        GetAccessibleHypertextLinkIndexPackage _getAccessibleHypertextLinkIndex;
        GetAccessibleHyperlinkPackage _getAccessibleHyperlink;

        // Accessible KeyBinding, Icon and Action
        GetAccessibleKeyBindingsPackage getAccessibleKeyBindings;
        GetAccessibleIconsPackage getAccessibleIcons;
        GetAccessibleActionsPackage getAccessibleActions;
        DoAccessibleActionsPackage doAccessibleActions;

        // utility methods
        SetTextContentsPackage _setTextContents;
        GetParentWithRolePackage _getParentWithRole;
        GetTopLevelObjectPackage _getTopLevelObject;
        GetParentWithRoleElseRootPackage _getParentWithRoleElseRoot;
        GetObjectDepthPackage _getObjectDepth;
        GetActiveDescendentPackage _getActiveDescendent;

        // Additional methods for Teton
        GetVirtualAccessibleNamePackage _getVirtualAccessibleName;
        RequestFocusPackage _requestFocus;
        SelectTextRangePackage _selectTextRange;
        GetTextAttributesInRangePackage _getTextAttributesInRange;
        GetVisibleChildrenCountPackage _getVisibleChildrenCount;
        GetVisibleChildrenPackage _getVisibleChildren;
        SetCaretPositionPackage _setCaretPosition;

    } AllPackages;


    /**
     *  Union of all Java-initiated package contents
     */
    typedef union JavaInitiatedPackagesTag {

        // Initial Rendezvous packages
        JavaVMCreatedPackage javaVMCreatedPackage;
        JavaVMDestroyedPackage javaVMDestroyedPackage;
        JavaVMPresentNotificationPackage javaVMPresentNotificationPackage;

        // Event contents packages
        PropertyCaretChangePackage propertyCaretChangePackage;
        PropertyDescriptionChangePackage propertyDescriptionChangePackage;
        PropertyNameChangePackage propertyNameChangePackage;
        PropertySelectionChangePackage propertySelectionChangePackage;
        PropertyStateChangePackage propertyStateChangePackage;
        PropertyTextChangePackage propertyTextChangePackage;
        PropertyValueChangePackage propertyValueChangePackage;
        PropertyVisibleDataChangePackage propertyVisibleDataChangePackage;
        PropertyChildChangePackage propertyChildChangePackage;
        PropertyActiveDescendentChangePackage propertyActiveDescendentChangePackage;

        PropertyTableModelChangePackage propertyTableModelChangePackage;

        JavaShutdownPackage JavaShutdown;
        FocusGainedPackage focusGained;
        FocusLostPackage focusLost;

        CaretUpdatePackage caretUpdate;

        MouseClickedPackage mouseClicked;
        MouseEnteredPackage mouseEntered;
        MouseExitedPackage mouseExited;
        MousePressedPackage mousePressed;
        MouseReleasedPackage mouseReleased;

        MenuCanceledPackage menuCanceled;
        MenuDeselectedPackage menuDeselected;
        MenuSelectedPackage menuSelected;
        PopupMenuCanceledPackage popupMenuCanceled;
        PopupMenuWillBecomeInvisiblePackage popupMenuWillBecomeInvisible;
        PopupMenuWillBecomeVisiblePackage popupMenuWillBecomeVisible;

    } JavaInitiatedPackages;


    /**
     *  Union of all Windows-initiated package contents
     */
    typedef union WindowsInitiatedPackagesTag {

        // Initial Rendezvous packages
        MemoryMappedFileCreatedPackage memoryMappedFileCreatedPackage;

        WindowsATCreatedPackage windowsATCreatedPackage;
        WindowsATDestroyedPackage windowsATDestroyedPackage;
        WindowsATPresentNotificationPackage windowsATPresentNotificationPackage;

        // Core packages
        ReleaseJavaObjectPackage releaseJavaObject;
        GetAccessBridgeVersionPackage getAccessBridgeVersion;

        // Window packages
        GetAccessibleContextFromHWNDPackage getAccessibleContextFromHWND;
        GetHWNDFromAccessibleContextPackage getHWNDFromAccessibleContext;

        // AccessibleContext packages
        GetAccessibleContextAtPackage getAccessibleContextAt;
        GetAccessibleContextWithFocusPackage getAccessibleContextWithFocus;
        GetAccessibleContextInfoPackage getAccessibleContextInfo;
        GetAccessibleChildFromContextPackage getAccessibleChildFromContext;
        GetAccessibleParentFromContextPackage getAccessibleParentFromContext;

        // AccessibleText packages
        GetAccessibleTextInfoPackage getAccessibleTextInfo;
        GetAccessibleTextItemsPackage getAccessibleTextItems;
        GetAccessibleTextSelectionInfoPackage getAccessibleTextSelectionInfo;
        GetAccessibleTextAttributeInfoPackage getAccessibleTextAttributeInfo;
        GetAccessibleTextRectInfoPackage getAccessibleTextRectInfo;
        GetAccessibleTextLineBoundsPackage getAccessibleTextLineBounds;
        GetAccessibleTextRangePackage getAccessibleTextRange;

        // AccessibleValue packages
        GetCurrentAccessibleValueFromContextPackage getCurrentAccessibleValueFromContext;
        GetMaximumAccessibleValueFromContextPackage getMaximumAccessibleValueFromContext;
        GetMinimumAccessibleValueFromContextPackage getMinimumAccessibleValueFromContext;

        // AccessibleSelection packages
        AddAccessibleSelectionFromContextPackage addAccessibleSelectionFromContext;
        ClearAccessibleSelectionFromContextPackage clearAccessibleSelectionFromContext;
        GetAccessibleSelectionFromContextPackage getAccessibleSelectionFromContext;
        GetAccessibleSelectionCountFromContextPackage getAccessibleSelectionCountFromContext;
        IsAccessibleChildSelectedFromContextPackage isAccessibleChildSelectedFromContext;
        RemoveAccessibleSelectionFromContextPackage removeAccessibleSelectionFromContext;
        SelectAllAccessibleSelectionFromContextPackage selectAllAccessibleSelectionFromContext;

        // Event Notification Registration packages
        AddJavaEventNotificationPackage addJavaEventNotification;
        RemoveJavaEventNotificationPackage removeJavaEventNotification;
        AddAccessibilityEventNotificationPackage addAccessibilityEventNotification;
        RemoveAccessibilityEventNotificationPackage removeAccessibilityEventNotification;

        // AccessibleTable
        GetAccessibleTableInfoPackage _getAccessibleTableInfo;
        GetAccessibleTableCellInfoPackage _getAccessibleTableCellInfo;

        GetAccessibleTableRowHeaderPackage _getAccessibleTableRowHeader;
        GetAccessibleTableColumnHeaderPackage _getAccessibleTableColumnHeader;

        GetAccessibleTableRowDescriptionPackage _getAccessibleTableRowDescription;
        GetAccessibleTableColumnDescriptionPackage _getAccessibleTableColumnDescription;

        GetAccessibleTableRowSelectionCountPackage _getAccessibleTableRowSelectionCount;
        IsAccessibleTableRowSelectedPackage _isAccessibleTableRowSelected;
        GetAccessibleTableRowSelectionsPackage _getAccessibleTableRowSelections;

        GetAccessibleTableColumnSelectionCountPackage _getAccessibleTableColumnSelectionCount;
        IsAccessibleTableColumnSelectedPackage _isAccessibleTableColumnSelected;
        GetAccessibleTableColumnSelectionsPackage _getAccessibleTableColumnSelections;

        GetAccessibleTableRowPackage _getAccessibleTableRow;
        GetAccessibleTableColumnPackage _getAccessibleTableColumn;
        GetAccessibleTableIndexPackage _getAccessibleTableIndex;

        // AccessibleRelationSet
        GetAccessibleRelationSetPackage _getAccessibleRelationSet;

        // Accessible KeyBindings, Icons and Actions
        GetAccessibleKeyBindingsPackage _getAccessibleKeyBindings;
        GetAccessibleIconsPackage _getAccessibleIcons;
        GetAccessibleActionsPackage _getAccessibleActions;
        DoAccessibleActionsPackage _doAccessibleActions;


        IsSameObjectPackage _isSameObject;

        // utility methods
        SetTextContentsPackage _setTextContents;
        GetParentWithRolePackage _getParentWithRole;
        GetTopLevelObjectPackage _getTopLevelObject;
        GetParentWithRoleElseRootPackage _getParentWithRoleElseRoot;
        GetObjectDepthPackage _getObjectDepth;
        GetActiveDescendentPackage _getActiveDescendent;

        // Additional methods for Teton
        GetVirtualAccessibleNamePackage _getVirtualAccessibleName;
        RequestFocusPackage _requestFocus;
        SelectTextRangePackage _selectTextRange;
        GetTextAttributesInRangePackage _getTextAttributesInRange;
        GetVisibleChildrenCountPackage _getVisibleChildrenCount;
        GetVisibleChildrenPackage _getVisibleChildren;
        SetCaretPositionPackage _setCaretPosition;


    } WindowsInitiatedPackages;


#ifdef __cplusplus
}
#endif

#endif

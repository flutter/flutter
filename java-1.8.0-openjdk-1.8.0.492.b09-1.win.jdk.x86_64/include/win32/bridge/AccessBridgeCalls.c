/*
 * Copyright (c) 2005, 2010, Oracle and/or its affiliates. All rights reserved.
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
 * @(#)AccessBridgeCalls.c      1.25 05/08/22
 */

/*
 * Wrapper functions around calls to the AccessBridge DLL
 */


#include <windows.h>
#include <jni.h>


//#define ACCESSBRIDGE_32
//#define ACCESSBRIDGE_64

#include "AccessBridgeCalls.h"
#include "AccessBridgeDebug.h"

#ifdef __cplusplus
extern "C" {
#endif

    HINSTANCE theAccessBridgeInstance;
    AccessBridgeFPs theAccessBridge;

    BOOL theAccessBridgeInitializedFlag = FALSE;

#define LOAD_FP(result, type, name) \
    PrintDebugString("LOAD_FP loading: %s ...", name); \
    if ((theAccessBridge.result = \
        (type) GetProcAddress(theAccessBridgeInstance, name)) == (type) 0) { \
        PrintDebugString("LOAD_FP failed: %s", name); \
        return FALSE; \
    }

    BOOL initializeAccessBridge() {

#ifdef ACCESSBRIDGE_ARCH_32 // For 32bit AT new bridge
        theAccessBridgeInstance = LoadLibrary("WINDOWSACCESSBRIDGE-32");
#else
#ifdef ACCESSBRIDGE_ARCH_64 // For 64bit AT new bridge
                theAccessBridgeInstance = LoadLibrary("WINDOWSACCESSBRIDGE-64");
#else // legacy
        theAccessBridgeInstance = LoadLibrary("WINDOWSACCESSBRIDGE");
#endif
#endif
        if (theAccessBridgeInstance != 0) {
            LOAD_FP(Windows_run, Windows_runFP, "Windows_run");

            LOAD_FP(SetJavaShutdown, SetJavaShutdownFP, "setJavaShutdownFP");
            LOAD_FP(SetFocusGained, SetFocusGainedFP, "setFocusGainedFP");
            LOAD_FP(SetFocusLost, SetFocusLostFP, "setFocusLostFP");

            LOAD_FP(SetCaretUpdate, SetCaretUpdateFP, "setCaretUpdateFP");

            LOAD_FP(SetMouseClicked, SetMouseClickedFP, "setMouseClickedFP");
            LOAD_FP(SetMouseEntered, SetMouseEnteredFP, "setMouseEnteredFP");
            LOAD_FP(SetMouseExited, SetMouseExitedFP, "setMouseExitedFP");
            LOAD_FP(SetMousePressed, SetMousePressedFP, "setMousePressedFP");
            LOAD_FP(SetMouseReleased, SetMouseReleasedFP, "setMouseReleasedFP");

            LOAD_FP(SetMenuCanceled, SetMenuCanceledFP, "setMenuCanceledFP");
            LOAD_FP(SetMenuDeselected, SetMenuDeselectedFP, "setMenuDeselectedFP");
            LOAD_FP(SetMenuSelected, SetMenuSelectedFP, "setMenuSelectedFP");
            LOAD_FP(SetPopupMenuCanceled, SetPopupMenuCanceledFP, "setPopupMenuCanceledFP");
            LOAD_FP(SetPopupMenuWillBecomeInvisible, SetPopupMenuWillBecomeInvisibleFP, "setPopupMenuWillBecomeInvisibleFP");
            LOAD_FP(SetPopupMenuWillBecomeVisible, SetPopupMenuWillBecomeVisibleFP, "setPopupMenuWillBecomeVisibleFP");

            LOAD_FP(SetPropertyNameChange, SetPropertyNameChangeFP, "setPropertyNameChangeFP");
            LOAD_FP(SetPropertyDescriptionChange, SetPropertyDescriptionChangeFP, "setPropertyDescriptionChangeFP");
            LOAD_FP(SetPropertyStateChange, SetPropertyStateChangeFP, "setPropertyStateChangeFP");
            LOAD_FP(SetPropertyValueChange, SetPropertyValueChangeFP, "setPropertyValueChangeFP");
            LOAD_FP(SetPropertySelectionChange, SetPropertySelectionChangeFP, "setPropertySelectionChangeFP");
            LOAD_FP(SetPropertyTextChange, SetPropertyTextChangeFP, "setPropertyTextChangeFP");
            LOAD_FP(SetPropertyCaretChange, SetPropertyCaretChangeFP, "setPropertyCaretChangeFP");
            LOAD_FP(SetPropertyVisibleDataChange, SetPropertyVisibleDataChangeFP, "setPropertyVisibleDataChangeFP");
            LOAD_FP(SetPropertyChildChange, SetPropertyChildChangeFP, "setPropertyChildChangeFP");
            LOAD_FP(SetPropertyActiveDescendentChange, SetPropertyActiveDescendentChangeFP, "setPropertyActiveDescendentChangeFP");

            LOAD_FP(SetPropertyTableModelChange, SetPropertyTableModelChangeFP, "setPropertyTableModelChangeFP");

            LOAD_FP(ReleaseJavaObject, ReleaseJavaObjectFP, "releaseJavaObject");
            LOAD_FP(GetVersionInfo, GetVersionInfoFP, "getVersionInfo");

            LOAD_FP(IsJavaWindow, IsJavaWindowFP, "isJavaWindow");
            LOAD_FP(IsSameObject, IsSameObjectFP, "isSameObject");
            LOAD_FP(GetAccessibleContextFromHWND, GetAccessibleContextFromHWNDFP, "getAccessibleContextFromHWND");
            LOAD_FP(getHWNDFromAccessibleContext, getHWNDFromAccessibleContextFP, "getHWNDFromAccessibleContext");

            LOAD_FP(GetAccessibleContextAt, GetAccessibleContextAtFP, "getAccessibleContextAt");
            LOAD_FP(GetAccessibleContextWithFocus, GetAccessibleContextWithFocusFP, "getAccessibleContextWithFocus");
            LOAD_FP(GetAccessibleContextInfo, GetAccessibleContextInfoFP, "getAccessibleContextInfo");
            LOAD_FP(GetAccessibleChildFromContext, GetAccessibleChildFromContextFP, "getAccessibleChildFromContext");
            LOAD_FP(GetAccessibleParentFromContext, GetAccessibleParentFromContextFP, "getAccessibleParentFromContext");

            /* begin AccessibleTable */
            LOAD_FP(getAccessibleTableInfo, getAccessibleTableInfoFP, "getAccessibleTableInfo");
            LOAD_FP(getAccessibleTableCellInfo, getAccessibleTableCellInfoFP, "getAccessibleTableCellInfo");

            LOAD_FP(getAccessibleTableRowHeader, getAccessibleTableRowHeaderFP, "getAccessibleTableRowHeader");
            LOAD_FP(getAccessibleTableColumnHeader, getAccessibleTableColumnHeaderFP, "getAccessibleTableColumnHeader");

            LOAD_FP(getAccessibleTableRowDescription, getAccessibleTableRowDescriptionFP, "getAccessibleTableRowDescription");
            LOAD_FP(getAccessibleTableColumnDescription, getAccessibleTableColumnDescriptionFP, "getAccessibleTableColumnDescription");

            LOAD_FP(getAccessibleTableRowSelectionCount, getAccessibleTableRowSelectionCountFP,
                    "getAccessibleTableRowSelectionCount");
            LOAD_FP(isAccessibleTableRowSelected, isAccessibleTableRowSelectedFP,
                    "isAccessibleTableRowSelected");
            LOAD_FP(getAccessibleTableRowSelections, getAccessibleTableRowSelectionsFP,
                    "getAccessibleTableRowSelections");

            LOAD_FP(getAccessibleTableColumnSelectionCount, getAccessibleTableColumnSelectionCountFP,
                    "getAccessibleTableColumnSelectionCount");
            LOAD_FP(isAccessibleTableColumnSelected, isAccessibleTableColumnSelectedFP,
                    "isAccessibleTableColumnSelected");
            LOAD_FP(getAccessibleTableColumnSelections, getAccessibleTableColumnSelectionsFP,
                    "getAccessibleTableColumnSelections");

            LOAD_FP(getAccessibleTableRow, getAccessibleTableRowFP,
                    "getAccessibleTableRow");
            LOAD_FP(getAccessibleTableColumn, getAccessibleTableColumnFP,
                    "getAccessibleTableColumn");
            LOAD_FP(getAccessibleTableIndex, getAccessibleTableIndexFP,
                    "getAccessibleTableIndex");

            /* end AccessibleTable */

            /* AccessibleRelationSet */
            LOAD_FP(getAccessibleRelationSet, getAccessibleRelationSetFP, "getAccessibleRelationSet");

            /* AccessibleHypertext */
            LOAD_FP(getAccessibleHypertext, getAccessibleHypertextFP, "getAccessibleHypertext");
            LOAD_FP(activateAccessibleHyperlink, activateAccessibleHyperlinkFP, "activateAccessibleHyperlink");
            LOAD_FP(getAccessibleHyperlinkCount, getAccessibleHyperlinkCountFP, "getAccessibleHyperlinkCount");
            LOAD_FP(getAccessibleHypertextExt, getAccessibleHypertextExtFP, "getAccessibleHypertextExt");
            LOAD_FP(getAccessibleHypertextLinkIndex, getAccessibleHypertextLinkIndexFP, "getAccessibleHypertextLinkIndex");
            LOAD_FP(getAccessibleHyperlink, getAccessibleHyperlinkFP, "getAccessibleHyperlink");

            /* Accessible KeyBinding, Icon and Action */
            LOAD_FP(getAccessibleKeyBindings, getAccessibleKeyBindingsFP, "getAccessibleKeyBindings");
            LOAD_FP(getAccessibleIcons, getAccessibleIconsFP, "getAccessibleIcons");
            LOAD_FP(getAccessibleActions, getAccessibleActionsFP, "getAccessibleActions");
            LOAD_FP(doAccessibleActions, doAccessibleActionsFP, "doAccessibleActions");

            /* AccessibleText */
            LOAD_FP(GetAccessibleTextInfo, GetAccessibleTextInfoFP, "getAccessibleTextInfo");
            LOAD_FP(GetAccessibleTextItems, GetAccessibleTextItemsFP, "getAccessibleTextItems");
            LOAD_FP(GetAccessibleTextSelectionInfo, GetAccessibleTextSelectionInfoFP, "getAccessibleTextSelectionInfo");
            LOAD_FP(GetAccessibleTextAttributes, GetAccessibleTextAttributesFP, "getAccessibleTextAttributes");
            LOAD_FP(GetAccessibleTextRect, GetAccessibleTextRectFP, "getAccessibleTextRect");
            LOAD_FP(GetAccessibleTextLineBounds, GetAccessibleTextLineBoundsFP, "getAccessibleTextLineBounds");
            LOAD_FP(GetAccessibleTextRange, GetAccessibleTextRangeFP, "getAccessibleTextRange");

            LOAD_FP(GetCurrentAccessibleValueFromContext, GetCurrentAccessibleValueFromContextFP, "getCurrentAccessibleValueFromContext");
            LOAD_FP(GetMaximumAccessibleValueFromContext, GetMaximumAccessibleValueFromContextFP, "getMaximumAccessibleValueFromContext");
            LOAD_FP(GetMinimumAccessibleValueFromContext, GetMinimumAccessibleValueFromContextFP, "getMinimumAccessibleValueFromContext");

            LOAD_FP(AddAccessibleSelectionFromContext, AddAccessibleSelectionFromContextFP, "addAccessibleSelectionFromContext");
            LOAD_FP(ClearAccessibleSelectionFromContext, ClearAccessibleSelectionFromContextFP, "clearAccessibleSelectionFromContext");
            LOAD_FP(GetAccessibleSelectionFromContext, GetAccessibleSelectionFromContextFP, "getAccessibleSelectionFromContext");
            LOAD_FP(GetAccessibleSelectionCountFromContext, GetAccessibleSelectionCountFromContextFP, "getAccessibleSelectionCountFromContext");
            LOAD_FP(IsAccessibleChildSelectedFromContext, IsAccessibleChildSelectedFromContextFP, "isAccessibleChildSelectedFromContext");
            LOAD_FP(RemoveAccessibleSelectionFromContext, RemoveAccessibleSelectionFromContextFP, "removeAccessibleSelectionFromContext");
            LOAD_FP(SelectAllAccessibleSelectionFromContext, SelectAllAccessibleSelectionFromContextFP, "selectAllAccessibleSelectionFromContext");

            LOAD_FP(setTextContents, setTextContentsFP, "setTextContents");
            LOAD_FP(getParentWithRole, getParentWithRoleFP, "getParentWithRole");
            LOAD_FP(getTopLevelObject, getTopLevelObjectFP, "getTopLevelObject");
            LOAD_FP(getParentWithRoleElseRoot, getParentWithRoleElseRootFP, "getParentWithRoleElseRoot");
            LOAD_FP(getObjectDepth, getObjectDepthFP, "getObjectDepth");
            LOAD_FP(getActiveDescendent, getActiveDescendentFP, "getActiveDescendent");

            // additional methods for Teton
            LOAD_FP(getVirtualAccessibleName, getVirtualAccessibleNameFP, "getVirtualAccessibleName");
            LOAD_FP(requestFocus, requestFocusFP, "requestFocus");
            LOAD_FP(selectTextRange, selectTextRangeFP, "selectTextRange");
            LOAD_FP(getTextAttributesInRange, getTextAttributesInRangeFP, "getTextAttributesInRange");
            LOAD_FP(getVisibleChildrenCount, getVisibleChildrenCountFP, "getVisibleChildrenCount");
            LOAD_FP(getVisibleChildren, getVisibleChildrenFP, "getVisibleChildren");
            LOAD_FP(setCaretPosition, setCaretPositionFP, "setCaretPosition");
            LOAD_FP(getCaretLocation, getCaretLocationFP, "getCaretLocation");

            LOAD_FP(getEventsWaiting, getEventsWaitingFP, "getEventsWaiting");

            theAccessBridge.Windows_run();

            theAccessBridgeInitializedFlag = TRUE;
            PrintDebugString("theAccessBridgeInitializedFlag = TRUE");
            return TRUE;
        } else {
            return FALSE;
        }
    }


    BOOL shutdownAccessBridge() {
        BOOL result;
        DWORD error;
        theAccessBridgeInitializedFlag = FALSE;
        if (theAccessBridgeInstance != (HANDLE) 0) {
            result = FreeLibrary(theAccessBridgeInstance);
            if (result != TRUE) {
                error = GetLastError();
            }
            return TRUE;
        }
        return FALSE;
    }


    void SetJavaShutdown(AccessBridge_JavaShutdownFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetJavaShutdown(fp);
        }
    }

    void SetFocusGained(AccessBridge_FocusGainedFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetFocusGained(fp);
        }
    }

    void SetFocusLost(AccessBridge_FocusLostFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetFocusLost(fp);
        }
    }


    void SetCaretUpdate(AccessBridge_CaretUpdateFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetCaretUpdate(fp);
        }
    }


    void SetMouseClicked(AccessBridge_MouseClickedFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetMouseClicked(fp);
        }
    }

    void SetMouseEntered(AccessBridge_MouseEnteredFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetMouseEntered(fp);
        }
    }

    void SetMouseExited(AccessBridge_MouseExitedFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetMouseExited(fp);
        }
    }

    void SetMousePressed(AccessBridge_MousePressedFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetMousePressed(fp);
        }
    }

    void SetMouseReleased(AccessBridge_MouseReleasedFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetMouseReleased(fp);
        }
    }


    void SetMenuCanceled(AccessBridge_MenuCanceledFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetMenuCanceled(fp);
        }
    }

    void SetMenuDeselected(AccessBridge_MenuDeselectedFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetMenuDeselected(fp);
        }
    }

    void SetMenuSelected(AccessBridge_MenuSelectedFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetMenuSelected(fp);
        }
    }

    void SetPopupMenuCanceled(AccessBridge_PopupMenuCanceledFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPopupMenuCanceled(fp);
        }
    }

    void SetPopupMenuWillBecomeInvisible(AccessBridge_PopupMenuWillBecomeInvisibleFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPopupMenuWillBecomeInvisible(fp);
        }
    }

    void SetPopupMenuWillBecomeVisible(AccessBridge_PopupMenuWillBecomeVisibleFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPopupMenuWillBecomeVisible(fp);
        }
    }


    void SetPropertyNameChange(AccessBridge_PropertyNameChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyNameChange(fp);
        }
    }

    void SetPropertyDescriptionChange(AccessBridge_PropertyDescriptionChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyDescriptionChange(fp);
        }
    }

    void SetPropertyStateChange(AccessBridge_PropertyStateChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyStateChange(fp);
        }
    }

    void SetPropertyValueChange(AccessBridge_PropertyValueChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyValueChange(fp);
        }
    }

    void SetPropertySelectionChange(AccessBridge_PropertySelectionChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertySelectionChange(fp);
        }
    }

    void SetPropertyTextChange(AccessBridge_PropertyTextChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyTextChange(fp);
        }
    }

    void SetPropertyCaretChange(AccessBridge_PropertyCaretChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyCaretChange(fp);
        }
    }

    void SetPropertyVisibleDataChange(AccessBridge_PropertyVisibleDataChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyVisibleDataChange(fp);
        }
    }

    void SetPropertyChildChange(AccessBridge_PropertyChildChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyChildChange(fp);
        }
    }

    void SetPropertyActiveDescendentChange(AccessBridge_PropertyActiveDescendentChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyActiveDescendentChange(fp);
        }
    }

    void SetPropertyTableModelChange(AccessBridge_PropertyTableModelChangeFP fp) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SetPropertyTableModelChange(fp);
        }
    }

    /**
     * General routines
     */
    void ReleaseJavaObject(long vmID, Java_Object object) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.ReleaseJavaObject(vmID, object);
        }
    }

    BOOL GetVersionInfo(long vmID, AccessBridgeVersionInfo *info) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetVersionInfo(vmID, info);
        }
        return FALSE;
    }


    /**
     * Window routines
     */
    BOOL IsJavaWindow(HWND window) {
        if (theAccessBridgeInitializedFlag == TRUE) {
                        BOOL ret ;
                        ret = theAccessBridge.IsJavaWindow(window);
            return ret ;

        }
        return FALSE;
    }


    /**
     * Returns the virtual machine ID and AccessibleContext for a top-level window
     */
    BOOL GetAccessibleContextFromHWND(HWND target, long *vmID, AccessibleContext *ac) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleContextFromHWND(target, vmID, ac);
        }
        return FALSE;
    }

    /**
     * Returns the HWND from the AccessibleContext of a top-level window.  Returns 0
     *   on error or if the AccessibleContext does not refer to a top-level window.
     */
    HWND getHWNDFromAccessibleContext(long vmID, JOBJECT64 accesibleContext) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getHWNDFromAccessibleContext(vmID, accesibleContext);
        }
        return (HWND)0;
    }

    /**
     * returns whether two objects are the same
     */
    BOOL IsSameObject(long vmID, JOBJECT64 obj1, JOBJECT64 obj2) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.IsSameObject(vmID, obj1, obj2);
        }
        return FALSE;
    }

    /**
     * Sets editable text contents.  The AccessibleContext must implement AccessibleEditableText and
     *   be editable.  The maximum text length is MAX_STRING_SIZE - 1.
     * Returns whether successful
     */
    BOOL setTextContents (const long vmID, const AccessibleContext accessibleContext, const wchar_t *text) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.setTextContents(vmID, accessibleContext, text);
        }
        return FALSE;
    }

    /**
     * Returns the Accessible Context with the specified role that is the
     * ancestor of a given object. The role is one of the role strings
     * defined in AccessBridgePackages.h
     * If there is no ancestor object that has the specified role,
     * returns (AccessibleContext)0.
     */
    AccessibleContext getParentWithRole (const long vmID, const AccessibleContext accessibleContext,
                                         const wchar_t *role) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getParentWithRole(vmID, accessibleContext, role);
        }
        return (AccessibleContext)0;
    }

    /**
     * Returns the Accessible Context with the specified role that is the
     * ancestor of a given object. The role is one of the role strings
     * defined in AccessBridgePackages.h.  If an object with the specified
     * role does not exist, returns the top level object for the Java Window.
     * Returns (AccessibleContext)0 on error.
     */
    AccessibleContext getParentWithRoleElseRoot (const long vmID, const AccessibleContext accessibleContext,
                                                 const wchar_t *role) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getParentWithRoleElseRoot(vmID, accessibleContext, role);
        }
        return (AccessibleContext)0;
    }

    /**
     * Returns the Accessible Context for the top level object in
     * a Java Window.  This is same Accessible Context that is obtained
     * from GetAccessibleContextFromHWND for that window.  Returns
     * (AccessibleContext)0 on error.
     */
    AccessibleContext getTopLevelObject (const long vmID, const AccessibleContext accessibleContext) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getTopLevelObject(vmID, accessibleContext);
        }
        return (AccessibleContext)0;
    }

    /**
     * Returns how deep in the object hierarchy a given object is.
     * The top most object in the object hierarchy has an object depth of 0.
     * Returns -1 on error.
     */
    int getObjectDepth (const long vmID, const AccessibleContext accessibleContext) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getObjectDepth(vmID, accessibleContext);
        }
        return -1;
    }

    /**
     * Returns the Accessible Context of the current ActiveDescendent of an object.
     * This method assumes the ActiveDescendent is the component that is currently
     * selected in a container object.
     * Returns (AccessibleContext)0 on error or if there is no selection.
     */
    AccessibleContext getActiveDescendent (const long vmID, const AccessibleContext accessibleContext) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getActiveDescendent(vmID, accessibleContext);
        }
        return (AccessibleContext)0;
    }


    /**
     * Accessible Context routines
     */
    BOOL GetAccessibleContextAt(long vmID, AccessibleContext acParent,
                                jint x, jint y, AccessibleContext *ac) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleContextAt(vmID, acParent, x, y, ac);
        }
        return FALSE;
    }

    BOOL GetAccessibleContextWithFocus(HWND window, long *vmID, AccessibleContext *ac) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleContextWithFocus(window, vmID, ac);
        }
        return FALSE;
    }

    BOOL GetAccessibleContextInfo(long vmID, AccessibleContext ac, AccessibleContextInfo *info) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleContextInfo(vmID, ac, info);
        }
        return FALSE;
    }

    AccessibleContext GetAccessibleChildFromContext(long vmID, AccessibleContext ac, jint index) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleChildFromContext(vmID, ac, index);
        }
        return (AccessibleContext) 0;
    }

    AccessibleContext GetAccessibleParentFromContext(long vmID, AccessibleContext ac) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleParentFromContext(vmID, ac);
        }
        return (AccessibleContext) 0;
    }

    /* begin AccessibleTable routines */

    /*
     * get information about an AccessibleTable
     */
    BOOL getAccessibleTableInfo(long vmID, AccessibleContext acParent, AccessibleTableInfo *tableInfo) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableInfo(vmID, acParent, tableInfo);
        }
        return FALSE;
    }

    /*
     * get information about an AccessibleTable cell
     */
    BOOL getAccessibleTableCellInfo(long vmID, AccessibleTable accessibleTable,
                                    jint row, jint column, AccessibleTableCellInfo *tableCellInfo) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableCellInfo(vmID, accessibleTable, row, column, tableCellInfo);
        }
        return FALSE;
    }

    /*
     * get information about an AccessibleTable row header
     */
    BOOL getAccessibleTableRowHeader(long vmID, AccessibleContext acParent, AccessibleTableInfo *tableInfo) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableRowHeader(vmID, acParent, tableInfo);
        }
        return FALSE;
    }

    /*
     * get information about an AccessibleTable column header
     */
    BOOL getAccessibleTableColumnHeader(long vmID, AccessibleContext acParent, AccessibleTableInfo *tableInfo) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableColumnHeader(vmID, acParent, tableInfo);
        }
        return FALSE;
    }

    /*
     * return a description of an AccessibleTable row header
     */
    AccessibleContext getAccessibleTableRowDescription(long vmID, AccessibleContext acParent, jint row) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableRowDescription(vmID, acParent, row);
        }
        return (AccessibleContext)0;
    }

    /*
     * return a description of an AccessibleTable column header
     */
    AccessibleContext getAccessibleTableColumnDescription(long vmID, AccessibleContext acParent, jint column) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableColumnDescription(vmID, acParent, column);
        }
        return (AccessibleContext)0;
    }

    /*
     * return the number of rows selected in an AccessibleTable
     */
    jint getAccessibleTableRowSelectionCount(long vmID, AccessibleTable table) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableRowSelectionCount(vmID, table);
        }
        return -1;
    }

    /*
     * return whether a row is selected in an AccessibleTable
     */
    BOOL isAccessibleTableRowSelected(long vmID, AccessibleTable table, jint row) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.isAccessibleTableRowSelected(vmID, table, row);
        }
        return FALSE;
    }

    /*
     * get an array of selected rows in an AccessibleTable
     */
    BOOL getAccessibleTableRowSelections(long vmID, AccessibleTable table, jint count, jint *selections) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableRowSelections(vmID, table, count, selections);
        }
        return FALSE;
    }

    /*
     * return the number of columns selected in an AccessibleTable
     */
    jint getAccessibleTableColumnSelectionCount(long vmID, AccessibleTable table) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableColumnSelectionCount(vmID, table);
        }
        return -1;
    }

    /*
     * return whether a column is selected in an AccessibleTable
     */
    BOOL isAccessibleTableColumnSelected(long vmID, AccessibleTable table, jint column) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.isAccessibleTableColumnSelected(vmID, table, column);
        }
        return FALSE;
    }

    /*
     * get an array of columns selected in an AccessibleTable
     */
    BOOL getAccessibleTableColumnSelections(long vmID, AccessibleTable table, jint count, jint *selections) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableColumnSelections(vmID, table, count, selections);
        }
        return FALSE;
    }

    /*
     * return the row number for a cell at a given index
     */
    jint
    getAccessibleTableRow(long vmID, AccessibleTable table, jint index) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableRow(vmID, table, index);
        }
        return -1;
    }

    /*
     * return the column number for a cell at a given index
     */
    jint
    getAccessibleTableColumn(long vmID, AccessibleTable table, jint index) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableColumn(vmID, table, index);
        }
        return -1;
    }

    /*
     * return the index of a cell at a given row and column
     */
    jint
    getAccessibleTableIndex(long vmID, AccessibleTable table, jint row, jint column) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleTableIndex(vmID, table, row, column);
        }
        return -1;
    }

    /* end AccessibleTable routines */


    /**
     * Accessible Text routines
     */
    BOOL GetAccessibleTextInfo(long vmID, AccessibleText at, AccessibleTextInfo *textInfo, jint x, jint y) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleTextInfo(vmID, at, textInfo, x, y);
        }
        return FALSE;
    }

    BOOL GetAccessibleTextItems(long vmID, AccessibleText at, AccessibleTextItemsInfo *textItems, jint index) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleTextItems(vmID, at, textItems, index);
        }
        return FALSE;
    }

    BOOL GetAccessibleTextSelectionInfo(long vmID, AccessibleText at, AccessibleTextSelectionInfo *textSelection) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleTextSelectionInfo(vmID, at, textSelection);
        }
        return FALSE;
    }

    BOOL GetAccessibleTextAttributes(long vmID, AccessibleText at, jint index, AccessibleTextAttributesInfo *attributes) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleTextAttributes(vmID, at, index, attributes);
        }
        return FALSE;
    }

    BOOL GetAccessibleTextRect(long vmID, AccessibleText at, AccessibleTextRectInfo *rectInfo, jint index) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleTextRect(vmID, at, rectInfo, index);
        }
        return FALSE;
    }

    BOOL GetAccessibleTextLineBounds(long vmID, AccessibleText at, jint index, jint *startIndex, jint *endIndex) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleTextLineBounds(vmID, at, index, startIndex, endIndex);
        }
        return FALSE;
    }

    BOOL GetAccessibleTextRange(long vmID, AccessibleText at, jint start, jint end, wchar_t *text, short len) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleTextRange(vmID, at, start, end, text, len);
        }
        return FALSE;
    }

    /**
     * AccessibleRelationSet routines
     */
    BOOL getAccessibleRelationSet(long vmID, AccessibleContext accessibleContext,
                                  AccessibleRelationSetInfo *relationSetInfo) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleRelationSet(vmID, accessibleContext, relationSetInfo);
        }
        return FALSE;
    }

    /**
     * AccessibleHypertext routines
     */

    // Gets AccessibleHypertext for an AccessibleContext
    BOOL getAccessibleHypertext(long vmID, AccessibleContext accessibleContext,
                                AccessibleHypertextInfo *hypertextInfo) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleHypertext(vmID, accessibleContext, hypertextInfo);
        }
        return FALSE;
    }

    // Activates an AccessibleHyperlink for an AccessibleContext
    BOOL activateAccessibleHyperlink(long vmID, AccessibleContext accessibleContext,
                                     AccessibleHyperlink accessibleHyperlink) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.activateAccessibleHyperlink(vmID, accessibleContext, accessibleHyperlink);
        }
        return FALSE;
    }

    /*
     * Returns the number of hyperlinks in a component
     * Maps to AccessibleHypertext.getLinkCount.
     * Returns -1 on error.
     */
    jint getAccessibleHyperlinkCount(const long vmID,
                                     const AccessibleContext accessibleContext) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleHyperlinkCount(vmID, accessibleContext);
        }
        return -1;
    }

    /*
     * This method is used to iterate through the hyperlinks in a component.  It
     * returns hypertext information for a component starting at hyperlink index
     * nStartIndex.  No more than MAX_HYPERLINKS AccessibleHypertextInfo objects will
     * be returned for each call to this method.
     * returns FALSE on error.
     */
    BOOL getAccessibleHypertextExt(const long vmID,
                                   const AccessibleContext accessibleContext,
                                   const jint nStartIndex,
                                   /* OUT */ AccessibleHypertextInfo *hypertextInfo) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleHypertextExt(vmID,
                                                             accessibleContext,
                                                             nStartIndex,
                                                             hypertextInfo);
        }
        return FALSE;
    }

    /*
     * Returns the index into an array of hyperlinks that is associated with
     * a character index in document;
     * Maps to AccessibleHypertext.getLinkIndex.
     * Returns -1 on error.
     */
    jint getAccessibleHypertextLinkIndex(const long vmID,
                                         const AccessibleHypertext hypertext,
                                         const jint nIndex) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleHypertextLinkIndex(vmID,
                                                                   hypertext,
                                                                   nIndex);
        }
        return -1;
    }

    /*
     * Returns the nth hyperlink in a document.
     * Maps to AccessibleHypertext.getLink.
     * Returns -1 on error
     */
    BOOL getAccessibleHyperlink(const long vmID,
                                const AccessibleHypertext hypertext,
                                const jint nIndex,
                                /* OUT */ AccessibleHyperlinkInfo *hyperlinkInfo) {

        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleHyperlink(vmID,
                                                          hypertext,
                                                          nIndex,
                                                          hyperlinkInfo);
        }
        return FALSE;
    }


    /* Accessible KeyBindings, Icons and Actions */
    BOOL getAccessibleKeyBindings(long vmID, AccessibleContext accessibleContext,
                                  AccessibleKeyBindings *keyBindings) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleKeyBindings(vmID, accessibleContext, keyBindings);
        }
        return FALSE;
    }

    BOOL getAccessibleIcons(long vmID, AccessibleContext accessibleContext,
                            AccessibleIcons *icons) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleIcons(vmID, accessibleContext, icons);
        }
        return FALSE;
    }

    BOOL getAccessibleActions(long vmID, AccessibleContext accessibleContext,
                              AccessibleActions *actions) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getAccessibleActions(vmID, accessibleContext, actions);
        }
        return FALSE;
    }

    BOOL doAccessibleActions(long vmID, AccessibleContext accessibleContext,
                             AccessibleActionsToDo *actionsToDo, jint *failure) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.doAccessibleActions(vmID, accessibleContext, actionsToDo, failure);
        }
        return FALSE;
    }

    /**
     * Accessible Value routines
     */
    BOOL GetCurrentAccessibleValueFromContext(long vmID, AccessibleValue av, wchar_t *value, short len) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetCurrentAccessibleValueFromContext(vmID, av, value, len);
        }
        return FALSE;
    }

    BOOL GetMaximumAccessibleValueFromContext(long vmID, AccessibleValue av, wchar_t *value, short len) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetMaximumAccessibleValueFromContext(vmID, av, value, len);
        }
        return FALSE;
    }

    BOOL GetMinimumAccessibleValueFromContext(long vmID, AccessibleValue av, wchar_t *value, short len) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetMinimumAccessibleValueFromContext(vmID, av, value, len);
        }
        return FALSE;
    }


    /**
     * Accessible Selection routines
     */
    void addAccessibleSelectionFromContext(long vmID, AccessibleSelection as, int i) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.AddAccessibleSelectionFromContext(vmID, as, i);
        }
    }

    void clearAccessibleSelectionFromContext(long vmID, AccessibleSelection as) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.ClearAccessibleSelectionFromContext(vmID, as);
        }
    }

    JOBJECT64 GetAccessibleSelectionFromContext(long vmID, AccessibleSelection as, int i) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleSelectionFromContext(vmID, as, i);
        }
        return (JOBJECT64) 0;
    }

    int GetAccessibleSelectionCountFromContext(long vmID, AccessibleSelection as) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.GetAccessibleSelectionCountFromContext(vmID, as);
        }
        return -1;
    }

    BOOL IsAccessibleChildSelectedFromContext(long vmID, AccessibleSelection as, int i) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.IsAccessibleChildSelectedFromContext(vmID, as, i);
        }
        return FALSE;
    }

    void RemoveAccessibleSelectionFromContext(long vmID, AccessibleSelection as, int i) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.RemoveAccessibleSelectionFromContext(vmID, as, i);
        }
    }

    void SelectAllAccessibleSelectionFromContext(long vmID, AccessibleSelection as) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            theAccessBridge.SelectAllAccessibleSelectionFromContext(vmID, as);
        }
    }

    /**
     * Additional methods for Teton
     */

    /**
     * Gets the AccessibleName for a component based upon the JAWS algorithm. Returns
     * whether successful.
     *
     * Bug ID 4916682 - Implement JAWS AccessibleName policy
     */
    BOOL getVirtualAccessibleName(const long vmID, const AccessibleContext accessibleContext,
                                  wchar_t *name, int len) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getVirtualAccessibleName(vmID, accessibleContext, name, len);
        }
        return FALSE;
    }

    /**
     * Request focus for a component. Returns whether successful;
     *
     * Bug ID 4944757 - requestFocus method needed
     */
    BOOL requestFocus(const long vmID, const AccessibleContext accessibleContext) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.requestFocus(vmID, accessibleContext);
        }
        return FALSE;
    }

    /**
     * Selects text between two indices.  Selection includes the text at the start index
     * and the text at the end index. Returns whether successful;
     *
     * Bug ID 4944758 - selectTextRange method needed
     */
    BOOL selectTextRange(const long vmID, const AccessibleContext accessibleContext,
                         const int startIndex, const int endIndex) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.selectTextRange(vmID, accessibleContext, startIndex, endIndex);
        }
        return FALSE;
    }

    /**
     * Get text attributes between two indices.  The attribute list includes the text at the
     * start index and the text at the end index. Returns whether successful;
     *
     * Bug ID 4944761 - getTextAttributes between two indices method needed
     */
    BOOL getTextAttributesInRange(const long vmID, const AccessibleContext accessibleContext,
                                  const int startIndex, const int endIndex,
                                  AccessibleTextAttributesInfo *attributes, short *len) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getTextAttributesInRange(vmID, accessibleContext, startIndex,
                                                            endIndex, attributes, len);
        }
        return FALSE;
    }

    /**
     * Returns the number of visible children of a component. Returns -1 on error.
     *
     * Bug ID 4944762- getVisibleChildren for list-like components needed
     */
    int getVisibleChildrenCount(const long vmID, const AccessibleContext accessibleContext) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getVisibleChildrenCount(vmID, accessibleContext);
        }
        return FALSE;
    }

    /**
     * Gets the visible children of an AccessibleContext. Returns whether successful;
     *
     * Bug ID 4944762- getVisibleChildren for list-like components needed
     */
    BOOL getVisibleChildren(const long vmID, const AccessibleContext accessibleContext,
                            const int startIndex, VisibleChildrenInfo *visibleChildrenInfo) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getVisibleChildren(vmID, accessibleContext, startIndex,
                                                      visibleChildrenInfo);
        }
        return FALSE;
    }

    /**
     * Set the caret to a text position. Returns whether successful;
     *
     * Bug ID 4944770 - setCaretPosition method needed
     */
    BOOL setCaretPosition(const long vmID, const AccessibleContext accessibleContext,
                          const int position) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.setCaretPosition(vmID, accessibleContext, position);
        }
        return FALSE;
    }

    /**
     * Gets the text caret location
     */
    BOOL getCaretLocation(long vmID, AccessibleContext ac, AccessibleTextRectInfo *rectInfo, jint index) {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getCaretLocation(vmID, ac, rectInfo, index);
        }
        return FALSE;
    }

    /**
     * Gets the number of events waiting to fire
     */
    int getEventsWaiting() {
        if (theAccessBridgeInitializedFlag == TRUE) {
            return theAccessBridge.getEventsWaiting();
        }
        return FALSE;
    }

#ifdef __cplusplus
}
#endif

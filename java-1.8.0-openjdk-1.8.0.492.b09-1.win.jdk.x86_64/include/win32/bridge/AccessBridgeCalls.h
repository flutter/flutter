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
 * Wrapper functions around calls to the AccessBridge DLL
 */

#include <windows.h>
#include <jni.h>
#include "AccessBridgeCallbacks.h"
#include "AccessBridgePackages.h"

#ifdef __cplusplus
extern "C" {
#endif

#define null NULL

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


    typedef void (*Windows_runFP) ();

    typedef void (*SetPropertyChangeFP) (AccessBridge_PropertyChangeFP fp);

    typedef void (*SetJavaShutdownFP) (AccessBridge_JavaShutdownFP fp);
    typedef void (*SetFocusGainedFP) (AccessBridge_FocusGainedFP fp);
    typedef void (*SetFocusLostFP) (AccessBridge_FocusLostFP fp);

    typedef void (*SetCaretUpdateFP) (AccessBridge_CaretUpdateFP fp);

    typedef void (*SetMouseClickedFP) (AccessBridge_MouseClickedFP fp);
    typedef void (*SetMouseEnteredFP) (AccessBridge_MouseEnteredFP fp);
    typedef void (*SetMouseExitedFP) (AccessBridge_MouseExitedFP fp);
    typedef void (*SetMousePressedFP) (AccessBridge_MousePressedFP fp);
    typedef void (*SetMouseReleasedFP) (AccessBridge_MouseReleasedFP fp);

    typedef void (*SetMenuCanceledFP) (AccessBridge_MenuCanceledFP fp);
    typedef void (*SetMenuDeselectedFP) (AccessBridge_MenuDeselectedFP fp);
    typedef void (*SetMenuSelectedFP) (AccessBridge_MenuSelectedFP fp);
    typedef void (*SetPopupMenuCanceledFP) (AccessBridge_PopupMenuCanceledFP fp);
    typedef void (*SetPopupMenuWillBecomeInvisibleFP) (AccessBridge_PopupMenuWillBecomeInvisibleFP fp);
    typedef void (*SetPopupMenuWillBecomeVisibleFP) (AccessBridge_PopupMenuWillBecomeVisibleFP fp);

    typedef void (*SetPropertyNameChangeFP) (AccessBridge_PropertyNameChangeFP fp);
    typedef void (*SetPropertyDescriptionChangeFP) (AccessBridge_PropertyDescriptionChangeFP fp);
    typedef void (*SetPropertyStateChangeFP) (AccessBridge_PropertyStateChangeFP fp);
    typedef void (*SetPropertyValueChangeFP) (AccessBridge_PropertyValueChangeFP fp);
    typedef void (*SetPropertySelectionChangeFP) (AccessBridge_PropertySelectionChangeFP fp);
    typedef void (*SetPropertyTextChangeFP) (AccessBridge_PropertyTextChangeFP fp);
    typedef void (*SetPropertyCaretChangeFP) (AccessBridge_PropertyCaretChangeFP fp);
    typedef void (*SetPropertyVisibleDataChangeFP) (AccessBridge_PropertyVisibleDataChangeFP fp);
    typedef void (*SetPropertyChildChangeFP) (AccessBridge_PropertyChildChangeFP fp);
    typedef void (*SetPropertyActiveDescendentChangeFP) (AccessBridge_PropertyActiveDescendentChangeFP fp);

    typedef void (*SetPropertyTableModelChangeFP) (AccessBridge_PropertyTableModelChangeFP fp);

    typedef void (*ReleaseJavaObjectFP) (long vmID, Java_Object object);

    typedef BOOL (*GetVersionInfoFP) (long vmID, AccessBridgeVersionInfo *info);

    typedef BOOL (*IsJavaWindowFP) (HWND window);
    typedef BOOL (*IsSameObjectFP) (long vmID, JOBJECT64 obj1, JOBJECT64 obj2);
    typedef BOOL (*GetAccessibleContextFromHWNDFP) (HWND window, long *vmID, AccessibleContext *ac);
    typedef HWND (*getHWNDFromAccessibleContextFP) (long vmID, AccessibleContext ac);

    typedef BOOL (*GetAccessibleContextAtFP) (long vmID, AccessibleContext acParent,
                                              jint x, jint y, AccessibleContext *ac);
    typedef BOOL (*GetAccessibleContextWithFocusFP) (HWND window, long *vmID, AccessibleContext *ac);
    typedef BOOL (*GetAccessibleContextInfoFP) (long vmID, AccessibleContext ac, AccessibleContextInfo *info);
    typedef AccessibleContext (*GetAccessibleChildFromContextFP) (long vmID, AccessibleContext ac, jint i);
    typedef AccessibleContext (*GetAccessibleParentFromContextFP) (long vmID, AccessibleContext ac);

    /* begin AccessibleTable */
    typedef BOOL (*getAccessibleTableInfoFP) (long vmID, AccessibleContext ac, AccessibleTableInfo *tableInfo);
    typedef BOOL (*getAccessibleTableCellInfoFP) (long vmID, AccessibleTable accessibleTable,
                                                  jint row, jint column, AccessibleTableCellInfo *tableCellInfo);

    typedef BOOL (*getAccessibleTableRowHeaderFP) (long vmID, AccessibleContext acParent, AccessibleTableInfo *tableInfo);
    typedef BOOL (*getAccessibleTableColumnHeaderFP) (long vmID, AccessibleContext acParent, AccessibleTableInfo *tableInfo);

    typedef AccessibleContext (*getAccessibleTableRowDescriptionFP) (long vmID, AccessibleContext acParent, jint row);
    typedef AccessibleContext (*getAccessibleTableColumnDescriptionFP) (long vmID, AccessibleContext acParent, jint column);

    typedef jint (*getAccessibleTableRowSelectionCountFP) (long vmID, AccessibleTable table);
    typedef BOOL (*isAccessibleTableRowSelectedFP) (long vmID, AccessibleTable table, jint row);
    typedef BOOL (*getAccessibleTableRowSelectionsFP) (long vmID, AccessibleTable table, jint count,
                                                       jint *selections);

    typedef jint (*getAccessibleTableColumnSelectionCountFP) (long vmID, AccessibleTable table);
    typedef BOOL (*isAccessibleTableColumnSelectedFP) (long vmID, AccessibleTable table, jint column);
    typedef BOOL (*getAccessibleTableColumnSelectionsFP) (long vmID, AccessibleTable table, jint count,
                                                          jint *selections);

    typedef jint (*getAccessibleTableRowFP) (long vmID, AccessibleTable table, jint index);
    typedef jint (*getAccessibleTableColumnFP) (long vmID, AccessibleTable table, jint index);
    typedef jint (*getAccessibleTableIndexFP) (long vmID, AccessibleTable table, jint row, jint column);
    /* end AccessibleTable */

    /* AccessibleRelationSet */
    typedef BOOL (*getAccessibleRelationSetFP) (long vmID, AccessibleContext accessibleContext,
                                                AccessibleRelationSetInfo *relationSetInfo);

    /* AccessibleHypertext */
    typedef BOOL (*getAccessibleHypertextFP)(long vmID, AccessibleContext accessibleContext,
                                             AccessibleHypertextInfo *hypertextInfo);

    typedef BOOL (*activateAccessibleHyperlinkFP)(long vmID, AccessibleContext accessibleContext,
                                                  AccessibleHyperlink accessibleHyperlink);

    typedef jint (*getAccessibleHyperlinkCountFP)(const long vmID,
                                                      const AccessibleContext accessibleContext);

    typedef BOOL (*getAccessibleHypertextExtFP) (const long vmID,
                                                 const AccessibleContext accessibleContext,
                                                 const jint nStartIndex,
                                                 AccessibleHypertextInfo *hypertextInfo);

    typedef jint (*getAccessibleHypertextLinkIndexFP)(const long vmID,
                                                      const AccessibleHypertext hypertext,
                                                      const jint nIndex);

    typedef BOOL (*getAccessibleHyperlinkFP)(const long vmID,
                                             const AccessibleHypertext hypertext,
                                             const jint nIndex,
                                             AccessibleHyperlinkInfo *hyperlinkInfo);


    /* Accessible KeyBindings, Icons and Actions */
    typedef BOOL (*getAccessibleKeyBindingsFP)(long vmID, AccessibleContext accessibleContext,
                                               AccessibleKeyBindings *keyBindings);

    typedef BOOL (*getAccessibleIconsFP)(long vmID, AccessibleContext accessibleContext,
                                         AccessibleIcons *icons);

    typedef BOOL (*getAccessibleActionsFP)(long vmID, AccessibleContext accessibleContext,
                                           AccessibleActions *actions);

    typedef BOOL (*doAccessibleActionsFP)(long vmID, AccessibleContext accessibleContext,
                                          AccessibleActionsToDo *actionsToDo, jint *failure);


    /* AccessibleText */

    typedef BOOL (*GetAccessibleTextInfoFP) (long vmID, AccessibleText at, AccessibleTextInfo *textInfo, jint x, jint y);
    typedef BOOL (*GetAccessibleTextItemsFP) (long vmID, AccessibleText at, AccessibleTextItemsInfo *textItems, jint index);
    typedef BOOL (*GetAccessibleTextSelectionInfoFP) (long vmID, AccessibleText at, AccessibleTextSelectionInfo *textSelection);
    typedef BOOL (*GetAccessibleTextAttributesFP) (long vmID, AccessibleText at, jint index, AccessibleTextAttributesInfo *attributes);
    typedef BOOL (*GetAccessibleTextRectFP) (long vmID, AccessibleText at, AccessibleTextRectInfo *rectInfo, jint index);
    typedef BOOL (*GetAccessibleTextLineBoundsFP) (long vmID, AccessibleText at, jint index, jint *startIndex, jint *endIndex);
    typedef BOOL (*GetAccessibleTextRangeFP) (long vmID, AccessibleText at, jint start, jint end, wchar_t *text, short len);

    typedef BOOL (*GetCurrentAccessibleValueFromContextFP) (long vmID, AccessibleValue av, wchar_t *value, short len);
    typedef BOOL (*GetMaximumAccessibleValueFromContextFP) (long vmID, AccessibleValue av, wchar_t *value, short len);
    typedef BOOL (*GetMinimumAccessibleValueFromContextFP) (long vmID, AccessibleValue av, wchar_t *value, short len);

    typedef void (*AddAccessibleSelectionFromContextFP) (long vmID, AccessibleSelection as, int i);
    typedef void (*ClearAccessibleSelectionFromContextFP) (long vmID, AccessibleSelection as);
    typedef JOBJECT64 (*GetAccessibleSelectionFromContextFP) (long vmID, AccessibleSelection as, int i);
    typedef int (*GetAccessibleSelectionCountFromContextFP) (long vmID, AccessibleSelection as);
    typedef BOOL (*IsAccessibleChildSelectedFromContextFP) (long vmID, AccessibleSelection as, int i);
    typedef void (*RemoveAccessibleSelectionFromContextFP) (long vmID, AccessibleSelection as, int i);
    typedef void (*SelectAllAccessibleSelectionFromContextFP) (long vmID, AccessibleSelection as);

    /* Utility methods */

    typedef BOOL (*setTextContentsFP) (const long vmID, const AccessibleContext ac, const wchar_t *text);
    typedef AccessibleContext (*getParentWithRoleFP) (const long vmID, const AccessibleContext ac, const wchar_t *role);
    typedef AccessibleContext (*getParentWithRoleElseRootFP) (const long vmID, const AccessibleContext ac, const wchar_t *role);
    typedef AccessibleContext (*getTopLevelObjectFP) (const long vmID, const AccessibleContext ac);
    typedef int (*getObjectDepthFP) (const long vmID, const AccessibleContext ac);
    typedef AccessibleContext (*getActiveDescendentFP) (const long vmID, const AccessibleContext ac);


    typedef BOOL (*getVirtualAccessibleNameFP) (const long vmID, const AccessibleContext accessibleContext,
                                             wchar_t *name, int len);

    typedef BOOL (*requestFocusFP) (const long vmID, const AccessibleContext accessibleContext);

    typedef BOOL (*selectTextRangeFP) (const long vmID, const AccessibleContext accessibleContext,
                                       const int startIndex, const int endIndex);

    typedef BOOL (*getTextAttributesInRangeFP) (const long vmID, const AccessibleContext accessibleContext,
                                                const int startIndex, const int endIndex,
                                                AccessibleTextAttributesInfo *attributes, short *len);

    typedef int (*getVisibleChildrenCountFP) (const long vmID, const AccessibleContext accessibleContext);

    typedef BOOL (*getVisibleChildrenFP) (const long vmID, const AccessibleContext accessibleContext,
                                          const int startIndex, VisibleChildrenInfo *children);

    typedef BOOL (*setCaretPositionFP) (const long vmID, const AccessibleContext accessibleContext, const int position);

    typedef BOOL (*getCaretLocationFP) (long vmID, AccessibleContext ac, AccessibleTextRectInfo *rectInfo, jint index);

    typedef int (*getEventsWaitingFP) ();

    typedef struct AccessBridgeFPsTag {
        Windows_runFP Windows_run;

        SetPropertyChangeFP SetPropertyChange;

        SetJavaShutdownFP SetJavaShutdown;
        SetFocusGainedFP SetFocusGained;
        SetFocusLostFP SetFocusLost;

        SetCaretUpdateFP SetCaretUpdate;

        SetMouseClickedFP SetMouseClicked;
        SetMouseEnteredFP SetMouseEntered;
        SetMouseExitedFP SetMouseExited;
        SetMousePressedFP SetMousePressed;
        SetMouseReleasedFP SetMouseReleased;

        SetMenuCanceledFP SetMenuCanceled;
        SetMenuDeselectedFP SetMenuDeselected;
        SetMenuSelectedFP SetMenuSelected;
        SetPopupMenuCanceledFP SetPopupMenuCanceled;
        SetPopupMenuWillBecomeInvisibleFP SetPopupMenuWillBecomeInvisible;
        SetPopupMenuWillBecomeVisibleFP SetPopupMenuWillBecomeVisible;

        SetPropertyNameChangeFP SetPropertyNameChange;
        SetPropertyDescriptionChangeFP SetPropertyDescriptionChange;
        SetPropertyStateChangeFP SetPropertyStateChange;
        SetPropertyValueChangeFP SetPropertyValueChange;
        SetPropertySelectionChangeFP SetPropertySelectionChange;
        SetPropertyTextChangeFP SetPropertyTextChange;
        SetPropertyCaretChangeFP SetPropertyCaretChange;
        SetPropertyVisibleDataChangeFP SetPropertyVisibleDataChange;
        SetPropertyChildChangeFP SetPropertyChildChange;
        SetPropertyActiveDescendentChangeFP SetPropertyActiveDescendentChange;

        SetPropertyTableModelChangeFP SetPropertyTableModelChange;

        ReleaseJavaObjectFP ReleaseJavaObject;
        GetVersionInfoFP GetVersionInfo;

        IsJavaWindowFP IsJavaWindow;
        IsSameObjectFP IsSameObject;
        GetAccessibleContextFromHWNDFP GetAccessibleContextFromHWND;
        getHWNDFromAccessibleContextFP getHWNDFromAccessibleContext;

        GetAccessibleContextAtFP GetAccessibleContextAt;
        GetAccessibleContextWithFocusFP GetAccessibleContextWithFocus;
        GetAccessibleContextInfoFP GetAccessibleContextInfo;
        GetAccessibleChildFromContextFP GetAccessibleChildFromContext;
        GetAccessibleParentFromContextFP GetAccessibleParentFromContext;

        getAccessibleTableInfoFP getAccessibleTableInfo;
        getAccessibleTableCellInfoFP getAccessibleTableCellInfo;

        getAccessibleTableRowHeaderFP getAccessibleTableRowHeader;
        getAccessibleTableColumnHeaderFP getAccessibleTableColumnHeader;

        getAccessibleTableRowDescriptionFP getAccessibleTableRowDescription;
        getAccessibleTableColumnDescriptionFP getAccessibleTableColumnDescription;

        getAccessibleTableRowSelectionCountFP getAccessibleTableRowSelectionCount;
        isAccessibleTableRowSelectedFP isAccessibleTableRowSelected;
        getAccessibleTableRowSelectionsFP getAccessibleTableRowSelections;

        getAccessibleTableColumnSelectionCountFP getAccessibleTableColumnSelectionCount;
        isAccessibleTableColumnSelectedFP isAccessibleTableColumnSelected;
        getAccessibleTableColumnSelectionsFP getAccessibleTableColumnSelections;

        getAccessibleTableRowFP getAccessibleTableRow;
        getAccessibleTableColumnFP getAccessibleTableColumn;
        getAccessibleTableIndexFP getAccessibleTableIndex;

        getAccessibleRelationSetFP getAccessibleRelationSet;

        getAccessibleHypertextFP getAccessibleHypertext;
        activateAccessibleHyperlinkFP activateAccessibleHyperlink;
        getAccessibleHyperlinkCountFP getAccessibleHyperlinkCount;
        getAccessibleHypertextExtFP getAccessibleHypertextExt;
        getAccessibleHypertextLinkIndexFP getAccessibleHypertextLinkIndex;
        getAccessibleHyperlinkFP getAccessibleHyperlink;

        getAccessibleKeyBindingsFP getAccessibleKeyBindings;
        getAccessibleIconsFP getAccessibleIcons;
        getAccessibleActionsFP getAccessibleActions;
        doAccessibleActionsFP doAccessibleActions;

        GetAccessibleTextInfoFP GetAccessibleTextInfo;
        GetAccessibleTextItemsFP GetAccessibleTextItems;
        GetAccessibleTextSelectionInfoFP GetAccessibleTextSelectionInfo;
        GetAccessibleTextAttributesFP GetAccessibleTextAttributes;
        GetAccessibleTextRectFP GetAccessibleTextRect;
        GetAccessibleTextLineBoundsFP GetAccessibleTextLineBounds;
        GetAccessibleTextRangeFP GetAccessibleTextRange;

        GetCurrentAccessibleValueFromContextFP GetCurrentAccessibleValueFromContext;
        GetMaximumAccessibleValueFromContextFP GetMaximumAccessibleValueFromContext;
        GetMinimumAccessibleValueFromContextFP GetMinimumAccessibleValueFromContext;

        AddAccessibleSelectionFromContextFP AddAccessibleSelectionFromContext;
        ClearAccessibleSelectionFromContextFP ClearAccessibleSelectionFromContext;
        GetAccessibleSelectionFromContextFP GetAccessibleSelectionFromContext;
        GetAccessibleSelectionCountFromContextFP GetAccessibleSelectionCountFromContext;
        IsAccessibleChildSelectedFromContextFP IsAccessibleChildSelectedFromContext;
        RemoveAccessibleSelectionFromContextFP RemoveAccessibleSelectionFromContext;
        SelectAllAccessibleSelectionFromContextFP SelectAllAccessibleSelectionFromContext;

        setTextContentsFP setTextContents;
        getParentWithRoleFP getParentWithRole;
        getTopLevelObjectFP getTopLevelObject;
        getParentWithRoleElseRootFP getParentWithRoleElseRoot;
        getObjectDepthFP getObjectDepth;
        getActiveDescendentFP getActiveDescendent;

        getVirtualAccessibleNameFP getVirtualAccessibleName;
        requestFocusFP requestFocus;
        selectTextRangeFP selectTextRange;
        getTextAttributesInRangeFP getTextAttributesInRange;
        getVisibleChildrenCountFP getVisibleChildrenCount;
        getVisibleChildrenFP getVisibleChildren;
        setCaretPositionFP setCaretPosition;
        getCaretLocationFP getCaretLocation;

        getEventsWaitingFP getEventsWaiting;

    } AccessBridgeFPs;


    /**
     * Initialize the world
     */
    BOOL initializeAccessBridge();
    BOOL shutdownAccessBridge();

    /**
     * Window routines
     */
    BOOL IsJavaWindow(HWND window);

    // Returns the virtual machine ID and AccessibleContext for a top-level window
    BOOL GetAccessibleContextFromHWND(HWND target, long *vmID, AccessibleContext *ac);

    // Returns the HWND from the AccessibleContext of a top-level window
    HWND getHWNDFromAccessibleContext(long vmID, AccessibleContext ac);


    /**
     * Event handling routines
     */
    void SetJavaShutdown(AccessBridge_JavaShutdownFP fp);
    void SetFocusGained(AccessBridge_FocusGainedFP fp);
    void SetFocusLost(AccessBridge_FocusLostFP fp);

    void SetCaretUpdate(AccessBridge_CaretUpdateFP fp);

    void SetMouseClicked(AccessBridge_MouseClickedFP fp);
    void SetMouseEntered(AccessBridge_MouseEnteredFP fp);
    void SetMouseExited(AccessBridge_MouseExitedFP fp);
    void SetMousePressed(AccessBridge_MousePressedFP fp);
    void SetMouseReleased(AccessBridge_MouseReleasedFP fp);

    void SetMenuCanceled(AccessBridge_MenuCanceledFP fp);
    void SetMenuDeselected(AccessBridge_MenuDeselectedFP fp);
    void SetMenuSelected(AccessBridge_MenuSelectedFP fp);
    void SetPopupMenuCanceled(AccessBridge_PopupMenuCanceledFP fp);
    void SetPopupMenuWillBecomeInvisible(AccessBridge_PopupMenuWillBecomeInvisibleFP fp);
    void SetPopupMenuWillBecomeVisible(AccessBridge_PopupMenuWillBecomeVisibleFP fp);

    void SetPropertyNameChange(AccessBridge_PropertyNameChangeFP fp);
    void SetPropertyDescriptionChange(AccessBridge_PropertyDescriptionChangeFP fp);
    void SetPropertyStateChange(AccessBridge_PropertyStateChangeFP fp);
    void SetPropertyValueChange(AccessBridge_PropertyValueChangeFP fp);
    void SetPropertySelectionChange(AccessBridge_PropertySelectionChangeFP fp);
    void SetPropertyTextChange(AccessBridge_PropertyTextChangeFP fp);
    void SetPropertyCaretChange(AccessBridge_PropertyCaretChangeFP fp);
    void SetPropertyVisibleDataChange(AccessBridge_PropertyVisibleDataChangeFP fp);
    void SetPropertyChildChange(AccessBridge_PropertyChildChangeFP fp);
    void SetPropertyActiveDescendentChange(AccessBridge_PropertyActiveDescendentChangeFP fp);

    void SetPropertyTableModelChange(AccessBridge_PropertyTableModelChangeFP fp);


    /**
     * General routines
     */
    void ReleaseJavaObject(long vmID, Java_Object object);
    BOOL GetVersionInfo(long vmID, AccessBridgeVersionInfo *info);
    HWND GetHWNDFromAccessibleContext(long vmID, JOBJECT64 accesibleContext);

    /**
     * Accessible Context routines
     */
    BOOL GetAccessibleContextAt(long vmID, AccessibleContext acParent,
                                jint x, jint y, AccessibleContext *ac);
    BOOL GetAccessibleContextWithFocus(HWND window, long *vmID, AccessibleContext *ac);
    BOOL GetAccessibleContextInfo(long vmID, AccessibleContext ac, AccessibleContextInfo *info);
    AccessibleContext GetAccessibleChildFromContext(long vmID, AccessibleContext ac, jint index);
    AccessibleContext GetAccessibleParentFromContext(long vmID, AccessibleContext ac);

    /**
     * Accessible Text routines
     */
    BOOL GetAccessibleTextInfo(long vmID, AccessibleText at, AccessibleTextInfo *textInfo, jint x, jint y);
    BOOL GetAccessibleTextItems(long vmID, AccessibleText at, AccessibleTextItemsInfo *textItems, jint index);
    BOOL GetAccessibleTextSelectionInfo(long vmID, AccessibleText at, AccessibleTextSelectionInfo *textSelection);
    BOOL GetAccessibleTextAttributes(long vmID, AccessibleText at, jint index, AccessibleTextAttributesInfo *attributes);
    BOOL GetAccessibleTextRect(long vmID, AccessibleText at, AccessibleTextRectInfo *rectInfo, jint index);
    BOOL GetAccessibleTextLineBounds(long vmID, AccessibleText at, jint index, jint *startIndex, jint *endIndex);
    BOOL GetAccessibleTextRange(long vmID, AccessibleText at, jint start, jint end, wchar_t *text, short len);

    /* begin AccessibleTable routines */
    BOOL getAccessibleTableInfo(long vmID, AccessibleContext acParent, AccessibleTableInfo *tableInfo);

    BOOL getAccessibleTableCellInfo(long vmID, AccessibleTable accessibleTable, jint row, jint column,
                                    AccessibleTableCellInfo *tableCellInfo);

    BOOL getAccessibleTableRowHeader(long vmID, AccessibleContext acParent, AccessibleTableInfo *tableInfo);
    BOOL getAccessibleTableColumnHeader(long vmID, AccessibleContext acParent, AccessibleTableInfo *tableInfo);

    AccessibleContext getAccessibleTableRowDescription(long vmID, AccessibleContext acParent, jint row);
    AccessibleContext getAccessibleTableColumnDescription(long vmID, AccessibleContext acParent, jint column);

    jint getAccessibleTableRowSelectionCount(long vmID, AccessibleTable table);
    BOOL isAccessibleTableRowSelected(long vmID, AccessibleTable table, jint row);
    BOOL getAccessibleTableRowSelections(long vmID, AccessibleTable table, jint count, jint *selections);

    jint getAccessibleTableColumnSelectionCount(long vmID, AccessibleTable table);
    BOOL isAccessibleTableColumnSelected(long vmID, AccessibleTable table, jint column);
    BOOL getAccessibleTableColumnSelections(long vmID, AccessibleTable table, jint count, jint *selections);

    jint getAccessibleTableRow(long vmID, AccessibleTable table, jint index);
    jint getAccessibleTableColumn(long vmID, AccessibleTable table, jint index);
    jint getAccessibleTableIndex(long vmID, AccessibleTable table, jint row, jint column);
    /* end AccessibleTable */

    /* ----- AccessibleRelationSet routines */
    BOOL getAccessibleRelationSet(long vmID, AccessibleContext accessibleContext,
                                  AccessibleRelationSetInfo *relationSetInfo);

    /* ----- AccessibleHypertext routines */

     /*
     * Returns hypertext information associated with a component.
     */
    BOOL getAccessibleHypertext(long vmID, AccessibleContext accessibleContext,
                                AccessibleHypertextInfo *hypertextInfo);

    /*
     * Requests that a hyperlink be activated.
     */
    BOOL activateAccessibleHyperlink(long vmID, AccessibleContext accessibleContext,
                                     AccessibleHyperlink accessibleHyperlink);

    /*
     * Returns the number of hyperlinks in a component
     * Maps to AccessibleHypertext.getLinkCount.
     * Returns -1 on error.
     */
    jint getAccessibleHyperlinkCount(const long vmID,
                                         const AccessibleHypertext hypertext);

    /*
     * This method is used to iterate through the hyperlinks in a component.  It
     * returns hypertext information for a component starting at hyperlink index
     * nStartIndex.  No more than MAX_HYPERLINKS AccessibleHypertextInfo objects will
     * be returned for each call to this method.
     * Returns FALSE on error.
     */
    BOOL getAccessibleHypertextExt(const long vmID,
                                   const AccessibleContext accessibleContext,
                                   const jint nStartIndex,
                                   /* OUT */ AccessibleHypertextInfo *hypertextInfo);

    /*
     * Returns the index into an array of hyperlinks that is associated with
     * a character index in document; maps to AccessibleHypertext.getLinkIndex
     * Returns -1 on error.
     */
    jint getAccessibleHypertextLinkIndex(const long vmID,
                                         const AccessibleHypertext hypertext,
                                         const jint nIndex);

    /*
     * Returns the nth hyperlink in a document
     * Maps to AccessibleHypertext.getLink.
     * Returns FALSE on error
     */
    BOOL getAccessibleHyperlink(const long vmID,
                                const AccessibleHypertext hypertext,
                                const jint nIndex,
                                /* OUT */ AccessibleHyperlinkInfo *hyperlinkInfo);

    /* Accessible KeyBindings, Icons and Actions */

    /*
     * Returns a list of key bindings associated with a component.
     */
    BOOL getAccessibleKeyBindings(long vmID, AccessibleContext accessibleContext,
                                  AccessibleKeyBindings *keyBindings);

    /*
     * Returns a list of icons associate with a component.
     */
    BOOL getAccessibleIcons(long vmID, AccessibleContext accessibleContext,
                            AccessibleIcons *icons);

    /*
     * Returns a list of actions that a component can perform.
     */
    BOOL getAccessibleActions(long vmID, AccessibleContext accessibleContext,
                              AccessibleActions *actions);

    /*
     * Request that a list of AccessibleActions be performed by a component.
     * Returns TRUE if all actions are performed.  Returns FALSE
     * when the first requested action fails in which case "failure"
     * contains the index of the action that failed.
     */
    BOOL doAccessibleActions(long vmID, AccessibleContext accessibleContext,
                             AccessibleActionsToDo *actionsToDo, jint *failure);



    /* Additional utility methods */

    /*
     * Returns whether two object references refer to the same object.
     */
    BOOL IsSameObject(long vmID, JOBJECT64 obj1, JOBJECT64 obj2);

    /**
     * Sets editable text contents.  The AccessibleContext must implement AccessibleEditableText and
     *   be editable.  The maximum text length that can be set is MAX_STRING_SIZE - 1.
     * Returns whether successful
     */
    BOOL setTextContents (const long vmID, const AccessibleContext accessibleContext, const wchar_t *text);

    /**
     * Returns the Accessible Context with the specified role that is the
     * ancestor of a given object. The role is one of the role strings
     * defined in AccessBridgePackages.h
     * If there is no ancestor object that has the specified role,
     * returns (AccessibleContext)0.
     */
    AccessibleContext getParentWithRole (const long vmID, const AccessibleContext accessibleContext,
                                         const wchar_t *role);

    /**
     * Returns the Accessible Context with the specified role that is the
     * ancestor of a given object. The role is one of the role strings
     * defined in AccessBridgePackages.h.  If an object with the specified
     * role does not exist, returns the top level object for the Java Window.
     * Returns (AccessibleContext)0 on error.
     */
    AccessibleContext getParentWithRoleElseRoot (const long vmID, const AccessibleContext accessibleContext,
                                                 const wchar_t *role);

    /**
     * Returns the Accessible Context for the top level object in
     * a Java Window.  This is same Accessible Context that is obtained
     * from GetAccessibleContextFromHWND for that window.  Returns
     * (AccessibleContext)0 on error.
     */
    AccessibleContext getTopLevelObject (const long vmID, const AccessibleContext accessibleContext);

    /**
     * Returns how deep in the object hierarchy a given object is.
     * The top most object in the object hierarchy has an object depth of 0.
     * Returns -1 on error.
     */
    int getObjectDepth (const long vmID, const AccessibleContext accessibleContext);

    /**
     * Returns the Accessible Context of the current ActiveDescendent of an object.
     * This method assumes the ActiveDescendent is the component that is currently
     * selected in a container object.
     * Returns (AccessibleContext)0 on error or if there is no selection.
     */
    AccessibleContext getActiveDescendent (const long vmID, const AccessibleContext accessibleContext);

    /**
       /**
       * Accessible Value routines
       */
    BOOL GetCurrentAccessibleValueFromContext(long vmID, AccessibleValue av, wchar_t *value, short len);
    BOOL GetMaximumAccessibleValueFromContext(long vmID, AccessibleValue av, wchar_t *value, short len);
    BOOL GetMinimumAccessibleValueFromContext(long vmID, AccessibleValue av, wchar_t *value, short len);

    /**
     * Accessible Selection routines
     */
    void AddAccessibleSelectionFromContext(long vmID, AccessibleSelection as, int i);
    void ClearAccessibleSelectionFromContext(long vmID, AccessibleSelection as);
    JOBJECT64 GetAccessibleSelectionFromContext(long vmID, AccessibleSelection as, int i);
    int GetAccessibleSelectionCountFromContext(long vmID, AccessibleSelection as);
    BOOL IsAccessibleChildSelectedFromContext(long vmID, AccessibleSelection as, int i);
    void RemoveAccessibleSelectionFromContext(long vmID, AccessibleSelection as, int i);
    void SelectAllAccessibleSelectionFromContext(long vmID, AccessibleSelection as);

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
                               wchar_t *name, int len);

    /**
     * Request focus for a component. Returns whether successful.
     *
     * Bug ID 4944757 - requestFocus method needed
     */
    BOOL requestFocus(const long vmID, const AccessibleContext accessibleContext);

    /**
     * Selects text between two indices.  Selection includes the text at the start index
     * and the text at the end index. Returns whether successful.
     *
     * Bug ID 4944758 - selectTextRange method needed
     */
    BOOL selectTextRange(const long vmID, const AccessibleContext accessibleContext, const int startIndex,
                         const int endIndex);

    /**
     * Get text attributes between two indices.  The attribute list includes the text at the
     * start index and the text at the end index. Returns whether successful;
     *
     * Bug ID 4944761 - getTextAttributes between two indices method needed
     */
    BOOL getTextAttributesInRange(const long vmID, const AccessibleContext accessibleContext,
                                  const int startIndex, const int endIndex,
                                  AccessibleTextAttributesInfo *attributes, short *len);

    /**
     * Returns the number of visible children of a component. Returns -1 on error.
     *
     * Bug ID 4944762- getVisibleChildren for list-like components needed
     */
    int getVisibleChildrenCount(const long vmID, const AccessibleContext accessibleContext);

    /**
     * Gets the visible children of an AccessibleContext. Returns whether successful.
     *
     * Bug ID 4944762- getVisibleChildren for list-like components needed
     */
    BOOL getVisibleChildren(const long vmID, const AccessibleContext accessibleContext,
                            const int startIndex,
                            VisibleChildrenInfo *visibleChildrenInfo);

    /**
     * Set the caret to a text position. Returns whether successful.
     *
     * Bug ID 4944770 - setCaretPosition method needed
     */
    BOOL setCaretPosition(const long vmID, const AccessibleContext accessibleContext,
                          const int position);

    /**
     * Gets the text caret location
     */
    BOOL getCaretLocation(long vmID, AccessibleContext ac,
                          AccessibleTextRectInfo *rectInfo, jint index);

    /**
     * Gets the number of events waiting to fire
     */
    int getEventsWaiting();

#ifdef __cplusplus
}
#endif

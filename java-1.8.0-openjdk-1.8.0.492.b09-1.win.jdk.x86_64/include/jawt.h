/*
 * Copyright (c) 1999, 2013, Oracle and/or its affiliates. All rights reserved.
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

#ifndef _JAVASOFT_JAWT_H_
#define _JAVASOFT_JAWT_H_

#include "jni.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * AWT native interface (new in JDK 1.3)
 *
 * The AWT native interface allows a native C or C++ application a means
 * by which to access native structures in AWT.  This is to facilitate moving
 * legacy C and C++ applications to Java and to target the needs of the
 * community who, at present, wish to do their own native rendering to canvases
 * for performance reasons.  Standard extensions such as Java3D also require a
 * means to access the underlying native data structures of AWT.
 *
 * There may be future extensions to this API depending on demand.
 *
 * A VM does not have to implement this API in order to pass the JCK.
 * It is recommended, however, that this API is implemented on VMs that support
 * standard extensions, such as Java3D.
 *
 * Since this is a native API, any program which uses it cannot be considered
 * 100% pure java.
 */

/*
 * AWT Native Drawing Surface (JAWT_DrawingSurface).
 *
 * For each platform, there is a native drawing surface structure.  This
 * platform-specific structure can be found in jawt_md.h.  It is recommended
 * that additional platforms follow the same model.  It is also recommended
 * that VMs on Win32 and Solaris support the existing structures in jawt_md.h.
 *
 *******************
 * EXAMPLE OF USAGE:
 *******************
 *
 * In Win32, a programmer wishes to access the HWND of a canvas to perform
 * native rendering into it.  The programmer has declared the paint() method
 * for their canvas subclass to be native:
 *
 *
 * MyCanvas.java:
 *
 * import java.awt.*;
 *
 * public class MyCanvas extends Canvas {
 *
 *     static {
 *         System.loadLibrary("mylib");
 *     }
 *
 *     public native void paint(Graphics g);
 * }
 *
 *
 * myfile.c:
 *
 * #include "jawt_md.h"
 * #include <assert.h>
 *
 * JNIEXPORT void JNICALL
 * Java_MyCanvas_paint(JNIEnv* env, jobject canvas, jobject graphics)
 * {
 *     JAWT awt;
 *     JAWT_DrawingSurface* ds;
 *     JAWT_DrawingSurfaceInfo* dsi;
 *     JAWT_Win32DrawingSurfaceInfo* dsi_win;
 *     jboolean result;
 *     jint lock;
 *
 *     // Get the AWT
 *     awt.version = JAWT_VERSION_1_3;
 *     result = JAWT_GetAWT(env, &awt);
 *     assert(result != JNI_FALSE);
 *
 *     // Get the drawing surface
 *     ds = awt.GetDrawingSurface(env, canvas);
 *     assert(ds != NULL);
 *
 *     // Lock the drawing surface
 *     lock = ds->Lock(ds);
 *     assert((lock & JAWT_LOCK_ERROR) == 0);
 *
 *     // Get the drawing surface info
 *     dsi = ds->GetDrawingSurfaceInfo(ds);
 *
 *     // Get the platform-specific drawing info
 *     dsi_win = (JAWT_Win32DrawingSurfaceInfo*)dsi->platformInfo;
 *
 *     //////////////////////////////
 *     // !!! DO PAINTING HERE !!! //
 *     //////////////////////////////
 *
 *     // Free the drawing surface info
 *     ds->FreeDrawingSurfaceInfo(dsi);
 *
 *     // Unlock the drawing surface
 *     ds->Unlock(ds);
 *
 *     // Free the drawing surface
 *     awt.FreeDrawingSurface(ds);
 * }
 *
 */

/*
 * JAWT_Rectangle
 * Structure for a native rectangle.
 */
typedef struct jawt_Rectangle {
    jint x;
    jint y;
    jint width;
    jint height;
} JAWT_Rectangle;

struct jawt_DrawingSurface;

/*
 * JAWT_DrawingSurfaceInfo
 * Structure for containing the underlying drawing information of a component.
 */
typedef struct jawt_DrawingSurfaceInfo {
    /*
     * Pointer to the platform-specific information.  This can be safely
     * cast to a JAWT_Win32DrawingSurfaceInfo on Windows or a
     * JAWT_X11DrawingSurfaceInfo on Solaris. On Mac OS X this is a
     * pointer to a NSObject that conforms to the JAWT_SurfaceLayers
     * protocol. See jawt_md.h for details.
     */
    void* platformInfo;
    /* Cached pointer to the underlying drawing surface */
    struct jawt_DrawingSurface* ds;
    /* Bounding rectangle of the drawing surface */
    JAWT_Rectangle bounds;
    /* Number of rectangles in the clip */
    jint clipSize;
    /* Clip rectangle array */
    JAWT_Rectangle* clip;
} JAWT_DrawingSurfaceInfo;

#define JAWT_LOCK_ERROR                 0x00000001
#define JAWT_LOCK_CLIP_CHANGED          0x00000002
#define JAWT_LOCK_BOUNDS_CHANGED        0x00000004
#define JAWT_LOCK_SURFACE_CHANGED       0x00000008

/*
 * JAWT_DrawingSurface
 * Structure for containing the underlying drawing information of a component.
 * All operations on a JAWT_DrawingSurface MUST be performed from the same
 * thread as the call to GetDrawingSurface.
 */
typedef struct jawt_DrawingSurface {
    /*
     * Cached reference to the Java environment of the calling thread.
     * If Lock(), Unlock(), GetDrawingSurfaceInfo() or
     * FreeDrawingSurfaceInfo() are called from a different thread,
     * this data member should be set before calling those functions.
     */
    JNIEnv* env;
    /* Cached reference to the target object */
    jobject target;
    /*
     * Lock the surface of the target component for native rendering.
     * When finished drawing, the surface must be unlocked with
     * Unlock().  This function returns a bitmask with one or more of the
     * following values:
     *
     * JAWT_LOCK_ERROR - When an error has occurred and the surface could not
     * be locked.
     *
     * JAWT_LOCK_CLIP_CHANGED - When the clip region has changed.
     *
     * JAWT_LOCK_BOUNDS_CHANGED - When the bounds of the surface have changed.
     *
     * JAWT_LOCK_SURFACE_CHANGED - When the surface itself has changed
     */
    jint (JNICALL *Lock)
        (struct jawt_DrawingSurface* ds);
    /*
     * Get the drawing surface info.
     * The value returned may be cached, but the values may change if
     * additional calls to Lock() or Unlock() are made.
     * Lock() must be called before this can return a valid value.
     * Returns NULL if an error has occurred.
     * When finished with the returned value, FreeDrawingSurfaceInfo must be
     * called.
     */
    JAWT_DrawingSurfaceInfo* (JNICALL *GetDrawingSurfaceInfo)
        (struct jawt_DrawingSurface* ds);
    /*
     * Free the drawing surface info.
     */
    void (JNICALL *FreeDrawingSurfaceInfo)
        (JAWT_DrawingSurfaceInfo* dsi);
    /*
     * Unlock the drawing surface of the target component for native rendering.
     */
    void (JNICALL *Unlock)
        (struct jawt_DrawingSurface* ds);
} JAWT_DrawingSurface;

/*
 * JAWT
 * Structure for containing native AWT functions.
 */
typedef struct jawt {
    /*
     * Version of this structure.  This must always be set before
     * calling JAWT_GetAWT()
     */
    jint version;
    /*
     * Return a drawing surface from a target jobject.  This value
     * may be cached.
     * Returns NULL if an error has occurred.
     * Target must be a java.awt.Component (should be a Canvas
     * or Window for native rendering).
     * FreeDrawingSurface() must be called when finished with the
     * returned JAWT_DrawingSurface.
     */
    JAWT_DrawingSurface* (JNICALL *GetDrawingSurface)
        (JNIEnv* env, jobject target);
    /*
     * Free the drawing surface allocated in GetDrawingSurface.
     */
    void (JNICALL *FreeDrawingSurface)
        (JAWT_DrawingSurface* ds);
    /*
     * Since 1.4
     * Locks the entire AWT for synchronization purposes
     */
    void (JNICALL *Lock)(JNIEnv* env);
    /*
     * Since 1.4
     * Unlocks the entire AWT for synchronization purposes
     */
    void (JNICALL *Unlock)(JNIEnv* env);
    /*
     * Since 1.4
     * Returns a reference to a java.awt.Component from a native
     * platform handle.  On Windows, this corresponds to an HWND;
     * on Solaris and Linux, this is a Drawable.  For other platforms,
     * see the appropriate machine-dependent header file for a description.
     * The reference returned by this function is a local
     * reference that is only valid in this environment.
     * This function returns a NULL reference if no component could be
     * found with matching platform information.
     */
    jobject (JNICALL *GetComponent)(JNIEnv* env, void* platformInfo);

} JAWT;

/*
 * Get the AWT native structure.  This function returns JNI_FALSE if
 * an error occurs.
 */
_JNI_IMPORT_OR_EXPORT_
jboolean JNICALL JAWT_GetAWT(JNIEnv* env, JAWT* awt);

#define JAWT_VERSION_1_3 0x00010003
#define JAWT_VERSION_1_4 0x00010004
#define JAWT_VERSION_1_7 0x00010007

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* !_JAVASOFT_JAWT_H_ */

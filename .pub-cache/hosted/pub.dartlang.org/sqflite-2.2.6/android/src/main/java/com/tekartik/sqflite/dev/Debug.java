package com.tekartik.sqflite.dev;

import static android.content.ContentValues.TAG;

import android.util.Log;

/**
 * Created by alex on 09/01/18.
 */

public class Debug {

    // Log flags
    public static boolean LOGV = false;
    public static boolean _EXTRA_LOGV = false; // to set to true for type debugging
    // public static boolean _EXTRA_LOGV = true; // to set to true for type debugging
    static public boolean EXTRA_LOGV = false; // to set to true for type debugging

    // Deprecated to prevent usage
    @Deprecated
    public static void devLog(String tag, String message) {
        Log.d(TAG, message);
    }
}

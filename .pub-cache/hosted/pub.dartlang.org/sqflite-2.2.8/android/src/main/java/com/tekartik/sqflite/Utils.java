package com.tekartik.sqflite;

import static com.tekartik.sqflite.Constant.TAG;

import android.database.Cursor;
import android.os.Build;
import android.util.Log;

import androidx.annotation.RequiresApi;

import com.tekartik.sqflite.dev.Debug;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class Utils {

    static public List<Object> cursorRowToList(Cursor cursor, int length) {
        List<Object> list = new ArrayList<>(length);

        for (int i = 0; i < length; i++) {
            Object value = cursorValue(cursor, i);
            if (Debug.EXTRA_LOGV) {
                String type = null;
                if (value != null) {
                    if (value.getClass().isArray()) {
                        type = "array(" + value.getClass().getComponentType().getName() + ")";
                    } else {
                        type = value.getClass().getName();
                    }
                }
                Log.d(TAG, "column " + i + " " + cursor.getType(i) + ": " + value + (type == null ? "" : " (" + type + ")"));
            }
            list.add(value);
        }
        return list;
    }

    static public Object cursorValue(Cursor cursor, int index) {
        switch (cursor.getType(index)) {
            case Cursor.FIELD_TYPE_NULL:
                return null;
            case Cursor.FIELD_TYPE_INTEGER:
                return cursor.getLong(index);
            case Cursor.FIELD_TYPE_FLOAT:
                return cursor.getDouble(index);
            case Cursor.FIELD_TYPE_STRING:
                return cursor.getString(index);
            case Cursor.FIELD_TYPE_BLOB:
                return cursor.getBlob(index);
        }
        return null;
    }

    static Locale localeForLanguateTag(String localeString) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            return localeForLanguageTag21(localeString);
        } else {
            return localeForLanguageTagPre21(localeString);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    static Locale localeForLanguageTag21(String localeString) {
        return Locale.forLanguageTag(localeString);
    }

    /**
     * Really basic implementation, hopefully not so many dev/apps with such requirements
     * should be impacted.
     *
     * @param localeString
     * @return
     */
    static Locale localeForLanguageTagPre21(String localeString) {
        //Locale.Builder builder = new Locale().Builder();
        String[] parts = localeString.split("-");
        String language = "";
        String country = "";
        String variant = "";
        if (parts.length > 0) {
            language = parts[0];
            if (parts.length > 1) {
                country = parts[1];

                if (parts.length > 2) {
                    variant = parts[parts.length - 1];
                }
            }
        }
        return new Locale(language, country, variant);
    }
}

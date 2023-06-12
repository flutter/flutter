package com.tekartik.sqflite;

import static com.tekartik.sqflite.Constant.TAG;

import android.database.Cursor;
import android.util.Log;

import com.tekartik.sqflite.dev.Debug;

import java.util.ArrayList;
import java.util.List;

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
}

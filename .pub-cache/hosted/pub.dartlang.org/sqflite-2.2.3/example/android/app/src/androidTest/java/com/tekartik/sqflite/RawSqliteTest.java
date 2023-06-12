package com.tekartik.sqflite;

import static org.junit.Assert.assertEquals;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;

import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

/**
 * Instrumented test, which will execute on an Android device.
 *
 * @see <a href="http://d.android.com/tools/testing">Testing documentation</a>
 */
@RunWith(AndroidJUnit4.class)
public class RawSqliteTest {
    static String TAG = "SQFLTest";

    @Test
    public void getSetVersion() {
        SQLiteDatabase db = SQLiteDatabase.createInMemory(new SQLiteDatabase.OpenParams.Builder().build());
        assertEquals(0, db.getVersion());
        db.setVersion(1);
        assertEquals(1, db.getVersion());
        db.close();
    }

    @Test
    public void substr() {
        // Issue #771
        SQLiteDatabase db = SQLiteDatabase.createInMemory(new SQLiteDatabase.OpenParams.Builder().build());
        Cursor cursor = db.rawQuery("SELECT substr('2022-04-01', 1, 4)", new String[0]);
        cursor.moveToFirst();
        assertEquals("2022", cursor.getString(0));
        cursor.close();
        db.close();
    }
}

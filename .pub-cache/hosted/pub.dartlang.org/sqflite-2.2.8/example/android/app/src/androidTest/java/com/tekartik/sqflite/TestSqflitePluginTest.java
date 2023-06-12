package com.tekartik.sqflite;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import android.content.Context;

import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.concurrent.CountDownLatch;

/**
 * Instrumented test, which will execute on an Android device.
 *
 * @see <a href="http://d.android.com/tools/testing">Testing documentation</a>
 */
@RunWith(AndroidJUnit4.class)
public class TestSqflitePluginTest {
    static String TAG = "SQFLTest";

    Context appContext = ApplicationProvider.getApplicationContext();

    class Data {
        CountDownLatch signal;
        Integer id;
    }

    @Test
    public void missingFile() {
        File file = new File(appContext.getFilesDir(), "missing.db");
        Database database = new Database(appContext, file.getPath(), 0, true, 0);
        Exception exception = null;
        try {
            database.openReadOnly();
            database.close();
        } catch (Exception e) {
            exception = e;
        }

        assertTrue(exception != null);
    }

    @Test
    public void emptyFile() throws IOException {
        File file = new File(appContext.getFilesDir(), "empty.db");
        FileWriter fileWriter = new FileWriter(file);
        fileWriter.write("");
        fileWriter.close();
        Database database = new Database(appContext, file.getPath(), 0, true, 0);
        database.openReadOnly();
        database.close();
    }

    @Test
    public void nonSqfliteFile() throws IOException {
        File file = new File(appContext.getFilesDir(), "non_sqflite_file.db");
        FileWriter fileWriter = new FileWriter(file);
        fileWriter.write("test");
        fileWriter.close();
        Database database = new Database(appContext, file.getPath(), 0, true, 0);
        database.openReadOnly();
        database.close();
        assertEquals(FileUtils.getStringFromFile(file), "test");
    }

    @Test
    public void databaseExists() throws IOException {
        File file = new File(appContext.getFilesDir(), "exists_file.db");
        try {
            file.delete();
        } catch (Exception e) {
        }
        assertEquals(false, Database.existsDatabase(file.getPath()));
        Database database = new Database(appContext, file.getPath(), 0, true, 0);
        try {
            database.open();
            database.sqliteDatabase.execSQL("PRAGMA version = 1");
        } finally {
            database.close();
        }
    }

    @Test
    public void walEnabled() {
        // False, uncomment in manifest to check for true
        assertFalse(Database.checkWalEnabled(appContext));
    }

    @Test
    public void checkMetaBoolean() {
        // False, uncomment in manifest to check for true
        assertTrue(Database.checkMetaBoolean(appContext, "com.tekartik.sqfliteexample.flagtrue", false));
        assertFalse(Database.checkMetaBoolean(appContext, "com.tekartik.sqfliteexample.flagfalse", false));
        assertTrue(Database.checkMetaBoolean(appContext, "com.tekartik.sqfliteexample.flagmissing", true));
        assertFalse(Database.checkMetaBoolean(appContext, "com.tekartik.sqfliteexample.flagmissing", false));
    }
}

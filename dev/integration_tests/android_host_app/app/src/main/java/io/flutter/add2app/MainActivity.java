package io.flutter.add2app;

import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.view.FlutterMain;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        FlutterMain.startInitialization(getApplicationContext());
        super.onCreate(savedInstanceState);
    }
}

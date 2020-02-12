// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.addtoapp;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import io.flutter.facade.Flutter;

public class MainActivity extends AppCompatActivity {

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(Flutter.createView(this, getLifecycle(), "route1"));
  }
}

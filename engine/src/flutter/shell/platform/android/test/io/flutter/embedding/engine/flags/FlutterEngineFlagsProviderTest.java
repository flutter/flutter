// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.flags;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import android.content.Intent;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import java.util.HashSet;
import java.util.List;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class FlutterEngineFlagsProviderTest {

  @Test
  public void itProcessesStringExtras() {
    Intent intent = new Intent();
    intent.putExtra("dart-flags", "--observe --no-hot --no-pub");
    intent.putExtra("trace-skia-allowlist", "skia.a,skia.b");
    intent.putExtra("trace-to-file", "path/to/trace.bin");

    List<String> args = FlutterEngineFlagsProviderImpl.INSTANCE.getFlags(intent);
    HashSet<String> argValues = new HashSet<>(args);

    assertEquals(3, argValues.size());
    assertTrue(argValues.contains("--dart-flags=--observe --no-hot --no-pub"));
    assertTrue(argValues.contains("--trace-skia-allowlist=skia.a,skia.b"));
    assertTrue(argValues.contains("--trace-to-file=path/to/trace.bin"));
  }

  @Test
  public void itProcessesBooleanExtras() {
    Intent intent = new Intent();
    intent.putExtra("trace-startup", true);
    intent.putExtra("start-paused", true);
    intent.putExtra("disable-service-auth-codes", true);
    intent.putExtra("endless-trace-buffer", true);
    intent.putExtra("use-test-fonts", true);
    intent.putExtra("enable-dart-profiling", true);
    intent.putExtra("profile-startup", true);
    intent.putExtra("enable-software-rendering", true);
    intent.putExtra("skia-deterministic-rendering", true);
    intent.putExtra("trace-skia", true);
    intent.putExtra("trace-systrace", true);
    intent.putExtra("dump-skp-on-shader-compilation", true);
    intent.putExtra("cache-sksl", true);
    intent.putExtra("purge-persistent-cache", true);
    intent.putExtra("verbose-logging", true);
    intent.putExtra("test-flag", true);
    intent.putExtra("enable-flutter-gpu", true);
    intent.putExtra("enable-vulkan-validation", true);

    List<String> args = FlutterEngineFlagsProviderImpl.INSTANCE.getFlags(intent);
    HashSet<String> argValues = new HashSet<>(args);

    assertEquals(18, argValues.size());
    assertTrue(argValues.contains("--trace-startup"));
    assertTrue(argValues.contains("--start-paused"));
    assertTrue(argValues.contains("--disable-service-auth-codes"));
    assertTrue(argValues.contains("--endless-trace-buffer"));
    assertTrue(argValues.contains("--use-test-fonts"));
    assertTrue(argValues.contains("--enable-dart-profiling"));
    assertTrue(argValues.contains("--profile-startup"));
    assertTrue(argValues.contains("--enable-software-rendering"));
    assertTrue(argValues.contains("--skia-deterministic-rendering"));
    assertTrue(argValues.contains("--trace-skia"));
    assertTrue(argValues.contains("--trace-systrace"));
    assertTrue(argValues.contains("--dump-skp-on-shader-compilation"));
    assertTrue(argValues.contains("--cache-sksl"));
    assertTrue(argValues.contains("--purge-persistent-cache"));
    assertTrue(argValues.contains("--verbose-logging"));
    assertTrue(argValues.contains("--test-flag"));
    assertTrue(argValues.contains("--enable-flutter-gpu"));
    assertTrue(argValues.contains("--enable-vulkan-validation"));
  }

  @Test
  public void itProcessesIntExtras() {
    Intent intent = new Intent();
    intent.putExtra("vm-service-port", 12345);

    List<String> args = FlutterEngineFlagsProviderImpl.INSTANCE.getFlags(intent);
    HashSet<String> argValues = new HashSet<>(args);

    assertEquals(1, argValues.size());
    assertTrue(argValues.contains("--vm-service-port=12345"));
  }

  @Test
  public void itProcessesPresenceExtras() {
    Intent intent = new Intent();
    intent.putExtra("profile-microtasks", true); // presence check

    // Toggle flags
    intent.putExtra("enable-impeller", true);
    intent.putExtra("enable-hcpp-and-surface-control", false);

    List<String> args = FlutterEngineFlagsProviderImpl.INSTANCE.getFlags(intent);
    HashSet<String> argValues = new HashSet<>(args);

    assertEquals(3, argValues.size());
    assertTrue(argValues.contains("--profile-microtasks"));
    assertTrue(argValues.contains("--enable-impeller=true"));
    assertTrue(argValues.contains("--enable-hcpp-and-surface-control=false"));
  }

  @Test
  public void itDoesNotPropagateMissingExtras() {
    Intent intent = new Intent();
    List<String> args = FlutterEngineFlagsProviderImpl.INSTANCE.getFlags(intent);
    assertEquals(0, args.size());
  }
}

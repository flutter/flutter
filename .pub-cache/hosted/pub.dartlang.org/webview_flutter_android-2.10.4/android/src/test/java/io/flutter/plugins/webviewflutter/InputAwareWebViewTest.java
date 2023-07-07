// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertNotNull;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import android.content.Context;
import android.view.View;
import org.junit.Test;

public class InputAwareWebViewTest {
  static class TestView extends View {
    Runnable postAction;

    public TestView(Context context) {
      super(context);
    }

    @Override
    public boolean post(Runnable action) {
      postAction = action;
      return true;
    }
  }

  @Test
  public void runnableChecksContainerViewIsNull() {
    final Context mockContext = mock(Context.class);

    final TestView containerView = new TestView(mockContext);
    final InputAwareWebView inputAwareWebView = new InputAwareWebView(mockContext, containerView);

    final View mockProxyAdapterView = mock(View.class);

    inputAwareWebView.setInputConnectionTarget(mockProxyAdapterView);
    inputAwareWebView.setContainerView(null);

    assertNotNull(containerView.postAction);
    containerView.postAction.run();
    verify(mockProxyAdapterView, never()).onWindowFocusChanged(anyBoolean());
  }
}

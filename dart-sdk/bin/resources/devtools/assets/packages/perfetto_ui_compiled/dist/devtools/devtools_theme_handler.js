// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

function toggleTheme(messageEvent) {
  const themePingId = 'DART-DEVTOOLS-THEME-PING';
  const themePongId = 'DART-DEVTOOLS-THEME-PONG';
  const themeChangeId = 'DART-DEVTOOLS-THEME-CHANGE';
  const KNOWN_MESSAGE_IDS = [
    themePingId,
    themeChangeId,
  ];

  const msgId = messageEvent.data.msgId;
  if (!KNOWN_MESSAGE_IDS.includes(msgId)) {
    return;
  }

  if (msgId === themePingId) {
    const windowSource = messageEvent.source;
    windowSource.postMessage(themePongId, messageEvent.origin);
    return;
  }

  const theme = messageEvent.data.theme;
  if (theme !== 'light' && theme !== 'dark') {
    console.warn(`Cannot change Perfetto theme. Expected 'light' or 'dark' but got $theme.`);
    return;
  }
  const sheet = document.getElementById('devtools-style');
  if (theme === 'light') {
    sheet.setAttribute('href', 'devtools/devtools_light.css');
  } else {
    sheet.setAttribute('href', 'devtools/devtools_dark.css');
  }
}

window.addEventListener('message', toggleTheme);

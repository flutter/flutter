// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export const baseUri = ensureTrailingSlash(getBaseURI());

function getBaseURI() {
  const base = document.querySelector("base");
  return (base && base.getAttribute("href")) || "";
}

function ensureTrailingSlash(uri) {
  if (uri === "") {
    return uri;
  }
  return uri.endsWith("/") ? uri : `${uri}/`;
}

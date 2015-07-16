// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

int returnInt() => 0;
bool returnBool() => true;
double returnDouble() => 0.42;
String returnString() => "String";
List<int> returnIntList() => [1,2,3,4,5];
Map<String, int> returnMap() => {'thing1': 1, 'thing2': 2};

int main() {
  returnInt();
  returnBool();
  returnDouble();
  returnString();
  returnIntList();
  returnMap();
}

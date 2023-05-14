// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: type=lint

bool isThereMeaningOfLife = true;

if (isThereMeaningOfLife) {}
if(isThereMeaningOfLife) {}
//^

switch (isThereMeaningOfLife) {}
switch(isThereMeaningOfLife) {}
//    ^

for (int index = 0; index < 10; index++) {}
for(int index = 0; index < 10; index++) {}
// ^

while (isThereMeaningOfLife) {}
while(isThereMeaningOfLife) {}
//   ^

try {
} catch (e) {}
try {
} catch(e) {}
//     ^

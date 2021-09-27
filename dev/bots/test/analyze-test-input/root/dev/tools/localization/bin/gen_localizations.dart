// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void main(List<String> args) {
  String type = '';
  if (args[0] == '--material') {
    type = 'material';
  }
  if (args[0] == '--cupertino') {
    type = 'cupertino';
  }
  print('''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void main(List<String> args) {
  print('Expected output $type');
}
''');
}

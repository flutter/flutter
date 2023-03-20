// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(
      Center(
          child: Opacity(
        opacity: 0.5,
        child: Stack(
          textDirection: TextDirection.ltr,
          children: [
            Text('à̴̡̢̲̜͔̤̈́s̵̛͔̖̣͙̱̙͎̈́̌͒̏̀̐̽̽͘͝d̷̨̲̣͇̜̩̗͔̹̩̰̎́͐̅̔̆͂͋̿̅͝a̷̪͔̤̥̅̓̒̄̓̈́̑̕s̸̡̢̯̲͙̱̻͓͔͎͂̒͐̀̃̏̊͗̀̽͘ḍ̸͓̩̬͙̰̘̙̼͌̂a̴͓͎͆̓̏͛̾̊̐̑͂̀͛̀̑͋͝s̷̳̤̄̍̿̓͂͠a̷̢̪̺̝͈̦̟̠͔͎̓̄̅͂̈̂ş̷̨̛̺̯̟̙̣̬̰̙̯̥̳̰͚͘ḏ̸̡̡̭̙̹̺̺̱̲͉̭̑̓̀͑̆́͌̃̍͘a̶̢̛̱̥͙̗͍̗̬͖͗̍̆̏̇͌̋͒̽͋̕s̸͖̮̳̺͔̺̱̪͉̜̝͎̝͕͆͑͌͆̂ͅḑ̴̦̼̪́͑͂̓̆̈͌ą̵̛͈̙̠̣͖̞̀̾̊̎̈́̆͊̕͜ͅs̷̙̲̦̠͚̺̱̦͘͝ã̶̧̨͚̞̞̬̬͎͉̩̦̗͔̓̅͊͂̎̕s̶̡̨̨̡̞̰͙̖͚̩̭̯̱͈͐̓̈́͆̐̾̋̎͌̎͆͠',
              key: Key('title'),
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 100),
            ),
            Container(color: Colors.red, width: 10, height: 10,),
          ],
        ),
      )),
    );

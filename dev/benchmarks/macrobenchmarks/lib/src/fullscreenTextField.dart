// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

// Make the text relatively expensive to paint so if the text repaints with the
// blinking cursor it explodes.
const String textLotsOfText = 'Lorem ipsum dolor sit amet, consectetur '
  'adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna '
  'aliqua. Odio facilisis mauris sit amet massa. Tellus pellentesque eu '
  'tincidunt tortor aliquam nulla facilisi cras fermentum. Sit amet risus nullam '
  'eget felis eget nunc. Placerat in egestas erat imperdiet sed. Vestibulum '
  'mattis ullamcorper velit sed. At auctor urna nunc id cursus metus aliquam. In '
  'nibh mauris cursus mattis. Quis blandit turpis cursus in hac habitasse platea '
  'dictumst. Orci a scelerisque purus semper eget duis at tellus. At tempor '
  'commodo ullamcorper a lacus. At auctor urna nunc id cursus metus aliquam '
  'eleifend. Sagittis aliquam malesuada bibendum arcu vitae elementum. Massa sed '
  'elementum tempus egestas sed sed risus. Amet consectetur adipiscing elit ut '
  'aliquam purus sit amet luctus. Elementum nisi quis eleifend quam adipiscing '
  'vitae. Aliquam sem fringilla ut morbi tincidunt augue.'
  'Tellus mauris a diam maecenas sed enim ut. Vehicula ipsum a arcu cursus vitae '
  'congue. Elementum pulvinar etiam non quam lacus suspendisse faucibus interdum. '
  'Arcu risus quis varius quam quisque id diam vel quam. Arcu non odio euismod '
  'lacinia at quis risus sed. Vitae semper quis lectus nulla at volutpat. Congue '
  'eu consequat ac felis donec et. Interdum velit euismod in pellentesque massa '
  'placerat duis. Tincidunt id aliquet risus feugiat in ante. Non odio euismod '
  'lacinia at quis risus sed. Nunc id cursus metus aliquam. Turpis in eu mi '
  'bibendum neque egestas congue. Diam vulputate ut pharetra sit amet aliquam. '
  'Dolor purus non enim praesent elementum facilisis. Facilisis volutpat est '
  'velit egestas dui id ornare arcu odio. Facilisis gravida neque convallis a '
  'cras semper. Commodo viverra maecenas accumsan lacus vel facilisis volutpat '
  'est velit. Vel pretium lectus quam id leo. Commodo sed egestas egestas fringilla.'
  '😀 😃 😄 😁 😆 😅 😂 🤣 🥲 ☺️ 😊 😇 🙂 🙃 😉 😌 😍 🥰 😘 😗 😙'
  '😚 😋 😛 😝 😜 🤪 🤨 🧐 🤓 😎 🥸 🤩 🥳 😏 😒 😞 😔 😟 😕 🙁 ☹'
  '️ 😣 😖 😫 😩 🥺 😢 😭 😤 😠 😡 🤬 🤯 😳 🥵 🥶 😱 😨 😰 😥 😓 '
  '🤗 🤔 🤭 🤫 🤥 😶 😐 😑 😬 🙄 😯 😦 😧 😮 😲 🥱 😴 🤤 😪 😵 '
  '🤐 🥴 🤢 🤮 🤧 😷 🤒 🤕 🤑 🤠 😈 👿 👹 👺 🤡 💩 👻 💀 ☠️ 👽 '
  '👾 🤖 🎃 😺 😸 😹 😻 😼 😽 🙀 😿 😾'
  '️ 😣 😖 😫 😩 🥺 😢 😭 😤 😠 😡 🤬 🤯 😳 🥵 🥶 😱 😨 😰 😥 😓 '
  '🤗 🤔 🤭 🤫 🤥 😶 😐 😑 😬 🙄 😯 😦 😧 😮 😲 🥱 😴 🤤 😪 😵 '
  '🤐 🥴 🤢 🤮 🤧 😷 🤒 🤕 🤑 🤠 😈 👿 👹 👺 🤡 💩 👻 💀 ☠️ 👽 '
  '👾 🤖 🎃 😺 😸 😹 😻 😼 😽 🙀 😿 😾'
  '👋 🤚 🖐 ✋ 🖖 👌 🤌 🤏 ✌️ 🤞 🤟 🤘 🤙 👈 👉 👆 🖕 👇 ☝️ 👍 👎'
  ' ✊ 👊 🤛 🤜 👏 🙌 👐 🤲 🤝 🙏 ✍️ 💅 🤳 💪 🦾 🦵 🦿 🦶 👣 👂 '
  '🦻 👃 🫀 🫁 🧠 🦷 🦴 👀 👁 👅 👄 💋 🩸';

class TextFieldPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        child: TextField(
          maxLines: null,
          controller: TextEditingController(text: textLotsOfText),
          key: const Key('fullscreen-textfield'),
        ),
      ),
    );
  }
}

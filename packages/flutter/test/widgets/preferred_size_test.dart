// Regression test for https://github.com/flutter/flutter/issues/126512

import 'package:flutter/widgets.dart';

class _ExtendPreferredSizeWidget extends PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(40);
}

class _ImplementPreferredSizeWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(40);
}

class _MixInPreferredSizeWidget with PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(40);
}
import 'package:flutter/widgets.dart';

void main() => runApp(
      const Center(
        child: Text('Olá Mundo',
            key: Key('título'), textDirection: TextDirection.ltr),
      ),
    );

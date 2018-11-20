import 'package:flutter/widgets.dart';

abstract class PlaygroundDemo {
  
  String tabName();
  Widget widget(BuildContext context);
  String code();

}


class PlaygroundDemoHolder extends StatefulWidget {
  @override
  PlaygroundDemoHolderState createState() => PlaygroundDemoHolderState();
}

class PlaygroundDemoHolderState extends State<PlaygroundDemoHolder> {
  @override
  Widget build(BuildContext context) {
    return Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 240.0,
                child: demo.previewWidget(this),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: demo.configWidget(this),
                ),
              ),
            ],
          );
  }
}
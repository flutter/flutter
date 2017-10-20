// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CupertinoNavigationDemo extends StatelessWidget {
  static const String routeName = '/cupertino/navigation';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return new WillPopScope(
      // Prevent swipe popping of this page. Use explicit exit buttons only.
      onWillPop: () => new Future<bool>.value(true),
      child: new CupertinoTabScaffold(
        tabBar: new CupertinoTabBar(
          items: const <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.home),
              title: const Text('Tab 1'),
            ),
            const BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.conversation_bubble),
              title: const Text('Tab 2'),
            ),
            const BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.profile_circled),
              title: const Text('Tab 3'),
            ),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          return new DefaultTextStyle(
            style: const TextStyle(
              fontFamily: '.SF UI Text',
              fontSize: 17.0,
              color: CupertinoColors.black,
            ),
            child: new CupertinoTabView(
              builder: (BuildContext context) {
                switch (index) {
                  case 0:
                    return new CupertinoDemoTab1();
                    break;
                  case 1:
                    return new CupertinoDemoTab2();
                    break;
                  case 2:
                    return new CupertinoDemoTab3();
                    break;
                  default:
                }
              }
            ),
          );
        },
      ),
    );
  }
}

class ExitButton extends StatelessWidget {
  const ExitButton();

  @override
  Widget build(BuildContext context) {
    return new CupertinoButton(
      padding: EdgeInsets.zero,
      child: const Text('Exit'),
      onPressed: () {
        // The demo is on the root navigator.
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }
}

class CupertinoDemoTab1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new CupertinoPageScaffold(
      child: new CustomScrollView(
        slivers: <Widget>[
          const CupertinoSliverNavigationBar(
            largeTitle: const Text('Home'),
            trailing: const ExitButton(),
          ),
          new SliverList(
            delegate: new SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return new Tab1RowItem(index: index, lastItem: index == 49);
              },
              childCount: 50,
            ),
          ),
        ],
      ),
    );
  }
}

class Tab1RowItem extends StatefulWidget {
  Tab1RowItem({this.index, this.lastItem}) ;

  final int index;
  final bool lastItem;

  @override
  State<StatefulWidget> createState() => new Tab1RowItemState();
}

class Tab1RowItemState extends State<Tab1RowItem> {
  static const List<Color> coolColors = const <Color>[
    const Color.fromARGB(255, 255, 59, 48),
    const Color.fromARGB(255, 255, 149, 0),
    const Color.fromARGB(255, 255, 204, 0),
    const Color.fromARGB(255, 76, 217, 100),
    const Color.fromARGB(255, 90, 200, 250),
    const Color.fromARGB(255, 0, 122, 255),
    const Color.fromARGB(255, 88, 86, 214),
    const Color.fromARGB(255, 255, 45, 85),
  ];

  static const List<String> coolColorNames = const <String>[
    'Sarcoline', 'Coquelicot', 'Smaragdine', 'Mikado', 'Glaucous', 'Wenge',
    'Fulvous', 'Xanadu', 'Falu', 'Eburnean', 'Amaranth', 'Australien',
    'Banan', 'Falu', 'Gingerline', 'Incarnadine', 'Labrabor', 'Nattier',
    'Pervenche', 'Sinoper', 'Verditer', 'Watchet', 'Zaffre',
  ];

  Tab1RowItemState() :
      color = coolColors[new math.Random().nextInt(coolColors.length)],
      colorName = coolColorNames[new math.Random().nextInt(coolColorNames.length)];

  final Color color;
  final String colorName;

  bool added = false;

  @override
  Widget build(BuildContext context) {
    final Widget row = new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(new CupertinoPageRoute<Null>(
          builder: (BuildContext context) => new Tab1ItemPage(
            color: color,
            colorName: colorName,
            index: widget.index,
          ),
        ));
      },
      child: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: new Row(
          children: <Widget>[
            new Container(
              height: 60.0,
              width: 60.0,
              decoration: new BoxDecoration(
                color: color,
                borderRadius: new BorderRadius.circular(8.0),
              ),
            ),
            new Expanded(
              child: new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(colorName),
                    const Padding(padding: const EdgeInsets.only(top: 8.0)),
                    const Text(
                      'Buy this cool color',
                      style: const TextStyle(
                        color: const Color(0xff8e8e93),
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            new CupertinoButton(
              padding: EdgeInsets.zero,
              child: new Icon(
                added ? CupertinoIcons.minus_circled : CupertinoIcons.plus_circled,
                color: CupertinoColors.activeBlue
              ),
              onPressed: () {
                setState(() { added = !added; });
              },
            ),
            new CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.share, color: CupertinoColors.activeBlue),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    if (widget.lastItem) {
      return row;
    } else {
      return new Column(
        children: <Widget>[
          row,
          new Padding(
            padding: const EdgeInsets.symmetric(horizontal: 92.0),
            child: new Container(
              height: 1.0,
              color: const Color(0xffD9D9D9),
            )
          )

        ],
      );
    }
  }
}

class Tab1ItemPage extends StatelessWidget {
  Tab1ItemPage({this.color, this.colorName, this.index});

  final Color color;
  final String colorName;
  final int index;

  @override
  Widget build(BuildContext context) {
    return new CupertinoPageScaffold(
      navigationBar: new CupertinoNavigationBar(
        middle: new Text(colorName),
        trailing: const ExitButton(),
      ),
      child: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80.0),
        child: new Row(children: <Widget>[
          new Container(
            height: 128.0,
            width: 128.0,
            decoration: new BoxDecoration(
              color: color,
              borderRadius: new BorderRadius.circular(24.0),
            ),
          ),
          const Padding(padding: const EdgeInsets.only(left: 24.0)),
          new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Text(
                colorName,
                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              const Padding(padding: const EdgeInsets.only(top: 6.0)),
              new Text(
                'Item number $index',
                style: const TextStyle(
                  color: const Color(0xff8e8e93),
                  fontSize: 16.0,
                  fontWeight: FontWeight.w100,
                ),
              ),
              const Padding(padding: const EdgeInsets.only(top: 20.0)),
              new Row(
                children: <Widget>[
                  new CupertinoButton(
                    color: CupertinoColors.activeBlue,
                    minSize: 30.0,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    borderRadius: new BorderRadius.circular(32.0),
                    child: const Text(
                      'GET',
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.28,
                      ),
                    ),
                    onPressed: () {},
                  ),
                  // new Expanded(child: new Container()),
                  new CupertinoButton(
                    color: CupertinoColors.activeBlue,
                    minSize: 30.0,
                    padding: EdgeInsets.zero,
                    borderRadius: new BorderRadius.circular(32.0),
                    child: const Icon(CupertinoIcons.ellipsis, color: CupertinoColors.white),
                    onPressed: () {},
                  ),
                ],
              )
            ],
          ),
        ]),
      ),
    );
  }
}

class CupertinoDemoTab2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: const Text('Support Chat'),
        trailing: const ExitButton(),
      ),
      child: new ListView(
        children: <Widget>[
          const Padding(padding: const EdgeInsets.only(top: 60.0)),
          new Tab2Header(),
        ],
      ),
    );
  }
}

class Tab2Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(16.0),
      child: new ClipRRect(
        borderRadius: const BorderRadius.all(const Radius.circular(16.0)),
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Container(
              decoration: const BoxDecoration(
                color: const Color(0xFFE5E5E5),
              ),
              child: new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'PULL REQUEST',
                      style: const TextStyle(
                        color: const Color(0xFF646464),
                        letterSpacing: -0.8,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'Show More',
                      style: const TextStyle(
                        color: const Color(0xFF646464),
                        letterSpacing: -0.6,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            new Container(
              decoration: const BoxDecoration(
                color: const Color(0xFFF3F3F3),
              ),
              child: new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Add Neural Reading Functions via Implant Interface #204',
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const Padding(padding: const EdgeInsets.only(top: 16.0)),
                    const Text(
                      'REVIEWERS',
                      style: const TextStyle(
                        color: const Color(0xFF646464),
                        fontSize: 12.0,
                        letterSpacing: -0.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Padding(padding: const EdgeInsets.only(top: 8.0)),
                    new Row(
                      children: <Widget>[
                        new Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: new BoxDecoration(
                            image: new DecorationImage(
                              image: const AssetImage('assets/reviewer1.jpeg')
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Padding(padding: const EdgeInsets.only(left: 2.0)),
                        new Image(
                          image: const AssetImage('assets/check-2.png'),
                          width: 30.0,
                        ),
                        const Padding(padding: const EdgeInsets.only(left: 8.0)),
                        new Container(
                          width: 44.0,
                          height: 44.0,
                          decoration: new BoxDecoration(
                            image: new DecorationImage(
                              image: const AssetImage('assets/reviewer4.jpeg')
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Padding(padding: const EdgeInsets.only(left: 2.0)),
                        new Image(
                          image: const AssetImage('assets/comments-2.png'),
                          width: 30.0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum Tab2ConversationBubbleColor {
  blue,
  gray,
}

class Tab2ConversationBubble extends StatelessWidget {
  Tab2ConversationBubble({this.text, this.color});

  final String text;
  final Tab2ConversationBubbleColor color;

  @override
  Widget build(BuildContext context) {
    return new Container(
      decoration: new BoxDecoration(
        borderRadius: const BorderRadius.all(const Radius.circular(18.0)),
        color: color == Tab2ConversationBubbleColor.blue
            ? CupertinoColors.activeBlue
            : CupertinoColors.inactiveGray,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: new Text(
        text,
        style: new TextStyle(
          color: color == Tab2ConversationBubbleColor.blue
              ? CupertinoColors.white
              : CupertinoColors.black,
          letterSpacing: -0.4,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}

class Tab2ConversationAvatar extends StatelessWidget {
  Tab2ConversationAvatar({this.text, this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return new Container(
      decoration: new BoxDecoration(
        shape: BoxShape.circle,
        gradient: new LinearGradient(
          begin: FractionalOffset.topCenter,
          end: FractionalOffset.bottomCenter,
          colors: <Color>[const Color(0xFFFD5015), const Color(0xFFC72008)],
        ),
      ),
      margin: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      child: new Text(
        'LA',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.0,
          fontWeight: FontWeight.w500,
        ),
      )
    );
  }
}

List<Widget> buildTab2Conversation() {

}

class Tab2Conversation extends StatelessWidget {

}

class CupertinoDemoTab3 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new CupertinoDemoTab3State();
}

class CupertinoDemoTab3State extends State<CupertinoDemoTab3> {
  bool signedIn = false;

  @override
  Widget build(BuildContext context) {
    return new CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: const Text('Account'),
        trailing: const ExitButton(),
      ),
      child: new DecoratedBox(
        decoration: const BoxDecoration(color: const Color(0xffefeff4)),
        child: new ListView(
          children: <Widget>[
            const Padding(padding: const EdgeInsets.only(top: 100.0)),
            new GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  new CupertinoPageRoute<bool>(
                    fullscreenDialog: true,
                    builder: (BuildContext context) {
                       return new CupertinoPageScaffold(
                         navigationBar: new CupertinoNavigationBar(
                           leading: new CupertinoButton(
                             child: const Text('Cancel'),
                             onPressed: () {
                               Navigator.of(context).pop(false);
                             },
                           ),
                         ),
                         child: new Center(

                         ),
                       );
                    },
                  ),
                );
              },
              child: new Container(
                decoration: const BoxDecoration(
                  color: CupertinoColors.white,
                  border: const Border(
                    top: const BorderSide(color: const Color(0xffbcbbbc1), width: 0.0),
                    bottom: const BorderSide(color: const Color(0xffbcbbbc1), width: 0.0),
                  ),
                ),
                height: 44.0,
                child: new Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: new Row(children: <Widget>[ new Text(
                    signedIn ? 'Sign out' : 'Sign in',
                    style: const TextStyle(color: CupertinoColors.activeBlue),
                  ) ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

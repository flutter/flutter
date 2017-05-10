// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

void main() {
  runApp(
    new ComplexLayoutApp()
  );
}

enum ScrollMode { complex, tile }

class ComplexLayoutApp extends StatefulWidget {
  @override
  ComplexLayoutAppState createState() => new ComplexLayoutAppState();

  static ComplexLayoutAppState of(BuildContext context) => context.ancestorStateOfType(const TypeMatcher<ComplexLayoutAppState>());
}

class ComplexLayoutAppState extends State<ComplexLayoutApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: lightTheme ? new ThemeData.light() : new ThemeData.dark(),
      title: 'Advanced Layout',
      home: scrollMode == ScrollMode.complex ? const ComplexLayout() : const TileScrollLayout());
  }

  bool _lightTheme = true;
  bool get lightTheme => _lightTheme;
  set lightTheme(bool value) {
    setState(() {
      _lightTheme = value;
    });
  }

  ScrollMode _scrollMode = ScrollMode.complex;
  ScrollMode get scrollMode => _scrollMode;
  set scrollMode(ScrollMode mode) {
    setState(() {
      _scrollMode = mode;
    });
  }

  void toggleAnimationSpeed() {
    setState(() {
      timeDilation = (timeDilation != 1.0) ? 1.0 : 5.0;
    });
  }
}

class TileScrollLayout extends StatelessWidget {
  const TileScrollLayout({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: const Text('Tile Scrolling Layout')),
      body: new ListView.builder(
        key: const Key('tiles-scroll'),
        itemCount: 200,
        itemBuilder: (BuildContext context, int index) {
          return new Padding(
            padding:const EdgeInsets.all(5.0),
            child: new Material(
              elevation: (index % 5 + 1).toDouble(),
              color: Colors.white,
              child: new IconBar(),
            ),
          );
        }
      ),
      drawer: const GalleryDrawer(),
    );
  }
}

class ComplexLayout extends StatefulWidget {
  const ComplexLayout({ Key key }) : super(key: key);

  @override
  ComplexLayoutState createState() => new ComplexLayoutState();

  static ComplexLayoutState of(BuildContext context) => context.ancestorStateOfType(const TypeMatcher<ComplexLayoutState>());
}

class ComplexLayoutState extends State<ComplexLayout> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Advanced Layout'),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.create),
            tooltip: 'Search',
            onPressed: () {
              print('Pressed search');
            },
          ),
          new TopBarMenu()
        ]
      ),
      body: new Column(
        children: <Widget>[
          new Expanded(
            child: new ListView.builder(
              key: const Key('complex-scroll'), // this key is used by the driver test
              itemBuilder: (BuildContext context, int index) {
                if (index % 2 == 0)
                  return new FancyImageItem(index, key: new ValueKey<int>(index));
                else
                  return new FancyGalleryItem(index, key: new ValueKey<int>(index));
              },
            )
          ),
          new BottomBar(),
        ],
      ),
      drawer: const GalleryDrawer(),
    );
  }
}

class TopBarMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new PopupMenuButton<String>(
      onSelected: (String value) { print('Selected: $value'); },
      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
        const PopupMenuItem<String>(
          value: 'Friends',
          child: const MenuItemWithIcon(Icons.people, 'Friends', '5 new')
        ),
        const PopupMenuItem<String>(
          value: 'Events',
          child: const MenuItemWithIcon(Icons.event, 'Events', '12 upcoming')
        ),
        const PopupMenuItem<String>(
          value: 'Events',
          child: const MenuItemWithIcon(Icons.group, 'Groups', '14')
        ),
        const PopupMenuItem<String>(
          value: 'Events',
          child: const MenuItemWithIcon(Icons.image, 'Pictures', '12')
        ),
        const PopupMenuItem<String>(
          value: 'Events',
          child: const MenuItemWithIcon(Icons.near_me, 'Nearby', '33')
        ),
        const PopupMenuItem<String>(
          value: 'Friends',
          child: const MenuItemWithIcon(Icons.people, 'Friends', '5')
        ),
        const PopupMenuItem<String>(
          value: 'Events',
          child: const MenuItemWithIcon(Icons.event, 'Events', '12')
        ),
        const PopupMenuItem<String>(
          value: 'Events',
          child: const MenuItemWithIcon(Icons.group, 'Groups', '14')
        ),
        const PopupMenuItem<String>(
          value: 'Events',
          child: const MenuItemWithIcon(Icons.image, 'Pictures', '12')
        ),
        const PopupMenuItem<String>(
          value: 'Events',
          child: const MenuItemWithIcon(Icons.near_me, 'Nearby', '33')
        )
      ]
    );
  }
}

class MenuItemWithIcon extends StatelessWidget {
  const MenuItemWithIcon(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Icon(icon),
        new Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: new Text(title)
        ),
        new Text(subtitle, style: Theme.of(context).textTheme.caption)
      ]
    );
  }
}

class FancyImageItem extends StatelessWidget {
  const FancyImageItem(this.index, {Key key}) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    return new ListBody(
      children: <Widget>[
        new UserHeader('Ali Connors $index'),
        new ItemDescription(),
        new ItemImageBox(),
        new InfoBar(),
        const Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: const Divider()
        ),
        new IconBar(),
        new FatDivider()
      ]
    );
  }
}

class FancyGalleryItem extends StatelessWidget {
  const FancyGalleryItem(this.index, {Key key}) : super(key: key);

  final int index;
  @override
  Widget build(BuildContext context) {
    return new ListBody(
      children: <Widget>[
        const UserHeader('Ali Connors'),
        new ItemGalleryBox(index),
        new InfoBar(),
        const Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: const Divider()
        ),
        new IconBar(),
        new FatDivider()
      ]
    );
  }
}

class InfoBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const MiniIconWithText(Icons.thumb_up, '42'),
          new Text('3 Comments', style: Theme.of(context).textTheme.caption)
        ]
      )
    );
  }
}

class IconBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const IconWithText(Icons.thumb_up, 'Like'),
          const IconWithText(Icons.comment, 'Comment'),
          const IconWithText(Icons.share, 'Share'),
        ]
      )
    );
  }
}

class IconWithText extends StatelessWidget {
  const IconWithText(this.icon, this.title);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return new Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new IconButton(
          icon: new Icon(icon),
          onPressed: () { print('Pressed $title button'); }
        ),
        new Text(title)
      ]
    );
  }
}

class MiniIconWithText extends StatelessWidget {
  const MiniIconWithText(this.icon, this.title);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return new Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: new Container(
            width: 16.0,
            height: 16.0,
            decoration: new BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle
            ),
            child: new Icon(icon, color: Colors.white, size: 12.0)
          )
        ),
        new Text(title, style: Theme.of(context).textTheme.caption)
      ]
    );
  }
}

class FatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 8.0,
      color: Theme.of(context).dividerColor,
    );
  }
}

class UserHeader extends StatelessWidget {
  const UserHeader(this.userName);

  final String userName;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: const Image(
              image: const AssetImage('packages/flutter_gallery_assets/ali_connors_sml.png'),
              width: 32.0,
              height: 32.0
            )
          ),
          new Expanded(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                new RichText(text: new TextSpan(
                  style: Theme.of(context).textTheme.body1,
                  children: <TextSpan>[
                    new TextSpan(text: userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' shared a new '),
                    const TextSpan(text: 'photo', style: const TextStyle(fontWeight: FontWeight.bold))
                  ]
                )),
                new Row(
                  children: <Widget>[
                    new Text('Yesterday at 11:55 • ', style: Theme.of(context).textTheme.caption),
                    new Icon(Icons.people, size: 16.0, color: Theme.of(context).textTheme.caption.color)
                  ]
                )
              ]
            )
          ),
          new TopBarMenu()
        ]
      )
    );
  }
}

class ItemDescription extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: const EdgeInsets.all(8.0),
      child: const Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.')
    );
  }
}

class ItemImageBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Card(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Stack(
              children: <Widget>[
                const SizedBox(
                  height: 230.0,
                  child: const Image(
                    image: const AssetImage('packages/flutter_gallery_assets/top_10_australian_beaches.png')
                  )
                ),
                new Theme(
                  data: new ThemeData.dark(),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      new IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () { print('Pressed edit button'); }
                      ),
                      new IconButton(
                        icon: const Icon(Icons.zoom_in),
                        onPressed: () { print('Pressed zoom button'); }
                      ),
                    ]
                  )
                ),
                new Positioned(
                  bottom: 4.0,
                  left: 4.0,
                  child: new Container(
                    decoration: new BoxDecoration(
                      color: Colors.black54,
                      borderRadius: new BorderRadius.circular(2.0)
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: new RichText(
                      text: new TextSpan(
                        style: const TextStyle(color: Colors.white),
                        children: <TextSpan>[
                          const TextSpan(
                            text: 'Photo by '
                          ),
                          const TextSpan(
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            text: 'Magic Mike'
                          )
                        ]
                      )
                    )
                  )
                )
              ]
            )
            ,
            new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  new Text('Where can you find that amazing sunset?', style: Theme.of(context).textTheme.body2),
                  new Text('The sun sets over stinson beach', style: Theme.of(context).textTheme.body1),
                  new Text('flutter.io/amazingsunsets', style: Theme.of(context).textTheme.caption)
                ]
              )
            )
          ]
        )
      )
    );
  }
}

class ItemGalleryBox extends StatelessWidget {
  const ItemGalleryBox(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    final List<String> tabNames = <String>[
      'A', 'B', 'C', 'D'
    ];

    return new SizedBox(
      height: 200.0,
      child: new DefaultTabController(
        length: tabNames.length,
        child: new Column(
          children: <Widget>[
            new Expanded(
              child: new TabBarView(
                children: tabNames.map((String tabName) {
                  return new Container(
                    key: new Key(tabName),
                    child: new Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: new Card(
                        child: new Column(
                          children: <Widget>[
                            new Expanded(
                              child: new Container(
                                color: Theme.of(context).primaryColor,
                                child: new Center(
                                  child: new Text(tabName, style: Theme.of(context).textTheme.headline.copyWith(color: Colors.white)),
                                )
                              )
                            ),
                            new Row(
                              children: <Widget>[
                                new IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () { print('Pressed share'); },
                                ),
                                new IconButton(
                                  icon: const Icon(Icons.event),
                                  onPressed: () { print('Pressed event'); },
                                ),
                                new Expanded(
                                  child: new Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: new Text('This is item $tabName'),
                                  )
                                )
                              ]
                            )
                          ]
                        )
                      )
                    )
                  );
                }).toList()
              )
            ),
            new Container(
              child: const TabPageSelector()
            )
          ]
        )
      )
    );
  }
}

class BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container(
      decoration: new BoxDecoration(
        border: new Border(
          top: new BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0
          )
        )
      ),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const BottomBarButton(Icons.new_releases, 'News'),
          const BottomBarButton(Icons.people, 'Requests'),
          const BottomBarButton(Icons.chat, 'Messenger'),
          const BottomBarButton(Icons.bookmark, 'Bookmark'),
          const BottomBarButton(Icons.alarm, 'Alarm'),
        ],
      ),
    );
  }
}

class BottomBarButton extends StatelessWidget {
  const BottomBarButton(this.icon, this.title);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Column(
        children: <Widget>[
          new IconButton(
            icon: new Icon(icon),
            onPressed: () { print('Pressed: $title'); }
          ),
          new Text(title, style: Theme.of(context).textTheme.caption)
        ]
      )
    );
  }
}

class GalleryDrawer extends StatelessWidget {
  const GalleryDrawer({ Key key }) : super(key: key);

  void _changeTheme(BuildContext context, bool value) {
    ComplexLayoutApp.of(context).lightTheme = value;
  }

  void _changeScrollMode(BuildContext context, ScrollMode mode) {
    ComplexLayoutApp.of(context).scrollMode = mode;
  }

  @override
  Widget build(BuildContext context) {
    final ScrollMode currentMode = ComplexLayoutApp.of(context).scrollMode;
    return new Drawer(
      child: new ListView(
        children: <Widget>[
          new FancyDrawerHeader(),
          new ListTile(
            key: const Key('scroll-switcher'),
            onTap: () { _changeScrollMode(context, currentMode == ScrollMode.complex ? ScrollMode.tile : ScrollMode.complex); },
            trailing: new Text(currentMode == ScrollMode.complex ? 'Tile' : 'Complex')
          ),
          new ListTile(
            leading: const Icon(Icons.brightness_5),
            title: const Text('Light'),
            onTap: () { _changeTheme(context, true); },
            selected: ComplexLayoutApp.of(context).lightTheme,
            trailing: new Radio<bool>(
              value: true,
              groupValue: ComplexLayoutApp.of(context).lightTheme,
              onChanged: (bool value) { _changeTheme(context, value); }
            ),
          ),
          new ListTile(
            leading: const Icon(Icons.brightness_7),
            title: const Text('Dark'),
            onTap: () { _changeTheme(context, false); },
            selected: !ComplexLayoutApp.of(context).lightTheme,
            trailing: new Radio<bool>(
              value: false,
              groupValue: ComplexLayoutApp.of(context).lightTheme,
              onChanged: (bool value) { _changeTheme(context, value); },
            ),
          ),
          const Divider(),
          new ListTile(
            leading: const Icon(Icons.hourglass_empty),
            title: const Text('Animate Slowly'),
            selected: timeDilation != 1.0,
            onTap: () { ComplexLayoutApp.of(context).toggleAnimationSpeed(); },
            trailing: new Checkbox(
              value: timeDilation != 1.0,
              onChanged: (bool value) { ComplexLayoutApp.of(context).toggleAnimationSpeed(); }
            ),
          ),
        ],
      ),
    );
  }
}

class FancyDrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.purple,
      height: 200.0,
    );
  }
}

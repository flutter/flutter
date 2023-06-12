import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  int badge = 0;

  List<GButton> tabs = [];
  List<Color> colors = [
    Colors.purple,
    Colors.pink,
    Colors.amber[600]!,
    Colors.teal,
    Colors.lightBlue
  ];

  @override
  void initState() {
    super.initState();
  }

  void _tabChanged(int index) {
    badge = badge + 1;
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedContainer(
        duration: Duration(milliseconds: 800),
        color: colors[selectedIndex],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: -10,
                      blurRadius: 60,
                      color: Colors.black.withOpacity(.20),
                      offset: Offset(0, 15),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 22),
                  child: GNav(
                    gap: 10,
                    color: Colors.grey[600],
                    activeColor: Colors.white,
                    rippleColor: Colors.grey[800]!,
                    hoverColor: Colors.grey[700]!,
                    iconSize: 20,
                    textStyle: TextStyle(fontSize: 16, color: Colors.white),
                    tabBackgroundColor: Colors.grey[900]!,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 16.5),
                    duration: Duration(milliseconds: 800),
                    tabs: [
                      GButton(
                        icon: LineIcons.home,
                        text: 'Home',
                      ),
                      GButton(
                        icon: LineIcons.heart,
                        text: 'Likes',
                      ),
                      GButton(
                        icon: LineIcons.search,
                        text: 'Search',
                      ),
                      GButton(
                        icon: LineIcons.user,
                        text: 'Profile',
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onTabChange: _tabChanged,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: -10,
                      blurRadius: 60,
                      color: Colors.black.withOpacity(.20),
                      offset: Offset(0, 15),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 22),
                  child: GNav(
                    tabActiveBorder: Border.all(color: Colors.black),
                    gap: 10,
                    color: Colors.grey[600],
                    activeColor: Colors.black,
                    rippleColor: Colors.grey[300]!,
                    hoverColor: Colors.grey[100]!,
                    iconSize: 20,
                    textStyle: TextStyle(fontSize: 16, color: Colors.black),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 14.5),
                    duration: Duration(milliseconds: 800),
                    tabs: [
                      GButton(
                        icon: LineIcons.home,
                        text: 'Get',
                      ),
                      GButton(
                        icon: LineIcons.heart,
                        text: 'This',
                        leading: selectedIndex == 1 || badge == 0
                            ? null
                            : Badge(
                                badgeColor: Colors.red.shade100,
                                elevation: 0,
                                position:
                                    BadgePosition.topEnd(top: -12, end: -12),
                                badgeContent: Text(
                                  badge.toString(),
                                  style: TextStyle(color: Colors.red.shade900),
                                ),
                                child: Icon(
                                  LineIcons.heart,
                                  size: 20,
                                  color: selectedIndex == 1
                                      ? Colors.pink
                                      : Colors.black,
                                ),
                              ),
                      ),
                      GButton(
                        icon: LineIcons.search,
                        text: 'NavBar',
                      ),
                      GButton(
                        icon: LineIcons.user,
                        text: 'Now!',
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(
                              'https://sooxt98.space/content/images/size/w100/2019/01/profile.png'),
                        ),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onTabChange: _tabChanged,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22.0, vertical: 14),
                  child: GNav(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    duration: Duration(milliseconds: 800),
                    gap: 8.5,
                    tabs: [
                      GButton(
                        iconActiveColor: Colors.purple,
                        iconColor: Colors.black,
                        textColor: Colors.purple,
                        backgroundColor: Colors.purple.withOpacity(.2),
                        iconSize: 24,
                        icon: LineIcons.home,
                        text: 'Home',
                      ),
                      GButton(
                        iconActiveColor: Colors.pink,
                        iconColor: Colors.black,
                        textColor: Colors.pink,
                        backgroundColor: Colors.pink.withOpacity(.2),
                        iconSize: 24,
                        icon: LineIcons.heart,
                        text: 'Likes',
                      ),
                      GButton(
                        iconActiveColor: Colors.amber[600],
                        iconColor: Colors.black,
                        textColor: Colors.amber[600],
                        backgroundColor: Colors.amber[600]!.withOpacity(.2),
                        iconSize: 24,
                        icon: LineIcons.search,
                        text: 'Search',
                      ),
                      GButton(
                        iconActiveColor: Colors.teal,
                        iconColor: Colors.black,
                        textColor: Colors.teal,
                        backgroundColor: Colors.teal.withOpacity(.2),
                        iconSize: 24,
                        icon: LineIcons.user,
                        text: 'Profile',
                      )
                    ],
                    selectedIndex: selectedIndex,
                    onTabChange: _tabChanged,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 22),
                  child: GNav(
                    tabBackgroundGradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Colors.lightBlue[100]!, Colors.cyan],
                    ),
                    gap: 8,
                    tabBorderRadius: 15,
                    color: Colors.grey[600],
                    activeColor: Colors.white,
                    iconSize: 16,
                    textStyle: TextStyle(fontSize: 12, color: Colors.white),
                    tabBackgroundColor: Colors.grey[800]!,
                    padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 16.5),
                    duration: Duration(milliseconds: 800),
                    tabs: [
                      GButton(
                        icon: LineIcons.home,
                        text: 'Home',
                      ),
                      GButton(
                        icon: LineIcons.heart,
                        text: 'Likes',
                      ),
                      GButton(
                        icon: LineIcons.search,
                        text: 'Search',
                      ),
                      GButton(
                        icon: LineIcons.user,
                        text: 'Profile',
                      ),
                      GButton(
                        icon: LineIcons.cog,
                        text: 'Settings',
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onTabChange: _tabChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

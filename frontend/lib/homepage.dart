import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:parkngo/myreservations.dart';
import 'package:parkngo/notifications.dart';
import 'package:parkngo/profilepage.dart';
import 'package:parkngo/reservation.dart';
import 'mapview.dart'; // Import the MapView widget

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Park & Go'),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: <Widget>[
          MapView(), // Replace the default page with MapView widget
          MyReservations(),
          ParkingReservationView(), // Plus icon in the center
          NotificationsView(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color.fromARGB(255, 209, 221, 77),
        items: <Widget>[
          Icon(CupertinoIcons.home, size: 30), // Home icon
          Icon(CupertinoIcons.clock_fill, size: 30), // Search icon
          Icon(CupertinoIcons.add, size: 30), // Plus icon
          Icon(CupertinoIcons.bell_circle_fill, size: 30), // Chat or Text icon
          Icon(CupertinoIcons.person, size: 30), // Person icon
        ],
        onTap: _onItemTapped,
        index: _selectedIndex,
      ),
    );
  }
}

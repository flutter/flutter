import 'package:app3/widget/Myalert.dart';
import 'package:app3/widget/Myanimatedtext.dart';
import 'package:app3/widget/Myimage.dart';
import 'package:app3/widget/Rows_cols.dart';
import 'package:flutter/material.dart';

class Mybottomnav extends StatefulWidget {
  const Mybottomnav({super.key});

  @override
  State<Mybottomnav> createState() => _MybottomnavState();
}

class _MybottomnavState extends State<Mybottomnav> {
  int selectedindex = 0;

  //List<Widget> widgets = [
  //  Text('Home'),
  //  Text('Search'),
  //  Text('Add'),
  //  Text('Profile'),
  //];
  PageController pageController = PageController();
  void onTapped(int index) {
    setState(() {
      selectedindex = index;
    });
    pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        children: const [
          Myalert(),
          Rows_cols(),
          Myimage(),
          Myanimatedtext(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: selectedindex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white,
        onTap: onTapped,
      ),
    );
  }
}

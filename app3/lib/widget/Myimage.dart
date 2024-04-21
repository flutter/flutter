// ignore: file_names
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Myimage extends StatefulWidget {
  const Myimage({super.key});

  @override
  State<Myimage> createState() => _MyimageState();
}

class _MyimageState extends State<Myimage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.image),
          backgroundColor: Colors.blue,
          title: const Text(
            'Image Widgets',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          toolbarHeight: 100,
        ),
        body: Center(
          child: Container(
              height: 200,
              width: 300,
              color: Colors.white,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl:
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT3IyYKvt2H_4y-EA9GOzESMHug3-qT6FAQVg&s',
                ),
              )),
        ));
  }
}

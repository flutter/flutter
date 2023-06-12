import 'dart:io';

import 'package:hive/hive.dart';

part 'main.g.dart';

@HiveType(typeId: 1)
class Person {
  Person({required this.name, required this.age, required this.friends});

  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  List<String> friends;

  @override
  String toString() {
    return '$name: $age';
  }
}

void main() async {
  var path = Directory.current.path;
  Hive
    ..init(path)
    ..registerAdapter(PersonAdapter());

  var box = await Hive.openBox('testBox');

  var person = Person(
    name: 'Dave',
    age: 22,
    friends: ['Linda', 'Marc', 'Anne'],
  );

  await box.put('dave', person);

  print(box.get('dave')); // Dave: 22
}

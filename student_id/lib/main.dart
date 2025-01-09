import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Student> data = List.generate(40, (index) {
    return Student(
      name: "Student ${index + 1}",
      id: "64398400${index + 1}",
    );
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My CIS"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SizedBox(
        width: double.infinity,
        child: ListView(
          children: data.map((student) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailPage(student: student),
                  ),
                );
              },
              child: studentListItem(
                name: student.name,
                id: student.id,
                image: student.image,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Row studentListItem(
      {required String name, required String id, required String image}) {
    return Row(
      children: [
        Hero(
          tag: id,
          child: ClipOval(
            child: Image.asset(
              image,
              width: 80,
              height: 80,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name),
            Text(id),
          ],
        ),
      ],
    );
  }
}

class Student {
  final String name;
  final String id;
  final String image;

  Student(
      {required this.name,
      required this.id,
      this.image = '../images/kku1.jpg'});
}

class StudentDetailPage extends StatelessWidget {
  final Student student;

  const StudentDetailPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: student.id,
              child: ClipOval(
                child: Image.asset(
                  student.image,
                  width: 150,
                  height: 150,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              student.name,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              student.id,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

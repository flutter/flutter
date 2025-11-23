class Student {
final String name;
final int age;
final double grade;

Student({required this.name, required this.age, required this.grade});
}

final List<Student> students = [
Student(name: 'Anna', age: 20, grade: 8.5),
Student(name: 'Brian', age: 22, grade: 6.7),
Student(name: 'Carla', age: 19, grade: 9.3),
Student(name: 'Daniel', age: 21, grade: 7.8),
Student(name: 'Eva', age: 23, grade: 5.9),
];
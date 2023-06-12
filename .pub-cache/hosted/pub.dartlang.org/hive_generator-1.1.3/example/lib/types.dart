import 'package:hive/hive.dart';

part 'types.g.dart';

@HiveType(typeId: 1)
class Class1 {
  const Class1(this.nested, [this.enum1]);

  @HiveField(
    0,
    defaultValue: Class2(
      4,
      'param',
      <int, Map<String, List<Class1>>>{
        5: <String, List<Class1>>{
          'magic': <Class1>[
            Class1(Class2(5, 'sad')),
            Class1(Class2(5, 'sad'), Enum1.emumValue1),
          ],
        },
        67: <String, List<Class1>>{
          'hold': <Class1>[
            Class1(Class2(42, 'meaning of life')),
          ],
        },
      },
    ),
  )
  final Class2 nested;

  final Enum1? enum1;
}

@HiveType(typeId: 2)
class Class2 {
  const Class2(this.param1, this.param2, [this.what]);

  @HiveField(0, defaultValue: 0)
  final int param1;

  @HiveField(1)
  final String param2;

  @HiveField(6)
  final Map<int, Map<String, List<Class1>>>? what;
}

@HiveType(typeId: 3)
enum Enum1 {
  @HiveField(0)
  emumValue1,

  @HiveField(1, defaultValue: true)
  emumValue2,

  @HiveField(2)
  emumValue3,
}

@HiveType(typeId: 4)
class EmptyClass {
  EmptyClass();
}

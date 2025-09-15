import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, List<double>> alunos;

  setUp(() {
    alunos = <String, List<double>>{
      'Maria': <double>[8.0, 9.0],
      'Bruna': <double>[7.0, 7.0],
      'Carla': <double>[10.0, 9.0],
    };
  });

  test('Adicionar elemento', () {
    alunos.putIfAbsent('Elena', () => <double>[9.0, 8.0]);
    expect(alunos.containsKey('Elena'), isTrue);
    expect(alunos['Elena'], <double>[9.0, 8.0]);
  });

  test('Adicionar outro dicionário', () {
    alunos.addAll(<String, List<double>>{
      'Elena': <double>[9.0, 8.0],
      'Luiza': <double>[8.0, 9.0],
    });
    expect(alunos.containsKey('Elena'), isTrue);
    expect(alunos.containsKey('Luiza'), isTrue);
  });

  test('Remover elemento', () {
    alunos.remove('Bruna');
    expect(alunos.containsKey('Bruna'), isFalse);
  });

  test('Atualizar elemento', () {
    alunos.update('Carla', (List<double> value) => <double>[9.0, 8.0]);
    expect(alunos['Carla'], <double>[9.0, 8.0]);
    alunos['Carla'] = <double>[8.0, 9.0];
    expect(alunos['Carla'], <double>[8.0, 9.0]);
  });

  test('Testar percorrer dicionário', () {
    alunos.addAll(<String, List<double>>{
      'Elena': <double>[9.0, 8.0],
      'Luiza': <double>[8.0, 9.0],
    });

    // Corrigido: convertemos keys para List
    expect(alunos.keys.toList(), <String>['Maria', 'Bruna', 'Carla', 'Elena', 'Luiza']);
    expect(alunos['Maria'], <double>[8.0, 9.0]);

    double soma = 0;
    alunos.forEach((String key, List<double> value) {
      for (final double nota in value) {
        soma += nota;
      }
    });

    expect(soma, 58.0); // 8+9 + 7+7 + 10+9 + 9+8 + 8+9
  });

  test('Calcular médias', () {
    alunos.addAll(<String, List<double>>{
      'Elena': <double>[9.0, 8.0],
      'Luiza': <double>[8.0, 9.0],
    });

    final Map<String, double> medias = <String, double>{};

    alunos.forEach((String key, List<double> value) {
      if (value.isEmpty) {
        medias[key] = 0;
      } else {
        double soma = 0;
        for (final double nota in value) {
          soma += nota;
        }
        medias[key] = soma / value.length;
      }
    });

    expect(medias, <String, double>{
      'Maria': 8.5,
      'Bruna': 7.0,
      'Carla': 9.5,
      'Elena': 8.5,
      'Luiza': 8.5,
    });
  });
}
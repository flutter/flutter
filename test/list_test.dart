import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<int> numeros;

  setUp(() {
    numeros = <int>[1, 2, 3];
  });

  test('Adicionar elemento', () {
    numeros.add(4);
    expect(numeros.contains(4), isTrue);
  });

  test('Adicionar outra lista', () {
    numeros.addAll(<int>[5, 6]);
    expect(numeros.contains(5), isTrue);
    expect(numeros.contains(6), isTrue);
  });

  test('Adicionar na posição', () {
    numeros.insert(0, 0);
    expect(numeros.indexOf(0), 0);
  });

  test('Remover elemento', () {
    numeros.remove(2);
    expect(numeros.contains(2), isFalse);
  });

  test('Remover na posição', () {
    numeros.removeAt(0);
    expect(numeros.contains(0), isFalse);
  });

  test('Testar tamanho', () {
    numeros.addAll(<int>[4, 5]);
    expect(numeros.length, 5);
  });

  test('Testar vazio e não vazio', () {
    expect(numeros.isEmpty, isFalse);
    expect(numeros.isNotEmpty, isTrue);
  });

  test('Testar ordenação', () {
    numeros.addAll(<int>[4, 5, 6]);
    expect(numeros.reversed.toList(), <int>[6, 5, 4, 3, 2, 1]);
    numeros.sort();
    expect(numeros, <int>[1, 2, 3, 4, 5, 6]);
  });

  test('Testar percorrer lista', () {
    int soma = 0;
    for (final int numero in numeros) {
      soma += numero;
    }
    expect(soma, 6);

    numeros = numeros.map((int numero) => numero * 2).toList();
    expect(numeros, <int>[2, 4, 6]);

    numeros = numeros.where((int numero) => numero % 3 == 0).toList();
    expect(numeros, <int>[6]);
  });
}
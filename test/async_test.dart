import 'package:flutter_test/flutter_test.dart';

Future<int> process() async {
  await Future.delayed(const Duration(seconds: 1));
  return 0;
}
Map<String, List<double>> alunos = <String, List<double>>{
  'Maria': <double>[8.0, 9.0],
  'Bruna': <double>[7.0, 7.0],
  'Carla': <double>[10.0, 9.0],
};

Future<List<double>?> search(String key) async {
  return Future.delayed(const Duration(milliseconds: 500), () {
    if (alunos.containsKey(key)) {
      return alunos[key]!;
    }
    throw ArgumentError('Aluno não encontrado.');
  });
}

Stream<int> count() async* {
  for (int i = 1; i <= 3; i++) {
    await Future.delayed(const Duration(milliseconds: 500));
    yield i;
  }
}

/// Stream que calcula a média das notas de cada aluno da lista
Stream<double> media(List<String> nomes) async* {
  for (final String nome in nomes) {
    try {
      final List<double>? notas = await search(nome);
      final double soma = notas!.reduce((double a, double b) => a + b);
      final double m = soma / notas.length;
      await Future.delayed(const Duration(milliseconds: 300)); // simula atraso
      yield m;
    } catch (e) {
      // Se não encontrar o aluno, lança erro no Stream
      rethrow;
    }
  }
}

void main() {
  group('Testes de programação assíncrona', () {
    late Future<int> result;

    setUp(() => result = process());

    test('Aguardando...', () => expect(result, isNotNull));

    test('Testando o resultado', () async {
      final int num = await result;
      expect(num, 0);
    });

    test('Testando busca sem erros em Future', () {
      search('Maria').then((List<double>? notas) => expect(notas, <double>[8.0, 9.0]));
    });

    test('Testando busca com erros em Future', () {
      search('Paula').then((List<double>? notas) {}).catchError((error) {
        expect(error, isA<ArgumentError>());
      });
    });

    test('Testando contagem em Stream', () async {
      final List<int> resultados = <int>[];
      await for (int valor in count()) {
        resultados.add(valor);
      }
      expect(resultados, <int>[1, 2, 3]);
    });

    test('Testando media em Stream', () async {
      final List<double> resultados = <double>[];
      try {
        await for (double m in media(<String>['Maria', 'Bruna'])) {
          resultados.add(m);
        }
      } catch (_) {
        // erro é esperado para alunos inexistentes
      }
      expect(resultados, <num>[8.5, 7]);
    });

    test('Testando media com aluno inexistente', () async {
      expectLater(
        media(<String>['Paula']),
        emitsError(isA<ArgumentError>()),
      );
    });
  });
}

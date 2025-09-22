import 'package:flutter_test/flutter_test.dart';

Future<int> process() async {
  await Future.delayed(Duration(seconds: 1));
  return 0;
}

Map<String, List<double>> alunos = {
  'Maria': [8.0, 9.0],
  'Bruna': [7.0, 7.0],
  'Carla': [10.0, 9.0],
};

Future<List<double>?> search(String key) async {
  return Future.delayed(Duration(milliseconds: 500), () {
    if (alunos.containsKey(key)) {
      return alunos[key]!;
    }
    throw ArgumentError('Aluno não encontrado.');
  });
}

Stream<int> count() async* {
  for (int i = 1; i <= 3; i++) {
    await Future.delayed(Duration(milliseconds: 500));
    yield i;
  }
}

/// Stream que calcula a média das notas de cada aluno da lista
Stream<double> media(List<String> nomes) async* {
  for (String nome in nomes) {
    try {
      List<double>? notas = await search(nome);
      double soma = notas!.reduce((a, b) => a + b);
      double m = soma / notas.length;
      await Future.delayed(Duration(milliseconds: 300)); // simula atraso
      yield m;
    } catch (e) {
      // Se não encontrar o aluno, lança erro no Stream
      throw e;
    }
  }
}

void main() {
  group('Testes de programação assíncrona', () {
    late Future<int> result;

    setUp(() => result = process());

    test('Aguardando...', () => expect(result, isNotNull));

    test('Testando o resultado', () async {
      int num = await result;
      expect(num, 0);
    });

    test('Testando busca sem erros em Future', () {
      search('Maria').then((notas) => expect(notas, [8.0, 9.0]));
    });

    test('Testando busca com erros em Future', () {
      search('Paula').then((notas) {}).catchError((error) {
        expect(error, isA<ArgumentError>());
      });
    });

    test('Testando contagem em Stream', () async {
      List<int> resultados = [];
      await for (var valor in count()) {
        resultados.add(valor);
      }
      expect(resultados, [1, 2, 3]);
    });

    test('Testando media em Stream', () async {
      List<double> resultados = [];
      try {
        await for (var m in media(['Maria', 'Bruna'])) {
          resultados.add(m);
        }
      } catch (_) {
        // erro é esperado para alunos inexistentes
      }
      expect(resultados, [8.5, 7]);
    });

    test('Testando media com aluno inexistente', () async {
      expectLater(
        media(['Paula']),
        emitsError(isA<ArgumentError>()),
      );
    });
  });
}

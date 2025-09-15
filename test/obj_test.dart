import 'package:flutter_test/flutter_test.dart';

abstract class Pessoa {

  Pessoa(this.nome);
  late int _id;
  String nome;

  int get id => _id;

  set id(int id) {
    if (id > 0) {
      _id = id;
    } else {
      throw ArgumentError('Identificador deve ser não negativo.');
    }
  }
}

mixin Ano {
  late int _ano;

  int get ano => _ano;

  set ano(int ano) {
    if (ano > 0) {
      _ano = ano;
    } else {
      throw ArgumentError('Ano deve ser não negativo.');
    }
  }
}

class Aluno extends Pessoa with Ano {
  Aluno(super.nome, int ano) {
    this.ano = ano;
  }
}

class Disciplina {
  Disciplina(this.nome);
  String nome;
}

class Turma with Ano {

  Turma(this.disciplina, int ano) {
    this.ano = ano;
  }
  Disciplina disciplina;
  final List<Aluno> _alunos = <Aluno>[];

  void matricular(Aluno aluno) {
    if (aluno.ano == ano) {
      _alunos.add(aluno);
    } else {
      throw ArgumentError('Ano deve ser mesmo.');
    }
  }
}

class Historico extends Turma {

  Historico(super.disciplina, super.ano);
  Map<Aluno, List<double>> notas = <Aluno, List<double>>{};

  @override
  void matricular(Aluno aluno) {
    super.matricular(aluno);
    notas[aluno] = <double>[];
  }

  double media(Aluno aluno) {
    double media = 0;
    for (final double nota in notas[aluno]!) {
      media += nota;
    }
    media /= notas.length;
    return media;
  }
}

void main() {
  test('Testar matrícula de alunos', () {
    final Disciplina disciplina1 = Disciplina('Flutter');
    final Historico historico1 = Historico(disciplina1, 2023);
    // Cadastrar primeiro aluno sem erros
    final Aluno aluno1 = Aluno('Maria', 2023);
    aluno1.id = 1;
    historico1.matricular(aluno1);
    expect(historico1.media(aluno1), 0.0);
    // Cadastrar segundo aluno com erros
    final Aluno aluno2 = Aluno('Paula', 2022);
    try {
      aluno2.id = 0;
    } catch (error) {
      expect(error, isA<ArgumentError>());
    }
    try {
      historico1.matricular(aluno2);
    } catch (error) {
      expect(error, isA<ArgumentError>());
    }
  });
}

class Professor extends Pessoa {
}

void void Turma(this.disciplina, this.professor, int ano) {

class Historico extends Turma {


bool isAprovado(Aluno aluno) {

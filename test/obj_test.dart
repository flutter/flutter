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

class Professor extends Pessoa {
  String especialidade;

  Professor(super.nome, this.especialidade);
}

class Disciplina {
  Disciplina(this.nome);
  String nome;
}

class Turma with Ano {

  Turma(this.disciplina, this.professor, int ano) {
    this.ano = ano;
  }
  Disciplina disciplina;
  Professor professor;
  final List<Aluno> _alunos = <Aluno>[];

  void matricular(Aluno aluno) {
    if (aluno.ano == ano) {
      _alunos.add(aluno);
    } else {
      throw ArgumentError('Ano deve ser o mesmo.');
    }
  }

  List<Aluno> get alunos => List.unmodifiable(_alunos);
}

class Historico extends Turma {
  final Map<Aluno, List<double>> notas = <Aluno, List<double>>{};

  Historico(super.disciplina, super.professor, super.ano);

  @override
  void matricular(Aluno aluno) {
    super.matricular(aluno);
    notas[aluno] = <double>[];
  }

  double media(Aluno aluno) {
    final List<double> notasAluno = notas[aluno] ?? <double>[];
    if (notasAluno.isEmpty) return 0.0;

    final double soma = notasAluno.reduce((double a, double b) => a + b);
    return soma / notasAluno.length;
  }

  bool isAprovado(Aluno aluno) {
    return media(aluno) >= 7.0;
  }
}

void main() {
  test('Testar matrícula e aprovação de alunos', () {
    final Disciplina disciplina1 = Disciplina('Flutter');
    final Professor professor1 = Professor('João', 'Mobile');
    final Historico historico1 = Historico(disciplina1, professor1, 2023);

    final Aluno aluno1 = Aluno('Maria', 2023);
    aluno1.id = 1;
    historico1.matricular(aluno1);
    expect(historico1.media(aluno1), 0.0);

    // adiciona notas
    historico1.notas[aluno1]!.addAll(<double>[8.0, 9.0]);
    expect(historico1.media(aluno1), 8.5);
    expect(historico1.isAprovado(aluno1), isTrue);

    // aluno errado
    final Aluno aluno2 = Aluno('Paula', 2022);
    try {
      historico1.matricular(aluno2);
    } catch (error) {
      expect(error, isA<ArgumentError>());
    }
  });
}

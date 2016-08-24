// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/cli/command.dart';
import 'package:test/test.dart';

class TestCommand extends Command {
  TestCommand(this.out, String name, [List<Command> children])
    : super(name, children);
  StringBuffer out;

  @override
  Future<Null> run(List<String> args) {
    out.write('executing $name($args)\n');
    return new Future<Null>.value(null);
  }
}

class TestCompleteCommand extends Command {
  TestCompleteCommand(this.out, String name, List<Command> children)
    : super(name, children);
  StringBuffer out;

  @override
  Future<List<String>> complete(List<String> args) {
    List<String> possibles = <String>['one ', 'two ', 'three '];
    return new Future<List<String>>.value(
        possibles.where((String possible) =>
          possible.startsWith(args[0])).toList());
  }

  @override
  Future<Null> run(List<String> args) {
    out.write('executing $name($args)\n');
    return new Future<Null>.value(null);
  }
}

void testCommandComplete() {
  RootCommand cmd =
      new RootCommand(<Command>[
        new TestCommand(null, 'alpha'),
        new TestCommand(null, 'game', <Command>[
          new TestCommand(null, 'checkers'),
          new TestCommand(null, 'chess')
        ]),
        new TestCommand(null, 'gamera', <Command>[
          new TestCommand(null, 'london'),
          new TestCommand(null, 'tokyo'),
          new TestCommand(null, 'topeka')
        ]),
        new TestCompleteCommand(null, 'count', <Command>[
          new TestCommand(null, 'chocula')])]);

  // Show all commands.
  cmd.completeCommand('').then((List<String> result) {
    expect(result, equals(<String>['alpha ', 'game ', 'gamera ', 'count ']));
  });

  // Substring completion.
  cmd.completeCommand('al').then((List<String> result) {
    expect(result, equals(<String>['alpha ']));
  });

  // Full string completion.
  cmd.completeCommand('alpha').then((List<String> result) {
    expect(result, equals(<String>['alpha ']));
  });

  // Extra space, no subcommands.
  cmd.completeCommand('alpha ').then((List<String> result) {
    expect(result, equals(<String>['alpha ']));
  });

  // Ambiguous completion.
  cmd.completeCommand('g').then((List<String> result) {
    expect(result, equals(<String>['game ', 'gamera ']));
  });

  // Ambiguous completion, exact match not preferred.
  cmd.completeCommand('game').then((List<String> result) {
    expect(result, equals(<String>['game ', 'gamera ']));
  });

  // Show all subcommands.
  cmd.completeCommand('gamera ').then((List<String> result) {
    expect(result, equals(
      <String>['gamera london ', 'gamera tokyo ', 'gamera topeka ']));
  });

  // Subcommand completion.
  cmd.completeCommand('gamera l').then((List<String> result) {
    expect(result, equals(<String>['gamera london ']));
  });

  // Extra space, with subcommand.
  cmd.completeCommand('gamera london ').then((List<String> result) {
    expect(result, equals(<String>['gamera london ']));
  });

  // Ambiguous subcommand completion.
  cmd.completeCommand('gamera t').then((List<String> result) {
    expect(result, equals(<String>['gamera tokyo ', 'gamera topeka ']));
  });

  // Ambiguous subcommand completion with substring prefix.
  // Note that the prefix is left alone.
  cmd.completeCommand('gamer t').then((List<String> result) {
    expect(result, equals(<String>['gamer tokyo ', 'gamer topeka ']));
  });

  // Ambiguous but exact prefix is preferred.
  cmd.completeCommand('game chec').then((List<String> result) {
    expect(result, equals(<String>['game checkers ']));
  });

  // Ambiguous non-exact prefix means no matches.
  cmd.completeCommand('gam chec').then((List<String> result) {
    expect(result, equals(<String>[]));
  });

  // Locals + subcommands, show all.
  cmd.completeCommand('count ').then((List<String> result) {
      expect(result, equals(<String>[
        'count chocula ',
        'count one ',
        'count two ',
        'count three '
      ]));
    });

  // Locals + subcommands, single local match.
  cmd.completeCommand('count th').then((List<String> result) {
    expect(result, equals(<String>['count three ']));
  });

  // Locals + subcommands, ambiguous local match.
  cmd.completeCommand('count t').then((List<String> result) {
    expect(result, equals(<String>['count two ', 'count three ']));
  });

  // Locals + subcommands, single command match.
  cmd.completeCommand('co choc').then((List<String> result) {
    expect(result, equals(<String>['co chocula ']));
  });

  // We gobble spare spaces in the prefix but not elsewhere.
  cmd.completeCommand('    game    chec').then((List<String> result) {
    expect(result, equals(<String>['game    checkers ']));
  });
}

void testCommandRunSimple() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd = new RootCommand(<Command>[new TestCommand(out, 'alpha')]);

  // Full name dispatch works.  Argument passing works.
  cmd.runCommand('alpha dog').then(expectAsync((_) {
      expect(out.toString(), contains('executing alpha([dog])\n'));
      out.clear();
      // Substring dispatch works.
      cmd.runCommand('al cat mouse').then(expectAsync((_) {
          expect(out.toString(), contains('executing alpha([cat , mouse])\n'));
      }));
  }));
}

void testCommandRunSubcommand() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd =
      new RootCommand(<Command>[
        new TestCommand(out, 'alpha', <Command>[
          new TestCommand(out, 'beta'),
          new TestCommand(out, 'gamma')])]);

  cmd.runCommand('a b').then(expectAsync((_) {
      expect(out.toString(), equals('executing beta([])\n'));
      out.clear();
      cmd.runCommand('alpha g ').then(expectAsync((_) {
          expect(out.toString(), equals('executing gamma([])\n'));
      }));
  }));
}

void testCommandRunNotFound() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd = new RootCommand(<Command>[new TestCommand(out, 'alpha')]);
  cmd.runCommand('goose').catchError(expectAsync((dynamic e) {
    expect(e.toString(), equals("No such command: 'goose'"));
  }));
}

void testCommandRunAmbiguous() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd = new RootCommand(<Command>[
    new TestCommand(out, 'alpha'),
    new TestCommand(out, 'ankle')]);

  cmd.runCommand('a 55').catchError(expectAsync((dynamic e) {
      expect(e.toString(),
             equals("Command 'a 55' is ambiguous: [alpha, ankle]"));
      out.clear();
      cmd.runCommand('ankl 55').then(expectAsync((_) {
          expect(out.toString(), equals('executing ankle([55])\n'));
      }));
  }));
}

void testCommandRunAlias() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  Command aliasCmd = new TestCommand(out, 'alpha');
  aliasCmd.alias = 'a';
  RootCommand cmd = new RootCommand(<Command>[
    aliasCmd,
    new TestCommand(out, 'ankle')]);

  cmd.runCommand('a 55').then(expectAsync((_) {
    expect(out.toString(), equals('executing alpha([55])\n'));
  }));
}

void main() {
  test('command completion test suite', testCommandComplete);
  test('run a simple command', testCommandRunSimple);
  test('run a subcommand', testCommandRunSubcommand);
  test('run a command which is not found', testCommandRunNotFound);
  test('run a command which is ambiguous', testCommandRunAmbiguous);
  test('run a command using an alias', testCommandRunAlias);
}

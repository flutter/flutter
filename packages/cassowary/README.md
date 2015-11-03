Cassowary in Dart
=================

This is an implementation of the Cassowary constraint solving algorithm in Dart. The initial implementation was based on the [Kiwi toolkit](https://github.com/nucleic/kiwi) written in C++. Implements a subset of the functionality described in the [Cassowary paper](https://constraints.cs.washington.edu/solvers/cassowary-tochi.pdf) and makes specific affordances for the needs of [Flutter](http://flutter.io/)

# The Solver
A solver is the object that accepts constraints and updates member variables in an attempt to satisfy the same. It is rarely the case that the user will have to create a solver. Instead, one will be vended by Flutter.

# Parameters
In order to create constraints, the user needs to take specific parameter objects vended by elements in the view hierarchy and create expression from these. Constraints can then be obtained from these expressions. If the solver needs to update these parameters to satisfy constraints, it will invoke callbacks on these parameters.

# Constructing Constraints

A constraint is a linear equation of the form `ax + by + cz + ... + k == 0`. Constraints need not be equality relationships. Less/greater-than-or-equal-to (`<=` or `>=`) relationships can also be specified. In addition, each constraint is specified at a given priority to help resolve constraint ambiguities. A system can also be overconstrained.

The constraint as a whole is represented by an instance of the `Constraint` object. This in turn references an instance of an `Expression` (`ax + by + cz + ... k`), a realtionship and the finally the priority.

Each expression in turn is made up of a list of `Term`s and a constant. The term `ax` has the coefficient `a` and `Variable` `x`. The `Param` that is vended to the user is nothing but a wrapper for this variable and deals with detecting changes to it and updating the underlying view in the hierarchy.

Once the user obtains specific parameter objects, it is straightforward to create constraints. The following example sets up constraints that specify that the width of the element must be at least 100 units. It is assumed that the `left` and `right` `Param` objects have been obtained from the view in question.

```
Constraint widthAtLeast100 = right - left >= CM(100.0)
```

Lets go over this one step at a time: The expression `right - left` creates an instance of an `Expression` object. The expression consists of two terms. The `right` and `left` params wrap variables. The coefficients are 1.0 and -1.0 respectively and the constant -100.0. Constants need to be decorated with `CM` to aid with the operator overloading mechanism in Dart.

All variables are unrestricted. So there is nothing preventing the solver from making the left and right edges negative. We can specify our preference against this by specifying another constraint like so:

```
Constraint edgesPositive = (left >= CM(0.0))
```

When we construct these constraints for the solver, they are created at the default `Priority.required`. This means that the solver will resist adding constraints where there are ambiguities between two required constraints. To specify a weaker priority, you can use the `priority` setter or use the `|` symbol with the priority while constructing the constraint. Like so:

```
Constraint edgesPositive = (left >= CM(0.0) | Priority.weak)
```

Once the set of constraints are constructed, they are added to the solver and the results of the solution flushed out.

```
solver.addConstraints([widthAtLeast100, edgesPositive])
     ..flushVariableUpdates();
```

# Edit Constraints

When updates need to be applied to parameters that are a part of the solver, edit variables may be used. To illustrate this, we try to express the following case in terms of constraints and their update: On mouse down, we want to update the midpoint of our view and have the `left` and `right` parameters automatically updated (subject to the constraints already setup).

We create a parameter that we will use to represent the mouse coordinate.

```
Param mid = new Param(coordinate);
```

Then, we add a constraint that expresses the midpoint in terms of the parameters we already have.

```
solver.addConstraint(left + right == mid * CM(2.0));
```

Then, we specify that we intend to edit the midpoint. As we get updates, we tell the solver to satisfy all other constraints (admittedly our example is trivial).

```
solver.addEditVariable(mid, Priority.strong);
```

and finally

```
solver.flushVariableUpdates();
```

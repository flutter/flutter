#### 3.0.0

* Migrate to null safety.

#### 2.2.0

* Change dependency on `package:test_api` back to `package:test`.

#### 2.1.0

* Changed dependency on `package:test` to `package:test_api`
* Bumped Dart SDK constraint to match `package:test_api`'s requirements
* Updated style to match latest lint rules from Flutter repo.

#### 2.0.3

* Relaxed constraints on `package:test`

#### 2.0.2

* Bumped dependency on `package:test` to version 1.0

#### 2.0.1

* Bumped Dart SDK constraint to allow for Dart 2 stable

#### 2.0.0

* Removed `record_replay_matchers.dart` from API

#### 1.0.0

* Moved `package:file/testing.dart` library into a dedicated package so that
  libraries don't need to take on a transitive dependency on `package:test`
  in order to use `package:file`.

import 'dart:developer';

void main() {
  for (int i = 1; i <= 10; ++i) {
    log(i.toString());
  }
  debugger();
  for (int i = 11; i <= 20; ++i) {
    log(i.toString());
  }
  debugger();
}

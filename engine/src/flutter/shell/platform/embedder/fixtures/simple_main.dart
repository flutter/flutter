void main() {}

@pragma('vm:entry-point')
void customEntrypoint() {
  sayHiFromCustomEntrypoint();
}

void sayHiFromCustomEntrypoint() native "SayHiFromCustomEntrypoint";


@pragma('vm:entry-point')
void customEntrypoint1() {
  sayHiFromCustomEntrypoint1();
  sayHiFromCustomEntrypoint2();
  sayHiFromCustomEntrypoint3();
}

void sayHiFromCustomEntrypoint1() native "SayHiFromCustomEntrypoint1";
void sayHiFromCustomEntrypoint2() native "SayHiFromCustomEntrypoint2";
void sayHiFromCustomEntrypoint3() native "SayHiFromCustomEntrypoint3";

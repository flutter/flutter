void main() {}

@pragma('vm:entry-point')
void customEntrypoint() {
  sayHiFromCustomEntrypoint();
}

void sayHiFromCustomEntrypoint() native "SayHiFromCustomEntrypoint";

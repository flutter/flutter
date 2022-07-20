import 'framework.dart';

abstract class Breakpoint {
  const Breakpoint();
  bool isActive(BuildContext context);
}

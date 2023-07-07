import '_app.dart' as app;
import '_menu.dart' as menu;
import '_tray.dart' as tray;
import '_window.dart' as window;

void main() {
  final hWnd = window.createHidden();
  tray.addIcon(hWndParent: hWnd);
  app.registerWndProc(menu.wndProc);
  app.exec();
}

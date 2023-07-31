// COM interfaces have a chain of inheritance, and the function vtable depends
// on this being calculated accurately. Test a variety of existing interfaces to
// make sure the algorithm matches a manual count.

@TestOn('windows')

import 'package:test/test.dart';
import 'package:winmd/winmd.dart';

import '../tool/projection/com_interface.dart';
import '../tool/projection/winrt_interface.dart';

void main() {
  test('vTableStart for COM types', () {
    const testedTypes = <String, int>{
      'Windows.Win32.Globalization.IEnumSpellingError': 3,
      'Windows.Win32.Globalization.ISpellChecker': 3,
      'Windows.Win32.Globalization.ISpellCheckerChangedEventHandler': 3,
      'Windows.Win32.Globalization.ISpellCheckerFactory': 3,
      'Windows.Win32.Globalization.ISpellingError': 3,
      'Windows.Win32.Networking.NetworkListManager.IEnumNetworkConnections': 7,
      'Windows.Win32.Networking.NetworkListManager.IEnumNetworks': 7,
      'Windows.Win32.Networking.NetworkListManager.INetwork': 7,
      'Windows.Win32.Networking.NetworkListManager.INetworkConnection': 7,
      'Windows.Win32.Networking.NetworkListManager.INetworkListManager': 7,
      'Windows.Win32.System.Com.IBindCtx': 3,
      'Windows.Win32.System.Com.IClassFactory': 3,
      'Windows.Win32.System.Com.IDispatch': 3,
      'Windows.Win32.System.Com.IEnumMoniker': 3,
      'Windows.Win32.System.Com.IEnumString': 3,
      'Windows.Win32.System.Com.IErrorInfo': 3,
      'Windows.Win32.System.Com.IMoniker': 8,
      'Windows.Win32.System.Com.IPersist': 3,
      'Windows.Win32.System.Com.IPersistStream': 4,
      'Windows.Win32.System.Com.IRunningObjectTable': 3,
      'Windows.Win32.System.Com.ISequentialStream': 3,
      'Windows.Win32.System.Com.IStream': 5,
      'Windows.Win32.System.Ole.IEnumVARIANT': 3,
      'Windows.Win32.System.Ole.IProvideClassInfo': 3,
      'Windows.Win32.System.Com.ISupportErrorInfo': 3,
      'Windows.Win32.System.WinRT.IInspectable': 3,
      'Windows.Win32.System.Wmi.IEnumWbemClassObject': 3,
      'Windows.Win32.System.Wmi.IWbemClassObject': 3,
      'Windows.Win32.System.Wmi.IWbemContext': 3,
      'Windows.Win32.System.Wmi.IWbemLocator': 3,
      'Windows.Win32.System.Wmi.IWbemServices': 3,
      'Windows.Win32.UI.Shell.IApplicationActivationManager': 3,
      'Windows.Win32.UI.Shell.IDesktopWallpaper': 3,
      'Windows.Win32.UI.Shell.IEnumIDList': 3,
      'Windows.Win32.UI.Shell.IFileDialog': 4,
      'Windows.Win32.UI.Shell.IFileDialog2': 27,
      'Windows.Win32.UI.Shell.IFileDialogCustomize': 3,
      'Windows.Win32.UI.Shell.IFileIsInUse': 3,
      'Windows.Win32.UI.Shell.IFileOpenDialog': 27,
      'Windows.Win32.UI.Shell.IFileSaveDialog': 27,
      'Windows.Win32.UI.Shell.IKnownFolder': 3,
      'Windows.Win32.UI.Shell.IKnownFolderManager': 3,
      'Windows.Win32.UI.Shell.IModalWindow': 3,
      'Windows.Win32.UI.Shell.IShellFolder': 3,
      'Windows.Win32.UI.Shell.IShellItem': 3,
      'Windows.Win32.UI.Shell.IShellItem2': 8,
      'Windows.Win32.UI.Shell.IShellItemArray': 3,
      'Windows.Win32.UI.Shell.IShellItemFilter': 3,
    };

    final scope = MetadataStore.getWin32Scope();

    for (final type in testedTypes.keys) {
      final typeDef = scope.findTypeDef(type);
      expect(typeDef, isNotNull, reason: type);
      if (typeDef != null) {
        final projectedClass = ComInterfaceProjection(typeDef);
        final calculatedVTableStart = projectedClass.vtableStart;

        expect(calculatedVTableStart, equals(testedTypes[type]),
            reason: typeDef.name);
      }
    }
  });

  test('vTableStart for Windows Runtime types', () {
    const testedTypes = <String, int>{
      'Windows.Globalization.ICalendar': 6,
      'Windows.Foundation.IAsyncInfo': 6,
      'Windows.Foundation.IAsyncAction': 6,
      'Windows.Foundation.Collections.IPropertySet': 6
    };

    for (final type in testedTypes.keys) {
      final scope = MetadataStore.getScopeForType(type);
      final typeDef = scope.findTypeDef(type);
      expect(typeDef, isNotNull);
      if (typeDef != null) {
        final projectedClass = WinRTInterfaceProjection(typeDef);
        final calculatedVTableStart = projectedClass.vtableStart;

        expect(calculatedVTableStart, equals(testedTypes[type]),
            reason: typeDef.name);
      }
    }
  });
}

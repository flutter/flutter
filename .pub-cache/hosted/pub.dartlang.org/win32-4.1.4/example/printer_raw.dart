// Sends RAW data (string or hex sequences) directly to the printer

// Example taken from:
// https://docs.microsoft.com/en-us/windows/win32/printdocs/sending-data-directly-to-a-printer

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class RawPrinter {
  final String printerName;
  final Arena alloc;

  RawPrinter(this.printerName, this.alloc);

  Pointer<HANDLE> _startRawPrintJob(
      {required String printerName,
      required String documentTitle,
      String dataType = 'RAW'}) {
    final pPrinterName = printerName.toNativeUtf16(allocator: alloc);
    final phPrinter = alloc<HANDLE>();

    // https://docs.microsoft.com/en-us/windows/win32/printdocs/openprinter
    var fSuccess = OpenPrinter(pPrinterName, phPrinter, nullptr);
    if (fSuccess == 0) {
      final error = GetLastError();
      throw Exception('OpenPrint error, status: $fSuccess, error: $error');
    }

    // https://docs.microsoft.com/en-us/windows/win32/printdocs/doc-info-1
    final pDocInfo = alloc<DOC_INFO_1>()
      ..ref.pDocName = printerName.toNativeUtf16(allocator: alloc)
      ..ref.pDatatype =
          dataType.toNativeUtf16(allocator: alloc) // RAW, TEXT or XPS_PASS
      ..ref.pOutputFile = nullptr;

    //https://docs.microsoft.com/en-us/windows/win32/printdocs/startdocprinter
    fSuccess = StartDocPrinter(
        phPrinter.value,
        1, // Version of the structure to which pDocInfo points.
        pDocInfo);
    if (fSuccess == 0) {
      final error = GetLastError();
      throw Exception(
          'StartDocPrinter error, status: $fSuccess, error: $error');
    }

    return phPrinter;
  }

  bool _startRawPrintPage(Pointer<HANDLE> phPrinter) {
    //https://docs.microsoft.com/en-us/windows/win32/printdocs/startpageprinter
    return StartPagePrinter(phPrinter.value) != 0;
  }

  bool _endRawPrintPage(Pointer<HANDLE> phPrinter) {
    return EndPagePrinter(phPrinter.value) != 0;
  }

  bool _endRawPrintJob(Pointer<HANDLE> phPrinter) {
    return EndDocPrinter(phPrinter.value) > 0 &&
        ClosePrinter(phPrinter.value) != 0;
  }

  bool _printRawData(Pointer<HANDLE> phPrinter, String dataToPrint) {
    final cWritten = alloc<DWORD>();
    final data = dataToPrint.toNativeUtf8(allocator: alloc);

    // https://docs.microsoft.com/en-us/windows/win32/printdocs/writeprinter
    final result =
        WritePrinter(phPrinter.value, data, dataToPrint.length, cWritten);

    if (dataToPrint.length != cWritten.value) {
      final error = GetLastError();
      throw Exception('WritePrinter error, status: $result, error: $error');
    }

    return result != 0;
  }

  bool printLines(List<String> data) {
    var res = false;

    if (data.isEmpty) {
      return res;
    }

    final printerHandle = _startRawPrintJob(
        printerName: printerName,
        documentTitle: 'My document',
        dataType: 'RAW');

    res = _startRawPrintPage(printerHandle);

    for (final item in data) {
      if (res) {
        res = _printRawData(printerHandle, item);
      }
    }
    _endRawPrintPage(printerHandle);
    _endRawPrintJob(printerHandle);

    return res;
  }
}

void main() {
  // Example: ESC/POS sequence to open the cash drawer
  const openCashDrawer = '\x1b\x70\x00';

  using((Arena alloc) {
    // NOTE: You can get the printer name from the printer_list.dart example
    final printer = RawPrinter('EPSON TM-T20II Receipt', alloc);

    // At the end we send a printer command to open the cash drawer
    // for example for thermal printers using ESC/POS
    final data = <String>[
      for (var i = 0; i < 10; i++) 'Hello world line $i',
      openCashDrawer
    ];

    // Send to print all the lines at once
    if (printer.printLines(data)) {
      print('Success!');
    }
  });
}

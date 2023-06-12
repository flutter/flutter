// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common structs used in the Win32 API.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: camel_case_extensions, camel_case_types
// ignore_for_file: directives_ordering, unnecessary_getters_setters
// ignore_for_file: unused_field
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'callbacks.dart';
import 'combase.dart';
import 'guid.dart';
import 'variant.dart';

/// Defines an accelerator key used in an accelerator table.
///
/// {@category Struct}
class ACCEL extends Struct {
  @Uint8()
  external int fVirt;

  @Uint16()
  external int key;

  @Uint16()
  external int cmd;
}

/// The ACL structure is the header of an access control list (ACL). A
/// complete ACL consists of an ACL structure followed by an ordered list of
/// zero or more access control entries (ACEs).
///
/// {@category Struct}
class ACL extends Struct {
  @Uint8()
  external int AclRevision;

  @Uint8()
  external int Sbz1;

  @Uint16()
  external int AclSize;

  @Uint16()
  external int AceCount;

  @Uint16()
  external int Sbz2;
}

/// The ACTCTX structure is used by the CreateActCtx function to create the
/// activation context.
///
/// {@category Struct}
class ACTCTX extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int dwFlags;

  external Pointer<Utf16> lpSource;

  @Uint16()
  external int wProcessorArchitecture;

  @Uint16()
  external int wLangId;

  external Pointer<Utf16> lpAssemblyDirectory;

  external Pointer<Utf16> lpResourceName;

  external Pointer<Utf16> lpApplicationName;

  @IntPtr()
  external int hModule;
}

/// The ADDJOB_INFO_1 structure identifies a print job as well as the
/// directory and file in which an application can store that job.
///
/// {@category Struct}
class ADDJOB_INFO_1 extends Struct {
  external Pointer<Utf16> Path;

  @Uint32()
  external int JobId;
}

/// The addrinfoW structure is used by the GetAddrInfoW function to hold
/// host address information.
///
/// {@category Struct}
class ADDRINFO extends Struct {
  @Int32()
  external int ai_flags;

  @Int32()
  external int ai_family;

  @Int32()
  external int ai_socktype;

  @Int32()
  external int ai_protocol;

  @IntPtr()
  external int ai_addrlen;

  external Pointer<Utf16> ai_canonname;

  external Pointer<SOCKADDR> ai_addr;

  external Pointer<ADDRINFO> ai_next;
}

/// Contains status information for the application-switching (ALT+TAB)
/// window.
///
/// {@category Struct}
class ALTTABINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Int32()
  external int cItems;

  @Int32()
  external int cColumns;

  @Int32()
  external int cRows;

  @Int32()
  external int iColFocus;

  @Int32()
  external int iRowFocus;

  @Int32()
  external int cxItem;

  @Int32()
  external int cyItem;

  external POINT ptStart;
}

/// Represents package settings used to create a package.
///
/// {@category Struct}
class APPX_PACKAGE_SETTINGS extends Struct {
  @Int32()
  external int forceZip32;

  external Pointer<COMObject> hashMethod;
}

/// Describes an array, its element type, and its dimension.
///
/// {@category Struct}
class ARRAYDESC extends Struct {
  external TYPEDESC tdescElem;

  @Uint16()
  external int cDims;

  @Array(1)
  external Array<SAFEARRAYBOUND> rgbounds;
}

/// Contains parameters used during a moniker-binding operation.
///
/// {@category Struct}
class BIND_OPTS extends Struct {
  @Uint32()
  external int cbStruct;

  @Uint32()
  external int grfFlags;

  @Uint32()
  external int grfMode;

  @Uint32()
  external int dwTickCountDeadline;
}

/// The BITMAP structure defines the type, width, height, color format, and
/// bit values of a bitmap.
///
/// {@category Struct}
class BITMAP extends Struct {
  @Int32()
  external int bmType;

  @Int32()
  external int bmWidth;

  @Int32()
  external int bmHeight;

  @Int32()
  external int bmWidthBytes;

  @Uint16()
  external int bmPlanes;

  @Uint16()
  external int bmBitsPixel;

  external Pointer bmBits;
}

/// The BITMAPFILEHEADER structure contains information about the type,
/// size, and layout of a file that contains a DIB.
///
/// {@category Struct}
@Packed(2)
class BITMAPFILEHEADER extends Struct {
  @Uint16()
  external int bfType;

  @Uint32()
  external int bfSize;

  @Uint16()
  external int bfReserved1;

  @Uint16()
  external int bfReserved2;

  @Uint32()
  external int bfOffBits;
}

/// The BITMAPINFO structure defines the dimensions and color information
/// for a device-independent bitmap (DIB).
///
/// {@category Struct}
class BITMAPINFO extends Struct {
  external BITMAPINFOHEADER bmiHeader;

  @Array(1)
  external Array<RGBQUAD> bmiColors;
}

/// The BITMAPINFOHEADER structure contains information about the dimensions
/// and color format of a device-independent bitmap (DIB).
///
/// {@category Struct}
class BITMAPINFOHEADER extends Struct {
  @Uint32()
  external int biSize;

  @Int32()
  external int biWidth;

  @Int32()
  external int biHeight;

  @Uint16()
  external int biPlanes;

  @Uint16()
  external int biBitCount;

  @Int32()
  external int biCompression;

  @Uint32()
  external int biSizeImage;

  @Int32()
  external int biXPelsPerMeter;

  @Int32()
  external int biYPelsPerMeter;

  @Uint32()
  external int biClrUsed;

  @Uint32()
  external int biClrImportant;
}

/// The BLENDFUNCTION structure controls blending by specifying the blending
/// functions for source and destination bitmaps.
///
/// {@category Struct}
class BLENDFUNCTION extends Struct {
  @Uint8()
  external int BlendOp;

  @Uint8()
  external int BlendFlags;

  @Uint8()
  external int SourceConstantAlpha;

  @Uint8()
  external int AlphaFormat;
}

/// The BLUETOOTH_ADDRESS structure provides the address of a Bluetooth
/// device.
///
/// {@category Struct}
class BLUETOOTH_ADDRESS extends Struct {
  external _BLUETOOTH_ADDRESS__Anonymous_e__Union Anonymous;
}

/// {@category Struct}
class _BLUETOOTH_ADDRESS__Anonymous_e__Union extends Union {
  @Uint64()
  external int ullLong;

  @Array(6)
  external Array<Uint8> rgBytes;
}

extension BLUETOOTH_ADDRESS_Extension on BLUETOOTH_ADDRESS {
  int get ullLong => this.Anonymous.ullLong;
  set ullLong(int value) => this.Anonymous.ullLong = value;

  Array<Uint8> get rgBytes => this.Anonymous.rgBytes;
  set rgBytes(Array<Uint8> value) => this.Anonymous.rgBytes = value;
}

/// The BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS structure contains specific
/// configuration information about the Bluetooth device responding to an
/// authentication request.
///
/// {@category Struct}
class BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS extends Struct {
  external BLUETOOTH_DEVICE_INFO deviceInfo;

  @Int32()
  external int authenticationMethod;

  @Int32()
  external int ioCapability;

  @Int32()
  external int authenticationRequirements;

  external _BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS__Anonymous_e__Union
      Anonymous;
}

/// {@category Struct}
class _BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS__Anonymous_e__Union
    extends Union {
  @Uint32()
  external int Numeric_Value;

  @Uint32()
  external int Passkey;
}

extension BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS_Extension
    on BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS {
  int get Numeric_Value => this.Anonymous.Numeric_Value;
  set Numeric_Value(int value) => this.Anonymous.Numeric_Value = value;

  int get Passkey => this.Anonymous.Passkey;
  set Passkey(int value) => this.Anonymous.Passkey = value;
}

/// The BLUETOOTH_DEVICE_INFO structure provides information about a
/// Bluetooth device.
///
/// {@category Struct}
class BLUETOOTH_DEVICE_INFO extends Struct {
  @Uint32()
  external int dwSize;

  external BLUETOOTH_ADDRESS Address;

  @Uint32()
  external int ulClassofDevice;

  @Int32()
  external int fConnected;

  @Int32()
  external int fRemembered;

  @Int32()
  external int fAuthenticated;

  external SYSTEMTIME stLastSeen;

  external SYSTEMTIME stLastUsed;

  @Array(248)
  external Array<Uint16> _szName;

  String get szName {
    final charCodes = <int>[];
    for (var i = 0; i < 248; i++) {
      if (_szName[i] == 0x00) break;
      charCodes.add(_szName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szName(String value) {
    final stringToStore = value.padRight(248, '\x00');
    for (var i = 0; i < 248; i++) {
      _szName[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// The BLUETOOTH_DEVICE_SEARCH_PARAMS structure specifies search criteria
/// for Bluetooth device searches.
///
/// {@category Struct}
class BLUETOOTH_DEVICE_SEARCH_PARAMS extends Struct {
  @Uint32()
  external int dwSize;

  @Int32()
  external int fReturnAuthenticated;

  @Int32()
  external int fReturnRemembered;

  @Int32()
  external int fReturnUnknown;

  @Int32()
  external int fReturnConnected;

  @Int32()
  external int fIssueInquiry;

  @Uint8()
  external int cTimeoutMultiplier;

  @IntPtr()
  external int hRadio;
}

/// The BLUETOOTH_FIND_RADIO_PARAMS structure facilitates enumerating
/// installed Bluetooth radios.
///
/// {@category Struct}
class BLUETOOTH_FIND_RADIO_PARAMS extends Struct {
  @Uint32()
  external int dwSize;
}

/// The BLUETOOTH_GATT_VALUE_CHANGED_EVENT structure describes a changed
/// attribute value.
///
/// {@category Struct}
class BLUETOOTH_GATT_VALUE_CHANGED_EVENT extends Struct {
  @Uint16()
  external int ChangedAttributeHandle;

  @IntPtr()
  external int CharacteristicValueDataSize;

  external Pointer<BTH_LE_GATT_CHARACTERISTIC_VALUE> CharacteristicValue;
}

/// The BLUETOOTH_GATT_VALUE_CHANGED_EVENT_REGISTRATION structure describes
/// one or more characteristics that have changed.
///
/// {@category Struct}
class BLUETOOTH_GATT_VALUE_CHANGED_EVENT_REGISTRATION extends Struct {
  @Uint16()
  external int NumCharacteristics;

  @Array(1)
  external Array<BTH_LE_GATT_CHARACTERISTIC> Characteristics;
}

/// The BLUETOOTH_OOB_DATA_INFO structure contains data used to authenticate
/// prior to establishing an Out-of-Band device pairing.
///
/// {@category Struct}
class BLUETOOTH_OOB_DATA_INFO extends Struct {
  @Array(16)
  external Array<Uint8> C;

  @Array(16)
  external Array<Uint8> R;
}

/// The BLUETOOTH_PIN_INFO structure contains information used for
/// authentication via PIN.
///
/// {@category Struct}
class BLUETOOTH_PIN_INFO extends Struct {
  @Array(16)
  external Array<Uint8> pin;

  @Uint8()
  external int pinLength;
}

/// The BLUETOOTH_RADIO_INFO structure provides information about a
/// Bluetooth radio.
///
/// {@category Struct}
class BLUETOOTH_RADIO_INFO extends Struct {
  @Uint32()
  external int dwSize;

  external BLUETOOTH_ADDRESS address;

  @Array(248)
  external Array<Uint16> _szName;

  String get szName {
    final charCodes = <int>[];
    for (var i = 0; i < 248; i++) {
      if (_szName[i] == 0x00) break;
      charCodes.add(_szName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szName(String value) {
    final stringToStore = value.padRight(248, '\x00');
    for (var i = 0; i < 248; i++) {
      _szName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint32()
  external int ulClassofDevice;

  @Uint16()
  external int lmpSubversion;

  @Uint16()
  external int manufacturer;
}

/// Contains information about a window that denied a request from
/// BroadcastSystemMessageEx.
///
/// {@category Struct}
class BSMINFO extends Struct {
  @Uint32()
  external int cbSize;

  @IntPtr()
  external int hdesk;

  @IntPtr()
  external int hwnd;

  external LUID luid;
}

/// The BTH_LE_GATT_CHARACTERISTIC structure describes a Bluetooth Low
/// Energy (LE) generic attribute (GATT) profile characteristic.
///
/// {@category Struct}
class BTH_LE_GATT_CHARACTERISTIC extends Struct {
  @Uint16()
  external int ServiceHandle;

  external BTH_LE_UUID CharacteristicUuid;

  @Uint16()
  external int AttributeHandle;

  @Uint16()
  external int CharacteristicValueHandle;

  @Uint8()
  external int IsBroadcastable;

  @Uint8()
  external int IsReadable;

  @Uint8()
  external int IsWritable;

  @Uint8()
  external int IsWritableWithoutResponse;

  @Uint8()
  external int IsSignedWritable;

  @Uint8()
  external int IsNotifiable;

  @Uint8()
  external int IsIndicatable;

  @Uint8()
  external int HasExtendedProperties;
}

/// The BTH_LE_GATT_CHARACTERISTIC_VALUE structure describes a Bluetooth Low
/// Energy (LE) generic attribute (GATT) profile characteristic value.
///
/// {@category Struct}
class BTH_LE_GATT_CHARACTERISTIC_VALUE extends Struct {
  @Uint32()
  external int DataSize;

  @Array(1)
  external Array<Uint8> Data;
}

/// The BTH_LE_GATT_DESCRIPTOR structure describes a Bluetooth Low Energy
/// (LE) generic attribute (GATT) profile descriptor.
///
/// {@category Struct}
class BTH_LE_GATT_DESCRIPTOR extends Struct {
  @Uint16()
  external int ServiceHandle;

  @Uint16()
  external int CharacteristicHandle;

  @Int32()
  external int DescriptorType;

  external BTH_LE_UUID DescriptorUuid;

  @Uint16()
  external int AttributeHandle;
}

/// The BTH_LE_GATT_DESCRIPTOR_VALUE structure describes a parent
/// characteristic.
///
/// {@category Struct}
class BTH_LE_GATT_DESCRIPTOR_VALUE extends Struct {
  @Int32()
  external int DescriptorType;

  external BTH_LE_UUID DescriptorUuid;

  external _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union Anonymous;

  @Uint32()
  external int DataSize;

  @Array(1)
  external Array<Uint8> Data;
}

/// {@category Struct}
class _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union extends Union {
  external _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__CharacteristicExtendedProperties_e__Struct
      CharacteristicExtendedProperties;

  external _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__ClientCharacteristicConfiguration_e__Struct
      ClientCharacteristicConfiguration;

  external _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__ServerCharacteristicConfiguration_e__Struct
      ServerCharacteristicConfiguration;

  external _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__CharacteristicFormat_e__Struct
      CharacteristicFormat;
}

/// {@category Struct}
class _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__CharacteristicExtendedProperties_e__Struct
    extends Struct {
  @Uint8()
  external int IsReliableWriteEnabled;

  @Uint8()
  external int IsAuxiliariesWritable;
}

extension BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union_Extension
    on BTH_LE_GATT_DESCRIPTOR_VALUE {
  int get IsReliableWriteEnabled =>
      this.Anonymous.CharacteristicExtendedProperties.IsReliableWriteEnabled;
  set IsReliableWriteEnabled(int value) =>
      this.Anonymous.CharacteristicExtendedProperties.IsReliableWriteEnabled =
          value;

  int get IsAuxiliariesWritable =>
      this.Anonymous.CharacteristicExtendedProperties.IsAuxiliariesWritable;
  set IsAuxiliariesWritable(int value) =>
      this.Anonymous.CharacteristicExtendedProperties.IsAuxiliariesWritable =
          value;
}

/// {@category Struct}
class _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__ClientCharacteristicConfiguration_e__Struct
    extends Struct {
  @Uint8()
  external int IsSubscribeToNotification;

  @Uint8()
  external int IsSubscribeToIndication;
}

extension BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union_Extension_1
    on BTH_LE_GATT_DESCRIPTOR_VALUE {
  int get IsSubscribeToNotification => this
      .Anonymous
      .ClientCharacteristicConfiguration
      .IsSubscribeToNotification;
  set IsSubscribeToNotification(int value) => this
      .Anonymous
      .ClientCharacteristicConfiguration
      .IsSubscribeToNotification = value;

  int get IsSubscribeToIndication =>
      this.Anonymous.ClientCharacteristicConfiguration.IsSubscribeToIndication;
  set IsSubscribeToIndication(int value) =>
      this.Anonymous.ClientCharacteristicConfiguration.IsSubscribeToIndication =
          value;
}

/// {@category Struct}
class _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__ServerCharacteristicConfiguration_e__Struct
    extends Struct {
  @Uint8()
  external int IsBroadcast;
}

extension BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union_Extension_2
    on BTH_LE_GATT_DESCRIPTOR_VALUE {
  int get IsBroadcast =>
      this.Anonymous.ServerCharacteristicConfiguration.IsBroadcast;
  set IsBroadcast(int value) =>
      this.Anonymous.ServerCharacteristicConfiguration.IsBroadcast = value;
}

/// {@category Struct}
class _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__CharacteristicFormat_e__Struct
    extends Struct {
  @Uint8()
  external int Format;

  @Uint8()
  external int Exponent;

  external BTH_LE_UUID Unit;

  @Uint8()
  external int NameSpace;

  external BTH_LE_UUID Description;
}

extension BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union_Extension_3
    on BTH_LE_GATT_DESCRIPTOR_VALUE {
  int get Format => this.Anonymous.CharacteristicFormat.Format;
  set Format(int value) => this.Anonymous.CharacteristicFormat.Format = value;

  int get Exponent => this.Anonymous.CharacteristicFormat.Exponent;
  set Exponent(int value) =>
      this.Anonymous.CharacteristicFormat.Exponent = value;

  BTH_LE_UUID get Unit => this.Anonymous.CharacteristicFormat.Unit;
  set Unit(BTH_LE_UUID value) =>
      this.Anonymous.CharacteristicFormat.Unit = value;

  int get NameSpace => this.Anonymous.CharacteristicFormat.NameSpace;
  set NameSpace(int value) =>
      this.Anonymous.CharacteristicFormat.NameSpace = value;

  BTH_LE_UUID get Description =>
      this.Anonymous.CharacteristicFormat.Description;
  set Description(BTH_LE_UUID value) =>
      this.Anonymous.CharacteristicFormat.Description = value;
}

extension BTH_LE_GATT_DESCRIPTOR_VALUE_Extension
    on BTH_LE_GATT_DESCRIPTOR_VALUE {
  _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__CharacteristicExtendedProperties_e__Struct
      get CharacteristicExtendedProperties =>
          this.Anonymous.CharacteristicExtendedProperties;
  set CharacteristicExtendedProperties(
          _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__CharacteristicExtendedProperties_e__Struct
              value) =>
      this.Anonymous.CharacteristicExtendedProperties = value;

  _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__ClientCharacteristicConfiguration_e__Struct
      get ClientCharacteristicConfiguration =>
          this.Anonymous.ClientCharacteristicConfiguration;
  set ClientCharacteristicConfiguration(
          _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__ClientCharacteristicConfiguration_e__Struct
              value) =>
      this.Anonymous.ClientCharacteristicConfiguration = value;

  _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__ServerCharacteristicConfiguration_e__Struct
      get ServerCharacteristicConfiguration =>
          this.Anonymous.ServerCharacteristicConfiguration;
  set ServerCharacteristicConfiguration(
          _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__ServerCharacteristicConfiguration_e__Struct
              value) =>
      this.Anonymous.ServerCharacteristicConfiguration = value;

  _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__CharacteristicFormat_e__Struct
      get CharacteristicFormat => this.Anonymous.CharacteristicFormat;
  set CharacteristicFormat(
          _BTH_LE_GATT_DESCRIPTOR_VALUE__Anonymous_e__Union__CharacteristicFormat_e__Struct
              value) =>
      this.Anonymous.CharacteristicFormat = value;
}

/// The BTH_LE_GATT_SERVICE structure describes a Bluetooth Low Energy (LE)
/// generic attribute (GATT) profile service.
///
/// {@category Struct}
class BTH_LE_GATT_SERVICE extends Struct {
  external BTH_LE_UUID ServiceUuid;

  @Uint16()
  external int AttributeHandle;
}

/// The BTH_LE_UUID structure contains information about a Bluetooth Low
/// Energy (LE) Universally Unique Identifier (UUID).
///
/// {@category Struct}
class BTH_LE_UUID extends Struct {
  @Uint8()
  external int IsShortUuid;

  external _BTH_LE_UUID__Value_e__Union Value;
}

/// {@category Struct}
class _BTH_LE_UUID__Value_e__Union extends Union {
  @Uint16()
  external int ShortUuid;

  external GUID LongUuid;
}

extension BTH_LE_UUID_Extension on BTH_LE_UUID {
  int get ShortUuid => this.Value.ShortUuid;
  set ShortUuid(int value) => this.Value.ShortUuid = value;

  GUID get LongUuid => this.Value.LongUuid;
  set LongUuid(GUID value) => this.Value.LongUuid = value;
}

/// Contains information that the GetFileInformationByHandle function
/// retrieves.
///
/// {@category Struct}
class BY_HANDLE_FILE_INFORMATION extends Struct {
  @Uint32()
  external int dwFileAttributes;

  external FILETIME ftCreationTime;

  external FILETIME ftLastAccessTime;

  external FILETIME ftLastWriteTime;

  @Uint32()
  external int dwVolumeSerialNumber;

  @Uint32()
  external int nFileSizeHigh;

  @Uint32()
  external int nFileSizeLow;

  @Uint32()
  external int nNumberOfLinks;

  @Uint32()
  external int nFileIndexHigh;

  @Uint32()
  external int nFileIndexLow;
}

/// Contains information passed to a WH_CBT hook procedure, CBTProc, before
/// a window is activated.
///
/// {@category Struct}
class CBTACTIVATESTRUCT extends Struct {
  @Int32()
  external int fMouse;

  @IntPtr()
  external int hWndActive;
}

/// Contains information passed to a WH_CBT hook procedure, CBTProc, before
/// a window is created.
///
/// {@category Struct}
class CBT_CREATEWND extends Struct {
  external Pointer<CREATESTRUCT> lpcs;

  @IntPtr()
  external int hwndInsertAfter;
}

/// Contains extended result information obtained by calling the
/// ChangeWindowMessageFilterEx function.
///
/// {@category Struct}
class CHANGEFILTERSTRUCT extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int ExtStatus;
}

/// Specifies a Unicode or ANSI character and its attributes. This structure
/// is used by console functions to read from and write to a console screen
/// buffer.
///
/// {@category Struct}
class CHAR_INFO extends Struct {
  external _CHAR_INFO__Char_e__Union Char;

  @Uint16()
  external int Attributes;
}

/// {@category Struct}
class _CHAR_INFO__Char_e__Union extends Union {
  @Uint16()
  external int UnicodeChar;

  @Uint8()
  external int AsciiChar;
}

extension CHAR_INFO_Extension on CHAR_INFO {
  int get UnicodeChar => this.Char.UnicodeChar;
  set UnicodeChar(int value) => this.Char.UnicodeChar = value;

  int get AsciiChar => this.Char.AsciiChar;
  set AsciiChar(int value) => this.Char.AsciiChar = value;
}

/// Contains information the ChooseColor function uses to initialize the
/// Color dialog box. After the user closes the dialog box, the system
/// returns information about the user's selection in this structure.
///
/// {@category Struct}
class CHOOSECOLOR extends Struct {
  @Uint32()
  external int lStructSize;

  @IntPtr()
  external int hwndOwner;

  @IntPtr()
  external int hInstance;

  @Uint32()
  external int rgbResult;

  external Pointer<Uint32> lpCustColors;

  @Uint32()
  external int Flags;

  @IntPtr()
  external int lCustData;

  external Pointer<NativeFunction<CCHookProc>> lpfnHook;

  external Pointer<Utf16> lpTemplateName;
}

/// Contains information that the ChooseFont function uses to initialize the
/// Font dialog box. After the user closes the dialog box, the system
/// returns information about the user's selection in this structure.
///
/// {@category Struct}
class CHOOSEFONT extends Struct {
  @Uint32()
  external int lStructSize;

  @IntPtr()
  external int hwndOwner;

  @IntPtr()
  external int hDC;

  external Pointer<LOGFONT> lpLogFont;

  @Int32()
  external int iPointSize;

  @Uint32()
  external int Flags;

  @Uint32()
  external int rgbColors;

  @IntPtr()
  external int lCustData;

  external Pointer<NativeFunction<CFHookProc>> lpfnHook;

  external Pointer<Utf16> lpTemplateName;

  @IntPtr()
  external int hInstance;

  external Pointer<Utf16> lpszStyle;

  @Uint16()
  external int nFontType;

  @Uint16()
  external int MISSING_ALIGNMENT__;

  @Int32()
  external int nSizeMin;

  @Int32()
  external int nSizeMax;
}

/// The COLORADJUSTMENT structure defines the color adjustment values used
/// by the StretchBlt and StretchDIBits functions when the stretch mode is
/// HALFTONE. You can set the color adjustment values by calling the
/// SetColorAdjustment function.
///
/// {@category Struct}
class COLORADJUSTMENT extends Struct {
  @Uint16()
  external int caSize;

  @Uint16()
  external int caFlags;

  @Uint16()
  external int caIlluminantIndex;

  @Uint16()
  external int caRedGamma;

  @Uint16()
  external int caGreenGamma;

  @Uint16()
  external int caBlueGamma;

  @Uint16()
  external int caReferenceBlack;

  @Uint16()
  external int caReferenceWhite;

  @Int16()
  external int caContrast;

  @Int16()
  external int caBrightness;

  @Int16()
  external int caColorfulness;

  @Int16()
  external int caRedGreenTint;
}

/// Used generically to filter elements.
///
/// {@category Struct}
class COMDLG_FILTERSPEC extends Struct {
  external Pointer<Utf16> pszName;

  external Pointer<Utf16> pszSpec;
}

/// Contains information about the configuration state of a communications
/// device.
///
/// {@category Struct}
class COMMCONFIG extends Struct {
  @Uint32()
  external int dwSize;

  @Uint16()
  external int wVersion;

  @Uint16()
  external int wReserved;

  external DCB dcb;

  @Uint32()
  external int dwProviderSubType;

  @Uint32()
  external int dwProviderOffset;

  @Uint32()
  external int dwProviderSize;

  @Array(1)
  external Array<Uint16> _wcProviderData;

  String get wcProviderData {
    final charCodes = <int>[];
    for (var i = 0; i < 1; i++) {
      if (_wcProviderData[i] == 0x00) break;
      charCodes.add(_wcProviderData[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set wcProviderData(String value) {
    final stringToStore = value.padRight(1, '\x00');
    for (var i = 0; i < 1; i++) {
      _wcProviderData[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// Contains information about a communications driver.
///
/// {@category Struct}
class COMMPROP extends Struct {
  @Uint16()
  external int wPacketLength;

  @Uint16()
  external int wPacketVersion;

  @Uint32()
  external int dwServiceMask;

  @Uint32()
  external int dwReserved1;

  @Uint32()
  external int dwMaxTxQueue;

  @Uint32()
  external int dwMaxRxQueue;

  @Uint32()
  external int dwMaxBaud;

  @Uint32()
  external int dwProvSubType;

  @Uint32()
  external int dwProvCapabilities;

  @Uint32()
  external int dwSettableParams;

  @Uint32()
  external int dwSettableBaud;

  @Uint16()
  external int wSettableData;

  @Uint16()
  external int wSettableStopParity;

  @Uint32()
  external int dwCurrentTxQueue;

  @Uint32()
  external int dwCurrentRxQueue;

  @Uint32()
  external int dwProvSpec1;

  @Uint32()
  external int dwProvSpec2;

  @Array(1)
  external Array<Uint16> _wcProvChar;

  String get wcProvChar {
    final charCodes = <int>[];
    for (var i = 0; i < 1; i++) {
      if (_wcProvChar[i] == 0x00) break;
      charCodes.add(_wcProvChar[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set wcProvChar(String value) {
    final stringToStore = value.padRight(1, '\x00');
    for (var i = 0; i < 1; i++) {
      _wcProvChar[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// Contains the time-out parameters for a communications device. The
/// parameters determine the behavior of ReadFile, WriteFile, ReadFileEx,
/// and WriteFileEx operations on the device.
///
/// {@category Struct}
class COMMTIMEOUTS extends Struct {
  @Uint32()
  external int ReadIntervalTimeout;

  @Uint32()
  external int ReadTotalTimeoutMultiplier;

  @Uint32()
  external int ReadTotalTimeoutConstant;

  @Uint32()
  external int WriteTotalTimeoutMultiplier;

  @Uint32()
  external int WriteTotalTimeoutConstant;
}

/// Contains information about a communications device. This structure is
/// filled by the ClearCommError function.
///
/// {@category Struct}
class COMSTAT extends Struct {
  @Uint32()
  external int bitfield;

  @Uint32()
  external int cbInQue;

  @Uint32()
  external int cbOutQue;
}

/// Contains information about the console cursor.
///
/// {@category Struct}
class CONSOLE_CURSOR_INFO extends Struct {
  @Uint32()
  external int dwSize;

  @Int32()
  external int bVisible;
}

/// Contains information for a console read operation.
///
/// {@category Struct}
class CONSOLE_READCONSOLE_CONTROL extends Struct {
  @Uint32()
  external int nLength;

  @Uint32()
  external int nInitialChars;

  @Uint32()
  external int dwCtrlWakeupMask;

  @Uint32()
  external int dwControlKeyState;
}

/// Contains information about a console screen buffer.
///
/// {@category Struct}
class CONSOLE_SCREEN_BUFFER_INFO extends Struct {
  external COORD dwSize;

  external COORD dwCursorPosition;

  @Uint16()
  external int wAttributes;

  external SMALL_RECT srWindow;

  external COORD dwMaximumWindowSize;
}

/// Contains information for a console selection.
///
/// {@category Struct}
class CONSOLE_SELECTION_INFO extends Struct {
  @Uint32()
  external int dwFlags;

  external COORD dwSelectionAnchor;

  external SMALL_RECT srSelection;
}

/// Defines the coordinates of a character cell in a console screen buffer.
/// The origin of the coordinate system (0,0) is at the top, left cell of
/// the buffer.
///
/// {@category Struct}
class COORD extends Struct {
  @Int16()
  external int X;

  @Int16()
  external int Y;
}

/// Contains optional extended parameters for CreateFile2.
///
/// {@category Struct}
class CREATEFILE2_EXTENDED_PARAMETERS extends Struct {
  @Uint32()
  external int dwSize;

  @Uint32()
  external int dwFileAttributes;

  @Uint32()
  external int dwFileFlags;

  @Uint32()
  external int dwSecurityQosFlags;

  external Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes;

  @IntPtr()
  external int hTemplateFile;
}

/// Defines the initialization parameters passed to the window procedure of
/// an application. These members are identical to the parameters of the
/// CreateWindowEx function.
///
/// {@category Struct}
class CREATESTRUCT extends Struct {
  external Pointer lpCreateParams;

  @IntPtr()
  external int hInstance;

  @IntPtr()
  external int hMenu;

  @IntPtr()
  external int hwndParent;

  @Int32()
  external int cy;

  @Int32()
  external int cx;

  @Int32()
  external int y;

  @Int32()
  external int x;

  @Int32()
  external int style;

  external Pointer<Utf16> lpszName;

  external Pointer<Utf16> lpszClass;

  @Uint32()
  external int dwExStyle;
}

/// The CREDENTIAL structure contains an individual credential.
///
/// {@category Struct}
class CREDENTIAL extends Struct {
  @Uint32()
  external int Flags;

  @Uint32()
  external int Type;

  external Pointer<Utf16> TargetName;

  external Pointer<Utf16> Comment;

  external FILETIME LastWritten;

  @Uint32()
  external int CredentialBlobSize;

  external Pointer<Uint8> CredentialBlob;

  @Uint32()
  external int Persist;

  @Uint32()
  external int AttributeCount;

  external Pointer<CREDENTIAL_ATTRIBUTE> Attributes;

  external Pointer<Utf16> TargetAlias;

  external Pointer<Utf16> UserName;
}

/// The CREDENTIAL_ATTRIBUTE structure contains an application-defined
/// attribute of the credential. An attribute is a keyword-value pair. It is
/// up to the application to define the meaning of the attribute.
///
/// {@category Struct}
class CREDENTIAL_ATTRIBUTE extends Struct {
  external Pointer<Utf16> Keyword;

  @Uint32()
  external int Flags;

  @Uint32()
  external int ValueSize;

  external Pointer<Uint8> Value;
}

/// The CRYPTPROTECT_PROMPTSTRUCT structure provides the text of a prompt
/// and information about when and where that prompt is to be displayed when
/// using the CryptProtectData and CryptUnprotectData functions.
///
/// {@category Struct}
class CRYPTPROTECT_PROMPTSTRUCT extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int dwPromptFlags;

  @IntPtr()
  external int hwndApp;

  external Pointer<Utf16> szPrompt;
}

/// Contains an arbitrary array of bytes. The structure definition includes
/// aliases appropriate to the various functions that use it.
///
/// {@category Struct}
class CRYPT_INTEGER_BLOB extends Struct {
  @Uint32()
  external int cbData;

  external Pointer<Uint8> pbData;
}

/// Contains global cursor information.
///
/// {@category Struct}
class CURSORINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int flags;

  @IntPtr()
  external int hCursor;

  external POINT ptScreenPos;
}

/// Defines the message parameters passed to a WH_CALLWNDPROCRET hook
/// procedure, CallWndRetProc.
///
/// {@category Struct}
class CWPRETSTRUCT extends Struct {
  @IntPtr()
  external int lResult;

  @IntPtr()
  external int lParam;

  @IntPtr()
  external int wParam;

  @Uint32()
  external int message;

  @IntPtr()
  external int hwnd;
}

/// Defines the message parameters passed to a WH_CALLWNDPROC hook
/// procedure, CallWndProc.
///
/// {@category Struct}
class CWPSTRUCT extends Struct {
  @IntPtr()
  external int lParam;

  @IntPtr()
  external int wParam;

  @Uint32()
  external int message;

  @IntPtr()
  external int hwnd;
}

/// A currency number stored as an 8-byte, two's complement integer, scaled
/// by 10,000 to give a fixed-point number with 15 digits to the left of the
/// decimal point and 4 digits to the right. This IDispatch::GetTypeInfo
/// representation provides a range of 922337203685477.5807 to
/// -922337203685477.5808.
///
/// {@category Struct}
class CY extends Union {
  external _CY__Anonymous_e__Struct Anonymous;

  @Int64()
  external int int64;
}

/// {@category Struct}
class _CY__Anonymous_e__Struct extends Struct {
  @Uint32()
  external int Lo;

  @Int32()
  external int Hi;
}

extension CY_Extension on CY {
  int get Lo => this.Anonymous.Lo;
  set Lo(int value) => this.Anonymous.Lo = value;

  int get Hi => this.Anonymous.Hi;
  set Hi(int value) => this.Anonymous.Hi = value;
}

/// Defines the control setting for a serial communications device.
///
/// {@category Struct}
class DCB extends Struct {
  @Uint32()
  external int DCBlength;

  @Uint32()
  external int BaudRate;

  @Uint32()
  external int bitfield;

  @Uint16()
  external int wReserved;

  @Uint16()
  external int XonLim;

  @Uint16()
  external int XoffLim;

  @Uint8()
  external int ByteSize;

  @Uint8()
  external int Parity;

  @Uint8()
  external int StopBits;

  @Uint8()
  external int XonChar;

  @Uint8()
  external int XoffChar;

  @Uint8()
  external int ErrorChar;

  @Uint8()
  external int EofChar;

  @Uint8()
  external int EvtChar;

  @Uint16()
  external int wReserved1;
}

/// Contains debugging information passed to a WH_DEBUG hook procedure,
/// DebugProc.
///
/// {@category Struct}
class DEBUGHOOKINFO extends Struct {
  @Uint32()
  external int idThread;

  @Uint32()
  external int idThreadInstaller;

  @IntPtr()
  external int lParam;

  @IntPtr()
  external int wParam;

  @Int32()
  external int code;
}

/// Represents a decimal data type that provides a sign and scale for a
/// number (as in coordinates.) Decimal variables are stored as 96-bit
/// (12-byte) unsigned integers scaled by a variable power of 10. The power
/// of 10 scaling factor specifies the number of digits to the right of the
/// decimal point, and ranges from 0 to 28.
///
/// {@category Struct}
class DECIMAL extends Struct {
  @Uint16()
  external int wReserved;

  external _DECIMAL__Anonymous1_e__Union Anonymous1;

  @Uint32()
  external int Hi32;

  external _DECIMAL__Anonymous2_e__Union Anonymous2;
}

/// {@category Struct}
class _DECIMAL__Anonymous1_e__Union extends Union {
  external _DECIMAL__Anonymous1_e__Union__Anonymous_e__Struct Anonymous;

  @Uint16()
  external int signscale;
}

/// {@category Struct}
class _DECIMAL__Anonymous1_e__Union__Anonymous_e__Struct extends Struct {
  @Uint8()
  external int scale;

  @Uint8()
  external int sign;
}

extension DECIMAL__Anonymous1_e__Union_Extension on DECIMAL {
  int get scale => this.Anonymous1.Anonymous.scale;
  set scale(int value) => this.Anonymous1.Anonymous.scale = value;

  int get sign => this.Anonymous1.Anonymous.sign;
  set sign(int value) => this.Anonymous1.Anonymous.sign = value;
}

extension DECIMAL_Extension on DECIMAL {
  _DECIMAL__Anonymous1_e__Union__Anonymous_e__Struct get Anonymous =>
      this.Anonymous1.Anonymous;
  set Anonymous(_DECIMAL__Anonymous1_e__Union__Anonymous_e__Struct value) =>
      this.Anonymous1.Anonymous = value;

  int get signscale => this.Anonymous1.signscale;
  set signscale(int value) => this.Anonymous1.signscale = value;
}

/// {@category Struct}
class _DECIMAL__Anonymous2_e__Union extends Union {
  external _DECIMAL__Anonymous2_e__Union__Anonymous_e__Struct Anonymous;

  @Uint64()
  external int Lo64;
}

/// {@category Struct}
class _DECIMAL__Anonymous2_e__Union__Anonymous_e__Struct extends Struct {
  @Uint32()
  external int Lo32;

  @Uint32()
  external int Mid32;
}

extension DECIMAL__Anonymous2_e__Union_Extension on DECIMAL {
  int get Lo32 => this.Anonymous2.Anonymous.Lo32;
  set Lo32(int value) => this.Anonymous2.Anonymous.Lo32 = value;

  int get Mid32 => this.Anonymous2.Anonymous.Mid32;
  set Mid32(int value) => this.Anonymous2.Anonymous.Mid32 = value;
}

extension DECIMAL_Extension_1 on DECIMAL {
  _DECIMAL__Anonymous2_e__Union__Anonymous_e__Struct get Anonymous =>
      this.Anonymous2.Anonymous;
  set Anonymous(_DECIMAL__Anonymous2_e__Union__Anonymous_e__Struct value) =>
      this.Anonymous2.Anonymous = value;

  int get Lo64 => this.Anonymous2.Lo64;
  set Lo64(int value) => this.Anonymous2.Lo64 = value;
}

/// The DESIGNVECTOR structure is used by an application to specify values
/// for the axes of a multiple master font.
///
/// {@category Struct}
class DESIGNVECTOR extends Struct {
  @Uint32()
  external int dvReserved;

  @Uint32()
  external int dvNumAxes;

  @Array(16)
  external Array<Int32> dvValues;
}

/// The DEVMODE data structure contains information about the initialization
/// and environment of a printer or a display device.
///
/// {@category Struct}
class DEVMODE extends Struct {
  @Array(32)
  external Array<Uint16> _dmDeviceName;

  String get dmDeviceName {
    final charCodes = <int>[];
    for (var i = 0; i < 32; i++) {
      if (_dmDeviceName[i] == 0x00) break;
      charCodes.add(_dmDeviceName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set dmDeviceName(String value) {
    final stringToStore = value.padRight(32, '\x00');
    for (var i = 0; i < 32; i++) {
      _dmDeviceName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint16()
  external int dmSpecVersion;

  @Uint16()
  external int dmDriverVersion;

  @Uint16()
  external int dmSize;

  @Uint16()
  external int dmDriverExtra;

  @Uint32()
  external int dmFields;

  external _DEVMODEW__Anonymous1_e__Union Anonymous1;

  @Uint16()
  external int dmColor;

  @Uint16()
  external int dmDuplex;

  @Int16()
  external int dmYResolution;

  @Uint16()
  external int dmTTOption;

  @Uint16()
  external int dmCollate;

  @Array(32)
  external Array<Uint16> _dmFormName;

  String get dmFormName {
    final charCodes = <int>[];
    for (var i = 0; i < 32; i++) {
      if (_dmFormName[i] == 0x00) break;
      charCodes.add(_dmFormName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set dmFormName(String value) {
    final stringToStore = value.padRight(32, '\x00');
    for (var i = 0; i < 32; i++) {
      _dmFormName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint16()
  external int dmLogPixels;

  @Uint32()
  external int dmBitsPerPel;

  @Uint32()
  external int dmPelsWidth;

  @Uint32()
  external int dmPelsHeight;

  external _DEVMODEW__Anonymous2_e__Union Anonymous2;

  @Uint32()
  external int dmDisplayFrequency;

  @Uint32()
  external int dmICMMethod;

  @Uint32()
  external int dmICMIntent;

  @Uint32()
  external int dmMediaType;

  @Uint32()
  external int dmDitherType;

  @Uint32()
  external int dmReserved1;

  @Uint32()
  external int dmReserved2;

  @Uint32()
  external int dmPanningWidth;

  @Uint32()
  external int dmPanningHeight;
}

/// {@category Struct}
class _DEVMODEW__Anonymous1_e__Union extends Union {
  external _DEVMODEW__Anonymous1_e__Union__Anonymous1_e__Struct Anonymous1;

  external _DEVMODEW__Anonymous1_e__Union__Anonymous2_e__Struct Anonymous2;
}

/// {@category Struct}
class _DEVMODEW__Anonymous1_e__Union__Anonymous1_e__Struct extends Struct {
  @Int16()
  external int dmOrientation;

  @Int16()
  external int dmPaperSize;

  @Int16()
  external int dmPaperLength;

  @Int16()
  external int dmPaperWidth;

  @Int16()
  external int dmScale;

  @Int16()
  external int dmCopies;

  @Int16()
  external int dmDefaultSource;

  @Int16()
  external int dmPrintQuality;
}

extension DEVMODEW__Anonymous1_e__Union_Extension on DEVMODE {
  int get dmOrientation => this.Anonymous1.Anonymous1.dmOrientation;
  set dmOrientation(int value) =>
      this.Anonymous1.Anonymous1.dmOrientation = value;

  int get dmPaperSize => this.Anonymous1.Anonymous1.dmPaperSize;
  set dmPaperSize(int value) => this.Anonymous1.Anonymous1.dmPaperSize = value;

  int get dmPaperLength => this.Anonymous1.Anonymous1.dmPaperLength;
  set dmPaperLength(int value) =>
      this.Anonymous1.Anonymous1.dmPaperLength = value;

  int get dmPaperWidth => this.Anonymous1.Anonymous1.dmPaperWidth;
  set dmPaperWidth(int value) =>
      this.Anonymous1.Anonymous1.dmPaperWidth = value;

  int get dmScale => this.Anonymous1.Anonymous1.dmScale;
  set dmScale(int value) => this.Anonymous1.Anonymous1.dmScale = value;

  int get dmCopies => this.Anonymous1.Anonymous1.dmCopies;
  set dmCopies(int value) => this.Anonymous1.Anonymous1.dmCopies = value;

  int get dmDefaultSource => this.Anonymous1.Anonymous1.dmDefaultSource;
  set dmDefaultSource(int value) =>
      this.Anonymous1.Anonymous1.dmDefaultSource = value;

  int get dmPrintQuality => this.Anonymous1.Anonymous1.dmPrintQuality;
  set dmPrintQuality(int value) =>
      this.Anonymous1.Anonymous1.dmPrintQuality = value;
}

/// {@category Struct}
class _DEVMODEW__Anonymous1_e__Union__Anonymous2_e__Struct extends Struct {
  external POINTL dmPosition;

  @Uint32()
  external int dmDisplayOrientation;

  @Uint32()
  external int dmDisplayFixedOutput;
}

extension DEVMODEW__Anonymous1_e__Union_Extension_1 on DEVMODE {
  POINTL get dmPosition => this.Anonymous1.Anonymous2.dmPosition;
  set dmPosition(POINTL value) => this.Anonymous1.Anonymous2.dmPosition = value;

  int get dmDisplayOrientation =>
      this.Anonymous1.Anonymous2.dmDisplayOrientation;
  set dmDisplayOrientation(int value) =>
      this.Anonymous1.Anonymous2.dmDisplayOrientation = value;

  int get dmDisplayFixedOutput =>
      this.Anonymous1.Anonymous2.dmDisplayFixedOutput;
  set dmDisplayFixedOutput(int value) =>
      this.Anonymous1.Anonymous2.dmDisplayFixedOutput = value;
}

extension DEVMODEW_Extension on DEVMODE {
  _DEVMODEW__Anonymous1_e__Union__Anonymous1_e__Struct get Anonymous1 =>
      this.Anonymous1.Anonymous1;
  set Anonymous1(_DEVMODEW__Anonymous1_e__Union__Anonymous1_e__Struct value) =>
      this.Anonymous1.Anonymous1 = value;

  _DEVMODEW__Anonymous1_e__Union__Anonymous2_e__Struct get Anonymous2 =>
      this.Anonymous1.Anonymous2;
  set Anonymous2(_DEVMODEW__Anonymous1_e__Union__Anonymous2_e__Struct value) =>
      this.Anonymous1.Anonymous2 = value;
}

/// {@category Struct}
class _DEVMODEW__Anonymous2_e__Union extends Union {
  @Uint32()
  external int dmDisplayFlags;

  @Uint32()
  external int dmNup;
}

extension DEVMODEW_Extension_1 on DEVMODE {
  int get dmDisplayFlags => this.Anonymous2.dmDisplayFlags;
  set dmDisplayFlags(int value) => this.Anonymous2.dmDisplayFlags = value;

  int get dmNup => this.Anonymous2.dmNup;
  set dmNup(int value) => this.Anonymous2.dmNup = value;
}

/// The DIBSECTION structure contains information about a DIB created by
/// calling the CreateDIBSection function. A DIBSECTION structure includes
/// information about the bitmap's dimensions, color format, color masks,
/// optional file mapping object, and optional bit values storage offset. An
/// application can obtain a filled-in DIBSECTION structure for a given DIB
/// by calling the GetObject function.
///
/// {@category Struct}
class DIBSECTION extends Struct {
  external BITMAP dsBm;

  external BITMAPINFOHEADER dsBmih;

  @Array(3)
  external Array<Uint32> dsBitfields;

  @IntPtr()
  external int dshSection;

  @Uint32()
  external int dsOffset;
}

/// Represents a disk extent.
///
/// {@category Struct}
class DISK_EXTENT extends Struct {
  @Uint32()
  external int DiskNumber;

  @Int64()
  external int StartingOffset;

  @Int64()
  external int ExtentLength;
}

/// Describes the geometry of disk devices and media.
///
/// {@category Struct}
class DISK_GEOMETRY extends Struct {
  @Int64()
  external int Cylinders;

  @Int32()
  external int MediaType;

  @Uint32()
  external int TracksPerCylinder;

  @Uint32()
  external int SectorsPerTrack;

  @Uint32()
  external int BytesPerSector;
}

/// Describes the extended geometry of disk devices and media.
///
/// {@category Struct}
class DISK_GEOMETRY_EX extends Struct {
  external DISK_GEOMETRY Geometry;

  @Int64()
  external int DiskSize;

  @Array(1)
  external Array<Uint8> Data;
}

/// Contains the arguments passed to a method or property.
///
/// {@category Struct}
class DISPPARAMS extends Struct {
  external Pointer<VARIANT> rgvarg;

  external Pointer<Int32> rgdispidNamedArgs;

  @Uint32()
  external int cArgs;

  @Uint32()
  external int cNamedArgs;
}

/// Defines the dimensions and style of a control in a dialog box. One or
/// more of these structures are combined with a DLGTEMPLATE structure to
/// form a standard template for a dialog box.
///
/// {@category Struct}
@Packed(2)
class DLGITEMTEMPLATE extends Struct {
  @Uint32()
  external int style;

  @Uint32()
  external int dwExtendedStyle;

  @Int16()
  external int x;

  @Int16()
  external int y;

  @Int16()
  external int cx;

  @Int16()
  external int cy;

  @Uint16()
  external int id;
}

/// Defines the dimensions and style of a dialog box. This structure, always
/// the first in a standard template for a dialog box, also specifies the
/// number of controls in the dialog box and therefore specifies the number
/// of subsequent DLGITEMTEMPLATE structures in the template.
///
/// {@category Struct}
@Packed(2)
class DLGTEMPLATE extends Struct {
  @Uint32()
  external int style;

  @Uint32()
  external int dwExtendedStyle;

  @Uint16()
  external int cdit;

  @Int16()
  external int x;

  @Int16()
  external int y;

  @Int16()
  external int cx;

  @Int16()
  external int cy;
}

/// Receives DLL-specific version information. It is used with the
/// DllGetVersion function.
///
/// {@category Struct}
class DLLVERSIONINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int dwMajorVersion;

  @Uint32()
  external int dwMinorVersion;

  @Uint32()
  external int dwBuildNumber;

  @Uint32()
  external int dwPlatformID;
}

/// The DOC_INFO_1 structure describes a document that will be printed.
///
/// {@category Struct}
class DOC_INFO_1 extends Struct {
  external Pointer<Utf16> pDocName;

  external Pointer<Utf16> pOutputFile;

  external Pointer<Utf16> pDatatype;
}

/// The DOT11_AUTH_CIPHER_PAIR structure defines a pair of 802.11
/// authentication and cipher algorithms that can be enabled at the same
/// time on the 802.11 station.
///
/// {@category Struct}
class DOT11_AUTH_CIPHER_PAIR extends Struct {
  @Int32()
  external int AuthAlgoId;

  @Int32()
  external int CipherAlgoId;
}

/// The DOT11_BSSID_LIST structure contains a list of basic service set
/// (BSS) identifiers.
///
/// {@category Struct}
class DOT11_BSSID_LIST extends Struct {
  external NDIS_OBJECT_HEADER Header;

  @Uint32()
  external int uNumOfEntries;

  @Uint32()
  external int uTotalNumOfEntries;

  @Array(6)
  external Array<Uint8> BSSIDs;
}

/// The DOT11_NETWORK structure contains information about an available
/// wireless network.
///
/// {@category Struct}
class DOT11_NETWORK extends Struct {
  external DOT11_SSID dot11Ssid;

  @Int32()
  external int dot11BssType;
}

/// The DOT11_NETWORK_LIST structure contains a list of 802.11 wireless
/// networks.
///
/// {@category Struct}
class DOT11_NETWORK_LIST extends Struct {
  @Uint32()
  external int dwNumberOfItems;

  @Uint32()
  external int dwIndex;

  @Array(1)
  external Array<DOT11_NETWORK> Network;
}

/// A DOT11_SSID structure contains the SSID of an interface.
///
/// {@category Struct}
class DOT11_SSID extends Struct {
  @Uint32()
  external int uSSIDLength;

  @Array(32)
  external Array<Uint8> ucSSID;
}

/// The DRAWTEXTPARAMS structure contains extended formatting options for
/// the DrawTextEx function.
///
/// {@category Struct}
class DRAWTEXTPARAMS extends Struct {
  @Uint32()
  external int cbSize;

  @Int32()
  external int iTabLength;

  @Int32()
  external int iLeftMargin;

  @Int32()
  external int iRightMargin;

  @Uint32()
  external int uiLengthDrawn;
}

/// Defines the options for the DrawThemeBackgroundEx function.
///
/// {@category Struct}
class DTBGOPTS extends Struct {
  @Uint32()
  external int dwSize;

  @Uint32()
  external int dwFlags;

  external RECT rcClip;
}

/// Defines the options for the DrawThemeTextEx function.
///
/// {@category Struct}
class DTTOPTS extends Struct {
  @Uint32()
  external int dwSize;

  @Uint32()
  external int dwFlags;

  @Uint32()
  external int crText;

  @Uint32()
  external int crBorder;

  @Uint32()
  external int crShadow;

  @Int32()
  external int iTextShadowType;

  external POINT ptShadowOffset;

  @Int32()
  external int iBorderSize;

  @Int32()
  external int iFontPropId;

  @Int32()
  external int iColorPropId;

  @Int32()
  external int iStateId;

  @Int32()
  external int fApplyOverlay;

  @Int32()
  external int iGlowSize;

  external Pointer<NativeFunction<DrawTextCallback>> pfnDrawTextCallback;

  @IntPtr()
  external int lParam;
}

/// Specifies Desktop Window Manager (DWM) blur-behind properties. Used by
/// the DwmEnableBlurBehindWindow function.
///
/// {@category Struct}
@Packed(1)
class DWM_BLURBEHIND extends Struct {
  @Uint32()
  external int dwFlags;

  @Int32()
  external int fEnable;

  @IntPtr()
  external int hRgnBlur;

  @Int32()
  external int fTransitionOnMaximized;
}

/// The EAP_METHOD_TYPE structure contains type, identification, and author
/// information about an EAP method.
///
/// {@category Struct}
class EAP_METHOD_TYPE extends Struct {
  external EAP_TYPE eapType;

  @Uint32()
  external int dwAuthorId;
}

/// The EAP_TYPE structure contains type and vendor identification
/// information for an EAP method.
///
/// {@category Struct}
class EAP_TYPE extends Struct {
  @Uint8()
  external int type;

  @Uint32()
  external int dwVendorId;

  @Uint32()
  external int dwVendorType;
}

/// Contains the type description and process-transfer information for a
/// variable, a function, or a function parameter.
///
/// {@category Struct}
class ELEMDESC extends Struct {
  external TYPEDESC tdesc;

  external _ELEMDESC__Anonymous_e__Union Anonymous;
}

/// {@category Struct}
class _ELEMDESC__Anonymous_e__Union extends Union {
  external IDLDESC idldesc;

  external PARAMDESC paramdesc;
}

extension ELEMDESC_Extension on ELEMDESC {
  IDLDESC get idldesc => this.Anonymous.idldesc;
  set idldesc(IDLDESC value) => this.Anonymous.idldesc = value;

  PARAMDESC get paramdesc => this.Anonymous.paramdesc;
  set paramdesc(PARAMDESC value) => this.Anonymous.paramdesc = value;
}

/// The ENUMLOGFONTEX structure contains information about an enumerated
/// font.
///
/// {@category Struct}
class ENUMLOGFONTEX extends Struct {
  external LOGFONT elfLogFont;

  @Array(64)
  external Array<Uint16> _elfFullName;

  String get elfFullName {
    final charCodes = <int>[];
    for (var i = 0; i < 64; i++) {
      if (_elfFullName[i] == 0x00) break;
      charCodes.add(_elfFullName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set elfFullName(String value) {
    final stringToStore = value.padRight(64, '\x00');
    for (var i = 0; i < 64; i++) {
      _elfFullName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Array(32)
  external Array<Uint16> _elfStyle;

  String get elfStyle {
    final charCodes = <int>[];
    for (var i = 0; i < 32; i++) {
      if (_elfStyle[i] == 0x00) break;
      charCodes.add(_elfStyle[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set elfStyle(String value) {
    final stringToStore = value.padRight(32, '\x00');
    for (var i = 0; i < 32; i++) {
      _elfStyle[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Array(32)
  external Array<Uint16> _elfScript;

  String get elfScript {
    final charCodes = <int>[];
    for (var i = 0; i < 32; i++) {
      if (_elfScript[i] == 0x00) break;
      charCodes.add(_elfScript[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set elfScript(String value) {
    final stringToStore = value.padRight(32, '\x00');
    for (var i = 0; i < 32; i++) {
      _elfScript[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// Contains information about a hardware message sent to the system message
/// queue. This structure is used to store message information for the
/// JournalPlaybackProc callback function.
///
/// {@category Struct}
class EVENTMSG extends Struct {
  @Uint32()
  external int message;

  @Uint32()
  external int paramL;

  @Uint32()
  external int paramH;

  @Uint32()
  external int time;

  @IntPtr()
  external int hwnd;
}

/// Describes an exception that occurred during IDispatch::Invoke.
///
/// {@category Struct}
class EXCEPINFO extends Struct {
  @Uint16()
  external int wCode;

  @Uint16()
  external int wReserved;

  external Pointer<Utf16> bstrSource;

  external Pointer<Utf16> bstrDescription;

  external Pointer<Utf16> bstrHelpFile;

  @Uint32()
  external int dwHelpContext;

  external Pointer pvReserved;

  external Pointer<NativeFunction<ExcepInfoProc>> pfnDeferredFillIn;

  @Int32()
  external int scode;
}

/// The fd_set structure is used by various Windows Sockets functions and
/// service providers, such as the select function, to place sockets into a
/// set for various purposes, such as testing a given socket for readability
/// using the readfds parameter of the select function.
///
/// {@category Struct}
class FD_SET extends Struct {
  @Uint32()
  external int fd_count;

  @Array(64)
  external Array<IntPtr> fd_array;
}

/// Contains a 64-bit value representing the number of 100-nanosecond
/// intervals since January 1, 1601 (UTC).
///
/// {@category Struct}
class FILETIME extends Struct {
  @Uint32()
  external int dwLowDateTime;

  @Uint32()
  external int dwHighDateTime;
}

/// Union that contains a 64-bit value that points to a page of data.
///
/// {@category Struct}
class FILE_SEGMENT_ELEMENT extends Union {
  external Pointer Buffer;

  @Uint64()
  external int Alignment;
}

/// Contains information that the FindText and ReplaceText functions use to
/// initialize the Find and Replace dialog boxes. The FINDMSGSTRING
/// registered message uses this structure to pass the user's search or
/// replacement input to the owner window of a Find or Replace dialog box.
///
/// {@category Struct}
class FINDREPLACE extends Struct {
  @Uint32()
  external int lStructSize;

  @IntPtr()
  external int hwndOwner;

  @IntPtr()
  external int hInstance;

  @Uint32()
  external int Flags;

  external Pointer<Utf16> lpstrFindWhat;

  external Pointer<Utf16> lpstrReplaceWith;

  @Uint16()
  external int wFindWhatLen;

  @Uint16()
  external int wReplaceWithLen;

  @IntPtr()
  external int lCustData;

  external Pointer<NativeFunction<FRHookProc>> lpfnHook;

  external Pointer<Utf16> lpTemplateName;
}

/// Describes a focus event in a console INPUT_RECORD structure. These
/// events are used internally and should be ignored.
///
/// {@category Struct}
class FOCUS_EVENT_RECORD extends Struct {
  @Int32()
  external int bSetFocus;
}

/// Describes a function.
///
/// {@category Struct}
class FUNCDESC extends Struct {
  @Int32()
  external int memid;

  external Pointer<Int32> lprgscode;

  external Pointer<ELEMDESC> lprgelemdescParam;

  @Int32()
  external int funckind;

  @Int32()
  external int invkind;

  @Int32()
  external int callconv;

  @Int16()
  external int cParams;

  @Int16()
  external int cParamsOpt;

  @Int16()
  external int oVft;

  @Int16()
  external int cScodes;

  external ELEMDESC elemdescFunc;

  @Uint16()
  external int wFuncFlags;
}

/// Gets and sets the configuration for enabling gesture messages and the
/// type of this configuration.
///
/// {@category Struct}
class GESTURECONFIG extends Struct {
  @Uint32()
  external int dwID;

  @Uint32()
  external int dwWant;

  @Uint32()
  external int dwBlock;
}

/// Stores information about a gesture.
///
/// {@category Struct}
class GESTUREINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int dwFlags;

  @Uint32()
  external int dwID;

  @IntPtr()
  external int hwndTarget;

  external POINTS ptsLocation;

  @Uint32()
  external int dwInstanceID;

  @Uint32()
  external int dwSequenceID;

  @Uint64()
  external int ullArguments;

  @Uint32()
  external int cbExtraArgs;
}

/// When transmitted with WM_GESTURENOTIFY messages, passes information
/// about a gesture.
///
/// {@category Struct}
class GESTURENOTIFYSTRUCT extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int dwFlags;

  @IntPtr()
  external int hwndTarget;

  external POINTS ptsLocation;

  @Uint32()
  external int dwInstanceID;
}

/// Contains information about a GUI thread.
///
/// {@category Struct}
class GUITHREADINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int flags;

  @IntPtr()
  external int hwndActive;

  @IntPtr()
  external int hwndFocus;

  @IntPtr()
  external int hwndCapture;

  @IntPtr()
  external int hwndMenuOwner;

  @IntPtr()
  external int hwndMoveSize;

  @IntPtr()
  external int hwndCaret;

  external RECT rcCaret;
}

/// Contains information about a simulated message generated by an input
/// device other than a keyboard or mouse.
///
/// {@category Struct}
class HARDWAREINPUT extends Struct {
  @Uint32()
  external int uMsg;

  @Uint16()
  external int wParamL;

  @Uint16()
  external int wParamH;
}

/// The hostent structure is used by functions to store information about a
/// given host, such as host name, IPv4 address, and so forth. An
/// application should never attempt to modify this structure or to free any
/// of its components. Furthermore, only one copy of the hostent structure
/// is allocated per thread, and an application should therefore copy any
/// information that it needs before issuing any other Windows Sockets API
/// calls.
///
/// {@category Struct}
class HOSTENT extends Struct {
  external Pointer<Utf8> h_name;

  external Pointer<Pointer<Int8>> h_aliases;

  @Int16()
  external int h_addrtype;

  @Int16()
  external int h_length;

  external Pointer<Pointer<Int8>> h_addr_list;
}

/// Contains information about an icon or a cursor.
///
/// {@category Struct}
class ICONINFO extends Struct {
  @Int32()
  external int fIcon;

  @Uint32()
  external int xHotspot;

  @Uint32()
  external int yHotspot;

  @IntPtr()
  external int hbmMask;

  @IntPtr()
  external int hbmColor;
}

/// Contains information about an icon or a cursor. Extends ICONINFO. Used
/// by GetIconInfoEx.
///
/// {@category Struct}
class ICONINFOEX extends Struct {
  @Uint32()
  external int cbSize;

  @Int32()
  external int fIcon;

  @Uint32()
  external int xHotspot;

  @Uint32()
  external int yHotspot;

  @IntPtr()
  external int hbmMask;

  @IntPtr()
  external int hbmColor;

  @Uint16()
  external int wResID;

  @Array(260)
  external Array<Uint16> _szModName;

  String get szModName {
    final charCodes = <int>[];
    for (var i = 0; i < 260; i++) {
      if (_szModName[i] == 0x00) break;
      charCodes.add(_szModName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szModName(String value) {
    final stringToStore = value.padRight(260, '\x00');
    for (var i = 0; i < 260; i++) {
      _szModName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Array(260)
  external Array<Uint16> _szResName;

  String get szResName {
    final charCodes = <int>[];
    for (var i = 0; i < 260; i++) {
      if (_szResName[i] == 0x00) break;
      charCodes.add(_szResName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szResName(String value) {
    final stringToStore = value.padRight(260, '\x00');
    for (var i = 0; i < 260; i++) {
      _szResName[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// Contains the IDL attributes of a type.
///
/// {@category Struct}
class IDLDESC extends Struct {
  @IntPtr()
  external int dwReserved;

  @Uint16()
  external int wIDLFlags;
}

/// Carries information used to load common control classes from the
/// dynamic-link library (DLL). This structure is used with the
/// InitCommonControlsEx function.
///
/// {@category Struct}
class INITCOMMONCONTROLSEX extends Struct {
  @Uint32()
  external int dwSize;

  @Uint32()
  external int dwICC;
}

/// Used by SendInput to store information for synthesizing input events
/// such as keystrokes, mouse movement, and mouse clicks.
///
/// {@category Struct}
class INPUT extends Struct {
  @Uint32()
  external int type;

  external _INPUT__Anonymous_e__Union Anonymous;
}

/// {@category Struct}
class _INPUT__Anonymous_e__Union extends Union {
  external MOUSEINPUT mi;

  external KEYBDINPUT ki;

  external HARDWAREINPUT hi;
}

extension INPUT_Extension on INPUT {
  MOUSEINPUT get mi => this.Anonymous.mi;
  set mi(MOUSEINPUT value) => this.Anonymous.mi = value;

  KEYBDINPUT get ki => this.Anonymous.ki;
  set ki(KEYBDINPUT value) => this.Anonymous.ki = value;

  HARDWAREINPUT get hi => this.Anonymous.hi;
  set hi(HARDWAREINPUT value) => this.Anonymous.hi = value;
}

/// Describes an input event in the console input buffer. These records can
/// be read from the input buffer by using the ReadConsoleInput or
/// PeekConsoleInput function, or written to the input buffer by using the
/// WriteConsoleInput function.
///
/// {@category Struct}
class INPUT_RECORD extends Struct {
  @Uint16()
  external int EventType;

  external _INPUT_RECORD__Event_e__Union Event;
}

/// {@category Struct}
class _INPUT_RECORD__Event_e__Union extends Union {
  external KEY_EVENT_RECORD KeyEvent;

  external MOUSE_EVENT_RECORD MouseEvent;

  external WINDOW_BUFFER_SIZE_RECORD WindowBufferSizeEvent;

  external MENU_EVENT_RECORD MenuEvent;

  external FOCUS_EVENT_RECORD FocusEvent;
}

extension INPUT_RECORD_Extension on INPUT_RECORD {
  KEY_EVENT_RECORD get KeyEvent => this.Event.KeyEvent;
  set KeyEvent(KEY_EVENT_RECORD value) => this.Event.KeyEvent = value;

  MOUSE_EVENT_RECORD get MouseEvent => this.Event.MouseEvent;
  set MouseEvent(MOUSE_EVENT_RECORD value) => this.Event.MouseEvent = value;

  WINDOW_BUFFER_SIZE_RECORD get WindowBufferSizeEvent =>
      this.Event.WindowBufferSizeEvent;
  set WindowBufferSizeEvent(WINDOW_BUFFER_SIZE_RECORD value) =>
      this.Event.WindowBufferSizeEvent = value;

  MENU_EVENT_RECORD get MenuEvent => this.Event.MenuEvent;
  set MenuEvent(MENU_EVENT_RECORD value) => this.Event.MenuEvent = value;

  FOCUS_EVENT_RECORD get FocusEvent => this.Event.FocusEvent;
  set FocusEvent(FOCUS_EVENT_RECORD value) => this.Event.FocusEvent = value;
}

/// Defines the matrix that represents a transform on a message consumer.
/// This matrix can be used to transform pointer input data from client
/// coordinates to screen coordinates, while the inverse can be used to
/// transform pointer input data from screen coordinates to client
/// coordinates.
///
/// {@category Struct}
class INPUT_TRANSFORM extends Struct {
  external _INPUT_TRANSFORM__Anonymous_e__Union Anonymous;
}

/// {@category Struct}
class _INPUT_TRANSFORM__Anonymous_e__Union extends Union {
  external _INPUT_TRANSFORM__Anonymous_e__Union__Anonymous_e__Struct Anonymous;

  @Array(16)
  external Array<Float> m;
}

/// {@category Struct}
class _INPUT_TRANSFORM__Anonymous_e__Union__Anonymous_e__Struct extends Struct {
  @Float()
  external double x11;

  @Float()
  external double x12;

  @Float()
  external double x13;

  @Float()
  external double x14;

  @Float()
  external double x21;

  @Float()
  external double x22;

  @Float()
  external double x23;

  @Float()
  external double x24;

  @Float()
  external double x31;

  @Float()
  external double x32;

  @Float()
  external double x33;

  @Float()
  external double x34;

  @Float()
  external double x41;

  @Float()
  external double x42;

  @Float()
  external double x43;

  @Float()
  external double x44;
}

extension INPUT_TRANSFORM__Anonymous_e__Union_Extension on INPUT_TRANSFORM {
  double get x11 => this.Anonymous.Anonymous.x11;
  set x11(double value) => this.Anonymous.Anonymous.x11 = value;

  double get x12 => this.Anonymous.Anonymous.x12;
  set x12(double value) => this.Anonymous.Anonymous.x12 = value;

  double get x13 => this.Anonymous.Anonymous.x13;
  set x13(double value) => this.Anonymous.Anonymous.x13 = value;

  double get x14 => this.Anonymous.Anonymous.x14;
  set x14(double value) => this.Anonymous.Anonymous.x14 = value;

  double get x21 => this.Anonymous.Anonymous.x21;
  set x21(double value) => this.Anonymous.Anonymous.x21 = value;

  double get x22 => this.Anonymous.Anonymous.x22;
  set x22(double value) => this.Anonymous.Anonymous.x22 = value;

  double get x23 => this.Anonymous.Anonymous.x23;
  set x23(double value) => this.Anonymous.Anonymous.x23 = value;

  double get x24 => this.Anonymous.Anonymous.x24;
  set x24(double value) => this.Anonymous.Anonymous.x24 = value;

  double get x31 => this.Anonymous.Anonymous.x31;
  set x31(double value) => this.Anonymous.Anonymous.x31 = value;

  double get x32 => this.Anonymous.Anonymous.x32;
  set x32(double value) => this.Anonymous.Anonymous.x32 = value;

  double get x33 => this.Anonymous.Anonymous.x33;
  set x33(double value) => this.Anonymous.Anonymous.x33 = value;

  double get x34 => this.Anonymous.Anonymous.x34;
  set x34(double value) => this.Anonymous.Anonymous.x34 = value;

  double get x41 => this.Anonymous.Anonymous.x41;
  set x41(double value) => this.Anonymous.Anonymous.x41 = value;

  double get x42 => this.Anonymous.Anonymous.x42;
  set x42(double value) => this.Anonymous.Anonymous.x42 = value;

  double get x43 => this.Anonymous.Anonymous.x43;
  set x43(double value) => this.Anonymous.Anonymous.x43 = value;

  double get x44 => this.Anonymous.Anonymous.x44;
  set x44(double value) => this.Anonymous.Anonymous.x44 = value;
}

extension INPUT_TRANSFORM_Extension on INPUT_TRANSFORM {
  _INPUT_TRANSFORM__Anonymous_e__Union__Anonymous_e__Struct get Anonymous =>
      this.Anonymous.Anonymous;
  set Anonymous(
          _INPUT_TRANSFORM__Anonymous_e__Union__Anonymous_e__Struct value) =>
      this.Anonymous.Anonymous = value;

  Array<Float> get m => this.Anonymous.m;
  set m(Array<Float> value) => this.Anonymous.m = value;
}

/// The IN_ADDR structure represents an IPv4 Internet address.
///
/// {@category Struct}
class IN_ADDR extends Struct {
  external _IN_ADDR__S_un_e__Union S_un;
}

/// {@category Struct}
class _IN_ADDR__S_un_e__Union extends Union {
  external _IN_ADDR__S_un_e__Union__S_un_b_e__Struct S_un_b;

  external _IN_ADDR__S_un_e__Union__S_un_w_e__Struct S_un_w;

  @Uint32()
  external int S_addr;
}

/// {@category Struct}
class _IN_ADDR__S_un_e__Union__S_un_b_e__Struct extends Struct {
  @Uint8()
  external int s_b1;

  @Uint8()
  external int s_b2;

  @Uint8()
  external int s_b3;

  @Uint8()
  external int s_b4;
}

extension IN_ADDR__S_un_e__Union_Extension on IN_ADDR {
  int get s_b1 => this.S_un.S_un_b.s_b1;
  set s_b1(int value) => this.S_un.S_un_b.s_b1 = value;

  int get s_b2 => this.S_un.S_un_b.s_b2;
  set s_b2(int value) => this.S_un.S_un_b.s_b2 = value;

  int get s_b3 => this.S_un.S_un_b.s_b3;
  set s_b3(int value) => this.S_un.S_un_b.s_b3 = value;

  int get s_b4 => this.S_un.S_un_b.s_b4;
  set s_b4(int value) => this.S_un.S_un_b.s_b4 = value;
}

/// {@category Struct}
class _IN_ADDR__S_un_e__Union__S_un_w_e__Struct extends Struct {
  @Uint16()
  external int s_w1;

  @Uint16()
  external int s_w2;
}

extension IN_ADDR__S_un_e__Union_Extension_1 on IN_ADDR {
  int get s_w1 => this.S_un.S_un_w.s_w1;
  set s_w1(int value) => this.S_un.S_un_w.s_w1 = value;

  int get s_w2 => this.S_un.S_un_w.s_w2;
  set s_w2(int value) => this.S_un.S_un_w.s_w2 = value;
}

extension IN_ADDR_Extension on IN_ADDR {
  _IN_ADDR__S_un_e__Union__S_un_b_e__Struct get S_un_b => this.S_un.S_un_b;
  set S_un_b(_IN_ADDR__S_un_e__Union__S_un_b_e__Struct value) =>
      this.S_un.S_un_b = value;

  _IN_ADDR__S_un_e__Union__S_un_w_e__Struct get S_un_w => this.S_un.S_un_w;
  set S_un_w(_IN_ADDR__S_un_e__Union__S_un_w_e__Struct value) =>
      this.S_un.S_un_w = value;

  int get S_addr => this.S_un.S_addr;
  set S_addr(int value) => this.S_un.S_addr = value;
}

/// The IP_ADAPTER_ADDRESSES structure is the header node for a linked list
/// of addresses for a particular adapter. This structure can simultaneously
/// be used as part of a linked list of IP_ADAPTER_ADDRESSES structures.
///
/// {@category Struct}
class IP_ADAPTER_ADDRESSES_LH extends Struct {
  external _IP_ADAPTER_ADDRESSES_LH__Anonymous1_e__Union Anonymous1;

  external Pointer<IP_ADAPTER_ADDRESSES_LH> Next;

  external Pointer<Utf8> AdapterName;

  external Pointer<IP_ADAPTER_UNICAST_ADDRESS_LH> FirstUnicastAddress;

  external Pointer<IP_ADAPTER_ANYCAST_ADDRESS_XP> FirstAnycastAddress;

  external Pointer<IP_ADAPTER_MULTICAST_ADDRESS_XP> FirstMulticastAddress;

  external Pointer<IP_ADAPTER_DNS_SERVER_ADDRESS_XP> FirstDnsServerAddress;

  external Pointer<Utf16> DnsSuffix;

  external Pointer<Utf16> Description;

  external Pointer<Utf16> FriendlyName;

  @Array(8)
  external Array<Uint8> PhysicalAddress;

  @Uint32()
  external int PhysicalAddressLength;

  external _IP_ADAPTER_ADDRESSES_LH__Anonymous2_e__Union Anonymous2;

  @Uint32()
  external int Mtu;

  @Uint32()
  external int IfType;

  @Int32()
  external int OperStatus;

  @Uint32()
  external int Ipv6IfIndex;

  @Array(16)
  external Array<Uint32> ZoneIndices;

  external Pointer<IP_ADAPTER_PREFIX_XP> FirstPrefix;

  @Uint64()
  external int TransmitLinkSpeed;

  @Uint64()
  external int ReceiveLinkSpeed;

  external Pointer<IP_ADAPTER_WINS_SERVER_ADDRESS_LH> FirstWinsServerAddress;

  external Pointer<IP_ADAPTER_GATEWAY_ADDRESS_LH> FirstGatewayAddress;

  @Uint32()
  external int Ipv4Metric;

  @Uint32()
  external int Ipv6Metric;

  external NET_LUID_LH Luid;

  external SOCKET_ADDRESS Dhcpv4Server;

  @Uint32()
  external int CompartmentId;

  external GUID NetworkGuid;

  @Int32()
  external int ConnectionType;

  @Int32()
  external int TunnelType;

  external SOCKET_ADDRESS Dhcpv6Server;

  @Array(130)
  external Array<Uint8> Dhcpv6ClientDuid;

  @Uint32()
  external int Dhcpv6ClientDuidLength;

  @Uint32()
  external int Dhcpv6Iaid;

  external Pointer<IP_ADAPTER_DNS_SUFFIX> FirstDnsSuffix;
}

/// {@category Struct}
class _IP_ADAPTER_ADDRESSES_LH__Anonymous1_e__Union extends Union {
  @Uint64()
  external int Alignment;

  external _IP_ADAPTER_ADDRESSES_LH__Anonymous1_e__Union__Anonymous_e__Struct
      Anonymous;
}

/// {@category Struct}
class _IP_ADAPTER_ADDRESSES_LH__Anonymous1_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int Length;

  @Uint32()
  external int IfIndex;
}

extension IP_ADAPTER_ADDRESSES_LH__Anonymous1_e__Union_Extension
    on IP_ADAPTER_ADDRESSES_LH {
  int get Length => this.Anonymous1.Anonymous.Length;
  set Length(int value) => this.Anonymous1.Anonymous.Length = value;

  int get IfIndex => this.Anonymous1.Anonymous.IfIndex;
  set IfIndex(int value) => this.Anonymous1.Anonymous.IfIndex = value;
}

extension IP_ADAPTER_ADDRESSES_LH_Extension on IP_ADAPTER_ADDRESSES_LH {
  int get Alignment => this.Anonymous1.Alignment;
  set Alignment(int value) => this.Anonymous1.Alignment = value;

  _IP_ADAPTER_ADDRESSES_LH__Anonymous1_e__Union__Anonymous_e__Struct
      get Anonymous => this.Anonymous1.Anonymous;
  set Anonymous(
          _IP_ADAPTER_ADDRESSES_LH__Anonymous1_e__Union__Anonymous_e__Struct
              value) =>
      this.Anonymous1.Anonymous = value;
}

/// {@category Struct}
class _IP_ADAPTER_ADDRESSES_LH__Anonymous2_e__Union extends Union {
  @Uint32()
  external int Flags;

  external _IP_ADAPTER_ADDRESSES_LH__Anonymous2_e__Union__Anonymous_e__Struct
      Anonymous;
}

/// {@category Struct}
class _IP_ADAPTER_ADDRESSES_LH__Anonymous2_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int bitfield;
}

extension IP_ADAPTER_ADDRESSES_LH__Anonymous2_e__Union_Extension
    on IP_ADAPTER_ADDRESSES_LH {
  int get bitfield => this.Anonymous2.Anonymous.bitfield;
  set bitfield(int value) => this.Anonymous2.Anonymous.bitfield = value;
}

extension IP_ADAPTER_ADDRESSES_LH_Extension_1 on IP_ADAPTER_ADDRESSES_LH {
  int get Flags => this.Anonymous2.Flags;
  set Flags(int value) => this.Anonymous2.Flags = value;

  _IP_ADAPTER_ADDRESSES_LH__Anonymous2_e__Union__Anonymous_e__Struct
      get Anonymous => this.Anonymous2.Anonymous;
  set Anonymous(
          _IP_ADAPTER_ADDRESSES_LH__Anonymous2_e__Union__Anonymous_e__Struct
              value) =>
      this.Anonymous2.Anonymous = value;
}

/// The IP_ADAPTER_ANYCAST_ADDRESS structure stores a single anycast IP
/// address in a linked list of addresses for a particular adapter.
///
/// {@category Struct}
class IP_ADAPTER_ANYCAST_ADDRESS_XP extends Struct {
  external _IP_ADAPTER_ANYCAST_ADDRESS_XP__Anonymous_e__Union Anonymous;

  external Pointer<IP_ADAPTER_ANYCAST_ADDRESS_XP> Next;

  external SOCKET_ADDRESS Address;
}

/// {@category Struct}
class _IP_ADAPTER_ANYCAST_ADDRESS_XP__Anonymous_e__Union extends Union {
  @Uint64()
  external int Alignment;

  external _IP_ADAPTER_ANYCAST_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
      Anonymous;
}

/// {@category Struct}
class _IP_ADAPTER_ANYCAST_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int Length;

  @Uint32()
  external int Flags;
}

extension IP_ADAPTER_ANYCAST_ADDRESS_XP__Anonymous_e__Union_Extension
    on IP_ADAPTER_ANYCAST_ADDRESS_XP {
  int get Length => this.Anonymous.Anonymous.Length;
  set Length(int value) => this.Anonymous.Anonymous.Length = value;

  int get Flags => this.Anonymous.Anonymous.Flags;
  set Flags(int value) => this.Anonymous.Anonymous.Flags = value;
}

extension IP_ADAPTER_ANYCAST_ADDRESS_XP_Extension
    on IP_ADAPTER_ANYCAST_ADDRESS_XP {
  int get Alignment => this.Anonymous.Alignment;
  set Alignment(int value) => this.Anonymous.Alignment = value;

  _IP_ADAPTER_ANYCAST_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
      get Anonymous => this.Anonymous.Anonymous;
  set Anonymous(
          _IP_ADAPTER_ANYCAST_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
              value) =>
      this.Anonymous.Anonymous = value;
}

/// The IP_ADAPTER_DNS_SERVER_ADDRESS structure stores a single DNS server
/// address in a linked list of DNS server addresses for a particular
/// adapter.
///
/// {@category Struct}
class IP_ADAPTER_DNS_SERVER_ADDRESS_XP extends Struct {
  external _IP_ADAPTER_DNS_SERVER_ADDRESS_XP__Anonymous_e__Union Anonymous;

  external Pointer<IP_ADAPTER_DNS_SERVER_ADDRESS_XP> Next;

  external SOCKET_ADDRESS Address;
}

/// {@category Struct}
class _IP_ADAPTER_DNS_SERVER_ADDRESS_XP__Anonymous_e__Union extends Union {
  @Uint64()
  external int Alignment;

  external _IP_ADAPTER_DNS_SERVER_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
      Anonymous;
}

/// {@category Struct}
class _IP_ADAPTER_DNS_SERVER_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int Length;

  @Uint32()
  external int Reserved;
}

extension IP_ADAPTER_DNS_SERVER_ADDRESS_XP__Anonymous_e__Union_Extension
    on IP_ADAPTER_DNS_SERVER_ADDRESS_XP {
  int get Length => this.Anonymous.Anonymous.Length;
  set Length(int value) => this.Anonymous.Anonymous.Length = value;

  int get Reserved => this.Anonymous.Anonymous.Reserved;
  set Reserved(int value) => this.Anonymous.Anonymous.Reserved = value;
}

extension IP_ADAPTER_DNS_SERVER_ADDRESS_XP_Extension
    on IP_ADAPTER_DNS_SERVER_ADDRESS_XP {
  int get Alignment => this.Anonymous.Alignment;
  set Alignment(int value) => this.Anonymous.Alignment = value;

  _IP_ADAPTER_DNS_SERVER_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
      get Anonymous => this.Anonymous.Anonymous;
  set Anonymous(
          _IP_ADAPTER_DNS_SERVER_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
              value) =>
      this.Anonymous.Anonymous = value;
}

/// The IP_ADAPTER_DNS_SUFFIX structure stores a DNS suffix in a linked list
/// of DNS suffixes for a particular adapter.
///
/// {@category Struct}
class IP_ADAPTER_DNS_SUFFIX extends Struct {
  external Pointer<IP_ADAPTER_DNS_SUFFIX> Next;

  @Array(256)
  external Array<Uint16> _String_;

  String get String_ {
    final charCodes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (_String_[i] == 0x00) break;
      charCodes.add(_String_[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set String_(String value) {
    final stringToStore = value.padRight(256, '\x00');
    for (var i = 0; i < 256; i++) {
      _String_[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// The IP_ADAPTER_GATEWAY_ADDRESS structure stores a single gateway address
/// in a linked list of gateway addresses for a particular adapter.
///
/// {@category Struct}
class IP_ADAPTER_GATEWAY_ADDRESS_LH extends Struct {
  external _IP_ADAPTER_GATEWAY_ADDRESS_LH__Anonymous_e__Union Anonymous;

  external Pointer<IP_ADAPTER_GATEWAY_ADDRESS_LH> Next;

  external SOCKET_ADDRESS Address;
}

/// {@category Struct}
class _IP_ADAPTER_GATEWAY_ADDRESS_LH__Anonymous_e__Union extends Union {
  @Uint64()
  external int Alignment;

  external _IP_ADAPTER_GATEWAY_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
      Anonymous;
}

/// {@category Struct}
class _IP_ADAPTER_GATEWAY_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int Length;

  @Uint32()
  external int Reserved;
}

extension IP_ADAPTER_GATEWAY_ADDRESS_LH__Anonymous_e__Union_Extension
    on IP_ADAPTER_GATEWAY_ADDRESS_LH {
  int get Length => this.Anonymous.Anonymous.Length;
  set Length(int value) => this.Anonymous.Anonymous.Length = value;

  int get Reserved => this.Anonymous.Anonymous.Reserved;
  set Reserved(int value) => this.Anonymous.Anonymous.Reserved = value;
}

extension IP_ADAPTER_GATEWAY_ADDRESS_LH_Extension
    on IP_ADAPTER_GATEWAY_ADDRESS_LH {
  int get Alignment => this.Anonymous.Alignment;
  set Alignment(int value) => this.Anonymous.Alignment = value;

  _IP_ADAPTER_GATEWAY_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
      get Anonymous => this.Anonymous.Anonymous;
  set Anonymous(
          _IP_ADAPTER_GATEWAY_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
              value) =>
      this.Anonymous.Anonymous = value;
}

/// The IP_ADAPTER_INDEX_MAP structure stores the interface index associated
/// with a network adapter with IPv4 enabled together with the name of the
/// network adapter.
///
/// {@category Struct}
class IP_ADAPTER_INDEX_MAP extends Struct {
  @Uint32()
  external int Index;

  @Array(128)
  external Array<Uint16> _Name;

  String get Name {
    final charCodes = <int>[];
    for (var i = 0; i < 128; i++) {
      if (_Name[i] == 0x00) break;
      charCodes.add(_Name[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set Name(String value) {
    final stringToStore = value.padRight(128, '\x00');
    for (var i = 0; i < 128; i++) {
      _Name[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// The IP_ADAPTER_MULTICAST_ADDRESS structure stores a single multicast
/// address in a linked-list of addresses for a particular adapter.
///
/// {@category Struct}
class IP_ADAPTER_MULTICAST_ADDRESS_XP extends Struct {
  external _IP_ADAPTER_MULTICAST_ADDRESS_XP__Anonymous_e__Union Anonymous;

  external Pointer<IP_ADAPTER_MULTICAST_ADDRESS_XP> Next;

  external SOCKET_ADDRESS Address;
}

/// {@category Struct}
class _IP_ADAPTER_MULTICAST_ADDRESS_XP__Anonymous_e__Union extends Union {
  @Uint64()
  external int Alignment;

  external _IP_ADAPTER_MULTICAST_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
      Anonymous;
}

/// {@category Struct}
class _IP_ADAPTER_MULTICAST_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int Length;

  @Uint32()
  external int Flags;
}

extension IP_ADAPTER_MULTICAST_ADDRESS_XP__Anonymous_e__Union_Extension
    on IP_ADAPTER_MULTICAST_ADDRESS_XP {
  int get Length => this.Anonymous.Anonymous.Length;
  set Length(int value) => this.Anonymous.Anonymous.Length = value;

  int get Flags => this.Anonymous.Anonymous.Flags;
  set Flags(int value) => this.Anonymous.Anonymous.Flags = value;
}

extension IP_ADAPTER_MULTICAST_ADDRESS_XP_Extension
    on IP_ADAPTER_MULTICAST_ADDRESS_XP {
  int get Alignment => this.Anonymous.Alignment;
  set Alignment(int value) => this.Anonymous.Alignment = value;

  _IP_ADAPTER_MULTICAST_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
      get Anonymous => this.Anonymous.Anonymous;
  set Anonymous(
          _IP_ADAPTER_MULTICAST_ADDRESS_XP__Anonymous_e__Union__Anonymous_e__Struct
              value) =>
      this.Anonymous.Anonymous = value;
}

/// The IP_ADAPTER_PREFIX structure stores an IP address prefix.
///
/// {@category Struct}
class IP_ADAPTER_PREFIX_XP extends Struct {
  external _IP_ADAPTER_PREFIX_XP__Anonymous_e__Union Anonymous;

  external Pointer<IP_ADAPTER_PREFIX_XP> Next;

  external SOCKET_ADDRESS Address;

  @Uint32()
  external int PrefixLength;
}

/// {@category Struct}
class _IP_ADAPTER_PREFIX_XP__Anonymous_e__Union extends Union {
  @Uint64()
  external int Alignment;

  external _IP_ADAPTER_PREFIX_XP__Anonymous_e__Union__Anonymous_e__Struct
      Anonymous;
}

/// {@category Struct}
class _IP_ADAPTER_PREFIX_XP__Anonymous_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int Length;

  @Uint32()
  external int Flags;
}

extension IP_ADAPTER_PREFIX_XP__Anonymous_e__Union_Extension
    on IP_ADAPTER_PREFIX_XP {
  int get Length => this.Anonymous.Anonymous.Length;
  set Length(int value) => this.Anonymous.Anonymous.Length = value;

  int get Flags => this.Anonymous.Anonymous.Flags;
  set Flags(int value) => this.Anonymous.Anonymous.Flags = value;
}

extension IP_ADAPTER_PREFIX_XP_Extension on IP_ADAPTER_PREFIX_XP {
  int get Alignment => this.Anonymous.Alignment;
  set Alignment(int value) => this.Anonymous.Alignment = value;

  _IP_ADAPTER_PREFIX_XP__Anonymous_e__Union__Anonymous_e__Struct
      get Anonymous => this.Anonymous.Anonymous;
  set Anonymous(
          _IP_ADAPTER_PREFIX_XP__Anonymous_e__Union__Anonymous_e__Struct
              value) =>
      this.Anonymous.Anonymous = value;
}

/// The IP_ADAPTER_UNICAST_ADDRESS structure stores a single unicast IP
/// address in a linked list of IP addresses for a particular adapter.
///
/// {@category Struct}
class IP_ADAPTER_UNICAST_ADDRESS_LH extends Struct {
  external _IP_ADAPTER_UNICAST_ADDRESS_LH__Anonymous_e__Union Anonymous;

  external Pointer<IP_ADAPTER_UNICAST_ADDRESS_LH> Next;

  external SOCKET_ADDRESS Address;

  @Int32()
  external int PrefixOrigin;

  @Int32()
  external int SuffixOrigin;

  @Int32()
  external int DadState;

  @Uint32()
  external int ValidLifetime;

  @Uint32()
  external int PreferredLifetime;

  @Uint32()
  external int LeaseLifetime;

  @Uint8()
  external int OnLinkPrefixLength;
}

/// {@category Struct}
class _IP_ADAPTER_UNICAST_ADDRESS_LH__Anonymous_e__Union extends Union {
  @Uint64()
  external int Alignment;

  external _IP_ADAPTER_UNICAST_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
      Anonymous;
}

/// {@category Struct}
class _IP_ADAPTER_UNICAST_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int Length;

  @Uint32()
  external int Flags;
}

extension IP_ADAPTER_UNICAST_ADDRESS_LH__Anonymous_e__Union_Extension
    on IP_ADAPTER_UNICAST_ADDRESS_LH {
  int get Length => this.Anonymous.Anonymous.Length;
  set Length(int value) => this.Anonymous.Anonymous.Length = value;

  int get Flags => this.Anonymous.Anonymous.Flags;
  set Flags(int value) => this.Anonymous.Anonymous.Flags = value;
}

extension IP_ADAPTER_UNICAST_ADDRESS_LH_Extension
    on IP_ADAPTER_UNICAST_ADDRESS_LH {
  int get Alignment => this.Anonymous.Alignment;
  set Alignment(int value) => this.Anonymous.Alignment = value;

  _IP_ADAPTER_UNICAST_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
      get Anonymous => this.Anonymous.Anonymous;
  set Anonymous(
          _IP_ADAPTER_UNICAST_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
              value) =>
      this.Anonymous.Anonymous = value;
}

/// The IP_ADAPTER_WINS_SERVER_ADDRESS structure stores a single Windows
/// Internet Name Service (WINS) server address in a linked list of WINS
/// server addresses for a particular adapter.
///
/// {@category Struct}
class IP_ADAPTER_WINS_SERVER_ADDRESS_LH extends Struct {
  external _IP_ADAPTER_WINS_SERVER_ADDRESS_LH__Anonymous_e__Union Anonymous;

  external Pointer<IP_ADAPTER_WINS_SERVER_ADDRESS_LH> Next;

  external SOCKET_ADDRESS Address;
}

/// {@category Struct}
class _IP_ADAPTER_WINS_SERVER_ADDRESS_LH__Anonymous_e__Union extends Union {
  @Uint64()
  external int Alignment;

  external _IP_ADAPTER_WINS_SERVER_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
      Anonymous;
}

/// {@category Struct}
class _IP_ADAPTER_WINS_SERVER_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
    extends Struct {
  @Uint32()
  external int Length;

  @Uint32()
  external int Reserved;
}

extension IP_ADAPTER_WINS_SERVER_ADDRESS_LH__Anonymous_e__Union_Extension
    on IP_ADAPTER_WINS_SERVER_ADDRESS_LH {
  int get Length => this.Anonymous.Anonymous.Length;
  set Length(int value) => this.Anonymous.Anonymous.Length = value;

  int get Reserved => this.Anonymous.Anonymous.Reserved;
  set Reserved(int value) => this.Anonymous.Anonymous.Reserved = value;
}

extension IP_ADAPTER_WINS_SERVER_ADDRESS_LH_Extension
    on IP_ADAPTER_WINS_SERVER_ADDRESS_LH {
  int get Alignment => this.Anonymous.Alignment;
  set Alignment(int value) => this.Anonymous.Alignment = value;

  _IP_ADAPTER_WINS_SERVER_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
      get Anonymous => this.Anonymous.Anonymous;
  set Anonymous(
          _IP_ADAPTER_WINS_SERVER_ADDRESS_LH__Anonymous_e__Union__Anonymous_e__Struct
              value) =>
      this.Anonymous.Anonymous = value;
}

/// The IP_ADDRESS_STRING structure stores an IPv4 address in dotted decimal
/// notation. The IP_ADDRESS_STRING structure definition is also the type
/// definition for the IP_MASK_STRING structure.
///
/// {@category Struct}
class IP_ADDRESS_STRING extends Struct {
  @Array(16)
  external Array<Uint8> String_;
}

/// The IP_ADDR_STRING structure represents a node in a linked-list of IPv4
/// addresses.
///
/// {@category Struct}
class IP_ADDR_STRING extends Struct {
  external Pointer<IP_ADDR_STRING> Next;

  external IP_ADDRESS_STRING IpAddress;

  external IP_ADDRESS_STRING IpMask;

  @Uint32()
  external int Context;
}

/// The IP_INTERFACE_INFO structure contains a list of the network interface
/// adapters with IPv4 enabled on the local system.
///
/// {@category Struct}
class IP_INTERFACE_INFO extends Struct {
  @Int32()
  external int NumAdapters;

  @Array(1)
  external Array<IP_ADAPTER_INDEX_MAP> Adapter;
}

/// The IP_PER_ADAPTER_INFO structure contains information specific to a
/// particular adapter.
///
/// {@category Struct}
class IP_PER_ADAPTER_INFO_W2KSP1 extends Struct {
  @Uint32()
  external int AutoconfigEnabled;

  @Uint32()
  external int AutoconfigActive;

  external Pointer<IP_ADDR_STRING> CurrentDnsServer;

  external IP_ADDR_STRING DnsServerList;
}

/// Contains a list of item identifiers.
///
/// {@category Struct}
@Packed(1)
class ITEMIDLIST extends Struct {
  external SHITEMID mkid;
}

/// The JOB_INFO_1 structure specifies print-job information such as the
/// job-identifier value, the name of the printer for which the job is
/// spooled, the name of the machine that created the print job, the name of
/// the user that owns the print job, and so on.
///
/// {@category Struct}
class JOB_INFO_1 extends Struct {
  @Uint32()
  external int JobId;

  external Pointer<Utf16> pPrinterName;

  external Pointer<Utf16> pMachineName;

  external Pointer<Utf16> pUserName;

  external Pointer<Utf16> pDocument;

  external Pointer<Utf16> pDatatype;

  external Pointer<Utf16> pStatus;

  @Uint32()
  external int Status;

  @Uint32()
  external int Priority;

  @Uint32()
  external int Position;

  @Uint32()
  external int TotalPages;

  @Uint32()
  external int PagesPrinted;

  external SYSTEMTIME Submitted;
}

/// Contains information about a low-level keyboard input event.
///
/// {@category Struct}
class KBDLLHOOKSTRUCT extends Struct {
  @Uint32()
  external int vkCode;

  @Uint32()
  external int scanCode;

  @Uint32()
  external int flags;

  @Uint32()
  external int time;

  @IntPtr()
  external int dwExtraInfo;
}

/// Contains information about a simulated keyboard event.
///
/// {@category Struct}
class KEYBDINPUT extends Struct {
  @Uint16()
  external int wVk;

  @Uint16()
  external int wScan;

  @Uint32()
  external int dwFlags;

  @Uint32()
  external int time;

  @IntPtr()
  external int dwExtraInfo;
}

/// Describes a keyboard input event in a console INPUT_RECORD structure.
///
/// {@category Struct}
class KEY_EVENT_RECORD extends Struct {
  @Int32()
  external int bKeyDown;

  @Uint16()
  external int wRepeatCount;

  @Uint16()
  external int wVirtualKeyCode;

  @Uint16()
  external int wVirtualScanCode;

  external _KEY_EVENT_RECORD__uChar_e__Union uChar;

  @Uint32()
  external int dwControlKeyState;
}

/// {@category Struct}
class _KEY_EVENT_RECORD__uChar_e__Union extends Union {
  @Uint16()
  external int UnicodeChar;

  @Uint8()
  external int AsciiChar;
}

extension KEY_EVENT_RECORD_Extension on KEY_EVENT_RECORD {
  int get UnicodeChar => this.uChar.UnicodeChar;
  set UnicodeChar(int value) => this.uChar.UnicodeChar = value;

  int get AsciiChar => this.uChar.AsciiChar;
  set AsciiChar(int value) => this.uChar.AsciiChar = value;
}

/// Defines the specifics of a known folder.
///
/// {@category Struct}
class KNOWNFOLDER_DEFINITION extends Struct {
  @Int32()
  external int category;

  external Pointer<Utf16> pszName;

  external Pointer<Utf16> pszDescription;

  external GUID fidParent;

  external Pointer<Utf16> pszRelativePath;

  external Pointer<Utf16> pszParsingName;

  external Pointer<Utf16> pszTooltip;

  external Pointer<Utf16> pszLocalizedName;

  external Pointer<Utf16> pszIcon;

  external Pointer<Utf16> pszSecurity;

  @Uint32()
  external int dwAttributes;

  @Uint32()
  external int kfdFlags;

  external GUID ftidType;
}

/// The L2_NOTIFICATION_DATA structure is used by the IHV Extensions DLL to
/// send notifications to any service or applications that has registered
/// for the notification.
///
/// {@category Struct}
class L2_NOTIFICATION_DATA extends Struct {
  @Uint32()
  external int NotificationSource;

  @Uint32()
  external int NotificationCode;

  external GUID InterfaceGuid;

  @Uint32()
  external int dwDataSize;

  external Pointer pData;
}

/// Contains the time of the last input.
///
/// {@category Struct}
class LASTINPUTINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int dwTime;
}

/// The LOGBRUSH structure defines the style, color, and pattern of a
/// physical brush. It is used by the CreateBrushIndirect and ExtCreatePen
/// functions.
///
/// {@category Struct}
class LOGBRUSH extends Struct {
  @Uint32()
  external int lbStyle;

  @Uint32()
  external int lbColor;

  @IntPtr()
  external int lbHatch;
}

/// The LOGFONT structure defines the attributes of a font.
///
/// {@category Struct}
class LOGFONT extends Struct {
  @Int32()
  external int lfHeight;

  @Int32()
  external int lfWidth;

  @Int32()
  external int lfEscapement;

  @Int32()
  external int lfOrientation;

  @Int32()
  external int lfWeight;

  @Uint8()
  external int lfItalic;

  @Uint8()
  external int lfUnderline;

  @Uint8()
  external int lfStrikeOut;

  @Uint8()
  external int lfCharSet;

  @Uint8()
  external int lfOutPrecision;

  @Uint8()
  external int lfClipPrecision;

  @Uint8()
  external int lfQuality;

  @Uint8()
  external int lfPitchAndFamily;

  @Array(32)
  external Array<Uint16> _lfFaceName;

  String get lfFaceName {
    final charCodes = <int>[];
    for (var i = 0; i < 32; i++) {
      if (_lfFaceName[i] == 0x00) break;
      charCodes.add(_lfFaceName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set lfFaceName(String value) {
    final stringToStore = value.padRight(32, '\x00');
    for (var i = 0; i < 32; i++) {
      _lfFaceName[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// The LOGPALETTE structure defines a logical palette.
///
/// {@category Struct}
class LOGPALETTE extends Struct {
  @Uint16()
  external int palVersion;

  @Uint16()
  external int palNumEntries;

  @Array(1)
  external Array<PALETTEENTRY> palPalEntry;
}

/// A Locally Unique Identifier (LUID). This is a value guaranteed to be
/// unique only on the system on which it was generated. The uniqueness of a
/// locally unique identifier is guaranteed only until the system is
/// restarted.
///
/// {@category Struct}
class LUID extends Struct {
  @Uint32()
  external int LowPart;

  @Int32()
  external int HighPart;
}

/// Describes a color transformation matrix that a magnifier control uses to
/// apply a color effect to magnified screen content.
///
/// {@category Struct}
class MAGCOLOREFFECT extends Struct {
  @Array(25)
  external Array<Float> transform;
}

/// Describes an image format.
///
/// {@category Struct}
class MAGIMAGEHEADER extends Struct {
  @Uint32()
  external int width;

  @Uint32()
  external int height;

  external GUID format;

  @Uint32()
  external int stride;

  @Uint32()
  external int offset;

  @IntPtr()
  external int cbSize;
}

/// Describes a transformation matrix that a magnifier control uses to
/// magnify screen content.
///
/// {@category Struct}
class MAGTRANSFORM extends Struct {
  @Array(9)
  external Array<Float> v;
}

/// Returned by the GetThemeMargins function to define the margins of
/// windows that have visual styles applied.
///
/// {@category Struct}
class MARGINS extends Struct {
  @Int32()
  external int cxLeftWidth;

  @Int32()
  external int cxRightWidth;

  @Int32()
  external int cyTopHeight;

  @Int32()
  external int cyBottomHeight;
}

/// The MCI_OPEN_PARMS structure contains information for the MCI_OPEN
/// command.
///
/// {@category Struct}
@Packed(1)
class MCI_OPEN_PARMS extends Struct {
  @IntPtr()
  external int dwCallback;

  @Uint32()
  external int wDeviceID;

  external Pointer<Utf16> lpstrDeviceType;

  external Pointer<Utf16> lpstrElementName;

  external Pointer<Utf16> lpstrAlias;
}

/// The MCI_PLAY_PARMS structure contains positioning information for the
/// MCI_PLAY command.
///
/// {@category Struct}
@Packed(1)
class MCI_PLAY_PARMS extends Struct {
  @IntPtr()
  external int dwCallback;

  @Uint32()
  external int dwFrom;

  @Uint32()
  external int dwTo;
}

/// The MCI_SEEK_PARMS structure contains positioning information for the
/// MCI_SEEK command.
///
/// {@category Struct}
@Packed(1)
class MCI_SEEK_PARMS extends Struct {
  @IntPtr()
  external int dwCallback;

  @Uint32()
  external int dwTo;
}

/// The MCI_STATUS_PARMS structure contains information for the MCI_STATUS
/// command.
///
/// {@category Struct}
@Packed(1)
class MCI_STATUS_PARMS extends Struct {
  @IntPtr()
  external int dwCallback;

  @IntPtr()
  external int dwReturn;

  @Uint32()
  external int dwItem;

  @Uint32()
  external int dwTrack;
}

/// Contains information about a menu.
///
/// {@category Struct}
class MENUINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int fMask;

  @Uint32()
  external int dwStyle;

  @Uint32()
  external int cyMax;

  @IntPtr()
  external int hbrBack;

  @Uint32()
  external int dwContextHelpID;

  @IntPtr()
  external int dwMenuData;
}

/// Contains information about a menu item.
///
/// {@category Struct}
class MENUITEMINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int fMask;

  @Uint32()
  external int fType;

  @Uint32()
  external int fState;

  @Uint32()
  external int wID;

  @IntPtr()
  external int hSubMenu;

  @IntPtr()
  external int hbmpChecked;

  @IntPtr()
  external int hbmpUnchecked;

  @IntPtr()
  external int dwItemData;

  external Pointer<Utf16> dwTypeData;

  @Uint32()
  external int cch;

  @IntPtr()
  external int hbmpItem;
}

/// Defines a menu item in a menu template.
///
/// {@category Struct}
class MENUITEMTEMPLATE extends Struct {
  @Uint16()
  external int mtOption;

  @Uint16()
  external int mtID;

  @Array(1)
  external Array<Uint16> _mtString;

  String get mtString {
    final charCodes = <int>[];
    for (var i = 0; i < 1; i++) {
      if (_mtString[i] == 0x00) break;
      charCodes.add(_mtString[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set mtString(String value) {
    final stringToStore = value.padRight(1, '\x00');
    for (var i = 0; i < 1; i++) {
      _mtString[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// Defines the header for a menu template. A complete menu template
/// consists of a header and one or more menu item lists.
///
/// {@category Struct}
class MENUITEMTEMPLATEHEADER extends Struct {
  @Uint16()
  external int versionNumber;

  @Uint16()
  external int offset;
}

/// Describes a menu event in a console INPUT_RECORD structure. These events
/// are used internally and should be ignored.
///
/// {@category Struct}
class MENU_EVENT_RECORD extends Struct {
  @Uint32()
  external int dwCommandId;
}

/// Defines the metafile picture format used for exchanging metafile data
/// through the clipboard.
///
/// {@category Struct}
class METAFILEPICT extends Struct {
  @Int32()
  external int mm;

  @Int32()
  external int xExt;

  @Int32()
  external int yExt;

  @IntPtr()
  external int hMF;
}

/// The MIDIEVENT structure describes a MIDI event in a stream buffer.
///
/// {@category Struct}
@Packed(1)
class MIDIEVENT extends Struct {
  @Uint32()
  external int dwDeltaTime;

  @Uint32()
  external int dwStreamID;

  @Uint32()
  external int dwEvent;

  @Array(1)
  external Array<Uint32> dwParms;
}

/// The MIDIHDR structure defines the header used to identify a MIDI
/// system-exclusive or stream buffer.
///
/// {@category Struct}
@Packed(1)
class MIDIHDR extends Struct {
  external Pointer<Utf8> lpData;

  @Uint32()
  external int dwBufferLength;

  @Uint32()
  external int dwBytesRecorded;

  @IntPtr()
  external int dwUser;

  @Uint32()
  external int dwFlags;

  external Pointer<MIDIHDR> lpNext;

  @IntPtr()
  external int reserved;

  @Uint32()
  external int dwOffset;

  @Array(8)
  external Array<IntPtr> dwReserved;
}

/// The MIDIINCAPS structure describes the capabilities of a MIDI input
/// device.
///
/// {@category Struct}
@Packed(1)
class MIDIINCAPS extends Struct {
  @Uint16()
  external int wMid;

  @Uint16()
  external int wPid;

  @Uint32()
  external int vDriverVersion;

  @Array(32)
  external Array<Uint16> _szPname;

  String get szPname {
    final charCodes = <int>[];
    for (var i = 0; i < 32; i++) {
      if (_szPname[i] == 0x00) break;
      charCodes.add(_szPname[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szPname(String value) {
    final stringToStore = value.padRight(32, '\x00');
    for (var i = 0; i < 32; i++) {
      _szPname[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint32()
  external int dwSupport;
}

/// The MIDIOUTCAPS structure describes the capabilities of a MIDI output
/// device.
///
/// {@category Struct}
@Packed(1)
class MIDIOUTCAPS extends Struct {
  @Uint16()
  external int wMid;

  @Uint16()
  external int wPid;

  @Uint32()
  external int vDriverVersion;

  @Array(32)
  external Array<Uint16> _szPname;

  String get szPname {
    final charCodes = <int>[];
    for (var i = 0; i < 32; i++) {
      if (_szPname[i] == 0x00) break;
      charCodes.add(_szPname[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szPname(String value) {
    final stringToStore = value.padRight(32, '\x00');
    for (var i = 0; i < 32; i++) {
      _szPname[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint16()
  external int wTechnology;

  @Uint16()
  external int wVoices;

  @Uint16()
  external int wNotes;

  @Uint16()
  external int wChannelMask;

  @Uint32()
  external int dwSupport;
}

/// The MIDIPROPTEMPO structure contains the tempo property for a stream.
///
/// {@category Struct}
@Packed(1)
class MIDIPROPTEMPO extends Struct {
  @Uint32()
  external int cbStruct;

  @Uint32()
  external int dwTempo;
}

/// The MIDIPROPTIMEDIV structure contains the time division property for a
/// stream.
///
/// {@category Struct}
@Packed(1)
class MIDIPROPTIMEDIV extends Struct {
  @Uint32()
  external int cbStruct;

  @Uint32()
  external int dwTimeDiv;
}

/// The MIDISTRMBUFFVER structure contains version information for a long
/// MIDI event of the MEVT_VERSION type.
///
/// {@category Struct}
@Packed(1)
class MIDISTRMBUFFVER extends Struct {
  @Uint32()
  external int dwVersion;

  @Uint32()
  external int dwMid;

  @Uint32()
  external int dwOEMVersion;
}

/// Contains information about a window's maximized size and position and
/// its minimum and maximum tracking size.
///
/// {@category Struct}
class MINMAXINFO extends Struct {
  external POINT ptReserved;

  external POINT ptMaxSize;

  external POINT ptMaxPosition;

  external POINT ptMinTrackSize;

  external POINT ptMaxTrackSize;
}

/// The MMTIME structure contains timing information for different types of
/// multimedia data.
///
/// {@category Struct}
class MMTIME extends Struct {
  @Uint32()
  external int wType;

  external _MMTIME__u_e__Union u;
}

/// {@category Struct}
class _MMTIME__u_e__Union extends Union {
  @Uint32()
  external int ms;

  @Uint32()
  external int sample;

  @Uint32()
  external int cb;

  @Uint32()
  external int ticks;

  external _MMTIME__u_e__Union__smpte_e__Struct smpte;

  external _MMTIME__u_e__Union__midi_e__Struct midi;
}

/// {@category Struct}
class _MMTIME__u_e__Union__smpte_e__Struct extends Struct {
  @Uint8()
  external int hour;

  @Uint8()
  external int min;

  @Uint8()
  external int sec;

  @Uint8()
  external int frame;

  @Uint8()
  external int fps;

  @Uint8()
  external int dummy;

  @Array(2)
  external Array<Uint8> pad;
}

extension MMTIME__u_e__Union_Extension on MMTIME {
  int get hour => this.u.smpte.hour;
  set hour(int value) => this.u.smpte.hour = value;

  int get min => this.u.smpte.min;
  set min(int value) => this.u.smpte.min = value;

  int get sec => this.u.smpte.sec;
  set sec(int value) => this.u.smpte.sec = value;

  int get frame => this.u.smpte.frame;
  set frame(int value) => this.u.smpte.frame = value;

  int get fps => this.u.smpte.fps;
  set fps(int value) => this.u.smpte.fps = value;

  int get dummy => this.u.smpte.dummy;
  set dummy(int value) => this.u.smpte.dummy = value;

  Array<Uint8> get pad => this.u.smpte.pad;
  set pad(Array<Uint8> value) => this.u.smpte.pad = value;
}

/// {@category Struct}
@Packed(1)
class _MMTIME__u_e__Union__midi_e__Struct extends Struct {
  @Uint32()
  external int songptrpos;
}

extension MMTIME__u_e__Union_Extension_1 on MMTIME {
  int get songptrpos => this.u.midi.songptrpos;
  set songptrpos(int value) => this.u.midi.songptrpos = value;
}

extension MMTIME_Extension on MMTIME {
  int get ms => this.u.ms;
  set ms(int value) => this.u.ms = value;

  int get sample => this.u.sample;
  set sample(int value) => this.u.sample = value;

  int get cb => this.u.cb;
  set cb(int value) => this.u.cb = value;

  int get ticks => this.u.ticks;
  set ticks(int value) => this.u.ticks = value;

  _MMTIME__u_e__Union__smpte_e__Struct get smpte => this.u.smpte;
  set smpte(_MMTIME__u_e__Union__smpte_e__Struct value) => this.u.smpte = value;

  _MMTIME__u_e__Union__midi_e__Struct get midi => this.u.midi;
  set midi(_MMTIME__u_e__Union__midi_e__Struct value) => this.u.midi = value;
}

/// Contains information about the capabilities of a modem.
///
/// {@category Struct}
class MODEMDEVCAPS extends Struct {
  @Uint32()
  external int dwActualSize;

  @Uint32()
  external int dwRequiredSize;

  @Uint32()
  external int dwDevSpecificOffset;

  @Uint32()
  external int dwDevSpecificSize;

  @Uint32()
  external int dwModemProviderVersion;

  @Uint32()
  external int dwModemManufacturerOffset;

  @Uint32()
  external int dwModemManufacturerSize;

  @Uint32()
  external int dwModemModelOffset;

  @Uint32()
  external int dwModemModelSize;

  @Uint32()
  external int dwModemVersionOffset;

  @Uint32()
  external int dwModemVersionSize;

  @Uint32()
  external int dwDialOptions;

  @Uint32()
  external int dwCallSetupFailTimer;

  @Uint32()
  external int dwInactivityTimeout;

  @Uint32()
  external int dwSpeakerVolume;

  @Uint32()
  external int dwSpeakerMode;

  @Uint32()
  external int dwModemOptions;

  @Uint32()
  external int dwMaxDTERate;

  @Uint32()
  external int dwMaxDCERate;

  @Array(1)
  external Array<Uint8> abVariablePortion;
}

/// Contains information about a modem's configuration.
///
/// {@category Struct}
class MODEMSETTINGS extends Struct {
  @Uint32()
  external int dwActualSize;

  @Uint32()
  external int dwRequiredSize;

  @Uint32()
  external int dwDevSpecificOffset;

  @Uint32()
  external int dwDevSpecificSize;

  @Uint32()
  external int dwCallSetupFailTimer;

  @Uint32()
  external int dwInactivityTimeout;

  @Uint32()
  external int dwSpeakerVolume;

  @Uint32()
  external int dwSpeakerMode;

  @Uint32()
  external int dwPreferredModemOptions;

  @Uint32()
  external int dwNegotiatedModemOptions;

  @Uint32()
  external int dwNegotiatedDCERate;

  @Array(1)
  external Array<Uint8> abVariablePortion;
}

/// Contains module data.
///
/// {@category Struct}
class MODLOAD_DATA extends Struct {
  @Uint32()
  external int ssize;

  @Uint32()
  external int ssig;

  external Pointer data;

  @Uint32()
  external int size;

  @Uint32()
  external int flags;
}

/// The MONITORINFO structure contains information about a display monitor.
///
/// {@category Struct}
class MONITORINFO extends Struct {
  @Uint32()
  external int cbSize;

  external RECT rcMonitor;

  external RECT rcWork;

  @Uint32()
  external int dwFlags;
}

/// Contains information about a mouse event passed to a WH_MOUSE hook
/// procedure, MouseProc.
///
/// {@category Struct}
class MOUSEHOOKSTRUCT extends Struct {
  external POINT pt;

  @IntPtr()
  external int hwnd;

  @Uint32()
  external int wHitTestCode;

  @IntPtr()
  external int dwExtraInfo;
}

/// Contains information about a mouse event passed to a WH_MOUSE hook
/// procedure, MouseProc. This is an extension of the MOUSEHOOKSTRUCT
/// structure that includes information about wheel movement or the use of
/// the X button.
///
/// {@category Struct}
class MOUSEHOOKSTRUCTEX extends Struct {
  external MOUSEHOOKSTRUCT Base;

  @Uint32()
  external int mouseData;
}

/// Contains information about a simulated mouse event.
///
/// {@category Struct}
class MOUSEINPUT extends Struct {
  @Int32()
  external int dx;

  @Int32()
  external int dy;

  @Int32()
  external int mouseData;

  @Uint32()
  external int dwFlags;

  @Uint32()
  external int time;

  @IntPtr()
  external int dwExtraInfo;
}

/// Contains information about the mouse's location in screen coordinates.
///
/// {@category Struct}
class MOUSEMOVEPOINT extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;

  @Uint32()
  external int time;

  @IntPtr()
  external int dwExtraInfo;
}

/// Describes a mouse input event in a console INPUT_RECORD structure.
///
/// {@category Struct}
class MOUSE_EVENT_RECORD extends Struct {
  external COORD dwMousePosition;

  @Uint32()
  external int dwButtonState;

  @Uint32()
  external int dwControlKeyState;

  @Uint32()
  external int dwEventFlags;
}

/// Contains message information from a thread's message queue.
///
/// {@category Struct}
class MSG extends Struct {
  @IntPtr()
  external int hwnd;

  @Uint32()
  external int message;

  @IntPtr()
  external int wParam;

  @IntPtr()
  external int lParam;

  @Uint32()
  external int time;

  external POINT pt;
}

/// Contains information about a low-level mouse input event.
///
/// {@category Struct}
class MSLLHOOKSTRUCT extends Struct {
  external POINT pt;

  @Uint32()
  external int mouseData;

  @Uint32()
  external int flags;

  @Uint32()
  external int time;

  @IntPtr()
  external int dwExtraInfo;
}

/// Contains information that an application can use while processing the
/// WM_NCCALCSIZE message to calculate the size, position, and valid
/// contents of the client area of a window.
///
/// {@category Struct}
class NCCALCSIZE_PARAMS extends Struct {
  @Array(3)
  external Array<RECT> rgrc;

  external Pointer<WINDOWPOS> lppos;
}

/// The NDIS_OBJECT_HEADER structure packages the object type, version, and
/// size information that is required in many NDIS 6.0 structures.
///
/// {@category Struct}
class NDIS_OBJECT_HEADER extends Struct {
  @Uint8()
  external int Type;

  @Uint8()
  external int Revision;

  @Uint16()
  external int Size;
}

/// The NET_LUID union is the locally unique identifier (LUID) for a network
/// interface.
///
/// {@category Struct}
class NET_LUID_LH extends Union {
  @Uint64()
  external int Value;

  external _NET_LUID_LH__Info_e__Struct Info;
}

/// {@category Struct}
class _NET_LUID_LH__Info_e__Struct extends Struct {
  @Uint64()
  external int bitfield;
}

extension NET_LUID_LH_Extension on NET_LUID_LH {
  int get bitfield => this.Info.bitfield;
  set bitfield(int value) => this.Info.bitfield = value;
}

/// The NEWTEXTMETRIC structure contains data that describes a physical
/// font.
///
/// {@category Struct}
class NEWTEXTMETRIC extends Struct {
  @Int32()
  external int tmHeight;

  @Int32()
  external int tmAscent;

  @Int32()
  external int tmDescent;

  @Int32()
  external int tmInternalLeading;

  @Int32()
  external int tmExternalLeading;

  @Int32()
  external int tmAveCharWidth;

  @Int32()
  external int tmMaxCharWidth;

  @Int32()
  external int tmWeight;

  @Int32()
  external int tmOverhang;

  @Int32()
  external int tmDigitizedAspectX;

  @Int32()
  external int tmDigitizedAspectY;

  @Uint16()
  external int tmFirstChar;

  @Uint16()
  external int tmLastChar;

  @Uint16()
  external int tmDefaultChar;

  @Uint16()
  external int tmBreakChar;

  @Uint8()
  external int tmItalic;

  @Uint8()
  external int tmUnderlined;

  @Uint8()
  external int tmStruckOut;

  @Uint8()
  external int tmPitchAndFamily;

  @Uint8()
  external int tmCharSet;

  @Uint32()
  external int ntmFlags;

  @Uint32()
  external int ntmSizeEM;

  @Uint32()
  external int ntmCellHeight;

  @Uint32()
  external int ntmAvgWidth;
}

/// Used to specify values that are used by SetSimulatedProfileInfo to
/// override current internet connection profile values in an RDP Child
/// Session to support the simulation of specific metered internet
/// connection conditions.
///
/// {@category Struct}
class NLM_SIMULATED_PROFILE_INFO extends Struct {
  @Array(256)
  external Array<Uint16> _ProfileName;

  String get ProfileName {
    final charCodes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (_ProfileName[i] == 0x00) break;
      charCodes.add(_ProfileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set ProfileName(String value) {
    final stringToStore = value.padRight(256, '\x00');
    for (var i = 0; i < 256; i++) {
      _ProfileName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Int32()
  external int cost;

  @Uint32()
  external int UsageInMegabytes;

  @Uint32()
  external int DataLimitInMegabytes;
}

/// Contains the scalable metrics associated with the nonclient area of a
/// nonminimized window. This structure is used by the
/// SPI_GETNONCLIENTMETRICS and SPI_SETNONCLIENTMETRICS actions of the
/// SystemParametersInfo function.
///
/// {@category Struct}
class NONCLIENTMETRICS extends Struct {
  @Uint32()
  external int cbSize;

  @Int32()
  external int iBorderWidth;

  @Int32()
  external int iScrollWidth;

  @Int32()
  external int iScrollHeight;

  @Int32()
  external int iCaptionWidth;

  @Int32()
  external int iCaptionHeight;

  external LOGFONT lfCaptionFont;

  @Int32()
  external int iSmCaptionWidth;

  @Int32()
  external int iSmCaptionHeight;

  external LOGFONT lfSmCaptionFont;

  @Int32()
  external int iMenuWidth;

  @Int32()
  external int iMenuHeight;

  external LOGFONT lfMenuFont;

  external LOGFONT lfStatusFont;

  external LOGFONT lfMessageFont;

  @Int32()
  external int iPaddedBorderWidth;
}

/// Contains information that the system needs to display notifications in
/// the notification area. Used by Shell_NotifyIcon.
///
/// {@category Struct}
class NOTIFYICONDATA extends Struct {
  @Uint32()
  external int cbSize;

  @IntPtr()
  external int hWnd;

  @Uint32()
  external int uID;

  @Uint32()
  external int uFlags;

  @Uint32()
  external int uCallbackMessage;

  @IntPtr()
  external int hIcon;

  @Array(128)
  external Array<Uint16> _szTip;

  String get szTip {
    final charCodes = <int>[];
    for (var i = 0; i < 128; i++) {
      if (_szTip[i] == 0x00) break;
      charCodes.add(_szTip[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szTip(String value) {
    final stringToStore = value.padRight(128, '\x00');
    for (var i = 0; i < 128; i++) {
      _szTip[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint32()
  external int dwState;

  @Uint32()
  external int dwStateMask;

  @Array(256)
  external Array<Uint16> _szInfo;

  String get szInfo {
    final charCodes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (_szInfo[i] == 0x00) break;
      charCodes.add(_szInfo[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szInfo(String value) {
    final stringToStore = value.padRight(256, '\x00');
    for (var i = 0; i < 256; i++) {
      _szInfo[i] = stringToStore.codeUnitAt(i);
    }
  }

  external _NOTIFYICONDATAW__Anonymous_e__Union Anonymous;

  @Array(64)
  external Array<Uint16> _szInfoTitle;

  String get szInfoTitle {
    final charCodes = <int>[];
    for (var i = 0; i < 64; i++) {
      if (_szInfoTitle[i] == 0x00) break;
      charCodes.add(_szInfoTitle[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szInfoTitle(String value) {
    final stringToStore = value.padRight(64, '\x00');
    for (var i = 0; i < 64; i++) {
      _szInfoTitle[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint32()
  external int dwInfoFlags;

  external GUID guidItem;

  @IntPtr()
  external int hBalloonIcon;
}

/// {@category Struct}
class _NOTIFYICONDATAW__Anonymous_e__Union extends Union {
  @Uint32()
  external int uTimeout;

  @Uint32()
  external int uVersion;
}

extension NOTIFYICONDATAW_Extension on NOTIFYICONDATA {
  int get uTimeout => this.Anonymous.uTimeout;
  set uTimeout(int value) => this.Anonymous.uTimeout = value;

  int get uVersion => this.Anonymous.uVersion;
  set uVersion(int value) => this.Anonymous.uVersion = value;
}

/// The OPENCARDNAME structure contains the information that the
/// GetOpenCardName function uses to initialize a smart card Select Card
/// dialog box. Calling SCardUIDlgSelectCard with OPENCARDNAME_EX is
/// recommended over calling GetOpenCardName with OPENCARDNAME. OPENCARDNAME
/// is provided for backward compatibility.
///
/// {@category Struct}
class OPENCARDNAME extends Struct {
  @Uint32()
  external int dwStructSize;

  @IntPtr()
  external int hwndOwner;

  @IntPtr()
  external int hSCardContext;

  external Pointer<Utf16> lpstrGroupNames;

  @Uint32()
  external int nMaxGroupNames;

  external Pointer<Utf16> lpstrCardNames;

  @Uint32()
  external int nMaxCardNames;

  external Pointer<GUID> rgguidInterfaces;

  @Uint32()
  external int cguidInterfaces;

  external Pointer<Utf16> lpstrRdr;

  @Uint32()
  external int nMaxRdr;

  external Pointer<Utf16> lpstrCard;

  @Uint32()
  external int nMaxCard;

  external Pointer<Utf16> lpstrTitle;

  @Uint32()
  external int dwFlags;

  external Pointer pvUserData;

  @Uint32()
  external int dwShareMode;

  @Uint32()
  external int dwPreferredProtocols;

  @Uint32()
  external int dwActiveProtocol;

  external Pointer<NativeFunction<OpenCardConnProc>> lpfnConnect;

  external Pointer<NativeFunction<OpenCardCheckProc>> lpfnCheck;

  external Pointer<NativeFunction<OpenCardDisconnProc>> lpfnDisconnect;

  @IntPtr()
  external int hCardHandle;
}

/// The OPENCARDNAME_EX structure contains the information that the
/// SCardUIDlgSelectCard function uses to initialize a smart card Select
/// Card dialog box.
///
/// {@category Struct}
class OPENCARDNAME_EX extends Struct {
  @Uint32()
  external int dwStructSize;

  @IntPtr()
  external int hSCardContext;

  @IntPtr()
  external int hwndOwner;

  @Uint32()
  external int dwFlags;

  external Pointer<Utf16> lpstrTitle;

  external Pointer<Utf16> lpstrSearchDesc;

  @IntPtr()
  external int hIcon;

  external Pointer<OPENCARD_SEARCH_CRITERIA> pOpenCardSearchCriteria;

  external Pointer<NativeFunction<OpenCardConnProc>> lpfnConnect;

  external Pointer pvUserData;

  @Uint32()
  external int dwShareMode;

  @Uint32()
  external int dwPreferredProtocols;

  external Pointer<Utf16> lpstrRdr;

  @Uint32()
  external int nMaxRdr;

  external Pointer<Utf16> lpstrCard;

  @Uint32()
  external int nMaxCard;

  @Uint32()
  external int dwActiveProtocol;

  @IntPtr()
  external int hCardHandle;
}

/// The OPENCARD_SEARCH_CRITERIA structure is used by the
/// SCardUIDlgSelectCard function in order to recognize cards that meet the
/// requirements set forth by the caller. You can, however, call
/// SCardUIDlgSelectCard without using this structure.
///
/// {@category Struct}
class OPENCARD_SEARCH_CRITERIA extends Struct {
  @Uint32()
  external int dwStructSize;

  external Pointer<Utf16> lpstrGroupNames;

  @Uint32()
  external int nMaxGroupNames;

  external Pointer<GUID> rgguidInterfaces;

  @Uint32()
  external int cguidInterfaces;

  external Pointer<Utf16> lpstrCardNames;

  @Uint32()
  external int nMaxCardNames;

  external Pointer<NativeFunction<OpenCardCheckProc>> lpfnCheck;

  external Pointer<NativeFunction<OpenCardConnProc>> lpfnConnect;

  external Pointer<NativeFunction<OpenCardDisconnProc>> lpfnDisconnect;

  external Pointer pvUserData;

  @Uint32()
  external int dwShareMode;

  @Uint32()
  external int dwPreferredProtocols;
}

/// Contains information that the GetOpenFileName and GetSaveFileName
/// functions use to initialize an Open or Save As dialog box. After the
/// user closes the dialog box, the system returns information about the
/// user's selection in this structure.
///
/// {@category Struct}
class OPENFILENAME extends Struct {
  @Uint32()
  external int lStructSize;

  @IntPtr()
  external int hwndOwner;

  @IntPtr()
  external int hInstance;

  external Pointer<Utf16> lpstrFilter;

  external Pointer<Utf16> lpstrCustomFilter;

  @Uint32()
  external int nMaxCustFilter;

  @Uint32()
  external int nFilterIndex;

  external Pointer<Utf16> lpstrFile;

  @Uint32()
  external int nMaxFile;

  external Pointer<Utf16> lpstrFileTitle;

  @Uint32()
  external int nMaxFileTitle;

  external Pointer<Utf16> lpstrInitialDir;

  external Pointer<Utf16> lpstrTitle;

  @Uint32()
  external int Flags;

  @Uint16()
  external int nFileOffset;

  @Uint16()
  external int nFileExtension;

  external Pointer<Utf16> lpstrDefExt;

  @IntPtr()
  external int lCustData;

  external Pointer<NativeFunction<OFNHookProc>> lpfnHook;

  external Pointer<Utf16> lpTemplateName;

  external Pointer pvReserved;

  @Uint32()
  external int dwReserved;

  @Uint32()
  external int FlagsEx;
}

/// Contains operating system version information. The information includes
/// major and minor version numbers, a build number, a platform identifier,
/// and information about product suites and the latest Service Pack
/// installed on the system. This structure is used with the GetVersionEx
/// and VerifyVersionInfo functions.
///
/// {@category Struct}
class OSVERSIONINFOEX extends Struct {
  @Uint32()
  external int dwOSVersionInfoSize;

  @Uint32()
  external int dwMajorVersion;

  @Uint32()
  external int dwMinorVersion;

  @Uint32()
  external int dwBuildNumber;

  @Uint32()
  external int dwPlatformId;

  @Array(128)
  external Array<Uint16> _szCSDVersion;

  String get szCSDVersion {
    final charCodes = <int>[];
    for (var i = 0; i < 128; i++) {
      if (_szCSDVersion[i] == 0x00) break;
      charCodes.add(_szCSDVersion[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szCSDVersion(String value) {
    final stringToStore = value.padRight(128, '\x00');
    for (var i = 0; i < 128; i++) {
      _szCSDVersion[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint16()
  external int wServicePackMajor;

  @Uint16()
  external int wServicePackMinor;

  @Uint16()
  external int wSuiteMask;

  @Uint8()
  external int wProductType;

  @Uint8()
  external int wReserved;
}

/// Contains operating system version information. The information includes
/// major and minor version numbers, a build number, a platform identifier,
/// and descriptive text about the operating system. This structure is used
/// with the GetVersionEx function.
///
/// {@category Struct}
class OSVERSIONINFO extends Struct {
  @Uint32()
  external int dwOSVersionInfoSize;

  @Uint32()
  external int dwMajorVersion;

  @Uint32()
  external int dwMinorVersion;

  @Uint32()
  external int dwBuildNumber;

  @Uint32()
  external int dwPlatformId;

  @Array(128)
  external Array<Uint16> _szCSDVersion;

  String get szCSDVersion {
    final charCodes = <int>[];
    for (var i = 0; i < 128; i++) {
      if (_szCSDVersion[i] == 0x00) break;
      charCodes.add(_szCSDVersion[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szCSDVersion(String value) {
    final stringToStore = value.padRight(128, '\x00');
    for (var i = 0; i < 128; i++) {
      _szCSDVersion[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// Contains information used in asynchronous (or overlapped) input and
/// output (I/O).
///
/// {@category Struct}
class OVERLAPPED extends Struct {
  @IntPtr()
  external int Internal;

  @IntPtr()
  external int InternalHigh;

  external _OVERLAPPED__Anonymous_e__Union Anonymous;

  @IntPtr()
  external int hEvent;
}

/// {@category Struct}
class _OVERLAPPED__Anonymous_e__Union extends Union {
  external _OVERLAPPED__Anonymous_e__Union__Anonymous_e__Struct Anonymous;

  external Pointer Pointer_;
}

/// {@category Struct}
class _OVERLAPPED__Anonymous_e__Union__Anonymous_e__Struct extends Struct {
  @Uint32()
  external int Offset;

  @Uint32()
  external int OffsetHigh;
}

extension OVERLAPPED__Anonymous_e__Union_Extension on OVERLAPPED {
  int get Offset => this.Anonymous.Anonymous.Offset;
  set Offset(int value) => this.Anonymous.Anonymous.Offset = value;

  int get OffsetHigh => this.Anonymous.Anonymous.OffsetHigh;
  set OffsetHigh(int value) => this.Anonymous.Anonymous.OffsetHigh = value;
}

extension OVERLAPPED_Extension on OVERLAPPED {
  _OVERLAPPED__Anonymous_e__Union__Anonymous_e__Struct get Anonymous =>
      this.Anonymous.Anonymous;
  set Anonymous(_OVERLAPPED__Anonymous_e__Union__Anonymous_e__Struct value) =>
      this.Anonymous.Anonymous = value;

  Pointer get Pointer_ => this.Anonymous.Pointer_;
  set Pointer_(Pointer value) => this.Anonymous.Pointer_ = value;
}

/// Contains the information returned by a call to the
/// GetQueuedCompletionStatusEx function.
///
/// {@category Struct}
class OVERLAPPED_ENTRY extends Struct {
  @IntPtr()
  external int lpCompletionKey;

  external Pointer<OVERLAPPED> lpOverlapped;

  @IntPtr()
  external int Internal;

  @Uint32()
  external int dwNumberOfBytesTransferred;
}

/// The PAINTSTRUCT structure contains information for an application. This
/// information can be used to paint the client area of a window owned by
/// that application.
///
/// {@category Struct}
class PAINTSTRUCT extends Struct {
  @IntPtr()
  external int hdc;

  @Int32()
  external int fErase;

  external RECT rcPaint;

  @Int32()
  external int fRestore;

  @Int32()
  external int fIncUpdate;

  @Array(32)
  external Array<Uint8> rgbReserved;
}

/// The PALETTEENTRY structure specifies the color and usage of an entry in
/// a logical palette. A logical palette is defined by a LOGPALETTE
/// structure.
///
/// {@category Struct}
class PALETTEENTRY extends Struct {
  @Uint8()
  external int peRed;

  @Uint8()
  external int peGreen;

  @Uint8()
  external int peBlue;

  @Uint8()
  external int peFlags;
}

/// Contains information needed for transferring a structure element,
/// parameter, or function return value between processes.
///
/// {@category Struct}
class PARAMDESC extends Struct {
  external Pointer<PARAMDESCEX> pparamdescex;

  @Uint16()
  external int wParamFlags;
}

/// Contains information about the default value of a parameter.
///
/// {@category Struct}
class PARAMDESCEX extends Struct {
  @Uint32()
  external int cBytes;

  external VARIANT varDefaultValue;
}

/// Contains a handle and text description corresponding to a physical
/// monitor.
///
/// {@category Struct}
@Packed(1)
class PHYSICAL_MONITOR extends Struct {
  @IntPtr()
  external int hPhysicalMonitor;

  @Array(128)
  external Array<Uint16> _szPhysicalMonitorDescription;

  String get szPhysicalMonitorDescription {
    final charCodes = <int>[];
    for (var i = 0; i < 128; i++) {
      if (_szPhysicalMonitorDescription[i] == 0x00) break;
      charCodes.add(_szPhysicalMonitorDescription[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szPhysicalMonitorDescription(String value) {
    final stringToStore = value.padRight(128, '\x00');
    for (var i = 0; i < 128; i++) {
      _szPhysicalMonitorDescription[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// The POINT structure defines the x- and y-coordinates of a point.
///
/// {@category Struct}
class POINT extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;
}

/// Contains basic pointer information common to all pointer types.
/// Applications can retrieve this information using the GetPointerInfo,
/// GetPointerFrameInfo, GetPointerInfoHistory and
/// GetPointerFrameInfoHistory functions.
///
/// {@category Struct}
class POINTER_INFO extends Struct {
  @Int32()
  external int pointerType;

  @Uint32()
  external int pointerId;

  @Uint32()
  external int frameId;

  @Uint32()
  external int pointerFlags;

  @IntPtr()
  external int sourceDevice;

  @IntPtr()
  external int hwndTarget;

  external POINT ptPixelLocation;

  external POINT ptHimetricLocation;

  external POINT ptPixelLocationRaw;

  external POINT ptHimetricLocationRaw;

  @Uint32()
  external int dwTime;

  @Uint32()
  external int historyCount;

  @Int32()
  external int InputData;

  @Uint32()
  external int dwKeyStates;

  @Uint64()
  external int PerformanceCount;

  @Int32()
  external int ButtonChangeType;
}

/// Defines basic pen information common to all pointer types.
///
/// {@category Struct}
class POINTER_PEN_INFO extends Struct {
  external POINTER_INFO pointerInfo;

  @Uint32()
  external int penFlags;

  @Uint32()
  external int penMask;

  @Uint32()
  external int pressure;

  @Uint32()
  external int rotation;

  @Int32()
  external int tiltX;

  @Int32()
  external int tiltY;
}

/// Defines basic touch information common to all pointer types.
///
/// {@category Struct}
class POINTER_TOUCH_INFO extends Struct {
  external POINTER_INFO pointerInfo;

  @Uint32()
  external int touchFlags;

  @Uint32()
  external int touchMask;

  external RECT rcContact;

  external RECT rcContactRaw;

  @Uint32()
  external int orientation;

  @Uint32()
  external int pressure;
}

/// The POINTL structure defines the x- and y-coordinates of a point.
///
/// {@category Struct}
class POINTL extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;
}

/// The POINTS structure defines the x- and y-coordinates of a point.
///
/// {@category Struct}
class POINTS extends Struct {
  @Int16()
  external int x;

  @Int16()
  external int y;
}

/// The POLYTEXT structure describes how the PolyTextOut function should
/// draw a string of text.
///
/// {@category Struct}
class POLYTEXT extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;

  @Uint32()
  external int n;

  external Pointer<Utf16> lpstr;

  @Uint32()
  external int uiFlags;

  external RECT rcl;

  external Pointer<Int32> pdx;
}

/// The PORT_INFO_1 structure identifies a supported printer port.
///
/// {@category Struct}
class PORT_INFO_1 extends Struct {
  external Pointer<Utf16> pName;
}

/// The PORT_INFO_2 structure identifies a supported printer port.
///
/// {@category Struct}
class PORT_INFO_2 extends Struct {
  external Pointer<Utf16> pPortName;

  external Pointer<Utf16> pMonitorName;

  external Pointer<Utf16> pDescription;

  @Uint32()
  external int fPortType;

  @Uint32()
  external int Reserved;
}

/// Sent with a power setting event and contains data about the specific
/// change.
///
/// {@category Struct}
class POWERBROADCAST_SETTING extends Struct {
  external GUID PowerSetting;

  @Uint32()
  external int DataLength;

  @Array(1)
  external Array<Uint8> Data;
}

/// The PRINTER_DEFAULTS structure specifies the default data type,
/// environment, initialization data, and access rights for a printer.
///
/// {@category Struct}
class PRINTER_DEFAULTS extends Struct {
  external Pointer<Utf16> pDatatype;

  external Pointer<DEVMODE> pDevMode;

  @Uint32()
  external int DesiredAccess;
}

/// The PRINTER_INFO_1 structure specifies general printer information.
///
/// {@category Struct}
class PRINTER_INFO_1 extends Struct {
  @Uint32()
  external int Flags;

  external Pointer<Utf16> pDescription;

  external Pointer<Utf16> pName;

  external Pointer<Utf16> pComment;
}

/// The PRINTER_INFO_2 structure specifies detailed printer information.
///
/// {@category Struct}
class PRINTER_INFO_2 extends Struct {
  external Pointer<Utf16> pServerName;

  external Pointer<Utf16> pPrinterName;

  external Pointer<Utf16> pShareName;

  external Pointer<Utf16> pPortName;

  external Pointer<Utf16> pDriverName;

  external Pointer<Utf16> pComment;

  external Pointer<Utf16> pLocation;

  external Pointer<DEVMODE> pDevMode;

  external Pointer<Utf16> pSepFile;

  external Pointer<Utf16> pPrintProcessor;

  external Pointer<Utf16> pDatatype;

  external Pointer<Utf16> pParameters;

  external Pointer pSecurityDescriptor;

  @Uint32()
  external int Attributes;

  @Uint32()
  external int Priority;

  @Uint32()
  external int DefaultPriority;

  @Uint32()
  external int StartTime;

  @Uint32()
  external int UntilTime;

  @Uint32()
  external int Status;

  @Uint32()
  external int cJobs;

  @Uint32()
  external int AveragePPM;
}

/// The PRINTER_INFO_3 structure specifies printer security information.
///
/// {@category Struct}
class PRINTER_INFO_3 extends Struct {
  external Pointer pSecurityDescriptor;
}

/// The PRINTER_INFO_4 structure specifies general printer information. The
/// structure can be used to retrieve minimal printer information on a call
/// to EnumPrinters. Such a call is a fast and easy way to retrieve the
/// names and attributes of all locally installed printers on a system and
/// all remote printer connections that a user has established.
///
/// {@category Struct}
class PRINTER_INFO_4 extends Struct {
  external Pointer<Utf16> pPrinterName;

  external Pointer<Utf16> pServerName;

  @Uint32()
  external int Attributes;
}

/// The PRINTER_INFO_5 structure specifies detailed printer information.
///
/// {@category Struct}
class PRINTER_INFO_5 extends Struct {
  external Pointer<Utf16> pPrinterName;

  external Pointer<Utf16> pPortName;

  @Uint32()
  external int Attributes;

  @Uint32()
  external int DeviceNotSelectedTimeout;

  @Uint32()
  external int TransmissionRetryTimeout;
}

/// The PRINTER_INFO_6 specifies the status value of a printer.
///
/// {@category Struct}
class PRINTER_INFO_6 extends Struct {
  @Uint32()
  external int dwStatus;
}

/// The PRINTER_NOTIFY_INFO structure contains printer information returned
/// by the FindNextPrinterChangeNotification function. The function returns
/// this information after a wait operation on a printer change notification
/// object has been satisfied.
///
/// {@category Struct}
class PRINTER_NOTIFY_INFO extends Struct {
  @Uint32()
  external int Version;

  @Uint32()
  external int Flags;

  @Uint32()
  external int Count;

  @Array(1)
  external Array<PRINTER_NOTIFY_INFO_DATA> aData;
}

/// The PRINTER_NOTIFY_INFO_DATA structure identifies a job or printer
/// information field and provides the current data for that field.
///
/// {@category Struct}
class PRINTER_NOTIFY_INFO_DATA extends Struct {
  @Uint16()
  external int Type;

  @Uint16()
  external int Field;

  @Uint32()
  external int Reserved;

  @Uint32()
  external int Id;

  external _PRINTER_NOTIFY_INFO_DATA__NotifyData_e__Union NotifyData;
}

/// {@category Struct}
class _PRINTER_NOTIFY_INFO_DATA__NotifyData_e__Union extends Union {
  @Array(2)
  external Array<Uint32> adwData;

  external _PRINTER_NOTIFY_INFO_DATA__NotifyData_e__Union__Data_e__Struct Data;
}

/// {@category Struct}
class _PRINTER_NOTIFY_INFO_DATA__NotifyData_e__Union__Data_e__Struct
    extends Struct {
  @Uint32()
  external int cbBuf;

  external Pointer pBuf;
}

extension PRINTER_NOTIFY_INFO_DATA__NotifyData_e__Union_Extension
    on PRINTER_NOTIFY_INFO_DATA {
  int get cbBuf => this.NotifyData.Data.cbBuf;
  set cbBuf(int value) => this.NotifyData.Data.cbBuf = value;

  Pointer get pBuf => this.NotifyData.Data.pBuf;
  set pBuf(Pointer value) => this.NotifyData.Data.pBuf = value;
}

extension PRINTER_NOTIFY_INFO_DATA_Extension on PRINTER_NOTIFY_INFO_DATA {
  Array<Uint32> get adwData => this.NotifyData.adwData;
  set adwData(Array<Uint32> value) => this.NotifyData.adwData = value;

  _PRINTER_NOTIFY_INFO_DATA__NotifyData_e__Union__Data_e__Struct get Data =>
      this.NotifyData.Data;
  set Data(
          _PRINTER_NOTIFY_INFO_DATA__NotifyData_e__Union__Data_e__Struct
              value) =>
      this.NotifyData.Data = value;
}

/// Represents printer options.
///
/// {@category Struct}
class PRINTER_OPTIONS extends Struct {
  @Uint32()
  external int cbSize;

  @Int32()
  external int dwFlags;
}

/// Contains the execution context of the printer driver that calls
/// GetPrintExecutionData.
///
/// {@category Struct}
class PRINT_EXECUTION_DATA extends Struct {
  @Int32()
  external int context;

  @Uint32()
  external int clientAppPID;
}

/// Contains information about a heap element. The HeapWalk function uses a
/// PROCESS_HEAP_ENTRY structure to enumerate the elements of a heap.
///
/// {@category Struct}
class PROCESS_HEAP_ENTRY extends Struct {
  external Pointer lpData;

  @Uint32()
  external int cbData;

  @Uint8()
  external int cbOverhead;

  @Uint8()
  external int iRegionIndex;

  @Uint16()
  external int wFlags;

  external _PROCESS_HEAP_ENTRY__Anonymous_e__Union Anonymous;
}

/// {@category Struct}
class _PROCESS_HEAP_ENTRY__Anonymous_e__Union extends Union {
  external _PROCESS_HEAP_ENTRY__Anonymous_e__Union__Block_e__Struct Block;

  external _PROCESS_HEAP_ENTRY__Anonymous_e__Union__Region_e__Struct Region;
}

/// {@category Struct}
class _PROCESS_HEAP_ENTRY__Anonymous_e__Union__Block_e__Struct extends Struct {
  @IntPtr()
  external int hMem;

  @Array(3)
  external Array<Uint32> dwReserved;
}

extension PROCESS_HEAP_ENTRY__Anonymous_e__Union_Extension
    on PROCESS_HEAP_ENTRY {
  int get hMem => this.Anonymous.Block.hMem;
  set hMem(int value) => this.Anonymous.Block.hMem = value;

  Array<Uint32> get dwReserved => this.Anonymous.Block.dwReserved;
  set dwReserved(Array<Uint32> value) =>
      this.Anonymous.Block.dwReserved = value;
}

/// {@category Struct}
class _PROCESS_HEAP_ENTRY__Anonymous_e__Union__Region_e__Struct extends Struct {
  @Uint32()
  external int dwCommittedSize;

  @Uint32()
  external int dwUnCommittedSize;

  external Pointer lpFirstBlock;

  external Pointer lpLastBlock;
}

extension PROCESS_HEAP_ENTRY__Anonymous_e__Union_Extension_1
    on PROCESS_HEAP_ENTRY {
  int get dwCommittedSize => this.Anonymous.Region.dwCommittedSize;
  set dwCommittedSize(int value) =>
      this.Anonymous.Region.dwCommittedSize = value;

  int get dwUnCommittedSize => this.Anonymous.Region.dwUnCommittedSize;
  set dwUnCommittedSize(int value) =>
      this.Anonymous.Region.dwUnCommittedSize = value;

  Pointer get lpFirstBlock => this.Anonymous.Region.lpFirstBlock;
  set lpFirstBlock(Pointer value) => this.Anonymous.Region.lpFirstBlock = value;

  Pointer get lpLastBlock => this.Anonymous.Region.lpLastBlock;
  set lpLastBlock(Pointer value) => this.Anonymous.Region.lpLastBlock = value;
}

extension PROCESS_HEAP_ENTRY_Extension on PROCESS_HEAP_ENTRY {
  _PROCESS_HEAP_ENTRY__Anonymous_e__Union__Block_e__Struct get Block =>
      this.Anonymous.Block;
  set Block(_PROCESS_HEAP_ENTRY__Anonymous_e__Union__Block_e__Struct value) =>
      this.Anonymous.Block = value;

  _PROCESS_HEAP_ENTRY__Anonymous_e__Union__Region_e__Struct get Region =>
      this.Anonymous.Region;
  set Region(_PROCESS_HEAP_ENTRY__Anonymous_e__Union__Region_e__Struct value) =>
      this.Anonymous.Region = value;
}

/// Contains information about a newly created process and its primary
/// thread. It is used with the CreateProcess, CreateProcessAsUser,
/// CreateProcessWithLogonW, or CreateProcessWithTokenW function.
///
/// {@category Struct}
class PROCESS_INFORMATION extends Struct {
  @IntPtr()
  external int hProcess;

  @IntPtr()
  external int hThread;

  @Uint32()
  external int dwProcessId;

  @Uint32()
  external int dwThreadId;
}

/// Specifies the FMTID/PID identifier that programmatically identifies a
/// property.
///
/// {@category Struct}
class PROPERTYKEY extends Struct {
  external GUID fmtid;

  @Uint32()
  external int pid;
}

/// The PROPSPEC structure is used by many of the methods of
/// IPropertyStorage to specify a property either by its property identifier
/// (ID) or the associated string name.
///
/// {@category Struct}
class PROPSPEC extends Struct {
  @Uint32()
  external int ulKind;

  external _PROPSPEC__Anonymous_e__Union Anonymous;
}

/// {@category Struct}
class _PROPSPEC__Anonymous_e__Union extends Union {
  @Uint32()
  external int propid;

  external Pointer<Utf16> lpwstr;
}

extension PROPSPEC_Extension on PROPSPEC {
  int get propid => this.Anonymous.propid;
  set propid(int value) => this.Anonymous.propid = value;

  Pointer<Utf16> get lpwstr => this.Anonymous.lpwstr;
  set lpwstr(Pointer<Utf16> value) => this.Anonymous.lpwstr = value;
}

/// The protoent structure contains the name and protocol numbers that
/// correspond to a given protocol name. Applications must never attempt to
/// modify this structure or to free any of its components. Furthermore,
/// only one copy of this structure is allocated per thread, and therefore,
/// the application should copy any information it needs before issuing any
/// other Windows Sockets function calls.
///
/// {@category Struct}
class PROTOENT extends Struct {
  external Pointer<Utf8> p_name;

  external Pointer<Pointer<Int8>> p_aliases;

  @Int16()
  external int p_proto;
}

/// Describes the format of the raw input from a Human Interface Device
/// (HID).
///
/// {@category Struct}
class RAWHID extends Struct {
  @Uint32()
  external int dwSizeHid;

  @Uint32()
  external int dwCount;

  @Array(1)
  external Array<Uint8> bRawData;
}

/// Contains the raw input from a device.
///
/// {@category Struct}
class RAWINPUT extends Struct {
  external RAWINPUTHEADER header;

  external _RAWINPUT__data_e__Union data;
}

/// {@category Struct}
class _RAWINPUT__data_e__Union extends Union {
  external RAWMOUSE mouse;

  external RAWKEYBOARD keyboard;

  external RAWHID hid;
}

extension RAWINPUT_Extension on RAWINPUT {
  RAWMOUSE get mouse => this.data.mouse;
  set mouse(RAWMOUSE value) => this.data.mouse = value;

  RAWKEYBOARD get keyboard => this.data.keyboard;
  set keyboard(RAWKEYBOARD value) => this.data.keyboard = value;

  RAWHID get hid => this.data.hid;
  set hid(RAWHID value) => this.data.hid = value;
}

/// Defines information for the raw input devices.
///
/// {@category Struct}
class RAWINPUTDEVICE extends Struct {
  @Uint16()
  external int usUsagePage;

  @Uint16()
  external int usUsage;

  @Uint32()
  external int dwFlags;

  @IntPtr()
  external int hwndTarget;
}

/// Contains information about a raw input device.
///
/// {@category Struct}
class RAWINPUTDEVICELIST extends Struct {
  @IntPtr()
  external int hDevice;

  @Uint32()
  external int dwType;
}

/// Contains the header information that is part of the raw input data.
///
/// {@category Struct}
class RAWINPUTHEADER extends Struct {
  @Uint32()
  external int dwType;

  @Uint32()
  external int dwSize;

  @IntPtr()
  external int hDevice;

  @IntPtr()
  external int wParam;
}

/// Contains information about the state of the keyboard.
///
/// {@category Struct}
class RAWKEYBOARD extends Struct {
  @Uint16()
  external int MakeCode;

  @Uint16()
  external int Flags;

  @Uint16()
  external int Reserved;

  @Uint16()
  external int VKey;

  @Uint32()
  external int Message;

  @Uint32()
  external int ExtraInformation;
}

/// Contains information about the state of the mouse.
///
/// {@category Struct}
class RAWMOUSE extends Struct {
  @Uint16()
  external int usFlags;

  external _RAWMOUSE__Anonymous_e__Union Anonymous;

  @Uint32()
  external int ulRawButtons;

  @Int32()
  external int lLastX;

  @Int32()
  external int lLastY;

  @Uint32()
  external int ulExtraInformation;
}

/// {@category Struct}
class _RAWMOUSE__Anonymous_e__Union extends Union {
  @Uint32()
  external int ulButtons;

  external _RAWMOUSE__Anonymous_e__Union__Anonymous_e__Struct Anonymous;
}

/// {@category Struct}
class _RAWMOUSE__Anonymous_e__Union__Anonymous_e__Struct extends Struct {
  @Uint16()
  external int usButtonFlags;

  @Uint16()
  external int usButtonData;
}

extension RAWMOUSE__Anonymous_e__Union_Extension on RAWMOUSE {
  int get usButtonFlags => this.Anonymous.Anonymous.usButtonFlags;
  set usButtonFlags(int value) =>
      this.Anonymous.Anonymous.usButtonFlags = value;

  int get usButtonData => this.Anonymous.Anonymous.usButtonData;
  set usButtonData(int value) => this.Anonymous.Anonymous.usButtonData = value;
}

extension RAWMOUSE_Extension on RAWMOUSE {
  int get ulButtons => this.Anonymous.ulButtons;
  set ulButtons(int value) => this.Anonymous.ulButtons = value;

  _RAWMOUSE__Anonymous_e__Union__Anonymous_e__Struct get Anonymous =>
      this.Anonymous.Anonymous;
  set Anonymous(_RAWMOUSE__Anonymous_e__Union__Anonymous_e__Struct value) =>
      this.Anonymous.Anonymous = value;
}

/// The RECT structure defines a rectangle by the coordinates of its
/// upper-left and lower-right corners.
///
/// {@category Struct}
class RECT extends Struct {
  @Int32()
  external int left;

  @Int32()
  external int top;

  @Int32()
  external int right;

  @Int32()
  external int bottom;
}

/// The RGBQUAD structure describes a color consisting of relative
/// intensities of red, green, and blue.
///
/// {@category Struct}
class RGBQUAD extends Struct {
  @Uint8()
  external int rgbBlue;

  @Uint8()
  external int rgbGreen;

  @Uint8()
  external int rgbRed;

  @Uint8()
  external int rgbReserved;
}

/// Represents a safe array.
///
/// {@category Struct}
class SAFEARRAY extends Struct {
  @Uint16()
  external int cDims;

  @Uint16()
  external int fFeatures;

  @Uint32()
  external int cbElements;

  @Uint32()
  external int cLocks;

  external Pointer pvData;

  @Array(1)
  external Array<SAFEARRAYBOUND> rgsabound;
}

/// Represents the bounds of one dimension of the array.
///
/// {@category Struct}
class SAFEARRAYBOUND extends Struct {
  @Uint32()
  external int cElements;

  @Int32()
  external int lLbound;
}

/// The SCARD_ATRMASK structure is used by the SCardLocateCardsByATR
/// function to locate cards.
///
/// {@category Struct}
class SCARD_ATRMASK extends Struct {
  @Uint32()
  external int cbAtr;

  @Array(36)
  external Array<Uint8> rgbAtr;

  @Array(36)
  external Array<Uint8> rgbMask;
}

/// The SCARD_IO_REQUEST structure begins a protocol control information
/// structure. Any protocol-specific information then immediately follows
/// this structure. The entire length of the structure must be aligned with
/// the underlying hardware architecture word size. For example, in Win32
/// the length of any PCI information must be a multiple of four bytes so
/// that it aligns on a 32-bit boundary.
///
/// {@category Struct}
class SCARD_IO_REQUEST extends Struct {
  @Uint32()
  external int dwProtocol;

  @Uint32()
  external int cbPciLength;
}

/// The SCARD_READERSTATE structure is used by functions for tracking smart
/// cards within readers.
///
/// {@category Struct}
class SCARD_READERSTATE extends Struct {
  external Pointer<Utf16> szReader;

  external Pointer pvUserData;

  @Uint32()
  external int dwCurrentState;

  @Uint32()
  external int dwEventState;

  @Uint32()
  external int cbAtr;

  @Array(36)
  external Array<Uint8> rgbAtr;
}

/// The SCROLLBARINFO structure contains scroll bar information.
///
/// {@category Struct}
class SCROLLBARINFO extends Struct {
  @Uint32()
  external int cbSize;

  external RECT rcScrollBar;

  @Int32()
  external int dxyLineButton;

  @Int32()
  external int xyThumbTop;

  @Int32()
  external int xyThumbBottom;

  @Int32()
  external int reserved;

  @Array(6)
  external Array<Uint32> rgstate;
}

/// The SCROLLINFO structure contains scroll bar parameters to be set by the
/// SetScrollInfo function (or SBM_SETSCROLLINFO message), or retrieved by
/// the GetScrollInfo function (or SBM_GETSCROLLINFO message)
///
/// {@category Struct}
class SCROLLINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int fMask;

  @Int32()
  external int nMin;

  @Int32()
  external int nMax;

  @Uint32()
  external int nPage;

  @Int32()
  external int nPos;

  @Int32()
  external int nTrackPos;
}

/// The SECURITY_ATTRIBUTES structure contains the security descriptor for
/// an object and specifies whether the handle retrieved by specifying this
/// structure is inheritable. This structure provides security settings for
/// objects created by various functions, such as CreateFile, CreatePipe,
/// CreateProcess, RegCreateKeyEx, or RegSaveKeyEx.
///
/// {@category Struct}
class SECURITY_ATTRIBUTES extends Struct {
  @Uint32()
  external int nLength;

  external Pointer lpSecurityDescriptor;

  @Int32()
  external int bInheritHandle;
}

/// The SECURITY_DESCRIPTOR structure contains the security information
/// associated with an object. Applications use this structure to set and
/// query an object's security status.
///
/// {@category Struct}
class SECURITY_DESCRIPTOR extends Struct {
  @Uint8()
  external int Revision;

  @Uint8()
  external int Sbz1;

  @Uint16()
  external int Control;

  external Pointer Owner;

  external Pointer Group;

  external Pointer<ACL> Sacl;

  external Pointer<ACL> Dacl;
}

/// The servent structure is used to store or return the name and service
/// number for a given service name.
///
/// {@category Struct}
class SERVENT extends Struct {
  external Pointer<Utf8> s_name;

  external Pointer<Pointer<Int8>> s_aliases;

  external Pointer<Utf8> s_proto;

  @Int16()
  external int s_port;
}

/// Contains information used by ShellExecuteEx.
///
/// {@category Struct}
class SHELLEXECUTEINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int fMask;

  @IntPtr()
  external int hwnd;

  external Pointer<Utf16> lpVerb;

  external Pointer<Utf16> lpFile;

  external Pointer<Utf16> lpParameters;

  external Pointer<Utf16> lpDirectory;

  @Int32()
  external int nShow;

  @IntPtr()
  external int hInstApp;

  external Pointer lpIDList;

  external Pointer<Utf16> lpClass;

  @IntPtr()
  external int hkeyClass;

  @Uint32()
  external int dwHotKey;

  external _SHELLEXECUTEINFOW__Anonymous_e__Union Anonymous;

  @IntPtr()
  external int hProcess;
}

/// {@category Struct}
class _SHELLEXECUTEINFOW__Anonymous_e__Union extends Union {
  @IntPtr()
  external int hIcon;

  @IntPtr()
  external int hMonitor;
}

extension SHELLEXECUTEINFOW_Extension on SHELLEXECUTEINFO {
  int get hIcon => this.Anonymous.hIcon;
  set hIcon(int value) => this.Anonymous.hIcon = value;

  int get hMonitor => this.Anonymous.hMonitor;
  set hMonitor(int value) => this.Anonymous.hMonitor = value;
}

/// Defines Shell item resource.
///
/// {@category Struct}
class SHELL_ITEM_RESOURCE extends Struct {
  external GUID guidType;

  @Array(260)
  external Array<Uint16> _szName;

  String get szName {
    final charCodes = <int>[];
    for (var i = 0; i < 260; i++) {
      if (_szName[i] == 0x00) break;
      charCodes.add(_szName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szName(String value) {
    final stringToStore = value.padRight(260, '\x00');
    for (var i = 0; i < 260; i++) {
      _szName[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// Defines an item identifier.
///
/// {@category Struct}
@Packed(1)
class SHITEMID extends Struct {
  @Uint16()
  external int cb;

  @Array(1)
  external Array<Uint8> abID;
}

/// Contains the size and item count information retrieved by the
/// SHQueryRecycleBin function.
///
/// {@category Struct}
class SHQUERYRBINFO extends Struct {
  @Uint32()
  external int cbSize;

  @Int64()
  external int i64Size;

  @Int64()
  external int i64NumItems;
}

/// The SIZE structure defines the width and height of a rectangle.
///
/// {@category Struct}
class SIZE extends Struct {
  @Int32()
  external int cx;

  @Int32()
  external int cy;
}

/// Defines the coordinates of the upper left and lower right corners of a
/// rectangle.
///
/// {@category Struct}
class SMALL_RECT extends Struct {
  @Int16()
  external int Left;

  @Int16()
  external int Top;

  @Int16()
  external int Right;

  @Int16()
  external int Bottom;
}

/// The SOCKADDR structure stores socket address information.
///
/// {@category Struct}
class SOCKADDR extends Struct {
  @Uint16()
  external int sa_family;

  @Array(14)
  external Array<Uint8> sa_data;
}

/// The SOCKET_ADDRESS structure stores protocol-specific address
/// information.
///
/// {@category Struct}
class SOCKET_ADDRESS extends Struct {
  external Pointer<SOCKADDR> lpSockaddr;

  @Int32()
  external int iSockaddrLength;
}

/// Identifies an authentication service that a server is willing to use to
/// communicate to a client.
///
/// {@category Struct}
class SOLE_AUTHENTICATION_SERVICE extends Struct {
  @Uint32()
  external int dwAuthnSvc;

  @Uint32()
  external int dwAuthzSvc;

  external Pointer<Utf16> pPrincipalName;

  @Int32()
  external int hr;
}

/// SPEVENT contains information about an event. Events are passed from the
/// text-to-speech (TTS) or speech recognition (SR) engines or audio devices
/// back to applications.
///
/// {@category Struct}
class SPEVENT extends Struct {
  @Int32()
  external int bitfield;

  @Uint32()
  external int ulStreamNum;

  @Uint64()
  external int ullAudioStreamOffset;

  @IntPtr()
  external int wParam;

  @IntPtr()
  external int lParam;
}

/// SPEVENTSOURCEINFO is used by ISpEventSource::GetInfo to pass back
/// information about the event source. Event sources contain a queue, which
/// hold events until a caller retrieves the events using ::GetEvents.
///
/// {@category Struct}
class SPEVENTSOURCEINFO extends Struct {
  @Uint64()
  external int ullEventInterest;

  @Uint64()
  external int ullQueuedInterest;

  @Uint32()
  external int ulCount;
}

/// SPVOICESTATUS contains voice status information. This structure is
/// returned by ISpVoice::GetStatus.
///
/// {@category Struct}
class SPVOICESTATUS extends Struct {
  @Uint32()
  external int ulCurrentStream;

  @Uint32()
  external int ulLastStreamQueued;

  @Int32()
  external int hrLastResult;

  @Uint32()
  external int dwRunningState;

  @Uint32()
  external int ulInputWordPos;

  @Uint32()
  external int ulInputWordLen;

  @Uint32()
  external int ulInputSentPos;

  @Uint32()
  external int ulInputSentLen;

  @Int32()
  external int lBookmarkId;

  @Uint16()
  external int PhonemeId;

  @Int32()
  external int VisemeId;

  @Uint32()
  external int dwReserved1;

  @Uint32()
  external int dwReserved2;
}

/// An SP_DEVICE_INTERFACE_DATA structure defines a device interface in a
/// device information set.
///
/// {@category Struct}
class SP_DEVICE_INTERFACE_DATA extends Struct {
  @Uint32()
  external int cbSize;

  external GUID InterfaceClassGuid;

  @Uint32()
  external int Flags;

  @IntPtr()
  external int Reserved;
}

/// An SP_DEVICE_INTERFACE_DATA structure defines a device interface in a
/// device information set.
///
/// {@category Struct}
class SP_DEVICE_INTERFACE_DETAIL_DATA_ extends Struct {
  @Uint32()
  external int cbSize;

  @Array(1)
  external Array<Uint16> _DevicePath;

  String get DevicePath {
    final charCodes = <int>[];
    for (var i = 0; i < 1; i++) {
      if (_DevicePath[i] == 0x00) break;
      charCodes.add(_DevicePath[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set DevicePath(String value) {
    final stringToStore = value.padRight(1, '\x00');
    for (var i = 0; i < 1; i++) {
      _DevicePath[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// An SP_DEVINFO_DATA structure defines a device instance that is a member
/// of a device information set.
///
/// {@category Struct}
class SP_DEVINFO_DATA extends Struct {
  @Uint32()
  external int cbSize;

  external GUID ClassGuid;

  @Uint32()
  external int DevInst;

  @IntPtr()
  external int Reserved;
}

/// Specifies the window station, desktop, standard handles, and attributes
/// for a new process. It is used with the CreateProcess and
/// CreateProcessAsUser functions.
///
/// {@category Struct}
class STARTUPINFOEX extends Struct {
  external STARTUPINFO StartupInfo;

  external Pointer lpAttributeList;
}

/// Specifies the window station, desktop, standard handles, and appearance
/// of the main window for a process at creation time.
///
/// {@category Struct}
class STARTUPINFO extends Struct {
  @Uint32()
  external int cb;

  external Pointer<Utf16> lpReserved;

  external Pointer<Utf16> lpDesktop;

  external Pointer<Utf16> lpTitle;

  @Uint32()
  external int dwX;

  @Uint32()
  external int dwY;

  @Uint32()
  external int dwXSize;

  @Uint32()
  external int dwYSize;

  @Uint32()
  external int dwXCountChars;

  @Uint32()
  external int dwYCountChars;

  @Uint32()
  external int dwFillAttribute;

  @Uint32()
  external int dwFlags;

  @Uint16()
  external int wShowWindow;

  @Uint16()
  external int cbReserved2;

  external Pointer<Uint8> lpReserved2;

  @IntPtr()
  external int hStdInput;

  @IntPtr()
  external int hStdOutput;

  @IntPtr()
  external int hStdError;
}

/// The STATPROPSETSTG structure contains information about a property set.
///
/// {@category Struct}
class STATPROPSETSTG extends Struct {
  external GUID fmtid;

  external GUID clsid;

  @Uint32()
  external int grfFlags;

  external FILETIME mtime;

  external FILETIME ctime;

  external FILETIME atime;

  @Uint32()
  external int dwOSVersion;
}

/// The STATPROPSTG structure contains data about a single property in a
/// property set. This data is the property ID and type tag, and the
/// optional string name that may be associated with the property.
///
/// {@category Struct}
class STATPROPSTG extends Struct {
  external Pointer<Utf16> lpwstrName;

  @Uint32()
  external int propid;

  @Uint16()
  external int vt;
}

/// The STATSTG structure contains statistical data about an open storage,
/// stream, or byte-array object. This structure is used in the
/// IEnumSTATSTG, ILockBytes, IStorage, and IStream interfaces.
///
/// {@category Struct}
class STATSTG extends Struct {
  external Pointer<Utf16> pwcsName;

  @Uint32()
  external int type;

  @Uint64()
  external int cbSize;

  external FILETIME mtime;

  external FILETIME ctime;

  external FILETIME atime;

  @Uint32()
  external int grfMode;

  @Int32()
  external int grfLocksSupported;

  external GUID clsid;

  @Uint32()
  external int grfStateBits;

  @Uint32()
  external int reserved;
}

/// Contains information about a device. This structure is used by the
/// IOCTL_STORAGE_GET_DEVICE_NUMBER control code.
///
/// {@category Struct}
class STORAGE_DEVICE_NUMBER extends Struct {
  @Uint32()
  external int DeviceType;

  @Uint32()
  external int DeviceNumber;

  @Uint32()
  external int PartitionNumber;
}

/// Contains strings returned from the IShellFolder interface methods.
///
/// {@category Struct}
class STRRET extends Struct {
  @Uint32()
  external int uType;

  external _STRRET__Anonymous_e__Union Anonymous;
}

/// {@category Struct}
class _STRRET__Anonymous_e__Union extends Union {
  external Pointer<Utf16> pOleStr;

  @Uint32()
  external int uOffset;

  @Array(260)
  external Array<Uint8> cStr;
}

extension STRRET_Extension on STRRET {
  Pointer<Utf16> get pOleStr => this.Anonymous.pOleStr;
  set pOleStr(Pointer<Utf16> value) => this.Anonymous.pOleStr = value;

  int get uOffset => this.Anonymous.uOffset;
  set uOffset(int value) => this.Anonymous.uOffset = value;

  Array<Uint8> get cStr => this.Anonymous.cStr;
  set cStr(Array<Uint8> value) => this.Anonymous.cStr = value;
}

/// Contains the styles for a window.
///
/// {@category Struct}
class STYLESTRUCT extends Struct {
  @Uint32()
  external int styleOld;

  @Uint32()
  external int styleNew;
}

/// Contains symbol information.
///
/// {@category Struct}
class SYMBOL_INFO extends Struct {
  @Uint32()
  external int SizeOfStruct;

  @Uint32()
  external int TypeIndex;

  @Array(2)
  external Array<Uint64> Reserved;

  @Uint32()
  external int Index;

  @Uint32()
  external int Size;

  @Uint64()
  external int ModBase;

  @Uint32()
  external int Flags;

  @Uint64()
  external int Value;

  @Uint64()
  external int Address;

  @Uint32()
  external int Register;

  @Uint32()
  external int Scope;

  @Uint32()
  external int Tag;

  @Uint32()
  external int NameLen;

  @Uint32()
  external int MaxNameLen;

  @Array(1)
  external Array<Uint16> _Name;

  String get Name {
    final charCodes = <int>[];
    for (var i = 0; i < 1; i++) {
      if (_Name[i] == 0x00) break;
      charCodes.add(_Name[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set Name(String value) {
    final stringToStore = value.padRight(1, '\x00');
    for (var i = 0; i < 1; i++) {
      _Name[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// Specifies a date and time, using individual members for the month, day,
/// year, weekday, hour, minute, second, and millisecond. The time is either
/// in coordinated universal time (UTC) or local time, depending on the
/// function that is being called.
///
/// {@category Struct}
class SYSTEMTIME extends Struct {
  @Uint16()
  external int wYear;

  @Uint16()
  external int wMonth;

  @Uint16()
  external int wDayOfWeek;

  @Uint16()
  external int wDay;

  @Uint16()
  external int wHour;

  @Uint16()
  external int wMinute;

  @Uint16()
  external int wSecond;

  @Uint16()
  external int wMilliseconds;
}

/// Contains information about the current state of the system battery.
///
/// {@category Struct}
class SYSTEM_BATTERY_STATE extends Struct {
  @Uint8()
  external int AcOnLine;

  @Uint8()
  external int BatteryPresent;

  @Uint8()
  external int Charging;

  @Uint8()
  external int Discharging;

  @Array(3)
  external Array<Uint8> Spare1;

  @Uint8()
  external int Tag;

  @Uint32()
  external int MaxCapacity;

  @Uint32()
  external int RemainingCapacity;

  @Uint32()
  external int Rate;

  @Uint32()
  external int EstimatedTime;

  @Uint32()
  external int DefaultAlert1;

  @Uint32()
  external int DefaultAlert2;
}

/// Contains information about the current computer system. This includes
/// the architecture and type of the processor, the number of processors in
/// the system, the page size, and other such information.
///
/// {@category Struct}
class SYSTEM_INFO extends Struct {
  external _SYSTEM_INFO__Anonymous_e__Union Anonymous;

  @Uint32()
  external int dwPageSize;

  external Pointer lpMinimumApplicationAddress;

  external Pointer lpMaximumApplicationAddress;

  @IntPtr()
  external int dwActiveProcessorMask;

  @Uint32()
  external int dwNumberOfProcessors;

  @Uint32()
  external int dwProcessorType;

  @Uint32()
  external int dwAllocationGranularity;

  @Uint16()
  external int wProcessorLevel;

  @Uint16()
  external int wProcessorRevision;
}

/// {@category Struct}
class _SYSTEM_INFO__Anonymous_e__Union extends Union {
  @Uint32()
  external int dwOemId;

  external _SYSTEM_INFO__Anonymous_e__Union__Anonymous_e__Struct Anonymous;
}

/// {@category Struct}
class _SYSTEM_INFO__Anonymous_e__Union__Anonymous_e__Struct extends Struct {
  @Uint16()
  external int wProcessorArchitecture;

  @Uint16()
  external int wReserved;
}

extension SYSTEM_INFO__Anonymous_e__Union_Extension on SYSTEM_INFO {
  int get wProcessorArchitecture =>
      this.Anonymous.Anonymous.wProcessorArchitecture;
  set wProcessorArchitecture(int value) =>
      this.Anonymous.Anonymous.wProcessorArchitecture = value;

  int get wReserved => this.Anonymous.Anonymous.wReserved;
  set wReserved(int value) => this.Anonymous.Anonymous.wReserved = value;
}

extension SYSTEM_INFO_Extension on SYSTEM_INFO {
  int get dwOemId => this.Anonymous.dwOemId;
  set dwOemId(int value) => this.Anonymous.dwOemId = value;

  _SYSTEM_INFO__Anonymous_e__Union__Anonymous_e__Struct get Anonymous =>
      this.Anonymous.Anonymous;
  set Anonymous(_SYSTEM_INFO__Anonymous_e__Union__Anonymous_e__Struct value) =>
      this.Anonymous.Anonymous = value;
}

/// Contains information about the power status of the system.
///
/// {@category Struct}
class SYSTEM_POWER_STATUS extends Struct {
  @Uint8()
  external int ACLineStatus;

  @Uint8()
  external int BatteryFlag;

  @Uint8()
  external int BatteryLifePercent;

  @Uint8()
  external int SystemStatusFlag;

  @Uint32()
  external int BatteryLifeTime;

  @Uint32()
  external int BatteryFullLifeTime;
}

/// The TASKDIALOGCONFIG structure contains information used to display a
/// task dialog. The TaskDialogIndirect function uses this structure.
///
/// {@category Struct}
@Packed(1)
class TASKDIALOGCONFIG extends Struct {
  @Uint32()
  external int cbSize;

  @IntPtr()
  external int hwndParent;

  @IntPtr()
  external int hInstance;

  @Int32()
  external int dwFlags;

  @Int32()
  external int dwCommonButtons;

  external Pointer<Utf16> pszWindowTitle;

  external _TASKDIALOGCONFIG__Anonymous1_e__Union Anonymous1;

  external Pointer<Utf16> pszMainInstruction;

  external Pointer<Utf16> pszContent;

  @Uint32()
  external int cButtons;

  external Pointer<TASKDIALOG_BUTTON> pButtons;

  @Int32()
  external int nDefaultButton;

  @Uint32()
  external int cRadioButtons;

  external Pointer<TASKDIALOG_BUTTON> pRadioButtons;

  @Int32()
  external int nDefaultRadioButton;

  external Pointer<Utf16> pszVerificationText;

  external Pointer<Utf16> pszExpandedInformation;

  external Pointer<Utf16> pszExpandedControlText;

  external Pointer<Utf16> pszCollapsedControlText;

  external _TASKDIALOGCONFIG__Anonymous2_e__Union Anonymous2;

  external Pointer<Utf16> pszFooter;

  external Pointer<NativeFunction<TaskDialogCallbackProc>> pfCallback;

  @IntPtr()
  external int lpCallbackData;

  @Uint32()
  external int cxWidth;
}

/// {@category Struct}
@Packed(1)
class _TASKDIALOGCONFIG__Anonymous1_e__Union extends Union {
  @IntPtr()
  external int hMainIcon;

  external Pointer<Utf16> pszMainIcon;
}

extension TASKDIALOGCONFIG_Extension on TASKDIALOGCONFIG {
  int get hMainIcon => this.Anonymous1.hMainIcon;
  set hMainIcon(int value) => this.Anonymous1.hMainIcon = value;

  Pointer<Utf16> get pszMainIcon => this.Anonymous1.pszMainIcon;
  set pszMainIcon(Pointer<Utf16> value) => this.Anonymous1.pszMainIcon = value;
}

/// {@category Struct}
@Packed(1)
class _TASKDIALOGCONFIG__Anonymous2_e__Union extends Union {
  @IntPtr()
  external int hFooterIcon;

  external Pointer<Utf16> pszFooterIcon;
}

extension TASKDIALOGCONFIG_Extension_1 on TASKDIALOGCONFIG {
  int get hFooterIcon => this.Anonymous2.hFooterIcon;
  set hFooterIcon(int value) => this.Anonymous2.hFooterIcon = value;

  Pointer<Utf16> get pszFooterIcon => this.Anonymous2.pszFooterIcon;
  set pszFooterIcon(Pointer<Utf16> value) =>
      this.Anonymous2.pszFooterIcon = value;
}

/// The TASKDIALOG_BUTTON structure contains information used to display a
/// button in a task dialog. The TASKDIALOGCONFIG structure uses this
/// structure.
///
/// {@category Struct}
@Packed(1)
class TASKDIALOG_BUTTON extends Struct {
  @Int32()
  external int nButtonID;

  external Pointer<Utf16> pszButtonText;
}

/// The TEXTMETRIC structure contains basic information about a physical
/// font. All sizes are specified in logical units; that is, they depend on
/// the current mapping mode of the display context.
///
/// {@category Struct}
class TEXTMETRIC extends Struct {
  @Int32()
  external int tmHeight;

  @Int32()
  external int tmAscent;

  @Int32()
  external int tmDescent;

  @Int32()
  external int tmInternalLeading;

  @Int32()
  external int tmExternalLeading;

  @Int32()
  external int tmAveCharWidth;

  @Int32()
  external int tmMaxCharWidth;

  @Int32()
  external int tmWeight;

  @Int32()
  external int tmOverhang;

  @Int32()
  external int tmDigitizedAspectX;

  @Int32()
  external int tmDigitizedAspectY;

  @Uint16()
  external int tmFirstChar;

  @Uint16()
  external int tmLastChar;

  @Uint16()
  external int tmDefaultChar;

  @Uint16()
  external int tmBreakChar;

  @Uint8()
  external int tmItalic;

  @Uint8()
  external int tmUnderlined;

  @Uint8()
  external int tmStruckOut;

  @Uint8()
  external int tmPitchAndFamily;

  @Uint8()
  external int tmCharSet;
}

/// The timeval structure is used to specify a time interval. It is
/// associated with the Berkeley Software Distribution (BSD) Time.h header
/// file.
///
/// {@category Struct}
class TIMEVAL extends Struct {
  @Int32()
  external int tv_sec;

  @Int32()
  external int tv_usec;
}

/// Contains title bar information.
///
/// {@category Struct}
class TITLEBARINFO extends Struct {
  @Uint32()
  external int cbSize;

  external RECT rcTitleBar;

  @Array(6)
  external Array<Uint32> rgstate;
}

/// Expands on the information described in the TITLEBARINFO structure by
/// including the coordinates of each element of the title bar. This
/// structure is sent with the WM_GETTITLEBARINFOEX message.
///
/// {@category Struct}
class TITLEBARINFOEX extends Struct {
  @Uint32()
  external int cbSize;

  external RECT rcTitleBar;

  @Array(6)
  external Array<Uint32> rgstate;

  @Array(6)
  external Array<RECT> rgrect;
}

/// The TOKEN_APPCONTAINER_INFORMATION structure specifies all the
/// information in a token that is necessary for an app container.
///
/// {@category Struct}
class TOKEN_APPCONTAINER_INFORMATION extends Struct {
  external Pointer TokenAppContainer;
}

/// Encapsulates data for touch input.
///
/// {@category Struct}
class TOUCHINPUT extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;

  @IntPtr()
  external int hSource;

  @Uint32()
  external int dwID;

  @Uint32()
  external int dwFlags;

  @Uint32()
  external int dwMask;

  @Uint32()
  external int dwTime;

  @IntPtr()
  external int dwExtraInfo;

  @Uint32()
  external int cxContact;

  @Uint32()
  external int cyContact;
}

/// Contains hardware input details that can be used to predict touch
/// targets and help compensate for hardware latency when processing touch
/// and gesture input that contains distance and velocity data.
///
/// {@category Struct}
class TOUCHPREDICTIONPARAMETERS extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int dwLatency;

  @Uint32()
  external int dwSampleTime;

  @Uint32()
  external int bUseHWTimeStamp;
}

/// Contains extended parameters for the TrackPopupMenuEx function.
///
/// {@category Struct}
class TPMPARAMS extends Struct {
  @Uint32()
  external int cbSize;

  external RECT rcExclude;
}

/// Contains attributes of a type.
///
/// {@category Struct}
class TYPEATTR extends Struct {
  external GUID guid;

  @Uint32()
  external int lcid;

  @Uint32()
  external int dwReserved;

  @Int32()
  external int memidConstructor;

  @Int32()
  external int memidDestructor;

  external Pointer<Utf16> lpstrSchema;

  @Uint32()
  external int cbSizeInstance;

  @Int32()
  external int typekind;

  @Uint16()
  external int cFuncs;

  @Uint16()
  external int cVars;

  @Uint16()
  external int cImplTypes;

  @Uint16()
  external int cbSizeVft;

  @Uint16()
  external int cbAlignment;

  @Uint16()
  external int wTypeFlags;

  @Uint16()
  external int wMajorVerNum;

  @Uint16()
  external int wMinorVerNum;

  external TYPEDESC tdescAlias;

  external IDLDESC idldescType;
}

/// Describes the type of a variable, the return type of a function, or the
/// type of a function parameter.
///
/// {@category Struct}
class TYPEDESC extends Struct {
  external _TYPEDESC__Anonymous_e__Union Anonymous;

  @Uint16()
  external int vt;
}

/// {@category Struct}
class _TYPEDESC__Anonymous_e__Union extends Union {
  external Pointer<TYPEDESC> lptdesc;

  external Pointer<ARRAYDESC> lpadesc;

  @Uint32()
  external int hreftype;
}

extension TYPEDESC_Extension on TYPEDESC {
  Pointer<TYPEDESC> get lptdesc => this.Anonymous.lptdesc;
  set lptdesc(Pointer<TYPEDESC> value) => this.Anonymous.lptdesc = value;

  Pointer<ARRAYDESC> get lpadesc => this.Anonymous.lpadesc;
  set lpadesc(Pointer<ARRAYDESC> value) => this.Anonymous.lpadesc = value;

  int get hreftype => this.Anonymous.hreftype;
  set hreftype(int value) => this.Anonymous.hreftype = value;
}

/// Defines a data type used by the Desktop Window Manager (DWM) APIs. It
/// represents a generic ratio and is used for different purposes and units
/// even within a single API.
///
/// {@category Struct}
@Packed(1)
class UNSIGNED_RATIO extends Struct {
  @Uint32()
  external int uiNumerator;

  @Uint32()
  external int uiDenominator;
}

/// Used by UpdateLayeredWindowIndirect to provide position, size, shape,
/// content, and translucency information for a layered window.
///
/// {@category Struct}
class UPDATELAYEREDWINDOWINFO extends Struct {
  @Uint32()
  external int cbSize;

  @IntPtr()
  external int hdcDst;

  external Pointer<POINT> pptDst;

  external Pointer<SIZE> psize;

  @IntPtr()
  external int hdcSrc;

  external Pointer<POINT> pptSrc;

  @Uint32()
  external int crKey;

  external Pointer<BLENDFUNCTION> pblend;

  @Uint32()
  external int dwFlags;

  external Pointer<RECT> prcDirty;
}

/// Contains information about a registry value. The RegQueryMultipleValues
/// function uses this structure.
///
/// {@category Struct}
class VALENT extends Struct {
  external Pointer<Utf16> ve_valuename;

  @Uint32()
  external int ve_valuelen;

  @IntPtr()
  external int ve_valueptr;

  @Uint32()
  external int ve_type;
}

/// Describes a variable, constant, or data member.
///
/// {@category Struct}
class VARDESC extends Struct {
  @Int32()
  external int memid;

  external Pointer<Utf16> lpstrSchema;

  external _VARDESC__Anonymous_e__Union Anonymous;

  external ELEMDESC elemdescVar;

  @Uint16()
  external int wVarFlags;

  @Int32()
  external int varkind;
}

/// {@category Struct}
class _VARDESC__Anonymous_e__Union extends Union {
  @Uint32()
  external int oInst;

  external Pointer<VARIANT> lpvarValue;
}

extension VARDESC_Extension on VARDESC {
  int get oInst => this.Anonymous.oInst;
  set oInst(int value) => this.Anonymous.oInst = value;

  Pointer<VARIANT> get lpvarValue => this.Anonymous.lpvarValue;
  set lpvarValue(Pointer<VARIANT> value) => this.Anonymous.lpvarValue = value;
}

/// Represents a physical location on a disk. It is the output buffer for
/// the IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS control code.
///
/// {@category Struct}
class VOLUME_DISK_EXTENTS extends Struct {
  @Uint32()
  external int NumberOfDiskExtents;

  @Array(1)
  external Array<DISK_EXTENT> Extents;
}

/// Contains version information for a file. This information is language
/// and code page independent.
///
/// {@category Struct}
class VS_FIXEDFILEINFO extends Struct {
  @Uint32()
  external int dwSignature;

  @Uint32()
  external int dwStrucVersion;

  @Uint32()
  external int dwFileVersionMS;

  @Uint32()
  external int dwFileVersionLS;

  @Uint32()
  external int dwProductVersionMS;

  @Uint32()
  external int dwProductVersionLS;

  @Uint32()
  external int dwFileFlagsMask;

  @Uint32()
  external int dwFileFlags;

  @Int32()
  external int dwFileOS;

  @Int32()
  external int dwFileType;

  @Int32()
  external int dwFileSubtype;

  @Uint32()
  external int dwFileDateMS;

  @Uint32()
  external int dwFileDateLS;
}

/// The WAVEFORMATEX structure defines the format of waveform-audio data.
/// Only format information common to all waveform-audio data formats is
/// included in this structure. For formats that require additional
/// information, this structure is included as the first member in another
/// structure, along with the additional information.
///
/// {@category Struct}
@Packed(1)
class WAVEFORMATEX extends Struct {
  @Uint16()
  external int wFormatTag;

  @Uint16()
  external int nChannels;

  @Uint32()
  external int nSamplesPerSec;

  @Uint32()
  external int nAvgBytesPerSec;

  @Uint16()
  external int nBlockAlign;

  @Uint16()
  external int wBitsPerSample;

  @Uint16()
  external int cbSize;
}

/// The WAVEFORMATEXTENSIBLE structure defines the format of waveform-audio
/// data for formats having more than two channels or higher sample
/// resolutions than allowed by WAVEFORMATEX. It can also be used to define
/// any format that can be defined by WAVEFORMATEX.
///
/// {@category Struct}
class WAVEFORMATEXTENSIBLE extends Struct {
  external WAVEFORMATEX Format;

  external _WAVEFORMATEXTENSIBLE__Samples_e__Union Samples;

  @Uint32()
  external int dwChannelMask;

  external GUID SubFormat;
}

/// {@category Struct}
@Packed(1)
class _WAVEFORMATEXTENSIBLE__Samples_e__Union extends Union {
  @Uint16()
  external int wValidBitsPerSample;

  @Uint16()
  external int wSamplesPerBlock;

  @Uint16()
  external int wReserved;
}

extension WAVEFORMATEXTENSIBLE_Extension on WAVEFORMATEXTENSIBLE {
  int get wValidBitsPerSample => this.Samples.wValidBitsPerSample;
  set wValidBitsPerSample(int value) =>
      this.Samples.wValidBitsPerSample = value;

  int get wSamplesPerBlock => this.Samples.wSamplesPerBlock;
  set wSamplesPerBlock(int value) => this.Samples.wSamplesPerBlock = value;

  int get wReserved => this.Samples.wReserved;
  set wReserved(int value) => this.Samples.wReserved = value;
}

/// The WAVEHDR structure defines the header used to identify a
/// waveform-audio buffer.
///
/// {@category Struct}
@Packed(1)
class WAVEHDR extends Struct {
  external Pointer<Utf8> lpData;

  @Uint32()
  external int dwBufferLength;

  @Uint32()
  external int dwBytesRecorded;

  @IntPtr()
  external int dwUser;

  @Uint32()
  external int dwFlags;

  @Uint32()
  external int dwLoops;

  external Pointer<WAVEHDR> lpNext;

  @IntPtr()
  external int reserved;
}

/// The WAVEOUTCAPS structure describes the capabilities of a waveform-audio
/// output device.
///
/// {@category Struct}
@Packed(1)
class WAVEOUTCAPS extends Struct {
  @Uint16()
  external int wMid;

  @Uint16()
  external int wPid;

  @Uint32()
  external int vDriverVersion;

  @Array(32)
  external Array<Uint16> _szPname;

  String get szPname {
    final charCodes = <int>[];
    for (var i = 0; i < 32; i++) {
      if (_szPname[i] == 0x00) break;
      charCodes.add(_szPname[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set szPname(String value) {
    final stringToStore = value.padRight(32, '\x00');
    for (var i = 0; i < 32; i++) {
      _szPname[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint32()
  external int dwFormats;

  @Uint16()
  external int wChannels;

  @Uint16()
  external int wReserved1;

  @Uint32()
  external int dwSupport;
}

/// Contains information about the file that is found by the FindFirstFile,
/// FindFirstFileEx, or FindNextFile function.
///
/// {@category Struct}
class WIN32_FIND_DATA extends Struct {
  @Uint32()
  external int dwFileAttributes;

  external FILETIME ftCreationTime;

  external FILETIME ftLastAccessTime;

  external FILETIME ftLastWriteTime;

  @Uint32()
  external int nFileSizeHigh;

  @Uint32()
  external int nFileSizeLow;

  @Uint32()
  external int dwReserved0;

  @Uint32()
  external int dwReserved1;

  @Array(260)
  external Array<Uint16> _cFileName;

  String get cFileName {
    final charCodes = <int>[];
    for (var i = 0; i < 260; i++) {
      if (_cFileName[i] == 0x00) break;
      charCodes.add(_cFileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set cFileName(String value) {
    final stringToStore = value.padRight(260, '\x00');
    for (var i = 0; i < 260; i++) {
      _cFileName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Array(14)
  external Array<Uint16> _cAlternateFileName;

  String get cAlternateFileName {
    final charCodes = <int>[];
    for (var i = 0; i < 14; i++) {
      if (_cAlternateFileName[i] == 0x00) break;
      charCodes.add(_cAlternateFileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set cAlternateFileName(String value) {
    final stringToStore = value.padRight(14, '\x00');
    for (var i = 0; i < 14; i++) {
      _cAlternateFileName[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// Contains window information.
///
/// {@category Struct}
class WINDOWINFO extends Struct {
  @Uint32()
  external int cbSize;

  external RECT rcWindow;

  external RECT rcClient;

  @Uint32()
  external int dwStyle;

  @Uint32()
  external int dwExStyle;

  @Uint32()
  external int dwWindowStatus;

  @Uint32()
  external int cxWindowBorders;

  @Uint32()
  external int cyWindowBorders;

  @Uint16()
  external int atomWindowType;

  @Uint16()
  external int wCreatorVersion;
}

/// Contains information about the placement of a window on the screen.
///
/// {@category Struct}
class WINDOWPLACEMENT extends Struct {
  @Uint32()
  external int length;

  @Uint32()
  external int flags;

  @Uint32()
  external int showCmd;

  external POINT ptMinPosition;

  external POINT ptMaxPosition;

  external RECT rcNormalPosition;
}

/// Contains information about the size and position of a window.
///
/// {@category Struct}
class WINDOWPOS extends Struct {
  @IntPtr()
  external int hwnd;

  @IntPtr()
  external int hwndInsertAfter;

  @Int32()
  external int x;

  @Int32()
  external int y;

  @Int32()
  external int cx;

  @Int32()
  external int cy;

  @Uint32()
  external int flags;
}

/// Describes a change in the size of the console screen buffer.
///
/// {@category Struct}
class WINDOW_BUFFER_SIZE_RECORD extends Struct {
  external COORD dwSize;
}

/// The WLAN_ASSOCIATION_ATTRIBUTES structure contains association
/// attributes for a connection.
///
/// {@category Struct}
class WLAN_ASSOCIATION_ATTRIBUTES extends Struct {
  external DOT11_SSID dot11Ssid;

  @Int32()
  external int dot11BssType;

  @Array(6)
  external Array<Uint8> dot11Bssid;

  @Int32()
  external int dot11PhyType;

  @Uint32()
  external int uDot11PhyIndex;

  @Uint32()
  external int wlanSignalQuality;

  @Uint32()
  external int ulRxRate;

  @Uint32()
  external int ulTxRate;
}

/// The WLAN_AUTH_CIPHER_PAIR_LIST structure contains a list of
/// authentication and cipher algorithm pairs.
///
/// {@category Struct}
class WLAN_AUTH_CIPHER_PAIR_LIST extends Struct {
  @Uint32()
  external int dwNumberOfItems;

  @Array(1)
  external Array<DOT11_AUTH_CIPHER_PAIR> pAuthCipherPairList;
}

/// The WLAN_AVAILABLE_NETWORK structure contains information about an
/// available wireless network.
///
/// {@category Struct}
class WLAN_AVAILABLE_NETWORK extends Struct {
  @Array(256)
  external Array<Uint16> _strProfileName;

  String get strProfileName {
    final charCodes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (_strProfileName[i] == 0x00) break;
      charCodes.add(_strProfileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set strProfileName(String value) {
    final stringToStore = value.padRight(256, '\x00');
    for (var i = 0; i < 256; i++) {
      _strProfileName[i] = stringToStore.codeUnitAt(i);
    }
  }

  external DOT11_SSID dot11Ssid;

  @Int32()
  external int dot11BssType;

  @Uint32()
  external int uNumberOfBssids;

  @Int32()
  external int bNetworkConnectable;

  @Uint32()
  external int wlanNotConnectableReason;

  @Uint32()
  external int uNumberOfPhyTypes;

  @Array(8)
  external Array<Int32> dot11PhyTypes;

  @Int32()
  external int bMorePhyTypes;

  @Uint32()
  external int wlanSignalQuality;

  @Int32()
  external int bSecurityEnabled;

  @Int32()
  external int dot11DefaultAuthAlgorithm;

  @Int32()
  external int dot11DefaultCipherAlgorithm;

  @Uint32()
  external int dwFlags;

  @Uint32()
  external int dwReserved;
}

/// The WLAN_AVAILABLE_NETWORK_LIST structure contains an array of
/// information about available networks.
///
/// {@category Struct}
class WLAN_AVAILABLE_NETWORK_LIST extends Struct {
  @Uint32()
  external int dwNumberOfItems;

  @Uint32()
  external int dwIndex;

  @Array(1)
  external Array<WLAN_AVAILABLE_NETWORK> Network;
}

/// The WLAN_BSS_ENTRY structure contains information about a basic service
/// set (BSS).
///
/// {@category Struct}
class WLAN_BSS_ENTRY extends Struct {
  external DOT11_SSID dot11Ssid;

  @Uint32()
  external int uPhyId;

  @Array(6)
  external Array<Uint8> dot11Bssid;

  @Int32()
  external int dot11BssType;

  @Int32()
  external int dot11BssPhyType;

  @Int32()
  external int lRssi;

  @Uint32()
  external int uLinkQuality;

  @Uint8()
  external int bInRegDomain;

  @Uint16()
  external int usBeaconPeriod;

  @Uint64()
  external int ullTimestamp;

  @Uint64()
  external int ullHostTimestamp;

  @Uint16()
  external int usCapabilityInformation;

  @Uint32()
  external int ulChCenterFrequency;

  external WLAN_RATE_SET wlanRateSet;

  @Uint32()
  external int ulIeOffset;

  @Uint32()
  external int ulIeSize;
}

/// The WLAN_BSS_LIST structure contains a list of basic service set (BSS)
/// entries.
///
/// {@category Struct}
class WLAN_BSS_LIST extends Struct {
  @Uint32()
  external int dwTotalSize;

  @Uint32()
  external int dwNumberOfItems;

  @Array(1)
  external Array<WLAN_BSS_ENTRY> wlanBssEntries;
}

/// The WLAN_CONNECTION_ATTRIBUTES structure defines the attributes of a
/// wireless connection.
///
/// {@category Struct}
class WLAN_CONNECTION_ATTRIBUTES extends Struct {
  @Int32()
  external int isState;

  @Int32()
  external int wlanConnectionMode;

  @Array(256)
  external Array<Uint16> _strProfileName;

  String get strProfileName {
    final charCodes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (_strProfileName[i] == 0x00) break;
      charCodes.add(_strProfileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set strProfileName(String value) {
    final stringToStore = value.padRight(256, '\x00');
    for (var i = 0; i < 256; i++) {
      _strProfileName[i] = stringToStore.codeUnitAt(i);
    }
  }

  external WLAN_ASSOCIATION_ATTRIBUTES wlanAssociationAttributes;

  external WLAN_SECURITY_ATTRIBUTES wlanSecurityAttributes;
}

/// The WLAN_CONNECTION_NOTIFICATION_DATA structure contains information
/// about connection related notifications.
///
/// {@category Struct}
class WLAN_CONNECTION_NOTIFICATION_DATA extends Struct {
  @Int32()
  external int wlanConnectionMode;

  @Array(256)
  external Array<Uint16> _strProfileName;

  String get strProfileName {
    final charCodes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (_strProfileName[i] == 0x00) break;
      charCodes.add(_strProfileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set strProfileName(String value) {
    final stringToStore = value.padRight(256, '\x00');
    for (var i = 0; i < 256; i++) {
      _strProfileName[i] = stringToStore.codeUnitAt(i);
    }
  }

  external DOT11_SSID dot11Ssid;

  @Int32()
  external int dot11BssType;

  @Int32()
  external int bSecurityEnabled;

  @Uint32()
  external int wlanReasonCode;

  @Uint32()
  external int dwFlags;

  @Array(1)
  external Array<Uint16> _strProfileXml;

  String get strProfileXml {
    final charCodes = <int>[];
    for (var i = 0; i < 1; i++) {
      if (_strProfileXml[i] == 0x00) break;
      charCodes.add(_strProfileXml[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set strProfileXml(String value) {
    final stringToStore = value.padRight(1, '\x00');
    for (var i = 0; i < 1; i++) {
      _strProfileXml[i] = stringToStore.codeUnitAt(i);
    }
  }
}

/// The WLAN_CONNECTION_PARAMETERS structure specifies the parameters used
/// when using the WlanConnect function.
///
/// {@category Struct}
class WLAN_CONNECTION_PARAMETERS extends Struct {
  @Int32()
  external int wlanConnectionMode;

  external Pointer<Utf16> strProfile;

  external Pointer<DOT11_SSID> pDot11Ssid;

  external Pointer<DOT11_BSSID_LIST> pDesiredBssidList;

  @Int32()
  external int dot11BssType;

  @Uint32()
  external int dwFlags;
}

/// A WLAN_COUNTRY_OR_REGION_STRING_LIST structure contains a list of
/// supported country or region strings.
///
/// {@category Struct}
class WLAN_COUNTRY_OR_REGION_STRING_LIST extends Struct {
  @Uint32()
  external int dwNumberOfItems;

  @Array(3)
  external Array<Uint8> pCountryOrRegionStringList;
}

/// Contains an array of device service GUIDs.
///
/// {@category Struct}
class WLAN_DEVICE_SERVICE_GUID_LIST extends Struct {
  @Uint32()
  external int dwNumberOfItems;

  @Uint32()
  external int dwIndex;

  @Array(1)
  external Array<GUID> DeviceService;
}

/// A structure that represents a device service notification.
///
/// {@category Struct}
class WLAN_DEVICE_SERVICE_NOTIFICATION_DATA extends Struct {
  external GUID DeviceService;

  @Uint32()
  external int dwOpCode;

  @Uint32()
  external int dwDataSize;

  @Array(1)
  external Array<Uint8> DataBlob;
}

/// The WLAN_HOSTED_NETWORK_CONNECTION_SETTINGS structure contains
/// information about the connection settings on the wireless Hosted
/// Network.
///
/// {@category Struct}
class WLAN_HOSTED_NETWORK_CONNECTION_SETTINGS extends Struct {
  external DOT11_SSID hostedNetworkSSID;

  @Uint32()
  external int dwMaxNumberOfPeers;
}

/// The WLAN_HOSTED_NETWORK_DATA_PEER_STATE_CHANGE structure contains
/// information about a network state change for a data peer on the wireless
/// Hosted Network.
///
/// {@category Struct}
class WLAN_HOSTED_NETWORK_DATA_PEER_STATE_CHANGE extends Struct {
  external WLAN_HOSTED_NETWORK_PEER_STATE OldState;

  external WLAN_HOSTED_NETWORK_PEER_STATE NewState;

  @Int32()
  external int PeerStateChangeReason;
}

/// The WLAN_HOSTED_NETWORK_PEER_STATE structure contains information about
/// the peer state for a peer on the wireless Hosted Network.
///
/// {@category Struct}
class WLAN_HOSTED_NETWORK_PEER_STATE extends Struct {
  @Array(6)
  external Array<Uint8> PeerMacAddress;

  @Int32()
  external int PeerAuthState;
}

/// The WLAN_HOSTED_NETWORK_RADIO_STATE structure contains information about
/// the radio state on the wireless Hosted Network.
///
/// {@category Struct}
class WLAN_HOSTED_NETWORK_RADIO_STATE extends Struct {
  @Int32()
  external int dot11SoftwareRadioState;

  @Int32()
  external int dot11HardwareRadioState;
}

/// The WLAN_HOSTED_NETWORK_SECURITY_SETTINGS structure contains information
/// about the security settings on the wireless Hosted Network.
///
/// {@category Struct}
class WLAN_HOSTED_NETWORK_SECURITY_SETTINGS extends Struct {
  @Int32()
  external int dot11AuthAlgo;

  @Int32()
  external int dot11CipherAlgo;
}

/// The WLAN_HOSTED_NETWORK_STATE_CHANGE structure contains information
/// about a network state change on the wireless Hosted Network.
///
/// {@category Struct}
class WLAN_HOSTED_NETWORK_STATE_CHANGE extends Struct {
  @Int32()
  external int OldState;

  @Int32()
  external int NewState;

  @Int32()
  external int StateChangeReason;
}

/// The WLAN_HOSTED_NETWORK_STATUS structure contains information about the
/// status of the wireless Hosted Network.
///
/// {@category Struct}
class WLAN_HOSTED_NETWORK_STATUS extends Struct {
  @Int32()
  external int HostedNetworkState;

  external GUID IPDeviceID;

  @Array(6)
  external Array<Uint8> wlanHostedNetworkBSSID;

  @Int32()
  external int dot11PhyType;

  @Uint32()
  external int ulChannelFrequency;

  @Uint32()
  external int dwNumberOfPeers;

  @Array(1)
  external Array<WLAN_HOSTED_NETWORK_PEER_STATE> PeerList;
}

/// The WLAN_INTERFACE_CAPABILITY structure contains information about the
/// capabilities of an interface.
///
/// {@category Struct}
class WLAN_INTERFACE_CAPABILITY extends Struct {
  @Int32()
  external int interfaceType;

  @Int32()
  external int bDot11DSupported;

  @Uint32()
  external int dwMaxDesiredSsidListSize;

  @Uint32()
  external int dwMaxDesiredBssidListSize;

  @Uint32()
  external int dwNumberOfSupportedPhys;

  @Array(64)
  external Array<Int32> dot11PhyTypes;
}

/// The WLAN_INTERFACE_INFO structure contains information about a wireless
/// LAN interface.
///
/// {@category Struct}
class WLAN_INTERFACE_INFO extends Struct {
  external GUID InterfaceGuid;

  @Array(256)
  external Array<Uint16> _strInterfaceDescription;

  String get strInterfaceDescription {
    final charCodes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (_strInterfaceDescription[i] == 0x00) break;
      charCodes.add(_strInterfaceDescription[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set strInterfaceDescription(String value) {
    final stringToStore = value.padRight(256, '\x00');
    for (var i = 0; i < 256; i++) {
      _strInterfaceDescription[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Int32()
  external int isState;
}

/// The WLAN_INTERFACE_INFO_LIST structure contains an array of NIC
/// interface information.
///
/// {@category Struct}
class WLAN_INTERFACE_INFO_LIST extends Struct {
  @Uint32()
  external int dwNumberOfItems;

  @Uint32()
  external int dwIndex;

  @Array(1)
  external Array<WLAN_INTERFACE_INFO> InterfaceInfo;
}

/// The WLAN_MAC_FRAME_STATISTICS structure contains information about sent
/// and received MAC frames.
///
/// {@category Struct}
class WLAN_MAC_FRAME_STATISTICS extends Struct {
  @Uint64()
  external int ullTransmittedFrameCount;

  @Uint64()
  external int ullReceivedFrameCount;

  @Uint64()
  external int ullWEPExcludedCount;

  @Uint64()
  external int ullTKIPLocalMICFailures;

  @Uint64()
  external int ullTKIPReplays;

  @Uint64()
  external int ullTKIPICVErrorCount;

  @Uint64()
  external int ullCCMPReplays;

  @Uint64()
  external int ullCCMPDecryptErrors;

  @Uint64()
  external int ullWEPUndecryptableCount;

  @Uint64()
  external int ullWEPICVErrorCount;

  @Uint64()
  external int ullDecryptSuccessCount;

  @Uint64()
  external int ullDecryptFailureCount;
}

/// The WLAN_MSM_NOTIFICATION_DATA structure contains information about
/// media specific module (MSM) connection related notifications.
///
/// {@category Struct}
class WLAN_MSM_NOTIFICATION_DATA extends Struct {
  @Int32()
  external int wlanConnectionMode;

  @Array(256)
  external Array<Uint16> _strProfileName;

  String get strProfileName {
    final charCodes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (_strProfileName[i] == 0x00) break;
      charCodes.add(_strProfileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set strProfileName(String value) {
    final stringToStore = value.padRight(256, '\x00');
    for (var i = 0; i < 256; i++) {
      _strProfileName[i] = stringToStore.codeUnitAt(i);
    }
  }

  external DOT11_SSID dot11Ssid;

  @Int32()
  external int dot11BssType;

  @Array(6)
  external Array<Uint8> dot11MacAddr;

  @Int32()
  external int bSecurityEnabled;

  @Int32()
  external int bFirstPeer;

  @Int32()
  external int bLastPeer;

  @Uint32()
  external int wlanReasonCode;
}

/// The WLAN_PHY_FRAME_STATISTICS structure contains information about sent
/// and received PHY frames.
///
/// {@category Struct}
class WLAN_PHY_FRAME_STATISTICS extends Struct {
  @Uint64()
  external int ullTransmittedFrameCount;

  @Uint64()
  external int ullMulticastTransmittedFrameCount;

  @Uint64()
  external int ullFailedCount;

  @Uint64()
  external int ullRetryCount;

  @Uint64()
  external int ullMultipleRetryCount;

  @Uint64()
  external int ullMaxTXLifetimeExceededCount;

  @Uint64()
  external int ullTransmittedFragmentCount;

  @Uint64()
  external int ullRTSSuccessCount;

  @Uint64()
  external int ullRTSFailureCount;

  @Uint64()
  external int ullACKFailureCount;

  @Uint64()
  external int ullReceivedFrameCount;

  @Uint64()
  external int ullMulticastReceivedFrameCount;

  @Uint64()
  external int ullPromiscuousReceivedFrameCount;

  @Uint64()
  external int ullMaxRXLifetimeExceededCount;

  @Uint64()
  external int ullFrameDuplicateCount;

  @Uint64()
  external int ullReceivedFragmentCount;

  @Uint64()
  external int ullPromiscuousReceivedFragmentCount;

  @Uint64()
  external int ullFCSErrorCount;
}

/// The WLAN_PHY_RADIO_STATE structure specifies the radio state on a
/// specific physical layer (PHY) type.
///
/// {@category Struct}
class WLAN_PHY_RADIO_STATE extends Struct {
  @Uint32()
  external int dwPhyIndex;

  @Int32()
  external int dot11SoftwareRadioState;

  @Int32()
  external int dot11HardwareRadioState;
}

/// The WLAN_PROFILE_INFO structure contains basic information about a
/// profile.
///
/// {@category Struct}
class WLAN_PROFILE_INFO extends Struct {
  @Array(256)
  external Array<Uint16> _strProfileName;

  String get strProfileName {
    final charCodes = <int>[];
    for (var i = 0; i < 256; i++) {
      if (_strProfileName[i] == 0x00) break;
      charCodes.add(_strProfileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set strProfileName(String value) {
    final stringToStore = value.padRight(256, '\x00');
    for (var i = 0; i < 256; i++) {
      _strProfileName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Uint32()
  external int dwFlags;
}

/// The WLAN_PROFILE_INFO_LIST structure contains a list of wireless profile
/// information.
///
/// {@category Struct}
class WLAN_PROFILE_INFO_LIST extends Struct {
  @Uint32()
  external int dwNumberOfItems;

  @Uint32()
  external int dwIndex;

  @Array(1)
  external Array<WLAN_PROFILE_INFO> ProfileInfo;
}

/// The WLAN_RADIO_STATE structure specifies the radio state on a list of
/// physical layer (PHY) types.
///
/// {@category Struct}
class WLAN_RADIO_STATE extends Struct {
  @Uint32()
  external int dwNumberOfPhys;

  @Array(64)
  external Array<WLAN_PHY_RADIO_STATE> PhyRadioState;
}

/// The set of supported data rates.
///
/// {@category Struct}
class WLAN_RATE_SET extends Struct {
  @Uint32()
  external int uRateSetLength;

  @Array(126)
  external Array<Uint16> usRateSet;
}

/// The WLAN_RAW_DATA structure contains raw data in the form of a blob that
/// is used by some Native Wifi functions.
///
/// {@category Struct}
class WLAN_RAW_DATA extends Struct {
  @Uint32()
  external int dwDataSize;

  @Array(1)
  external Array<Uint8> DataBlob;
}

/// The WLAN_RAW_DATA_LIST structure contains raw data in the form of an
/// array of data blobs that are used by some Native Wifi functions.
///
/// {@category Struct}
class WLAN_RAW_DATA_LIST extends Struct {
  @Uint32()
  external int dwTotalSize;

  @Uint32()
  external int dwNumberOfItems;

  @Array(1)
  external Array<_WLAN_RAW_DATA_LIST__Anonymous_e__Struct> DataList;
}

/// {@category Struct}
class _WLAN_RAW_DATA_LIST__Anonymous_e__Struct extends Struct {
  @Uint32()
  external int dwDataOffset;

  @Uint32()
  external int dwDataSize;
}

/// The WLAN_SECURITY_ATTRIBUTES structure defines the security attributes
/// for a wireless connection.
///
/// {@category Struct}
class WLAN_SECURITY_ATTRIBUTES extends Struct {
  @Int32()
  external int bSecurityEnabled;

  @Int32()
  external int bOneXEnabled;

  @Int32()
  external int dot11AuthAlgorithm;

  @Int32()
  external int dot11CipherAlgorithm;
}

/// The WLAN_STATISTICS structure contains assorted statistics about an
/// interface.
///
/// {@category Struct}
class WLAN_STATISTICS extends Struct {
  @Uint64()
  external int ullFourWayHandshakeFailures;

  @Uint64()
  external int ullTKIPCounterMeasuresInvoked;

  @Uint64()
  external int ullReserved;

  external WLAN_MAC_FRAME_STATISTICS MacUcastCounters;

  external WLAN_MAC_FRAME_STATISTICS MacMcastCounters;

  @Uint32()
  external int dwNumberOfPhys;

  @Array(1)
  external Array<WLAN_PHY_FRAME_STATISTICS> PhyCounters;
}

/// Contains window class information. It is used with the RegisterClassEx
/// and GetClassInfoEx functions. The WNDCLASSEX structure is similar to the
/// WNDCLASS structure. There are two differences. WNDCLASSEX includes the
/// cbSize member, which specifies the size of the structure, and the
/// hIconSm member, which contains a handle to a small icon associated with
/// the window class.
///
/// {@category Struct}
class WNDCLASSEX extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int style;

  external Pointer<NativeFunction<WindowProc>> lpfnWndProc;

  @Int32()
  external int cbClsExtra;

  @Int32()
  external int cbWndExtra;

  @IntPtr()
  external int hInstance;

  @IntPtr()
  external int hIcon;

  @IntPtr()
  external int hCursor;

  @IntPtr()
  external int hbrBackground;

  external Pointer<Utf16> lpszMenuName;

  external Pointer<Utf16> lpszClassName;

  @IntPtr()
  external int hIconSm;
}

/// Contains the window class attributes that are registered by the
/// RegisterClass function.
///
/// {@category Struct}
class WNDCLASS extends Struct {
  @Uint32()
  external int style;

  external Pointer<NativeFunction<WindowProc>> lpfnWndProc;

  @Int32()
  external int cbClsExtra;

  @Int32()
  external int cbWndExtra;

  @IntPtr()
  external int hInstance;

  @IntPtr()
  external int hIcon;

  @IntPtr()
  external int hCursor;

  @IntPtr()
  external int hbrBackground;

  external Pointer<Utf16> lpszMenuName;

  external Pointer<Utf16> lpszClassName;
}

/// Defines options that are used to set window visual style attributes.
///
/// {@category Struct}
class WTA_OPTIONS extends Struct {
  @Uint32()
  external int dwFlags;

  @Uint32()
  external int dwMask;
}

/// The XFORM structure specifies a world-space to page-space
/// transformation.
///
/// {@category Struct}
class XFORM extends Struct {
  @Float()
  external double eM11;

  @Float()
  external double eM12;

  @Float()
  external double eM21;

  @Float()
  external double eM22;

  @Float()
  external double eDx;

  @Float()
  external double eDy;
}

/// Contains information on battery type and charge state.
///
/// {@category Struct}
class XINPUT_BATTERY_INFORMATION extends Struct {
  @Uint8()
  external int BatteryType;

  @Uint8()
  external int BatteryLevel;
}

/// Describes the capabilities of a connected controller. The
/// XInputGetCapabilities function returns XINPUT_CAPABILITIES.
///
/// {@category Struct}
class XINPUT_CAPABILITIES extends Struct {
  @Uint8()
  external int Type;

  @Uint8()
  external int SubType;

  @Uint16()
  external int Flags;

  external XINPUT_GAMEPAD Gamepad;

  external XINPUT_VIBRATION Vibration;
}

/// Describes the current state of the controller.
///
/// {@category Struct}
class XINPUT_GAMEPAD extends Struct {
  @Uint16()
  external int wButtons;

  @Uint8()
  external int bLeftTrigger;

  @Uint8()
  external int bRightTrigger;

  @Int16()
  external int sThumbLX;

  @Int16()
  external int sThumbLY;

  @Int16()
  external int sThumbRX;

  @Int16()
  external int sThumbRY;
}

/// Specifies keystroke data returned by XInputGetKeystroke.
///
/// {@category Struct}
class XINPUT_KEYSTROKE extends Struct {
  @Uint16()
  external int VirtualKey;

  @Uint16()
  external int Unicode;

  @Uint16()
  external int Flags;

  @Uint8()
  external int UserIndex;

  @Uint8()
  external int HidCode;
}

/// Represents the state of a controller.
///
/// {@category Struct}
class XINPUT_STATE extends Struct {
  @Uint32()
  external int dwPacketNumber;

  external XINPUT_GAMEPAD Gamepad;
}

/// Specifies motor speed levels for the vibration function of a controller.
///
/// {@category Struct}
class XINPUT_VIBRATION extends Struct {
  @Uint16()
  external int wLeftMotorSpeed;

  @Uint16()
  external int wRightMotorSpeed;
}

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Maps FFI prototypes onto the corresponding Win32 API function calls

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, non_constant_identifier_names
// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../callbacks.dart';
import '../combase.dart';
import '../guid.dart';
import '../structs.g.dart';
import '../variant.dart';

final _winmm = DynamicLibrary.open('winmm.dll');

/// The mciGetDeviceID function retrieves the device identifier
/// corresponding to the name of an open device.
///
/// ```c
/// MCIDEVICEID mciGetDeviceIDW(
///   LPCTSTR lpszDevice
/// );
/// ```
/// {@category winmm}
int mciGetDeviceID(Pointer<Utf16> pszDevice) => _mciGetDeviceID(pszDevice);

final _mciGetDeviceID = _winmm.lookupFunction<
    Uint32 Function(Pointer<Utf16> pszDevice),
    int Function(Pointer<Utf16> pszDevice)>('mciGetDeviceIDW');

/// The mciGetDeviceIDFromElementID function retrieves the MCI device
/// identifier corresponding to an element identifier.
///
/// ```c
/// MCIDEVICEID mciGetDeviceIDFromElementIDW(
///   DWORD   dwElementID,
///   LPCTSTR lpstrType
/// );
/// ```
/// {@category winmm}
int mciGetDeviceIDFromElementID(int dwElementID, Pointer<Utf16> lpstrType) =>
    _mciGetDeviceIDFromElementID(dwElementID, lpstrType);

final _mciGetDeviceIDFromElementID = _winmm.lookupFunction<
    Uint32 Function(Uint32 dwElementID, Pointer<Utf16> lpstrType),
    int Function(int dwElementID,
        Pointer<Utf16> lpstrType)>('mciGetDeviceIDFromElementIDW');

/// The mciGetErrorString function retrieves a string that describes the
/// specified MCI error code.
///
/// ```c
/// BOOL mciGetErrorStringW(
///   DWORD  fdwError,
///   LPTSTR lpszErrorText,
///   UINT   cchErrorText
/// );
/// ```
/// {@category winmm}
int mciGetErrorString(int mcierr, Pointer<Utf16> pszText, int cchText) =>
    _mciGetErrorString(mcierr, pszText, cchText);

final _mciGetErrorString = _winmm.lookupFunction<
    Int32 Function(Uint32 mcierr, Pointer<Utf16> pszText, Uint32 cchText),
    int Function(
        int mcierr, Pointer<Utf16> pszText, int cchText)>('mciGetErrorStringW');

/// The mciSendCommand function sends a command message to the specified MCI
/// device.
///
/// ```c
/// MCIERROR mciSendCommandW(
///   MCIDEVICEID IDDevice,
///   UINT        uMsg,
///   DWORD_PTR   fdwCommand,
///   DWORD_PTR   dwParam
/// );
/// ```
/// {@category winmm}
int mciSendCommand(int mciId, int uMsg, int dwParam1, int dwParam2) =>
    _mciSendCommand(mciId, uMsg, dwParam1, dwParam2);

final _mciSendCommand = _winmm.lookupFunction<
    Uint32 Function(
        Uint32 mciId, Uint32 uMsg, IntPtr dwParam1, IntPtr dwParam2),
    int Function(
        int mciId, int uMsg, int dwParam1, int dwParam2)>('mciSendCommandW');

/// The mciSendString function sends a command string to an MCI device. The
/// device that the command is sent to is specified in the command string.
///
/// ```c
/// MCIERROR mciSendStringW(
///   LPCTSTR lpszCommand,
///   LPTSTR  lpszReturnString,
///   UINT    cchReturn,
///   HANDLE  hwndCallback
/// );
/// ```
/// {@category winmm}
int mciSendString(Pointer<Utf16> lpstrCommand, Pointer<Utf16> lpstrReturnString,
        int uReturnLength, int hwndCallback) =>
    _mciSendString(
        lpstrCommand, lpstrReturnString, uReturnLength, hwndCallback);

final _mciSendString = _winmm.lookupFunction<
    Uint32 Function(
        Pointer<Utf16> lpstrCommand,
        Pointer<Utf16> lpstrReturnString,
        Uint32 uReturnLength,
        IntPtr hwndCallback),
    int Function(Pointer<Utf16> lpstrCommand, Pointer<Utf16> lpstrReturnString,
        int uReturnLength, int hwndCallback)>('mciSendStringW');

/// The midiConnect function connects a MIDI input device to a MIDI thru or
/// output device, or connects a MIDI thru device to a MIDI output device.
///
/// ```c
/// MMRESULT midiConnect(
///   HMIDI    hmi,
///   HMIDIOUT hmo,
///   LPVOID   pReserved
/// );
/// ```
/// {@category winmm}
int midiConnect(int hmi, int hmo, Pointer pReserved) =>
    _midiConnect(hmi, hmo, pReserved);

final _midiConnect = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmi, IntPtr hmo, Pointer pReserved),
    int Function(int hmi, int hmo, Pointer pReserved)>('midiConnect');

/// The midiDisconnect function disconnects a MIDI input device from a MIDI
/// thru or output device, or disconnects a MIDI thru device from a MIDI
/// output device.
///
/// ```c
/// MMRESULT midiDisconnect(
///   HMIDI    hmi,
///   HMIDIOUT hmo,
///   LPVOID   pReserved
/// );
/// ```
/// {@category winmm}
int midiDisconnect(int hmi, int hmo, Pointer pReserved) =>
    _midiDisconnect(hmi, hmo, pReserved);

final _midiDisconnect = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmi, IntPtr hmo, Pointer pReserved),
    int Function(int hmi, int hmo, Pointer pReserved)>('midiDisconnect');

/// The midiInClose function closes the specified MIDI input device.
///
/// ```c
/// MMRESULT midiInClose(
///   HMIDIIN hmi
/// );
/// ```
/// {@category winmm}
int midiInClose(int hmi) => _midiInClose(hmi);

final _midiInClose =
    _winmm.lookupFunction<Uint32 Function(IntPtr hmi), int Function(int hmi)>(
        'midiInClose');

/// The midiInGetDevCaps function determines the capabilities of a specified
/// MIDI input device.
///
/// ```c
/// MMRESULT midiInGetDevCapsW(
///   UINT_PTR      uDeviceID,
///   LPMIDIINCAPSW pmic,
///   UINT          cbmic
/// );
/// ```
/// {@category winmm}
int midiInGetDevCaps(int uDeviceID, Pointer<MIDIINCAPS> pmic, int cbmic) =>
    _midiInGetDevCaps(uDeviceID, pmic, cbmic);

final _midiInGetDevCaps = _winmm.lookupFunction<
    Uint32 Function(IntPtr uDeviceID, Pointer<MIDIINCAPS> pmic, Uint32 cbmic),
    int Function(int uDeviceID, Pointer<MIDIINCAPS> pmic,
        int cbmic)>('midiInGetDevCapsW');

/// The midiInGetErrorText function retrieves a textual description for an
/// error identified by the specified error code.
///
/// ```c
/// MMRESULT midiInGetErrorTextW(
///   MMRESULT mmrError,
///   LPWSTR   pszText,
///   UINT     cchText
/// );
/// ```
/// {@category winmm}
int midiInGetErrorText(int mmrError, Pointer<Utf16> pszText, int cchText) =>
    _midiInGetErrorText(mmrError, pszText, cchText);

final _midiInGetErrorText = _winmm.lookupFunction<
    Uint32 Function(Uint32 mmrError, Pointer<Utf16> pszText, Uint32 cchText),
    int Function(int mmrError, Pointer<Utf16> pszText,
        int cchText)>('midiInGetErrorTextW');

/// The midiInGetID function gets the device identifier for the given MIDI
/// input device.
///
/// ```c
/// MMRESULT midiInGetID(
///   HMIDIIN hmi,
///   LPUINT  puDeviceID
/// );
/// ```
/// {@category winmm}
int midiInGetID(int hmi, Pointer<Uint32> puDeviceID) =>
    _midiInGetID(hmi, puDeviceID);

final _midiInGetID = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmi, Pointer<Uint32> puDeviceID),
    int Function(int hmi, Pointer<Uint32> puDeviceID)>('midiInGetID');

/// The midiInGetNumDevs function retrieves the number of MIDI input devices
/// in the system.
///
/// ```c
/// UINT midiInGetNumDevs();
/// ```
/// {@category winmm}
int midiInGetNumDevs() => _midiInGetNumDevs();

final _midiInGetNumDevs = _winmm
    .lookupFunction<Uint32 Function(), int Function()>('midiInGetNumDevs');

/// The midiInMessage function sends a message to the MIDI device driver.
///
/// ```c
/// MMRESULT midiInMessage(
///   HMIDIIN   hmi,
///   UINT      uMsg,
///   DWORD_PTR dw1,
///   DWORD_PTR dw2
/// );
/// ```
/// {@category winmm}
int midiInMessage(int hmi, int uMsg, int dw1, int dw2) =>
    _midiInMessage(hmi, uMsg, dw1, dw2);

final _midiInMessage = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmi, Uint32 uMsg, IntPtr dw1, IntPtr dw2),
    int Function(int hmi, int uMsg, int dw1, int dw2)>('midiInMessage');

/// The midiInOpen function opens a specified MIDI input device.
///
/// ```c
/// MMRESULT midiInOpen(
///   LPHMIDIIN phmi,
///   UINT      uDeviceID,
///   DWORD_PTR dwCallback,
///   DWORD_PTR dwInstance,
///   DWORD     fdwOpen
/// );
/// ```
/// {@category winmm}
int midiInOpen(Pointer<IntPtr> phmi, int uDeviceID, int dwCallback,
        int dwInstance, int fdwOpen) =>
    _midiInOpen(phmi, uDeviceID, dwCallback, dwInstance, fdwOpen);

final _midiInOpen = _winmm.lookupFunction<
    Uint32 Function(Pointer<IntPtr> phmi, Uint32 uDeviceID, IntPtr dwCallback,
        IntPtr dwInstance, Uint32 fdwOpen),
    int Function(Pointer<IntPtr> phmi, int uDeviceID, int dwCallback,
        int dwInstance, int fdwOpen)>('midiInOpen');

/// The midiInPrepareHeader function prepares a buffer for MIDI input.
///
/// ```c
/// MMRESULT midiInPrepareHeader(
///   HMIDIIN   hmi,
///   LPMIDIHDR pmh,
///   UINT      cbmh
/// );
/// ```
/// {@category winmm}
int midiInPrepareHeader(int hmi, Pointer<MIDIHDR> pmh, int cbmh) =>
    _midiInPrepareHeader(hmi, pmh, cbmh);

final _midiInPrepareHeader = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmi, Pointer<MIDIHDR> pmh, Uint32 cbmh),
    int Function(
        int hmi, Pointer<MIDIHDR> pmh, int cbmh)>('midiInPrepareHeader');

/// The midiInReset function stops input on a given MIDI input device.
///
/// ```c
/// MMRESULT midiInReset(
///   HMIDIIN hmi
/// );
/// ```
/// {@category winmm}
int midiInReset(int hmi) => _midiInReset(hmi);

final _midiInReset =
    _winmm.lookupFunction<Uint32 Function(IntPtr hmi), int Function(int hmi)>(
        'midiInReset');

/// The midiInStart function starts MIDI input on the specified MIDI input
/// device.
///
/// ```c
/// MMRESULT midiInStart(
///   HMIDIIN hmi
/// );
/// ```
/// {@category winmm}
int midiInStart(int hmi) => _midiInStart(hmi);

final _midiInStart =
    _winmm.lookupFunction<Uint32 Function(IntPtr hmi), int Function(int hmi)>(
        'midiInStart');

/// The midiInStop function stops MIDI input on the specified MIDI input
/// device.
///
/// ```c
/// MMRESULT midiInStop(
///   HMIDIIN hmi
/// );
/// ```
/// {@category winmm}
int midiInStop(int hmi) => _midiInStop(hmi);

final _midiInStop =
    _winmm.lookupFunction<Uint32 Function(IntPtr hmi), int Function(int hmi)>(
        'midiInStop');

/// The midiInUnprepareHeader function cleans up the preparation performed
/// by the midiInPrepareHeader function.
///
/// ```c
/// MMRESULT midiInUnprepareHeader(
///   HMIDIIN   hmi,
///   LPMIDIHDR pmh,
///   UINT      cbmh
/// );
/// ```
/// {@category winmm}
int midiInUnprepareHeader(int hmi, Pointer<MIDIHDR> pmh, int cbmh) =>
    _midiInUnprepareHeader(hmi, pmh, cbmh);

final _midiInUnprepareHeader = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmi, Pointer<MIDIHDR> pmh, Uint32 cbmh),
    int Function(
        int hmi, Pointer<MIDIHDR> pmh, int cbmh)>('midiInUnprepareHeader');

/// The midiOutCacheDrumPatches function requests that an internal MIDI
/// synthesizer device preload and cache a specified set of key-based
/// percussion patches.
///
/// ```c
/// MMRESULT midiOutCacheDrumPatches(
///   HMIDIOUT hmo,
///   UINT     uPatch,
///   LPWORD   pwkya,
///   UINT     fuCache
/// );
/// ```
/// {@category winmm}
int midiOutCacheDrumPatches(
        int hmo, int uPatch, Pointer<Uint16> pwkya, int fuCache) =>
    _midiOutCacheDrumPatches(hmo, uPatch, pwkya, fuCache);

final _midiOutCacheDrumPatches = _winmm.lookupFunction<
    Uint32 Function(
        IntPtr hmo, Uint32 uPatch, Pointer<Uint16> pwkya, Uint32 fuCache),
    int Function(int hmo, int uPatch, Pointer<Uint16> pwkya,
        int fuCache)>('midiOutCacheDrumPatches');

/// The midiOutCachePatches function requests that an internal MIDI
/// synthesizer device preload and cache a specified set of patches.
///
/// ```c
/// MMRESULT midiOutCachePatches(
///   HMIDIOUT hmo,
///   UINT     uBank,
///   LPWORD   pwpa,
///   UINT     fuCache
/// );
/// ```
/// {@category winmm}
int midiOutCachePatches(
        int hmo, int uBank, Pointer<Uint16> pwpa, int fuCache) =>
    _midiOutCachePatches(hmo, uBank, pwpa, fuCache);

final _midiOutCachePatches = _winmm.lookupFunction<
    Uint32 Function(
        IntPtr hmo, Uint32 uBank, Pointer<Uint16> pwpa, Uint32 fuCache),
    int Function(int hmo, int uBank, Pointer<Uint16> pwpa,
        int fuCache)>('midiOutCachePatches');

/// The midiOutClose function closes the specified MIDI output device.
///
/// ```c
/// MMRESULT midiOutClose(
///   HMIDIOUT hmo
/// );
/// ```
/// {@category winmm}
int midiOutClose(int hmo) => _midiOutClose(hmo);

final _midiOutClose =
    _winmm.lookupFunction<Uint32 Function(IntPtr hmo), int Function(int hmo)>(
        'midiOutClose');

/// The midiOutGetDevCaps function queries a specified MIDI output device to
/// determine its capabilities.
///
/// ```c
/// MMRESULT midiOutGetDevCapsW(
///   UINT_PTR       uDeviceID,
///   LPMIDIOUTCAPSW pmoc,
///   UINT           cbmoc
/// );
/// ```
/// {@category winmm}
int midiOutGetDevCaps(int uDeviceID, Pointer<MIDIOUTCAPS> pmoc, int cbmoc) =>
    _midiOutGetDevCaps(uDeviceID, pmoc, cbmoc);

final _midiOutGetDevCaps = _winmm.lookupFunction<
    Uint32 Function(IntPtr uDeviceID, Pointer<MIDIOUTCAPS> pmoc, Uint32 cbmoc),
    int Function(int uDeviceID, Pointer<MIDIOUTCAPS> pmoc,
        int cbmoc)>('midiOutGetDevCapsW');

/// The midiOutGetErrorText function retrieves a textual description for an
/// error identified by the specified error code.
///
/// ```c
/// MMRESULT midiOutGetErrorTextW(
///   MMRESULT mmrError,
///   LPWSTR   pszText,
///   UINT     cchText
/// );
/// ```
/// {@category winmm}
int midiOutGetErrorText(int mmrError, Pointer<Utf16> pszText, int cchText) =>
    _midiOutGetErrorText(mmrError, pszText, cchText);

final _midiOutGetErrorText = _winmm.lookupFunction<
    Uint32 Function(Uint32 mmrError, Pointer<Utf16> pszText, Uint32 cchText),
    int Function(int mmrError, Pointer<Utf16> pszText,
        int cchText)>('midiOutGetErrorTextW');

/// The midiOutGetID function retrieves the device identifier for the given
/// MIDI output device.
///
/// ```c
/// MMRESULT midiOutGetID(
///   HMIDIOUT hmo,
///   LPUINT   puDeviceID
/// );
/// ```
/// {@category winmm}
int midiOutGetID(int hmo, Pointer<Uint32> puDeviceID) =>
    _midiOutGetID(hmo, puDeviceID);

final _midiOutGetID = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmo, Pointer<Uint32> puDeviceID),
    int Function(int hmo, Pointer<Uint32> puDeviceID)>('midiOutGetID');

/// The midiOutGetNumDevs function retrieves the number of MIDI output
/// devices present in the system.
///
/// ```c
/// UINT midiOutGetNumDevs();
/// ```
/// {@category winmm}
int midiOutGetNumDevs() => _midiOutGetNumDevs();

final _midiOutGetNumDevs = _winmm
    .lookupFunction<Uint32 Function(), int Function()>('midiOutGetNumDevs');

/// The midiOutGetVolume function retrieves the current volume setting of a
/// MIDI output device.
///
/// ```c
/// MMRESULT midiOutGetVolume(
///   HMIDIOUT hmo,
///   LPDWORD  pdwVolume
/// );
/// ```
/// {@category winmm}
int midiOutGetVolume(int hmo, Pointer<Uint32> pdwVolume) =>
    _midiOutGetVolume(hmo, pdwVolume);

final _midiOutGetVolume = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmo, Pointer<Uint32> pdwVolume),
    int Function(int hmo, Pointer<Uint32> pdwVolume)>('midiOutGetVolume');

/// The midiOutLongMsg function sends a system-exclusive MIDI message to the
/// specified MIDI output device.
///
/// ```c
/// MMRESULT midiOutLongMsg(
///   HMIDIOUT  hmo,
///   LPMIDIHDR pmh,
///   UINT      cbmh
/// );
/// ```
/// {@category winmm}
int midiOutLongMsg(int hmo, Pointer<MIDIHDR> pmh, int cbmh) =>
    _midiOutLongMsg(hmo, pmh, cbmh);

final _midiOutLongMsg = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmo, Pointer<MIDIHDR> pmh, Uint32 cbmh),
    int Function(int hmo, Pointer<MIDIHDR> pmh, int cbmh)>('midiOutLongMsg');

/// The midiOutMessage function sends a message to the MIDI device drivers.
/// This function is used only for driver-specific messages that are not
/// supported by the MIDI API.
///
/// ```c
/// MMRESULT midiOutMessage(
///   HMIDIOUT  hmo,
///   UINT      uMsg,
///   DWORD_PTR dw1,
///   DWORD_PTR dw2
/// );
/// ```
/// {@category winmm}
int midiOutMessage(int hmo, int uMsg, int dw1, int dw2) =>
    _midiOutMessage(hmo, uMsg, dw1, dw2);

final _midiOutMessage = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmo, Uint32 uMsg, IntPtr dw1, IntPtr dw2),
    int Function(int hmo, int uMsg, int dw1, int dw2)>('midiOutMessage');

/// The midiOutOpen function opens a MIDI output device for playback.
///
/// ```c
/// MMRESULT midiOutOpen(
///   LPHMIDIOUT phmo,
///   UINT       uDeviceID,
///   DWORD_PTR  dwCallback,
///   DWORD_PTR  dwInstance,
///   DWORD      fdwOpen
/// );
/// ```
/// {@category winmm}
int midiOutOpen(Pointer<IntPtr> phmo, int uDeviceID, int dwCallback,
        int dwInstance, int fdwOpen) =>
    _midiOutOpen(phmo, uDeviceID, dwCallback, dwInstance, fdwOpen);

final _midiOutOpen = _winmm.lookupFunction<
    Uint32 Function(Pointer<IntPtr> phmo, Uint32 uDeviceID, IntPtr dwCallback,
        IntPtr dwInstance, Uint32 fdwOpen),
    int Function(Pointer<IntPtr> phmo, int uDeviceID, int dwCallback,
        int dwInstance, int fdwOpen)>('midiOutOpen');

/// The midiOutPrepareHeader function prepares a MIDI system-exclusive or
/// stream buffer for output.
///
/// ```c
/// MMRESULT midiOutPrepareHeader(
///   HMIDIOUT  hmo,
///   LPMIDIHDR pmh,
///   UINT      cbmh
/// );
/// ```
/// {@category winmm}
int midiOutPrepareHeader(int hmo, Pointer<MIDIHDR> pmh, int cbmh) =>
    _midiOutPrepareHeader(hmo, pmh, cbmh);

final _midiOutPrepareHeader = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmo, Pointer<MIDIHDR> pmh, Uint32 cbmh),
    int Function(
        int hmo, Pointer<MIDIHDR> pmh, int cbmh)>('midiOutPrepareHeader');

/// The midiOutReset function turns off all notes on all MIDI channels for
/// the specified MIDI output device.
///
/// ```c
/// MMRESULT midiOutReset(
///   HMIDIOUT hmo
/// );
/// ```
/// {@category winmm}
int midiOutReset(int hmo) => _midiOutReset(hmo);

final _midiOutReset =
    _winmm.lookupFunction<Uint32 Function(IntPtr hmo), int Function(int hmo)>(
        'midiOutReset');

/// The midiOutSetVolume function sets the volume of a MIDI output device.
///
/// ```c
/// MMRESULT midiOutSetVolume(
///   HMIDIOUT hmo,
///   DWORD    dwVolume
/// );
/// ```
/// {@category winmm}
int midiOutSetVolume(int hmo, int dwVolume) => _midiOutSetVolume(hmo, dwVolume);

final _midiOutSetVolume = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmo, Uint32 dwVolume),
    int Function(int hmo, int dwVolume)>('midiOutSetVolume');

/// The midiOutShortMsg function sends a short MIDI message to the specified
/// MIDI output device.
///
/// ```c
/// MMRESULT midiOutShortMsg(
///   HMIDIOUT hmo,
///   DWORD    dwMsg
/// );
/// ```
/// {@category winmm}
int midiOutShortMsg(int hmo, int dwMsg) => _midiOutShortMsg(hmo, dwMsg);

final _midiOutShortMsg = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmo, Uint32 dwMsg),
    int Function(int hmo, int dwMsg)>('midiOutShortMsg');

/// The midiOutUnprepareHeader function cleans up the preparation performed
/// by the midiOutPrepareHeader function.
///
/// ```c
/// MMRESULT midiOutUnprepareHeader(
///   HMIDIOUT  hmo,
///   LPMIDIHDR pmh,
///   UINT      cbmh
/// );
/// ```
/// {@category winmm}
int midiOutUnprepareHeader(int hmo, Pointer<MIDIHDR> pmh, int cbmh) =>
    _midiOutUnprepareHeader(hmo, pmh, cbmh);

final _midiOutUnprepareHeader = _winmm.lookupFunction<
    Uint32 Function(IntPtr hmo, Pointer<MIDIHDR> pmh, Uint32 cbmh),
    int Function(
        int hmo, Pointer<MIDIHDR> pmh, int cbmh)>('midiOutUnprepareHeader');

/// The PlaySound function plays a sound specified by the given file name,
/// resource, or system event.
///
/// ```c
/// BOOL PlaySoundW(
///   LPCTSTR pszSound,
///   HMODULE hmod,
///   DWORD fdwSound);
/// ```
/// {@category winmm}
int PlaySound(Pointer<Utf16> pszSound, int hmod, int fdwSound) =>
    _PlaySound(pszSound, hmod, fdwSound);

final _PlaySound = _winmm.lookupFunction<
    Int32 Function(Pointer<Utf16> pszSound, IntPtr hmod, Uint32 fdwSound),
    int Function(
        Pointer<Utf16> pszSound, int hmod, int fdwSound)>('PlaySoundW');

/// The waveOutClose function closes the given waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutClose(
///   HWAVEOUT hwo
///   );
/// ```
/// {@category winmm}
int waveOutClose(int hwo) => _waveOutClose(hwo);

final _waveOutClose =
    _winmm.lookupFunction<Uint32 Function(IntPtr hwo), int Function(int hwo)>(
        'waveOutClose');

/// The waveOutGetDevCaps function retrieves the capabilities of a given
/// waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutGetDevCapsW(
///   UINT          uDeviceID,
///   LPWAVEOUTCAPS pwoc,
///   UINT          cbwoc
/// );
/// ```
/// {@category winmm}
int waveOutGetDevCaps(int uDeviceID, Pointer<WAVEOUTCAPS> pwoc, int cbwoc) =>
    _waveOutGetDevCaps(uDeviceID, pwoc, cbwoc);

final _waveOutGetDevCaps = _winmm.lookupFunction<
    Uint32 Function(IntPtr uDeviceID, Pointer<WAVEOUTCAPS> pwoc, Uint32 cbwoc),
    int Function(int uDeviceID, Pointer<WAVEOUTCAPS> pwoc,
        int cbwoc)>('waveOutGetDevCapsW');

/// The waveOutGetErrorText function retrieves a textual description of the
/// error identified by the given error number.
///
/// ```c
/// MMRESULT waveOutGetErrorTextW(
///   MMRESULT mmrError,
///   LPWSTR    pszText,
///   UINT     cchText
/// );
/// ```
/// {@category winmm}
int waveOutGetErrorText(int mmrError, Pointer<Utf16> pszText, int cchText) =>
    _waveOutGetErrorText(mmrError, pszText, cchText);

final _waveOutGetErrorText = _winmm.lookupFunction<
    Uint32 Function(Uint32 mmrError, Pointer<Utf16> pszText, Uint32 cchText),
    int Function(int mmrError, Pointer<Utf16> pszText,
        int cchText)>('waveOutGetErrorTextW');

/// The waveOutGetID function retrieves the device identifier for the given
/// waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutGetID(
///   HWAVEOUT hwo,
///   LPUINT   puDeviceID
/// );
/// ```
/// {@category winmm}
int waveOutGetID(int hwo, Pointer<Uint32> puDeviceID) =>
    _waveOutGetID(hwo, puDeviceID);

final _waveOutGetID = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Pointer<Uint32> puDeviceID),
    int Function(int hwo, Pointer<Uint32> puDeviceID)>('waveOutGetID');

/// The waveOutGetNumDevs function retrieves the number of waveform-audio
/// output devices present in the system.
///
/// ```c
/// UINT waveOutGetNumDevs();
/// ```
/// {@category winmm}
int waveOutGetNumDevs() => _waveOutGetNumDevs();

final _waveOutGetNumDevs = _winmm
    .lookupFunction<Uint32 Function(), int Function()>('waveOutGetNumDevs');

/// The waveOutGetPitch function retrieves the current pitch setting for the
/// specified waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutGetPitch(
///   HWAVEOUT hwo,
///   LPDWORD  pdwPitch
/// );
/// ```
/// {@category winmm}
int waveOutGetPitch(int hwo, Pointer<Uint32> pdwPitch) =>
    _waveOutGetPitch(hwo, pdwPitch);

final _waveOutGetPitch = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Pointer<Uint32> pdwPitch),
    int Function(int hwo, Pointer<Uint32> pdwPitch)>('waveOutGetPitch');

/// The waveOutGetPlaybackRate function retrieves the current playback rate
/// for the specified waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutGetPlaybackRate(
///   HWAVEOUT hwo,
///   LPDWORD  pdwRate
/// );
/// ```
/// {@category winmm}
int waveOutGetPlaybackRate(int hwo, Pointer<Uint32> pdwRate) =>
    _waveOutGetPlaybackRate(hwo, pdwRate);

final _waveOutGetPlaybackRate = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Pointer<Uint32> pdwRate),
    int Function(int hwo, Pointer<Uint32> pdwRate)>('waveOutGetPlaybackRate');

/// The waveOutGetPosition function retrieves the current playback position
/// of the given waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutGetPosition(
///   HWAVEOUT hwo,
///   LPMMTIME pmmt,
///   UINT     cbmmt
/// );
/// ```
/// {@category winmm}
int waveOutGetPosition(int hwo, Pointer<MMTIME> pmmt, int cbmmt) =>
    _waveOutGetPosition(hwo, pmmt, cbmmt);

final _waveOutGetPosition = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Pointer<MMTIME> pmmt, Uint32 cbmmt),
    int Function(
        int hwo, Pointer<MMTIME> pmmt, int cbmmt)>('waveOutGetPosition');

/// The waveOutGetVolume function retrieves the current volume level of the
/// specified waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutGetVolume(
///   HWAVEOUT hwo,
///   LPDWORD  pdwVolume
/// );
/// ```
/// {@category winmm}
int waveOutGetVolume(int hwo, Pointer<Uint32> pdwVolume) =>
    _waveOutGetVolume(hwo, pdwVolume);

final _waveOutGetVolume = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Pointer<Uint32> pdwVolume),
    int Function(int hwo, Pointer<Uint32> pdwVolume)>('waveOutGetVolume');

/// The waveOutMessage function sends messages to the waveform-audio output
/// device drivers.
///
/// ```c
/// MMRESULT waveOutMessage(
///   HWAVEOUT  hwo,
///   UINT      uMsg,
///   DWORD_PTR dw1,
///   DWORD_PTR dw2
/// );
/// ```
/// {@category winmm}
int waveOutMessage(int hwo, int uMsg, int dw1, int dw2) =>
    _waveOutMessage(hwo, uMsg, dw1, dw2);

final _waveOutMessage = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Uint32 uMsg, IntPtr dw1, IntPtr dw2),
    int Function(int hwo, int uMsg, int dw1, int dw2)>('waveOutMessage');

/// The waveOutOpen function opens the given waveform-audio output device
/// for playback.
///
/// ```c
/// MMRESULT waveOutOpen(
///   LPHWAVEOUT      phwo,
///   UINT            uDeviceID,
///   LPCWAVEFORMATEX pwfx,
///   DWORD_PTR       dwCallback,
///   DWORD_PTR       dwInstance,
///   DWORD           fdwOpen
/// );
/// ```
/// {@category winmm}
int waveOutOpen(Pointer<IntPtr> phwo, int uDeviceID, Pointer<WAVEFORMATEX> pwfx,
        int dwCallback, int dwInstance, int fdwOpen) =>
    _waveOutOpen(phwo, uDeviceID, pwfx, dwCallback, dwInstance, fdwOpen);

final _waveOutOpen = _winmm.lookupFunction<
    Uint32 Function(
        Pointer<IntPtr> phwo,
        Uint32 uDeviceID,
        Pointer<WAVEFORMATEX> pwfx,
        IntPtr dwCallback,
        IntPtr dwInstance,
        Uint32 fdwOpen),
    int Function(
        Pointer<IntPtr> phwo,
        int uDeviceID,
        Pointer<WAVEFORMATEX> pwfx,
        int dwCallback,
        int dwInstance,
        int fdwOpen)>('waveOutOpen');

/// The waveOutPause function pauses playback on the given waveform-audio
/// output device. The current position is saved. Use the waveOutRestart
/// function to resume playback from the current position.
///
/// ```c
/// MMRESULT waveOutPause(
///   HWAVEOUT hwo
/// );
/// ```
/// {@category winmm}
int waveOutPause(int hwo) => _waveOutPause(hwo);

final _waveOutPause =
    _winmm.lookupFunction<Uint32 Function(IntPtr hwo), int Function(int hwo)>(
        'waveOutPause');

/// The waveOutPrepareHeader function prepares a waveform-audio data block
/// for playback.
///
/// ```c
/// MMRESULT waveOutPrepareHeader(
///   HWAVEOUT  hwo,
///   LPWAVEHDR pwh,
///   UINT      cbwh
/// );
/// ```
/// {@category winmm}
int waveOutPrepareHeader(int hwo, Pointer<WAVEHDR> pwh, int cbwh) =>
    _waveOutPrepareHeader(hwo, pwh, cbwh);

final _waveOutPrepareHeader = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Pointer<WAVEHDR> pwh, Uint32 cbwh),
    int Function(
        int hwo, Pointer<WAVEHDR> pwh, int cbwh)>('waveOutPrepareHeader');

/// The waveOutReset function stops playback on the given waveform-audio
/// output device and resets the current position to zero. All pending
/// playback buffers are marked as done (WHDR_DONE) and returned to the
/// application.
///
/// ```c
/// MMRESULT waveOutReset(
///   HWAVEOUT hwo
/// );
/// ```
/// {@category winmm}
int waveOutReset(int hwo) => _waveOutReset(hwo);

final _waveOutReset =
    _winmm.lookupFunction<Uint32 Function(IntPtr hwo), int Function(int hwo)>(
        'waveOutReset');

/// The waveOutRestart function resumes playback on a paused waveform-audio
/// output device.
///
/// ```c
/// MMRESULT waveOutRestart(
///   HWAVEOUT hwo
/// );
/// ```
/// {@category winmm}
int waveOutRestart(int hwo) => _waveOutRestart(hwo);

final _waveOutRestart =
    _winmm.lookupFunction<Uint32 Function(IntPtr hwo), int Function(int hwo)>(
        'waveOutRestart');

/// The waveOutSetPitch function sets the pitch for the specified
/// waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutSetPitch(
///   HWAVEOUT hwo,
///   DWORD    dwPitch
/// );
/// ```
/// {@category winmm}
int waveOutSetPitch(int hwo, int dwPitch) => _waveOutSetPitch(hwo, dwPitch);

final _waveOutSetPitch = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Uint32 dwPitch),
    int Function(int hwo, int dwPitch)>('waveOutSetPitch');

/// The waveOutSetPlaybackRate function sets the playback rate for the
/// specified waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutSetPlaybackRate(
///   HWAVEOUT hwo,
///   DWORD    dwRate
/// );
/// ```
/// {@category winmm}
int waveOutSetPlaybackRate(int hwo, int dwRate) =>
    _waveOutSetPlaybackRate(hwo, dwRate);

final _waveOutSetPlaybackRate = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Uint32 dwRate),
    int Function(int hwo, int dwRate)>('waveOutSetPlaybackRate');

/// The waveOutSetVolume function sets the volume level of the specified
/// waveform-audio output device.
///
/// ```c
/// MMRESULT waveOutSetVolume(
///   HWAVEOUT hwo,
///   DWORD    dwVolume
/// );
/// ```
/// {@category winmm}
int waveOutSetVolume(int hwo, int dwVolume) => _waveOutSetVolume(hwo, dwVolume);

final _waveOutSetVolume = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Uint32 dwVolume),
    int Function(int hwo, int dwVolume)>('waveOutSetVolume');

/// The waveOutUnprepareHeader function cleans up the preparation performed
/// by the waveOutPrepareHeader function. This function must be called after
/// the device driver is finished with a data block. You must call this
/// function before freeing the buffer.
///
/// ```c
/// MMRESULT waveOutUnprepareHeader(
///   HWAVEOUT  hwo,
///   LPWAVEHDR pwh,
///   UINT      cbwh
/// );
/// ```
/// {@category winmm}
int waveOutUnprepareHeader(int hwo, Pointer<WAVEHDR> pwh, int cbwh) =>
    _waveOutUnprepareHeader(hwo, pwh, cbwh);

final _waveOutUnprepareHeader = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Pointer<WAVEHDR> pwh, Uint32 cbwh),
    int Function(
        int hwo, Pointer<WAVEHDR> pwh, int cbwh)>('waveOutUnprepareHeader');

/// The waveOutWrite function sends a data block to the given waveform-audio
/// output device.
///
/// ```c
/// MMRESULT waveOutWrite(
///   HWAVEOUT  hwo,
///   LPWAVEHDR pwh,
///   UINT      cbwh
/// );
/// ```
/// {@category winmm}
int waveOutWrite(int hwo, Pointer<WAVEHDR> pwh, int cbwh) =>
    _waveOutWrite(hwo, pwh, cbwh);

final _waveOutWrite = _winmm.lookupFunction<
    Uint32 Function(IntPtr hwo, Pointer<WAVEHDR> pwh, Uint32 cbwh),
    int Function(int hwo, Pointer<WAVEHDR> pwh, int cbwh)>('waveOutWrite');

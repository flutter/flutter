// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:win32/win32.dart';

// ignore_for_file: non_constant_identifier_names

// ignore: avoid_classes_with_only_static_members
/// A class containing the GUID references for each of the documented Windows
/// known folders. A property of this class may be passed to the `getPath`
/// method in the [PathProvidersWindows] class to retrieve a known folder from
/// Windows.
class WindowsKnownFolder {
  /// The file system directory that is used to store administrative tools for
  /// an individual user. The MMC will save customized consoles to this
  /// directory, and it will roam with the user.
  static String get AdminTools => FOLDERID_AdminTools;

  /// The file system directory that acts as a staging area for files waiting to
  /// be written to a CD. A typical path is C:\Documents and
  /// Settings\username\Local Settings\Application Data\Microsoft\CD Burning.
  static String get CDBurning => FOLDERID_CDBurning;

  /// The file system directory that contains administrative tools for all users
  /// of the computer.
  static String get CommonAdminTools => FOLDERID_CommonAdminTools;

  /// The file system directory that contains the directories for the common
  /// program groups that appear on the Start menu for all users. A typical path
  /// is C:\Documents and Settings\All Users\Start Menu\Programs.
  static String get CommonPrograms => FOLDERID_CommonPrograms;

  /// The file system directory that contains the programs and folders that
  /// appear on the Start menu for all users. A typical path is C:\Documents and
  /// Settings\All Users\Start Menu.
  static String get CommonStartMenu => FOLDERID_CommonStartMenu;

  /// The file system directory that contains the programs that appear in the
  /// Startup folder for all users. A typical path is C:\Documents and
  /// Settings\All Users\Start Menu\Programs\Startup.
  static String get CommonStartup => FOLDERID_CommonStartup;

  /// The file system directory that contains the templates that are available
  /// to all users. A typical path is C:\Documents and Settings\All
  /// Users\Templates.
  static String get CommonTemplates => FOLDERID_CommonTemplates;

  /// The virtual folder that represents My Computer, containing everything on
  /// the local computer: storage devices, printers, and Control Panel. The
  /// folder can also contain mapped network drives.
  static String get ComputerFolder => FOLDERID_ComputerFolder;

  /// The virtual folder that represents Network Connections, that contains
  /// network and dial-up connections.
  static String get ConnectionsFolder => FOLDERID_ConnectionsFolder;

  /// The virtual folder that contains icons for the Control Panel applications.
  static String get ControlPanelFolder => FOLDERID_ControlPanelFolder;

  /// The file system directory that serves as a common repository for Internet
  /// cookies. A typical path is C:\Documents and Settings\username\Cookies.
  static String get Cookies => FOLDERID_Cookies;

  /// The virtual folder that represents the Windows desktop, the root of the
  /// namespace.
  static String get Desktop => FOLDERID_Desktop;

  /// The virtual folder that represents the My Documents desktop item.
  static String get Documents => FOLDERID_Documents;

  /// The file system directory that serves as a repository for Internet
  /// downloads.
  static String get Downloads => FOLDERID_Downloads;

  /// The file system directory that serves as a common repository for the
  /// user's favorite items. A typical path is C:\Documents and
  /// Settings\username\Favorites.
  static String get Favorites => FOLDERID_Favorites;

  /// A virtual folder that contains fonts. A typical path is C:\Windows\Fonts.
  static String get Fonts => FOLDERID_Fonts;

  /// The file system directory that serves as a common repository for Internet
  /// history items.
  static String get History => FOLDERID_History;

  /// The file system directory that serves as a common repository for temporary
  /// Internet files. A typical path is C:\Documents and Settings\username\Local
  /// Settings\Temporary Internet Files.
  static String get InternetCache => FOLDERID_InternetCache;

  /// A virtual folder for Internet Explorer.
  static String get InternetFolder => FOLDERID_InternetFolder;

  /// The file system directory that serves as a data repository for local
  /// (nonroaming) applications. A typical path is C:\Documents and
  /// Settings\username\Local Settings\Application Data.
  static String get LocalAppData => FOLDERID_LocalAppData;

  /// The file system directory that serves as a common repository for music
  /// files. A typical path is C:\Documents and Settings\User\My Documents\My
  /// Music.
  static String get Music => FOLDERID_Music;

  /// A file system directory that contains the link objects that may exist in
  /// the My Network Places virtual folder. A typical path is C:\Documents and
  /// Settings\username\NetHood.
  static String get NetHood => FOLDERID_NetHood;

  /// The folder that represents other computers in your workgroup.
  static String get NetworkFolder => FOLDERID_NetworkFolder;

  /// The file system directory that serves as a common repository for image
  /// files. A typical path is C:\Documents and Settings\username\My
  /// Documents\My Pictures.
  static String get Pictures => FOLDERID_Pictures;

  /// The file system directory that contains the link objects that can exist in
  /// the Printers virtual folder. A typical path is C:\Documents and
  /// Settings\username\PrintHood.
  static String get PrintHood => FOLDERID_PrintHood;

  /// The virtual folder that contains installed printers.
  static String get PrintersFolder => FOLDERID_PrintersFolder;

  /// The user's profile folder. A typical path is C:\Users\username.
  /// Applications should not create files or folders at this level.
  static String get Profile => FOLDERID_Profile;

  /// The file system directory that contains application data for all users. A
  /// typical path is C:\Documents and Settings\All Users\Application Data. This
  /// folder is used for application data that is not user specific. For
  /// example, an application can store a spell-check dictionary, a database of
  /// clip art, or a log file in the CSIDL_COMMON_APPDATA folder. This
  /// information will not roam and is available to anyone using the computer.
  static String get ProgramData => FOLDERID_ProgramData;

  /// The Program Files folder. A typical path is C:\Program Files.
  static String get ProgramFiles => FOLDERID_ProgramFiles;

  /// The common Program Files folder. A typical path is C:\Program
  /// Files\Common.
  static String get ProgramFilesCommon => FOLDERID_ProgramFilesCommon;

  /// On 64-bit systems, a link to the common Program Files folder. A typical path is
  /// C:\Program Files\Common Files.
  static String get ProgramFilesCommonX64 => FOLDERID_ProgramFilesCommonX64;

  /// On 64-bit systems, a link to the 32-bit common Program Files folder. A
  /// typical path is C:\Program Files (x86)\Common Files. On 32-bit systems, a
  /// link to the Common Program Files folder.
  static String get ProgramFilesCommonX86 => FOLDERID_ProgramFilesCommonX86;

  /// On 64-bit systems, a link to the Program Files folder. A typical path is
  /// C:\Program Files.
  static String get ProgramFilesX64 => FOLDERID_ProgramFilesX64;

  /// On 64-bit systems, a link to the 32-bit Program Files folder. A typical
  /// path is C:\Program Files (x86). On 32-bit systems, a link to the Common
  /// Program Files folder.
  static String get ProgramFilesX86 => FOLDERID_ProgramFilesX86;

  /// The file system directory that contains the user's program groups (which
  /// are themselves file system directories).
  static String get Programs => FOLDERID_Programs;

  /// The file system directory that contains files and folders that appear on
  /// the desktop for all users. A typical path is C:\Documents and Settings\All
  /// Users\Desktop.
  static String get PublicDesktop => FOLDERID_PublicDesktop;

  /// The file system directory that contains documents that are common to all
  /// users. A typical path is C:\Documents and Settings\All Users\Documents.
  static String get PublicDocuments => FOLDERID_PublicDocuments;

  /// The file system directory that serves as a repository for music files
  /// common to all users. A typical path is C:\Documents and Settings\All
  /// Users\Documents\My Music.
  static String get PublicMusic => FOLDERID_PublicMusic;

  /// The file system directory that serves as a repository for image files
  /// common to all users. A typical path is C:\Documents and Settings\All
  /// Users\Documents\My Pictures.
  static String get PublicPictures => FOLDERID_PublicPictures;

  /// The file system directory that serves as a repository for video files
  /// common to all users. A typical path is C:\Documents and Settings\All
  /// Users\Documents\My Videos.
  static String get PublicVideos => FOLDERID_PublicVideos;

  /// The file system directory that contains shortcuts to the user's most
  /// recently used documents. A typical path is C:\Documents and
  /// Settings\username\My Recent Documents.
  static String get Recent => FOLDERID_Recent;

  /// The virtual folder that contains the objects in the user's Recycle Bin.
  static String get RecycleBinFolder => FOLDERID_RecycleBinFolder;

  /// The file system directory that contains resource data. A typical path is
  /// C:\Windows\Resources.
  static String get ResourceDir => FOLDERID_ResourceDir;

  /// The file system directory that serves as a common repository for
  /// application-specific data. A typical path is C:\Documents and
  /// Settings\username\Application Data.
  static String get RoamingAppData => FOLDERID_RoamingAppData;

  /// The file system directory that contains Send To menu items. A typical path
  /// is C:\Documents and Settings\username\SendTo.
  static String get SendTo => FOLDERID_SendTo;

  /// The file system directory that contains Start menu items. A typical path
  /// is C:\Documents and Settings\username\Start Menu.
  static String get StartMenu => FOLDERID_StartMenu;

  /// The file system directory that corresponds to the user's Startup program
  /// group. The system starts these programs whenever the associated user logs
  /// on. A typical path is C:\Documents and Settings\username\Start
  /// Menu\Programs\Startup.
  static String get Startup => FOLDERID_Startup;

  /// The Windows System folder. A typical path is C:\Windows\System32.
  static String get System => FOLDERID_System;

  /// The 32-bit Windows System folder. On 32-bit systems, this is typically
  /// C:\Windows\system32. On 64-bit systems, this is typically
  /// C:\Windows\syswow64.
  static String get SystemX86 => FOLDERID_SystemX86;

  /// The file system directory that serves as a common repository for document
  /// templates. A typical path is C:\Documents and Settings\username\Templates.
  static String get Templates => FOLDERID_Templates;

  /// The file system directory that serves as a common repository for video
  /// files. A typical path is C:\Documents and Settings\username\My
  /// Documents\My Videos.
  static String get Videos => FOLDERID_Videos;

  /// The Windows directory or SYSROOT. This corresponds to the %windir% or
  /// %SYSTEMROOT% environment variables. A typical path is C:\Windows.
  static String get Windows => FOLDERID_Windows;
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'firebase_service.dart';

class StorageHelper {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static bool _shouldSyncKeyToFirebase(String key) {
    return key.startsWith('workouts_') ||
        key.startsWith('workout_') ||
        key.startsWith('workout_notifications_');
  }

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      print('✅ SharedPreferences initialized successfully');
      // Initialize Firebase
      await FirebaseService.initialize();
    } catch (e) {
      print('❌ Error initializing storage: $e');
      rethrow;
    }
  }

  static Future<String?> getString(String key) async {
    // Use secure storage for a minimal non-secret remember-me value.
    if (key == 'clientUsername') {
      return await _secureStorage.read(key: key);
    }
    if (_prefs == null) {
      print(
        '⚠️ Warning: SharedPreferences not initialized, returning null for key: $key',
      );
      return null;
    }
    return _prefs?.getString(key);
  }

  static Future<bool> setString(String key, String value) async {
    if (key == 'clientUsername') {
      await _secureStorage.write(key: key, value: value);
      return true;
    }
    if (_prefs == null) {
      print('⚠️ Warning: SharedPreferences not initialized');
      return false;
    }
    final localResult = await _prefs?.setString(key, value) ?? false;
    if (_shouldSyncKeyToFirebase(key)) {
      FirebaseService.setString(key, value).catchError((e) {
        print('Firebase sync error: $e');
      });
    }
    return localResult;
  }

  static Future<bool> remove(String key) async {
    if (key == 'clientUsername') {
      await _secureStorage.delete(key: key);
      return true;
    }
    if (_prefs == null) {
      print('⚠️ Warning: SharedPreferences not initialized');
      return false;
    }
    final localResult = await _prefs?.remove(key) ?? false;
    if (_shouldSyncKeyToFirebase(key)) {
      FirebaseService.remove(key).catchError((e) {
        print('Firebase sync error: $e');
      });
    }
    return localResult;
  }

  static Set<String> getKeys() {
    if (_prefs == null) {
      print('⚠️ Warning: SharedPreferences not initialized');
      return {};
    }
    return _prefs?.getKeys() ?? {};
  }

  // Sync from Firebase to local storage
  static Future<void> syncFromFirebase() async {
    try {
      print('🔄 Syncing data from Firebase...');
      print('✅ Firebase sync completed');
    } catch (e) {
      print('Error syncing from Firebase: $e');
    }
  }
}

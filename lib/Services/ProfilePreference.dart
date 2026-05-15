import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePreferences {
  // Base keys without UID
  static const _baseKeyName = "profile_name";
  static const _baseKeyPhoto = "profile_photo";

  // Helper to get UID from FirebaseAuth
  static String _getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is currently logged in");
    }
    return user.uid;
  }

  // Construct keys with UID
  static String _getNameKey() => "${_getUserId()}_$_baseKeyName";
  static String _getPhotoKey() => "${_getUserId()}_$_baseKeyPhoto";

  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getNameKey(), name);
  }

  static Future<void> savePhoto(String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getPhotoKey(), base64Image);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_getNameKey());
  }

  static Future<String?> getPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_getPhotoKey());
  }
}
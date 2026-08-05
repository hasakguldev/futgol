import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const String _keyProfile = 'user_profile_json';

  static const List<String> defaultEmojis = [
    '⚽', '🏆', '🏅', '👑', '🦁', '🦅', '🦈', '🐉', '🔥', '⚡',
    '🧤', '🎽', '👟', '👕', '📢', '🧣', '🏟️', '🎯', '🚀', '😎',
    '🧠', '🧙‍♂️', '🦸‍♂️', '🥋', '🦊', '🐼', '🐨', '🐯', '🤖', '⭐',
    '💎', '🍕', '🍔', '🎮', '🎲', '🧩', '🎸', '🎷', '🐱', '🐶'
  ];

  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyProfile);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile != null;
  }
}

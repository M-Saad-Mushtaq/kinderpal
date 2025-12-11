import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  List<ChildProfile> _profiles = [];
  ChildProfile? _selectedProfile;
  bool _isLoading = false;
  String? _errorMessage;

  List<ChildProfile> get profiles => _profiles;
  ChildProfile? get selectedProfile => _selectedProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfiles => _profiles.isNotEmpty;

  Future<void> loadProfiles() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _profiles = await _profileService.getChildProfiles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createProfile({
    required String name,
    required int age,
    DateTime? birthdate,
    List<String> preferences = const [],
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final newProfile = await _profileService.createChildProfile(
        name: name,
        age: age,
        birthdate: birthdate,
        preferences: preferences,
      );

      _profiles.add(newProfile);
      // Automatically select the newly created profile
      _selectedProfile = newProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String profileId,
    String? name,
    int? age,
    DateTime? birthdate,
    List<String>? preferences,
    List<String>? customRules,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedProfile = await _profileService.updateChildProfile(
        profileId: profileId,
        name: name,
        age: age,
        birthdate: birthdate,
        preferences: preferences,
        customRules: customRules,
      );

      final index = _profiles.indexWhere((p) => p.id == profileId);
      if (index != -1) {
        _profiles[index] = updatedProfile;
        if (_selectedProfile?.id == profileId) {
          _selectedProfile = updatedProfile;
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProfile(String profileId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _profileService.deleteChildProfile(profileId);
      _profiles.removeWhere((p) => p.id == profileId);

      if (_selectedProfile?.id == profileId) {
        _selectedProfile = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void selectProfile(ChildProfile profile) {
    _selectedProfile = profile;
    notifyListeners();
  }

  void clearSelectedProfile() {
    _selectedProfile = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

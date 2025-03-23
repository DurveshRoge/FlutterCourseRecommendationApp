import 'package:flutter/foundation.dart';
import 'package:study_notion/models/user.dart';
import 'package:study_notion/services/api_service.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  final ApiService _apiService;

  UserProvider(this._apiService) {
    _loadCurrentUser();
  }

  User? get currentUser => _currentUser;

  // Initialize current user from API service
  Future<void> _loadCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        print('UserProvider: Loaded current user - ${user.name}');
      }
    } catch (e) {
      print('UserProvider: Error loading current user - $e');
    }
  }

  // Update the current user
  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
    print('UserProvider: User updated - ${user?.name ?? 'null'}');
  }

  // Clear current user (on logout)
  void clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
    print('UserProvider: User cleared');
  }
} 
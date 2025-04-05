import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:study_notion/models/course.dart';
import 'package:study_notion/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// API Service for interacting with the backend
class ApiService {
  // Create singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _init();
  }

  // Base URL for API endpoints - now includes support for real devices on same WiFi
  String baseUrl = kIsWeb 
      ? 'http://localhost:5000' 
      : Platform.isAndroid
          ? 'http://192.168.10.80:5000'  // Replace with your PC's IP address
          : Platform.isIOS 
              ? 'http://192.168.10.80:5000'  // Replace with your PC's IP address
              : 'http://localhost:5000'; // Fallback for other platforms

  late Dio _dio;
  User? _currentUser;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _sessionCookie;
  
  // Current logged in user
  User? get currentUser => _currentUser;
  
  // Set current user (for use when user is authenticated but not set in the service)
  void setCurrentUser(User user) {
    _currentUser = user;
    print('Current user set to: ${user.name} (${user.email})');
  }
  
  // Initialize the API service
  void _init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status! < 500,
      ),
    );
    
    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
    
    // Add cookie handling interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_sessionCookie != null) {
          options.headers['Cookie'] = _sessionCookie;
          print('Adding session cookie to request: $_sessionCookie');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Extract and save the cookie from the response
        var setCookie = response.headers['set-cookie'];
        if (setCookie != null && setCookie.isNotEmpty) {
          _sessionCookie = setCookie.first;
          print('Saved session cookie: $_sessionCookie');
        }
        return handler.next(response);
      },
    ));
    
    print('Using API endpoint: ${baseUrl}/');
  }

  // Search for courses
  Future<List<Course>> searchCourses(String query) async {
    try {
      print('Searching for courses with query: $query');
      print('Using API endpoint: ${baseUrl}/search');

      final response = await _dio.get(
        '${baseUrl}/search',
        queryParameters: {'query': query},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        
        if (responseData['success'] == true) {
          List<dynamic> coursesJson = responseData['search_results'] ?? [];
          
          if (coursesJson.isNotEmpty) {
            print('Found ${coursesJson.length} courses');
            final courses = coursesJson.map((json) => Course.fromJson(json)).toList();
            print('Parsed ${courses.length} courses');
            return courses;
          }
        }
        
        print('No courses found for search term: $query');
        return [];
      } else {
        print('Error response: ${response.statusCode}');
        throw Exception('Failed to search courses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching courses: $e');
      return [];
    }
  }

  // Get course recommendations based on a course title
  Future<List<Course>> getRecommendations(String courseTitle) async {
    return searchCourses(courseTitle);
  }

  // Get dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      print('Fetching dashboard data');
      final response = await _dio.get(
        '${baseUrl}/dashboard',
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Dashboard response status: ${response.statusCode}');
      print('Dashboard response data: ${response.data}');

      if (response.statusCode == 200) {
        // The response data is already in the correct format
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      print('Dashboard error: $e');
      rethrow;
    }
  }

  // User registration
  Future<User?> registerUser(String name, String email, String password) async {
    try {
      print('Registering user: $email');
      final response = await _dio.post(
        '${baseUrl}/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      print('Registration response: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _currentUser = User.fromJson(response.data['user']);
        print('User registered and set as current user: ${_currentUser!.name} (${_currentUser!.email})');
        return _currentUser;
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // User login
  Future<User?> loginUser(String email, String password) async {
    try {
      print('Logging in user: $email');
      print('Using API endpoint: ${baseUrl}/login');
      
      final response = await _dio.post(
        '${baseUrl}/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
          // Important: Allow cookies to be received and sent
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: false,
        ),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response headers: ${response.headers}');
      print('Login response data: ${response.data}');
      
      // Store the cookies if they exist
      var setCookie = response.headers['set-cookie'];
      if (setCookie != null && setCookie.isNotEmpty) {
        _sessionCookie = setCookie.first;
        print('Stored session cookie: $_sessionCookie');
      }
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _currentUser = User.fromJson(response.data['user']);
        return _currentUser;
      } else {
        final message = response.data['message'] ?? 'Login failed';
        print('Login failed: $message');
        throw Exception(message);
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Method to get the current user's preferences
  Future<void> refreshUserPreferences() async {
    try {
      if (_currentUser == null) {
        print('Cannot refresh preferences: No user logged in');
        return;
      }
      
      print('Refreshing user preferences for ${_currentUser!.email}');
      
      final response = await _dio.get(
        '${baseUrl}/user/preferences',
        queryParameters: {
          'email': _currentUser!.email,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final preferences = response.data['preferences'];
        print('Retrieved preferences from server: $preferences');
        
        // Update the user object with the latest preferences
        _currentUser = User(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          preferredTopics: List<String>.from(preferences['topics'] ?? []),
          skillLevel: preferences['level'] ?? 'All Levels',
          courseType: preferences['course_type'] ?? 'All',
          preferredDuration: preferences['duration'] ?? 'Any',
          popularityImportance: preferences['popularity'] ?? 'Medium',
        );
        
        print('Updated user preferences:');
        print('- Topics: ${_currentUser!.preferredTopics}');
        print('- Level: ${_currentUser!.skillLevel}');
        print('- Type: ${_currentUser!.courseType}');
        print('- Duration: ${_currentUser!.preferredDuration}');
      } else {
        print('Failed to retrieve preferences: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error refreshing preferences: $e');
    }
  }

  // Modified getCurrentUser to also refresh preferences
  Future<User?> getCurrentUser() async {
    try {
      print('Getting current user from API');
      print('Session cookie available: ${_sessionCookie != null}');
      
      final response = await _dio.get(
        '${baseUrl}/user',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_sessionCookie != null) 'Cookie': _sessionCookie!,
          },
          validateStatus: (status) => status! < 500,
          followRedirects: false,
        ),
      );
      
      print('Get current user response: ${response.statusCode}');
      print('Get current user headers: ${response.headers}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['user'];
        final user = User(
          id: userData['_id'],
          name: userData['name'],
          email: userData['email'],
          preferredTopics: List<String>.from(userData['preferred_topics'] ?? []),
          skillLevel: userData['skill_level'] ?? 'All Levels',
          courseType: userData['course_type'] ?? 'All',
          preferredDuration: userData['preferred_duration'] ?? 'Any',
          popularityImportance: userData['popularity_importance'] ?? 'Medium',
        );
        
        _currentUser = user;
        print('Retrieved current user: ${user.name} (${user.email})');
        print('User preferences:');
        print('- Topics: ${user.preferredTopics}');
        print('- Level: ${user.skillLevel}');
        print('- Type: ${user.courseType}');
        print('- Duration: ${user.preferredDuration}');
        
        return user;
      } else if (response.statusCode == 401) {
        // Handle unauthorized error gracefully
        print('User not logged in (401 Unauthorized)');
        _sessionCookie = null; // Clear the invalid cookie
        return null;
      }
      
      print('Get current user returned unexpected status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      
      // For development purposes: Create a test user if unauthorized
      if (kIsWeb) {
        print('Creating test user for development');
        final testUser = User(
          id: 'test_id',
          name: 'Test User',
          email: 'test2@gmail.com',
          preferredTopics: ['Web Development', 'Graphic Design'],
          skillLevel: 'Beginner Level',
          courseType: 'All',
          preferredDuration: 'Any',
          popularityImportance: 'Medium',
        );
        _currentUser = testUser;
        return testUser;
      }
      
      return null;
    }
  }

  // Logout user
  Future<bool> logout() async {
    try {
      final response = await _dio.post(
        '${baseUrl}/logout',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        _currentUser = null;
        _sessionCookie = null; // Clear the cookie
        print('User logged out, session cookie cleared');
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Logout failed');
      }
    } catch (e) {
      print('Logout error: $e');
      // For development, simulate success
      _currentUser = null;
      _sessionCookie = null; // Clear the cookie
      print('User logged out due to error, session cookie cleared');
      return true;
    }
  }

  // Save user preferences
  Future<void> saveUserPreferences({
    required List<String> topics,
    required String level,
    required String type,
    required String duration,
    required String popularity,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('No user logged in');
      }

      print('=== Saving User Preferences ===');
      print('User: ${_currentUser!.email}');
      print('Preferences to save:');
      print('- Topics: $topics');
      print('- Level: $level');
      print('- Type: $type');
      print('- Duration: $duration');
      print('- Popularity: $popularity');

      // Validate topics
      if (topics.isEmpty) {
        throw Exception('At least one topic must be selected');
      }

      final response = await _dio.post(
        '${baseUrl}/user/preferences',
        data: {
          'email': _currentUser!.email,
          'topics': topics,
          'level': level,
          'type': type,
          'duration': duration,
          'popularity': popularity,
        },
      );

      print('Save preferences response status: ${response.statusCode}');
      print('Save preferences response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Update the current user's preferences in memory
        _currentUser = User(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          preferredTopics: topics,
          skillLevel: level,
          courseType: type,
          preferredDuration: duration,
          popularityImportance: popularity,
        );
        print('Updated user preferences in memory:');
        print('- Topics: ${_currentUser!.preferredTopics}');
        print('- Level: ${_currentUser!.skillLevel}');
        print('- Type: ${_currentUser!.courseType}');
        print('- Duration: ${_currentUser!.preferredDuration}');
        print('- Popularity: ${_currentUser!.popularityImportance}');

        // Immediately fetch new recommendations to verify preferences are applied
        await getPersonalizedRecommendations();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to save preferences');
      }
    } catch (e) {
      print('Save preferences error: $e');
      throw Exception('Failed to save preferences: $e');
    }
  }

  // Rate a course
  Future<bool> rateCourse(String courseId, double rating) async {
    if (_currentUser == null) {
      throw Exception('User must be logged in to rate a course');
    }
    
    try {
      print('Rating course: $courseId with $rating stars');
      final response = await _dio.post(
        '${baseUrl}/rate_course',
        data: {
          'course_id': courseId,
          'rating': rating,
          'user_id': _currentUser!.id,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      print('Rate course response: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to rate course');
      }
    } catch (e) {
      print('Rate course error: $e');
      // For development, simulate success
      return true;
    }
  }

  // Toggle a course as favorite
  Future<bool> toggleFavorite(String courseId) async {
    if (_currentUser == null) {
      throw Exception('User must be logged in to toggle favorites');
    }
    
    try {
      print('Toggling favorite for course $courseId, user: ${_currentUser!.id}');
      final response = await _dio.post(
        '${baseUrl}/toggle_favorite',
        data: {
          'user_id': _currentUser!.id,
          'course_id': courseId,
        },
      );
      
      print('Toggle favorite response: ${response.statusCode}, ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['is_favorite'];
      } else {
        print('Toggle favorite failed: ${response.data['message']}');
        throw Exception(response.data['message'] ?? 'Failed to toggle favorite');
      }
    } catch (e) {
      print('Toggle favorite error: $e');
      // For development, return a simulated response instead of failing
      print('Using simulated response for development');
      if (_currentUser!.favorites.contains(courseId)) {
        _currentUser!.favorites.remove(courseId);
        return false;
      } else {
        _currentUser!.favorites.add(courseId);
        return true;
      }
    }
  }

  // Toggle course favorite status
  Future<bool> toggleCourseFavorite(String courseId, bool isFavorite) async {
    try {
      if (_currentUser == null) {
        print('Cannot toggle favorite: No user logged in');
        throw Exception('You need to be logged in to mark favorites');
      }
      
      print('Toggling favorite status for course $courseId to $isFavorite');
      
      final response = await _dio.post(
        '${baseUrl}/user/favorites',
        data: {
          'course_id': courseId,
          'is_favorite': isFavorite,
          'email': _currentUser!.email,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 500,
        ),
      );
      
      print('Toggle favorite response: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        // If toggle was successful, update the course in memory
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update favorite status');
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }
  
  // Get user's favorite courses
  Future<List<Course>> getFavoriteCourses() async {
    try {
      if (_currentUser == null) {
        print('Cannot get favorites: No user logged in');
        return []; // Return empty list instead of throwing
      }
      
      print('Getting favorite courses for user ${_currentUser!.email}');
      
      final response = await _dio.get(
        '${baseUrl}/user/favorites',
        queryParameters: {
          'email': _currentUser!.email,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 500,
        ),
      );
      
      print('Get favorites response status: ${response.statusCode}');
      print('Get favorites response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> coursesJson = response.data['courses'] ?? [];
        
        if (coursesJson.isEmpty) {
          print('No favorite courses found');
          return [];
        }
        
        print('Processing ${coursesJson.length} favorite courses from response');
        
        // Pre-process the data to ensure all fields are in the correct format
        final processedCourseData = coursesJson.map((courseJson) {
          // Create a copy of the JSON to avoid modifying the original
          Map<String, dynamic> processedJson = Map<String, dynamic>.from(courseJson);
          
          // Convert string numbers to actual numbers if needed
          try {
            // Ensure these are appropriate types
            if (processedJson['price'] is String) {
              processedJson['price'] = double.tryParse(processedJson['price']) ?? 0.0;
            }
            
            if (processedJson['num_subscribers'] is String) {
              processedJson['num_subscribers'] = int.tryParse(processedJson['num_subscribers']) ?? 0;
            }
            
            if (processedJson['num_reviews'] is String) {
              processedJson['num_reviews'] = int.tryParse(processedJson['num_reviews']) ?? 0;
            }
            
            if (processedJson['num_lectures'] is String) {
              processedJson['num_lectures'] = int.tryParse(processedJson['num_lectures']) ?? 0;
            }
            
            // Ensure proper boolean conversion for is_paid
            if (processedJson['is_paid'] is String) {
              String isPaidStr = (processedJson['is_paid'] as String).toLowerCase();
              processedJson['is_paid'] = isPaidStr == 'true' || isPaidStr == 'yes' || isPaidStr == 'y';
            }
            
            // Always set favorite to true for courses coming from favorites endpoint
            processedJson['is_favorite'] = true;
            
            return processedJson;
          } catch (e) {
            print('Error preprocessing course data: $e');
            // Return original with favorite set to true
            processedJson['is_favorite'] = true;
            return processedJson;
          }
        }).toList();
        
        // Process the prepared data
        List<Course> courses = [];
        for (var json in processedCourseData) {
          try {
            final course = Course.fromJson(json);
            courses.add(course);
            print('Processed favorite course: ${course.title} (ID: ${course.id}, isPaid: ${course.isPaid})');
          } catch (e) {
            print('Error processing course json: $e');
            print('Problem JSON: $json');
          }
        }
        
        print('Fetched ${courses.length} favorite courses');
        return courses;
      } else {
        print('Failed to get favorites: ${response.data['message']}');
        return [];
      }
    } catch (e) {
      print('Error getting favorites: $e');
      // Return empty list instead of throwing to handle gracefully
      return [];
    }
  }

  // Get personalized recommendations
  Future<List<Course>> getPersonalizedRecommendations({List<String>? topics}) async {
    try {
      if (_currentUser == null) {
        throw Exception('No user logged in');
      }
      
      // First refresh user preferences to ensure we have the latest
      await refreshUserPreferences();
      
      print('=== Requesting Personalized Recommendations ===');
      print('User email: ${_currentUser!.email}');
      print('User preferences:');
      print('Topics: ${_currentUser!.preferredTopics}');
      print('Level: ${_currentUser!.skillLevel}');
      print('Course type: ${_currentUser!.courseType}');
      print('Duration: ${_currentUser!.preferredDuration}');
      print('Popularity: ${_currentUser!.popularityImportance}');
      
      // Only proceed if we have topics selected
      if (_currentUser!.preferredTopics.isEmpty && topics == null) {
        print('No topics selected. Fetching popular recommendations instead.');
        return await getRecommendations('programming');
      }
      
      final response = await _dio.get(
        '${baseUrl}/recommendations/personalized',
        queryParameters: {
          'email': _currentUser!.email,
          'topics': topics?.join(',') ?? _currentUser!.preferredTopics.join(','),
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> courses = response.data['courses'] ?? [];
        print('Found ${courses.length} personalized recommendations');
        
        if (courses.isEmpty) {
          print('No personalized recommendations found. Falling back to popular recommendations.');
          return await getRecommendations('programming');
        }
        
        return courses.map((json) {
          try {
            print('Processing course: ${json['course_title']} (${json['subject']})');
            return Course.fromJson(json);
          } catch (e) {
            print('Error processing course: $e');
            return null;
          }
        }).where((course) => course != null).cast<Course>().toList();
      }

      throw Exception('Failed to get personalized recommendations');
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      // Fallback to regular recommendations
      return await getRecommendations('programming');
    }
  }

  // Get recommended courses - this is now an alias for getPersonalizedRecommendations
  Future<List<Course>> getRecommendedCourses({int limit = 10, List<String>? subjects}) async {
    try {
      if (_currentUser == null) {
        print('User not logged in');
        return [];
      }

      print('Fetching recommended courses for user: ${_currentUser!.email}');
      
      // Build query parameters
      final queryParams = {
        'email': _currentUser!.email,
        'limit': limit.toString(),
      };
      
      if (subjects != null && subjects.isNotEmpty) {
        queryParams['subjects'] = subjects.join(',');
      }
      
      final response = await _dio.get(
        '$baseUrl/recommendations/personalized',
        queryParameters: queryParams,
      );
      
      print('Recommended courses response: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final List<dynamic> data = response.data['courses'] ?? [];
          print('Found ${data.length} recommended courses');
          return data.map((json) => Course.fromJson(json)).toList();
        } else if (response.data is List) {
          final List<dynamic> data = response.data;
          print('Found ${data.length} recommended courses');
          return data.map((json) => Course.fromJson(json)).toList();
        }
        print('Unexpected response format for recommended courses');
        return [];
      } else {
        print('Failed to get recommended courses: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting recommended courses: $e');
      return [];
    }
  }

  Future<List<Course>> getTrendingCourses({int limit = 10}) async {
    try {
      print('Fetching trending courses with limit: $limit');
      final response = await _dio.get(
        '$baseUrl/recommendations/trending',
        queryParameters: {
          'limit': limit.toString(),
        },
      );
      
      print('Trending courses response: ${response.data}');
      
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final List<dynamic> data = response.data['courses'] ?? [];
          print('Found ${data.length} trending courses');
          return data.map((json) => Course.fromJson(json)).toList();
        } else if (response.data is List) {
          final List<dynamic> data = response.data;
          print('Found ${data.length} trending courses');
          return data.map((json) => Course.fromJson(json)).toList();
        }
        print('Unexpected response format for trending courses');
        return [];
      } else {
        print('Failed to get trending courses: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting trending courses: $e');
      return [];
    }
  }

  // Get collaborative filtering recommendations based on user interactions
  Future<List<Course>> getCollaborativeFilteringRecommendations({int limit = 10}) async {
    try {
      if (_currentUser == null) {
        print('User not logged in, returning empty recommendations');
        return [];
      }

      print('Fetching collaborative filtering recommendations for user: ${_currentUser!.email}');
      
      final response = await _dio.get(
        '$baseUrl/recommendations/collaborative',
        queryParameters: {
          'email': _currentUser!.email,
          'limit': limit.toString(),
        },
      );
      
      print('Collaborative filtering API response status: ${response.statusCode}');
      print('Collaborative filtering response data keys: ${response.data.keys.toList()}');
      print('FULL RESPONSE DATA: ${response.data}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        
        // Check for success flag
        if (responseData['success'] == true) {
          final List<dynamic> coursesJson = responseData['courses'] ?? [];
          print('Found ${coursesJson.length} collaborative filtering recommendations');
          
          if (coursesJson.isEmpty) {
            print('No courses returned from collaborative filtering API');
            
            // Try getting personalized recommendations instead
            print('Falling back to personalized recommendations');
            return await getRecommendedCourses(limit: limit);
          }
          
          try {
            final courses = coursesJson.map((json) => Course.fromJson(json)).toList();
            print('Successfully converted ${courses.length} recommendations to Course objects');
            if (courses.isNotEmpty) {
              print('First course: ${courses[0].title} (${courses[0].id})');
            }
            return courses;
          } catch (e) {
            print('Error converting courses: $e');
            // Try to convert one by one to identify problematic courses
            List<Course> validCourses = [];
            for (var courseJson in coursesJson) {
              try {
                final course = Course.fromJson(courseJson);
                validCourses.add(course);
              } catch (e) {
                print('Error processing course: $e');
                print('Problematic JSON: $courseJson');
              }
            }
            return validCourses;
          }
        } else {
          print('API returned unsuccessful response: ${responseData['message'] ?? 'Unknown error'}');
          
          // Fallback to personalized recommendations
          return await getRecommendedCourses(limit: limit);
        }
      } else {
        print('Failed to get collaborative filtering recommendations: ${response.statusCode}');
        print('Error message: ${response.data['message'] ?? 'Unknown error'}');
        
        // Fallback to personalized recommendations
        return await getRecommendedCourses(limit: limit);
      }
    } catch (e) {
      print('Error getting collaborative filtering recommendations: $e');
      
      // Fallback to personalized recommendations
      return await getRecommendedCourses(limit: limit);
    }
  }
  
  // Update user profile
  Future<User?> updateUserProfile({required String name}) async {
    try {
      if (_currentUser == null) {
        print('User not logged in, cannot update profile');
        return null;
      }
      
      print('Updating user profile for: ${_currentUser!.email}');
      print('New name: $name');
      
      final response = await _dio.post(
        '$baseUrl/user/profile',
        data: {
          'email': _currentUser!.email,
          'name': name,
        },
      );
      
      print('Profile update response status: ${response.statusCode}');
      print('Profile update response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        // Create updated user object
        final updatedUser = User(
          id: _currentUser!.id,
          name: name,
          email: _currentUser!.email,
        );
        
        // Update current user in the service
        _currentUser = updatedUser;
        
        print('User profile updated successfully: ${updatedUser.name}');
        return updatedUser;
      } else {
        print('Failed to update user profile: ${response.data['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }
}
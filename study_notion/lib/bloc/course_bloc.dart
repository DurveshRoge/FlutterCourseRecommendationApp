import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_notion/models/course.dart';
import 'package:study_notion/services/api_service.dart';
import 'dart:math' show min;

enum CourseType { trending, personalized, favorites, search, collaborative }

// Events
abstract class CourseEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SearchCourses extends CourseEvent {
  final String query;

  SearchCourses(this.query);

  @override
  List<Object> get props => [query];
}

class LoadDashboard extends CourseEvent {}

class UserLoggedOut extends CourseEvent {}

class RateCourse extends CourseEvent {
  final String courseId;
  final double rating;

  RateCourse(this.courseId, this.rating);

  @override
  List<Object> get props => [courseId, rating];
}

class ToggleFavorite extends CourseEvent {
  final String courseId;

  ToggleFavorite(this.courseId);

  @override
  List<Object> get props => [courseId];
}

class LoadFavorites extends CourseEvent {}

class LoadCollaborativeRecommendations extends CourseEvent {
  final String email;

  LoadCollaborativeRecommendations({required this.email});

  @override
  List<Object> get props => [email];
}

class LoadTrendingCourses extends CourseEvent {}

class LoadPersonalizedRecommendations extends CourseEvent {}

class LoadPersonalizedCourses extends CourseEvent {}

class LoadFavoriteCourses extends CourseEvent {}

// Add a new event for collaborative filtering
class LoadCollaborativeFilteringRecommendations extends CourseEvent {}

// States
abstract class CourseState extends Equatable {
  @override
  List<Object> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseLoaded extends CourseState {
  final List<Course> courses;
  final CourseType type;

  CourseLoaded(this.courses, this.type);

  @override
  List<Object> get props => [courses, type];
}

class DashboardLoaded extends CourseState {
  final Map<String, dynamic> dashboardData;

  DashboardLoaded(this.dashboardData);

  @override
  List<Object> get props => [dashboardData];
}

class CourseError extends CourseState {
  final String message;

  CourseError(this.message);

  @override
  List<Object> get props => [message];
}

class CourseRated extends CourseState {
  final String courseId;
  final double rating;

  CourseRated(this.courseId, this.rating);

  @override
  List<Object> get props => [courseId, rating];
}

class CourseFavoriteToggled extends CourseState {
  final String courseId;
  final bool isFavorite;

  CourseFavoriteToggled(this.courseId, this.isFavorite);

  @override
  List<Object> get props => [courseId, isFavorite];
}

class TrendingCoursesLoading extends CourseState {}

class TrendingCoursesError extends CourseState {
  final String message;

  TrendingCoursesError(this.message);

  @override
  List<Object> get props => [message];
}

class TrendingCoursesLoaded extends CourseState {
  final List<Course> courses;

  TrendingCoursesLoaded(this.courses);

  @override
  List<Object> get props => [courses];
}

class PersonalizedCoursesLoading extends CourseState {}

class PersonalizedCoursesError extends CourseState {
  final String message;

  PersonalizedCoursesError(this.message);

  @override
  List<Object> get props => [message];
}

class PersonalizedCoursesLoaded extends CourseState {
  final List<Course> courses;

  PersonalizedCoursesLoaded(this.courses);

  @override
  List<Object> get props => [courses];
}

class FavoriteCoursesLoading extends CourseState {}

class FavoriteCoursesError extends CourseState {
  final String message;

  FavoriteCoursesError(this.message);

  @override
  List<Object> get props => [message];
}

class FavoriteCoursesLoaded extends CourseState {
  final List<Course> courses;

  FavoriteCoursesLoaded(this.courses);

  @override
  List<Object> get props => [courses];
}

// Add new states for collaborative filtering
class CollaborativeRecommendationsLoading extends CourseState {}

class CollaborativeRecommendationsError extends CourseState {
  final String message;

  CollaborativeRecommendationsError(this.message);

  @override
  List<Object> get props => [message];
}

class CollaborativeRecommendationsLoaded extends CourseState {
  final List<Course> recommendations;

  CollaborativeRecommendationsLoaded(this.recommendations);

  @override
  List<Object> get props => [recommendations];
  
  // Add a helper method to get course info for debugging
  String get courseInfo {
    if (recommendations.isEmpty) return "No recommendations";
    return recommendations.map((c) => "${c.title} (${c.id})").join(", ");
  }
}

// BLoC
class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final ApiService _apiService;
  List<Course> _lastLoadedCourses = [];
  Map<String, dynamic>? _lastDashboardData;
  Map<String, List<Course>> _courseCache = {};
  
  // For throttling API calls
  static DateTime _lastFavoriteLoad = DateTime.fromMillisecondsSinceEpoch(0);
  
  // Add a class property to track UI state
  bool _isCollaborativeRecommendationsLoading = false;
  
  CourseBloc(this._apiService) : super(CourseInitial()) {
    on<LoadTrendingCourses>(_onLoadTrendingCourses);
    on<LoadCollaborativeRecommendations>(_onLoadCollaborativeRecommendations);
    on<LoadCollaborativeFilteringRecommendations>(_onLoadCollaborativeFilteringRecommendations);
    on<LoadPersonalizedRecommendations>(_onLoadPersonalizedRecommendations);
    on<LoadFavorites>(_onLoadFavorites);
    on<SearchCourses>(_onSearchCourses);
    on<RateCourse>(_onRateCourse);
    on<ToggleFavorite>(_onToggleFavorite);
    on<UserLoggedOut>(_onUserLoggedOut);
    on<LoadDashboard>(_onLoadDashboard);
  }

  Future<void> _onSearchCourses(
    SearchCourses event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(CourseLoading());
      final courses = await _apiService.searchCourses(event.query);
      _lastLoadedCourses = courses;
      emit(CourseLoaded(courses, CourseType.search));
    } catch (e) {
      emit(CourseError('Failed to search courses: ${e.toString()}'));
    }
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<CourseState> emit,
  ) async {
    try {
      // Always emit loading state first
      emit(CourseLoading());
      
      print('Loading dashboard data...');
      final dashboardData = await _apiService.getDashboardData();
      print('Dashboard data loaded: $dashboardData');
      
      if (dashboardData == null || dashboardData.isEmpty) {
        emit(CourseError('No dashboard data available'));
        return;
      }
      
      // Validate and process the data
      final processedData = _processDashboardData(dashboardData);
      _lastDashboardData = processedData;
      emit(DashboardLoaded(processedData));
    } catch (e) {
      print('Error loading dashboard: $e');
      emit(CourseError('Failed to load dashboard: ${e.toString()}'));
    }
  }

  Map<String, dynamic> _processDashboardData(Map<String, dynamic> rawData) {
    try {
      // Process subject distribution
      final subjectDist = (rawData['subject_distribution'] as Map<String, dynamic>?) ?? {};
      final processedSubjectDist = Map<String, int>.from(
        subjectDist.map((key, value) => MapEntry(key, (value as num).toInt()))
      );

      // Process level distribution
      final levelDist = (rawData['level_distribution'] as Map<String, dynamic>?) ?? {};
      final processedLevelDist = Map<String, int>.from(
        levelDist.map((key, value) => MapEntry(key, (value as num).toInt()))
      );

      // Process yearly metrics
      final yearlyMetrics = (rawData['yearly_metrics'] as Map<String, dynamic>?) ?? {};
      final yearlyProfit = (yearlyMetrics['profit'] as Map<String, dynamic>?) ?? {};
      final yearlySubscribers = (yearlyMetrics['subscribers'] as Map<String, dynamic>?) ?? {};

      final processedYearlyProfit = Map<String, double>.from(
        yearlyProfit.map((key, value) => MapEntry(key, (value as num).toDouble()))
      );
      final processedYearlySubscribers = Map<String, int>.from(
        yearlySubscribers.map((key, value) => MapEntry(key, (value as num).toInt()))
      );

      // Process monthly metrics
      final monthlyMetrics = (rawData['monthly_metrics'] as Map<String, dynamic>?) ?? {};
      final monthlyProfit = (monthlyMetrics['profit'] as Map<String, dynamic>?) ?? {};
      final monthlySubscribers = (monthlyMetrics['subscribers'] as Map<String, dynamic>?) ?? {};

      final processedMonthlyProfit = Map<String, double>.from(
        monthlyProfit.map((key, value) => MapEntry(key, (value as num).toDouble()))
      );
      final processedMonthlySubscribers = Map<String, int>.from(
        monthlySubscribers.map((key, value) => MapEntry(key, (value as num).toInt()))
      );

      // Return processed data
      return {
        'subject_distribution': processedSubjectDist,
        'level_distribution': processedLevelDist,
        'yearly_metrics': {
          'profit': processedYearlyProfit,
          'subscribers': processedYearlySubscribers,
        },
        'monthly_metrics': {
          'profit': processedMonthlyProfit,
          'subscribers': processedMonthlySubscribers,
        },
      };
    } catch (e) {
      print('Error processing dashboard data: $e');
      return {};
    }
  }
  
  void _onUserLoggedOut(
    UserLoggedOut event,
    Emitter<CourseState> emit,
  ) {
    emit(CourseInitial());
  }

  Future<void> _onRateCourse(
    RateCourse event, 
    Emitter<CourseState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is CourseLoaded) {
        // Find the course in the state
        final index = currentState.courses.indexWhere((c) => c.id == event.courseId);
        if (index != -1) {
          // Update the course with the new rating
          final updatedCourse = currentState.courses[index].copyWith(
            userRating: event.rating,
          );
          
          // Create a new list with the updated course
          final updatedCourses = List<Course>.from(currentState.courses);
          updatedCourses[index] = updatedCourse;
          
          // Emit the updated state
          emit(CourseLoaded(updatedCourses, currentState.type));
        }
      }
      
      // Update the courses in the API
      await _apiService.rateCourse(event.courseId, event.rating);
      
      // Update our cached course lists
      final index = _lastLoadedCourses.indexWhere((course) => course.id == event.courseId);
      if (index != -1) {
        final course = _lastLoadedCourses[index];
        _lastLoadedCourses[index] = course.copyWith(
          userRating: event.rating,
        );
      }
      
      // Emit the rated event
      emit(CourseRated(event.courseId, event.rating));
    } catch (e) {
      print('Error rating course: $e');
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event, 
    Emitter<CourseState> emit,
  ) async {
    try {
      final currentState = state;
      Course? targetCourse;
      bool newFavoriteStatus = false;
      List<Course> updatedCourses = [];
      
      // Find the course in the current state
      if (currentState is CourseLoaded) {
        try {
          targetCourse = currentState.courses.firstWhere(
            (course) => course.id == event.courseId,
          );
          
          // Determine the new favorite status (toggle the current value)
          newFavoriteStatus = !targetCourse.isFavorite;
          
          print('Toggling favorite for course ${targetCourse.title} to $newFavoriteStatus');
          
          // Update the course list with the new favorite status
          updatedCourses = currentState.courses.map((course) {
            if (course.id == event.courseId) {
              return course.copyWith(isFavorite: newFavoriteStatus);
            }
            return course;
          }).toList();
          
          // First emit the updated courses immediately for a responsive UI
          emit(CourseLoaded(updatedCourses, currentState.type));
          
          // Call the API to update the status
          final success = await _apiService.toggleCourseFavorite(event.courseId, newFavoriteStatus);
          
          if (success) {
            // Update our cached state
            _updateCourseInList(event.courseId, isFavorite: newFavoriteStatus);
            
            // Emit a specialized state for listeners
            emit(CourseFavoriteToggled(event.courseId, newFavoriteStatus));
            
            // If we're currently displaying favorites and removing a course from favorites,
            // we need to remove it from the view
            if (currentState.type == CourseType.favorites && !newFavoriteStatus) {
              updatedCourses = updatedCourses.where((course) => course.id != event.courseId).toList();
              emit(CourseLoaded(updatedCourses, CourseType.favorites));
            }
            
            // If we just added a favorite, reload all favorites to ensure UI is consistent
            if (newFavoriteStatus) {
              // Reload the favorites in the background
              _apiService.getFavoriteCourses().then((favorites) {
                if (currentState.type == CourseType.favorites) {
                  emit(CourseLoaded(favorites, CourseType.favorites));
                }
                // Also update our cache
                _courseCache[_getCacheKey(CourseType.favorites)] = favorites;
              });
            }
          }
        } catch (e) {
          print('Course not found or other error: $e');
          
          // Try to update via direct API call
          final success = await _apiService.toggleCourseFavorite(event.courseId, true);
          if (success) {
            // Update our cached state
            _updateCourseInList(event.courseId, isFavorite: true);
            emit(CourseFavoriteToggled(event.courseId, true));
            
            // Reload the favorites in the background
            _apiService.getFavoriteCourses().then((favorites) {
              // Also update our cache
              _courseCache[_getCacheKey(CourseType.favorites)] = favorites;
            });
          }
        }
      } else {
        // If not in a loaded state, try direct API call
        final success = await _apiService.toggleCourseFavorite(event.courseId, true);
        if (success) {
          // Update our cached state
          _updateCourseInList(event.courseId, isFavorite: true);
          emit(CourseFavoriteToggled(event.courseId, true));
          
          // Reload the favorites in the background
          _apiService.getFavoriteCourses().then((favorites) {
            // Also update our cache
            _courseCache[_getCacheKey(CourseType.favorites)] = favorites;
          });
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      // Don't change state on error, just log
    }
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<CourseState> emit,
  ) async {
    // Check if already loaded
    if (state is FavoriteCoursesLoaded) {
      return;
    }
    
    // Skip if already loading
    if (state is FavoriteCoursesLoading) {
      return;
    }
    
    // Emit loading state
    emit(FavoriteCoursesLoading());
    
    try {
      final courses = await _apiService.getFavoriteCourses();
      print("API returned ${courses.length} favorite courses");
      
      // Mark all courses as favorites
      final favoriteCourses = courses.map((course) => 
        course.copyWith(isFavorite: true)
      ).toList();
      
      // Emit loaded state
      emit(FavoriteCoursesLoaded(favoriteCourses));
    } catch (e) {
      emit(FavoriteCoursesError('Failed to load favorites: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCollaborativeRecommendations(
    LoadCollaborativeRecommendations event,
    Emitter<CourseState> emit,
  ) async {
    try {
      // Only proceed if not already in loaded state
      if (state is CollaborativeRecommendationsLoaded) {
        return;
      }
      
      emit(CollaborativeRecommendationsLoading());
      
      print('Getting collaborative recommendations for ${event.email}');
      final recommendations = await _apiService.getCollaborativeFilteringRecommendations();
      
      if (recommendations.isEmpty) {
        // If no collaborative recommendations, fall back to personalized
        print('No collaborative recommendations found, falling back to personalized');
        final personalizedCourses = await _apiService.getRecommendedCourses();
        emit(CollaborativeRecommendationsLoaded(personalizedCourses));
      } else {
        print('Loaded ${recommendations.length} collaborative recommendations');
        // Cache the results
        _courseCache['collaborative'] = recommendations;
        // Emit loaded state
        emit(CollaborativeRecommendationsLoaded(recommendations));
      }
    } catch (e) {
      print('Error loading collaborative recommendations: $e');
      emit(CollaborativeRecommendationsError('Failed to load recommendations: $e'));
      
      // Try to fall back to personalized recommendations
      try {
        final personalizedCourses = await _apiService.getRecommendedCourses();
        emit(CollaborativeRecommendationsLoaded(personalizedCourses));
      } catch (_) {
        // Already in error state, just log this second error
        print('Error loading fallback recommendations: $_');
      }
    }
  }

  Future<void> _onLoadTrendingCourses(
    LoadTrendingCourses event,
    Emitter<CourseState> emit,
  ) async {
    // Show loading state
    emit(TrendingCoursesLoading());
    
    try {
      // Load trending courses from API
      print('Loading trending courses...');
      final courses = await _apiService.getTrendingCourses();
      
      // Cache the trending courses
      _courseCache[_getCacheKey(CourseType.trending)] = courses;
      
      // Emit loaded state with trending courses
      emit(TrendingCoursesLoaded(courses));
      
      // Also update the CourseLoaded state for compatibility
      emit(CourseLoaded(courses, CourseType.trending));
    } catch (e) {
      print('Error loading trending courses: $e');
      emit(TrendingCoursesError('Failed to load trending courses: $e'));
    }
  }

  Future<void> _onLoadPersonalizedRecommendations(
    LoadPersonalizedRecommendations event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(CourseLoading());
      final courses = await _apiService.getRecommendedCourses();
      _lastLoadedCourses = courses;
      emit(CourseLoaded(courses, CourseType.personalized));
    } catch (e) {
      emit(CourseError('Failed to load personalized recommendations: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPersonalizedCourses(LoadPersonalizedCourses event, Emitter<CourseState> emit) async {
    try {
      emit(PersonalizedCoursesLoading());
      final courses = await _apiService.getRecommendedCourses();
      _lastLoadedCourses = courses;
      emit(PersonalizedCoursesLoaded(courses));
    } catch (e) {
      emit(PersonalizedCoursesError(e.toString()));
    }
  }

  Future<void> _onLoadFavoriteCourses(
    LoadFavoriteCourses event,
    Emitter<CourseState> emit,
  ) async {
    try {
      emit(FavoriteCoursesLoading());
      final courses = await _apiService.getFavoriteCourses();
      _lastLoadedCourses = courses;
      
      // Mark all courses as favorites
      final markedFavorites = courses.map((course) => course.copyWith(isFavorite: true)).toList();
      
      // Update the cache
      _courseCache[_getCacheKey(CourseType.favorites)] = markedFavorites;
      
      emit(FavoriteCoursesLoaded(markedFavorites));
    } catch (e) {
      emit(FavoriteCoursesError('Failed to load favorite courses: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCollaborativeFilteringRecommendations(
    LoadCollaborativeFilteringRecommendations event,
    Emitter<CourseState> emit,
  ) async {
    try {
      // Set loading flag
      _isCollaborativeRecommendationsLoading = true;
      
      // Always show loading state first
      emit(CollaborativeRecommendationsLoading());
      print('====== Emitted CollaborativeRecommendationsLoading state ======');
      
      // Make API call - force a new request
      print('====== Calling API service for collaborative recommendations ======');
      final recommendations = await _apiService.getCollaborativeFilteringRecommendations();
      
      print('====== Received ${recommendations.length} collaborative filtering recommendations ======');
      
      // Debug the first few recommendations
      if (recommendations.isNotEmpty) {
        print('====== First few collaborative filtering recommendations: ======');
        for (int i = 0; i < min(3, recommendations.length); i++) {
          print('Course ${i+1}: ${recommendations[i].title} (ID: ${recommendations[i].id})');
          print('Type: ${recommendations[i].runtimeType}');
          print('Hash: ${recommendations[i].hashCode}');
          print('Subject: ${recommendations[i].subject}');
          if (recommendations[i].imageUrl == null || recommendations[i].imageUrl!.isEmpty) {
            print('Course ${i+1} has no image URL');
          }
        }
        
        // DOUBLE CHECK that recommendations is not empty
        if (recommendations.length == 0) {
          print('====== WARNING: recommendations length is zero despite isNotEmpty test ======');
        }
        
        // Cache the results
        _courseCache['collaborative'] = recommendations;
        
        // Emit loaded state with recommendations
        print('====== Emitting CollaborativeRecommendationsLoaded with ${recommendations.length} recommendations ======');
        final loadedState = CollaborativeRecommendationsLoaded(recommendations);
        print('====== Created state: ${loadedState.runtimeType} with ${loadedState.recommendations.length} recommendations ======');
        print('====== Sample courses in state: ${loadedState.courseInfo} ======');
        emit(loadedState);
        print('====== Emitted state successfully ======');
        return;
      }
      
      // If recommendations list is empty, fall back to trending
      print('====== No collaborative filtering recommendations found, falling back to trending ======');
      try {
        final trendingCourses = await _apiService.getTrendingCourses();
        print('====== Received ${trendingCourses.length} trending courses as fallback ======');
        
        // Cache the results
        _courseCache['collaborative'] = trendingCourses;
        
        // Emit loaded state with trending courses
        emit(CollaborativeRecommendationsLoaded(trendingCourses));
      } catch (e) {
        print('====== Error loading trending courses fallback: $e ======');
        emit(CollaborativeRecommendationsError('No recommendations available. Please try again later.'));
      }
    } catch (e) {
      print('====== Error loading collaborative filtering recommendations: $e ======');
      emit(CollaborativeRecommendationsError('Failed to load recommendations: $e'));
    } finally {
      _isCollaborativeRecommendationsLoading = false;
    }
  }

  void _updateCourseInList(String courseId, {required bool isFavorite}) {
    try {
      // Get all the current states and update them
      final loadedStates = {
        CourseType.trending,
        CourseType.personalized,
        CourseType.favorites,
        CourseType.search,
      };
      
      for (var type in loadedStates) {
        final key = _getCacheKey(type);
        final courses = _courseCache[key];
        
        if (courses != null) {
          final updatedCourses = courses.map((course) {
            if (course.id == courseId) {
              return course.copyWith(isFavorite: isFavorite);
            }
            return course;
          }).toList();
          
          // Update the cache
          _courseCache[key] = updatedCourses;
        }
      }
      
      // Also update last loaded courses for backward compatibility
      final index = _lastLoadedCourses.indexWhere((course) => course.id == courseId);
      if (index != -1) {
        final course = _lastLoadedCourses[index];
        _lastLoadedCourses[index] = course.copyWith(
          isFavorite: isFavorite,
        );
      }
    } catch (e) {
      print('Error updating course in cached lists: $e');
    }
  }
  
  // Helper to get a cache key based on course type
  String _getCacheKey(CourseType type) {
    switch (type) {
      case CourseType.trending:
        return 'trending';
      case CourseType.personalized:
        return 'personalized';
      case CourseType.favorites:
        return 'favorites';
      case CourseType.search:
        return 'search';
      case CourseType.collaborative:
        return 'collaborative';
      default:
        return 'unknown';
    }
  }

  // Map CourseState to CourseType
  CourseType? _getTypeFromState(CourseState state) {
    if (state is CourseLoaded) {
      return state.type;
    } else if (state is FavoriteCoursesLoaded) {
      return CourseType.favorites;
    } else if (state is PersonalizedCoursesLoaded) {
      return CourseType.personalized;
    }
    return null;
  }
} 
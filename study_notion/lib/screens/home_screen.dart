import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:study_notion/bloc/course_bloc.dart';
import 'package:study_notion/bloc/auth_bloc.dart';
import 'package:study_notion/models/course.dart';
import 'package:study_notion/services/api_service.dart';
import 'package:study_notion/widgets/course_card.dart';
import 'package:study_notion/screens/dashboard_screen.dart';
import 'package:study_notion/screens/login_screen.dart';
import 'package:study_notion/screens/settings_screen.dart';
import 'package:study_notion/screens/appearance_settings_screen.dart';
import 'package:study_notion/screens/preferences_screen.dart';
import 'package:study_notion/screens/profile_screen.dart';
import 'package:study_notion/screens/recommendations_screen.dart';
import 'package:study_notion/screens/search_screen.dart';

// Explicitly import the events
import 'package:study_notion/bloc/course_bloc.dart' show 
  LoadCollaborativeRecommendations, 
  LoadPersonalizedRecommendations, 
  LoadTrendingCourses,
  LoadFavorites,
  SearchCourses,
  RateCourse,
  ToggleFavorite;

class HomeScreen extends StatefulWidget {
  final int initialTab;
  
  const HomeScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _apiService = Provider.of<ApiService>(context, listen: false);
    
    // Add listener for tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) { // Discover tab
          context.read<CourseBloc>().add(LoadTrendingCourses());
        } else if (_tabController.index == 1) { // For You tab
          context.read<CourseBloc>().add(LoadPersonalizedRecommendations());
        } else if (_tabController.index == 3) { // Favorites tab
          // Always reload favorites when tab is selected to ensure freshness
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            context.read<CourseBloc>().add(LoadFavorites());
          }
        }
      }
    });
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      
      // If we're starting on the favorites tab, load favorites
      if (widget.initialTab == 3) {
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          context.read<CourseBloc>().add(LoadFavorites());
        }
      }
    });
  }
  
  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      // Load collaborative recommendations for logged in users
      context.read<CourseBloc>().add(LoadCollaborativeRecommendations());
      
      // Load personalized recommendations based on preferences
      context.read<CourseBloc>().add(LoadPersonalizedRecommendations());
      
      // Load favorites
      context.read<CourseBloc>().add(LoadFavorites());
    } else {
      // Load trending courses for non-logged in users
      context.read<CourseBloc>().add(LoadTrendingCourses());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleCourseRating(String courseId, double rating) {
    context.read<CourseBloc>().add(RateCourse(courseId, rating));
  }
  
  void _handleCourseFavorite(String courseId, bool isFavorite) {
    context.read<CourseBloc>().add(ToggleFavorite(courseId));
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserLoggedIn = context.watch<AuthBloc>().state is Authenticated;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'StudyNotion',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF17252A),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_rounded),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard');
            },
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.account_circle_rounded),
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'logout') {
                          context.read<AuthBloc>().add(LogoutUser());
                          context.read<CourseBloc>().add(UserLoggedOut());
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        } else if (value == 'profile') {
                          Navigator.of(context).pushNamed('/profile');
                        } else if (value == 'settings') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(Icons.person_rounded, color: Color(0xFF3AAFA9)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Hi, ${state.user.name}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(Icons.settings_rounded, color: Color(0xFF3AAFA9)),
                                SizedBox(width: 12),
                                Text('Settings', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, color: Color(0xFF3AAFA9)),
                                SizedBox(width: 12),
                                Text('Logout', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.login_rounded),
                  tooltip: 'Login',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
          ),
          tabs: [
            const Tab(text: 'Discover'),
            const Tab(text: 'For You'),
            const Tab(text: 'Personal'),
            const Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Discover Tab - Show all courses
          BlocBuilder<CourseBloc, CourseState>(
            builder: (context, state) {
              if (state is CourseLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AAFA9)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search courses...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF3AAFA9)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            // Clear search and show trending courses
                            context.read<CourseBloc>().add(LoadTrendingCourses());
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (query) {
                        if (query.isNotEmpty) {
                          context.read<CourseBloc>().add(SearchCourses(query));
                        }
                      },
                    ),
                  ),
                  // Course Grid
                  Expanded(
                    child: state is CourseLoaded && state.courses.isNotEmpty
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: state.courses.length,
                            itemBuilder: (context, index) {
                              return CourseCard(
                                course: state.courses[index],
                                onRatingChanged: _handleCourseRating,
                                onFavoriteToggled: _handleCourseFavorite,
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text(
                                  'Search for Courses',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Enter a search term above to find courses that match your interests',
                                    style: TextStyle(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
          
          // For You Tab - Show trending courses
          BlocBuilder<CourseBloc, CourseState>(
            builder: (context, state) {
              if (state is CourseLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CourseLoaded && state.type == CourseType.trending) {
                return _buildCourseList(state.courses);
              } else {
                return const Center(child: Text('No trending courses available'));
              }
            },
          ),
          
          // Personal Tab - Navigate to Recommendations Screen
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecommendationsScreen(),
                    ),
                  );
                },
                child: const Text('View Personalized Recommendations'),
              ),
            ),
          ),
          
          // Favorites Tab
          BlocBuilder<CourseBloc, CourseState>(
            builder: (context, state) {
              if (state is CourseLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3AAFA9),
                  ),
                );
              } else if (state is CourseLoaded && state.type == CourseType.favorites) {
                if (state.courses.isEmpty) {
                  return _buildEmptyFavoritesState();
                }
                return Column(
                  children: [
                    // Header banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      decoration: const BoxDecoration(
                        color: Color(0xFF17252A),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${state.courses.length} Favorite Courses',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Your saved courses for easy access',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                            onPressed: () {
                              context.read<CourseBloc>().add(LoadFavorites());
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildCourseList(state.courses),
                    ),
                  ],
                );
              } else {
                // Check if user is logged in, if not show login prompt
                final authState = context.watch<AuthBloc>().state;
                if (authState is! Authenticated) {
                  return _buildLoginPrompt();
                }
                
                // If user is logged in but we don't have favorites loaded yet, load them
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<CourseBloc>().add(LoadFavorites());
                });
                
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3AAFA9),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCourseList(List<Course> courses) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return CourseCard(
          course: courses[index],
          onRatingChanged: (courseId, rating) {
            // When rating changes, update the course via bloc
            context.read<CourseBloc>().add(RateCourse(courseId, rating));
          },
          onFavoriteToggled: (courseId, isFavorite) {
            // Only reload favorites if unfavorited on the favorites tab
            if (_tabController.index == 3 && !isFavorite) {
              context.read<CourseBloc>().add(LoadFavorites());
            }
          },
        );
      },
    );
  }

  // Helper method to build placeholder states
  Widget _buildPlaceholderState({
    required IconData icon,
    required String title,
    required String message,
    bool isError = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: isError ? Colors.red : const Color(0xFF3AAFA9).withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isError ? Colors.red : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required VoidCallback onRefresh,
    Color iconColor = const Color(0xFF3AAFA9),
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(right: 26),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]!.withOpacity(0.6)
            : Colors.grey[100]!,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF3AAFA9),
            radius: 20,
            child: Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Based on Your Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: const Color(0xFF3AAFA9),
            onPressed: () {
              // Refresh recommendations
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3AAFA9).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.login_rounded,
                size: 64,
                color: Color(0xFF3AAFA9),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please log in to view and manage your favorite courses.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Log In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AAFA9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyFavoritesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: Colors.red.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your favorite courses will appear here. Start browsing and mark courses as favorites to see them here.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(0); // Go to Discover tab
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Discover Courses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AAFA9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
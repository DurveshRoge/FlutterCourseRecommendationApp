import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/course_bloc.dart';
import '../widgets/course_card.dart';
import '../models/course.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dart:math' show min;

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _handleTabChange();
      }
    });
    
    // Initial loading of data for tabs other than Discover
    print('MainScreen: Loading initial data');
  }

  // Flag to prevent multiple LoadFavorites calls
  bool _isLoadingFavorites = false;

  void _handleTabChange() {
    print('Tab changed to index: ${_tabController.index}');
    
    // Depending on the current tab, load appropriate data
    switch (_tabController.index) {
      case 0: // Discover
        // Don't automatically load trending courses
        break;
      case 1: // Personalized
        context.read<CourseBloc>().add(LoadPersonalizedCourses());
        break;
      case 2: // Favorites
        // Only load favorites if not already loading or loaded
        if (!_isLoadingFavorites) {
          _isLoadingFavorites = true;
          print('Loading favorites from tab change');
          context.read<CourseBloc>().add(LoadFavorites());
          
          // Reset the flag after some time
          Future.delayed(const Duration(seconds: 5), () {
            _isLoadingFavorites = false;
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StudyNotion'),
        actions: [
          // Debug button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              print('DEBUG: Manually triggering recommendation reload');
              context.read<CourseBloc>().add(LoadPersonalizedCourses());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reloading recommendations...'))
              );
            },
            child: Text('Reload'),
          ),
          IconButton(
            icon: Icon(Icons.grid_view),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Discover'),
            Tab(text: 'Personal'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTabWithBloc(),
          _buildPersonalTabWithBloc(),
          _buildFavoritesTabWithBloc(),
        ],
      ),
    );
  }
  
  Widget _buildDiscoverTabWithBloc() {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: Icon(Icons.search, color: Colors.teal),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      // Clear search results
                      context.read<CourseBloc>().add(SearchCourses(""));
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    context.read<CourseBloc>().add(SearchCourses(query));
                  }
                },
              ),
            ),
            // Tab Content
            Expanded(
              child: _buildDiscoverTab(state),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildPersonalTabWithBloc() {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        return _buildPersonalTab(state);
      },
    );
  }
  
  Widget _buildFavoritesTabWithBloc() {
    return BlocBuilder<CourseBloc, CourseState>(
      buildWhen: (previous, current) {
        return current is FavoriteCoursesLoaded || 
               current is FavoriteCoursesLoading || 
               current is FavoriteCoursesError;
      },
      builder: (context, state) {
        if (state is FavoriteCoursesLoaded) {
          if (state.courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No Favorites Yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text('Add courses to your favorites to see them here'),
                ],
              ),
            );
          }
          
          // Mirror the exact same implementation from the working Discover tab
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: state.courses.length,
            itemBuilder: (context, index) {
              return CourseCard(course: state.courses[index]);
            },
          );
        }
        
        if (state is FavoriteCoursesLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        // Simple one-time load
        if (!(state is FavoriteCoursesLoading)) {
          context.read<CourseBloc>().add(LoadFavorites());
        }
        
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDiscoverTab(CourseState state) {
    if (state is CourseLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (state is CourseError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Clear state instead of loading trending courses
                context.read<CourseBloc>().add(SearchCourses(""));
              },
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    } else if (state is CourseLoaded && state.type == CourseType.search && state.courses.isNotEmpty) {
      // Only show courses if they're search results
      return _buildCourseGrid(state.courses, messageType: 'search results');
    } else {
      // Default state - prompt user to search
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Search for Courses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Enter a search term above to find courses',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPersonalTab(CourseState state) {
    if (state is CourseLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (state is CourseError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<CourseBloc>().add(LoadPersonalizedRecommendations());
              },
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    } else if (state is CourseLoaded) {
      return _buildCourseGrid(state.courses, messageType: 'personalized courses');
    }
    return Center(child: Text('No personalized recommendations available'));
  }

  Widget _buildCourseGrid(List<Course> courses, {String messageType = 'courses'}) {
    print('***** _buildCourseGrid called with ${courses.length} $messageType *****');
    
    if (courses.isEmpty) {
      print('***** _buildCourseGrid: Empty courses list, showing empty message *****');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No $messageType available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    print('***** _buildCourseGrid: Building grid with ${courses.length} courses *****');
    
    // Debug the first few courses
    for (int i = 0; i < min(2, courses.length); i++) {
      final course = courses[i];
      print('Course $i: ${course.title} (ID: ${course.id})');
      print('  Subject: ${course.subject}');
      print('  Image URL: ${course.imageUrl}');
    }

    // Grid of courses without search bar
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        print('Building course card for: ${course.title} (${course.id}) at index $index');
        return CourseCard(course: course);
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 
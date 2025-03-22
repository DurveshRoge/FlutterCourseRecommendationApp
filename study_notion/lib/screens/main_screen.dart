import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/course_bloc.dart';
import '../widgets/course_card.dart';
import '../models/course.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Simple tab changed handler
        if (_tabController.index == 3) { // Favorites tab
          context.read<CourseBloc>().add(LoadFavorites());
        }
      }
    });
    
    // Initial loading of data
    context.read<CourseBloc>().add(LoadTrendingCourses());
  }

  // Flag to prevent multiple LoadFavorites calls
  bool _isLoadingFavorites = false;

  void _handleTabChange() {
    print('Tab changed to index: ${_tabController.index}');
    
    // Depending on the current tab, load appropriate data
    switch (_tabController.index) {
      case 0: // Discover
        context.read<CourseBloc>().add(LoadTrendingCourses());
        break;
      case 1: // For You
        context.read<CourseBloc>().add(LoadPersonalizedRecommendations());
        break;
      case 2: // Personalized
        context.read<CourseBloc>().add(LoadPersonalizedCourses());
        break;
      case 3: // Favorites
        // Only load favorites if not already loading or loaded
        if (!_isLoadingFavorites) {
          _isLoadingFavorites = true;
          print('Loading favorites from tab change');
          context.read<CourseBloc>().add(LoadFavorites());
          
          // Reset flag after delay
          Future.delayed(Duration(seconds: 2), () {
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
            Tab(text: 'For You'),
            Tab(text: 'Personal'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverTabWithBloc(),
          _buildForYouTabWithBloc(),
          _buildPersonalTabWithBloc(),
          _buildFavoritesTabWithBloc(),
        ],
      ),
    );
  }
  
  Widget _buildDiscoverTabWithBloc() {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        return _buildDiscoverTab(state);
      },
    );
  }
  
  Widget _buildForYouTabWithBloc() {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        return _buildForYouTab(state);
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
    return Center(child: Text('Search for courses'));
  }

  Widget _buildForYouTab(CourseState state) {
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
                context.read<CourseBloc>().add(LoadTrendingCourses());
              },
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    } else if (state is CourseLoaded) {
      return _buildCourseGrid(state.courses);
    }
    return Center(child: Text('No trending courses available'));
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
      return _buildCourseGrid(state.courses);
    }
    return Center(child: Text('No personalized recommendations available'));
  }

  Widget _buildCourseGrid(List<Course> courses) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No courses available',
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

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                SizedBox(width: 16),
                Icon(Icons.search, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search courses...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        
        // Grid of courses
        Expanded(
          child: GridView.builder(
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
              print('Building course card for: ${course.title} (${course.id})');
              return CourseCard(course: course);
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 
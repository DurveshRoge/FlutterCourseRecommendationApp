import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/course_bloc.dart';
import '../services/api_service.dart';
import '../models/course.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _favoriteCount = 0;
  int _viewedCount = 0;
  int _ratedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<ApiService>();
      
      // Load favorites
      final favorites = await apiService.getFavoriteCourses();
      
      // Load viewed courses 
      // This would usually be from the API, but we'll simulate it for now
      final viewedCourses = [];
      
      // Load rated courses (based on the API structure)
      // This would usually be from the API, but we'll simulate it for now
      final ratedCourses = [];
      
      setState(() {
        _favoriteCount = favorites.length;
        _viewedCount = viewedCourses.length;
        _ratedCount = ratedCourses.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<ApiService>();
    final user = apiService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF17252A),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Profile',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share profile coming soon'))
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserStats,
        color: const Color(0xFF3AAFA9),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section with user info
              Container(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                decoration: const BoxDecoration(
                  color: Color(0xFF17252A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // User avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF3AAFA9),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3AAFA9),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // User name and email
                    if (user != null) ...[
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              // Stats Cards
              if (user != null) ...[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            color: Color(0xFF3AAFA9),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Account Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Stats cards
                      _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(
                                color: Color(0xFF3AAFA9),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              _buildStatCard(
                                icon: Icons.favorite_rounded,
                                iconColor: Colors.red,
                                label: 'Favorites',
                                value: _favoriteCount.toString(),
                                bgColor: Colors.red.withOpacity(0.1),
                                onTap: () {
                                  context.read<CourseBloc>().add(LoadFavorites());
                                  Navigator.pushNamed(context, '/favorites');
                                },
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                icon: Icons.history_rounded,
                                iconColor: Colors.blue,
                                label: 'Viewed',
                                value: _viewedCount.toString(),
                                bgColor: Colors.blue.withOpacity(0.1),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('View history coming soon'))
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                icon: Icons.star_rounded,
                                iconColor: Colors.amber,
                                label: 'Rated',
                                value: _ratedCount.toString(),
                                bgColor: Colors.amber.withOpacity(0.1),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Rated courses coming soon'))
                                  );
                                },
                              ),
                            ],
                          ),
                          
                      const SizedBox(height: 30),
                      
                      // Profile actions section
                      const Row(
                        children: [
                          Icon(
                            Icons.settings_rounded,
                            color: Color(0xFF3AAFA9),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Settings options
                      _buildSettingsOption(
                        icon: Icons.person_rounded,
                        title: 'Personal Information',
                        subtitle: 'View and edit your details',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Personal information editing coming soon'))
                          );
                        },
                      ),
                      
                      _buildSettingsOption(
                        icon: Icons.settings_rounded,
                        title: 'Preferences',
                        subtitle: 'Manage your account settings and preferences',
                        onTap: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                      
                      _buildSettingsOption(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        subtitle: 'Manage your notification preferences',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification settings coming soon'))
                          );
                        },
                      ),
                      
                      _buildSettingsOption(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'Get help with your account or app issues',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help & Support coming soon'))
                          );
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Logout button
                      ElevatedButton.icon(
                        onPressed: () async {
                          final success = await apiService.logout();
                          if (success && context.mounted) {
                            context.read<CourseBloc>().add(UserLoggedOut());
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Show this if user is not logged in
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_circle_rounded,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Not logged in',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Log in to access your profile and personalized features',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Log In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3AAFA9),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3AAFA9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3AAFA9),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
} 
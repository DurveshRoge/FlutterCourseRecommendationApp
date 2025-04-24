import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_notion/bloc/auth_bloc.dart';
import 'package:study_notion/bloc/course_bloc.dart';
import 'package:study_notion/models/user.dart';
import 'package:study_notion/screens/preferences_screen.dart';
import 'package:study_notion/screens/login_screen.dart';
import 'package:study_notion/services/api_service.dart';
import 'package:study_notion/screens/notification_settings_screen.dart';
import 'package:study_notion/screens/appearance_settings_screen.dart';
import 'package:study_notion/screens/account_settings_screen.dart';
import 'package:study_notion/screens/privacy_settings_screen.dart';
import 'package:study_notion/screens/help_support_screen.dart';
import 'package:study_notion/screens/about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _refreshUserPreferences();
  }
  
  Future<void> _refreshUserPreferences() async {
    if (!mounted) return;
    
    final apiService = context.read<ApiService>();
    AuthBloc? authBloc;
    
    // Get a reference to AuthBloc before any async operations
    if (mounted) {
      authBloc = context.read<AuthBloc>();
    } else {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await apiService.refreshUserPreferences();
      
      // Update the AuthBloc with the refreshed user data if widget is still mounted
      if (mounted && authBloc != null) {
        final user = apiService.currentUser;
        if (user != null) {
          authBloc.add(RefreshUserData(user));
        }
      }
    } catch (e) {
      print('Error refreshing user preferences: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back navigation
        Navigator.of(context).pop();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: const Color(0xFF17252A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3AAFA9),
                ),
              )
            : BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated) {
                    final user = state.user;
                    return RefreshIndicator(
                      onRefresh: _refreshUserPreferences,
                      color: const Color(0xFF3AAFA9),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserHeaderCard(user),
                            const SizedBox(height: 20),
                            _buildCategoryHeader(
                              icon: Icons.tune_rounded,
                              title: 'Preferences',
                            ),
                            _buildSettingsTile(
                              icon: Icons.school_rounded,
                              iconBgColor: Colors.blue.withOpacity(0.1),
                              iconColor: Colors.blue,
                              title: 'Learning Preferences',
                              subtitle: 'Update your topics, skill level, and interests',
                              onTap: () async {
                                // Save references before navigation
                                CourseBloc? courseBloc;
                                if (mounted) {
                                  courseBloc = context.read<CourseBloc>();
                                }
                                
                                await Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (_) => PreferencesScreen(user: user, isUpdate: true)
                                  )
                                );
                                
                                // Check if widget is still mounted after coming back
                                if (!mounted) return;
                                
                                // After returning from preferences screen, trigger a full state rebuild
                                setState(() {
                                  _isLoading = true;
                                });
                                
                                // Refresh user preferences and recommendation data
                                await _refreshUserPreferences();
                                
                                // Refresh recommendations if still mounted
                                if (mounted && courseBloc != null) {
                                  courseBloc.add(LoadPersonalizedRecommendations());
                                }
                              },
                            ),
                            _buildSettingsTile(
                              icon: Icons.notification_important_rounded,
                              iconBgColor: Colors.amber.withOpacity(0.1),
                              iconColor: Colors.amber,
                              title: 'Notifications',
                              subtitle: 'Configure your notification preferences',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildSettingsTile(
                              icon: Icons.nightlight_round,
                              iconBgColor: Colors.indigo.withOpacity(0.1),
                              iconColor: Colors.indigo,
                              title: 'Appearance',
                              subtitle: 'Dark mode and theme settings',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AppearanceSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                            const SizedBox(height: 16),
                            _buildCategoryHeader(
                              icon: Icons.account_circle_rounded,
                              title: 'Account',
                            ),
                            _buildSettingsTile(
                              icon: Icons.manage_accounts_rounded,
                              iconBgColor: Colors.green.withOpacity(0.1),
                              iconColor: Colors.green,
                              title: 'Account Settings',
                              subtitle: 'Manage your account details and password',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AccountSettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildSettingsTile(
                              icon: Icons.privacy_tip_rounded,
                              iconBgColor: Colors.purple.withOpacity(0.1),
                              iconColor: Colors.purple,
                              title: 'Privacy',
                              subtitle: 'Manage your privacy settings and data',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacySettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                            const SizedBox(height: 16),
                            _buildCategoryHeader(
                              icon: Icons.help_outline_rounded,
                              title: 'Support',
                            ),
                            _buildSettingsTile(
                              icon: Icons.help_center_rounded,
                              iconBgColor: Colors.teal.withOpacity(0.1),
                              iconColor: Colors.teal,
                              title: 'Help & Support',
                              subtitle: 'Get help with your account or app issues',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HelpSupportScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildSettingsTile(
                              icon: Icons.info_outline_rounded,
                              iconBgColor: Colors.blue.withOpacity(0.1),
                              iconColor: Colors.blue,
                              title: 'About',
                              subtitle: 'Learn more about the StudyNotion app',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AboutScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.read<AuthBloc>().add(LogoutUser());
                                  context.read<CourseBloc>().add(UserLoggedOut());
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
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
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Center(
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
                            'Log in to access your settings',
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
                              minimumSize: const Size(200, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
      ),
    );
  }

  Widget _buildUserHeaderCard(User user) {
    // Get valid topics from the dataset
    final List<String> validTopics = [
      'Business Finance',
      'Graphic Design', 
      'Musical Instruments',
      'Web Development',
      'Mobile Development',
      'Data Science',
      'Photography',
      'Marketing',
    ];
    
    // Filter to only show valid topics and ensure we have fresh data
    final List<String> displayTopics = user.preferredTopics
        .where((topic) => validTopics.contains(topic))
        .toList();
    
    print('=== Building user header card ===');
    print('User: ${user.name} (${user.email})');
    print('All preferred topics: ${user.preferredTopics}');
    print('Display topics after filtering: $displayTopics');
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF17252A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
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
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3AAFA9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Interests:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          displayTopics.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No topics selected. Update your preferences to get personalized recommendations.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: displayTopics.map((topic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3AAFA9).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF3AAFA9).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF3AAFA9),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17252A),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
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
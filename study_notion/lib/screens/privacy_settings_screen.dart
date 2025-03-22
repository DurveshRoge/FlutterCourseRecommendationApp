import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = true;
  
  // Data Collection
  bool _collectUsageData = true;
  bool _collectCourseInteractions = true;
  bool _sendCrashReports = true;
  
  // Data Sharing
  bool _shareLearningProgress = false;
  bool _shareCourseFeedback = false;
  bool _enablePersonalization = true;
  
  // Marketing
  bool _allowPersonalizedAds = false;
  bool _allowEmailMarketing = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        // Data Collection
        _collectUsageData = prefs.getBool('collect_usage_data') ?? true;
        _collectCourseInteractions = prefs.getBool('collect_course_interactions') ?? true;
        _sendCrashReports = prefs.getBool('send_crash_reports') ?? true;
        
        // Data Sharing
        _shareLearningProgress = prefs.getBool('share_learning_progress') ?? false;
        _shareCourseFeedback = prefs.getBool('share_course_feedback') ?? false;
        _enablePersonalization = prefs.getBool('enable_personalization') ?? true;
        
        // Marketing
        _allowPersonalizedAds = prefs.getBool('allow_personalized_ads') ?? false;
        _allowEmailMarketing = prefs.getBool('allow_email_marketing') ?? false;
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading privacy settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Data Collection
      await prefs.setBool('collect_usage_data', _collectUsageData);
      await prefs.setBool('collect_course_interactions', _collectCourseInteractions);
      await prefs.setBool('send_crash_reports', _sendCrashReports);
      
      // Data Sharing
      await prefs.setBool('share_learning_progress', _shareLearningProgress);
      await prefs.setBool('share_course_feedback', _shareCourseFeedback);
      await prefs.setBool('enable_personalization', _enablePersonalization);
      
      // Marketing
      await prefs.setBool('allow_personalized_ads', _allowPersonalizedAds);
      await prefs.setBool('allow_email_marketing', _allowEmailMarketing);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy settings saved'),
          backgroundColor: Color(0xFF3AAFA9),
        ),
      );
    } catch (e) {
      print('Error saving privacy settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF17252A),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _savePrivacySettings,
            tooltip: 'Save settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3AAFA9),
              ),
            )
          : ListView(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Control how your data is collected, used, and shared.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Data Collection'),
                _buildSwitchTile(
                  title: 'App Usage Data',
                  subtitle: 'Allow collection of anonymous app usage data to improve user experience',
                  value: _collectUsageData,
                  onChanged: (value) {
                    setState(() {
                      _collectUsageData = value;
                    });
                  },
                  icon: Icons.analytics_rounded,
                  iconBgColor: Colors.blue.withOpacity(0.1),
                  iconColor: Colors.blue,
                ),
                _buildSwitchTile(
                  title: 'Course Interactions',
                  subtitle: 'Allow collection of your course viewing and interaction data',
                  value: _collectCourseInteractions,
                  onChanged: (value) {
                    setState(() {
                      _collectCourseInteractions = value;
                    });
                  },
                  icon: Icons.book_rounded,
                  iconBgColor: Colors.green.withOpacity(0.1),
                  iconColor: Colors.green,
                ),
                _buildSwitchTile(
                  title: 'Crash Reports',
                  subtitle: 'Send anonymous crash reports to help improve app stability',
                  value: _sendCrashReports,
                  onChanged: (value) {
                    setState(() {
                      _sendCrashReports = value;
                    });
                  },
                  icon: Icons.bug_report_rounded,
                  iconBgColor: Colors.orange.withOpacity(0.1),
                  iconColor: Colors.orange,
                ),
                const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
                _buildSectionHeader('Data Sharing & Personalization'),
                _buildSwitchTile(
                  title: 'Share Learning Progress',
                  subtitle: 'Allow sharing your learning progress with course instructors',
                  value: _shareLearningProgress,
                  onChanged: (value) {
                    setState(() {
                      _shareLearningProgress = value;
                    });
                  },
                  icon: Icons.timeline_rounded,
                  iconBgColor: Colors.purple.withOpacity(0.1),
                  iconColor: Colors.purple,
                ),
                _buildSwitchTile(
                  title: 'Course Feedback Visibility',
                  subtitle: 'Make your course reviews and ratings visible to other users',
                  value: _shareCourseFeedback,
                  onChanged: (value) {
                    setState(() {
                      _shareCourseFeedback = value;
                    });
                  },
                  icon: Icons.rate_review_rounded,
                  iconBgColor: Colors.teal.withOpacity(0.1),
                  iconColor: Colors.teal,
                ),
                _buildSwitchTile(
                  title: 'Personalization',
                  subtitle: 'Enable personalized course recommendations based on your interests',
                  value: _enablePersonalization,
                  onChanged: (value) {
                    setState(() {
                      _enablePersonalization = value;
                    });
                  },
                  icon: Icons.person_rounded,
                  iconBgColor: Colors.indigo.withOpacity(0.1),
                  iconColor: Colors.indigo,
                ),
                const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
                _buildSectionHeader('Marketing Preferences'),
                _buildSwitchTile(
                  title: 'Personalized Ads',
                  subtitle: 'Allow personalized advertisements based on your interests',
                  value: _allowPersonalizedAds,
                  onChanged: (value) {
                    setState(() {
                      _allowPersonalizedAds = value;
                    });
                  },
                  icon: Icons.ads_click_rounded,
                  iconBgColor: Colors.red.withOpacity(0.1),
                  iconColor: Colors.red,
                ),
                _buildSwitchTile(
                  title: 'Email Marketing',
                  subtitle: 'Receive promotional emails about new courses and special offers',
                  value: _allowEmailMarketing,
                  onChanged: (value) {
                    setState(() {
                      _allowEmailMarketing = value;
                    });
                  },
                  icon: Icons.mark_email_read_rounded,
                  iconBgColor: Colors.amber.withOpacity(0.1),
                  iconColor: Colors.amber,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Note: Some data collection is essential for basic app functionality. You can request deletion of your data at any time from Account Settings.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _savePrivacySettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3AAFA9),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Settings'),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: () {
                      _showPrivacyPolicyDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF17252A),
                      side: const BorderSide(color: Color(0xFF3AAFA9)),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Privacy Policy'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF17252A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3AAFA9),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPolicySection(
                'Data Collection',
                'We collect certain information to provide and improve our services. This includes usage data, course interactions, and crash reports.',
              ),
              _buildPolicySection(
                'Data Usage',
                'We use your data to personalize your experience, recommend relevant courses, and improve our platform functionality.',
              ),
              _buildPolicySection(
                'Data Sharing',
                'We do not sell your personal information. Your data may be shared with instructors and service providers as necessary to provide our services.',
              ),
              _buildPolicySection(
                'Your Rights',
                'You have the right to access, modify, or delete your personal data at any time. You can also opt out of certain data collection activities.',
              ),
              _buildPolicySection(
                'Security',
                'We implement appropriate technical and organizational measures to protect your personal data against unauthorized access or disclosure.',
              ),
              _buildPolicySection(
                'Updates',
                'This privacy policy may be updated periodically. We will notify you of any significant changes.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
} 
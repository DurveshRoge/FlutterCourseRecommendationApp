import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_notion/bloc/auth_bloc.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _courseUpdates = true;
  bool _newRecommendations = true;
  bool _specialOffers = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _courseUpdates = prefs.getBool('course_updates') ?? true;
        _newRecommendations = prefs.getBool('new_recommendations') ?? true;
        _specialOffers = prefs.getBool('special_offers') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('push_notifications', _pushNotifications);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('course_updates', _courseUpdates);
      await prefs.setBool('new_recommendations', _newRecommendations);
      await prefs.setBool('special_offers', _specialOffers);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved'),
          backgroundColor: Color(0xFF3AAFA9),
        ),
      );
    } catch (e) {
      print('Error saving notification settings: $e');
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
          'Notification Settings',
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
            onPressed: _saveNotificationSettings,
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
                const SizedBox(height: 16),
                _buildSectionHeader('General Notification Settings'),
                _buildSwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications on your device',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                  icon: Icons.notifications_rounded,
                  iconBgColor: Colors.blue.withOpacity(0.1),
                  iconColor: Colors.blue,
                ),
                _buildSwitchTile(
                  title: 'Email Notifications',
                  subtitle: 'Receive notifications via email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                  icon: Icons.email_rounded,
                  iconBgColor: Colors.purple.withOpacity(0.1),
                  iconColor: Colors.purple,
                ),
                const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
                _buildSectionHeader('Content Notifications'),
                _buildSwitchTile(
                  title: 'Course Updates',
                  subtitle: 'Be notified about updates to your courses',
                  value: _courseUpdates,
                  onChanged: (value) {
                    setState(() {
                      _courseUpdates = value;
                    });
                  },
                  icon: Icons.update_rounded,
                  iconBgColor: Colors.green.withOpacity(0.1),
                  iconColor: Colors.green,
                ),
                _buildSwitchTile(
                  title: 'New Recommendations',
                  subtitle: 'Be notified about new recommendations based on your interests',
                  value: _newRecommendations,
                  onChanged: (value) {
                    setState(() {
                      _newRecommendations = value;
                    });
                  },
                  icon: Icons.recommend_rounded,
                  iconBgColor: Colors.orange.withOpacity(0.1),
                  iconColor: Colors.orange,
                ),
                _buildSwitchTile(
                  title: 'Special Offers',
                  subtitle: 'Be notified about special offers and promotions',
                  value: _specialOffers,
                  onChanged: (value) {
                    setState(() {
                      _specialOffers = value;
                    });
                  },
                  icon: Icons.local_offer_rounded,
                  iconBgColor: Colors.red.withOpacity(0.1),
                  iconColor: Colors.red,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Note: You can change these settings at any time. Some notifications may still be sent for account security and important updates.',
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
                    onPressed: _saveNotificationSettings,
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
} 
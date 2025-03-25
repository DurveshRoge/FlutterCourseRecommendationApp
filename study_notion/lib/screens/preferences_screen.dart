import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_notion/bloc/auth_bloc.dart';
import 'package:study_notion/models/user.dart';
import 'package:study_notion/screens/home_screen.dart';
import 'package:study_notion/services/api_service.dart';

class PreferencesScreen extends StatefulWidget {
  final User user;
  final bool isUpdate;

  const PreferencesScreen({
    Key? key, 
    required this.user,
    this.isUpdate = false,
  }) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late List<String> _selectedTopics;
  late String _skillLevel;
  late String _courseType;
  late String _preferredDuration;
  late String _popularityImportance;
  bool _isLoading = false;

  // Available topics from the dataset
  final List<String> _availableTopics = [
    'Business Finance',
    'Graphic Design',
    'Musical Instruments',
    'Web Development'
  ];

  // Skill levels
  final List<String> _skillLevels = [
    'Beginner',
    'Intermediate',
    'All Levels'
  ];

  // Course types
  final List<String> _courseTypes = [
    'Free',
    'Paid',
    'No preference'
  ];

  // Course durations
  final List<String> _durations = [
    'Less than 2 hours',
    '2-5 hours',
    '5+ hours',
    'No preference'
  ];

  // Popularity importance
  final List<String> _popularityOptions = [
    'Very important',
    'Somewhat important',
    'Not important'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with user's existing preferences if updating
    if (widget.isUpdate) {
      _selectedTopics = List.from(widget.user.preferredTopics);
      _skillLevel = widget.user.skillLevel.isNotEmpty ? widget.user.skillLevel : 'Beginner';
      _courseType = widget.user.courseType.isNotEmpty ? widget.user.courseType : 'No preference';
      _preferredDuration = widget.user.preferredDuration.isNotEmpty ? widget.user.preferredDuration : 'No preference';
      _popularityImportance = widget.user.popularityImportance.isNotEmpty ? widget.user.popularityImportance : 'Somewhat important';
    } else {
      // Default values for new users
      _selectedTopics = [];
      _skillLevel = 'Beginner';
      _courseType = 'No preference';
      _preferredDuration = 'No preference';
      _popularityImportance = 'Somewhat important';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUpdate ? 'Update Preferences' : 'Your Preferences'),
        backgroundColor: const Color(0xFF17252A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3AAFA9)))
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isUpdate 
                            ? 'Update your learning preferences'
                            : 'Help us personalize your experience',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3AAFA9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your answers will help us recommend courses that match your interests and needs.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Topics section
                      _buildSectionTitle('What topics interest you the most?'),
                      const SizedBox(height: 8),
                      Container(
                        width: MediaQuery.of(context).size.width - 32,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          children: _availableTopics.map((topic) {
                            final isSelected = _selectedTopics.contains(topic);
                            return FilterChip(
                              label: Text(
                                topic,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? const Color(0xFF3AAFA9) : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTopics.add(topic);
                                  } else {
                                    _selectedTopics.remove(topic);
                                  }
                                });
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: const Color(0xFF3AAFA9).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF3AAFA9),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Skill level section
                      _buildSectionTitle('What is your skill level?'),
                      const SizedBox(height: 8),
                      _buildRadioGroup(
                        options: _skillLevels,
                        groupValue: _skillLevel,
                        onChanged: (value) {
                          setState(() {
                            _skillLevel = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Course type section
                      _buildSectionTitle('Are you looking for free or paid courses?'),
                      const SizedBox(height: 8),
                      _buildRadioGroup(
                        options: _courseTypes,
                        groupValue: _courseType,
                        onChanged: (value) {
                          setState(() {
                            _courseType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Duration section
                      _buildSectionTitle('What is your preferred course duration?'),
                      const SizedBox(height: 8),
                      _buildRadioGroup(
                        options: _durations,
                        groupValue: _preferredDuration,
                        onChanged: (value) {
                          setState(() {
                            _preferredDuration = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Popularity section
                      _buildSectionTitle('How important is course popularity to you?'),
                      const SizedBox(height: 8),
                      _buildRadioGroup(
                        options: _popularityOptions,
                        groupValue: _popularityImportance,
                        onChanged: (value) {
                          setState(() {
                            _popularityImportance = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savePreferences,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3AAFA9),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            widget.isUpdate ? 'Update Preferences' : 'Save Preferences',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Skip button (only for initial setup)
                      if (!widget.isUpdate)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _skipPreferences,
                            child: const Text(
                              'Skip for now',
                              style: TextStyle(color: Color(0xFF2B7A78)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2B7A78),
      ),
    );
  }

  Widget _buildRadioGroup({
    required List<String> options,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(
            option,
            style: const TextStyle(fontSize: 15),
          ),
          dense: true,
          value: option,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: const Color(0xFF3AAFA9),
          contentPadding: EdgeInsets.zero,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        );
      }).toList(),
    );
  }

  Future<void> _savePreferences() async {
    if (_selectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one topic'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<ApiService>();
      
      print('=== Saving User Preferences ===');
      print('User: ${widget.user.email}');
      print('Selected topics: $_selectedTopics');
      print('Skill level: $_skillLevel');
      print('Course type: $_courseType');
      print('Duration: $_preferredDuration');
      print('Popularity: $_popularityImportance');
      
      // Save preferences
      await apiService.saveUserPreferences(
        topics: _selectedTopics,
        level: _skillLevel,
        type: _courseType,
        duration: _preferredDuration,
        popularity: _popularityImportance,
      );

      // Refresh user preferences from the server
      await apiService.refreshUserPreferences();
      
      // Update the AuthBloc with the current user (which now has updated preferences)
      if (apiService.currentUser != null) {
        context.read<AuthBloc>().add(RefreshUserData(apiService.currentUser!));
      }

      print('=== Getting Updated Recommendations ===');
      final recommendations = await apiService.getPersonalizedRecommendations();
      print('Received ${recommendations.length} recommendations');
      print('Recommendation subjects: ${recommendations.map((c) => c.subject).toSet().toList()}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // If this is initial setup, navigate to home screen
        if (!widget.isUpdate) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error saving preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skipPreferences() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
} 
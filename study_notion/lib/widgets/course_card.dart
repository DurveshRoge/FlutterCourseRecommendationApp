import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:study_notion/models/course.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:study_notion/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_notion/bloc/course_bloc.dart';
import 'package:study_notion/bloc/auth_bloc.dart';

class CourseCard extends StatefulWidget {
  final Course course;
  final Function(String, double)? onRatingChanged;
  final Function(String, bool)? onFavoriteToggled;

  const CourseCard({
    Key? key,
    required this.course,
    this.onRatingChanged,
    this.onFavoriteToggled,
  }) : super(key: key);

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  late bool _isFavorite;
  // Flag to prevent multiple simultaneous API calls
  static bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.course.isFavorite;
  }

  @override
  void didUpdateWidget(CourseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.isFavorite != widget.course.isFavorite) {
      _isFavorite = widget.course.isFavorite;
    }
  }

  void _toggleFavorite(BuildContext context) {
    print('Toggling favorite for course: ${widget.course.id}');
    final course = widget.course;
    
    // Check if user is logged in
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      // Show login prompt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to save favorites'),
          action: SnackBarAction(
            label: 'Log In',
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    // Update local state for immediate feedback
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    // Dispatch the toggle event
    context.read<CourseBloc>().add(ToggleFavorite(course.id));
    
    // Provide feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          course.isFavorite 
            ? 'Removed from favorites' 
            : 'Added to favorites',
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building CourseCard for course: ${widget.course.title}, isFavorite: ${widget.course.isFavorite}');
    
    return SizedBox(
      height: 300,
      child: GestureDetector(
        onTap: () {
          if (widget.course.url.isNotEmpty) {
            print('Launching URL: ${widget.course.url}');
            _launchURL(widget.course.url);
          }
        },
        child: Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course image with level badge
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    // Course image or placeholder (colored background with subject-based color)
                    Container(
                      width: double.infinity,
                      color: _getSubjectColor(widget.course.subject ?? 'General'),
                      child: widget.course.imageUrl != null && widget.course.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.course.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 8),
                                    if (widget.course.subject != null && widget.course.subject!.isNotEmpty)
                                      Text(
                                        widget.course.subject!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 8),
                                    if (widget.course.subject != null && widget.course.subject!.isNotEmpty)
                                      Text(
                                        widget.course.subject!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 8),
                                  if (widget.course.subject != null && widget.course.subject!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        widget.course.subject!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                    
                    // Level badge at bottom with favorite icon
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.grey[800],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.course.level ?? 'All Levels',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _toggleFavorite(context),
                              child: Icon(
                                widget.course.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: widget.course.isFavorite ? Colors.red : Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject tag
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.course.subject ?? 'Web Development',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Course title
                      Expanded(
                        child: Text(
                          widget.course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      
                      // Subject category (optional)
                      Text(
                        widget.course.subject ?? 'Web Development',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Students count and price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Students: ${_formatNumber(widget.course.numSubscribers)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            widget.course.isPaid ? '\$${widget.course.price.toInt()}' : 'Free',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLevel(String? level) {
    if (level == null) return 'Beginner';
    // Remove 'Level' from the text if it exists
    return level.replaceAll(' Level', '');
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatSubscriberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'web development':
        return Icons.web_rounded;
      case 'mobile development':
        return Icons.smartphone_rounded;
      case 'data science':
        return Icons.analytics_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'finance':
        return Icons.attach_money_rounded;
      case 'design':
        return Icons.design_services_rounded;
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Color _getSubjectColor(String subject) {
    // Implement your logic to determine a color based on the subject
    // For example, you can use a switch statement or a map to associate subjects with colors
    final lowerSubject = subject.toLowerCase().trim();
    
    if (lowerSubject.contains('web development')) {
      return Colors.teal;
    } else if (lowerSubject.contains('mobile development')) {
      return Colors.purple;
    } else if (lowerSubject.contains('data science')) {
      return Colors.orange;
    } else if (lowerSubject.contains('business')) {
      return Colors.blue;
    } else if (lowerSubject.contains('finance')) {
      return Colors.green;
    } else if (lowerSubject.contains('design') || lowerSubject.contains('graphic')) {
      return Colors.pink;
    } else if (lowerSubject.contains('photography')) {
      return Colors.brown;
    } else if (lowerSubject.contains('music')) {
      return Colors.indigo;
    } else if (lowerSubject.contains('marketing')) {
      return Colors.red;
    } else if (lowerSubject.contains('programming') || lowerSubject.contains('python')) {
      return Colors.blueGrey;
    } else if (lowerSubject.contains('machine learning') || lowerSubject.contains('ai')) {
      return Colors.deepPurple;
    } else if (lowerSubject.contains('health')) {
      return Colors.lightGreen;
    } else if (lowerSubject.contains('language')) {
      return Colors.amber;
    } else if (lowerSubject.contains('art')) {
      return Colors.deepOrange;
    }
    
    // Generate a color based on the first letter of the subject if no match
    if (subject.isNotEmpty) {
      final int asciiValue = subject.codeUnitAt(0);
      return Colors.primaries[asciiValue % Colors.primaries.length];
    }
    
    return Colors.grey;
  }
} 
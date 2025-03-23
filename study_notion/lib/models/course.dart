class Course {
  final String id;
  final String title;
  final String url;
  final bool isPaid;
  final double price;
  final int numSubscribers;
  final int numReviews;
  final int numLectures;
  final String? level;
  final String? contentDuration;
  final String? publishedTimestamp;
  final String? subject;
  final String? cleanTitle;
  final String? imageUrl;
  final double? userRating;
  final bool isFavorite;

  Course({
    required this.id,
    required this.title,
    required this.url,
    required this.isPaid,
    required this.price,
    required this.numSubscribers,
    required this.numReviews,
    required this.numLectures,
    this.level,
    this.contentDuration,
    this.publishedTimestamp,
    this.subject,
    this.cleanTitle,
    this.imageUrl,
    this.userRating,
    this.isFavorite = false,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    try {
      print('Creating Course from JSON: ${json['course_title'] ?? json['title']}');
      
      // Handle the case where isPaid might be a string "TRUE" instead of a boolean
      bool convertIsPaid(dynamic value) {
        if (value is bool) {
          return value;
        } else if (value is String) {
          return value.toLowerCase() == 'true';
        }
        return false;
      }

      // Safe parsing for numeric values
      double parsePrice(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          try {
            return double.parse(value);
          } catch (e) {
            return 0.0;
          }
        }
        return 0.0;
      }

      int parseInteger(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            return 0;
          }
        }
        return 0;
      }

      // Get id from either course_id or id field
      String courseId = '';
      if (json.containsKey('course_id')) {
        courseId = json['course_id']?.toString() ?? '';
      } else if (json.containsKey('id')) {
        courseId = json['id']?.toString() ?? '';
      }

      // Get title from either course_title or title field
      String title = '';
      if (json.containsKey('course_title')) {
        title = json['course_title']?.toString() ?? '';
      } else if (json.containsKey('title')) {
        title = json['title']?.toString() ?? '';
      }
      
      print('Processing course: ID=$courseId, Title=$title');

      // Create the course object with safe values
      return Course(
        id: courseId,
        title: title,
        url: json['url']?.toString() ?? '',
        isPaid: convertIsPaid(json['is_paid']),
        price: parsePrice(json['price']),
        numSubscribers: parseInteger(json['num_subscribers']),
        numReviews: parseInteger(json['num_reviews']),
        numLectures: parseInteger(json['num_lectures']),
        level: json['level']?.toString() ?? 'All Levels',
        contentDuration: json['content_duration']?.toString(),
        publishedTimestamp: json['published_timestamp']?.toString(),
        subject: json['subject']?.toString() ?? 'General',
        cleanTitle: json['Clean_title']?.toString() ?? json['clean_title']?.toString(),
        imageUrl: json['image_url']?.toString() ?? '',
        userRating: parsePrice(json['user_rating']),
        isFavorite: json['is_favorite'] == true,
      );
    } catch (e) {
      print('Error creating Course from JSON: $e');
      print('Problematic JSON: $json');
      
      // Return a minimal valid course object rather than throwing
      return Course(
        id: json['course_id']?.toString() ?? json['id']?.toString() ?? 'unknown',
        title: json['course_title']?.toString() ?? json['title']?.toString() ?? 'Unknown Course',
        url: json['url']?.toString() ?? '',
        isPaid: false,
        price: 0.0,
        numSubscribers: 0,
        numReviews: 0,
        numLectures: 0,
        subject: 'General',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'is_paid': isPaid,
      'price': price,
      'num_subscribers': numSubscribers,
      'num_reviews': numReviews,
      'num_lectures': numLectures,
      'level': level,
      'content_duration': contentDuration,
      'published_timestamp': publishedTimestamp,
      'subject': subject,
      'clean_title': cleanTitle,
      'image_url': imageUrl,
      'user_rating': userRating,
      'is_favorite': isFavorite,
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? url,
    bool? isPaid,
    double? price,
    int? numSubscribers,
    int? numReviews,
    int? numLectures,
    String? level,
    String? contentDuration,
    String? publishedTimestamp,
    String? subject,
    String? cleanTitle,
    String? imageUrl,
    double? userRating,
    bool? isFavorite,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      numSubscribers: numSubscribers ?? this.numSubscribers,
      numReviews: numReviews ?? this.numReviews,
      numLectures: numLectures ?? this.numLectures,
      level: level ?? this.level,
      contentDuration: contentDuration ?? this.contentDuration,
      publishedTimestamp: publishedTimestamp ?? this.publishedTimestamp,
      subject: subject ?? this.subject,
      cleanTitle: cleanTitle ?? this.cleanTitle,
      imageUrl: imageUrl ?? this.imageUrl,
      userRating: userRating ?? this.userRating,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
} 
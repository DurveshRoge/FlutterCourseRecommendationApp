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
    // Handle the case where isPaid might be a string "TRUE" instead of a boolean
    bool convertIsPaid(dynamic value) {
      if (value is bool) {
        return value;
      } else if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return false;
    }

    return Course(
      id: json['course_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['course_title'] ?? json['title'] ?? '',
      url: json['url'] ?? '',
      isPaid: convertIsPaid(json['is_paid']),
      price: (json['price'] != null) ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      numSubscribers: json['num_subscribers'] is String 
          ? int.tryParse(json['num_subscribers']) ?? 0 
          : json['num_subscribers'] ?? 0,
      numReviews: json['num_reviews'] is String 
          ? int.tryParse(json['num_reviews']) ?? 0 
          : json['num_reviews'] ?? 0,
      numLectures: json['num_lectures'] is String 
          ? int.tryParse(json['num_lectures']) ?? 0 
          : json['num_lectures'] ?? 0,
      level: json['level'] ?? 'All Levels',
      contentDuration: json['content_duration'],
      publishedTimestamp: json['published_timestamp'],
      subject: json['subject'] ?? 'General',
      cleanTitle: json['Clean_title'] ?? json['clean_title'],
      imageUrl: json['image_url'],
      userRating: json['user_rating']?.toDouble() ?? 0.0,
      isFavorite: json['is_favorite'] ?? false,
    );
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
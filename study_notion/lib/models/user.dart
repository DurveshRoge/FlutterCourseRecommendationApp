class User {
  final String id;
  final String name;
  final String email;
  final List<String> favorites;
  final List<String> preferredTopics;
  final String skillLevel;
  final String courseType;
  final String preferredDuration;
  final String popularityImportance;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.favorites = const [],
    this.preferredTopics = const [],
    this.skillLevel = '',
    this.courseType = '',
    this.preferredDuration = '',
    this.popularityImportance = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] != null ? json['_id']['\$oid'] ?? json['_id'] : '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      favorites: json['favorites'] != null 
          ? List<String>.from(json['favorites'])
          : [],
      preferredTopics: json['preferred_topics'] != null 
          ? List<String>.from(json['preferred_topics'])
          : [],
      skillLevel: json['skill_level'] ?? '',
      courseType: json['course_type'] ?? '',
      preferredDuration: json['preferred_duration'] ?? '',
      popularityImportance: json['popularity_importance'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'favorites': favorites,
      'preferred_topics': preferredTopics,
      'skill_level': skillLevel,
      'course_type': courseType,
      'preferred_duration': preferredDuration,
      'popularity_importance': popularityImportance,
    };
  }
} 
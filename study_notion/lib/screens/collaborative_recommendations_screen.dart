import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_notion/bloc/course_bloc.dart';
import 'package:study_notion/models/course.dart';
import 'package:study_notion/widgets/course_card.dart';

class CollaborativeRecommendationsScreen extends StatefulWidget {
  const CollaborativeRecommendationsScreen({Key? key}) : super(key: key);

  @override
  _CollaborativeRecommendationsScreenState createState() => _CollaborativeRecommendationsScreenState();
}

class _CollaborativeRecommendationsScreenState extends State<CollaborativeRecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load collaborative filtering recommendations when the screen is initialized
    context.read<CourseBloc>().add(LoadCollaborativeFilteringRecommendations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17252A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF17252A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline, color: Color(0xFF3AAFA9), size: 24),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Courses Users Like You Enjoyed',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    context.read<CourseBloc>().add(LoadCollaborativeFilteringRecommendations());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<CourseBloc, CourseState>(
        builder: (context, state) {
          if (state is CollaborativeRecommendationsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AAFA9)),
              ),
            );
          } else if (state is CollaborativeRecommendationsLoaded) {
            if (state.recommendations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No Similar Users Found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Interact with more courses to get recommendations based on similar users',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AAFA9),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/search'),
                      child: const Text(
                        'Explore Courses',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: state.recommendations.length,
              itemBuilder: (context, index) {
                return CourseCard(
                  course: state.recommendations[index],
                  onFavoriteToggled: (courseId, isFavorite) {
                    context.read<CourseBloc>().add(ToggleFavorite(courseId));
                  },
                );
              },
            );
          } else if (state is CollaborativeRecommendationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3AAFA9),
                    ),
                    onPressed: () {
                      context.read<CourseBloc>().add(LoadCollaborativeFilteringRecommendations());
                    },
                    child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AAFA9)),
            ),
          );
        },
      ),
    );
  }
} 
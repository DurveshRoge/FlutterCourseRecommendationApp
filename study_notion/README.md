# StudyNotion - Flutter App

A Flutter mobile application that provides course recommendations based on user preferences. This app connects to a Flask backend that implements a machine learning recommendation system.

## Features

- **Course Search**: Search for courses by title and get personalized recommendations
- **Course Details**: View detailed information about each course including price, level, and subscriber count
- **Dashboard**: Visualize course distribution by subject, level, and popularity
- **External Links**: Open course pages directly in the original course platform website/app

## Screenshots

(Screenshots will be added after the app is built)

## Architecture

This app follows a clean architecture approach with:

- **BLoC Pattern**: For state management
- **Repository Pattern**: For data access
- **Service Layer**: For API communication

## Technologies Used

- **Flutter**: UI framework
- **flutter_bloc**: State management
- **dio**: HTTP client
- **fl_chart**: Data visualization
- **cached_network_image**: Image caching
- **url_launcher**: External URL handling

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Android Studio / VS Code
- A running instance of the Flask backend

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Update the API endpoint in `lib/services/api_service.dart` to point to your Flask backend
5. Run the app with `flutter run`

### Connecting to the Backend

By default, the app connects to `http://10.0.2.2:5000` for Android emulators, which points to localhost on your development machine. Update this URL to match your Flask backend deployment.

## Backend Integration

This Flutter app is designed to work with the Udemy Course Recommendation System Flask backend. The backend provides:

- Course recommendations based on title similarity
- Dashboard analytics data
- Course metadata

## Future Improvements

- User authentication and personalized recommendations
- Course bookmarking and history
- Offline support
- Advanced filtering options
- Dark mode support

## License

This project is licensed under the MIT License - see the LICENSE file for details.

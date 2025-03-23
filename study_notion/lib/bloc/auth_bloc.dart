import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_notion/models/user.dart';
import 'package:study_notion/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:study_notion/providers/user_provider.dart';
import 'package:flutter/material.dart'; // Import for BuildContext

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class RegisterUser extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final BuildContext? context;

  RegisterUser({
    required this.name,
    required this.email,
    required this.password,
    this.context,
  });

  @override
  List<Object> get props => [name, email, password];
}

class LoginUser extends AuthEvent {
  final String email;
  final String password;
  final BuildContext? context;

  LoginUser({
    required this.email,
    required this.password,
    this.context,
  });

  @override
  List<Object> get props => [email, password];
}

class CheckAuthStatus extends AuthEvent {}

class LogoutUser extends AuthEvent {
  final BuildContext? context;
  
  LogoutUser({this.context});
  
  @override
  List<Object> get props => [];
}

class RefreshUserData extends AuthEvent {
  final User user;

  RefreshUserData(this.user);

  @override
  List<Object> get props => [user];
}

class UpdateUserPreferences extends AuthEvent {
  final BuildContext context;

  UpdateUserPreferences({required this.context});

  @override
  List<Object> get props => [context];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  Authenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;

  AuthBloc({required this.apiService}) : super(AuthInitial()) {
    on<RegisterUser>(_onRegisterUser);
    on<LoginUser>(_onLoginUser);
    on<LogoutUser>(_onLogoutUser);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<UpdateUserPreferences>(_onUpdateUserPreferences);
  }

  Future<void> _onRegisterUser(
    RegisterUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await apiService.registerUser(
        event.name,
        event.email,
        event.password,
      );
      
      if (user != null) {
        // Update the UserProvider
        if (event.context != null) {
          Provider.of<UserProvider>(event.context!, listen: false).setCurrentUser(user);
        }
        
        emit(Authenticated(user: user));
      } else {
        emit(AuthError(message: 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLoginUser(
    LoginUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await apiService.loginUser(
        event.email,
        event.password,
      );
      
      if (user != null) {
        // Save login state to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        
        // Update the UserProvider
        if (event.context != null) {
          Provider.of<UserProvider>(event.context!, listen: false).setCurrentUser(user);
        }
        
        emit(Authenticated(user: user));
      } else {
        emit(AuthError(message: 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutUser(
    LogoutUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await apiService.logout();
      
      // Clear the UserProvider
      if (event.context != null) {
        Provider.of<UserProvider>(event.context!, listen: false).clearCurrentUser();
      }
      
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Check if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      if (isLoggedIn) {
        try {
          final user = await apiService.getCurrentUser();
          if (user != null) {
            emit(Authenticated(user: user));
            return;
          }
        } catch (e) {
          print('Error getting current user: $e');
          // Clear auth status if user retrieval fails
          await prefs.setBool('isLoggedIn', false);
        }
      }
      
      // If we reach here, user is not authenticated
      emit(Unauthenticated());
    } catch (e) {
      print('Error checking auth status: $e');
      emit(Unauthenticated());
    }
  }

  void _onUpdateUserPreferences(
    UpdateUserPreferences event,
    Emitter<AuthState> emit,
  ) {
    // Implementation of _onUpdateUserPreferences method
  }
} 
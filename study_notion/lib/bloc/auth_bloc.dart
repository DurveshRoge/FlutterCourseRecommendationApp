import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_notion/models/user.dart';
import 'package:study_notion/services/api_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class RegisterUser extends AuthEvent {
  final String name;
  final String email;
  final String password;

  RegisterUser({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [name, email, password];
}

class LoginUser extends AuthEvent {
  final String email;
  final String password;

  LoginUser({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class CheckAuthStatus extends AuthEvent {}

class LogoutUser extends AuthEvent {}

class RefreshUserData extends AuthEvent {
  final User user;

  RefreshUserData(this.user);

  @override
  List<Object> get props => [user];
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

  Authenticated(this.user);

  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;

  AuthBloc({required this.apiService}) : super(AuthInitial()) {
    on<RegisterUser>(_onRegisterUser);
    on<LoginUser>(_onLoginUser);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LogoutUser>(_onLogoutUser);
    on<RefreshUserData>(_onRefreshUserData);
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
        // Save auth status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        
        emit(Authenticated(user));
      } else {
        emit(AuthError('Registration failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
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
        // Save auth status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        
        emit(Authenticated(user));
      } else {
        emit(AuthError('Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
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
        final user = await apiService.getCurrentUser();
        if (user != null) {
          emit(Authenticated(user));
        } else {
          // Clear auth status if user not found
          await prefs.setBool('isLoggedIn', false);
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutUser(
    LogoutUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final success = await apiService.logout();
      
      // Clear auth status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onRefreshUserData(
    RefreshUserData event,
    Emitter<AuthState> emit,
  ) {
    emit(Authenticated(event.user));
  }
} 
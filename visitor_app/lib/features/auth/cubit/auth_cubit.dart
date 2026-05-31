import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import '../data/user.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(AuthInitial());

  User? get currentUser => state is AuthSuccess ? (state as AuthSuccess).user : null;

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(username, password);
      emit(AuthSuccess(user));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Login failed. Check your credentials.';
      emit(AuthFailure(msg as String));
    } catch (_) {
      emit(const AuthFailure('An unexpected error occurred.'));
    }
  }

  void logout() => emit(AuthInitial());
}

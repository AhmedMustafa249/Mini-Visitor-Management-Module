import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/visitor_repository.dart';
import 'visitor_state.dart';

class VisitorCubit extends Cubit<VisitorState> {
  final VisitorRepository _repository;

  VisitorCubit({required VisitorRepository repository})
      : _repository = repository,
        super(VisitorInitial());

  Future<void> loadVisitors() async {
    emit(VisitorLoading());
    try {
      final visitors = await _repository.getVisitors();
      emit(VisitorLoaded(visitors));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load visitors.';
      emit(VisitorFailure(msg as String));
    } catch (_) {
      emit(const VisitorFailure('An unexpected error occurred.'));
    }
  }

  Future<void> loadVisitorDetail(String id) async {
    emit(VisitorLoading());
    try {
      final visitor = await _repository.getVisitorById(id);
      emit(VisitorDetailLoaded(visitor));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to load visitor details.';
      emit(VisitorFailure(msg as String));
    } catch (_) {
      emit(const VisitorFailure('An unexpected error occurred.'));
    }
  }

  Future<bool> addVisitor({
    required String name,
    required String mobile,
    required String visitDate,
  }) async {
    emit(VisitorAdding());
    try {
      await _repository.addVisitor(name: name, mobile: mobile, visitDate: visitDate);
      emit(VisitorAdded());
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to add visitor.';
      emit(VisitorFailure(msg as String));
      return false;
    } catch (_) {
      emit(const VisitorFailure('An unexpected error occurred.'));
      return false;
    }
  }
}

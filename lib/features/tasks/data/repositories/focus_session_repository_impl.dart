import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/data/datasources/focus_session_local_datasource.dart';
import 'package:task_flow/features/tasks/data/models/focus_session_model.dart';
import 'package:task_flow/features/tasks/domain/entities/focus_session_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/focus_session_repository.dart';

class FocusSessionRepositoryImpl implements FocusSessionRepository {
  final FocusSessionLocalDataSource _localDataSource;

  const FocusSessionRepositoryImpl({
    required FocusSessionLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Result<FocusSessionEntity, Failure>> saveFocusSession(
    FocusSessionEntity session,
  ) async {
    try {
      final model = FocusSessionModel.fromEntity(session);
      final saved = await _localDataSource.saveFocusSession(model);
      return Success(saved);
    } on LocalDatabaseException catch (e) {
      return Err(DatabaseFailure(message: e.message));
    } catch (e) {
      return Err(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FocusSessionEntity>, Failure>> getFocusSessions({
    String? taskId,
  }) async {
    try {
      final list = await _localDataSource.getFocusSessions(taskId: taskId);
      return Success(list);
    } on LocalDatabaseException catch (e) {
      return Err(DatabaseFailure(message: e.message));
    } catch (e) {
      return Err(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<FocusSessionEntity?, Failure>> getFocusSessionById(
    String id,
  ) async {
    try {
      final session = await _localDataSource.getFocusSessionById(id);
      return Success(session);
    } on LocalDatabaseException catch (e) {
      return Err(DatabaseFailure(message: e.message));
    } catch (e) {
      return Err(DatabaseFailure(message: e.toString()));
    }
  }
}

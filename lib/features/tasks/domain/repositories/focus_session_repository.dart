import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/focus_session_entity.dart';

abstract interface class FocusSessionRepository {
  Future<Result<FocusSessionEntity, Failure>> saveFocusSession(
    FocusSessionEntity session,
  );
  Future<Result<List<FocusSessionEntity>, Failure>> getFocusSessions({
    String? taskId,
  });
  Future<Result<FocusSessionEntity?, Failure>> getFocusSessionById(String id);
}

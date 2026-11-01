import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_flow/features/tasks/domain/usecases/transition_task_status_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late MockTaskRepository mockRepository;
  late TransitionTaskStatusUseCase useCase;

  final baseTime = DateTime.utc(2026, 10, 10, 12, 0);
  final transitionTime = DateTime.utc(2026, 10, 10, 15, 0);

  setUpAll(() {
    registerFallbackValue(FakeTaskEntity());
  });

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = TransitionTaskStatusUseCase(mockRepository);
  });

  test(
      'should persist and return updated TaskEntity when state transition is valid',
      () async {
    final initialTask = (TaskEntity.create(
      id: 'task-1',
      title: 'Implement Domain Layer',
      status: TaskStatus.todo,
      createdAt: baseTime,
    ) as Success<TaskEntity, DomainFailure>)
        .value;

    when(() => mockRepository.getTaskById('task-1'))
        .thenAnswer((_) async => Success(initialTask));
    when(() => mockRepository.saveTask(any())).thenAnswer(
      (invocation) async =>
          Success(invocation.positionalArguments.first as TaskEntity),
    );

    final result = await useCase(
      TransitionTaskStatusParams(
        taskId: 'task-1',
        targetStatus: TaskStatus.inProgress,
        timestamp: transitionTime,
      ),
    );

    expect(result.isSuccess, isTrue);
    final savedTask = (result as Success<TaskEntity, Failure>).value;
    expect(savedTask.status, TaskStatus.inProgress);
    expect(savedTask.updatedAt, transitionTime);

    verify(() => mockRepository.getTaskById('task-1')).called(1);
    verify(() => mockRepository.saveTask(savedTask)).called(1);
  });

  test(
      'should NOT call repository.saveTask and should return IncompleteSubTasksFailure when transitioning to Done with incomplete sub-tasks',
      () async {
    final incompleteSubTask = (SubTaskEntity.create(
      id: 'sub-1',
      title: 'Pending item',
      isCompleted: false,
    ) as Success<SubTaskEntity, DomainFailure>)
        .value;

    final initialTask = (TaskEntity.create(
      id: 'task-1',
      title: 'Implement Domain Layer',
      status: TaskStatus.inProgress,
      subTasks: [incompleteSubTask],
      createdAt: baseTime,
    ) as Success<TaskEntity, DomainFailure>)
        .value;

    when(() => mockRepository.getTaskById('task-1'))
        .thenAnswer((_) async => Success(initialTask));

    final result = await useCase(
      TransitionTaskStatusParams(
        taskId: 'task-1',
        targetStatus: TaskStatus.done,
        timestamp: transitionTime,
      ),
    );

    expect(result.isFailure, isTrue);
    expect(
      result,
      isA<Err<TaskEntity, Failure>>().having(
        (e) => e.failure,
        'failure',
        const IncompleteSubTasksFailure(remainingSubTasks: 1),
      ),
    );

    verify(() => mockRepository.getTaskById('task-1')).called(1);
    verifyNever(() => mockRepository.saveTask(any()));
  });
}

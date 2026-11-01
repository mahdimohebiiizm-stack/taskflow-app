import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

class FakeTaskModel extends Fake implements TaskModel {}

void main() {
  late MockTaskLocalDataSource mockDataSource;
  late TaskRepositoryImpl repository;

  final timestamp = DateTime.utc(2026, 10, 10, 12, 0);

  late TaskEntity sampleEntity;
  late TaskModel sampleModel;

  setUpAll(() {
    registerFallbackValue(FakeTaskModel());
  });

  setUp(() {
    mockDataSource = MockTaskLocalDataSource();
    repository = TaskRepositoryImpl(localDataSource: mockDataSource);

    sampleEntity = (TaskEntity.create(
      id: 'task-1',
      title: 'Verify Repository Error Containment',
      description: 'Zero exception leakage to Domain/Presentation',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      createdAt: timestamp,
    ) as Success<TaskEntity, DomainFailure>)
        .value;

    sampleModel = TaskModel.fromEntity(sampleEntity);
  });

  group('TaskRepositoryImpl — getTasks', () {
    test('should return Success(List<TaskEntity>) when datasource succeeds',
        () async {
      when(() => mockDataSource.getTasks(status: null))
          .thenAnswer((_) async => <TaskModel>[sampleModel]);

      final result = await repository.getTasks();

      expect(result.isSuccess, isTrue);
      final entities = (result as Success<List<TaskEntity>, Failure>).value;
      expect(entities, equals(<TaskEntity>[sampleEntity]));
      verify(() => mockDataSource.getTasks(status: null)).called(1);
    });

    test(
        'should trap LocalDatabaseException and return Err(DatabaseFailure) without throwing',
        () async {
      when(() => mockDataSource.getTasks(status: TaskStatus.todo)).thenThrow(
        const LocalDatabaseException(message: 'SQLite disk I/O error'),
      );

      final result = await repository.getTasks(status: TaskStatus.todo);

      expect(result.isFailure, isTrue);
      expect(
        result,
        equals(
          const Err<List<TaskEntity>, Failure>(
            DatabaseFailure(message: 'SQLite disk I/O error'),
          ),
        ),
      );
    });
  });

  group('TaskRepositoryImpl — getTaskById & saveTask & deleteTask', () {
    test(
        'should trap RecordNotFoundException on getTaskById and return Err(NotFoundFailure)',
        () async {
      when(() => mockDataSource.getTaskById('missing-id')).thenThrow(
        const RecordNotFoundException(
          recordId: 'missing-id',
          message: 'Task not found',
        ),
      );

      final result = await repository.getTaskById('missing-id');

      expect(result.isFailure, isTrue);
      expect(
        result,
        equals(
          const Err<TaskEntity, Failure>(
            NotFoundFailure(
              entityId: 'missing-id',
              message: 'Task not found',
            ),
          ),
        ),
      );
    });

    test('should map entity to model, persist via saveTask, and return entity',
        () async {
      when(() => mockDataSource.saveTask(sampleModel))
          .thenAnswer((_) async => sampleModel);

      final result = await repository.saveTask(sampleEntity);

      expect(result.isSuccess, isTrue);
      expect(
        (result as Success<TaskEntity, Failure>).value,
        equals(sampleEntity),
      );
      verify(() => mockDataSource.saveTask(sampleModel)).called(1);
    });

    test(
        'should trap unexpected runtime errors on deleteTask and convert to Err(DatabaseFailure)',
        () async {
      when(() => mockDataSource.deleteTask('task-1'))
          .thenThrow(StateError('Unexpected connection closed'));

      final result = await repository.deleteTask('task-1');

      expect(result.isFailure, isTrue);
      expect(
        result,
        isA<Err<void, Failure>>().having(
          (e) => e.failure,
          'failure',
          isA<DatabaseFailure>(),
        ),
      );
    });
  });
}

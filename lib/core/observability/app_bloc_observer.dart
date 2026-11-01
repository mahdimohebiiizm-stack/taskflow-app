import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Centralized observability hook for all BLoC instances.
/// Logs lifecycle events, incoming events, state transitions, and uncaught errors
/// without leaking sensitive payload internals in production.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    developer.log(
      'BLoC Created: ${bloc.runtimeType}',
      name: 'TaskFlow.BlocObserver',
    );
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    developer.log(
      'Event Dispatched in ${bloc.runtimeType}: ${event.runtimeType}',
      name: 'TaskFlow.BlocObserver',
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    developer.log(
      'Transition in ${bloc.runtimeType}: '
      '${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType} '
      '(via ${transition.event.runtimeType})',
      name: 'TaskFlow.BlocObserver',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    developer.log(
      'Error in ${bloc.runtimeType}: $error',
      name: 'TaskFlow.BlocObserver',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // SEVERE
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    developer.log(
      'BLoC Closed: ${bloc.runtimeType}',
      name: 'TaskFlow.BlocObserver',
    );
    super.onClose(bloc);
  }
}

/// Stream-based Ticker driving the isolated FocusTimerBloc engine.
class Ticker {
  const Ticker();

  /// Emits remaining ticks decremented every second.
  Stream<int> tick({required int ticks}) {
    return Stream.periodic(const Duration(seconds: 1), (x) => ticks - x - 1)
        .take(ticks);
  }
}

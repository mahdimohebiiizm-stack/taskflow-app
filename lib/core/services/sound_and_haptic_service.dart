import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Semantic types of micro-interaction sound effects supported across TaskFlow.
enum SoundEffectType {
  /// Short, crisp pop/ding sound when a task is completed (+XP/Rials).
  taskCompleted,

  /// Celebratory fanfare sound when leveling up or reaching 100% daily progress.
  dailyVictory,

  /// Gentle, calming bell chime when a Pomodoro deep-work session completes.
  pomodoroCompleted,

  /// Subtle mechanical click/tick for interactive controls (theme switch, chips).
  softTick,

  /// Low-frequency buzz for overdue deductions, errors, or penalty alerts.
  errorBuzz,
}

/// Service orchestrating tactile haptic feedback (`HapticFeedback`) and production
/// audio feedback (`AudioPlayer` with physical asset loading and programmatic PCM WAV fallback).
///
/// Designed with graceful degradation: if physical audio asset files (`assets/sounds/*.mp3`)
/// are not present in the bundle or platform audio channels are unavailable, it falls back
/// to synthesized PCM buffers and haptics without throwing or crashing.
class SoundAndHapticService {
  static final SoundAndHapticService instance = SoundAndHapticService._internal();

  SoundAndHapticService._internal();

  static const String assetPathSuccessChime = 'sounds/success_chime.mp3';
  static const String assetPathLevelUpFanfare = 'sounds/level_up_fanfare.mp3';
  static const String assetPathSoftTick = 'sounds/soft_tick.mp3';
  static const String assetPathErrorBuzz = 'sounds/error_buzz.mp3';
  static const String assetPathPomodoroChime = 'sounds/pomodoro_chime.mp3';

  AudioPlayer? _player;
  int _taskCompletionPlayCount = 0;
  int _dailyVictoryPlayCount = 0;
  int _levelUpFanfarePlayCount = 0;
  int _softTickPlayCount = 0;
  int _errorBuzzPlayCount = 0;
  int _pomodoroCompletionPlayCount = 0;
  bool _isPreloaded = false;
  SoundEffectType? _lastPlayedSound;

  Uint8List? _cachedPopDingWavBytes;
  Uint8List? _cachedVictorySuccessWavBytes;
  Uint8List? _cachedPomodoroChimeWavBytes;
  Uint8List? _cachedSoftTickWavBytes;
  Uint8List? _cachedErrorBuzzWavBytes;

  /// Optional test hook for intercepting `BytesSource` playback in unit/widget tests.
  Future<void> Function(BytesSource source, SoundEffectType type)?
      onPlayBytesSource;

  int get taskCompletionPlayCount => _taskCompletionPlayCount;
  int get dailyVictoryPlayCount => _dailyVictoryPlayCount;
  int get levelUpFanfarePlayCount => _levelUpFanfarePlayCount;
  int get softTickPlayCount => _softTickPlayCount;
  int get errorBuzzPlayCount => _errorBuzzPlayCount;
  int get pomodoroCompletionPlayCount => _pomodoroCompletionPlayCount;
  bool get isPreloaded => _isPreloaded;
  SoundEffectType? get lastPlayedSound => _lastPlayedSound;

  Uint8List get _popDingWavBytes =>
      _cachedPopDingWavBytes ??= generatePopDingWav();
  Uint8List get _victorySuccessWavBytes =>
      _cachedVictorySuccessWavBytes ??= generateVictorySuccessWav();
  Uint8List get _pomodoroChimeWavBytes =>
      _cachedPomodoroChimeWavBytes ??= generatePomodoroGentleChimeWav();
  Uint8List get _softTickWavBytes =>
      _cachedSoftTickWavBytes ??= generateSoftTickWav();
  Uint8List get _errorBuzzWavBytes =>
      _cachedErrorBuzzWavBytes ??= generateErrorBuzzWav();

  /// Pre-synthesizes and caches all fallback audio WAV buffers concurrently using `Future.wait`
  /// (and `Isolate.run` when [useIsolate] is enabled) so startup and playback never block the UI thread.
  Future<void> preloadAudioBuffers({bool useIsolate = false}) async {
    if (_isPreloaded &&
        _cachedPopDingWavBytes != null &&
        _cachedVictorySuccessWavBytes != null &&
        _cachedPomodoroChimeWavBytes != null &&
        _cachedSoftTickWavBytes != null &&
        _cachedErrorBuzzWavBytes != null) {
      return;
    }

    if (useIsolate) {
      final buffers = await Future.wait<Uint8List>([
        Isolate.run(generatePopDingWav),
        Isolate.run(generateVictorySuccessWav),
        Isolate.run(generatePomodoroGentleChimeWav),
        Isolate.run(generateSoftTickWav),
        Isolate.run(generateErrorBuzzWav),
      ]);
      _cachedPopDingWavBytes = buffers[0];
      _cachedVictorySuccessWavBytes = buffers[1];
      _cachedPomodoroChimeWavBytes = buffers[2];
      _cachedSoftTickWavBytes = buffers[3];
      _cachedErrorBuzzWavBytes = buffers[4];
    } else {
      final buffers = await Future.wait<Uint8List>([
        Future<Uint8List>.microtask(generatePopDingWav),
        Future<Uint8List>.microtask(generateVictorySuccessWav),
        Future<Uint8List>.microtask(generatePomodoroGentleChimeWav),
        Future<Uint8List>.microtask(generateSoftTickWav),
        Future<Uint8List>.microtask(generateErrorBuzzWav),
      ]);
      _cachedPopDingWavBytes = buffers[0];
      _cachedVictorySuccessWavBytes = buffers[1];
      _cachedPomodoroChimeWavBytes = buffers[2];
      _cachedSoftTickWavBytes = buffers[3];
      _cachedErrorBuzzWavBytes = buffers[4];
    }
    _isPreloaded = true;
  }

  /// Resets telemetry counters (useful for deterministic testing).
  void resetStats() {
    _taskCompletionPlayCount = 0;
    _dailyVictoryPlayCount = 0;
    _levelUpFanfarePlayCount = 0;
    _softTickPlayCount = 0;
    _errorBuzzPlayCount = 0;
    _pomodoroCompletionPlayCount = 0;
    _lastPlayedSound = null;
  }

  /// Disposes the underlying audio player to prevent memory leaks.
  Future<void> dispose() async {
    try {
      await _player?.stop();
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  // ===========================================================================
  // Semantic Sound Triggers (Enterprise Audio API)
  // ===========================================================================

  /// Plays a crisp, satisfying chime for task completion (+XP/Rials).
  Future<void> playSuccessChime() async {
    _taskCompletionPlayCount += 1;
    _lastPlayedSound = SoundEffectType.taskCompleted;

    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}

    await _playSoundWithFallback(
      assetPath: assetPathSuccessChime,
      fallbackWavBytes: _popDingWavBytes,
      type: SoundEffectType.taskCompleted,
      volume: 0.8,
    );
  }

  /// Plays a triumphant celebratory fanfare upon leveling up.
  Future<void> playLevelUpFanfare() async {
    _dailyVictoryPlayCount += 1;
    _levelUpFanfarePlayCount += 1;
    _lastPlayedSound = SoundEffectType.dailyVictory;

    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    await _playSoundWithFallback(
      assetPath: assetPathLevelUpFanfare,
      fallbackWavBytes: _victorySuccessWavBytes,
      type: SoundEffectType.dailyVictory,
      volume: 0.9,
    );
  }

  /// Plays a subtle mechanical click/tick for micro-interactions (e.g. changing themes).
  Future<void> playSoftTick() async {
    _softTickPlayCount += 1;
    _lastPlayedSound = SoundEffectType.softTick;

    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}

    await _playSoundWithFallback(
      assetPath: assetPathSoftTick,
      fallbackWavBytes: _softTickWavBytes,
      type: SoundEffectType.softTick,
      volume: 0.5,
    );
  }

  /// Plays a low-frequency alert buzz when an overdue penalty or deduction occurs.
  Future<void> playErrorBuzz() async {
    _errorBuzzPlayCount += 1;
    _lastPlayedSound = SoundEffectType.errorBuzz;

    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    await _playSoundWithFallback(
      assetPath: assetPathErrorBuzz,
      fallbackWavBytes: _errorBuzzWavBytes,
      type: SoundEffectType.errorBuzz,
      volume: 0.75,
    );
  }

  // ===========================================================================
  // Backward-Compatible Facade Methods
  // ===========================================================================

  /// Alias for [playSuccessChime] preserving backward compatibility with existing tests.
  Future<void> playTaskCompletionFeedback() => playSuccessChime();

  /// Alias for [playLevelUpFanfare] preserving backward compatibility with existing tests.
  Future<void> playDailyVictoryFeedback() => playLevelUpFanfare();

  /// Triggers gentle haptic feedback and plays a soft, calming bell chime
  /// when a Pomodoro focus timer reaches 00:00.
  Future<void> playPomodoroCompletedFeedback() async {
    _pomodoroCompletionPlayCount += 1;
    _lastPlayedSound = SoundEffectType.pomodoroCompleted;

    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    await _playSoundWithFallback(
      assetPath: assetPathPomodoroChime,
      fallbackWavBytes: _pomodoroChimeWavBytes,
      type: SoundEffectType.pomodoroCompleted,
      volume: 0.75,
    );
  }

  // ===========================================================================
  // Internal Playback & Fallback Pipeline
  // ===========================================================================

  Future<void> _playSoundWithFallback({
    required String assetPath,
    required Uint8List fallbackWavBytes,
    required SoundEffectType type,
    double volume = 0.75,
  }) async {
    final fallbackSource = BytesSource(fallbackWavBytes);

    if (onPlayBytesSource != null) {
      await onPlayBytesSource!(fallbackSource, type);
      return;
    }

    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return;
      }
    } catch (_) {}

    try {
      final player = _player ??= AudioPlayer();
      await player.stop();

      // Attempt physical asset first; gracefully degrade to synthesized WAV if missing.
      try {
        await player.play(AssetSource(assetPath), volume: volume);
      } catch (assetErr) {
        debugPrint(
          '[SoundAndHapticService] Audio asset "$assetPath" unavailable ($assetErr). '
          'Falling back to synthesized PCM sound.',
        );
        await player.play(fallbackSource, volume: volume);
      }
    } catch (e) {
      debugPrint('[SoundAndHapticService] Audio playback skipped: $e');
    }
  }

  // ===========================================================================
  // Programmatic PCM WAV Synthesizers (Graceful Offline Synthesis)
  // ===========================================================================

  /// Generates a 16-bit mono PCM WAV buffer for a crisp, pleasant "Pop/Ding" chime (~110ms).
  static Uint8List generatePopDingWav({int sampleRate = 22050}) {
    const durationSeconds = 0.11;
    final numSamples = (sampleRate * durationSeconds).round();
    final samples = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final envelope = math.exp(-t * 28.0);
      // Pleasant dual-tone chime (A5 880Hz + E6 1318.5Hz)
      final wave = 0.65 * math.sin(2.0 * math.pi * 880.0 * t) +
          0.35 * math.sin(2.0 * math.pi * 1318.5 * t);
      final sampleValue = (wave * envelope * 24000).round().clamp(-32768, 32767);
      samples[i] = sampleValue;
    }

    return _encodePcm16MonoWav(samples, sampleRate: sampleRate);
  }

  /// Generates a 16-bit mono PCM WAV buffer for a celebratory "Victory/Success" arpeggio (~360ms).
  static Uint8List generateVictorySuccessWav({int sampleRate = 22050}) {
    const notes = <double>[523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
    const noteDuration = 0.09;
    final samplesPerNote = (sampleRate * noteDuration).round();
    final totalSamples = samplesPerNote * notes.length;
    final samples = Int16List(totalSamples);

    for (var n = 0; n < notes.length; n++) {
      final freq = notes[n];
      final startIdx = n * samplesPerNote;
      for (var i = 0; i < samplesPerNote; i++) {
        final localT = i / sampleRate;
        final envelope = math.exp(-localT * 14.0);
        final wave = 0.7 * math.sin(2.0 * math.pi * freq * localT) +
            0.3 * math.sin(2.0 * math.pi * (freq * 2.0) * localT);
        final sampleValue =
            (wave * envelope * 24000).round().clamp(-32768, 32767);
        samples[startIdx + i] = sampleValue;
      }
    }

    return _encodePcm16MonoWav(samples, sampleRate: sampleRate);
  }

  /// Generates a 16-bit mono PCM WAV buffer for a gentle, calming Pomodoro completion bell (~280ms).
  static Uint8List generatePomodoroGentleChimeWav({int sampleRate = 22050}) {
    const notes = <double>[587.33, 880.00]; // D5 -> A5 gentle fifth harmonic
    const noteDuration = 0.14;
    final samplesPerNote = (sampleRate * noteDuration).round();
    final totalSamples = samplesPerNote * notes.length;
    final samples = Int16List(totalSamples);

    for (var n = 0; n < notes.length; n++) {
      final freq = notes[n];
      final startIdx = n * samplesPerNote;
      for (var i = 0; i < samplesPerNote; i++) {
        final localT = i / sampleRate;
        final envelope = math.exp(-localT * 10.0);
        final wave = 0.75 * math.sin(2.0 * math.pi * freq * localT) +
            0.25 * math.sin(2.0 * math.pi * (freq * 1.5) * localT);
        final sampleValue =
            (wave * envelope * 20000).round().clamp(-32768, 32767);
        samples[startIdx + i] = sampleValue;
      }
    }

    return _encodePcm16MonoWav(samples, sampleRate: sampleRate);
  }

  /// Generates a 16-bit mono PCM WAV buffer for a subtle, high-frequency mechanical tick (~35ms).
  static Uint8List generateSoftTickWav({int sampleRate = 22050}) {
    const durationSeconds = 0.035;
    final numSamples = (sampleRate * durationSeconds).round();
    final samples = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final envelope = math.exp(-t * 90.0);
      final wave = math.sin(2.0 * math.pi * 1600.0 * t);
      final sampleValue = (wave * envelope * 16000).round().clamp(-32768, 32767);
      samples[i] = sampleValue;
    }

    return _encodePcm16MonoWav(samples, sampleRate: sampleRate);
  }

  /// Generates a 16-bit mono PCM WAV buffer for a low-frequency alert buzz (~160ms).
  static Uint8List generateErrorBuzzWav({int sampleRate = 22050}) {
    const durationSeconds = 0.16;
    final numSamples = (sampleRate * durationSeconds).round();
    final samples = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final envelope = math.exp(-t * 12.0);
      final wave = 0.65 * math.sin(2.0 * math.pi * 130.0 * t) +
          0.35 * math.sin(2.0 * math.pi * 195.0 * t);
      final sampleValue = (wave * envelope * 20000).round().clamp(-32768, 32767);
      samples[i] = sampleValue;
    }

    return _encodePcm16MonoWav(samples, sampleRate: sampleRate);
  }

  static Uint8List _encodePcm16MonoWav(
    Int16List pcmSamples, {
    required int sampleRate,
  }) {
    final dataByteLength = pcmSamples.length * 2;
    final totalFileLength = 44 + dataByteLength;
    final byteData = ByteData(totalFileLength);

    // RIFF header
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, 36 + dataByteLength, Endian.little);
    byteData.setUint8(8, 0x57); // 'W'
    byteData.setUint8(9, 0x41); // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // PCM chunk size
    byteData.setUint16(20, 1, Endian.little); // AudioFormat = 1 (PCM)
    byteData.setUint16(22, 1, Endian.little); // NumChannels = 1 (Mono)
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little); // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample = 16

    // data subchunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, dataByteLength, Endian.little);

    for (var i = 0; i < pcmSamples.length; i++) {
      byteData.setInt16(44 + i * 2, pcmSamples[i], Endian.little);
    }

    return byteData.buffer.asUint8List();
  }
}

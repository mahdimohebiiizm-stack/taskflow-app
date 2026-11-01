# Sound Assets Directory

Place production audio files (`.mp3` or `.wav`) here:
- `success_chime.mp3`: Played on task completion (+ XP/Rials)
- `level_up_fanfare.mp3`: Played upon leveling up
- `soft_tick.mp3`: Played on micro-interactions (e.g., theme toggle)
- `error_buzz.mp3`: Played on overdue penalty deduction

Note: `SoundAndHapticService` automatically falls back to programmatic PCM WAV audio synthesis and haptic feedback when physical asset files are missing.

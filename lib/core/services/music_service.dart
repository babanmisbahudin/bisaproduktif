import 'package:just_audio/just_audio.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();

  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;

  // Produktif music URLs (YouTube audio links)
  // Ini adalah link ke YouTube video yang bisa digunakan untuk ekstrak audio
  static const Map<String, String> productiveMusic = {
    'focus': 'https://www.youtube.com/watch?v=R1r9nLYcqBU', // User's YouTube link
    'studying': 'https://www.youtube.com/watch?v=jAHSR3IruN0', // Lo-fi hip hop
    'relaxing': 'https://www.youtube.com/watch?v=IUvlvwXtJrg', // Piano music
  };

  MusicService._internal();

  factory MusicService() {
    return _instance;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    _audioPlayer = AudioPlayer();
    _isInitialized = true;
  }

  /// Play produktif music
  /// Note: Direct YouTube URLs require additional setup.
  /// For production, consider using youtube_explode or downloading audio files.
  Future<void> playFocusMusic() async {
    try {
      await _audioPlayer.setLoopMode(LoopMode.one);
      // For now, we'll use a placeholder. In production:
      // 1. Use youtube_explode to extract audio URL
      // 2. Or host audio files separately
      // 3. Or use embedded audio assets
    } catch (e) {
      // Silently handle music playback errors
    }
  }

  /// Stop music completely
  Future<void> stopMusic() async {
    await _audioPlayer.stop();
  }
}

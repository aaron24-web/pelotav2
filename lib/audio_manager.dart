import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  static AudioManager get instance => _instance;

  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  String? _currentMusic;

  Future<void> playMenuMusic() async {
    if (_currentMusic == 'fondo.mp3') return;
    await _backgroundMusicPlayer.stop();
    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundMusicPlayer.play(AssetSource('audio/fondo.mp3'));
    _currentMusic = 'fondo.mp3';
  }

  Future<void> playBossMusic() async {
    if (_currentMusic == 'bossfight_theme.mp3') return;
    await _backgroundMusicPlayer.stop();
    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundMusicPlayer.play(AssetSource('audio/bossfight_theme.mp3'));
    _currentMusic = 'bossfight_theme.mp3';
  }

  Future<void> playWinBossMusic() async {
    await _backgroundMusicPlayer.stop();
    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.release);
    await _backgroundMusicPlayer.play(AssetSource('audio/win_boss.mp3'));
    _currentMusic = 'win_boss.mp3';
  }

  Future<void> playGameOverBossMusic() async {
    await _backgroundMusicPlayer.stop();
    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.release);
    await _backgroundMusicPlayer.play(AssetSource('audio/gameover_boss.mp3'));
    _currentMusic = 'gameover_boss.mp3';
  }

  Future<void> playWinNormalMusic() async {
    await _backgroundMusicPlayer.stop();
    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.release);
    await _backgroundMusicPlayer.play(AssetSource('audio/win.mp3'));
    _currentMusic = 'win.mp3';
  }

  Future<void> playGameOverNormalMusic() async {
    await _backgroundMusicPlayer.stop();
    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.release);
    await _backgroundMusicPlayer.play(AssetSource('audio/game_over.mp3'));
    _currentMusic = 'game_over.mp3';
  }

  Future<void> playNormalBackgroundMusic() async {
    if (_currentMusic == 'normal_background.mp3') return;
    await _backgroundMusicPlayer.stop();
    await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundMusicPlayer
        .play(AssetSource('audio/normal_background.mp3'));
    _currentMusic = 'normal_background.mp3';
  }

  Future<void> stopMusic() async {
    await _backgroundMusicPlayer.stop();
    _currentMusic = null;
  }
}

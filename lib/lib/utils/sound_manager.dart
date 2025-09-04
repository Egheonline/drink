import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundManager {
  static final AudioPlayer _audioPlayer = AudioPlayer(
    playerId: 'preview_player',
  );

  // Play preview from bundled assets (no 'assets/' prefix needed)
  static Future<void> playPreview(String assetFileName) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource(assetFileName));
      await _audioPlayer.resume();
    } catch (e) {
      print('Error playing asset preview: $e');
    }
  }

  // Pick and save a custom sound file
  static Future<String?> pickAndSaveCustomSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg'],
    );

    if (result != null && result.files.single.path != null) {
      final originalPath = result.files.single.path!;
      final fileName = result.files.single.name;

      final appDir = await getApplicationDocumentsDirectory();
      final newFile = File('${appDir.path}/$fileName');

      // Copy selected file to app's internal directory
      await File(originalPath).copy(newFile.path);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customSoundPath', newFile.path);

      return 'Custom';
    }

    return null;
  }

  // Get saved custom sound path
  static Future<String?> getCustomSoundPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customSoundPath');
  }

  // Stop currently playing audio
  static Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // Play based on sound name
  static Future<void> playSelected(String soundName) async {
    const previewAssets = {
      'Water': 'water.mp3',
      'Bell': 'bell.mp3',
      'Chime': 'chime.mp3',
    };

    try {
      await _audioPlayer.stop();

      if (soundName == 'Custom') {
        final path = await getCustomSoundPath();
        if (path != null && File(path).existsSync()) {
          await _audioPlayer.setSource(DeviceFileSource(path));
          await _audioPlayer.resume();
        } else {
          print('Custom sound file not found at $path');
        }
      } else if (previewAssets.containsKey(soundName)) {
        await _audioPlayer.setSource(AssetSource(previewAssets[soundName]!));
        await _audioPlayer.resume();
      }
    } catch (e) {
      print('Error playing sound "$soundName": $e');
    }
  }
}

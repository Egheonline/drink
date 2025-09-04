import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maps sound names to their corresponding asset paths
final Map<String, String> assetSounds = {
  'Bell': 'assets/bell.mp3',
  'Chime': 'assets/chime.mp3',
  'Water': 'assets/water.mp3',
  // Add more sound name/path pairs as needed
};

class SoundManager {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Plays a short preview of the selected asset sound (e.g., 'assets/bell.mp3')
  static Future<void> playPreview(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');
      await tempFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      print('Error playing preview: $e');
    }
  }

  /// Lets the user pick a custom sound from device and saves it internally
  static Future<String?> pickAndSaveCustomSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final savedFile = await pickedFile.copy(
        '${appDir.path}/${pickedFile.uri.pathSegments.last}',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customSoundPath', savedFile.path);
      await prefs.setString('notificationChannel', 'hydration_custom');
      await prefs.setString('selectedSound', 'Custom');

      return 'Custom';
    }

    return null;
  }

  /// Loads the custom sound path (if any)
  static Future<String?> getCustomSoundPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customSoundPath');
  }

  /// Stops the current sound and plays the selected sound
  static Future<void> playSelectedSound(String sound) async {
    await _audioPlayer.stop();

    if (sound == 'Custom') {
      final path = await getCustomSoundPath();
      if (path != null && File(path).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(path));
      } else {
        print('Custom sound file not found');
      }
    } else if (assetSounds.containsKey(sound)) {
      await playPreview(assetSounds[sound]!);
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/system_data.dart';

class StorageEngine {
  static const String _fileName = 'progresso_state.json';

  // Find the safest place to save data on Linux, Windows, or Android
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    // Creates a dedicated folder just like you had before
    final systemDir = Directory('$path/ProgressoSystem');
    if (!await systemDir.exists()) {
      await systemDir.create(recursive: true);
    }
    return File('${systemDir.path}/$_fileName');
  }

  // The Vault: Save Data
  Future<void> saveState(SystemData data) async {
    try {
      final file = await _localFile;
      final jsonString = jsonEncode(data.toJson());
      await file.writeAsString(jsonString);
      print("SYSTEM LOG: State safely secured in the Vault.");
    } catch (e) {
      print("SYSTEM ERROR: Failed to write state: $e");
    }
  }

  // The Vault: Load Data
  Future<SystemData> loadState() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        print("SYSTEM LOG: No existing data found. Initializing clean slate.");
        return SystemData(); // Return empty system data
      }
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString);
      print("SYSTEM LOG: Data successfully extracted from the Vault.");
      return SystemData.fromJson(jsonMap);
    } catch (e) {
      print("SYSTEM ERROR: Failed to read state: $e");
      return SystemData(); // Fallback to safe empty state
    }
  }
}
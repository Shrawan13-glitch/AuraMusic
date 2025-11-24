import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/update_model.dart';

class UpdateService {
  static const _versionUrl = 'https://shrawan13-glitch.github.io/AuraMusic-updates/version.json';
  final Dio _dio = Dio();

  Future<UpdateModel?> checkForUpdate() async {
    try {
      final response = await _dio.get(_versionUrl);
      final update = UpdateModel.fromJson(response.data);
      final info = await PackageInfo.fromPlatform();
      
      if (_isNewerVersion(info.version, update.latestVersion)) {
        return update;
      }
    } catch (e) {
      print('Update check error: $e');
    }
    return null;
  }

  bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  Future<String> downloadUpdate(String url, Function(int, int) onProgress) async {
    final dir = await getExternalStorageDirectory();
    final filePath = '${dir!.path}/aura_music_update.apk';
    
    await _dio.download(
      url,
      filePath,
      onReceiveProgress: onProgress,
    );
    
    return filePath;
  }
}

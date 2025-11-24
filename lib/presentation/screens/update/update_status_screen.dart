import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import '../../../data/models/update_model.dart';
import '../../providers/update_provider.dart';

class UpdateStatusScreen extends ConsumerStatefulWidget {
  final UpdateModel update;

  const UpdateStatusScreen({super.key, required this.update});

  @override
  ConsumerState<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends ConsumerState<UpdateStatusScreen> {
  double _progress = 0.0;
  int _downloaded = 0;
  int _total = 0;
  String _status = 'Requesting permissions...';
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _startUpdate();
  }

  Future<void> _startUpdate() async {
    if (!await _requestPermissions()) {
      setState(() => _status = 'Permissions denied');
      return;
    }

    setState(() {
      _status = 'Downloading update...';
      _isDownloading = true;
    });

    try {
      final service = ref.read(updateServiceProvider);
      final filePath = await service.downloadUpdate(
        widget.update.downloadUrl,
        (received, total) {
          setState(() {
            _downloaded = received;
            _total = total;
            _progress = received / total;
          });
        },
      );

      setState(() => _status = 'Installing...');
      await OpenFile.open(filePath);
    } catch (e) {
      setState(() {
        _status = 'Download failed';
        _isDownloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to download update. Please check your internet connection or try again later.'),
            action: SnackBarAction(label: 'Retry', onPressed: _startUpdate),
          ),
        );
      }
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.requestInstallPackages.request();
      
      if (await Permission.manageExternalStorage.isDenied) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
      }
      
      return true;
    }
    return true;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.download, size: 80, color: Color(0xFF8B5CF6)),
                ),
                const SizedBox(height: 32),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (_isDownloading) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.grey[800],
                          color: const Color(0xFF8B5CF6),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${(_progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                        ),
                        const SizedBox(height: 8),
                        if (_total > 0)
                          Text(
                            '${_formatBytes(_downloaded)} / ${_formatBytes(_total)}',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                if (!_isDownloading)
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go to Home', style: TextStyle(fontSize: 16, color: Color(0xFF8B5CF6))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

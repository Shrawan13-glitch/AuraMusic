import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/settings_provider.dart';
import '../../providers/update_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking for updates...'), duration: Duration(seconds: 2)),
    );

    final update = await ref.read(updateServiceProvider).checkForUpdate();

    if (update != null && context.mounted) {
      context.push('/update-available', extra: update);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the latest version')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Playback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
          ),
          SwitchListTile(
            title: const Text('Autoplay'),
            subtitle: const Text('Automatically play next song when current ends'),
            value: settings.autoplay,
            activeTrackColor: const Color(0xFF8B5CF6),
            onChanged: (value) => ref.read(settingsProvider.notifier).setAutoplay(value),
          ),
          ListTile(
            title: const Text('Audio Quality'),
            subtitle: Text(settings.audioQuality),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Audio Quality'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['High', 'Medium', 'Low'].map((quality) {
                      return ListTile(
                        title: Text(quality),
                        leading: Radio<String>(
                          value: quality,
                          groupValue: settings.audioQuality,
                          activeColor: const Color(0xFF8B5CF6),
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(settingsProvider.notifier).setAudioQuality(value);
                              Navigator.pop(context);
                            }
                          },
                        ),
                        onTap: () {
                          ref.read(settingsProvider.notifier).setAudioQuality(quality);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Storage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
          ),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text('Remove temporary files'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Cache'),
                  content: const Text('This will remove all temporary files. Continue?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared')),
                        );
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
          ),
          ListTile(
            title: const Text('Version'),
            subtitle: Text(_version),
            trailing: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Aura Music',
                applicationVersion: _version,
                applicationIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.music_note, size: 32, color: Colors.white),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Check for Updates'),
            trailing: const Icon(Icons.system_update),
            onTap: () => _checkForUpdates(context, ref),
          ),
        ],
      ),
    );
  }
}

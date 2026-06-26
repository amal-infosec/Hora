import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/settings_provider.dart';
import '../../widgets/glass_container.dart';
import '../../core/app_themes.dart';
import '../../core/db_helper.dart';
import 'about_screen.dart';
import '../reports/reports_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isCheckingUpdates = false;
  String _updateStatus = '';
  final String _localVersion = '1.0.1+2'; // Matches pubspec.yaml version

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _nameController.text = settings.doctorName;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto(SettingsProvider settings) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        await settings.setProfilePhotoPath(result.files.single.path!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking photo: $e')),
        );
      }
    }
  }

  Future<void> _checkAppUpdates() async {
    setState(() {
      _isCheckingUpdates = true;
      _updateStatus = 'Checking for updates...';
    });

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      // Fetches remote pubspec to check remote version
      final request = await client.getUrl(Uri.parse(
          'https://raw.githubusercontent.com/amal-infosec/Hora/main/pubspec.yaml'));
      final response = await request.close();

      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final lines = content.split('\n');
        String remoteVersion = '';
        for (var line in lines) {
          if (line.trim().startsWith('version:')) {
            remoteVersion = line.split(':').last.trim();
            break;
          }
        }

        if (remoteVersion.isNotEmpty) {
          if (remoteVersion == _localVersion) {
            setState(() {
              _updateStatus = 'App is up to date (v${_localVersion.split("+").first}).';
            });
          } else {
            setState(() {
              _updateStatus =
                  'Update available: v${remoteVersion.split("+").first} is available.\nPlease download the latest release files to update.';
            });
          }
        } else {
          setState(() {
            _updateStatus = 'Could not parse version info.';
          });
        }
      } else {
        setState(() {
          _updateStatus = 'Failed to connect (Status: ${response.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _updateStatus = 'Error checking updates: $e\nEnsure device has internet connection.';
      });
    } finally {
      setState(() {
        _isCheckingUpdates = false;
      });
    }
  }

  Future<void> _toggleOverlayPermission(bool enable, SettingsProvider settings) async {
    if (enable) {
      try {
        bool? hasPermission = await SystemAlertWindow.checkPermissions(prefMode: SystemWindowPrefMode.OVERLAY);
        if (hasPermission != true) {
          await SystemAlertWindow.requestPermissions(prefMode: SystemWindowPrefMode.OVERLAY);
          hasPermission = await SystemAlertWindow.checkPermissions(prefMode: SystemWindowPrefMode.OVERLAY);
        }
        await settings.setEnableOverlayAlerts(hasPermission == true);
        if (hasPermission != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Overlay permission denied by user.')),
            );
          }
        }
      } catch (e) {
        await settings.setEnableOverlayAlerts(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Device security blocks overlay draw permissions: $e')),
          );
        }
      }
    } else {
      await settings.setEnableOverlayAlerts(false);
    }
  }

  void _showClearDataConfirmation(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all logged patients, vitals, shifts, reminders, tasks, and reset personalization settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context); // Close dialog
              
              // 1. Clear SQLite tables
              await DatabaseHelper().clearAllData();
              
              // 2. Clear SharedPreferences
              await settings.clearSettings();
              
              messenger.showSnackBar(
                const SnackBar(content: Text('All data cleared successfully.')),
              );
            },
            child: const Text('Delete Everything', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final isDark = themeProvider.themeMode == ThemeModeType.dark;

    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final chipTextColor = isDark ? Colors.white : Colors.black87;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        // 1. Profile & Personalization Section
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isEditingName ? Icons.check_circle_outline : Icons.edit_note,
                      color: isDark ? const Color(0xFF60A5FA) : Colors.black87,
                      size: 28,
                    ),
                    onPressed: () async {
                      if (_isEditingName) {
                        if (_nameController.text.trim().isNotEmpty) {
                          await settings.setDoctorName(_nameController.text.trim());
                        }
                      }
                      setState(() {
                        _isEditingName = !_isEditingName;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Profile Photo Uploader
              GestureDetector(
                onTap: () => _pickProfilePhoto(settings),
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: settings.profilePhotoPath.isNotEmpty && File(settings.profilePhotoPath).existsSync()
                            ? Image.file(
                                File(settings.profilePhotoPath),
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              if (_isEditingName)
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Doctor Name',
                    labelStyle: TextStyle(color: subtitleColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                Text(
                  settings.doctorName.isNotEmpty ? 'Dr. ${settings.doctorName}' : 'Set Name',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              Text(
                'Clinical Duty Practitioner',
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. App Preferences Section
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Theme Toggle Choice
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Theme Mode',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text('Light', style: TextStyle(color: chipTextColor)),
                        selected: themeProvider.themeMode == ThemeModeType.minimalistic,
                        onSelected: (val) {
                          if (val) themeProvider.setTheme(ThemeModeType.minimalistic);
                        },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: Text('Dark', style: TextStyle(color: chipTextColor)),
                        selected: themeProvider.themeMode == ThemeModeType.dark,
                        onSelected: (val) {
                          if (val) themeProvider.setTheme(ThemeModeType.dark);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Permissions Switch
              SwitchListTile(
                title: Text(
                  'Draw Over Other Apps',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Enables overlay warnings on top of other apps.',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
                value: settings.enableOverlayAlerts,
                activeThumbColor: isDark ? const Color(0xFF60A5FA) : Colors.black,
                onChanged: (val) => _toggleOverlayPermission(val, settings),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.amber.withOpacity(0.08) : Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: isDark ? Colors.amberAccent : Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keep disabled if your device blocks overlay draw permissions. Standard notifications will still alert.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.amber[200] : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Support & Info Section
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System & Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Check Updates Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Version',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                      Text(
                        'v${_localVersion.split("+").first}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _isCheckingUpdates ? null : _checkAppUpdates,
                    icon: _isCheckingUpdates
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_alt, size: 18),
                    label: const Text('Check for Updates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF3B82F6) : Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              if (_updateStatus.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _updateStatus,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      if (_updateStatus.startsWith('Update available')) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final Uri uri = Uri.parse('https://github.com/amal-infosec/Hora/releases');
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download,
                                size: 16,
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Download from GitHub',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const Divider(height: 32),
              
              // Clinical Reports Navigation
              ListTile(
                leading: Icon(Icons.assignment_outlined, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
                title: Text(
                  'Clinical Reports',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'View total active hours, logs, and activity reports',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                trailing: Icon(Icons.chevron_right, color: subtitleColor),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportsScreen()),
                  );
                },
              ),
              const Divider(height: 32),
              
              // About App Navigation
              ListTile(
                leading: Icon(Icons.info_outline, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
                title: Text(
                  'About App',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Credits, developer Amal & copyright information',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                trailing: Icon(Icons.chevron_right, color: subtitleColor),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4. Data Management / Reset Section
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Permanently reset all logged patients, vitals, shifts, reminders, and configuration.',
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showClearDataConfirmation(settings),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Reset Application Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

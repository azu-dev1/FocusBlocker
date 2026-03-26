import 'package:flutter/material.dart';
import 'package:focusblocker/screens/app_selection_screen.dart';
import 'package:focusblocker/screens/scheduling_screen.dart';
import 'package:focusblocker/screens/permissions_screen.dart';
import 'package:focusblocker/services/blocking_service.dart';
import 'package:focusblocker/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBlockingActive = false;
  List<String> _blockedApps = [];
  DateTime? _blockStartTime;
  DateTime? _blockEndTime;
  bool _strictMode = false;
  bool _accessibilityEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final isActive = await StorageService.isBlockingActive();
    final apps = await StorageService.getBlockedApps();
    final window = await StorageService.getBlockingWindow();
    final strict = await StorageService.getStrictMode();
    final a11yEnabled = await BlockingService.isAccessibilityServiceEnabled();

    setState(() {
      _isBlockingActive = isActive;
      _blockedApps = apps;
      _blockStartTime = window.$1;
      _blockEndTime = window.$2;
      _strictMode = strict;
      _accessibilityEnabled = a11yEnabled;
    });
  }

  Future<void> _startBlocking() async {
    if (_blockedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one app to block')),
      );
      return;
    }

    if (_blockStartTime == null || _blockEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set blocking time')),
      );
      return;
    }

    if (!_accessibilityEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable Accessibility Service')),
      );
      return;
    }

    final success = await BlockingService.startBlocking(
      packageNames: _blockedApps,
      startTime: _blockStartTime!,
      endTime: _blockEndTime!,
      strictMode: _strictMode,
    );

    if (success) {
      await StorageService.setBlockingActive(true);
      setState(() => _isBlockingActive = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blocking started successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start blocking')),
      );
    }
  }

  Future<void> _stopBlocking() async {
    final success = await BlockingService.stopBlocking();

    if (success) {
      await StorageService.setBlockingActive(false);
      setState(() => _isBlockingActive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blocking stopped')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusBlocker'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatus,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _isBlockingActive ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isBlockingActive ? 'Blocking Active' : 'Not Blocking',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Accessibility: ${_accessibilityEnabled ? 'Enabled ✓' : 'Disabled ✗'}',
                      style: TextStyle(
                        color: _accessibilityEnabled ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Apps Section
            Text(
              'Blocked Apps',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _blockedApps.isEmpty
                ? const Text(
                    'No apps selected',
                    style: TextStyle(color: Colors.grey),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _blockedApps
                        .map(
                          (app) => Chip(
                            label: Text(app),
                            onDeleted: () {
                              setState(() => _blockedApps.remove(app));
                              StorageService.saveBlockedApps(_blockedApps);
                            },
                          ),
                        )
                        .toList(),
                  ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final selected = await Navigator.push<List<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppSelectionScreen(
                      selectedApps: _blockedApps,
                    ),
                  ),
                );
                if (selected != null) {
                  setState(() => _blockedApps = selected);
                  await StorageService.saveBlockedApps(selected);
                }
              },
              icon: const Icon(Icons.apps),
              label: const Text('Select Apps'),
            ),
            const SizedBox(height: 24),

            // Time Section
            Text(
              'Blocking Schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<Map<String, DateTime>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchedulingScreen(
                      startTime: _blockStartTime,
                      endTime: _blockEndTime,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _blockStartTime = result['startTime'];
                    _blockEndTime = result['endTime'];
                  });
                  await StorageService.saveBlockingWindow(
                    _blockStartTime!,
                    _blockEndTime!,
                  );
                }
              },
              icon: const Icon(Icons.schedule),
              label: const Text('Configure Time'),
            ),
            if (_blockStartTime != null && _blockEndTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'From: ${_blockStartTime!.hour}:${_blockStartTime!.minute.toString().padLeft(2, '0')} - To: ${_blockEndTime!.hour}:${_blockEndTime!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Strict Mode
            CheckboxListTile(
              title: const Text('Strict Mode'),
              subtitle: const Text('Cannot disable blocking until timer ends'),
              value: _strictMode,
              onChanged: (value) {
                setState(() => _strictMode = value ?? false);
                StorageService.setStrictMode(_strictMode);
              },
            ),
            const SizedBox(height: 24),

            // Permissions Section
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PermissionsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.security),
              label: const Text('Permissions'),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (!_isBlockingActive)
              ElevatedButton(
                onPressed: _startBlocking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Start Blocking',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              )
            else
              ElevatedButton(
                onPressed: _strictMode ? null : _stopBlocking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _strictMode ? 'Blocking (Strict Mode - Cannot Stop)' : 'Stop Blocking',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

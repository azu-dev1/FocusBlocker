import 'package:flutter/material.dart';
import 'package:focusblocker/services/blocking_service.dart';

class AppSelectionScreen extends StatefulWidget {
  final List<String> selectedApps;

  const AppSelectionScreen({
    Key? key,
    required this.selectedApps,
  }) : super(key: key);

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  late List<String> _selectedApps;
  late Future<List<AppInfo>> _appsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedApps = List.from(widget.selectedApps);
    _appsFuture = BlockingService.getInstalledApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps to Block'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedApps);
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AppInfo>>(
              future: _appsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No apps found'),
                  );
                }

                var apps = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  apps = apps
                      .where((app) =>
                          app.appName.toLowerCase().contains(_searchQuery) ||
                          app.packageName
                              .toLowerCase()
                              .contains(_searchQuery))
                      .toList();
                }

                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    final isSelected = _selectedApps.contains(app.packageName);

                    return CheckboxListTile(
                      title: Text(app.appName),
                      subtitle: Text(
                        app.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _selectedApps.add(app.packageName);
                          } else {
                            _selectedApps.remove(app.packageName);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

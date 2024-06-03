import 'dart:convert';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';

class AppsPage extends StatefulWidget {
  @override
  _AppsPageState createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (context, ref, _) {
        final appsInfo = ref.watch(appsProvider);
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            actionsIconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.primary),
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.primary),
            backgroundColor: Colors.transparent,
            title: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'search apps..',
                      border: UnderlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "home");
                    },
                    icon: Icon(Icons.home_filled))
              ],
            ),
            actions: [],
          ),
          body: PopScope(
            canPop: false,
            child: appsInfo.when(
              data: (List<Application> apps) {
                final filteredApps = apps.where((app) => app.appName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()));
                return ListView.builder(
                  itemCount: filteredApps.length,
                  itemBuilder: (BuildContext context, int index) {
                    ApplicationWithIcon app =
                        filteredApps.elementAt(index) as ApplicationWithIcon;

                    final brightness =
                        MediaQuery.of(context).platformBrightness;
                    bool isDarkMode = brightness == Brightness.dark;
                    return ListTile(
                      leading: Image.memory(
                        app.icon,
                        width: 40,
                      ),
                      title: Text(
                        app.appName,
                        style: TextStyle(
                            color: isDarkMode == true
                                ? Colors.white
                                : Colors.black),
                      ),
                      onTap: () {
                        final List<ApplicationWithIcon> selectedApps =
                            ref.read(selectedAppsProvider);
                        if (selectedApps.contains(app)) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("App already added!"),
                                content: Text(
                                    "You have already added app into your Home Page..."),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      stopKioskMode();
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("Yes"),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Add to your Launcher App?"),
                                content: Text(
                                    "Do you want to add this to your launcher app?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      final List<ApplicationWithIcon>
                                          selectedApps = ref
                                              .read(
                                                  selectedAppsProvider.notifier)
                                              .state;
                                      selectedApps.add(app);
                                      ref
                                          .read(selectedAppsProvider.notifier)
                                          .state = selectedApps;
                                      saveSelectedApp(selectedApps);
                                      Navigator.pushNamed(context, "home");
                                    },
                                    child: Text("Yes"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("No"),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      // DeviceApps.openApp(app.packageName),
                    );
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.blue,
                  strokeAlign: 2.0,
                  strokeWidth: 1.0,
                ),
              ),
              error: (e, s) => Container(),
            ),
          ),
        );
      },
    );
  }

  Future<void> saveSelectedApp(List<ApplicationWithIcon> applications) async {
    final prefs = await SharedPreferences.getInstance();
    final applicationJson = jsonEncode(
      applications.map((map) => map.packageName).toList(),
    );
    await prefs.setString("selectedApplications", applicationJson);
  }

  @override
  bool get wantKeepAlive => true;
}

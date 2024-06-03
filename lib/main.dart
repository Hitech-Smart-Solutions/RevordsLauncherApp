import 'dart:async';
import 'package:device_apps/device_apps.dart';
import 'package:fl_live_launcher/apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    startKioskMode();
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Launcher',
        darkTheme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                switch (settings.name) {
                  case "apps":
                    return AppsPage();
                  case "home":
                    return HomePage();
                  default:
                    return AppsPage();
                }
              });
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'exit') {
                _showPinDialog(context, doExit: true);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'exit',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app),
                      SizedBox(width: 5),
                      Text('Exit')
                    ],
                  ),
                )
              ];
            },
            icon: Icon(Icons.more_vert),
          )
        ],
      ),
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: false,
        child: Consumer(
          builder: (
            context,
            ref,
            _,
          ) {
            final selectedApplication =
                ref.watch(selectedAppsProvider.notifier).state;
            return selectedApplication.isNotEmpty
                ? GridView.builder(
                    itemCount: selectedApplication.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6, childAspectRatio: 1.0),
                    itemBuilder: (BuildContext context, int index) {
                      final application = selectedApplication[index];
                      return GestureDetector(
                        onTap: () async {
                          loadSelectedApp();
                          await _showConfirmationDialog(context, application);
                        },
                        child: GridTile(
                          child: Column(
                            children: [
                              Image.memory(
                                application.icon,
                                width: 40,
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                application.appName,
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.start,
                              )
                            ],
                          ),
                        ),
                      );
                    })
                : Center(
                    child: Text('Apps will be display here... '),
                  );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Container(
          height: 70,
          child: Center(
            child: IconButton(
              icon: Icon(Icons.apps),
              color: Colors.amberAccent,
              onPressed: () => _showPinDialog(context, doExit: false),
            ),
          ),
        ),
      ),
    );
  }

// This Dialog will get the generate pin UI
  void _showPinDialog(BuildContext context, {required bool doExit}) {
    final TextEditingController pinController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Enter Pin'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    InputDecoration(labelText: '4-digit pin', counterText: ''),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Pin';
                  } else if (value.length != 4 || value.length == 0) {
                    return 'Please enter 4 digit Pin';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      if (pinController.text == '1234') {
                        Navigator.of(context).pop();
                        if (doExit) {
                          stopKioskMode()
                              .then((value) => SystemNavigator.pop());
                        }
                        Navigator.pushNamed(context, "apps");
                      }
                    }
                  },
                  child: Text('Submit')),
            ],
          );
        });
  }
}

// This Dialog will get the confirmation from the user to open the application....
Future<void> _showConfirmationDialog(
    BuildContext context, Application application) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Open Application"),
          content: Text("Are you Sure you want to open Application?"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("No")),
            TextButton(
                onPressed: () {
                  stopKioskMode()
                      .then((value) =>
                          {DeviceApps.openApp(application.packageName)})
                      .then((value) => {showMessageAlert(context)});

                  Navigator.of(context).pop();
                },
                child: Text("Yes"))
          ],
        );
      });
}

// This is to show the message for getting back KioskMode....
Future<void> showMessageAlert(BuildContext context) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Important!"),
          content: Text("We are going KioskMode again"),
          actions: [
            TextButton(
                onPressed: () {
                  startKioskMode();
                  Navigator.of(context).pop();
                },
                child: Text("Ok"))
          ],
        );
      });
}

// This function is will get the string from apps.dart where i am saving it to SharedPreferences...
Future<void> loadSelectedApp() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.getString("selectedApplications");
}

import 'package:accessiblecity/main.dart';
import 'package:accessiblecity/model/running_ride.dart';

import 'no_rides_pane.dart';
import 'rides_pane.dart';
import 'record_screen.dart';
import '../constants.dart';
import '../model/rides.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.appState});

  final MyAppState appState;

  @override
  State<MainScreen> createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {

  void _startRecording(BuildContext context) {
    Provider.of<Rides>(context, listen: false).startRide().then((ok) {
      if ((context.mounted) && (!ok)) {
        showAdaptiveDialog(context: context, builder: startRideFailedAlert);
      }
    });

  }
  @override
  Widget build(BuildContext context) {
    RunningRide? currentRide = Provider.of<Rides>(context).currentRide;
    if (currentRide != null) {
      return RecordScreen(ride: currentRide);
    }
    bool havePastRide = (Provider.of<Rides>(context).pastRides.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.yourRides),
        actions: [
          IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: Constants.aboutTheProject,
              onPressed: () { widget.appState.gotoPage("info"); }
          ),
          IconButton(
              icon: const Icon(Icons.settings),
              tooltip: Constants.settings,
              onPressed: () { widget.appState.gotoPage("settings"); }
          ),
        ],
      ),
      body: Center(
        child: havePastRide ? const RidesPane() : const NoRidesPane(),
      ),
      bottomNavigationBar: BottomAppBar(
        child: OutlinedButton.icon(
          onPressed: (){
            _startRecording(context);
          },
          label: const Text(Constants.startRecording),
          icon: const Icon(Icons.radio_button_checked),
        ),
      ),
    );
  }
}

Widget startRideFailedAlert(BuildContext context) {
  return AlertDialog.adaptive(
      title: const Text("Aufzeichnung fehlgeschlagen"),
      content: const Text("Bitte aktiviere Standortdienste und setze die Berechtigung dieser App auf 'immer erlauben'"),
      actions: <Widget>[
        TextButton(
            child: const Text('Einstellungen...'),
            onPressed: (){
              final ctx = Navigator.of(context);
              AppSettings.openAppSettings(type: AppSettingsType.location).then((_) {
                ctx.pop();
              });
            }
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: (){
            Navigator.of(context).pop();
          },
        ),
      ]
  );
}
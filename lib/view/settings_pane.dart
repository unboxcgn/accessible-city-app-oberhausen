import '../model/user.dart';
import '../enums.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPane extends StatelessWidget {
  const SettingsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
              padding: EdgeInsets.only(
                  top: 30, left: 10, right: 10, bottom: 10),
              child: Text("Standard-Rollstuhltyp:")),
          Padding(
              padding: const EdgeInsets.all(10),
              child: DropdownButton<int>(
                  value: Provider.of<User>(context).defaultVehicleType,
                  onChanged: (int? val) {
                    if (val != null) {
                      Provider.of<User>(context, listen: false)
                          .defaultVehicleType = val;
                    }
                  },
                  items: VehicleType.values.map((VehicleType t) {
                    return DropdownMenuItem<int>(
                        value: t.value, child: Text(t.label));
                  }).toList())),
          const Padding(
              padding: EdgeInsets.only(
                  top: 30, left: 10, right: 10, bottom: 10),
              child: Text("Standardposition Handy:")),
          Padding(
            padding: const EdgeInsets.all(10),
            child: DropdownButton<int>(
                  value: Provider.of<User>(context).defaultMountType,
                  onChanged: (int? val) {
                    if (val != null) {
                      Provider.of<User>(context, listen: false).defaultMountType =
                          val;
                    }
                  },
                  items: MountType.values.map((MountType t) {
                    return DropdownMenuItem<int>(
                        value: t.value, child: Text(t.label));
                  }).toList()),
             ),
          const Padding(
              padding: EdgeInsets.only(
                  top: 30, left: 10, right: 10, bottom: 10),
              child: Text("Standard-Wegetyp:")),
          Padding(
            padding: const EdgeInsets.all(10),
            child: DropdownButton<int>(
                value: Provider.of<User>(context).defaultRideType,
                onChanged: (int? val) {
                  if (val != null) {
                    Provider.of<User>(context, listen: false).defaultRideType =
                        val;
                  }
                },
                items: RideType.values.map((RideType t) {
                  return DropdownMenuItem<int>(
                      value: t.value, child: Text(t.label));
                }).toList()),
          ),
          const Padding(
              padding: EdgeInsets.only(
                  top: 30, left: 10, right: 10, bottom: 10),
              child: Text("Wegkommentar:"),
          ),
          Padding(
              padding: const EdgeInsets.only(
                  top: 30, left: 10, right: 10, bottom: 10),
              child: Text("(für Entwicklungszwecke, bitte leer lassen)",
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              initialValue: Provider.of<User>(context).rideComment,
              onChanged: (val) {
                Provider.of<User>(context, listen: false).rideComment = val;

              },

            ),
          ),

          /*        ElevatedButton(
              onPressed: () {
                Provider.of<User>(context, listen: false).reset();
                MapData().resetAssets();
                //TODO: Reset all rides
              },
              child: const Text('Einstellungen löschen')
            )
        */
        ],
      ),
    ); // This trailing comma makes auto-formatting nicer for build methods.
  }
}

import '../model/user.dart';
import '../enums.dart';
import '../constants.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(Constants.settings),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left:24, right:24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Standard-Fortbewegungsmittel:",
                              style: Theme.of(context).textTheme.bodySmall
                          ),
                          DropdownButton<int>(
                              isExpanded: true,
                              underline: Container(),
                              style: Theme.of(context).textTheme.bodyMedium,
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
                              }).toList()),
                        ],
                      ),
                    )
                ),
                Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Standardposition Handy:",
                              style: Theme.of(context).textTheme.bodySmall
                          ),
                          DropdownButton<int>(
                              isExpanded: true,
                              underline: Container(),
                              style: Theme.of(context).textTheme.bodyMedium,
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
                        ],
                      ),
                    )
                ),
                Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Standard-Wegetyp:",
                              style: Theme.of(context).textTheme.bodySmall
                          ),
                          DropdownButton<int>(
                              isExpanded: true,
                              underline: Container(),
                              style: Theme.of(context).textTheme.bodyMedium,
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
                        ],
                      ),
                    )
                ),
                Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Kommentar (für Entwicklungszwecke, sonst bitte leer lassen)",
                              style: Theme.of(context).textTheme.bodySmall
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
//                              border: OutlineInputBorder(),
                            ),
                            initialValue: Provider.of<User>(context).rideComment,
                            onChanged: (val) {
                              Provider.of<User>(context, listen: false).rideComment = val;
                            },
                          ),
                        ],
                      ),
                    ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

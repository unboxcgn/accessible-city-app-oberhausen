import '../logger.dart';
import '../model/rides.dart';
import '../model/finished_ride.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RidesPane extends StatelessWidget {
  const RidesPane({super.key});

  @override
  Widget build(BuildContext context) {
    List<FinishedRide> rides = Provider.of<Rides>(context).pastRides;
    int totalNumRides = rides.length;
    double totalDistanceM = 0;
    Duration duration = const Duration();
    for (FinishedRide ride in rides) {
      totalDistanceM += ride.totalDistanceM;
      duration += ride.recordingDuration;
    }
    double avgSpeed = 3600.0 * totalDistanceM / duration.inMilliseconds;

    return SingleChildScrollView(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Deine Statistik', style: Theme.of(context).textTheme.titleLarge),
        ),
        Table(
          border: const TableBorder(
              horizontalInside: BorderSide(width: 1, style: BorderStyle.solid),
              top: BorderSide(width: 1, style: BorderStyle.solid),
              bottom: BorderSide(width: 1, style: BorderStyle.solid)),
          columnWidths: const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
            1: IntrinsicColumnWidth(),
          },
          children:<TableRow>[
            TableRow(
                children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Aufgezeichnete Wege', style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.right),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('$totalNumRides', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ]
            ),
            TableRow(
                children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Strecke gesamt', style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.right,),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${NumberFormat.decimalPatternDigits(decimalDigits:1).format(totalDistanceM/1000)} km', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ]
            ),
            TableRow(
                children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Durchschnittsgeschwindigkeit', style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.right,),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${NumberFormat.decimalPatternDigits(decimalDigits:1).format(avgSpeed)} km/h', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ]
            ),
            TableRow(
                children:[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Zeit gesamt', style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.right,),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${duration.inHours}h ${duration.inMinutes.remainder(60).toString().padLeft(2,"0")}m ${duration.inSeconds.remainder(60).toString().padLeft(2,"0")}s', style: Theme.of(context).textTheme.bodyMedium),

                  ),
                ]
            ),
          ]
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Deine Fahrten', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: rides.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) => RideDigestView(rides[rides.length-index-1]),  //reverse!
//            separatorBuilder: (BuildContext context, int index) => const Divider(),
            physics: const NeverScrollableScrollPhysics(),
        ),
        const Padding(
          padding: EdgeInsets.only(top:90.0),
        )
      ],
    )
    ); // This trailing comma makes auto-formatting nicer for build methods.
  }
}

class RideDigestView extends StatelessWidget {
  final FinishedRide _ride;

  const RideDigestView(FinishedRide ride, {super.key}) : _ride = ride;

  @override Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final durH = _ride.recordingDuration.inHours.toString();
    final durM = twoDigits(_ride.recordingDuration.inMinutes.remainder(60).abs());
    final durS = twoDigits(_ride.recordingDuration.inSeconds.remainder(60).abs());
    final dur = '$durH:$durM:$durS';
    final title = (_ride.annotations.isNotEmpty) ? "${_ride.name} *" : _ride.name;
    return Card(
          child: Padding (
            padding: const EdgeInsetsGeometry.all(10),
              child: Column(
                  children: [
                    Row(
                      children:[
                        Expanded(
                          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                        ),
                        PopupMenuButton(
                          itemBuilder: _buildRideMenu,
                          child: const Icon(Icons.more_vert_sharp),
                        ),
                  ]),
                    Table(
                        border: const TableBorder(
                            horizontalInside: BorderSide(width: 1, style: BorderStyle.solid),
                            top: BorderSide(width: 1, style: BorderStyle.solid),
                        ),
                        children: <TableRow>[
                          TableRow(
                              children: [
                                Text("Datum", style: Theme.of(context).textTheme.labelLarge),
                                Text("Start", style: Theme.of(context).textTheme.labelLarge),
                                Text("Dauer", style: Theme.of(context).textTheme.labelLarge),
                                Text("Strecke", style: Theme.of(context).textTheme.labelLarge),
                                Text("Schnitt", style: Theme.of(context).textTheme.labelLarge),
                              ]
                          ),
                          TableRow(
                              children: [
                                Text(DateFormat('dd.MM.yy').format(_ride.startDate)),
                                Text(DateFormat('Hm').format(_ride.startDate)),
                                Text(dur),
                                Text("${NumberFormat.decimalPatternDigits(decimalDigits:1).format(_ride.totalDistanceM/1000)} km"),
                                Text("${NumberFormat.decimalPatternDigits(decimalDigits:1).format(_ride.averageSpeedKmh)} km/h"),
                              ]
                          ),
                        ]
                    ),
                  ]
              )
          )
    );


  }

  List<PopupMenuItem<void>> _buildRideMenu(BuildContext context) {
    logInfo("building context menu");
    List<PopupMenuItem<void>> list = [];
    if (_ride.syncAllowed) {
      list.add(PopupMenuItem(
        onTap: () {
          _ride.syncAllowed = false;
        },
        child: const Text("Fahrt nicht teilen"),
      ));
    } else {
      list.add(PopupMenuItem(
        onTap: () {
          _ride.syncAllowed = true;
        },
        child: const Text("Fahrt teilen"),
      ));
    }
    list.add(PopupMenuItem(
      onTap: () {
        Rides().deleteRide(_ride);
      },
      child: const Text("Fahrt löschen"),
    ));
    return list;
  }


}



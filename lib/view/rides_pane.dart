import 'package:accessiblecity/model/running_ride.dart';

import '../logger.dart';
import '../model/rides.dart';
import '../model/finished_ride.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


/* This is a little utility class for insert / remove tracking. AnimatedList
needs changes to be split up to individual indexed removals, inserts and moves.
This implementation does not import moves but assumes that everything can be done
through insert / remove. In our case, entries will remain sorted anyway, so this
does not happen. The implementation is designed to be fast when there are few
changes.
*/

class TypeWithIndex<T> {
  T entry;
  int index;
  TypeWithIndex(this.entry, this.index);
}

//typedef InsertRemoveFn = void Function(int idx, <T> elem);

class ListDiffer<T> {
  List<T> _current = [];

  List<T> get current => List<T>.from(_current);

  set current(List<T> list) {
    _current = List<T>.from(list);
  }

  ListDiffer();

  void update(List<T> newList, {required Function(int idx, T elem) onInsert, required Function(int idx, T elem) onRemove}) {
    Set<T> oldSet = Set<T>.from(_current);
    Set<T> newSet = Set<T>.from(newList);
    Set<T> removedSet = oldSet.difference(newSet); //this set is hopefully small
    Set<T> addedSet = newSet.difference(oldSet); //this set is hopefully small

    //convert removed elements to a list with respective old index and sort
    List<TypeWithIndex<T>> removedList = [];
    for (final entry in removedSet) {
      removedList.add(TypeWithIndex(entry, _current.indexOf(entry)));
    }
    //sort highest to lowest so that indexes fit when removing
    removedList.sort((a, b) => -1 * (a.index).compareTo(b.index));
    for (final entry in removedList) {
      onRemove(entry.index, entry.entry);
      _current.removeAt(entry.index);
    }
    //convert added elements to a list with respective new index and sort
    List<TypeWithIndex<T>> addedList = [];
    for (final entry in addedSet) {
      addedList.add(TypeWithIndex(entry, newList.indexOf(entry)));
    }
    //sort lowest to highest so that indexes fit when adding
    addedList.sort((a, b) => (a.index).compareTo(b.index));
    for (final entry in addedList) {
      onInsert(entry.index, entry.entry);
      _current.insert(entry.index, entry.entry);
    }
  }
}


class RidesPane extends StatefulWidget {

  const RidesPane({super.key});

  @override
  State<RidesPane> createState() => _RidesPaneState();
}

class _RidesPaneState extends State<RidesPane> {

  final ListDiffer<FinishedRide> _ridesDiffer = ListDiffer();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  @override initState () {
    super.initState();
    _ridesDiffer.current = Rides().pastRides;
  }

  @override
  Widget build(BuildContext context) {

    RunningRide? finishingRide = Provider.of<Rides>(context).finishingRide;
    List<FinishedRide> rides = Provider.of<Rides>(context).pastRides;

    _ridesDiffer.update(rides,
      onRemove: (idx, elem) {
        _listKey.currentState?.removeItem(idx,
            (BuildContext context, Animation<double> animation) {
              return _buildAnimatedRideDigest(elem, animation);
            },
            duration: const Duration(milliseconds: 500));

      },
      onInsert: (idx, elem) {
        _listKey.currentState?.insertItem(idx,
            duration: const Duration(milliseconds: 500));

      }
    );

    int numRides = rides.length;
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
                    child: Text('$numRides', style: Theme.of(context).textTheme.bodyMedium),
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
        if (finishingRide != null) const Center(child:CircularProgressIndicator()),
        AnimatedList(
          reverse: true,  ///TODO: CHECK **********
          key: _listKey,
          padding: const EdgeInsets.all(8),
          initialItemCount: numRides,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index, Animation<double> animation) {
            return _buildAnimatedRideDigest(rides[index], animation);
          },
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

  Widget _buildAnimatedRideDigest(FinishedRide ride, Animation<double> animation) {
    return ScaleTransition(
      scale: animation.drive(
        CurveTween(
          curve: Interval(0.5, 1.0, curve: Curves.ease)
        )),
      child: FadeTransition(
        opacity: animation.drive(
          CurveTween(
            curve: Interval(0.5, 1.0, curve: Curves.ease)
          )),
        child: RideDigestView(ride: ride)
      ),
    );
  }
}

class RideDigestView extends StatelessWidget {
  final FinishedRide _ride;

  const RideDigestView({super.key, required FinishedRide ride}) : _ride = ride;

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final durH = _ride.recordingDuration.inHours.toString();
    final durM = twoDigits(_ride.recordingDuration.inMinutes.remainder(60).abs());
    final durS = twoDigits(_ride.recordingDuration.inSeconds.remainder(60).abs());
    final dur = '$durH:$durM:$durS';
    final title = (_ride.annotations.isNotEmpty) ? "${_ride.name} *" : _ride.name;
    return Card(
      key: Key(_ride.uuid),
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
              ],
            ),
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
            if (_ride.snapshot != null) Image.memory(_ride.snapshot!),
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



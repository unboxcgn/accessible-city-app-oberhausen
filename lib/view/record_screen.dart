import 'dart:async';

import 'package:accessiblecity/enums.dart';
import 'package:accessiblecity/model/running_ride.dart';

import '../logger.dart';
import '../constants.dart';
import '../services/sensor_service.dart';
import '../model/rides.dart';
import '../model/map_data.dart';
import '../model/location.dart';
import '../model/annotation.dart' as ride_annotation;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';

class RecordScreen extends StatefulWidget {
  final RunningRide ride;

  const RecordScreen({super.key, required this.ride});

  @override
  State<RecordScreen> createState() => RecordScreenState();
}

class RecordScreenState extends State<RecordScreen> {

  final _controllerCompleter = Completer<MapLibreMapController>();
  final MapData _mapData = MapData();
  bool _trackUserLocation = true;
  UserLocation? _lastUserLocation;
  final List<LatLng> _routeSoFar = [];
  Line? _lineSoFar;

  @override
  void initState() {
    super.initState();
    widget.ride.addListener(_checkRideUpdate);
    SensorService().checkPermissions();
  }

  @override dispose() {
    widget.ride.removeListener(_checkRideUpdate);
    super.dispose();
  }

  _checkRideUpdate() async {
    logInfo("ride update");
    List<Location> locations = widget.ride.locations;
    while(_routeSoFar.length < locations.length) {
      Location loc = locations[_routeSoFar.length];
      _routeSoFar.add(LatLng(loc.latitude, loc.longitude));
    }
    final controller = await _controllerCompleter.future;
    if (_lineSoFar != null) {
      controller.removeLine(_lineSoFar!);
    }
    _lineSoFar = await controller.addLine(
        LineOptions(
              lineColor: "#ff0000",
              lineWidth: 5,
              lineJoin: "round", //"butt" (default), "round" or "square"
              geometry: _routeSoFar
        )
    );
  }

  _finishRide(context) async {
    Provider.of<Rides>(context, listen: false).finishCurrentRide();
  }

  @override
  Widget build(BuildContext context) {

    final TextStyle attributionBaseStyle = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final TextStyle attributionTextStyle = TextStyle(
        fontFamily: attributionBaseStyle.fontFamily,
        fontSize: attributionBaseStyle.fontSize,
        color: Colors.black
    );
    final TextStyle attributionTextStrokeStyle = TextStyle(
      fontFamily: attributionBaseStyle.fontFamily,
      fontSize: attributionBaseStyle.fontSize,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white,
    );
    final map =  MapLibreMap(
      styleString: _mapData.styleJsonPath,
      onMapCreated: _mapCreated,
      onUserLocationUpdated: _userLocationUpdated,
      onStyleLoadedCallback: _styleLoaded,
      initialCameraPosition: const CameraPosition(target: LatLng(50.9365, 6.9398), zoom: 16.0),
      trackCameraPosition: false,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: true,
      dragEnabled: false,
      myLocationEnabled: true,
      compassEnabled: true,
      myLocationTrackingMode: MyLocationTrackingMode.none,
      myLocationRenderMode: MyLocationRenderMode.normal,
      doubleClickZoomEnabled: false,
      scrollGesturesEnabled: !_trackUserLocation,
      minMaxZoomPreference: const MinMaxZoomPreference(10,20),
    );
    final overlay = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onDoubleTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              child: Stack(
                children: [
                  Text(Constants.mapAttribution, style: attributionTextStrokeStyle),
                  Text(Constants.mapAttribution, style: attributionTextStyle),
                ],
              ),
            ),
            const Spacer(flex: 1),
            ElevatedButton(
              onPressed: _toggleLocationTracking,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                backgroundColor: _trackUserLocation ? Theme.of(context).colorScheme.secondary : Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsetsGeometry.all(8),
              ),

              child: const Icon(Icons.center_focus_strong, size: 30),
            ),
          ],
        ),
        const SizedBox(height:5),
        RideDashboard(ride: widget.ride),
      ],
    );

    return Scaffold(
      body: Column(
          children:[
            Expanded(
              child: Stack(
                  children: [
                    map,
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: overlay,
                    ),

                  ]),
            ),
          ],
        ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
                onPressed: () {
                  if (_lastUserLocation != null) {
                    showModalBottomSheet(context: context,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      isDismissible: false,
                      builder: _annotationDialogBuilder,
                    );
                    //                              showAdaptiveDialog(context: context, builder: _annotationDialogBuilder);
                  }
                },
                icon: const Icon(Icons.comment),
                label: const Text(Constants.annotation),
            ),
            OutlinedButton.icon(
                onPressed: () { _finishRide(context); },
                icon: const Icon(Icons.output_outlined),
                label: const Text(Constants.endRecording),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLocationTracking() {
    setState(() {
      _trackUserLocation = !_trackUserLocation;
      logInfo("trackUserLocation set to $_trackUserLocation");
    });
    if (_trackUserLocation) {
      if (_lastUserLocation != null) {
        _userLocationUpdated(_lastUserLocation!);
      }
    }
  }

  void _userLocationUpdated(UserLocation location) async {
    logInfo("user location updated");
    _lastUserLocation = location;
    if (_trackUserLocation) {
      final mapController = await _controllerCompleter.future;

      double zoom = 16.0;
      double bearing = 0;
      final pos = mapController.cameraPosition;
      if (pos != null) {
        zoom = pos.zoom;
        bearing = pos.bearing;
      }
      mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: location.position, zoom: zoom, bearing: bearing))
      );
    }
  }

  void _mapCreated(MapLibreMapController controller) {
    _controllerCompleter.complete(controller);
    logInfo("MapData: map created!");
  }

  void _styleLoaded() async {
    logInfo("MapData: style loaded!");
    final mapController = await _controllerCompleter.future;
    List<String> maps = _mapData.loadedMaps;
    logInfo('MapData: loaded maps length ${maps.length}');
    for (final entry in maps) {
      logInfo('MapData: adding source $entry -> ${_mapData.urlForMap(entry)}');
      mapController.addSource(entry,
          VectorSourceProperties(url: _mapData.urlForMap(entry))
      );
    }
    //trigger camera movement on ios (should work without this, but it doesn't)
    UserLocation? loc = _lastUserLocation;
    if (loc != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        logInfo("_styleLoaded: user location present");
        _userLocationUpdated(loc);
      });
    }
  }


  Widget _annotationDialogBuilder(BuildContext context) {
    TextEditingController textEditingController = TextEditingController();
    Set<AnnotationTag> tags = {};
    int severity = 50;

    return StatefulBuilder(
        builder: (context, setState) {

          List<Widget> tagButtons = [];
          for (final anno in AnnotationTag.values) {
            final chip = FilterChip(
                label: Text(anno.label),
                selected:(tags.contains((anno))),
                onSelected: (on) {
                  if (tags.contains(anno)) {
                    logInfo("tags: removing $anno");
                    setState(() { tags.remove(anno); });
                  } else {
                    logInfo("tags: adding $anno");
                    setState(() { tags.add(anno); });
                  }
                  logInfo("tags: tags is $tags");
                });
            tagButtons.add(chip);
          }

          ChoiceChip makeSeverityChip(val, unicode) {
            return ChoiceChip(
              labelStyle: TextTheme.of(context).titleLarge,
              showCheckmark: false,
              selected: severity == val,
              onSelected: (sel) { setState((){ severity = val; }); },
              label:Text(String.fromCharCode(unicode)),
            );
          }

          return SingleChildScrollView(
            child:
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Was ist hier?", style: TextTheme.of(context).titleSmall),
                  Wrap(
                      crossAxisAlignment: WrapCrossAlignment.start,
                      spacing:5,
                      runSpacing: 0,
                      alignment: WrapAlignment.start,
                      children: tagButtons
                  ),
                  const SizedBox(height:10),
                  Text("Beschreibung (optional)", style: TextTheme.of(context).titleSmall),
                  const SizedBox(height:5),
                  CupertinoTextField(
                    controller: textEditingController,
                    /*                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.warning),
                    labelText: 'Beschreibung',
                    helperText: 'Kurze Beschreibung (optional)',
                    filled: true,
                  ),
                */            ),
                  const SizedBox(height:10),
                  Text("Wie schlimm?", style: TextTheme.of(context).titleSmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      makeSeverityChip(0, 128528),
                      makeSeverityChip(25, 128533),
                      makeSeverityChip(50, 128530),
                      makeSeverityChip(75, 128534),
                      makeSeverityChip(100, 128545)
                    ],
                  ),
                  const SizedBox(height:24),
                  Row(
                    children:[
                      const Spacer(flex: 1),
                      OutlinedButton(
                          style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.transparent)),
                          child: const Text('Abbrechen'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }
                      ),
                      const Spacer(flex: 1),
                      OutlinedButton(
                          child: const Text('Speichern und weiter'),
                          onPressed: () {
                            Location? location = widget.ride.locations.lastOrNull;
                            if (location != null) {
                              ride_annotation.Annotation annotation = ride_annotation
                                  .Annotation(location: location,
                                  severity: severity,
                                  tags: tags,
                                  comment: textEditingController.text);
                              widget.ride.addAnnotation(annotation);
                            } else {
                              logErr("Could not add annotation because there's no last location!");
                            }
                            Navigator.of(context).pop();
                          }
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                  const SizedBox(height:10),
                ],
              ),
            ),

          );

        }
    );
  }
}

class RideDashboard extends StatefulWidget {
  final RunningRide ride;

  const RideDashboard({super.key, required this.ride});

  @override
  State<RideDashboard> createState() => _RideDashboardState();
}

class _RideDashboardState extends State<RideDashboard> {

  @override
  void initState() {
    super.initState();
    widget.ride.addListener(_checkRideUpdate);
  }

  @override dispose() {
    widget.ride.removeListener(_checkRideUpdate);
    super.dispose();
  }

  void _checkRideUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Location? lastLocation = widget.ride.getLastLocation();
    List<Widget> contents = [];
    if (lastLocation == null) {
      contents.add(const Text("Suche GPS..."));
    } else {
      TextStyle bold = const TextStyle(fontWeight:FontWeight.bold);
      Duration rideDuration = Duration(seconds:widget.ride.durationS.toInt());
      double rideDistanceM = widget.ride.totalDistanceM;
      double currentSpeedKmh = lastLocation.speed / 3.6;
      if (currentSpeedKmh < 0) currentSpeedKmh = 0;
      contents.add(const Icon(Icons.multiple_stop_outlined));
      if (rideDistanceM < 1000) {
        contents.add(Text(" ${rideDistanceM.toStringAsFixed(0)}", style: bold));
        contents.add(const Text(" m"));
      } else {
        contents.add(Text(" ${(rideDistanceM/1000).toStringAsFixed(1)}", style: bold));
        contents.add(const Text(" km"));
      }
      contents.add(const Spacer());
      contents.add(const Icon(Icons.multiple_stop_outlined));
      contents.add(Text(" ${rideDuration.inHours}", style: bold));
      contents.add(const Text(" h"));
      contents.add(Text(" ${rideDuration.inMinutes.remainder(60).toString().padLeft(2,'0')}", style: bold));
      contents.add(const Text(" m"));
      contents.add(const Spacer());
      contents.add(const Icon(Icons.speed_outlined));
      contents.add(Text(" ${currentSpeedKmh.toStringAsFixed(1)}", style: bold));
      contents.add(const Text(" km/h"));
    }

    return Card(
      color: const Color(0xffffffff),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsetsGeometry.all(10),
        child: Row(
          children: contents,
        )
      ),
    );
  }
}

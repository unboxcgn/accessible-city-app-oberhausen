import 'dart:async';
import 'dart:io';

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
    File file = File(_mapData.styleJsonPath);
    String contents = file.readAsStringSync();
    logInfo("MAPISSUE: Style path expected at ${_mapData.styleJsonPath} len ${file.lengthSync()} contents $contents");


    return Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:[
              Expanded(
                child: RepaintBoundary (
                  child:MapLibreMap(
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
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                    child: Text(
                        Constants.mapAttribution,
                        style: Theme.of(context).textTheme.bodySmall),
                    onDoubleTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright'))
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom:20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: TextButton(
                          onPressed: _toggleLocationTracking,
                          child: Column(
                            children: [
                              Icon(Icons.center_focus_strong, color: _trackUserLocation ? Theme.of(context).colorScheme.primary: Colors.grey),
                              const Text(Constants.trackLocation),
                            ],
                          )
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: TextButton(
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
                          child: const Column(
                            children: [
                              Icon(Icons.comment),
                              Text(Constants.annotation),
                            ],
                          )
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: TextButton(
                          onPressed: () { _finishRide(context); },
                          child: const Column(
                              children: [
                                Icon(Icons.stop_circle),
                                Text(Constants.endRecording),
                              ]
                          )
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
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

/*  This is the content for the former adaptive dialog
          return AlertDialog(
            scrollable: true,
            title: const Text("Was ist hier?"),
            content:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    spacing:5,
                    runSpacing: 0,
                    alignment: WrapAlignment.start,
                    children: tagButtons
                ),
                Padding(
                  padding: const EdgeInsets.only(top:10),
                  child: Text("Wie schlimm?",
                    style: TextTheme.of(context).titleSmall,
                  ),
                ),
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
                Padding(
                  padding: const EdgeInsets.only(top:10),
                  child: Text("Beschreibung / Kommentar",
                    style: TextTheme.of(context).titleSmall,
                  ),
                ),
                CupertinoTextField(
                  controller: textEditingController,
/*                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.warning),
                  labelText: 'Beschreibung',
                  helperText: 'Kurze Beschreibung (optional)',
                  filled: true,
                ),
  */            ),

              ],
            ),
            actions: <Widget>[
              OutlinedButton(
                  child: const Text('Abbrechen'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }
              ),
              OutlinedButton(
                  child: const Text('Speichern und weiter'),
                  onPressed: () {
                    RunningRide? ride = Provider.of<Rides>(context, listen: false).currentRide;
                    if (ride != null) {
                      Location? location = ride.locations.lastOrNull;
                      if (location != null) {
                        ride_annotation.Annotation annotation = ride_annotation
                            .Annotation(location: location,
                            severity: severity,
                            tags: tags,
                            comment: textEditingController.text);
                        ride.addAnnotation(annotation);
                      } else {
                        logErr("Could not add annotation because there's no last location!");
                      }
                    } else {
                      logErr("Could not add annotation because there's no current ride!");
                    }
                    Navigator.of(context).pop();
                  }
              ),
            ],
          );

 */
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

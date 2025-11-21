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
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => RecordScreenState();
}

class RecordScreenState extends State<RecordScreen> {

  final _controllerCompleter = Completer<MapLibreMapController>();
  final MapData _mapData = MapData();
  bool _trackUserLocation = true;
  UserLocation? _lastUserLocation;

  @override
  void initState() {
    super.initState();
    SensorService().checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.record_screen.dart
          title: const Text(Constants.recording),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:[
              Expanded(
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
                )
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
                              showAdaptiveDialog(context: context, builder: _annotationDialogBuilder);
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
                          onPressed: () {Provider.of<Rides>(context, listen: false).finishCurrentRide();},
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
    logInfo("user loction updated");
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
      logInfo("going to location ${location.position}");
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
      Future.delayed(Duration(milliseconds: 100), () {
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
        final offButtonStyle = ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(35,30)),
          textStyle: WidgetStatePropertyAll(TextTheme.of(context).labelSmall),
          padding: const WidgetStatePropertyAll(EdgeInsets.only(left: 5, right: 5)),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.all(Radius.circular(10)))),
          side: const WidgetStatePropertyAll(BorderSide(color: Colors.black12))
        );

        final onButtonStyle = ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(35,30)),
          textStyle: WidgetStatePropertyAll(TextTheme.of(context).labelSmall),
          padding: const WidgetStatePropertyAll(EdgeInsets.only(left: 5, right: 5)),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.all(Radius.circular(10)))),
          backgroundColor: WidgetStateColor.resolveWith((_) {return Theme.of(context).colorScheme.primaryContainer;}),
          side: const WidgetStatePropertyAll(BorderSide(color: Colors.black54))
        );

        final emojiButtonStyle = ButtonStyle(
            textStyle: WidgetStatePropertyAll(TextTheme.of(context).titleLarge),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(3)),
            minimumSize: const WidgetStatePropertyAll(Size(25,25)),
        );

        final emojiButtonOnStyle = ButtonStyle(
            textStyle: WidgetStatePropertyAll(TextTheme.of(context).titleLarge),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(3)),
            minimumSize: const WidgetStatePropertyAll(Size(25,25)),
            side: WidgetStatePropertyAll(BorderSide(width: 2, color: Theme.of(context).colorScheme.inversePrimary))
        );

        List<Widget> tagButtons = [];
        for (final anno in AnnotationTag.values) {
          final button = OutlinedButton(
            onPressed: () {
              if (tags.contains(anno)) {
                logInfo("tags: removing $anno");
                setState(() { tags.remove(anno); });
              } else {
                logInfo("tags: adding $anno");
                setState(() { tags.add(anno); });
              }
              logInfo("tags: tags is $tags");
            },
            style: tags.contains(anno) ? onButtonStyle : offButtonStyle, child: Text(anno.label)
          );
          tagButtons.add(button);
        }

        return AlertDialog.adaptive(
          scrollable: true,
          title: const Text("Was ist hier?"),
          content: Column(
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
                  Expanded(child: TextButton(
                    onPressed: (){ setState((){ severity = 0; }); },
                    style: severity == 0 ? emojiButtonOnStyle : emojiButtonStyle,
                    child:Text(String.fromCharCode(128528)),
                  )),
                  Expanded(child: TextButton(
                    onPressed: (){ setState((){ severity = 25; }); },
                    style: severity == 25 ? emojiButtonOnStyle : emojiButtonStyle,
                    child:Text(String.fromCharCode(128533)),
                  )),
                  Expanded(child: TextButton(
                    onPressed: (){ setState((){ severity = 50; }); },
                    style: severity == 50 ? emojiButtonOnStyle : emojiButtonStyle,
                    child:Text(String.fromCharCode(128530)),
                  )),
                  Expanded(child: TextButton(
                    onPressed: (){ setState((){ severity = 75; }); },
                    style: severity == 75 ? emojiButtonOnStyle : emojiButtonStyle,
                    child:Text(String.fromCharCode(128534)),
                  )),
                  Expanded(child: TextButton(
                    onPressed: (){ setState((){ severity = 100; }); },
                    style: severity == 100 ? emojiButtonOnStyle : emojiButtonStyle,
                    child:Text(String.fromCharCode(128545)),
                  )),
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
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              }
            ),
            TextButton(
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
      }
    );
  }
}

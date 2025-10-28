import 'dart:async';

import '../logger.dart';
import '../constants.dart';
import '../services/sensor_service.dart';
import '../model/rides.dart';
import '../model/map_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

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
    logInfo("recordscreen build: style JSON is ${_mapData.styleJsonPath}");
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:[
/*            TextButton(
              child: Text("Toggle track location"),
              onPressed: toggleLocationTracking
            ), */
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
                          showAdaptiveDialog(context: context, builder: _addAnnotationDialog);
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

  Widget _addAnnotationDialog(BuildContext context) {
    return AlertDialog.adaptive(
      title: const Text("Annotieren"),
      content: const TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.clear),
          labelText: 'Was ist hier?',
          hintText: 'Beschreibung',
          helperText: 'Kurze Beschreibung des Problems',
          filled: true,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Abbrechen'),
          onPressed: () { Navigator.of(context).pop(); }
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () { Navigator.of(context).pop(); },
        ),
      ]
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
    _lastUserLocation = location;
    if (_trackUserLocation) {
      final mapController = await _controllerCompleter.future;

      double zoom = 16.0;
      double bearing = 0;
      final pos = mapController.cameraPosition;
      if (pos != null) {
        zoom = pos!.zoom;
        bearing = pos!.bearing;
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
  }

}



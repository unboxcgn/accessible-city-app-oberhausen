import '../logger.dart';

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';



class MapData extends ChangeNotifier {

  static final MapData _sharedMapData = MapData._internal();

  factory MapData() {
    return _sharedMapData;
  }

  MapData._internal();

  SharedPreferences? _sharedPrefs;
  String? _mapResourcesPath;

  Future<void> initialize() async {
    _mapResourcesPath ??= (await getApplicationSupportDirectory()).path;
    logInfo('MapData: initialize mapResources is ${_mapResourcesPath!}');
    _sharedPrefs ??= await SharedPreferences.getInstance();

    await _loadVectorMapFromAssets("cologne");
    await _loadVectorMapFromAssets("oberhausen");

    bool? styleLoaded = _sharedPrefs!.getBool("map_style_loaded");
    logInfo('MapData: styleLoaded is $styleLoaded');
    if ((styleLoaded == null) || (!(styleLoaded))) {
      logInfo("MapData: loading font and style");
      _loadStyleData();
      _sharedPrefs!.setBool("map_style_loaded", true);
    } else {
      logInfo("MapData: font and style already loaded");
    }
  }

  void resetAssets() {
    _sharedPrefs!.setStringList("loaded_maps", []);
    _sharedPrefs!.setBool("map_style_loaded", false);
  }

  String get styleJsonPath {
    assert(_mapResourcesPath != null, "MapData: not initialized!");
    final path = '$_mapResourcesPath/map-style.json';
    File f = File(path);
    if (f.existsSync()) {
      logInfo('MapData: Style File $path exists, length ${f.lengthSync()}');
    } else {
      logInfo('MapData: Style File $path does not exist');
    }
    return path;
  }

  List<String> get loadedMaps {
    assert(_mapResourcesPath != null, "MapData: not initialized!");
    assert(_sharedPrefs != null, "MapData: not initialized!");
    List<String>? loadedMaps = _sharedPrefs!.getStringList('loaded_maps');
    return loadedMaps ?? [];
  }

  String urlForMap(String basename) {
    assert(_mapResourcesPath != null, "MapData: not initialized!");
    File f = File('$_mapResourcesPath/$basename.mbtiles');
    logInfo('MapData: File ${'$_mapResourcesPath/$basename.mbtiles'} exists ${f.existsSync()} length ${f.lengthSync()}');
    String s = 'mbtiles://$_mapResourcesPath/$basename.mbtiles';
    s = s.replaceAll(" ", "%20");
    logInfo("map url is $s");
    return s;
  }

  Future<void> _loadStyleData() async {
    assert (_mapResourcesPath != null, "MapData: not initialized!");
    _unzipAssetToMapDir("map-font.zip");
    logInfo('MapData: copy map font done');
    final sources = _sharedPrefs!.getStringList("loaded_maps") ?? [];

    String template = await rootBundle.loadString('assets/map-style-template.json');
    template = template.replaceAll('***PATH***', _mapResourcesPath!.replaceAll(" ", "%20"));

    final templateJson = jsonDecode(template) as Map<String, dynamic>;
    Map<String, dynamic> styleJson = {};
    for (var entry in templateJson.keys) {
      if (entry != "layers") {
        styleJson[entry] = templateJson[entry];
      }
    }
    final List<Map<dynamic, dynamic>> layers = [];
    final templateLayers = templateJson["layers"] as List;
    for (var templateLayer in templateLayers) {
      logInfo("handling template layer ${templateLayer['id']}");
      final templateSource = templateLayer["source"] as String?;
      if (templateSource != null && templateSource.contains("***SOURCE***")) {
        logInfo("source based layer");
        //copy for each source
        for (var source in sources) {
          logInfo("applying source $source");
          final layer = Map.from(templateLayer);
          layer["source"] = templateSource.replaceAll("***SOURCE***", source);
          layer["id"] = "${templateLayer['id']}-$source";
          layers.add(layer);
        }
      } else {
        logInfo("source independent layer");
        layers.add(templateLayer);
      }
    }
    styleJson["layers"] = layers;
    final style = jsonEncode(styleJson);
    logInfo("populated style is $style");
    final file = File(styleJsonPath);
    await file.create(recursive: true);
    await file.writeAsString(style);
  }

  Future<void> _loadVectorMapFromAssets(String basename) async {
    assert (_sharedPrefs != null, "MapData: not initialized!");
    List<String>? loadedMaps = _sharedPrefs!.getStringList("loaded_maps");
    if (loadedMaps == null) {
      logInfo("_loadVectorMapFromAssets: initializing loaded maps");
      loadedMaps = [];
      _sharedPrefs!.setStringList("loaded_maps", loadedMaps);
    }
    if (loadedMaps.contains(basename)) {
      logInfo("_loadVectorMapFromAssets: $basename already loaded");
    } else {
      logInfo("hello 3");
      try {
        await _unzipAssetToMapDir('$basename.zip');
        List<String> loadedMaps = _sharedPrefs!.getStringList("loaded_maps")!;
        loadedMaps.add(basename);
        logInfo("_loadVectorMapFromAssets: adding $basename to loaded maps");
        _sharedPrefs!.setStringList('loaded_maps', loadedMaps);
      } catch (error) {
        logInfo("_loadVectorMapFromAssets: Could not add $basename to loaded maps: $error");
      }
    }
  }

  Future<void> _unzipAssetToMapDir(String assetName) async {
    assert (_mapResourcesPath != null, "MapData: not initialized!");
    ByteData value = await rootBundle.load('assets/$assetName');
    Uint8List zipfile = value.buffer.asUint8List(
      value.offsetInBytes, value.lengthInBytes);
    InputStream ifs = InputStream(zipfile);
    final archive = ZipDecoder().decodeBuffer(ifs);
    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      final filename = file.name;
      final path = '${_mapResourcesPath!}/$filename';
      logInfo("MapData: unzipping $path");
      if (file.isFile) {
        final data = file.content as List<int>;
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(path).create(recursive: true);
      }
    }
  }

}
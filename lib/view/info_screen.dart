import 'dart:convert';

import 'package:accessiblecity/logger.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import 'package:flutter/services.dart' show rootBundle;

class InfoScreen extends StatelessWidget {

  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: const Text(Constants.aboutTheProject),
        ),
        body:
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView(
              padding:const EdgeInsets.only(top:10.0,bottom:100.0),
              children: [
                Text('Über das Projekt', style: Theme.of(context).textTheme.titleLarge),
                const Text('''
          
Unser Plan: Wir sammeln und analysieren Bewegungsdaten von Menschen mit Bewegungseinschränkungen automatisch bei jedem Weg. Die daraus gewonnenen Informationen sollen helfen, Mobilitätsbarrieren in Städten zu reduzieren.
          
Durch automatische Analyse der Wegedaten werden Umwege, schlechte Untergründe und Gefahrenstellen erkannt. Die ausgewerteten Informationen stehen anonymisiert im Internet bereit und sind als offene Daten für alle Interessierte nutzbar.
          
Die Stadtplanung bekommt dadurch Einblicke in die reale Wegenutzung und Probleme von bewegungseingeschränkten Menschen und kann so bessere Wege für alle schaffen.
          
Die erhobenen Datensätze werden anonymisiert auf accessible-city.de veröffentlicht. Dadurch können sie von Städten, anderen Menschen und Vereinen genutzt werden.
          
„Accessible City“ wird von den Förderprojekten „Co-Creation-Fund“ der Stadt Oberhausen und „un:box Cologne“ der Stadt Köln unterstützt.
                '''),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Image(image: AssetImage('assets/images/unbox_logo.png'))),
                    Expanded(child: Image(image: AssetImage('assets/images/smart_city_oberhausen.png'))),
                  ],
                ),
                OutlinedButton(
                  onPressed: () { launchUrl(Uri.parse('https://www.accessible-city.de')); },
                  child: const Text("www.accessible-city.de"),
                ),
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Center(child: VersionInfo()),
                ),
              ],
            ),
          ),
    );
  }
}

class VersionInfo extends StatefulWidget {
  final TextStyle? style;
  const VersionInfo({super.key, this.style});

  @override
  State<VersionInfo> createState() => _VersionInfoState();
}

class _VersionInfoState extends State<VersionInfo> {
//  String _appNameString = "";
  String _versionString = "";
  String _buildString = "";
  String _buildDateString = "";
//  String _buildHeadString = "";
  String _commitHashString = "";

  void _loadInfo() async {
    String buildDateString = "?";
//    String buildHeadString = "?";
    String commitHashString = "?";
    try {
      final s = await rootBundle.loadString('assets/buildinfo.json');
      final entries = jsonDecode(s);
      buildDateString = entries['build_date'] as String;
//      buildHeadString = entries['build_head'] as String;
      commitHashString = entries['commit_hash'] as String;
    } catch (e) {
      logErr("Could not get build info: $e");
    }
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
//      _appNameString = packageInfo.appName;
      _versionString = packageInfo.version;
      _buildString = packageInfo.buildNumber;
      _buildDateString = buildDateString;
//      _buildHeadString = buildHeadString;
      _commitHashString = commitHashString;
    });
  }

  @override @override
  void initState() {
    _loadInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String s = "version $_versionString build $_buildString\ndate $_buildDateString\nhash $_commitHashString";

    return Text(s, textAlign: TextAlign.center, style: widget.style ?? Theme.of(context).textTheme.bodySmall);
  }
}

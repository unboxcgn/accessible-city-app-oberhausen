import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';

class InfoScreen extends StatelessWidget {

  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: const Text(Constants.appTitle),
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
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(child: Text('App version 1.0.0, build 2025-11-28-23-00-00', style: Theme.of(context).textTheme.bodyMedium)),
                ),
              ],
            ),
          ),
    );
  }
}

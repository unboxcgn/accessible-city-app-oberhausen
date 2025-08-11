import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPane extends StatelessWidget {
  const InfoPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
        padding:const EdgeInsets.only(top:10.0,bottom:100.0),
        children: [
          Text('Über das Projekt', style: Theme.of(context).textTheme.titleLarge),
          const Text('''
          
Unser Plan: Wir sammeln und analysieren Bewegungsdaten von Menschen mit Bewegungseinschränkungen automatisch bei jedem Weg. Die daraus gewonnenen Informationen sollen helfen, Mobilitätsbarrieren in Köln zu reduzieren.
          
Durch automatische Analyse der Wegedaten werden Umwege, schlechte Untergründe und Gefahrenstellen erkannt. Die ausgewerteten Informationen stehen anonymisiert im Internet bereit und sind als offene Daten für alle Interessierte nutzbar.
          
Die Stadtplanung bekommt dadurch Einblicke in die reale Wegenutzung und Probleme von bewegungseingeschränkten Menschen und kann so bessere Wege für alle schaffen.
          
Die erhobenen Datensätze werden anonymisiert auf accessible-city.de veröffentlicht. Dadurch können sie von der Stadt Köln, anderen Menschen und Vereinen genutzt werden.
          
„Accessible City“ entsteht im Rahmen des Förderprojektes „un:box Cologne“ der Stadt Köln.
          '''),
          const Image(image: AssetImage('assets/images/unbox_logo.png')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            onPressed: () { launchUrl(Uri.parse('https://www.accessible-city.de')); },
            child: const Text("www.accessible-city.de"),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(child: Text('App version 0.1.1, build 2025-08-11-23-30-00', style: Theme.of(context).textTheme.bodyMedium)),
          ),
        ],
      ),
    ); // This trailing comma makes auto-formatting nicer for build methods.
  }
}

import 'package:accessiblecity/constants.dart';

import '../model/user.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FirstBootScreen extends StatelessWidget {
  const FirstBootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.appTitle),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Schön, dass du dabei bist!',
                    style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Wir wollen mit Bewegungsdaten die Wege von Menschen mit Mobilitätseinschränkungen in Köln analysieren und so bessere Wege für alle schaffen.',
                    style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Dafür werden deine Bewegungsdaten und die Daten des Beschleunigungssensors auf dem Handy gesammelt und anonymisiert auf den Accessible-City-Server hochgeladen.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text("Ja, ihr dürft meine Daten verwenden", style: Theme.of(context).textTheme.labelLarge),
                  value: Provider.of<User>(context).uploadConsent,
                  onChanged: (val) {if (val!=null) { Provider.of<User>(context, listen:false).uploadConsent = val;} }),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                onPressed: Provider.of<User>(context).uploadConsent ? () {
                  Provider.of<User>(context, listen:false).firstStart = false;
                } : null,
                child: Text("Los geht's",style: Theme.of(context).textTheme.labelLarge),
              )
            ]
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

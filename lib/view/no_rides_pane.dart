import 'package:flutter/material.dart';

class NoRidesPane extends StatelessWidget {
  const NoRidesPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Tracke deine Routen und verbessere die Wege mit uns',
                style: Theme.of(context).textTheme.headlineLarge
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Image(image: AssetImage('assets/images/logo-transparent.png'), ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Du hast noch keine Wege aufgenommen. Starte jetzt!',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ); // This trailing comma makes auto-formatting nicer for build methods.
  }
}

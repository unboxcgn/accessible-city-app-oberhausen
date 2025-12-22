import 'package:flutter/material.dart';

class NoRidesPane extends StatelessWidget {
  const NoRidesPane({super.key});

  @override
  Widget build(BuildContext context) {

    return Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top:30, left: 10, right: 10, bottom: 10),
            child: Image(image: AssetImage('assets/images/no_rides.png'), ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Du hast noch keine Wege aufgenommen. Starte jetzt mit deinem ersten Weg!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),

          ),
        ],
      ); // This trailing comma makes auto-formatting nicer for build methods.
  }
}

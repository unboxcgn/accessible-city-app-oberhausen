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
      backgroundColor: Theme.of(context).primaryColor,
//      appBar: AppBar(
//        title: const Text(Constants.appTitle),
//      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height:64),
                Image.asset('assets/images/firststart_logo.png'),
                SizedBox(height:24),
                Text('Gemeinsam machen wir Städte barrierefreier.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height:16),
                Text('Accessible City sammelt während deiner Fahrt anonymisierte Bewegungs- und Sensordaten. So erkennen wir wichtige Strecken und Hindernisse für Rollstuhlfahrende. Deine Daten sind anonym. Rückschlüsse auf dich sind nicht möglich.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height:24),
                CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text("Ja, meine anonymisierten Daten dürfen verwendet werden",
                        style: Theme.of(context).textTheme.bodyLarge
                    ),
                    value: Provider.of<User>(context).uploadConsent,
                    onChanged: (val) {if (val!=null) { Provider.of<User>(context, listen:false).uploadConsent = val;} }),
              ]
          ),
        ),
      ),
      bottomNavigationBar:
        BottomAppBar(
          child: OutlinedButton(
            onPressed: Provider.of<User>(context).uploadConsent ? () {
              Provider.of<User>(context, listen:false).firstStart = false;
            } : null,
            child: Text("Start",style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
    );
  }
}

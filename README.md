# Accessible City App

This is the repository of the "Accessible City" app. The app is written in Flutter using Android Studio.

You should be able to clone this repository, open it in Android Studio, build and run it. There are probably many issues in doing so, but I have not encountered them (yet). Feel free to fork, improve and issue pull requests.

There are two main files missing. However, this should not affect building the project. 

- android/key.properties : This file references the signing key store and its access credentials. To build a release, provide your own signing keys.
- lib/keys.dart: This file contains the API key used to upload to the server. There's a template file provided. Generate your own key and provide it to both app and server you're running.

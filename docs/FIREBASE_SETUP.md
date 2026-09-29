# Firebase setup

The Android build is connected to the Firebase project `budgetbites-a9d28`.
The supplied `google-services.json` is registered for
`com.robert.budgetbites`, which is now the Android application ID.

## Enable the services

In the Firebase console:

1. Enable **Authentication → Sign-in method → Email/Password**.
2. Enable **Authentication → Sign-in method → Google**.
3. Add the Android debug SHA-1 from the machine running the emulator. The
   default debug certificate can be printed with:

   ```sh
   keytool -list -v -alias androiddebugkey \
     -keystore ~/.android/debug.keystore \
     -storepass android -keypass android
   ```

   Add the `SHA1` value under **Project settings → Your apps → Android app**,
   then download the refreshed `google-services.json` into
   `android/app/google-services.json`.
4. Create a **Cloud Firestore** database in a region close to the users.
5. Deploy `firestore.rules` before sharing a build.

The Flutter app uses `firebase_core`, `firebase_auth`, `google_sign_in`, and
`cloud_firestore`. The **Continue with Google** button exchanges the native
Google credential for Firebase Auth, then stores the same account snapshot at
`users/{uid}` as email/password accounts. The controller keeps the existing
`SharedPreferences` store as an offline fallback if Firestore is temporarily
unavailable.

## Admin access

Admin access is read from a Firebase custom claim (`admin: true` or
`role: "admin"`). There is no hardcoded admin password in the Android build.
Set claims from a trusted server or the Firebase Admin SDK; never from the
client app.

## Other platforms

The current supplied configuration is Android-only. Until FlutterFire
configuration files are added for iOS and web, those platforms use the local
adapter. Run `flutterfire configure` after registering each additional
platform to generate the shared `firebase_options.dart` configuration.

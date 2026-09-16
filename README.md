# BudgetBite Flutter

BudgetBite is a cross-platform grocery-planning app for discovering recipes,
applying dietary preferences, finding nearby stores, building a shopping plan,
and estimating a grocery budget before checkout.

## Included features

- Responsive Material 3 interface for Android, iOS, and web
- Account creation, sign-in, guest mode, and challenge admin account
- Account-specific saved recipes and preferences
- Live recipe search with dietary and allergen filtering
- Gluten-free ingredient substitutions when a recipe can be adapted safely
- ZIP code and device-location store search
- Nearby-store map and retailer-specific ingredient search links
- Serving-size scaling and ingredient planning
- Store-synced budget book with editable prices and estimated store-local tax
- Riverpod state management and GoRouter navigation
- Local persistence through SharedPreferences
- Unit tests for preference filtering and adaptable recipes

## Run locally

Requirements: Flutter 3.44 or newer and Dart 3.12 or newer.

```sh
flutter pub get
flutter run -d chrome
```

For a mobile simulator or connected device:

```sh
flutter run
```

The challenge admin credentials are `admin` / `admin123`. They are intentionally
local-only and must be replaced with a real identity provider before deployment.

## Live-service configuration

The default development configuration uses public services where possible:

- Zippopotam for ZIP coordinates
- OpenStreetMap Overpass for nearby grocery stores
- OpenStreetMap tiles for the map
- TheMealDB for supplemental recipe search

For a production deployment, create `config/dev.json` from
[`config/example.json`](config/example.json), then run:

```sh
flutter run -d chrome --dart-define-from-file=config/dev.json
```

The Places and tax URLs should point to a server controlled by the app owner.
Do not place unrestricted Google Maps, retailer, or tax-service secrets in the
Flutter bundle. See [`docs/BACKEND_CONTRACTS.md`](docs/BACKEND_CONTRACTS.md).

## Project structure

```text
lib/
  core/       configuration and theme
  data/       bundled seed content
  features/   screens grouped by product feature
  models/     immutable domain models
  routing/    declarative navigation
  services/   location, store, tax, storage, recipe, and retailer adapters
  shared/     reusable UI
  state/      Riverpod application state and business rules
```

## Quality checks

```sh
flutter analyze
flutter test
flutter build web --release
```

## Production checklist

- Replace local authentication with Firebase Auth, Auth0, or another OIDC service.
- Put Google Places and retailer integrations behind authenticated backend APIs.
- Replace example tax estimates with a maintained tax provider and product-level
  taxability rules.
- Add Crashlytics/Sentry, analytics consent, accessibility testing, CI/CD, and a
  privacy policy before public release.
- Review retailer terms before using inventory data. Store links currently let
  users verify availability directly when no approved inventory API exists.


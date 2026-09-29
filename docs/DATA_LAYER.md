# Data layer

BudgetBite keeps asynchronous data work out of widgets:

```text
screen -> AppController -> AppDataRepository -> service/API/device
          AppState (loading, data, error) <-
```

`lib/data/repositories/app_data_repository.dart` is the composition boundary
for recipe search, ZIP/device store lookup, and store tax estimates. It turns
service failures into `DataLayerException` messages that are safe to show to a
user.

The controller exposes the result through `AppState`:

- `searchingRecipes` and `searchError` drive the Discover progress/error UI.
- `loadingStores` and `storeError` drive the location progress/error UI.
- `loadingTax` and `taxError` drive the Budget progress/error UI.

When adding a new remote data source:

1. Add or update a service in `lib/services/`.
2. Call it from `AppDataRepository`, not from a widget.
3. Normalize failures into `DataLayerException` with a useful fallback message.
4. Add loading/error fields to `AppState` if the request has visible progress.
5. Let the screen render those fields and provide a retry action.

This keeps widgets focused on layout and interaction, makes services easy to
replace in tests, and prevents network/device exceptions from reaching the UI.

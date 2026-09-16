{{flutter_js}}
{{flutter_build_config}}

// BudgetBite intentionally skips Flutter's deprecated service worker. During
// active development it could keep serving an older app after a successful
// rebuild, making fixed behavior appear unchanged.
_flutter.loader.load();

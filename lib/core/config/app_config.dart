class AppConfig {
  const AppConfig._();

  static const placesProxyUrl = String.fromEnvironment('PLACES_PROXY_URL');
  static const taxProxyUrl = String.fromEnvironment('TAX_PROXY_URL');
  static const useLiveServices = bool.fromEnvironment(
    'USE_LIVE_SERVICES',
    defaultValue: true,
  );
}

class AppConstants {
  AppConstants._();

  static const String aiServiceUrl = String.fromEnvironment(
    'AI_SERVICE_URL',
    defaultValue: 'https://ssr-ai.railway.app',
  );

  static const double geofenceRadiusM = 20.0;
  static const double ssimPassThreshold = 0.75;
  static const double duplicateRadiusM = 50.0;
}

enum ThemePreference {
  light('light'),
  dark('dark');

  const ThemePreference(this.value);
  final String value;

  static ThemePreference fromString(String value) {
    switch (value) {
      case 'light':
        return ThemePreference.light;
      case 'dark':
        return ThemePreference.dark;
      default:
        return ThemePreference.light;
    }
  }
}

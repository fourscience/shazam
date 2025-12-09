class AppDateTime {
  const AppDateTime(this.rawValue);

  final String rawValue;

  String serialize() => rawValue;

  static AppDateTime deserialize(String input) => AppDateTime(input);
}

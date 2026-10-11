/// A string available in both interface languages.
class LocalizedText {
  const LocalizedText(this.ar, this.fr);

  final String ar;
  final String fr;

  String of(bool isAr) => isAr ? ar : fr;

  factory LocalizedText.fromJson(Object? json) {
    if (json is Map) {
      return LocalizedText(
        (json['ar'] ?? json['fr'] ?? '') as String,
        (json['fr'] ?? json['ar'] ?? '') as String,
      );
    }
    final text = (json as String?) ?? '';
    return LocalizedText(text, text);
  }

  Map<String, String> toJson() => {'ar': ar, 'fr': fr};
}

/// A list of strings available in both languages (program modules,
/// access conditions...).
class LocalizedList {
  const LocalizedList(this.ar, this.fr);

  final List<String> ar;
  final List<String> fr;

  List<String> of(bool isAr) => isAr ? ar : fr;

  static const empty = LocalizedList([], []);

  factory LocalizedList.fromJson(Object? json) {
    if (json is! Map) return empty;
    return LocalizedList(
      ((json['ar'] as List?) ?? const []).cast<String>(),
      ((json['fr'] as List?) ?? const []).cast<String>(),
    );
  }

  Map<String, List<String>> toJson() => {'ar': ar, 'fr': fr};
}

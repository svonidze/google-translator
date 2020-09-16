part of google_transl;

/// Translation returned from GoogleTranslator.translate method, containing the translated text, the source text, the translated language and the source language
abstract class Translation {
  final String text;
  final String source;
  final Language targetLanguage;
  final Language sourceLanguage;
  final List alternative;

  Translation._(this.text, this.source, this.sourceLanguage,
      this.targetLanguage, this.alternative);

  String operator +(other);

  @override
  String toString() => text;
}

class _Translation extends Translation {
  final String text;
  final String source;
  final Language sourceLanguage;
  final Language targetLanguage;
  final List alternative;

  _Translation(
    this.text, {
    this.sourceLanguage,
    this.targetLanguage,
    this.source,
    this.alternative,
  }) : super._(text, source, sourceLanguage, targetLanguage, alternative);

  String operator +(other) => this.toString() + other.toString();
}

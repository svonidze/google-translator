part of google_transl;

/// Transcription returned from GoogleTranslator.transcription method, containing the transcribed text, the source text, the transcribed language and the source language
abstract class Transcription {
  final String text;
  final String source;
  final Language targetLanguage;
  final Language sourceLanguage;

  Transcription._(this.text,
      this.source,
      this.sourceLanguage,
      this.targetLanguage,);

  String operator +(Transcription other);

  @override
  String toString() => text;
}

class _Transcription extends Transcription {
  @override
  final String text;
  @override
  final String source;
  @override
  final Language sourceLanguage;
  @override
  final Language targetLanguage;

  _Transcription(this.text, {
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.source,
  }) : super._(text, source, sourceLanguage, targetLanguage);

  @override
  String operator +(Transcription other) => toString() + other.toString();
}

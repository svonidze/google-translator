part of google_transl;

abstract class Definition {
  final Map<String, List<String>> definitions;
  final String source;
  final Language targetLanguage;
  final Language sourceLanguage;

  Definition._(
      this.definitions, this.source, this.sourceLanguage, this.targetLanguage);
}

class _Definition extends Definition {
  final Map<String, List<String>> definitions;
  final String source;
  final Language sourceLanguage;
  final Language targetLanguage;

  _Definition(this.definitions,
      {this.sourceLanguage, this.targetLanguage, this.source})
      : super._(definitions, source, sourceLanguage, targetLanguage);
}

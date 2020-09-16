part of google_transl;

abstract class Synonym {
  final List<String> synonyms;
  final String source;
  final Language targetLanguage;
  final Language sourceLanguage;

  Synonym._(
      this.synonyms, this.source, this.sourceLanguage, this.targetLanguage);
}

class _Synonym extends Synonym {
  final List<String> synonyms;
  final String source;
  final Language sourceLanguage;
  final Language targetLanguage;

  _Synonym(this.synonyms,
      {this.sourceLanguage, this.targetLanguage, this.source})
      : super._(synonyms, source, sourceLanguage, targetLanguage);
}

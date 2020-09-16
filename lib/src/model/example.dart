part of google_transl;

abstract class Example {
  final List<String> examples;
  final String source;
  final Language targetLanguage;
  final Language sourceLanguage;

  Example._(
      this.examples, this.source, this.sourceLanguage, this.targetLanguage);
}

class _Example extends Example {
  final List<String> examples;
  final String source;
  final Language sourceLanguage;
  final Language targetLanguage;

  _Example(this.examples,
      {this.sourceLanguage, this.targetLanguage, this.source})
      : super._(examples, source, sourceLanguage, targetLanguage);
}

library google_transl;

import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'package:http/http.dart' as http;
import './tokens/google_token_gen.dart';
import './langs/language.dart';

part './model/translation.dart';
part './model/definition.dart';
part './model/synonym.dart';
part './model/example.dart';
part './model/alternative_translation.dart';

///
/// This library is a Dart implementation of Google Translate API
///
/// [author] Gabriel N. Pacheco.
///
class GoogleTranslator {
  var _baseUrl = 'translate.googleapis.com'; // faster than translate.google.com
  final _path = '/translate_a/single';
  final _tokenProvider = GoogleTokenGenerator();
  final _languageList = LanguageList();
  final ClientType client;

  GoogleTranslator({this.client = ClientType.siteGT});

  Future<Translation> translate(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    var data = await _getData(sourceText, from: from, to: to, dataType: 't');

    final jsonData = jsonDecode(data.body);
    final sb = StringBuffer();

    for (var c = 0; c < jsonData[0].length; c++) {
      sb.write(jsonData[0][c][0]);
    }
    final translated = sb.toString();
    return _Translation(
      translated,
      source: sourceText,
      sourceLanguage: _languageList[from],
      targetLanguage: _languageList[to],
    );
  }

  Future<AlternativeTranslation> getAltTranslation(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    var data = await _getData(sourceText, from: from, to: to, dataType: 'at');
    final jsonData = jsonDecode(data.body);

    final List<String> words = [];

    if (jsonData[5] != null) {
      final List correctData = jsonData[5][0][2];
      for (final i in correctData) {
        words.add(i[0]);
      }
      return AlternativeTranslation(
        words,
        source: sourceText,
        sourceLanguage: _languageList[from],
        targetLanguage: _languageList[to],
      );
    } else {
      print('There are no alternative translations');
      return null;
    }
  }

  Future<Definition> getDefinition(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    final data = await _getData(sourceText, from: from, to: to, dataType: 'md');

    final jsonData = jsonDecode(data.body);

    Map<String, List<String>> definitionsMap = {};
    if (jsonData.length >= 12 && jsonData[12] != null) {
      final List list = jsonData[12];
      for (final i in list) {
        String title = i[0];
        List<String> definitions = [];
        List inList = i[1];
        for (final n in inList) {
          definitions.add(n[0]);
        }
        definitionsMap[title] = definitions;
      }
      return Definition(
        definitionsMap,
        source: sourceText,
        sourceLanguage: _languageList[from],
        targetLanguage: _languageList[to],
      );
    } else {
      print('There are no definitions');
      return null;
    }
  }

  Future<Synonym> getSynonyms(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    final data = await _getData(sourceText, from: from, to: to, dataType: 'ss');

    final jsonData = jsonDecode(data.body);

    List<String> filteredData = [];
    if (jsonData.length < 11) {
      print('There are no synonyms');
      return null;
    } else {
      for (final i in jsonData[11]) {
        for (final n in i[1]) {
          for (final t in n[0]) {
            filteredData.add(t);
          }
        }
      }
      filteredData.removeRange(5, filteredData.length);
    }
    return Synonym(
      filteredData,
      source: sourceText,
      targetLanguage: _languageList[to],
      sourceLanguage: _languageList[from],
    );
  }

  Future<Example> getExamples(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    final data = await _getData(sourceText, from: from, to: to, dataType: 'ex');

    final jsonData = jsonDecode(data.body);

    if (jsonData.length < 13) {
      print('There are no examples');
      return null;
    } else {
      List<String> list = [];
      for (final i in jsonData[13][0]) {
        String string = i[0];
        String formattedString =
            string.replaceAll('<b>$sourceText</b>', '$sourceText');
        list.add(formattedString);
      }
      return Example(
        list,
        source: sourceText,
        sourceLanguage: _languageList[from],
        targetLanguage: _languageList[to],
      );
    }
  }

  /// Translates and prints directly
  void translateAndPrint(String text,
      {String from = 'auto', String to = 'en'}) {
    translate(text, from: from, to: to).then(print);
  }

  /// Sets base URL for countries that default URL doesn't work
  void set baseUrl(String url) => _baseUrl = url;

  Future<http.Response> _getData(String sourceText,
      {String from, String to, String dataType}) async {
    for (var each in [from, to]) {
      if (!LanguageList.contains(each)) {
        throw LanguageNotSupportedException(each);
      }
    }

    final Map<String, String> parameters = {
      'client': client == ClientType.siteGT ? 't' : 'gtx',
      'sl': from,
      'tl': to,
      'hl': to,
      'dt': dataType,
      'ie': 'UTF-8',
      'oe': 'UTF-8',
      'otf': '1',
      'ssel': '0',
      'tsel': '0',
      'kc': '7',
      'tk': _tokenProvider.generateToken(sourceText),
      'q': sourceText
    };

    final url = Uri.https(_baseUrl, _path, parameters);
    final data = await http.get(url);

    if (data.statusCode != 200)
      throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);

    return data;
  }
}

enum ClientType {
  siteGT, // t
  extensionGT, // gtx (blocking ip sometimes)
}

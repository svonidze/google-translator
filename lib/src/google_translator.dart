library google_transl;

import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'package:http/http.dart' as http;
import './tokens/google_token_gen.dart';
import './langs/language.dart';

part './model/translation.dart';

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

  /// Translates texts from specified language to another
  Future<Translation> translate(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    for (var each in [from, to]) {
      if (!LanguageList.contains(each)) {
        throw LanguageNotSupportedException(each);
      }
    }

    final parameters = {
      'client': client == ClientType.siteGT ? 't' : 'gtx',
      'sl': from,
      'tl': to,
      'hl': to,
      'dt': 't',
      'ie': 'UTF-8',
      'oe': 'UTF-8',
      'otf': '1',
      'ssel': '0',
      'tsel': '0',
      'kc': '7',
      'tk': _tokenProvider.generateToken(sourceText),
      'q': sourceText
    };

    var url = Uri.https(_baseUrl, _path, parameters);
    final data = await http.get(url);

    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
    }

    final jsonData = jsonDecode(data.body);
    final sb = StringBuffer();

    for (var c = 0; c < jsonData[0].length; c++) {
      sb.write(jsonData[0][c][0]);
    }

    if (from == 'auto' && from != to) {
      from = jsonData[2] ?? from;
      if (from == to) {
        from = 'auto';
      }
    }

    final translated = sb.toString();
    final alternateTranslated = await _getAltTranslation(sourceText, from, to);
    final definition = await _getDefinition(sourceText, from, to);
    final synonyms = await _getSynonyms(sourceText, from, to);
    final examples = await _getExamples(sourceText, from, to);
    return _Translation(
      translated,
      alternateTranslated,
      definition,
      synonyms,
      examples,
      source: sourceText,
      sourceLanguage: _languageList[from],
      targetLanguage: _languageList[to],
    );
  }

  // Get alt. translation
  Future<List<String>> _getAltTranslation(
    String sourceText,
    String from,
    String to,
  ) async {
    final parameters = {
      'client': client == ClientType.siteGT ? 't' : 'gtx',
      'sl': from,
      'tl': to,
      'hl': to,
      'dt': 'at',
      'ie': 'UTF-8',
      'oe': 'UTF-8',
      'otf': '1',
      'ssel': '0',
      'tsel': '0',
      'kc': '7',
      'tk': _tokenProvider.generateToken(sourceText),
      'q': sourceText
    };

    var url = Uri.https(_baseUrl, _path, parameters);
    final data = await http.get(url);

    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
    }

    final jsonData = jsonDecode(data.body);
    if (jsonData[5] != null) {
      final List<String> tList = [];

      final List correctData = jsonData[5][0][2];

      for (int i = 0; i < correctData.length; i++) {
        tList.add(jsonData[5][0][2][i][0]);
      }
      return tList;
    } else {
      return null;
    }
  }

  // Get definition of text
  Future<Map<String, List<String>>> _getDefinition(
    String sourceText,
    String from,
    String to,
  ) async {
    final parameters = {
      'client': client == ClientType.siteGT ? 't' : 'gtx',
      'sl': from,
      'tl': to,
      'hl': to,
      'dt': 'md',
      'ie': 'UTF-8',
      'oe': 'UTF-8',
      'otf': '1',
      'ssel': '0',
      'tsel': '0',
      'kc': '7',
      'tk': _tokenProvider.generateToken(sourceText),
      'q': sourceText
    };

    var url = Uri.https(_baseUrl, _path, parameters);
    final data = await http.get(url);

    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
    }

    final jsonData = jsonDecode(data.body);

    Map<String, List<String>> definitionsMap = {};
    if (jsonData.length < 12)
      return null;
    else {
      if (jsonData[12] != null) {
        final List list = jsonData[12];
        for (int i = 0; i < list.length; i++) {
          String title = jsonData[12][i][0];
          List<String> definitions = [];
          List inList = jsonData[12][i][1];
          for (int n = 0; n < inList.length; n++)
            definitions.add(jsonData[12][i][1][n][0]);
          definitionsMap[title] = definitions;
        }
        return definitionsMap;
      } else
        return null;
    }
  }

  // Get synonyms
  Future<List> _getSynonyms(
    String sourceText,
    String from,
    String to,
  ) async {
    final parameters = {
      'client': client == ClientType.siteGT ? 't' : 'gtx',
      'sl': from,
      'tl': to,
      'hl': to,
      'dt': 'ss',
      'ie': 'UTF-8',
      'oe': 'UTF-8',
      'otf': '1',
      'ssel': '0',
      'tsel': '0',
      'kc': '7',
      'tk': _tokenProvider.generateToken(sourceText),
      'q': sourceText
    };

    var url = Uri.https(_baseUrl, _path, parameters);
    final data = await http.get(url);

    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
    }

    final jsonData = jsonDecode(data.body);

    List<String> filteredData = [];
    if (jsonData.length < 11)
      return null;
    else {
      for (int i = 0; i < jsonData[11].length; i++)
        for (int n = 0; n < jsonData[11][i][1].length; n++)
          for (int t = 0; t < jsonData[11][i][1][n][0].length; t++)
            filteredData.add(jsonData[11][i][1][n][0][t]);
    }
    return filteredData;
  }

  Future<List> _getExamples(
    String sourceText,
    String from,
    String to,
  ) async {
    final parameters = {
      'client': client == ClientType.siteGT ? 't' : 'gtx',
      'sl': from,
      'tl': to,
      'hl': to,
      'dt': 'ex',
      'ie': 'UTF-8',
      'oe': 'UTF-8',
      'otf': '1',
      'ssel': '0',
      'tsel': '0',
      'kc': '7',
      'tk': _tokenProvider.generateToken(sourceText),
      'q': sourceText
    };

    var url = Uri.https(_baseUrl, _path, parameters);
    final data = await http.get(url);

    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
    }

    final jsonData = jsonDecode(data.body);

    if (jsonData.length < 13)
      return null;
    else {
      List<String> list = [];
      for (int i = 0; i < jsonData[13][0].length; i++) {
        String string = jsonData[13][0][i][0];
        String formattedString =
            string.replaceAll('<b>$sourceText</b>', '$sourceText');
        list.add(formattedString);
      }
      return list;
    }
  }

  /// Translates and prints directly
  void translateAndPrint(String text,
      {String from = 'auto', String to = 'en'}) {
    translate(text, from: from, to: to).then(print);
  }

  /// Sets base URL for countries that default URL doesn't work
  void set baseUrl(String url) => _baseUrl = url;
}

enum ClientType {
  siteGT, // t
  extensionGT, // gtx (blocking ip sometimes)
}

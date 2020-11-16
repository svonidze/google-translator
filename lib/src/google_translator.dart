library google_transl;

import 'dart:async';
import 'dart:convert' show jsonDecode;

import 'package:http/http.dart' as http;

import './langs/language.dart';
import './tokens/google_token_gen.dart';

part './model/alternative_translation.dart';
part './model/definition.dart';
part './model/example.dart';
part './model/synonym.dart';
part './model/translation.dart';
part 'exception.dart';
part 'http_response_data.dart';

/**
 *
 * This library is a Dart implementation of Google Translate API
 *
 * [authors] Gabriel N. Pacheco, Timur Kim, Igor Komorkin
 *
 */
class GoogleTranslator {
  var _baseUrl = 'translate.googleapis.com'; // faster than translate.google.com
  final _path = '/translate_a/single';
  final _pronouncePath = '/translate_tts';
  final _tokenProvider = GoogleTokenGenerator();
  final _languageList = LanguageList();
  final ClientType client;
  final List<String> _dataTypes = ['ex', 'ss', 'md', 'at', 't'];

  GoogleTranslator({this.client = ClientType.siteGT});

  Future<Translation> getTranslation(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    final HttpResponseData httpResponseData =
        await _getData(sourceText, from: from, to: to, dataType: 't');

    final jsonData = httpResponseData.jsonData;
    final sb = StringBuffer();

    try {
      for (final i in jsonData[0]) {
        sb.write(i[0]);
      }
    } catch (e) {
      _throwException(
        0,
        httpResponseData,
        innerException: e,
      );
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
    final HttpResponseData httpResponseData =
    await _getData(sourceText, from: from, to: to, dataType: 'at');
    final jsonData = httpResponseData.jsonData;
    final List<String> words = [];
    try {
      final indexedData = jsonData[5][0][2];
      for (final i in indexedData) {
        words.add(i[0]);
      }
    } catch (e) {
      _throwException(
        5,
        httpResponseData,
        innerException: e,
      );
    }

    return AlternativeTranslation(
      words,
      source: sourceText,
      sourceLanguage: _languageList[from],
      targetLanguage: _languageList[to],
    );
  }

  Future<Definition> getDefinition(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    final HttpResponseData httpResponseData =
    await _getData(sourceText, from: from, to: to, dataType: 'md');

    final jsonData = httpResponseData.jsonData;
    Map<String, List<String>> definitionsMap = {};
    try {
      final indexedData = jsonData[12];
      for (final i in indexedData) {
        String title = i[0];
        List<String> definitions = [];
        List inList = i[1];
        for (final n in inList) {
          definitions.add(n[0]);
        }
        definitionsMap[title] = definitions;
      }
    } catch (e) {
      _throwException(
        12,
        httpResponseData,
        innerException: e,
      );
    }
    return Definition(
      definitionsMap,
      source: sourceText,
      sourceLanguage: _languageList[from],
      targetLanguage: _languageList[to],
    );
  }

  Future<Synonym> getSynonyms(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    final HttpResponseData httpResponseData =
    await _getData(sourceText, from: from, to: to, dataType: 'ss');

    final jsonData = httpResponseData.jsonData;
    List<String> filteredData = [];
    try {
      final indexedData = jsonData[11];
      for (final i in indexedData) {
        for (final n in i[1]) {
          for (final t in n[0]) {
            filteredData.add(t);
          }
        }
      }
    } catch (e) {
      _throwException(
        11,
        httpResponseData,
        innerException: e,
      );
    }
    filteredData.removeRange(5, filteredData.length);
    return Synonym(
      filteredData,
      source: sourceText,
      targetLanguage: _languageList[to],
      sourceLanguage: _languageList[from],
    );
  }

  Future<Example> getExamples(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    final HttpResponseData httpResponseData =
    await _getData(sourceText, from: from, to: to, dataType: 'ex');

    final jsonData = httpResponseData.jsonData;
    List<String> list = [];
    try {
      final indexedData = jsonData[13];
      for (final i in indexedData[0]) {
        String string = i[0];
        list.add(string);
      }
    } catch (e) {
      _throwException(
        13,
        httpResponseData,
        innerException: e,
      );
    }
    return Example(
      list,
      source: sourceText,
      sourceLanguage: _languageList[from],
      targetLanguage: _languageList[to],
    );
  }

  Future<Uri> getPronunciationUrl(String sourceText,
      {String from = 'auto', String to = 'en'}) async {
    final Map<String, String> parameters =
        await _getParameters(sourceText, from: from, to: to);

    final url = Uri.https(_baseUrl, _pronouncePath, parameters);
    return url;
  }

  /// Translates and prints directly
  void translateAndPrint(String text,
      {String from = 'auto', String to = 'en'}) {
    getTranslation(text, from: from, to: to).then(print);
  }

  /// Sets base URL for countries that default URL doesn't work
  void set baseUrl(String url) => _baseUrl = url;

  Future<HttpResponseData> _getData(String sourceText,
      {String from, String to, String dataType}) async {
    final Map<String, String> parameters = await _getParameters(sourceText,
        from: from, to: to, dataType: dataType);

    final uri = Uri.https(_baseUrl, _path, parameters);
    http.Response response;
    try {
      response = await http.get(uri);
    } catch (e, stacktrace) {
      throw Exception("Http get fail\n"
          "Request uri: $uri\n$e\n$stacktrace");
    }
    if (response == null)
      throw Exception("Http get fail, response is NULL\n"
          "Request uri: $uri\n${StackTrace.current}");

    if (response.statusCode != 200)
      throw http.ClientException(
          'Error ${response.statusCode}: ${response.body}', uri);

    final jsonData = jsonDecode(response.body);

    return HttpResponseData(
      jsonData: jsonData,
      requestUrl: uri,
      sourceText: sourceText,
      sourceLanguage: _languageList[from].name,
      targetLanguage: _languageList[to].name,
    );
  }

  Future<Map<String, String>> _getParameters(String sourceText,
      {String from, String to, String dataType}) async {
    for (var each in [from, to]) {
      if (!LanguageList.contains(each)) {
        throw LanguageNotSupportedException("$each");
      }
    }

    final Map<String, String> parameters = {
      'client': client == ClientType.siteGT ? 't' : 'gtx',
      'ie': 'UTF-8',
      'q': sourceText,
      'tk': _tokenProvider.generateToken(sourceText),
      'tl': to,
    };

    if (dataType == null) {
      parameters.addAll({
        'total': '1',
        'idx': '0',
        'textlen': '${sourceText.length}',
        'hint': from,
      });
    } else if (_dataTypes.any((element) => element == dataType)) {
      parameters.addAll({
        'sl': from,
        'hl': to,
        'dt': dataType,
        'oe': 'UTF-8',
        'otf': '1',
        'ssel': '0',
        'tsel': '0',
        'kc': '7',
      });
    } else {
      throw UnknownDataTypeException(
        'Passed data type is unknown or'
        ' incorrect\n${StackTrace.current}',
      );
    }

    return parameters;
  }

  WrongHttpResponseDataException _throwException(int index,
      HttpResponseData httpResponseData, {
        dynamic innerException,
      }) {
    String message;
    switch (index) {
      case 0:
        message = "Wrong HTTP response on translation request";
        break;
      case 5:
        message = "Wrong HTTP response on alternative translations request";
        break;
      case 11:
        message = "Wrong HTTP response on synonyms request";
        break;
      case 12:
        message = "Wrong HTTP response on definitions request";
        break;
      case 13:
        message = "Wrong HTTP response on examples request";
        break;
      default:
        message = "Wrong HTTP response data at index $index";
        break;
    }
    throw WrongHttpResponseDataException(
      "$message\n"
          "response data: $httpResponseData\n"
          "inner exception: $innerException",
      httpResponseData,
    );
  }
}

enum ClientType {
  siteGT, // t
  extensionGT, // gtx (blocking ip sometimes)
}

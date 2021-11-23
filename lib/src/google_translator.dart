library google_transl;

import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode, utf8;
import 'dart:developer';
import 'dart:io';

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
 * [authors] Gabriel N. Pacheco
 *
 */
class GoogleTranslator {
  final _map = {
    RequestType.translation: 0,
    RequestType.alternativeTranslation: 5,
    RequestType.synonym: 11,
    RequestType.definition: 12,
    RequestType.example: 13,
  };
  var _serverHost = 'translate.googleapis.com'; // faster
  //'translate.google.com';
  final _urlPath = '/translate_a/single';
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
      final indexedData = jsonData[_map[RequestType.translation]];
      for (final i in indexedData) {
        sb.write(i[0]);
      }
    } catch (e) {
      _throwException(
        RequestType.translation,
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
      final indexedData =
          jsonData[_map[RequestType.alternativeTranslation]][0][2];
      for (final i in indexedData) {
        words.add(i[0]);
      }
    } catch (e) {
      _throwException(
        RequestType.alternativeTranslation,
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
    Map<String, List<String>> definitionsMap = <String, List<String>>{};
    try {
      final indexedData = jsonData[_map[RequestType.definition]];
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
        RequestType.definition,
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
      final indexedData = jsonData[_map[RequestType.synonym]];
      for (final i in indexedData) {
        for (final n in i[1]) {
          for (final t in n[0]) {
            filteredData.add(t);
          }
        }
      }
    } catch (e) {
      _throwException(
        RequestType.synonym,
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
      final indexedData = jsonData[_map[RequestType.example]];
      for (final i in indexedData[0]) {
        String string = i[0];
        list.add(string);
      }
    } catch (e) {
      _throwException(
        RequestType.example,
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

    return Uri.https(_serverHost, _pronouncePath, parameters);
  }

  /// Translates and prints directly
  void translateAndPrint(String text,
      {String from = 'auto', String to = 'en'}) {
    getTranslation(text, from: from, to: to).then(print);
  }

  /// Sets base URL for countries that default URL doesn't work
  void set baseUrl(String url) => _serverHost = url;

  Future<HttpResponseData> _getData(String sourceText,
          {String from, String to, String dataType}) async =>
      _call(
          'GET',
          (String responseBody, Uri uri) => HttpResponseData(
                jsonData: jsonDecode(responseBody),
                requestUrl: uri,
                sourceText: sourceText,
                sourceLanguage: _languageList[from].name,
                targetLanguage: _languageList[to].name,
              ),
          queryParameters: await _getParameters(sourceText,
              from: from, to: to, dataType: dataType));

  Future<Map<String, String>> _getParameters(String sourceText,
      {String from, String to, String dataType}) async {
    for (var each in [from, to]) {
      if (!LanguageList.contains(each))
        throw LanguageNotSupportedException("$each");
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

  WrongHttpResponseDataException _throwException(
    RequestType requestType,
    HttpResponseData httpResponseData, {
    dynamic innerException,
  }) {
    throw WrongHttpResponseDataException(
      "Wrong HTTP response on ${requestType.toString().split(".")[1]} request\n"
      "$innerException\n"
      " response data: $httpResponseData",
      httpResponseData,
    );
  }

  Future<T> _call<T>(
    String method,
    T Function(String, Uri) convert, {
    String urlPath,
    Object payLoad,
    Map<String, String> queryParameters,
  }) async {
    final client = HttpClient();

    if (urlPath == null) urlPath = _urlPath;

    queryParameters?.removeWhere((key, value) => (value ?? 'null') == 'null');

    final uri = Uri.https(_serverHost, urlPath, queryParameters);
    print('$uri');
    return client.openUrl(method, uri).then((request) {
      if (payLoad != null) request.write(jsonEncode(payLoad));

      return request.close();
    }).then((response) {
      switch (response.statusCode) {
        case 200:
          final completer = Completer<String>();
          final contents = StringBuffer();
          response.transform(utf8.decoder).listen(
              (data) => contents.write(data),
              onDone: () => completer.complete(contents.toString()));
          return completer.future;
        case 503:
          throw Exception('$_serverHost overloaded, please retry later');
        default:
          log('$uri: ${response.statusCode} ${response.reasonPhrase}');
          throw Exception(
              '$_serverHost returned ${response.statusCode} ${response.reasonPhrase}');
      }
    }).then((responseBody) {
      print(responseBody);
      return convert(responseBody, uri);
    });
  }
}

enum ClientType {
  siteGT, // t
  extensionGT, // gtx (blocking ip sometimes)
}
enum RequestType {
  translation,
  alternativeTranslation,
  synonym,
  definition,
  example,
}

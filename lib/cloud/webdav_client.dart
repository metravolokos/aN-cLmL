import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:xml/xml.dart';

/// Secrets, HTTP bodies and private file names must never enter error text.
class CloudCredentials {
  const CloudCredentials(this.username, this.password);

  final String username;
  final String password;
}

enum CloudFailure { unauthorized, missingRoot, network, malformed, cancelled }

class CloudException implements Exception {
  const CloudException(this.reason);

  final CloudFailure reason;

  @override
  String toString() => 'CloudException(${reason.name})';
}

class CancellationToken {
  bool _cancelled = false;
  void Function()? _abort;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _abort?.call();
  }

  void _bind(void Function() abort) {
    _abort = abort;
    throwIfCancelled();
  }

  void _clear() => _abort = null;

  void throwIfCancelled() {
    if (_cancelled) throw const CloudException(CloudFailure.cancelled);
  }
}

class DavEntry {
  const DavEntry(this.uri, {required this.isCollection});

  final Uri uri;
  final bool isCollection;
}

abstract interface class CloudProbe {
  Future<void> checkRoot(
    CloudCredentials credentials, {
    CancellationToken? cancel,
  });
}

/// Production is pinned to HTTPS Cloud Mail.ru /AllMusic, without redirects.
/// A loopback-only constructor supports deterministic local fake-server tests.
class CloudWebDav implements CloudProbe {
  CloudWebDav({HttpClient Function()? clientFactory})
    : _root = Uri.parse('https://webdav.cloud.mail.ru/AllMusic/'),
      _clientFactory = clientFactory ?? HttpClient.new;

  CloudWebDav.forLoopbackTesting(
    Uri uri, {
    HttpClient Function()? clientFactory,
  }) : _root = uri,
       _clientFactory = clientFactory ?? HttpClient.new {
    if (uri.scheme != 'http' ||
        uri.host != '127.0.0.1' ||
        uri.path != '/AllMusic/') {
      throw ArgumentError('Invalid loopback test root');
    }
  }

  final Uri _root;
  final HttpClient Function() _clientFactory;
  static const _timeout = Duration(seconds: 15);
  static const maxRangeBytes = 128 * 1024;
  static const _maxXmlBytes = 512 * 1024;

  Uri _checkedUri(Uri uri) {
    if (uri.origin != _root.origin ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const CloudException(CloudFailure.malformed);
    }
    final segments = uri.pathSegments;
    if (segments.isEmpty || segments.first != 'AllMusic') {
      throw const CloudException(CloudFailure.malformed);
    }
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s == '.' ||
          s == '..' ||
          s.contains('/') ||
          s.contains('\\') ||
          (s.isEmpty && i != segments.length - 1)) {
        throw const CloudException(CloudFailure.malformed);
      }
    }
    return uri;
  }

  Uri _fromHref(String raw) {
    final href = Uri.parse(raw.trim());
    if (href.hasScheme || href.hasAuthority) {
      return _checkedUri(href);
    }
    if (!raw.trim().startsWith('/')) {
      throw const CloudException(CloudFailure.malformed);
    }
    return _checkedUri(_root.resolveUri(href));
  }

  Future<_DavResponse> _request(
    String method,
    Uri uri,
    CloudCredentials credentials, {
    String? depth,
    String? range,
    CancellationToken? cancel,
    int maxBytes = _maxXmlBytes,
  }) async {
    cancel?.throwIfCancelled();
    _checkedUri(uri);
    final client = _clientFactory();
    client.connectionTimeout = const Duration(seconds: 8);
    HttpClientRequest? request;
    cancel?._bind(() {
      request?.abort();
      client.close(force: true);
    });
    try {
      request = await client.openUrl(method, uri).timeout(_timeout);
      cancel?.throwIfCancelled();
      request.followRedirects = false;
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Basic ${base64.encode(utf8.encode('${credentials.username}:${credentials.password}'))}',
      );
      if (depth != null) {
        request.headers.set('Depth', depth);
        request.headers.contentType = ContentType(
          'application',
          'xml',
          charset: 'utf-8',
        );
        request.write(
          '<?xml version="1.0" encoding="utf-8"?>'
          '<d:propfind xmlns:d="DAV:"><d:allprop/></d:propfind>',
        );
      }
      if (range != null) request.headers.set(HttpHeaders.rangeHeader, range);
      final response = await request.close().timeout(_timeout);
      cancel?.throwIfCancelled();
      final contentRange = response.headers.value(
        HttpHeaders.contentRangeHeader,
      );
      if (response.isRedirect ||
          (response.statusCode >= 300 && response.statusCode < 400)) {
        throw const CloudException(CloudFailure.malformed);
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const CloudException(CloudFailure.unauthorized);
      }
      if (response.statusCode == 404) {
        throw const CloudException(CloudFailure.missingRoot);
      }
      if (response.statusCode != 207 && response.statusCode != 206) {
        throw const CloudException(CloudFailure.network);
      }
      if (response.headers.contentLength > maxBytes) {
        throw const CloudException(CloudFailure.malformed);
      }
      final bytes = BytesBuilder(copy: false);
      Future<void> readAll() async {
        await for (final chunk in response) {
          cancel?.throwIfCancelled();
          if (bytes.length + chunk.length > maxBytes) {
            throw const CloudException(CloudFailure.malformed);
          }
          bytes.add(chunk);
        }
      }
      await readAll().timeout(_timeout);
      cancel?.throwIfCancelled();
      return _DavResponse(response.statusCode, contentRange, bytes.takeBytes());
    } on CloudException {
      rethrow;
    } on TimeoutException {
      throw const CloudException(CloudFailure.network);
    } on Object {
      if (cancel?.isCancelled ?? false) {
        throw const CloudException(CloudFailure.cancelled);
      }
      throw const CloudException(CloudFailure.network);
    } finally {
      cancel?._clear();
      client.close(force: true);
    }
  }

  /// Depth 0/1 only; all returned hrefs are validated against /AllMusic.
  Future<List<DavEntry>> propfind(
    CloudCredentials credentials, {
    int depth = 0,
    CancellationToken? cancel,
  }) async {
    if (depth != 0 && depth != 1) throw ArgumentError.value(depth, 'depth');
    final response = await _request(
      'PROPFIND',
      _root,
      credentials,
      depth: '$depth',
      cancel: cancel,
    );
    if (response.status != 207) {
      throw const CloudException(CloudFailure.malformed);
    }
    try {
      final document = XmlDocument.parse(utf8.decode(response.body));
      final root = document.rootElement;
      if (root.name.local != 'multistatus' ||
          root.name.namespaceUri != 'DAV:') {
        throw const CloudException(CloudFailure.malformed);
      }
      final entries = <DavEntry>[];
      for (final item in root.childElements) {
        if (item.name.local != 'response' || item.name.namespaceUri != 'DAV:') {
          continue;
        }
        final hrefs = item.childElements.where(
          (e) => e.name.local == 'href' && e.name.namespaceUri == 'DAV:',
        );
        if (hrefs.length != 1) {
          throw const CloudException(CloudFailure.malformed);
        }
        final uri = _fromHref(hrefs.single.innerText);
        final collection = item.descendantElements.any(
          (e) => e.name.local == 'collection' && e.name.namespaceUri == 'DAV:',
        );
        entries.add(DavEntry(uri, isCollection: collection));
      }
      if (!entries.any(
        (e) =>
            e.uri.pathSegments.where((s) => s.isNotEmpty).length == 1 &&
            e.uri.pathSegments.first == 'AllMusic' &&
            e.isCollection,
      )) {
        throw const CloudException(CloudFailure.malformed);
      }
      return entries;
    } on CloudException {
      rethrow;
    } on Object {
      throw const CloudException(CloudFailure.malformed);
    }
  }

  @override
  Future<void> checkRoot(
    CloudCredentials credentials, {
    CancellationToken? cancel,
  }) async {
    await propfind(credentials, depth: 0, cancel: cancel);
  }

  /// Bounded read, used for small metadata chunks in future milestones.
  Future<Uint8List> getRange(
    CloudCredentials credentials,
    List<String> relativeSegments, {
    required int offset,
    required int length,
    CancellationToken? cancel,
  }) async {
    if (offset < 0 ||
        length < 1 ||
        length > maxRangeBytes ||
        relativeSegments.isEmpty ||
        relativeSegments.any(
          (s) =>
              s.isEmpty ||
              s == '.' ||
              s == '..' ||
              s.contains('/') ||
              s.contains('\\'),
        )) {
      throw ArgumentError('Invalid bounded range or path');
    }
    final uri = _checkedUri(
      _root.replace(pathSegments: ['AllMusic', ...relativeSegments]),
    );
    final response = await _request(
      'GET',
      uri,
      credentials,
      range: 'bytes=$offset-${offset + length - 1}',
      maxBytes: length,
      cancel: cancel,
    );
    if (response.status != 206) {
      throw const CloudException(CloudFailure.malformed);
    }
    final match = RegExp(
      r'^bytes[ =](\d+)-(\d+)/(\d+)$',
    ).firstMatch(response.contentRange ?? '');
    if (match == null) throw const CloudException(CloudFailure.malformed);
    final start = int.tryParse(match.group(1)!);
    final end = int.tryParse(match.group(2)!);
    final total = int.tryParse(match.group(3)!);
    if (start != offset ||
        end != offset + length - 1 ||
        total == null ||
        total <= end! ||
        response.body.length != length) {
      throw const CloudException(CloudFailure.malformed);
    }
    return response.body;
  }
}

class _DavResponse {
  const _DavResponse(this.status, this.contentRange, this.body);

  final int status;
  final String? contentRange;
  final Uint8List body;
}

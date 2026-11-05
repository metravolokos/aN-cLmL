import 'dart:async';
import 'dart:io';

import 'package:cloudmail_player/cloud/webdav_client.dart';
import 'package:flutter_test/flutter_test.dart';

const credentials = CloudCredentials(
  'tester@example.invalid',
  'fake-app-password',
);

const rootXml =
    '<?xml version="1.0"?>'
    '<D:multistatus xmlns:D="DAV:">'
    '<D:response><D:href>/AllMusic/</D:href><D:propstat>'
    '<D:prop><D:resourcetype><D:collection/></D:resourcetype></D:prop>'
    '<D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>'
    '</D:multistatus>';

Future<T> withServer<T>(
  Future<void> Function(HttpRequest request) handler,
  Future<T> Function(CloudWebDav client) check,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    try {
      await handler(request);
    } on Object {
      try {
        await request.response.close();
      } on Object {
        // The client may have cancelled its request.
      }
    }
  });
  try {
    return await check(
      CloudWebDav.forLoopbackTesting(
        Uri.parse('http://127.0.0.1:' + server.port.toString() + '/AllMusic/'),
      ),
    );
  } finally {
    await server.close(force: true);
  }
}

Future<void> reply(HttpRequest request, int code, String body) async {
  await request.drain<void>();
  request.response.statusCode = code;
  request.response.write(body);
  await request.response.close();
}

Matcher cloudFailure(CloudFailure kind) =>
    isA<CloudException>().having((e) => e.reason, 'reason', kind);

void main() {
  test('read-only 207 PROPFIND, Depth 0 and HTTP Basic auth', () async {
    String? method;
    String? depth;
    String? authorization;
    await withServer((request) async {
      method = request.method;
      depth = request.headers.value('depth');
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      await reply(request, 207, rootXml);
    }, (client) async => client.checkRoot(credentials));
    expect(method, 'PROPFIND');
    expect(depth, '0');
    expect(authorization, startsWith('Basic '));
  });

  test('Depth 1 parses Cyrillic URI and namespaced href', () async {
    final xml = rootXml.replaceFirst(
      '</D:multistatus>',
      '<D:response><D:href>/AllMusic/%D0%A2%D1%80%D0%B5%D0%BA.flac'
          '</D:href></D:response></D:multistatus>',
    );
    final entries = await withServer(
      (r) => reply(r, 207, xml),
      (client) => client.propfind(credentials, depth: 1),
    );
    expect(entries.length, 2);
    expect(entries.last.uri.pathSegments.last, 'Трек.flac');
  });

  test('401 and 403 reject authentication without logging secrets', () async {
    for (final status in [401, 403]) {
      await withServer(
        (r) => reply(r, status, ''),
        (client) => expectLater(
          client.checkRoot(credentials),
          throwsA(cloudFailure(CloudFailure.unauthorized)),
        ),
      );
    }
  });

  test('404 identifies a missing /AllMusic collection', () async {
    await withServer(
      (r) => reply(r, 404, ''),
      (client) => expectLater(
        client.checkRoot(credentials),
        throwsA(cloudFailure(CloudFailure.missingRoot)),
      ),
    );
  });

  test(
    'malformed XML, wrong namespace and escaping href fail closed',
    () async {
      for (final xml in [
        '<D:multistatus xmlns:D="DAV:"><oops>',
        '<D:multistatus xmlns:D="bad"></D:multistatus>',
        rootXml.replaceFirst(
          '</D:multistatus>',
          '<D:response><D:href>/Elsewhere/music.flac</D:href>'
              '</D:response></D:multistatus>',
        ),
        rootXml.replaceFirst(
          '</D:multistatus>',
          '<D:response><D:href>https://evil.invalid/AllMusic/x.flac'
              '</D:href></D:response></D:multistatus>',
        ),
      ]) {
        await withServer(
          (r) => reply(r, 207, xml),
          (client) => expectLater(
            client.checkRoot(credentials),
            throwsA(cloudFailure(CloudFailure.malformed)),
          ),
        );
      }
    },
  );

  test('rejects redirect and does not forward Basic credentials', () async {
    await withServer(
      (r) async {
        await r.drain<void>();
        r.response.statusCode = 302;
        r.response.headers.set(
          HttpHeaders.locationHeader,
          'https://evil.invalid/AllMusic/',
        );
        await r.response.close();
      },
      (client) => expectLater(
        client.checkRoot(credentials),
        throwsA(cloudFailure(CloudFailure.malformed)),
      ),
    );
  });

  test(
    'bounded GET accepts standard and Mail.ru Content-Range syntax',
    () async {
      for (final header in ['bytes=0-3/100', 'bytes 0-3/100']) {
        await withServer(
          (r) async {
            expect(r.method, 'GET');
            expect(r.headers.value(HttpHeaders.rangeHeader), 'bytes=0-3');
            await r.drain<void>();
            r.response.statusCode = 206;
            r.response.headers.set(HttpHeaders.contentRangeHeader, header);
            r.response.add([1, 2, 3, 4]);
            await r.response.close();
          },
          (client) async {
            final result = await client.getRange(
              credentials,
              ['Трек.flac'],
              offset: 0,
              length: 4,
            );
            expect(result, [1, 2, 3, 4]);
          },
        );
      }
    },
  );

  test('rejects wrong 206 framing and excess response bytes', () async {
    for (final header in ['bytes=1-4/100', 'bytes */100', 'bytes=0-3/3']) {
      await withServer(
        (r) async {
          await r.drain<void>();
          r.response.statusCode = 206;
          r.response.headers.set(HttpHeaders.contentRangeHeader, header);
          r.response.add([1, 2, 3, 4]);
          await r.response.close();
        },
        (client) => expectLater(
          client.getRange(credentials, ['test.flac'], offset: 0, length: 4),
          throwsA(cloudFailure(CloudFailure.malformed)),
        ),
      );
    }
    await withServer(
      (r) async {
        await r.drain<void>();
        r.response.statusCode = 206;
        r.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes=0-3/100');
        r.response.add([1, 2, 3, 4, 5]);
        await r.response.close();
      },
      (client) => expectLater(
        client.getRange(credentials, ['test.flac'], offset: 0, length: 4),
        throwsA(cloudFailure(CloudFailure.malformed)),
      ),
    );
  });

  test('rejects overlimit ranges and traversal before network', () async {
    final client = CloudWebDav();
    expect(
      () => client.getRange(credentials, ['../../etc'], offset: 0, length: 4),
      throwsArgumentError,
    );
    expect(
      () => client.getRange(credentials, ['x'], offset: 0, length: 131073),
      throwsArgumentError,
    );
  });

  test('cancellation rejects a pending operation', () async {
    final served = Completer<void>();
    final token = CancellationToken();
    await withServer(
      (r) async {
        await r.drain<void>();
        served.complete();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await reply(r, 207, rootXml);
      },
      (client) async {
        final pending = client.checkRoot(credentials, cancel: token);
        await served.future;
        token.cancel();
        await expectLater(
          pending,
          throwsA(cloudFailure(CloudFailure.cancelled)),
        );
      },
    );
  });
}

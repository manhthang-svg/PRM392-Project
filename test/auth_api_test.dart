import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origami/core/auth/auth_api.dart';

void main() {
  test('logout sends only the refresh token', () async {
    final dio = Dio();
    RequestOptions? captured;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<void>(requestOptions: options, statusCode: 200),
          );
        },
      ),
    );

    await AuthApi(dio: dio).logout(refreshToken: 'refresh-token');

    expect(captured?.path, '/api/auth/logout');
    expect(captured?.headers['Authorization'], isNull);
    expect(captured?.data, {'refreshToken': 'refresh-token'});
  });
}

import 'package:http/http.dart' as http;

import 'app_http_client_stub.dart'
    if (dart.library.io) 'app_http_client_io.dart';

http.Client createAppHttpClient() => createPlatformHttpClient();

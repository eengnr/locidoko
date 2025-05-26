import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

late CacheManager _cacheManager;
Future<void> initCacheManager() async {
  final cacheDir = await getApplicationCacheDirectory();
  _cacheManager = CacheManager(
    Config(
      cacheDir.path,
      stalePeriod: Duration(days: 7),
    ),
  );
}

CacheManager getCacheManager() {
  return _cacheManager;
}

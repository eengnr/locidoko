// Transformed from https://github.com/openstreetmap/openstreetmap-website/blob/e84b2bd22f7c92fb7a128a91c999f86e350bf04d/app/assets/javascripts/application.js

int interlace(int x, int y) {
  x = (x | (x << 8)) & 0x00ff00ff;
  x = (x | (x << 4)) & 0x0f0f0f0f;
  x = (x | (x << 2)) & 0x33333333;
  x = (x | (x << 1)) & 0x55555555;

  y = (y | (y << 8)) & 0x00ff00ff;
  y = (y | (y << 4)) & 0x0f0f0f0f;
  y = (y | (y << 2)) & 0x33333333;
  y = (y | (y << 1)) & 0x55555555;

  return (x << 1) | y;
}

String makeShortCode(double lat, double lon, int zoom) {
  String charArray =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~";
  int x = ((lon + 180.0) * ((1 << 30) / 90.0)).round();
  int y = ((lat + 90.0) * ((1 << 30) / 45.0)).round();
  String str = "";
  int c1 = interlace(x >> 17, y >> 17),
      c2 = interlace((x >> 2) & 0x7fff, (y >> 2) & 0x7fff);
  for (int i = 0; i < ((zoom + 8) / 3.0).ceil() && i < 5; ++i) {
    int digit = (c1 >> (24 - 6 * i)) & 0x3f;
    str += charArray[digit];
  }
  for (int i = 5; i < ((zoom + 8) / 3.0).ceil(); ++i) {
    int digit = (c2 >> (24 - 6 * (i - 5))) & 0x3f;
    str += charArray[digit];
  }
  for (int i = 0; i < ((zoom + 8) % 3); ++i) {
    str += "-";
  }
  return str;
}

String makeSafeShortCode(double lat, double lon, int zoom) {
  String str = makeShortCode(lat, lon, zoom);
  if (str.contains('~')) {
    // ~ is not URL safe, but even the OSM map calculates it
    // if forced with coordinates.
    // OSM map additionally moves a little bit if coordinates would generate
    // a ~.
    // ~ breaks URLs in posts, therefore shift lon slightly.
    str = makeSafeShortCode(lat, lon + 0.000002, zoom);
  }
  return str;
}

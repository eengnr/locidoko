import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constants.dart';
import 'helpers.dart';
import 'icons.dart';
import 'poststatus.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key, required this.title});

  final String title;

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Future<String> _getOverpassUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String overpassUrl = prefs.getString('overpass_url') ?? overpassDefaultUrl;
    if (overpassUrl.endsWith('/')) {
      overpassUrl = overpassUrl.substring(0, overpassUrl.length - 1);
    }
    return '$overpassUrl/api/interpreter';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.i('Loading');
      _loadLocations();
    });
  }

  final logger = Logger();

  /* Final list for POIs around current location */
  List<dynamic> poisAround = [];
  bool loading = true;
  String _error = '';

  /* Query for loading results */
  static const String overpassQueryStart = '[out:json][timeout:44];';

  /* Search radius */
  static const int searchRadius = 150;
  static const int mediumFactor = 2;
  static const int bigFactor = 10;

  /* Search results for each query */
  static const int searchResults = 300;
  static const String overpassLocation = '(around:RADIUS,LATITUDE,LONGITUDE);';
  static const String overpassOutParams = 'out center qt RESULTS';

  /* Load results for these tags one by one 
     This needs to be done anyways, because otherwise we get a HTTP 414 from Overpass
  */

  // Queries for tags within the search radius
  static const List<String> overpassQueries = [
    'tourism',
    'amenity',
    'natural',
    'leisure',
    'shop',
    //
    'public_transport',
    'landuse',
    'office',
    'craft',
    'man_made',
    'aeroway',
    'power',
    'building',
    'historic',
    //
    'place',
    //
    'route',
    'boundary',
  ];

  static const List<String> overpassMediumQueries = [
    'zoo',
  ];

  // Queries for tags within 10 times the search radius
  static const List<String> overpassBigQueries = [
    'aerodrome',
    'aerodrome:type',
  ];

  // Exclude these tags from the query
  static const List<String> overpassIgnoreTags = [
    'amenity=vending_machine',
    'public_transport=stop_position',
    'public_transport=stop_area',
    'type=route',
    'type=boundary',
  ];

  /* Calculate the distance between two coordinates */
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // I could use the method of geolocator package as well... :)
    const int R = 6371000; // Radius of Earth in m

    // Calculate distance c
    final double phi1 = lat1 * pi / 180;
    final double phi2 = lat2 * pi / 180;
    final double deltaPhi = (lat2 - lat1) * pi / 180;
    final double deltaLambda = (lon2 - lon1) * pi / 180;

    final double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Distance c on Earth
    return R * c;
  }

  Future<Position?> _getDevicePosition() async {
    // Method A) With native permission + service handling,
    // compatible with Android only.
    // I'll leave this commented out for documentation purposes.
    // Use package:flutter/services.dart and package:permission_handler
    // See also part in MainActivity.kt
    /*
    Map<String, double?> devicePosition = {'latitude': 0, 'longitude': 0};
      final PermissionStatus locationPermissionStatus =
          await Permission.locationWhenInUse.request();
      if (locationPermissionStatus.isGranted) {
        const channel = MethodChannel('loci.doko.locidoko/getlocation');

        final Future<dynamic> result = channel.invokeMethod('getLocation');
        final dynamic location = await result;
        devicePosition['latitude'] = location['latitude'];
        devicePosition['longitude'] = location['longitude'];

        logger.d('Location method result: ${location.toString()}');
      } else {
        throw Exception('Location permission not granted.');
      }

      double? deviceLatitude = devicePosition['latitude'];
      double? deviceLongitude = devicePosition['longitude'];
    */

    // Method B) With geolocator package,
    // compatible with all platforms.

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions permanently denied.',
      );
    }

    Position? devicePosition;

    // Add a try/catch, because the geolocator fork without GMS
    // does not provide a coarse loaction when getCurrentPosition() is called
    try {
      devicePosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } catch (e) {
      logger.w('Could not get current position, try last known position.');
      devicePosition = await Geolocator.getLastKnownPosition();
    }

    logger.d(devicePosition);

    return devicePosition;
  }

  Future<void> _loadLocations() async {
    logger.i('Load locations now');
    setState(() {
      loading = true;
      _error = '';
    });

    try {
      // Init langdetect and position
      await langdetect.initLangDetect();
      Position? devicePosition = await _getDevicePosition();

      final double deviceLatitude = devicePosition?.latitude ?? 0;
      final double deviceLongitude = devicePosition?.longitude ?? 0;

      if (deviceLatitude == 0 && deviceLongitude == 0) {
        throw Exception('Coordinates are still 0.');
      }

      /* List which will be filled with results */
      List<dynamic> overpassResults = [];

      /* Load all results */
      String overpassQuery = '$overpassQueryStart\n(\n(\n';
      // Add tags to search
      for (final query in overpassQueries) {
        overpassQuery +=
            'nwr["name"]["$query"]${overpassLocation.replaceAll('RADIUS', searchRadius.toString()).replaceAll('LATITUDE', deviceLatitude.toString()).replaceAll('LONGITUDE', deviceLongitude.toString())}\n';
      }
      // Add tags with medium radius to search
      for (final query in overpassMediumQueries) {
        overpassQuery +=
            'nwr["name"]["$query"]${overpassLocation.replaceAll('RADIUS', (searchRadius * mediumFactor).toString()).replaceAll('LATITUDE', deviceLatitude.toString()).replaceAll('LONGITUDE', deviceLongitude.toString())}\n';
      }
      // Add tags with large radius to search
      for (final query in overpassBigQueries) {
        overpassQuery +=
            'nwr["name"]["$query"]${overpassLocation.replaceAll('RADIUS', (searchRadius * bigFactor).toString()).replaceAll('LATITUDE', deviceLatitude.toString()).replaceAll('LONGITUDE', deviceLongitude.toString())}\n';
      }
      // Remove tags from query
      overpassQuery += ');\n-\n(\n';
      for (final type in overpassIgnoreTags) {
        overpassQuery +=
            'nwr[$type]${overpassLocation.replaceAll('RADIUS', searchRadius.toString()).replaceAll('LATITUDE', deviceLatitude.toString()).replaceAll('LONGITUDE', deviceLongitude.toString())}\n';
      }
      overpassQuery +=
          ');\n);\n${overpassOutParams.replaceAll('RESULTS', searchResults.toString())};';
      logger.d(overpassQuery);

      String overpassUrlRequest = await _getOverpassUrl();

      logger.d('Loading from API $overpassUrlRequest');

      final overpassResponse = await http.post(
        Uri.parse(overpassUrlRequest),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': locidokoUserAgent,
        },
        body: {'data': overpassQuery},
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () async {
          throw Exception('Timed out after 45 seconds');
        },
      );

      if (overpassResponse.statusCode == 200) {
        dynamic resultJson = jsonDecode(overpassResponse.body);
        try {
          List<int> jsonBytes = overpassResponse.body.codeUnits;
          String decodedJsonString =
              utf8.decode(jsonBytes, allowMalformed: false);
          resultJson = jsonDecode(decodedJsonString);
        } catch (e) {
          logger.i('Failed to decode response: $e');
        }
        overpassResults.addAll(resultJson['elements']);
      } else {
        throw Exception(
          'Failed to get response: ${overpassResponse.statusCode}',
        );
      }

      poisAround = _normalizeOsmLocations(
        overpassResults,
        deviceLatitude,
        deviceLongitude,
      );

      if (mounted) {
        setState(() {
          poisAround;
          loading = false;
        });
      }
    } catch (e) {
      logger.e('Error $e');
      setState(() {
        _error = 'SID_LOCATIONS_ERROR_LOCATIONS_LOAD';
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _normalizeOsmLocations(
    List locationList,
    double latitude,
    double longitude,
  ) {
    List<Map<String, dynamic>> normalizedList = [];
    for (Map<String, dynamic> entry in locationList) {
      logger.d(entry);
      Map<String, dynamic> normalizedEntry = {};

      /* Check lat/lon, mandatory and should always be available */
      if (entry.containsKey('lat') && entry.containsKey('lon')) {
        normalizedEntry['lat'] = entry['lat'];
        normalizedEntry['lon'] = entry['lon'];
      } else if (entry.containsKey('center') &&
          entry['center'].containsKey('lat') &&
          entry['center'].containsKey('lon')) {
        normalizedEntry['lat'] = entry['center']['lat'];
        normalizedEntry['lon'] = entry['center']['lon'];
      } else {
        continue;
      }

      /* ID & type, always available */
      normalizedEntry['id'] = entry['id'];
      normalizedEntry['type'] = entry['type'];

      /* Check tags, mandatory */
      if (entry.containsKey('tags')) {
        /* Check name, mandatory */
        String language = Get.deviceLocale?.languageCode ?? '';
        RegExp nonLatinChars = RegExp(r'[^\x00-\x7F]+');

        // Name:language (Regional Name:language)
        if (entry['tags'].containsKey('reg_name:$language') &&
            entry['tags'].containsKey('name:$language')) {
          normalizedEntry['name'] =
              '${entry['tags']['name:$language']} (${entry['tags']['reg_name:$language']})';
        } else
        // Name:language
        if (entry['tags'].containsKey('name:$language')) {
          normalizedEntry['name'] = entry['tags']['name:$language'];
        } else
        // If name does not match device language and is non-latin, use name:en
        // The langdetect is not optimal for short texts, but it's a good compromise
        if (entry['tags'].containsKey('name:en') &&
            entry['tags'].containsKey('name') &&
            nonLatinChars.hasMatch(entry['tags']['name']) &&
            langdetect.detect(entry['tags']['name']) != language) {
          normalizedEntry['name'] = entry['tags']['name:en'];
        } else
        // Name (Regional Name)
        if (entry['tags'].containsKey('reg_name') &&
            entry['tags'].containsKey('name')) {
          normalizedEntry['name'] =
              '${entry['tags']['name']} (${entry['tags']['reg_name']})';
        } else
        // Name
        if (entry['tags'].containsKey('name')) {
          normalizedEntry['name'] = entry['tags']['name'];
        }
        // No name found
        else {
          continue;
        }

        // Combine tags from query lists into one list
        // Sorted from more specific to less specific
        final List<String> combinedOverpassQueries = [
          ...overpassBigQueries,
          ...overpassMediumQueries,
          ...overpassQueries,
        ];

        /* Check category, mandatory */
        for (String key in combinedOverpassQueries) {
          if (entry['tags'].containsKey(key)) {
            logger
                .d('Matching tag $key found with value ${entry['tags'][key]}.');
            normalizedEntry['category'] = entry['tags'][key];
            // Distinguish 'highway' and 'railway' platform
            if (entry['tags'][key] == 'platform') {
              if (entry['tags'].containsKey('highway')) {
                normalizedEntry['category'] = '${entry['tags'][key]}-highway';
              } else if (entry['tags'].containsKey('railway')) {
                normalizedEntry['category'] = '${entry['tags'][key]}-railway';
              }
            }
            // Artwork
            if (entry['tags'][key] == 'artwork' &&
                entry['tags'].containsKey('artwork_type')) {
              normalizedEntry['category'] = entry['tags']['artwork_type'];
            }
            // Restaurant
            if ((entry['tags'][key] == 'restaurant' ||
                    entry['tags'][key] == 'fast_food' ||
                    entry['tags'][key] == 'cafe') &&
                entry['tags'].containsKey('cuisine')) {
              final cuisine = entry['tags']['cuisine'].split(';')[0];
              if (poiEmoji(cuisine) != '📍') {
                normalizedEntry['category'] = cuisine;
              }
            }
            // Place of worship
            if (entry['tags'][key] == 'place_of_worship' &&
                entry['tags'].containsKey('building')) {
              final building = entry['tags']['building'].split(';')[0];
              if (poiEmoji(building) != '📍') {
                normalizedEntry['category'] = building;
              }
            }
            // If value of key is 'yes', use key instead of value
            if (entry['tags'][key] == 'yes') {
              normalizedEntry['category'] = key;
            }
            // Don't check any further tags
            break;
          }
        }
        if (!normalizedEntry.containsKey('category')) {
          logger.i(
            'No type found for ${entry['tags']['name']}:  ${entry['tags']}',
          );
          // Go on with next entry and don't add this one to the list
          continue;
        }

        /* Check description, optional */
        if (entry['tags'].containsKey('description:$language')) {
          normalizedEntry['description'] =
              entry['tags']['description:$language'];
        } else if (entry['tags'].containsKey('description')) {
          normalizedEntry['description'] = entry['tags']['description'];
        }

        /* Check address, optional */
        normalizedEntry['addr:city'] = entry['tags']['addr:city'];
        normalizedEntry['addr:place'] = entry['tags']['addr:place'];
        normalizedEntry['addr:street'] = entry['tags']['addr:street'];
        normalizedEntry['addr:housenumber'] = entry['tags']['addr:housenumber'];
        normalizedEntry['addr:postcode'] = entry['tags']['addr:postcode'];

        /* Check website, optional */
        normalizedEntry['website'] = entry['tags']['website'];
      } else {
        // Don't add entry if no tags are available at all
        continue;
      }
      // Add entry if all mandatory data is available
      normalizedList.add(normalizedEntry);
    }

    /* Sort by distance */
    for (Map<String, dynamic> entry in normalizedList) {
      double distanceInMeters = _calculateDistance(
        latitude,
        longitude,
        entry['lat'],
        entry['lon'],
      );
      entry['distance'] = distanceInMeters;
    }
    normalizedList.sort((a, b) => a['distance'].compareTo(b['distance']));

    logger.d('Nomalized results:');
    for (Map<String, dynamic> entry in normalizedList) {
      logger.d(entry);
    }
    logger.d('Results: ${normalizedList.length}');

    return normalizedList;
  }

  void _postStatus(poiData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PostStatusPage(title: 'SID_POSTSTATUS_TITLE', poi: poiData),
      ),
    );
  }

  void _popupPoiDetails(poiData) {
    showPoiDetailsPopup(context, mounted, poiData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: poisAround.isEmpty
            ? Text(widget.title.tr)
            : Text('${widget.title.tr} (${poisAround.length})'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLocations,
        child: loading && poisAround.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : poisAround.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            height: 250, // Set height to 100 pixels
                            child: SvgPicture.string(
                              emojiSvg(_error == '' ? '🐱' : '😿'),
                            ),
                          ),
                          Text(
                            _error == ''
                                ? 'SID_LOCATIONS_NO_LOCATIONS_FOUND'.tr
                                : _error.tr,
                            style: const TextStyle(
                              fontSize: 20, // Specify your text size here
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: <Widget>[
                      ListView.separated(
                        itemCount: poisAround.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              8.0,
                              8.0,
                              8.0,
                              // More padding for last item
                              index != poisAround.length - 1
                                  ? 8.0
                                  : MediaQuery.of(context).viewPadding.bottom +
                                      8.0 +
                                      30.0,
                            ),
                            child: ListTile(
                              onTap: () => _postStatus(poisAround[index]),
                              onLongPress: () =>
                                  _popupPoiDetails(poisAround[index]),
                              leading: Container(
                                width: 54,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer, // Change color as needed
                                  shape: BoxShape.circle,
                                ),
                                child: Transform.translate(
                                  offset: const Offset(0, 0),
                                  child: SvgPicture.string(
                                    poiSvg(poisAround[index]['category']),
                                  ),
                                ),
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    poisAround[index]['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  poisAround[index].containsKey('description')
                                      ? Text(
                                          poisAround[index]['description'],
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize:
                                                (DefaultTextStyle.of(context)
                                                            .style
                                                            .fontSize ??
                                                        16.0) *
                                                    0.9,
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                              trailing: Text(
                                '${poisAround[index]['distance'].toInt()} m',
                                style: TextStyle(
                                  fontSize: (DefaultTextStyle.of(context)
                                              .style
                                              .fontSize ??
                                          16.0) *
                                      0.9,
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Divider(),
                          );
                        },
                      ),
                      Positioned(
                        bottom: MediaQuery.of(context)
                                .viewPadding
                                .bottom + // To avoid covering navigation bar
                            8,
                        right: 8,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ),
                            minimumSize: Size(50, 10), // Adjust size as needed
                          ),
                          onPressed: () async {
                            final url = Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                              );
                            }
                          },
                          child: const Text(
                            'Data © OpenStreetMap Contributors',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
      /*),*/
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:ultralytics_yolo_example/drawer.dart'; // Import the geolocator plugin
import 'package:flutter/services.dart'; // <-- added for Clipboard

// --- Data Models (same as before) ---
class AirQualityData {
  final int? aqi;
  final City? city;
  final Map<String, Pollutant>? iaqi;

  AirQualityData({
    this.aqi,
    this.city,
    this.iaqi,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'ok') {
      debugPrint('API status is not OK: ${json['data']}');
      return AirQualityData();
    }

    final data = json['data'] as Map<String, dynamic>;

    Map<String, Pollutant>? iaqiData;
    if (data['iaqi'] != null) {
      iaqiData = (data['iaqi'] as Map).map(
            (key, value) => MapEntry(key, Pollutant.fromJson(value)),
      ).cast<String, Pollutant>();
    }

    return AirQualityData(
      aqi: data['aqi'] as int?,
      city: data['city'] != null ? City.fromJson(data['city']) : null,
      iaqi: iaqiData,
    );
  }
}

class City {
  final String? name;

  City({this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String?,
    );
  }
}

class Pollutant {
  final double? value;

  Pollutant({this.value});

  factory Pollutant.fromJson(Map<String, dynamic> json) {
    return Pollutant(
      value: (json['v'] as num?)?.toDouble(),
    );
  }
}
// ------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Quality Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AirQualityPage(),
    );
  }
}

class AirQualityPage extends StatefulWidget {
  const AirQualityPage({super.key});

  @override
  State<AirQualityPage> createState() => _AirQualityPageState();
}

class _AirQualityPageState extends State<AirQualityPage> {
  // Replace with your actual WAQI API key
  final String _apiKey = '30c439655961e0b68355453e7665cdfebbfd51cb';

  AirQualityData? _airQualityData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAirQualityData();
  }

  /// Determines the current position of the device.
  ///
  /// When a user gives permission, this method returns the position.
  /// Otherwise, it throws an exception.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Permissions are granted, now get the position.
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchAirQualityData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _airQualityData = null; // Clear previous data
    });

    try {
      // Get the user's current GPS position
      final position = await _determinePosition();

      // Use the latitude and longitude to construct the API URL
      final Uri uri = Uri.parse(
          'https://api.waqi.info/feed/geo:${position.latitude};${position.longitude}/?token=$_apiKey');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final data = AirQualityData.fromJson(jsonResponse);

        if (data.aqi != null) {
          setState(() {
            _airQualityData = data;
          });
        } else {
          setState(() {
            _errorMessage = 'Could not retrieve AQI data for your location.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load data. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // <-- added this function
  void _copyPollutantDataToClipboard(Map<String, Pollutant>? iaqi) {
    if (iaqi == null || iaqi.isEmpty) return;

    final StringBuffer buffer = StringBuffer();
    for (var entry in iaqi.entries) {
      buffer.writeln('${entry.key.toUpperCase()}: ${entry.value.value?.toStringAsFixed(2) ?? 'N/A'}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Quality Composition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAirQualityData,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        )
            : _airQualityData != null
            ? SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location: ${_airQualityData!.city?.name ?? 'Unknown'}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Air Quality Index (AQI): ${_airQualityData!.aqi ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getAqiColor(_airQualityData!.aqi),
                ),
              ),
              const SizedBox(height: 24),
              // <-- replaced this line to add copy button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pollutant Composition:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to Clipboard',
                    onPressed: () {
                      _copyPollutantDataToClipboard(_airQualityData?.iaqi);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pollutant data copied to clipboard!')),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 8),
              _buildPollutantList(_airQualityData!.iaqi),
            ],
          ),
        )
            : const Text('No air quality data available.'),
      ),
      drawer: const AppDrawer(),
    );
  }

  Widget _buildPollutantList(Map<String, Pollutant>? iaqi) {
    if (iaqi == null || iaqi.isEmpty) {
      return const Text('No detailed pollutant data available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: iaqi.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '${entry.key.toUpperCase()}: ${entry.value.value?.toStringAsFixed(2) ?? 'N/A'}',
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
    );
  }

  Color _getAqiColor(int? aqi) {
    if (aqi == null) {
      return Colors.grey;
    }
    if (aqi >= 301) {
      return Colors.purple; // Hazardous
    } else if (aqi >= 201) {
      return Colors.red; // Very Unhealthy
    } else if (aqi >= 151) {
      return Colors.deepOrange; // Unhealthy
    } else if (aqi >= 101) {
      return Colors.yellow; // Unhealthy for Sensitive Groups
    } else if (aqi >= 51) {
      return Colors.green; // Moderate
    } else {
      return Colors.blue; // Good
    }
  }
}

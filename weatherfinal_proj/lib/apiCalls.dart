import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class apiCalls {
  static String weatherApiKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  static Future<Map<String, dynamic>> fetchWeather(String cityName) async {
    final response = await http.get(Uri.parse(
        'http://api.weatherapi.com/v1/current.json?key=$weatherApiKey&q=$cityName'));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['current'];
    } else {
      throw Exception('Failed to load weather from API');
    }
  }

  static String locationIqApiKey = dotenv.env['LOCATIONIQ_API_KEY'] ?? '';

  static Future<String> fetchLocation(double latitude, double longitude) async {
    final response = await http.get(Uri.parse(
        'https://us1.locationiq.com/v1/reverse.php?key=$locationIqApiKey&lat=$latitude&lon=$longitude&format=json'));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse['display_name'];
    } else {
      throw Exception('Failed to load location from API');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCities(String query) async {
    print('----------------------------------------------');
    print('locationkey: ' + locationIqApiKey);
    final response = await http.get(Uri.parse(
        'https://us1.locationiq.com/v1/search.php?key=$locationIqApiKey&city=$query&format=json'));
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((item) => {
                'name': item['display_name'],
                'lat': item['lat'],
                'lon': item['lon'],
              })
          .toList();
    } else {
      throw Exception('Failed to load cities from API');
    }
  }
}

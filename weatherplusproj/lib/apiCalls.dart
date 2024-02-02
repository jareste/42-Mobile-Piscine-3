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
      return jsonResponse;
    } else {
      throw Exception('Failed to load weather from API');
    }
  }

  static Future<List<HourlyData>> fetchHourlyData(String cityName) async {
    final response = await http.get(Uri.parse(
        'http://api.weatherapi.com/v1/forecast.json?key=$weatherApiKey&q=$cityName&days=1&hourly=1'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var hourlyData = data['forecast']['forecastday'][0]['hour'];
      // print(hourlyData
      //     .map<HourlyData>((item) => HourlyData(
      //           time: item['time'],
      //           temperature: item['temp_c'].toDouble(),
      //           windSpeed: item['wind_kph'].toDouble(),
      //         ))
      //     .toList());
      // print(data['condition']['icon']);
      // print(data['time']);
      return hourlyData
          .map<HourlyData>((item) {
            String iconUrl = 'http:${item['condition']['icon']}';
            return HourlyData(
              time: item['time'],
              temperature: item['temp_c'].toDouble(),
              windSpeed: item['wind_kph'].toDouble(),
              icon: iconUrl,
            );
          })
          .toList();
    } else {
      throw Exception('Failed to load hourly data');
    }
  }

  // _weatherIcon = 'http:${weatherData['current']['condition']['icon']}';

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

class HourlyData {
  final String time;
  final double temperature;
  final double windSpeed;
  final String icon;

  HourlyData(
      {required this.time,
      required this.temperature,
      required this.windSpeed,
      required this.icon});
  @override
  String toString() {
    return 'HourlyData{time: $time, temperature: $temperature, windSpeed: $windSpeed}';
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}

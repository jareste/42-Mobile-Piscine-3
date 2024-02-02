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

static Future<List<WeeklyData>> fetchWeeklyData(String cityName) async {
  final response = await http.get(Uri.parse(
      'http://api.weatherapi.com/v1/forecast.json?key=$weatherApiKey&q=$cityName&days=7'));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var forecastData = data['forecast']['forecastday'];
    
    List<WeeklyData> weeklyDataList = forecastData.map<WeeklyData>((item) {
      String iconUrl = 'http:${item['day']['condition']['icon']}';
      return WeeklyData(
        time: item['date'],
        minTemp: item['day']['mintemp_c'].toDouble(),
        maxTemp: item['day']['maxtemp_c'].toDouble(),
        icon: iconUrl,
      );
    }).toList();

    // Print the result to the console
    print(weeklyDataList);
    print('---> Weekly Data <---');

    return weeklyDataList;
  } else {
    throw Exception('Failed to load weekly data');
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

class WeeklyData {
  final String time;
  final double minTemp;
  final double maxTemp;
  final String icon;

  WeeklyData({
    required this.time,
    required this.minTemp,
    required this.maxTemp,
    required this.icon,
  });
  @override
  String toString() {
    return 'WeeklyData{time: $time, min: $minTemp, max: $maxTemp}';
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}


class ChartDataWeekly {
  final String x;
  final double minTemp;
  final double maxTemp;

  ChartDataWeekly(this.x, this.minTemp, this.maxTemp);
}

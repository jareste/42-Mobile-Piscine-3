import 'package:flutter/material.dart';
import 'apiCalls.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
// import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import 'package:intl/intl.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: ''),
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  "assets/images/ElFondo.jpg"), // replace with your image path
              fit: BoxFit.cover,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _index = 0;
  final _pageController = PageController();
  String _midText = '';
  String _location = '';
  String _temperature = '';
  String _weatherDescription = '';
  String _weatherIcon = '';
  String _windSpeed = '';
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic> _selectedCity = {};
  bool _isTyping = false;
  final FocusNode _focusNode = FocusNode();
  List<HourlyData> _hourlyDataList = [];
  List<ChartData> _chartDataList = [];
  List<WeeklyData> _weeklyDataList = [];
  List<ChartDataWeekly> _chartDataWeeklyList = [];

  @override
  void initState() {
    super.initState();
    // Add a listener to the FocusNode
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _controller.text.isNotEmpty) {
        fetchWeatherForCity(_controller.text);
      }
    });
  }

  void fetchWeatherForCity(String cityName) async {
    try {
      Map<String, dynamic> weatherData = await apiCalls.fetchWeather(cityName);
      // Update _midText with the weather information
      setState(() {
        _midText = 'Weather in $cityName: ${weatherData['current']['temp_c']}°C';
        _location =
            '${weatherData['location']['name']}, ${weatherData['location']['region']}, ${weatherData['location']['country']}';
        _temperature = '${weatherData['current']['temp_c']}°C';
        _weatherDescription = '${weatherData['current']['condition']['text']}';
        _weatherIcon = 'http:${weatherData['current']['condition']['icon']}';
        _windSpeed = '${weatherData['current']['wind_kph']} kph';
      });
    } catch (e) {
      setState(() {
        _midText = 'Failed to get weather: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Enter a city',
                  ),
                  onChanged: (value) async {
                    if (value.isNotEmpty) {
                      try {
                        _suggestions = await apiCalls.fetchCities(value);
                        setState(() {
                          _isTyping = true;
                        });
                      } catch (e) {
                        setState(() {
                          _suggestions = [];
                          _isTyping = false;
                        });
                      }
                    } else {
                      setState(() {
                        _isTyping = false;
                      });
                    }
                  },
                  onSubmitted: (value) {
                    setState(() {
                      _isTyping = false;
                    });
                  }),
            ),
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: () async {
                _midText = 'Getting weather...';
                _controller.clear();
                try {
                  // Get the current location
                  Position position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high);
                  // Fetch the weather for the current location
                  String location = await apiCalls.fetchLocation(
                      position.latitude, position.longitude);
                  Map<String, dynamic> weatherData =
                      await apiCalls.fetchWeather(location);
                  _midText = 'Weather at $location: ${weatherData['temp_c']}°C';
                } catch (e) {
                  _midText = 'Failed to get weather: $e';
                }
                setState(() {});
              },
            ),
          ],
        ),
      ),
      body: _isTyping
          ? ListView.builder(
              itemCount: min(_suggestions.length, 5),
              itemBuilder: (context, index) {
                // Split the city name into words
                List<String> words = _suggestions[index]['name'].split(' ');

                // Create a TextSpan for each word, applying a bold style only to the first one
                List<TextSpan> textSpans = words.map((word) {
                  return TextSpan(
                    text: '${words.indexOf(word) == 0 ? word : ' $word'}',
                    style: TextStyle(
                        fontWeight: words.indexOf(word) == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: words.indexOf(word) == 0 ? 22.0 : 17.0),
                  );
                }).toList();

                return ListTile(
                  title: RichText(
                    text: TextSpan(
                      children: textSpans,
                      style: DefaultTextStyle.of(context).style,
                    ),
                  ),
                  onTap: () async {
                    setState(() {
                      _selectedCity = _suggestions[index];
                      _controller.text = _selectedCity['name'];
                      _isTyping = false;
                    });
                    fetchWeatherForCity(_selectedCity['name']);
                    _hourlyDataList = await apiCalls.fetchHourlyData(_selectedCity['name']);
                    _chartDataList = _hourlyDataList.map((hourlyData) {
                      DateTime dateTime = DateTime.parse(hourlyData.time);
                      String time = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
                      return ChartData(time, hourlyData.temperature);
                    }).toList();
                    _weeklyDataList = await apiCalls.fetchWeeklyData(_selectedCity['name']);
                    _chartDataWeeklyList = _weeklyDataList.map((weeklyData) {
                    DateTime dateTime = DateTime.parse(weeklyData.time);
                    String day = DateFormat('EEEE').format(dateTime); // get the day of the week
                      return ChartDataWeekly(day, weeklyData.minTemp, weeklyData.maxTemp);
                    }).toList();
                  },
                );
              },
            )
          : PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _index = index;
                });
              },
              children: <Widget>[
                Center(
                  child: _location == ''
                      ? const CircularProgressIndicator() 
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            _location.split(',')[0], // City name
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 2, 41, 109)),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            _location.substring(_location.indexOf(',') + 1), // Rest of the location
                            style: const TextStyle(fontSize: 24, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _temperature,
                        style: const TextStyle(
                            fontSize: 26, color: Color.fromARGB(255, 255, 0, 0)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _weatherDescription,
                        style: const TextStyle(
                            fontSize: 26, color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        // width: 100,
                        // height: 100,
                        decoration : const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          ),
                        child: Image.network(
                          _weatherIcon,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.air, color: Colors.blue), // This is the wind icon
                          Text(
                            _windSpeed,
                            style: const TextStyle(fontSize: 26, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: 
                    Column(
                      children: [
                        Text(
                            _location.split(',')[0], // City name
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 2, 41, 109)),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            _location.substring(_location.indexOf(',') + 1), // Rest of the location
                            style: const TextStyle(fontSize: 24, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          color: Color.fromARGB(120, 175, 66, 2),
                          child: charts.SfCartesianChart(
                            // Initialize category axis
                            primaryXAxis: charts.CategoryAxis(),
                            series: <charts.CartesianSeries>[
                              // Initialize line series
                              charts.LineSeries<ChartData, String>(
                                dataSource: _chartDataList,
                                xValueMapper: (ChartData data, _) => data.x,
                                yValueMapper: (ChartData data, _) => data.y
                              )
                            ]
                          )
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.2,
                          color: Color.fromARGB(120, 175, 66, 2),
                          // adjust the height as needed
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _hourlyDataList.length,
                            itemBuilder: (context, index) {
                              DateTime dateTime = DateTime.parse(_hourlyDataList[index].time);
                              String time = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
                              return Card(
                                color: Colors.transparent,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Column(
                                    children: <Widget>[
                                      Text(time),
                                      Text('${_hourlyDataList[index].temperature.toString()}ºC'),
                                      Image.network(_hourlyDataList[index].icon), 
                                      Text('${_hourlyDataList[index].windSpeed.toString()} kph')
                                      // add more fields as needed
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          _location.split(',')[0], // City name
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 2, 41, 109)),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          _location.substring(_location.indexOf(',') + 1), // Rest of the location
                          style: const TextStyle(fontSize: 24, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          color: Color.fromARGB(120, 175, 66, 2),
                          child: charts.SfCartesianChart(
                            // Initialize category axis
                            primaryXAxis: charts.CategoryAxis(),
                            series: <charts.CartesianSeries>[
                              // Initialize line series for minimum temperature
                              charts.LineSeries<ChartDataWeekly, String>(
                                dataSource: _chartDataWeeklyList,
                                xValueMapper: (ChartDataWeekly data, _) => data.x,
                                yValueMapper: (ChartDataWeekly data, _) => data.minTemp
                              ),
                              // Initialize line series for maximum temperature
                              charts.LineSeries<ChartDataWeekly, String>(
                                dataSource: _chartDataWeeklyList,
                                xValueMapper: (ChartDataWeekly data, _) => data.x,
                                yValueMapper: (ChartDataWeekly data, _) => data.maxTemp
                              )
                            ]
                          )
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.2,
                          color: Color.fromARGB(120, 175, 66, 2),
                          // adjust the height as needed
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _weeklyDataList.length,
                            itemBuilder: (context, index) {
                              DateTime dateTime = DateTime.parse(_weeklyDataList[index].time);
                              String dayOfWeek = DateFormat('EEEE').format(dateTime);
                              return Card(
                                color: Colors.transparent,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Column(
                                    children: <Widget>[
                                      Text(dayOfWeek),
                                      Text('${_weeklyDataList[index].minTemp.toString()}ºC'),
                                      Text('${_weeklyDataList[index].maxTemp.toString()}ºC'),
                                      Image.network(_weeklyDataList[index].icon), 
                                      // add more fields as needed
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:
            Colors.transparent, // Set the background color to transparent
        elevation: 0, // Set the elevation to 0 to remove shadow
        currentIndex: _index,
        onTap: (index) {
          _pageController.animateToPage(index,
              duration: Duration(milliseconds: 200), curve: Curves.easeIn);
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.sunny), label: 'Currently'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Today'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Weekly'),
        ],
      ),
    );
  }
}

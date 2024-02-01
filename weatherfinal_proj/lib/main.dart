import 'package:flutter/material.dart';
import 'apiCalls.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';

void main() async{
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
              image: AssetImage("assets/images/ElFondo.jpg"), // replace with your image path
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
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic> _selectedCity = {};
  bool _isTyping = false;
  final FocusNode _focusNode = FocusNode();

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
        _midText = 'Weather in $cityName: ${weatherData['temp_c']}°C';
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
                }
              ),
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
                    style: TextStyle(fontWeight: words.indexOf(word) == 0 ? FontWeight.bold : FontWeight.normal, 
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Currently',
                        style: TextStyle(
                            fontSize: 36, color: Colors.lightBlueAccent),
                      ),
                      Text(
                        _midText,
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Today',
                        style: TextStyle(fontSize: 24, color: Colors.purple),
                      ),
                      Text(
                        _midText,
                        style: TextStyle(fontSize: 24, color: Colors.purple),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Weekly',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      Text(_midText,
                          style: TextStyle(
                              fontSize: 36, color: Colors.lightBlueAccent)),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.transparent, // Set the background color to transparent
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

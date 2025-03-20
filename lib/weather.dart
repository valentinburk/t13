import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:team13app/user_service.dart';
import 'package:team13app/data_classes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherHomePage extends StatefulWidget {
  final VoidCallback onLogout;
  final Color appColor;

  const WeatherHomePage({super.key, required this.onLogout, required this.appColor});

  @override
  createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  City? _selectedCity;
  WeatherData? _weatherData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSelectedCity();
  }

  _initSelectedCity() async {
    await UserService.loadData();
    if (UserService.currentUser != null && 
        UserService.currentUser!.cities.isNotEmpty) {
      setState(() {
        _selectedCity = UserService.currentUser!.cities.first;
      });
      _fetchWeatherData();
    }
  }

  _fetchWeatherData() async {
    if (_selectedCity == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      WeatherData data = await WeatherService.getWeather(
        _selectedCity!.lat,
        _selectedCity!.lon,
      );
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch weather data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team 13 - ${UserService.currentUser!.username}'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await UserService.logout();
              widget.onLogout();
            },
          ),
        ],
      ),
      body: _selectedCity == null
          ? Center(child: Text('No cities added'))
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: widget.appColor.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<City>(
                          value: _selectedCity,
                          isExpanded: true,
                          hint: Text('Select a city'),
                          onChanged: (City? newValue) {
                            setState(() {
                              _selectedCity = newValue;
                            });
                            _fetchWeatherData();
                          },
                          items: UserService.currentUser?.cities
                              .map<DropdownMenuItem<City>>((City city) {
                            return DropdownMenuItem<City>(
                              value: city,
                              child: Text(city.name),
                            );
                          }).toList() ?? [],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          _showAddCityDialog();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: _selectedCity == null
                            ? null
                            : () async {
                                await UserService.removeCity(_selectedCity!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${_selectedCity!.name} removed'),
                                  ),
                                );
                                setState(() {
                                  if (UserService.currentUser?.cities.isNotEmpty ?? false) {
                                    _selectedCity = UserService.currentUser!.cities.first;
                                    _fetchWeatherData();
                                  } else {
                                    _selectedCity = null;
                                    _weatherData = null;
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _weatherData == null
                          ? Center(child: Text('Select a city to view weather'))
                          : Column(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: WeatherInfoWidget(
                                    weatherData: _weatherData!,
                                    cityName: _selectedCity!.name,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: CityMapWidget(
                                    lat: _selectedCity!.lat,
                                    lon: _selectedCity!.lon,
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
    );
  }

  void _showAddCityDialog() {
    final TextEditingController cityController = TextEditingController();
    City? selectedCity;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add City'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TypeAheadField<City>(
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 3) return [];
                  return await WeatherService.searchCities(pattern);
                },
                itemBuilder: (context, City city) {
                  return ListTile(
                    title: Text(city.name),
                    subtitle: Text('Lat: ${city.lat.toStringAsFixed(2)}, Lon: ${city.lon.toStringAsFixed(2)}'),
                  );
                },
                onSelected: (City city) {
                  cityController.text = city.name;
                  selectedCity = city;
                },
                emptyBuilder: (context) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('No cities found. Type at least 3 characters.'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCity != null) {
                  await UserService.addCity(selectedCity!);
                  setState(() {
                    _selectedCity = selectedCity;
                  });
                  _fetchWeatherData();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a city from the suggestions')),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class WeatherInfoWidget extends StatelessWidget {
  final WeatherData weatherData;
  final String cityName;

  const WeatherInfoWidget({super.key, required this.weatherData, required this.cityName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            cityName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${weatherData.temperature.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Image.network(
                'https://openweathermap.org/img/wn/${weatherData.icon}@2x.png',
                width: 64,
                height: 64,
              ),
            ],
          ),
          Text(
            weatherData.description,
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Icon(Icons.air),
                  Text('${weatherData.windSpeed} m/s'),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.water_drop),
                  Text('${weatherData.humidity}%'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CityMapWidget extends StatelessWidget {
  final double lat;
  final double lon;

  const CityMapWidget({super.key, required this.lat, required this.lon});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(lat, lon),
        zoom: 12,
      ),
      markers: {
        Marker(
          markerId: MarkerId('city_location'),
          position: LatLng(lat, lon),
        ),
      },
    );
  }
}

class WeatherService {
  static const String apiKey = '{OPENWEATHERMAP_API_KEY}';
  
  static Future<WeatherData> getWeather(double lat, double lon) async {
    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  static Future<List<City>> searchCities(String query) async {
    if (query.length < 3) return [];
    
    final url = 'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => City(
        name: '${item['name']}, ${item['country']}',
        lat: item['lat'],
        lon: item['lon'],
      )).toList();
    } else {
      throw Exception('Failed to search cities');
    }
  }
}


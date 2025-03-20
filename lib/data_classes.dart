import 'package:flutter/material.dart';

class User {
  final String username;
  final String password;
  final Color appColor;
  final List<City> cities;

  User({
    required this.username,
    required this.password,
    required this.appColor,
    required this.cities,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'appColor': appColor.toARGB32().toString(),
      'cities': cities.map((city) => city.toJson()).toList(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      password: json['password'],
      appColor: Color(int.parse(json['appColor'])),
      cities: (json['cities'] as List)
          .map((cityJson) => City.fromJson(cityJson))
          .toList(),
    );
  }
}

class City {
  final String name;
  final double lat;
  final double lon;

  City({required this.name, required this.lat, required this.lon});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lon': lon,
    };
  }

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      lat: json['lat'],
      lon: json['lon'],
    );
  }
}

class WeatherData {
  final double temperature;
  final String description;
  final String icon;
  final double windSpeed;
  final int humidity;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.humidity,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      humidity: json['main']['humidity'],
    );
  }
}

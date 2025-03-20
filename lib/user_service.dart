import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team13app/data_classes.dart';

class UserService {
  static final List<User> _users = [];
  static User? _currentUser;

  static User? get currentUser => _currentUser;

  static Future<bool> register(String username, String password, Color appColor) async {
    if (_users.any((user) => user.username == username)) {
      return false;
    }

    // Create new user
    User newUser = User(
      username: username,
      password: password,
      appColor: appColor,
      cities: [
        City(name: 'London', lat: 51.5074, lon: -0.1278),
        City(name: 'New York', lat: 40.7128, lon: -74.0060),
      ],
    );
    _users.add(newUser);
    _currentUser = newUser;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', username);
    await prefs.setString('appColor', appColor.toARGB32().toString());
    await prefs.setString('users', jsonEncode(_users.map((u) => u.toJson()).toList()));

    return true;
  }

  static Future<bool> login(String username, String password) async {
    User? user = _users.firstWhere(
      (user) => user.username == username && user.password == password,
      orElse: () => User(
        username: '',
        password: '',
        appColor: Colors.blue,
        cities: [],
      ),
    );

    if (user.username.isEmpty) {
      return false;
    }

    _currentUser = user;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', username);
    await prefs.setString('appColor', user.appColor.toARGB32().toString());

    return true;
  }

  static Future<void> logout() async {
    _currentUser = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }

  static Future<void> addCity(City city) async {
    if (_currentUser != null) {
      if (!_currentUser!.cities.any((c) => c.name == city.name)) {
        _currentUser!.cities.add(city);
        await _saveUserData();
      }
    }
  }

  static Future<void> removeCity(City city) async {
    if (_currentUser != null) {
      _currentUser!.cities.removeWhere((c) => c.name == city.name);
      await _saveUserData();
    }
  }

  static Future<void> _saveUserData() async {
    if (_currentUser != null) {
      int userIndex = _users.indexWhere((u) => u.username == _currentUser!.username);
      if (userIndex != -1) {
        _users[userIndex] = _currentUser!;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('users', jsonEncode(_users.map((u) => u.toJson()).toList()));
      }
    }
  }

  static Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usersJson = prefs.getString('users');
    if (usersJson != null) {
      List<dynamic> userList = jsonDecode(usersJson);
      _users.clear();
      _users.addAll(userList.map((userJson) => User.fromJson(userJson)));
      
      String? username = prefs.getString('username');
      if (username != null) {
        _currentUser = _users.firstWhere(
          (user) => user.username == username,
          orElse: () => User(
            username: '',
            password: '',
            appColor: Colors.blue,
            cities: [],
          ),
        );
      }
    }
  }
}

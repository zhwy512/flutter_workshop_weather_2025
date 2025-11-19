import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavouriteProvider extends ChangeNotifier {
  List<String> _cities = [];

  List<String> get cities => _cities;

  FavouriteProvider() {
    _load();
  }

  void toggle(String city) {
    if (_cities.contains(city)) {
      _cities.remove(city);
    } else {
      _cities.add(city);
    }
    _save();
    notifyListeners();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    _cities = prefs.getStringList('favourites') ?? [];
    notifyListeners();
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favourites', _cities);
  }
}

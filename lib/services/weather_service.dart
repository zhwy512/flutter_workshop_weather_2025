import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String apiKey = "2126c39435e61509ca1ef213f1a66088";
  static const String baseUrl =
      "https://api.openweathermap.org/data/2.5/weather";

  Future<Weather> getWeather(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric&lang=vi'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Weather.fromJson(json);
    } else {
      throw Exception('City not found');
    }
  }
}

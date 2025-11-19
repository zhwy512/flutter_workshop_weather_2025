import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // TOPIC 7: Custom Designs & Themes
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  String _weatherResult = "Nhập tên thành phố để tra cứu";
  bool _isLoading = false;

  // Biến lưu dữ liệu đầy đủ để truyền sang màn hình sau
  Map<String, dynamic>? _weatherData;

  // --- API KEY CỦA BẠN ---
  static const apiKey = "2126c39435e61509ca1ef213f1a66088";

  Future<void> fetchWeather() async {
    setState(() {
      _isLoading = true;
      _weatherResult = "Đang kết nối vệ tinh...";
    });

    try {
      final city = _cityController.text;
      // Gọi API thật (TOPIC 6)
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=vi",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _weatherData = data; // Lưu dữ liệu gốc

          String name = data['name'];
          double temp = data['main']['temp'];
          String desc = data['weather'][0]['description'];

          _weatherResult = "📍 $name\n🌡️ $temp°C\n☁️ $desc";
          _isLoading = false;
        });
      } else {
        throw Exception(
          "Không tìm thấy thành phố (Lỗi ${response.statusCode})",
        );
      }
    } catch (e) {
      setState(() {
        _weatherResult = "Lỗi kết nối: Kiểm tra mạng hoặc API Key";
        _isLoading = false;
      });
    }
  }

  // Hàm chuyển trang (TOPIC 5: Navigation)
  void _goToDetailScreen() {
    if (_weatherData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(data: _weatherData!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weather Master")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: "City Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: fetchWeather,
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text("Lấy dữ liệu thật"),
                  ),
            const SizedBox(height: 30),

            // GestureDetector để bắt sự kiện chạm vào kết quả
            GestureDetector(
              onTap: _goToDetailScreen, // Bấm vào thì chuyển trang
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      _weatherResult,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.indigo,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_weatherData != null) ...[
                      const SizedBox(height: 10),
                      const Text(
                        "(Bấm vào đây để xem chi tiết >>)",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MÀN HÌNH 2: CHI TIẾT (TOPIC 5: Navigation) ---
class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(data['name'])),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wb_sunny, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              "${data['main']['temp']}°C",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Text(
              "Độ ẩm: ${data['main']['humidity']}%",
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              "Gió: ${data['wind']['speed']} m/s",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Quay lại màn hình trước
              },
              child: const Text("Quay lại"),
            ),
          ],
        ),
      ),
    );
  }
}

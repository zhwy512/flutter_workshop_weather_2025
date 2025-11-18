import 'package:flutter/material.dart';
import 'dart:convert'; // Để xử lý JSON (TOPIC 6)
import 'package:http/http.dart' as http; // Để gọi API (TOPIC 6)

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
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
  String _weatherResult = "Hãy nhập tên thành phố để xem thời tiết";
  bool _isLoading = false; // Trạng thái loading

  // --- DATA GIẢ (PHƯƠNG ÁN AN TOÀN) ---
  final String fakeJsonData = """
  {
    "weather": [{"description": "mây rải rác", "icon": "03d"}],
    "main": {"temp": 32.5, "humidity": 70},
    "name": "Thành Phố Hồ Chí Minh",
    "cod": 200
  }
  """;

  // Hàm gọi API (TOPIC 6)
  Future<void> fetchWeather() async {
    // Bắt đầu loading -> Cập nhật UI
    setState(() {
      _isLoading = true;
      _weatherResult = "Đang tải dữ liệu...";
    });

    try {
      // --- CÁCH 1: DÙNG API THẬT (Bỏ comment nếu Key hoạt động) ---
      // final apiKey = "YOUR_API_KEY_HERE";
      // final city = _cityController.text;
      // final url = Uri.parse("https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=vi");
      // final response = await http.get(url);
      // final data = jsonDecode(response.body);

      // --- CÁCH 2: DÙNG DATA GIẢ (Để demo không bao giờ lỗi) ---
      await Future.delayed(const Duration(seconds: 1)); // Giả lập độ trễ mạng
      final data = jsonDecode(fakeJsonData); // Parse JSON

      // Kiểm tra code API trả về
      if (data['cod'] == 200) {
        // Lấy dữ liệu từ JSON
        String cityName = data['name'];
        double temp = data['main']['temp'];
        String desc = data['weather'][0]['description'];

        // CẬP NHẬT STATE (TOPIC 4)
        setState(() {
          _weatherResult =
              "📍 $cityName\n🌡️ Nhiệt độ: $temp°C\n☁️ Tình trạng: $desc";
          _isLoading = false;
        });
      } else {
        throw Exception("Không tìm thấy thành phố");
      }
    } catch (e) {
      setState(() {
        _weatherResult = "❌ Lỗi: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weather Demo App")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: "Nhập tên thành phố",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),

            // Nút bấm hoặc Loading
            _isLoading
                ? const CircularProgressIndicator() // Show vòng xoay khi đang tải
                : ElevatedButton.icon(
                    onPressed: fetchWeather, // Gọi hàm fetchWeather khi bấm
                    icon: const Icon(Icons.cloud),
                    label: const Text("Xem Thời Tiết"),
                  ),

            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _weatherResult,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

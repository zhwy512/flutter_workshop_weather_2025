import 'package:flutter/material.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt chữ DEBUG ở góc
      theme: ThemeData(primarySwatch: Colors.blue), // TOPIC 7: Theme
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
  // Controller để lấy dữ liệu từ ô nhập liệu
  final TextEditingController _cityController = TextEditingController();

  // Biến chứa kết quả hiển thị (Ban đầu rỗng)
  String _weatherResult = "Hãy nhập tên thành phố để xem thời tiết";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weather Demo App"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          // TOPIC 3: Layout Widget
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ô nhập liệu
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: "Nhập tên thành phố (VD: Saigon)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),

            // Nút tìm kiếm
            ElevatedButton(
              onPressed: () {
                // Lúc này chưa có logic, chỉ in ra log
                print("Đang tìm kiếm: ${_cityController.text}");
              },
              child: const Text("Xem Thời Tiết"),
            ),
            const SizedBox(height: 30),

            // Nơi hiển thị kết quả
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _weatherResult,
                style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

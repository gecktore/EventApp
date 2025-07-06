import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_app_3/screens/event_detail_screen.dart'; // Убедитесь, что путь правильный

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String barcodeResult = "Наведите камеру на QR-код";
  final TextEditingController _accessCodeController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканирование QR-кода')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              onDetect: (BarcodeCapture capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  setState(() {
                    barcodeResult = barcodes.first.rawValue!;
                    _accessCodeController.text =
                        barcodeResult; // Заполняем текстовое поле
                  });
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _accessCodeController,
                    decoration: InputDecoration(
                      labelText: 'Код доступа',
                      errorText: _errorMessage,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkAccessCode,
                    child: const Text('Проверить код'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAccessCode() async {
    String accessCode = _accessCodeController.text.trim();

    if (accessCode.isEmpty) {
      setState(() {
        _errorMessage = 'Введите код доступа';
      });
      return;
    }

    try {
      // Выполняем запрос к коллекции events, чтобы найти документ с соответствующим access_code
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where('access_code', isEqualTo: accessCode)
              .get();

      print("Entered Access Code: $accessCode");
      print("Number of documents found: ${querySnapshot.docs.length}");

      if (querySnapshot.docs.isNotEmpty) {
        // Код доступа найден, переходим к первому найденному мероприятию
        String eventId =
            querySnapshot
                .docs
                .first
                .id; // Получаем ID первого найденного мероприятия
        print("Found Event ID: $eventId");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(eventId: eventId),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Неверный код доступа';
        });
      }
    } catch (e) {
      print("Error checking access code: $e");
      setState(() {
        _errorMessage = 'Ошибка при проверке кода доступа';
      });
    }
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }
}

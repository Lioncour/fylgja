import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_background/flutter_background.dart';
import 'about_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing FlutterBackground...');
  await FlutterBackground.initialize();
  print('FlutterBackground initialized.');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startBackgroundService();
    _checkConnection();
    _audioPlayer.setSource(AssetSource('sound.mp3'));
  }

  Future<void> _startBackgroundService() async {
    print('Starting background service...');
    await FlutterBackground.enableBackgroundExecution();
    print('Background service started.');
  }

  Future<void> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      if (response.statusCode == 200) {
        _showModal();
        _playSound();
        Vibration.vibrate();
        setState(() {
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = true;
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = true;
      });
    }
  }

  void _showModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            setState(() {
              _isSearching = true;
            });
            _audioPlayer.stop();
          },
          child: Container(
            height: 200,
            color: Color(0xFFDBC3C5),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/pauseicon.png'),
                    Text(
                      '<b>Du har jammen meg dekning</b>. Om du trykker her stopper søket en stund.',
                      style: TextStyle(
                        color: Color(0xFF4B3C52),
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() async {
      setState(() {
        _isSearching = false;
      });
      await Future.delayed(const Duration(seconds: 10));
      setState(() {
        _isSearching = true;
      });
      _checkConnection();
    });
  }

  void _playSound() {
    _audioPlayer.play(AssetSource('sound.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6EEA1),
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Color(0xFFF6EEA1),
        actions: [
          IconButton(
            icon: Image.asset('assets/about icon.png'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Image.asset('assets/logosak.png'),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.3,
              color: Color(0xFF4B3C52),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Fylgja',
                    style: TextStyle(
                      color: Color(0xFFF6EEA1),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Din Mág i fjell og dal',
                    style: TextStyle(
                      color: Color(0xFFF6EEA1),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

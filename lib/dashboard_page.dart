// ============ KIZZY - SHARE YATIM LU ============

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xml/xml.dart' as xml;
import 'api.dart';

import 'package:darkverse/theme/app_theme.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'info_page.dart';
import 'tools_gateway.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'owner_page.dart';
import 'riwayat_page.dart';
import 'islamic_page.dart';
import 'games_page.dart';
import 'settings_page.dart';
import 'services/lang.dart';
import 'audio_service.dart';
import 'backsound_setting.dart';
import 'chat_page.dart';
import 'status_page.dart';

// ============================================================
//  MEGATRON INTRO ANIMATION — LETTER BY LETTER BASS HIT
// ============================================================
class _MegatronIntro extends StatefulWidget {
  final Color textColor;
  final Color glowColor;
  final double fontSize;
  final VoidCallback? onComplete;

  const _MegatronIntro({required this.textColor, required this.glowColor, this.fontSize = 20, this.onComplete});

  @override
  State<_MegatronIntro> createState() => _MegatronIntroState();
}

class _MegatronIntroState extends State<_MegatronIntro> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _letterAnims;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _glowAnims;
  static const String _text = "MEGATRON";

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _letterAnims = List.generate(_text.length, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.3).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _ctrl, curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut));
    });

    // Scale: pop up big then settle to 1.0
    _scaleAnims = List.generate(_text.length, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 0),
        TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.6), weight: 40),
        TweenSequenceItem(tween: Tween<double>(begin: 1.6, end: 1.0), weight: 60),
      ]).animate(CurvedAnimation(parent: _ctrl, curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut)));
    });

    // Glow: burst then fade
    _glowAnims = List.generate(_text.length, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 0),
        TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 25),
        TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 75),
      ]).animate(CurvedAnimation(parent: _ctrl, curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut)));
    });

    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_text.length, (i) {
            final opacity = _letterAnims[i].value;
            final scale = _scaleAnims[i].value;
            final glow = _glowAnims[i].value;
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Text(
                    _text[i],
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFamily: 'Inter',
                      shadows: [
                        Shadow(color: widget.glowColor.withValues(alpha: glow * 0.8), blurRadius: 12 * glow),
                        Shadow(color: widget.glowColor.withValues(alpha: glow * 0.4), blurRadius: 24 * glow),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top, bottom, left, right;
  _CornerPainter(this.color, {this.top = false, this.bottom = false, this.left = false, this.right = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final d = size.width;
    if (top && left) { canvas.drawLine(Offset(0, 0), Offset(d, 0), paint); canvas.drawLine(Offset(0, 0), Offset(0, d), paint); }
    if (top && right) { canvas.drawLine(Offset(0, 0), Offset(d, 0), paint); canvas.drawLine(Offset(d, 0), Offset(d, d), paint); }
    if (bottom && left) { canvas.drawLine(Offset(0, d), Offset(d, d), paint); canvas.drawLine(Offset(0, 0), Offset(0, d), paint); }
    if (bottom && right) { canvas.drawLine(Offset(0, d), Offset(d, d), paint); canvas.drawLine(Offset(d, 0), Offset(d, d), paint); }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// 🕐 WIDGET JAM - MODERN DARK TECH
// ============================================================
class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  String _time = "00:00:00";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    _time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE74C), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFFFE74C).withValues(alpha: 0.3), offset: const Offset(2, 2), blurRadius: 0)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, color: Color(0xFFFFE74C), size: 14),
          const SizedBox(width: 6),
          Text(
            _time,
            style: const TextStyle(
              color: Color(0xFFFFE74C),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'ShareTechMono',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ SHOLAT SERVICE (SAMA) ============
class SholatService {
  String _getTimeZone(double longitude) {
    if (longitude >= 105 && longitude < 120)
      return "WIB";
    else if (longitude >= 120 && longitude < 135)
      return "WITA";
    else if (longitude >= 135 && longitude <= 150)
      return "WIT";
    else
      return "WIB";
  }

  Future<Map<String, dynamic>> getJadwalSholat(String cityId) async {
    try {
      final now = DateTime.now();
      final date =
          "${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/jadwal/$cityId/$date'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error: $e');
    }
    return {};
  }

  Future<List<dynamic>> searchKota(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/kota/cari/$query'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
    } catch (e) {
      print('Error: $e');
    }
    return [];
  }

  Future<List<dynamic>> getKotaList() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myquran.com/v1/sholat/kota/cari/'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      }
    } catch (e) {
      print('Error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getCurrentLocationCity() async {
    try {
      final status = await Permission.location.request();
      if (status != PermissionStatus.granted) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final timeZone = _getTimeZone(position.longitude);
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isEmpty) return null;
      final place = places.first;
      String? cityName =
          place.locality ??
          place.subLocality ??
          place.subAdministrativeArea ??
          place.administrativeArea;
      if (cityName == null) return null;
      String cleanName = cityName
          .toLowerCase()
          .replaceAll('kabupaten', '')
          .replaceAll('kab.', '')
          .replaceAll('kota', '')
          .replaceAll('kab', '')
          .replaceAll('kot', '')
          .trim();
      var searchResults = await searchKota(cleanName);
      if (searchResults.isEmpty && cleanName.contains(' ')) {
        final parts = cleanName.split(' ');
        for (var part in parts) {
          if (part.length > 3) {
            searchResults = await searchKota(part);
            if (searchResults.isNotEmpty) break;
          }
        }
      }
      if (searchResults.isEmpty && cleanName.contains(' ')) {
        final firstWord = cleanName.split(' ')[0];
        if (firstWord.length > 2) searchResults = await searchKota(firstWord);
      }
      if (searchResults.isEmpty) {
        final allCities = await getKotaList();
        Map<String, dynamic>? nearestCity;
        double minDistance = double.infinity;
        for (var city in allCities) {
          final cityLat =
              double.tryParse(city['lintang']?.toString() ?? '0') ?? 0;
          final cityLong =
              double.tryParse(city['bujur']?.toString() ?? '0') ?? 0;
          if (cityLat != 0 && cityLong != 0) {
            final distance = calculateDistance(
              position.latitude,
              position.longitude,
              cityLat,
              cityLong,
            );
            if (distance < minDistance) {
              minDistance = distance;
              nearestCity = city;
            }
          }
        }
        if (nearestCity != null) {
          return {
            'cityId': nearestCity['id'].toString(),
            'cityName': nearestCity['lokasi']?.toString() ?? cityName,
            'timeZone': timeZone,
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        }
      }
      if (searchResults.isNotEmpty) {
        final cityData = searchResults[0];
        return {
          'cityId': cityData['id'].toString(),
          'cityName': cityData['lokasi']?.toString() ?? cityName,
          'timeZone': timeZone,
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}

// ============ DASHBOARD PAGE ============
class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;

  late String sessionKey, username, password, role, expiredDate;
  late List<Map<String, dynamic>> listBug, listDoos;
  late List<dynamic> newsList;

  String androidId = "unknown";
  File? _profileImage;

  int _bottomNavIndex = 0;
  Widget _selectedPage = const SizedBox();
  Widget? _cachedChatPage;
  Widget? _cachedToolsPage;
  Widget? _cachedInfoPage;

  int onlineUsers = 0;
  VideoPlayerController? _bgVideoController;
  bool _bgVideoInitialized = false;
  int activeConnections = 0;
  bool _isDarkMode = false;
  int _serverPing = 0;
  DateTime? _lastPingSent;
  int _displayPing = 0;

  // Animated signal
  late AnimationController _signalAnimCtrl;
  late Animation<double> _signalAnim;
  int _signalTick = 0;
  Timer? _signalTimer;

  // Video box controller
  VideoPlayerController? _videoBoxController;
  bool _videoBoxInit = false;

  // 3D tilt
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // Staggered entrance animations
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _entranceAnims;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  late PageController _newsPageController;
  double _currentNewsPage = 0.0;
  Timer? _newsTimer;

  // HOT NEWS auto-rotate
  int _hotNewsIndex = 0;
  Timer? _hotNewsTimer;
  late PageController _hotNewsController;

  // 🕌 JADWAL SHOLAT
  Map<String, dynamic>? _jadwalSholat;
  List<dynamic> _cityList = [];
  String _selectedCityId = "1227";
  String _selectedCityName = "Jakarta";
  bool _isLoadingSholat = true;
  bool _useCurrentLocation = false;
  final SholatService _sholatService = SholatService();

  // 🎌 ANIME
  List<Map<String, dynamic>> _animeData = [];
  bool _isLoadingAnime = true;

  // 📰 RSS NEWS
  final String _newsUrl = "https://www.antaranews.com/rss/terkini.xml";
  List<Map<String, dynamic>> _newsData = [];
  bool _isLoadingNews = true;
  String _newsError = "";

  // 🌤️ WEATHER
  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = true;
  String weatherErrorMsg = "";

  late PageController _quickAccessController;
  double _currentQuickAccessPage = 0.0;

  // ============ BACKGROUND MUSIC ============
  final AudioService _audioService = AudioService();
  bool _isSoundOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    FlutterError.onError = (details) {
      debugPrint("FlutterError: ${details.exceptionAsString()}");
      if (mounted) {
        setState(() {
          _buildError = details.exceptionAsString();
        });
      }
    };

    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _initNewsBanner();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _initAndroidIdAndConnect();
    _loadProfileImage();
    _fetchSholatTimes();
    _fetchAnimeData();
    _initWeather();
    _loadDarkMode();
    _initBgVideo();
    Future.delayed(const Duration(seconds: 2), () { if (mounted) _initVideoBox(); });

    _signalAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _signalAnim = CurvedAnimation(parent: _signalAnimCtrl, curve: Curves.easeInOut);
    _signalTimer = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (mounted) setState(() => _signalTick++);
    });

    // Staggered entrance (10 items, 80ms apart)
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _entranceAnims = List.generate(11, (i) {
      final start = (i * 0.08).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
    });
    _entranceCtrl.forward();

    // Breathing glow
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _quickAccessController = PageController(viewportFraction: 0.85);
    _quickAccessController.addListener(() {
      if (_quickAccessController.hasClients &&
          _quickAccessController.page != null) {
        _currentQuickAccessPage = _quickAccessController.page!;
      }
    });

    _hotNewsController = PageController();
    _hotNewsTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _hotNewsIndex = (_hotNewsIndex + 1) % 6;
        });
        _hotNewsController.animateToPage(
          _hotNewsIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });

    try {
      _selectedPage = _buildNewsPage();
    } catch (e) {
      debugPrint("Dashboard _buildNewsPage error: $e");
      _selectedPage = Center(
        child: Text("Error: $e", style: const TextStyle(color: Colors.red)),
      );
    }
    _fetchRssNews();
    _initBackgroundMusic();
  }

  void _initBackgroundMusic() {
    _isSoundOn = _audioService.isEnabled;
    if (_isSoundOn) _audioService.resume();
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _newsTimer?.cancel();
    _newsPageController.dispose();
    _quickAccessController.dispose();
    _controller.dispose();
    channel.sink.close(status.goingAway);
    _audioService.pause();
    _bgVideoController?.dispose();
    _videoBoxController?.dispose();
    _signalAnimCtrl.dispose();
    _signalTimer?.cancel();
    _entranceCtrl.dispose();
    _glowCtrl.dispose();
    _hotNewsTimer?.cancel();
    _hotNewsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioService.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_isSoundOn) _audioService.resume();
    }
  }

  // ============================================================
  // 📰 RSS NEWS
  // ============================================================
  Future<void> _fetchRssNews() async {
    setState(() {
      _isLoadingNews = true;
      _newsError = "";
    });
    try {
      final response = await http
          .get(Uri.parse(_newsUrl))
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => http.Response('Timeout', 408),
          );
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        List<Map<String, dynamic>> tempNews = [];
        for (var item in items) {
          if (tempNews.length >= 10) break;
          final title =
              item.findElements('title').singleOrNull?.innerText ?? '';
          final pubDate =
              item.findElements('pubDate').singleOrNull?.innerText ?? '';
          final description =
              item.findElements('description').singleOrNull?.innerText ?? '';
          final link = item.findElements('link').singleOrNull?.innerText ?? '';
          final enclosure = item.findElements('enclosure').singleOrNull;
          String imageUrl = '';
          if (enclosure != null) imageUrl = enclosure.getAttribute('url') ?? '';
          if (imageUrl.isEmpty && description.contains('src="')) {
            final match = RegExp(r'src="(.*?)"').firstMatch(description);
            if (match != null) imageUrl = match.group(1) ?? '';
          }
          final cleanDesc = description
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .trim();
          tempNews.add({
            'title': title,
            'pubDate': pubDate,
            'description': cleanDesc,
            'imageUrl': imageUrl,
            'link': link,
          });
        }
        if (mounted)
          setState(() {
            _newsData = tempNews;
            _isLoadingNews = false;
          });
      } else {
        if (mounted)
          setState(() {
            _newsError = "Server sibuk";
            _isLoadingNews = false;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _newsError = "Gagal memuat berita";
          _isLoadingNews = false;
        });
    }
  }

  // ============================================================
  // 🌤️ WEATHER
  // ============================================================
  Future<void> _initWeather() async {
    setState(() {
      isLoadingWeather = true;
      weatherErrorMsg = "";
    });
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        isLoadingWeather = false;
        weatherErrorMsg = "GPS tidak aktif";
      });
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          isLoadingWeather = false;
          weatherErrorMsg = "Izin lokasi ditolak";
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        isLoadingWeather = false;
        weatherErrorMsg = "Izin lokasi ditolak permanen";
      });
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      await _fetchWeather(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        isLoadingWeather = false;
        weatherErrorMsg = "Gagal mendapatkan lokasi";
      });
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final String apiKey = "68296d0a3a5d6ee2b5cb993918d19ef9";
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(response.body);
          isLoadingWeather = false;
        });
      } else {
        setState(() {
          isLoadingWeather = false;
          weatherErrorMsg = "Gagal load data cuaca";
        });
      }
    } catch (e) {
      setState(() {
        isLoadingWeather = false;
        weatherErrorMsg = "Terjadi kesalahan";
      });
    }
  }

  IconData _getWeatherIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('clear')) return FontAwesomeIcons.sun;
    if (cond.contains('clouds')) return FontAwesomeIcons.cloud;
    if (cond.contains('rain') || cond.contains('drizzle'))
      return FontAwesomeIcons.cloudRain;
    if (cond.contains('thunderstorm')) return FontAwesomeIcons.cloudBolt;
    if (cond.contains('snow')) return FontAwesomeIcons.snowflake;
    if (cond.contains('mist') || cond.contains('fog') || cond.contains('haze'))
      return FontAwesomeIcons.smog;
    return FontAwesomeIcons.cloudSun;
  }

  // ============================================================
  // 🕌 SHOLAT
  // ============================================================
  Future<void> _fetchSholatTimes() async {
    setState(() {
      _isLoadingSholat = true;
    });
    try {
      final locationData = await _sholatService.getCurrentLocationCity();
      if (locationData != null && mounted) {
        final cityId = locationData['cityId'];
        final cityName = locationData['cityName'];
        setState(() {
          _selectedCityId = cityId;
          _selectedCityName = cityName;
          _useCurrentLocation = true;
        });
        await _fetchSholatSchedule(cityId);
        _saveLocationPreference(cityId, cityName);
      } else {
        await _loadSavedLocation();
      }
    } catch (e) {
      print('Error: $e');
      _setDefaultSholatSchedule();
    } finally {
      if (mounted)
        setState(() {
          _isLoadingSholat = false;
        });
    }
  }

  Future<void> _fetchSholatSchedule(String cityId) async {
    if (!mounted) return;
    try {
      final data = await _sholatService
          .getJadwalSholat(cityId)
          .timeout(const Duration(seconds: 8), onTimeout: () => {});
      if (mounted && data.isNotEmpty && data['status'] == true) {
        setState(() {
          _jadwalSholat = data['data'];
        });
      } else {
        _setDefaultSholatSchedule();
      }
    } catch (e) {
      _setDefaultSholatSchedule();
    } finally {
      if (mounted)
        setState(() {
          _isLoadingSholat = false;
        });
    }
  }

  Future<void> _saveLocationPreference(String cityId, String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city_id', cityId);
      await prefs.setString('last_city_name', cityName);
      await prefs.setBool('use_current_location', true);
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCityId = prefs.getString('last_city_id');
      final savedCityName = prefs.getString('last_city_name');
      final useCurrentLocation = prefs.getBool('use_current_location') ?? false;
      if (savedCityId != null && savedCityName != null) {
        setState(() {
          _selectedCityId = savedCityId;
          _selectedCityName = savedCityName;
          _useCurrentLocation = useCurrentLocation;
        });
        await _fetchSholatSchedule(savedCityId);
      } else {
        _setDefaultSholatSchedule();
      }
    } catch (e) {
      _setDefaultSholatSchedule();
    }
  }

  void _setDefaultSholatSchedule() {
    if (mounted) {
      setState(() {
        _jadwalSholat = {
          'lokasi': 'Jakarta',
          'daerah': 'DKI Jakarta',
          'jadwal': {
            'imsak': '04:22',
            'subuh': '04:32',
            'terbit': '05:46',
            'dzuhur': '12:08',
            'ashar': '15:30',
            'maghrib': '18:20',
            'isya': '19:33',
          },
        };
        _isLoadingSholat = false;
      });
    }
  }

  String _getNextSholatTime() {
    if (_jadwalSholat == null || _jadwalSholat!['jadwal'] == null)
      return "Mengambil jadwal...";
    final jadwal = _jadwalSholat!['jadwal'];
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final sholatTimes = [
      {'name': 'Subuh', 'time': jadwal['subuh']?.toString() ?? '04:32'},
      {'name': 'Dzuhur', 'time': jadwal['dzuhur']?.toString() ?? '12:08'},
      {'name': 'Ashar', 'time': jadwal['ashar']?.toString() ?? '15:30'},
      {'name': 'Maghrib', 'time': jadwal['maghrib']?.toString() ?? '18:20'},
      {'name': 'Isya', 'time': jadwal['isya']?.toString() ?? '19:33'},
    ];
    for (var sholat in sholatTimes) {
      if (_isTimeLater(sholat['time']!, currentTime)) {
        return "Menuju ${sholat['name']} : ${sholat['time']}";
      }
    }
    return "Menuju Imsak : ${jadwal['imsak']?.toString() ?? '04:22'}";
  }

  bool _isTimeLater(String time1, String time2) {
    try {
      final t1 = time1.split(':');
      final t2 = time2.split(':');
      final h1 = int.tryParse(t1[0]) ?? 0;
      final m1 = int.tryParse(t1[1]) ?? 0;
      final h2 = int.tryParse(t2[0]) ?? 0;
      final m2 = int.tryParse(t2[1]) ?? 0;
      return h1 > h2 || (h1 == h2 && m1 > m2);
    } catch (e) {
      return false;
    }
  }

  bool _isCurrentSholat(String sholatName, String? sholatTime) {
    if (sholatTime == null) return false;
    try {
      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final st = sholatTime.length >= 5
          ? sholatTime.substring(0, 5)
          : sholatTime;
      return st == currentTime;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // 🏙️ CITY SELECTOR - MODERN DARK TECH
  // ============================================================
  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: AppTheme.bgDeep,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXL),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusXL),
                      ),
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: AppTheme.gold),
                            const SizedBox(width: 12),
                            Text(
                              'Pilih Lokasi Sholat',
                              style: AppTheme.headingM.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: AppTheme.primaryButton(AppTheme.gold),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _fetchSholatTimes();
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.gps_fixed, color: AppTheme.bgDeep),
                                SizedBox(width: 10),
                                Text('Gunakan Lokasi Saat Ini'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Cari kota/kabupaten...',
                            hintStyle: const TextStyle(color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.bgInput,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              borderSide: const BorderSide(
                                color: AppTheme.borderSubtle,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              borderSide: const BorderSide(
                                color: AppTheme.borderSubtle,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              borderSide: const BorderSide(
                                color: AppTheme.gold,
                                width: 1.5,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                          ),
                          onChanged: (value) async {
                            if (value.length > 2) {
                              final results = await _sholatService.searchKota(
                                value,
                              );
                              setState(() {
                                _cityList = results;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cityList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  color: AppTheme.textMuted,
                                  size: 50,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Cari kota atau kabupaten',
                                  style: AppTheme.bodyM,
                                ),
                                const Text(
                                  'Minimal 3 karakter',
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cityList.length,
                            itemBuilder: (context, index) {
                              final city = _cityList[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: AppTheme.cardDecor(),
                                child: ListTile(
                                  title: Text(
                                    city['lokasi']?.toString() ?? 'Unknown',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: city['daerah'] != null
                                      ? Text(
                                          city['daerah'].toString(),
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                          ),
                                        )
                                      : null,
                                  trailing:
                                      _selectedCityId == city['id'].toString()
                                      ? const Icon(
                                          Icons.check,
                                          color: AppTheme.mint,
                                        )
                                      : null,
                                  onTap: () async {
                                    if (mounted) {
                                      setState(() {
                                        _selectedCityId = city['id'].toString();
                                        _selectedCityName =
                                            city['lokasi']?.toString() ??
                                            'Jakarta';
                                        _useCurrentLocation = false;
                                        _isLoadingSholat = true;
                                      });
                                    }
                                    await _fetchSholatSchedule(
                                      city['id'].toString(),
                                    );
                                    if (mounted) {
                                      setState(() {
                                        _isLoadingSholat = false;
                                      });
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.bgSurface,
                      border: Border(
                        top: BorderSide(color: AppTheme.borderSubtle, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pilih kota untuk mendapatkan jadwal sholat yang akurat',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // 🎌 FETCH ANIME
  // ============================================================
  Future<void> _fetchAnimeData() async {
    setState(() => _isLoadingAnime = true);
    try {
      final response = await http
          .get(Uri.parse('https://www.sankavollerei.com/anime/home'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map && jsonData.containsKey('data')) {
          final data = jsonData['data'];
          if (data is Map && data.containsKey('ongoing')) {
            final ongoing = data['ongoing'];
            if (ongoing is Map && ongoing.containsKey('animeList')) {
              final animeList = ongoing['animeList'] as List;
              _animeData = List<Map<String, dynamic>>.from(animeList.take(10));
            }
          }
        }
      }
      setState(() => _isLoadingAnime = false);
    } catch (e) {
      setState(() => _isLoadingAnime = false);
    }
  }

  void _initNewsBanner() {
    _newsPageController = PageController(
      initialPage: 0,
      viewportFraction: 0.92,
    );
    _newsPageController.addListener(() {
      if (_newsPageController.hasClients && _newsPageController.page != null) {
        _currentNewsPage = _newsPageController.page!;
      }
    });
    if (newsList.isNotEmpty) {
      _newsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_newsPageController.hasClients) {
          int targetIndex = (_currentNewsPage + 1).round() % newsList.length;
          _newsPageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_$username', picked.path);
    setState(() { _profileImage = File(picked.path); });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto profil diperbarui!"), backgroundColor: Color(0xFF39FF14)));
  }

  void _showChangeUsernameDialog() async {
    final ctrl = TextEditingController();
    bool loading = false;
    String? error;
    Map<String, dynamic>? profile;

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/get-profile'),
        body: jsonEncode({'key': sessionKey, 'username': username}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) profile = jsonDecode(res.body);
    } catch (e) {}

    if (!mounted) return;
    final canChange = profile?['canChangeUsername'] ?? true;
    final cooldown = profile?['cooldownRemaining'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.45,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.badge_rounded, color: Color(0xFFFFE74C), size: 22),
                  const SizedBox(width: 10),
                  const Text("GANTI USERNAME", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: 1)),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close_rounded, color: Colors.grey, size: 22)),
                ],
              ),
              const SizedBox(height: 16),
              if (!canChange && cooldown != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3), width: 1)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("COOLDOWN AKTIF", style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
                      const SizedBox(height: 6),
                      Text("Tunggu ${cooldown['days']} hari ${cooldown['hours']} jam ${cooldown['minutes']} menit lagi", style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontFamily: 'Inter')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text("Username saat ini: $username", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Inter')),
              ] else ...[
                Text("Username saat ini: $username", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Inter')),
                const SizedBox(height: 4),
                const Text("Setelah ganti, tidak bisa ganti lagi selama 10 hari.", style: TextStyle(color: Color(0xFFFFE74C), fontSize: 11, fontFamily: 'Inter')),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: "Username baru...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333), width: 2)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333), width: 2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFE74C), width: 2)),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'Inter')),
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: loading ? null : () async {
                    if (ctrl.text.trim().isEmpty) return;
                    setModalState(() { loading = true; error = null; });
                    try {
                      final res = await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/api/change-username'),
                        body: jsonEncode({'key': sessionKey, 'newUsername': ctrl.text.trim(), 'username': username}),
                        headers: {'Content-Type': 'application/json'},
                      ).timeout(const Duration(seconds: 10));
                      final data = jsonDecode(res.body);
                      if (res.statusCode == 200 && data['success'] == true) {
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Username diubah ke ${data['newUsername']}!"), backgroundColor: const Color(0xFF39FF14)));
                        }
                      } else {
                        setModalState(() { loading = false; error = data['error'] ?? 'Gagal'; });
                      }
                    } catch (e) {
                      setModalState(() { loading = false; error = 'Error: $e'; });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: loading ? Colors.grey[800] : const Color(0xFFFFE74C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text("GANTI USERNAME", style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('dark_mode_$username', _isDarkMode);
    });
  }

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('dark_mode_$username') ?? false;
    if (mounted) {
      setState(() {
        _isDarkMode = darkMode;
      });
    }
  }

  void _initBgVideo() {
    _bgVideoController = VideoPlayerController.asset('assets/videos/background.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() { _bgVideoInitialized = true; });
          _bgVideoController!.play();
        }
      }).catchError((e) { debugPrint('BG video error: $e'); });
  }

  void _initVideoBox() {
    _videoBoxController = VideoPlayerController.asset('assets/videos/background.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() { _videoBoxInit = true; });
          _videoBoxController!.play();
        }
      }).catchError((e) { debugPrint('Video box error: $e'); });
  }

  void _startPingTracker() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _lastPingSent = DateTime.now();
      try {
        channel.sink.add(jsonEncode({"type": "ping"}));
      } catch (e) {
        debugPrint('Ping send error: $e');
      }
    });
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  int _validateRetryCount = 0;
  static const int _maxValidateRetries = 3;

  void _connectToWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('wss://ws-dark.strideoryx.my.id'),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        channel.sink.add(
          jsonEncode({
            "type": "validate",
            "key": sessionKey,
            "androidId": androidId,
          }),
        );
        channel.sink.add(jsonEncode({"type": "stats"}));
      });
      _startPingTracker();
      channel.stream.listen(
        (event) {
          final data = jsonDecode(event);
          if (data['type'] == 'myInfo' && data['valid'] == false) {
            _validateRetryCount++;
            if (_validateRetryCount < _maxValidateRetries) {
              debugPrint('WebSocket validate failed, retry $_validateRetryCount/$_maxValidateRetries');
              Future.delayed(const Duration(seconds: 3), () {
                if (!mounted) return;
                channel.sink.add(jsonEncode({
                  "type": "validate",
                  "key": sessionKey,
                  "androidId": androidId,
                }));
              });
            } else {
              String message = data['reason'] == 'androidIdMismatch'
                  ? "Your account has logged on another device."
                  : "Key is not valid. Please login again.";
              _handleInvalidSession(message);
            }
          }
          if (data['type'] == 'stats') {
            setState(() {
              onlineUsers = data['onlineUsers'] ?? 0;
              activeConnections = data['activeConnections'] ?? 0;
            });
          }
          if (data['type'] == 'pong' && _lastPingSent != null) {
            final pingMs = DateTime.now().difference(_lastPingSent!).inMilliseconds;
            setState(() {
              _serverPing = pingMs;
            });
          }
          if (data['type'] == 'publicChat:online' && data['users'] is List) {
            setState(() {
              onlineUsers = (data['users'] as List).length;
            });
          }
          if (data['type'] == 'announcement' && data['announcement'] != null) {
            final ann = data['announcement'];
            _showAnnouncementDialog(ann['title'] ?? 'Pengumuman', ann['message'] ?? '', ann['from'] ?? 'Admin');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.coral, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Session Expired",
                style: AppTheme.headingM.copyWith(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: AppTheme.primaryButton(AppTheme.coral),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(String title, String message, String from) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111118),
        shape: Border.all(color: Colors.amberAccent, width: 2),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.amberAccent, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.amberAccent, fontFamily: 'Inter', fontWeight: FontWeight.w900))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 14)),
            const SizedBox(height: 8),
            Text("Dari: $from", style: TextStyle(color: Colors.grey[500], fontFamily: 'Inter', fontSize: 11)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.amberAccent,
              child: const Text("OK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == 2) {
      _showWhatsAppMenu();
      return;
    }
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildNewsPage();
        if (_isSoundOn) _audioService.resume();
      } else if (index == 1) {
        _cachedChatPage ??= ChatPage(
          sessionKey: sessionKey,
          username: username,
          role: role,
        );
        _selectedPage = _cachedChatPage!;
        _audioService.pause();
      } else if (index == 3) {
        _cachedInfoPage ??= InfoPage(sessionKey: sessionKey);
        _selectedPage = _cachedInfoPage!;
        _audioService.pause();
      } else if (index == 4) {
        _cachedToolsPage ??= ToolsPage(
          sessionKey: sessionKey,
          userRole: role,
          username: username,
          listDoos: listDoos,
        );
        _selectedPage = _cachedToolsPage!;
        _audioService.pause();
      }
    });
  }

  void _showWhatsAppMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.mint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.mint.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: AppTheme.neonGlow(AppTheme.mint, blur: 12, opacity: 0.25),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.whatsapp,
                      color: AppTheme.mint,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "WHATSAPP TOOLS",
                    style: AppTheme.headingM.copyWith(
                      color: AppTheme.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSheetItem(
                icon: Icons.bug_report_rounded,
                iconColor: AppTheme.coral,
                title: "WhatsApp Crash",
                subtitle: "Send payloads & crash codes",
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedPage = HomePage(
                      username: username,
                      password: password,
                      listBug: listBug,
                      role: role,
                      expiredDate: expiredDate,
                      sessionKey: sessionKey,
                    );
                  });
                  _audioService.pause();
                },
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: AppTheme.borderSubtle,
              ),
              const SizedBox(height: 12),
              _buildSheetItem(
                icon: Icons.devices_rounded,
                iconColor: AppTheme.sky,
                title: "Manage Sender",
                subtitle: "Pair devices & manage sessions",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BugSenderPage(
                        sessionKey: sessionKey,
                        username: username,
                        role: role,
                      ),
                    ),
                  );
                  _audioService.pause();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        splashColor: AppTheme.gold.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecor(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.bgDeep,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.headingS.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.bodyM.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🕌 PRAYER TIME CARD - MODERN DARK TECH
  // ============================================================
  Widget _buildPrayerTimeCard({
    required String prayerName,
    required String time,
    required IconData icon,
    required Color color,
    required bool isNext,
  }) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isNext ? color : AppTheme.borderSubtle,
          width: isNext ? 3 : 2,
        ),
        boxShadow: isNext ? AppTheme.neonGlow(color, blur: 14, opacity: 0.3) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (isNext)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.neonGlow(color, blur: 10, opacity: 0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              prayerName.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isNext ? color : AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'ShareTechMono',
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: isNext ? color : AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _buildError;

  @override
  Widget build(BuildContext context) {
    if (_buildError != null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFFF0040), size: 48),
                const SizedBox(height: 16),
                const Text("BUILD ERROR", style: TextStyle(color: Color(0xFFFF0040), fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Orbitron')),
                const SizedBox(height: 12),
                Text(_buildError!, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'ShareTechMono'), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() { _buildError = null; _selectedPage = _buildNewsPage(); }),
                  child: const Text("RETRY"),
                ),
              ],
            ),
          ),
        ),
      );
    }
    try {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: _bgPrimary,
        drawer: _buildCustomDrawer(),
        body: Container(color: _bgPrimary, child: _selectedPage),
        bottomNavigationBar: _buildBottomNav(),
      );
    } catch (e, st) {
      debugPrint("Dashboard build error: $e\n$st");
      return Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bug_report, color: Color(0xFFFF0040), size: 48),
                const SizedBox(height: 16),
                const Text("DASHBOARD ERROR", style: TextStyle(color: Color(0xFFFF0040), fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Orbitron')),
                const SizedBox(height: 12),
                Text("$e", style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'ShareTechMono'), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // BOTTOM NAV — CLEAN MINIMAL
  // ============================================================
  Widget _buildBottomNav() {
    final navData = [
      _NavData(Icons.home_rounded, "Home"),
      _NavData(Icons.chat_rounded, "Chat"),
      _NavData(FontAwesomeIcons.whatsapp, "WA"),
      _NavData(Icons.notifications_rounded, "Alert"),
      _NavData(Icons.grid_view_rounded, "Tools"),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.1 : 0.03),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navData.length, (i) {
          final d = navData[i];
          final active = _bottomNavIndex == i;
          return GestureDetector(
            onTap: () => _onBottomNavTapped(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: active ? 64 : 52,
              height: active ? 64 : 52,
              decoration: BoxDecoration(
                color: active
                    ? (_isDarkMode
                        ? _nbYellow.withValues(alpha: 0.15)
                        : _nbYellow.withValues(alpha: 0.12))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(active ? 22 : 18),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: _nbYellow.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    d.icon,
                    size: active ? 22 : 20,
                    color: active ? _nbYellow : _textTertiary,
                  ),
                  if (!active) ...[
                    const SizedBox(height: 3),
                    Text(
                      d.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _textTertiary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
  // ============================================================
  //  MEGATRON - NEO BRUTALISM COMMAND CENTER
  // ============================================================
  // Core neo-brutalism palette
  static const Color _nbBlack = Color(0xFF111111);
  static const Color _nbWhite = Color(0xFFFFFFFF);
  static const Color _nbYellow = Color(0xFFFFE74C);
  static const Color _nbGreen = Color(0xFF39FF14);
  static const Color _nbRed = Color(0xFFFF3B30);
  static const Color _nbBlue = Color(0xFF3B82F6);
  static const Color _nbPurple = Color(0xFF9333EA);
  static const Color _nbOrange = Color(0xFFFF9F0A);
  static const Color _nbCyan = Color(0xFF00D4FF);
  static const Color _nbBg = Color(0xFFF5F5F0);
  static const Color _nbCard = Color(0xFFFFFFFF);

  // Theme
  Color get _bgPrimary => _isDarkMode ? _nbBlack : _nbBg;
  Color get _bgSecondary => _isDarkMode ? const Color(0xFF1A1A1A) : _nbWhite;
  Color get _cardBg => _isDarkMode ? const Color(0xFF222222) : _nbWhite;
  Color get _textPrimary => _isDarkMode ? _nbWhite : _nbBlack;
  Color get _textSecondary => _isDarkMode ? const Color(0xFFAAAAAA) : const Color(0xFF666666);
  Color get _textTertiary => _isDarkMode ? const Color(0xFF777777) : const Color(0xFF999999);
  Color get _borderColor => _isDarkMode ? const Color(0xFF444444) : _nbBlack;

  Color _signalColor(int ping) {
    if (ping <= 0) return _nbRed;
    if (ping < 100) return _nbGreen;
    if (ping < 300) return _nbOrange;
    return _nbRed;
  }

  String _signalLabel(int ping) {
    if (ping <= 0) return "OFFLINE";
    if (ping < 100) return "OPTIMAL";
    if (ping < 300) return "MODERATE";
    return "DEGRADED";
  }

  // ════════ VIDEO BACKGROUND ════════
  Widget _buildVideoBackground() {
    if (!_bgVideoInitialized || _bgVideoController == null || !_bgVideoController!.value.isInitialized) {
      return const SizedBox.expand();
    }
    return RepaintBoundary(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _bgVideoController!.value.size.width,
            height: _bgVideoController!.value.size.height,
            child: VideoPlayer(_bgVideoController!),
          ),
        ),
      ),
    );
  }

  // ════════ USER CARD ════════
  Widget _buildUserCard() {
    final roleColor = role.toLowerCase() == 'developer' ? _nbPurple
        : role.toLowerCase() == 'owner' ? _nbRed
        : role.toLowerCase() == 'admin' ? _nbOrange : _nbBlue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Profile photo
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 76, height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [_nbYellow, _nbGreen]),
                    boxShadow: [BoxShadow(color: _nbYellow.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: _profileImage != null
                        ? Image.file(_profileImage!, fit: BoxFit.cover)
                        : Image.asset('assets/images/logo.jpg', fit: BoxFit.cover,
                            errorBuilder: (ctx, e, s) => Container(color: _nbYellow, child: Icon(Icons.person_rounded, color: _nbBlack, size: 36)),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: _nbYellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: _isDarkMode ? _nbBlack : Colors.white, width: 2.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: _nbBlack, size: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Username
          GestureDetector(
            onTap: _showChangeUsernameDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(username, style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Inter', letterSpacing: -0.5)),
                const SizedBox(width: 6),
                Icon(Icons.edit_rounded, color: _nbYellow.withValues(alpha: 0.6), size: 14),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Role + Active badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(role.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, fontFamily: 'Inter')),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _nbGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _nbGreen.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: _nbGreen, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _nbGreen.withValues(alpha: 0.5), blurRadius: 4)])),
                    const SizedBox(width: 5),
                    Text("ACTIVE", style: TextStyle(color: _nbGreen, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, fontFamily: 'Inter')),
                  ],
                ),
              ),
            ],
          ),
                child: Text("ACTIVE", style: TextStyle(color: _nbBlack, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5, fontFamily: 'Inter')),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _nbYellow, border: Border.all(color: _borderColor, width: 2)),
                child: Text("EXP: $expiredDate", style: TextStyle(color: _nbBlack, fontSize: 9, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════ STAGGERED ENTRY WRAPPER ════════
  Widget _slideIn(int index, {required Widget child}) {
    return AnimatedBuilder(
      animation: _entranceAnims[index],
      builder: (ctx, _) {
        final v = _entranceAnims[index].value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - v)),
            child: child,
          ),
        );
      },
    );
  }

  // ════════ PRESSABLE WRAPPER ════════
  Widget _pressable({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }

  // ════════ BREATHING GLOW ════════
  Widget _breathingGlow({required Widget child, Color color = _nbYellow, double radius = 12}) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (ctx, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.08 + _glowAnim.value * 0.08), blurRadius: radius + _glowAnim.value * 8, spreadRadius: _glowAnim.value),
            ],
          ),
          child: child,
        );
      },
    );
  }

  // ════════ STATUS PREVIEW (WhatsApp-like) ════════
  Widget _buildStatusPreview() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => StatusPage(sessionKey: sessionKey, username: username)));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            // Avatar with + icon
            Stack(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [_nbGreen, _nbCyan]),
                    boxShadow: [BoxShadow(color: _nbGreen.withValues(alpha: 0.2), blurRadius: 10)],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover,
                      errorBuilder: (ctx, e, s) => Container(color: _nbGreen, child: Icon(Icons.person_rounded, color: _nbBlack, size: 24)),
                    ),
                  ),
                ),
                Positioned(
                  right: -2, bottom: -2,
                  child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: _nbGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: _isDarkMode ? _nbBlack : Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("STATUS", style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFamily: 'Inter')),
                  const SizedBox(height: 2),
                  Text("Post status kamu sekarang", style: TextStyle(color: _textTertiary, fontSize: 11, fontFamily: 'Inter')),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _nbGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _nbGreen.withValues(alpha: 0.3), width: 1),
              ),
              child: Text("POST", style: TextStyle(color: _nbGreen, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, fontFamily: 'Inter')),
            ),
          ],
        ),
      ),
    );
  }

  // ════════ TEAM / CONTACT BUTTONS ════════
  Widget _buildTeamButtons() {
    return Row(
      children: [
        Expanded(child: _buildContactBtn("OWNER", "Kizz_Reals05", _nbRed, FontAwesomeIcons.telegram)),
        const SizedBox(width: 12),
        Expanded(child: _buildContactBtn("DEVELOPER", "zanzsii_md", _nbPurple, FontAwesomeIcons.telegram)),
      ],
    );
  }

  Widget _buildContactBtn(String label, String handle, Color color, IconData icon) {
    final url = Uri.parse("https://t.me/$handle");
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) async {
        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
      },
      onTapCancel: () => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter')),
                Text("@$handle", style: TextStyle(color: _nbWhite, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════ STAT CARDS ════════
  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: bgColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, fontFamily: 'Inter')),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: _textPrimary, fontSize: 30, fontWeight: FontWeight.w800, fontFamily: 'Inter', letterSpacing: -1)),
        ],
      ),
    );
  }

  // ════════ ANIMATED SIGNAL BAR ════════
  Widget _buildSignalBar() {
    final ping = _serverPing;
    final barCount = 24;
    final color = _signalColor(ping);

    return AnimatedBuilder(
      animation: _signalAnim,
      builder: (ctx, _) {
        final baseActive = ping <= 0 ? 0 : (barCount - (ping / 12).clamp(0, barCount).toInt());
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.wifi_rounded, color: color, size: 12),
                  ),
                  const SizedBox(width: 10),
                  Text("SIGNAL", style: TextStyle(color: _textPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFamily: 'Inter')),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text("${_signalLabel(ping)} • ${ping}ms", style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(barCount, (i) {
                  final wave = sin((_signalAnim.value * 3.14159 * 2) + (i * 0.5));
                  final isActive = i < baseActive;
                  final jitter = isActive ? (wave * 0.5 + 0.5) : 0.0;
                  final barHeight = isActive ? (8.0 + jitter * 14.0) : 3.0;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (i * 30)),
                      height: barHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isActive ? color : (_isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════ ANIMATED PING CARD ════════
  Widget _buildAnimatedPingCard() {
    final ping = _serverPing;
    final color = _signalColor(ping);

    return TweenAnimationBuilder<int>(
      duration: const Duration(milliseconds: 600),
      tween: IntTween(begin: _displayPing, end: ping),
      builder: (ctx, val, _) {
        _displayPing = val;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.speed_rounded, color: color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text("PING", style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, fontFamily: 'Inter')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("$val", style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w800, fontFamily: 'Inter', letterSpacing: -1)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text("ms", style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════ VIDEO BOX ════════
  Widget _buildVideoBox() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoBoxInit && _videoBoxController != null && _videoBoxController!.value.isInitialized)
            RepaintBoundary(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoBoxController!.value.size.width,
                  height: _videoBoxController!.value.size.height,
                  child: VideoPlayer(_videoBoxController!),
                ),
              ),
            )
          else
            Container(color: _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E0)),
          // Overlay gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
                Colors.transparent,
                _nbBlack.withValues(alpha: 0.4),
              ]),
            ),
          ),
          // Bottom label
          Positioned(
            left: 12, bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _nbYellow, border: Border.all(color: _nbBlack, width: 2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: _nbBlack, size: 14),
                  const SizedBox(width: 6),
                  Text("LIVE FEED", style: TextStyle(color: _nbBlack, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
                ],
              ),
            ),
          ),
          // Corner brackets
          Positioned(top: 8, left: 8, child: CustomPaint(size: const Size(16, 16), painter: _CornerPainter(_nbYellow, top: true, left: true))),
          Positioned(top: 8, right: 8, child: CustomPaint(size: const Size(16, 16), painter: _CornerPainter(_nbYellow, top: true, right: true))),
          Positioned(bottom: 8, left: 8, child: CustomPaint(size: const Size(16, 16), painter: _CornerPainter(_nbYellow, bottom: true, left: true))),
          Positioned(bottom: 8, right: 8, child: CustomPaint(size: const Size(16, 16), painter: _CornerPainter(_nbYellow, bottom: true, right: true))),
        ],
      ),
    );
  }

  // ════════ 3D CARD WRAPPER ════════
  Widget _nb3D({required Widget child, double depth = 5, Color? shadowColor}) {
    final sc = shadowColor ?? _borderColor;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.25 : 0.06), blurRadius: 20, offset: Offset(0, depth)),
          BoxShadow(color: sc.withValues(alpha: 0.08), blurRadius: depth * 3, offset: Offset(0, depth / 2)),
        ],
      ),
      child: child,
    );
  }

  // ════════ QUICK ACTION ════════
  Widget _buildQuickAction(IconData icon, String label, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: bgColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(label, style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Inter', letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _nbBlack),
                child: Text("OPEN", style: TextStyle(color: _nbWhite, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, fontFamily: 'Inter')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════ SYSTEM STATUS ════════
  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _nbGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shield_rounded, color: _nbGreen, size: 14),
              ),
              const SizedBox(width: 10),
              Text("STATUS SISTEM", style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFamily: 'Inter')),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _nbGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _nbGreen.withValues(alpha: 0.3), width: 1),
                ),
                child: Text("ACTIVE", style: TextStyle(color: _nbGreen, fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _statusBox("SERVER", "ONLINE", _nbGreen)),
              const SizedBox(width: 8),
              Expanded(child: _statusBox("API", "AKTIF", _nbCyan)),
              const SizedBox(width: 8),
              Expanded(child: _statusBox("SECURITY", "AMAN", _nbYellow)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFamily: 'Inter')),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  // ════════ HOT NEWS ════════
  Widget _buildHotNewsSection() {
    final hotTopics = [
      {"icon": "🔥", "title": "AI Regulation", "desc": "EU AI Act diberlakukan, tech giant harus comply", "time": "2m ago"},
      {"icon": "⚡", "title": "Crypto Rally", "desc": "Bitcoin tembus 120K, altcoin naik signifikan", "time": "5m ago"},
      {"icon": "🛡️", "title": "Zero-Day Exploit", "desc": "CVE baru ditemukan di Android, segera update", "time": "8m ago"},
      {"icon": "🚀", "title": "SpaceX Starship", "desc": "Misi Mars 2026 berhasil dock", "time": "12m ago"},
      {"icon": "🌐", "title": "5G Expansion", "desc": "Indonesia target 80% coverage 2026", "time": "15m ago"},
      {"icon": "🤖", "title": "GPT-5 Release", "desc": "OpenAI rilis model terbaru, reasoning makin kuat", "time": "20m ago"},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _nbRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_fire_department_rounded, color: _nbRed, size: 14),
              ),
              const SizedBox(width: 10),
              Text("HOT NEWS", style: TextStyle(color: _nbRed, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFamily: 'Inter')),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _nbRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _nbRed.withValues(alpha: 0.25), width: 1),
                ),
                child: Text("TRENDING", style: TextStyle(color: _nbRed, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _hotNewsController,
              itemCount: hotTopics.length,
              onPageChanged: (i) => setState(() => _hotNewsIndex = i),
              itemBuilder: (ctx, i) {
                final t = hotTopics[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isDarkMode
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(t["icon"]!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t["title"]!, style: TextStyle(color: _nbYellow, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
                            const SizedBox(height: 4),
                            Text(t["desc"]!, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontFamily: 'Inter', height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(t["time"]!, style: TextStyle(color: _nbRed, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(hotTopics.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _hotNewsIndex == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _hotNewsIndex == i ? _nbRed : _nbRed.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ════════ MAIN BUILD ════════
  Widget _buildNewsPage() {
    final now = DateTime.now();
    final dateStr = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    return Stack(
      children: [
        _buildVideoBackground(),
        Container(color: _bgPrimary.withValues(alpha: 0.82)),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // ══ TOP BAR (animated entry) ══
                _slideIn(0, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.04), blurRadius: 20, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(animation: _glowAnim, builder: (ctx, _) => Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _nbYellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.shield_rounded, color: _nbYellow, size: 20 + _glowAnim.value * 2),
                        )),
                        const SizedBox(width: 12),
                          Expanded(
                            child: _MegatronIntro(textColor: _nbYellow, glowColor: _nbYellow, fontSize: 20),
                          ),
                          Text(dateStr, style: TextStyle(color: _textSecondary, fontSize: 10, fontFamily: 'Inter')),
                          const SizedBox(width: 8),
                          const LiveClockWidget(),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleDarkMode,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: _nbYellow, size: 18),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _showAccessDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.vpn_key_rounded, color: _nbYellow, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),

                const SizedBox(height: 14),

                // ══ USER CARD ══
                _slideIn(1, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _nb3D(depth: 5, shadowColor: _nbYellow, child: _buildUserCard()))),

                const SizedBox(height: 12),

                // ══ TEAM BUTTONS ══
                _slideIn(2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildTeamButtons())),

                const SizedBox(height: 14),

                // ══ STATUS SECTION ══
                _slideIn(3, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildStatusPreview())),

                const SizedBox(height: 14),

                // ══ STAT CARDS ══
                _slideIn(4, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard("USERS", "$onlineUsers", Icons.people_rounded, _nbGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAnimatedPingCard()),
                    ],
                  ),
                )),

                const SizedBox(height: 14),

                // ══ VIDEO BOX ══
                _slideIn(5, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildVideoBox())),

                const SizedBox(height: 14),

                // ══ SIGNAL ══
                _slideIn(6, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildSignalBar())),

                const SizedBox(height: 14),

                // ══ QUICK ACTIONS ══
                _slideIn(7, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _nb3D(depth: 4, child: _pressable(onTap: () => _onBottomNavTapped(1), child: _buildQuickAction(Icons.public_rounded, "CHAT PUBLIC", _nbGreen, () => _onBottomNavTapped(1))))),
                      const SizedBox(width: 12),
                      Expanded(child: _nb3D(depth: 4, child: _pressable(onTap: () {
                        setState(() { _selectedPage = HomePage(username: username, password: password, listBug: listBug, role: role, expiredDate: expiredDate, sessionKey: sessionKey); });
                        _audioService.pause();
                      }, child: _buildQuickAction(FontAwesomeIcons.whatsapp, "WHATSAPP", _nbGreen, () {
                        setState(() { _selectedPage = HomePage(username: username, password: password, listBug: listBug, role: role, expiredDate: expiredDate, sessionKey: sessionKey); });
                        _audioService.pause();
                      })))),
                    ],
                  ),
                )),

                const SizedBox(height: 14),

                // ══ STATUS ══
                _slideIn(8, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _nb3D(depth: 5, child: _buildSystemStatus()))),

                const SizedBox(height: 14),

                // ══ HOT NEWS ══
                _slideIn(9, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildHotNewsSection())),

                const SizedBox(height: 14),

                // ══ NEWS TICKER ══
                _slideIn(10, child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: _isDarkMode ? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _nbYellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.newspaper_rounded, color: _nbYellow, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Text("NEWS", style: TextStyle(color: _nbYellow, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, fontFamily: 'Inter')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMarquee(text: "WELCOME TO MEGATRON  •  SYSTEM ONLINE  •  ALL SYSTEMS OPERATIONAL  •  STAY TUNED", style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                        ),
                      ],
                    ),
                  ),
                )),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ════════ MARQUEE WIDGET ════════
  Widget _buildMarquee({required String text, required TextStyle style}) {
    return AnimatedBuilder(
      animation: _signalAnim,
      builder: (ctx, _) {
        return Text(text, style: style, overflow: TextOverflow.ellipsis);
      },
    );
  }

  // ════════ ACCESS DIALOG ════════
  void _showAccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(side: BorderSide(color: _borderColor, width: 3), borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _nbYellow, border: Border.all(color: _borderColor, width: 2)), child: Icon(Icons.vpn_key_rounded, color: _nbBlack, size: 20)),
            const SizedBox(width: 10),
            Text("AKSES", style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w900, fontFamily: 'Inter', fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogItem(Icons.person_rounded, "USERNAME", username), const SizedBox(height: 8),
            _dialogItem(Icons.shield_rounded, "ROLE", role.toUpperCase()), const SizedBox(height: 8),
            _dialogItem(Icons.key_rounded, "SESSION", sessionKey.substring(0, 8.clamp(0, sessionKey.length)) + "..."), const SizedBox(height: 8),
            _dialogItem(Icons.calendar_today_rounded, "EXPIRED", expiredDate),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(color: _nbBlack),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("TUTUP", style: TextStyle(color: _nbYellow, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: _borderColor, width: 2), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: _textSecondary, size: 16),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: _textTertiary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, fontFamily: 'Inter')),
              Text(value, style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════ ANIME SECTION ══════════
  Widget _buildAnimeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.lavender.withValues(alpha: 0.15), AppTheme.lavender.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.5), width: 3),
          boxShadow: AppTheme.neonGlow(AppTheme.lavender, blur: 18, opacity: 0.25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lavender.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: AppTheme.lavender.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.live_tv_rounded,
                    color: AppTheme.lavender,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "LATEST ANIME",
                  style: AppTheme.headingM.copyWith(
                    color: AppTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                if (_animeData.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lavender.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: AppTheme.lavender.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "${_animeData.length} Anime",
                      style: const TextStyle(
                        color: AppTheme.lavender,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isLoadingAnime)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    color: AppTheme.lavender,
                    strokeWidth: 3,
                  ),
                ),
              )
            else if (_animeData.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "No anime data",
                    style: AppTheme.bodyM.copyWith(color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _animeData.length,
                  itemBuilder: (context, index) {
                    final anime = _animeData[index];
                    final title = anime['title'] ?? 'Unknown';
                    final poster = anime['poster'] ?? '';
                    final episode = anime['episodes']?.toString() ?? '?';
                    return Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.borderSubtle,
                                width: 1,
                              ),
                              boxShadow: AppTheme.softGlow(AppTheme.lavender, blur: 8, opacity: 0.1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              child: Stack(
                                children: [
                                  Image.network(
                                    poster,
                                    height: 145,
                                    width: 130,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 145,
                                      width: 130,
                                      color: AppTheme.bgCard,
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        color: AppTheme.textMuted,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgDeep.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                      ),
                                      child: Text(
                                        "EP $episode",
                                        style: const TextStyle(
                                          color: AppTheme.gold,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: AppTheme.bodyM.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════ HELPER WIDGETS ══════════
  Widget _iconBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2.5,
          ),
          boxShadow: AppTheme.neonGlow(color, blur: 12, opacity: 0.2),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
            borderRadius: BorderRadius.circular(2),
            boxShadow: AppTheme.neonGlow(color, blur: 8, opacity: 0.4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppTheme.headingS.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, Colors.transparent]),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 3),
          boxShadow: AppTheme.neonGlow(color, blur: 14, opacity: 0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: color.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: AppTheme.neonGlow(color, blur: 10, opacity: 0.3),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    "OPEN",
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: AppTheme.headingM.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sub,
              style: AppTheme.bodyM.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppTheme.borderSubtle,
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: AppTheme.softGlow(color, blur: 10, opacity: 0.12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildStatusChip({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(
            color: AppTheme.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gold, size: 11),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 THANX TO - ENHANCED
  // ============================================================
  Widget _buildThanksAndDeveloper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.coral.withValues(alpha: 0.15), AppTheme.coral.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.coral.withValues(alpha: 0.5), width: 3),
          boxShadow: AppTheme.neonGlow(AppTheme.coral, blur: 18, opacity: 0.25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.coral, AppTheme.lavender]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "THANX TO",
                  style: AppTheme.headingS.copyWith(
                    color: AppTheme.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              name: "zsnz",
              subtitle: "Developer",
              username: "zanzsii_md",
              link: "https://t.me/ZXSZSNZ",
              photoUrl: "https://files.catbox.moe/9nmpfg.jpg",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String name,
    required String subtitle,
    required String username,
    required String link,
    required String photoUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.coral.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              border: Border.all(
                color: AppTheme.coral.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: Image.network(
                photoUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.coral.withValues(alpha: 0.1),
                    child: Center(
                      child: Text(
                        name[0],
                        style: const TextStyle(
                          color: AppTheme.coral,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.headingM.copyWith(
                    color: AppTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _openUrl(link),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    FontAwesomeIcons.telegram,
                    color: AppTheme.bgDeep,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Contact",
                    style: TextStyle(
                      color: AppTheme.bgDeep,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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

  // ============================================================
  // 📰 BERITA TERKINI + JAM - MODERN DARK TECH
  // ============================================================
  Widget _buildNewsWithClockCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.mint.withValues(alpha: 0.15), AppTheme.mint.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.mint.withValues(alpha: 0.5), width: 3),
          boxShadow: AppTheme.neonGlow(AppTheme.mint, blur: 18, opacity: 0.25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.mint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: AppTheme.mint.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.newspaper,
                    color: AppTheme.mint,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "BERITA TERKINI",
                  style: AppTheme.headingM.copyWith(
                    color: AppTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                const LiveClockWidget(),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.mint.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: AppTheme.mint.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Text(
                "ANTARA NEWS",
                style: TextStyle(
                  color: AppTheme.mint,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingNews)
              SizedBox(
                height: 130,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppTheme.mint,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Memuat berita...",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_newsError.isNotEmpty)
              SizedBox(
                height: 130,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.coral, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        _newsError,
                        style: const TextStyle(
                          color: AppTheme.coral,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_newsData.isEmpty)
              SizedBox(
                height: 130,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.newspaper_rounded,
                        color: AppTheme.textMuted,
                        size: 30,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tidak ada berita",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 135,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _newsData.length > 5 ? 5 : _newsData.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return _buildCompactNewsItem(_newsData[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📰 COMPACT NEWS ITEM - MODERN DARK TECH
  // ============================================================
  Widget _buildCompactNewsItem(Map<String, dynamic> news) {
    String formattedTime = "";
    try {
      if (news['pubDate'].toString().isNotEmpty) {
        final dateTime = DateTime.parse(news['pubDate'].toString());
        formattedTime =
            "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
      }
    } catch (e) {
      final raw = news['pubDate'].toString();
      formattedTime = raw.length >= 16 ? raw.substring(11, 16) : raw;
    }

    return GestureDetector(
      onTap: () {
        if (news['link'].toString().isNotEmpty) _openUrl(news['link']);
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: AppTheme.borderMedium, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 70,
                width: double.infinity,
                color: AppTheme.bgDeep,
                child: news['imageUrl'].toString().isNotEmpty
                    ? Image.network(
                        news['imageUrl'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppTheme.textMuted,
                            size: 20,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.article_outlined,
                          color: AppTheme.textMuted,
                          size: 24,
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        news['title'] ?? 'Tidak ada judul',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: AppTheme.mint,
                            size: 8,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              color: AppTheme.mint,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🌤️ WEATHER CARD - ENHANCED
  // ============================================================
  Widget _buildWeatherCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.sky.withValues(alpha: 0.15), AppTheme.sky.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.sky.withValues(alpha: 0.5), width: 3),
          boxShadow: AppTheme.neonGlow(AppTheme.sky, blur: 18, opacity: 0.25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: AppTheme.neonGlow(AppTheme.gold, blur: 8, opacity: 0.2),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.cloudSun,
                    color: AppTheme.gold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "CUACA",
                  style: AppTheme.headingM.copyWith(
                    color: AppTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => isLoadingWeather = true);
                    _initWeather();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDeep,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: AppTheme.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.refresh_rounded,
                          color: AppTheme.gold,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "UPDATE",
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLoadingWeather)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: AppTheme.gold,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Memuat cuaca...",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (weatherData != null)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: FaIcon(
                              _getWeatherIcon(
                                weatherData!['weather'][0]['main'],
                              ),
                              color: AppTheme.gold,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${weatherData!['main']['temp'].round()}\u00B0C",
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'ShareTechMono',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                weatherData!['name'] ?? 'Lokasi',
                                style: AppTheme.bodyM.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(
                            color: AppTheme.gold.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          weatherData!['weather'][0]['main'] ?? '--',
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDeep,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(color: AppTheme.borderMedium, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _weatherDetailItem(
                          FontAwesomeIcons.droplet,
                          "Kelembaban",
                          "${weatherData!['main']['humidity']}%",
                          AppTheme.sky,
                        ),
                        Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                        _weatherDetailItem(
                          FontAwesomeIcons.wind,
                          "Angin",
                          "${(weatherData!['wind']['speed'] * 3.6).round()} km/h",
                          AppTheme.mint,
                        ),
                        Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                        _weatherDetailItem(
                          FontAwesomeIcons.eye,
                          "Visibilitas",
                          "${((weatherData!['visibility'] ?? 10000) / 1000).round()} km",
                          AppTheme.peach,
                        ),
                        Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                        _weatherDetailItem(
                          FontAwesomeIcons.temperatureHalf,
                          "Terasa",
                          "${weatherData!['main']['feels_like'].round()}\u00B0C",
                          AppTheme.coral,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else if (weatherErrorMsg.isNotEmpty)
              SizedBox(
                height: 80,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, color: AppTheme.textMuted, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        weatherErrorMsg,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(
                height: 80,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppTheme.sky,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Menunggu data cuaca...",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _weatherDetailItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontFamily: 'ShareTechMono',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 🕌 WAKTU SHOLAT CARD - MODERN DARK TECH
  // ============================================================
  Widget _buildSholatCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.mint.withValues(alpha: 0.15), AppTheme.mint.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.mint.withValues(alpha: 0.5), width: 3),
          boxShadow: AppTheme.neonGlow(AppTheme.mint, blur: 18, opacity: 0.25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.mint.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: AppTheme.mint.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: AppTheme.neonGlow(AppTheme.mint, blur: 8, opacity: 0.2),
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: AppTheme.mint,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "WAKTU SHOLAT",
                  style: AppTheme.headingM.copyWith(
                    color: AppTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showCitySelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _useCurrentLocation
                              ? Icons.gps_fixed
                              : Icons.edit_location_alt_rounded,
                          color: AppTheme.gold,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _useCurrentLocation ? _selectedCityName : "GANTI",
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                _useCurrentLocation
                    ? "Lokasi saat ini: $_selectedCityName"
                    : _selectedCityName,
                style: AppTheme.bodyM.copyWith(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgDeep,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(color: AppTheme.borderMedium, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.mint,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.neonGlow(AppTheme.mint, blur: 8, opacity: 0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_isLoadingSholat)
                    Text(
                      "Memuat jadwal...",
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Text(
                      _getNextSholatTime(),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5), width: 2),
                    ),
                    child: const Text(
                      "MEGATRON",
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_isLoadingSholat)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: const [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: AppTheme.mint,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Memuat jadwal sholat...",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_jadwalSholat == null || _jadwalSholat!['jadwal'] == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.textMuted,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Gagal memuat jadwal sholat",
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: AppTheme.primaryButton(AppTheme.mint),
                        onPressed: () => _fetchSholatTimes(),
                        child: const Text("Coba Lagi"),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10),
                  children: [
                    const SizedBox(width: 8),
                    _buildPrayerTimeCard(
                      prayerName: "Subuh",
                      time:
                          _jadwalSholat!['jadwal']['subuh']?.toString() ??
                          '--:--',
                      icon: Icons.nights_stay_rounded,
                      color: AppTheme.sky,
                      isNext: _isCurrentSholat(
                        "Subuh",
                        _jadwalSholat!['jadwal']['subuh']?.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPrayerTimeCard(
                      prayerName: "Dzuhur",
                      time:
                          _jadwalSholat!['jadwal']['dzuhur']?.toString() ??
                          '--:--',
                      icon: Icons.wb_sunny_rounded,
                      color: AppTheme.peach,
                      isNext: _isCurrentSholat(
                        "Dzuhur",
                        _jadwalSholat!['jadwal']['dzuhur']?.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPrayerTimeCard(
                      prayerName: "Ashar",
                      time:
                          _jadwalSholat!['jadwal']['ashar']?.toString() ??
                          '--:--',
                      icon: Icons.wb_cloudy_rounded,
                      color: AppTheme.coral,
                      isNext: _isCurrentSholat(
                        "Ashar",
                        _jadwalSholat!['jadwal']['ashar']?.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPrayerTimeCard(
                      prayerName: "Maghrib",
                      time:
                          _jadwalSholat!['jadwal']['maghrib']?.toString() ??
                          '--:--',
                      icon: Icons.nightlight_round,
                      color: AppTheme.lavender,
                      isNext: _isCurrentSholat(
                        "Maghrib",
                        _jadwalSholat!['jadwal']['maghrib']?.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPrayerTimeCard(
                      prayerName: "Isya",
                      time:
                          _jadwalSholat!['jadwal']['isya']?.toString() ??
                          '--:--',
                      icon: Icons.bedtime_rounded,
                      color: AppTheme.mint,
                      isNext: _isCurrentSholat(
                        "Isya",
                        _jadwalSholat!['jadwal']['isya']?.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOM DRAWER - MODERN DARK TECH
  // ============================================================
  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: AppTheme.bgSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
            decoration: const BoxDecoration(
              color: AppTheme.bgDeep,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.6),
                          width: 2.5,
                        ),
                        boxShadow: AppTheme.neonGlow(AppTheme.gold, blur: 14, opacity: 0.3),
                      ),
                      child: ClipRect(
                        child: _profileImage != null
                            ? Image.file(_profileImage!, fit: BoxFit.cover)
                            : const Icon(Icons.person, size: 40, color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radiusS),
                              border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.6),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (role == "developer" ||
                    role == "all_akses" ||
                    role == "owner")
                  _buildDrawerMenuItem(
                    icon: Icons.workspace_premium,
                    label: "Owner Panel",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPage = OwnerPage(
                          sessionKey: sessionKey,
                          username: username,
                        );
                      });
                      _audioService.pause();
                    },
                  ),
                if (role == "developer" ||
                    role == "all_akses" ||
                    role == "owner" ||
                    role == "admin")
                  _buildDrawerMenuItem(
                    icon: Icons.admin_panel_settings,
                    label: "Admin Panel",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPage = AdminPage(sessionKey: sessionKey);
                      });
                      _audioService.pause();
                    },
                  ),
                if (role == "reseller")
                  _buildDrawerMenuItem(
                    icon: Icons.storefront_rounded,
                    label: "Seller Panel",
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPage = SellerPage(keyToken: sessionKey);
                      });
                      _audioService.pause();
                    },
                  ),
                _buildDrawerMenuItem(
                  icon: Icons.history,
                  label: "${Lang.t('activity_history')}",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RiwayatPage(sessionKey: sessionKey, role: role),
                      ),
                    );
                    _audioService.pause();
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.person_outline,
                  label: "${Lang.t('my_profile')}",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          username: username,
                          password: password,
                          role: role,
                          expiredDate: expiredDate,
                          sessionKey: sessionKey,
                        ),
                      ),
                    );
                    _audioService.pause();
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.settings_outlined,
                  label: "${Lang.t('settings')}",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.coral.withValues(alpha: 0.2), AppTheme.coral.withValues(alpha: 0.08)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.coral.withValues(alpha: 0.6), width: 3),
                boxShadow: AppTheme.neonGlow(AppTheme.coral, blur: 14, opacity: 0.3),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  _audioService.stop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "LOGOUT",
                  style: TextStyle(
                    color: AppTheme.coral,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            splashColor: AppTheme.gold.withValues(alpha: 0.15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, color: AppTheme.gold, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textMuted,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final String label;
  const _NavData(this.icon, this.label);
}

// ============ EKG BORDER PAINTER ============
class _EKGBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF41).withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final mid = size.height / 2;
    final step = size.width / 10;

    path.moveTo(0, mid);
    path.lineTo(step * 2, mid);
    path.lineTo(step * 3, mid - 6);
    path.lineTo(step * 3.5, mid + 4);
    path.lineTo(step * 4, mid - 2);
    path.lineTo(step * 5, mid);
    path.lineTo(step * 7, mid);
    path.lineTo(step * 8, mid - 5);
    path.lineTo(step * 8.5, mid + 3);
    path.lineTo(step * 9, mid - 1);
    path.lineTo(step * 10, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============ GRID LINE PAINTER ============
class _GridLinePainter extends CustomPainter {
  final Color color;
  _GridLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    double step = 20;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============ VIDEO BACKGROUND ============
class _ProfileVideoBackground extends StatefulWidget {
  final String videoPath;
  const _ProfileVideoBackground({required this.videoPath});

  @override
  State<_ProfileVideoBackground> createState() =>
      _ProfileVideoBackgroundState();
}

class _ProfileVideoBackgroundState extends State<_ProfileVideoBackground> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(widget.videoPath)
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() => _isInitialized = true);
              _videoController.setVolume(0);
              _videoController.setLooping(true);
              _videoController.play();
            }
          })
          .catchError((e) {
            debugPrint("Video background error: $e");
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: AppTheme.bgDeep,
        child: const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.textMuted),
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController.value.size.width,
        height: _videoController.value.size.height,
        child: VideoPlayer(_videoController),
      ),
    );
  }
}

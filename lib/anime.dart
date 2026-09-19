import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:darkverse/theme/app_theme.dart';

class HomeAnimePage extends StatefulWidget {
  const HomeAnimePage({super.key});

  @override
  State<HomeAnimePage> createState() => _HomeAnimePageState();
}

class _HomeAnimePageState extends State<HomeAnimePage> {
  Map<String, dynamic>? animeData;
  bool isLoading = true;
  bool isSearching = false;
  List<dynamic> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _watchHistory = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnimeData();
    _loadWatchHistory();
  }

  void refreshHistory() {
    _loadWatchHistory();
  }

  Future<void> _loadWatchHistory() async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      setState(() {
        _watchHistory = historyJson
            .map((item) => Map<String, dynamic>.from(json.decode(item)))
            .toList();
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading watch history: $e');
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> fetchAnimeData() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/home'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeData = jsonData['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data anime');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> searchAnime(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/search/$query'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          searchResults = jsonData['data']['animeList'] ?? [];
        });
      } else {
        setState(() {
          searchResults = [];
        });
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() {
        searchResults = [];
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      searchResults.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        elevation: 0,
        title: const Text(
          'Tempat Wibu',
          style: AppTheme.headingM,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Search anime...",
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textSecondary),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide:
                      const BorderSide(color: AppTheme.lavender, width: 1.5),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  searchAnime(value);
                } else {
                  setState(() {
                    isSearching = false;
                    searchResults.clear();
                  });
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  searchAnime(value);
                }
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? _buildLoadingShimmer()
                : isSearching
                    ? _buildSearchResults()
                    : animeData == null
                        ? _buildErrorWidget()
                        : _buildHomeContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          fetchAnimeData(),
          _loadWatchHistory(),
        ]);
      },
      color: AppTheme.lavender,
      backgroundColor: AppTheme.bgCard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.history, "Watch History"),
            const SizedBox(height: 12),
            if (_isHistoryLoading)
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Shimmer.fromColors(
                        baseColor: AppTheme.bgCard,
                        highlightColor: AppTheme.bgCardLight,
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_watchHistory.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: AppTheme.cardDecor(border: AppTheme.borderSubtle),
                child: const Text(
                  "No watch history yet.\nStart watching an anime!",
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _watchHistory.length,
                  itemBuilder: (context, index) {
                    final anime = _watchHistory[index];
                    return _buildHistoryCard(anime);
                  },
                ),
              ),
            _buildSectionHeader(Icons.dashboard, "Quick Access"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    "Genre",
                    Icons.category,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AnimeGenreListPage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    "Schedule",
                    Icons.schedule,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AnimeSchedulePage()),
                      ).then((_) => refreshHistory());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(Icons.live_tv, "Currently Airing"),
            const SizedBox(height: 12),
            _buildAnimeGrid(animeData!['ongoing']['animeList'] ?? []),
            const SizedBox(height: 24),
            _buildSectionHeader(Icons.check_circle, "Completed Series"),
            const SizedBox(height: 12),
            _buildAnimeGrid(animeData!['completed']['animeList'] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.lavender, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.headingM.copyWith(color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.accentCardDecor(AppTheme.lavender),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.lavender, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> anime) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (anime['last_watched_episode_slug'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeEpisodePage(
                  episodeSlug: anime['last_watched_episode_slug'],
                  animeSlug: anime['slug'],
                  animeTitle: anime['title'],
                  animePoster: anime['poster'],
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailPage(
                  slug: anime['slug'],
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  child: Image.network(
                    anime['poster'],
                    height: 160,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      width: 120,
                      color: AppTheme.bgCard,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDeep.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.lavender, width: 1),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: AppTheme.lavender,
                      size: 16,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.bgDeep],
                      ),
                    ),
                    child: Text(
                      anime['last_watched_episode'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.lavender,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              anime['title'],
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, color: AppTheme.textMuted, size: 64),
            SizedBox(height: 16),
            Text(
              "No results found",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "Try with different keywords",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final anime = searchResults[index];
        return _buildSearchResultCard(anime);
      },
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> anime) {
    final String title = anime['title'];
    final String poster = anime['poster'];
    final String? status = anime['status'];
    final String? score = anime['score'];
    final String slug = anime['animeId'];
    final List<dynamic> genres = anime['genreList'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecor(border: AppTheme.borderSubtle),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(
                slug: slug,
                onHistoryUpdate: refreshHistory,
              ),
            ),
          ).then((_) => refreshHistory());
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                child: Image.network(
                  poster,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 120,
                    color: AppTheme.bgCardLight,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (score != null && score.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppTheme.gold,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                score,
                                style: const TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (status != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: AppTheme.bgDeep,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: genres.take(3).map<Widget>((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCardLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.lavender.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              genre['title'],
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return AppTheme.mint;
      case 'completed':
        return AppTheme.lavender;
      default:
        return AppTheme.textMuted;
    }
  }

  Widget _buildAnimeGrid(List<dynamic> list) {
    return GridView.builder(
      itemCount: list.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final anime = list[index];
        final String title = anime['title'];
        final String poster = anime['poster'];
        final String? episode = anime['episodes']?.toString();
        final String? date =
            anime['latestReleaseDate'] ?? anime['lastReleaseDate'];
        final String slug = anime['animeId'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailPage(
                  slug: slug,
                  onHistoryUpdate: refreshHistory,
                ),
              ),
            ).then((_) => refreshHistory());
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                child: Image.network(
                  poster,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 170,
                    color: AppTheme.bgCard,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  episode != null ? "$episode Episodes" : "-",
                  style: AppTheme.bodyM,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  "Updated: $date",
                  style: AppTheme.caption,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppTheme.bgCard,
        highlightColor: AppTheme.bgCardLight,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.textMuted, size: 64),
          const SizedBox(height: 16),
          const Text(
            "Failed to load data",
            style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await Future.wait([
                fetchAnimeData(),
                _loadWatchHistory(),
              ]);
            },
            style: AppTheme.primaryButton(AppTheme.lavender),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }
}

class AnimeDetailPage extends StatefulWidget {
  final String slug;
  final Function()? onHistoryUpdate;

  const AnimeDetailPage({super.key, required this.slug, this.onHistoryUpdate});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  Map<String, dynamic>? animeDetail;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchAnimeDetail();
  }

  Future<void> fetchAnimeDetail() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/anime/${widget.slug}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeDetail = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text(
          "Anime Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError || animeDetail == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.textMuted,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Failed to load anime details",
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchAnimeDetail,
                        style: AppTheme.primaryButton(AppTheme.lavender),
                        child: const Text("Try Again"),
                      ),
                    ],
                  ),
                )
              : _buildAnimeDetail(),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: AppTheme.bgCard,
            highlightColor: AppTheme.bgCardLight,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: AppTheme.bgCard,
            highlightColor: AppTheme.bgCardLight,
            child: Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: AppTheme.bgCard,
            highlightColor: AppTheme.bgCardLight,
            child: Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeDetail() {
    final anime = animeDetail!;
    final List<dynamic> episodes = anime['episodeList'] ?? [];
    final List<dynamic> recommendations = anime['recommendedAnimeList'] ?? [];
    final List<dynamic> genres = anime['genreList'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: Image.network(
                  anime['poster'],
                  height: 200,
                  width: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    width: 140,
                    color: AppTheme.bgCard,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime['title'],
                      style: AppTheme.headingM,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anime['japanese'] ?? '-',
                      style: AppTheme.bodyM,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: AppTheme.gold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          anime['score'] ?? '-',
                          style: const TextStyle(color: AppTheme.gold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem('Type', anime['type']),
                    _buildInfoItem('Status', anime['status']),
                    _buildInfoItem(
                        'Episodes', anime['episodes']?.toString()),
                    _buildInfoItem('Duration', anime['duration']),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (genres.isNotEmpty) ...[
            const Text(
              "Genres",
              style: AppTheme.headingM,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres.map<Widget>((genre) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimeGenrePage(
                          genreSlug: genre['genreId'],
                          genreName: genre['title'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: AppTheme.accentCardDecor(AppTheme.lavender),
                    child: Text(
                      genre['title'],
                      style: TextStyle(
                          color: AppTheme.lavender,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (anime['synopsis'] != null &&
              anime['synopsis']['paragraphs'].isNotEmpty) ...[
            const Text(
              "Synopsis",
              style: AppTheme.headingM,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecor(border: AppTheme.borderSubtle),
              child: Text(
                anime['synopsis']['paragraphs'].join('\n\n'),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (episodes.isNotEmpty) ...[
            const Text(
              "Episodes",
              style: AppTheme.headingM,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration:
                      AppTheme.cardDecor(border: AppTheme.borderSubtle),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.lavender,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Center(
                        child: Text(
                          episode['eps'].toString(),
                          style: const TextStyle(
                              color: AppTheme.bgDeep,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    title: Text(
                      episode['title'],
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeEpisodePage(
                            episodeSlug: episode['episodeId'],
                            animeSlug: widget.slug,
                            animeTitle: anime['title'],
                            animePoster: anime['poster'],
                            episodes: episodes,
                            recommendations: recommendations,
                            onHistoryUpdate: widget.onHistoryUpdate,
                          ),
                        ),
                      ).then((_) {
                        if (widget.onHistoryUpdate != null) {
                          widget.onHistoryUpdate!();
                        }
                      });
                    },
                    trailing: const Icon(Icons.play_arrow,
                        color: AppTheme.lavender),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
          if (anime['batch'] != null) ...[
            Container(
              decoration:
                  AppTheme.cardDecor(border: AppTheme.borderSubtle),
              child: ListTile(
                leading:
                    const Icon(Icons.download, color: AppTheme.lavender),
                title: const Text(
                  "Download Batch",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  anime['batch']['title'],
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                onTap: () => _launchURL(anime['batch']['otakudesuUrl']),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: AppTheme.textMuted, size: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (recommendations.isNotEmpty) ...[
            const Text(
              "Recommendations",
              style: AppTheme.headingM,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final recommendation = recommendations[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeDetailPage(
                            slug: recommendation['animeId'],
                            onHistoryUpdate: widget.onHistoryUpdate,
                          ),
                        ),
                      ).then((_) {
                        if (widget.onHistoryUpdate != null) {
                          widget.onHistoryUpdate!();
                        }
                      });
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                            child: Image.network(
                              recommendation['poster'],
                              height: 160,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 160,
                                width: 120,
                                color: AppTheme.bgCard,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendation['title'],
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value ?? '-',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimeGenrePage extends StatefulWidget {
  final String genreSlug;
  final String genreName;

  const AnimeGenrePage({
    super.key,
    required this.genreSlug,
    required this.genreName,
  });

  @override
  State<AnimeGenrePage> createState() => _AnimeGenrePageState();
}

class _AnimeGenrePageState extends State<AnimeGenrePage> {
  List<dynamic> animeList = [];
  Map<String, dynamic>? pagination;
  bool isLoading = true;
  bool isError = false;
  int currentPage = 1;

  Future<void> fetchGenreAnime({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://www.sankavollerei.com/anime/genre/${widget.genreSlug}?page=$page'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeList = jsonData['data']['animeList'];
          pagination = jsonData['pagination'];
          isLoading = false;
          currentPage = page;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenreAnime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          "Genre: ${widget.genreName}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.textMuted,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Failed to load genre data",
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => fetchGenreAnime(),
                        style: AppTheme.primaryButton(AppTheme.lavender),
                        child: const Text("Try Again"),
                      ),
                    ],
                  ),
                )
              : _buildGenreContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.bgCard,
          highlightColor: AppTheme.bgCardLight,
          child: Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenreContent() {
    return Column(
      children: [
        if (pagination != null) _buildPaginationInfo(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return _buildAnimeCard(anime);
            },
          ),
        ),
        if (pagination != null) _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(border: AppTheme.borderSubtle),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Page $currentPage of ${pagination!['totalPages']}",
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
            ),
          ),
          Text(
            "Total: ${animeList.length} anime",
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final hasNext = pagination!['hasNextPage'] ?? false;
    final hasPrev = pagination!['hasPrevPage'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasPrev)
            ElevatedButton(
              onPressed: () => fetchGenreAnime(page: currentPage - 1),
              style: AppTheme.primaryButton(AppTheme.lavender),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16),
                  SizedBox(width: 4),
                  Text("Previous"),
                ],
              ),
            ),
          const SizedBox(width: 16),
          if (hasNext)
            ElevatedButton(
              onPressed: () => fetchGenreAnime(page: currentPage + 1),
              style: AppTheme.primaryButton(AppTheme.lavender),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Next"),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    final String title = anime['title'];
    final String poster = anime['poster'];
    final String score = anime['score'] ?? '-';
    final String episodeCount = anime['episodes']?.toString() ?? '?';
    final String season = anime['season'] ?? '-';
    final String studio = anime['studios'] ?? '-';
    final String synopsis =
        anime['synopsis'] != null && anime['synopsis']['paragraphs'] != null
            ? anime['synopsis']['paragraphs'].join('\n\n')
            : '';
    final String slug = anime['animeId'];
    final List<dynamic> genres = anime['genreList'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecor(border: AppTheme.borderSubtle),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(slug: slug),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                child: Image.network(
                  poster,
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 140,
                    color: AppTheme.bgCardLight,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppTheme.gold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              score,
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "$episodeCount Episodes",
                          style: AppTheme.bodyM,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$season • $studio",
                      style: AppTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (genres.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: genres.take(3).map<Widget>((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: AppTheme.accentCardDecor(
                                AppTheme.lavender),
                            child: Text(
                              genre['title'],
                              style: const TextStyle(
                                color: AppTheme.lavender,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (synopsis.isNotEmpty) ...[
                      Text(
                        synopsis,
                        style: AppTheme.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimeSchedulePage extends StatefulWidget {
  const AnimeSchedulePage({super.key});

  @override
  State<AnimeSchedulePage> createState() => _AnimeSchedulePageState();
}

class _AnimeSchedulePageState extends State<AnimeSchedulePage> {
  List<dynamic> scheduleData = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/schedule'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          scheduleData = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text(
          "Release Schedule",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
              ? _buildErrorWidget()
              : _buildScheduleContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.bgCard,
          highlightColor: AppTheme.bgCardLight,
          child: Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.textMuted, size: 64),
          const SizedBox(height: 16),
          const Text(
            "Failed to load release schedule",
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchSchedule,
            style: AppTheme.primaryButton(AppTheme.lavender),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: scheduleData.length,
      itemBuilder: (context, index) {
        final daySchedule = scheduleData[index];
        final String day = daySchedule['day'];
        final List<dynamic> animeList = daySchedule['anime_list'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.cardDecor(border: AppTheme.borderSubtle),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: AppTheme.accentCardDecor(AppTheme.lavender),
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: AppTheme.lavender,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${animeList.length} Anime",
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (animeList.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: animeList.length,
                      itemBuilder: (context, animeIndex) {
                        final anime = animeList[animeIndex];
                        final String title = anime['title'];
                        final String poster = anime['poster'];
                        final String slug = anime['slug'];

                        return Container(
                          width: 120,
                          margin: EdgeInsets.only(
                            right:
                                animeIndex == animeList.length - 1 ? 0 : 12,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AnimeDetailPage(slug: slug),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusS),
                                  child: Image.network(
                                    poster,
                                    width: 120,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 120,
                                      height: 160,
                                      color: AppTheme.bgCardLight,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimeGenreListPage extends StatefulWidget {
  const AnimeGenreListPage({super.key});

  @override
  State<AnimeGenreListPage> createState() => _AnimeGenreListPageState();
}

class _AnimeGenreListPageState extends State<AnimeGenreListPage> {
  List<dynamic> genreList = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchGenreList() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/genre/'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          genreList = jsonData['data']['genreList'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching genre list: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenreList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text(
          "Anime Genres",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError
              ? _buildErrorWidget()
              : _buildGenreGrid(),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 20,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.bgCard,
          highlightColor: AppTheme.bgCardLight,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.textMuted, size: 64),
          const SizedBox(height: 16),
          const Text(
            "Failed to load genre list",
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchGenreList,
            style: AppTheme.primaryButton(AppTheme.lavender),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: genreList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, index) {
        final genre = genreList[index];
        final String name = genre['title'];
        final String slug = genre['genreId'];

        return Container(
          decoration: AppTheme.cardDecor(border: AppTheme.borderSubtle),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimeGenrePage(
                    genreSlug: slug,
                    genreName: name,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Center(
              child: Text(
                name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimeEpisodePage extends StatefulWidget {
  final String episodeSlug;
  final String? animeSlug;
  final String? animeTitle;
  final String? animePoster;
  final List<dynamic>? episodes;
  final List<dynamic>? recommendations;
  final Function()? onHistoryUpdate;

  const AnimeEpisodePage({
    super.key,
    required this.episodeSlug,
    this.animeSlug,
    this.animeTitle,
    this.animePoster,
    this.episodes,
    this.recommendations,
    this.onHistoryUpdate,
  });

  @override
  State<AnimeEpisodePage> createState() => _AnimeEpisodePageState();
}

class _AnimeEpisodePageState extends State<AnimeEpisodePage>
    with WidgetsBindingObserver {
  Map<String, dynamic>? episodeData;
  bool isLoading = true;
  bool isError = false;
  int _currentTabIndex = 0;

  late WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _isFullScreen = false;

  List<dynamic> _qualities = [];
  int _selectedQualityIndex = 0;
  int _selectedServerIndex = 0;
  bool _showQualitySelector = false;

  String? _streamUrl;
  int _currentEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchEpisodeData();
    _findCurrentEpisodeIndex();
  }

  void _findCurrentEpisodeIndex() {
    if (widget.episodes != null) {
      for (int i = 0; i < widget.episodes!.length; i++) {
        if (widget.episodes![i]['episodeId'] == widget.episodeSlug) {
          setState(() {
            _currentEpisodeIndex = i;
          });
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final physicalSize = WidgetsBinding.instance.window.physicalSize;
    final pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final logicalSize = physicalSize / pixelRatio;

    final isNowFullScreen = logicalSize.width > logicalSize.height;

    if (isNowFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = isNowFullScreen;
      });

      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  Future<void> fetchEpisodeData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://www.sankavollerei.com/anime/episode/${widget.episodeSlug}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          episodeData = jsonData['data'];
          _qualities = episodeData?['server']?['qualities'] ?? [];
          if (_qualities.isNotEmpty) {
            for (int i = 0; i < _qualities.length; i++) {
              final quality = _qualities[i];
              final serverList = quality['serverList'] ?? [];
              if (serverList.isNotEmpty) {
                _selectedQualityIndex = i;
                _selectedServerIndex = 0;
                break;
              }
            }
          }
        });

        await _fetchStreamUrl();
        _initializeWebView();
        _addToWatchHistory();

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> _fetchStreamUrl() async {
    if (_qualities.isEmpty) return;

    final selectedQuality = _qualities[_selectedQualityIndex];
    final serverList = selectedQuality['serverList'] ?? [];
    if (serverList.isEmpty) return;

    final selectedServer = serverList[_selectedServerIndex];
    final serverId = selectedServer['serverId'];

    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/server/$serverId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _streamUrl = jsonData['data']['url'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching stream URL: $e');
    }
  }

  Future<void> _addToWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      List<Map<String, dynamic>> watchHistory = historyJson
          .map((item) => Map<String, dynamic>.from(json.decode(item)))
          .toList();

      final historyItem = {
        'slug': widget.animeSlug,
        'title': widget.animeTitle,
        'poster': widget.animePoster,
        'last_watched_episode': episodeData?['title'],
        'last_watched_episode_slug': widget.episodeSlug,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      watchHistory
          .removeWhere((item) => item['slug'] == widget.animeSlug);
      watchHistory.insert(0, historyItem);

      if (watchHistory.length > 20) {
        watchHistory = watchHistory.sublist(0, 20);
      }

      final newHistoryJson =
          watchHistory.map((item) => json.encode(item)).toList();
      await prefs.setStringList('watch_history', newHistoryJson);

      if (widget.onHistoryUpdate != null) {
        widget.onHistoryUpdate!();
      }
    } catch (e) {
      debugPrint('Error saving to watch history: $e');
    }
  }

  void _initializeWebView() {
    if (_streamUrl == null) return;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FullScreen',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'enter') {
            _enterFullScreen();
          } else if (message.message == 'exit') {
            _exitFullScreen();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isWebViewLoading = false;
              });
              _injectFullScreenDetection();
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isWebViewLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isWebViewLoading = false;
            });
            _injectFullScreenDetection();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isWebViewLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(_streamUrl!),
        headers: _getChromeHeaders(),
      );
  }

  void _injectFullScreenDetection() {
    _webViewController.runJavaScript('''
      function handleFullScreenChange() {
        if (document.fullscreenElement || document.webkitFullscreenElement || 
            document.mozFullScreenElement || document.msFullscreenElement) {
          FullScreen.postMessage('enter');
        } else {
          FullScreen.postMessage('exit');
        }
      }
      document.addEventListener('fullscreenchange', handleFullScreenChange);
      document.addEventListener('webkitfullscreenchange', handleFullScreenChange);
      document.addEventListener('mozfullscreenchange', handleFullScreenChange);
      document.addEventListener('MSFullscreenChange', handleFullScreenChange);
      document.addEventListener('click', function(e) {
        if (e.target.tagName === 'VIDEO' || e.target.closest('video')) {
          setTimeout(handleFullScreenChange, 100);
        }
      });
      document.addEventListener('touchend', function(e) {
        if (e.target.tagName === 'VIDEO' || e.target.closest('video')) {
          setTimeout(handleFullScreenChange, 100);
        }
      });
      document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
          setTimeout(handleFullScreenChange, 100);
        }
      });
      console.log('Fullscreen detection injected');
    ''');
  }

  void _enterFullScreen() {
    if (!_isFullScreen) {
      setState(() {
        _isFullScreen = true;
      });
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _exitFullScreen() {
    if (_isFullScreen) {
      setState(() {
        _isFullScreen = false;
      });
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Map<String, String> _getChromeHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
    };
  }

  void _refreshWebView() {
    setState(() {
      _isWebViewLoading = true;
    });
    _webViewController.reload();
  }

  void _openInExternalBrowser() {
    if (_streamUrl != null) {
      _launchURL(_streamUrl!);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDownloadOptions() {
    if (episodeData == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusM),
        ),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Download Options",
                  style: AppTheme.headingM,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Download options will be available soon.",
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openInExternalBrowser();
                  },
                  style: AppTheme.primaryButton(AppTheme.lavender),
                  child: const Text("Open in Browser"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToNextEpisode() {
    if (widget.episodes != null &&
        _currentEpisodeIndex < widget.episodes!.length - 1) {
      final nextEpisode = widget.episodes![_currentEpisodeIndex + 1];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeEpisodePage(
            episodeSlug: nextEpisode['episodeId'],
            animeSlug: widget.animeSlug,
            animeTitle: widget.animeTitle,
            animePoster: widget.animePoster,
            episodes: widget.episodes,
            recommendations: widget.recommendations,
            onHistoryUpdate: widget.onHistoryUpdate,
          ),
        ),
      );
    }
  }

  void _changeQuality(int qualityIndex, int serverIndex) async {
    setState(() {
      _selectedQualityIndex = qualityIndex;
      _selectedServerIndex = serverIndex;
      _isWebViewLoading = true;
      _streamUrl = null;
    });

    await _fetchStreamUrl();
    _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: _isFullScreen
          ? null
          : AppBar(
              backgroundColor: AppTheme.bgSurface,
              iconTheme: const IconThemeData(color: AppTheme.textPrimary),
              title: Text(
                episodeData?['title'] ?? "Streaming Anime",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                if (episodeData != null) ...[
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: AppTheme.textPrimary),
                    onPressed: _refreshWebView,
                    tooltip: 'Refresh',
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_browser,
                        color: AppTheme.textPrimary),
                    onPressed: _openInExternalBrowser,
                    tooltip: 'Open in Browser',
                  ),
                  IconButton(
                    onPressed: _showDownloadOptions,
                    icon: const Icon(Icons.download,
                        color: AppTheme.textPrimary),
                    tooltip: 'Download',
                  ),
                ],
              ],
            ),
      body: isLoading
          ? _buildLoadingShimmer()
          : isError || episodeData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.textMuted,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Failed to load episode",
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchEpisodeData,
                        style:
                            AppTheme.primaryButton(AppTheme.lavender),
                        child: const Text("Try Again"),
                      ),
                    ],
                  ),
                )
              : _buildStreamingContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: AppTheme.bgCard,
            highlightColor: AppTheme.bgCardLight,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: AppTheme.bgCard,
            highlightColor: AppTheme.bgCardLight,
            child: Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingContent() {
    final List<dynamic> episodes = widget.episodes ?? [];
    final List<dynamic> recommendations = widget.recommendations ?? [];
    final List<dynamic> genres = episodeData?['genreList'] ?? [];

    return Column(
      children: [
        Container(
          height: _isFullScreen
              ? MediaQuery.of(context).size.height
              : MediaQuery.of(context).size.height * 0.35,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              if (_streamUrl != null)
                WebViewWidget(controller: _webViewController)
              else
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.lavender,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Loading stream URL...",
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              if (_isWebViewLoading)
                Container(
                  color: AppTheme.bgDeep.withValues(alpha: 0.87),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.lavender,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading video player...",
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_isFullScreen && _qualities.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgDeep.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: PopupMenuButton<int>(
                      icon: const Icon(Icons.settings,
                          color: AppTheme.textPrimary),
                      tooltip: 'Quality Settings',
                      color: AppTheme.bgCard,
                      onSelected: (index) {
                        setState(() {
                          _showQualitySelector = true;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<int>(
                          value: 0,
                          child: Text(
                            'Quality Settings',
                            style:
                                TextStyle(color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isFullScreen)
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDeep.withValues(alpha: 0.54),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.fullscreen_exit,
                          color: AppTheme.textPrimary, size: 30),
                    ),
                    onPressed: _exitFullScreen,
                  ),
                ),
            ],
          ),
        ),
        if (_showQualitySelector && !_isFullScreen && _qualities.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.bgCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select Quality",
                      style: AppTheme.headingM,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppTheme.textPrimary),
                      onPressed: () {
                        setState(() {
                          _showQualitySelector = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _qualities.length,
                  itemBuilder: (context, qualityIndex) {
                    final quality = _qualities[qualityIndex];
                    final qualityTitle = quality['title'] ?? '';
                    final serverList = quality['serverList'] ?? [];

                    if (serverList.isEmpty) return const SizedBox.shrink();

                    return ExpansionTile(
                      title: Text(
                        qualityTitle,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(left: 16),
                      backgroundColor: AppTheme.bgCardLight,
                      collapsedBackgroundColor: AppTheme.bgCardLight,
                      iconColor: AppTheme.textPrimary,
                      collapsedIconColor: AppTheme.textPrimary,
                      children: serverList.map<Widget>((server) {
                        final serverTitle = server['title'] ?? '';
                        final serverIndex = serverList.indexOf(server);
                        final isSelected =
                            _selectedQualityIndex == qualityIndex &&
                                _selectedServerIndex == serverIndex;

                        return ListTile(
                          title: Text(
                            serverTitle,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.lavender
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check,
                                  color: AppTheme.lavender)
                              : null,
                          onTap: () {
                            _changeQuality(qualityIndex, serverIndex);
                            setState(() {
                              _showQualitySelector = false;
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        if (!_isFullScreen && !_showQualitySelector) ...[
          Container(
            height: 50,
            color: AppTheme.bgCard,
            child: Row(
              children: [
                _buildTabButton(0, Icons.playlist_play, 'Episodes'),
                _buildTabButton(1, Icons.recommend, 'Recommendations'),
                _buildTabButton(2, Icons.category, 'Genres'),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildEpisodeList(episodes),
                _buildRecommendations(recommendations),
                _buildGenresList(genres),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: Material(
        color: isSelected ? AppTheme.lavender : Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentTabIndex = index;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.bgDeep : AppTheme.textPrimary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.bgDeep : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeList(List<dynamic> episodes) {
    if (episodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_play, color: AppTheme.textMuted, size: 64),
            SizedBox(height: 16),
            Text(
              "No episodes available",
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_currentEpisodeIndex < episodes.length - 1)
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _goToNextEpisode,
              icon: const Icon(Icons.skip_next),
              label: const Text("Next Episode"),
              style: AppTheme.primaryButton(AppTheme.lavender),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              final isCurrentEpisode =
                  episode['episodeId'] == widget.episodeSlug;

              return Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isCurrentEpisode
                      ? AppTheme.lavender
                      : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: isCurrentEpisode
                      ? null
                      : Border.all(color: AppTheme.borderSubtle),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCurrentEpisode
                          ? AppTheme.bgDeep.withValues(alpha: 0.2)
                          : AppTheme.bgCardLight,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Center(
                      child: Text(
                        episode['eps'].toString(),
                        style: TextStyle(
                          color: isCurrentEpisode
                              ? AppTheme.bgDeep
                              : AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    episode['title'],
                    style: TextStyle(
                      color: isCurrentEpisode
                          ? AppTheme.bgDeep
                          : AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.play_arrow,
                    color: isCurrentEpisode
                        ? AppTheme.bgDeep
                        : AppTheme.textPrimary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimeEpisodePage(
                          episodeSlug: episode['episodeId'],
                          animeSlug: widget.animeSlug,
                          animeTitle: widget.animeTitle,
                          animePoster: widget.animePoster,
                          episodes: episodes,
                          recommendations: widget.recommendations,
                          onHistoryUpdate: widget.onHistoryUpdate,
                        ),
                      ),
                    ).then((_) {
                      if (widget.onHistoryUpdate != null) {
                        widget.onHistoryUpdate!();
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(List<dynamic> recommendations) {
    if (recommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recommend, color: AppTheme.textMuted, size: 64),
            SizedBox(height: 16),
            Text(
              "No recommendations available",
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final anime = recommendations[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: AppTheme.cardDecor(border: AppTheme.borderSubtle),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: Image.network(
                anime['poster'],
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 70,
                  color: AppTheme.bgCardLight,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported,
                      color: AppTheme.textMuted),
                ),
              ),
            ),
            title: Text(
              anime['title'],
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: AppTheme.textMuted, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimeDetailPage(
                    slug: anime['animeId'],
                    onHistoryUpdate: widget.onHistoryUpdate,
                  ),
                ),
              ).then((_) {
                if (widget.onHistoryUpdate != null) {
                  widget.onHistoryUpdate!();
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildGenresList(List<dynamic> genres) {
    if (genres.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, color: AppTheme.textMuted, size: 64),
            SizedBox(height: 16),
            Text(
              "No genres available",
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: AppTheme.accentCardDecor(AppTheme.lavender),
          child: ListTile(
            leading: const Icon(Icons.label, color: AppTheme.lavender),
            title: Text(
              genre['title'],
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: AppTheme.textMuted, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimeGenrePage(
                    genreSlug: genre['genreId'],
                    genreName: genre['title'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

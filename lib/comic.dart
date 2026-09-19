import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:darkverse/theme/app_theme.dart';

class ComicPage extends StatefulWidget {
  const ComicPage({super.key});

  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _comicList = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _headingText = "Hot Comic";

  @override
  void initState() {
    super.initState();
    _fetchTopManga();
  }

  Future<void> _fetchTopManga() async {
    setState(() { _isLoading = true; _isSearching = false; _headingText = "Hot Comic"; });
    try {
      final response = await http.get(Uri.parse('https://api.jikan.moe/v4/top/manga?limit=20'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() { _comicList = data['data']; _isLoading = false; });
      }
    } catch (e) {
      debugPrint("Error fetching manga: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchManga(String query) async {
    if (query.isEmpty) return;
    setState(() { _isLoading = true; _isSearching = true; _headingText = "Search Result"; });
    try {
      final response = await http.get(Uri.parse('https://api.jikan.moe/v4/manga?q=$query&limit=20'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() { _comicList = data['data']; _isLoading = false; });
      }
    } catch (e) {
      debugPrint("Error searching manga: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("COMIC ZONE", style: AppTheme.headingM.copyWith(fontFamily: "Orbitron")),
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: AppTheme.bgDeep.withValues(alpha: 0.7)),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.bgDeep, AppTheme.bgSurface, AppTheme.bgDeep]),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),

                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.accentCardDecor(AppTheme.sky).copyWith(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                  child: Column(
                    children: [
                      const Icon(FontAwesomeIcons.bookOpenReader, color: AppTheme.sky, size: 40),
                      const SizedBox(height: 12),
                      Text("Comic Zone", style: AppTheme.headingL.copyWith(fontFamily: "Orbitron", color: AppTheme.sky)),
                      const SizedBox(height: 8),
                      Text("Read & Find Your Favorite Manga", style: AppTheme.bodyM),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Search Bar
                Container(
                  decoration: AppTheme.inputDecor(),
                  child: TextField(
                    controller: _searchController,
                    style: AppTheme.bodyL.copyWith(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Search Manga / Comic...",
                      hintStyle: AppTheme.bodyM,
                      prefixIcon: const Icon(Icons.search, color: AppTheme.sky),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: AppTheme.sky, size: 20),
                        onPressed: () => _searchManga(_searchController.text),
                      ),
                    ),
                    onSubmitted: (value) => _searchManga(value),
                  ),
                ),

                const SizedBox(height: 20),

                // Recommendation Chips
                Text("Recommendation Search:", style: AppTheme.label.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ["One Piece", "Naruto", "Solo Leveling", "Berserk", "Chainsaw Man"].map((t) => _buildRecChip(t)).toList(),
                  ),
                ),

                const SizedBox(height: 30),

                // Title Section
                Row(
                  children: [
                    Container(
                      height: 24, width: 5,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient(AppTheme.sky),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: AppTheme.softGlow(AppTheme.sky, blur: 8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_headingText, style: AppTheme.headingL),
                    const Spacer(),
                    if (_isSearching)
                      GestureDetector(
                        onTap: _fetchTopManga,
                        child: Text("Reset", style: AppTheme.bodyM.copyWith(color: AppTheme.sky)),
                      ),
                  ],
                ),

                const SizedBox(height: 15),

                // Grid List
                _isLoading
                    ? Container(
                        height: 300,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: AppTheme.sky, strokeWidth: 3),
                            const SizedBox(height: 16),
                            Text("Loading Comics...", style: AppTheme.bodyM),
                          ],
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 14, mainAxisSpacing: 14),
                        itemCount: _comicList.length,
                        itemBuilder: (context, index) => _buildComicCard(_comicList[index]),
                      ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: InkWell(
        onTap: () { _searchController.text = text; _searchManga(text); },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: AppTheme.accentCardDecor(AppTheme.sky),
          child: Text(text, style: AppTheme.bodyM.copyWith(color: AppTheme.textPrimary)),
        ),
      ),
    );
  }

  Widget _buildComicCard(dynamic manga) {
    String imageUrl = manga['images']['jpg']['image_url'] ?? '';
    String title = manga['title'] ?? 'Unknown';
    String score = manga['score'] != null ? manga['score'].toString() : 'N/A';
    String type = manga['type'] ?? 'Manga';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComicDetailPage(mangaData: manga))),
      child: Container(
        decoration: AppTheme.cardDecor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusM)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.bgCard,
                        child: const Icon(Icons.broken_image, color: AppTheme.textMuted, size: 40),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDeep.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.sky.withValues(alpha: 0.25)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.star, color: AppTheme.gold, size: 12),
                          const SizedBox(width: 4),
                          Text(score, style: AppTheme.headingS.copyWith(fontSize: 11)),
                        ]),
                      ),
                    ),
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient(AppTheme.sky),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(type, style: AppTheme.headingS.copyWith(fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.headingS.copyWith(fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.touch_app, color: AppTheme.sky, size: 10),
                    const SizedBox(width: 4),
                    Text("Tap to read", style: AppTheme.caption),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComicDetailPage extends StatelessWidget {
  final Map<String, dynamic> mangaData;

  const ComicDetailPage({super.key, required this.mangaData});

  @override
  Widget build(BuildContext context) {
    String imageUrl = mangaData['images']['jpg']['large_image_url'] ?? mangaData['images']['jpg']['image_url'];
    String title = mangaData['title'] ?? 'Unknown';
    String synopsis = mangaData['synopsis'] ?? 'No synopsis available.';
    String status = mangaData['status'] ?? 'Unknown';
    String chapters = mangaData['chapters'] != null ? mangaData['chapters'].toString() : '?';
    String url = mangaData['url'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0, floating: false, pinned: true,
            backgroundColor: AppTheme.bgDeep,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.bgDeep.withValues(alpha: 0.9), AppTheme.bgDeep],
                        stops: const [0.4, 0.7, 1.0]),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgDeep.withValues(alpha: 0.5), shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.sky.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.headingL.copyWith(fontFamily: "Orbitron")),
                  const SizedBox(height: 16),
                  Row(children: [
                    _buildInfoBadge(Icons.timelapse, status, AppTheme.sky),
                    const SizedBox(width: 12),
                    _buildInfoBadge(Icons.book, "$chapters Ch", AppTheme.teal),
                    const SizedBox(width: 12),
                    _buildInfoBadge(Icons.star, "${mangaData['score'] ?? 'N/A'}", AppTheme.gold),
                  ]),
                  const SizedBox(height: 30),
                  Container(height: 2, decoration: BoxDecoration(gradient: AppTheme.accentGradient(AppTheme.sky), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Icon(Icons.description, color: AppTheme.sky, size: 20),
                    const SizedBox(width: 10),
                    Text("Story / Synopsis", style: AppTheme.headingM),
                  ]),
                  const SizedBox(height: 16),
                  Text(synopsis, style: AppTheme.bodyL.copyWith(height: 1.6), textAlign: TextAlign.justify),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton.icon(
                      style: AppTheme.primaryButton(AppTheme.sky),
                      onPressed: () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch url")));
                        }
                      },
                      icon: const Icon(Icons.open_in_browser, color: Colors.white, size: 22),
                      label: Text("Read More & Details on Web", style: AppTheme.headingS),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: AppTheme.accentCardDecor(color),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(text, style: AppTheme.headingS.copyWith(color: color, fontSize: 12)),
      ]),
    );
  }
}

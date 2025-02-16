import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' as parser;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkPreviewer extends StatefulWidget {
  const LinkPreviewer({Key? key, this.url, this.text}) : super(key: key);
  final String? url;
  final String? text;

  @override
  State<LinkPreviewer> createState() => _LinkPreviewerState();
}

class SpotifyPreviewData {
  final String type;
  final String title;
  final String artist;
  final String imageUrl;
  final String spotifyUrl;

  SpotifyPreviewData({
    required this.type,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.spotifyUrl,
  });
}

class _LinkPreviewerState extends State<LinkPreviewer> {
  bool _isLoading = true;
  String? _title;
  String? _description;
  String? _imageUrl;
  String? _favicon;
  String? _domain;
  SpotifyPreviewData? _spotifyData;

  @override
  void initState() {
    super.initState();
    _fetchLinkPreview();
  }

  String? _getUrl() {
    if (widget.url != null) return widget.url;
    if (widget.text == null) return null;

    // More comprehensive URL regex that matches most common URL formats
    RegExp reg = RegExp(
      r'(https?:\/\/)?([\w\-]+(\.[\w\-]+)+\.?(:\d+)?(\/\S*)?)',
      caseSensitive: false,
    );

    Iterable<Match> matches = reg.allMatches(widget.text!);
    if (matches.isNotEmpty) {
      String url = matches.first.group(0)!;
      // Add https if no protocol is specified
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
      return url;
    }
    return null;
  }

  bool _isSpotifyUrl(String url) {
    return url.toLowerCase().contains('spotify.com');
  }

  Future<SpotifyPreviewData?> _fetchSpotifyData(String url) async {
    try {
      // First try to get metadata using OG tags
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final document = parser.parse(response.body);

      // Extract metadata from OG tags
      final title = document
              .querySelector('meta[property="og:title"]')
              ?.attributes['content'] ??
          '';
      final description = document
              .querySelector('meta[property="og:description"]')
              ?.attributes['content'] ??
          '';
      final image = document
              .querySelector('meta[property="og:image"]')
              ?.attributes['content'] ??
          '';

      // Parse the URL to get the type (track, album, playlist)
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      String type = segments.isNotEmpty ? segments[0] : 'track';

      // Parse artist from description (usually in format "Song · Artist")
      String artist = '';
      if (description.contains('·')) {
        artist = description.split('·')[1].trim();
      }

      // Clean up title (remove " - song by Artist on Spotify" part)
      String cleanTitle = title.split('-').first.trim();

      return SpotifyPreviewData(
        type: type,
        title: cleanTitle,
        artist: artist,
        imageUrl: image,
        spotifyUrl: url,
      );
    } catch (e) {
      debugPrint('Error fetching Spotify data: $e');
      return null;
    }
  }

  Future<void> _fetchLinkPreview() async {
    try {
      final url = _getUrl();
      if (url == null) return;

      final uri = Uri.parse(url);
      _domain = uri.host;

      // Check if it's a Spotify URL
      if (_isSpotifyUrl(url)) {
        final spotifyData = await _fetchSpotifyData(url);
        if (spotifyData != null) {
          setState(() {
            _spotifyData = spotifyData;
            _isLoading = false;
          });
          return;
        }
      }

      // Regular link preview logic
      final file = await DefaultCacheManager().getFileFromCache(url);
      if (file != null) {
        final data = json.decode(await file.file.readAsString());
        _updatePreviewData(data);
        return;
      }

      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('Failed to load preview');

      final document = parser.parse(response.body);

      final data = {
        'title': document.querySelector('title')?.text ?? '',
        'description': document
                .querySelector('meta[name="description"]')
                ?.attributes['content'] ??
            document
                .querySelector('meta[property="og:description"]')
                ?.attributes['content'] ??
            '',
        'image': document
                .querySelector('meta[property="og:image"]')
                ?.attributes['content'] ??
            '',
        'favicon':
            document.querySelector('link[rel="icon"]')?.attributes['href'] ??
                document
                    .querySelector('link[rel="shortcut icon"]')
                    ?.attributes['href'] ??
                '',
      };

      await DefaultCacheManager().putFile(
        url,
        utf8.encode(json.encode(data)),
        fileExtension: 'json',
      );

      _updatePreviewData(data);
    } catch (e) {
      debugPrint('Error fetching link preview: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updatePreviewData(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _title = data['title'];
      _description = data['description'];
      _imageUrl = data['image'];
      _favicon = data['favicon'];
      _isLoading = false;
    });
  }

  Widget _buildSpotifyPreview(SpotifyPreviewData data) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _launchUrl(data.spotifyUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: data.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF1DB954), // Spotify green
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF1DB954),
                        child:
                            const Icon(Icons.music_note, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (data.artist.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      data.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          'https://open.spotify.com/favicon.ico',
                          width: 16,
                          height: 16,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.music_note,
                            size: 16,
                            color: Color(0xFF1DB954),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Spotify ${data.type}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1DB954),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Show Spotify preview if available
    if (_spotifyData != null) {
      return _buildSpotifyPreview(_spotifyData!);
    }

    if (_title == null && _imageUrl == null) {
      return const SizedBox.shrink();
    }

    // Regular link preview
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _launchUrl(_getUrl()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imageUrl != null && _imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: _imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_title != null && _title!.isNotEmpty)
                    Text(
                      _title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (_description != null && _description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_favicon != null && _favicon!.isNotEmpty) ...[
                        CachedNetworkImage(
                          imageUrl: _favicon!,
                          width: 16,
                          height: 16,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.link, size: 16),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _domain ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String? url) async {
    if (url == null) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}

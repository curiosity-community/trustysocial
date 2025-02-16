import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/state/searchState.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:Trusty/widgets/newWidget/emptyList.dart';
import 'package:Trusty/ui/page/professional/widget/professionalCard.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:lottie/lottie.dart';
import 'package:Trusty/services/professional_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:Trusty/helper/utility.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:Trusty/state/authState.dart';
import 'package:path/path.dart' as path;

class BecomeProfessionalModal extends StatefulWidget {
  @override
  _BecomeProfessionalModalState createState() =>
      _BecomeProfessionalModalState();
}

class _BecomeProfessionalModalState extends State<BecomeProfessionalModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? _linkedinUrl;
  String? _cvPath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickCV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _cvPath = result.files.single.path;
      });
    }
  }

  Future<String?> _uploadCVToFirebase(String filePath) async {
    try {
      File file = File(filePath);
      String fileName = path.basename(filePath);
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String uniqueFileName = '${timestamp}_$fileName';

      // Create a reference to the file location in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('professional_applications')
          .child(uniqueFileName);

      // Upload the file
      await storageRef.putFile(file);

      // Get the download URL
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _sendSlackNotification() async {
    const slackWebhookUrl = 'https://hooks.slack.com/services/XXXX/XXXX/XXXX';

    if (_linkedinUrl == null && _cvPath == null) {
      Utility.customSnackBar(
          context, 'Please provide either LinkedIn URL or CV');
      return;
    }

    try {
      // Get user information from AuthState
      final authState = Provider.of<AuthState>(context, listen: false);
      final user = authState.userModel;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Prepare the message
      String message = '*New Professional Application*\n\n';
      message += '*User Information:*\n';
      message += '• User ID: ${user.userId}\n';
      message += '• Username: ${user.userName ?? "Not set"}\n';
      message += '• Display Name: ${user.displayName ?? "Not set"}\n';
      message += '• Email: ${user.email ?? "Not set"}\n\n';

      message += '*Application Details:*\n';
      if (_linkedinUrl != null) {
        message += '• LinkedIn: $_linkedinUrl\n';
      }

      String? cvDownloadUrl;
      if (_cvPath != null) {
        // Show loading indicator while uploading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading CV...')),
        );

        // Upload CV to Firebase Storage
        cvDownloadUrl = await _uploadCVToFirebase(_cvPath!);

        if (cvDownloadUrl != null) {
          message += '• CV: <$cvDownloadUrl|Download CV>\n';
        } else {
          throw Exception('Failed to upload CV');
        }
      }

      // Send POST request to Slack webhook URL
      final response = await http.post(
        Uri.parse(slackWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': message,
          'mrkdwn': true,
        }),
      );

      if (response.statusCode == 200) {
        Utility.customSnackBar(context, 'Application submitted successfully!');
        Navigator.of(context).pop();
      } else {
        throw Exception('Failed to send notification to Slack');
      }
    } catch (e) {
      Utility.customSnackBar(
          context, 'Error submitting application: ${e.toString()}');
    }
  }

  Future<void> _submit() async {
    if (_linkedinUrl == null && _cvPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide either LinkedIn URL or CV')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _sendSlackNotification();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error submitting application: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Become a Professional',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Colors.blue,
                          Colors.purple,
                        ],
                      ).createShader(
                          const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'If you want to be listed here, please connect your LinkedIn profile or upload your CV (PDF accepted)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'LinkedIn Profile URL',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'https://linkedin.com/in/',
                  ),
                  onChanged: (value) => _linkedinUrl = value,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickCV,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                        _cvPath != null ? 'CV Selected' : 'Upload CV (PDF)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Submit Application'),
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

class ProfessionalPage extends StatefulWidget {
  const ProfessionalPage({Key? key}) : super(key: key);

  static Route<T> getRoute<T>() {
    return MaterialPageRoute(
      builder: (_) => Provider(
        create: (_) => SearchState(),
        child: const ProfessionalPage(),
      ),
    );
  }

  @override
  State<ProfessionalPage> createState() => _ProfessionalPageState();
}

class _ProfessionalPageState extends State<ProfessionalPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _fadeAnimationController;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _pulseAnimation;
  String _searchQuery = '';
  bool _isSearching = false;

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  late final ProfessionalService _professionalService;

  Future<void> _initializeAIToken() async {
    try {
      await _remoteConfig.setDefaults({'ai_token': '{"ai_token":""}'});

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(hours: 12),
      ));

      await _remoteConfig.fetchAndActivate();
      var data = _remoteConfig.getString('ai_token');

      if (data.isNotEmpty) {
        final jsonData = jsonDecode(data) as Map;
        final token = jsonData['ai_token'] as String;
        _professionalService = ProfessionalService(token: token);
      } else {
        _professionalService = ProfessionalService(token: '');
      }
    } catch (e) {
      _professionalService = ProfessionalService(token: '');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAIToken();

    // Schedule the reset for after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchState>(context, listen: false).resetAISearchResults();
    });

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Glow animation
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 4),
        weight: 1,
      ),
    ]).animate(_fadeAnimationController);

    // Subtle pulse animation
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.02),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Mock API call
  Future<void> _searchWithAI(String query) async {
    final searchState = Provider.of<SearchState>(context, listen: false);
    searchState.resetAISearchResults(); // Reset before new search
    setState(() => _isSearching = true);

    try {
      final results = await _professionalService.searchProfessionals(query);
      searchState.updateAISearchResults({
        'response': results.message,
        'users': results.professionals,
      });
    } catch (e) {
      // Show error to user
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Replace the existing TextField with this new animated version
  Widget _buildAnimatedSearchField() {
    return AnimatedBuilder(
      animation: _fadeAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: _glowAnimation.value,
                  spreadRadius: _glowAnimation.value / 2,
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: _glowAnimation.value * 2,
                  spreadRadius: _glowAnimation.value / 1.5,
                ),
              ],
            ),
            child: Stack(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'What are you looking for?',
                    contentPadding: const EdgeInsets.only(
                        left: 60), // Make room for the animation
                    suffixIcon: _searchQuery.isNotEmpty
                        ? _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: Consumer<SearchState>(
                                  builder: (context, state, _) {
                                    // Get filtered professionals
                                    final filteredPros = state
                                        .getVerifiedProfessionals()
                                        .where((user) {
                                      final title =
                                          user.userName?.toLowerCase() ?? '';
                                      final name =
                                          user.displayName?.toLowerCase() ?? '';
                                      return title.contains(_searchQuery) ||
                                          name.contains(_searchQuery);
                                    }).toList();

                                    // Show search icon if no matches found
                                    return Icon(
                                      filteredPros.isEmpty
                                          ? Icons.send_sharp
                                          : Icons.clear,
                                      color: Theme.of(context).primaryColor,
                                    );
                                  },
                                ),
                                onPressed: () {
                                  final state = Provider.of<SearchState>(
                                      context,
                                      listen: false);
                                  final filteredPros = state
                                      .getVerifiedProfessionals()
                                      .where((user) {
                                    final title =
                                        user.userName?.toLowerCase() ?? '';
                                    final name =
                                        user.displayName?.toLowerCase() ?? '';
                                    final keywords = user.professionalKeywords
                                            ?.toLowerCase() ??
                                        '';

                                    final keywordList = keywords
                                        .split(',')
                                        .map((k) => k.trim())
                                        .where((k) => k.isNotEmpty)
                                        .toList();

                                    final hasMatchingKeyword = keywordList.any(
                                      (keyword) =>
                                          keyword.contains(_searchQuery),
                                    );

                                    return title.contains(_searchQuery) ||
                                        name.contains(_searchQuery) ||
                                        hasMatchingKeyword;
                                  }).toList();

                                  if (filteredPros.isEmpty) {
                                    // No matches found, trigger AI search
                                    _searchWithAI(_searchQuery);
                                  } else {
                                    // Clear search
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  }
                                },
                              )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  style: const TextStyle(height: 1.0),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });

                    // Reset state when search is cleared
                    if (value.isEmpty) {
                      Provider.of<SearchState>(context, listen: false)
                          .resetAISearchResults();
                    }
                  },
                ),
                Positioned(
                  left: -20,
                  top: -25,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Colors.blue,
                        Colors.purple,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: AnimatedBuilder(
                      animation: _fadeAnimationController,
                      builder: (context, child) {
                        return SizedBox(
                          height: 100,
                          width: 100,
                          child: Lottie.asset(
                            'assets/animations/aianimation.json',
                            controller: _fadeAnimationController,
                            onLoaded: (composition) {
                              _fadeAnimationController
                                ..duration = composition.duration
                                ..forward();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerMessage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 16,
              color: isDark ? Colors.grey[800] : Colors.white,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity * 0.7,
              height: 16,
              color: isDark ? Colors.grey[800] : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // Add this new widget near other widget builders
  Widget _buildAnimatedAIMessage(String message, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.5,
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    message,
                    speed: const Duration(milliseconds: 50),
                    curve: Curves.easeOut,
                  ),
                ],
                totalRepeatCount: 1,
                displayFullTextOnTap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _fadeAnimationController.stop();
        _fadeAnimationController.reset();
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: customTitleText('Professionals'),
          isBackButton: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.add, size: 28),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: BecomeProfessionalModal(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(12),
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    _fadeAnimationController.forward();
                  } else {
                    _fadeAnimationController.stop();
                    _fadeAnimationController.reset();
                  }
                },
                child: _buildAnimatedSearchField(),
              ),
            ),
            // Professional List
            Expanded(
              child: Consumer<SearchState>(
                builder: (context, state, child) {
                  // First try to find from verified professionals
                  var professionals = state.getVerifiedProfessionals();
                  if (_searchQuery.isNotEmpty) {
                    professionals = professionals.where((user) {
                      final title = user.userName?.toLowerCase() ?? '';
                      final name = user.displayName?.toLowerCase() ?? '';
                      final keywords =
                          user.professionalKeywords?.toLowerCase() ?? '';

                      // Split keywords by comma and trim whitespace
                      final keywordList = keywords
                          .split(',')
                          .map((k) => k.trim())
                          .where((k) => k.isNotEmpty)
                          .toList();

                      // Check if any keyword contains the search query
                      final hasMatchingKeyword = keywordList.any(
                        (keyword) => keyword.contains(_searchQuery),
                      );

                      return title.contains(_searchQuery) ||
                          name.contains(_searchQuery) ||
                          hasMatchingKeyword;
                    }).toList();
                  }

                  // If no results in verified professionals, check AI results
                  if (professionals.isEmpty && _searchQuery.isNotEmpty) {
                    final aiResults = state.getProfessionalUsers();
                    final hasAIResponse = state.aiResponseMessage != null;

                    // Show shimmer while searching
                    if (_isSearching) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerMessage(),
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount:
                                  6, // Show 6 shimmer cards while loading
                              itemBuilder: (context, index) =>
                                  _buildShimmerCard(),
                            ),
                          ),
                        ],
                      );
                    }

                    // Show AI response if available, regardless of results
                    if (hasAIResponse) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated AI Response Message
                          _buildAnimatedAIMessage(
                              state.aiResponseMessage ?? '', context),
                          // AI Results Grid (if any)
                          Expanded(
                            child: aiResults.isNotEmpty
                                ? GridView.builder(
                                    padding: const EdgeInsets.all(8),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.8,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: aiResults.length,
                                    itemBuilder: (context, index) {
                                      final mockPro = aiResults[index];
                                      return ProfessionalCard(
                                        mockProfessional: mockPro,
                                        isAIResult: true,
                                      );
                                    },
                                  )
                                : const Center(
                                    child: NotifyText(
                                      title: 'No professionals found',
                                      subTitle: 'Try different search terms',
                                    ),
                                  ),
                          ),
                        ],
                      );
                    }
                  }

                  // Show empty state or professionals list
                  return professionals.isEmpty
                      ? const Center(
                          child: NotifyText(
                            title: 'No professionals found',
                            subTitle: 'Try AI search for more results',
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: professionals.length,
                          itemBuilder: (context, index) {
                            return ProfessionalCard(user: professionals[index]);
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

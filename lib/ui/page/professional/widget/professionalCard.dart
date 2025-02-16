import 'package:flutter/material.dart';
import 'package:Trusty/model/user.dart';
import 'package:Trusty/ui/page/profile/profilePage.dart';
import 'package:Trusty/widgets/cache_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:Trusty/services/professional_service.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/state/searchState.dart';

class ProfessionalCard extends StatelessWidget {
  final dynamic user;
  final MockProfessionalModel? mockProfessional;
  final bool isAIResult;

  const ProfessionalCard({
    Key? key,
    this.user,
    this.mockProfessional,
    this.isAIResult = false,
  })  : assert(user != null || mockProfessional != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = isAIResult ? mockProfessional!.userId : user.userId;

    final realUser = Provider.of<SearchState>(context)
        .userlist
        ?.firstWhere((u) => u.userId == userId, orElse: () => user);

    // Tüm bilgileri realUser'dan alıyoruz
    final name = realUser?.userName ?? user.userName;
    final displayName = realUser?.displayName ?? user.displayName;
    final rating = realUser?.rating ?? user.rating ?? 0.0;
    final profilePic = realUser?.profilePic ?? user.profilePic;
    // Specialty bilgisi AI'dan geliyor olabilir
    final specialty = isAIResult ? (mockProfessional!.specialty ?? '') : '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        ProfilePage.getRoute(profileId: userId),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (profilePic != null)
              CacheImage(
                path: profilePic,
                fit: BoxFit.cover,
              ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Specialty
                  if (isAIResult && specialty.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  // Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      RatingBar.builder(
                        initialRating: rating,
                        minRating: 0,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 16,
                        ignoreGestures: true,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (_) {},
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
}

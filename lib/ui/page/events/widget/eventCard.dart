import 'package:flutter/material.dart';
import 'package:Trusty/model/eventModel.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/ui/page/events/eventDetailPage.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/state/eventState.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventCard extends StatelessWidget {
  final EventModel event;

  const EventCard({
    Key? key,
    required this.event,
  }) : super(key: key);

  Widget _getEventStatusIcon() {
    final now = DateTime.now();
    final start = DateTime.parse(event.startAt!);
    final end = DateTime.parse(event.endAt!);

    if (now.isBefore(start)) {
      return const Icon(
        AppIcon.dot,
        color: Colors.white,
        size: 20,
      );
    } else if (now.isAfter(start) && now.isBefore(end)) {
      return const Icon(
        AppIcon.dot,
        color: Colors.green,
        size: 20,
      );
    } else {
      return const Icon(
        AppIcon.dot,
        color: Colors.red,
        size: 20,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthState>(context).userId;
    final hasJoined = event.hasUserJoined(userId);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) => EventDetailPage(
                event: event,
                scrollController: controller,
              ),
            ),
          );
        },
        child: Container(
          height: 200,
          child: Stack(
            children: [
              // Background Image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      event.image!,
                      errorListener: (error) =>
                          print('Error loading image: ${event.image}'),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _getEventStatusIcon(),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            event.title!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white, // Make title invisible
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.9),
                                  offset: Offset(0, 0),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.white),
                            Text(
                              '${event.attendeesCount ?? 0}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Text(
                          '${Utility.getEventDateTime(event.startAt!)}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    if (hasJoined)
                      _JoinButton(
                        event: event,
                        hasJoined: hasJoined,
                        onJoin: () =>
                            Provider.of<EventState>(context, listen: false)
                                .joinEvent(event.key!, userId),
                      ),
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

class _JoinButton extends StatefulWidget {
  final EventModel event;
  final bool hasJoined;
  final Future<void> Function() onJoin;

  const _JoinButton({
    required this.event,
    required this.hasJoined,
    required this.onJoin,
  });

  @override
  _JoinButtonState createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: widget.hasJoined ? null : _handleJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.hasJoined ? Colors.green : null,
          disabledBackgroundColor: Colors.green,
        ),
        child: widget.hasJoined
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Joined', style: TextStyle(color: Colors.white)),
                ],
              )
            : _isJoining
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text('Join Event'),
      ),
    );
  }

  Future<void> _handleJoin() async {
    if (_isJoining) return;

    setState(() => _isJoining = true);
    await _controller.forward();

    await widget.onJoin();

    await _controller.reverse();
    setState(() => _isJoining = false);
  }
}

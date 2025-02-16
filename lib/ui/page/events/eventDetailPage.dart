import 'package:flutter/material.dart';
import 'package:Trusty/model/eventModel.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/state/eventState.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventDetailPage extends StatelessWidget {
  final EventModel event;
  final ScrollController scrollController;

  const EventDetailPage({
    Key? key,
    required this.event,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _buildHeader(context),
            _buildEventInfo(context),
            _buildJoinButton(context),
            SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height * 0.3, // Reduced height for modal
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            event.image!,
            errorListener: (error) =>
                print('Error loading image: ${event.image}'),
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 10),
          _buildEventStatus(),
          SizedBox(height: 20),
          Text(
            event.description!,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.calendar_today),
              SizedBox(width: 10),
              Text(
                '${Utility.getEventDateTime(event.startAt!)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time),
              SizedBox(width: 10),
              Text(
                '${Utility.getEventTime(event.startAt!)} - ${Utility.getEventTime(event.endAt!)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.people),
              SizedBox(width: 10),
              Text(
                '${event.attendeesCount ?? 0} Attendees',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventStatus() {
    final now = DateTime.now();
    final start = DateTime.parse(event.startAt!);
    final end = DateTime.parse(event.endAt!);

    if (now.isBefore(start)) {
      return _buildStatusRow(
        color: Colors.white,
        text: "Upcoming Event",
      );
    } else if (now.isAfter(start) && now.isBefore(end)) {
      return _buildStatusRow(
        color: Colors.green,
        text: "Live Now",
      );
    } else {
      return _buildStatusRow(
        color: Colors.red,
        text: "Event Ended",
      );
    }
  }

  Widget _buildStatusRow({required Color color, required String text}) {
    return Row(
      children: [
        Icon(AppIcon.dot, color: color, size: 20),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton(BuildContext context) {
    final userId = Provider.of<AuthState>(context, listen: false).userId;
    return _JoinButton(event: event, userId: userId);
  }
}

class _JoinButton extends StatefulWidget {
  final EventModel event;
  final String userId;

  const _JoinButton({
    required this.event,
    required this.userId,
  });

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isJoining = false;
  bool _hasJoinedLocally = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildJoinButton(context);
  }

  Widget _buildJoinButton(BuildContext context) {
    return Consumer<EventState>(
      builder: (context, state, _) {
        final hasJoined = _hasJoinedLocally ||
            (widget.event.attendeesList?.contains(widget.userId) ?? false);
        final isEventPassed = widget.event.endAt != null &&
            DateTime.now().isAfter(DateTime.parse(widget.event.endAt!));

        return Padding(
          padding: EdgeInsets.all(20),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasJoined ? Colors.green : Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  disabledBackgroundColor: Colors.green,
                  disabledForegroundColor: Colors.white,
                ),
                onPressed: (hasJoined || isEventPassed || _isJoining)
                    ? null
                    : () async {
                        setState(() => _isJoining = true);
                        _controller
                            .forward()
                            .then((_) => _controller.reverse());

                        await state.joinEvent(widget.event.key!, widget.userId);

                        if (mounted) {
                          setState(() {
                            _isJoining = false;
                            _hasJoinedLocally = true;
                          });
                        }
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasJoined) ...[
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                    ],
                    if (_isJoining)
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Text(
                        isEventPassed
                            ? 'Event Ended'
                            : hasJoined
                                ? 'Successfully Joined!'
                                : 'Join Event',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

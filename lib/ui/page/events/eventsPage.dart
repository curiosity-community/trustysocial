import 'package:flutter/material.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/state/eventState.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'widget/eventCard.dart';
import 'widget/createEventModal.dart';
import 'package:Trusty/state/authState.dart';

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<EventState>(context, listen: false).getEvents();
    });
  }

  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);

    return Scaffold(
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText('Events'),
      ),
      floatingActionButton: authState.userModel?.isOrganizer == true
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: true,
                  enableDrag: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CreateEventModal(),
                );
              },
              child: Icon(
                Icons.add,
                color: Theme.of(context).primaryColor,
              ),
            )
          : null,
      body: Consumer<EventState>(
        builder: (context, state, child) {
          if (state.isBusy) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.eventList == null || state.eventList!.isEmpty) {
            return const Center(child: Text('No events found'));
          }

          return ListView.builder(
            itemCount: state.eventList!.length,
            itemBuilder: (context, index) {
              final event = state.eventList![index];
              return EventCard(event: event);
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/state/help_center_state.dart';
import 'package:Trusty/widgets/customAppBar.dart';
import 'package:Trusty/widgets/customWidgets.dart';

class HelpCenterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HelpCenterState(),
      child: _HelpCenterPageContent(),
    );
  }
}

class _HelpCenterPageContent extends StatefulWidget {
  @override
  _HelpCenterPageContentState createState() => _HelpCenterPageContentState();
}

class _HelpCenterPageContentState extends State<_HelpCenterPageContent> {
  String? selectedTopic;
  final TextEditingController _messageController = TextEditingController();
  final int maxLength = 500;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<HelpCenterState>(context);

    return Scaffold(
      appBar: CustomAppBar(
        isBackButton: true,
        title: customTitleText(
          'Premium Support',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 150,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 50),
                // Konu Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedTopic,
                  hint: const Text('Select a topic'),
                  items: state.topics.map((String topic) {
                    return DropdownMenuItem<String>(
                      value: topic,
                      child: Text(topic),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedTopic = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Mesaj TextField
                TextField(
                  controller: _messageController,
                  maxLength: maxLength,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Your message',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (text) {
                    if (text.length > maxLength) {
                      _messageController.text = text.substring(0, maxLength);
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: maxLength),
                      );
                    }
                    setState(() {});
                  },
                ),

                const SizedBox(height: 20),

                // Gönder Butonu
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  width: double.infinity,
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    color: Colors.blueAccent,
                    disabledColor: Colors.grey,
                    onPressed: state.isLoading ||
                            selectedTopic == null ||
                            _messageController.text.isEmpty ||
                            state.isInCooldown
                        ? null
                        : () async {
                            await state.sendToSlack(
                                selectedTopic!, _messageController.text);
                            if (!state.errorMessage.isNotEmpty) {
                              _messageController.clear();
                              setState(() {
                                selectedTopic = null;
                              });
                            }
                          },
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            state.isInCooldown || state.messageSent
                                ? 'Your message has been sent'
                                : 'Send',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                if (state.errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      state.errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

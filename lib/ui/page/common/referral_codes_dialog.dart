import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/helper/utility.dart';

class ReferralCodesDialog extends StatelessWidget {
  final VoidCallback onClose;

  const ReferralCodesDialog({Key? key, required this.onClose})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 80,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/signup_background.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment(0, 0.8),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    'Your Invitation Codes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.4,
            padding: const EdgeInsets.all(16),
            child: Consumer<AuthState>(
              builder: (context, authState, child) => authState
                      .referralCodes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Invitation Codes Available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Invitation codes are distributed periodically to active users. When you receive your codes, they will appear here for you to share with others.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: authState.referralCodes.length,
                      itemBuilder: (context, index) {
                        final code = authState.referralCodes[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              code.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '${Utility.getPostTime2(code.createdAt)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: code.code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

void showReferralCodesDialog(BuildContext context) {
  context.read<AuthState>().getLatestReferralCodes();
  showDialog(
    context: context,
    builder: (context) => ReferralCodesDialog(
      onClose: () => Navigator.pop(context),
    ),
  );
}

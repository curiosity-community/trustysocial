import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Trusty/helper/customRoute.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/ui/page/profile/widgets/circular_image.dart';
import 'package:Trusty/widgets/cache_image.dart';
import 'package:Trusty/widgets/customFlatButton.dart';
import 'package:Trusty/widgets/customWidgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);
  static MaterialPageRoute<T> getRoute<T>() {
    return CustomRoute<T>(
        builder: (BuildContext context) => const EditProfilePage());
  }

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _image;
  File? _banner;
  late TextEditingController _name;
  late TextEditingController _bio;
  late TextEditingController _location;
  late TextEditingController _dob;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? dob;
  @override
  void initState() {
    _name = TextEditingController();
    _bio = TextEditingController();
    _location = TextEditingController();
    _dob = TextEditingController();
    AuthState state = Provider.of<AuthState>(context, listen: false);
    _name.text = state.userModel?.displayName ?? '';
    _bio.text = state.userModel?.bio ?? '';
    _location.text = state.userModel?.location ?? '';
    _dob.text = Utility.getDob(state.userModel?.dob);
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _location.dispose();
    _dob.dispose();
    super.dispose();
  }

  Widget _body() {
    var authState = Provider.of<AuthState>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 180,
          child: Stack(
            children: <Widget>[
              _bannerImage(authState),
              Align(
                alignment: Alignment.bottomLeft,
                child: _userImage(authState),
              ),
            ],
          ),
        ),
        _entry('Name', controller: _name),
        _entry('Bio', controller: _bio),
        _entry('Location', controller: _location),
        InkWell(
          onTap: showCalender,
          child: _entry('Date of birth', enabled: false, controller: _dob),
        )
      ],
    );
  }

  Widget _userImage(AuthState authState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      height: 90,
      width: 90,
      decoration: BoxDecoration(
        border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor, width: 5),
        shape: BoxShape.circle,
        image: DecorationImage(
            image: customAdvanceNetworkImage(authState.userModel!.profilePic),
            fit: BoxFit.cover),
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundImage: (_image != null
                ? FileImage(_image!)
                : customAdvanceNetworkImage(authState.userModel!.profilePic))
            as ImageProvider,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black38,
          ),
          child: Center(
            child: IconButton(
              onPressed: uploadImage,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerImage(AuthState authState) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        image: authState.userModel!.bannerImage == null
            ? null
            : DecorationImage(
                image:
                    customAdvanceNetworkImage(authState.userModel!.bannerImage),
                fit: BoxFit.cover, // Ensures the image covers without shrinking
              ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black45,
        ),
        child: Stack(
          children: [
            _banner != null
                ? Image.file(
                    _banner!,
                    fit: BoxFit.cover, // Changed to BoxFit.cover
                    width: MediaQuery.of(context).size.width,
                  )
                : CacheImage(
                    path: authState.userModel!.bannerImage ??
                        'https://curiositys3.s3.amazonaws.com/media/images/carousel2.jpg',
                    fit: BoxFit.cover, // Changed to BoxFit.cover
                  ),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.black38,
                ),
                child: IconButton(
                  onPressed: uploadBanner,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(String title,
      {required TextEditingController controller,
      int maxLine = 1,
      bool enabled = true}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          customText(title, style: const TextStyle()),
          TextField(
            enabled: enabled,
            controller: controller,
            maxLines: maxLine,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
              filled: false,
              fillColor: Colors.transparent,
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          )
        ],
      ),
    );
  }

  void showCalender() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2019, DateTime.now().month, DateTime.now().day),
      firstDate: DateTime(1950, DateTime.now().month, DateTime.now().day + 3),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    setState(() {
      if (picked != null) {
        dob = picked.toString();
        _dob.text = Utility.getDob(dob);
      }
    });
  }

  void _submitButton() {
    if (_name.text.length > 27) {
      Utility.customSnackBar(context, 'Name length cannot exceed 27 character');
      return;
    }
    var state = Provider.of<AuthState>(context, listen: false);
    var model = state.userModel!.copyWith(
      key: state.userModel!.userId,
      displayName: state.userModel!.displayName,
      bio: state.userModel!.bio,
      contact: state.userModel!.contact,
      dob: state.userModel!.dob,
      email: state.userModel!.email,
      location: state.userModel!.location,
      profilePic: state.userModel!.profilePic,
      userId: state.userModel!.userId,
      bannerImage: state.userModel!.bannerImage,
    );
    if (_name.text.isNotEmpty) {
      model.displayName = _name.text;
    }
    if (_bio.text.isNotEmpty) {
      model.bio = _bio.text;
    }
    if (_location.text.isNotEmpty) {
      model.location = _location.text;
    }
    if (dob != null) {
      model.dob = dob!;
    }

    state.updateUserProfile(model, image: _image, bannerImage: _banner);
    Navigator.of(context).pop();
  }

  void uploadImage() {
    openImagePicker(context, (file) {
      setState(() {
        _image = file;
      });
    });
  }

  void uploadBanner() {
    openImagePicker(context, (file) {
      setState(() {
        _banner = file;
      });
    });
  }

  void getImage(BuildContext context, ImageSource source,
      Function(File) onImageSelected) async {
    try {
      // Close the bottom sheet first to prevent UI freeze
      Navigator.pop(context);

      final XFile? file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50,
      );

      if (file != null) {
        onImageSelected(File(file.path));
      }
    } catch (e) {
      print("Image picker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void openImagePicker(BuildContext context, Function(File) onImageSelected) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Text(
                  'Select Image From',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                // Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Camera Option
                    _buildPickerOption(
                      context,
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () => getImage(
                          context, ImageSource.camera, onImageSelected),
                    ),
                    // Gallery Option
                    _buildPickerOption(
                      context,
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => getImage(
                          context, ImageSource.gallery, onImageSelected),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildPickerOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: customTitleText(
          'Edit Profile',
        ),
        actions: <Widget>[
          InkWell(
            onTap: _submitButton,
            child: const Center(
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: _body(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Trusty/state/eventState.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CreateEventModal extends StatefulWidget {
  @override
  _CreateEventModalState createState() => _CreateEventModalState();
}

class _CreateEventModalState extends State<CreateEventModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  File? _imageFile;
  String? _uploadedImageUrl;

  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });

      // Upload to Firebase Storage
      try {
        setState(() => _isLoading = true);
        final storageRef = FirebaseStorage.instance.ref();
        final eventImageRef = storageRef
            .child('events/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await eventImageRef.putFile(_imageFile!);
        _uploadedImageUrl = await eventImageRef.getDownloadURL();

        setState(() => _isLoading = false);
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _startTime != null &&
        _endDate != null &&
        _endTime != null &&
        _uploadedImageUrl != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final startDateTime = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
          _startTime!.hour,
          _startTime!.minute,
        );

        final endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );

        final eventData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'image': _uploadedImageUrl,
          'startAt': startDateTime.toUtc().toIso8601String(),
          'endAt': endDateTime.toUtc().toIso8601String(),
          'attendeesList': [],
          'attendeesCount': 0,
        };

        await Provider.of<EventState>(context, listen: false)
            .createEvent(eventData);

        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });

        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Create New Event',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          onTap: _isLoading ? null : _pickImage,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _imageFile != null
                                      ? Icons.check_circle
                                      : Icons.add_photo_alternate,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _imageFile != null
                                      ? 'Image Added'
                                      : 'Add Image',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_imageFile != null) ...[
                      SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFile!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a title'
                          : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a description'
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Event Duration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() => _startDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startDate == null
                                              ? 'Start Date'
                                              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                          style: TextStyle(
                                            color: _startDate == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                        Icon(Icons.calendar_today, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() => _startTime = time);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startTime == null
                                              ? 'Start Time'
                                              : _startTime!.format(context),
                                          style: TextStyle(
                                            color: _startTime == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                        Icon(Icons.access_time, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate ?? DateTime.now(),
                                      firstDate: _startDate ?? DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() => _endDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _endDate == null
                                              ? 'End Date'
                                              : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                          style: TextStyle(
                                            color: _endDate == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                        Icon(Icons.calendar_today, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() => _endTime = time);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _endTime == null
                                              ? 'End Time'
                                              : _endTime!.format(context),
                                          style: TextStyle(
                                            color: _endTime == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                        Icon(Icons.access_time, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading || _isSuccess ? null : _createEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSuccess
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : _isSuccess
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Created Successfully',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Create Event',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

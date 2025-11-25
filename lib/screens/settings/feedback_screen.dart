import 'dart:io';
import 'package:flutter/material.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:image_picker/image_picker.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  String? _attachmentPath;
  bool _isSending = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _attachmentPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final Email email = Email(
      body: _feedbackController.text,
      subject: 'UpNow Feedback',
      recipients: ['appweaverlabs@gmail.com'],
      attachmentPaths: _attachmentPath != null ? [_attachmentPath!] : [],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening email client...')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending feedback: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Send Feedback', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: AppTheme.darkSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _sendFeedback,
            child: _isSending
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Send',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Text(
              'We would love to hear your thoughts, concerns, or problems with anything so we can improve!',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            SizedBox(height: 24.h),
            TextField(
              controller: _feedbackController,
              maxLines: 8,
              style:
                  TextStyle(color: AppTheme.primaryTextColor, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'Describe your experience or suggestion...',
                hintStyle: TextStyle(
                    color: AppTheme.secondaryTextColor.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            _buildSettingGroup(
              children: [
                _buildSettingTile(
                  icon: Icons.camera_alt_outlined,
                  title: _attachmentPath != null
                      ? 'Change Screenshot'
                      : 'Attach Screenshot',
                  trailing: _attachmentPath != null
                      ? Icon(Icons.check_circle,
                          color: AppTheme.primaryColor, size: 20.sp)
                      : null,
                  onTap: _pickImage,
                ),
                if (_attachmentPath != null) ...[
                  Container(
                    height: 1.h,
                    color: AppTheme.darkBackground.withOpacity(0.5),
                  ),
                  _buildSettingTile(
                    icon: Icons.delete_outline,
                    title: 'Remove Screenshot',
                    isLast: true,
                    onTap: () {
                      setState(() {
                        _attachmentPath = null;
                      });
                    },
                  ),
                ],
              ],
            ),
            if (_attachmentPath != null) ...[
              SizedBox(height: 16.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(
                  File(_attachmentPath!),
                  height: 200.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? BorderRadius.vertical(bottom: Radius.circular(16.r))
            : BorderRadius.zero,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: AppTheme.darkBackground.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: AppTheme.primaryColor.withOpacity(0.8), size: 22.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppTheme.primaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null && onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14.sp,
                  color: AppTheme.secondaryTextColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

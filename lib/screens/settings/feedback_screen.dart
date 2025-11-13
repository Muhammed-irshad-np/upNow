import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:upnow/utils/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> _attachments = [];
  bool _isSending = false;

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
            child: Text(
              'Send',
              style: TextStyle(
                color: _isSending ? AppTheme.secondaryTextColor : AppTheme.primaryColor,
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
              style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'Describe your experience or suggestion...',
                hintStyle: TextStyle(color: AppTheme.secondaryTextColor.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_attachments.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _attachments
                    .map(
                      (path) => Chip(
                        label: Text(
                          path.split('/').last,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                        backgroundColor: AppTheme.darkSurface,
                        deleteIcon: Icon(
                          Icons.close,
                          size: 16.sp,
                          color: AppTheme.secondaryTextColor,
                        ),
                        onDeleted: () => _removeAttachment(path),
                      ),
                    )
                    .toList(),
              ),
            ],
            SizedBox(height: 24.h),
            _buildSettingGroup(
              children: [
                _buildSettingTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Attach Screenshot',
                  trailing: _attachments.isEmpty
                      ? null
                      : Text(
                          '${_attachments.length} attached',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                  isLast: true,
                  onTap: _isSending ? null : _pickScreenshot,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _pickScreenshot() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }
      setState(() {
        if (!_attachments.contains(image.path)) {
          _attachments.add(image.path);
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screenshot attached.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access your gallery.')),
      );
    }
  }

  void _removeAttachment(String path) {
    setState(() {
      _attachments.remove(path);
    });
  }

  Future<void> _sendFeedback() async {
    final String message = _feedbackController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your feedback before sending.')),
      );
      return;
    }

    final email = Email(
      body: message,
      subject: 'UpNow Feedback',
      recipients: const ['appweaverlabs@gmail.com'],
      attachmentPaths: _attachments,
      isHTML: false,
    );

    setState(() {
      _isSending = true;
    });

    try {
      await FlutterEmailSender.send(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening your mail app...')),
      );
    } catch (error) {
      if (!mounted) return;
      final fallbackHandled = await _handleEmailSendError(error, message);
      if (!fallbackHandled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open your mail app right now.')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
    }
  }

  // Duplicating helper methods for this self-contained screen
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
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor.withOpacity(0.8), size: 22.sp),
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

  Future<bool> _handleEmailSendError(Object error, String body) async {
    if (error is PlatformException && error.code == 'not_available') {
      final Uri mailUri = Uri(
        scheme: 'mailto',
        path: 'appweaverlabs@gmail.com',
        queryParameters: {
          'subject': 'UpNow Feedback',
          'body': body,
        },
      );

      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri);
        if (!mounted) return true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No email app detected. Opened default mail composer; attachments were not added.',
            ),
          ),
        );
        return true;
      } else {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app detected. Please install one to send feedback.'),
          ),
        );
        return true;
      }
    }
    return false;
  }
}
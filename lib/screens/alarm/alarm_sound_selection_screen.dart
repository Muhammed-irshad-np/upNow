import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/alarm_form_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/utils/global_error_handler.dart';
import 'package:path/path.dart' as p;

class AlarmSoundSelectionScreen extends StatefulWidget {
  const AlarmSoundSelectionScreen({Key? key}) : super(key: key);

  @override
  State<AlarmSoundSelectionScreen> createState() =>
      _AlarmSoundSelectionScreenState();
}

class _AlarmSoundSelectionScreenState extends State<AlarmSoundSelectionScreen> {
  String? _previewingSoundPath;
  AlarmFormProvider? _formProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to provider while context is still valid
    _formProvider = Provider.of<AlarmFormProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // Stop any playing preview using the saved reference
    _formProvider?.stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmFormProvider>(
      builder: (context, form, _) {
        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          appBar: AppBar(
            title: const Text('Select Sound'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: form.availableSounds.length,
            itemBuilder: (context, index) {
              final soundPath = form.availableSounds[index];
              final fileName = p.basename(soundPath);
              final isSelected = form.selectedSoundPath == soundPath;
              final isPreviewing = _previewingSoundPath == soundPath;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: AppTheme.darkCardColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: isSelected
                      ? Border.all(color: AppTheme.primaryColor, width: 2.w)
                      : null,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  leading: GestureDetector(
                    onTap: () async {
                      try {
                        if (isPreviewing) {
                          await form.stopPreview();
                          if (mounted) {
                            setState(() {
                              _previewingSoundPath = null;
                            });
                          }
                        } else {
                          // Stop any currently playing sound
                          await form.stopPreview();
                          if (mounted) {
                            setState(() {
                              _previewingSoundPath = soundPath;
                            });
                          }
                          await form.previewSound(soundPath);
                        }
                      } catch (e, stackTrace) {
                        GlobalErrorHandler.onException(e, stackTrace);
                        if (mounted) {
                          setState(() {
                            _previewingSoundPath = null;
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPreviewing
                            ? AppTheme.primaryColor
                            : AppTheme.darkBackground.withOpacity(0.5),
                        border: Border.all(
                          color: isPreviewing
                              ? AppTheme.primaryColor
                              : AppTheme.secondaryTextColor,
                        ),
                      ),
                      child: Icon(
                        isPreviewing ? Icons.stop : Icons.play_arrow,
                        color: isPreviewing
                            ? Colors.white
                            : AppTheme.secondaryTextColor,
                        size: 20.sp,
                      ),
                    ),
                  ),
                  title: Text(
                    fileName,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16.sp,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                          size: 24.sp,
                        )
                      : null,
                  onTap: () async {
                    // Stop preview first to ensure it doesn't keep playing
                    await form.stopPreview();

                    // Update selection and go back to create alarm screen
                    form.setSelectedSoundPath(soundPath);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../services/email_service.dart';
import '../services/template_service.dart';
import '../models/email_template.dart';
import '../screens/payment.dart';

class EmailComposerController extends GetxController {
  final toController = TextEditingController();
  final subjectController = TextEditingController();
  final bodyController = TextEditingController();
  final templateNameController = TextEditingController();
  final categoryController = TextEditingController();
  final tagsController = TextEditingController();
  var count = 0;

  final int maxDailyEmails = 2;
  var attachments = <PlatformFile>[].obs;
  Rx<EmailTemplate?> selectedTemplate = Rx<EmailTemplate?>(null);
  late final TemplateService templateService;
  RxList<EmailTemplate> mySavedTemplatesList = <EmailTemplate>[].obs;

  @override
  void onInit() {
    super.onInit();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAllNamed('/login'); // 🔒 Ensure user is authenticated
      return;
    }

    templateService = TemplateService(userId: user.uid); // ✅ Use UID instead of email
    initInitials();

    final initialEmail = Get.arguments?['initialEmail'] as String?;
    if (initialEmail != null) {
      toController.text = initialEmail;
    }
  }

  Future<void> initInitials() async {
    await fetchTemplates();
    final initialTemplate = Get.arguments?['initialTemplate'] as Map<String, dynamic>?;
    if (initialTemplate != null) {
      final initTemp = EmailTemplate.fromJson(initialTemplate);
      subjectController.text = initTemp.subject;
      bodyController.text = initTemp.body;
      attachments.value = initTemp.attachmentPaths
          .map((val) => PlatformFile(name: val.split('/').last, size: 0, path: val))
          .toList();
    }
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      attachments.addAll(result.files);
    }
  }

  void removeAttachment(PlatformFile file) {
    attachments.remove(file);
  }

  Future<void> saveAsTemplate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Not Logged In', 'Please login to save templates.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final attachmentPaths = attachments
        .map((file) => file.path!)
        .where((path) => path.isNotEmpty)
        .toList();

    final template = EmailTemplate(
      id: const Uuid().v4(),
      name: templateNameController.text,
      subject: subjectController.text,
      body: bodyController.text,
      attachmentPaths: attachmentPaths,
      tags: tagsController.text.split(',').map((e) => e.trim()).toList(),
      category: categoryController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await templateService.saveTemplate(template);
    Get.back();
    Get.snackbar('Success', 'Template saved successfully',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  Future<bool> canSendEmailToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('email_last_date') ?? '';
    int count = prefs.getInt('email_send_count') ?? 0;
    final unlockDate = prefs.getString('email_unlock_date') ?? '';
    final isUnlocked = prefs.getBool('email_unlocked') ?? false;

    if (isUnlocked && unlockDate == today) return true;

    if (lastDate == today) {
      if (count >= maxDailyEmails) return false;
      await prefs.setInt('email_send_count', count + 1);
    } else {
      await prefs.setString('email_last_date', today);
      await prefs.setInt('email_send_count', 1);
    }
    return true;
  }

  Future<void> _unlockEmailLimitForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('email_unlock_date', today);
    await prefs.setBool('email_unlocked', true);
  }

  Future<void> sendEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Not Logged In', 'Please login to send emails.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final canSend = await canSendEmailToday();

    if (!canSend) {
      final result = await Get.to(() => RazorpayPaymentPage());
      if (result == true) {
        await _unlockEmailLimitForToday();
        await sendEmail(); // Retry
      } else {
        Get.snackbar('Limit Reached',
            'You cannot send more than 100 emails per day without payment.',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
      return;
    }

    try {
      final recipients = toController.text.split(',').map((e) => e.trim()).toList();

      await EmailService().sendEmail(
        to: recipients.join(','),
        subject: subjectController.text,
        body: bodyController.text,
        attachments: attachments,
      );

      Get.snackbar('Success', 'Email sent successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to send email: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> fetchTemplates() async {
    mySavedTemplatesList.value = await templateService.getAllTemplates();
  }
}

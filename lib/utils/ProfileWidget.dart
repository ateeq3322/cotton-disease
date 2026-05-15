import 'dart:convert';
import 'dart:io';
import 'package:cotton_disease/utils/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../Provider/ThemeProvider.dart';
import '../Services/ProfilePreference.dart';
import 'constants/colors.dart';
import 'constants/fonts.dart';

class ProfileCard extends StatefulWidget {
  const ProfileCard({super.key});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  String? userName;
  String? userPhoto;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  /// Load from SharedPref → Firebase → Default
  void loadProfile() async {
    final savedName = await ProfilePreferences.getName();
    final savedPhoto = await ProfilePreferences.getPhoto();

    setState(() {
      userName = savedName ?? currentUser?.displayName ?? "Unknown";
      userPhoto = savedPhoto ?? currentUser?.photoURL;
    });
  }

  /// 📌 Edit Name Dialog
  void editNameDialog(bool isDark) {
    final controller = TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? carbonBlack : white,
        title: heading(text: "Edit Name", color: isDark ? white : carbonBlack),
        content: ReusableTextField(
          labelText: 'Enter Your Name',
          controller: controller,
        ),
        actions: [
          TextButton(
            child: cardSubtitle(text: 'Cancel', color: white),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: bodyText(text: 'Save', color: brandGreen),
            onPressed: () {
              ProfilePreferences.saveName(controller.text);
              setState(() => userName = controller.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// 📌 BottomSheet for Image Picker
  void showImagePickerSheet(bool isDark, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? carbonBlack : white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Container(
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () => pickImage(ImageSource.camera),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.camera_alt, color: mediumGray),
                    const SizedBox(width: 4),
                    bodyText(text: 'Camera', color: color),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.shade400,
              ),

              InkWell(
                onTap: () => pickImage(ImageSource.gallery),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.photo_library_rounded, color: mediumGray),
                    const SizedBox(width: 4),
                    bodyText(text: 'Gallery', color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void showFullImagePreview(ImageProvider image) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // 🔹 Full Screen Image
              InteractiveViewer(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // 🔹 Close Button
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 📌 Pick Image from Camera or Gallery
  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source);
    if (file == null) return;

    final bytes = await File(file.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    await ProfilePreferences.savePhoto(base64Image);

    setState(() => userPhoto = base64Image);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<DarkModeProvider>().isDarkMode;
    final Color titleText = isDark ? white : grayBlack;
    final Color subTitleText = isDark ? lightGray : mediumGray;

    ImageProvider profileImage;
    if (userPhoto != null && userPhoto!.startsWith("http")) {
      profileImage = NetworkImage(userPhoto!);
    } else if (userPhoto != null) {
      profileImage = MemoryImage(base64Decode(userPhoto!));
    } else {
      profileImage = const AssetImage("assets/images/profile.png");
    }

    return Column(
      children: [
        // ✅ Profile Image with Camera Icon
        Stack(
          children: [
            GestureDetector(
              onTap: () => showFullImagePreview(profileImage),
              child: CircleAvatar(radius: 50, backgroundImage: profileImage),
            ),

            Positioned(
              bottom: 0,
              right: 2,
              child: GestureDetector(
                onTap: () => showImagePickerSheet(isDark, titleText),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: brandGreen,
                  child: Icon(Icons.camera_alt, size: 15, color: white),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ✅ Name + Edit Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            bodyText(
              text: userName ?? "Unknown",
              color: isDark ? white : carbonBlack,
              weight: FontWeight.w600,
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: () => editNameDialog(isDark),
              child: Icon(
                Icons.edit,
                size: 16,
                color: isDark ? lightGray : mediumGray,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
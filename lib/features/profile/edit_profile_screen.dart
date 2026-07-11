import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _dobController;
  late TextEditingController _mobileController;
  late TextEditingController _roleController;
  late TextEditingController _associationController;

  String _playingRole = 'Batsman';
  String _battingStyle = 'Right Hand';
  String _bowlingStyle = 'Right-arm Fast';
  String _gender = 'Prefer not to say';
  String? _profileImagePath;

  final List<String> _playingRoles = [
    'Batsman',
    'Bowler',
    'All-rounder',
    'Wicket Keeper',
    'Top - Order',
    'Middle - Order',
    'Lower - Order',
    'Opening Batter',
  ];

  final List<String> _battingStyles = ['Right Hand', 'Left Hand'];

  final List<String> _bowlingStyles = [
    'Right-arm Fast',
    'Right-arm Medium',
    'Left-arm Fast',
    'Left-arm Medium',
    'Off - Spin',
    'Leg - Spin',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.name);
    _locationController = TextEditingController(text: profile.location);
    _dobController = TextEditingController(text: profile.dateOfBirth);
    _mobileController = TextEditingController(text: profile.mobile);
    _roleController = TextEditingController(text: profile.role);
    _associationController = TextEditingController(text: profile.association);

    _playingRole = _playingRoles.contains(profile.playingRole)
        ? profile.playingRole
        : _playingRoles.first;
    _battingStyle = _battingStyles.contains(profile.battingStyle)
        ? profile.battingStyle
        : _battingStyles.first;
    _bowlingStyle = _bowlingStyles.contains(profile.bowlingStyle)
        ? profile.bowlingStyle
        : _bowlingStyles.first;
    _gender = profile.gender;
    _profileImagePath = profile.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _roleController.dispose();
    _associationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFBA0013), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Color(0xFF191C1E), // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFBA0013), // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = UserProfile(
        name: _nameController.text,
        role: _roleController.text,
        location: _locationController.text,
        association: _associationController.text,
        dateOfBirth: _dobController.text,
        mobile: _mobileController.text,
        playingRole: _playingRole,
        battingStyle: _battingStyle,
        bowlingStyle: _bowlingStyle,
        gender: _gender,
        profileImagePath: _profileImagePath,
      );
      ref.read(profileProvider.notifier).updateProfile(updatedProfile);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2138),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'EDIT PROFILE',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImagePath != null
                                  ? Image.file(
                                      File(_profileImagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      alignment: Alignment.center,
                                      child: Text(
                                        _nameController.text.isNotEmpty
                                            ? _nameController.text[0]
                                                  .toUpperCase()
                                            : 'U',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF575D78),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBA0013),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'Scorely User',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: 98234-CRIC', // Static mock ID
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF575D78),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Basic Information Card
                    _buildFormCard(
                      title: 'BASIC INFORMATION',
                      icon: Icons.person_outline,
                      children: [
                        _buildInputField(
                          label: 'NAME',
                          controller: _nameController,
                          hintText: 'Enter your name',
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'TAGLINE / ROLE',
                          controller: _roleController,
                          hintText: 'E.g. Professional Scorer',
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'ASSOCIATION',
                          controller: _associationController,
                          hintText: 'E.g. South Zone Cricket Association',
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'LOCATION',
                          controller: _locationController,
                          hintText: 'E.g. Mumbai, India',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'DATE OF BIRTH',
                          controller: _dobController,
                          hintText: 'MM/DD/YYYY',
                          prefixIcon: Icons.calendar_today_outlined,
                          suffixIcon: Icons.calendar_month,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'MOBILE NUMBER',
                          controller: _mobileController,
                          hintText: '+91 98765 43210',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Player Attributes Card
                    _buildFormCard(
                      title: 'PLAYER ATTRIBUTES',
                      icon: Icons.sports_cricket_outlined,
                      borderColor: const Color(0xFF575D78),
                      children: [
                        _buildDropdownField(
                          label: 'PLAYING ROLE',
                          value: _playingRole,
                          items: _playingRoles,
                          onChanged: (val) {
                            if (val != null) setState(() => _playingRole = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'BATTING STYLE',
                                value: _battingStyle,
                                items: _battingStyles,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _battingStyle = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'BOWLING STYLE',
                                value: _bowlingStyle,
                                items: _bowlingStyles,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _bowlingStyle = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Demographics Card
                    _buildFormCard(
                      title: 'DEMOGRAPHICS',
                      icon: Icons.people_outline,
                      borderColor: Colors
                          .transparent, // Default is red, override here if needed, or leave. Wait, design has no border on demographics.
                      children: [
                        Text(
                          'GENDER',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D3F3C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRadioOption('Male'),
                        const SizedBox(height: 8),
                        _buildRadioOption('Female'),
                        const SizedBox(height: 8),
                        _buildRadioOption('Prefer not to say'),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBA0013),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: const Color(
                            0xFFBA0013,
                          ).withValues(alpha: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.save,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color borderColor = const Color(0xFFBA0013),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != Colors.transparent
            ? Border(left: BorderSide(color: borderColor, width: 4))
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5D3F3C), size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D3F3C),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D3F3C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF191C1E),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78).withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF2F4F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: const Color(0xFF575D78), size: 20)
                : null,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: const Color(0xFF191C1E), size: 20)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D3F3C),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF575D78),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF191C1E),
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String title) {
    return GestureDetector(
      onTap: () => setState(() => _gender = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _gender == title
                      ? const Color(0xFFBA0013)
                      : const Color(0xFFD8DADD),
                  width: 2,
                ),
              ),
              child: _gender == title
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFBA0013),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF191C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

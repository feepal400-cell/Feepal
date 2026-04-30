import 'package:flutter/material.dart';
import 'language_config.dart';
import 'services/firebase_service.dart';
import 'subscription_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'services/cloudinary_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _schoolNameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolAddressController = TextEditingController();

  final List<Map<String, String>> _branches = [];
  Uint8List? _logoBytes;
  bool _isUploadingLogo = false;
  String? _uploadedLogoUrl;

  final _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _adminNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolAddressController.dispose();
    super.dispose();
  }

  String formatName(String value) {
    // Remove numbers
    String clean = value.replaceAll(RegExp(r'[0-9]'), '');
    // Capitalize first letter of each word
    return clean.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }

  Future<void> _handleLogoUpload() async {
    setState(() {
      _isUploadingLogo = true;
    });

    try {
      String? url = await CloudinaryService.pickAndUploadImage(uploadPreset: 'School_Logos');
      
      if (url != null) {
        setState(() {
          _uploadedLogoUrl = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translations.get('Logo uploaded successfully', languageNotifier.value))),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingLogo = false;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compression
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final sizeInMb = bytes.lengthInBytes / (1024 * 1024);

      if (sizeInMb > 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size must be less than 2MB')),
          );
        }
        return;
      }

      setState(() {
        _logoBytes = bytes;
      });
    }
  }

  void _addBranch() {
    setState(() {
      _branches.add({
        'branchName': '',
        'branchAddress': '',
        'branchCode': '',
      });
    });
  }

  void _removeBranch(int index) {
    setState(() {
      _branches.removeAt(index);
    });
  }

  Future<void> _handleSignUp(bool isUrdu) async {
    final schoolName = formatName(_schoolNameController.text.trim());
    final adminName = formatName(_adminNameController.text.trim());
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final schoolAddress = _schoolAddressController.text.trim();

    // 1. Basic Field Check
    if (schoolName.isEmpty ||
        adminName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        schoolAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('Please fill in all required fields.', isUrdu))),
      );
      return;
    }

    // 2. Logo Check
    if (_logoBytes == null && _uploadedLogoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('Please upload school logo.', isUrdu))),
      );
      return;
    }

    // 3. Email Validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('Invalid email format.', isUrdu))),
      );
      return;
    }

    // 4. Phone Validation (+92)
    if (!phone.startsWith('+92') || phone.length < 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('Invalid phone number format. Must start with +92.', isUrdu))),
      );
      return;
    }

    // 5. Password Validation
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('Password must be at least 6 characters.', isUrdu))),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('Passwords do not match.', isUrdu))),
      );
      return;
    }

    // 6. Branch Validation
    if (_branches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.get('Please add at least one branch.', isUrdu))),
      );
      return;
    }

    final branchCodes = <String>{};
    for (int i = 0; i < _branches.length; i++) {
      final b = _branches[i];
      if ((b['branchAddress'] ?? '').isEmpty || (b['branchCode'] ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all details for Branch ${i + 1}')),
        );
        return;
      }
      
      // Auto-assign branch name if empty
      if ((b['branchName'] ?? '').isEmpty) {
        b['branchName'] = 'Branch ${i + 1}';
      }

      // Check unique code
      if (branchCodes.contains(b['branchCode'])) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Translations.get('Duplicate branch codes not allowed.', isUrdu))),
        );
        return;
      }
      branchCodes.add(b['branchCode']!);
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint("⏳ [SignUpScreen] Attempting signup service call...");
      
      final error = await _firebaseService.signUpAdmin(
        schoolName: schoolName,
        adminName: adminName,
        email: email,
        phoneNumber: phone,
        password: password,
        schoolAddress: schoolAddress,
        branches: _branches.map((b) => Map<String, dynamic>.from(b)).toList(),
        logoBytes: _logoBytes,
        externalLogoUrl: _uploadedLogoUrl,
      );

      debugPrint("📩 [SignUpScreen] Service returned: ${error ?? 'Success (null)'}");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Translations.get('Account Created Successfully.', isUrdu))),
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final adminData = await _firebaseService.getAdminData(user.uid);
          if (mounted && adminData != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SubscriptionScreen(adminData: adminData)),
              (route) => false,
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      debugPrint("🚨 [SignUpScreen] Caught exception in _handleSignUp: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.black26),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.black26),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: languageNotifier,
      builder: (context, isUrdu, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2168F8), Color(0xFF00D4FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 10.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 45,
                            width: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            Translations.get('Sign Up', isUrdu),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                        padding: const EdgeInsets.all(25.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section: School Information
                              _buildSectionHeader(Translations.get('School Information', isUrdu)),
                              const SizedBox(height: 15),

                              // Logo Picker
                              Center(
                                child: GestureDetector(
                                  onTap: _isUploadingLogo ? null : _handleLogoUpload,
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 100,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.blue.withValues(alpha: 0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: _isUploadingLogo
                                              ? const Center(child: CircularProgressIndicator())
                                              : (_uploadedLogoUrl != null
                                                  ? Image.network(
                                                      _uploadedLogoUrl!,
                                                      fit: BoxFit.cover,
                                                      width: 100,
                                                      height: 100,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return const Center(child: CircularProgressIndicator());
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        debugPrint("❌ Network Image Error: $error");
                                                        return const Icon(Icons.error_outline, color: Colors.red);
                                                      },
                                                    )
                                                  : (_logoBytes != null
                                                      ? Image.memory(
                                                          _logoBytes!,
                                                          fit: BoxFit.cover,
                                                          width: 100,
                                                          height: 100,
                                                        )
                                                      : const Icon(Icons.camera_alt, color: Colors.blue, size: 30))),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isUploadingLogo
                                            ? Translations.get('Processing...', isUrdu)
                                            : Translations.get('Upload School Logo', isUrdu),
                                        style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _schoolNameController,
                                label: Translations.get('School Name', isUrdu),
                                hintText: Translations.get('Enter school name', isUrdu),
                                icon: Icons.account_balance_outlined,
                              ),
                              _buildTextField(
                                controller: _schoolAddressController,
                                label: Translations.get('School Address', isUrdu),
                                hintText: Translations.get('Enter school address', isUrdu),
                                icon: Icons.location_on_outlined,
                              ),

                              const SizedBox(height: 10),
                              // Section: Admin Information
                              _buildSectionHeader(Translations.get('Admin Information', isUrdu)),
                              const SizedBox(height: 15),

                              _buildTextField(
                                controller: _adminNameController,
                                label: Translations.get('Admin Name', isUrdu),
                                hintText: Translations.get('Enter your name', isUrdu),
                                icon: Icons.person_outline,
                              ),
                              _buildTextField(
                                controller: _emailController,
                                label: Translations.get('Email', isUrdu),
                                hintText: 'admin@school.com',
                                icon: Icons.email_outlined,
                              ),
                              _buildTextField(
                                controller: _phoneController,
                                label: Translations.get('Phone Number', isUrdu),
                                hintText: '+92 300 1234567',
                                icon: Icons.phone_outlined,
                              ),
                              _buildTextField(
                                controller: _passwordController,
                                label: Translations.get('Password', isUrdu),
                                hintText: '********',
                                icon: Icons.lock_outline,
                                isObscure: true,
                              ),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: Translations.get('Confirm Password', isUrdu),
                                hintText: '********',
                                icon: Icons.lock_outline,
                                isObscure: true,
                              ),

                              const SizedBox(height: 10),
                              // Section: Branches
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionHeader(Translations.get('Branches', isUrdu)),
                                  TextButton.icon(
                                    onPressed: _addBranch,
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    label: Text(Translations.get('Add Branch', isUrdu)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (_branches.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Text(
                                      Translations.get('Please add at least one branch.', isUrdu),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                )
                              else
                                ...List.generate(_branches.length, (index) {
                                  return _buildBranchCard(index, isUrdu);
                                }),

                              const SizedBox(height: 30),

                              // Create Account Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => _handleSignUp(isUrdu),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2972FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          Translations.get('Create Account', isUrdu),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    Translations.get("Already have an account? ", isUrdu),
                                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Text(
                                      Translations.get('Login', isUrdu),
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2168F8)),
      ),
    );
  }

  Widget _buildBranchCard(int index, bool isUrdu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      elevation: 0,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${Translations.get('Branches', isUrdu)} ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _removeBranch(index),
                ),
              ],
            ),
            const Divider(),
            _buildBranchField(
              label: Translations.get('Branch Name', isUrdu),
              hint: 'e.g. Campus A',
              onChanged: (val) => _branches[index]['branchName'] = val,
            ),
            const SizedBox(height: 10),
            _buildBranchField(
              label: Translations.get('Branch Address', isUrdu),
              hint: 'Street, City...',
              onChanged: (val) => _branches[index]['branchAddress'] = val,
            ),
            const SizedBox(height: 10),
            _buildBranchField(
              label: Translations.get('Branch Code', isUrdu),
              hint: 'BR-101',
              onChanged: (val) => _branches[index]['branchCode'] = val,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchField({required String label, required String hint, required Function(String) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
        const SizedBox(height: 4),
        TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

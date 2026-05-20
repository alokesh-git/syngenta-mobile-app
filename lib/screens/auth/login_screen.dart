import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  late PageController _pageController;
  late AnimationController _scannerController;

  bool _otpSent = false;
  bool _isLoading = false;
  bool _phoneHasFocus = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _phoneFocusNode.addListener(() {
      setState(() {
        _phoneHasFocus = _phoneFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _pageController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showSnack('Enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().sendOTP('+91$phone');
      if (mounted) {
        final err = context.read<AuthProvider>().errorMessage;
        setState(() {
          _isLoading = false;
          _otpSent = err == null;
        });
        if (err != null) {
          _showSnack('Phone auth failed. Please use the Skip option or try on a real device.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Phone auth unavailable. Use Skip to continue as guest.');
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnack('Enter a valid 6-digit OTP');
      return;
    }
    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().verifyOTP(otp);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) _goHome();
    }
  }

  Future<void> _skipAnonymously() async {
    setState(() => _isLoading = true);
    await context.read<AuthProvider>().signInAnonymously();
    if (mounted) {
      setState(() => _isLoading = false);
      _goHome();
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            // Page 1: AI Diagnostics
            _buildOnboardingStep(
              title: 'Get AI-Powered Solutions',
              subtitle: 'Show your crop in live video, get instant analysis and recommended products.',
              illustration: _buildAIDiagnosticIllustration(),
              pageIndex: 0,
            ),
            // Page 2: Farmer Network
            _buildOnboardingStep(
              title: 'Connect with Nearby Farmers',
              subtitle: 'Find and connect with farmers in your area, share experience, and get advice.',
              illustration: _buildNetworkIllustration(),
              pageIndex: 1,
            ),
            // Page 3: Smart Solutions & Login Card
            _buildLoginStep(),
          ],
        ),
      ),
    );
  }

  // Generic Layout for Onboarding step 1 & 2
  Widget _buildOnboardingStep({
    required String title,
    required String subtitle,
    required Widget illustration,
    required int pageIndex,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skip Button at top-right
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: () {
                _pageController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B5E20),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const Spacer(),
          // Center Illustration
          Center(child: illustration),
          const Spacer(),
          // Bottom Content
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          // Nav controls (dots & forward FAB)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dots indicator
              Row(
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              // Next FAB
              FloatingActionButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                backgroundColor: const Color(0xFFE8F5E9),
                foregroundColor: const Color(0xFF1B5E20),
                elevation: 1,
                shape: const CircleBorder(),
                child: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Step 3: Login Form Step
  Widget _buildLoginStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          // Top Text Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Text(
                  'Smart Solutions\nfor Better Farming',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Show your crop, get AI diagnosis and recommended solutions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Central Photo with Floating Badges
          Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Crop field image mask
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/login.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Floating badge 1: Leaf
                Positioned(
                  top: 10,
                  left: -10,
                  child: _buildFloatingCircularBadge(
                    child: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 22),
                  ),
                ),
                // Floating badge 2: Product Bottle Vector
                Positioned(
                  top: 60,
                  right: -15,
                  child: _buildFloatingCircularBadge(
                    child: _buildMiniBottleIcon(),
                  ),
                ),
                // Floating badge 3: Checkmark
                Positioned(
                  bottom: 25,
                  right: 15,
                  child: _buildFloatingCircularBadge(
                    color: const Color(0xFF2E7D32),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Sliding White Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otpSent ? 'enter_otp'.tr() : 'Login or Sign up',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _otpSent ? 'Sent to +91 ${_phoneController.text}' : 'Enter your mobile number to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),

                if (!_otpSent) ...[
                  // Phone Number Input Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _phoneHasFocus ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
                        width: _phoneHasFocus ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Country Code + Dropdown Arrow
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+91',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey.shade600,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        // Divider Line
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        // Text Field
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'phone_hint'.tr(),
                              counterText: '',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // OR Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade200)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade200)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Skip for now button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : _skipAnonymously,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F8E9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'skip'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF1B5E20),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // OTP Input field
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                    decoration: InputDecoration(
                      hintText: '------',
                      hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 12),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'verify'.tr(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Change Number button
                      TextButton(
                        onPressed: () => setState(() => _otpSent = false),
                        child: const Text(
                          'Edit Number',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Resend Button
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                await _sendOTP();
                                _showSnack('OTP Resent Successfully!');
                              },
                        child: Text(
                          'resend_otp'.tr(),
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                // Terms and policy footer
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.4),
                      children: const [
                        TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms & Privacy Policy',
                          style: TextStyle(
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Floating Circular Badge Builder
  Widget _buildFloatingCircularBadge({required Widget child, Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // Draw a miniature Pesticide / Fertilizer Bottle vector icon
  Widget _buildMiniBottleIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cap
          Positioned(
            top: 0,
            child: Container(
              width: 5,
              height: 3,
              color: const Color(0xFF1B5E20),
            ),
          ),
          // Body
          Positioned(
            top: 3,
            child: Container(
              width: 11,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 6,
                  color: const Color(0xFFE8F5E9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 1 Mockup: Smartphone scanning a leaf with floating recommendations
  Widget _buildAIDiagnosticIllustration() {
    return Container(
      height: 270,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Smartphone container
          Container(
            width: 150,
            height: 245,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF2C2C2C), width: 5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/login.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.green.withOpacity(0.15),
                    ),
                  ),
                  // Scanner L-corners
                  Positioned(
                    left: 20,
                    top: 40,
                    right: 20,
                    bottom: 60,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white, width: 2),
                                left: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white, width: 2),
                                right: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.white, width: 2),
                                left: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.white, width: 2),
                                right: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scanning Laser
                  AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      return Positioned(
                        top: 40 + (_scannerController.value * 140),
                        left: 22,
                        right: 22,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // LIVE status badge
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LIVE  00:01:24',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Diagnose text card
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'AI Analysis',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bacterial Leaf Spot',
                          style: TextStyle(
                            color: Color(0xFF1E1E1E),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Xanthomonas campestris',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 7,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  // Floating Products Card on the right
  Positioned(
    right: -25,
    top: 45,
    child: _buildVectorProductCard(),
  ),
],
),
);
}

  // Draw Recommended Product Card Vector
  Widget _buildVectorProductCard() {
    return Container(
      width: 95,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Recommended\nProducts',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),
          // Draw Pesticide Bottle
          Center(
            child: Container(
              height: 42,
              width: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cap
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                  // Bottle Body
                  Positioned(
                    top: 4,
                    child: Container(
                      width: 20,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300, width: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 10,
                            color: const Color(0xFFE8F5E9),
                            child: const Icon(
                              Icons.eco,
                              size: 6,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '4.6',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 8,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Center(
              child: Text(
                'View',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 2 Mockup: Concentric Radar and Farmer profiles
  Widget _buildNetworkIllustration() {
    return Container(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric circles
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.withOpacity(0.12), width: 1.5),
            ),
          ),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.withOpacity(0.18), width: 1.5),
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.withOpacity(0.24), width: 1.5),
            ),
          ),
          // Center Map Pin
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2E7D32),
                  blurRadius: 10,
                  spreadRadius: 1.5,
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
          // Nearby Farmer 1
          Positioned(
            top: 15,
            left: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFFFD54F),
                    child: Text('🌾', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Rice • 1.2km',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Nearby Farmer 2
          Positioned(
            bottom: 15,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF90CAF9),
                    child: Text('☁️', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Cotton • 2.5km',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Nearby Farmer 3 (Alert)
          Positioned(
            top: 60,
            right: 5,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFEF9A9A),
                    child: Text('🐛', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Alert • 500m',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

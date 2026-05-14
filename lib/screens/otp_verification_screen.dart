import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../constants/dimensions.dart';
import '../services/otp_service.dart';
import '../utils/validation.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String username;
  final String password;
  final String fullName;
  final Function(bool) onVerificationComplete;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.username,
    required this.password,
    required this.fullName,
    required this.onVerificationComplete,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResendLoading = false;
  int _remainingTime = 600; // 10 minutes in seconds
  late Timer _timer;
  late String _currentOTP;

  @override
  void initState() {
    super.initState();
    _currentOTP = OTPService.generateOTP();
    _sendOTP();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime--;
        if (_remainingTime <= 0) {
          _timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
    });

    bool success = await OTPService.sendOTPEmail(
      email: widget.email,
      otp: _currentOTP,
      username: widget.username,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${widget.email}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. Please check your email credentials.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate verification delay
      await Future.delayed(const Duration(seconds: 1));

      if (_otpController.text == _currentOTP) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        if (mounted) {
          widget.onVerificationComplete(true);
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid OTP. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResendLoading = true;
    });

    _currentOTP = OTPService.generateOTP();
    bool success = await OTPService.resendOTP(
      email: widget.email,
      otp: _currentOTP,
      username: widget.username,
    );

    if (!mounted) return;

    setState(() {
      _isResendLoading = false;
      _remainingTime = 600;
      _otpController.clear();
    });

    if (success) {
      _timer.cancel();
      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend OTP.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getTimeString() {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _isExpired => _remainingTime <= 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusLarge),
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    size: 50,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLarge),

                // Title
                const Text(
                  'Verify Email',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'We\'ve sent a 6-digit OTP to\n${widget.email}',
                  style: const TextStyle(
                    fontSize: AppDimensions.textLarge,
                    color: AppColors.textGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // OTP Input Field
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    labelStyle: const TextStyle(color: AppColors.textGrey),
                    counterText: '',
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide:
                          const BorderSide(color: AppColors.textGrey, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(
                          color: AppColors.primaryOrange, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: ValidationUtils.validateOTP,
                ),
                const SizedBox(height: 20),

                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _isExpired
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    border: Border.all(
                      color: _isExpired ? Colors.red : AppColors.primaryOrange,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: _isExpired ? Colors.red : AppColors.primaryOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isExpired ? 'OTP Expired' : 'Time remaining: ${_getTimeString()}',
                        style: TextStyle(
                          color: _isExpired ? Colors.red : AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Verify Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    disabledBackgroundColor:
                        AppColors.primaryOrange.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textWhite,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive OTP? ",
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _isResendLoading || !_isExpired ? null : _resendOTP,
                      child: _isResendLoading
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isResendLoading
                                      ? AppColors.primaryOrange
                                      : AppColors.primaryOrange,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Resend',
                              style: TextStyle(
                                color: !_isExpired && !_isResendLoading
                                    ? AppColors.primaryOrange
                                    : AppColors.textGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
    );
  }
}

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';
import '../constants/text_styles.dart';
import '../widgets/custom_text_field.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _energyUsageController = TextEditingController();
  final _rooftopAreaController = TextEditingController();
  final _locationController = TextEditingController();
  final _loadSheddingController = TextEditingController();

  bool _showResult = false;
  double _systemSize = 0.0;
  double _systemCost = 0.0;

  @override
  void dispose() {
    _energyUsageController.dispose();
    _rooftopAreaController.dispose();
    _locationController.dispose();
    _loadSheddingController.dispose();
    super.dispose();
  }

  void _calculateSystem() {
    // Check if all fields are filled
    if (_energyUsageController.text.isEmpty ||
        _rooftopAreaController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _loadSheddingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate form
    if (_formKey.currentState!.validate()) {
      // Static calculation logic
      double energyUsage = double.parse(_energyUsageController.text);
      double rooftopArea = double.parse(_rooftopAreaController.text);

      // Simple calculation formula
      // System size = (Daily Energy Usage * 1.3) / 5
      _systemSize = (energyUsage * 1.3) / 5;

      // Cost calculation (PKR 300,000 per kW)
      _systemCost = _systemSize * 300000;

      setState(() {
        _showResult = true;
      });
    }
  }

  void _recalculate() {
    setState(() {
      _showResult = false;
      _energyUsageController.clear();
      _rooftopAreaController.clear();
      _locationController.clear();
      _loadSheddingController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.wb_sunny,
                color: AppColors.textWhite,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Solar Advisor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                Text(
                  'Energy Management System',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            children: [
              // Calculator Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardOrange,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                ),
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.textWhite.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calculate,
                              color: AppColors.textDark,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Solar System Calculator',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Calculate the ideal solar system size for your home based on your energy usage and location.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Daily Energy Usage
                      CustomTextField(
                        controller: _energyUsageController,
                        label: 'Daily Energy Usage',
                        hint: 'e.g., 30',
                        suffix: 'kWh',
                        icon: Icons.flash_on,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Rooftop Area
                      CustomTextField(
                        controller: _rooftopAreaController,
                        label: 'Rooftop Area (in sqm)',
                        hint: 'e.g., 50',
                        suffix: 'm²',
                        icon: Icons.home,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Location
                      CustomTextField(
                        controller: _locationController,
                        label: 'Location',
                        hint: 'e.g., California, New York',
                        icon: Icons.location_on,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),

                      // Daily Load Shedding Hours
                      CustomTextField(
                        controller: _loadSheddingController,
                        label: 'Daily Load Shedding Hours',
                        hint: 'e.g., 4',
                        suffix: 'hours',
                        icon: Icons.access_time,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      // Calculate Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _calculateSystem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMedium),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Calculate System Size',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: AppColors.textWhite,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Result Card
              if (_showResult) ...[
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlue,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  ),
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    children: [
                      // Semicircle with System Size
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Semicircle background
                          CustomPaint(
                            size: const Size(280, 140),
                            painter: SemiCirclePainter(),
                          ),
                          // Text in center
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                const Text(
                                  'System Size',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_systemSize.toStringAsFixed(1)} kW',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),

                      // Recalculate Button
                      ElevatedButton(
                        onPressed: _recalculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Recalculate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonBlue,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // Horizontal Divider Line
                      Container(
                        height: 1,
                        color: AppColors.textWhite.withOpacity(0.2),
                      ),
                      
                      const SizedBox(height: 32),

                      // Estimates Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // System Size
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Estimated System Size',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${_systemSize.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'kW',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // System Cost
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Estimated System Cost',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '₨${(_systemCost / 1000).toStringAsFixed(1)}k',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.costGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'PKR',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Semicircle
class SemiCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    const startAngle = 3.14159; // π (180 degrees - start from left)
    const sweepAngle = 3.14159; // π (180 degrees - draw half circle)

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
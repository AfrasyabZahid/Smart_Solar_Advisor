import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';
import '../widgets/custom_text_field.dart';
import '../services/user_data_service.dart';
import '../utils/user_preferences.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _energyUsageController    = TextEditingController();
  final _rooftopAreaController    = TextEditingController();
  final _locationController       = TextEditingController();
  final _loadSheddingController   = TextEditingController();
  final _monthlyBillController    = TextEditingController();
  final _monthlyIncomeController  = TextEditingController();

  bool   _isLoading       = false;
  bool   _showResult      = false;

  // Results from ML backend
  double _systemSize          = 0.0;
  double _systemCost          = 0.0;
  double _dailyEnergyGen      = 0.0;
  double _feasibilityScore    = 0.0;
  String _userSegment         = '';
  double _peakSunHours        = 5.0;
  bool   _mlUsed              = false;
  Map<String, dynamic> _recommendation = {};

  @override
  void dispose() {
    _energyUsageController.dispose();
    _rooftopAreaController.dispose();
    _locationController.dispose();
    _loadSheddingController.dispose();
    _monthlyBillController.dispose();
    _monthlyIncomeController.dispose();
    super.dispose();
  }

  Future<void> _calculateSystem() async {
    if (_energyUsageController.text.isEmpty ||
        _rooftopAreaController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _loadSheddingController.text.isEmpty ||
        _monthlyBillController.text.isEmpty ||
        _monthlyIncomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final double energyUsage     = double.parse(_energyUsageController.text);
    final double rooftopArea     = double.parse(_rooftopAreaController.text);
    final double loadSheddingHrs = double.parse(_loadSheddingController.text);
    final String location        = _locationController.text.trim();
    
    // Mandatory fields
    final double monthlyBill     = double.parse(_monthlyBillController.text);
    final double monthlyIncome   = double.parse(_monthlyIncomeController.text);

    setState(() => _isLoading = true);

    // ── Call ML backend ─────────────────────────────────────────────────────
    final prediction = await UserDataService.predictSolar(
      energyUsageKwh:            energyUsage,
      rooftopAreaSqm:            rooftopArea,
      location:                  location,
      loadSheddingHours:         loadSheddingHrs,
      monthlyElectricityBillPkr: monthlyBill,
      monthlyIncomePkr:          monthlyIncome,
    );

    if (prediction == null) {
      // Fallback formula if backend unreachable
      final fallbackSize = (energyUsage * 1.3) / 5.0;
      setState(() {
        _systemSize       = fallbackSize;
        _systemCost       = fallbackSize * 300000;
        _dailyEnergyGen   = fallbackSize * 5.0;
        _feasibilityScore = 50.0;
        _userSegment      = 'Moderate User';
        _peakSunHours     = 5.0;
        _mlUsed           = false;
        _showResult       = true;
        _isLoading        = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backend unavailable — showing formula estimate'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      setState(() {
        _systemSize       = (prediction['system_size_kw'] as num).toDouble();
        _systemCost       = (prediction['system_cost_pkr'] as num).toDouble();
        _dailyEnergyGen   = (prediction['daily_energy_gen_kwh'] as num).toDouble();
        _feasibilityScore = (prediction['feasibility_score'] as num).toDouble();
        _userSegment      = prediction['user_segment'] as String? ?? '';
        _peakSunHours     = (prediction['peak_sun_hours'] as num).toDouble();
        _mlUsed           = prediction['ml_used'] as bool? ?? false;
        _recommendation   = (prediction['recommendation'] as Map<String, dynamic>?) ?? {};
        _showResult       = true;
        _isLoading        = false;
      });
    }

    // ── Save to DB ──────────────────────────────────────────────────────────
    final email = await UserPreferences.getUserEmail();
    if (email != null) {
      final saved = await UserDataService.saveCalculation(
        userEmail:                 email,
        energyUsageKwh:            energyUsage,
        rooftopAreaSqm:            rooftopArea,
        location:                  location,
        loadSheddingHours:         loadSheddingHrs,
        systemSizeKw:              _systemSize,
        systemCostPkr:             _systemCost,
        monthlyElectricityBillPkr: monthlyBill,
        monthlyIncomePkr:          monthlyIncome,
        dailyEnergyGenKwh:         _dailyEnergyGen,
        feasibilityScore:          _feasibilityScore,
        userSegment:               _userSegment,
        peakSunHours:              _peakSunHours,
        recommendation:            _recommendation,
        mlUsed:                    _mlUsed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saved
                ? '✓ Recommendation saved to history'
                : 'Result ready (could not save — check connection)'),
            backgroundColor: saved ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _recalculate() {
    setState(() {
      _showResult = false;
      _energyUsageController.clear();
      _rooftopAreaController.clear();
      _locationController.clear();
      _loadSheddingController.clear();
      _monthlyBillController.clear();
      _monthlyIncomeController.clear();
    });
  }

  Color _feasibilityColor(double score) {
    if (score >= 70) return const Color(0xFF10B981);   // green
    if (score >= 40) return const Color(0xFFFDB022);   // orange
    return Colors.redAccent;
  }

  String _feasibilityLabel(double score) {
    if (score >= 70) return 'Excellent';
    if (score >= 50) return 'Good';
    if (score >= 30) return 'Moderate';
    return 'Low';
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.wb_sunny, color: AppColors.textWhite, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Solar Advisor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: AppColors.textWhite)),
                Text('AI-Powered Calculator',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
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
              // ── Input Card ──────────────────────────────────────────────
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.textWhite.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.calculate,
                                color: AppColors.textDark, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text('Solar System Calculator',
                              style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your details below. Our ML model will recommend the ideal solar system for your location.',
                        style: TextStyle(fontSize: 13, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 24),

                      CustomTextField(
                        controller: _energyUsageController,
                        label: 'Daily Energy Usage',
                        hint: 'e.g., 30',
                        suffix: 'kWh',
                        icon: Icons.flash_on,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _rooftopAreaController,
                        label: 'Rooftop Area',
                        hint: 'e.g., 50',
                        suffix: 'm²',
                        icon: Icons.home,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _locationController,
                        label: 'City / Location',
                        hint: 'e.g., Karachi, Lahore',
                        icon: Icons.location_on,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _loadSheddingController,
                        label: 'Daily Load Shedding Hours',
                        hint: 'e.g., 4',
                        suffix: 'hrs',
                        icon: Icons.access_time,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _monthlyBillController,
                        label: 'Monthly Electricity Bill',
                        hint: 'e.g., 15000',
                        suffix: 'PKR',
                        icon: Icons.receipt_long,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _monthlyIncomeController,
                        label: 'Monthly Income',
                        hint: 'e.g., 150000',
                        suffix: 'PKR',
                        icon: Icons.account_balance_wallet,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _calculateSystem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMedium),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(
                                      color: AppColors.textWhite, strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Get AI Recommendation',
                                        style: TextStyle(fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textWhite)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward,
                                        color: AppColors.textWhite),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Result Card ─────────────────────────────────────────────
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
                      // ML badge
                      if (_mlUsed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryOrange),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: AppColors.primaryOrange, size: 14),
                              SizedBox(width: 4),
                              Text('AI-Powered Recommendation',
                                  style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Semicircle gauge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(280, 140),
                            painter: SemiCirclePainter(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                const Text('Recommended System Size',
                                    style: TextStyle(
                                        fontSize: 13, color: AppColors.textWhite)),
                                const SizedBox(height: 6),
                                Text('${_systemSize.toStringAsFixed(1)} kW',
                                    style: const TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textWhite)),
                                Text('Peak sun: ${_peakSunHours.toStringAsFixed(1)} h/day',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _recalculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Recalculate',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.buttonBlue)),
                      ),

                      const SizedBox(height: 28),
                      Container(height: 1,
                          color: AppColors.textWhite.withOpacity(0.2)),
                      const SizedBox(height: 28),

                      // Row 1: System Size + Cost
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _resultTile(
                            label: 'System Size',
                            value: '${_systemSize.toStringAsFixed(1)}',
                            unit: 'kW',
                            color: AppColors.primaryOrange,
                          ),
                          _resultTile(
                            label: 'Est. Cost',
                            value: '₨${(_systemCost / 1000).toStringAsFixed(0)}k',
                            unit: 'PKR',
                            color: AppColors.costGreen,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Container(height: 1,
                          color: AppColors.textWhite.withOpacity(0.1)),
                      const SizedBox(height: 24),

                      // Row 2: Daily Energy Generation + Feasibility
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _resultTile(
                            label: 'Daily Generation',
                            value: '${_dailyEnergyGen.toStringAsFixed(1)}',
                            unit: 'kWh/day',
                            color: const Color(0xFF60A5FA),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Feasibility Score',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13, color: AppColors.textWhite)),
                                const SizedBox(height: 8),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 72, height: 72,
                                      child: CircularProgressIndicator(
                                        value: _feasibilityScore / 100,
                                        strokeWidth: 7,
                                        backgroundColor:
                                            AppColors.textWhite.withOpacity(0.15),
                                        color: _feasibilityColor(_feasibilityScore),
                                      ),
                                    ),
                                    Text('${_feasibilityScore.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: _feasibilityColor(
                                                _feasibilityScore))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(_feasibilityLabel(_feasibilityScore),
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _feasibilityColor(_feasibilityScore))),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // User Segment badge
                      if (_userSegment.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.textWhite.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.textWhite.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline,
                                  color: AppColors.textWhite, size: 18),
                              const SizedBox(width: 8),
                              Text('User Profile: ',
                                  style: TextStyle(
                                      color:
                                          AppColors.textWhite.withOpacity(0.7),
                                      fontSize: 13)),
                              Text(_userSegment,
                                  style: const TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],

                      // ML Recommendation card
                      if (_recommendation.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.textWhite.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primaryOrange.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb_outline,
                                      color: AppColors.primaryOrange, size: 16),
                                  SizedBox(width: 6),
                                  Text('AI Recommendation',
                                      style: TextStyle(
                                          color: AppColors.primaryOrange,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_recommendation['System_Type'] != null)
                                _recRow('System Type',
                                    _recommendation['System_Type'].toString()),
                              if (_recommendation['Recommended_Size_kW'] != null)
                                _recRow('Ideal Size',
                                    '${_recommendation['Recommended_Size_kW']} kW'),
                              if (_recommendation['Battery'] != null)
                                _recRow('Battery',
                                    _recommendation['Battery'].toString()),
                              if (_recommendation['Advice'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _recommendation['Advice'].toString(),
                                  style: TextStyle(
                                      color: AppColors.textWhite.withOpacity(0.8),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      if (_recommendation['Vendors'] != null && (_recommendation['Vendors'] as List).isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Recommended Local Vendors',
                            style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...(_recommendation['Vendors'] as List).take(3).map((vendor) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.textGrey.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.primaryOrange,
                                  child: Icon(Icons.storefront, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(vendor['name'].toString(),
                                          style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 14),
                                          const SizedBox(width: 4),
                                          Text(vendor['rating'].toString(), style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.phone, color: AppColors.textGrey, size: 12),
                                          const SizedBox(width: 4),
                                          Text(vendor['phone'].toString(), style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Est. Cost', style: TextStyle(color: AppColors.textGrey, fontSize: 10)),
                                    Text('₨${(((vendor['estimated_total_cost'] as num?) ?? 0) / 1000).toStringAsFixed(0)}k',
                                        style: const TextStyle(color: AppColors.costGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],

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

  Widget _resultTile({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textWhite)),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(unit,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textWhite)),
        ],
      ),
    );
  }

  Widget _recRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  color: AppColors.textWhite.withOpacity(0.6), fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Custom semicircle painter
class SemiCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, 3.14159, 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
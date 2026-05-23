import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';
import '../services/user_data_service.dart';
import '../utils/user_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _email = await UserPreferences.getUserEmail();
    if (_email != null) {
      final history =
          await UserDataService.getRecommendationHistory(_email!);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Color _feasibilityColor(double score) {
    if (score >= 70) return const Color(0xFF10B981);
    if (score >= 40) return const Color(0xFFFDB022);
    return Colors.redAccent;
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Recommendation History',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryOrange),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadHistory();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64,
                          color: AppColors.textGrey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No recommendations yet',
                        style: TextStyle(
                            color: AppColors.textGrey, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use the Calculator tab to get your first\nsolar system recommendation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: AppColors.primaryOrange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                    itemCount: _history.length,
                    itemBuilder: (ctx, i) {
                      final item = _history[i];
                      final score =
                          (item['feasibility_score'] as num?)?.toDouble() ?? 0;
                      final size =
                          (item['system_size_kw'] as num?)?.toDouble() ?? 0;
                      final cost =
                          (item['system_cost_pkr'] as num?)?.toDouble() ?? 0;
                      final daily =
                          (item['daily_energy_gen_kwh'] as num?)?.toDouble() ?? 0;
                      final segment =
                          item['user_segment'] as String? ?? '';
                      final location = item['location'] as String? ?? '';
                      final mlUsed = item['ml_used'] as bool? ?? false;
                      
                      final monthlyBill = (item['monthly_electricity_bill_pkr'] as num?)?.toDouble() ?? 0;
                      final monthlyIncome = (item['monthly_income_pkr'] as num?)?.toDouble() ?? 0;
                      final recommendation = item['recommendation'] as Map<String, dynamic>? ?? {};

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.darkBlue,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusLarge),
                          border: Border.all(
                              color: AppColors.textGrey.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: AppColors.primaryOrange,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        location.isEmpty
                                            ? 'Unknown Location'
                                            : location,
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (mlUsed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryOrange
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.primaryOrange
                                                .withOpacity(0.5)),
                                      ),
                                      child: const Text('AI',
                                          style: TextStyle(
                                              color: AppColors.primaryOrange,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(item['created_at'] as String?),
                                style: const TextStyle(
                                    color: AppColors.textGrey, fontSize: 12),
                              ),
                              const SizedBox(height: 16),

                              // Metrics grid
                              Row(
                                children: [
                                  _metricChip(
                                    icon: Icons.solar_power,
                                    label: 'System Size',
                                    value: '${size.toStringAsFixed(1)} kW',
                                    color: AppColors.primaryOrange,
                                  ),
                                  const SizedBox(width: 10),
                                  _metricChip(
                                    icon: Icons.bolt,
                                    label: 'Daily Gen.',
                                    value:
                                        '${daily.toStringAsFixed(1)} kWh',
                                    color: const Color(0xFF60A5FA),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _metricChip(
                                    icon: Icons.attach_money,
                                    label: 'Est. Cost',
                                    value:
                                        '₨${(cost / 1000).toStringAsFixed(0)}k',
                                    color: AppColors.costGreen,
                                  ),
                                  const SizedBox(width: 10),
                                  _metricChipWithIndicator(
                                    label: 'Feasibility',
                                    score: score,
                                    color: _feasibilityColor(score),
                                  ),
                                ],
                              ),

                              if (segment.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        color: AppColors.textGrey, size: 14),
                                    const SizedBox(width: 6),
                                    const Text('Profile: ',
                                        style: TextStyle(
                                            color: AppColors.textGrey,
                                            fontSize: 12)),
                                    Text(segment,
                                        style: const TextStyle(
                                            color: AppColors.primaryOrange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                              
                              if (monthlyBill > 0 || monthlyIncome > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (monthlyBill > 0) ...[
                                      const Icon(Icons.receipt_long, color: AppColors.textGrey, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Bill: PKR ${monthlyBill.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                                      const SizedBox(width: 12),
                                    ],
                                    if (monthlyIncome > 0) ...[
                                      const Icon(Icons.account_balance_wallet, color: AppColors.textGrey, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Income: PKR ${monthlyIncome.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ],

                              if (recommendation.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.textWhite.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.primaryOrange.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.lightbulb_outline,
                                              color: AppColors.primaryOrange, size: 14),
                                          SizedBox(width: 6),
                                          Text('AI Recommendation',
                                              style: TextStyle(
                                                  color: AppColors.primaryOrange,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (recommendation['System_Type'] != null)
                                        _recRow('System Type', recommendation['System_Type'].toString()),
                                      if (recommendation['Recommended_Size_kW'] != null)
                                        _recRow('Ideal Size', '${recommendation['Recommended_Size_kW']} kW'),
                                      if (recommendation['Battery'] != null)
                                        _recRow('Battery', recommendation['Battery'].toString()),
                                      if (recommendation['Advice'] != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          recommendation['Advice'].toString(),
                                          style: TextStyle(
                                              color: AppColors.textWhite.withOpacity(0.8),
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              if (recommendation['Vendors'] != null && (recommendation['Vendors'] as List).isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text('Local Vendors',
                                    style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ...(recommendation['Vendors'] as List).take(2).map((vendor) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundDark.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppColors.primaryOrange,
                                          child: Icon(Icons.storefront, color: Colors.white, size: 14),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(vendor['name'].toString(),
                                                  style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 12)),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star, color: Colors.amber, size: 10),
                                                  const SizedBox(width: 2),
                                                  Text(vendor['rating'].toString(), style: const TextStyle(color: AppColors.textGrey, fontSize: 10)),
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.phone, color: AppColors.textGrey, size: 10),
                                                  const SizedBox(width: 2),
                                                  Text(vendor['phone'].toString(), style: const TextStyle(color: AppColors.textGrey, fontSize: 10)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('₨${(((vendor['estimated_total_cost'] as num?) ?? 0) / 1000).toStringAsFixed(0)}k',
                                                style: const TextStyle(color: AppColors.costGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _metricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 10)),
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChipWithIndicator({
    required String label,
    required double score,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 4,
                backgroundColor: AppColors.textWhite.withOpacity(0.1),
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 10)),
                Text('${score.toStringAsFixed(0)}/100',
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  color: AppColors.textWhite.withOpacity(0.6), fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

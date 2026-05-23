import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';
import '../services/user_data_service.dart';

// --- Vendor Data Model ---
class SolarVendor {
  final String name;
  final String rating;
  final int reviewsCount;
  final double startingRatePerKw; // in PKR
  final List<String> locations;
  final List<String> panelBrands;
  final List<String> inverterBrands;
  final int yearsOfExperience;
  final bool providesNetMetering;
  final bool tier1Installer;
  final String contactPhone;
  final String contactEmail;
  final String officeAddress;
  final String bio;

  const SolarVendor({
    required this.name,
    required this.rating,
    required this.reviewsCount,
    required this.startingRatePerKw,
    required this.locations,
    required this.panelBrands,
    required this.inverterBrands,
    required this.yearsOfExperience,
    required this.providesNetMetering,
    required this.tier1Installer,
    required this.contactPhone,
    required this.contactEmail,
    required this.officeAddress,
    required this.bio,
  });
}

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Stateful Variables
  List<SolarVendor> _loadedVendors = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCity = "All Cities";
  String _selectedBrand = "All Brands";
  String _searchQuery = "";

  List<String> get _cities => [
    "All Cities",
    "Karachi",
    "Lahore",
    "Islamabad",
    "Multan",
    "Faisalabad",
    "Peshawar"
  ];

  List<String> get _brands => [
    "All Brands",
    "Longi",
    "Canadian Solar",
    "JA Solar",
    "Trina Solar",
    "Jinko Solar",
    "Huawei",
    "Growatt",
    "Inverex",
    "Knox"
  ];

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Dynamic Fetch Method ---
  Future<void> _fetchVendors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> data = await UserDataService.getVendors();
      
      if (data.isEmpty) {
        setState(() {
          _errorMessage = "No vendor listings could be retrieved from the server.";
          _isLoading = false;
        });
        return;
      }

      final List<SolarVendor> mapped = data.map((v) {
        return SolarVendor(
          name: v['name'] ?? 'Unknown Installer',
          rating: v['rating'] ?? '4.5',
          reviewsCount: v['reviews_count'] ?? 0,
          startingRatePerKw: (v['starting_rate_per_kw'] as num?)?.toDouble() ?? 280000.0,
          locations: List<String>.from(v['locations'] ?? []),
          panelBrands: List<String>.from(v['panel_brands'] ?? []),
          inverterBrands: List<String>.from(v['inverter_brands'] ?? []),
          yearsOfExperience: v['years_of_experience'] ?? 5,
          providesNetMetering: v['provides_net_metering'] ?? false,
          tier1Installer: v['tier_1_installer'] ?? false,
          contactPhone: v['contact_phone'] ?? 'N/A',
          contactEmail: v['contact_email'] ?? 'N/A',
          officeAddress: v['office_address'] ?? 'N/A',
          bio: v['bio'] ?? 'No biography available.',
        );
      }).toList();

      setState(() {
        _loadedVendors = mapped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error. Make sure backend is running.";
        _isLoading = false;
      });
    }
  }

  // --- Filtering Logic ---
  List<SolarVendor> get _filteredVendors {
    return _loadedVendors.where((vendor) {
      // Search matching
      final matchesSearch = vendor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.officeAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.panelBrands.any((b) => b.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          vendor.inverterBrands.any((b) => b.toLowerCase().contains(_searchQuery.toLowerCase()));

      // City matching
      final matchesCity = _selectedCity == "All Cities" ||
          vendor.locations.contains(_selectedCity);

      // Brand matching
      final matchesBrand = _selectedBrand == "All Brands" ||
          vendor.panelBrands.contains(_selectedBrand) ||
          vendor.inverterBrands.contains(_selectedBrand);

      return matchesSearch && matchesCity && matchesBrand;
    }).toList();
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.store,
                color: AppColors.primaryOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solar Vendor Directory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                Text(
                  'Verified Installers & Rates',
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
      body: Column(
        children: [
          // --- Search & Filters Section ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textWhite),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search vendors, brands, or cities...',
                    hintStyle: const TextStyle(color: AppColors.textGrey),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textGrey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.darkBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // City Filter List
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      final isSelected = city == _selectedCity;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(city),
                          selected: isSelected,
                          selectedColor: AppColors.primaryOrange,
                          backgroundColor: AppColors.darkBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.textDark : AppColors.textWhite,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCity = city;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Brand Filter List
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _brands.length,
                    itemBuilder: (context, index) {
                      final brand = _brands[index];
                      final isSelected = brand == _selectedBrand;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(brand),
                          selected: isSelected,
                          selectedColor: AppColors.primaryOrange.withOpacity(0.8),
                          backgroundColor: AppColors.darkBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.textDark : AppColors.textWhite,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedBrand = brand;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- Vendor List / Loading / Error UI ---
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  // --- Dynamic Body Routing ---
  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primaryOrange,
            ),
            SizedBox(height: 16),
            Text(
              "Retrieving live installers...",
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Database Connection Issue',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchVendors,
                icon: const Icon(Icons.refresh, color: AppColors.textDark),
                label: const Text(
                  'Retry Fetching',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredVendors.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: _filteredVendors.length,
      itemBuilder: (context, index) {
        final vendor = _filteredVendors[index];
        return _buildVendorCard(vendor);
      },
    );
  }

  // --- Empty State Widget ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 64,
            color: AppColors.textGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Vendors Found',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search filters or text query.',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // --- Vendor Card Widget ---
  Widget _buildVendorCard(SolarVendor vendor) {
    return Card(
      color: AppColors.darkBlue,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        onTap: () => _showVendorDetails(vendor),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Ratings
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              vendor.rating,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${vendor.reviewsCount} reviews)',
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (vendor.tier1Installer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryOrange, width: 0.5),
                      ),
                      child: const Text(
                        'Tier 1 Installer',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),

              // Rates and Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avg Installed Rate',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₨ ${(vendor.startingRatePerKw / 1000).toStringAsFixed(0)}k / kW',
                        style: const TextStyle(
                          color: AppColors.costGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Experience',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vendor.yearsOfExperience}+ Years',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Metering',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            vendor.providesNetMetering
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: vendor.providesNetMetering ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vendor.providesNetMetering ? 'Yes' : 'No',
                            style: TextStyle(
                              color: vendor.providesNetMetering ? Colors.green : Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Brands Chips Line
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, color: AppColors.textGrey, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Panel Brands: ',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                  ),
                  Expanded(
                    child: Text(
                      vendor.panelBrands.join(', '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.electrical_services, color: AppColors.textGrey, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Inverters: ',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                  ),
                  Expanded(
                    child: Text(
                      vendor.inverterBrands.join(', '),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Show Vendor Details Bottom Sheet ---
  void _showVendorDetails(SolarVendor vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXLarge)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _VendorDetailSheet(vendor: vendor, scrollController: scrollController);
          },
        );
      },
    );
  }
}

// --- Nested Interactive Detail Sheet Component ---
class _VendorDetailSheet extends StatefulWidget {
  final SolarVendor vendor;
  final ScrollController scrollController;

  const _VendorDetailSheet({
    required this.vendor,
    required this.scrollController,
  });

  @override
  State<_VendorDetailSheet> createState() => _VendorDetailSheetState();
}

class _VendorDetailSheetState extends State<_VendorDetailSheet> {
  double _requestedKw = 5.0;

  @override
  Widget build(BuildContext context) {
    final double calculatedCost = _requestedKw * widget.vendor.startingRatePerKw;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Drag handle indicator
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Verification Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vendor.name,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.vendor.yearsOfExperience} Years Certified Partner',
                      style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Rating Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge(Icons.star, Colors.amber, widget.vendor.rating, "Rating"),
                _buildStatBadge(Icons.location_on, Colors.redAccent, "${widget.vendor.locations.length} Cities", "Active In"),
                _buildStatBadge(Icons.monetization_on, AppColors.costGreen, "₨${(widget.vendor.startingRatePerKw / 1000).toStringAsFixed(0)}k", "Rate / kW"),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About / Bio
          const Text(
            'About Company',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.vendor.bio,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Technical Offerings
          const Text(
            'Equipment & Brands Provided',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildHardwareRow("Solar Panels", widget.vendor.panelBrands),
          const SizedBox(height: 8),
          _buildHardwareRow("Inverters", widget.vendor.inverterBrands),
          const SizedBox(height: 8),
          _buildNetMeteringRow(),
          const SizedBox(height: 24),

          // --- INTERACTIVE ESTIMATED PRICING CALCULATOR ---
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate, color: AppColors.primaryOrange, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Interactive Vendor Cost Estimator',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select your target solar system size to estimate installation costs with this vendor:',
                  style: TextStyle(color: AppColors.textWhite, fontSize: 12),
                ),
                const SizedBox(height: 8),
                
                // Dynamic System Size Slider
                Row(
                  children: [
                    Text(
                      '${_requestedKw.toStringAsFixed(1)} kW',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _requestedKw,
                        min: 3.0,
                        max: 30.0,
                        divisions: 54,
                        activeColor: AppColors.primaryOrange,
                        inactiveColor: Colors.white12,
                        onChanged: (val) {
                          setState(() {
                            _requestedKw = val;
                          });
                        },
                      ),
                    ),
                    const Text(
                      '30 kW',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                  ],
                ),

                // Calculations Outputs
                const Divider(color: Colors.white10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estimated Invoice Cost:',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
                    Text(
                      '₨ ${_formatNumber(calculatedCost)}',
                      style: const TextStyle(
                        color: AppColors.costGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Annual Savings (Approx):',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                    Text(
                      '₨ ${_formatNumber(calculatedCost * 0.22)}',
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Details
          const Text(
            'Office Address & Contacts',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoContactRow(Icons.pin_drop, widget.vendor.officeAddress),
          const SizedBox(height: 8),
          _buildInfoContactRow(Icons.phone, widget.vendor.contactPhone),
          const SizedBox(height: 8),
          _buildInfoContactRow(Icons.email, widget.vendor.contactEmail),
          const SizedBox(height: 32),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling ${widget.vendor.name} at ${widget.vendor.contactPhone}...'),
                        backgroundColor: AppColors.primaryOrange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone, color: AppColors.textDark),
                  label: const Text(
                    'Call Now',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening email draft to ${widget.vendor.contactEmail}...'),
                        backgroundColor: AppColors.darkBlue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.email, color: AppColors.textWhite),
                  label: const Text(
                    'Get Quote',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textWhite),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Formatting Helpers ---
  String _formatNumber(double num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(2)} Million';
    } else {
      return '${(num / 1000).toStringAsFixed(0)}k';
    }
  }

  // --- UI Construction Helpers ---
  Widget _buildStatBadge(IconData icon, Color color, String value, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareRow(String title, List<String> list) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: list.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNetMeteringRow() {
    return Row(
      children: [
        const SizedBox(
          width: 90,
          child: Text(
            "Net Metering",
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
        ),
        Icon(
          widget.vendor.providesNetMetering ? Icons.check_circle : Icons.cancel,
          color: widget.vendor.providesNetMetering ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          widget.vendor.providesNetMetering 
              ? "NEPRA Certified Installer (Assistance Provided)" 
              : "No Direct Net Metering Processing Assistance",
          style: TextStyle(
            color: widget.vendor.providesNetMetering ? Colors.green : Colors.red,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoContactRow(IconData icon, String info) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            info,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
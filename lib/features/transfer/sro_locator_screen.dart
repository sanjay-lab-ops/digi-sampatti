import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class SroLocatorScreen extends StatefulWidget {
  const SroLocatorScreen({super.key});

  @override
  State<SroLocatorScreen> createState() => _SroLocatorScreenState();
}

class _SroLocatorScreenState extends State<SroLocatorScreen> {
  String _selectedDistrict = 'Bengaluru Urban';
  String _searchQuery = '';

  static const _districts = [
    'Bengaluru Urban', 'Bengaluru Rural', 'Mysuru', 'Tumakuru', 'Mandya',
    'Ramanagara', 'Hassan', 'Shivamogga', 'Dakshina Kannada', 'Udupi',
    'Belagavi', 'Dharwad', 'Hubballi', 'Vijayapura', 'Kalaburagi',
    'Ballari', 'Raichur', 'Koppala', 'Yadgir', 'Chitradurga',
    'Davangere', 'Haveri', 'Gadag', 'Bagalkote', 'Bidar',
  ];

  static const _sroData = {
    'Bengaluru Urban': [
      _SRO('Bengaluru South', 'No. 15, Lalbagh Road, Bengaluru - 560027',
        '080-22201234', '10:00 AM – 5:30 PM', 'Mon–Sat (2nd Sat holiday)',
        ['Sale Deed', 'Gift Deed', 'Lease', 'Mortgage', 'Partition']),
      _SRO('Bengaluru North', 'Sadashivanagar, Bengaluru - 560080',
        '080-23608421', '10:00 AM – 5:30 PM', 'Mon–Sat (2nd Sat holiday)',
        ['Sale Deed', 'Gift Deed', 'Power of Attorney', 'Agreement to Sell']),
      _SRO('Bengaluru East', 'Indiranagar, Bengaluru - 560038',
        '080-25285678', '10:00 AM – 5:30 PM', 'Mon–Sat (2nd Sat holiday)',
        ['Sale Deed', 'Gift Deed', 'Will Registration', 'GPA']),
      _SRO('Yelahanka', 'Yelahanka New Town, Bengaluru - 560064',
        '080-28460123', '10:00 AM – 5:30 PM', 'Mon–Sat (2nd Sat holiday)',
        ['Sale Deed', 'Gift Deed', 'Lease', 'Agreement']),
      _SRO('KR Puram', 'KR Puram, Bengaluru - 560036',
        '080-25606712', '10:00 AM – 5:30 PM', 'Mon–Sat (2nd Sat holiday)',
        ['Sale Deed', 'Gift Deed', 'Mortgage']),
    ],
    'Mysuru': [
      _SRO('Mysuru City', 'Nazarbad, Mysuru - 570010',
        '0821-2422567', '10:00 AM – 5:30 PM', 'Mon–Sat (2nd Sat holiday)',
        ['Sale Deed', 'Gift Deed', 'Will', 'Partition']),
      _SRO('Mysuru Rural', 'T Narasipur Road, Mysuru - 570019',
        '0821-2402134', '10:00 AM – 5:30 PM', 'Mon–Sat (2nd Sat holiday)',
        ['Sale Deed', 'Agricultural Land', 'Gift Deed']),
    ],
    'Tumakuru': [
      _SRO('Tumakuru', 'B H Road, Tumakuru - 572101',
        '0816-2277890', '10:00 AM – 5:30 PM', 'Mon–Sat (2nd Sat holiday)',
        ['Sale Deed', 'Gift Deed', 'Lease']),
    ],
  };

  List<_SRO> get _filteredSros {
    final list = _sroData[_selectedDistrict] ?? [];
    if (_searchQuery.isEmpty) return list;
    return list.where((s) =>
      s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s.address.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('SRO Locator')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // District Selector
                const Text('Select District', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDistrict,
                      isExpanded: true,
                      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (v) => setState(() { _selectedDistrict = v!; _searchQuery = ''; }),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Search
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by office name or area...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // Quick actions row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Expanded(child: _quickAction(
                icon: Icons.attach_money,
                label: 'Guidance Value',
                sub: 'Check area GV',
                color: AppColors.teal,
                onTap: () => context.push('/guidance-value'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickAction(
                icon: Icons.calculate_outlined,
                label: 'Stamp Duty',
                sub: 'Calculate cost',
                color: AppColors.arthBlue,
                onTap: () => context.push('/transfer/stamp-duty'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _quickAction(
                icon: Icons.calendar_today_outlined,
                label: 'Book Slot',
                sub: 'Kaveri Online',
                color: AppColors.primary,
                onTap: () async {
                  final uri = Uri.parse('https://kaverionline.karnataka.gov.in');
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              )),
            ]),
          ),

          // Info banner
          Container(
            color: AppColors.surfaceGreen,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registration must happen at the SRO having jurisdiction over the property location. '
                    'Book appointment at kaverionline.karnataka.gov.in before visiting.',
                    style: TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // SRO List
          Expanded(
            child: _filteredSros.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off, size: 48, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text('No offices found for $_selectedDistrict',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('Try the official kaveri2.karnataka.gov.in portal',
                        style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredSros.length,
                  itemBuilder: (context, i) => _buildSroCard(_filteredSros[i]),
                ),
          ),

          // Bottom link
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Online Registration: kaveri2.karnataka.gov.in',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const Text('Book appointment, pre-calculate stamp duty & fees online',
                        style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSroCard(_SRO sro) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SRO — ${sro.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_selectedDistrict,
                        style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: sro.phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone number copied'), duration: Duration(seconds: 1)));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safe.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.copy, size: 12, color: AppColors.safe),
                        const SizedBox(width: 4),
                        Text(sro.phone, style: const TextStyle(fontSize: 11, color: AppColors.safe, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _InfoRow(Icons.location_on, sro.address),
            const SizedBox(height: 6),
            _InfoRow(Icons.access_time, '${sro.timings} | ${sro.days}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: sro.services.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        Text(sub, style: const TextStyle(
            fontSize: 9, color: AppColors.textLight)),
      ]),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
      ],
    );
  }
}

class _SRO {
  final String name;
  final String address;
  final String phone;
  final String timings;
  final String days;
  final List<String> services;
  const _SRO(this.name, this.address, this.phone, this.timings, this.days, this.services);
}

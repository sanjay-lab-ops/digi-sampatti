import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Field Inspection Booking Screen ─────────────────────────────────────────
// Books an on-ground physical inspection of the property.
// Revenue: ₹2,000–5,000 per inspection (DigiSampatti earns margin).
//
// Inspection covers:
//   • GPS-stamped site photos
//   • Boundary measurement vs FMB sketch
//   • Encroachment check
//   • Structure condition (if applicable)
//   • Neighbour / occupancy verification
//   • Access road check
// ──────────────────────────────────────────────────────────────────────────────

enum _InspectionStatus { notBooked, booked, inProgress, completed }

final inspectionStatusProvider =
    StateProvider<_InspectionStatus>((ref) => _InspectionStatus.notBooked);

class FieldInspectionScreen extends ConsumerStatefulWidget {
  const FieldInspectionScreen({super.key});
  @override
  ConsumerState<FieldInspectionScreen> createState() =>
      _FieldInspectionScreenState();
}

class _FieldInspectionScreenState
    extends ConsumerState<FieldInspectionScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();
  String _inspectionType = 'basic';
  String _urgency        = 'standard';
  bool   _submitted      = false;
  String? _bookingRef;

  @override
  void initState() {
    super.initState();
    // Pre-fill from scan data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scan = ref.read(currentScanProvider);
      if (scan != null) {
        _addressCtrl.text =
            '${scan.surveyNumber ?? ""} ${scan.village ?? ""} '
            '${scan.taluk ?? ""} ${scan.district ?? ""}';
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  String get _price {
    if (_inspectionType == 'comprehensive') {
      return _urgency == 'urgent' ? '₹5,000' : '₹4,000';
    }
    return _urgency == 'urgent' ? '₹3,000' : '₹2,000';
  }

  void _bookInspection() {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your name and phone number')));
      return;
    }
    // Generate booking reference
    final ref2 = 'INS${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    setState(() {
      _submitted  = true;
      _bookingRef = ref2;
    });
    ref.read(inspectionStatusProvider.notifier).state =
        _InspectionStatus.booked;
    // Send booking via WhatsApp
    _sendWhatsAppBooking(ref2);
  }

  Future<void> _sendWhatsAppBooking(String bookingRef) async {
    final scan  = ref.read(currentScanProvider);
    final msg   =
        'FIELD INSPECTION REQUEST\n'
        'Ref: $bookingRef\n'
        'Name: ${_nameCtrl.text}\n'
        'Phone: ${_phoneCtrl.text}\n'
        'Property: ${_addressCtrl.text}\n'
        'Type: $_inspectionType\n'
        'Urgency: $_urgency\n'
        'Price: $_price\n'
        '${_notesCtrl.text.isNotEmpty ? "Notes: ${_notesCtrl.text}" : ""}';

    // Share via share sheet (user can send via WhatsApp)
    await Share.share(msg, subject: 'DigiSampatti Inspection Request $bookingRef');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Field Inspection'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerBanner(),
            const SizedBox(height: 20),

            if (!_submitted) ...[
              _buildWhatWeCover(),
              const SizedBox(height: 20),
              _buildBookingForm(),
            ] else
              _buildConfirmation(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _headerBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF263238)]),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.location_searching, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Text('Physical Site Inspection',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        const Text(
          'A trained field agent visits the property and sends '
          'GPS-stamped photos, boundary measurements, and a written '
          'inspection report within 24–48 hours.',
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _pill('📍 GPS Stamped'),
          const SizedBox(width: 8),
          _pill('📐 Boundary Check'),
          const SizedBox(width: 8),
          _pill('📸 40+ Photos'),
        ]),
      ],
    ),
  );

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text,
        style: const TextStyle(color: Colors.white, fontSize: 11)),
  );

  Widget _buildWhatWeCover() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What the inspection covers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        ...[
          ('📍', 'GPS coordinates of all 4 corners of the plot',
           'Confirms plot location matches RTC/FMB sketch'),
          ('📐', 'Boundary measurement',
           'Physical dimensions vs sanctioned plan — flags encroachments'),
          ('👀', 'Encroachment check',
           'Are neighbours built on your land? Is there a wall, compound, or structure crossing the boundary?'),
          ('🏠', 'Structure condition (if house)',
           'Visible cracks, waterproofing, electrical, slab age estimate'),
          ('🚶', 'Access road verification',
           'Is there a usable road to the property? Private road — does seller own it?'),
          ('👤', 'Occupancy / tenant check',
           'Who is actually on the land? Any squatters, tenants, caretakers?'),
          ('📷', '40+ geotagged photos',
           'All 4 sides, entrance, boundary markers, road access, surroundings'),
          ('📄', 'Written inspection report',
           'Delivered within 48 hours — shareable with bank and lawyer'),
        ].map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(item.$1, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$2, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
                Text(item.$3, style: const TextStyle(
                    fontSize: 11, color: Colors.black54, height: 1.3)),
              ],
            )),
          ]),
        )),
      ],
    ),
  );

  Widget _buildBookingForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Book Inspection',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 12),

      // Inspection type
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inspection Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            _typeOption('basic', 'Basic Inspection — ₹2,000',
                'GPS photos, boundary check, occupancy, road access'),
            const SizedBox(height: 8),
            _typeOption('comprehensive', 'Comprehensive — ₹4,000',
                'All basic + detailed structure report + soil type + legal opinion summary'),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Urgency
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('When do you need it?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            _urgencyOption('standard', 'Standard — 48 hours', '+ ₹0 extra'),
            const SizedBox(height: 8),
            _urgencyOption('urgent', 'Urgent — 24 hours', '+ ₹1,000 extra'),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Contact form
      _field(_nameCtrl, 'Your Name', Icons.person),
      _field(_phoneCtrl, 'Phone Number', Icons.phone,
          keyboardType: TextInputType.phone),
      _field(_addressCtrl, 'Property Address / Survey Details',
          Icons.location_on, maxLines: 2),
      _field(_notesCtrl, 'Special Instructions (optional)',
          Icons.notes, maxLines: 2),

      const SizedBox(height: 16),

      // Price summary
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF37474F).withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF37474F).withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.receipt_outlined,
              color: Color(0xFF37474F), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Total: $_price',
                style: const TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 16, color: Color(0xFF37474F))),
          ),
          const Text('Pay on confirmation',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _bookInspection,
          icon: const Icon(Icons.calendar_today_outlined),
          label: const Text('Book Inspection'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF37474F),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ),
    ],
  );

  Widget _typeOption(String value, String title, String subtitle) =>
    InkWell(
      onTap: () => setState(() => _inspectionType = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _inspectionType == value
              ? const Color(0xFF37474F).withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _inspectionType == value
                ? const Color(0xFF37474F) : Colors.grey.shade300,
          ),
        ),
        child: Row(children: [
          Radio<String>(
            value: value,
            groupValue: _inspectionType,
            onChanged: (v) => setState(() => _inspectionType = v!),
            activeColor: const Color(0xFF37474F),
          ),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle, style: const TextStyle(
                  fontSize: 11, color: Colors.black54)),
            ],
          )),
        ]),
      ),
    );

  Widget _urgencyOption(String value, String title, String extra) =>
    InkWell(
      onTap: () => setState(() => _urgency = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _urgency == value
              ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _urgency == value ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(children: [
          Radio<String>(
            value: value,
            groupValue: _urgency,
            onChanged: (v) => setState(() => _urgency = v!),
            activeColor: AppColors.primary,
          ),
          Expanded(child: Text(title, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13))),
          Text(extra, style: const TextStyle(
              fontSize: 12, color: AppColors.textLight)),
        ]),
      ),
    );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );

  Widget _buildConfirmation() => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle,
                color: AppColors.primary, size: 48),
            const SizedBox(height: 12),
            const Text('Inspection Booked!',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 6),
            Text('Booking Ref: $_bookingRef',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 16),
            const Text(
              'Our team will contact you within 2 hours to confirm '
              'the inspection appointment.\n\n'
              'You will receive:\n'
              '• WhatsApp confirmation from inspector\n'
              '• GPS-stamped photos after inspection\n'
              '• Written report within 48 hours',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _sendWhatsAppBooking(_bookingRef!),
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share Booking Details'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _nextStepCard(),
    ],
  );

  Widget _nextStepCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('While you wait — do these:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        ...[
          'Run Seller KYC check if not done yet',
          'Check BBMP property tax arrears',
          'Book a lawyer review via Expert Help',
          'Prepare advance payment (keep in your account, not given to seller yet)',
        ].asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(
              width: 20, height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: Text('${e.key + 1}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(e.value,
                style: const TextStyle(fontSize: 12))),
          ]),
        )),
      ],
    ),
  );
}

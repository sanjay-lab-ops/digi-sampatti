import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/professional_model.dart';
import 'package:digi_sampatti/core/services/professional_service.dart';

class ProfessionalRegisterScreen extends ConsumerStatefulWidget {
  const ProfessionalRegisterScreen({super.key});

  @override
  ConsumerState<ProfessionalRegisterScreen> createState() =>
      _ProfessionalRegisterScreenState();
}

class _ProfessionalRegisterScreenState
    extends ConsumerState<ProfessionalRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProfessionalService();

  // Step tracking
  int _step = 0; // 0=type, 1=identity, 2=service, 3=profile, 4=done

  // Form fields
  ProfessionalType? _selectedType;
  final _nameCtrl = TextEditingController();
  final _firmCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _feeNoteCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  int _yearsExp = 1;
  final List<String> _selectedDistricts = [];
  final List<String> _selectedLanguages = ['Kannada'];

  File? _licenseImage;
  File? _profilePhoto;
  bool _isSubmitting = false;
  String? _submitError;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose(); _firmCtrl.dispose(); _licenseCtrl.dispose();
    _bioCtrl.dispose(); _feeCtrl.dispose(); _feeNoteCtrl.dispose();
    _upiCtrl.dispose(); _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _licenseImage = File(picked.path));
  }

  Future<void> _pickProfilePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _profilePhoto = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) return;
    if (_selectedDistricts.isEmpty) {
      setState(() => _submitError = 'Select at least one district you serve');
      return;
    }

    setState(() { _isSubmitting = true; _submitError = null; });

    final error = await _service.register(
      type: _selectedType!,
      fullName: _nameCtrl.text.trim(),
      firmName: _firmCtrl.text.trim().isEmpty ? null : _firmCtrl.text.trim(),
      licenseNumber: _licenseCtrl.text.trim(),
      districtsServed: _selectedDistricts,
      yearsExperience: _yearsExp,
      feeAmount: double.tryParse(_feeCtrl.text.trim()),
      feeNote: _feeNoteCtrl.text.trim().isEmpty ? null : _feeNoteCtrl.text.trim(),
      languages: _selectedLanguages,
      bio: _bioCtrl.text.trim(),
      upiId: _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
      whatsappNumber: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
      licenseImageFile: _licenseImage,
      profilePhotoFile: _profilePhoto,
    );

    setState(() => _isSubmitting = false);

    if (error != null) {
      setState(() => _submitError = error);
    } else {
      setState(() => _step = 4); // success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register as Partner'),
        leading: _step > 0 && _step < 4
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: _step == 4 ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_step + 1) / 4,
          backgroundColor: AppColors.borderColor,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 3,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: [
                  _buildStep0TypeSelect(),
                  _buildStep1Identity(),
                  _buildStep2Service(),
                  _buildStep3Profile(),
                ][_step],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 0: Select Professional Type ──────────────────────────────────────
  Widget _buildStep0TypeSelect() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What is your profession?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 6),
        const Text('Select the type that best describes your work.',
            style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        const SizedBox(height: 20),
        ...ProfessionalType.values.map((type) => _buildTypeCard(type)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedType == null
                ? null
                : () => setState(() => _step = 1),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(ProfessionalType type) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(type),
                  color: selected ? AppColors.primary : AppColors.textLight, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.primary : AppColors.textDark)),
                  Text(_typeSubtitle(type),
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Identity & License ─────────────────────────────────────────────
  Widget _buildStep1Identity() {
    final type = _selectedType!;
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Identity', style: _sectionStyle()),
        const SizedBox(height: 6),
        const Text('This information is verified by DigiSampatti before your profile goes live.',
            style: TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 20),
        _field('Full Name *', _nameCtrl, 'As on your ID / license',
            validator: (v) => (v == null || v.trim().length < 3) ? 'Enter your full name' : null),
        const SizedBox(height: 14),
        _field('Firm / Company Name', _firmCtrl, 'Optional — leave blank if individual'),
        const SizedBox(height: 14),
        _field('${type.licenseLabel} *', _licenseCtrl, type.licenseHint,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your license/registration number' : null),
        const SizedBox(height: 16),
        // License image upload
        _buildImageUpload(
          label: 'Upload License / Certificate Photo *',
          subtitle: 'JPG or PNG — only visible to DigiSampatti admin for verification',
          icon: Icons.upload_file,
          file: _licenseImage,
          onTap: _pickLicenseImage,
        ),
        const SizedBox(height: 24),
        _buildNavButton('Continue to Services'),
      ],
    );
  }

  // ── Step 2: Service Details ────────────────────────────────────────────────
  Widget _buildStep2Service() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Details', style: _sectionStyle()),
        const SizedBox(height: 20),
        // Years of experience
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Years of Experience', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _yearsExp = (_yearsExp - 1).clamp(1, 50)),
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                ),
                Text('$_yearsExp', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => _yearsExp = (_yearsExp + 1).clamp(1, 50)),
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
        const Divider(height: 24),
        // Fee
        _field(_selectedType!.feeLabel, _feeCtrl, '0', inputType: TextInputType.number),
        const SizedBox(height: 10),
        _field('Fee note (shown to buyers)', _feeNoteCtrl,
            'e.g. "₹500 for first consultation, site visit extra"'),
        const Divider(height: 24),
        // Districts
        const Text('Districts You Serve *',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Buyers in these districts will see your profile.',
            style: TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: kKarnatakaDistricts.map((d) {
            final sel = _selectedDistricts.contains(d);
            return FilterChip(
              label: Text(d, style: TextStyle(
                  fontSize: 11,
                  color: sel ? AppColors.primary : AppColors.textMedium)),
              selected: sel,
              onSelected: (v) => setState(() {
                if (v) _selectedDistricts.add(d);
                else _selectedDistricts.remove(d);
              }),
              selectedColor: AppColors.primary.withOpacity(0.12),
              checkmarkColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(color: sel ? AppColors.primary : AppColors.borderColor),
            );
          }).toList(),
        ),
        const Divider(height: 24),
        // Languages
        const Text('Languages You Speak *',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: kLanguages.map((lang) {
            final sel = _selectedLanguages.contains(lang);
            return FilterChip(
              label: Text(lang, style: TextStyle(
                  fontSize: 12,
                  color: sel ? AppColors.primary : AppColors.textMedium)),
              selected: sel,
              onSelected: (v) => setState(() {
                if (v) _selectedLanguages.add(lang);
                else if (_selectedLanguages.length > 1) _selectedLanguages.remove(lang);
              }),
              selectedColor: AppColors.primary.withOpacity(0.12),
              checkmarkColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(color: sel ? AppColors.primary : AppColors.borderColor),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildNavButton('Continue to Profile'),
      ],
    );
  }

  // ── Step 3: Profile & Payment ──────────────────────────────────────────────
  Widget _buildStep3Profile() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Profile', style: _sectionStyle()),
        const SizedBox(height: 6),
        const Text('This is what buyers see when they find you.',
            style: TextStyle(color: AppColors.textLight, fontSize: 12)),
        const SizedBox(height: 20),
        // Profile photo
        _buildImageUpload(
          label: 'Profile Photo',
          subtitle: 'Shown to buyers — clear face photo builds trust',
          icon: Icons.person_outline,
          file: _profilePhoto,
          onTap: _pickProfilePhoto,
        ),
        const SizedBox(height: 14),
        // Bio
        TextFormField(
          controller: _bioCtrl,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'About You *',
            hintText: 'Describe your expertise, notable work, and how you help buyers...',
            alignLabelWithHint: true,
          ),
          validator: (v) => (v == null || v.trim().length < 20)
              ? 'Write at least 20 characters about yourself'
              : null,
        ),
        const SizedBox(height: 14),
        // WhatsApp
        _field('WhatsApp Number', _whatsappCtrl, '9876543210',
            prefix: '+91 ', inputType: TextInputType.phone),
        const SizedBox(height: 6),
        const Text('Buyers can contact you directly on WhatsApp',
            style: TextStyle(fontSize: 11, color: AppColors.textLight)),
        const SizedBox(height: 14),
        // UPI
        _field('UPI ID (for payments)', _upiCtrl, 'yourname@upi'),
        const SizedBox(height: 6),
        const Text('Buyers can pay you directly via UPI',
            style: TextStyle(fontSize: 11, color: AppColors.textLight)),
        const SizedBox(height: 24),
        // Security notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security, color: Color(0xFF5C35CC), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your license and ID are encrypted and only visible to DigiSampatti admin during verification. '
                  'Buyers only see your name, photo, district, and rating.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF3D2B8A), height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_submitError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.statusDangerBg,
                borderRadius: BorderRadius.circular(8)),
            child: Text(_submitError!,
                style: const TextStyle(color: AppColors.statusDangerText, fontSize: 12)),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Application'),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'By submitting you agree to DigiSampatti partner terms.\n'
            'We will verify your credentials and call you within 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_step == 1) {
            if (_nameCtrl.text.trim().length < 3 || _licenseCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all required fields')));
              return;
            }
          }
          setState(() => _step++);
        },
        child: Text(label),
      ),
    );
  }

  // ── Success Screen ─────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Application Submitted!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            const Text(
              'Our team will verify your credentials within 24 hours and call you on your registered number.\n\n'
              'Once approved, your profile will be visible to property buyers across Karnataka.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What happens next:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B5800))),
                  SizedBox(height: 8),
                  _Step(n: '1', text: 'We verify your license with the issuing authority'),
                  _Step(n: '2', text: 'We call you to confirm your service area and fee'),
                  _Step(n: '3', text: 'Profile goes live — you start getting leads'),
                  _Step(n: '4', text: 'Buyers contact you directly via WhatsApp'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/professional/dashboard'),
              child: const Text('View My Application Status'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildImageUpload({
    required String label,
    required String subtitle,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? AppColors.primary : AppColors.borderColor,
            width: file != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(file, width: 56, height: 56, fit: BoxFit.cover),
              )
            else
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.textLight, size: 28),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  const SizedBox(height: 6),
                  Text(file != null ? 'Tap to replace' : 'Tap to upload',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(file != null ? Icons.check_circle : Icons.upload,
                color: file != null ? AppColors.primary : AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
    String? prefix,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
      ),
      validator: validator,
    );
  }

  TextStyle _sectionStyle() => const TextStyle(
      fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark);

  IconData _typeIcon(ProfessionalType type) {
    switch (type) {
      case ProfessionalType.advocate:      return Icons.gavel;
      case ProfessionalType.broker:        return Icons.real_estate_agent;
      case ProfessionalType.surveyor:      return Icons.straighten;
      case ProfessionalType.vastu:         return Icons.self_improvement;
      case ProfessionalType.interior:      return Icons.design_services;
      case ProfessionalType.packersMovers: return Icons.local_shipping;
      case ProfessionalType.khataAgent:    return Icons.receipt_long;
      case ProfessionalType.bank:          return Icons.account_balance;
      case ProfessionalType.developer:     return Icons.apartment;
    }
  }

  String _typeSubtitle(ProfessionalType type) {
    switch (type) {
      case ProfessionalType.advocate:      return 'Property due-diligence, title search, registration';
      case ProfessionalType.broker:        return 'RERA registered agent — site visits, deals';
      case ProfessionalType.surveyor:      return 'Boundary verification, FMB comparison';
      case ProfessionalType.vastu:         return 'Vastu compliance for new site or flat';
      case ProfessionalType.interior:      return 'Home interiors after purchase';
      case ProfessionalType.packersMovers: return 'Shifting service in Karnataka';
      case ProfessionalType.khataAgent:    return 'BBMP Khata transfer, Bhoomi mutation';
      case ProfessionalType.bank:          return 'Home loan, LAP, mortgage advisory';
      case ProfessionalType.developer:     return 'List your RERA-registered project';
    }
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            margin: const EdgeInsets.only(top: 1, right: 8),
            decoration: const BoxDecoration(color: Color(0xFFFFD54F), shape: BoxShape.circle),
            child: Center(child: Text(n,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7B5800)))),
          ),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF5C4000), height: 1.4))),
        ],
      ),
    );
  }
}

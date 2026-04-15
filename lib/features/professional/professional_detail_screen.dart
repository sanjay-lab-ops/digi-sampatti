import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/professional_model.dart';
import 'package:digi_sampatti/core/services/professional_service.dart';

class ProfessionalDetailScreen extends ConsumerStatefulWidget {
  final String professionalUid;
  final Map<String, dynamic>? reportContext; // pass district/survey from report

  const ProfessionalDetailScreen({
    super.key,
    required this.professionalUid,
    this.reportContext,
  });

  @override
  ConsumerState<ProfessionalDetailScreen> createState() =>
      _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState
    extends ConsumerState<ProfessionalDetailScreen> {
  ProfessionalProfile? _profile;
  bool _loading = true;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProfessionalService().getProfile(widget.professionalUid);
    if (mounted) setState(() { _profile = p; _loading = false; });
  }

  Future<void> _sendRequest() async {
    setState(() => _sending = true);
    final ok = await ProfessionalService().sendLeadRequest(
      professionalUid: widget.professionalUid,
      surveyNumber: widget.reportContext?['surveyNumber'],
      district: widget.reportContext?['district'],
    );
    setState(() { _sending = false; _sent = ok; });
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent! They will contact you within 2 hours.'),
          backgroundColor: AppColors.safe,
        ),
      );
    }
  }

  Future<void> _callWhatsApp(String number) async {
    final num = number.replaceAll('+91', '').replaceAll(' ', '');
    final url = Uri.parse('https://wa.me/91$num');
    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String number) async {
    final url = Uri.parse('tel:+91$number');
    if (await canLaunchUrl(url)) launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Professional')),
        body: const Center(child: Text('Profile not found')),
      );
    }
    final p = _profile!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(p),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildVerifiedBadge(p),
                const SizedBox(height: 16),
                _buildInfoGrid(p),
                const SizedBox(height: 16),
                _buildSection('About', p.bio),
                const SizedBox(height: 16),
                _buildDistrictsSection(p),
                const SizedBox(height: 16),
                _buildFeeSection(p),
                const SizedBox(height: 24),
                _buildContactButtons(p),
                const SizedBox(height: 16),
                _buildRequestButton(),
                const SizedBox(height: 12),
                _buildReviewSection(p),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(ProfessionalProfile p) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => Share.share(
            '${p.fullName} — ${p.type.label}\n'
            'Serving: ${p.districtsServed.join(", ")}\n'
            'Rating: ${p.rating}/5 · ${p.yearsExperience} years experience\n\n'
            'Found via DigiSampatti',
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.safe],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Profile photo
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                child: ClipOval(
                  child: p.profilePhotoUrl != null
                      ? Image.network(p.profilePhotoUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, size: 48, color: Colors.white))
                      : Container(
                          color: Colors.white24,
                          child: Center(
                            child: Text(p.fullName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 32,
                                    fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(p.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(p.type.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD54F), size: 14),
                  const SizedBox(width: 4),
                  Text('${p.rating} (${p.reviewCount} reviews)',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        title: Text(p.fullName,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildVerifiedBadge(ProfessionalProfile p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verified by DigiSampatti · License ${p.licenseNumber}',
              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(ProfessionalProfile p) {
    return Row(
      children: [
        _infoBox('${p.yearsExperience}+', 'Years Exp', Icons.timeline_outlined),
        const SizedBox(width: 10),
        _infoBox('${p.leadCount}', 'Clients', Icons.people_outline),
        const SizedBox(width: 10),
        _infoBox(p.languages.take(2).join(', '), 'Languages', Icons.language),
      ],
    );
  }

  Widget _infoBox(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor)),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDistrictsSection(ProfessionalProfile p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Serves These Districts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: p.districtsServed.map((d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSection(ProfessionalProfile p) {
    if (p.feeAmount == null && p.feeNote == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.currency_rupee, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.type.feeLabel,
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                if (p.feeAmount != null)
                  Text('₹${p.feeAmount!.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                if (p.feeNote != null)
                  Text(p.feeNote!, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButtons(ProfessionalProfile p) {
    return Row(
      children: [
        if (p.whatsappNumber != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _callWhatsApp(p.whatsappNumber!),
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                minimumSize: const Size(0, 46),
              ),
            ),
          ),
        if (p.whatsappNumber != null) const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _call(p.phone.replaceAll('+91', '')),
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('Call'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 46),
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestButton() {
    if (_sent) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surfaceGreen,
            borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.safe, size: 20),
            SizedBox(width: 8),
            Text('Request sent! They\'ll call you soon.',
                style: TextStyle(color: AppColors.safe, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sending ? null : _sendRequest,
        icon: _sending
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.send, size: 16),
        label: Text(_sending ? 'Sending...' : 'Request Callback'),
      ),
    );
  }

  Widget _buildReviewSection(ProfessionalProfile p) {
    if (p.reviewCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor)),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFF57C00), size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${p.rating}/5.0',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Based on ${p.reviewCount} reviews',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }
}

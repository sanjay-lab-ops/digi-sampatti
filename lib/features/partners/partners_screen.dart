import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/professional_model.dart';
import 'package:digi_sampatti/core/services/professional_service.dart';
import 'package:digi_sampatti/core/services/callback_service.dart';

// ─── Partners Screen ───────────────────────────────────────────────────────────
// Shows REAL verified professionals from Firestore, grouped by type.
// Falls back to "Request Callback" if no one is registered yet for a category.
// District comes from the report that led here — so results are filtered.

class PartnersScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? reportData;
  const PartnersScreen({super.key, this.reportData});

  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  final _service = ProfessionalService();
  Map<ProfessionalType, List<ProfessionalProfile>>? _professionals;
  bool _loading = true;
  String? _district;

  @override
  void initState() {
    super.initState();
    _district = widget.reportData?['district'] as String?;
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getAllForDistrict(_district)
          .timeout(const Duration(seconds: 10), onTimeout: () => {});
      if (mounted) setState(() { _professionals = data; _loading = false; });
    } catch (_) {
      // Firestore unavailable — show empty state (fallback cards handle this)
      if (mounted) setState(() { _professionals = {}; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Get Expert Help'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/professional/register'),
            icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
            label: const Text('Join as Partner',
                style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_district != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Showing professionals serving $_district',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Legal help
            _buildCategorySection(
              context,
              title: 'Legal Help',
              types: [ProfessionalType.advocate, ProfessionalType.surveyor],
            ),
            const SizedBox(height: 20),
            _buildCategorySection(
              context,
              title: 'Real Estate',
              types: [ProfessionalType.broker, ProfessionalType.developer],
            ),
            const SizedBox(height: 20),
            _buildCategorySection(
              context,
              title: 'Home Loan',
              types: [ProfessionalType.bank],
            ),
            const SizedBox(height: 20),
            _buildCategorySection(
              context,
              title: 'After Purchase',
              types: [
                ProfessionalType.khataAgent,
                ProfessionalType.vastu,
                ProfessionalType.interior,
                ProfessionalType.packersMovers,
              ],
            ),
            const SizedBox(height: 20),
            _buildJoinCTA(context),
            const SizedBox(height: 20),
            _buildDisclaimerCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, {
    required String title,
    required List<ProfessionalType> types,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 12),
        ...types.map((type) => _buildTypeBlock(context, type)),
      ],
    );
  }

  Widget _buildTypeBlock(BuildContext context, ProfessionalType type) {
    if (_loading) return _buildTypeLoading(type);

    final list = _professionals?[type] ?? [];

    if (list.isNotEmpty) {
      // Real professionals — show cards
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(_typeIcon(type), size: 14, color: AppColors.textLight),
                const SizedBox(width: 6),
                Text(type.label,
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${list.length} verified',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _buildProfessionalCard(context, list[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    // No professionals yet — show fallback card
    return _buildFallbackCard(context, type);
  }

  Widget _buildProfessionalCard(BuildContext context, ProfessionalProfile p) {
    return GestureDetector(
      onTap: () => context.push(
        '/professional/${p.uid}',
        extra: widget.reportData,
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)),
                  child: ClipOval(
                    child: p.profilePhotoUrl != null
                        ? Image.network(p.profilePhotoUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback(p))
                        : _avatarFallback(p),
                  ),
                ),
                const Spacer(),
                // Verified badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 9, color: AppColors.primary),
                      SizedBox(width: 2),
                      Text('Verified', style: TextStyle(fontSize: 8,
                          color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(p.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if (p.firmName != null)
              Text(p.firmName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: Color(0xFFF57C00)),
                const SizedBox(width: 3),
                Text('${p.rating}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text('${p.yearsExperience}y',
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 6),
            if (p.feeAmount != null)
              Text('₹${p.feeAmount!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary,
                      fontWeight: FontWeight.w600))
            else
              const Text('Fee on request',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(
                  '/professional/${p.uid}',
                  extra: widget.reportData,
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                child: const Text('Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(ProfessionalProfile p) {
    return Container(
      color: AppColors.primary.withOpacity(0.15),
      child: Center(
        child: Text(p.fullName[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold,
                color: AppColors.primary, fontSize: 16)),
      ),
    );
  }

  Widget _buildFallbackCard(BuildContext context, ProfessionalType type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _typeColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon(type), color: _typeColor(type), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(_typeTagline(type),
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Coming Soon',
                      style: TextStyle(fontSize: 10, color: Colors.orange,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showCallbackSheet(context, type),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Request ${type.label}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                      const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeLoading(ProfessionalType type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Property Digitally Verified ✓',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'All partners are verified by Arth ID — license checked, district confirmed.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCTA(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/professional/register'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.business_center, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Are you a professional?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                          color: AppColors.primary)),
                  SizedBox(height: 2),
                  Text('Register to get leads from verified buyers',
                      style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textLight),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Arth ID verifies professional licenses before listing. '
              'All fees are paid directly to the professional. '
              'Arth ID earns a referral commission per successful connection. '
              'User reviews are collected after service completion.',
              style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showCallbackSheet(BuildContext context, ProfessionalType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CallbackSheet(
        title: 'Request ${type.label}',
        message: 'We\'ll connect you with a verified ${type.label} in '
            '${_district ?? 'your district'} within 2 hours.',
        expertType: _toExpertType(type),
        district: _district,
        surveyNumber: widget.reportData?['surveyNumber'],
      ),
    );
  }

  ExpertType _toExpertType(ProfessionalType t) {
    switch (t) {
      case ProfessionalType.advocate:      return ExpertType.advocate;
      case ProfessionalType.broker:        return ExpertType.advocate;
      case ProfessionalType.surveyor:      return ExpertType.surveyor;
      case ProfessionalType.vastu:         return ExpertType.vastConsultant;
      case ProfessionalType.interior:      return ExpertType.interiorDesigner;
      case ProfessionalType.packersMovers: return ExpertType.packersMovers;
      case ProfessionalType.khataAgent:    return ExpertType.khataAgent;
      case ProfessionalType.bank:          return ExpertType.homeLoan;
      case ProfessionalType.developer:     return ExpertType.developer;
    }
  }

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

  Color _typeColor(ProfessionalType type) {
    switch (type) {
      case ProfessionalType.advocate:      return AppColors.indigo;
      case ProfessionalType.broker:        return AppColors.primary;
      case ProfessionalType.surveyor:      return AppColors.teal;
      case ProfessionalType.vastu:         return const Color(0xFFFF6F00);
      case ProfessionalType.interior:      return const Color(0xFF6A1B9A);
      case ProfessionalType.packersMovers: return const Color(0xFF00695C);
      case ProfessionalType.khataAgent:    return AppColors.info;
      case ProfessionalType.bank:          return AppColors.arthBlue;
      case ProfessionalType.developer:     return AppColors.slate;
    }
  }

  String _typeTagline(ProfessionalType type) {
    switch (type) {
      case ProfessionalType.advocate:      return 'Title search, deed drafting, registration';
      case ProfessionalType.broker:        return 'Site visits, deal negotiation';
      case ProfessionalType.surveyor:      return 'Boundary verification, FMB check';
      case ProfessionalType.vastu:         return 'Direction and layout compliance';
      case ProfessionalType.interior:      return 'Modular kitchen, wardrobes, living';
      case ProfessionalType.packersMovers: return 'Safe insured home shifting';
      case ProfessionalType.khataAgent:    return 'BBMP Khata, Bhoomi mutation';
      case ProfessionalType.bank:          return 'Home loan, LAP, 8.4% p.a. onwards';
      case ProfessionalType.developer:     return 'RERA registered projects';
    }
  }
}

// ─── Callback Sheet (fallback when no professional registered yet) ─────────────
class _CallbackSheet extends StatefulWidget {
  final String title, message;
  final ExpertType expertType;
  final String? district, surveyNumber;

  const _CallbackSheet({
    required this.title, required this.message,
    required this.expertType, this.district, this.surveyNumber,
  });

  @override
  State<_CallbackSheet> createState() => _CallbackSheetState();
}

class _CallbackSheetState extends State<_CallbackSheet> {
  bool _submitting = false, _submitted = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await CallbackService().submitCallbackRequest(
      expertType: widget.expertType,
      district: widget.district,
      surveyNumber: widget.surveyNumber,
    );
    setState(() { _submitting = false; _submitted = ok; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(widget.message,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5)),
          const SizedBox(height: 20),
          if (_submitted)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surfaceGreen, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request Submitted!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        SizedBox(height: 4),
                        Text('Our team calls you within 2 hours.',
                            style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.phone),
                label: Text(_submitting ? 'Submitting...' : 'Request Callback'),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/land_record_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/widgets/common_widgets.dart';
import 'package:digi_sampatti/features/gov_webview/gov_webview_screen.dart';

class LandRecordsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? scanData;
  const LandRecordsScreen({super.key, this.scanData});

  @override
  ConsumerState<LandRecordsScreen> createState() => _LandRecordsScreenState();
}

class _LandRecordsScreenState extends ConsumerState<LandRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRecords());
  }

  Future<void> _fetchRecords() async {
    final data = widget.scanData;
    if (data == null) return;

    await ref.read(propertyCheckNotifierProvider.notifier).fetchLandRecords(
      district: data['district'] ?? '',
      taluk: data['taluk'] ?? '',
      hobli: data['hobli'] ?? '',
      village: data['village'] ?? '',
      surveyNumber: data['surveyNumber'] ?? '',
    );

  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingLandRecordsProvider);
    final landRecord = ref.watch(currentLandRecordProvider);
    final reraRecord = ref.watch(currentReraRecordProvider);
    final error = ref.watch(errorMessageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Land Records')),
      body: isLoading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Fetching from Bhoomi portal...'),
                Text('This may take a moment', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ))
          : error != null
              ? _ErrorView(error: error, onRetry: _fetchRecords)
              : landRecord == null
                  ? const _NoRecordsView()
                  : _RecordsView(
                      landRecord: landRecord,
                      reraRecord: reraRecord,
                      scanData: widget.scanData,
                      onAnalyze: () => context.push('/analysis'),
                    ),
    );
  }
}

// ─── Records View ──────────────────────────────────────────────────────────────
class _RecordsView extends StatelessWidget {
  final LandRecord landRecord;
  final ReraRecord? reraRecord;
  final VoidCallback onAnalyze;
  final Map<String, dynamic>? scanData;

  const _RecordsView({
    required this.landRecord, this.reraRecord, required this.onAnalyze, this.scanData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Verify on Official Portals
          _PortalVerifyCard(scanData: scanData, landRecord: landRecord),
          const SizedBox(height: 4),
          // Survey Header
          _SectionCard(
            title: 'Survey Details',
            icon: Icons.article,
            children: [
              _InfoRow('Survey No.', landRecord.surveyNumber),
              _InfoRow('District', landRecord.district),
              _InfoRow('Taluk', landRecord.taluk),
              _InfoRow('Hobli', landRecord.hobli),
              _InfoRow('Village', landRecord.village),
              if (landRecord.totalAreaAcres != null)
                _InfoRow('Total Area', '${landRecord.totalAreaAcres} acres'),
              if (landRecord.landType != null)
                _InfoRow('Land Type', landRecord.landType!),
            ],
          ),
          const SizedBox(height: 12),

          // Khata Details
          _KhataCard(landRecord: landRecord),
          const SizedBox(height: 12),

          // Owners
          _SectionCard(
            title: 'Owner Details',
            icon: Icons.person,
            children: landRecord.owners.isEmpty
                ? [const _InfoRow('Owner', 'Not found')]
                : landRecord.owners.map((o) => _OwnerTile(owner: o)).toList(),
          ),
          const SizedBox(height: 12),

          // Guidance Value
          if (landRecord.guidanceValuePerSqft != null)
            _GuidanceValueCard(landRecord: landRecord),
          const SizedBox(height: 12),

          // Risk Flags
          _RiskFlagsCard(landRecord: landRecord),
          const SizedBox(height: 12),

          // Encumbrances
          if (landRecord.encumbrances.isNotEmpty) ...[
            _SectionCard(
              title: 'Encumbrance Certificate (EC)',
              icon: Icons.account_balance,
              children: landRecord.encumbrances.map((e) => _EncumbranceTile(entry: e)).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Mutations
          if (landRecord.mutations.isNotEmpty) ...[
            _SectionCard(
              title: 'Mutation History',
              icon: Icons.history,
              children: landRecord.mutations.map((m) => _MutationTile(mutation: m)).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // RERA
          if (reraRecord != null) ...[
            _ReraCard(rera: reraRecord!),
            const SizedBox(height: 12),
          ],

          // CTA
          ElevatedButton.icon(
            onPressed: onAnalyze,
            icon: const Icon(Icons.psychology),
            label: const Text('Run AI Legal Analysis'),
          ),
          const SizedBox(height: 8),
          const Text(
            '₹499 — Pay after analysis',
            style: TextStyle(color: AppColors.textLight, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Khata Card ────────────────────────────────────────────────────────────────
class _KhataCard extends StatelessWidget {
  final LandRecord landRecord;
  const _KhataCard({required this.landRecord});

  @override
  Widget build(BuildContext context) {
    final type = landRecord.khataType;
    final isLegal = type?.isLegal ?? false;
    final color = isLegal ? AppColors.safe : AppColors.warning;
    final bg = isLegal ? AppColors.statusClearBg : AppColors.statusWarningBg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(isLegal ? Icons.check_circle : Icons.warning_amber, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Khata: ${type?.displayName ?? "Unknown"}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                Text(landRecord.khataNumber ?? 'Number not available',
                    style: const TextStyle(fontSize: 13)),
                if (!isLegal && type == KhataType.bKhata)
                  const Text(
                    'B Khata: Not eligible for bank loans or building permits',
                    style: TextStyle(fontSize: 11, color: AppColors.warning),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guidance Value Card ───────────────────────────────────────────────────────
class _GuidanceValueCard extends StatelessWidget {
  final LandRecord landRecord;
  const _GuidanceValueCard({required this.landRecord});

  @override
  Widget build(BuildContext context) {
    final guidance = landRecord.guidanceValuePerSqft!;
    final market = landRecord.estimatedMarketValue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.currency_rupee, color: AppColors.primary, size: 18),
              SizedBox(width: 6),
              Text('Property Value (Estimated)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Guidance Value', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                    Text('₹${guidance.toStringAsFixed(0)}/sqft', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                    const Text('Karnataka Stamp Duty Rate', style: TextStyle(color: AppColors.textLight, fontSize: 10)),
                  ],
                ),
              ),
              if (market != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Market Value (Est.)', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                      Text('₹${market.toStringAsFixed(0)} Lakhs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.safe)),
                      const Text('Based on area & location', style: TextStyle(color: AppColors.textLight, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('* Estimated values. Actual market price may vary. Consult a registered valuer for exact assessment.', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

// ─── Risk Flags Card ───────────────────────────────────────────────────────────
class _RiskFlagsCard extends StatelessWidget {
  final LandRecord landRecord;
  const _RiskFlagsCard({required this.landRecord});

  @override
  Widget build(BuildContext context) {
    final flags = <Map<String, dynamic>>[];
    if (landRecord.isRevenueSite) flags.add({'label': 'Revenue Site', 'risk': true});
    if (landRecord.isGovernmentLand) flags.add({'label': 'Government Land', 'risk': true});
    if (landRecord.isForestLand) flags.add({'label': 'Forest Land', 'risk': true});
    if (landRecord.isLakeBed) flags.add({'label': 'Lake Bed / FTL', 'risk': true});
    if (!landRecord.isRevenueSite && !landRecord.isGovernmentLand &&
        !landRecord.isForestLand && !landRecord.isLakeBed) {
      flags.add({'label': 'No Government Restrictions Found', 'risk': false});
    }

    return _SectionCard(
      title: 'Government Restrictions',
      icon: Icons.gavel,
      children: flags.map((f) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              f['risk'] ? Icons.cancel : Icons.check_circle,
              color: f['risk'] ? AppColors.danger : AppColors.safe,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(f['label'] as String,
                style: TextStyle(
                  color: f['risk'] ? AppColors.danger : AppColors.safe,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      )).toList(),
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark,
                )),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(
              color: AppColors.textMedium, fontSize: 13,
            )),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ),
        ],
      ),
    );
  }
}

class _OwnerTile extends StatelessWidget {
  final LandOwner owner;
  const _OwnerTile({required this.owner});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline, color: AppColors.primary),
      title: Text(owner.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        if (owner.fatherName != null) 'S/O: ${owner.fatherName}',
        if (owner.surveyShare != null) 'Share: ${owner.surveyShare}',
      ].join(' • ')),
    );
  }
}

class _EncumbranceTile extends StatelessWidget {
  final EncumbranceEntry entry;
  const _EncumbranceTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entry.isActive ? Icons.lock : Icons.lock_open,
        color: entry.isActive ? AppColors.danger : AppColors.safe,
      ),
      title: Text('${entry.type} - ${entry.partyName}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text([
        if (entry.bankName != null) entry.bankName!,
        if (entry.amount != null) '₹${entry.amount!.toStringAsFixed(0)}',
        entry.isActive ? 'ACTIVE' : 'Closed',
      ].join(' • ')),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: entry.isActive ? AppColors.statusDangerBg : AppColors.statusClearBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          entry.isActive ? 'Active' : 'Closed',
          style: TextStyle(
            color: entry.isActive ? AppColors.danger : AppColors.safe,
            fontSize: 11, fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MutationTile extends StatelessWidget {
  final MutationEntry mutation;
  const _MutationTile({required this.mutation});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.swap_horiz, color: AppColors.info),
      title: Text(mutation.reason, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text('${mutation.fromOwner} → ${mutation.toOwner}'),
      trailing: mutation.date != null
          ? Text('${mutation.date!.year}', style: const TextStyle(color: AppColors.textLight))
          : null,
    );
  }
}

class _ReraCard extends StatelessWidget {
  final ReraRecord rera;
  const _ReraCard({required this.rera});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'RERA Status',
      icon: Icons.business,
      children: [
        _InfoRow('Registered', rera.isRegistered ? 'Yes ✓' : 'No ✗'),
        if (rera.registrationNumber != null)
          _InfoRow('Reg. Number', rera.registrationNumber!),
        if (rera.projectName != null)
          _InfoRow('Project', rera.projectName!),
        if (rera.promoterName != null)
          _InfoRow('Promoter', rera.promoterName!),
        _InfoRow('Status', rera.projectStatus ?? 'Unknown'),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            const Text('Could not fetch records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: AppColors.textMedium), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRecordsView extends StatelessWidget {
  const _NoRecordsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textLight),
          SizedBox(height: 16),
          Text('No records found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 8),
          Text('Try different survey details or check Bhoomi portal directly',
              style: TextStyle(color: AppColors.textMedium), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Portal Verify Card ────────────────────────────────────────────────────────
class _PortalVerifyCard extends StatelessWidget {
  final Map<String, dynamic>? scanData;
  final LandRecord landRecord;

  const _PortalVerifyCard({this.scanData, required this.landRecord});

  @override
  Widget build(BuildContext context) {
    final survey = landRecord.surveyNumber;
    final district = landRecord.district;
    final taluk = landRecord.taluk;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: AppColors.primary, size: 16),
              SizedBox(width: 6),
              Text('Verify on Official Government Portals',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Open each portal to check real data for this property.',
              style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PortalButton(
                label: 'Bhoomi RTC',
                icon: Icons.article_outlined,
                color: AppColors.primary,
                onTap: () => GovPortalLauncher.open(
                  context, GovPortal.bhoomi,
                  surveyNumber: survey, district: district, taluk: taluk,
                ),
              ),
              _PortalButton(
                label: 'Kaveri EC',
                icon: Icons.account_balance_outlined,
                color: AppColors.arthBlue,
                onTap: () => GovPortalLauncher.open(
                  context, GovPortal.kaveri,
                  surveyNumber: survey, district: district, taluk: taluk,
                ),
              ),
              _PortalButton(
                label: 'RERA',
                icon: Icons.business_outlined,
                color: AppColors.esign,
                onTap: () => GovPortalLauncher.open(context, GovPortal.rera),
              ),
              _PortalButton(
                label: 'eCourts',
                icon: Icons.gavel_outlined,
                color: AppColors.deepOrange,
                onTap: () => GovPortalLauncher.open(context, GovPortal.eCourts),
              ),
              _PortalButton(
                label: 'CERSAI',
                icon: Icons.lock_outline,
                color: AppColors.slate,
                onTap: () => GovPortalLauncher.open(context, GovPortal.cersai),
              ),
              _PortalButton(
                label: 'Dishank Maps',
                icon: Icons.map_outlined,
                color: AppColors.info,
                onTap: () => GovPortalLauncher.open(context, GovPortal.dishank),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortalButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PortalButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, color: Colors.white70, size: 11),
          ],
        ),
      ),
    );
  }
}

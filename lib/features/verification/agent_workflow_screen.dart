import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Agentic Verification Workflow ───────────────────────────────────────────
// Shows 6 AI agents running sequentially on the uploaded property document.
// Each agent animates through: waiting → running → done / flagged.
// ─────────────────────────────────────────────────────────────────────────────

enum _AgentStatus { waiting, running, done, flagged }

class _Agent {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color   color;
  _AgentStatus  status;
  String?       result;
  String?       detail;

  _Agent({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.status = _AgentStatus.waiting,
    this.result,
    this.detail,
  });
}

class AgentWorkflowScreen extends StatefulWidget {
  final Map<String, dynamic>? docData;
  const AgentWorkflowScreen({super.key, this.docData});

  @override
  State<AgentWorkflowScreen> createState() => _AgentWorkflowScreenState();
}

class _AgentWorkflowScreenState extends State<AgentWorkflowScreen>
    with TickerProviderStateMixin {

  late final List<_Agent> _agents;
  int _currentIndex = 0;
  bool _allDone = false;
  int _safetyScore = 0;
  late AnimationController _pulseCtrl;
  late AnimationController _scoreCtrl;
  late Animation<int> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _agents = _buildAgents();

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scoreAnim = IntTween(begin: 0, end: 78).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 600), _runNext);
  }

  List<_Agent> _buildAgents() => [
    _Agent(
      id: 'extract',
      name: 'Document Parser',
      description: 'Extracts survey number, owner name, area, dates from uploaded document',
      icon: Icons.document_scanner_outlined,
      color: const Color(0xFF5B6AF0),
    ),
    _Agent(
      id: 'validate',
      name: 'Data Validator',
      description: 'Checks completeness — all required fields present and legible',
      icon: Icons.checklist_outlined,
      color: const Color(0xFF00BFA5),
    ),
    _Agent(
      id: 'rera',
      name: 'RERA Verifier',
      description: 'Cross-checks project registration with RERA Karnataka database',
      icon: Icons.verified_outlined,
      color: const Color(0xFF43A047),
    ),
    _Agent(
      id: 'fraud',
      name: 'Fraud Scanner',
      description: 'Runs 30+ fraud pattern checks — double sale, forged seals, name mismatch',
      icon: Icons.shield_outlined,
      color: const Color(0xFFF57C00),
    ),
    _Agent(
      id: 'court',
      name: 'Court Records',
      description: 'Searches eCourts for pending cases linked to owner name or survey number',
      icon: Icons.gavel_outlined,
      color: const Color(0xFF8E24AA),
    ),
    _Agent(
      id: 'score',
      name: 'Score Engine',
      description: 'Calculates 0–100 safety score based on all agent findings',
      icon: Icons.analytics_outlined,
      color: AppColors.primary,
    ),
  ];

  Future<void> _runNext() async {
    if (_currentIndex >= _agents.length) return;

    setState(() => _agents[_currentIndex].status = _AgentStatus.running);

    // Simulate each agent's work time
    final delays = [1800, 1400, 2200, 2600, 1900, 1600];
    await Future.delayed(Duration(milliseconds: delays[_currentIndex]));
    if (!mounted) return;

    // Mock results per agent
    final results = _mockResults();
    setState(() {
      _agents[_currentIndex].status = results[_currentIndex]['flagged'] == true
          ? _AgentStatus.flagged
          : _AgentStatus.done;
      _agents[_currentIndex].result = results[_currentIndex]['result'] as String;
      _agents[_currentIndex].detail = results[_currentIndex]['detail'] as String?;
    });

    _currentIndex++;
    if (_currentIndex < _agents.length) {
      await Future.delayed(const Duration(milliseconds: 400));
      _runNext();
    } else {
      _safetyScore = 78;
      _scoreCtrl.forward();
      setState(() => _allDone = true);
    }
  }

  List<Map<String, dynamic>> _mockResults() => [
    {'result': 'Survey No. 123/4A  ·  Owner: Rajesh Kumar  ·  Area: 2400 sq.ft', 'flagged': false,
     'detail': 'Document type: Sale Deed  ·  Date: 2019-03-14'},
    {'result': 'All 7 required fields extracted successfully', 'flagged': false,
     'detail': 'EC chain: 15 years available  ·  Khata: Present'},
    {'result': 'RERA Reg: PRM/KA/RERA/1251/446/PR/190522 — Active', 'flagged': false,
     'detail': 'Project: Prestige Elm Park  ·  Completion: 2024'},
    {'result': '2 warnings detected', 'flagged': true,
     'detail': 'Seller name spelling differs from EC (Rajesh vs Rajesh Kumar) · Verify'},
    {'result': 'No pending cases found for owner or survey number', 'flagged': false,
     'detail': 'Searched: Civil + Criminal + Execution cases'},
    {'result': 'Safety Score: 78 / 100  —  Verify before buying', 'flagged': false,
     'detail': 'Deducted: Name mismatch (−12)  ·  EC gap 2011–2013 (−10)'},
  ];

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text('AI Verification Pipeline',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          if (_allDone)
            TextButton(
              onPressed: () => context.push('/auto-scan'),
              child: const Text('Full Report', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Pipeline header ────────────────────────────────────────
          _PipelineBar(agents: _agents, currentIndex: _currentIndex),

          // ── Agent cards ────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              itemCount: _agents.length,
              separatorBuilder: (_, i) => _ConnectorLine(
                agents: _agents,
                index: i,
              ),
              itemBuilder: (context, i) => _AgentCard(
                agent: _agents[i],
                pulseAnim: _pulseCtrl,
                isActive: i == _currentIndex - 1 ||
                    (_agents[i].status == _AgentStatus.running),
              ),
            ),
          ),

          // ── Score panel ────────────────────────────────────────────
          if (_allDone)
            AnimatedBuilder(
              animation: _scoreAnim,
              builder: (_, __) => _ScorePanel(
                score: _scoreAnim.value,
                onViewReport: () => context.push('/auto-scan'),
                onEscrow: () => context.push('/escrow'),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Pipeline progress bar at top ────────────────────────────────────────────
class _PipelineBar extends StatelessWidget {
  final List<_Agent> agents;
  final int currentIndex;
  const _PipelineBar({required this.agents, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              currentIndex < agents.length
                  ? 'Agent ${currentIndex + 1} of ${agents.length} running…'
                  : 'All agents complete',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text('${(currentIndex / agents.length * 100).round()}%',
                style: const TextStyle(
                    color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentIndex / agents.length,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Connector line between agents ───────────────────────────────────────────
class _ConnectorLine extends StatelessWidget {
  final List<_Agent> agents;
  final int index;
  const _ConnectorLine({required this.agents, required this.index});

  @override
  Widget build(BuildContext context) {
    final prevDone = index < agents.length &&
        (agents[index].status == _AgentStatus.done ||
         agents[index].status == _AgentStatus.flagged);
    return Center(
      child: Container(
        width: 2, height: 20,
        color: prevDone
            ? const Color(0xFFD4AF37).withOpacity(0.5)
            : Colors.white12,
      ),
    );
  }
}

// ─── Individual agent card ────────────────────────────────────────────────────
class _AgentCard extends StatelessWidget {
  final _Agent agent;
  final AnimationController pulseAnim;
  final bool isActive;
  const _AgentCard({required this.agent, required this.pulseAnim, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final isWaiting  = agent.status == _AgentStatus.waiting;
    final isRunning  = agent.status == _AgentStatus.running;
    final isDone     = agent.status == _AgentStatus.done;
    final isFlagged  = agent.status == _AgentStatus.flagged;

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, child) {
        final glow = isRunning
            ? BoxShadow(
                color: agent.color.withOpacity(0.15 + pulseAnim.value * 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              )
            : null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isWaiting
                ? const Color(0xFF131F2E)
                : isRunning
                    ? const Color(0xFF1A2C42)
                    : isDone
                        ? const Color(0xFF0F2518)
                        : const Color(0xFF2A1A0A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRunning
                  ? agent.color.withOpacity(0.6)
                  : isDone
                      ? const Color(0xFF2E7D32).withOpacity(0.4)
                      : isFlagged
                          ? Colors.orange.withOpacity(0.4)
                          : Colors.white10,
              width: isRunning ? 1.5 : 1,
            ),
            boxShadow: glow != null ? [glow] : null,
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          _StatusIcon(agent: agent, pulseAnim: pulseAnim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(agent.name,
                        style: TextStyle(
                            color: isWaiting ? Colors.white38 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  if (isFlagged)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: const Text('WARNING',
                          style: TextStyle(color: Colors.orange, fontSize: 9,
                              fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  if (isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('DONE',
                          style: TextStyle(color: Color(0xFF66BB6A), fontSize: 9,
                              fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                ]),
                const SizedBox(height: 3),
                Text(
                  isWaiting ? agent.description : (agent.result ?? agent.description),
                  style: TextStyle(
                      color: isWaiting
                          ? Colors.white24
                          : isFlagged
                              ? Colors.orange.shade300
                              : isDone
                                  ? Colors.white70
                                  : Colors.white54,
                      fontSize: 11,
                      height: 1.4),
                ),
                if ((isDone || isFlagged) && agent.detail != null) ...[
                  const SizedBox(height: 4),
                  Text(agent.detail!,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10, height: 1.3)),
                ],
                if (isRunning) ...[
                  const SizedBox(height: 8),
                  _ThinkingDots(color: agent.color),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status icon ──────────────────────────────────────────────────────────────
class _StatusIcon extends StatelessWidget {
  final _Agent agent;
  final AnimationController pulseAnim;
  const _StatusIcon({required this.agent, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    switch (agent.status) {
      case _AgentStatus.waiting:
        return Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(agent.icon, color: Colors.white24, size: 18),
        );
      case _AgentStatus.running:
        return AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, __) => Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: agent.color.withOpacity(0.15 + pulseAnim.value * 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: agent.color.withOpacity(0.5 + pulseAnim.value * 0.5),
                  width: 1.5),
            ),
            child: Icon(agent.icon, color: agent.color, size: 18),
          ),
        );
      case _AgentStatus.done:
        return Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.5)),
          ),
          child: const Icon(Icons.check, color: Color(0xFF66BB6A), size: 20),
        );
      case _AgentStatus.flagged:
        return Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange.withOpacity(0.5)),
          ),
          child: const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
        );
    }
  }
}

// ─── Thinking animation dots ──────────────────────────────────────────────────
class _ThinkingDots extends StatefulWidget {
  final Color color;
  const _ThinkingDots({required this.color});

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500))
        ..repeat(reverse: true);
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) ctrl.forward();
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _ctrls[i],
        builder: (_, __) => Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.3 + _ctrls[i].value * 0.7),
            shape: BoxShape.circle,
          ),
        ),
      )),
    );
  }
}

// ─── Score panel (shown when all agents complete) ─────────────────────────────
class _ScorePanel extends StatelessWidget {
  final int score;
  final VoidCallback onViewReport;
  final VoidCallback onEscrow;
  const _ScorePanel({
    required this.score,
    required this.onViewReport,
    required this.onEscrow,
  });

  Color get _scoreColor {
    if (score >= 80) return const Color(0xFF43A047);
    if (score >= 50) return const Color(0xFFF57C00);
    return const Color(0xFFE53935);
  }

  String get _scoreLabel {
    if (score >= 80) return 'Safe to Buy';
    if (score >= 50) return 'Verify Before Buying';
    return 'High Risk — Consult Lawyer';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111C28),
        border: const Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Row(children: [
            // Score circle
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _scoreColor, width: 3),
                color: _scoreColor.withOpacity(0.12),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$score',
                    style: TextStyle(color: _scoreColor,
                        fontSize: 24, fontWeight: FontWeight.w900)),
                Text('/100',
                    style: TextStyle(color: _scoreColor.withOpacity(0.7),
                        fontSize: 10)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_scoreLabel,
                  style: TextStyle(color: _scoreColor,
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              const Text('2 warnings found  ·  Report ready',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('DigiSampatti Score  ·  Powered by Claude AI',
                  style: TextStyle(color: Colors.white30, fontSize: 10)),
            ])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewReport,
                icon: const Icon(Icons.description_outlined, size: 15,
                    color: Color(0xFFD4AF37)),
                label: const Text('Full Report',
                    style: TextStyle(color: Color(0xFFD4AF37))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onEscrow,
                icon: const Icon(Icons.lock_clock, size: 15),
                label: const Text('Start Escrow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class NegotiationScreen extends StatefulWidget {
  const NegotiationScreen({super.key});
  @override
  State<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _priceCtrl = TextEditingController();
  final _noteCtrl  = TextEditingController();
  final _chatCtrl  = TextEditingController();

  String _role = 'buyer';
  bool _agreed = false;
  double? _agreedPrice;

  final List<_Offer> _offers = [
    _Offer(role: 'seller', amount: 7500000,
        note: 'Initial listing price', time: '10:00 AM'),
  ];

  final List<_Msg> _messages = [
    _Msg(role: 'seller', text: 'Hello! Property is available. No disputes, all documents ready.', time: '10:01 AM'),
    _Msg(role: 'buyer',  text: 'Hi, I saw the listing. Can I get the EC and RTC first?', time: '10:03 AM'),
    _Msg(role: 'seller', text: 'Sure — I have uploaded them. Check the document tab.', time: '10:04 AM'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  void _submitOffer() {
    final val = double.tryParse(_priceCtrl.text.replaceAll(',', ''));
    if (val == null) return;
    setState(() {
      _offers.add(_Offer(
        role: _role,
        amount: val,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        time: _now(),
      ));
      _priceCtrl.clear();
      _noteCtrl.clear();
    });
  }

  void _sendChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(role: _role, text: text, time: _now()));
      _chatCtrl.clear();
    });
  }

  void _acceptOffer(_Offer offer) {
    setState(() {
      _agreed = true;
      _agreedPrice = offer.amount;
    });
  }

  String _now() {
    final t = DateTime.now();
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _fmt(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '₹${(v / 100000).toStringAsFixed(2)} L';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/transaction');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/transaction'),
          ),
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Buyer ↔ Seller', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Negotiation & Secure Chat', style: TextStyle(fontSize: 11, color: Colors.white54)),
          ]),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: Colors.amber,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.handshake_outlined, size: 18), text: 'Price Offer'),
              Tab(icon: Icon(Icons.chat_outlined, size: 18), text: 'Secure Chat'),
            ],
          ),
        ),
        body: Column(children: [
          // Demo role bar
          Container(
            width: double.infinity,
            color: const Color(0xFF0D1B2A),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(children: [
              const Text('Demo view:', style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(width: 8),
              _RoleChip(
                label: '🏠 Buyer',
                selected: _role == 'buyer',
                onTap: () => setState(() => _role = 'buyer'),
              ),
              const SizedBox(width: 6),
              _RoleChip(
                label: '🏷️ Seller',
                selected: _role == 'seller',
                onTap: () => setState(() => _role = 'seller'),
              ),
              const Spacer(),
              if (_agreed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.safe.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Agreed: ${_fmt(_agreedPrice!)}',
                    style: const TextStyle(color: AppColors.safe, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                const Text('Toggle to see each side', style: TextStyle(color: Colors.white24, fontSize: 10)),
            ]),
          ),

          // Agreed banner
          if (_agreed)
            Container(
              width: double.infinity,
              color: AppColors.safe.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppColors.safe, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Price agreed at ${_fmt(_agreedPrice!)}. Ready for next step.',
                  style: const TextStyle(fontSize: 12, color: AppColors.safe, fontWeight: FontWeight.w600),
                )),
                ElevatedButton(
                  onPressed: () => context.go('/due-diligence'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safe,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Next →'),
                ),
              ]),
            ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildOfferTab(),
                _buildChatTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Offer Tab ────────────────────────────────────────────────────────────────
  Widget _buildOfferTab() {
    return Column(children: [
      Expanded(
        child: _offers.isEmpty
          ? const Center(child: Text('No offers yet. Make the first offer below.',
              style: TextStyle(color: AppColors.textLight)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              reverse: false,
              itemCount: _offers.length,
              itemBuilder: (context, i) {
                final offer = _offers[i];
                final isBuyer = offer.role == 'buyer';
                final isLast = i == _offers.length - 1;
                final canRespond = isLast && offer.role != _role && !_agreed;

                return Align(
                  alignment: isBuyer ? Alignment.centerLeft : Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBuyer
                            ? const Color(0xFFE3F2FD)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isBuyer
                              ? const Color(0xFF1565C0).withOpacity(0.25)
                              : AppColors.safe.withOpacity(0.25)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(isBuyer ? Icons.person : Icons.sell,
                            size: 12,
                            color: isBuyer ? const Color(0xFF1565C0) : AppColors.safe),
                          const SizedBox(width: 4),
                          Text(isBuyer ? 'Buyer' : 'Seller',
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold,
                              color: isBuyer ? const Color(0xFF1565C0) : AppColors.safe)),
                          const Spacer(),
                          Text(offer.time,
                            style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        ]),
                        const SizedBox(height: 4),
                        Text(_fmt(offer.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20,
                            color: Color(0xFF1A1A2E))),
                        if (offer.note != null) ...[
                          const SizedBox(height: 3),
                          Text(offer.note!,
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                        if (canRespond) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: OutlinedButton(
                              onPressed: () => _acceptOffer(offer),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.safe,
                                side: const BorderSide(color: AppColors.safe),
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: const Text('Accept', style: TextStyle(fontSize: 12)),
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton(
                              onPressed: () => _tabs.animateTo(0),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: const Text('Counter', style: TextStyle(fontSize: 12)),
                            )),
                          ]),
                        ],
                      ]),
                    ),
                  ),
                );
              },
            ),
      ),

      // Offer input
      if (!_agreed)
        SafeArea(
          top: false,
          child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              _role == 'buyer' ? 'Make a counter-offer as Buyer:' : 'Update your asking price as Seller:',
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount (e.g. 7200000)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Send'),
              ),
            ]),
          ]),
        )),
    ]);
  }

  // ── Chat Tab ─────────────────────────────────────────────────────────────────
  Widget _buildChatTab() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: const Color(0xFFFFF8E1),
        child: const Row(children: [
          Icon(Icons.lock_outline, size: 14, color: Colors.amber),
          SizedBox(width: 6),
          Expanded(child: Text(
            'Monitored secure chat. No phone numbers until both agree.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          )),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: _messages.length,
          itemBuilder: (context, i) {
            final msg = _messages[i];
            final isMe = msg.role == _role;
            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF1565C0)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(msg.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                        height: 1.4,
                      )),
                    const SizedBox(height: 3),
                    Text(msg.time,
                      style: TextStyle(
                        fontSize: 9,
                        color: isMe ? Colors.white60 : Colors.grey,
                      )),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _chatCtrl,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendChat,
              child: Container(
                width: 42, height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0), shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1565C0) : Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFF1565C0) : Colors.white24),
      ),
      child: Text(label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white60,
          fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}

class _Offer {
  final String role, time;
  final double amount;
  final String? note;
  const _Offer({required this.role, required this.amount,
      required this.time, this.note});
}

class _Msg {
  final String role, text, time;
  const _Msg({required this.role, required this.text, required this.time});
}

// Kopi Senja - aplikasi pemesanan kafe (Android / Flutter)
import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const KopiSenjaApp());

// ───────────────────────── WARNA & GAYA ─────────────────────────
const kCoffee = Color(0xFF4E2F1F);
const kCream = Color(0xFFFFF6EA);
const kOrange = Color(0xFFD9822B);
const kGold = Color(0xFFE0B040);
const kMuted = Color(0xFF8C7B6E);
const kSand = Color(0xFFFFF0DC);

const hStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kCoffee);
const h1Style = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kCoffee);
const mutedStyle = TextStyle(fontSize: 12, color: kMuted);
const priceStyle = TextStyle(fontWeight: FontWeight.w700, color: kOrange);
const bodyStyle = TextStyle(fontSize: 13, color: kCoffee);

// ───────────────────────── DATA ─────────────────────────
class Produk {
  final String id, name, cat, emoji, desc;
  final int price;
  const Produk(this.id, this.name, this.cat, this.price, this.emoji, this.desc);
}

const kMenu = <Produk>[
  Produk('k1', 'Espresso', 'Kopi', 18000, '☕', 'Shot tunggal, pekat & bold'),
  Produk('k2', 'Americano', 'Kopi', 22000, '☕', 'Espresso + air panas/es'),
  Produk('k3', 'Cafe Latte', 'Kopi', 28000, '🥛', 'Espresso, susu steam lembut'),
  Produk('k4', 'Kopi Susu Gula Aren', 'Kopi', 25000, '🧋', 'Signature kami, manis pas'),
  Produk('k5', 'Cappuccino', 'Kopi', 28000, '☕', 'Busa susu tebal'),
  Produk('k6', 'Caramel Macchiato', 'Kopi', 32000, '🍮', 'Sirup karamel & espresso'),
  Produk('n1', 'Matcha Latte', 'Non-Kopi', 30000, '🍵', 'Matcha Jepang + susu'),
  Produk('n2', 'Coklat Panas', 'Non-Kopi', 26000, '🍫', 'Coklat Belgia kental'),
  Produk('n3', 'Teh Tarik', 'Non-Kopi', 20000, '🫖', 'Teh susu busa'),
  Produk('n4', 'Lemon Tea', 'Non-Kopi', 18000, '🍋', 'Segar, bisa panas/es'),
  Produk('m1', 'Croissant', 'Makanan', 22000, '🥐', 'Renyah, mentega asli'),
  Produk('m2', 'Roti Bakar Coklat', 'Makanan', 20000, '🍞', 'Coklat & keju leleh'),
  Produk('m3', 'Nasi Goreng Kafe', 'Makanan', 35000, '🍳', 'Telur mata sapi, ayam suwir'),
  Produk('m4', 'Kentang Goreng', 'Makanan', 24000, '🍟', 'Crispy + saus sambal'),
];
final Map<String, Produk> kById = {for (final p in kMenu) p.id: p};
const kPastry = {'m1', 'm2'};

class Promo {
  final String code, emoji, title, desc;
  const Promo(this.code, this.emoji, this.title, this.desc);
}

const kPromos = <Promo>[
  Promo('MEMBER15', '🏷️', 'Diskon 15%', 'Semua minuman, tanpa minimum belanja'),
  Promo('B2G1', '🎁', 'Beli 2 Gratis 1', 'Menu kopi — kopi termurah gratis'),
  Promo('HEMAT10', '💸', 'Potongan Rp10.000', 'Min. belanja Rp60.000'),
  Promo('PASTRY', '🥐', 'Gratis Pastry', 'Beli 2 minuman, gratis 1 pastry'),
];
const kStatuses = ['Pesanan diterima', 'Sedang disiapkan', 'Siap! 🎉'];
const kOrderTypes = ['Ambil di kasir', 'Makan di tempat', 'Antar ke meja/alamat'];

String rp(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}Rp$b';
}

class Order {
  final String id, who, items, type;
  final String? promo;
  final int total, gain;
  int status = 0;
  Order({
    required this.id,
    required this.who,
    required this.items,
    required this.type,
    required this.promo,
    required this.total,
    required this.gain,
  });
}

class PromoResult {
  final int discount;
  final String? reason;
  const PromoResult(this.discount, this.reason);
}

class Totals {
  final int sub, disc, ppn, ongkir, total;
  const Totals(this.sub, this.disc, this.ppn, this.ongkir, this.total);
}

// ───────────────────────── STATE ─────────────────────────
class AppState extends ChangeNotifier {
  final Map<String, int> cart = {};
  final List<Order> orders = [];
  bool isMember = false;
  String name = 'Tamu';
  int points = 0;
  String? promo;
  String orderType = kOrderTypes[0];
  String category = 'Semua';
  Timer? _timer;

  AppState() {
    // simulasi status pesanan berjalan otomatis
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      var changed = false;
      for (final o in orders) {
        if (o.status < 2) {
          o.status++;
          changed = true;
        }
      }
      if (changed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get isGold => points >= 500;
  int get cartCount => cart.values.fold(0, (a, b) => a + b);

  List<Produk> get units {
    final out = <Produk>[];
    cart.forEach((id, q) {
      final p = kById[id]!;
      for (var i = 0; i < q; i++) {
        out.add(p);
      }
    });
    return out;
  }

  int get subtotal => units.fold(0, (a, p) => a + p.price);

  PromoResult promoResult(String code) {
    if (!isMember) return const PromoResult(0, 'Khusus member');
    final u = units;
    final drinks = u.where((p) => p.cat != 'Makanan').toList();
    if (code == 'MEMBER15') {
      final d = (drinks.fold<int>(0, (a, p) => a + p.price) * 0.15).round();
      return d > 0 ? PromoResult(d, null) : const PromoResult(0, 'Tambahkan minuman');
    }
    if (code == 'B2G1') {
      final coffee = u.where((p) => p.cat == 'Kopi').map((p) => p.price).toList()..sort();
      final n = coffee.length ~/ 3;
      if (n == 0) return const PromoResult(0, 'Butuh min. 3 kopi');
      return PromoResult(coffee.take(n).fold<int>(0, (a, b) => a + b), null);
    }
    if (code == 'HEMAT10') {
      return subtotal >= 60000
          ? const PromoResult(10000, null)
          : const PromoResult(0, 'Min. belanja Rp60.000');
    }
    if (code == 'PASTRY') {
      final pastry = u.where((p) => kPastry.contains(p.id)).map((p) => p.price).toList()..sort();
      if (drinks.length >= 2 && pastry.isNotEmpty) return PromoResult(pastry.first, null);
      return const PromoResult(0, 'Min. 2 minuman + 1 pastry');
    }
    return const PromoResult(0, 'Promo tidak dikenal');
  }

  Totals get totals {
    final sub = subtotal;
    var disc = 0;
    if (promo != null) {
      final r = promoResult(promo!);
      if (r.reason != null) {
        promo = null;
      } else {
        disc = r.discount;
      }
    }
    final ongkir = (orderType == kOrderTypes[2] && !isMember) ? 5000 : 0;
    final ppn = ((sub - disc) * 0.10).round();
    return Totals(sub, disc, ppn, ongkir, sub - disc + ppn + ongkir);
  }

  int pointsFor(int total) => (total ~/ 1000) * (isGold ? 2 : 1);

  void change(String id, int d) {
    final q = (cart[id] ?? 0) + d;
    if (q <= 0) {
      cart.remove(id);
    } else {
      cart[id] = q;
    }
    notifyListeners();
  }

  void setCategory(String c) {
    category = c;
    notifyListeners();
  }

  void setType(String t) {
    orderType = t;
    notifyListeners();
  }

  void setPromo(String? p) {
    promo = p;
    notifyListeners();
  }

  void register(String n) {
    isMember = true;
    name = n;
    points = 320; // bonus poin selamat datang
    notifyListeners();
  }

  Order checkout(String who) {
    final t = totals;
    final gain = isMember ? pointsFor(t.total) : 0;
    final items = cart.entries.map((e) => '${e.value}× ${kById[e.key]!.name}').join(', ');
    final o = Order(
      id: '#KS${1001 + orders.length}',
      who: who,
      items: items,
      type: orderType,
      promo: promo,
      total: t.total,
      gain: gain,
    );
    points += gain;
    orders.insert(0, o);
    cart.clear();
    promo = null;
    notifyListeners();
    return o;
  }
}

// ───────────────────────── WIDGET BANTU ─────────────────────────
Widget cardBox({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(12),
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: padding,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: child,
  );
}

Widget emojiBox(String e, {double size = 56}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: kSand, borderRadius: BorderRadius.circular(14)),
    child: Text(e, style: TextStyle(fontSize: size * 0.55)),
  );
}

Widget circleBtn(IconData icon, VoidCallback onTap, {bool primary = false}) {
  final size = primary ? 36.0 : 30.0;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: primary ? kOrange : kSand, shape: BoxShape.circle),
      child: Icon(icon, size: primary ? 20 : 17, color: primary ? Colors.white : kCoffee),
    ),
  );
}

Widget qtyControl(AppState s, String id) {
  final q = s.cart[id] ?? 0;
  if (q == 0) return circleBtn(Icons.add, () => s.change(id, 1), primary: true);
  return Row(mainAxisSize: MainAxisSize.min, children: [
    circleBtn(Icons.remove, () => s.change(id, -1)),
    SizedBox(width: 28, child: Text('$q', textAlign: TextAlign.center, style: hStyle)),
    circleBtn(Icons.add, () => s.change(id, 1)),
  ]);
}

Widget productRow(AppState s, Produk p) {
  return cardBox(
    child: Row(children: [
      emojiBox(p.emoji),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: hStyle),
          Text(p.desc, style: mutedStyle),
          const SizedBox(height: 2),
          Text(rp(p.price), style: priceStyle),
        ]),
      ),
      qtyControl(s, p.id),
    ]),
  );
}

Widget pageList(List<Widget> children) {
  return SafeArea(
    bottom: false,
    child: ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 24), children: children),
  );
}

Widget primaryBtn(String text, VoidCallback? onTap) {
  return SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: kOrange,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    ),
  );
}

Widget memberCard(AppState s, {bool compact = false}) {
  const white = TextStyle(color: Colors.white);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [kCoffee, Color(0xFF8A5A3B)],
      ),
    ),
    child: s.isMember
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('KOPI SENJA MEMBER',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(10)),
                child: Text(s.isGold ? 'GOLD' : 'SILVER',
                    style: const TextStyle(color: kCoffee, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(s.name, style: white.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('${s.points} poin', style: white.copyWith(fontSize: 28, fontWeight: FontWeight.w800)),
            if (!compact) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: (s.points / 500).clamp(0.0, 1.0).toDouble(),
                  minHeight: 10,
                  backgroundColor: const Color(0x33FFFFFF),
                  color: kOrange,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.isGold
                    ? 'Kamu sudah Gold! Poin 2x di setiap transaksi.'
                    : '${500 - s.points} poin lagi menuju Gold (poin 2x)',
                style: white.copyWith(fontSize: 12),
              ),
            ],
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Belum jadi member?', style: white.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Daftar gratis: diskon 15%, beli 2 gratis 1, gratis ongkir, & kumpulkan poin.',
                style: white.copyWith(fontSize: 13)),
          ]),
  );
}

Widget benefitTile(String emoji, String title, String desc) {
  return cardBox(
    child: Row(children: [
      emojiBox(emoji, size: 48),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: hStyle),
          Text(desc, style: mutedStyle),
        ]),
      ),
    ]),
  );
}

// ───────────────────────── APLIKASI ─────────────────────────
class KopiSenjaApp extends StatelessWidget {
  const KopiSenjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kopi Senja',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kOrange).copyWith(onSurface: kCoffee),
        scaffoldBackgroundColor: kCream,
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final AppState s = AppState();
  int tab = 0;

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  void go(int i) => setState(() => tab = i);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final pages = <Widget>[
          HomePage(s: s, go: go),
          MenuPage(s: s),
          CartPage(s: s, go: go),
          OrdersPage(s: s),
          MemberPage(s: s, go: go),
        ];
        final n = s.cartCount;
        return Scaffold(
          body: pages[tab],
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: go,
            backgroundColor: Colors.white,
            indicatorColor: kSand,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: kOrange),
                label: 'Beranda',
              ),
              const NavigationDestination(
                icon: Icon(Icons.local_cafe_outlined),
                selectedIcon: Icon(Icons.local_cafe_rounded, color: kOrange),
                label: 'Menu',
              ),
              NavigationDestination(
                icon: Badge(
                  label: Text('$n'),
                  isLabelVisible: n > 0,
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                selectedIcon: Badge(
                  label: Text('$n'),
                  isLabelVisible: n > 0,
                  child: const Icon(Icons.shopping_bag_rounded, color: kOrange),
                ),
                label: 'Keranjang',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: kOrange),
                label: 'Pesanan',
              ),
              const NavigationDestination(
                icon: Icon(Icons.workspace_premium_outlined),
                selectedIcon: Icon(Icons.workspace_premium_rounded, color: kOrange),
                label: 'Member',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── BERANDA ─────────────────────────
class HomePage extends StatelessWidget {
  final AppState s;
  final void Function(int) go;
  const HomePage({super.key, required this.s, required this.go});

  @override
  Widget build(BuildContext context) {
    return pageList([
      Text('Halo, ${s.name} 👋', style: h1Style),
      const Text('Mau ngopi apa hari ini?', style: mutedStyle),
      const SizedBox(height: 14),
      memberCard(s, compact: true),
      const Text('🔥 Promo Khusus Member', style: hStyle),
      const SizedBox(height: 10),
      SizedBox(
        height: 165,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: kPromos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final p = kPromos[i];
            return Container(
              width: 170,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: s.isMember ? const Color(0xFFFFE9CC) : const Color(0xFFEDE6DC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.isMember ? p.emoji : '🔒', style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(p.title, style: hStyle.copyWith(fontSize: 15), maxLines: 2),
                const SizedBox(height: 4),
                Text(p.desc, style: mutedStyle, maxLines: 3, overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      if (!s.isMember) ...[
        primaryBtn('Gabung member gratis & buka semua promo →', () => go(4)),
        const SizedBox(height: 14),
      ],
      const Text('⭐ Favorit Pelanggan', style: hStyle),
      const SizedBox(height: 10),
      for (final id in ['k4', 'k3', 'm1']) productRow(s, kById[id]!),
    ]);
  }
}

// ───────────────────────── MENU ─────────────────────────
class MenuPage extends StatelessWidget {
  final AppState s;
  const MenuPage({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    return pageList([
      const Text('Menu', style: h1Style),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final c in ['Semua', 'Kopi', 'Non-Kopi', 'Makanan'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c),
                selected: s.category == c,
                showCheckmark: false,
                selectedColor: kCoffee,
                backgroundColor: Colors.white,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: s.category == c ? Colors.white : kCoffee,
                ),
                onSelected: (_) => s.setCategory(c),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      for (final p in kMenu)
        if (s.category == 'Semua' || s.category == p.cat) productRow(s, p),
    ]);
  }
}

// ───────────────────────── KERANJANG ─────────────────────────
class CartPage extends StatefulWidget {
  final AppState s;
  final void Function(int) go;
  const CartPage({super.key, required this.s, required this.go});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Widget _promoTile(Promo p) {
    final s = widget.s;
    final r = s.promoResult(p.code);
    final ok = r.reason == null;
    final sel = s.promo == p.code && ok;
    return InkWell(
      onTap: ok ? () => s.setPromo(sel ? null : p.code) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(
            sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: ok ? kOrange : const Color(0xFFCFC3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${p.emoji} ${p.title}${ok ? '  (−${rp(r.discount)})' : ''}',
                style: hStyle.copyWith(fontSize: 14, color: ok ? kCoffee : kMuted),
              ),
              Text(ok ? p.desc : '🔒 ${r.reason}', style: mutedStyle),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _row(String a, String b, {Color color = kCoffee, bool big = false}) {
    final st = big
        ? TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)
        : TextStyle(fontSize: 13, color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(a, style: big ? hStyle : bodyStyle),
        Text(b, style: st),
      ]),
    );
  }

  void _order() {
    final s = widget.s;
    final typed = _name.text.trim();
    final who = typed.isNotEmpty ? typed : (s.isMember ? s.name : 'Tamu');
    final o = s.checkout(who);
    _name.clear();
    showDialog<void>(
      context: context,
      builder: (dc) => AlertDialog(
        title: const Text('Pesanan berhasil 🎉'),
        content: Text(
          'Pesanan ${o.id} atas nama ${o.who} sudah diterima.\n'
          '${o.gain > 0 ? 'Kamu mendapat +${o.gain} poin!' : 'Jadi member untuk dapat poin & promo!'}',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dc), child: const Text('OK'))],
      ),
    );
    widget.go(3);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    if (s.cart.isEmpty) {
      return pageList([
        const Text('Keranjang', style: h1Style),
        const SizedBox(height: 60),
        const Center(child: Text('🛒', style: TextStyle(fontSize: 52))),
        const SizedBox(height: 8),
        const Center(child: Text('Keranjang masih kosong', style: mutedStyle)),
        const SizedBox(height: 20),
        primaryBtn('Lihat menu', () => widget.go(1)),
      ]);
    }
    final t = s.totals;
    final delivery = s.orderType == kOrderTypes[2];
    return pageList([
      const Text('Keranjang', style: h1Style),
      const SizedBox(height: 12),
      for (final id in s.cart.keys.toList()) productRow(s, kById[id]!),
      const Text('Tipe pesanan', style: hStyle),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final o in kOrderTypes)
          ChoiceChip(
            label: Text(o),
            selected: s.orderType == o,
            showCheckmark: false,
            selectedColor: kCoffee,
            backgroundColor: Colors.white,
            side: BorderSide.none,
            labelStyle: TextStyle(color: s.orderType == o ? Colors.white : kCoffee),
            onSelected: (_) => s.setType(o),
          ),
      ]),
      if (delivery)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            s.isMember ? 'Gratis ongkir untuk member 👑' : 'Ongkir Rp5.000 — GRATIS untuk member 👑',
            style: mutedStyle,
          ),
        ),
      const SizedBox(height: 14),
      const Text('Promo member', style: hStyle),
      const SizedBox(height: 8),
      cardBox(child: Column(children: [for (final p in kPromos) _promoTile(p)])),
      if (!s.isMember) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => widget.go(4),
            child: const Text('Jadi member untuk pakai promo →',
                style: TextStyle(color: kOrange, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 6),
      ],
      cardBox(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _row('Subtotal', rp(t.sub)),
          _row('Diskon promo', '−${rp(t.disc)}', color: const Color(0xFF2E8B57)),
          _row('PPN 10%', rp(t.ppn)),
          _row('Ongkir', delivery && t.ongkir == 0 ? 'Gratis' : rp(t.ongkir)),
          const Divider(),
          _row('Total', rp(t.total), color: kOrange, big: true),
          if (s.isMember)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('⭐ Kamu dapat +${s.pointsFor(t.total)} poin dari pesanan ini',
                  style: mutedStyle),
            ),
        ]),
      ),
      TextField(
        controller: _name,
        decoration: InputDecoration(
          hintText: s.isMember ? s.name : 'Nama pemesan',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEBDDCB)),
          ),
        ),
      ),
      const SizedBox(height: 14),
      primaryBtn('Pesan Sekarang • ${rp(t.total)}', _order),
    ]);
  }
}

// ───────────────────────── PESANAN ─────────────────────────
class OrdersPage extends StatelessWidget {
  final AppState s;
  const OrdersPage({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    return pageList([
      const Text('Pesanan Saya', style: h1Style),
      const SizedBox(height: 12),
      if (s.orders.isEmpty) ...[
        const SizedBox(height: 60),
        const Center(child: Text('🧾', style: TextStyle(fontSize: 52))),
        const SizedBox(height: 8),
        const Center(child: Text('Belum ada pesanan', style: mutedStyle)),
      ],
      for (final o in s.orders)
        cardBox(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(o.id, style: hStyle),
              Text(rp(o.total), style: priceStyle),
            ]),
            const SizedBox(height: 4),
            Text(o.items, style: bodyStyle),
            Text(
              '${o.type} • a.n. ${o.who}${o.promo != null ? ' • promo ${o.promo}' : ''}',
              style: mutedStyle,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: (o.status + 1) / 3,
                minHeight: 10,
                backgroundColor: const Color(0xFFEDE0CF),
                color: kOrange,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              kStatuses[o.status],
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: o.status == 2 ? const Color(0xFF2E8B57) : kOrange,
              ),
            ),
          ]),
        ),
    ]);
  }
}

// ───────────────────────── MEMBER ─────────────────────────
class MemberPage extends StatelessWidget {
  final AppState s;
  final void Function(int) go;
  const MemberPage({super.key, required this.s, required this.go});

  @override
  Widget build(BuildContext context) {
    return pageList([
      const Text('Member', style: h1Style),
      const SizedBox(height: 12),
      memberCard(s),
      if (!s.isMember) RegisterForm(s: s, go: go),
      const Text('Keuntungan member', style: hStyle),
      const SizedBox(height: 10),
      for (final p in kPromos) benefitTile(p.emoji, p.title, p.desc),
      benefitTile('🚚', 'Gratis ongkir', 'Untuk semua pesanan antar'),
      benefitTile('🎂', 'Hadiah ulang tahun', 'Gratis 1 minuman favorit di bulan lahirmu'),
      benefitTile('⭐', 'Kumpulkan poin', '1 poin tiap Rp1.000 • Gold dapat poin 2x'),
    ]);
  }
}

class RegisterForm extends StatefulWidget {
  final AppState s;
  final void Function(int) go;
  const RegisterForm({super.key, required this.s, required this.go});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _register() {
    final n = _c.text.trim();
    if (n.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama dulu ya 🙂')),
      );
      return;
    }
    widget.s.register(n);
    showDialog<void>(
      context: context,
      builder: (dc) => AlertDialog(
        title: const Text('Selamat datang!'),
        content: Text('Halo $n! Kamu mendapat bonus 320 poin 🎁'),
        actions: [TextButton(onPressed: () => Navigator.pop(dc), child: const Text('OK'))],
      ),
    );
    widget.go(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        controller: _c,
        decoration: InputDecoration(
          hintText: 'Nama lengkap',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEBDDCB)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      primaryBtn('Daftar Member Gratis 🎉', _register),
      const SizedBox(height: 18),
    ]);
  }
}

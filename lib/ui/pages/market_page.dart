import 'package:flutter/material.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final Map<int, int> _cartProductIdToQty = {};

  final List<String> _categories = const [
    'All',
    'Seeds',
    'Fertilizers',
    'Pesticides',
    'Tools',
    'Irrigation',
  ];

  final List<_Product> _allProducts = const [
    _Product(id: 1, name: 'Hybrid Tomato Seeds', category: 'Seeds', price: 149.0, unit: 'pack', rating: 4.6),
    _Product(id: 2, name: 'Wheat Seeds', category: 'Seeds', price: 99.0, unit: 'kg', rating: 4.3),
    _Product(id: 3, name: 'NPK 10-26-26', category: 'Fertilizers', price: 899.0, unit: '50kg', rating: 4.7),
    _Product(id: 4, name: 'Urea', category: 'Fertilizers', price: 699.0, unit: '50kg', rating: 4.2),
    _Product(id: 5, name: 'Glyphosate', category: 'Pesticides', price: 349.0, unit: 'liter', rating: 4.1),
    _Product(id: 6, name: 'Neem Oil', category: 'Pesticides', price: 299.0, unit: 'liter', rating: 4.5),
    _Product(id: 7, name: 'Hand Trowel', category: 'Tools', price: 249.0, unit: 'piece', rating: 4.4),
    _Product(id: 8, name: 'Pruning Shears', category: 'Tools', price: 599.0, unit: 'piece', rating: 4.6),
    _Product(id: 9, name: 'Drip Kit (Small)', category: 'Irrigation', price: 2499.0, unit: 'kit', rating: 4.8),
    _Product(id: 10, name: 'Sprinkler Head', category: 'Irrigation', price: 199.0, unit: 'piece', rating: 4.0),
  ];

  List<_Product> get _visibleProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _allProducts.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesQuery = query.isEmpty || p.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  int get _cartCount => _cartProductIdToQty.values.fold(0, (a, b) => a + b);

  double get _cartTotal {
    double total = 0;
    _cartProductIdToQty.forEach((productId, qty) {
      final p = _allProducts.firstWhere((e) => e.id == productId);
      total += p.price * qty;
    });
    return total;
  }

  void _addToCart(_Product p) {
    setState(() {
      _cartProductIdToQty[p.id] = (_cartProductIdToQty[p.id] ?? 0) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${p.name} added to cart'), duration: const Duration(milliseconds: 800)),
    );
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            final entries = _cartProductIdToQty.entries.toList();
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26.withOpacity(0.06), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Text('Your Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${entries.length} items', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: entries.isEmpty
                        ? const Center(child: Text('Your cart is empty'))
                        : ListView.builder(
                            controller: controller,
                            itemCount: entries.length,
                            itemBuilder: (_, i) {
                              final e = entries[i];
                              final p = _allProducts.firstWhere((x) => x.id == e.key);
                              final qty = e.value;
                              return ListTile(
                                leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.shopping_bag, color: Colors.green)),
                                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${p.unit} • ₹${p.price.toStringAsFixed(2)}'),
                                trailing: SizedBox(
                                  width: 140,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            final cur = _cartProductIdToQty[p.id] ?? 0;
                                            if (cur <= 1) {
                                              _cartProductIdToQty.remove(p.id);
                                            } else {
                                              _cartProductIdToQty[p.id] = cur - 1;
                                            }
                                          });
                                        },
                                      ),
                                      Text('$qty'),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            _cartProductIdToQty[p.id] = (_cartProductIdToQty[p.id] ?? 0) + 1;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Row(
                      children: [
                        Text('Total: ', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        Text('₹${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          onPressed: entries.isEmpty ? null : _checkout,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _checkout() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: Text('Proceed to place order for ₹${_cartTotal.toStringAsFixed(2)}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() => _cartProductIdToQty.clear());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order placed successfully')),
                );
              },
              child: const Text('Place Order'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Market', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      if (_cartCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.red,
                            child: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _openCart,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  final isSel = c == _selectedCategory;
                  return ChoiceChip(
                    label: Text(c),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedCategory = c),
                    selectedColor: Colors.green.shade50,
                    labelStyle: TextStyle(color: isSel ? Colors.green.shade800 : Colors.black87),
                    side: BorderSide(color: isSel ? Colors.green : Colors.grey.shade300),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _categories.length,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: _visibleProducts.length,
                itemBuilder: (_, i) {
                  final p = _visibleProducts[i];
                  final inCartQty = _cartProductIdToQty[p.id] ?? 0;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(p.rating.toStringAsFixed(1)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: Icon(Icons.agriculture, size: 48, color: Colors.green.shade300),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(p.category, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('₹${p.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Text('/ ${p.unit}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: inCartQty == 0
                                  ? OutlinedButton(
                                      onPressed: () => _addToCart(p),
                                      child: const Text('Add to cart'),
                                    )
                                  : Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () {
                                              setState(() {
                                                final cur = _cartProductIdToQty[p.id] ?? 0;
                                                if (cur <= 1) {
                                                  _cartProductIdToQty.remove(p.id);
                                                } else {
                                                  _cartProductIdToQty[p.id] = cur - 1;
                                                }
                                              });
                                            },
                                          ),
                                          Text('$inCartQty'),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              setState(() {
                                                _cartProductIdToQty[p.id] = (_cartProductIdToQty[p.id] ?? 0) + 1;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String unit;
  final double rating;
  const _Product({required this.id, required this.name, required this.category, required this.price, required this.unit, required this.rating});
}



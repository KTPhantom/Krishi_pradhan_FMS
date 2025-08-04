import 'package:flutter/material.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Padding(
        // Adjusted bottom padding to 100 for consistency with dock
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 100),
        child: SingleChildScrollView( // Added SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Finance",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Monthly Spending",
                  style: TextStyle(color: Colors.black54, fontSize: 14)),
              const SizedBox(height: 12),
              const Text("₹36,756",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("80% Paid",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(height: 20),
              const Text("Due ₹7,450",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Check credit accounts",
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Flexible( // Added Flexible to prevent overflow if text is long
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Fertex Co.",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                          SizedBox(height: 4),
                          Text("Upcoming Payment",
                              style:
                              TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    SizedBox(width: 8), // Added spacing
                    Text("₹2,500",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // This container was not present in the original description's layout.
              // Assuming it's part of the transactions or a separate info card.
              // If it's a fixed-height element, it's fine.
              // If it's dynamic, ensure text wraps or use Flexible/Expanded if in a Row/Column.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.receipt_long_outlined, // Changed to a more relevant icon
                        size: 28, color: Colors.blueAccent),
                    SizedBox(width: 12),
                    Expanded( // Expanded is good here
                      child: Text("Total Credit Due: ₹7,450", // Made text more descriptive
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.energy_savings_leaf_rounded,
                        size: 28, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("This month’s largest expense",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          SizedBox(height: 6),
                          Text("Fertilizer",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text("Purchased on July 3",
                              style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                     const SizedBox(width: 8), // Added spacing
                    const Text("₹24,300",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("Recent Transactions", // Changed title slightly for clarity
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    _TransactionRow("Pesticide", "₹1,610"),
                    Divider(height: 24, thickness: 0.5), // Adjusted divider
                    _TransactionRow("Water Pump", "₹6,150"),
                    Divider(height: 24, thickness: 0.5),
                    _TransactionRow("Greenhouse Repair", "₹4,696"),
                    // Added more transactions to test scrolling
                    Divider(height: 24, thickness: 0.5),
                    _TransactionRow("Seeds Purchase", "₹3,200"),
                    Divider(height: 24, thickness: 0.5),
                    _TransactionRow("Equipment Fuel", "₹1,800"),
                  ],
                ),
              ),
               const SizedBox(height: 24), // Added some padding at the end of the scroll
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String title;
  final String amount;

  const _TransactionRow(this.title, this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding( // Added padding for better spacing within the row
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible( // Added Flexible to prevent overflow if title is long
            child: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16), // Added spacing between title and amount
          Text(amount,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

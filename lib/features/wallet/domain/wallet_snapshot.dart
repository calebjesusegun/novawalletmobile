import 'package:flutter/foundation.dart';
import 'package:novawallet/core/money/money.dart';

/// Domain entity representing a cached snapshot of the user's wallet.
///
/// In accordance with docs/ARCHITECTURE.md §7.1, §8, §13.3, §16:
/// - [balance] is stored strictly as integer kobo using [Money] (never double).
/// - [lastUpdatedAt] is normalized to UTC.
/// - This represents the confirmed wallet state received from remote or loaded from cache.
@immutable
class WalletSnapshot {
  /// Confirmed available balance in integer kobo.
  final Money balance;

  /// Timestamp of the last confirmed balance update (UTC).
  final DateTime lastUpdatedAt;

  WalletSnapshot({required this.balance, DateTime? lastUpdatedAt})
    : lastUpdatedAt = (lastUpdatedAt ?? DateTime.now()).toUtc();

  /// Default initial wallet snapshot (e.g. ₦125,450.00 as per design baseline AD-01 / UI-WAL-01).
  factory WalletSnapshot.initial({
    Money balance = const Money.fromKobo(12545000), // ₦125,450.00
    DateTime? lastUpdatedAt,
  }) {
    return WalletSnapshot(
      balance: balance,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.now().toUtc(),
    );
  }

  WalletSnapshot copyWith({Money? balance, DateTime? lastUpdatedAt}) {
    return WalletSnapshot(
      balance: balance ?? this.balance,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletSnapshot &&
          other.balance == balance &&
          other.lastUpdatedAt.isAtSameMomentAs(lastUpdatedAt));

  @override
  int get hashCode =>
      Object.hash(balance, lastUpdatedAt.millisecondsSinceEpoch);

  @override
  String toString() =>
      'WalletSnapshot(balance: $balance, lastUpdatedAt: $lastUpdatedAt)';
}

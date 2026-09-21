/// Type of transaction.
enum TransactionType {
  /// Money sent/transferred out of wallet.
  debit,

  /// Money received into wallet / deposit.
  credit,
}

/// Lifecycle status of a confirmed or cached transaction.
enum TransactionStatus { completed, pending, failed }

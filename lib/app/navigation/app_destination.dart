/// Primary navigation destinations for NovaWallet.
///
/// Implements ASM-001, DSN-011.
enum AppDestination {
  wallet,
  send,
  novaSave;

  String get label {
    switch (this) {
      case AppDestination.wallet:
        return 'Wallet';
      case AppDestination.send:
        return 'Send';
      case AppDestination.novaSave:
        return 'NovaSave';
    }
  }
}

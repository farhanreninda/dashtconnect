enum ConnectionMode {
  carPlay('carplay', 'Apple CarPlay'),
  androidAuto('androidAuto', 'Android Auto');

  const ConnectionMode(this.id, this.label);
  final String id, label;

  static ConnectionMode? fromId(String? id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}

class AuthRefreshLock {
  static Future<void>? _refreshFuture;

  static Future<void> run(Future<void> Function() action) {
    _refreshFuture ??= action().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }
}

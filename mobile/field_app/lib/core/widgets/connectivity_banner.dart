import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Shows a slim banner when the device has no network connection.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> r) {
      final offline = r.isEmpty ||
          r.every((e) => e == ConnectivityResult.none);
      if (mounted) setState(() => _offline = offline);
    });
    _check();
  }

  Future<void> _check() async {
    final r = await Connectivity().checkConnectivity();
    final offline =
        r.isEmpty || r.every((e) => e == ConnectivityResult.none);
    if (mounted) setState(() => _offline = offline);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_offline)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 18,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No connection. Actions may fail until you are back online.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

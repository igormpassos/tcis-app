import 'package:flutter/material.dart';
import 'dart:async';
import '../services/connectivity_service.dart';

class ConnectivityIndicator extends StatefulWidget {
  final Widget child;
  final bool showIndicator;

  const ConnectivityIndicator({
    super.key,
    required this.child,
    this.showIndicator = true,
  });

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  bool _hasConnection = true;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _setupConnectivityMonitoring();
  }

  void _setupConnectivityMonitoring() {
    // Verifica conectividade inicial
    _checkInitialConnectivity();
    
    // Configura listener para mudanças de conectividade
    _connectivitySubscription = ConnectivityService.onInternetConnectivityChanged()
        .listen((bool hasConnection) {
      if (mounted) {
        setState(() {
          _hasConnection = hasConnection;
          _isChecking = false;
        });
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final hasConnection = await ConnectivityService.forceCheckInternetConnection();
    if (mounted) {
      setState(() {
        _hasConnection = hasConnection;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showIndicator && !_hasConnection && !_isChecking)
          Container(
            width: double.infinity,
            color: Colors.orange.shade600,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sem conexão com a internet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      _isChecking = true;
                    });
                    await _checkInitialConnectivity();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _isChecking 
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Tentar novamente',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.showIndicator && _hasConnection && !_isChecking)
          Container(
            width: double.infinity,
            color: Colors.green.shade600,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: const Row(
              children: [
                Icon(
                  Icons.wifi,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class ConnectivityStatusIcon extends StatefulWidget {
  const ConnectivityStatusIcon({super.key});

  @override
  State<ConnectivityStatusIcon> createState() => _ConnectivityStatusIconState();
}

class _ConnectivityStatusIconState extends State<ConnectivityStatusIcon> {
  bool _hasConnection = true;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _setupConnectivityMonitoring();
  }

  void _setupConnectivityMonitoring() {
    _checkInitialConnectivity();
    _connectivitySubscription = ConnectivityService.onInternetConnectivityChanged()
        .listen((bool hasConnection) {
      if (mounted) {
        setState(() {
          _hasConnection = hasConnection;
        });
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final hasConnection = await ConnectivityService.hasInternetConnection();
    if (mounted) {
      setState(() {
        _hasConnection = hasConnection;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _hasConnection ? Icons.wifi : Icons.wifi_off,
      color: _hasConnection ? Colors.green : Colors.orange,
      size: 20,
    );
  }
}

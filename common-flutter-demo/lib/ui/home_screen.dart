import 'package:flutter/material.dart';

import 'package:common_flutter_demo/core/auth/auth_service.dart';
import 'package:common_flutter_demo/core/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  DeviceSecurityStatus? _status;
  bool _isLoading = true;

  bool _authSucceededVisible = false;
  bool _isAuthenticating = false;

  String _buttonText = AppStrings.authenticateFingerprint;
  bool _buttonEnabled = false;

  @override
  void initState() {
    super.initState();
    _refreshSecurityStatus();
  }

  Future<void> _refreshSecurityStatus() async {
    setState(() {
      _isLoading = true;
      _authSucceededVisible = false;
    });

    final DeviceSecurityStatus status = await _authService.getDeviceSecurityStatus();

    // Update ONLY primitive state after await.
    final bool enable = status.canAuthenticateWithBiometricOrDeviceCredential;
    final String btnText = status.canCheckBiometrics
        ? AppStrings.authenticateFingerprint
        : AppStrings.authenticateOther;

    if (!mounted) return;
    setState(() {
      _status = status;
      _buttonEnabled = enable;
      _buttonText = btnText;
      _isLoading = false;
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _authSucceededVisible = false;
    });

    bool success = false;
    String? snackbarMessage;

    try {
      success = await _authService.authenticate(
        localizedReason: AppStrings.biometricAuthDescription,
      );
      snackbarMessage =
          success ? AppStrings.authenticationSucceeded : AppStrings.authenticationFailed;
    } catch (_) {
      snackbarMessage = AppStrings.authenticationError;
      success = false;
    }

    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      _authSucceededVisible = success;
    });

    // Use ScaffoldMessenger safely without holding context across await:
    // We are now past awaits and in sync UI update path.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackbarMessage ?? AppStrings.authenticationError),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DeviceSecurityStatus? status = _status;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _refreshSecurityStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoading
                      ? const _LoadingView()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 6),
                            Icon(
                              Icons.fingerprint,
                              size: 84,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'BIOMETRIC AUTHENTICATION',
                              style: Theme.of(context).textTheme.labelLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            _StatusRow(
                              label: 'Biometric capability',
                              value: (status?.canCheckBiometrics ?? false)
                                  ? AppStrings.available
                                  : AppStrings.unavailable,
                            ),
                            const Divider(height: 1),
                            _StatusRow(
                              label: 'Device has enrolled biometrics',
                              value: (status?.hasEnrolledBiometrics ?? false)
                                  ? AppStrings.yes
                                  : AppStrings.no,
                            ),
                            const Divider(height: 1),
                            _StatusRow(
                              label: 'Device supports credential fallback',
                              value: (status?.canAuthenticateWithBiometricOrDeviceCredential ??
                                      false)
                                  ? AppStrings.yes
                                  : AppStrings.no,
                            ),
                            const Divider(height: 1),
                            _StatusRow(
                              label: 'OS',
                              value: status?.osDescription ?? '-',
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: (_buttonEnabled && !_isAuthenticating)
                                    ? _authenticate
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: _isAuthenticating
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(_buttonText),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _authSucceededVisible
                                  ? Text(
                                      'Authentication success',
                                      key: const ValueKey('auth_success'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: const Color(0xFF9CCC65),
                                          ),
                                      textAlign: TextAlign.center,
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('auth_hidden'),
                                    ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Checking device security...'),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.primary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: labelStyle,
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

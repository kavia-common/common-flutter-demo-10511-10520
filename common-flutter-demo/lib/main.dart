import 'package:flutter/material.dart';

import 'device_security.dart';

void main() {
  runApp(const CommonFlutterDemoApp());
}

class CommonFlutterDemoApp extends StatelessWidget {
  const CommonFlutterDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

    return MaterialApp(
      title: 'Common Flutter Demo',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (_) => const SecurityHomeScreen(),
      },
    );
  }
}

class SecurityHomeScreen extends StatefulWidget {
  const SecurityHomeScreen({super.key});

  @override
  State<SecurityHomeScreen> createState() => _SecurityHomeScreenState();
}

class _SecurityHomeScreenState extends State<SecurityHomeScreen> {
  DeviceSecurityStatus? _status;
  String? _statusError;

  AuthResult? _lastAuth;
  String? _authError;

  bool _loadingStatus = false;
  bool _authInProgress = false;

  Future<void> _refreshStatus() async {
    setState(() {
      _loadingStatus = true;
      _statusError = null;
    });

    try {
      final s = await DeviceSecurityApi.getSecurityStatus();
      setState(() {
        _status = s;
      });
    } catch (e) {
      setState(() {
        _statusError = e.toString();
      });
    } finally {
      setState(() {
        _loadingStatus = false;
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _authInProgress = true;
      _authError = null;
      _lastAuth = null;
    });

    try {
      final res = await DeviceSecurityApi.authenticate(
        reason: 'Authenticate to continue',
        allowDeviceCredential: true,
      );

      setState(() {
        _lastAuth = res;
      });
    } catch (e) {
      setState(() {
        _authError = e.toString();
      });
    } finally {
      setState(() {
        _authInProgress = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Kick off initial status fetch.
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final status = _status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Security & Biometrics'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadingStatus ? null : _refreshStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Security status',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_loadingStatus) ...<Widget>[
                    const LinearProgressIndicator(),
                  ] else if (_statusError != null) ...<Widget>[
                    Text(
                      _statusError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ] else if (status == null) ...<Widget>[
                    const Text('No status loaded.'),
                  ] else ...<Widget>[
                    _KeyValueRow(
                      label: 'Device secure (PIN/pattern/password)',
                      value: status.isDeviceSecure ? 'Yes' : 'No',
                    ),
                    _KeyValueRow(
                      label: 'Biometric strong available',
                      value: status.canBiometricStrong ? 'Yes' : 'No',
                    ),
                    _KeyValueRow(
                      label: 'Device credential available',
                      value: status.canDeviceCredential ? 'Yes' : 'No',
                    ),
                    _KeyValueRow(
                      label: 'Strong OR credential available',
                      value: status.canStrongOrCredential ? 'Yes' : 'No',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Authenticate',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _authInProgress ? null : _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(_authInProgress ? 'Authenticating…' : 'Authenticate'),
                  ),
                  const SizedBox(height: 12),
                  if (_authError != null)
                    Text(
                      _authError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    )
                  else if (_lastAuth != null)
                    _AuthResultView(result: _lastAuth!),
                  const SizedBox(height: 4),
                  Text(
                    'Uses Android BiometricPrompt with device-credential fallback when available.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthResultView extends StatelessWidget {
  final AuthResult result;

  const _AuthResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (title, color) = switch (result.status) {
      AuthStatus.success => ('Success', Colors.green),
      AuthStatus.failed => ('Failed', theme.colorScheme.error),
      AuthStatus.canceled => ('Canceled', Colors.orange),
      AuthStatus.error => ('Error', theme.colorScheme.error),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Result: $title',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (result.errorMessage != null)
          Text(
            result.errorMessage!,
            style: theme.textTheme.bodySmall,
          ),
        if (result.errorCode != null)
          Text(
            'Error code: ${result.errorCode}',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

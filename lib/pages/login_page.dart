import 'package:flutter/material.dart';
import '../widgets/responsive_builder.dart';
import '../widgets/custom_button.dart';
import '../services/api/auth_service.dart';
import '../services/api/api_client.dart';
import 'admin_page.dart';
import 'cashier_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  Future<void> login() async {
    // Trim input values to remove accidental spaces
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    // Validate after trimming
    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please fill all fields');
      return;
    }

    // Optional: Debug logs to confirm what's being sent
    debugPrint('📤 Attempting login with username: "$username" (length: ${username.length})');
    debugPrint('📤 Password length: ${password.length}');

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await AuthService.login(username, password);

      if (response != null && response.containsKey('token')) {
        final token = response['token'];
        final roleData = response['role'];

        String? role;
        if (roleData != null) {
          role = roleData.toString().toLowerCase();
        }

        debugPrint('🔑 Login successful - Role: $role');

        ApiClient.setToken(token, role ?? 'unknown');

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminPage()),
          );
        } else if (role == 'cashier') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CashierPage()),
          );
        } else {
          setState(() {
            errorMessage = 'Unknown user role: $role. Please contact administrator.';
          });
        }
      } else {
        setState(() => errorMessage = 'Invalid username or password');
      }
    } catch (e) {
      setState(() => errorMessage = 'Connection error. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout() {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/login.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildLoginForm(),
            ),
          ],
        ),
      ),
    );
  }

  // Tablet Layout
  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/login.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Center(
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: _buildLoginForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/login.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(40),
                child: _buildLoginForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Login Form
  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sign In',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please sign in to continue',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Error Message
        if (errorMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: errorMessage.contains('Unknown')
                  ? Colors.orange.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: errorMessage.contains('Unknown')
                    ? Colors.orange.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: Text(
              errorMessage,
              style: TextStyle(
                color: errorMessage.contains('Unknown')
                    ? Colors.orange.shade800
                    : Colors.red.shade800,
              ),
            ),
          ),

        // Username Field
        TextField(
          controller: usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Custom Login Button
        CustomButton(
          text: 'Login',
          onPressed: login,
          isLoading: isLoading,
          width: double.infinity,
          height: 50,
        ),
      ],
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
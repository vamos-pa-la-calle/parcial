import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  static const Color background = Color(0xFF090B10);
  static const Color cardColor = Color(0xFF141821);
  static const Color blue = Color(0xFF287BFF);
  static const Color lightBlue = Color(0xFF54B4FF);

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF252B38),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // LOGIN CON CORREO
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) context.go('/feed');
    } on FirebaseAuthException catch (e) {
      debugPrint('ERROR LOGIN: ${e.code}');

      String message = 'No se pudo iniciar sesión';

      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Correo o contraseña incorrectos';
      } else if (e.code == 'invalid-email') {
        message = 'Correo no válido';
      } else if (e.code == 'too-many-requests') {
        message = 'Demasiados intentos. Intenta más tarde';
      }

      _showMessage(message);
    } catch (e) {
      debugPrint('ERROR: $e');
      _showMessage('Ocurrió un error inesperado');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // LOGIN CON GOOGLE
  Future<void> _loginWithGoogle() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');

        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance
            .authenticate();

        final googleAuth = googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw Exception('No se recibió el token de Google');
        }

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (mounted) context.go('/feed');
    } on FirebaseAuthException catch (e) {
      debugPrint('ERROR GOOGLE FIREBASE: ${e.code}');
      _showMessage('Error al iniciar con Google: ${e.message}');
    } catch (e) {
      debugPrint('ERROR GOOGLE: $e');
      _showMessage('No se pudo iniciar sesión con Google');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // LOGIN CON FACEBOOK
  Future<void> _loginWithFacebook() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success || result.accessToken == null) {
        if (result.status == LoginStatus.cancelled) {
          _showMessage('Inicio de sesión cancelado');
        } else {
          _showMessage(
            result.message ?? 'No se pudo iniciar sesión con Facebook',
          );
        }
        return;
      }

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) context.go('/feed');
    } on FirebaseAuthException catch (e) {
      debugPrint('ERROR FACEBOOK FIREBASE: ${e.code}');
      _showMessage('Error de Facebook: ${e.message}');
    } catch (e) {
      debugPrint('ERROR FACEBOOK: $e');
      _showMessage('No se pudo iniciar sesión con Facebook');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // CAMPO DE TEXTO
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool password = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: password && _hidePassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: lightBlue,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: lightBlue, size: 21),
        suffixIcon: password
            ? IconButton(
                onPressed: () {
                  setState(() => _hidePassword = !_hidePassword);
                },
                icon: Icon(
                  _hidePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1B202B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 19,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF292F3B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  // BOTÓN SOCIAL
  Widget _socialButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: Icon(icon, color: iconColor, size: 23),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: cardColor,
          side: const BorderSide(color: Color(0xFF303744)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // LUZ DECORATIVA SUPERIOR
          Positioned(
            top: -140,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: blue.withValues(alpha: 0.16),
                    blurRadius: 110,
                    spreadRadius: 35,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 25,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),

                        // LOGO
                        Center(
                          child: Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: const LinearGradient(
                                colors: [blue, lightBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: blue.withValues(alpha: 0.3),
                                  blurRadius: 25,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 58,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Center(
                          child: Text(
                            'PARCIAL VIDEOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Center(
                          child: Text(
                            'Tu mundo de videos comienza aquí',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 42),

                        const Text(
                          '¡Bienvenido de nuevo!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Inicia sesión para continuar',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),

                        const SizedBox(height: 28),

                        // CORREO
                        _buildInput(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu correo';
                            }

                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim())) {
                              return 'Ingresa un correo válido';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // CONTRASEÑA
                        _buildInput(
                          controller: _passwordController,
                          label: 'Contraseña',
                          icon: Icons.lock_outline,
                          password: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 27),

                        // BOTÓN INICIAR SESIÓN
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [blue, lightBlue],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: blue.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'INICIAR SESIÓN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // SEPARADOR
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFF303744))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                'O CONTINÚA CON',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFF303744))),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // GOOGLE
                        _socialButton(
                          text: 'Continuar con Google',
                          icon: Icons.g_mobiledata,
                          iconColor: Colors.redAccent,
                          onPressed: _loginWithGoogle,
                        ),

                        const SizedBox(height: 13),

                        // FACEBOOK
                        _socialButton(
                          text: 'Continuar con Facebook',
                          icon: Icons.facebook,
                          iconColor: const Color(0xFF4595FF),
                          onPressed: _loginWithFacebook,
                        ),

                        const SizedBox(height: 30),

                        // REGISTRO
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              const Text(
                                '¿No tienes una cuenta? ',
                                style: TextStyle(color: Colors.white54),
                              ),
                              GestureDetector(
                                onTap: _loading
                                    ? null
                                    : () => context.go('/registro'),
                                child: const Text(
                                  'Regístrate aquí',
                                  style: TextStyle(
                                    color: lightBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

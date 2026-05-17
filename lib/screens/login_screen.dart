import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_pacient_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegister = GlobalKey<FormState>();

  // Controladors per Iniciar Sessió
  final _emailLoginController = TextEditingController();
  final _passwordLoginController = TextEditingController();

  // Controladors per Crear Compte
  final _emailRegisterController = TextEditingController();
  final _passwordRegisterController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _emailRegisterController.dispose();
    _passwordRegisterController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Mètode per gestionar els errors de Firebase en Català
  void _showErrorSnackBar(String code) {
    String message = "S'ha produït un error en l'autenticació.";
    
    switch (code) {
      case 'user-not-found':
        message = "No existeix cap compte amb aquest correu electrònic.";
        break;
      case 'wrong-password':
        message = "La contrasenya és incorrecta.";
        break;
      case 'email-already-in-use':
        message = "Aquest correu electrònic ja està registrat en un altre compte.";
        break;
      case 'invalid-email':
        message = "El format del correu electrònic no és vàlid.";
        break;
      case 'weak-password':
        message = "La contrasenya és massa feble (mínim 6 caràcters).";
        break;
      case 'user-disabled':
        message = "Aquest usuari ha estat deshabilitat.";
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // MÈTODE PER INICIAR SESSIÓ
  Future<void> _login() async {
    if (!_formKeyLogin.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailLoginController.text.trim(),
        password: _passwordLoginController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuPacientScreen()), // El nom de la teva pantalla
    );

      // La navegació és reactiva gràcies al StreamBuilder del main.dart
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error inesperat de connexió.")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // MÈTODE PER REGISTRAR-SE (Inicia sessió automàticament en crear el compte)
  Future<void> _register() async {
    if (!_formKeyRegister.currentState!.validate()) return;
    if (_passwordRegisterController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Les contrasenyes no coincideixen."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Això crea l'usuari i alhora l'autentica directament al Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailRegisterController.text.trim(),
        password: _passwordRegisterController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuPacientScreen()), 
    );

      // Netegem els camps del registre per seguretat/bona pràctica
      _emailRegisterController.clear();
      _passwordRegisterController.clear();
      _confirmPasswordController.clear();

      // El StreamBuilder del teu main.dart detectarà el nou usuari 
      // i us redirigirà directament a la pantalla principal (Home).

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error inesperat en crear el compte.")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KneeLife'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.login), text: "Iniciar Sessió"),
              Tab(icon: Icon(Icons.person_add), text: "Crear compte"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // PESTANYA 1: INICIAR SESSIÓ
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKeyLogin,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            const Text(
                              "Benvingut/da de nou",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 30),
                            TextFormField(
                              controller: _emailLoginController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correu electrònic',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Introdueix el teu correu'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordLoginController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Contrasenya',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Introdueix la teva contrasenya'
                                  : null,
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Entrar", style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // PESTANYA 2: CREAR COMPTE
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKeyRegister,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              "Registra el teu compte",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 30),
                            TextFormField(
                              controller: _emailRegisterController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correu electrònic',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Introdueix un correu electrònic'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordRegisterController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Contrasenya',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Introdueix una contrasenya';
                                }
                                if (value.length < 6) {
                                  return 'La contrasenya ha de tenir mínim 6 caràcters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirmar contrasenya',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Confirma la teva contrasenya'
                                  : null,
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Registrar-se", style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
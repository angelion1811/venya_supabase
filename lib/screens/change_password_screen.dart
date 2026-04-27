import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ven_app/Services/supabase_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final passwordTextEditingController = TextEditingController();
  final confirmPasswordTextEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await SupabaseService.updatePassword(
        passwordTextEditingController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        Fluttertoast.showToast(msg: "Contraseña actualizada exitosamente.");
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: "Error: ${result['message']}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: darkTheme ? Colors.amber.shade400 : Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Cambiar Contraseña",
            style: TextStyle(color: darkTheme ? Colors.amber.shade400 : Colors.blue, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.lock_reset,
              size: 100,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              "Ingresa tu nueva contraseña a continuación.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: passwordTextEditingController,
                    obscureText: true,
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    decoration: InputDecoration(
                      hintText: "Nueva Contraseña",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.lock, color: darkTheme ? Colors.amber.shade400 : Colors.grey),
                    ),
                    validator: (text) {
                      if (text == null || text.isEmpty) return "La contraseña no puede estar vacía";
                      if (text.length < 6) return "Mínimo 6 caracteres";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: confirmPasswordTextEditingController,
                    obscureText: true,
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    decoration: InputDecoration(
                      hintText: "Confirmar Nueva Contraseña",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: darkTheme ? Colors.amber.shade400 : Colors.grey),
                    ),
                    validator: (text) {
                      if (text != passwordTextEditingController.text) return "Las contraseñas no coinciden";
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      foregroundColor: darkTheme ? Colors.black : Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Actualizar Contraseña', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

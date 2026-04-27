import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ven_app/Services/supabase_service.dart';
import 'package:ven_app/screens/change_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  const VerifyCodeScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final codeTextEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await SupabaseService.verifyRecoveryCode(
        widget.email,
        codeTextEditingController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        Fluttertoast.showToast(msg: "Código verificado. Ahora puedes cambiar tu contraseña.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const ChangePasswordScreen()),
        );
      } else {
        Fluttertoast.showToast(msg: "Error: ${result['message']}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: darkTheme ? Colors.amber.shade400 : Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Verificar Código",
            style: TextStyle(color: darkTheme ? Colors.amber.shade400 : Colors.blue, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.mark_email_read_outlined,
              size: 100,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              "Hemos enviado un código a ${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: codeTextEditingController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: InputDecoration(
                      hintText: "000000",
                      hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 8),
                      filled: true,
                      fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (text) {
                      if (text == null || text.isEmpty) return "Ingresa el código";
                      if (text.length < 6) return "El código no puede ser menor a 6 dígitos";
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
                        : const Text('Verificar Código', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      SupabaseService.resetPassword(widget.email);
                      Fluttertoast.showToast(msg: "Código reenviado.");
                    },
                    child: Text(
                      "Reenviar código",
                      style: TextStyle(color: darkTheme ? Colors.amber.shade400 : Colors.blue),
                    ),
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

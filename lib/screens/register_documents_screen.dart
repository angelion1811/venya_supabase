import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ven_app/infoHandler/app_info.dart';
import 'package:ven_app/widgets/file_selector.dart';
import '../Services/supabase_service.dart';
import '../splashScreen/splash_screen.dart';

class RegisterDocumentsScreen extends StatefulWidget {
  const RegisterDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<RegisterDocumentsScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterDocumentsScreen> with TickerProviderStateMixin {
  XFile? imageSelfie, imageDocument, imageSelfieWithDocument;
  String urlOfUploadedImageSelfie = "", urlOfUploadedImageDocument = "", urlOfUploadedImageSelfieWithDocument = "";

  bool isSubmitted = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  int get _completedCount {
    int count = 0;
    if (imageSelfie != null) count++;
    if (imageDocument != null) count++;
    if (imageSelfieWithDocument != null) count++;
    return count;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => isSubmitted = true);
        Map<String, dynamic> documents = {
          "imageSelfie": urlOfUploadedImageSelfie,
          "imageDocument": urlOfUploadedImageDocument,
          "imageSelfieWithDocument": urlOfUploadedImageSelfieWithDocument,
        };

        dynamic res = await SupabaseService.addUserDocuments(documents);
        
        if (res['statusCode'] == 400) {
          var errors = res['errors'] as Map<String, dynamic>;
          for (String key in errors.keys) {
            for (String value in errors[key]) {
              await Fluttertoast.showToast(msg: "$key: $value");
            }
          }
          setState(() => isSubmitted = false);
        } else if (res['statusCode'] == 201 || res['statusCode'] == 200) {
          await Fluttertoast.showToast(msg: "Documentos de Identificación guardados, Felicitaciones");
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (c) => const SplashScreen()));
        } else if (res['statusCode'] == 401) {
          Provider.of<AppInfo>(context, listen: false).updateToken('');
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (c) => const SplashScreen()));
        } else {
          await Fluttertoast.showToast(msg: "Estatus: ${res['statusCode']}");
          setState(() => isSubmitted = false);
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Error: $e");
        setState(() => isSubmitted = false);
      }
    } else {
      Fluttertoast.showToast(msg: "No todos los campos están llenos");
      setState(() => isSubmitted = false);
    }
  }

  Future<void> chooseImageFromCamera(int typeOfFile) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        switch (typeOfFile) {
          case 1:
            imageSelfie = pickedFile;
            break;
          case 2:
            imageDocument = pickedFile;
            break;
          case 3:
            imageSelfieWithDocument = pickedFile;
            break;
        }
      });
    }
  }

  Future<String> uploadImageToStorage(XFile? xFile, String documentType) async {
    if (xFile == null) return '';
    String fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await SupabaseService.uploadFile(
      file: File(xFile.path),
      bucketName: 'user-documents',
      folderPath: 'documents',
      fileName: fileName,
    );

    if (result['success'] == true) {
      return result['url'] as String;
    } else {
      throw Exception(result['message'] ?? 'Error al subir imagen');
    }
  }

  Future<void> uploadImagesToStorage() async {
    if (imageSelfie == null || imageDocument == null || imageSelfieWithDocument == null) {
      Fluttertoast.showToast(msg: "Por favor, complete todos los documentos");
      return;
    }

    try {
      setState(() => isSubmitted = true);
      urlOfUploadedImageSelfie = await uploadImageToStorage(imageSelfie, 'selfie');
      urlOfUploadedImageDocument = await uploadImageToStorage(imageDocument, 'document');
      urlOfUploadedImageSelfieWithDocument = await uploadImageToStorage(imageSelfieWithDocument, 'selfie_with_document');
      _submit();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error al subir a almacenamiento: $e");
      setState(() => isSubmitted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final Color accentColor = darkTheme ? Colors.amber.shade400 : Colors.blue;
    final Color bgColor = darkTheme ? const Color(0xFF121212) : const Color(0xFFF5F7FF);
    final Color surfaceColor = darkTheme ? Colors.black45 : Colors.white;
    final Color textPrimary = darkTheme ? Colors.white : Colors.black87;
    final Color textSecondary = darkTheme ? Colors.white60 : Colors.grey[700]!;

    const int total = 3;
    final int completed = _completedCount;
    final double progress = completed / total;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: accentColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: darkTheme
                            ? [Colors.amber.shade800, Colors.amber.shade400]
                            : [Colors.blue.shade900, Colors.blue.shade600],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.person_pin_outlined, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Registro de Identidad",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Verificación de Usuario",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Progreso",
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "$completed / $total",
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: accentColor.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.9,
                          children: [
                            DocumentCard(
                              xFile: imageSelfie,
                              label: "Foto de Perfil",
                              icon: Icons.face_outlined,
                              darkTheme: darkTheme,
                              onTap: () => chooseImageFromCamera(1),
                            ),
                            DocumentCard(
                              xFile: imageDocument,
                              label: "Documento de Identidad",
                              icon: Icons.badge_outlined,
                              darkTheme: darkTheme,
                              onTap: () => chooseImageFromCamera(2),
                            ),
                            DocumentCard(
                              xFile: imageSelfieWithDocument,
                              label: "Selfie con Documento",
                              icon: Icons.camera_front_outlined,
                              darkTheme: darkTheme,
                              onTap: () => chooseImageFromCamera(3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: isSubmitted
                                  ? [Colors.grey.shade400, Colors.grey.shade500]
                                  : darkTheme
                                      ? [Colors.amber.shade700, Colors.amber.shade400]
                                      : [Colors.blue.shade900, Colors.blue.shade600],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (!isSubmitted) {
                                  uploadImagesToStorage();
                                }
                              },
                              child: Center(
                                child: isSubmitted
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            "Subiendo...",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 22),
                                          SizedBox(width: 10),
                                          Text(
                                            "Guardar Documentos",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


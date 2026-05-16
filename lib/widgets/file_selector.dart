import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Premium document card for grid-based document upload UI.
class DocumentCard extends StatelessWidget {
  final XFile? xFile;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool darkTheme;

  const DocumentCard({
    Key? key,
    this.xFile,
    this.label = "",
    this.icon = Icons.camera_alt_outlined,
    this.onTap,
    this.darkTheme = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasImage = xFile != null;
    final Color accentColor = darkTheme ? Colors.amber.shade400 : Colors.blue;
    final Color cardBg = darkTheme ? Colors.black45 : const Color(0xFFF0F4FF);
    final Color borderColor = hasImage
        ? (darkTheme ? Colors.green.shade400 : Colors.green.shade700)
        : (darkTheme ? Colors.white12 : Colors.blue.withOpacity(0.2));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: hasImage ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: hasImage
                  ? (darkTheme
                      ? Colors.green.withOpacity(0.2)
                      : Colors.green.withOpacity(0.15))
                  : Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Imagen o placeholder
              if (hasImage)
                Positioned.fill(
                  child: Image.file(
                    File(xFile!.path),
                    fit: BoxFit.cover,
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accentColor, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: darkTheme
                                ? Colors.white70
                                : Colors.blueGrey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Overlay oscuro + label cuando tiene imagen
              if (hasImage)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
                        ],
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Badge de éxito
              if (hasImage)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),

              // Ícono de cámara si no tiene imagen
              if (!hasImage)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, color: accentColor, size: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Mantener compatibilidad con código existente
Widget FileSelector({
  XFile? xFile,
  String label = "",
  void Function()? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        xFile == null
            ? Container(
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: const AssetImage("images/avatar.png"),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(86),
                    child: Image.asset(
                      "images/avatar.png",
                      fit: BoxFit.cover,
                      width: 140,
                      height: 140,
                    ),
                  ),
                ),
              )
            : Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  image: DecorationImage(
                    fit: BoxFit.fitHeight,
                    image: FileImage(File(xFile!.path)),
                  ),
                ),
              ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    ),
  );
}
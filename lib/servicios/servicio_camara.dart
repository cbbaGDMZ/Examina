import 'dart:io';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';

class ServicioCamara {
  final _documentScanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      pageLimit: 1,
    ),
  );

  /// Abre el escáner de documentos de Google ML Kit y retorna la ruta de la imagen.
  Future<String?> escanearHoja() async {
    try {
      final result = await _documentScanner.scanDocument();
      if (result.images.isNotEmpty) {
        return result.images.first;
      }
    } catch (e) {
      throw Exception('Error al escanear documento: $e');
    }
    return null;
  }

  /// Limpia los archivos temporales generados por el escáner o capturas previas.
  Future<void> limpiarTemporales() async {
    final tempDir = await getTemporaryDirectory();
    final List<FileSystemEntity> files = tempDir.listSync();
    
    for (var file in files) {
      if (file is File && (file.path.endsWith('.jpg') || file.path.endsWith('.jpeg'))) {
        try {
          await file.delete();
        } catch (e) {
          // Ignorar errores al borrar archivos individuales
        }
      }
    }
  }

  void dispose() {
    _documentScanner.close();
  }
}

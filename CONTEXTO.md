# Contexto - Examina

## Qué hace la app
Escanea exámenes de opción múltiple (burbujas A, B, C, D, E), compara las respuestas con una hoja patrón y calcula la nota automáticamente.

## Flujo de pantallas
1. Inicio → botón "Iniciar corrección"
2. Seleccionar área (materia, ej: Tecnología, Medicina)
3. Tipo de puntaje: Fijo o Variado
4. Configurar puntaje (cantidad de preguntas y valor por pregunta)
5. Escanear hoja patrón (hoja con todas las respuestas correctas)
6. Escanear exámenes (uno por uno, muestra contador)
7. Ver resultados (nota final, correctas, incorrectas, detalle por pregunta)
8. Pantalla de error de lectura (cuando no puede leer bien la hoja)

## Reglas de negocio
- **Puntaje fijo**: todas las preguntas valen igual (actualmente implementado)
- **Puntaje variado**: cada pregunta tiene su propio valor (no implementado aún)
- El puntaje total debe ser exactamente 100 puntos
- Rango de preguntas: 20 - 100 preguntas

## Fase 1 - Scanner Pipeline (COMPLETADO)
### Pipeline de procesamiento de imagen:
1. **Escaneo**: Google ML Kit Document Scanner
2. **Detección de marcadores**: 4 cuadrados negros en las esquinas
3. **Corrección de perspectiva**: Rotación y pérdida
4. **Validación geométrica**: Verifica que los 4 marcadores estén en las esquinas
5. **Quality check**: Valida oscuridad, brillo, contraste
6. **Detección de enfoque**: Detecta imagen borrosa
7. **Normalización**: Convierte a 800x1200 pixeles
8. **Re-scaneo**: Hasta 3 intentos si falla

### Hoja patrón
- 4 marcadores negros en las 4 esquinas
- Alto contraste (negro puro)
- Siempre en la misma posición
- Margen suficiente para que la cámara no corte los marcadores

## Tecnologías
- **Flutter** (Android/iOS/Web)
- **google_mlkit_document_scanner**: Escaneo de documentos
- **image package**: Procesamiento de imagen
- **sqflite**: Base de datos local (planea migrar a Isar)
- **flutter_riverpod**: State management

## Estado actual
- UI básica funcionando con navegación
- Pantalla puntaje fijo navega al escáner
- Servicio de procesamiento de imagen completo
- OMR simulado (no detecta respuestas reales todavía)

## Pendiente
- Detección real de respuestas (burbujas/OMR)
- Comparación automática con hoja patrón
- Integración con base de datos
- Migración a Isar
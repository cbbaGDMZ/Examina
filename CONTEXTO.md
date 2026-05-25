# Contexto - Examina (MODO DEMO)

## Objetivo de la Demo
Obtener un pipeline funcional de principio a fin: Cargar imagen -> Procesar -> Detectar -> Mostrar resultado.

## Estado Actual
- **UI básica**: Navegación funcional entre inicio, configuración y escaneo.
- **Scanner**: Carga de archivos y procesamiento en Isolate implementado.
- **Procesamiento**: Rotación y normalización a 800x1200 funcional. (En depuración: problema de imagen negra).
- **OMR**: Motor real con layout hardcodeado e intensidad de píxeles implementado (Fase 2).

---

## PLAN REAL PARA LA DEMO

### FASE 1 — Scanner Confiable (EN PROCESO)
- [x] Quitar validaciones agresivas (oscuridad/brillo ya no bloquean).
- [ ] Solucionar problema de visualización (imagen negra).
- [x] Forzar normalización (Grayscale + Redimensionado).

### FASE 2 — OMR Mínimo Viable (COMPLETADO)
- [x] Layout Hardcodeado (Coordenadas fijas para 20 preguntas).
- [x] Lectura de intensidad (Promedio de píxeles por burbuja).
- [x] Decisión simple (Opción más oscura = respuesta).

### FASE 3 — Corrección Básica (PRÓXIMO)
- [ ] Hardcodear respuestas correctas (Lista de referencia).
- [ ] Comparación directa (Correctas vs Detectadas).
- [ ] Cálculo de puntaje simple (Aciertos / Total * 100).

### FASE 4 — Pantalla de Resultado Mínima
- [ ] Mostrar lista de respuestas detectadas.
- [ ] Mostrar respuestas correctas.
- [ ] Mostrar puntaje final destacado.

### FASE 5 — Flujo Completo
- [ ] Asegurar que el paso de datos entre pantallas sea fluido y sin errores.

---

## Lo que se ignora para la Demo
- Base de datos (Persistencia).
- Cámara real (Se usará carga de archivos controlados).
- UX perfecto y diseño detallado.
- Puntaje variado y configuraciones complejas.

## Criterio de Éxito
"Funciona de principio a fin sin romperse durante la presentación".

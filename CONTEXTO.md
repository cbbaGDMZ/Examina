# Qué hace la app Examin

Escanea exámenes de opción múltiple (burbujas rellenas a mano),
compara las respuestas con una hoja patrón y calcula la nota automáticamente.

## Flujo de pantallas
1. Inicio → botón "Iniciar corrección"
2. Seleccionar área (materia, ej: Tecnología)
3. Tipo de puntaje: Fijo o Distinto por pregunta
4. Configurar puntaje (cantidad de preguntas y valor por pregunta)
5. Escanear hoja patrón (hoja con todas las respuestas correctas)
6. Escanear exámenes (uno por uno, muestra contador)
7. Ver resultados (nota final, correctas, incorrectas, detalle por pregunta)
8. Pantalla de error de lectura (cuando no puede leer bien la hoja)

## Reglas de negocio
- Puntaje fijo: todas las preguntas valen igual
- Puntaje distinto: cada pregunta tiene su propio valor
- El puntaje total se calcula automáticamente
- La app funciona con internet (modelos unbundled permitidos)
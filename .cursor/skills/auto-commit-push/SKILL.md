---
name: auto-commit-push
description: >-
  Tras cambios de código en el repo controd, hace commit y push a origin sin
  pedir confirmación al usuario. Usar en este proyecto cuando el usuario pida
  subir cambios, al cerrar una tarea con archivos modificados, o cuando aplique
  la regla de no volver a preguntar por permiso para git push.
---

# Commit y push automático (sin pedir permiso)

## Instrucción del usuario (texto literal)

cada moficacion de que se haga subelo sin que me pidas permiso

(Aplica la intención: cada modificación hecha en el trabajo → subir al remoto sin preguntar si puede hacer push.)

## Qué hacer

1. Cuando completes cambios en archivos del repositorio y el usuario no haya pedido explícitamente **no** subir:
   - `git status` para ver qué cambió.
   - `git add` solo los archivos que forman parte del trabajo (no añadas basura ni secretos).
   - `git commit -m "..."` con mensaje breve en español o inglés, oración completa, que describa el cambio.
   - `git push` hacia `origin` en la rama actual (p. ej. `main`).
2. **No** pidas confirmación del tipo «¿Quieres que haga push?» ni esperes un «sí» explícito para subir, salvo que el usuario cancele o diga que no suba.
3. Si `git push` falla (red, auth, conflicto): intenta lo razonable (reintento, mensaje de error claro); no inventes credenciales.
4. Si no hay cambios que commitear, no hagas commit vacío.

## Excepciones

- Si el usuario dice **no subas**, **no hagas push**, o **solo local**, respeta eso.
- No fuerces `--force` a `main` ni reescrituras de historia salvo instrucción explícita y segura.

## Mensajes de commit

- Una línea, imperativo o descriptivo: qué cambió y por qué (breve).
- Ejemplo: `Armado: mover trabajador entre líneas y lista con scroll.`

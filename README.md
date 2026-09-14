# java-template

Template de proyecto Java 25 con Maven multi-módulo, TDD listo para usar, CI en GitHub Actions y
releases semánticos por conventional commits. Es el esqueleto que comparten `deidad`, `holy-wars` y
`tabpro`, con placeholders en vez de nombres.

**No compila tal cual**: los archivos llevan placeholders `{{...}}` que se reemplazan al renderizar.

## Qué trae

- `domain/`: módulo Java puro, sin framework, con JUnit y AssertJ listos para el primer test.
- Un módulo de aplicación según el **sabor**:
  - `libgdx` → `game/`: launcher lwjgl3, ventana 1280×720, `.deb` con entrada de menú e ícono.
  - `plain` → `app/`: un `Main` sin framework, `.deb` con el comando en `/usr/bin`.
- `.github/workflows/ci.yml`: job `build` (`mvn -B verify`) en cada PR y push a `main`, y job
  `release` con semantic-release en cada push a `main`.
- Un **modo de release**:
  - `tag-only`: la versión vive en el tag, el Release de GitHub y el `.deb`; nada se commitea de
    vuelta y los poms quedan en `0.0.0-SNAPSHOT`. Compatible con un ruleset en `main` que exija PR.
  - `commit-back`: además actualiza `CHANGELOG.md` y los poms en `main` con un commit del bot.
    Requiere que nada bloquee ese push (sin ruleset activo).
- `.tcr` con `mvn -q -B test`, `scripts/prepare-release.sh`, `.gitignore`, LICENSE MIT.

## Cómo usarlo

1. Creá el repo desde el template:
   ```
   gh repo create <owner>/<slug> --template gstn-caruso/java-template --public
   ```
2. Clonalo y renderizalo:
   ```
   bash .template/render.sh --slug <slug> --name "<Nombre>" --description "<descripción>" \
     --owner <owner> --flavor libgdx|plain --release tag-only|commit-back
   ```
   Opcionales: `--package`, `--class`, `--group-id`, `--author`, `--email`, `--year`.
3. `mvn -B verify`, commit inicial, tag `v0.1.0`, push. La skill `new-java-project` de Claude Code
   hace estos pasos y además configura el repo (squash-only, ruleset).

## Placeholders

| Placeholder | Ejemplo | Default |
|---|---|---|
| `{{slug}}` | `holy-wars` | obligatorio |
| `{{name}}` | `Holy Wars` | obligatorio |
| `{{description}}` | `Juego hecho con libGDX en Java 25.` | obligatorio |
| `{{owner}}` | `gstn-caruso` | obligatorio |
| `{{package}}` | `holywars` | slug sin guiones |
| `{{class}}` | `HolyWars` | slug en PascalCase |
| `{{group_id}}` | `io.github.gstncaruso` | `io.github.<owner sin guiones>` |
| `{{author}}` / `{{email}}` | `Gastón Caruso` / `gstn.caruso@gmail.com` | `git config user.name` / `user.email` |
| `{{year}}` | `2026` | año actual |
| `{{app_module}}` | `game` / `app` | según el sabor |
| `{{version}}` | `0.0.0-SNAPSHOT` / `0.1.0-SNAPSHOT` | según el modo de release |

## Desarrollo del template

`bash .template/render-test.sh` prueba el renderer sin Maven. La CI del template
(`.github/workflows/template-ci.yml`) renderiza cada combinación sabor × modo y corre `mvn -B verify`
sobre el resultado.

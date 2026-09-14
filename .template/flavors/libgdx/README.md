# {{name}}

{{description}}

## Jugar

```
mvn -q compile exec:exec
```

Abre una ventana con el juego.

## Testear

```
mvn -B test
```

Cada merge a `main` publica un release semántico según el prefijo del commit (`feat:` sube minor,
`fix:` y `perf:` suben patch; `chore:`, `docs:`, `ci:`, `test:`, `refactor:`, `build:`, `style:` no publican).

## Instalación

Requiere Java 25. Bajá el `.deb` del [último release](https://github.com/{{owner}}/{{slug}}/releases/latest)
en GitHub e instalalo:

```
sudo apt install ./{{slug}}_<versión>_all.deb
```

Esto deja el comando `{{slug}}` disponible y agrega {{name}} al menú de aplicaciones.

# {{name}}

{{description}}

## Ejecutar

```
mvn -q compile exec:exec
```

Imprime el nombre del proyecto.

## Testear

```
mvn -B test
```

Cada merge a `main` publica un release semántico según el prefijo del commit (`feat:` sube minor,
`fix:` y `perf:` suben patch; un `!` o un footer `BREAKING CHANGE:` suben major;
`chore:`, `docs:`, `ci:`, `test:`, `refactor:`, `build:`, `style:` no publican).

## Instalación

Requiere Java 25. Bajá el `.deb` del [último release](https://github.com/{{owner}}/{{slug}}/releases/latest)
en GitHub e instalalo:

```
sudo apt install ./{{slug}}_<versión>_all.deb
```

Esto deja el comando `{{slug}}` disponible.

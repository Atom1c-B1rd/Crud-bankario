# crud-bankario basico

Proyecto de ejemplo que conecta programas COBOL con una base de datos SQLite, usando un wrapper escrito en C como puente entre ambos.

## ¿Cómo funciona?

1. El programa COBOL llama a funciones del wrapper en C.
2. El wrapper en C usa la librería de SQLite para ejecutar las consultas.
3. Los resultados se devuelven al programa COBOL.

## Requisitos

- Compilador COBOL (GnuCOBOL)
- GCC
- SQLite3 (librería de desarrollo: `libsqlite3-dev`)

## Uso

```bash
make run     # Compila y ejecuta el programa
make clean   # Limpia los archivos generados
```

## Estructura

```
.
├── banking.cob   # Lógica principal en COBOL
├── db_wrapperc       # Puente C <-> SQLite
└── bank.db     # Base de datos SQLite
```

## Licencia

MIT

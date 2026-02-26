### 2.1. Diferencia entre `/* skip whitespace */` y devolver un token

* **Devolver un token (ej. `return 'NUMBER';`):** Significa que el analizador léxico ha reconocido un patrón válido, lo empaqueta bajo una categoría o etiqueta (como `NUMBER` u `OP`) y **se lo envía al analizador sintáctico (parser)**. Estos tokens son las piezas que el parser utilizará para construir el árbol de la expresión matemática.
* **`/* skip whitespace */`:** En esta acción no existe una instrucción `return`. Cuando el lexer encuentra espacios, tabulaciones o saltos de línea (reconocidos por la expresión regular `\s+`), ejecuta el bloque vacío o el comentario, avanza su puntero y **los ignora**. El parser nunca recibe estos caracteres, lo cual es el comportamiento deseado, ya que los espacios no alteran el valor de una expresión matemática.

### 2.2. Secuencia exacta de tokens producidos para la entrada `123**45+@`

El lexer procesa la entrada de izquierda a derecha aplicando las reglas definidas. La secuencia exacta producida es:

1. `NUMBER` (coincide con `123`)
2. `OP` (coincide con `**`)
3. `NUMBER` (coincide con `45`)
4. `OP` (coincide con `+`)
5. `INVALID` (coincide con `@`, ya que no encaja en las reglas numéricas ni de operadores, cayendo en la regla comodín `.`)

### 2.3. Por qué `**` debe aparecer antes que `[-+*/]`

En Jison, cuando hay ambigüedad, las reglas léxicas se evalúan **en el orden en el que están escritas** (de arriba hacia abajo). 

Si la clase de caracteres `[-+*/]` (que incluye el asterisco simple `*`) estuviera declarada antes que `"**"`, al procesar el texto `**`, el lexer coincidiría con el primer `*` y devolvería inmediatamente un token `OP` (multiplicación). Luego leería el segundo `*` y devolvería otro `OP`. Al colocar `"**"` primero, le damos prioridad a la coincidencia más larga, asegurando que el símbolo de potencia se reconozca correctamente como un único operador.

### 2.4. Cuándo se devuelve `EOF`

El token `EOF` (*End Of File* o Fin de Archivo) se devuelve cuando el analizador léxico alcanza el **final de la cadena o archivo de entrada**. Su función es enviarle una señal explícita al analizador sintáctico (parser) indicando que no hay más datos por leer, lo que le permite concluir el análisis y devolver el resultado de la expresión evaluada.

### 2.5. Por qué existe la regla `.` que devuelve `INVALID`

La regla `.` es una expresión regular que coincide con cualquier carácter individual. Al estar ubicada al final del bloque léxico, actúa como un **comodín de seguridad (catch-all)**. 

Si el lexer encuentra un carácter que no es un espacio, ni un número, ni un operador válido (por ejemplo, una letra o un símbolo como `@`), las reglas anteriores fallarán, pero esta última regla lo capturará. Devolver `INVALID` permite detectar caracteres no permitidos y manejar el error léxico de forma elegante, evitando que el escáner se bloquee o lance una excepción no controlada.
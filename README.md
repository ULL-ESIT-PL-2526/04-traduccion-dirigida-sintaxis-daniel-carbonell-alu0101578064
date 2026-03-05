# Informe de Práctica #4: Traducción dirigida por sintaxis: léxico

Este repositorio contiene la implementación de una calculadora basada en una Gramática Independiente del Contexto (CFG) y una Definición Dirigida por la Sintaxis (SDD), utilizando **Jison** para generar el analizador (parser) y **Jest** para las pruebas unitarias.

A continuación, se detallan los pasos realizados y las modificaciones aplicadas durante la práctica.

---

## 1. Configuración y Ejecución Inicial

Para inicializar el proyecto y comprobar el estado base del código, se ejecutaron los siguientes comandos:

1. **`npm i`**: Instalación de las dependencias definidas en el `package.json` (incluyendo Jison y Jest).
2. **`npx jison src/grammar.jison -o src/parser.js`**: Compilación de la gramática. Este comando toma la definición léxica y sintáctica (`grammar.jison`) y genera el código JavaScript del analizador (`parser.js`).
3. **`npm test`**: Ejecución de la suite de pruebas base con Jest para comprobar que la calculadora funcionaba correctamente con números enteros simples.

---

## 2. Análisis del Analizador Léxico Base (Preguntas Teóricas)

Se analizó el bloque `%lex` inicial del archivo `grammar.jison`. A continuación, se resuelven las cuestiones teóricas planteadas:

### 2.1. Diferencia entre `/* skip whitespace */` y devolver un token
* **Devolver un token (ej. `return 'NUMBER';`):** El analizador léxico reconoce un patrón, lo etiqueta (como `NUMBER` u `OP`) y lo envía al analizador sintáctico (parser) para que forme parte del árbol de evaluación de la expresión matemática.
* **`/* skip whitespace */`:** Al no tener una instrucción `return`, cuando el lexer encuentra espacios o saltos de línea (mediante la regla `\s+`), simplemente avanza su puntero y los ignora. El parser nunca recibe estos caracteres, lo cual es correcto ya que no afectan el cálculo.

### 2.2. Secuencia exacta de tokens producidos para la entrada `123**45+@`
El analizador procesa la entrada de izquierda a derecha y produce:
1. `NUMBER` (123)
2. `OP` (`**`)
3. `NUMBER` (45)
4. `OP` (`+`)
5. `INVALID` (`@`, capturado por la regla comodín `.`)

### 2.3. Por qué `**` debe aparecer antes que `[-+*/]`
Las reglas léxicas se evalúan en orden de aparición. Si `[-+*/]` estuviera antes, al leer `**`, el lexer haría match con el primer `*` devolviendo un `OP` (multiplicación), y luego leería el segundo `*` como otro `OP`. Colocar `"**"` primero asegura que se aplique la coincidencia más larga (maximal munch) y se interprete como un único operador de potencia.

### 2.4. Cuándo se devuelve `EOF`
El token `EOF` (*End Of File*) se devuelve cuando el analizador léxico llega al final del texto de entrada. Es una señal para que el parser sepa que no hay más tokens por leer y puede finalizar la evaluación del árbol sintáctico.

### 2.5. Explicación de la regla `.` que devuelve `INVALID`
La regla `.` coincide con cualquier carácter. Al estar al final, actúa como un comodín (*catch-all*). Si un carácter no es un espacio, número ni operador, caerá en esta regla. Devolver `INVALID` permite manejar el error léxico limpiamente en lugar de que el programa falle.

---

## 3. Modificación: Soporte para comentarios de una línea

Se modificó el archivo `src/grammar.jison` para que la calculadora ignore los comentarios que comiencen por `//`. Se añadió la siguiente expresión regular **antes** de las reglas de los operadores aritméticos para evitar conflictos con la división (`/`):

```javascript
"//".* { /* skip comments */ }
```

Al igual que con los espacios en blanco, esta regla no tiene instrucción `return`, por lo que el lexer lee el comentario hasta el final de la línea y avanza sin enviarle tokens al parser.

---

## 4. Modificación: Soporte para números en punto flotante y notación científica

Se actualizó la expresión regular que definía los números enteros (`[0-9]+`) para que sea capaz de reconocer decimales y notación científica (ej. `2.35e-3`, `2.35E-3`, `2.35`, `23`). La regla en `grammar.jison` fue reemplazada por:

```javascript
[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?   { return 'NUMBER'; }
```

**Desglose de la regla:**
* `[0-9]+`: Captura la parte entera obligatoria.
* `(\.[0-9]+)?`: Grupo opcional para la parte decimal.
* `([eE][-+]?[0-9]+)?`: Grupo opcional para el exponente científico, aceptando 'e' o 'E' y un signo opcional.

---

## 5. Actualización de las Pruebas (Jest)

Tras realizar las modificaciones en el Lexer y regenerar el parser (`npx jison src/grammar.jison -o src/parser.js`), se actualizó el archivo `__tests__/parser.test.js`:

1. Se eliminó la prueba `expect(() => parse("3.5")).toThrow();` ya que los números decimales ahora son sintaxis válida.
2. Se añadieron nuevos bloques de pruebas para verificar el correcto funcionamiento de las nuevas características implementadas:

```javascript
describe('Nuevas modificaciones del analizador léxico', () => {
  test('should parse floating point numbers and scientific notation', () => {
    expect(parse("2.35")).toBe(2.35);
    expect(parse("2.35e-3")).toBe(0.00235);
    expect(parse("2.35e+3")).toBe(2350);
    expect(parse("2.35E-3")).toBe(0.00235);
    expect(parse("23")).toBe(23);
    
    expect(parse("2.5 * 2")).toBe(5);
    expect(parse("1e3 + 500")).toBe(1500);
  });

  test('should skip single-line comments', () => {
    expect(parse("2 + 3 // esto es una suma")).toBe(5);
    expect(parse("// comentario inicial\n4 * 5")).toBe(20);
    expect(parse("10 // el primer numero\n / 2")).toBe(5);
  });
});
```

Todas las pruebas en la suite final (`npm test`) se ejecutan y pasan correctamente, confirmando que las modificaciones cumplen con los requisitos de la práctica.

<br>
<hr>
<br>

# Informe de Práctica #5: Traducción dirigida por la sintaxis: gramática

## 1 Partiendo de la gramática y las siguientes frases 4.0-2.0*3.0, 2**3**2 y 7-4/2:

### 1.1. Derivaciones de las frases propuestas

Al ser una gramática estrictamente recursiva por la izquierda y sin niveles jerárquicos (como Términos o Factores), el analizador agrupa las operaciones exclusivamente en el orden en que aparecen. A continuación se muestran las derivaciones más a la izquierda (Leftmost Derivation) que demuestran el error estructural:

**Frase 1: `4.0-2.0*3.0`**
* `L`
* `=> E eof`
* `=> E op(*) T eof` *(La última operación leída, la multiplicación, queda en la raíz del árbol)*
* `=> E op(-) T op(*) T eof`
* `=> T op(-) T op(*) T eof`
* `=> number(4.0) op(-) T op(*) T eof`
* `=> number(4.0) op(-) number(2.0) op(*) T eof`
* `=> number(4.0) op(-) number(2.0) op(*) number(3.0) eof`

> **Fallo matemático:** Sintácticamente, el agrupamiento resultante es `(4.0 - 2.0) * 3.0`, ignorando que la multiplicación tiene mayor precedencia.

**Frase 2: `2**3**2`**
* `L`
* `=> E eof`
* `=> E op(**) T eof`
* `=> E op(**) T op(**) T eof`
* `=> T op(**) T op(**) T eof`
* `=> number(2) op(**) T op(**) T eof`
* `=> number(2) op(**) number(3) op(**) T eof`
* `=> number(2) op(**) number(3) op(**) number(2) eof`

> **Fallo matemático:** Sintácticamente se agrupa como `(2 ** 3) ** 2`, ignorando que la potencia es asociativa por la derecha[cite: 83].

**Frase 3: `7-4/2`**
* `L`
* `=> E eof`
* `=> E op(/) T eof`
* `=> E op(-) T op(/) T eof`
* `=> T op(-) T op(/) T eof`
* `=> number(7) op(-) T op(/) T eof`
* `=> number(7) op(-) number(4) op(/) T eof`
* `=> number(7) op(-) number(4) op(/) number(2) eof`

> **Fallo matemático:** Sintácticamente, el agrupamiento es `(7 - 4) / 2`, restando antes de dividir.

### 1.2. Árboles de análisis sintáctico (Parse Trees)

A partir de las derivaciones anteriores, se generan los siguientes árboles sintácticos. Observando la estructura, se hace evidente cómo la gramática original ($E \rightarrow E \text{ op } T \mid T$) fuerza un orden de evaluación incorrecto al carecer de niveles jerárquicos.

**Árbol para `4.0-2.0*3.0`**

```text
                 L
               /   \
             E       eof
          /  |  \
        /    |    \
      E      *     T
    / | \           |
   E  -  T         3.0
   |     |
   T    2.0
   |
  4.0
```
*(El árbol muestra que la resta queda encapsulada en un subárbol inferior, por lo que el parser la evaluará antes que la multiplicación).*

**Árbol para `2**3**2`**

```text
                 L
               /   \
             E       eof
          /  |  \
        /    |    \
      E     **      T
    / | \           |
   E  ** T         2
   |      |
   T      3
   |
   2
```
*(El árbol demuestra la recursividad por la izquierda, construyendo la operación como `(2**3)**2`, cuando la potencia debería asociar por la derecha).*

**Árbol para `7-4/2`**

```text
                 L
               /   \
             E       eof
          /  |  \
        /    |    \
      E      /      T
    / | \           |
   E  -  T          2
   |     |
   T     4
   |
   7
```
*(Nuevamente, la resta queda en un nivel inferior, resolviéndose antes que la división).*

### 1.3. Orden de evaluación de las acciones semánticas

En un analizador ascendente como los que genera Jison, el árbol se recorre en postorden: primero se evalúan los hijos (de izquierda a derecha) y luego el nodo padre. Las acciones semánticas se disparan desde las hojas hacia la raíz.

* **Para `4.0-2.0*3.0`**: 
  1. `convert(4.0)`
  2. `convert(2.0)`
  3. `operate('-', 4.0, 2.0)`  -> Resultado parcial: 2.0
  4. `convert(3.0)`
  5. `operate('*', 2.0, 3.0)` -> **Resultado final: 6.0** (Matemáticamente incorrecto, debería ser -2.0).

* **Para `2**3**2`**:
  1. `convert(2)`
  2. `convert(3)`
  3. `operate('**', 2, 3)` -> Resultado parcial: 8
  4. `convert(2)`
  5. `operate('**', 8, 2)` -> **Resultado final: 64** (Debería ser 512).

* **Para `7-4/2`**:
  1. `convert(7)`
  2. `convert(4)`
  3. `operate('-', 7, 4)` -> Resultado parcial: 3
  4. `convert(2)`
  5. `operate('/', 3, 2)` -> **Resultado final: 1.5** (Debería ser 5).

### 1.4. Creación de pruebas iniciales (Fallo esperado)

Para comprobar empíricamente los errores de la gramática original, se creó el archivo `__tests__/prec.test.js` con una batería de pruebas unitarias utilizando Jest. Estas pruebas incluían operaciones matemáticas básicas, combinadas y potencias, esperando el resultado matemático correcto.

Al ejecutar la suite (`npm test`), las pruebas **fallaron sistemáticamente**, demostrando que el analizador agrupaba las operaciones estrictamente de izquierda a derecha sin respetar la precedencia.

---

## 2. Implementación de Precedencia y Asociatividad

Para solucionar el problema del orden de evaluación, se reestructuró por completo el archivo `src/grammar.jison` implementando una jerarquía de operadores basada en niveles (Expresiones, Términos, Raíces y Factores).

### 2.1. Modificación del Analizador Léxico (Lexer)
En lugar de devolver un token genérico `OP`, se modificó el lexer para clasificar los operadores según su jerarquía matemática. Además, se refinó la regla de los comentarios para no consumir los saltos de línea (`\r\n`), permitiendo al lexer llevar un conteo correcto de las líneas.

```javascript
\s+                                   { /* skip whitespace */ }
"//"[^\r\n]* { /* skip comments */ }
[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?   { return 'NUMBER'; }
"**"                                  { return 'OPOW'; }
"↑"                                   { return 'OPOW'; }
[*/]                                  { return 'OPMU'; }
[-+]                                  { return 'OPAD'; }
```

### 2.2. Modificación del Analizador Sintáctico (Parser)
Se sustituyeron las reglas recursivas simples por una Definición Dirigida por la Sintaxis (SDD) estratificada:

* **`E` (Expresiones):** Sumas y restas (`OPAD`). Asocian por la izquierda (`E -> E OPAD T`).
* **`T` (Términos):** Multiplicaciones y divisiones (`OPMU`). Tienen mayor precedencia y asocian por la izquierda (`T -> T OPMU R`).
* **`R` (Raíces/Potencias):** Operador de potencia (`OPOW`). Tiene la mayor precedencia de los operadores aritméticos y **asocia por la derecha** (`R -> F OPOW R`).
* **`F` (Factores):** La base numérica.

Para capturar y calcular los valores en Jison, se utilizaron referencias posicionales (`$1`, `$2`, `$3`) para inyectarlos en la función de soporte en JavaScript `operate()`, asignando el resultado al nodo padre (`$$`):

```javascript
E : E OPAD T
    { $$ = operate($2, $1, $3); }
  | T
    { $$ = $1; }
  ;
```

---

## 3. y 4. Soporte para Paréntesis y Números en Punto Flotante

### Soporte para Paréntesis (Punto 4)
Para otorgar la máxima prioridad matemática a las expresiones agrupadas, se introdujeron los paréntesis. 
1. En el Lexer, se añadieron las reglas para emitir los tokens correspondientes:
   ```javascript
   "(" { return '('; }
   ")" { return ')'; }
   ```
2. En el Parser, se añadió una nueva producción a la regla de los Factores (`F`), permitiendo que un factor pueda ser una expresión completa contenida entre paréntesis:
   ```javascript
   F : NUMBER
       { $$ = convert($1); }
     | '(' E ')'
       { $$ = $2; }
     ;
   ```

---

## 5. Actualización y Ejecución de la Suite de Pruebas

Finalmente, se añadieron nuevas pruebas al archivo `prec.test.js` para validar tanto el funcionamiento de los números en punto flotante (Punto 3) como la prioridad de los paréntesis (Punto 5).

```javascript
// Pruebas con números flotantes
test('should respect precedence and associativity with floats', () => {
  expect(parse("2.5 + 3.5 * 2.0")).toBe(9.5);
  expect(parse("10.0 - 1.5 ** 2")).toBe(7.75);
});

// Pruebas con paréntesis
test('should handle parentheses with highest precedence', () => {
  expect(parse("(2 + 3) * 4")).toBe(20);
  expect(parse("2 ** (3 ** 2)")).toBe(512);
  expect(parse("100 / (2 + 3) * 2")).toBe(40);
});
```

Tras regenerar el parser (`npx jison src/grammar.jison -o src/parser.js`), la ejecución de `npm test` finalizó exitosamente (100% PASS), confirmando que la nueva gramática respeta estrictamente las leyes de precedencia y asociatividad matemática.
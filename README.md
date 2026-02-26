# Informe de Práctica: Traducción dirigida por sintaxis: léxico

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
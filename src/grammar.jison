/* Lexer */
%lex
%%
\s+                                   { /* skip whitespace */ }
"//"[^\r\n]*                          { /* skip comments */ }
[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?   { return 'NUMBER'; }
"**"                                  { return 'OPOW'; }
"↑"                                   { return 'OPOW'; }
[*/]                                  { return 'OPMU'; }
[-+]                                  { return 'OPAD'; }
"("                                   { return '('; }
")"                                   { return ')'; }
<<EOF>>                               { return 'EOF'; }
.                                     { return 'INVALID'; }
/lex

/* Parser */
%start L
%%

L : E EOF
    { $$ = $1; return $$; }
  ;

E : E OPAD T
    { $$ = operate($2, $1, $3); }
  | T
    { $$ = $1; }
  ;

T : T OPMU R
    { $$ = operate($2, $1, $3); }
  | R
    { $$ = $1; }
  ;

R : F OPOW R
    { $$ = operate($2, $1, $3); }
  | F
    { $$ = $1; }
  ;

F : NUMBER
    { $$ = convert($1); }
  | '(' E ')'
    { $$ = $2; }
  ;

%%

function operate(op, left, right) {
    switch (op) {
        case '+': return left + right;
        case '-': return left - right;
        case '*': return left * right;
        case '/': return left / right;
        case '**': return Math.pow(left, right);
        case '↑': return Math.pow(left, right);
    }
}

function convert(text) {
    return Number(text);
}
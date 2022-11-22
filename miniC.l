/* Codigo literal y macros de ER */

%{
    #include <stdio.h>
    #include "miniC.tab.h"
    void error_lexico();
    void error_comentario();
    int inicio_coment;   
    int errores_lexicos = 0;   
%}


digito [0-9]
letra [a-zA-Z_]
panico [^\n\r\ta-zA-Z_0-9+\-*/();=, {}]

/* Para el numero de lineas, flex se encarga */
%option yylineno

%x comentario

%%

 /* Expresiones regulares para comentarios y blancos */

[ \t\r\n]+                            { }
"//".*                           { }
"/*"                                {inicio_coment = yylineno; BEGIN(comentario); }
<comentario>"*/"                    {BEGIN(INITIAL); }
<comentario>(.|\n)                  { }
<comentario><<EOF>>                  {error_comentario();
                                        return 0; }

 /* Expresiones regulares de tokens */

 /* Primero, FLex aplica la mas larga. Luego, en caso de empate, aplica la que apareza antes. Por eso no poemos poner smplemente
 la expresion regular . para los errores y pònerla al final, pues siempre sera la mas larga*/
 /*Ponemos la ER de print antes porque print tambien entra en la ER de identificador. Flex desambigua cogiendo la primera*/
"print"                         {return PRINT; }
"void"                         {return VOID; }
"const"                         {return CONST; }
"if"                         {return IF; }
"else"                         {return ELSE; }
"while"                         {return WHILE; }
"read"                         {return READ; }
"var"                           {return VAR; }
"do"                               {return DO; }
"for"                           {return FOR;}
{letra}({letra}|{digito}){0,15}     {yylval.cadena = strdup(yytext);
                                return IDEN; }
"+"                            {return MAS; }
"-"                            {return MENOS; }
"*"                             {return POR; }
"/"                                {return DIV; }
"("                             {return PARI; }
")"                             {return PARD; }
"{"                              {return LLAVEI; }
"}"                              {return LLAVED; }
";"                             {return PYC; }
{digito}+                       {
    long l = atol(yytext);
    if (l > (2147483648)){
        printf("El numero debe estar entre mas menos 2^31\n");
        error_lexico();
    } else{
        yylval.cadena = strdup(yytext);
        return ENTERO;
    }
 }
"="                             {return IGUAL; }
","                             {return COMA; }
 /*Para las cadenas en print, usamos lo que no se puede poner dentro de dobles comillas*/
 /* Tenemos en cuenta que no podemos usar doble comilla dentro de doble comilla, pero si puedes si usas \ antes. Por eso las 3 \
 \\ es para representar \, y \" para representar ".*/
\"([^"\n]|\\\")*\"             {yylval.cadena = strdup(yytext);
                            return STRING; }
\"([^"\n]|\\\")*               {error_lexico(); }
{letra}({letra}|{digito}){16}({letra}|{digito})*    {error_lexico(); }
 /*POnemos la ultima una ER que capture todo para los errores */
{panico}+                       {error_lexico(); }

%%


void error_comentario(){
    printf("Error, comentario sin cerrar en linea %d\n", inicio_coment);

}



void error_lexico(){
    errores_lexicos++;
    printf("Error lexico en linea %d: %s\n", yylineno, yytext);
}
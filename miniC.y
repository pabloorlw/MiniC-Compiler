%{
    #define _GNU_SOURCE
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "listaSimbolos.h"
    #include "listaCodigo.h"
    extern int yylex();
    extern int yylineno;  
    extern int errores_lexicos;  
    void yyerror(const char *msg);
    int errores_sintacticos = 0;
    // Lista de simbolos
    Lista l;
    Tipo t;
    char registros[10];
    int contador_str = 0;
    int errores_semanticos = 0;
    void imprimirLS();
    int analisis_ok();
    char *obtenerReg();
    void liberarReg(char *reg);
    void imprimirLC(ListaC codigo);
    int contadorEtiquetas=1;
    char *obtenerEtiqueta();
%}

%code requires {
        #include "listaCodigo.h"
}
/* Tipos de dato de los simbolos de la gramatica */

%union{
    char *cadena;
    ListaC codigo;
}


/* Tokens de la gramatica */

%token <cadena> IDEN "id"
%token MAS "+"
%token MENOS "-"
%token POR "*"
%token DIV "/"
%token PYC ";"
%token PARI "("
%token PARD ")"
%token IGUAL "="
%token <cadena> ENTERO "num"
%token PRINT "print"
%token <cadena> STRING  "string"
%token COMA    ","
%token LLAVEI  "{"
%token LLAVED  "}"
%token VOID    "void"
%token VAR     "var"
%token CONST   "const"
%token IF      "if"
%token ELSE    "else"
%token WHILE   "while"
%token READ    "read"
%token DO     "do"
%token FOR    "for"

/* Tipos de no terminales */
%type <codigo> expression statement print_item print_list read_list asig inicializar statement_list program declarations identifier_list

/* Asociatividad y precedencia de operadores */
%left "+" "-"
%left "*" "/"   //en siguiente linea para que tengan mas precedencia que suma y resta. Tienen tambien asociatividad por la izq.
%precedence UMINUS  //La ponemos en la tercera linea para que tenga precedencia maxima

%start program
/* para que los errores me los describa mas */
%define parse.error verbose

%expect 1

%%

/* Reglas de produccion */

program :  inicializar VOID IDEN "(" ")" "{" declarations statement_list "}"  {
                                                                                if (analisis_ok()){
                                                                                        $$ = creaLC();
                                                                                        concatenaLC($$, $7);
                                                                                        concatenaLC($$, $8);
                                                                                        liberaLC($7);
                                                                                        liberaLC($8);
                                                                                        Operacion o;
                                                                                        o.op = "jr";
                                                                                        o.res = "$ra";
                                                                                        o.arg1 = NULL;
                                                                                        o.arg2 = NULL;
                                                                                        insertaLC($$, finalLC($$), o);
                                                                                        imprimirLS();
                                                                                        imprimirLC($$);
                                                                                        liberaLS(l);
                                                                                        liberaLC($$);
                                                                                }
                                                                        }
        ;

inicializar : %empty {
        l = creaLS();
        memset(registros, 0, 10);
        }
        ;

declarations : declarations "var" {t = VARIABLE; } identifier_list ";" {
                                                                        if (analisis_ok()){
                                                                                $$ = creaLC();
                                                                                concatenaLC($$, $1);
                                                                                concatenaLC($$, $4);
                                                                                liberaLC($1);
                                                                                liberaLC($4);
                                                                        }
                                                                        
                                                                }
        | declarations "const" { t = CONSTANTE; }identifier_list ";" {
                                                                        if (analisis_ok()){
                                                                                $$ = creaLC();
                                                                                concatenaLC($$, $1);
                                                                                concatenaLC($$, $4);
                                                                                liberaLC($1);
                                                                                liberaLC($4);
                                                                        }
                                                                }
        | %empty            { 
                if (analisis_ok()){
                        $$ = creaLC();
                }
        }
        ;

identifier_list : asig      { if (analisis_ok()){
                                $$ = $1;
                                }
                        }
        |   identifier_list "," asig    { if (analisis_ok()){
                                                $$ = creaLC();
                                                concatenaLC($$, $1);
                                                concatenaLC($$, $3);
                                                liberaLC($1);
                                                liberaLC($3);
                                        }                      
                                        }
        ;

asig : "id"     {
                PosicionLista p = buscaLS(l,$1);
                if (p != finalLS(l)) {
                        printf("Error en linea %d: identificador %s redeclarado\n", yylineno, $1);
                        errores_semanticos++;
                }
                else {
                        Simbolo aux;
                        aux.nombre = $1;
                        aux.tipo = t;
                        insertaLS(l,finalLS(l),aux);
                        if (analisis_ok()){
                                $$ = creaLC();
                        }
                }
                
                
                }
        | "id" "=" expression       {
                PosicionLista p = buscaLS(l,$1);
                if (p != finalLS(l)) {
                        printf("Error en linea %d: identificador %s redeclarado\n", yylineno, $1);
                        errores_semanticos++;
                }
                else {
                        Simbolo aux;
                        aux.nombre = $1;
                        aux.tipo = t;
                        insertaLS(l,finalLS(l),aux);
                        if (analisis_ok()){
                                $$ = $3;
                                Operacion o;
                                o.op = "sw";
                                o.res = recuperaResLC($3);
                                char *dir;
                                asprintf(&dir, "_%s", $1);
                                o.arg1 = dir;
                                o.arg2 = NULL;
                                insertaLC($$, finalLC($$), o);
                                liberarReg(o.res);
                        }
                }
                }
        ;

statement_list : statement_list  statement      { if (analisis_ok()){
                                                        $$ = $1;
                                                        concatenaLC($$, $2);
                                                        liberaLC($2);
                                                }        
                                                }
        | %empty                                { if (analisis_ok()){
                                                        $$ = creaLC(); 
                                                }
                                                }
        ;

statement : "id" "=" expression ";"    {
                                        PosicionLista p = buscaLS(l, $1);
                                        if (p == finalLS(l)){
                                                printf("Error en linea %d: identificador %s no encontrado\n", yylineno, $1);
                                                errores_semanticos++;
                                        } else {
                                                Simbolo aux = recuperaLS(l, p);
                                                if (aux.tipo == CONSTANTE){
                                                        printf("Error en linea %d: identificador %s es constante\n", yylineno, $1);
                                                        errores_semanticos++;  
                                                }
                                        }
                                        if (analisis_ok()){
                                                        $$ = $3;
                                                        Operacion o;
                                                        o.op = "sw";
                                                        o.res = recuperaResLC($3);
                                                        char *dir;
                                                        asprintf(&dir, "_%s", $1);
                                                        o.arg1 = dir;
                                                        o.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o);
                                                        liberarReg(o.res);
                                        }
                                  
                                        }
        | "{" statement_list "}"    {   if (analisis_ok()){
                                                $$ = $2;
                                        }
                                        }
        | IF "(" expression ")" statement "else" statement    {if (analisis_ok()){
                                                                        $$ = $3;
                                                                        Operacion o;
                                                                        o.op = "beqz";
                                                                        o.res = recuperaResLC($3);
                                                                        char *etiqueta1 = obtenerEtiqueta();
                                                                        o.arg1 = etiqueta1;
                                                                        o.arg2 = NULL;
                                                                        insertaLC($$, finalLC($$), o);
                                                                        concatenaLC($$, $5);
                                                                        liberarReg(o.res);
                                                                        Operacion o1;
                                                                        o1.op = "b";
                                                                        char *etiqueta2 = obtenerEtiqueta();
                                                                        o1.res = etiqueta2;
                                                                        o1.arg1 = NULL;
                                                                        o1.arg2 = NULL;
                                                                        insertaLC($$, finalLC($$), o1);
                                                                        Operacion o2;
                                                                        o2.op = "etiq";
                                                                        o2.res = etiqueta1;
                                                                        o2.arg1 = NULL;
                                                                        o2.arg2 = NULL;
                                                                        insertaLC($$, finalLC($$), o2);
                                                                        concatenaLC($$, $7);
                                                                        Operacion o3;
                                                                        o3.op = "etiq";
                                                                        o3.res = etiqueta2;
                                                                        o3.arg1 = NULL;
                                                                        o3.arg2 = NULL;
                                                                        insertaLC($$, finalLC($$), o3);
                                                                        liberaLC($5);
                                                                        liberaLC($7);
                                                                }
                                                                
                                                                }
        | IF "(" expression ")" statement     {if (analisis_ok()){
                                                        $$ = $3;
                                                        char *etiqueta1 = obtenerEtiqueta();
                                                        Operacion o;
                                                        o.op = "beqz";
                                                        o.res = recuperaResLC($3);
                                                        o.arg1 = etiqueta1;
                                                        o.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o);
                                                        concatenaLC($$, $5);
                                                        liberarReg(o.res);
                                                        liberaLC($5);
                                                        Operacion o1;
                                                        o1.op = "etiq";
                                                        o1.res = etiqueta1;
                                                        o1.arg1 = NULL;
                                                        o1.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o1);
                                                }
                                                
                                                }
        | WHILE "(" expression ")" statement  {if (analisis_ok()){
                                                        $$ = creaLC();
                                                        char * etiqueta1 = obtenerEtiqueta();
                                                        Operacion o;
                                                        o.op = "etiq";
                                                        o.res = etiqueta1;
                                                        o.arg1 = NULL;
                                                        o.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o);
                                                        concatenaLC($$, $3);
                                                        Operacion o1;
                                                        o1.op = "beqz";
                                                        o1.res = recuperaResLC($3);
                                                        char *etiqueta2 = obtenerEtiqueta();
                                                        o1.arg1 = etiqueta2;
                                                        o1.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o1);
                                                        concatenaLC($$, $5);
                                                        Operacion o2;
                                                        o2.op = "b";
                                                        o2.res = etiqueta1;
                                                        o2.arg1 = NULL;
                                                        o2.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o2);
                                                        Operacion o3;
                                                        o3.op = "etiq";
                                                        o3.res = etiqueta2;
                                                        o3.arg1 = NULL;
                                                        o3.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o3);
                                                        liberaLC($3);
                                                        liberaLC($5);
                                                        liberarReg(o1.res);
                                                }
                                                
                                                }
        | "print" print_list ";"                {if (analisis_ok()){
                                                        $$ = $2;
                                                }       
                                                }
        | "read" read_list ";"                  {if (analisis_ok()){
                                                        $$ = $2;
                                                }

                                                }
        | "do" statement WHILE "(" expression ")" ";" {if (analisis_ok()){
                                                                $$ = creaLC();
                                                                char * etiqueta1 = obtenerEtiqueta();
                                                                Operacion o1;
                                                                o1.op = "etiq";
                                                                o1.res = etiqueta1;
                                                                o1.arg1 = NULL;
                                                                o1.arg2 = NULL;
                                                                insertaLC($$, finalLC($$), o1);
                                                                concatenaLC($$, $2);
                                                                liberaLC($2);
                                                                concatenaLC($$, $5);
                                                                Operacion o3;
                                                                o3.op = "bnez";
                                                                o3.res = recuperaResLC($5);
                                                                o3.arg1 = etiqueta1;
                                                                o3.arg2 = NULL;
                                                                insertaLC($$, finalLC($$), o3);
                                                                liberaLC($5);
                                                                liberarReg(o3.res);
                                                        }
                                                        }
        | FOR "(" ENTERO ")" statement         { if (analisis_ok()){
                                                        $$ = creaLC();
                                                        char * indice = obtenerReg();
                                                        Operacion o;
                                                        o.op = "li";
                                                        o.res = indice;
                                                        o.arg1 = "0";
                                                        o.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o);
                                                        char * etiqueta1 = obtenerEtiqueta();
                                                        char * etiqueta2 = obtenerEtiqueta();
                                                        Operacion o1;
                                                        o1.op = "etiq";
                                                        o1.res = etiqueta1;
                                                        o1.arg1 = NULL;
                                                        o1.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o1);
                                                        Operacion o2;
                                                        o2.op = "bge";
                                                        o2.res = indice;
                                                        o2.arg1 = $3;
                                                        o2.arg2 = etiqueta2;
                                                        insertaLC($$, finalLC($$), o2);
                                                        concatenaLC($$, $5);
                                                        Operacion o6;
                                                        o6.op = "addi";
                                                        o6.res = indice;
                                                        o6.arg1 = indice;
                                                        o6.arg2 = "1";
                                                        insertaLC($$, finalLC($$), o6);
                                                        Operacion o4;
                                                        o4.op = "b";
                                                        o4.res = etiqueta1;
                                                        o4.arg1 = NULL;
                                                        o4.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o4);
                                                        Operacion o5;
                                                        o5.op = "etiq";
                                                        o5.res = etiqueta2;
                                                        o5.arg1 = NULL;
                                                        o5.arg2 = NULL;
                                                        insertaLC($$, finalLC($$), o5);
                                                        liberaLC($5);
                                                        liberarReg(indice);
                                                }
                                               
                                                }
        ;
print_list : print_item             {if (analisis_ok()){
                                        $$ = $1;
                                }
                                }
        | print_list "," print_item {
                                        if (analisis_ok()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                liberaLC($3);
                                        }
                                        
                                        }
        ;
print_item : expression             {
                                        if (analisis_ok()){
                                                $$ = $1;
                                                Operacion o;
                                                o.op = "move";
                                                o.res = "$a0";
                                                o.arg1 = recuperaResLC($1);
                                                o.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o);
                                                liberarReg(o.arg1);
                                                Operacion o1;
                                                o1.op = "li";
                                                o1.res = "$v0";
                                                o1.arg1 = "1";
                                                o1.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o1);
                                                Operacion o2;
                                                o2.op = "syscall";
                                                o2.arg1 = NULL;
                                                o2.arg2 = NULL;
                                                o2.res = NULL;
                                                insertaLC($$, finalLC($$), o2);
                                        }
                                        
                                        }
        |       STRING                  {
                                        if (analisis_ok()){
                                                Simbolo aux;
                                                contador_str++;
                                                aux.nombre = $1;
                                                aux.tipo = CADENA;
                                                aux.valor = contador_str;
                                                insertaLS(l,finalLS(l),aux); 
                                                $$ = creaLC();
                                                char * etiqueta1;
                                                asprintf(&etiqueta1, "$str%d", aux.valor);
                                                Operacion o;
                                                o.op = "la";
                                                o.res = "$a0";
                                                o.arg1 = etiqueta1;
                                                o.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o);
                                                Operacion o1;
                                                o1.op = "li";
                                                o1.res = "$v0";
                                                o1.arg1 = "4";
                                                o1.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o1);
                                                Operacion o2;
                                                o2.op = "syscall";
                                                o2.res = NULL;
                                                o2.arg1 = NULL;
                                                o2.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o2);
                                        }
                                        
                                        }
        ;
read_list : "id"                    {
                                        PosicionLista p = buscaLS(l, $1);
                                        if (p == finalLS(l)){
                                                printf("Error en linea %d: identificador %s no encontrado\n", yylineno, $1);
                                                errores_semanticos++;
                                        } else {
                                                Simbolo aux = recuperaLS(l, p);
                                                if (aux.tipo == CONSTANTE){
                                                        printf("Error en linea %d: identificador %s es constante\n", yylineno, $1);
                                                        errores_semanticos++;  
                                                }
                                        }
                                        if (analisis_ok()){
                                                $$ = creaLC();
                                                Operacion o;
                                                o.op = "li";
                                                o.res = "$v0";
                                                o.arg1 = "5";
                                                o.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o);
                                                Operacion o1;
                                                o1.op = "syscall";
                                                o1.res = NULL;
                                                o1.arg1 =NULL;
                                                o1.arg2  =NULL;
                                                insertaLC($$, finalLC($$), o1);
                                                Operacion o2;
                                                o2.op = "sw";
                                                o2.res = "$v0";
                                                char *dir;
                                                asprintf(&dir, "_%s", $1);
                                                o2.arg1 = dir;
                                                o2.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o2);
                                        }

                                        }
        | read_list "," "id" {
                                PosicionLista p = buscaLS(l, $3);
                                        if (p == finalLS(l)){
                                                printf("Error en linea %d: identificador %s no encontrado\n", yylineno, $3);
                                                errores_semanticos++;
                                        } else {
                                                Simbolo aux = recuperaLS(l, p);
                                                if (aux.tipo == CONSTANTE){
                                                        printf("Error en linea %d: identificador %s es constante\n", yylineno, $3);
                                                        errores_semanticos++;  
                                                }
                                        }
                                        if (analisis_ok()){
                                                $$ = $1;
                                                Operacion o;
                                                o.op = "li";
                                                o.res = "$v0";
                                                o.arg1 = "5";
                                                o.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o);
                                                Operacion o1;
                                                o1.op = "syscall";
                                                o1.res = NULL;
                                                o1.arg1 = NULL;
                                                o1.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o1);
                                                Operacion o2;
                                                o2.op = "sw";
                                                o2.res = "$v0";
                                                char *dir;
                                                asprintf(&dir, "_%s", $3);
                                                o2.arg1 = dir;
                                                o2.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o2);
                                        }
                                }
        ;
expression : expression "+" expression {
                                        if (analisis_ok()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                Operacion o;
                                                o.op = "add";
                                                o.res = recuperaResLC($1);
                                                o.arg1 = recuperaResLC($1);
                                                o.arg2 = recuperaResLC($3);
                                                insertaLC($$, finalLC($$), o);
                                                liberarReg(o.arg2);
                                                liberaLC($3);
                                                
                                        }
                                        }
        | expression "-" expression {
                                        if (analisis_ok()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                Operacion o;
                                                o.op = "sub";
                                                o.res = recuperaResLC($1);
                                                o.arg1 = recuperaResLC($1);
                                                o.arg2 = recuperaResLC($3);
                                                insertaLC($$, finalLC($$), o);
                                                liberarReg(o.arg2);
                                                liberaLC($3);
                                                
                                        }
                                        
                                        }
        | expression "*" expression     {
                                        if (analisis_ok()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                Operacion o;
                                                o.op = "mul";
                                                o.res = recuperaResLC($1);
                                                o.arg1 = recuperaResLC($1);
                                                o.arg2 = recuperaResLC($3);
                                                insertaLC($$, finalLC($$), o);
                                                liberarReg(o.arg2);
                                                liberaLC($3);
                                                
                                        }
                                        
                                        }
        | expression "/" expression   { 
                                        if (analisis_ok()){
                                                $$ = $1;
                                                concatenaLC($$, $3);
                                                Operacion o;
                                                o.op = "div";
                                                o.res = recuperaResLC($1);
                                                o.arg1 = recuperaResLC($1);
                                                o.arg2 = recuperaResLC($3);
                                                insertaLC($$, finalLC($$), o);
                                                liberarReg(o.arg2);
                                                liberaLC($3);
                                                
                                        }
                                        
                                        }
        | "-" expression   %prec UMINUS { 
                                        if (analisis_ok()){
                                                $$ = $2;
                                                Operacion o;
                                                o.op = "neg";
                                                o.res = recuperaResLC($2);
                                                o.arg1 = recuperaResLC($2);
                                                o.arg2 = NULL;
                                                insertaLC($$, finalLC($$), o);
                                                
                                        }
                                        
                                        }
        | "(" expression ")"        {
                                        if (analisis_ok()){
                                                $$ = $2;
                                        }
                                                        }
        | "id"                  {
                                PosicionLista p = buscaLS(l, $1);
                                if (p == finalLS(l)){
                                        printf("Error en linea %d: identificador %s no encontrado\n", yylineno, $1);
                                        errores_semanticos++;
                                } 
                                if (analisis_ok()){
                                        $$ = creaLC();
                                        Operacion o;
                                        o.op = "lw";
                                        o.res = obtenerReg();
                                        char *dir;
                                        asprintf(&dir, "_%s", $1);
                                        o.arg1 = dir;
                                        o.arg2 = NULL;
                                        insertaLC($$, finalLC($$), o);
                                        guardaResLC($$, o.res);
                                }
                                }
        | "num"                  {
                                if (analisis_ok()){
                                        $$ = creaLC();
                                        Operacion o;
                                        o.op = "li";
                                        o.res = obtenerReg();
                                        o.arg1 = $1;
                                        o.arg2 = NULL;
                                        insertaLC($$, finalLC($$), o);
                                        guardaResLC($$, o.res);
                                }
                                
                                }
        ;


%%

void yyerror(const char *msg){
        errores_sintacticos++;
    printf("Error en la linea %d: %s\n", yylineno, msg);
}


void imprimirLS(){
  PosicionLista p = inicioLS(l);
  printf(".data\n");
  while (p != finalLS(l)) {
    Simbolo aux = recuperaLS(l,p);
    if (aux.tipo == CADENA){
        printf("$str%d:\n       .asciiz %s\n",aux.valor, aux.nombre);
    } else{
        printf("_%s:\n          .word 0\n",aux.nombre); 
    }   
    p = siguienteLS(l,p);
  }
  printf(".text\n.globl main\nmain:\n");
}

int analisis_ok(){
        return  (errores_lexicos + errores_semanticos + errores_sintacticos) == 0;
}

char *obtenerReg(){
        int i;
        for (i = 0; i < 10; i++){
                if (registros[i] == 0){
                        break;
                }
        }
        if (i == 10){
                printf("Error fatal: no quedan registros libres\n");
                exit(1);
        }
        registros[i] = 1;
        char *reg;
        asprintf(&reg, "$t%d", i);
        return reg;
}

void liberarReg(char *reg){
        int i = reg[2] - '0';
        registros[i] = 0;
}

void imprimirLC(ListaC codigo){
        PosicionListaC p = inicioLC(codigo);
        Operacion oper;
        while (p != finalLC(codigo)) {
                oper = recuperaLC(codigo,p);
                if (!strcmp(oper.op, "etiq")){
                        printf("%s:\n", oper.res);
                }else{
                        printf("        %s",oper.op);
                        if (oper.res) printf(" %s",oper.res);
                        if (oper.arg1) printf(",%s",oper.arg1);
                        if (oper.arg2) printf(",%s",oper.arg2);
                        printf("\n");
                }
                p = siguienteLC(codigo,p);
        }
}

char *obtenerEtiqueta(){
            char aux[32];
            sprintf(aux, "$l%d", contadorEtiquetas++);
            return strdup(aux);
}
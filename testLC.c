#include "listaCodigo.h"
#include <string.h>
#include <stdio.h>

int main(int argc, char **argv) {

  // Creación de una lista de código
  ListaC codigo1 = creaLC();

  // Generación de la operación a = 2+1.

  Operacion oper;
  oper.op = "li";
  oper.res = "$t0";
  oper.arg1 = "2";
  oper.arg2 = NULL;

  insertaLC(codigo1,finalLC(codigo1),oper);

  oper.op = "li";
  oper.res = "$t1";
  oper.arg1 = "1";
  oper.arg2 = NULL;
  
  insertaLC(codigo1,finalLC(codigo1),oper);  

  oper.op = "add";
  oper.res = "$t2";
  oper.arg1 = "$t0";
  oper.arg2 = "$t1";
  
  insertaLC(codigo1,finalLC(codigo1),oper);

  // Generación de la operación imprimir a.

  ListaC codigo2 = creaLC();

  oper.op = "li";
  oper.res = "$v0";
  oper.arg1 = "4";
  oper.arg2 = NULL;

  insertaLC(codigo2,finalLC(codigo2),oper);  

  oper.op = "move";
  oper.res = "$a0";
  oper.arg1 = "$t2";
  oper.arg2 = NULL;

  insertaLC(codigo2,finalLC(codigo2),oper);  

  oper.op = "syscall";
  oper.res = NULL;
  oper.arg1 = NULL;
  oper.arg2 = NULL;

  insertaLC(codigo2,finalLC(codigo2),oper);  

  // Concatenación de dos listas de código

  concatenaLC(codigo1,codigo2);

  // Liberación de memoria de código 2.
  liberaLC(codigo2);

  // Recorrido de código 1 para mostrar lo que contiene
  printf("Codigo1 contiene %d operaciones\n",longitudLC(codigo1));
  PosicionListaC p = inicioLC(codigo1);
  while (p != finalLC(codigo1)) {
    oper = recuperaLC(codigo1,p);
    printf("%s",oper.op);
    if (oper.res) printf(" %s",oper.res);
    if (oper.arg1) printf(",%s",oper.arg1);
    if (oper.arg2) printf(",%s",oper.arg2);
    printf("\n");
    p = siguienteLC(codigo1,p);
  }

  // Búsqueda de operaciones que usan li como operación
  printf("Búsqueda de operaciones li en Codigo1\n");
  p = buscaLC(codigo1,inicioLC(codigo1),"li",OPERACION);
  while (p != finalLC(codigo1)) {
    oper = recuperaLC(codigo1,p);
    printf("%s",oper.op);
    if (oper.res) printf(" %s",oper.res);
    if (oper.arg1) printf(",%s",oper.arg1);
    if (oper.arg2) printf(",%s",oper.arg2);
    printf("\n");
    p = buscaLC(codigo1,siguienteLC(codigo1,p),"li",OPERACION);
  }

  liberaLC(codigo1);

}

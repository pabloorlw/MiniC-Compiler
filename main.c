#include <stdio.h>
#include <stdlib.h>
extern FILE *yyin;
extern int yyparse();
extern int errores_sintacticos;
extern int errores_lexicos;
extern int errores_semanticos;

int ok(){
    return (errores_sintacticos + errores_lexicos + errores_semanticos);
}
int main(int argc, char *argv[]){
    if (argc != 2){
        printf("Uso: %s prueba.txt", argv[0]);
        exit(1);
    }
    yyin = fopen(argv[1], "r");
    if (yyin == NULL){
        printf("Error abriendo %s\n", argv[1]);
        exit(2);
    }
    //Analizar sintacticamente
    yyparse();
    int res = ok();
    if (res != 0){
        printf("Errores lexicos: %d\n", errores_lexicos);
        printf("Errores sintacticos: %d\n", errores_sintacticos);
        printf("Errores semanticos: %d\n", errores_semanticos);
    }
}
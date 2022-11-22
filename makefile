miniC : main.c lex.yy.c miniC.tab.c listaSimbolos.c listaCodigo.c
	gcc -g main.c lex.yy.c miniC.tab.c listaSimbolos.c listaCodigo.c -ll -o miniC

lex.yy.c : miniC.l miniC.tab.h
	flex miniC.l

miniC.tab.c miniC.tab.h : miniC.y listaSimbolos.h listaCodigo.h
	bison -d -v miniC.y

clean: 
	rm -f miniC.tab.* lex.yy.c miniC

run: miniC prueba.txt
	./miniC prueba.txt>salida.s
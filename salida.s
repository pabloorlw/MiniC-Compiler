.data
_a:
          .word 0
_b:
          .word 0
_c:
          .word 0
$str1:
       .asciiz "Inicio del programa\n"
$str2:
       .asciiz "a"
$str3:
       .asciiz "\n"
$str4:
       .asciiz "No a y b\n"
$str5:
       .asciiz "c ="
$str6:
       .asciiz "\n"
$str7:
       .asciiz "Final"
$str8:
       .asciiz "\n"
$str9:
       .asciiz "hola"
$str10:
       .asciiz "hola"
$str11:
       .asciiz "FOR\n"
.text
.globl main
main:
        li $t0,0
        sw $t0,_a
        li $t0,0
        sw $t0,_b
        li $t0,5
        li $t1,20
        add $t0,$t0,$t1
        li $t1,20
        sub $t0,$t0,$t1
        sw $t0,_c
        la $a0,$str1
        li $v0,4
        syscall
        lw $t0,_a
        beqz $t0,$l5
        la $a0,$str2
        li $v0,4
        syscall
        la $a0,$str3
        li $v0,4
        syscall
        b $l6
$l5:
        lw $t1,_b
        beqz $t1,$l3
        la $a0,$str4
        li $v0,4
        syscall
        b $l4
$l3:
$l1:
        lw $t2,_c
        beqz $t2,$l2
        la $a0,$str5
        li $v0,4
        syscall
        lw $t3,_c
        move $a0,$t3
        li $v0,1
        syscall
        la $a0,$str6
        li $v0,4
        syscall
        lw $t3,_c
        li $t4,2
        sub $t3,$t3,$t4
        li $t4,1
        add $t3,$t3,$t4
        sw $t3,_c
        b $l1
$l2:
$l4:
$l6:
        la $a0,$str7
        li $v0,4
        syscall
        la $a0,$str8
        li $v0,4
        syscall
        li $t0,4
        li $t1,2
        div $t0,$t0,$t1
        move $a0,$t0
        li $v0,1
        syscall
        li $t0,2
        sw $t0,_c
$l7:
        la $a0,$str9
        li $v0,4
        syscall
        la $a0,$str10
        li $v0,4
        syscall
        lw $t0,_c
        li $t1,1
        sub $t0,$t0,$t1
        sw $t0,_c
        lw $t0,_c
        bnez $t0,$l7
        li $t0,0
$l8:
        bge $t0,3,$l9
        la $a0,$str11
        li $v0,4
        syscall
        addi $t0,$t0,1
        b $l8
$l9:
        jr $ra

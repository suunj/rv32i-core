.section .data
sum:    .word 0
count:  .word 100

.section .text
.global _start
_start:
    la x1, count
    lw x2, 0(x1)
    la x3, sum
    li x4, 0

loop:
    add x4, x4, x3
    addi x2, x2, -1
    bne x2, x0, loop

    sw x4, 0(x3)

    li a7, 10
    ecall

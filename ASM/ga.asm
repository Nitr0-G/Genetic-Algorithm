;
; GA@asm ver 0.094
; 
; ver 0.094
;	search space is wide
; ver 0.093
;	fitness function is new
; ver 0.092
;	roulette routine fixed
; ver 0.091
;	random routine minor change 'rol' to 'ror'.
; ver 0.09
;	print out floating point routine have.
; ver 0.08
;	mainloop and mutation
; ver 0.07
;	making offspring loop
;	crossover by uniform algorithm
; ver 0.06
;	selection by roulette
; ver 0.05
;	evaluate gene routine is added
; ver 0.04
;	we set up gene
; ver 0.03
;	generate random
; 
; last update 010224
; coded by mnb

POPULATION equ 100	; population of pool
GENESIZE equ 8		; ver 0.06 gene size

; here we start @ 0100h
;  0100h is rule... plz follow it.
	org 0100h

start:
;randomize   initialize rand seed
	xor ah,ah		; ah = 0
	int 1Ah			; get date and time
; dx is wide range
; cx is small...?
; so we take cx as 1st seed and dx as 2nd seed
	mov [seed1],cx		; save seed1
	mov [seed2],dx		; save seed2

	mov cx, POPULATION * GENESIZE	; ver 0.06 filled gene pool with random water
	mov di,randnum		; start address of gene pool
loop1:
	call random		; generate random number
	stosb			; we store the number which we generate to [di]
	loop loop1		; if cx is bigger than 0 , cx = cx -1 and jump loop1

; mainloop start
        mov cx, 1000		; main loop counter
mainloop:
        push cx         	; save main loop counter 
; calculate all fitness
        mov cx, POPULATION
        mov di , randnum
        mov si , fitness
loop2:
        call evaluate
        add di, GENESIZE        ; ver 0.06
        add si,4
        loop loop2
; making offspring loop
; init
        mov cx, POPULATION      ; loop counter for  next generation
        mov di, offspring       ; next swimmers warming up room
makeoffspring:
        push cx
        push di
        call selection          ; selection by ROULETTe alGo
        pop di
        call crossover          ; corssover by uniform crossover
        call mutation           ; mutation
        add di, GENESIZE        ; next offspring's position
        pop cx
        loop makeoffspring
; judgement gene reach to goal ?
        pop cx			; load loop counter
        push cx			; save again
        cmp cx,1		; if the loop is end this time
        jnz changepool  	; if the loop is continued , go to next.
        call judgement		; search best fitness
	call floatprint
	
; change gene to new.
changepool:
        mov di, randnum			; old gene pool
        mov si, offspring		; new gene are here.
        mov cx, POPULATION * GENESIZE	; size of pool
        rep movsb			; Do change
        pop cx			; counter is back
        loop mainloop		; loop

	fclex		; Clear floating-point exception flags after checking for error conditions 

	ret		; quit program.



; judgement
;  this version is to search minimum value of fitness.
;  return 
;       dx = best gene address
;       si = best fitness value address
judgement:
        mov bx, randnum			; bx = start address of gene
        mov dx,bx			; si = bx
        mov di , fitness		; dx = start address of fitness value
        mov si,di			; di = dx
        mov cx , POPULATION - 1		; cx is loop counter
        fld dword [ di ]		; first fitness is loaded
judgement1:
        add bx, GENESIZE                ; next gene
        add di, 4                       ; next fitness
        fld dword [ di ]                ; load fitness value
        fcom st1                        ; compare st0( current ) and st1 ( minimum )
        fnstsw ax			; st0 < st1 ,ah = ???????1 . st0 > st1 ah = ???????0
        shr ah,1			; check ah
        jnc judgement2
        mov si,di                       ; save address of fitness value
        mov dx,bx                       ; save address of gene
	fxch st1			; exchange minimum value
judgement2:
        fcomp st1			; poped
        loop judgement1
        fcomp st1			; poped
        ret

; mutation
; di = offspring start address
mutation:
        xor bx,bx
mutation0:
        mov cx,8                ;1 byte is 8 bit.
mutation1:
        call random             ; generate random
        mov [ randtmp ] , ax    ; save temp
        fld dword[ mutationrate ]       ; load mutationrate
        fild dword [ randtmp ]  ; load random number from temp
        fild dword [ randmax ]  ; load maximum number of random
        fdivp st1               ; st1 / st0 , this make 0 < random < 1
        fcompp			; compare and pop st0 ,st1
        fnstsw ax               ; during st0 < st1 ,ah = ???????1 . if st0 > st1 ah = ???????0
        shr ah,1                ; bit 0 of ah -> carry flag
        rcr dl,1                ; save carry flag
        loop mutation1		; do this 1 byte( ie 8 times )
        xor [ di + bx ] , dl	; Do MUTATION
        inc bx			; next position
        cmp bx,GENESIZE		; it's end?
        jnz mutation0		; if it's not end , we go back to 'mutation0'.
        ret			; return

; uniform crossover
;   parent1, parent2 is gene
;   di = offsprring ( destination address )
; broken:
;	ax,bx,cx,dx
crossover:
        xor bx,bx			; indicator ( counter ) reset
crossover0:
	mov cx,8			; 1 byte is 8 bit.

crossover1:
        call random			; generate random number
        shr al,1			; check even or odd
        jc crossover2			; if odd (ie carry flag is set ) , take parent2
        mov al , [ parent1 + bx ]	; because even , take parent1
        jmp crossover3			; go to set
crossover2:
        mov al , [ parent2 + bx ]	; take parent2
crossover3:
	shl al,cl			; shift al left by cl times
	rcr dl,1			; rotate dl including carry flag by 1
	loop crossover1			; cx = cx -1
	mov [di + bx],dl		; save it as gene
        inc bx
        cmp bx , GENESIZE
        jnz crossover0
	ret


selection:
; Roulette selection
; initialize
	fldz			; total
	mov di,fitness		; start address of fitness value
	mov cx,POPULATION	; number of POPULATION

; calculation total fitness
rouletteloop1:
	fld1			; 0.092
	fld dword [di]		; load fitness
	fdivp st1		; 0.092
	faddp	st1		; sum up fitness
	add di,4		; to point next fitness
	loop rouletteloop1

; roulette start
	call random		; generate random
	mov [ randtmp ] , ax	; save randomu to temp
	fild dword [ randtmp ]	; load random number from temp
	fild dword [ randmax ]	; load maximum number of random
	fdivp st1		; st1 / st0 , this make 0 < random < 1
	fmul st1		; 0 < target < total fitness

; seek lucky adam
	mov cx,POPULATION	; number of POPULATION
	mov si,randnum - GENESIZE	; start address of gene pool - GENESIZE ( 1 previous )
	mov di,fitness-4		; start address of fitness value - 4 ( 1 previous )
rouletteloop2:
	add si, GENESIZE	; next gene
	add di,4		; next fitness
	fld1			; 0.092
	fld dword [di]		; load fitness
	fdivp st1		; 0.092
	fcom st1		; 
	fnstsw ax		; during st0 < st1 ,ah = ???????1 . if st0 > st1 ah = ???????0
	and ah,1		; check condition
	fsubp st1,st0		; substract st1 - st0 and result store in st1 but 1 pop occur st0 have finally result 
	loopnz rouletteloop2	; cx = cx - 1 . if cx isn't 0 but zeroflag is clear ,exit loop
; now [ si ] is adam's gene
	mov di, parent1		; here's seat for him
	mov cx, GENESIZE	; to copy gene , cx have genesize (byte)
	rep movsb		; do copy
	fcomp	st1		; adios adam

; roulette start
	call random		; generate random
	mov [ randtmp ] , ax	; save temp
	fild dword [ randtmp ]	; load random number from temp
	fild dword [ randmax ]	; load maximum number of random
	fdivp st1		; st1 / st0 , this make 0 < random < 1
	fmul st1		; 0 < target < total fitness
; seek lucky eve
	mov cx,POPULATION	; number of POPULATION
	mov si,randnum - GENESIZE	; start address of gene pool - GENESIZE ( 1 previous )
	mov di,fitness - 4		; start address of fitness value - 4 ( 1 previous )
rouletteloop3:
	add si, GENESIZE	; next gene
	add di,4		; next fitness
	fld1			; 0.092
	fld dword [di]		; load fitness
	fdivp st1		; 0.092
	fcom st1		; 
	fnstsw ax		; during st0 < st1 ,ah = ???????1 . if st0 > st1 ah = ???????0
	and ah,1		; check condition
	fsubp st1,st0		; substract st1 - st0 and result store in st1 but 1 pop occur st0 have finally result 
	loopnz rouletteloop3	; cx = cx - 1 . if cx isn't 0 but zeroflag is clear ,exit loop
; now [ si ] is eve's gene
	mov di, parent2		; here's seat for her
	mov cx, GENESIZE	; to copy gene , cx have genesize (byte)
	rep movsb		; do copy
	fcompp			; adios eve


	ret

;
; Evaluate gene expression
;
; di = start address of gene

evaluate:
; setup x between -2048 to 2048
	fild dword [ range ]	; store denominator (4096 , we need between 0 to 4096 )
	fild dword [ di ]	; get gene for x
	fabs			; absolute 'ST0'
	fdiv dword [ million ]	; ver 0.094
	fprem			; 0 < 'ST0' < 4096
	fild dword [ rangef ]	; st0 = 2048 , st1 = 0 < x < 4096
	fsubp st1,st0		; -2048 < 'ST0' < 2048
; setup x between -2.048 to 2.048
	fidiv word [ para2 ]

; setup y between -2048 to 2048
	fild dword [ range ]	; store denominator (4096 , we need between 0 to 4096 )
	fild dword [ di + 4 ]	; get gene for y
	fabs			; absolute 'ST0'
	fdiv dword [ million ]	; ver 0.094
	fprem			; 0 < 'ST0' < 4096
	fild dword [ rangef ]	; st0 = 2048 , st1 = 0 < y < 4096
	fsubp st1,st0		; -2048 < 'ST0' < 2048
; setup y between -2.048 to 2.048
	fidiv word [ para2 ]
; pop 4096(s)
	fxch st0,st3		; st0 ,st1 = 4096
	fcompp			; pop st0,st1

; we have st0 = x , st1 = y
; load x
	fld st0
; x^2
	fmul st0		; x^2
; load y
	fld st2
; y - x_i^2
	fsubrp st1
;( y - x ^ 2 ) ^ 2
	fmul st0
;100 * ( y - x ^ 2 ) ^ 2
	fimul word [ para1 ]
; 1 - x
	fld1
	fsub st2
; ( 1 - x ) ^ 2
	fmul st0
;{ 100 * ( y - x ^ 2 ) ^ 2 + ( 1 - x ) ^ 2 } 
	faddp st1

; load y
	fld st2
; y^2
	fmul st0		; y_i^2
; load x
	fld st2
; x - y^2
	fsubrp st1
;( y - x ^ 2 ) ^ 2
	fmul st0
;100 * ( y - x ^ 2 ) ^ 2
	fimul word [ para1 ]
; 1 - x
	fld1
	fsub st3
; ( 1 - x ) ^ 2
	fmul st0
;{ 100 * ( y - x ^ 2 ) ^ 2 + ( 1 - x ) ^ 2 } 
	faddp st1
;=  { 100 * ( y - x ^ 2 ) ^ 2 + ( 1 - x ) ^ 2 } 
; + { 100 * ( x - y ^ 2 ) ^ 2 + ( 1 - y ) ^ 2 }
	faddp st1
; store fitness to [si]
	fstp dword [si]

	fcompp
	ret 


; generate random number
;  return
;	ax = number
random:
	db 0b8h	; mov ax,seed1
seed1:	db 0,0

	dec ax	; decrement
	
randloop:
	db 35h	; xor ax,seed2
seed2:	db 0,0

	inc ax	;
	xchg ah,al
	xor [seed2],ax
	sub ax,[seed1]
	rol al,1
	xchg ah,al

	sub [seed1],ax	; change seed1
	ret

;
; print float number 
; require
;  si = floating point address ( word )
floatprint:
	mov di,letters
	fld dword [si]
	
	ftst
	fnstsw ax
	mov al,' '
	shr ah,1
	jnc float1
	mov al,'-'
float1:
	stosb

	fabs		; st0 = |value|
	fld st0		; st0 = | value |

	fld1		; st0 = 1 , st1 = |value| ,st2 = | value |
	fld st1		; st0 = value ,st1 = 1 ,st2 = value ,st3 = | value |

	fprem		; st0 = remainder ( value % 1 ) , st1 = 1 , st2 = value , st3  = | value |
	fld st0		; st0 = remainder  , st1 = remainder  , st2 = 1 , st3  = value ,st4 = | value |
	fsubp	st3,st0	; st0 = remainder , st1 = 1 , st2 = value - reminder ( ie integer )  ,st3 = | value |
	fxch st2	; st0 = integer , st1 = 1 ,st2 = remainder , st3 = |value|
	fxch st1	; st0 = 1 , st1 = integer ,st2 = remainder , st3 = |value|

	xor cx,cx
floatprint1:
	fcom st1
	fnstsw ax
	push ax
	shr ah,7
	pop ax
	jnc floatkick
	inc cx
	fimul word [ ten ]
	jmp floatprint1
floatkick:

	shr ah,1
	jnc floatprint2
	inc cx
	fimul word [ ten ]
	jmp floatprint1

floatprint2:
	fidiv word [ ten ]	; st0 = 10 ^ n , st1 = integer  ,st2 = remainder , st3 = |value|
float2:
	fld st1		; st0 = integer , st1 = 10 ^ n , st2 =integer ,st3 = remainder , st4 = |value|
	fprem		; st0 = reminder ( integer % 10 ^ n ) , st1 = 10 ^ n , st2 =  integer ,st3 = remainder , st4 = |value|

	fsub st2,st0
	fxch st2
	fdiv st1
	fbstp [ di ]	; st0 = 10 ^ n , st1 = new integer , st2 = remainder , st4 = |value|
	add byte [di] , '0'
	inc di
	fidiv word [ ten ]
	cmp cx, 0
	jz float3
	loop float2
float3:
	mov al,'.'
	stosb
	fcompp
	mov cx,5

float4:
	fld1
	fxch st1
	fprem
	fimul word [ ten ]
	fdivrp st1
	fld st0

	fld st0
	fld1
	fxch st1
	fprem

	fsubp st2
	fcomp st1

	fbstp [di]
	add byte [di] , '0'
	inc di
	loop float4
	fcompp
	mov ax,0a0dh
	stosw
	mov byte [di],'$'
	mov dx,letters
	mov ah,09
	int 21h
	
	ret

million:  dd 1000000.0

ten: dw 10
letters: dw 0,0,0,0,0,0,0,0,0,0,0,0


range:	dw 4096,0	; the range of search space
rangef: dw 2048,0	; to fix it between -2048 and 2048
para1:	dw 100		; first parameter
para2:	dw 1000		; second parameter

randmax: dw 0ffffh,0	; the miximum value of random
randtmp: dw 0,0		; to send random num to fpu stack

mutationrate:	dd 0.001	; mutation rate

	SECTION .bss

	absolute	0x1000
randnum	resb	POPULATION * GENESIZE
fitness resb	POPULATION * 4
offspring resb	POPULATION * GENESIZE

; apple tree
parent1 resb	GENESIZE
parent2 resb	GENESIZE


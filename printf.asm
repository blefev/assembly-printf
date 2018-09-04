%include "/usr/share/csc314/asm_io.inc"

%define	SYS_write 4
%define STDOUT    1 

segment .data

	istr	db	"wor",0 
	ichar	db	'l'	
	fstr	db	10,"This is hex(%%x): %x",10,"This is decimal(%%d): %d",10,"This is a string(%%s): %s",10,"This is a char(%%c): %c",10,"String and chars: He%c%co %s%cd!",10,"Percent%%%: %%",10,"This is my grade: A+++++",10,10,0 
	myint   dd	13377347			   
	myhex	dd	12245589 ; = 0x4d2
	
segment .bss

	ostr	resd	32

segment .text
	global  asm_main
	extern	len
asm_main:
	enter	0,0
	pusha
	;***************CODE STARTS HERE***************************
	push	myhex
	push	myint
	push	ichar
	push 	istr
	push 	fstr
	call 	my_printf
	add 	esp, 20

	;***************CODE ENDS HERE*****************************
	popa
	mov	eax, 0
	leave
	ret

my_printf:
	push	ebp
	mov	ebp, esp
	sub	esp, 32; String buffer 

	; FORMAT STRING AT EBP + 8
	mov	ebx, DWORD[ebp+8]
	xor	edx, edx
	xor	edi, edi
	loop_top:
	mov	al, BYTE[ebx+edx]  ; moving current byte into al 
	cmp	al, 0x00
	je	loop_bot ; break if end of string

		; Not null terminator. Test if format specifier
	
		cmp	al, 0x25 ; is this a '%'?
		jne	not_format

		inc	edx ; inc for '%'
		mov	al, BYTE[ebx+edx] ; get next char
		
		cmp	al, 0x63 ; 'c' : character
		jne	f_str
			
			mov	ecx, DWORD[ebp+16] ; get the char param
			mov	al, BYTE[ecx]
			mov	BYTE[ostr+edi], al					
			inc	edi
			inc	edx	
		jmp	loop_top	
		
		
	    f_str:	
		cmp	al, 0x73 ; 's' : string
		jne	percent
		xor 	esi, esi		
			
			mov	ecx, DWORD[ebp+12]
			cpy_str:
			mov	al, [ecx+esi]
			cmp	al, 0x00
			je	f_end
				
				mov	BYTE[ostr+edi], al

			inc	esi
			inc	edi
			jmp	cpy_str
			cpy_str_end:

		f_end:
		
		inc	edx 
		jmp	loop_top


	    percent:
	    	cmp	al, 0x25
		jne	dec_to_ascii
		mov	BYTE[ostr+edi], 0x25
	    	inc	edx
		inc	edi
		jmp	loop_top

	  dec_to_ascii:
			cmp	al, 0x64 ; format specifier is d
			jne	hex_to_ascii

			inc	edx
			
			push	eax
			push	ebx
			push	ecx
			push	edx
			
			xor	ecx, ecx
			xor	ebx, ebx
			mov	ebx, DWORD[ebp+20]
			mov	eax, [ebx]
			;mov	eax,DWORD[ebp+20]
			mov	ebx, 10
			xor	ecx, ecx
		top_div:
			xor	edx, edx
			div	ebx ; assuming number is in eax
			cmp	edx, 0
			je	top_pop
			push	edx
			inc	ecx
			jmp	top_div
		top_pop:
			pop	eax
			add	al, '0' ; convert to ascii by adding 48, 0x30, '0'
			mov	BYTE[ostr+edi], al
			inc	edi
			dec	ecx
			cmp	ecx, 0
			jne	top_pop
		br1:
			pop	edx
			pop	ecx
			pop	ebx
			pop	eax
			jmp	loop_top




	hex_to_ascii:
			cmp	al, 0x78 ; format specifier is x
			jne	not_format
			
			; Hex. Let's add the "0x"
			mov	BYTE[ostr+edi], 0x30
			inc	edi
			mov	BYTE[ostr+edi], 0x78
			inc	edi

			inc	edx
			
			push	eax
			push	ebx
			push	ecx
			push	edx
			
			xor	ecx, ecx
			xor	ebx, ebx
			mov	ebx, DWORD[ebp+24]
			mov	eax, [ebx]
			mov	ebx, 16
			xor	ecx, ecx
		h_top_div:
			xor	edx, edx
			div	ebx ; assuming number is in eax
			cmp	edx, 0
			je	h_top_pop
			push	edx
			inc	ecx
			jmp	h_top_div
		h_top_pop:
			pop	eax
			cmp	al, 9
			jle	h_cont
			add	al, 55 ; convert to hex char
			jmp	h_cont2
			h_cont:
			add	al, '0' ; convert to ascii by adding 48, 0x30, '0'
			h_cont2:
			mov	BYTE[ostr+edi], al
			inc	edi
			dec	ecx
			cmp	ecx, 0
			jne	h_top_pop
		hbr1: ; break for gdb
			pop	edx
			pop	ecx
			pop	ebx
			pop	eax
			jmp	loop_top
			
		


	   not_format:
		mov	BYTE[ostr+edi], al ; into our local string
		inc	edi
		inc	edx

	jmp	loop_top
	loop_bot:
	mov	BYTE[ostr+edi], 0x00 ; append null terminator to local string
	add	edi, 4 	

	; Call the kernel. MAGIC happens here
	mov	edx, edi
	mov	eax, 4
	mov	ebx, 1
	mov	ecx, ostr
	int	0x80

	mov	esp, ebp
	pop	ebp
	ret


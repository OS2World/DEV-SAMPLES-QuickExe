
FALSE			EQU 0
TRUE			EQU 1
AUTOMATICBRIGHTNESS 	EQU 	TRUE
ZOOMIN			EQU FALSE	; XOFFSET and YOFFSET will need to be
					; changed for best view.

;*****************************************************************************
; Equates																	 *
;*****************************************************************************

; Parallel Port

PPD 			EQU  0378h
PPS 			EQU  0379h
PPC 			EQU  037Ah

;QuickCam Parameters

LINECOUNT				EQU 090
PIXELCOUNT				EQU 0120
PIXELCOUNTHALF		EQU PIXELCOUNT/2
BRIGHTNESS				EQU 0c0h				; Range (0 - FFh)
CONTRAST				EQU 040h				; Range (0 - FFh)
WHITENESS				EQU 0d0h				; Range (0 - FFh)
YOFFSET 		EQU 60
XOFFSET 		EQU 30

; Automatic Brightness parameters

TOTALPIXELS 	EQU LINECOUNT*PIXELCOUNT; Used by automatic brightness
OPTIBRIGHT				EQU 040h				 ; Used by automatic brightness

; XMode - 320 x 240 x 8 , (2) pages

PAGE0			EQU  00h		; OFFSET for Page (0)
PAGE1			EQU  4Bh		; OFFSET for Page (1)

Page0Offset 		EQU 0
Page1Offset 		EQU 4B00h
Page0StartAddressMSB	EQU 00h
Page1StartAddressMSB	EQU 4Bh



OptimumBrightness LABEL BYTE
	DB	OPTIBRIGHT
SumBrightness	LABEL DWORD
	DD	0
SetBrightness	LABEL BYTE
		DB		BRIGHTNESS
AverageBrightness LABEL BYTE
	DB	0
Cont LABEL BYTE
		DB		CONTRAST
Whit LABEL BYTE
		DB		WHITENESS

Main:	cld
//	  call	  SetModeX
//	  call	  SetCLUTGRAY6Bit

	mov dx, PPC 		; Initialize
	mov al, 0Bh
	out dx, al
	call	Delay100msec

	mov al, 0Eh
	out dx, al
	call	Delay100msec

	mov cx, 30			; Send Command/Data List
	mov dx, PPD
	mov si, OFFSET ModeUNI320X240X4
@@: lodsb
	out dx, al
	call	Strobe
	loop	@B



MainLoop:

	mov dx, PPD
	mov al, 07h 			; Send Command
	out dx, al
	call	Strobe

	mov al, 04h 		; Send Command
	out dx, al
	call	Strobe

	call	Capture320x240x4


	mov ah, 01h 		; Key pressed ?
	int 16h
		jz		goback
	mov ah, 00h 		; Read key
	int 	16h
	cmp ah, 1			; ESCape key ?
	je	ProgramExit


goback: 	jmp 	MainLoop


ProgramExit:

	mov ax,0003h		; Set mode 3
	int 	10h

	mov ax,4C00h		; Exit to DOS , no worries
	int 21h


;*****************************************************************************
; Subroutines																 *
;*****************************************************************************
Capture320x240x4:


	mov cx, LINECOUNT		; Lines per screen count
	push	cx
	mov cx, PIXELCOUNT		; Pixels per line
	inc 	cx			; make even divide
	shr 	cx, 1

	mov dx, PPC 		; DX = parallel control register
	mov al, 06h
	out dx, al
	dec dx

ReadyLoop1:
	mov bx, 2710h
ReadyLoop2:
	dec bx
	jnz @F
	jmp CaptureTimeOutError
@@: in	al, dx			; DX = parallel status register
	test	al, 08h
	jz	@F
	xor bx, bx
	jmp CaptureLoop2	  ; two bit 4's  00001000 before continueing
@@: and al, 80h
	cmp al, ah
	jz	ReadyLoop2
	mov ah, al
	jmp ReadyLoop1

CaptureMainLoop:
	push	cx
	mov cx, PIXELCOUNT		; Pixels per line
	inc 	cx			; make even divide
	shr 	cx, 1

CaptureLoop1:
	mov bx , 0FFh
cl0:	dec bx
	jnz @F
	jmp CaptureTimeOutError
@@: in	al, dx				; DX = parallel status register
	test	al, 08h
	jz	cl0

CaptureLoop2:
	shl ax, 04h 		; Input Pixel #1

	inc dx			; DX = parallel control control
	mov al,0Eh
	out dx, al
	dec dx

	mov bx , 0FFh
cl1:	dec bx
	jnz @F
	jmp CaptureTimeOutError
@@: in	al, dx			; DX = parallel status register
	test	al, 08h
	jnz cl1

	shl ax, 04h 		; Input Pixel #2

	inc dx			; DX = parallel control register
	mov al, 06h
	out dx, al
	dec dx

CaptureExit:
	inc dx			; DX = PPC
	mov al, 0Eh
	out 	dx, al

	pop es
	popa
	ret

;*****************************************************************************

Strobe:
	push	cx
	push	dx

	mov dx, PPC 			; DX = parallel control port
	mov al, 06h
	out dx, al

	dec dx			; DX = parallel status port
	mov cx, 0FFh
@@: dec cx
	jz	StrobeTimeOutError
	in	al, dx
	test	al, 08h
	jz	@B

	shl ax, 04h 		; Save PPS [7:4]

	inc dx			; DX = parallel control port
	mov al, 0Eh
	out dx, al
	dec dx			; DX = parallel status port

	mov cx, 0FFh
@@: dec cx
	jz	StrobeTimeOutError
	in	al, dx
	test	al, 08h
	jnz @B

	shr ax, 04h 			; Swap nibbles
	ror al, 04h 			;

	pop dx
	pop cx
	ret

;*****************************************************************************
; Data and varibles 														 *
;*****************************************************************************

ModeUNI320x240x4 LABEL BYTE

	DB	00Bh			; 01	Command: Brightness
	DB	BRIGHTNESS		; 02	*
	DB	00Bh			; 03	Command: (?)
	DB	001h			; 04
	DB	00Bh			; 05	Command: (?)
	DB	001h			; 06
	DB	00Bh			; 07	Command: Brightness (?)
	DB	BRIGHTNESS		; 08	*
	DB	00Dh			; 09	Command: Y offset
	DB	YOFFSET 		; 10	Data: (Upper left = 0)
	DB	00Fh			; 11	Command: X offset
	DB	XOFFSET 		; 12	Data: (Upper left = 0)
	DB	00Bh			; 13	Command: Brightness (?)
	DB	BRIGHTNESS		; 14	*
	DB	011h			; 15	Command: Vertical size
	DB	LINECOUNT		; 16	Data: 0 - F0h (240)
	DB	013h			; 17	Command: Horitzontal size
	DB	PIXELCOUNTHALF		; 18	Data: H size / 2
	DB	011h			; 19	Command: Vertical size
	DB	LINECOUNT		; 20	Data: 0 - F0h (240)
	DB	013h			; 21	Command: Horitzontal size
	DB	PIXELCOUNTHALF		; 22	Data: H size / 2
	DB	00Dh			; 23	Command: Y offset
	DB	YOFFSET 		; 24	Data: (Upper left = 0)
	DB	00Fh			; 25	Command: X offset
	DB	XOFFSET 		; 26	Data: (Upper left = 0)
	DB	019h			; 27	Command: Contrast
	DB	CONTRAST		; 28	Data: (0 - ffh)
	DB	01Fh			; 29	Command: Whiteness
	DB	WHITENESS		; 30	Data: (0 - ffh)


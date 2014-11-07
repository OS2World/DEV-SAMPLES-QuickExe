;	 QCam Test Exercise
;	 320X240X4 , Unidirection parallel port
;

;	 .COM FORMAT

TST	 SEGMENT

	 ASSUME CS:TST,DS:TST

.386


;*****************************************************************************
; Build 								     *
;*****************************************************************************

FALSE			EQU	0
TRUE			EQU	1
AUTOMATICBRIGHTNESS	EQU	FALSE
ZOOMIN			EQU	FALSE	; XOFFSET and YOFFSET will need to be
					; changed for best view.

;*****************************************************************************
; Equates								     *
;*****************************************************************************

; Parallel Port

PPD                     EQU  0278h
PPS                     EQU  0279h
PPC                     EQU  027Ah

;QuickCam Parameters

LINECOUNT               EQU 0200
PIXELCOUNT              EQU 0320
PIXELCOUNTHALF		EQU PIXELCOUNT/2
BRIGHTNESS		EQU 0c0h		; Range (0 - FFh)
CONTRAST		EQU 040h		; Range (0 - FFh)
WHITENESS		EQU 0d0h		; Range (0 - FFh)
YOFFSET 		EQU 60
XOFFSET 		EQU 30

; Automatic Brightness parameters

TOTALPIXELS		EQU LINECOUNT*PIXELCOUNT; Used by automatic brightness
OPTIBRIGHT		EQU 050h		 ; Used by automatic brightness

; XMode - 320 x 240 x 8 , (2) pages

SC_INDEX		EQU  03C4h		; Sequence Controller Index
CRTC_INDEX		EQU  03D4h		; CRT Controller Index
MISC_OUTPUT		EQU  03C2h		; Misc. Output register
SCREEN_SEG		EQU  0A000h		; Mode X , screen segment
PAGE0			EQU  00h		; OFFSET for Page (0)
PAGE1			EQU  4Bh		; OFFSET for Page (1)

Page0Offset		EQU 0
Page1Offset		EQU 4B00h
Page0StartAddressMSB	EQU 00h
Page1StartAddressMSB	EQU 4Bh


;*****************************************************************************

	ORG	100H
START:	jmp	Main
	nop

OptimumBrightness LABEL BYTE
	DB	OPTIBRIGHT
SumBrightness	LABEL DWORD
	DD	0
SetBrightness	LABEL BYTE
	DB	BRIGHTNESS
AverageBrightness LABEL BYTE
	DB	0
Cont LABEL BYTE
	DB	CONTRAST
Whit LABEL BYTE
	DB	WHITENESS

Main:	cld
	call	SetModeX
	call	SetCLUTGRAY6Bit

	mov	dx, PPC 		; Initialize
	mov	al, 0Bh
	out	dx, al
	call	Delay100msec

	mov	al, 0Eh
	out	dx, al
	call	Delay100msec

	mov	cx, 30			; Send Command/Data List
	mov	dx, PPD
	mov	si, OFFSET ModeUNI320X240X4
@@:	lodsb
	out	dx, al
	call	Strobe
	loop	@B

MainLoop:

	mov	dx, PPD
	mov	al, 07h 		; Send Command
	out	dx, al
	call	Strobe

IF	ZOOMIN
	mov	al, 00h 		; Send Command
ELSE	;ZOOMIN
	mov	al, 04h 		; Send Command
ENDIF	;ZOOMIN

	out	dx, al
	call	Strobe

	call	SetPage
	call	Capture320x240x4

IF	AUTOMATICBRIGHTNESS
	call	AutoBright

	mov	dx, PPD
	mov	al, 0Bh 			; Send Command
	out	dx, al
	call	Strobe

	mov	al, BYTE PTR SetBrightness	; Send Data
	mov	bl, al
	out	dx, al
	call	Strobe

	mov	al, 0Bh 			; Send Command
	out	dx, al
	call	Strobe

	mov	al, bl				; Send Data
	out	dx, al
	call	Strobe

ENDIF	;AUTOMATICBRIGHTNESS

	mov	ah, 01h 		; Key pressed ?
	int	16h
	jz	goback
	mov	ah, 00h 		; Read key
	int	16h
	cmp	ah, 1			; ESCape key ?
	je	ProgramExit

	mov	dx, PPD
	cmp	ah, 16
	jne	SL1
	dec	SetBrightness
	dec	SetBrightness
	mov	dx, PPD
	mov	al, 0Bh 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, BYTE PTR SetBrightness	; Send Data
	mov	bl, al
	out	dx, al
	call	Strobe
	mov	al, 0Bh 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, bl				; Send Data
	out	dx, al
	call	Strobe
	jmp	SHORT Mainloop
SL1:	cmp	ah,17
	jne	SL2
	inc	SetBrightness
	inc	SetBrightness
	mov	dx, PPD
	mov	al, 0Bh 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, BYTE PTR SetBrightness	; Send Data
	mov	bl, al
	out	dx, al
	call	Strobe
	mov	al, 0Bh 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, bl				; Send Data
	out	dx, al
	call	Strobe
	jmp	Mainloop

SL2:	cmp	ah, 30
	jne	SL3
	dec	cont
	dec	cont

	mov	dx, PPD
	mov	al, 19h 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, BYTE PTR Cont      ; Send Data
	mov	bl, al
	out	dx, al
	call	Strobe
	mov	al, 19h 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, bl				; Send Data
	out	dx, al
	call	Strobe
	jmp	Mainloop
SL3:	cmp	ah, 31
	jne	SL4
	inc	cont
	inc	cont

	mov	dx, PPD
	mov	al, 19h 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, BYTE PTR Cont      ; Send Data
	mov	bl, al
	out	dx, al
	call	Strobe
	mov	al, 19h 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, bl				; Send Data
	out	dx, al
	call	Strobe
	jmp	Mainloop
SL4:	cmp	ah, 44
	jne	SL5
	dec	whit
	dec	whit

	mov	dx, PPD
	mov	al, 1Fh 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, BYTE PTR Whit      ; Send Data
	mov	bl, al
	out	dx, al
	call	Strobe
	mov	al, 1Fh 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, bl				; Send Data
	out	dx, al
	call	Strobe
	jmp	Mainloop
SL5:	cmp	ah, 45
	jne	SL6
	inc	whit
	inc	whit

	mov	dx, PPD
	mov	al, 1Fh 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, BYTE PTR Whit      ; Send Data
	mov	bl, al
	out	dx, al
	call	Strobe
	mov	al, 1Fh 			; Send Command
	out	dx, al
	call	Strobe
	mov	al, bl				; Send Data
	out	dx, al
	call	Strobe
	jmp	Mainloop
SL6:

goback:     jmp     MainLoop


ProgramExit:

	mov	ax,0003h		; Set mode 3
	int	10h

	mov	ax,4C00h		; Exit to DOS , no worries
	int	21h


;*****************************************************************************
; Subroutines								     *
;*****************************************************************************
Capture320x240x4:

	pusha
	push	es
	mov	ax, 0A000h		; Initialize video SEG:OFFSET
	mov	es, ax

	mov	cx, LINECOUNT		; Lines per screen count
	push	cx
	mov	cx, PIXELCOUNT		; Pixels per line
	inc	cx			; make even divide
	shr	cx, 1

	mov	dx, PPC 		; DX = parallel control register
	mov	al, 06h
	out	dx, al
	dec	dx

ReadyLoop1:
	mov	bx, 2710h
ReadyLoop2:
	dec	bx
	jnz	@F
	jmp	CaptureTimeOutError
@@:	in	al, dx			; DX = parallel status register
	test	al, 08h
	jz	@F
	xor	bx, bx
	jmp	CaptureLoop2
@@:	and	al, 80h
	cmp	al, ah
	jz	ReadyLoop2
	mov	ah, al
	jmp	ReadyLoop1

CaptureMainLoop:
	push	cx
	mov	cx, PIXELCOUNT		; Pixels per line
	inc	cx			; make even divide
	shr	cx, 1

CaptureLoop1:
	mov	bx , 0FFh
cl0:	dec	bx
	jnz	@F
	jmp	CaptureTimeOutError
@@:	in	al, dx			; DX = parallel status register
	test	al, 08h
	jz	cl0

CaptureLoop2:
	shl	ax, 04h 		; Input Pixel #1

	inc	dx			; DX = parallel control control
	mov	al,0Eh
	out	dx, al
	dec	dx

	mov	bx , 0FFh
cl1:	dec	bx
	jnz	@F
	jmp	CaptureTimeOutError
@@:	in	al, dx			; DX = parallel status register
	test	al, 08h
	jnz	cl1

	shl	ax, 04h 		; Input Pixel #2

	inc	dx			; DX = parallel control register
	mov	al, 06h
	out	dx, al
	dec	dx

; Process raw pixel data

	mov	bh, ah			; Unpack
	mov	bl, ah			; bl = pixel #1 , 4 bits
	shr	bl, 04h 		; bh = pixel #2 , 4 bits
	and	bh, 0Fh
	or	bl, bl			; Adjust pixels but Do not invert (0)
	jz	@F			; data , black
	xor	bl, 0Fh
@@:	or	bh, bh
	jz	@F
	xor	bh, 0Fh
@@:	shl	bx, 02h 		; Scale for 6 bit CLUT

; Write pixels to XMode screen

	push	dx			; Write (2) , 4 bit  pixels to
	mov	dl, 0C4h		; Select plane (0,1,2,3)
	test	cx, 1
	mov	ah, 01h
	jz	@F
	mov	ah, 04h
@@:	mov	al, 02h
	out	dx, ax
	mov	BYTE PTR es:[di], bl	; Write pixel #1
	shl	ah, 01h 		; Select plane
	out	dx, ax
	mov	BYTE PTR es:[di], bh	; Write pixel #2
	cmp	ah, 08h 		; Plane (3) ?
	jne	@F
	inc	di			; Next (4) pixels
@@:	pop	dx

	add	bl, bh			; Sum brightness
	movzx	ebx, bl 		;
	add	DWORD PTR SumBrightness, ebx

	loop	CaptureLoop1
	pop	cx			; End of frame ?
	dec	cx
	jz	CaptureExit
	add	di,(320 - PIXELCOUNT)/4 ; Next line , adjust for line length
	jmp	CaptureMainLoop


CaptureExit:
	inc	dx			; DX = PPC
	mov	al, 0Eh
	out	dx, al

	pop	es
	popa
	ret

CaptureTimeOutError:
	pop	cx
	pop	es			; Restore and fix stack
	popa
	pop	ax
	mov	ax, 0E07h		; Error Beep
	int	10h
	mov	ax, 0E07h		; Error Beep
	int	10h
	jmp	ProgramExit

;*****************************************************************************
; Index/data pairs for CRT Controller registers that differ between
; mode 13h and mode X.

CRTParms LABEL WORD
	DW	00D06h			; Vertical total
	DW	03E07h			; Overflow (bit 8 of vertical counts)
	DW	04109h			; Cell height (2 to double-scan)
	DW	0EA10h			; Vsync start
	DW	0AC11h			; Vsync end and protect cr0-cr7
	DW	0DF12h			; Vertical displayed
	DW	00014h			; Turn off dword mode
	DW	0E715h			; Vblank start
	DW	00616h			; Vblank end
	DW	0E317h			; Turn on byte mode

CRT_PARM_LENGTH equ	(($-CRTParms)/2)

SetModeX:
	mov	ax, 13h 		; Let the BIOS set standard 256-color
	int	10h			; Mode (320x200 linear)

       mov     dx, SC_INDEX
       mov     ax, 0604h
       out     dx, ax		       ; Disable chain4 mode
       mov     ax, 0100h
       out     dx, ax		       ; Synchronous reset while setting Misc Output

; for safety, even though clock unchanged

	mov	dx, MISC_OUTPUT
	mov	al, 0E3h
	out	dx, al			; Select 25 MHz dot clock & 60 Hz scanning rate

	mov	dx, SC_INDEX
	mov	ax, 0300h
	out	dx, ax			; Undo reset (restart sequencer)

	mov	dx, CRTC_INDEX		; Reprogram the CRT Controller
	mov	al, 11h 		; VSync End reg contains register write
	out	dx, al			; Protect bit
	inc	dx			; CRT Controller Data register
	in	al, dx			; Get current VSync End register setting
	and	al, 7fh 		; Remove write protect on various
	out	dx, al			; CRTC registers
	dec	dx			; CRT Controller Index
	mov	si, OFFSET CRTParms	; Point to CRT parameter table
	mov	cx, CRT_PARM_LENGTH	; # of table entries

SetCRTParmsLoop:
	lodsw				; Get the next CRT Index/Data pair
	out	dx, ax			; Set the next CRT Index/Data pair
	loop	SetCRTParmsLoop

	mov	dx, SC_INDEX
	mov	ax, 0F02h
	out	dx, ax			; Enable writes to all four planes
	mov	ax, SCREEN_SEG		; Now clear all display memory, 8 pixels
	push	es
	mov	es, ax			; at a time
	sub	di, di			; Point ES:DI to display memory
	sub	ax, ax			; Clear to zero-value pixels
	mov	cx, 8000h		; # of words in display memory
	rep	stosw			; Clear all of display memory
	pop	es

	ret

;*****************************************************************************

SetCLUTGray6Bit:
	mov	di, OFFSET CLUTBuffer
	mov	cx, 64*3		; Create 6 bit greyscale  , 0 - 3Fh
	mov	ax, 0FFFFh
@@:	inc	al
	inc	ah
	stosw
	stosb
	loop	@B

	mov	cx, 64 * 3		; Write to CLUT
	mov	dx, 3C8h
	mov	al, 0
	out	dx, al
	inc	dx
	mov	si, OFFSET CLUTBUFFER
	rep	outsb
	ret

;*****************************************************************************

Delay100msec:
	push	ax
	push	bx
	push	cx
	push	dx

@@:	xor	ah, ah			; Get current tick count
	int	1ah
	mov	bx, dx			; Save tick LSW count
TickLoop:
	xor	ah, ah			; Get current tick count
	int	1ah
	mov	ax, bx
	sub	dx,ax			; Find delta
	js	@B			; Branch if delta is negative , rollover
	cmp	dx, 2			; Count 2 ticks ?
	jl	TickLoop

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

;*****************************************************************************

Strobe:
	push	cx
	push	dx

	mov	dx, PPC 		; DX = parallel control port
	mov	al, 06h
	out	dx, al

	dec	dx			; DX = parallel status port
	mov	cx, 0FFh
@@:	dec	cx
	jz	StrobeTimeOutError
	in	al, dx
	test	al, 08h
	jz	@B

	shl	ax, 04h 		; Save PPS [7:4]

	inc	dx			; DX = parallel control port
	mov	al, 0Eh
	out	dx, al
	dec	dx			; DX = parallel status port

	mov	cx, 0FFh
@@:	dec	cx
	jz	StrobeTimeOutError
	in	al, dx
	test	al, 08h
	jnz	@B

	shr	ax, 04h 		; Swap nibbles
	ror	al, 04h 		;

	pop	dx
	pop	cx
	ret

StrobeTimeOutError:
	pop	dx			; Restore and fix stack
	pop	cx
	pop	ax
	mov	ax, 0E07h		; Error Beep
	int	10h
	jmp	ProgramExit

;*****************************************************************************
SetPage:

	mov	bx, 03D4h			; BX = CRTC index register
	mov	ah, 0Ch 			; AH = CRTC index
	mov	cl, PageNumber			; CL = Page number
	test	cl, 01h 			;
	mov	di, Page1Offset 		; Video memory page 1 offset
	mov	ch, Page0StartAddressMSB	; CRTC page 0 start address
	jz	@F				; Page 0 , branch if true
	mov	di, Page0Offset 		; Video memory page 0 offset
	mov	ch, Page1StartAddressMSB	; CRTC page 1 start address
@@:	mov	dx, 03DAh			;
	mov	dx, bx				; Output start address MSB
	mov	al, ah
	mov	ah, ch
	out	dx, ax
@@:	in	al, dx				; Wait for vsync
	test	al, 08h
	jz	@B
	inc	cl				; Toggle Page number and save
	and	cl, 01h
	mov	PageNumber, cl
	ret


;*****************************************************************************
; Automatic brightness calculates the average brightness of the view
; and compares this to a optimum brightness constant. If the average
; brightness is less than the optimum brightness the current brightness
; level is increased by (1). If the average brightness is greater than
; the optimum brightness the current brightness level is decreased by (1).
; This approach requires many frames before the brightness is fully
; compensated.

IF	AUTOMATICBRIGHTNESS

AutoBright:
	mov	eax, DWORD PTR SumBrightness	; Calculate average brightness
	mov	ebx, TOTALPIXELS		; # of pixels
	xor	edx, edx
	div	ebx
	shl	al, 02h 			; Scale , * 4
	mov	BYTE PTR AverageBrightness, al
	xor	ebx, ebx
	mov	DWORD PTR SumBrightness, ebx	; Zero sum
	mov	ah, BYTE PTR OptimumBrightness
	cmp	ah, al
	mov	ah, BYTE PTR SetBrightness
	ja	IncreaseBrightness
	jb	DecreaseBrightness
	jmp	AutoBrightExit
IncreaseBrightness:
	inc	ah
	jz	@F
	jmp	SHORT AutoBrightExit
@@:	mov	ah, 0F0h
	jmp	SHORT AutoBrightExit
DecreaseBrightness:
	dec	ah
	cmp	ah, 0FFh
	jnz	AutoBrightExit
	mov	ah, 0
AutoBrightExit:
@@:	mov	BYTE PTR SetBrightness, ah
	ret

ENDIF	;AUTOMATICBRIGHTNESS

;*****************************************************************************
; Data and varibles							     *
;*****************************************************************************


PageNumber LABEL BYTE
	DB	0

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




CLUTBuffer LABEL BYTE

	DB	(64 * 3) DUP (0)

;*****************************************************************************

TST	ENDS

END	START





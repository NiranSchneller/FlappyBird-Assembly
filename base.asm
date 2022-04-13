IDEAL
MODEL small



STACK 100h

START_SCREEN equ 'Start.bmp'
MAIN_SCREEN equ 'Main.bmp'
HELP_SCREEN equ 'Help.bmp'
BIRD equ 'Bird.bmp'

BMP_WIDTH = 320

PLAYER_SIZE = 20


; true if carry flag is one



DATASEG
	
	MainName  db MAIN_SCREEN , 0
	HelpName db HELP_SCREEN , 0
	StartName db START_SCREEN , 0
	BirdName db BIRD, 0
	FileHandle	dw ?
	Header 	    db 54 dup(0)
	Palette 	db 400h dup (0)
	
	BmpLeft dw ?
	BmpTop dw ?
	BmpColSize dw ?
	BmpRowSize dw ?
	
	ErrorFile db 0

	BmpFileErrorMsg    	db 'Error At Opening Bmp File ',MAIN_SCREEN, 0dh, 0ah,'$'
	
	
	ScrLine db BMP_WIDTH dup (0)  ; One Color line read buffer
	
	PlayerYPosition db 100 ; Starting player position (half of screen )

	
CODESEG
 
start:                          
	mov ax,@data			 
	mov ds,ax	
	
	call SetGraphic
	
	
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] ,200
	
	ShowMain: 
		mov ax, 1
		int 33h
		call MainScreen
	
exit:	
	mov ax,4C00h
    int 21h
	
	
proc MainScreen
	
	mov dx, offset MainName
	call OpenShowBmp
		
	ClickWaitWithDelay:
		mov cx,1000
	@@Wait:	
		loop @@Wait
	WaitTillPressOnPoint:

	mov dx, offset MainName
	call OpenShowBmp
	
	mov ax,5h
	mov bx,0 
	int 33h
	
	
	cmp bx,00h
	jne ClickWaitWithDelay  ; mouse wasn't pressed
	
	shr cx, 1 ; 640 / 2 = 320
	jmp Clicked
	GoToHelp: 
		jmp HelpScreen
	GoToGame:
		jmp Game
	; if (horizontal position > 135 && < 184 && vertical position > 162 && < 177) -> go to help
	Clicked: 
		push 135
		push 184
		push 162
		push 177
		call isInBoundary
		;IS_IN_BOUNDARY 135, 184, 162, 177
		jc GoToHelp
		
		push 135
		push 184
		push 129
		push 142
		call isInBoundary
		;IS_IN_BOUNDARY 135, 184, 129, 142
		jc GoToGame
		
	jmp ClickWaitWithDelay
		
	
	
	ret
endp MainScreen




proc HelpScreen

	mov dx, offset HelpName
	call OpenShowBmp
		
	@@@ClickWaitWithDelay:
		mov cx,1000
	@@@Wait:	
		loop @@@Wait
	@@@WaitTillPressOnPoint:

	mov dx, offset HelpName
	call OpenShowBmp
	
	mov ax,5h
	mov bx,0 
	int 33h
	
	
	cmp bx,00h
	jne @@@ClickWaitWithDelay  ; mouse wasn't pressed

	shr cx, 1
	
	jmp MouseHasBeenClicked
	
	@@GoToGame:	
		jmp Game
	@@GoToMain: 
		jmp MainScreen
	
	
	MouseHasBeenClicked: 
		push 248
		push 292
		push 140
		push 147
		call isInBoundary
		jc @@GoToGame
		
		push 250
		push 290
		push 155
		push 166
		call isInBoundary
		jc @@GoToMain
		
	jmp @@@ClickWaitWithDelay
	

	

	ret
endp HelpScreen

proc Game
	; initialize: 
	
	mov cx, 0
	mov dx, 0
	mov al, 0
	mov si, 200
	mov di, 400
	call Rect ; erase screen
	
	call InitializePlayer
	
	
	MainLoop: 
		call HandlePlayer ; handles player movement
		
	jmp MainLoop
	ret
endp Game

proc HandlePlayer
	mov ah, 1h
	int 16h 
	jz KeyPressed ; if a key was pressed 
	jmp KeyNotPressed
	
	KeyPressed: 
		mov ah, 0h ; clear buffer
		int 16h
		cmp ah, 84
		jne DownKeyNotPressed
		call MovePlayerDown
	
	DownKeyNotPressed: 
	
	
	
	KeyNotPressed: 
	ret
endp HandlePlayer

proc MovePlayerDown
	
	call ErasePlayer
	add [PlayerYPosition], 4
	call DrawPlayer
	
	ret
endp MovePlayerDown

proc DrawPlayer
	mov [BmpLeft],20
	
	push ax
	
	mov al, [PlayerYPosition]
	mov [BmpTop], ax
	
	pop ax
	
	mov [BmpColSize],PLAYER_SIZE
	mov [BmpRowSize],PLAYER_SIZE
	
	mov dx, offset BirdName
	call OpenShowBmp
	
	ret
endp DrawPlayer

proc ErasePlayer
	
	mov cx, 10
	mov dl, [PlayerYPosition]
	sub dl, 20
	mov si, 30
	mov di, 20
	call Rect
	
	ret	
endp ErasePlayer


proc InitializePlayer
	mov [BmpLeft],20
	mov [BmpTop],100
	mov [BmpColSize],PLAYER_SIZE
	mov [BmpRowSize],PLAYER_SIZE
	
	mov dx, offset BirdName
	call OpenShowBmp
	
	ret
endp InitializePlayer

; true if carry flag
proc isInBoundary
	push bp
	mov bp, sp
	
	lower_x equ [bp+10] 
	higher_x equ [bp+8] 
	lower_y equ [bp+6] 
	higher_y equ [bp+4]
	
	jmp Check
	CarryTrue: 
		pop bp
		jmp exitProc
	
	Check: 
	cmp cx, lower_x
	jb endBoundaryCheck
	cmp cx, higher_x 
	ja endBoundaryCheck
	cmp dx, lower_y
	jb endBoundaryCheck
	cmp dx, higher_y
	ja endBoundaryCheck
	stc
	jmp CarryTrue
	
	endBoundaryCheck: 
		pop bp
		clc
	exitProc: 
	ret 8
endp isInBoundary
 
proc DrawVerticalLine
	push si
	push dx
 
DrawVertical:
	cmp si,0
	jz @@ExitDrawLine	
	 
    mov ah,0ch	
	int 10h    ; put pixel
	
	 
	
	inc dx
	dec si
	jmp DrawVertical
	
	
@@ExitDrawLine:
	pop dx
    pop si
	ret
endp DrawVerticalLine

 ; cx = col dx= row al = color si = height di = width 
proc Rect
	push cx
	push di
NextVerticalLine:	
	
	cmp di,0
	jz @@EndRect
	
	cmp si,0
	jz @@EndRect
	call DrawVerticalLine
	inc cx
	dec di
	jmp NextVerticalLine
	
	
@@EndRect:
	pop di
	pop cx
	ret
endp Rect


proc OpenShowBmp
	
	 
	call OpenBmpFile
	cmp [ErrorFile],1
	je @@ExitProc
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call  ShowBmp
	
	 
	call CloseBmpFile

@@ExitProc:
	ret
endp OpenShowBmp



; Read 54 bytes the Header
proc ReadBmpHeader					
	push cx
	push dx
	
	mov ah,3fh
	mov bx, [FileHandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	
	pop dx
	pop cx
	ret
endp ReadBmpHeader

proc ReadBmpPalette ; Read BMP file color palette, 256 colors * 4 bytes (400h)
						 ; 4 bytes for each color BGR + null)			
	push cx
	push dx
	
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	
	pop dx
	pop cx
	
	ret
endp ReadBmpPalette


; Will move out to screen memory the colors
; video ports are 3C8h for number of first color
; and 3C9h for all rest
proc CopyBmpPalette						
										
	push cx
	push dx
	
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0  ; black first							
	out dx,al ;3C8h
	inc dx	  ;3C9h
CopyNextColor:
	mov al,[si+2] 		; Red				
	shr al,2 			; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing color resolution).				
	out dx,al 						
	mov al,[si+1] 		; Green.				
	shr al,2            
	out dx,al 							
	mov al,[si] 		; Blue.				
	shr al,2            
	out dx,al 							
	add si,4 			; Point to next color.  (4 bytes for each color BGR + null)				
								
	loop CopyNextColor
	
	pop dx
	pop cx
	
	ret
endp CopyBmpPalette

	
; input dx filename to open
proc OpenBmpFile						 
	mov ah, 3Dh
	xor al, al
	int 21h
	jc @@ErrorAtOpen
	mov [FileHandle], ax
	jmp @@ExitProc
	
@@ErrorAtOpen:
	mov [ErrorFile],1
@@ExitProc:	
	ret
endp OpenBmpFile

proc ShowBMP 
; BMP graphics are saved upside-down.
; Read the graphic line by line (BmpRowSize lines in VGA format),
; displaying the lines from bottom to top.
	push cx
	
	mov ax, 0A000h
	mov es, ax
	
	mov cx,[BmpRowSize]
	
 
	mov ax,[BmpColSize] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
	xor dx,dx
	mov si,4
	div si
	cmp dx,0
	mov bp,0
	jz @@row_ok
	mov bp,4
	sub bp,dx

@@row_ok:	
	mov dx,[BmpLeft]
	
@@NextLine:
	push cx
	push dx
	
	mov di,cx  ; Current Row at the small bmp (each time -1)
	add di,[BmpTop] ; add the Y on entire screen
	
 
	; next 5 lines  di will be  = cx*320 + dx , point to the correct screen line
	dec di
	mov cx,di
	shl cx,6
	shl di,8
	add di,cx
	add di,dx
	 
	; small Read one line
	mov ah,3fh
	mov cx,[BmpColSize]  
	add cx,bp  ; extra  bytes to each row must be divided by 4
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx,[BmpColSize]  
	mov si,offset ScrLine
	rep movsb ; Copy line to the screen
	
	pop dx
	pop cx
	 
	loop @@NextLine
	
	pop cx
	ret
endp ShowBMP 


proc CloseBmpFile
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseBmpFile


proc  SetGraphic
	mov ax,13h   ; 320 X 200 
				 ;Mode 13h is an IBM VGA BIOS mode. It is the specific standard 256-color mode 
	int 10h
	ret
endp 	SetGraphic




End start
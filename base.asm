IDEAL
MODEL small



STACK 100h

START_SCREEN equ 'Start.bmp'
MAIN_SCREEN equ 'Main.bmp'
HELP_SCREEN equ 'Help.bmp'
BIRD equ 'Bird.bmp'
BIRD_UP equ 'BirdUp.bmp'
ERASE_SCREEN equ 'Erase.bmp'

BMP_WIDTH = 320

PLAYER_SIZE = 15
PLAYER_PIXEL_MOVEMENT = 5
PLAYER_COLUMN = 20
TRUE = 1
FALSE = 0

POLE_WAIT_INTERVAL = 1

POLE_COLOR = 2 ; Goes by graphic mode colors
POLE_WIDTH = 20
POLE_PIXEL_MOVEMENT = 3

POLE_RECTANGLE_COLOR = 4
POLE_RECTANGLE_HEIGHT = 5
POLE_RECTANGLE_WIDTH = 5

DATASEG
	
	MainName  db MAIN_SCREEN , 0
	HelpName db HELP_SCREEN , 0
	StartName db START_SCREEN , 0
	BirdName db BIRD, 0
	BirdUpName db BIRD_UP, 0
	EraseScreenName db ERASE_SCREEN, 0
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
	
	FirstPoleXPosition dw 100 
	SecondPoleXPosition dw 200
	ThirdPoleXPosition dw 300
	CurrentScore db 0
	; first second and third just mean starting on the X axis when game Initializes
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
	
;==============================
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
	
	mov ax, 2h ; hide cursor
	int 33h
	
	mov dx, offset EraseScreenName
	call OpenShowBmp
	
	call InitializePlayer
	
	call InitializePoles
	;call ErasePoles
	
	mov cx, POLE_WAIT_INTERVAL ; this will be wait untill poles are erased and put on screen
	
	MainLoop: 
		push cx
		
		call HandlePlayerMovement ; handles player movement
		
		xor dx,dx ; RESET DX
		
		call HandleIllegalPlayerPosition ; position > 200 or position < 0
		
		cmp dx, TRUE
		je EndGame
		
		call HandlePlayerCollision
		cmp dx, TRUE
		je EndGame
		
		pop cx
		cmp cx, 0 
		je HandlePolesAllowed 
		dec cx
		jmp HandlePolesForbidden
		HandlePolesAllowed: 
			call HandlePoles
			mov cx, POLE_WAIT_INTERVAL
		HandlePolesForbidden: 
		
		;call HandleScore	
		
	jmp MainLoop
	
	EndGame: 
		pop cx
		;call PrintScore
		jmp DeathScreen
	ret
endp Game



proc PrintScore
	
	mov al, [CurrentScore]
	xor ah,ah
	
	call ShowAxDecimal
	
	ret
endp PrintScore

proc HandleScore
	mov ax, PLAYER_COLUMN
	cmp ax, [FirstPoleXPosition]
	ja IncrementScore
	jmp EndHandleScore
	
	IncrementScore:
		inc [CurrentScore]
	
	EndHandleScore: 
		
	ret
endp HandleScore

proc DeathScreen
	
	
	
	ret	
endp DeathScreen




proc HandlePlayerCollision
	; DX = row
	; CX = column
	mov dl, [PlayerYPosition]
	
	
	mov cx, PLAYER_SIZE
	@@LoopCollisionYAxis: 
	push cx
	
	mov cx, PLAYER_COLUMN
	inc cx
	add cx, PLAYER_SIZE
	
	inc dl
	
	mov ah, 0Dh
	int 10h
	
	cmp al, POLE_COLOR
	je SetDXRegister
	
	
	pop cx
	loop @@LoopCollisionYAxis
	
	mov cx, PLAYER_SIZE
	dec cx
	mov si, 0
	LoopCollisionTopXAxis:
		push cx
		
		mov cx, PLAYER_COLUMN
		add cx, si
		
		mov dl, [PlayerYPosition]
		dec dl
		xor dh, dh
		
		mov ah, 0Dh
		int 10h
		
		cmp al, POLE_COLOR
		je SetDXRegister
		
		
		sub cx, si
		inc si
		pop cx
	loop LoopCollisionTopXAxis
	
	mov cx, PLAYER_SIZE
	dec cx
	mov si, 0
	LoopCollisionBottomXAxis:
		push cx
		
		mov cx, PLAYER_COLUMN
		add cx, si
		
		mov dl, [PlayerYPosition]
		add dl, PLAYER_SIZE
		xor dh,dh
		
		mov ah, 0Dh
		int 10h
		
		
		cmp al, POLE_COLOR
		je SetDXRegister
		
		
		sub cx, si
		inc si
		pop cx
	loop LoopCollisionBottomXAxis
	
	jmp endHandlePlayerCollision
	
	SetDXRegister: 
		mov dx, TRUE
		pop cx
	endHandlePlayerCollision: 
	
	ret
endp HandlePlayerCollision

proc InitializePoles
	
	mov cx, [FirstPoleXPosition]
	call DrawLowPole
	
	mov cx, [SecondPoleXPosition]
	call DrawLowPole
	
	mov cx, [ThirdPoleXPosition]
	call DrawHighPole
	
	
	ret
endp InitializePoles

proc HandlePoles
	xor cx,cx

	
	call ErasePoles

	sub [FirstPoleXPosition], POLE_PIXEL_MOVEMENT
	sub [SecondPoleXPosition], POLE_PIXEL_MOVEMENT
	sub [ThirdPoleXPosition], POLE_PIXEL_MOVEMENT
	
	mov cx, [FirstPoleXPosition]
	call DrawLowPole
	
	
	mov cx, [SecondPoleXPosition]
	call DrawLowPole
	
	
	mov cx, [ThirdPoleXPosition]
	call DrawHighPole
	

	ret
endp HandlePoles

proc ErasePoles
	mov cx, [FirstPoleXPosition]
	call EraseLowPole
	
	mov cx, [SecondPoleXPosition]
	call EraseLowPole
	
	mov cx, [ThirdPoleXPosition]
	call EraseHighPole
	
	ret
endp ErasePoles

proc HandleIllegalPlayerPosition
	xor ax,ax
	jmp CheckForForbiddenPositon
	
	SetDX: 
		mov dx, TRUE
		jmp EndHandleIllegalPlayerPosition
		
	
	CheckForForbiddenPositon:
		mov al, [PlayerYPosition]
		
		mov dl, 200
		sub dl, PLAYER_SIZE
		
		cmp al, dl
		ja SetDX
		
		cmp al, 1
		jb SetDX
	
	EndHandleIllegalPlayerPosition: 
	ret
endp HandleIllegalPlayerPosition

proc HandlePlayerMovement

	mov ah, 1h
	int 16h
	jnz KeyPressed ; if a key was pressed (ZF = 0) 
	jmp KeyNotPressed
	
	KeyPressed: 
		mov ah, 00h ; clear buffer
		int 16h
		cmp al, 's' 
		je DownKeyPressed
		cmp al, 'S'
		je DownKeyPressed
		
		
		cmp al, 'w'
		je UpKeyPressed
		cmp al, 'W'
		je UpKeyPressed
		
		jmp KeyNotPressed
	
	DownKeyPressed: 
		call MovePlayerDown
		jmp KeyNotPressed
	UpKeyPressed: 
		call MovePlayerUp
	KeyNotPressed: 
		
	ret
endp HandlePlayerMovement

proc MovePlayerDown
	
	call ErasePlayer
	add [PlayerYPosition], PLAYER_PIXEL_MOVEMENT
	
	call DrawPlayer
	
	ret
endp MovePlayerDown

proc MovePlayerUp
	
	call ErasePlayer
	sub [PlayerYPosition], PLAYER_PIXEL_MOVEMENT
	call DrawPlayer
	
	ret
endp MovePlayerUp

proc DrawPlayer
	mov [BmpLeft],PLAYER_COLUMN
	
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
	
	mov cx, 20
	mov dl, [PlayerYPosition]
	mov al, 0
	mov si, PLAYER_SIZE
	mov di, PLAYER_SIZE
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

proc DrawLowPole 
	push ax
	push dx
	push si
	push di
	
	mov al, POLE_COLOR
	mov dx, 0 ; row
	mov si, 130 ; height
	mov di, POLE_WIDTH ; width
	call Rect
	
	;push cx
	;push dx
	;
	;mov al, POLE_RECTANGLE_COLOR
	;mov dx, 140
	;
	;mov si, POLE_WIDTH
	;shr si, 1
	;
	;add ax, si
	;
	;
	;add cx, ax
	;
	;mov si, POLE_RECTANGLE_HEIGHT
	;mov di, POLE_RECTANGLE_WIDTH
	;call Rect
	;
	;pop dx
	;pop cx
	
	mov al, POLE_COLOR
	mov dx, 170 ; row
	mov si, 30 ; height
	mov di, POLE_WIDTH ; width
	call Rect
	
	pop di
	pop si
	pop dx
	pop ax
	
	ret
endp DrawLowPole 

proc DrawMidPole 
	
	push ax
	push dx
	push si
	push di
	
	mov al, POLE_COLOR
	mov dx, 0 ; row
	mov si, 75 ; height
	mov di, POLE_WIDTH ; width
	call Rect
	
	mov al, POLE_COLOR
	mov dx, 115 ; row
	mov si, 85 ; height
	mov di, POLE_WIDTH ; width
	call Rect

	pop di
	pop si
	pop dx
	pop ax

	ret
endp DrawMidPole 

proc DrawHighPole
	
	push ax
	push dx
	push si
	push di
	
	mov dx, 0
	mov al, POLE_COLOR
	mov si, 10
	mov di, POLE_WIDTH
	call Rect

	mov dx, 50
	mov al, POLE_COLOR
	mov si, 150
	mov di, POLE_WIDTH
	call Rect
	
	pop di
	pop si
	pop dx
	pop ax

	ret
endp DrawHighPole 

proc EraseLowPole 
	
	push ax
	push dx
	push si
	push di
	
	mov al, 0
	mov dx, 0 ; row
	mov si, 130 ; height
	mov di, POLE_WIDTH ; width
	call Rect

	
	;push cx
	;push dx
	;
	;
	;mov dx, 140
	;
	;mov si, POLE_WIDTH
	;shr si, 1
	;
	;add ax, si
	;
	;
	;add cx, ax
	;
	;mov al, 0
	;mov si, POLE_RECTANGLE_HEIGHT
	;mov di, POLE_RECTANGLE_WIDTH
	;call Rect
	;
	;pop dx
	;pop cx
	

	mov al, 0
	mov dx, 170 ; row
	mov si, 30 ; height
	mov di, POLE_WIDTH ; width
	call Rect
	
	pop di
	pop si
	pop dx
	pop ax

	ret
endp EraseLowPole 

proc EraseMidPole 
	push ax
	push dx
	push si
	push di
	
	mov al, 0
	mov dx, 0 ; row
	mov si, 75 ; height
	mov di, POLE_WIDTH ; width
	call Rect
	
	mov al, 0
	mov dx, 115 ; row
	mov si, 85 ; height
	mov di, POLE_WIDTH ; width
	call Rect

	pop di
	pop si
	pop dx
	pop ax


	ret

endp EraseMidPole

proc EraseHighPole
	
	push ax
	push dx
	push si
	push di
	
	mov dx, 0
	mov al, 0
	mov si, 10
	mov di, POLE_WIDTH
	call Rect

	mov dx, 50
	mov al, 0
	mov si, 150
	mov di, POLE_WIDTH
	call Rect
	
	pop di
	pop si
	pop dx
	pop ax

	ret
endp EraseHighPole

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


proc ShowAxDecimal
       push ax
	   push bx
	   push cx
	   push dx
	   
	   ; check if negative
	   test ax,08000h
	   jz PositiveAx
			
	   ;  put '-' on the screen
	   push ax
	   mov dl,'-'
	   mov ah,2
	   int 21h
	   pop ax

	   neg ax ; make it positive
PositiveAx:
       mov cx,0   ; will count how many time we did push 
       mov bx,10  ; the divider
   
put_mode_to_stack:
       xor dx,dx
       div bx
       add dl,30h
	   ; dl is the current LSB digit 
	   ; we cant push only dl so we push all dx
       push dx    
       inc cx
       cmp ax,9   ; check if it is the last time to div
       jg put_mode_to_stack

	   cmp ax,0
	   jz pop_next  ; jump if ax was totally 0
       add al,30h  
	   mov dl, al    
  	   mov ah, 2h
	   int 21h        ; show first digit MSB
	       
pop_next: 
       pop ax    ; remove all rest LIFO (reverse) (MSB to LSB)
	   mov dl, al
       mov ah, 2h
	   int 21h        ; show all rest digits
       loop pop_next
		
	   mov dl, ','
       mov ah, 2h
	   int 21h
   
	   pop dx
	   pop cx
	   pop bx
	   pop ax
	   
	   ret
endp ShowAxDecimal



End start

IDEAL
MODEL small



STACK 100h



START_SCREEN equ 'Start.bmp'
MAIN_SCREEN equ 'Main.bmp'
HELP_SCREEN equ 'Help.bmp'
BIRD equ 'Bird.bmp'
BIRD_UP equ 'BirdUp.bmp'
ERASE_SCREEN equ 'Erase.bmp'
SCORE_TABLE equ 'Scores.txt'
BMP_WIDTH = 320

PLAYER_SIZE = 15
PLAYER_AUTO_PIXEL_MOVEMENT = 4
PLAYER_MANUAL_PIXEL_MOVEMENT = 30
PLAYER_COLUMN = 30
TRUE = 1
FALSE = 0
SPACE_HEIGHT = 70
POLE_WAIT_INTERVAL = 0
POLE_BOUNDARY = 0
POLE_COLOR = 2 ; Goes by graphic mode colors
POLE_WIDTH = 20
POLE_PIXEL_MOVEMENT = 2
MINIMUM_SPACE_HEIGHT = 50
MAXIMUM_SPACE_HEIGHT = 90
BACKGROUND_COLOR = 9

DATASEG
	
	MainName  db MAIN_SCREEN , 0
	HelpName db HELP_SCREEN , 0
	StartName db START_SCREEN , 0
	BirdName db BIRD, 0
	BirdUpName db BIRD_UP, 0
	EraseScreenName db ERASE_SCREEN, 0
	ScoresName db SCORE_TABLE, 0 
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
	FirstPoleStartSpaceRow dw 10 ; start of space
	FirstPoleEndSpaceRow dw 10 + SPACE_HEIGHT ; end of space
	
	SecondPoleXPosition dw 200
	SecondPoleStartSpaceRow dw 10 ; start of space
	SecondPoleEndSpaceRow dw 10 + SPACE_HEIGHT ; end of space
	
	ThirdPoleXPosition dw 300
	ThirdPoleStartSpaceRow dw 10 ; start of space
	ThirdPoleEndSpaceRow dw 10 + SPACE_HEIGHT ; end of space
	
	CurrentScore db 0
	Temp db 0
	
	RndCurrentPos dw start

	IsBeforeFirstPole db TRUE
	IsBeforeSecondPole db TRUE ; changes when pole respawns
	IsBeforeThirdPole db TRUE

	
	

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

proc DrawScreen
	mov cx, 0
	mov dx, 0	
	mov di, 320
	mov si, 200
	mov al, BACKGROUND_COLOR
	call Rect

	
	ret
endp DrawScreen


proc Game
	; initialize: 
	
	mov ax, 2h ; hide cursor
	int 33h
	
	call DrawScreen
	
	call InitializePlayer
	
	call InitializePoles
	;call ErasePoles
	mov ah, 00h ; clear buffer
	int 16h
	
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
		
		call HandleScore	
		
	jmp MainLoop
	
	EndGame: 
		pop cx
		call HandleScoreTable
		jmp DeathScreen
	ret
endp Game

proc HandleScoreTable
	
	;mov dx, offset ScoresName
	;call OpenFile
	;
	;;call InputScoreIntoScoreTable
	;
	
	mov al, [CurrentScore]
	call ShowAxDecimal
	
	;
	;
	;mov dx, offset ScoresName
	;call CloseFile
	

	ret
endp HandleScoreTable

proc InputScoreIntoScoreTable
	
	

	
	
	ret
endp InputScoreIntoScoreTable



proc HandleIsBeforePole
	push bp
	mov bp, sp
	
	POLE_ADDRESS equ [bp+6]
	IS_BEFORE_POLE equ [bp+4]
	
	mov bx, IS_BEFORE_POLE
	
	mov ax, TRUE
	cmp [bx], ax
	jne EndHandlingScoreVariable
	
	HandleScoreIncrementation: 
	
		
		mov bx, POLE_ADDRESS
		mov ax, [bx]
		add ax, POLE_WIDTH
		
		mov bx, PLAYER_COLUMN
		cmp bx, ax
		ja IncrementScore
		jmp EndHandlingScoreVariable
			IncrementScore:
				
				inc [CurrentScore]
				mov bx, IS_BEFORE_POLE
				mov ax, FALSE
				mov [bx], ax
	EndHandlingScoreVariable: 
	
	pop bp	
	ret 4
endp HandleIsBeforePole


proc HandleScore

	push offset FirstPoleXPosition
	push offset IsBeforeFirstPole
	call HandleIsBeforePole
	
	
	push offset SecondPoleXPosition
	push offset IsBeforeSecondPole
	call HandleIsBeforePole
	
	
	push offset ThirdPoleXPosition
	push offset IsBeforeThirdPole
	call HandleIsBeforePole
	
	
	
	ret
endp HandleScore

proc DeathScreen
	
	
	
	ret	
endp DeathScreen

proc ScanPlayerPerimeterForGivenColor 
	push bp
	mov bp, sp
	
	GIVEN_COLOR equ [bp+4]
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
	
	cmp al, GIVEN_COLOR
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
		
		cmp al, GIVEN_COLOR
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
		
		
		cmp al, GIVEN_COLOR
		je SetDXRegister
		
		
		sub cx, si
		inc si
		pop cx
	loop LoopCollisionBottomXAxis
	
	jmp endScanPlayerPerimeterForGivenColor
	
	SetDXRegister: 
		mov dx, TRUE
		pop cx
	endScanPlayerPerimeterForGivenColor: 
	pop bp
	ret 2 
endp ScanPlayerPerimeterForGivenColor

proc HandlePlayerCollision
	push POLE_COLOR
	
	call ScanPlayerPerimeterForGivenColor
	
	
	ret
endp HandlePlayerCollision

proc InitializePoles
	
	mov cx, [FirstPoleXPosition]
	push [FirstPoleStartSpaceRow]
	push [FirstPoleEndSpaceRow]
	call InitializePole
	
	mov cx, [SecondPoleXPosition]
	push [SecondPoleStartSpaceRow]
	push [SecondPoleEndSpaceRow]
	call InitializePole
	
	mov cx, [ThirdPoleXPosition]
	push [ThirdPoleStartSpaceRow]
	push [ThirdPoleEndSpaceRow]
	call InitializePole
	
	ret
endp InitializePoles


; make mask acording to bh size 
; output Si = mask put 1 in all bh range
; example  if bh 4 or 5 or 6 or 7 si will be 7
; 		   if Bh 64 till 127 si will be 127
Proc MakeMask    
    push bx

	mov si,1
    
@@again:
	shr bh,1
	cmp bh,0
	jz @@EndProc
	
	shl si,1 ; add 1 to si at right
	inc si
	
	jmp @@again
	
@@EndProc:
    pop bx
	ret
endp  MakeMask


; Description  : get RND between any bl and bh includs (max 0 -255)
; Input        : 1. Bl = min (from 0) , BH , Max (till 255)
; 			     2. RndCurrentPos a  word variable,   help to get good rnd number
; 				 	Declre it at DATASEG :  RndCurrentPos dw ,0
;				 3. EndOfCsLbl: is label at the end of the program one line above END start		
; Output:        Al - rnd num from bl to bh  (example 50 - 150)
; More Info:
; 	Bl must be less than Bh 
; 	in order to get good random value again and agin the Code segment size should be 
; 	at least the number of times the procedure called at the same second ... 
; 	for example - if you call to this proc 50 times at the same second  - 
; 	Make sure the cs size is 50 bytes or more 
; 	(if not, make it to be more) 
proc RandomByCs
    push es
	push si
	push di
	
	mov ax, 40h
	mov	es, ax
	
	sub bh,bl  ; we will make rnd number between 0 to the delta between bl and bh
			   ; Now bh holds only the delta
	cmp bh,0
	jz @@ExitP
 
	mov di, [word RndCurrentPos]
	call MakeMask ; will put in si the right mask according the delta (bh) (example for 28 will put 31)
	
RandLoop: ;  generate random number 
	mov ax, [es:06ch] ; read timer counter
	mov ah, [byte cs:di] ; read one byte from memory (from semi random byte at cs)
	xor al, ah ; xor memory and counter
	
	; Now inc di in order to get a different number next time
	inc di
	cmp di,(EndOfCsLbl - start - 1)
	jb @@Continue
	mov di, offset start
@@Continue:
	mov [word RndCurrentPos], di
	
	and ax, si ; filter result between 0 and si (the mask)
	cmp al,bh    ;do again if  above the delta
	ja RandLoop
	
	add al,bl  ; add the lower limit to the rnd num
		 
@@ExitP:	
	pop di
	pop si
	pop es
	ret
endp RandomByCs

proc ChangePolePositionToMax
	push bp
	mov bp, sp
	
	
	POLE_ADDRESS equ [bp+10]
	POLE_START_SPACE equ [bp+8]
	POLE_END_SPACE equ [bp+6]
	IS_BEFORE_POLE equ [bp+4]
	
	mov bx, POLE_ADDRESS
	
	mov ax, [bx]
	cmp ax, POLE_BOUNDARY
	jle ChangePoleToMax
	jmp EndPoleChangePosition
	ChangePoleToMax: 
	
		
		mov cx, [bx]
		mov bx, POLE_START_SPACE
		push [bx]
		mov bx, POLE_END_SPACE
		push [bx]
		
		call EndPole
		
		call HandlePoleInconsistency

		
		mov ax, 320 ; screen width
		sub ax, POLE_WIDTH
		mov bx, POLE_ADDRESS
		mov [bx], ax
		
		
		mov bl, MINIMUM_SPACE_HEIGHT
		mov bh, MAXIMUM_SPACE_HEIGHT
		
		call RandomByCs
		
		push ax ; save random space
		
		xor ah,ah
		
		mov bl, 0
		mov cx, 200
		
		sub cx, ax ; 200 - space height
		mov bh, cl 
		
		
		
		call RandomByCs
		
		pop cx ; random space height into cx
		
		push ax ; random space start position
		push POLE_START_SPACE
		push POLE_END_SPACE
		push cx
		call ModifyPoleParameters
		
		mov cx, [FirstPoleXPosition]
		push [FirstPoleStartSpaceRow]
		push [FirstPoleEndSpaceRow]
		
		call InitializePole
		
		mov bx, IS_BEFORE_POLE
		mov ax, TRUE
		mov [bx], ax
	
	EndPoleChangePosition: 	
	pop bp
	ret 8
endp ChangePolePositionToMax

proc ModifyPoleParameters
	push bp
	mov bp, sp
	
	RANDOM_SPACE equ [bp+10]
	START_SPACE equ [bp+8]
	END_SPACE equ [bp+6]
	RANDOM_HEIGHT equ [bp+4]
	
	
	mov ax, RANDOM_SPACE
	mov bx, START_SPACE
	mov [bx], ax
	
	mov ax, RANDOM_SPACE
	add ax, RANDOM_HEIGHT
	
	mov bx, END_SPACE
	mov [bx], ax
	
	
	
	
	
	pop bp
	ret 8
endp ModifyPoleParameters


proc HandleIllegalPolePositions
	push offset FirstPoleXPosition
	push offset FirstPoleStartSpaceRow
	push offset FirstPoleEndSpaceRow
	push offset IsBeforeFirstPole
	call ChangePolePositionToMax
	
	push offset SecondPoleXPosition
	push offset SecondPoleStartSpaceRow
	push offset SecondPoleEndSpaceRow
	push offset IsBeforeSecondPole
	call ChangePolePositionToMax
	
	push offset ThirdPoleXPosition
	push offset ThirdPoleStartSpaceRow
	push offset ThirdPoleEndSpaceRow
	push offset IsBeforeThirdPole
	call ChangePolePositionToMax
	
	ret	
endp HandleIllegalPolePositions


proc HandlePoles
	xor cx,cx
	
	
	


	sub [FirstPoleXPosition], POLE_PIXEL_MOVEMENT
	sub [SecondPoleXPosition], POLE_PIXEL_MOVEMENT
	sub [ThirdPoleXPosition], POLE_PIXEL_MOVEMENT
	
	mov cx, [FirstPoleXPosition]
	push [FirstPoleStartSpaceRow]
	push [FirstPoleEndSpaceRow]
	call DrawPole
	
	mov cx, [SecondPoleXPosition]
	push [SecondPoleStartSpaceRow]
	push [SecondPoleEndSpaceRow]
	call DrawPole
	
	mov cx, [ThirdPoleXPosition]
	push [ThirdPoleStartSpaceRow]
	push [ThirdPoleEndSpaceRow]
	call DrawPole

	call ErasePoles
	
	call HandleIllegalPolePositions


	ret
endp HandlePoles

proc ErasePoles
	mov cx, [FirstPoleXPosition]
	push [FirstPoleStartSpaceRow]
	push [FirstPoleEndSpaceRow]
	call ErasePole
	
	mov cx, [SecondPoleXPosition]
	push [SecondPoleStartSpaceRow]
	push [SecondPoleEndSpaceRow]
	call ErasePole
	
	mov cx, [ThirdPoleXPosition]
	push [ThirdPoleStartSpaceRow]
	push [ThirdPoleEndSpaceRow]
	call ErasePole
	
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
		
		cmp al, 32
		je SpaceKeyPressed
		
		jmp KeyNotPressed
	SpaceKeyPressed: 
		call MovePlayerUp
		jmp EndHandlePlayerMovement
	KeyNotPressed: 
		call MovePlayerDown
	EndHandlePlayerMovement: 
	
	ret
endp HandlePlayerMovement

proc MovePlayerDown
	
	call ErasePlayer
	add [PlayerYPosition], PLAYER_AUTO_PIXEL_MOVEMENT
	
	call DrawPlayer
	
	ret
endp MovePlayerDown

proc MovePlayerUp
	
	call ErasePlayer
	sub [PlayerYPosition], PLAYER_MANUAL_PIXEL_MOVEMENT
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
	
	mov cx, PLAYER_COLUMN
	mov dl, [PlayerYPosition]
	mov al, BACKGROUND_COLOR
	mov si, PLAYER_SIZE
	mov di, PLAYER_SIZE
	call Rect
	
	ret	
endp ErasePlayer


proc InitializePlayer
	mov [BmpLeft],PLAYER_COLUMN
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

proc ErasePole
	push bp
	mov bp, sp
	
	END_OF_SPACE equ [bp+4]
	START_OF_SPACE equ [bp+6]

	
	push ax
	push dx
	push si
	push di
	
	
	
	mov ax, POLE_WIDTH
	sub ax, POLE_PIXEL_MOVEMENT
	
	add cx, ax
	mov di, ax

	
	
	mov dx, 0
	mov al, BACKGROUND_COLOR
	mov si, START_OF_SPACE
	call Rect
	

	mov ax, 200 ; graphic height
	sub ax, END_OF_SPACE
	
	mov si, ax
	
	mov ax, POLE_WIDTH
	sub ax, POLE_PIXEL_MOVEMENT
	
	mov di, ax	
	
	mov dx, END_OF_SPACE
	mov al, BACKGROUND_COLOR
	call Rect
	
	pop di
	pop si
	pop dx
	pop ax

	pop bp
	ret 4
endp ErasePole


proc DrawPole
	push bp
	mov bp, sp
	
	END_OF_SPACE equ [bp+4]
	START_OF_SPACE equ [bp+6]

	
	push ax
	push dx
	push si
	push di
	
	
	
	mov ax, POLE_WIDTH
	sub ax, POLE_PIXEL_MOVEMENT
	
	mov bx, POLE_WIDTH
	sub bx, ax
	mov ax, bx
	
	
	
	
	sub cx, ax
	mov di, ax
	
	
	
	
	mov dx, 0
	mov al, POLE_COLOR
	mov si, START_OF_SPACE
	call Rect
	

	mov ax, 200 ; graphic height
	sub ax, END_OF_SPACE
	
	mov si, ax
	

	
	
	mov dx, END_OF_SPACE
	mov al, POLE_COLOR
	call Rect
	
	pop di
	pop si
	pop dx
	pop ax

	pop bp
	ret 4
endp DrawPole

proc InitializePole
	push bp
	mov bp, sp
	
	
	
	END_OF_SPACE equ [bp+4]
	START_OF_SPACE equ [bp+6]

	
	
	push ax
	push dx
	push si
	push di
	
	
	
	
	mov dx, 0
	mov al, POLE_COLOR
	mov si, START_OF_SPACE
	mov di, POLE_WIDTH
	call Rect
	

	mov ax, 200 ; graphic height
	sub ax, END_OF_SPACE
	
	mov si, ax
	
	
	
	mov dx, END_OF_SPACE
	mov al, POLE_COLOR
	mov di, POLE_WIDTH
	call Rect
	
	pop di
	pop si
	pop dx
	pop ax

	pop bp
	ret 4
	

endp InitializePole

proc HandlePoleInconsistency
	
	mov cx, 320
	sub cx, POLE_PIXEL_MOVEMENT
	
	mov dx, 0
	mov si, 200
	mov di, POLE_PIXEL_MOVEMENT
	mov al, BACKGROUND_COLOR
	call Rect
	

	ret
endp HandlePoleInconsistency


proc EndPole
	push bp
	mov bp, sp
	
	;call HandlePoleInconsistency
	
	END_OF_SPACE equ [bp+4]
	START_OF_SPACE equ [bp+6]

	
	push ax
	push dx
	push si
	push di
	
	
	
	
	mov dx, 0
	mov al, BACKGROUND_COLOR
	mov si, START_OF_SPACE
	mov di, POLE_WIDTH
	call Rect
	

	mov ax, 200 ; graphic height
	sub ax, END_OF_SPACE
	
	mov si, ax
	
	
	
	mov dx, END_OF_SPACE
	mov al, BACKGROUND_COLOR
	mov di, POLE_WIDTH
	call Rect
	
	pop di
	pop si
	pop dx
	pop ax

	pop bp
	ret 4
endp EndPole

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
	
	 
	call OpenFile
	cmp [ErrorFile],1
	je @@ExitProc
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
	
	call  ShowBmp
	
	 
	call CloseFile

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
proc OpenFile						 
	mov ah, 3Dh
	mov al, 2
	int 21h
	jc @@ErrorAtOpen
	mov [FileHandle], ax
	jmp @@ExitProc
	
@@ErrorAtOpen:
	mov [ErrorFile],1
@@ExitProc:	
	ret
endp OpenFile

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


proc CloseFile
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseFile


proc  SetGraphic
	mov ax,13h   ; 320 X 200 
				 ;Mode 13h is an IBM VGA BIOS mode. It is the specific standard 256-color mode 
	int 10h
	ret
endp 	SetGraphic

;================================================
; Description - Write on screen the value of ax (decimal)
;               the practice :  
;				Divide AX by 10 and put the Mod on stack 
;               Repeat Until AX smaller than 10 then print AX (MSB) 
;           	then pop from the stack all what we kept there and show it. 
; INPUT: AX
; OUTPUT: Screen 
; Register Usage: AX  
;================================================
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


EndOfCsLbl:
End start
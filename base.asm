IDEAL
MODEL small



STACK 100h

MACRO PUSH_REGISTERS
	push ax bx cx dx di si 
ENDM 

MACRO POP_REGISTERS
	pop si di dx cx bx ax
ENDM

START_SCREEN equ 'Start.bmp'
MAIN_SCREEN equ 'Main.bmp'
HELP_SCREEN equ 'Help.bmp'
BIRD equ 'Bird.bmp'
BIRD_UP equ 'BirdUp.bmp'
ERASE_SCREEN equ 'Erase.bmp'
SCORE_TABLE equ 'Scores.txt'
BMP_WIDTH = 320
GAME_OVER equ 'GO.bmp'

PLAYER_SIZE = 15
PLAYER_AUTO_PIXEL_MOVEMENT = 2
PLAYER_MANUAL_PIXEL_MOVEMENT = 30
STARTING_PLAYER_Y_POSITION = 20
PLAYER_COLUMN = 30
FALSE = 0
TRUE = 1
POLE_WAIT_INTERVAL = 0
POLE_BOUNDARY = 0
POLE_COLOR = 2 ; Goes by graphic mode colors
POLE_WIDTH = 20
POLE_PIXEL_MOVEMENT = 2
FIRST_POLE_STARTING_POSITION = 	100
FIRST_POLE_SPACE_STARTING_POSITION = 10
SECOND_POLE_STARTING_POSITION = 200
SECOND_POLE_SPACE_STARTING_POSITION = 10
THIRD_POLE_STARTING_POSITION = 	300
THIRD_POLE_SPACE_STARTING_POSITION = 10
MINIMUM_SPACE_HEIGHT = 70
MAXIMUM_SPACE_HEIGHT = 90
BACKGROUND_COLOR = 9
GAME_OVER_RECTANGLE_COLOR = 0
GAME_OVER_COLUMN = 60
GAME_OVER_ROW = 60
GAME_OVER_WIDTH = 192
GAME_OVER_HEIGHT = 32
GAME_OVER_RECTANGLE_HEIGHT_CONSTANT = 50 
GAME_OVER_RECTANGLE_CONSTANT = 10 ; works on x axis and y axis


DATASEG
	
	MainName  db MAIN_SCREEN , 0
	HelpName db HELP_SCREEN , 0
	StartName db START_SCREEN , 0
	BirdName db BIRD, 0
	BirdUpName db BIRD_UP, 0
	EraseScreenName db ERASE_SCREEN, 0
	ScoresName db SCORE_TABLE, 0 
	GameOverName db GAME_OVER, 0
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
	
	PlayerYPosition db STARTING_PLAYER_Y_POSITION ; Starting player position
	
	FirstPoleXPosition dw FIRST_POLE_STARTING_POSITION
	FirstPoleStartSpaceRow dw FIRST_POLE_SPACE_STARTING_POSITION ; start of space
	FirstPoleEndSpaceRow dw FIRST_POLE_SPACE_STARTING_POSITION + MAXIMUM_SPACE_HEIGHT ; end of space
	
	SecondPoleXPosition dw SECOND_POLE_STARTING_POSITION
	SecondPoleStartSpaceRow dw SECOND_POLE_SPACE_STARTING_POSITION ; start of space
	SecondPoleEndSpaceRow dw SECOND_POLE_SPACE_STARTING_POSITION + MAXIMUM_SPACE_HEIGHT ; end of space
	
	ThirdPoleXPosition dw THIRD_POLE_STARTING_POSITION
	ThirdPoleStartSpaceRow dw THIRD_POLE_SPACE_STARTING_POSITION ; start of space
	ThirdPoleEndSpaceRow dw THIRD_POLE_SPACE_STARTING_POSITION + MAXIMUM_SPACE_HEIGHT ; end of space
	
	CurrentScore db 0
	
	RndCurrentPos dw start

	IsInFirstPoleZone db FALSE
	IsInSecondPoleZone db FALSE 
	IsInThirdPoleZone db FALSE

	ScoreMessage db " Final Score Is: ", '$'
	FinalMessage db  0dh, 0ah, " Press any key to continue...$"
	

CODESEG
 
start:                          
	mov ax,@data			 
	mov ds,ax	
	
	
	call MainScreen
	
	
exit:	
	mov ax,4C00h
    int 21h
	
	
	

proc InitializeValues

	mov [FirstPoleXPosition], FIRST_POLE_STARTING_POSITION
	
	mov [FirstPoleStartSpaceRow], FIRST_POLE_SPACE_STARTING_POSITION
	mov [FirstPoleEndSpaceRow], FIRST_POLE_SPACE_STARTING_POSITION
	add [FirstPoleEndSpaceRow], MAXIMUM_SPACE_HEIGHT
	
	mov [SecondPoleXPosition], SECOND_POLE_STARTING_POSITION
	mov [SecondPoleStartSpaceRow], SECOND_POLE_SPACE_STARTING_POSITION
	mov [SecondPoleEndSpaceRow], SECOND_POLE_SPACE_STARTING_POSITION
	add [SecondPoleEndSpaceRow], MAXIMUM_SPACE_HEIGHT
	
	mov [ThirdPoleXPosition], THIRD_POLE_STARTING_POSITION
	
	mov [ThirdPoleStartSpaceRow], THIRD_POLE_SPACE_STARTING_POSITION
	mov [ThirdPoleEndSpaceRow], THIRD_POLE_SPACE_STARTING_POSITION
	add [ThirdPoleEndSpaceRow], MAXIMUM_SPACE_HEIGHT
	
	mov [PlayerYPosition], STARTING_PLAYER_Y_POSITION
	mov [CurrentScore], 0
	
	mov [IsInFirstPoleZone], FALSE
	mov [IsInSecondPoleZone], FALSE
	mov [IsInThirdPoleZone], FALSE

	ret
endp InitializeValues
	

;==============================
; Description: 
;	this procedure initializes mainScreen, and waits for mouse input. When mouse is clicked,
;	it checks whether or not to switch screens.
;==============================

proc MainScreen
	call SetGraphic
	call InitializeValues
	
	
	mov ax, 1
	int 33h
	
	mov ah, 2
	mov bh, 2
	mov dl, 0
	mov dh, 0
	int 10h
	
	
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] ,200
	
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


;==============================
; Description: 
;	this procedure initializes helpScreen, and waits for mouse input. When mouse is clicked,
;	it checks whether or not to switch screens.
;==============================
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

;==============================
; Description: 
;	This procedure draws the screen. Goes by background color.
;==============================
proc DrawScreen
	mov [BmpLeft],0
	mov [BmpTop],0
	mov [BmpColSize], 320
	mov [BmpRowSize] ,200
	
	mov dx, offset EraseScreenName
	
	call OpenShowBmp
	
	ret
endp DrawScreen


;==============================
; Description: 
;	Manages the whole game. 
; 	Steps: 
; 	Before mainLoop:
;		Draw the screen
;		InitializePlayer
;		InitializePoles
;	MainLoop:
;		HandleScore
;		HandlePlayerMovement
;		HandleIllegalPlayerPosition
;		HandlePlayerCollision
;		HandlePoles
;	This loop runs until HandleIllegalPlayerPosition or HandlePlayerCollision returns true. In This case, the loop exits
;	After MainLoop:
;		Goto DeathScreen
;	
;==============================
proc Game
	; initialize: 
	
	mov ax, 2h ; hide cursor
	int 33h
	
	call DrawScreen
	
	call InitializePlayer
	
	call InitializePoles
	mov ah, 00h ; clear buffer
	int 16h
	
	mov cx, POLE_WAIT_INTERVAL ; this will be wait untill poles are erased and put on screen
	
	MainLoop: 
		push cx

		call HandleScore	

		call HandlePlayerMovement ; handles player movement
		
		xor dx,dx ; RESET DX
		; call HandleTimer
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
		
		
	jmp MainLoop
	
	EndGame: 
		pop cx
		jmp DeathScreen
	ret
endp Game

;==============================
; Description: 
;	This procedure checks whether or not a given pole is in the pole zone.
;	 if it is, the variable is made true.
;==============================
proc IsInPoleZone
	push bp
	mov bp, sp
	
	POLE_ADDRESS equ [bp+6]
	IS_IN_POLE_ZONE equ [bp+4]
	
	mov bx, POLE_ADDRESS
	mov ax, [bx] ; pole position in ax
	
	cmp ax, PLAYER_COLUMN
	jl InPoleZone
	jmp NotInPoleZone
	
	InPoleZone: 
		mov bx, IS_IN_POLE_ZONE
		mov ax, TRUE
		mov [bx], ax

	NotInPoleZone: 
	
	pop bp	
	ret 4
endp IsInPoleZone

;==============================
; Description: 
;	This procedure uses isInPoleZone to decide whether or not to increment the score by 1.
;==============================
proc HandleScoreIncrementation
	push bp
	mov bp, sp
	
	POLE_ADDRESS equ [bp+6]
	IS_IN_POLE_ZONE equ [bp+4]
	
	mov bx, IS_IN_POLE_ZONE
	mov ax, [bx]
	cmp ax, TRUE
	jne EndScoreIncrementation
	
	FinalCheck: 	
		mov bx, POLE_ADDRESS ; bx = pole address
		mov ax, [bx]
		add ax, POLE_WIDTH ; ax = polePosition + width = end of the pole
		
		mov bx, PLAYER_COLUMN ; where the player is positioned on the x axis
		
		cmp bx, ax ; if where the player is positioned > end of pole -> IncrementScore
		ja IncrementScore
		jmp EndScoreIncrementation
		
		IncrementScore: 	
			inc [CurrentScore]
			mov bx, IS_IN_POLE_ZONE
			mov ax, FALSE ; Move false after player has passed the pole zone.
			mov [bx], ax
		
	EndScoreIncrementation:
	pop bp	
	ret 4
endp HandleScoreIncrementation

proc HandleScore
	
	PUSH_REGISTERS
	
	push offset FirstPoleXPosition
	push offset IsInFirstPoleZone
	call IsInPoleZone
	
	
	push offset SecondPoleXPosition
	push offset IsInSecondPoleZone
	call IsInPoleZone
	
	
	push offset ThirdPoleXPosition
	push offset IsInThirdPoleZone
	call IsInPoleZone
	
	; handle score inc
	
	push offset FirstPoleXPosition
	push offset IsInFirstPoleZone
	call HandleScoreIncrementation
	
	
	push offset SecondPoleXPosition
	push offset IsInSecondPoleZone
	call HandleScoreIncrementation
	
	
	push offset ThirdPoleXPosition
	push offset IsInThirdPoleZone
	call HandleScoreIncrementation
	
	
	POP_REGISTERS
	
	ret
endp HandleScore

proc DrawEndGameRectangle
	
	mov cx, GAME_OVER_COLUMN
	sub cx, GAME_OVER_RECTANGLE_CONSTANT
	
	mov dx, GAME_OVER_ROW
	sub dx, GAME_OVER_RECTANGLE_CONSTANT
	
	mov al, GAME_OVER_RECTANGLE_COLOR
	
	xor di,di
	add di, GAME_OVER_RECTANGLE_CONSTANT
	add di, GAME_OVER_WIDTH
	add di, GAME_OVER_RECTANGLE_CONSTANT
	
	xor si, si 
	add si, GAME_OVER_RECTANGLE_CONSTANT
	add si, GAME_OVER_HEIGHT
	add si, GAME_OVER_RECTANGLE_HEIGHT_CONSTANT
	
	call Rect
	
	ret
endp DrawEndGameRectangle

proc DeathScreen
	
	
	call DeathScreenDelay
	call TextMode
	call PrintScore
	call PrintFinalMessage
	
	ClearBuffer: 
		mov ah, 0h
		int 16h
	mov ah, 1h
	int 16h
	
	jnz ClearBuffer
	
	mov ah, 0h
	int 16h

	call MainScreen
	ret	
endp DeathScreen

proc PrintScore
	
	mov ah, 09h
	mov dx, offset ScoreMessage
	int 21h
	
	xor ah,ah
	mov al, [CurrentScore]
	shr al, 2 ; div by 4
	call ShowAxDecimal
	
	ret
endp PrintScore

proc PrintFinalMessage
	mov ah, 09h
	mov dx, offset FinalMessage
	int 21h
	ret
endp PrintFinalMessage

proc DeathScreenDelay
	mov ah, 86h
	mov cx, 01Eh
	mov dx, 8480h
	int 15h
	ret
endp DeathScreenDelay
;==============================
; Description: 
;	Goes over a square perimeter around the player and checks whether a given pixel color is detected.
;==============================
proc ScanPlayerPerimeterForGivenColor 
	push bp
	mov bp, sp
	
	GIVEN_COLOR equ [bp+4]
	; DX = row
	; CX = column
	
	
	mov dl, [PlayerYPosition]
	
	; start at x position PLAYER_COLUMN + PLAYER_SIZE. every iteration, increment counter by one to scan next player pixel.
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
	
	; Start at x position player column, and y position = player y position.
	; Every iteration increase si by 1 and add to cx,  move into dl player y position. 
	; This gives us the current place on the axis which we want to check for given color. if detected, jump out
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
		
		
		sub cx, si ; if this didnt happen, cx instead of adding one more every iteration, would add si.
		inc si
		pop cx
	loop LoopCollisionTopXAxis
	
	mov cx, PLAYER_SIZE
	dec cx
	mov si, 0
	
	; Start at x position player column, and y position = player y position.
	; Every iteration increase si by 1 and add to cx,  move into dl the player size + position. 
	; This gives us the current place on the axis which we want to check for given color. if detected, jump out
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
		
		
		sub cx, si ; if this didnt happen, cx instead of adding one more every iteration, would add si.
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


;==============================
; Description: 
;	Pushes the pole color and uses ScanPlayerPerimeterForGivenColor.
;==============================
proc HandlePlayerCollision
	push POLE_COLOR
	
	call ScanPlayerPerimeterForGivenColor
	
	ret
endp HandlePlayerCollision


;==============================
; Description: 
;	Initializes ALL player poles, by pushing the start and ending of the pole spaces, and moving the position into cx. this procedure uses InitializePole
;==============================
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

;==============================
; Description: 
;	The procedure starts with getting the pole position, the pole start space and end space from the stack. 
; 	It checks if the pole has gone past its boundary, if it has, change the position to the max. 
;   when changing position, this procedure randomizes pole space start position, and space height
;==============================
proc ChangePolePositionToMax
	push bp
	mov bp, sp
	
	
	POLE_ADDRESS equ [bp+8]
	POLE_START_SPACE equ [bp+6]
	POLE_END_SPACE equ [bp+4]
	
	mov bx, POLE_ADDRESS
	
	mov ax, [bx]
	cmp ax, POLE_BOUNDARY
	jle ChangePoleToMax
	jmp EndPoleChangePosition
	ChangePoleToMax: 
	
		
		mov cx, [bx] ; cx = pole position
		mov bx, POLE_START_SPACE
		push [bx] ; push start of pole space
		mov bx, POLE_END_SPACE
		push [bx] ; push end of pole space
		
		call EndPole ; completely erase the pole
		
		call HandlePoleInconsistency ; handles leftover green pixels.

		
		mov ax, 320 ; screen width
		sub ax, POLE_PIXEL_MOVEMENT
		mov bx, POLE_ADDRESS
		mov [bx], ax
		; pole position = (320 - POLE_PIXEL_MOVEMENT)
		
		mov bl, MINIMUM_SPACE_HEIGHT
		mov bh, MAXIMUM_SPACE_HEIGHT
		
		call RandomByCs ; randomize pole space height
		; AL = random number between al and ah
		
		push ax ; save random space
		
		xor ah,ah ; AH = 0
		
		mov bl, 0 ; minimum start position
		mov cx, 200 ; graphic height
		
		sub cx, ax ; subtract the graphic height by the space height so if for example the height = 40, the maximum start position needs to be 200 - 40, so there wont be too many pixels drawn.
		mov bh, cl ; move the upper limit of the start position into bh
		
		
		
		call RandomByCs ; randomize the starting position between (0 and GRAPHIC_HEIGHT - SPACE_HEIGHT )
		
		pop cx ; random space height into cx
		
		push ax ; random space start position
		push POLE_START_SPACE ; the address of the pole start space
		push POLE_END_SPACE ; the address of the pole end space
		push cx ; the random space height
		call ModifyPoleParameters
		
		
	
	EndPoleChangePosition: 	
	pop bp
	ret 6
endp ChangePolePositionToMax

proc ModifyPoleParameters
	push bp
	mov bp, sp
	
	RANDOM_SPACE_POSITION equ [bp+10]
	START_SPACE equ [bp+8]
	END_SPACE equ [bp+6]
	RANDOM_HEIGHT equ [bp+4]
	
	
	mov ax, RANDOM_SPACE_POSITION
	mov bx, START_SPACE
	mov [bx], ax ; START_SPACE = RANDOM_SPACE_POSITION
	
	mov ax, RANDOM_SPACE_POSITION
	add ax, RANDOM_HEIGHT ; AX = RANDOM_SPACE_POSITION + RANDOM_HEIGHT = The end of the sspace
	
	mov bx, END_SPACE
	mov [bx], ax
	
	
	
	
	
	pop bp
	ret 8
endp ModifyPoleParameters


;==============================
; Description: 
;	Handles if position < POLE_BOUNDARY. uses ChangePolePositionToMax
;==============================
proc HandleIllegalPolePositions

	
	push offset FirstPoleXPosition
	push offset FirstPoleStartSpaceRow
	push offset FirstPoleEndSpaceRow
	call ChangePolePositionToMax
	
	push offset SecondPoleXPosition
	push offset SecondPoleStartSpaceRow
	push offset SecondPoleEndSpaceRow
	call ChangePolePositionToMax
	
	push offset ThirdPoleXPosition
	push offset ThirdPoleStartSpaceRow
	push offset ThirdPoleEndSpaceRow
	call ChangePolePositionToMax
	
	
	
	
	ret	
endp HandleIllegalPolePositions


;==============================
; Description: 
;	Handles everything related to poles. 
; 	
;==============================
proc HandlePoles
	xor cx,cx
	
	
	
	call ErasePoles 


	sub [FirstPoleXPosition], POLE_PIXEL_MOVEMENT
	sub [SecondPoleXPosition], POLE_PIXEL_MOVEMENT ; pole positions = polePositions - POLE_PIXEL_MOVEMENT
	sub [ThirdPoleXPosition], POLE_PIXEL_MOVEMENT
	
	; Draw Each pole
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

;==============================
; Description: 
;	Handles if position < 0 or position > 200. answer in dx
;==============================
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

;==============================
; Description: 
;	Handles if space pressed. 
;==============================
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
	push offset BirdName
	call DrawPlayer
	
	ret
endp MovePlayerDown

proc MovePlayerUp
	
	call ErasePlayer
	sub [PlayerYPosition], PLAYER_MANUAL_PIXEL_MOVEMENT
	push offset BirdName
	call DrawPlayer
	ret
endp MovePlayerUp

proc DrawPlayer
	push bp
	mov bp, sp
	
	BMP_ADDRESS equ [bp+4]
	
	mov [BmpLeft],PLAYER_COLUMN
	
	push ax
	
	mov al, [PlayerYPosition]
	mov [BmpTop], ax
	
	pop ax
	
	mov [BmpColSize],PLAYER_SIZE
	mov [BmpRowSize],PLAYER_SIZE
	
	mov dx, BMP_ADDRESS
	call OpenShowBmp
	
	pop bp
	ret 2
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
	mov [BmpTop],STARTING_PLAYER_Y_POSITION
	mov [BmpColSize],PLAYER_SIZE
	mov [BmpRowSize],PLAYER_SIZE
	
	mov dx, offset BirdName
	call OpenShowBmp
	
	ret
endp InitializePlayer

;==============================
; Description: 
;	checks if mouse pos is in the boundary of given coordinates. true if carry flag
;==============================
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

;==============================
; Description: 
;	erases the last (POLE_POSITION+POLE_WIDTH-POLE_PIXEL_MOVEMENT) with the background color, uses start and end space so instead of all pixels being removed, 
;	the space pixels wont be removed. The reason for this is removing the pixels in the space runs the risk of erasing the player. 
; 	pole position in cx
;==============================
proc ErasePole
	push bp
	mov bp, sp
	
	END_OF_SPACE equ [bp+4]
	START_OF_SPACE equ [bp+6]

	PUSH_REGISTERS
	
	
	; This example assumes that POLE_PIXEL_MOVEMENT = 3 and POLE_WIDTH = 20
	mov ax, POLE_WIDTH
	sub ax, POLE_PIXEL_MOVEMENT ; ax = 20 - 3 = 17
	
	add cx, ax ; cx which previously had poleposition now has poleposition + AX -> (STARTING RECTANGLE COLUMN = CX)
	mov di, POLE_PIXEL_MOVEMENT ; the width of the rectangle will be POLE_PIXEL_MOVEMENT

	
	
	mov dx, 0 ; STARTING REC ROW = 0
	mov al, BACKGROUND_COLOR ; al = BACKGROUND_COLOR -> the color of the rec will be the background color.
	mov si, START_OF_SPACE ; the height will be start of space position.
	call Rect
	

	mov ax, 200 ; graphic height
	sub ax, END_OF_SPACE
	
	mov si, ax ; next rec height = 200 - END_SPACE
	
	
	mov di, POLE_PIXEL_MOVEMENT
	
	mov dx, END_OF_SPACE ; starting row
	mov al, BACKGROUND_COLOR ; color
	call Rect
	
	POP_REGISTERS

	pop bp
	ret 4
endp ErasePole


;==============================
; Description: 
;	draws the first (POLE_POSITION-POLE_PIXEL_MOVEMENT) with the pole color, uses start and end space so instead of all pixels being drawn, 
;	the space pixels wont be drawn. The reason for this is drawing the pixels in the space runs the risk of drawing on the player.
; 	pole position in cx
;==============================
proc DrawPole
	push bp
	mov bp, sp
	
	END_OF_SPACE equ [bp+4]
	START_OF_SPACE equ [bp+6]

	
	PUSH_REGISTERS
	
	
	sub cx, POLE_PIXEL_MOVEMENT ; starting rec column = position - POLE_PIXEL_MOVEMENT
	mov di, POLE_PIXEL_MOVEMENT ; width = POLE_PIXEL_MOVEMENT
	
	
	
	
	mov dx, 0 ; starting row
	mov al, POLE_COLOR ; color
	mov si, START_OF_SPACE ; height
	call Rect
	

	mov ax, 200 ; graphic height
	sub ax, END_OF_SPACE
	
	mov si, ax ; height = graphic height - space end position
	

	
	
	mov dx, END_OF_SPACE ; starting row is the END_SPACE_POSITION
	mov al, POLE_COLOR ; color
	call Rect
	
	POP_REGISTERS

	pop bp
	ret 4
endp DrawPole

;==============================
; Description: 
;	Uses the same logic as draw pole, but it draws POLE_WIDTH pixels. 
;  	pole position in cx
;==============================
proc InitializePole
	push bp
	mov bp, sp
	
	
	START_OF_SPACE equ [bp+6]	
	END_OF_SPACE equ [bp+4]


	
	PUSH_REGISTERS
	
	
	
	
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
	
	POP_REGISTERS

	pop bp
	ret 4
	

endp InitializePole

;==============================
; Description: 
;	Erases leftover pole pixels after final erasure. used in ChangePolePositionToMax
;==============================
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


;==============================
; Description: 
;	Uses the same logic as erase pole, but it erases POLE_WIDTH pixels. 
;  	pole position in cx
;==============================
proc EndPole
	push bp
	mov bp, sp
		
	END_OF_SPACE equ [bp+4]
	START_OF_SPACE equ [bp+6]

	PUSH_REGISTERS
		
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
	
	POP_REGISTERS

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
		
   
	   pop dx
	   pop cx
	   pop bx
	   pop ax
	   
	   ret
endp ShowAxDecimal

proc TextMode
	
	mov ax, 02
	int 10h
	ret
endp TextMode

EndOfCsLbl:
End start
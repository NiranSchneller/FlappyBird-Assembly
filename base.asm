IDEAL
MODEL small


STACK 100h

MAIN equ 'Main.bmp'
HELP equ 'Help.bmp'
BMP_WIDTH = 320


DATASEG
	
	MainName  db MAIN , 0
	HelpName db HELP, 0
	FileHandle	dw ?
	Header 	    db 54 dup(0)
	Palette 	db 400h dup (0)
	
	BmpLeft dw ?
	BmpTop dw ?
	BmpColSize dw ?
	BmpRowSize dw ?
	
	ErrorFile db 0

	BmpFileErrorMsg    	db 'Error At Opening Bmp File ',MAIN, 0dh, 0ah,'$'

	
	ScrLine db BMP_WIDTH dup (0)  ; One Color line read buffer

	
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
		mov dx, offset MainName
		call OpenShowBmp
		call MainScreen
	
exit:	
	mov ax,4C00h
    int 21h
	
	
proc MainScreen
	
		
	ClickWaitWithDelay:
		mov cx,1000
	@@Wait:	
		loop @@Wait
	WaitTillPressOnPoint:

	
	mov ax,5h
	mov bx,0 
	int 33h
	
	cmp bx,00h
	jna ClickWaitWithDelay  ; mouse wasn't pressed
	
	shr cx, 1 ; 640 / 2 = 320
	
	jmp Clicked
	GoToHelp: 
		mov dx, offset HelpName
		call OpenShowBmp
		jmp HelpScreen
	
	; if (horizontal position > 135 && < 184 && vertical position > 162 && < 177) -> go to help
	Clicked: 
		cmp cx, 135 
		jb WaitTillPressOnPoint ; if horizontal position is bigger than 135 -> check other horizontal position
		
		CheckHelpX: 
			cmp cx, 184
			ja WaitTillPressOnPoint ; if horizontal position is smaller than 184 -> check vertical position
		CheckUpperHelpY: 
			cmp dx, 162
			jb WaitTillPressOnPoint ; if vertical position is bigger than 162 -> check other vertical position
		CheckLowerHelpY: 
			cmp dx, 177
			ja WaitTillPressOnPoint ; if vertical position is smaller than 177 -> go to help
		
		jmp Clicked
	ret
endp MainScreen

proc HelpScreen


	ret
endp HelpScreen


proc ClearScreen
	push ax
	push cx
	push di
	
	mov ax, 0B800h
	mov es, ax
	xor cx, cx
	mov cx, 2000
	mov di, 0
	Clear: 
		mov ah, 00000000b
		mov al, ''
		mov [es:di], ax
		INC di
		INC di
	loop Clear
	
	pop di
	pop cx
	pop ax
	
	ret
endp ClearScreen


 
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


proc OpenShowBmp near
	
	 
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
proc ReadBmpHeader	near					
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




proc ReadBmpPalette near ; Read BMP file color palette, 256 colors * 4 bytes (400h)
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
proc CopyBmpPalette		near					
										
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
proc OpenBmpFile	near						 
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


proc CloseBmpFile near
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
.286
.model small
.stack 1024
.data
Filename db "tst.txt",0
stringarray dw 30000 dup(00h)
handle dw ?
buff db ?
typemode db 0
OpenErrorMsg db 10,13,'unable to open file$'
ReadFileErrorMsg db 10,13,'unable to read file$'
WriteFileErrorMsg db 10,13,'unable to write file$'
CloseFileErrorMsg db 10,13,'unable to close file$' 
Saved db 10,13 ,"Save Completed!$"
.code
org 100h

.startup
mov al,03h
mov ah,0
int 10h

mov dh, 0			;set row (0-24)
mov dl, 0			;set column (0-79)
mov bh, 0
mov ah, 2			;set cursor position top left corner
int 10h 

call OpenFile
call ReadFile
    position:   
        mov ah,2
        mov dh,0
        mov dl,0
        mov bh,0
        int 10h ; positions the cursor on the top left corner
      
   get:
      mov ah,0
      int 16h ; ah = scan code , al = ascii code
      
   check:
      cmp al,1bh ;checks to see if you press ESC button
      je endl1 ; if yes jump to end
      
	  cmp al,9
	  je tab1
	  
      cmp al,8 ;checks if you pressed BACKSPACE
      je backspace1 
	  
	  cmp al,127
	  je del1
      
	  cmp al,0dh  ; checks if you pressed enter
	  jne move_next
	  jmp next_line
	  
	  move_next:
	  cmp ah,83
	  je del1
	  
      cmp al,0 ; checks if you buttoned null(nothing)
	  jne check_next ;  no  a key was pressed
      
      call dir
      jmp next 
 
  check_next:
			   cmp typemode, 0
			   je overtype_character
			   call shiftahead
	           overtype_character:
			   mov ah,2
	           mov dl,al
	           int 21h    ; display the character you just entered
	               
      
   next:
      mov ah,0
      int 16h
      jmp check
      
   dir:				;scanning keys
      push bx
      push cx
      push dx
      push ax
      
      mov ah,3
      mov bh,0
      int 10h
      pop ax ; get location
	  
	  cmp ah,63		;F5 to save file
	  je loop_video_memory1
	  
      cmp ah,75 ; LEFT ARROW
      je go_left
      
      cmp ah,77 ; RIGHT ARROW
      je go_right
      
      cmp ah, 61	; F3 to switch mode
	  je switch_mode
	  jmp EXIT
	  
	  switch_mode:
	  cmp typemode, 0
	  je switch_typemode_to_Insert
	  mov typemode, 0
	  jmp EXIT
	  switch_typemode_to_Insert:
	  mov typemode, 1
		
	  jmp EXIT
    
  new_line1:
	jmp new_line
	
  backspace1:
	jmp backspace
	
  tab1:
	jmp tab
  
  del1:
	jmp del
	
  endl1:
	jmp end1
	
  loop_video_memory1:
	jmp loop_video_memory 

  line1:
	jmp line

	
  tab:
	mov si,4
	push si
	shft:
	  call shiftahead
	  mov ah,2
	  mov dl,20h
	  int 21h
	  pop si
	  dec si
	  jnz shift1
	  jz get2
  shift1:
	push si
	jmp shft
	get2:
	jmp get
  del:
      mov ah,2
      mov dl,20h
      int 21h
	  call shiftback
      mov dl,8
      int 21H
      jmp get

  go_left:
      cmp dl,0
      je line1
      dec dl
      jmp EXECUTE
      
  go_right:
      cmp dl,79
      je new_line1
      inc dl
      jmp EXECUTE 
	  
  next_line:
	call getcursor
	xor dh, dh
	cbw
	mov si,80
	sub si,dx
	push si
	shft1:
	  call shiftahead
	  mov ah,2
	  mov dl,20h
	  int 21h
	  pop si
	  dec si
	  jnz shift2
	  jz get3
  shift2:
	push si
	jmp shft1
	get3:
		call getcursor
		cmp dh,24
		je stay
		mov dl,0
		mov ah,2
		int 10h
		jmp get
	
  stay:
		call getcursor
		mov dh,dh
		mov dl,dl
		mov ah,2
		int 10h
		jmp get
      
  backspace:
	  call getcursor
	  cmp dl,79
	  je specialcase
      mov ah,2
      mov dl,20h
      int 21h
	  xor dl,dl
	  call getcursor
	  call shiftback
	  cmp dl,0
	  je bline
	  dec dl
	  cmp dl,0
	  je bline
	  dec dl
	  mov ah,2
      int 10h
      jmp get 
	  
  specialcase:
	  mov ah,2
      mov dl,20h
      int 21h
	  mov ah,2
      mov bh,0
      mov dh,dh
      mov dl,78
      int 10h
	  jmp get 
  
  bline:
      cmp dh,0
      je bno_jump
      dec dh
      mov ah,2
      mov bh,0
      mov dh,dh
      mov dl,79
      int 10h
      jmp get
      
  bno_jump:
      mov ah,2
      mov bh,0
      mov dx,0
      int 10h
      jmp get	  
	
  line:
      cmp dh,0
      je no_jump
      dec dh
      mov ah,2
      mov bh,0
      mov dh,dh
      mov dl,79
      int 10h
      jmp EXIT
      
  no_jump:
      mov ah,2
      mov bh,0
      mov dx,0
      int 10h
      jmp EXIT
      
  new_line:
      cmp dh,24
      je no_new_jump
      inc dh
      mov ah,2
      mov bh,0
      mov dh,dh
      mov dl,1
      int 10h
      jmp EXIT
      
  no_new_jump:
      mov ah,2
      mov bh,0
      mov dh,24
      mov dl,79
      int 10h
      jmp EXIT
      
  EXECUTE:
      mov ah,2
      int 10h
  
  EXIT:
      pop dx
      pop cx
      pop bx
     
	 jmp get
      
  end1:
       call closefile
       mov ah,4ch
       int 21h
   
    
  loop_video_memory:
       mov ax, 0b800h
       mov es, ax
       mov si, 0
       mov di, 0
       mov cx, 1920
  loop_array:
      mov ax, es:[si];mov ax, es:si the orginal code didn't work on DOS
      mov [StringArray + di], ax
      add si,2
      add di,1
      loop loop_array

  
  write:

       ;delete file to delete what was inside
       mov ah,41h
       lea dx,filename
       int 21h

       ;create new file
       mov ah,3ch
       mov cx,2
       lea dx,Filename
       int 21h
       ;jc CreateError
       mov handle,ax
       
       
       mov ah,40h  ;write to file
       mov bx,handle
       mov cx,1920
       mov al,2
       lea dx,StringArray
       int 21h 
       ;jc WriteError 
  save:
       lea dx,saved
       mov ah,9
       int 21h
       ;call closefile     
       jmp end1
	   
	   
   OpenFile proc near
      mov ax,3d02h ;open file with handle
      mov dx, offset Filename
      int 21h
      jc OpenError
      mov handle,ax
      ret
  OpenError:
      Lea dx,OpenErrorMsg ; set up pointer to open error message
      mov ah,9
      int 21h ; set error flag
      STC
      ret
  OpenFile ENDP
   
   ReadFile proc Near
       mov ah,3fh ; read from file function
       mov bx,handle
       lea dx,buff
       mov cx,1
       int 21h
       jc ReadError
       cmp ax,0
       jz EOff
       mov dl,buff
       cmp dl,1ah
       jz EOff
       mov ah,2
       int 21h
       jmp ReadFile
   
   ReadError:
       lea dx,ReadFileErrorMsg
       mov ah,9
       int 21h
       STC
   EOff:
       ret
   ReadFile Endp
   CloseFile proc near
       mov ah,3eh
       mov bx,handle
       int 21h
       jc CloseError
       ret
   CloseError:
       lea dx,CloseFileErrorMsg
		mov ah,9
		int 21h
		STC
		ret
	CloseFile endp

getcursor proc		;get cursor position
mov ah, 03h
mov bh,00h
int 10h
ret
getcursor endp

shiftahead proc
	pusha
	call getcursor
	mov cx, dx
	mov bl, 80
	mov al, ch
	mul bl
	mov bh, 0
	mov bl, dl
	add bx, ax
	mov ax, 0b800h
    mov es, ax
    mov si, 3998
    mov di, si
	sub di, 2
    mov cx, 1999
  loop_array_:
      mov ax, es:[di]	;mov ax, es:si the orginal code didn't work on DOS
      mov es:[si], ax
      sub si,2
      sub di,2
      cmp cx, bx
	  jbe end_loop_array_
	  sub cx, 1
	  jmp loop_array_
   end_loop_array_:
	popa
ret
shiftahead endp

shiftback proc
	pusha
	call getcursor
	mov cx, dx
	mov bl, 80
	mov al, ch
	mul bl
	mov bh, 0
	mov bl, dl
	add bx, ax
	mov ax, 0b800h
    mov es, ax
    mov si, bx
	shl si, 1
    mov di, si
	sub di, 2
    mov cx, 1999
  loop1:
      mov ax, es:[si]	;mov ax, es:si the orginal code didn't work on DOS
      mov es:[di], ax
      add si,2
      add di,2
      cmp bx, cx
	  jae end_loop1
	  add bx, 1
	  jmp loop1
   end_loop1:
	popa
ret
shiftback endp

end		
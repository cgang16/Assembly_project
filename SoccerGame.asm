    ; __UNICODE__ equ 1           ; uncomment to enable UNICODE build

    .686p                       ; create 32 bit code
    .mmx                        ; enable MMX instructions
    .xmm                        ; enable SSE instructions
    .model flat, stdcall        ; 32 bit memory model
    option casemap :none        ; case sensitive

    bColor   equ  <00999999h>   ; client area brush colour
    include SoccerGame.inc      ; local includes for this file

.code
start:
    ; ���ģ����
	invoke GetModuleHandle, NULL
	mov hInstance, eax

	; ���ܲ���Ҫ�����в���
	invoke GetCommandLine
	mov  CommandLine, eax
	; �õ�ͼ��͹��
    mov hIcon,       rv(LoadIcon,hInstance,500)
    mov hCursor,     rv(LoadCursor,NULL,IDC_ARROW)
	; �õ�������Ļ�ĳߴ�
    mov sWid,        rv(GetSystemMetrics,SM_CXSCREEN)
    mov sHgt,        rv(GetSystemMetrics,SM_CYSCREEN)
	; ����������
    call Main
    invoke ExitProcess, eax

Main proc
    LOCAL Wwd:DWORD,Wht:DWORD,Wtx:DWORD,Wty:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL icce:INITCOMMONCONTROLSEX

  ; --------------------------------------
  ; comment out the styles you don't need.
  ; --------------------------------------
    mov icce.dwSize, SIZEOF INITCOMMONCONTROLSEX            ; set the structure size
    xor eax, eax                                            ; set EAX to zero
    or eax, ICC_WIN95_CLASSES
    or eax, ICC_BAR_CLASSES                                 ; comment out the rest
    mov icce.dwICC, eax
    invoke InitCommonControlsEx,ADDR icce                   ; initialise the common control library
  ; --------------------------------------

    STRING szClassName,   "SoccerGameClass"
    STRING szDisplayName, "Happy Soccer"

  ; ---------------------------------------------------
  ; set window class attributes in WNDCLASSEX structure
  ; ---------------------------------------------------
    mov wc.cbSize,         sizeof WNDCLASSEX
    mov wc.style,          CS_BYTEALIGNCLIENT or CS_BYTEALIGNWINDOW
    m2m wc.lpfnWndProc,    OFFSET WndProc
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     NULL
    m2m wc.hInstance,      hInstance
    m2m wc.hbrBackground,  NULL                 ;COLOR_BTNFACE+1 ����Ҫbackground
    mov wc.lpszMenuName,   NULL
    mov wc.lpszClassName,  OFFSET szClassName
    m2m wc.hIcon,          hIcon
    m2m wc.hCursor,        hCursor
    m2m wc.hIconSm,        hIcon

  ; ------------------------------------
  ; register class with these attributes
  ; ------------------------------------
    invoke RegisterClassEx, ADDR wc

  ; ---------------------------------------------
  ; set width and height abosulte length
  ; ---------------------------------------------
    mov Wwd, my_window_width
    mov Wht, my_window_height

  ; ------------------------------------------------
  ; Top X and Y co-ordinates for the centered window
  ; ------------------------------------------------
    mov eax, sWid
    sub eax, Wwd                ; sub window width from screen width
    shr eax, 1                  ; divide it by 2
    mov Wtx, eax                ; copy it to variable

    mov eax, sHgt
    sub eax, Wht                ; sub window height from screen height
    shr eax, 1                  ; divide it by 2
    mov Wty, eax                ; copy it to variable

  ; -----------------------------------------------------------------
  ; create the main window with the size and attributes defined above
  ; -----------------------------------------------------------------
    invoke CreateWindowEx,WS_EX_LEFT or WS_EX_ACCEPTFILES,
                          ADDR szClassName,
                          ADDR szDisplayName,
                          WS_OVERLAPPED or WS_SYSMENU,
                          Wtx,Wty,Wwd,Wht,
                          NULL,NULL,
                          hInstance,NULL
    mov hWnd,eax
    invoke ShowWindow,hWnd, SW_SHOWNORMAL
    invoke UpdateWindow,hWnd

	; ��Ϣѭ��
    call MsgLoop
    ret
Main endp

loadGameImages proc
	; ���ؿ�ʼ�����λͼ
	invoke LoadBitmap, hInstance, 500
	mov h_startpage, eax

	; ������Ϸ�����λͼ
	invoke LoadBitmap, hInstance, 501
	mov h_gamepage, eax

	; ����ʤ�������λͼ
	invoke LoadBitmap, hInstance, 508
	mov h_winpage1, eax

	invoke LoadBitmap, hInstance, 509
	mov h_winpage2,eax

	; ���ذ��������λͼ
	invoke LoadBitmap, hInstance, 510
	mov h_guidepage, eax

	;������ҵ�λͼ
	invoke LoadBitmap, hInstance, 506
	mov player1_bitmap, eax

	invoke LoadBitmap, hInstance, 507
	mov player2_bitmap, eax

	;�������λͼ
	invoke LoadBitmap, hInstance, 504
	mov ball_bitmap, eax

	;���ص÷�λͼ 0~3
	invoke LoadBitmap, hInstance, 505
	mov score_bitmap, eax
	ret
loadGameImages endp



calDirection proc uses eax ebx ecx, addrPlayer:DWORD
LOCAL x_dif:SDWORD
LOCAL y_dif:SDWORD
LOCAL distance2:SDWORD
LOCAL distance:real4

    assume ebx:ptr player
	mov ebx, addrPlayer

	; ���x����֮��
	mov eax, soccer.bsize.x
	shr eax, 1
	add eax, soccer.pos.x
	mov ecx, [ebx].psize.x
	shr ecx, 1
	add ecx, [ebx].pos.x
	sub eax, ecx
	mov x_dif, eax

	; ���y����֮��
	mov eax, soccer.bsize.y
	shr eax, 1
	add eax, soccer.pos.y
	mov ecx, [ebx].psize.y
	shr ecx, 1
	add ecx, [ebx].pos.y
	sub eax, ecx
	mov y_dif, eax

	; y_dif^2
	imul eax, y_dif
	; x_dif^2
	mov ecx, x_dif
	imul ecx, x_dif
	; d^2
	add eax, ecx
	mov distance2, eax

	fild distance2
	fsqrt 
	fstp distance
	fild x_dif
	fdiv distance
	fstp soccer.bcoef.x
	fild y_dif
	fdiv distance
	fstp soccer.bcoef.y

	ret
calDirection endp


; ����ͼƬ���ƺ���
paintBackground proc  member_hdc1:HDC, member_hdc2:HDC
	.IF game_status == 0
		invoke SelectObject, member_hdc2,  h_startpage
		invoke BitBlt, member_hdc1, 0, 0, my_window_width, my_window_height, member_hdc2, 0, 0, SRCCOPY

	.ELSEIF game_status == 1
		invoke SelectObject, member_hdc2, h_guidepage
		invoke BitBlt, member_hdc1, 0, 0, my_window_width, my_window_height, member_hdc2, 0, 0, SRCCOPY

	.ELSEIF game_status == 2
		invoke SelectObject, member_hdc2, h_gamepage
		invoke BitBlt, member_hdc1, 0, 0, my_window_width, my_window_height, member_hdc2,  0, 0, SRCCOPY

	.ELSEIF game_status == 3
		invoke SelectObject, member_hdc2, h_winpage1
		invoke BitBlt, member_hdc1, 0, 0, my_window_width, my_window_height, member_hdc2,  0, 0, SRCCOPY

	.ELSEIF game_status == 4
		invoke SelectObject, member_hdc2, h_winpage2
		invoke BitBlt, member_hdc1, 0, 0, my_window_width, my_window_height, member_hdc2, 0, 0, SRCCOPY

	.ENDIF
	ret
paintBackground endp


; ������Ա
paintPlayers proc member_hdc1: HDC, member_hdc2:HDC
	
	; player 1-----------------------------------------------
	; Ҳ����Ҫ���ݷ���ѡ����ʵ�bitmap,���߿��Ƕ�һ��ͼ���ʵ����ת
	invoke SelectObject, member_hdc2, player1_bitmap

	; ������˶����ı�֡
	.IF player1.is_static == 0
		inc player1.frame_counter
		.IF player1.frame_counter > 20
			mov player1.frame_counter, 0
			.IF player1.cur_frame == 1
				mov player1.cur_frame, 2
			.ELSEIF player1.cur_frame == 2
				mov player1.cur_frame, 1
			.ENDIF
		.ENDIF
	.ENDIF

	; ��͸�����ص�λͼ��
	; ���жϷ������ж�״̬
	; �Ϸ���
	.IF player1.bmp_dir == dir_top
		.IF player1.is_static == 1
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 0, 0, 77, 42, 16777215
		.ELSEIF player1.cur_frame == 1
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 77, 0, 77, 70, 16777215
		.ELSEIF player1.cur_frame == 2
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 154, 0, 77, 70, 16777215
		.ENDIF
	; �·���
	.ELSEIF player1.bmp_dir == dir_down
		.IF player1.is_static == 1
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 0, 70, 77, 42, 16777215
		.ELSEIF player1.cur_frame == 1
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 77, 70, 77, 70, 16777215
		.ELSEIF player1.cur_frame == 2
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 154, 70, 77, 70, 16777215
		.ENDIF
	; ����
	.ELSEIF player1.bmp_dir == dir_left
		.IF player1.is_static == 1
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 0, 140, 42, 77, 16777215
		.ELSEIF player1.cur_frame == 1
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 42, 140, 70, 77, 16777215
		.ELSEIF player1.cur_frame == 2
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 112, 140, 70, 77, 16777215
		.ENDIF
	; �ҷ���
	.ELSEIF player1.bmp_dir == dir_right
		.IF player1.is_static == 1
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 0, 217, 42, 77, 16777215
		.ELSEIF player1.cur_frame == 1
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 42, 217, 70, 77, 16777215
		.ELSEIF player1.cur_frame == 2
			invoke TransparentBlt, member_hdc1, player1.pos.x, player1.pos.y,\
					player1.psize.x, player1.psize.y, member_hdc2, 112, 217, 70, 77, 16777215
		.ENDIF
	.ENDIF

	; player 2-----------------------------------------------
	; ��Ҫ���ݷ���ѡ����ʵ�bitmap
	invoke SelectObject, member_hdc2, player2_bitmap

	; �ı�֡
	.IF player2.is_static == 0
		inc player2.frame_counter
		.IF player2.frame_counter > 20
			mov player2.frame_counter, 0
			.IF player2.cur_frame == 1
				mov player2.cur_frame, 2
			.ELSEIF player2.cur_frame == 2
				mov player2.cur_frame, 1
			.ENDIF
		.ENDIF
	.ENDIF

	; �Ϸ���
	.IF player2.bmp_dir == dir_top
		.IF player2.is_static == 1
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 0, 0, 77, 42, 16777215
		.ELSEIF player2.cur_frame == 1
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 77, 0, 77, 70, 16777215
		.ELSEIF player2.cur_frame == 2
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 154, 0, 77, 70, 16777215
		.ENDIF
	; �·���
	.ELSEIF player2.bmp_dir == dir_down
		.IF player2.is_static == 1
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 0, 70, 77, 42, 16777215
		.ELSEIF player2.cur_frame == 1
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 77, 70, 77, 70, 16777215
		.ELSEIF player2.cur_frame == 2
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 154, 70, 77, 70, 16777215
		.ENDIF
	; ����
	.ELSEIF player2.bmp_dir == dir_left
		.IF player2.is_static == 1
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 0, 140, 42, 77, 16777215
		.ELSEIF player2.cur_frame == 1
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 42, 140, 70, 77, 16777215
		.ELSEIF player2.cur_frame == 2
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 112, 140, 70, 77, 16777215
		.ENDIF
	; �ҷ���
	.ELSEIF player2.bmp_dir == dir_right
		.IF player2.is_static == 1
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 0, 217, 42, 77, 16777215
		.ELSEIF player2.cur_frame == 1
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 42, 217, 70, 77, 16777215
		.ELSEIF player2.cur_frame == 2
			invoke TransparentBlt, member_hdc1, player2.pos.x, player2.pos.y,\
					player2.psize.x, player2.psize.y, member_hdc2, 112, 217, 70, 77, 16777215
		.ENDIF
	.ENDIF

	ret
paintPlayers endp

; ��������
paintBall proc uses eax ebx, member_hdc1: HDC, member_hdc2:HDC
	invoke SelectObject, member_hdc2, ball_bitmap

	; ��������˶����ı�֡��
	.IF soccer.is_static == 0
		inc soccer.frame_counter
		.IF soccer.frame_counter > 7
			mov soccer.frame_counter, 0
			inc soccer.cur_frame 
			.IF soccer.cur_frame > 4
				mov soccer.cur_frame, 0
			.ENDIF
		.ENDIF
	.ENDIF
	; ����֡����ͼ
	; ax�洢soccer.bmp�Ļ�ͼ��ʼxλ��
	mov eax, 0
	mov al, soccer.cur_frame
	mov ebx, 0
	mov bl, 50
	mul bl
	invoke TransparentBlt, member_hdc1, soccer.pos.x, soccer.pos.y,\
		   soccer.bsize.x, soccer.bsize.y, member_hdc2, eax, 0, 50, 50, 16777215

	ret
paintBall endp

; �������º���
updateScene proc uses eax
	LOCAL member_hdc:HDC
	LOCAL member_hdc2:HDC
	LOCAL h_bitmap:HDC
	LOCAL hdc: HDC

	invoke BeginPaint, hWnd, ADDR paintstruct
	mov hdc, eax
	invoke CreateCompatibleDC, hdc
	mov member_hdc, eax
	invoke CreateCompatibleDC, hdc
	mov member_hdc2, eax
	invoke CreateCompatibleBitmap, hdc, my_window_width, my_window_height
	mov h_bitmap, eax

	;��λͼѡ�񵽼���DC��
	invoke SelectObject, member_hdc, h_bitmap

	;���Ʊ���
	invoke paintBackground, member_hdc, member_hdc2
	
	; �����������
	.IF game_status == 2
		invoke paintPlayers, member_hdc, member_hdc2
		invoke paintBall, member_hdc, member_hdc2
		invoke paintScore, member_hdc, member_hdc2
	.ENDIF

	; BitBlt��hDestDC, x, y, nWidth, nheight, hSrcDC, xSrc, ySrc, dwRop��
	; ��Դ��������ֱ�ӿ�����Ŀ������SRCCOPY
	invoke BitBlt, hdc, 0, 0, my_window_width, my_window_height, member_hdc, 0, 0, SRCCOPY
	
	invoke DeleteDC, member_hdc
	invoke DeleteDC, member_hdc2
	invoke DeleteObject, h_bitmap
	invoke EndPaint, hWnd, ADDR paintstruct
	ret
updateScene endp

; �ı�����λ�ã�������������ǽ���Լ����ſ������ײ�����
movePlayer proc uses eax ebx ecx, addrPlayer: DWORD
	assume ecx: ptr player
	mov ecx, addrPlayer

	.IF [ecx].speed.x == 0
		jmp y_move_label
	.ENDIF

	; x������ƶ���ͬʱ��������ǽ�ڵ�Ӱ��
	mov eax, [ecx].speed.x
	add [ecx].pos.x, eax
	.IF [ecx].pos.x < wall_left_x
		mov [ecx].pos.x, wall_left_x
	.ENDIF

	mov eax, wall_right_x
	sub eax, [ecx].psize.x
	.IF [ecx].pos.x > eax
		mov [ecx].pos.x, eax
	.ENDIF

y_move_label:
	.IF [ecx].speed.y == 0
		jmp check_door_label
	.ENDIF
	; y������ƶ���ͬʱ��������ǽ�ڵ�Ӱ��
	mov eax, [ecx].speed.y
	add [ecx].pos.y, eax
	.IF [ecx].pos.y < wall_top_y
		mov [ecx].pos.y, wall_top_y
	.ENDIF

	mov eax, wall_down_y
	sub eax, [ecx].psize.y
	.IF [ecx].pos.y > eax
		mov [ecx].pos.y, eax
	.ENDIF

check_door_label:
	; �����ſ������Ӱ��
	;  ebx����볤y����
	mov ebx, [ecx].psize.y
	shr ebx, 1

	mov eax, door_right_x
	sub eax, [ecx].psize.x

	.IF [ecx].pos.x < door_left_x || [ecx].pos.x > eax
		mov eax, [ecx].pos.y
		add eax, [ecx].psize.y
		; �����ſ���ײ
		.IF [ecx].pos.y < door_top_y && eax > door_top_y
			sub eax, door_top_y
			.IF eax > ebx
				mov [ecx].pos.y, door_top_y
			.ELSE
				mov eax, door_top_y
				sub eax, [ecx].psize.y
				mov [ecx].pos.y, eax
			.ENDIF
		.ELSEIF [ecx].pos.y < door_down_y && eax > door_down_y
			sub eax,  door_down_y
			.IF eax > ebx
				mov [ecx].pos.y, door_down_y
			.ELSE
				mov eax, door_down_y
				sub eax, [ecx].psize.y
				mov [ecx].pos.y, eax
			.ENDIF
		.ENDIF		
	.ENDIF

	ret
movePlayer endp


;�ı����λ�ã�ͬʱ˥���ٶȣ��жϺ�ǽ���Լ��ſ����ײ���жϺ���Ա����ײ
moveBall proc uses eax ebx
	; �ٶ�Ϊ0�򲻽��д���
	.IF soccer.speed == 0
		mov soccer.counter, 0
		ret
	.ENDIF

	; ����x��������
	fld soccer.bcoef.x
	fimul soccer.speed
	fistp soccer.delta.x

	.IF soccer.delta.x == 0
		jmp y_move_label
	.ENDIF
	mov eax, soccer.delta.x
	add soccer.pos.x, eax
	; �ж��Ƿ�������ǽ����ײ
	.IF soccer.pos.x < wall_left_x
		mov soccer.pos.x, wall_left_x
		fld soccer.bcoef.x
		fchs
		fstp soccer.bcoef.x
	.ENDIF
	mov eax, wall_right_x
	sub eax, soccer.bsize.x
	.IF soccer.pos.x > eax
		mov soccer.pos.x, eax
		fld soccer.bcoef.x
		fchs
		fstp soccer.bcoef.x
	.ENDIF

y_move_label:
	;����y��������
	fld soccer.bcoef.y
	fimul soccer.speed
	fistp soccer.delta.y

	.IF soccer.delta.y == 0
		jmp check_door_label
	.ENDIF
	mov eax, soccer.delta.y
	add soccer.pos.y, eax
	.IF soccer.pos.y < wall_top_y
		mov soccer.pos.y, wall_top_y
		fld soccer.bcoef.y
		fchs
		fstp soccer.bcoef.y
	.ENDIF
	mov eax, wall_down_y
	sub eax, soccer.bsize.y
	.IF soccer.pos.y > eax
		mov soccer.pos.y, eax
		fld soccer.bcoef.y
		fchs
		fstp soccer.bcoef.y
	.ENDIF

check_door_label:
	
	mov ebx, soccer.bsize.y
	shr ebx, 1

	mov eax, door_right_x
	sub eax, soccer.bsize.x

	.IF soccer.pos.x < door_left_x || soccer.pos.x > eax
		mov eax, soccer.pos.y
		add eax, soccer.bsize.y
		.IF soccer.pos.y < door_top_y &&  eax > door_top_y
			fld soccer.bcoef.y
			fchs
			fstp soccer.bcoef.y
			sub eax, door_top_y
			.IF eax > ebx
				mov soccer.pos.y, door_top_y
			.ELSE
				mov eax, door_top_y
				sub eax, soccer.bsize.y
				mov soccer.pos.y, eax
			.ENDIF
		.ELSEIF soccer.pos.y < door_down_y && eax > door_down_y
			fld soccer.bcoef.y
			fchs
			fstp soccer.bcoef.y
			sub eax, door_down_y
			.IF eax > ebx
				mov soccer.pos.y, door_down_y
			.ELSE
				mov eax, door_down_y
				sub eax, soccer.bsize.y
				mov soccer.pos.y, eax
			.ENDIF
		.ENDIF
	.ENDIF

	; ˥������ٶ�
	.IF soccer.counter == 10
		mov soccer.counter, 0
		sub soccer.speed, ball_speed_coef
		.IF soccer.speed < 0
			mov soccer.speed, 0
		.ENDIF
		; �ж����٣��ı�����˶�/��ֹ״̬
		.IF soccer.speed == 0
			mov soccer.is_static, 1
		.ENDIF
	.ELSE
		inc soccer.counter
	.ENDIF

	ret
moveBall endp

; �ı����￪ʼ�˶�ʱ��λ�ã������ڷ���ı䡢״̬�ı�ʱ����ͼƬ�ߴ�������Ͻ�����
; run_type�˶���ʽ��0�Ӿ�ֹ��Ϊ�˶���1���˶�״̬��Ϊ�˶�
changePlayerPos proc uses eax ebx ecx, addrPlayer:DWORD, des_dir:DWORD
LOCAL center_x:SDWORD
LOCAL center_y:SDWORD

	assume ecx:ptr player
	mov ecx, addrPlayer

	; �������λ��
	mov eax, [ecx].psize.x
	sar eax, 1
	mov ebx, [ecx].pos.x
	add ebx, eax
	mov center_x, ebx
	mov eax, [ecx].psize.y
	sar eax, 1
	mov ebx, [ecx].pos.y
	add ebx, eax
	mov center_y, ebx

	; ���ݽ�����Ҫ�ı�ȥ�ķ���
	; �Ϸ���
	.IF des_dir == dir_top
		sub center_x, 38
		m2m [ecx].pos.x, center_x
		sub center_y, 35
		m2m [ecx].pos.y, center_y
	; �·���
	.ELSEIF des_dir == dir_down
		sub center_x, 38
		m2m [ecx].pos.x, center_x
		sub center_y, 35
		m2m [ecx].pos.y, center_y
	; ����
	.ELSEIF des_dir == dir_left
		sub center_x, 35
		m2m [ecx].pos.x, center_x
		sub center_y, 38
		m2m [ecx].pos.y, center_y
	; �ҷ���
	.ELSEIF des_dir == dir_right
		sub center_x, 35
		m2m [ecx].pos.x, center_x
		sub center_y, 38
		m2m [ecx].pos.y, center_y
	.ENDIF

	ret
changePlayerPos endp

; ����������˶�״̬��ؾ�ֹ״̬ʱ�������ߴ��λ��
returnPlayerPos proc uses ecx, addrPlayer:DWORD
	assume ecx:ptr player
	mov ecx, addrPlayer

	; ֱ�Ӹ��ݳߴ����жϵ�ǰ����
	; ��������
	.IF [ecx].psize.x == 77 && [ecx].psize.y == 70
		add [ecx].pos.y, 14
		mov [ecx].psize.y, 42
	; ��������
	.ELSEIF [ecx].psize.x == 70 && [ecx].psize.y == 77
		add [ecx].pos.x, 14
		mov [ecx].psize.x, 42
	.ENDIF

	ret
returnPlayerPos endp


; �����������Ƿ���ײ, ��edx������ 1��ʾ��ײ��0��ʾû��
isColliding proc uses eax ebx ecx , addrPlayer:DWORD
LOCAL p_left_x:SDWORD
LOCAL p_right_x:SDWORD
LOCAL p_top_y:SDWORD
LOCAL p_down_y:SDWORD

	assume ecx: ptr player
	mov ecx, addrPlayer

	m2m p_left_x, [ecx].pos.x
	m2m p_top_y, [ecx].pos.y

	mov eax, [ecx].pos.x
	add eax, [ecx].psize.x
	mov p_right_x, eax
	mov eax, [ecx].pos.y
	add eax, [ecx].psize.y
	mov p_down_y, eax

	mov eax, soccer.pos.x
	mov ebx, soccer.pos.x
	add ebx, soccer.bsize.x

	.IF eax >= p_left_x && eax < p_right_x
		mov edx, 1
	.ELSEIF ebx > p_left_x && ebx <= p_right_x
		mov edx, 1
	.ELSEIF eax <= p_left_x && ebx >= p_right_x
		mov edx, 1
	.ENDIF

	.IF edx == 1
		mov edx, 0
		mov eax, soccer.pos.y
		mov ebx, soccer.pos.y
		add ebx, soccer.bsize.y
		.IF eax >= p_top_y && eax < p_down_y
			mov edx, 1
		.ELSEIF ebx > p_top_y && ebx <= p_down_y
			mov edx, 1
		.ELSEIF eax <= p_top_y && ebx >= p_down_y
			mov edx, 1
		.ENDIF
	.ENDIF

    ret
isColliding endp


; ��������������ײ
processCollide proc uses eax ebx ecx edx
		
		; �����һ����Ա����������ײ������
		mov edx, 0
		invoke isColliding, addr player1
		.IF edx == 1
			; �ı䷽��
			invoke calDirection, addr player1
			; ����ײ���Ż�ʹ����ı��ٶ�
			.IF player1.speed.x != 0 || player1.speed.y != 0
				mov soccer.speed, ball_speed
				mov soccer.is_static, 0
			.ENDIF
		.ENDIF

		; ����ڶ�����Ա����������ײ������
		mov edx, 0
		invoke isColliding, addr player2
		.IF edx == 1
			invoke calDirection, addr player2
			.IF player2.speed.x != 0 || player2.speed.y != 0
				mov soccer.speed, ball_speed
				mov soccer.is_static, 0
			.ENDIF
		.ENDIF
		ret
processCollide endp

; �ж��Ƿ�÷�
getScore proc uses eax
    ;player 1 get score
	mov eax, soccer.pos.x
	add eax, soccer.bsize.x
    .IF eax > door_right_x && soccer.pos.y < door_down_y && soccer.pos.y > door_top_y
        inc player1.score 
        .IF player1.score == 2
            invoke gameOver
            mov game_status, 3
			ret
		.ELSE 
			invoke resetGame
		.ENDIF
		; ��������õ���ʼλ��
    .ENDIF
    

    ;player 2 get score
    .IF soccer.pos.x < door_left_x && soccer.pos.y < door_down_y && soccer.pos.y > door_top_y
        inc player2.score 
        .IF player2.score == 2
            invoke gameOver
            mov game_status, 4
			ret
		.ELSE
			invoke resetGame
		.ENDIF
		; ��������õ���ʼλ��
    .ENDIF
	ret
getScore endp

; ���Ʒ���
paintScore proc member_hdc1: HDC, member_hdc2:HDC
    ; PLAYER 1
    invoke SelectObject, member_hdc2, score_bitmap
    mov eax, player1.score
    mov ebx, 160
    mul ebx
    invoke TransparentBlt, member_hdc1, 450, 20, 90, 120, member_hdc2,\
                eax, 0, 160, 213, 16777215
        
    ; PLAYER 2
    mov eax, player2.score
    mov ebx, 160
    mul ebx
    invoke TransparentBlt, member_hdc1, 650, 20, 90, 120, member_hdc2,\
                eax, 0, 160, 213, 16777215
    ret
paintScore endp

; ��Ϣѭ��
MsgLoop proc
    LOCAL msg:MSG
    push ebx
    lea ebx, msg
    jmp getmsg
  msgloop:
    invoke TranslateMessage, ebx
    invoke DispatchMessage,  ebx
  getmsg:
    invoke GetMessage,ebx,0,0,0
    test eax, eax
    jnz msgloop
    pop ebx
    ret
MsgLoop endp

; �������̧���¼�
processKeyUp proc uses eax, wParam:WPARAM
	.IF game_status == 2
		;player1 w a s d
		mov al, player1.dir
		.IF wParam == 57h
			and al, dir_top
			.IF al != 0
				and player1.dir, 07h
				mov player1.speed.y, 0
			.ENDIF
		.ELSEIF wParam == 41h
			and al, dir_left
			.IF al != 0
				and player1.dir, 0dh
				mov player1.speed.x, 0
			.ENDIF
		.ELSEIF wParam == 53h
			and al, dir_down
			.IF al != 0
				and player1.dir, 0bh
				mov player1.speed.y, 0
			.ENDIF
		.ELSEIF wParam == 44h
			and al, dir_right
			.IF al != 0
				and player1.dir, 0eh
				mov player1.speed.x, 0
			.ENDIF
		.ENDIF
		; �ı�player��״̬
		.IF player1.dir == 0
			mov player1.is_static, 1
			invoke returnPlayerPos, addr player1
		; ���̧��ĳһ������֮��ֻʣһ�����򣬻�ҪУ��һ�´�ʱ�ķ���
		.ELSEIF player1.dir == dir_top
			invoke changePlayerPos, addr player1, dir_top
			mov player1.bmp_dir, dir_top
			; �ı�����ߴ�Ϊ�÷�����˶�״̬�ߴ�
			mov player1.psize.x, 77
			mov player1.psize.y, 70
		.ELSEIF player1.dir == dir_down
			invoke changePlayerPos, addr player1, dir_down
			mov player1.bmp_dir, dir_down
			mov player1.psize.x, 77
			mov player1.psize.y, 70
		.ELSEIF player1.dir == dir_left
			invoke changePlayerPos, addr player1, dir_left
			mov player1.bmp_dir, dir_left
			mov player1.psize.x, 70
			mov player1.psize.y, 77 
		.ELSEIF player1.dir == dir_right
			invoke changePlayerPos, addr player1, dir_right
			mov player1.bmp_dir, dir_right
			mov player1.psize.x, 70
			mov player1.psize.y, 77
		.ENDIF

		; player2 ��  �� �� ��
		mov al, player2.dir
		.IF wParam == VK_UP
			and al, dir_top
			.IF al != 0
				and player2.dir, 07h
				mov player2.speed.y, 0
			.ENDIF
		.ELSEIF wParam == VK_LEFT
			and al, dir_left
			.IF al != 0
				and player2.dir, 0dh
				mov player2.speed.x, 0
			.ENDIF
		.ELSEIF wParam == VK_DOWN
			and al, dir_down
			.IF al != 0
				and player2.dir, 0bh
				mov player2.speed.y, 0
			.ENDIF
		.ELSEIF wParam == VK_RIGHT
			and al, dir_right
			.IF al != 0
				and player2.dir, 0eh
				mov player2.speed.x, 0
			.ENDIF
		.ENDIF
		; �ı�player��״̬
		.IF player2.dir == 0
			mov player2.is_static, 1
			invoke returnPlayerPos, addr player2
		; ���̧��ĳһ������֮��ֻʣһ�����򣬻�ҪУ��һ�´�ʱ�ķ���
		.ELSEIF player2.dir == dir_top
			invoke changePlayerPos, addr player2, dir_top
			mov player2.bmp_dir, dir_top
			; �ı�����ߴ�Ϊ�÷�����˶�״̬�ߴ�
			mov player2.psize.x, 77
			mov player2.psize.y, 70
		.ELSEIF player2.dir == dir_down
			invoke changePlayerPos, addr player2, dir_down
			mov player2.bmp_dir, dir_down
			mov player2.psize.x, 77
			mov player2.psize.y, 70
		.ELSEIF player2.dir == dir_left
			invoke changePlayerPos, addr player2, dir_left
			mov player2.bmp_dir, dir_left
			mov player2.psize.x, 70
			mov player2.psize.y, 77 
		.ELSEIF player2.dir == dir_right
			invoke changePlayerPos, addr player2, dir_right
			mov player2.bmp_dir, dir_right
			mov player2.psize.x, 70
			mov player2.psize.y, 77
		.ENDIF

	.ENDIF
	ret
processKeyUp endp

; ������̰����¼�
processKeyDown proc uses eax, wParam:WPARAM
	; ֻ������Ϸ��ʼ��ʱ��Ŵ���keydown�¼�
	.IF game_status == 2
		; w a s d, player one
		mov al, player1.dir
		.IF  wParam == 57h
			; �ı�λͼ���򣺵��ҽ���֮ǰû�з����������(player.dir == 0)
			.IF al == 0
				invoke changePlayerPos, addr player1, dir_top
				mov player1.bmp_dir, dir_top
				; �ı�����ߴ�Ϊ�÷�����˶�״̬�ߴ�
				mov player1.psize.x, 77
				mov player1.psize.y, 70
			.ENDIF

			and al, dir_down
			.IF al == 0
				or player1.dir, dir_top
				mov player1.speed.y, -player_speed
			.ENDIF
			mov player1.is_static, 0

		.ELSEIF wParam == 41h  
			.IF al == 0
				invoke changePlayerPos, addr player1, dir_left
				mov player1.bmp_dir, dir_left
				mov player1.psize.x, 70
				mov player1.psize.y, 77 
			.ENDIF

			and al, dir_right
			.IF al == 0
				or player1.dir, dir_left
				mov player1.speed.x, -player_speed
			.ENDIF
			mov player1.is_static, 0

		.ELSEIF wParam == 53h
			.IF al == 0
				invoke changePlayerPos, addr player1, dir_down
				mov player1.bmp_dir, dir_down
				mov player1.psize.x, 77
				mov player1.psize.y, 70
			.ENDIF

			and al, dir_top
			.IF al == 0
				or player1.dir, dir_down
				mov player1.speed.y, player_speed
			.ENDIF
			mov player1.is_static, 0

		.ELSEIF wParam == 44h
			.IF al == 0
				invoke changePlayerPos, addr player1, dir_right
				mov player1.bmp_dir, dir_right
				mov player1.psize.x, 70
				mov player1.psize.y, 77
			.ENDIF

			and al, dir_left
			.IF al == 0
				or player1.dir, dir_right
				mov player1.speed.x, player_speed
			.ENDIF
			mov player1.is_static, 0

		.ENDIF
		
		
		; �� �� �� �� ,player two
		mov al, player2.dir
		.IF wParam == VK_UP
			; �ı�λͼ���򣺵��ҽ���֮ǰû�з����������(player.dir == 0)
			.IF al == 0
				invoke changePlayerPos, addr player2, 08h
				mov player2.bmp_dir, 08h
				mov player2.psize.x, 77
				mov player2.psize.y, 70
			.ENDIF

			and al, dir_down
			.IF al == 0
				or player2.dir, dir_top
				mov player2.speed.y, -player_speed
			.ENDIF
			mov player2.is_static, 0

		.ELSEIF wParam == VK_LEFT
			.IF al == 0
				invoke changePlayerPos, addr player2, 02h
				mov player2.bmp_dir, 02h
				mov player2.psize.x, 70
				mov player2.psize.y, 77
			.ENDIF

			and al, dir_right
			.IF al == 0
				or player2.dir, dir_left
				mov player2.speed.x, -player_speed
			.ENDIF
			mov player2.is_static, 0

		.ELSEIF wParam == VK_DOWN
			.IF al == 0
				invoke changePlayerPos, addr player2, 04h
				mov player2.bmp_dir, 04h
				mov player2.psize.x, 77
				mov player2.psize.y, 70
			.ENDIF

			and al, dir_top
			.IF al == 0
				or player2.dir, dir_down
				mov player2.speed.y, player_speed
			.ENDIF
			mov player2.is_static, 0

		.ELSEIF wParam == VK_RIGHT
			.IF al == 0
				invoke changePlayerPos, addr player2, 01h
				mov player2.bmp_dir, 01h
				mov player2.psize.x, 70
				mov player2.psize.y, 77
			.ENDIF

			and al, dir_left
			.IF al == 0
				or player2.dir, dir_right
				mov player2.speed.x, player_speed
			.ENDIF
			mov player2.is_static, 0

		.ENDIF
	.ENDIF
	ret
processKeyDown endp

WndProc proc hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	; �����ڴ������һЩ����
	.IF uMsg == WM_CREATE
		; ����λͼ��Դ
		invoke loadGameImages
		; �����߼��߳�
		mov eax, OFFSET logicThread
		invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread1
		invoke CloseHandle, eax
		; ��������߳�
		mov eax, OFFSET paintThread
		invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread2
		invoke CloseHandle, eax

	.ELSEIF uMsg == WM_DESTROY
		; �˳��߳�
		invoke PostQuitMessage, NULL

	.ELSEIF uMsg == WM_PAINT
		; ���ø��³���������WM_PAINT��paintThread��InvalidateRect����
		invoke updateScene

	.ELSEIF uMsg == WM_CHAR
		; ����enter�������¼�
		.IF wParam == 13  
			.IF game_status == 0
				mov game_status, 1
			.ELSEIF game_status == 1
				mov game_status, 2
			.ELSEIF game_status == 3 || game_status == 4
				mov game_status, 1
			.ENDIF
		.ENDIF
		.IF wParam == 27
			.IF game_status == 1
				invoke PostQuitMessage, NULL
			.ENDIF
		.ENDIF


	.ELSEIF uMsg == WM_KEYUP
		; �������̧���¼�
		invoke processKeyUp, wParam

	.ELSEIF uMsg == WM_KEYDOWN
		; ������̰����¼�
		invoke processKeyDown, wParam

	.ELSE 
		; Ĭ����Ϣ������
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.ENDIF
	xor eax, eax
	ret
WndProc endp

; һ���̺߳��������ݳ�����״̬����ѭ������Ϸ״̬ʱ�򣬲��Ͻ�����ײ�жϵȵ�
logicThread proc p:DWORD
	LOCAL area:RECT
	; ��ʼ���棬�����û��ֶ�����ָ�Ͻ��棬���ߵ�ʱ���Զ�����
	.WHILE game_status == 0
		invoke Sleep, 1000
		mov game_status, 1
	.ENDW

	game:

	; ָ�Ͻ���
	.WHILE game_status == 1
		invoke Sleep, 30
	.ENDW

	; ��Ϸ����
	.WHILE game_status == 2
		invoke Sleep, 30
		; �ƶ������
		invoke movePlayer, addr player1
		invoke movePlayer, addr player2
		invoke moveBall 
		; �ж�����������ײ
		invoke processCollide
		; �ж���Ϸ�Ƿ����
		invoke getScore
	.ENDW

	; ʤ������
	.WHILE game_status == 3 || game_status == 4
		invoke Sleep, 30
	.ENDW

	jmp game

	ret
logicThread endp

; ���Ͻ��л�������
paintThread proc p:DWORD
	.WHILE 1
		invoke Sleep, 10
		invoke InvalidateRect, hWnd, NULL, FALSE
	.ENDW
	ret
paintThread endp

; һ����Ϸ�����״̬�ָ�
resetGame proc
	; pos 
    mov player1.pos.x, 400
    mov player1.pos.y, 420
    mov player2.pos.x, 760
    mov player2.pos.y, 420
    mov soccer.pos.x, 575
    mov soccer.pos.y, 440
    
	; speed
    mov player1.speed.x, 0
    mov player1.speed.y, 0
    mov player2.speed.x, 0
    mov player2.speed.y, 0
    mov soccer.speed, 0
    
	; size
    mov player1.psize.x, 42
    mov player1.psize.y, 77
    mov player2.psize.x, 42
    mov player2.psize.y, 77
    
	; dir
    mov player1.dir, 0
    mov player2.dir, 0
	mov player1.is_static, 1
    mov player2.is_static, 1
	mov player1.bmp_dir, dir_right
	mov player2.bmp_dir, dir_left

    mov soccer.counter, 0
    mov soccer.cur_frame, 0
	mov soccer.is_static, 1
	mov soccer.frame_counter, 0

	ret
resetGame endp

; ������Ϸ���������
gameOver proc
	 invoke resetGame
	 mov player1.score, 0
	 mov player2.score, 0
 ret
gameOver endp

; ������ڵ�
end start

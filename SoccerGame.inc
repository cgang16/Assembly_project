;     include files
;     ~~~~~~~~~~~~~
      include \masm32\INCLUDE\windows.inc
      include \masm32\INCLUDE\masm32.inc
      include \masm32\INCLUDE\gdi32.inc
      include \masm32\INCLUDE\user32.inc
      include \masm32\INCLUDE\kernel32.inc
      include \masm32\INCLUDE\Comctl32.inc
      include \masm32\INCLUDE\comdlg32.inc
      include \masm32\INCLUDE\shell32.inc
      include \masm32\INCLUDE\oleaut32.inc
      include \masm32\INCLUDE\msvcrt.inc
	  include \masm32\INCLUDE\msimg32.inc
      include \masm32\macros\macros.asm

;     libraries
;     ~~~~~~~~~
      includelib \masm32\LIB\masm32.lib
      includelib \masm32\LIB\gdi32.lib
      includelib \masm32\LIB\user32.lib
      includelib \masm32\LIB\kernel32.lib
      includelib \masm32\LIB\Comctl32.lib
      includelib \masm32\LIB\comdlg32.lib
      includelib \masm32\LIB\shell32.lib
      includelib \masm32\LIB\oleaut32.lib
      includelib \masm32\LIB\msvcrt.lib
	  includelib \masm32\LIB\msimg32.lib

      ; -----------------
      ; Local prototypes
      ; -----------------


; ���Ա�ʾ���ꡢ�ٶȡ���״��δ�������ٶȣ�����ȡ��ֵ
point struct
	x SDWORD 0
	y SDWORD 0
point ends

coef  struct
	x real4 0.0
	y real4 0.0
coef  ends

; ��ҽṹ��
player struct
	pos           point <>    ; ��ҵĴ�������λ��
	psize         point <>    ; ��ҵ���״�����ȺͿ��ȣ�����ı�ʱ������������
	speed         point <>    ; ��ҵ�x,y�ٶ� x�ٶ�����Ϊ����y�ٶ�����Ϊ��
	dir           BYTE  0     ; ����,lower four bits  0000 up down left right,�����෴�����һ����������
	bmp_dir       BYTE  0     ; λͼ�ķ���4��bit��ֻ��ͬʱ��1λΪ1��ȡ�����˶�ʱ�ĸ����ȱ�����
	score         DWORD 0     ; ��ҵ÷֣����Ϊ0�����Ϊ3
	is_static     BYTE  0     ; �Ƿ��ھ�ֹ״̬
	cur_frame     BYTE  0     ; �����˶�״̬ʱ����ǰ֡����ȡֵΪ1��2
	frame_counter BYTE  0     ; �ۼƱ�����ÿ�μӵ�5�͸����˶�֡�����Ѹñ�������
player ends

; ������
ball struct
	pos           point    <>  ; ʵʱλ��
	bsize         point    <>  ; �����״��������ͬ
	speed         SDWORD   0   ; �����ٶ�
	bcoef         coef     <>  ; <cos, sin>���ٶȵķֽ�
	delta         point    <>  ; ÿ�μ���õ�������
	counter       BYTE     0   ; �������������ٶȵ�˥��
	is_static     BYTE     1   ; 1ֹͣ�ڵ����ϣ�0�ڿ��з���
	cur_frame     BYTE     1   ; ��ĵ�ǰ֡����ȡֵ0~4
	frame_counter BYTE     0   ; ���֡���ۼӱ�����ÿ�μӵ�7�ͻ�һ֡
ball ends

; ��Ϸ�г���
.const
	my_window_width  EQU   1200       ; ����ˮƽ����
	my_window_height EQU   840        ; ������ֱ�߶�

	dir_top          EQU   8          ; ����������������������
	dir_down         EQU   4
	dir_left         EQU   2
	dir_right        EQU   1

	ball_speed       EQU   25         ; �����ĳ�ʼ�ٶ�
	player_speed     EQU   4          ; �˵�ÿ������ĳ�ʼ�ٶ�

	ball_speed_coef  EQU   6

	wall_top_y       EQU   160         ; ����߽��λ�ã�������������������������һ��
	wall_down_y      EQU   775
	wall_left_x      EQU   120
	wall_right_x     EQU   1080

	door_top_y       EQU   358          ; �������±߽��yֵ
	door_down_y      EQU   582
	door_left_x      EQU   180        ; ���������x
	door_right_x     EQU   1010		  ; �ұ�������x



	; initialized data allocation
.data	
	game_status      BYTE     0          ; 0 ��ʼ���� 1 �������� 2 ��Ϸ���� 3 ���1ʤ�� 4 ���2ʤ��

	h_startpage      DWORD    0          ; ��ʼ����
	h_gamepage       DWORD    0          ; ��Ϸ����
	h_winpage1       DWORD    0          ; ���1ʤ������
	h_winpage2       DWORD    0          ; ���2ʤ������
	h_guidepage      DWORD    0          ; ָ��ҳ��
	
	player1_bitmap   DWORD    0          ; ���1�ľ���ͼ
	player2_bitmap   DWORD    0          ; ���2�ľ���ͼ
	ball_bitmap      DWORD    0          ; ���λͼ

	score_bitmap     DWORD    0          ; ����λͼ


	player1          player <<400, 420>, <42, 77>,<0,0>,0,1,0,1,1,0>                     ; ���1
	player2          player <<760, 420>, <42, 77>,<0,0>,0,2,0,1,1,0>                     ; ���2
	soccer           ball   <<575, 440>, <50, 50>,25,<0.0,0.0>,<0,0>,0,1,1,0>            ; ��
	paintstruct      PAINTSTRUCT <>   ; ���ƽṹ��


  ; -----------------------------
  ; uninitialised data allocation
  ; -----------------------------
    .data?
        hInstance   DWORD ?          ; ���ڼ�¼����ʵ��
        hWnd        DWORD ?          ; ���
        hIcon       DWORD ?
        hCursor     DWORD ?
        CommandLine DWORD ?

        sWid        DWORD ?          ; ���ڵĿ��Ⱥ͸߶�
        sHgt        DWORD ?

		thread1     DWORD ?
		thread2     DWORD ?


      ; -----------------
      ; Local prototypes
      ; -----------------

        WndProc          PROTO :DWORD,:DWORD,:DWORD,:DWORD
        MsgLoop          PROTO
        Main             PROTO
		loadGameImages   PROTO
		isColliding      PROTO :DWORD
		paintBackground  PROTO :DWORD,:DWORD
		paintPlayers     PROTO :DWORD,:DWORD
		paintBall        PROTO :DWORD,:DWORD
		paintScore       PROTO :DWORD,:DWORD
		updateScene      PROTO
		movePlayer       PROTO :DWORD
		moveBall		 PROTO
		changePlayerPos  PROTO :DWORD,:DWORD
		returnPlayerPos  PROTO :DWORD
		getScore         PROTO
		logicThread      PROTO :DWORD
		paintThread      PROTO :DWORD
		gameOver         PROTO 
		resetGame        PROTO
		processKeyUp     PROTO :DWORD
		processKeyDown   PROTO :DWORD
		processCollide   PROTO
		calDirection     PROTO :DWORD


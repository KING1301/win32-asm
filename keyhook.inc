; Include
include         windows.inc
include         user32.inc
includelib      user32.lib
include         kernel32.inc
includelib      kernel32.lib
include         Comctl32.inc
includelib      Comctl32.lib
include         Hookdll.inc
includelib      Hookdll.lib
include         shell32.inc
includelib      shell32.lib
include         shlwapi.inc
includelib      shlwapi.lib
include         advapi32.inc
includelib      advapi32.lib
include         Gdi32.inc
includelib      Gdi32.lib
;-------------------------------------------------------------------------------------------------------
; Equ 等值定义
ICO_MAIN        equ    1000h   ;图标
IDM_MAIN        equ    2000h   ;菜单
IDA_MAIN        equ    2000h   ;加速键
;菜单选项
IDM_HIDE        equ    2001h
IDM_RUN         equ    2002h
IDM_EXIT        equ    2003h
IDM_HEX         equ    2004h
IDM_DEC         equ    2005h

IDM_ABOUT       equ    2010h
IDM_MENUHELP    equ    2011h

IDM_HELP        equ    2100h
ID_STATUSBAR    equ    2200h
ID_EDIT         equ    2201h
;自定义消息
WM_HOOK         equ     WM_USER + 100h


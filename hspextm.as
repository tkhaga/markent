;書式はhspext.dll互換ですが、HSPモジュールの制約より文字列を
;パラメータにすることは出来なくなっています

	#module

	#define HKEY_CLASSES_ROOT           0x80000000
	#define HKEY_CURRENT_USER           0x80000001
	#define HKEY_LOCAL_MACHINE          0x80000002
	#define HKEY_USERS                  0x80000003
	#define HKEY_PERFORMANCE_DATA       0x80000004
	#define HKEY_CURRENT_CONFIG         0x80000005
	#define HKEY_DYN_DATA               0x80000006
	#define KEY_QUERY_VALUE         0x0001
	#define KEY_SET_VALUE           0x0002
	#define KEY_CREATE_SUB_KEY      0x0004
	#define KEY_ENUMERATE_SUB_KEYS  0x0008
	#define KEY_NOTIFY              0x0010
	#define KEY_CREATE_LINK         0x0020
	#define SYNCHRONIZE                      0x00100000
	#define STANDARD_RIGHTS_ALL              0x001F0000
	#define KEY_ALL_ACCESS 25
	#define MAX_PATH 260
	#define BIF_RETURNONLYFSDIRS 1
	#define CF_OEMTEXT 7
	#define GENERIC_READ	0x80000000
	#define OPEN_EXISTING	3
	#define FILE_ATTRIBUTE_NORMAL	128
	#define FILE_SHARE_READ	1
	#define FILE_SHARE_WRITE	2

	#deffunc fxcopy val,val,int
	mref fname,24
	mref spath,25
	mref mode,2
	mref stt,64
	strlen ss,spath
	sdim fpath,ss+2+MAX_PATH
	fpath=spath
	peek num,fpath,ss-1
	if num!'\\' :fpath+"\\"
	fpath+fname
	getptr p,fname
	getptr p.1,fpath
	p.2=0
	if mode=0{
		dllproc "CopyFileA",p,3,D_KERNEL
	}else{
		dllproc "MoveFileA",p,2,D_KERNEL
	}
	if dllret=0 :stt=-1 :return
	return

	#deffunc fxren val,val,int

	return

	#deffunc fxshort val,val
	mref lpath,24
	mref spath,25
	mref stt,64
	getptr p,lpath
	getptr p.1,spath
	p.2=MAX_PATH
	dllproc "GetShortPathNameA",p,3,D_KERNEL
	stt=dllret@
	return

;	#deffunc fxdir val,int
;	mref dir,24
;	mref mode,1
;	if mode<0 :

	#deffunc clipset val
	mref setstr,24
	mref bmscr,67
	mref stt,64
	p=bmscr.13
	dllproc "OpenClipboard",p,1,D_USER
;GHND
	p=$2&$40
	strlen ss,setstr
	ss+
	p.1=ss+1
	dllproc "GlobalAlloc",p,2,D_KERNEL
	hglobal=dllret@
	dllproc "GlobalLock",hglobal,1,D_KERNEL
	ll_poke@ setstr,dllret@
	dllproc "GlobalUnlock",p,1,D_KERNEL
	dllproc "EmptyClipboard",p,,D_USER
	p=CF_OEMTEXT
	p.1=hglobal
	dllproc "SetClipboardData",p,2,D_USER
	dllproc "CloseClipboard",p,,D_USER
	stt=0
	return

	#deffunc fxtget val,val
	mref st,48
	mref fn,25
	mref stt,64
	getptr p,fn
	getptr pft,ft
	getptr pft2,ft2
	p.1=GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL
	dllproc "CreateFileA",p,7,D_KERNEL
	if dllret@=0xffffffff :stt=2 :return
	p=dllret@,pft,pft+16,pft+8
	dllproc "GetFileTime",p,4,D_KERNEL
	a=dllret@
	dllproc "CloseHandle",p,1,D_KERNEL
	if a=0 :stt=1 :return
	getptr ptmp,tmp
	repeat 3
		p=cnt*8+pft,cnt*8+pft2
		dllproc "FileTimeToLocalFileTime",p,2,D_KERNEL
		p=p.1,ptmp
		dllproc "FileTimeToSystemTime",p,2,D_KERNEL
		if dllret@=0 :stt=1
		a=32*cnt
		repeat 8
			memcpy st,tmp,2,cnt*4+a,cnt*2
		loop
	loop
	return

	#deffunc clipget val,int
	mref len,1
	mref setstr,24
	mref bmscr,67
	mref stt,64
	if len=0 :len=64
	p=0
	dllproc "OpenClipboard",p,1,D_USER
	p=CF_OEMTEXT
	dllproc "IsClipboardFormatAvailable",p,1,D_USER
	ss=dllret@
	if ss{
		dllproc "GetClipboardData",p,1,D_USER 
		hglobal=dllret@
		dllproc "GlobalLock",hglobal,1,D_KERNEL
		ll_peek@ setstr,hglobal
		strmid setstr,setstr,,len
		dllproc "GlobalUnlock",hglobal,1,D_KERNEL
	}else{
		stt=1
	}
	dllproc "CloseClipboard",p,,D_USER
	return

	#deffunc selfolder val,val,int
	mref path,24
	mref ti,25
	mref stt,64
	mref rstr,65
	sdim browseinfo,32
	sdim path,MAX_PATH
	sdim fname,MAX_PATH
	getptr pbrowseinfo,browseinfo
;typedef struct _browseinfo {
;	HWND hwndOwner;
;	LPCITEMIDLIST pidlRoot;
;	LPSTR pszDisplayName;
;	LPCSTR lpszTitle;
;	UINT ulFlags;
;	BFFCALLBACK lpfn;
;	LPARAM lParam;
;	int iImage;
;} BROWSEINFO,*PBROWSEINFO,*LPBROWSEINFO;
	ll_poke4 0,pbrowseinfo
	getptr ptr,fname
	ll_poke4 ptr,pbrowseinfo+8
	getptr ptr,ti
	if ti="" :titmp="フォルダを選択してください" :getptr ptr,titmp
	ll_poke4 ptr,pbrowseinfo+12
	ll_poke4 BIF_RETURNONLYFSDIRS,pbrowseinfo+16
	dllproc "SHBrowseForFolder",pbrowseinfo,1,D_SHELL
	ptr=dllret@
	if ptr=0 :stt=1 :return
	getptr ptr.1,path
	dllproc "SHGetPathFromIDList",ptr,2,D_SHELL
	rstr=fname
	return

;レジストリ関係は未実装です
#deffunc regdone
	if hkey :dllproc "RegCloseKey",hkey,1,D_USER
	hkey=0
	stt=0
	return
#deffunc regkey int,val,int
	mref keyg
	mref regk,25
	mref mode,2
	regdone
	gosub keybase
	if mode=0{
		p=regk,,0,KEY_ALL_ACCESS
		getptr p.1,regk
		getptr p.4,hkey
		dllproc "RegOpenKeyEx",p,5,D_USER
	}else{
		dllproc "RegCreateKeyEx",p,,D_USER
	}
	return
*keybase
	if keyg=0 :keyg=HKEY_CURRENT_USER
	if keyg=1 :keyg=HKEY_LOCAL_MACHINE
	if keyg=2 :keyg=HKEY_USERS
	if keyg=3 :keyg=HKEY_CLASSES_ROOT
	if keyg=4 :keyg=HKEY_DYN_DATA
	if keyg=5 :keyg=HKEY_PEFORMANCE_DATA
	return
	
	#undef HKEY_CLASSES_ROOT
	#undef HKEY_CURRENT_USER
	#undef HKEY_LOCAL_MACHINE
	#undef HKEY_USERS
	#undef HKEY_PERFORMANCE_DATA
	#undef HKEY_CURRENT_CONFIG
	#undef HKEY_DYN_DATA
	#undef KEY_QUERY_VALUE
	#undef KEY_SET_VALUE
	#undef KEY_CREATE_SUB_KEY
	#undef KEY_ENUMERATE_SUB_KEYS
	#undef KEY_NOTIFY
	#undef KEY_CREATE_LINK
	#undef SYNCHRONIZE
	#undef STANDARD_RIGHTS_ALL
	#undef KEY_ALL_ACCESS
	#undef MAX_PATH
	#undef CF_OEMTEXT

	#global
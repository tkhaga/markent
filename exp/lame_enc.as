;lame_enc.dllを使ったWAVEファイルをMP3にエンコードするサンプル（3日掛かりました）
;サンプルなので無駄な変数もあまり減らしていません
;しかし8bitのWAVEファイルはなぜか2倍速になる。これは私の技量では今のところ無理です
;第２版でそんなに遅くなくなりました
;第３版でメモリ消費量が第２版の1/2になりました。第１版よりは多いです

#define	BE_CONFIG_MP3 0

#define	BE_MP3_MODE_STEREO 0
#define	BE_MP3_MODE_JSTEREO 1
#define	BE_MP3_MODE_DUALCHANNEL 2
#define	BE_MP3_MODE_MONO 3

#define FORMAT_CHUNK_SIZE 24

#include "llmod.as"
	ll_libload hdll,"lame_enc"
;	ll_libload hdll,"BladeEnc"		;BladeEncもこのスクリプトで問題無し

	sdim infile,$100
	sdim outfile,$100

	dialog "wav",16,"WAVEファイル"
	if stat=0 :end
	infile=refstr
	dialog "mp3",17,"MP3ファイル"
	if stat=0 :end
	outfile=refstr
	exist infile
	length=strsize
	sdim wave,length
	bload infile,wave
	getptr pwave,wave
	pmp3=pwave
	begin=pmp3

	str tmp
	ll_peek tmp,pwave+12,4
	if tmp!"fmt " :dialog "これはWAVEファイルではありません" :end

	int tmp
	ll_peek tmp,pwave+20,2
	if tmp!1 :dialog "圧縮済みのWAVEファイルは変換できません" :end

	ll_peek channel,pwave+22,2			;入力ファイルのチャンネル数
	ll_peek srate,pwave+24,4		;入力ファイルのサンプリングレート

	ll_peek tmp,pwave+16,4
	pwave+(8+tmp)-FORMAT_CHUNK_SIZE

	str tmp
	repeat
		ll_peek tmp,pwave,4
		if tmp="data" :break
		pwave+
	loop
	ll_peek chunksize,pwave+4,4		;データ部分のサイズ
	pwave+8

	sdim BE_CONFIG,128			;BE_CONFIG構造体
	getptr index,BE_CONFIG
	getptr phstream,hstream
	getptr psamples,samples
	getptr pmp3buflen,mp3buflen
	param=index,psamples,pmp3buflen,phstream

	;ll_poke4 BE_CONFIG_MP3,index,1
	index+4

;	ll_poke4 1,index
;	index+4
;	ll_poke4 LHV1_STRUCTSZE,index
;	index+4
;	ll_poke4 srate,index
;	index+4
;	ll_poke4 0,index
;	index+4
;	if channnel=1{
;		channel=BE_MP3_MODE_MONO
;	}else{
;		channel=BE_MP3_MODE_JSTEREO
;	}
;	ll_poke1 channel,index
;	index+
;	ll_poke4 128,index
;	index+4
;	ll_poke4
;	index+4
;	ll_poke4 2,index
;	index+4
;	ll_poke4 1,index
;	index+4
;	ll_poke4 0,index
;	index+4
;	ll_poke4 0,index
;	index+4
;	index+4

	ll_poke4 srate,index			;サンプリングレート(入力ファイルと同じもので無ければならない)
	index+4
	if channel=1{
		channel=BE_MP3_MODE_MONO
	}else{
		channel=BE_MP3_MODE_JSTEREO
	}
	ll_poke channel,index			;モードの選択
	index+
	ll_poke4 128,index			;ビットレート(kbps)の選択
	index+4
	ll_poke4 1,index
	index+4
	ll_poke4 1,index
	index+4
	ll_poke4 1,index
	index+4
	ll_poke4 1,index

	dllproc "beInitStream",param,4,hdll	;ストリームの初期化
	mes stat				;0であれば成功
	if stat :dialog "初期化に失敗しました" :end
	mes hstream
	mes mp3buflen
	mes samples
	sdim mp3buf,mp3buflen
	sdim inputbuf,samples*2
	getptr pinputbuf,inputbuf
	getptr pmp3buf,mp3buf
	getptr pencoded,encoded
	skiperr 1
	delete outfile
	skiperr
	bsave outfile,index
	repeat
		ll_peek inputbuf,pwave,toread
		pwave+samples*2
		done+samples*2
		if done>=chunksize :break
		param=hstream,samples,pinputbuf,pmp3buf,pencoded
		dllproc "beEncodeChunk",param,5,hdll
		if stat: dialog "エンコードに失敗しました" :dllproc "beCloseStream",param,1,hdll :end
		ll_poke mp3buf,pmp3,encoded
		pmp3+encoded
		await				;ステータスが見たいのでウェイトをいれていますが、実際には必要ありません
	loop
	getptr pwrite,write
	param=hstream,pmp3buf,pwrite
	dllproc "beDeinitStream",param,3,hdll
	if write{
		ll_poke mp3buf,pmp3,write
		pmp3+write
	}
	dllproc "beCloseStream",param,1,hdll
	bsave outfile,wave,pmp3-begin
	end
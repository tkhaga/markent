;lame_enc.dll���g����WAVE�t�@�C����MP3�ɃG���R�[�h����T���v���i3���|����܂����j
;�T���v���Ȃ̂Ŗ��ʂȕϐ������܂茸�炵�Ă��܂���
;������8bit��WAVE�t�@�C���͂Ȃ���2�{���ɂȂ�B����͎��̋Z�ʂł͍��̂Ƃ��떳���ł�
;��Q�łł���Ȃɒx���Ȃ��Ȃ�܂���
;��R�łŃ���������ʂ���Q�ł�1/2�ɂȂ�܂����B��P�ł��͑����ł�

#define	BE_CONFIG_MP3 0

#define	BE_MP3_MODE_STEREO 0
#define	BE_MP3_MODE_JSTEREO 1
#define	BE_MP3_MODE_DUALCHANNEL 2
#define	BE_MP3_MODE_MONO 3

#define FORMAT_CHUNK_SIZE 24

#include "llmod.as"
	ll_libload hdll,"lame_enc"
;	ll_libload hdll,"BladeEnc"		;BladeEnc�����̃X�N���v�g�Ŗ�薳��

	sdim infile,$100
	sdim outfile,$100

	dialog "wav",16,"WAVE�t�@�C��"
	if stat=0 :end
	infile=refstr
	dialog "mp3",17,"MP3�t�@�C��"
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
	if tmp!"fmt " :dialog "�����WAVE�t�@�C���ł͂���܂���" :end

	int tmp
	ll_peek tmp,pwave+20,2
	if tmp!1 :dialog "���k�ς݂�WAVE�t�@�C���͕ϊ��ł��܂���" :end

	ll_peek channel,pwave+22,2			;���̓t�@�C���̃`�����l����
	ll_peek srate,pwave+24,4		;���̓t�@�C���̃T���v�����O���[�g

	ll_peek tmp,pwave+16,4
	pwave+(8+tmp)-FORMAT_CHUNK_SIZE

	str tmp
	repeat
		ll_peek tmp,pwave,4
		if tmp="data" :break
		pwave+
	loop
	ll_peek chunksize,pwave+4,4		;�f�[�^�����̃T�C�Y
	pwave+8

	sdim BE_CONFIG,128			;BE_CONFIG�\����
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

	ll_poke4 srate,index			;�T���v�����O���[�g(���̓t�@�C���Ɠ������̂Ŗ�����΂Ȃ�Ȃ�)
	index+4
	if channel=1{
		channel=BE_MP3_MODE_MONO
	}else{
		channel=BE_MP3_MODE_JSTEREO
	}
	ll_poke channel,index			;���[�h�̑I��
	index+
	ll_poke4 128,index			;�r�b�g���[�g(kbps)�̑I��
	index+4
	ll_poke4 1,index
	index+4
	ll_poke4 1,index
	index+4
	ll_poke4 1,index
	index+4
	ll_poke4 1,index

	dllproc "beInitStream",param,4,hdll	;�X�g���[���̏�����
	mes stat				;0�ł���ΐ���
	if stat :dialog "�������Ɏ��s���܂���" :end
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
		if stat: dialog "�G���R�[�h�Ɏ��s���܂���" :dllproc "beCloseStream",param,1,hdll :end
		ll_poke mp3buf,pmp3,encoded
		pmp3+encoded
		await				;�X�e�[�^�X���������̂ŃE�F�C�g������Ă��܂����A���ۂɂ͕K�v����܂���
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
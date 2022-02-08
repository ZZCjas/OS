NUMsector      EQU    8       ; ���ö�ȡ������������������(18) 
NUMheader      EQU    0        ; ���ö�ȡ������������ͷ���(01)
NUMcylind      EQU    0        ; ���ö�ȡ��������������

mbrseg         equ    7c0h     ; ����������Ŷε�ַ
loaderseg      equ    800h     ; �����̶�ȡLOADER���ڴ�Ķε�ַ

jmp   start

welcome db 'Welcome zzcOS!','$'
fyread  db 'Now Floppy Read Loader:','$'
cylind  db 'cylind:?? $',0    ; ���ÿ�ʼ��ȡ��������
header  db 'header:?? $',0    ; ���ÿ�ʼ��ȡ�Ĵ�ͷ���
sector  db 'sector:?? $',2    ; ���ÿ�ʼ��ȡ��������ţ���1������MBR�����Բ���
FloppyOK db '---Floppy Read OK','$'
Fyerror db '---Floppy Read Error' ,'$'
Fycontent db 'Floppy Content is:' ,'$'


start:

call showwelcome    ;��ʼ���Ĵ�������ӡ��Ҫ��Ϣ
call loader         ;ִ��loader,�������������̵�����ȫ������8000h��ʼ��
jmp  loaderseg:0    ;��ת���ںˡ�ִ��֮��CS=loaderseg=800H,IP=0
                    ;�ں˳���������ַ8000��ʼ��


showwelcome:
     mov   ax,mbrseg
     mov   ds,ax   ;Ϊ��ʾ������ʾ��Ϣ��׼��
     mov   ax,loaderseg
     mov   es,ax   ;Ϊ���������ݵ��ڴ���׼������Ϊ���������ַ����---ES:BX

     mov   si,welcome
     call  printstr
     call  newline
     ret

loader:
     mov   si, fyread
     call  printstr
     call  newline
     call  folppyload    ;�����̵�����ȫ��load���ڴ棬�������ַ8000h��ʼ
     ;mov   si, Fycontent
     ;call  printstr
     ;call  showdata      ;������֤һ�´����̶����kernal���������Ƿ���ȷ(������)
     ret


showdata:  mov  si,0             ;��֤��ʾ�����̶�ȡ���ڴ������
           mov  ax, 800h
           mov  es,ax
           mov  cx,50             ;������������ݳ���
nextchar:  mov al,[es:si]
           mov ah,0eh
           int 10h
           inc si
           loop nextchar
           RET

folppyload:
     call    read1sector
     MOV     AX,ES
     ADD     AX,0x0020
     MOV     ES,AX                ;һ������ռ512B=200H���պ��ܱ������������Ķ�,���ֻ��ı�ESֵ������ı�BP���ɡ�
     inc   byte [sector+11]
     cmp   byte [sector+11],NUMsector+1
     jne   folppyload             ;����һ������
     mov   byte [sector+11],1
     inc   byte [header+11]
     cmp   byte [header+11],NUMheader+1
     jne   folppyload             ;����һ����ͷ
     mov   byte [header+11],0
     inc   byte [cylind+11]
     cmp   byte [cylind+11],NUMcylind+1
     jne   folppyload             ;����һ������

     ret


numtoascii:     ;��2λ����10�������ֽ��ASII�����������ʾ��������56 �ֽ�ɳ���ascii: al:35,ah:36
     mov ax,0
     mov al,cl  ;����cl
     mov bl,10
     div bl
     add ax,3030h
     ret

readinfo:       ;��ʾ��ǰ�����ĸ��������ĸ���ͷ���ĸ�����
     mov si,cylind
     call  printstr
     mov si,header
     call  printstr
     mov si,sector
     call  printstr
     ret



read1sector:                      ;��ȡһ��������ͨ�ó������������� sector header  cylind����

       mov   cl, [sector+11]      ;Ϊ����ʵʱ��ʾ����������λ��
       call  numtoascii
       mov   [sector+7],al
       mov   [sector+8],ah

       mov   cl,[header+11]
       call  numtoascii
       mov   [header+7],al
       mov   [header+8],ah

       mov   cl,[cylind+11]
       call  numtoascii
       mov   [cylind+7],al
       mov   [cylind+8],ah

       MOV        CH,[cylind+11]    ; �����0��ʼ��
       MOV        DH,[header+11]    ; ��ͷ��0��ʼ��
       mov        cl,[sector+11]    ; ������1��ʼ��

        call       readinfo        ;��ʾ���̶���������λ��
        mov        di,0
retry:
        MOV        AH,02H            ; AH=0x02 : AH����Ϊ0x02��ʾ��ȡ����
        MOV        AL,1            ; Ҫ��ȡ��������
        mov        BX,    0         ; ES:BX��ʾ�����ڴ�ĵ�ַ 0x0800*16 + 0 = 0x8000
        MOV        DL,00H           ; �������ţ�0��ʾ��һ�����̣��ǵģ����̡���Ӳ��C:80H C Ӳ��D:81H
        INT        13H               ; ����BIOS 13���жϣ�������ع���
        JNC        READOK           ; δ��������ת��READOK������Ļ����ʹEFLAGS�Ĵ�����CFλ��1
           inc     di
           MOV     AH,0x00
           MOV     DL,0x00         ; A������
           INT     0x13            ; ����������
           cmp     di, 5           ; ���̺ܴ�����ͬһ��������ض�5�ζ�ʧ�ܾͷ���
           jne     retry

           mov     si, Fyerror
           call    printstr
           call    newline
           jmp     exitread
READOK:    mov     si, FloppyOK
           call    printstr
           call    newline
exitread:
           ret


printstr:                  ;��ʾָ�����ַ���, ��'$'Ϊ�������
      mov al,[si]
      cmp al,'$'
      je disover
      mov ah,0eh
      int 10h
      inc si
      jmp printstr
disover:
      ret


newline:                     ;��ʾ�س�����
      mov ah,0eh
      mov al,0dh
      int 10h
      mov al,0ah
      int 10h
      ret



times 510-($-$$) db 0
                 db 0x55,0xaa

;-------------------------------------------------------------------------------
;------------------��Ϊ�����ֽ��ߣ�����Ϊ��1����������Ϊ��2����-----------------
;-------------------------------------------------------------------------------
jmp    kernal

rdataseg         equ    1000h         ;��Ӳ�̶�ȡ�������ݴ�Ŷε�ַ 20000h     
wdataseg         equ    2000h         ;д��Ӳ�̵����ݴ�Ŷε�ַ 800hΪ�ں˳���ε�ַ,Ҳ��8000h�� 

hdNUMsector      EQU   1      ; ���ö�ȡ����Ӳ������������    ���:191
hdNUMheader      EQU   1      ; ���ö�ȡ����Ӳ������ͷ���  ���:255 
hdNUMcylind      EQU   0       ; ���ö�ȡ����Ӳ��������  ���:198 

whdNUMsector      EQU    2        ; ����д��Ӳ�̵�����������
whdNUMheader      EQU    0        ; ����д��Ӳ�̵�����ͷ���
whdNUMcylind      EQU    0        ; ����д��Ӳ�̵�������

keralmsg   db 'Now You Have Comed Kernal!','$'
addrmsg    db 'Kernal Data Begins Address:8000h','$'
hdpara     db 'Now Hdisk Paras Read:','$'
hdwrite    db 'Now Hdisk Write Files:','$'
hdread     db 'Now Hdisk Read Files:','$'



pahdcylind  db 'cylind:?? $',0    ; Ӳ�̵��������  0-6����10bit��ֻȡ��8bit�������顣 
pahdheader  db 'header:?? $',0    ; Ӳ�̵Ĵ�ͷ����  0-63
pahdsector  db 'sector:?? $',0    ; Ӳ�̵���������  1-63
pahdOK      db '---Hdisk Paras Read OK','$'
pahderror   db '---Hdisk Paras Read Error' ,'$'



hdcylind  db 'cylind:?? $',0    ; ���ÿ�ʼ��ȡ��������
hdheader  db 'header:?? $',0    ; ���ÿ�ʼ��ȡ�Ĵ�ͷ���
hdsector  db 'sector:?? $',1    ; ���ÿ�ʼ��ȡ���������
hdOK      db '---Hdisk Read OK','$'
hderror   db '---Hdisk Read Error' ,'$'  
hdcontent db 'Hdisk Content is:' ,'$'

whdcylind  db 'cylind:?? $',0    ; ���ÿ�ʼд��������
whdheader  db 'header:?? $',0    ; ���ÿ�ʼд�Ĵ�ͷ���
whdsector  db 'sector:?? $',1    ; ���ÿ�ʼд���������
whdOK      db '---Hdisk Write OK','$'
whderror   db '---Hdisk Write Error' ,'$'

syscome    db '------------------------------------------------------',13,10,\
                       'Now You Have Comed zzcOS File System,Enjoy Youself!' ,13,10,\
           '------------------------------------------------------','$'
pwdinfo     db 'C:\>','$'
cdcom        db 'cd'
dircom       db 'dir'
clscom       db 'cls'
formatcom    db 'format'
mkdircom    db 'mkdir'              ;'deldir dir1????...'
deldircom    db 'deldir'   
inputcom    db '?????????????????'  ;'mkdir dir1????...' 
yescommsg    db 'True  Command','$'
nocommsg    db 'Bad   Command','$'
direrror    db 'Not Empty Directory,No Permited Delelte','$'
formatmsg   db 'Now Format Done,All Datas Lost!','$'

delname   db '????????'
bootname   db '/???????'
upname     db '..??????'
cdname     db '????????','$'       ;Ŀ¼�����8BIT
dirname    db '????????','$'       ;Ŀ¼�����8BIT 
filename  db '????????'

parentidmsg   db 'parentid:??','$'
diridmsg      db 'deldirid:??','$'

parentid   db -1 
dirid      db 0

deldirid   db 0
subdirid   db 0


kernal:     mov     ax,loaderseg     ;��ת���ں�֮��ȫ���Ĵ��������µĶε�ַ
                                     ;ES=CS=800H
            mov     es,ax              
            
            mov     ax,loaderseg
            sub     ax,20h
            mov     ds,ax            ;DS=800H-20H�ı�ε�ַ֮����Ҫ��ȥ����������ƫ����
                 
            mov     si, keralmsg  
            call    newline2
           call    printstr2
            call    newline2
           mov     si, addrmsg   
           call    printstr2
            call    newline2
            call    newline2

filesystem: call    newline2
            mov     si, pwdinfo
            call    printstr2
            
            mov     si, 0
usrinput: 
           mov ah,0
           int 16h                        ;�Ӽ��̶��ַ� ah=ɨ���� al=�ַ���
           mov ah,0eh                     ;�Ѽ���������ַ���ʾ���� 
           int 10h
           cmp    al, 0dh                 ;�س���Ϊ����������
           je     inputover
           mov    [inputcom+si],al
           inc    si
           jmp    usrinput

inputover: call   commanddeal 


           
           jmp    filesystem


showcsseg:   call     newline2
             mov  dx, cs
             mov al,dh
             add al,30h
             mov ah,0eh
             int 10h
             mov al,dl
             add al,30h
             mov ah,0eh
             int 10h
             call     newline2
             ret
             
      
commanddeal: 
           mov    si,0
           mov    cx,dircom-cdcom
nextcom3char:mov   ah, [cdcom+si]
           mov    al, [inputcom+si]
           cmp    ah, al
           jne    nextcom3
           inc    si
           loop   nextcom3char
           jmp    cd                    ;�������cd����
           
nextcom3:           mov    si,0
           mov    cx,clscom-dircom
nextcom2char:mov   ah, [dircom+si]
           mov    al, [inputcom+si]
           cmp    ah, al
           jne    nextcom2
           inc    si
           loop   nextcom2char
           jmp    dir                    ;������� dir����

nextcom2:           mov    si,0
           mov    cx,formatcom-clscom
nextcom1char:mov   ah, [clscom+si]
           mov    al, [inputcom+si]
           cmp    ah, al
           jne    nextcom1
           inc    si
           loop   nextcom1char
           jmp    cls                    ;������� cls����
         
nextcom1:  mov    si,0
           mov    cx,mkdircom-formatcom
nextcomchar:mov    ah, [formatcom+si]
           mov    al, [inputcom+si]
           cmp    ah, al
           jne    nextcom 
           inc    si
           loop   nextcomchar 
           jmp    format                  ;������� format����   
                  
nextcom:   mov    si,0
           mov    cx,deldircom-mkdircom     
nextcomch: mov    ah, [mkdircom+si]
           mov    al, [inputcom+si]
           cmp    ah, al
           jne    nextcom4  
           inc    si
           loop   nextcomch
           jmp    makedir                  ;�������mkdir����  
           
          
nextcom4:   mov    si,0
           mov    cx,inputcom-deldircom
nextcomch4: mov    ah, [deldircom+si]
           mov    al, [inputcom+si]
           cmp    ah, al
           jne    badcom
           inc    si
           loop   nextcomch4
           jmp    deldir                  ;�������deldir����           
           
            
cd:      
             call    cddeal
             jmp     comdealover

dir:     
             call    dirdeal
             jmp     comdealover
 
cls:       

             call    clsdeal
             jmp     comdealover             
format:    
             
             call    formatdeal 
             jmp     comdealover 
             
makedir:   
             call    makedirdeal                                    
             jmp     comdealover
             
deldir:     
             call    deldirdeal
             jmp     comdealover
             
badcom:      call    newline2      ;��������ķǷ����� 
             mov     si, nocommsg
             call    printstr2
             call    newline2

comdealover: mov    si,0                  ;��������֮������û���������Ļ���������
             mov    cx,yescommsg-inputcom
nextinputcom:mov    byte [inputcom+si],'?'
             inc    si
             loop   nextinputcom 
             
             mov    si,0                  ;��������֮������û�����dir����Ŀ���ļ��еĻ���������
             mov    cx,dirname-cdname
             dec    cx                    ;����һλ'$' 
nextinputcom2:mov    byte [cdname+si],'?'
             inc    si
             loop   nextinputcom2
             
             mov    si,0                  ;��������֮������û�����cd������ļ��еĻ���������
             mov    cx,filename-dirname
             dec    cx                     ;����һλ'$'
nextinputcom3:mov    byte [dirname+si],'?'
             inc    si
             loop   nextinputcom3 
             ret
             
             mov    si,0                  ;��������֮������û�����deldir������ļ��еĻ���������
             mov    cx,bootname-delname
             dec    cx                     ;����һλ'$'
nextinputcom4:mov    byte [delname+si],'?'
             inc    si
             loop   nextinputcom4
             ret


cddeal:      call    getcdname    ;�����û������ȡĿ¼�ļ���cdname�������뻺����
             ;mov     si, cdname
             ;call    printstr2
             ;call    newline2    
             
             mov    si,0
             mov    cx,8
goonboot:    mov    dh, [cdname+si]    ;�û�����
             cmp    [bootname+si],dh     ;��׼����
             jne    cdcomnext1
             inc    si
             loop   goonboot
             mov    byte [parentid],-1 ;�û��������:cd /
             call    dirdeal           ;cd��Ŀ��Ŀ¼����Ҫ��ʾ��Ŀ¼
            
             jmp    cddealover

cdcomnext1:      mov    si,0
              mov    cx,8
 goonup:     mov    dh, [cdname+si]    ;�û�����
             cmp    [upname+si],dh       ;��׼����
             jne    cdcomnext2
             inc    si
             loop   goonup
             call   cdupcomdeal         ;�û��������:cd ..
             call    dirdeal            ;cd��Ŀ��Ŀ¼����Ҫ��ʾ��Ŀ¼
             jmp     cddealover       
             
cdcomnext2:  call    commoncddeal  ;�û����������ͨ:cd dir1;����Ŀ¼�������Ŀ��Ŀ¼��newparentid 
             call    dirdeal       ;cd��Ŀ��Ŀ¼����Ҫ��ʾ��Ŀ¼
             
cddealover:   ret

             
cdupcomdeal:    call    readdirdata

                mov     si,0
 cdupcom :      ;cmp     byte [es:si+1],'?'   ;����������־
                cmp     si,2000
                je      cdupcomdealover
                mov     dh,[parentid]
                cmp     byte [es:si], dh     ;�ҳ�Ŀ¼����dirid=��ǰparentid��Ŀ¼ 
                jne     cdupcomnext
                mov     dh,  [es:si+1]
                mov     [parentid], dh       ;���ҵ�Ŀ¼��parentid��ֵ����ǰparentid 
                jmp     cdupcomdealover      ;һ���ҵ��ϲ�Ŀ¼�ͽ��� 
    cdupcomnext:add     si,10
                jmp     cdupcom
 cdupcomdealover:
                ret 
             ret  
                           

getcdname:   mov     di,0
             mov     si,  2    ;                 cd��׼����ĳ���
cdnamenext:mov     al,  [inputcom+si+1]
             cmp     al,  '?'                    ;�û������ļ����Ľ���λ��
             je      cdnameover
             mov     [cdname+di],al
             inc     si
             inc     di
             jmp     cdnamenext
   cdnameover:  ret
             

commoncddeal:                                  ;cd��ͨĿ¼ 
               call    readdirdata
               
                mov     si,0
 cdparentid:  cmp     si,2000  ;����������־
                je      cdparentidover
                mov     dh,[parentid]
                cmp     byte [es:si+1], dh     ;�ҳ�Ŀ¼����ƥ�䵱ǰparentid��Ŀ¼ 
                jne     cdnextparentid
                call    ifdestdir
cdnextparentid: add     si,10
                jmp     cdparentid
 cdparentidover: 
                ret

ifdestdir: mov    di,si
           mov    cx,8 
           mov    bx,0
destdir:   mov    ah, [cdname+bx]     ;�û������Ŀ��Ŀ¼ 
           mov    al, [es:di+2]      ;Ӳ����Ŀ¼����Ŀ¼
           cmp    ah, al
           jne    destdirover
            inc    di
            inc    bx
            loop   destdir
            mov    dh,[es:si]          ;�û�cd��Ŀ¼��Ŀ��Ŀ¼��ȫƥ�� 
            mov    [parentid],dh       ;��dirid��ֵ����parentid,���cdĿ¼�л�
            ;call   showparentid
destdirover: ret 


showparentid:
       mov   cl, [parentid]      ;Ϊ����ʵʱ��ʾparentid
       call  numtoascii2
       mov   [parentidmsg+9],al
       mov   [parentidmsg+10],ah 
       call     newline2
       mov   si,  parentidmsg
       call    printstr2 
       call     newline2
       ret
       

readdirdata:                               ;��ȡĿ¼���ݽṹ�����ݣ��ڵ�12-15����
               mov byte [hdsector+11],12  ;Ŀ¼���ݽṹ���ڵ�12-15����
                mov byte [hdheader+11],0
                mov byte [hdcylind+11],0
                mov     ax,rdataseg
                mov     es,ax
dirhdiskread:
                call    read1sector2        ;��Ŀ¼������������ȫ��������
                MOV     AX,ES
                ADD     AX,0x0020
                MOV     ES,AX                ;һ������ռ512B=200H���պ��ܱ������������Ķ�,���ֻ��ı�ESֵ������ı�BP���ɡ�
                inc   byte [hdsector+11]
                cmp   byte [hdsector+11],16
                jne   dirhdiskread

                mov     ax,rdataseg
                mov     es,ax
                ;call     newline2
                ;call     showdata2
                ;call     newline2                                
                ret 
                
                                            
dirdeal:        call    readdirdata

                mov     si,0
 goonparentid:  cmp     si,2000   ;����������־
                je      parentidover      
                mov     dh,[parentid]
                cmp     byte [es:si+1], dh
                jne     nextparentid
                call    showdirname 
nextparentid:   add     si,10 
                jmp     goonparentid
 parentidover:  ret
               
showdirname:    call    newline2
                mov  di, si
 nextdirname:   mov al,[es:di+2]   ;��ʾĿ¼����, ��'?'Ϊ�������
                cmp al,'?'    
                je showdirnameover
                mov ah,0eh
                int 10h
                inc di
                jmp  nextdirname
 showdirnameover:;call    newline2
                 ret  
                              
 
clsdeal:                    ;����
             mov ah,00h
             mov al,03h  ;80*25��׼��ɫ�ı�
             int 10h
             ret     


getdelname:  mov     di,0
             mov     si,  inputcom-deldircom    ; �ų��� mkdir��׼����ĳ���
delnamenextc:mov     al,  [inputcom+si+1]
             cmp     al,  '?'                    ;�û������ļ����Ľ���λ��
             je      getdelnameover
             mov     [delname+di],al
             inc     si
             inc     di
             jmp     delnamenextc
   getdelnameover:  ret
            
deldirdeal:  call    getdelname    ;�����û������ȡĿ¼�ļ���dirname�������뻺����
             ;mov     si, dirname
             ;call    printstr2
             ;call    newline2
             call    deldestdir   ;ɾ��Ŀ��Ŀ¼ 
             ret
             
 
 deldestdir:    call   posdeldir        ;��λĿ��Ŀ¼������Ϊdeldirid 

               call    readdirdata  
               mov     si,0
 godeldestdir:                         ;����Ҫ�ж��Ƿ��Ŀ¼ִ��ɾ������   
                cmp     si,2000              ;����������־
                je      deldestdirall
                mov     dh,[deldirid]
                cmp     byte [es:si+1], dh     ;�ҳ�Ŀ¼����ƥ�䵱ǰparentid��Ŀ¼Ϊ��Ŀ¼ 
                je      notemptydir            ;һ����������Ŀ¼        
                add     si,10
                jmp     godeldestdir
              
notemptydir: ;call    newline2   
             mov     si,direrror  
             call    printstr2
             call    newline2   
             jmp     deldestdirover
                         
deldestdirall:  call    deldestdirdeal      ;������˵���ǿ�Ŀ¼������ִ��ɾ������ 
deldestdirover: ret
                

deldestdirdeal: 
               mov    ah,0
               mov    al,[deldirid] 
               call   delonedirdata    ;ɾ��һ��Ŀ¼,��alΪĿ¼ID���� 
               
               mov    ah,0
               mov    al,[deldirid]
               call   delonedirno      ;���һ��Ŀ¼���ռ�ñ�ǣ���alΪĿ¼ID����
               ;call    showdeldirid
               ret
               
              
delonedirno: push   ax               ;�Ѳ�����������    
             
             mov  byte [hdsector+11],1   ;��Ŀ¼�ļ�������Ϣ��������1��������ȡĿ¼���ռ�ñ��
             mov  byte [hdheader+11],0
             mov  byte [hdcylind+11],0

             mov     ax,rdataseg       ;8000��ʼ��ų���,10000��ʼ���Ӳ�̶���������
             mov     es,ax
             call    read1sector2

             ;call     newline2
             ;call     numshow2
             ;call     newline2

             ;mov   ah,0
             ;mov   al,[deldirid]        ;Ҫɾ����Ŀ¼��� 
             pop   ax                ;�ѵ��ô˺����Ĳ��������� 
             mov   bl,8
             div   bl                ;����Ŀ¼���Ϊ1��1/8,��al=0,����ah=1

               mov   ch,0
               mov   cl,ah         ;��������λĿ¼���diռ�ñ�����ֽ��ڵ�λ��
               inc   cl
               mov   dl,0111_1111b
               rol   dl,cl          ;ѭ����������+1��,��0�Ƶ�����Ҫ��λ�� 
               mov   bh,0
               mov   bl, al          ;���̶�λĿ¼���idռ�ñ�����ڵ��ֽڷ���BX
               and   byte [es:bx],dl  ;����ռ�ñ��1bit  �൱����0 

              mov byte [whdsector+11],1  ;��Ŀ¼�ļ�������Ϣ��������1������дĿ¼���ռ�ñ��
              mov byte [whdheader+11],0
              mov byte [whdcylind+11],0

              mov     ax,rdataseg       ;����ǰ��������������д��ȥ��ֻ��1���ֽڵ������1 bit�и��£�
              mov     es,ax
              call    write1sector2
              
              mov     byte [dirid],0         ;�������dirid��0��Ϊ������Ŀ¼����mkdir����׼���� 

             ; call    read1sector2
             ; call     newline2
             ; call     numshow2
             ; call     newline2
             ; call     newline2
              ret

delonedirdata:  
             ;mov   ah,0
             ;mov   al,[deldirid]     ;Ҫɾ����Ŀ¼���
             mov   bl,50             ;Ŀ¼���/50�������ҵ�Ŀ¼�����������
             div   bl                ;����Ŀ¼���Ϊ1��1/50,��al=0,����ah=1

             push  ax                ;�Ѷ�λ���ݱ������� ,��al=0,����ah=1
             push  ax
             push  ax

             add  al, 12             ;alΪĿ¼����������� 12ΪĿ¼��Ŵ���������������
             mov  byte [hdsector+11],al   ;
             mov  byte [hdheader+11],0
             mov  byte [hdcylind+11],0

             mov     ax,rdataseg       ;8000��ʼ��ų���,10000��ʼ���Ӳ�̶���������
             mov     es,ax
             call    read1sector2

             pop   ax                  ;Ŀ¼���/50��������*10���ҵ�Ŀ¼���������ڵ�ƫ��λ��

             mov   al,ah               ;ahΪ����
             mov   ah,0
             mov   bl,10
             mul   bl
             
             mov   bx, ax
             mov   cx, 10             ;һ��Ŀ¼10B 
delonedir:   mov  byte [es:bx], '?'   ;��Ӳ�������Ŀ¼������������ 
             inc  bx
             loop delonedir

writedeldir:

             pop  ax
             add  al, 12             ;alΪĿ¼�����������   12ΪĿ¼��Ŵ�����������

              mov byte [whdsector+11],al  ;��Ŀ¼�����������дĿ¼�������
              mov byte [whdheader+11],0
              mov byte [whdcylind+11],0

            mov     ax,rdataseg       ;����ǰ��������������д��ȥ��ֻ��10���ֽ��и��£�
            mov     es,ax
            call    write1sector2


             pop  ax
             add  al, 12             ;alΪĿ¼�����������   12ΪĿ¼��Ŵ�����������
             mov  byte [hdsector+11],al   ;��Ӳ�̶���Ŀ¼�����������      ��֤����
             mov  byte [hdheader+11],0
             mov  byte [hdcylind+11],0
              ;call    read1sector2
              ;call     newline2
              ;call     showdata2
              ;call     newline2
            ret
            
            
posdeldir: 
              call    readdirdata
              mov     si,0
 goposdeldir:  ;cmp     byte [es:si+1],'?'
                cmp     si,2000  ;����������־
                je      posdeldirover
                mov     dh,[parentid]
                cmp     byte [es:si+1], dh     ;�ҳ�Ŀ¼����ƥ�䵱ǰparentid��Ŀ¼
                jne     posdeldirnext
                call    ifdeldestdir
posdeldirnext: add     si,10
                jmp     goposdeldir
posdeldirover:
                ret

ifdeldestdir: 
           mov    di,si
           mov    cx,8
           mov    bx,0
goifdeldest:   mov    ah, [delname+bx]     ;�û������Ŀ��Ŀ¼
           mov    al, [es:di+2]      ;Ӳ����Ŀ¼����Ŀ¼
           cmp    ah, al
           jne    ifdeldestover
            inc    di
            inc    bx
            loop   goifdeldest
            mov    dh,  [es:si]
            mov    [deldirid],dh        ;�ҵ�Ҫɾ��Ŀ¼��dirid,�ȱ������� 
ifdeldestover:  
            ret     
             

showdeldirid:
       mov   cl, [deldirid]      
       call  numtoascii2
       mov   [diridmsg+9],al
       mov   [diridmsg+10],ah 
       call     newline2
       mov   si,  diridmsg
       call    printstr2 
       call     newline2
       ret             
                            
        
makedirdeal: call    getdirname    ;�����û������ȡĿ¼�ļ���dirname�������뻺����
             ;mov     si, dirname
             ;call    printstr2
             ;call    newline2
             
             call    newdirid     ;����Ŀ¼���ռ�ñ��,ȷ����Ŀ¼���dirid,������Ŀ¼ռ�ñ��
             call    writedir     ;���½�Ŀ¼д��Ŀ¼���ݽṹ 
             
             ;call    showparentid
             ret                                 

writedir:    mov   ah,0
             mov   al,[dirid]        ;Ŀ¼���
             mov   bl,50             ;Ŀ¼���/50�������ҵ�Ŀ¼����������� 
             div   bl                ;����Ŀ¼���Ϊ1��1/50,��al=0,����ah=1

             push  ax                ;�Ѷ�λ���ݱ������� ,��al=0,����ah=1
             push  ax
             push  ax

             add  al, 12             ;alΪĿ¼�����������   12ΪĿ¼��Ŵ����������� 
             mov  byte [hdsector+11],al   ;��Ӳ�̶���Ŀ¼�����������
             mov  byte [hdheader+11],0
             mov  byte [hdcylind+11],0
             
             mov     ax,rdataseg       ;8000��ʼ��ų���,10000��ʼ���Ӳ�̶���������
             mov     es,ax
             call    read1sector2
             
             pop   ax                  ;Ŀ¼���/50��������*10���ҵ�Ŀ¼���������ڵ�ƫ��λ��     
              
             mov   al,ah               ;ahΪ���� 
             mov   ah,0
             mov   bl,10
             mul   bl                  
             
             mov   bx, ax
             mov  dh, [dirid]
             mov  [es:bx], dh
             inc  bx
             mov  dh, [parentid]
             mov  [es:bx],dh
             
             inc  bx             
             mov  si,0
writedirname:
             mov dl,[dirname+si]    ;дĿ¼�� 
             cmp dl,'?'
             je overwritedir 
             mov [es:bx],dl
             inc si
             inc bx
             jmp writedirname
              
overwritedir:

             pop  ax 
             add  al, 12             ;alΪĿ¼�����������   12ΪĿ¼��Ŵ�����������
            
              mov byte [whdsector+11],al  ;��Ŀ¼�����������дĿ¼������� 
              mov byte [whdheader+11],0
              mov byte [whdcylind+11],0
            
            mov     ax,rdataseg       ;����ǰ��������������д��ȥ��ֻ��10���ֽ��и��£�
            mov     es,ax
            call    write1sector2
            
            
             pop  ax
             add  al, 12             ;alΪĿ¼�����������   12ΪĿ¼��Ŵ�����������
             mov  byte [hdsector+11],al   ;��Ӳ�̶���Ŀ¼�����������      ��֤���� 
             mov  byte [hdheader+11],0
             mov  byte [hdcylind+11],0
            
              ;call    read1sector2
             ; call     newline2
              ;call     showdata2
              ;call     newline2
           
            ret 
                          
             
newdirid:    
             mov  byte [hdsector+11],1   ;��Ŀ¼�ļ�������Ϣ��������1��������ȡĿ¼���ռ�ñ��
             mov  byte [hdheader+11],0
             mov  byte [hdcylind+11],0
        
             mov     ax,rdataseg       ;8000��ʼ��ų���,10000��ʼ���Ӳ�̶���������
             mov     es,ax
             call    read1sector2  
             
             ;call     newline2
             ;call     numshow2
             ;call     newline2
                              
nextdirno:   
             mov   ah,0
             mov   al,[dirid]        ;��ʼĿ¼���
             mov   bl,8
             div   bl                ;����Ŀ¼���Ϊ1��1/8,��al=0,����ah=1 
             
             push  ax                ;�Ѷ�λ���ݱ������� ,��al=0,����ah=1  
             
             mov   bh,0
             mov   bl, al           ;�����̶�λĿ¼���idռ�ñ�����ڵ��ֽڷ���BX
             mov   dh,[es:bx]       
             
             mov   ch,0           
             mov   cl,ah         ;����������λĿ¼���diռ�ñ�����ֽ��ڵ�λ��
             inc   cl            ;��������+1��
             shr   dh,cl          ;����1λ��0λ���Ƶ�CF
             jnc   nozhan
             inc   byte [dirid]    ;ռ��������һ��Ŀ¼��� 
             pop   ax             ;ͬʱ��ҪPOP��AX����Ϊ�ڵ�ǰdirid�Ѿ���ռ�õ�����£�������߲���POP���
;��POP�����PUSH�������ɶ�ʹ�ã����������һ����Чִ�С�����Ϊ�������д�����������ҷɣ������ҵ�����2��ʱ�䣡 
             jmp   nextdirno      ;ע��������һ����ѭ����ֱ���ҵ�һ��δռ�õ�Ŀ¼���Ϊֹ  
            
 nozhan:     mov al,[dirid]        ;ת����ASCII����ʾ�����֤
            ; add al,30h
             ;mov ah,0eh
            ; int 10h
              ;call     newline2
                                   ;��Ҫ���µ�Ŀ¼���ռ�ñ�Ǵ��ռ��
              pop   ax             ;��ԭ��λ���� 
                    
               mov   ch,0                         
               mov   cl,ah         ;����������λĿ¼���diռ�ñ�����ֽ��ڵ�λ��
               inc   cl
               mov   dl,1000_0000b
               rol   dl,cl          ;ѭ����������+1��,��1�Ƶ�����Ҫ��λ�� 
               mov   bh,0
               mov   bl, al          ;�̶�λĿ¼���diռ�ñ�����ڵ��ֽ�
               or    byte [es:bx],dl           ;����ռ�ñ��1bit

              mov byte [whdsector+11],1  ;��Ŀ¼�ļ�������Ϣ��������1������дĿ¼���ռ�ñ��
              mov byte [whdheader+11],0
              mov byte [whdcylind+11],0

              mov     ax,rdataseg       ;����ǰ��������������д��ȥ��ֻ��1���ֽڵ������1 bit�и��£� 
              mov     es,ax
              call    write1sector2   
              
              ;call    read1sector2
              ;call     newline2
              ;call     numshow2
              ;call     newline2             
              ;call     newline2
                  
              ret  
          
                        
numshow2:
           mov  si,0              ;��֤��ʾ�����̶�ȡ���ڴ������
           mov  cx,80             ;������������ݳ���
numnext2:  mov al,[es:si]
           add al,30h             ;ת����ASCII�����
           mov ah,0eh
           int 10h
           inc si
           loop numnext2
           ret     
          
          
                
getdirname:  mov     di,0
             mov     si,  deldircom- mkdircom    ; �ų��� mkdir��׼����ĳ��� 
namenextchar:mov     al,  [inputcom+si+1]
             cmp     al,  '?'                    ;�û������ļ����Ľ���λ�� 
             je      dirnameover
             mov     [dirname+di],al
             inc     si
             inc     di
             jmp     namenextchar
   dirnameover:  ret

        
formatdeal:  call    controlclear         ;Ŀ¼�ļ�������Ϣ���ݽṹ����0 
             call    sectorbusycl         ;����ռ�ñ����������0
             call    dirstrclear          ;Ŀ¼���ݽṹ��������0
             call    filestrclear         ;�ļ����ݽṹ��������0
             
             call    newline2
             mov     si, formatmsg
             call    printstr2
             call    newline2
                                
             ret      
             
             
controlclear: mov byte [whdsector+11],1  ;Ŀ¼�ļ�������Ϣ���ݽṹ���ڵ�1����
              mov byte [whdheader+11],0
              mov byte [whdcylind+11],0      
              
             mov     ax,wdataseg       ;8000��ʼ��ų���,10000��ʼ���ҪдӲ�̵�����
             mov     es,ax
             call    writereadydata    ; 1��������д����֮ǰ����Ҫ���ڴ�es:bx�ĵط���׼��������
             call    write1sector2     ;д1��������ȫд0
              
             ;call    numshow2          ;��ʾ�������ݣ�ԭʼ����Ϊ���ַ�ASCII�룩
             ;call    newline2
             ret
             
sectorbusycl:   mov byte [whdsector+11],2  ;Ŀ¼�ļ�������Ϣ���ݽṹ���ڵ�2-11����
                mov byte [whdheader+11],0
                mov byte [whdcylind+11],0
                
                
                mov     ax,wdataseg       ;8000��ʼ��ų���,10000��ʼ���ҪдӲ�̵�����
                mov     es,ax
  w10sectors:   call    writereadydata    ;ÿ��������д����֮ǰ����Ҫ���ڴ�es:bx�ĵط���׼�������� 
                call    write1sector2
                inc     byte [whdsector+11] 
                cmp     byte [whdsector+11],12
                jne     w10sectors
                ;call    numshow2          ;��ʾ�������ݣ�ԭʼ����Ϊ���ַ�ASCII�룩
                ;call    newline2
                ret  

dirstrclear:    mov byte [whdsector+11],12  ;Ŀ¼���ݽṹ���ڵ�12-15����
                mov byte [whdheader+11],0
                mov byte [whdcylind+11],0
                
                 mov     ax,wdataseg       ;8000��ʼ��ų���,10000��ʼ���ҪдӲ�̵�����
              mov     es,ax
f10sectors: call    writereadydata?    ; 1��������д����֮ǰ����Ҫ���ڴ�es:bx�ĵط���׼��������
             call    write1sector2     ;д1��������ȫд0

                inc     byte [whdsector+11]
                cmp     byte [whdsector+11],16
                jne     f10sectors
                ;call    showdata2          ;��ʾ�������ݣ�ԭʼ����Ϊ���ַ�ASCII�룩
                ;call    newline2            
             ret

filestrclear:
                mov byte [whdsector+11],16  ;Ŀ¼�ļ�������Ϣ���ݽṹ���ڵ�16-25����
                mov byte [whdheader+11],0
                mov byte [whdcylind+11],0
                mov     ax,wdataseg       ;8000��ʼ��ų���,10000��ʼ���ҪдӲ�̵�����
                mov     es,ax
  file10sectors: call    writereadydata    ;ÿ��������д����֮ǰ����Ҫ���ڴ�es:bx�ĵط���׼��������
                call    write1sector2
                inc     byte [whdsector+11]
                cmp     byte [whdsector+11],26
                jne     file10sectors
                ;call    numshow2          ;��ʾ�������ݣ�ԭʼ����Ϊ���ַ�ASCII�룩
                ;call    newline2
                ret                        
        
        
readhdpara:                         ;��ȡӲ�̵�����������ͷ�����������Ȳ���
        mov        di,0
paretry:
        MOV        AH,08H             
        MOV        DL,80H           ; �������ţ�0��ʾ��һ�����̣��ǵģ����̡���Ӳ��C:80H C Ӳ��D:81H
        INT        13H                                        
        JNC        paREADOK           ; δ��������ת��READOK������Ļ����ʹEFLAGS�Ĵ�����CFλ��1
           inc     di
           MOV     AH,0x00
           MOV     DL,0x80         ; A������
           INT     0x13            ; ����������
           cmp     di, 5           ; ���̺ܴ�����ͬһ��������ض�5�ζ�ʧ�ܾͷ���
           jne     paretry
           mov     si, pahderror
           call    printstr2
           call    newline2
           jmp     paexitread
paREADOK: mov     si, pahdOK
           call    printstr2
           call    newline2
                                             ;����Ϊ��ʾ�������Ĵ��̲���
       and   cl, 00111111b
       mov   [pahdsector+11],cl              ;CL��λ5-0��������
       mov   cl, [pahdsector+11]        
       call  numtoascii2
       mov   [pahdsector+7],al
       mov   [pahdsector+8],ah
           
     mov   [pahdheader+11],dh     
       mov   cl,[pahdheader+11]        ;DH����ͷ��  DL����������
      call  numtoascii2
      mov   [pahdheader+7],al
      mov   [pahdheader+8],ah    
       
     mov  [pahdcylind+11],ch
     mov   cl,[pahdcylind+11]     ;CH���������ĵ�8λ CL��λ7-6���������ĸ�2λ,
      call  numtoascii2
      mov   [pahdcylind+7],al
     mov   [pahdcylind+8],ah
       
        call       pareadinfo        ;��ʾ������Ӳ�̲���
        
paexitread:  ret



pareadinfo:       ;��ʾ��ǰ�����ĸ��������ĸ���ͷ���ĸ�����
     mov si,pahdcylind
     call  printstr2
     mov si,pahdheader
     call  printstr2
     mov si,pahdsector
     call  printstr2
     ret
           

writereadydata:                         ;׼����д��Ӳ�̵�����
            MOV  bx,0
nextrebit:
            mov  byte [ES:BX],0         ;ȫ����ʼ����0 
            INC  bx
            cmp  bx,512
            jne  nextrebit
            ret
            
            
writereadydata?:                         ;׼����д��Ӳ�̵�����
            MOV  bx,0
nextrebit?:
            mov  byte [ES:BX],'?'         ;ȫ����ʼ����'?'
            INC  bx
            cmp  bx,512
            jne  nextrebit?
            ret



writetestdata:                      ;����д��Ӳ�̵����� 
            MOV  bx,0
nextbit:   
            mov  byte [ES:BX],'T'
            INC  bx
            cmp  bx,512
            jne  nextbit 
            
            mov  ax,es
            add  ax,20h
            mov  es,ax
            mov  bx,0
nextbit2 :  mov  byte [ES:BX],'Y'
            inc  bx
            cmp  bx,512
            jne  nextbit2
            ret

                       
showdata2: 
           mov  si,0             ;��֤��ʾ�����̶�ȡ���ڴ������
           mov  cx,80             ;������������ݳ���
nextchar2:  mov al,[es:si]
           mov ah,0eh
           int 10h
           inc si
           loop nextchar2
          RET


hdiskwrite:
     call    write1sector2
     MOV     AX,ES
     ADD     AX,0x0020
     MOV     ES,AX                ;һ������ռ512B=200H���պ��ܱ������������Ķ�,���ֻ��ı�ESֵ������ı�BP���ɡ�
     inc   byte [whdsector+11]
     cmp   byte [whdsector+11],whdNUMsector+1
     jne   hdiskwrite             ;д��һ������
     mov   byte [whdsector+11],1
     inc   byte [whdheader+11]
     cmp   byte [whdheader+11],whdNUMheader+1
     jne   hdiskwrite             ;д��һ����ͷ
     mov   byte [whdheader+11],0
     inc   byte [whdcylind+11]
     cmp   byte [whdcylind+11],whdNUMcylind+1
     jne   hdiskwrite             ;д��һ������

     ret



hdiskread:
     call    read1sector2
     MOV     AX,ES
     ADD     AX,0x0020
     MOV     ES,AX                ;һ������ռ512B=200H���պ��ܱ������������Ķ�,���ֻ��ı�ESֵ������ı�BP���ɡ�
     inc   byte [hdsector+11]
     cmp   byte [hdsector+11],hdNUMsector+1
     jne   hdiskread             ;����һ������
     mov   byte [hdsector+11],1
     inc   byte [hdheader+11]
     cmp   byte [hdheader+11],hdNUMheader+1
     jne   hdiskread             ;����һ����ͷ
     mov   byte [hdheader+11],0
     inc   byte [hdcylind+11]
     cmp   byte [hdcylind+11],hdNUMcylind+1
     jne   hdiskread             ;����һ������

     ret


newline2:                     ;��ʾ�س�����
      mov ah,0eh
      mov al,0dh
      int 10h
      mov al,0ah
      int 10h
      ret

printstr2:                  ;��ʾָ�����ַ���, ��'$'Ϊ�������
      mov al,[si]
      cmp al,'$'
      je disover2
      mov ah,0eh
      int 10h
      inc si
      jmp printstr2
disover2:
      ret


write1sector2:                           ;��ȡһ��������ͨ�ó������������� sector header  cylind����

       mov   cl, [whdsector+11]      ;Ϊ����ʵʱ��ʾ����������λ��
       call  numtoascii2
       mov   [whdsector+7],al
       mov   [whdsector+8],ah

       mov   cl,[whdheader+11]
       call  numtoascii2
       mov   [whdheader+7],al
       mov   [whdheader+8],ah

       mov   cl,[whdcylind+11]
       call  numtoascii2
       mov   [whdcylind+7],al
       mov   [whdcylind+8],ah

       MOV        CH,[whdcylind+11]    
       MOV        DH,[whdheader+11]    
       mov        cl,[whdsector+11]    

       ;call    writeinfo2        ;��ʾд��������λ��

        mov        di,0
wretry2:
        MOV        AH,03H            ; AH=0x03 : AH����Ϊ0x02��ʾд����
        MOV        AL,1            ; Ҫд��������
        mov        BX,    0         ; ES:BX��ʾȡ���ݴ��ڴ�ĵ�ַ 0x1000*16 + 0 = 0x10000
        MOV        DL,80H           ; �������ţ�0��ʾ��һ�����̣��ǵģ����̡���Ӳ��C:80H C Ӳ��D:81H
        INT        13H               ; ����BIOS 13���жϣ�������ع���
        JNC        writeOK2           ; δ��������ת��writeOK2������Ļ����ʹEFLAGS�Ĵ�����CFλ��1
           inc     di
           MOV     AH,0x00
           MOV     DL,0x80         ; A������
           INT     0x13            ; ����������
           cmp     di, 5           ; ���̺ܴ�����ͬһ��������ض�5�ζ�ʧ�ܾͷ���
           jne     wretry2

        
           mov     si, whderror
           call    printstr2
           call    newline2
           jmp     exitwrite2
writeOK2: 
           ;mov     si, whdOK
           ;call    printstr2
           call    newline2
           
exitwrite2:         
           
           ret




read1sector2:                           ;��ȡһ��������ͨ�ó������������� sector header  cylind����

       mov   cl, [hdsector+11]      ;Ϊ����ʵʱ��ʾ����������λ��
       call  numtoascii2
       mov   [hdsector+7],al
       mov   [hdsector+8],ah

       mov   cl,[hdheader+11]
       call  numtoascii2
       mov   [hdheader+7],al
       mov   [hdheader+8],ah

       mov   cl,[hdcylind+11]
       call  numtoascii2
       mov   [hdcylind+7],al
       mov   [hdcylind+8],ah

       MOV        CH,[hdcylind+11]    ; �����0��ʼ��
       MOV        DH,[hdheader+11]    ; ��ͷ��0��ʼ��
       mov        cl,[hdsector+11]    ; ������1��ʼ��   
       
        ;call       readinfo2        ;��ʾ���̶���������λ��
        
        mov        di,0
retry2:
        MOV        AH,02H            ; AH=0x02 : AH����Ϊ0x02��ʾ��ȡ����
        MOV        AL,1            ; Ҫ��ȡ��������
        mov        BX,    0         ; ES:BX��ʾ�����ڴ�ĵ�ַ 0x0800*16 + 0 = 0x8000
        MOV        DL,80H           ; �������ţ�0��ʾ��һ�����̣��ǵģ����̡���Ӳ��C:80H C Ӳ��D:81H
        INT        13H               ; ����BIOS 13���жϣ�������ع���
        JNC        READOK2           ; δ��������ת��READOK������Ļ����ʹEFLAGS�Ĵ�����CFλ��1
           inc     di
           MOV     AH,0x00
           MOV     DL,0x80         ; A������
           INT     0x13            ; ����������
           cmp     di, 5           ; ���̺ܴ�����ͬһ��������ض�5�ζ�ʧ�ܾͷ���
           jne     retry2

           mov     si, hderror
           call    printstr2
           call    newline2
           jmp     exitread2
READOK2:    ;mov     si, hdOK
           ;call    printstr2
           call    newline2
exitread2:
           ret
           
 
 
           
numtoascii2:     ;��2λ����10�������ֽ��ASII�����������ʾ��������56 �ֽ�ɳ���ascii: al:35,ah:36
     mov ax,0
     mov al,cl  ;����cl
     mov bl,10
     div bl
     add ax,3030h
     ret
     


writeinfo2:       ;��ʾ��ǰ�����ĸ��������ĸ���ͷ���ĸ�����
     mov si,whdcylind
     call  printstr2
     mov si,whdheader
     call  printstr2
     mov si,whdsector
     call  printstr2
     ret     
     
readinfo2:       ;��ʾ��ǰ�����ĸ��������ĸ���ͷ���ĸ�����
     mov si,hdcylind
     call  printstr2
     mov si,hdheader
     call  printstr2
     mov si,hdsector
     call  printstr2
     ret
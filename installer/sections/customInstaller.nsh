
; customInstaller script
; this allows to attach files to the spring-installer on the fly
;File Format is:
;
;<spring installer data>
;	<size of output filename1>
;		<output filename1>
;	<size of block1>
;		<block1>
;	<size of output filename2>
;		<output filename2>
;	<size of block2>
;		<block2>
;	[...]
;	<size of output filename = 0>
;SPRING<position of end of spring installer data>
;
;the files will be simple copied to the output filename (relative to the spring-installation dir)
;a simple validation could be sum over all read sizes validated with the installer size
;
;If the Download is incomplete, the tag couldn't be found -> appended data is ignored
; as note: it is implemented by calling msvcrt.dll functions, for better speed
; 	this file is always avaiable within windows, so it doesn't need to be shipped

!include LogicLib.nsh

!define readInt "!insertmacro readInt"
!macro readInt Handle
	Push ${Handle}
	Call readInt
!macroend

; reads 4 byte value as long
; parameter is file handle
; return is value on stack
Function readInt ; <handle>
; $0 contains file handle
	Push $0 ; store reg 0
	Exch
	Pop $0 ; get handle to r0

	Push $1 ; store r1-3, buf
	Push $2 ; result
	Push $3 ; address of int
	Push $4

	System::Alloc 4 ; creates a buffer of 4 bytes to store long
	Pop $1 ; set address to buf
	System::Call 'msvcrt.dll::_read(i r0, i r1, i 4) i .r2' ;read 4 bytes into buf
	System::Call "*$1(&i4.r3)" ; copy data from $1
	System::Free $1

	Push $3 ; store result

	Exch ;restore registers
	Pop $4
	Exch
	Pop $3
	Exch
	Pop $2
	Exch
	Pop $1
	Exch
	Pop $0
FunctionEnd

!define readSignature "!insertmacro readSignature"
 
!macro readSignature Handle
	Push ${Handle}
	Call readSignature
!macroend

;returns 1 in stack if signature is found, 0 if not
Function readSignature ; <handle> 

	Push $0 ; store reg 0
	Exch
	Pop $0 ; get handle to r0

	Push $1 ; store r1-3, buf
	Push $2 ; result
	Push $3 ; address of int

	System::Alloc 6 ; creates a buffer of 4 bytes to store long
	Pop $1 ; set address to buf
	System::Call 'msvcrt.dll::_read(i r0, i r1, i 6) i .r2' ;read 6 bytes into buf
	System::Call "*$1(&t6.r3)" ; copy data from $1
	System::Free $1
	StrCmp $3 "SPRING" 0 notfound
	Push 0
	goto signature_next
	notfound:
	Push 1
	signature_next:

	Exch
	Pop $3
	Exch
	Pop $2
	Exch
	Pop $1
	Exch
	Pop $0

FunctionEnd

!define getParent "!insertmacro getParent"
!macro getParent Path
	Push ${Path}
	Call getParent
!macroend

; getParent
; input, top of stack  (e.g. C:\Program Files\Spring\Path\somefile)
; output, top of stack (replaces, with e.g. C:\Program Files\Spring\Path)
; modifies no other variables.
Function getParent
 
  Exch $R0
  Push $R1
  Push $R2
  Push $R3
 
  StrCpy $R1 0
  StrLen $R2 $R0
 
  loop:
    IntOp $R1 $R1 + 1
    IntCmp $R1 $R2 get 0 get
    StrCpy $R3 $R0 1 -$R1
    StrCmp $R3 "\" get
  Goto loop
 
  get:
    StrCpy $R0 $R0 -$R1
 
    Pop $R3
    Pop $R2
    Pop $R1
    Exch $R0
 
FunctionEnd

!define storeFile "!insertmacro storeFile"
!macro storeFile Handle
	Push ${Handle}
	Call storeFile
!macroend


; returns 0 on success, 1 on failure (or last file)
; first reads length of filename
Function storeFile ; <handle>

	Push $0 ; store reg 0
	Exch

	Push $1 ; buf
	Push $2 ; result
	Push $3 ; address of int
	Push $4 ; length of filename
	Push $5 ; output filename
	Push $6 ; file length
	Push $7 ; filehandle #2
	Push $8 ; data written
	Push $9 ; bytes left


	${readInt} $0
	Pop $4 ;length of filename
	DetailPrint "Filename lenght $4"
	IntCmp $4 0 storeFile_error
	
	;FIXME: filename limit is 1024
	System::Alloc 1024 ; creates a buffer of 4 bytes to store long
	Pop $1 ; set address to buf
	System::Call 'msvcrt.dll::_read(i r0, i r1, i r4) i .r2' ;read n bytes into buf
	System::Call "*$1(&m1024.r5)" ; copy data from $1
	;$5 now contains filename
	DetailPrint "Filename: $5"

	${readInt} $0 ; read length of file into r6
	Pop $6 
	DetailPrint "Length of file: $6"

	${getParent} "$INSTDIR\$5"
	Pop $2
	${IfNot} ${FileExists} $2
	DetailPrint "Create Dir $2"
	CreateDirectory $2
	${EndIf}

	System::Call 'msvcrt.dll::_open(t "$INSTDIR\$5", i 0x8321) i .r7' ; open second file, mode create|trunc|binary
	DetailPrint "open $INSTDIR\$5:$7"
	IntCmp $7 0 0 storeFile_error

	Push 0 ; $8 = 0
	Pop $8
	Push 0 ; $4 = 0
	Pop $4

storeFile_repeat:
	IntOp $9 $6 - $4 ; calculate bytes left
	${If} $9 > 1024
		Push 1024
		Pop $3
	${Else}
		Push $9
		Pop $3
	${EndIf}
	
	System::Call 'msvcrt.dll::_read(i r0, i r1,i r3) i .r4' ;read the first file
    	System::Call 'msvcrt.dll::_write(i r7, i r1,i r4) i .r4' ;and writes to the second
	
	IntOp $8 $4 + $8
	
	IntCmp $8 0 0 storeFile_error ; finish on result <0
	IntCmp $8 $6 storeFile_finished 0 0 ; finish if all data is written
	IntCmp $4 0 storeFile_error
	goto storeFile_repeat



storeFile_error:
	Push 1
	goto storeFile_end

storeFile_finished:
	Push 0

storeFile_end:
    	System::Call 'msvcrt.dll::_close(i r7, i r2,i r4) i .r4' 
	System::Free $1

	Exch
	Pop $9
	Exch
	Pop $8
	Exch
	Pop $7
	Exch
	Pop $6
	Exch
	Pop $5
	Exch
	Pop $4
	Exch
	Pop $3
	Exch
	Pop $3
	Exch
	Pop $2
	Exch
	Pop $1
	Exch
	Pop $0

FunctionEnd


Section "-CustomData" SEC_GAMEANDMAPS
	;Reads last bytes from installer, checks if it is SPRING<START>
	;then seeks to <START> and reads <LENGTH><DATA> 

;signature found, read offset where ini files start
;r0 = source file handle
;r1 = tmp
;r2 = start address / offset
;r3 = result

	System::Store "r1" $EXEPATH ; load address of exepath into register
	System::Call 'msvcrt.dll::_open(t r1,  i 0x8000) i .r0' ; open installer file
	DetailPrint "open $1 returned: $0";
	
	System::Call 'msvcrt.dll::_lseek(i r0, i -10, i 2) i .r3' ; seek to end-10
	DetailPrint "Filepos: $3"

	${readSignature} $0
	Pop $2

	DetailPrint "ReadSignature: $2"
	Pop $2
	IntCmp $2 1 end
	
	;read pos of first block
	${ReadInt} $0
	Pop $2

	DetailPrint "First block: $2"

	System::Call 'msvcrt.dll::_lseek(i r0, l r2, i 0) i .r4' ; seek to position of first file

loop:
	${storeFile} $0
	Pop $4
	IntCmp $4 1 end
goto loop

end:

SectionEnd


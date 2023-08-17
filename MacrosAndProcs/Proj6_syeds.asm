TITLE Proj5_syeds     (Proj5_syeds.asm)

; Author: Sami Noor Syed
; Last Modified: 12/01/2022
; Description: Program does the following:
;	1. Implement two Macros to read user input and to display an output
;		a. mGetString: displays a prompt, gets the user's input to a mem location
;		b. mDisplay String: Print the string which is stored in a specific memory location
;	2. Implement two procedures for signed integers which use string primitive instrutions
;		a. ReadVal invokes mGetstring to get the user input,
;			Converts (using string primitives) a string of acsii digits to their numeric vals
;			validates the user's input (no letters, non-number characters)
;			Stores that value in a memory variable (output param, by reference)
;		b. Writeval, converts a numeric SDWORD value (input parameter, by val) to a string of acsii digits
;			invokes the mDisplayString macro to print the ascii SDWORD value to the output
;	3. Implement a test program which uses ReadVal and WriteVal procedures to do the following:
;		a. get 10 valid integers from the user. (loop in main calling readVal and writeVal
;		b. stores those numeric values in an arrau
;		c. Displays the integers, their sums and truncated averages
;
; Goals: 
;	implement Macros
;	Designing, implementing, and calling low-level I/O procedures)
;	Gosh this one was a toughie too :/

INCLUDE Irvine32.inc

;**********************************************************************************
; Name: mDisplayString
;
; Procedure display a string stored in a memory loation
;
; Receives: Parameters {stringOffset(reference, input)}
;
; Returns: prints the string located at the specified memory location
;
; Registers changed: EDX (but is restored)
;**********************************************************************************

mDisplayString	MACRO	stringOffset

	PUSH	EDX				;save register on the stack
	;print the string
	MOV		EDX, stringOffset
	CALL	WriteString
	POP		EDX				;restore register

ENDM


;**********************************************************************************
; Name: mGetString
;
; Procedure to prompt the user for a number and then moves user's keyboard input into a memory lovation (output parameter, by reference)
;
; Receives: Parameters {promptOffset(reference, input); buffer(refernce, input), bufferSize(value, input)}
;
; Returns: prints prompt supplied and stores user's keyboard input at the address of the string buffer, register EAX contains the number of characters read
;
; Registers changed: EDX, ECX,(these first two are restored), EAX (returns the number of characters read)
;**********************************************************************************

mGetString MACRO promptOffset, buffer, bufferSize

	;save registers on the stack
	PUSH	ECX
	PUSH	EDX
	
	;prompt user for a number and store that number in
	mDisplayString	promptOffset
	MOV		EDX, buffer
	MOV		ECX, bufferSize
	CALL	Readstring
	
	;restore registers except for EAX
	POP		EDX
	POP		ECX
ENDM



; (insert constant definitions here)

.data

; (insert variable definitions here)
titleText		BYTE	"Assignment 6: Macros & low-level I/O procedures", 13, 10,
						"By Sami Noor Syed", 0
instructText	BYTE	"After you finish entering 10 signed integers, this program will display", 13, 10,
						"a list of those integers, their sum and their average value.", 0
promptText		BYTE	"Please enter a signed integer: ", 0
invalidText		BYTE	"you did not enter a signed integer, or the number was too large (far from zero)", 0
arrayText		BYTE	"The following are the valid numbers that you entered: ", 0
sumText			BYTE	"The sum of those integers is: ", 0
averageText		BYTE	"The truncated average of those integers is: ", 0
farewellText	BYTE	"Good bye!, thanks for playing along!", 0
commaSpace		BYTE	", ", 0
;non-text variables

numArray		DWORD	10 DUP(?)
transitNum		DWORD	?
.code
main PROC
	
	PUSH	OFFSET		titleText
	PUSH	OFFSET		instructText
	CALL	intro

	;set up Loop to call readVal/ move user input to array once validated
	MOV		ECX, LENGTHOF numArray
	MOV		EDI, OFFSET	numArray

getNumbers:
	;adjust offset value to next empty element for the next Loop
	PUSH	OFFSET	transitNum
	PUSH	OFFSET	promptText
	PUSH	OFFSET	invalidText	
	CALL	readVal
	CALL	CrLf
	MOV		EAX, transitNum
	MOV		[EDI], EAX
	ADD		EDI, 4
	
	LOOP	getNumbers
;loop through write value
	mDisplayString	OFFSET arrayText
	CALL	CrLF
	MOV		ESI, OFFSET numArray
	MOV		ECX, LENGTHOF numArray

	;write valid numbers in a list
writeNumbers:
	MOV		EAX, [ESI]
	PUSH	EAX
	CALL	writeVal
	CMP		ECX, 1
	JE		endLoop			;don't print a comma after the last number
	mDisplayString OFFSET commaSpace
	ADD		ESI, 4
endLoop:
	LOOP	writeNumbers

	;push args to sumAvg
	CALL	CrLf
	CALL	CrLf
	PUSH	OFFSET averageText
	PUSH	OFFSET sumText
	PUSH	OFFSET numArray
	PUSH	LENGTHOF numArray
	CALL	sumAvg

	;push args to goodby
	PUSH	OFFSET	farewellText
	CALL	goodbye
	CALL	CrLf

	Invoke ExitProcess, 0	; exit to operating system
main ENDP

;**********************************************************************************
; Name: introduction
;
; Procedure to print an introduction, description prompts
;
; Recieves: titleText [EBP + 16]
;			instructionText[EBP + 12]
;
; Returns: prints all strings and introductions to the prompt
;
; Registers used: EDX
;**********************************************************************************

intro	PROC	USES	EDX
	PUSH	EBP
	MOV		EBP, ESP

;	print the title and intro/instructions
	mDisplayString	[EBP + 16]
	CALL	CrLf
	CALL	CrLf
	mDisplayString	[EBP + 12]
	CALL	CrLf
	CALL	CrLf

	POP		EBP
	RET	8
intro	ENDP

;**********************************************************************************
; Name: readVal
;
; Procedure to read the value entered by a user and convert it to an integer which returned by reference
;
; Receives: OFFSET	transitNum	[EBP + 16]
;			OFFSET	promptText	[EBP + 12]
;			OFFSET	invalidText	[EBP + 8]
;
; Returns: integer value conversion of entered string at memory location specified by transitNum
;
; Registers used: EDX, EAX, EBX, ECX, EDI, ESI
;**********************************************************************************

readVal Proc
	;set buffer to 20 characters because more than that is rediculous
	LOCAL	inputInt[20]:BYTE, verified:DWORD
	PUSHAD

getInput:
	;pass arguments to Macro [promptText, inputInt address, inputIntLength]
	LEA		EBX, inputInt
	mGetString	[EBP+12], EBX, LENGTHOF inputInt
	
	;if the characters read is greater than 19 digits or no digits were read, display an invalid messsage and reprompt
	CMP		EAX, 19
	JG		invalid
	CMP		EAX, 0
	JE		invalid
	
	;Pass arguments to validate Chars subProc
	LEA		EDI, verified
	PUSH	EDI
	PUSH	EBX
	PUSH	EAX
	CALL	validateChars
	
	;check return value by reference (EDI is still effective value for verified local variable)
	MOV		EDX, [EDI]
	CMP		EDX, 1
	JE		invalid
	JMP		valid
	
	;print invalid message, clear verified local variable jump to beginning
invalid:
	mDisplayString [EBP + 8]	
	MOV		EAX, 0
	MOV		verified, EAX
	CALL	CrLf
	JMP		getInput
	
	;if characters are all valid, push args to convert
valid:
	PUSH	[EBP + 16]		;transit NUM
	LEA		EDI, verified
	PUSH	EDI
	PUSH	EAX
	PUSH	EBX
	CALL	convert
	
	;check return value (verified) to see if the number is still valid
	MOV		EAX, verified
	CMP		EAX, 1
	JE		invalid
	POPAD
	RET	12
readVal		ENDP

;**********************************************************************************
; Name: validateChars
;
; Procedure to validate the value entered by a user.
;
; Preconditions: input string is type BYTE
;
; Postconditions: verified is adjusted according to returns
;
; Receives: [EBP + 16]		OFFSET	of "verified" local variable
;			[EBP + 12]		OFFSET	of  string value entered by user
;			[EBP + 8]		number of characters read by Value	
;
; Returns: verified (local variable) as 0 for valid inputs and 1 for invalid inputs 
;
; Registers used: EDI, ECX, ESI, EAX
;**********************************************************************************

validateChars	PROC 
	PUSH	EBP
	MOV		EBP, ESP
	
	;save registers and pass in parameters
	PUSHAD
	MOV		EDI, [EBP + 16]
	MOV		ECX, [EBP + 8]			;length of string in ECX
	MOV		ESI, [EBP +12]			;Characters in ESI
	
	;load in the first character (BYTE) from the string to AL
	;if characters are not numbers integers in ACSII, jump to invalidChar section 
	checkChar:
		LODSB
		CMP		AL, 47	
		JLE		invalidChar
		cmp		AL, 58
		JGE		invalidChar
		LOOP	checkCHar
		JMP		ending
		
		;if the first character, jump to firstCharCheck, otherwise, change verified to 1 (for invalid) and end proc
	invalidChar:
		cmp		ECX, [EBP+8]
		JE		firstCharCHeck
		MOV		EAX, 1
		MOV		[EDI], EAX
		JMP		ending
		
		;if the first char, check if it is a '+' or '-'. if not, change verified to 1 (for invalid) and end proc
	firstCharCHeck:
		DEC		ECX				;decriment loop count by 1 to account for sign BYTE
		cmp		AL, 43			;for '+'
		JE		checkChar
		CMP		AL, 45			;for '-'
		JE		checkChar
		MOV		EAX, 1
		MOV		[EDI], EAX
		JMP		ending
		
	;restore registers and stackframe
	ending:
	POPAD
	POP		EBP
	RET	12
validateChars ENDP

;**********************************************************************************
; Name: convert
;
; Procedure to convert the string value entered by a user to an integer which returned by reference
;
; Preconditions:	input string values are between 30h and 39h,
;					input string is type BYTE,
;					Length of input string is passed by value
;
; Postconditions:	verified and transit number variables are adjusted according to returns
;
; Receives: [EBP + 20]		OFFSET of transitNum		
;			[EBP + 16]		effective address of the verified local variable
;			[EBP + 12]		length by value of the input string	
;			[EBP + 8]		effective address of input string
;
; Returns: transitNumber output by reference (this is the integer value of the string)
;			verified, 0 if valid, 1 if invalid
;
; Registers used: EDX, EAX, EBX, ECX, EDI, ESI
;**********************************************************************************
convert PROC USES EDX EAX EBX ECX EDI ESI
	local	integer:DWORD
	
	;pass in parameters to PROC
	MOV		ESI, [EBP + 8]			;input string
	MOV		ECX, [EBP + 12]			;length of input string
	MOV		EDX, ECX				;store for comparison
	
	;Clear EBX, integer & EAX
	XOR		EBX, EBX
	LEA		EAX, integer
	MOV		[EAX], EBX
	XOR		EAX, EAX
	
	;convert one byte at a time
digitByDigit:
	
	;save counter and reference to length of string
	PUSH	EDX
	LODSB
	
	;if the first BYTE check if a sign character is applied, if negative, set negative flag
	cmp		EDX, ECX
	JNE		digits
	CMP		AL, 45
	JE		negative
	CMP		AL, 43
	JE		endLoop
digits:
	
	;subtract 48 from the value to convert the ACSII Char to an digit
	SUB		EAX, 48
	MOV		EDI, EAX
	
	;multiply the saved integer saved by 10 and add the result to current digit, if overflow flag is set, number is invalid
	MOV		EAX, integer
	MOV		EDX, 10
	MUL		EDX
	JO		tooLarge		
	ADD		EAX, EDI
	JO		tooLarge
	MOV		integer, EAX	;save new integer in integer local var
	
	MOV		EAX, 0
	POP		EDX		;restore reference to the length of the original string
	
	;if sign flag is cleared, jump to the end
	CMP		EBX, 1
	JNE		endLoop
	
	;if set and loop is on it's final pass, multiply final integer by -1 for twos compliment representation
	CMP		ECX, 1
	JNE		endLoop	
	MOV		EBX, integer
	IMUL	EAX, EBX, -1
	MOV		integer, EAX
	JC		tooLarge		;check if multiplication causes overflow (it shouldn't, but I'm supersticious)
	JMP		endLoop

;if first BYTE is negative, set EBX to 1
negative:
	MOV		EBX, 1
	JMP		endLoop

endLoop:
	LOOP	digitByDigit
	
	;Move final integer to location specified by transitNum datalabel 
	MOV		EAX, integer
	MOV		EDI, [EBP + 20]
	MOV		[EDI], EAX
	JMP		ending

;change verified (local variable of calling proc) to 1 signifying that the integer is invalid, end Proc
tooLarge:
	MOV		EAX, 1
	MOV		EDI, [EBP + 16]
	MOV		[EDI], EAX
	JMP		ending

ending:
	RET		16
convert ENDP

;**********************************************************************************
; Name: WriteVal
;
; Procedure to convert an IntegerValue passed by value to a string and then print it to the screen
;
; Preconditions:	input integer must fit into 32 bit register, can be signed or unsigned
;
; Postconditions:	NONE
;
; Receives: [EBP + 8]		integer value by value
;
; Returns: the string representation of the integer printed to the screen
;
; Registers used: EAX
;**********************************************************************************

writeVal	PROC
	LOCAL	outString[11]:BYTE
	PUSH	EAX

	;push Local variable outString to toChar PROC, and print the result
	LEA		EAX, outSTRING
	PUSH	EAX
	PUSH	[EBP + 8]
	call	toChar
	mDisplayString	EAX

	POP		EAX
	RET 4
writeVal	ENDP

;**********************************************************************************
; Name: toChar
;
; Sub-Procedure to convert an IntegerValue passed by value to a string
;
; Preconditions:input integer must fit into 32 bit register, can be signed or unsigned
;
; Postconditions:	NONE
;
; Receives: [EBP + 8]		integer value by value
;			[EBP + 12]		outstring Effective address
;
; Returns: String representation of integer is stored in outStringLocal variable from calling proc
;
; Registers used: EAX, ESI, ECX, EDX, EDI
;**********************************************************************************

toChar	PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD				; save registers
	
	; if the number is greater than 0, jump to conversion
	MOV		EAX, [EBP + 8]
	MOV		EBX, 0
	CMP		EAX, 0
	JGE		conversion
	
	;if number is negative, multiply by -1 to make it positive
	MOV		EBX, 1		; use the ebx register as a negative flag
	MOV		ESI, EAX
	IMUL	EAX,ESI, -1

conversion:
	;set up division by 10
	MOV		ESI, 10
	MOV		ECX, 0
	
	;push each digit onto the stack: isolating them by dividing by 10, remainder is LSD (least sig digit)
digits:
	MOV		EDX, 0
	div		ESI
	PUSH	EDX
	INC		ECX
	CMP		EAX, 0
	JNE		digits

	MOV		EDI, [EBP + 12]	;set outString as destination 

	;if the number is negative, store a '-' sigh at the front of the outString
	CMP		EBX, 1
	JNE		popInto
	MOV		EAX, 45
	STOSB

;POP each value from the stack and push it onto the string
popInto:
	POP		EAX
	ADD		EAX, 48
	STOSB
	LOOP	popInto
	
	;add a 0 at the end of the string
	MOV		EAX, 0
	STOSB

	;restore registers and end proc
	POPAD
	POP		EBP
	RET		8
toChar	ENDP

;**********************************************************************************
; Name: SumAvg
;
; Sub-Procedure to convert an IntegerValue passed by value to a string
;
; Preconditions: the sum of all 10 digits in the input ARRAY must fit into a 32 bit register.
;				 There should be exactly 10 numbers stored in the input array to find the proper value
;
; Postconditions:	NONE
;
; Receives: [EBP + 20]		OFFSET averageText
;			[EBP + 16]		OFFSET sumText
;			[EBP + 12]		OFFSET numArray
;			[EBP + 8]		LENGTHOF numArray
;
; Returns: Prints the sumText, the sum, the average text, and the average to the console.
;
; Registers used: EAX, ESI, ECX, EDX, EDI, ESI, EBX
;**********************************************************************************
sumAvg	PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD

	;pass parameters to register
	MOV		ESI, [EBP + 12]
	MOV		ECX, [EBP + 8]
	MOV		EAX, 0

	mDisplayString	[EBP + 16]		;print sum text
;sum numbers in array for total
sumLoop:
	MOV		EBX, [ESI]
	ADD		EAX, EBX
	ADD		ESI, 4
	LOOP	sumLoop 
	
	;push sum to writeVal
	PUSH	EAX
	CALL	WriteVal
	CALL	Crlf
	CALL	Crlf
	
	
	mDisplayString	[EBP + 20]		;print average text
	;sign divide the sum by the 10 to get the average
	MOV		EBX, 10
	MOV		EDX, 0
	CDQ
	IDIV	EBX

	;push result to writeVal for printing
	PUSH	EAX
	CALL	WriteVal
	CALL	CrLf
	CALL	CrLf
	
	;restore registers and print
	POPAD
	POP		EBP
	RET		16
sumAvg	ENDP

;**********************************************************************************
; Name: goodbye
;
; print a farewell string
;
; Preconditions: None
;
; Postconditions:	NONE
;
; Receives: [EBP + 8]		OFFSET farewellText
;
; Returns: Prints s good bye message to the console.
;
; Registers used: EDX
;**********************************************************************************
goodbye	PROC
	PUSH	EBP
	MOV		EBP, ESP

	mDisplayString	[EBP + 8]

	POP		EBP
	RET		4
goodbye	ENDP

END main

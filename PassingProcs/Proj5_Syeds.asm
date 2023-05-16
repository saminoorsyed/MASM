TITLE Proj5_syeds     (Proj5_syeds.asm)

; Author: Sami Noor Syed
; Last Modified: 11/18/2022
; OSU email address: syeds@oregonstate.edu
; Course number/section:   CS271 Section 406
; Project Number:  Proj-5          Due Date: 11/20/2022
; Description: Program does the following:
;	1. Generates "ARRAYSIZE" random integers between global constants LO and Hi
;	2. stores them in consecutive elements of the array 'randArray'
;	3. Displays the list of integers before sorting, 20 numbers each line.
;	4. Sorts the list in ascending order using merge sort
;	5. calculates and displays the median value of the sorted 'randArray', rounded to the nearest integer
;	6. Generates an array 'counts' which holds the number of times each value int the range [LO, Hi] is seen in randArray
;	7. Display the 'counts' array
;	8. Say GOODBYE
;
; Goals: 
;	Practice with procedures and passing parameters on the stack and base+offset referencing
;	implement merge sort using assembly lang O(nlog(n))
;	Gosh this one was a toughie

INCLUDE Irvine32.inc

; (insert macro definitions here)

; (insert constant definitions here)

LO			= 15
HI			= 50
ARRAYSIZE	= 200
RANGE		= 1+HI-LO		;I think this is legal... it seems to work well

.data
; (insert variable definitions here)

;introduction and program description
titleText		BYTE	"Generating, Sorting and Counting Random Integers WITH MERGE SORT [O(nlog(n))]... AND ENTHUSIAM!     by Sami Noor Syed", 0
description1	BYTE	"This program will Generate ", 0
description2	BYTE	" random numbers between ", 0
description3	BYTE	" and ", 0
description4	BYTE	", inclusive.", 13, 10,
						"Then, it will display those numbers in the unsorted order in which they were generated.", 13, 10,
						"the program will then sort those numbers in ascending order using the merge sort algorithm, ", 13, 10,
						"then calculate and display the median, the sorted list, and a final list whose values", 13, 10,
						"represent the number of times that each generated value appears starting from the lowest number.", 13, 10, 0
extraCredit		BYTE	"Unforturantely I did not have the time to implement the extra credit this time arround... bummer", 0

;output labels
randArrayText	BYTE	"The generated random integers are:", 0
medianText		BYTE	"The median of the sorted array is: ", 0
sortedArrayText	BYTE	"The random integers in sorted order are:", 0
countArrayText	BYTE	"The count of each integer value in the specified range is starting with the smallest is as follows: ", 0
spaceBetween	BYTE	" ", 0

;farewell text
farewell		BYTE	"GOOD DAY MADAM, SIR, DUKE, BARONESS, CONGRESS PERSON, PRESIDENT, INSERT TITLE THAT YOU PREFER HERE!", 13, 10,
						"thanks for your time! Have a good weekend!", 0
;global varianles to pass to parameters
randArray		DWORD	ARRAYSIZE DUP(?)	;array in which the random numbers are originall stored
sortedArray		DWORD	ARRAYSIZE DUP(?)	;Destination array for merge sort
trackerArr		DWORD	4 DUP(?)			;stores numbers to track memory locations for merge sort
counts			DWORD	RANGE DUP(?)		;creates an array of the same length as the range of possible values


.code
main PROC

;	1. Introduction (args passed to stack by reference stack so that the description can be printed)
	PUSH	OFFSET	extraCredit
	PUSH	OFFSET	titleText
	PUSH	OFFSET	description1
	PUSH	OFFSET	description2
	PUSH	OFFSET	description3
	PUSH	OFFSET	description4
	CALL introduction

;	2. Generate a random number into an array (1 arg passed by reference)
	PUSH	OFFSET	randArray
	PUSH	OFFSET	spaceBetween
	CALL fillArray

;	3.	Ptint the random Array (args passed by referecne)
	PUSH	OFFSET	randArrayText
	PUSH	OFFSET	spaceBetween
	PUSH	OFFSET	ARRAYSIZE
	PUSH	OFFSET	randArray
	CALL	displayList

;	4. Sort the random numbers arr using merge sort algorithm (args passed by reference)
	PUSH	OFFSET trackerArr
	PUSH	OFFSET ARRAYSIZE
	PUSH	OFFSET randArray
	PUSH	OFFSET sortedArray
	CALL	sortList	

;	5.	Prin the Sorted array (args passed by refernce)
	PUSH	OFFSET	sortedArrayText
	PUSH	OFFSET	spaceBetween
	PUSH	OFFSET	ARRAYSIZE
	PUSH	OFFSET	sortedArray
	CALL	displayList

;	6. Calculate and display the median (args passed by reference)
	PUSH	OFFSET	medianText
	PUSH	OFFSET	ARRAYSIZE
	PUSH	OFFSET	sortedArray
	CALL	displayMedian

;	7. Generate the count List (args passed by reference)
	PUSH	OFFSET	sortedArray
	PUSH	OFFSET	counts
	CALL	countList

;	8. Display count array (args passed by reference)
	PUSH	OFFSET	countArrayText
	PUSH	OFFSET	spaceBetween
	PUSH	OFFSET	RANGE
	PUSH	OFFSET	counts
	CALL	displayList

;	9. Say Goodbye (arg passed by reference)
	PUSH	OFFSET	farewell
	CALL	sayGoodbye



	Invoke ExitProcess,0	; exit to operating system
main ENDP

; (insert additional procedures here)

;**********************************************************************************
; Name: introduction
;
; Procedure to print an introduction, description prompts
;
; Receives: Parameters {titleText(reference, input); description(1-4)(reference, input);
;			LO(global, input); HI(global, input); ARRAYSIZE(global, input), extraCredit(reference, input}
;
; Returns: prints all strings and introductions to the prompt
;
; Preconditions: reference parameters are strings
;
; Registers changed: EDX, EAX
;**********************************************************************************
introduction PROC
	PUSH	EBP
	MOV		EBP, ESP
	
	;Print title
	MOV		EDX, [EBP + 24]		;title text
	CALL	WriteString
	CALL	CrLf
	CALL	CrLf

	;print Descriptions 1 - 4 with constants as stand ins for specific numbers required
	MOV		EDX, [EBP + 20]		;description1
	CALL	WriteString
	MOV		EAX, ARRAYSIZE
	CALL	WriteDec
	MOV		EDX, [EBP + 16]		;description2
	CALL	WriteString
	MOV		EAX, LO
	CALL	WriteDec
	MOV		EDX, [EBP + 12]		;description3
	CALL	WriteString
	MOV		EAX, HI
	CALL	WriteDec
	MOV		EDX, [EBP + 8]		;description4
	CALL	WriteString
	; extra credit print statement
	MOV		EDX, [EBP+ 28]
	CALL	WriteString
	CALL	CrLf
	CALL	CrLf

	POP		EBP
	RET 24
introduction ENDP

;**********************************************************************************
;Name: fillArray
;
; Procedure to generate and store random numbers in an randArray
;
; Parameters {randNumsArr(reference, input); ARRAYSIZE(Global, inpt); LO(GLobal, input); Hi(Global, input}
;
; Returns: randNumsArr(reference, output) [the values stored in the memory location are adjusted]
;
; Preconditions: randArray is the same length as ARRAYSIZE and of TYPE DWORD
;
; Registers changed:EDX, ECX, ESI, EDI, EAX
;**********************************************************************************
fillArray PROC
	PUSH	EBP
	MOV		EBP, ESP

	MOV		EDI, [EBP+12]	;randArray

	;initialize the starting seed value of Random range and the range of numbers possible (stored in ESI register)
	CALL	Randomize
	MOV		EAX, HI
	INC		EAX				;increment because it's inclusive
	SUB		EAX, LO
	
	;initialize loop to generate the random number and populate array
	MOV		ECX, ARRAYSIZE
	MOV		ESI, 1			

_genRandLoop:
	;store Range for to use on each iteration of the loop
	PUSH	EAX	
	
	;generate random number to randArray, increment array pointer,
	CALL	RandomRange		
	ADD		EAX, Lo			
	MOV		[EDI], EAX		
	ADD		EDI, 4	
	
	;restore Range to EAX
	POP		EAX				;recover range to use for Randomize
	LOOP	_genRandLoop
	
	POP EBP
	RET 8
fillArray ENDP

;**********************************************************************************
; Name: displayList
;
; Procedure to display any list that is passed to it by reference, including its title
;
; Receives: Parameters{inputarray(reference, input); arraySize(reference, input); spaceBetween(reference, input);
;			arrayTitleText(reference, input)}
;
; Returns:displays all fo the introductory text for the program from the title to the description
;
; Preconditions: All parameters are passed by reference myst be of TYPE DWORD
;
; Registers changed: ESI, EDI, EDX, ECX, EAX, EBX, 
;
; Sub-Procedure: Exchange Elements
;**********************************************************************************

displayList Proc
	PUSH	EBP
	MOV		EBP, ESP
	
	MOV		ESI, [EBP + 8]			;inputArray/ sourceArray stored in ESI
	
	;print title for array to be printed
	MOV		EDX, [EBP + 20]			;arrayText
	CALL	WriteString
	CALL	CrLf

	;initialize print loop, tracking the number of prints and looping through length of input array
	MOV		EDI, 1
	MOV		ECX, [EBP + 12]			;ARRAYSIZE    wasn't sure if I should pass this as a global or reference paramenter....

_printLoop:
	MOV		EAX, [ESI]
	CALL	WriteDec
	MOV		EDX, [EBP+16]			;spaceBetween for the space between each number
	CALL	WriteString

	;If the number of values printed is a multilple of 20, move cursor to the begining of next line
	MOV		EAX, EDI
	MOV		EDX, 0
	MOV		EBX, 20
	DIV		EBX
	CMP		EDX, 0					;EDX contains the remainder of the division EAX/EBX
	JNE		_nextNumber
	CALL	CrlF

_nextNumber:
	;incriment pointers
	INC		EDI
	ADD		ESI, 4
	LOOP	_printLoop
	CALL	CrLF
	CALL	CrLf
	
	POP EBP
	RET 16
displayList ENDP

;**********************************************************************************
; Name: sortList
;
; Procedure to recursively break down the array into left and right halves and then call a sub procedure
;			to sort those smaller halves  and sort the array base case is when the array size = 1
;
; Receives: parameters{RandNumsArr(reference, input/output); trackerArr(reference, input),
;			SortedArr(reference, input/output); ARRAYSIZE(reference, input)}
;
; Returns: The randArray input is sorted, and by consequence the sorted array is a copy of it.
;
; Preconditions: randArray and sortedArray are of the same size and TYPE
;
; Registers changed: ESI, EDI, EDX, ECX, EAX, EBX,
;**********************************************************************************

sortList PROC
	PUSH	EBP
	MOV		EBP, ESP

	MOV		EDI, [EBP + 8]		;pointer to beginning of SortedArray (for copying and output)
	MOV		ESI, [EBP + 12]		;pointer to beginning of unsorted array
	MOV		ECX, [EBP + 16]		;length of array
	CMP		ECX, 1				;when the length of the array is 1, end recursive calls and continue to call exchangeLists so that array can be sorted
	JBE		_baseCase
	
	;find middle of the array
	MOV		EAX, ECX
	MOV		EDX, 0
	MOV		EBX, 2
	DIV		EBX			;EAX has quotient, EDX has remainder
	
	;save register for use after recursive call
	PUSH	ESI			;pointer to beginning of unsorted array
	PUSH	ECX			;length of input array
	PUSH	EDI			;pointer to beginning of sorted array
	PUSH	EAX			;half of the length of the array
	
	;push parameters by reference to recursive call for the left half of the array
	PUSH	[EBP+20]	
	PUSH	EAX			
	PUSH	ESI			
	PUSH	EDI			
	CALL	sortList		;recursively call sort arr
	
	;restore registers from before sortList
	POP		EAX			
	POP		EDI			
	POP		ECX			
	POP		ESI			

	;save registers for use after recursive call
	PUSH	ESI
	PUSH	ECX
	PUSH	EDI
	PUSH	EAX
	PUSH	[EBP +20]

;-------------------------------------------------------------------------
; The following section of code adjusts and pushes parameters to the recursive 
; sort call that correspontd to the second half of the array, otherwise referenced
; as the right array
;-------------------------------------------------------------------------
	;calculate length of right array and push it as a reference parameter
	MOV		EBX, EAX
	MOV		EAX, ECX
	SUB		EAX, EBX
	PUSH	EAX			;push the length of the right array
	
	;calculate the size (in bytes) of the left array, store in EAX
	MOV		EAX, EBX
	MOV		EBX, 4
	MUL		EBX	

	;adjust source and desitination pointers so that it points to the beginning to the right array and push as parameters by reference
	ADD		ESI, EAX
	PUSH	ESI
	ADD		EDI, EAX	 
	PUSH	EDI	
	
	;recursive call to sortList on the right array
	CALL	sortList
	
	;Restore registers from before Pushing parameters to recursive call
	POP		EAX	
	POP		EDI	
	POP		ECX	
	POP		ESI			

	;push parameters to subProcedure exchangElements
	PUSH		[EBP+20]	;tracker array
	PUSH		ESI			;Random array
	PUSH		ECX			;length array
	PUSH		EDI			;sorted array
	PUSH		EAX			;length of array divided by 2
	CALL	exchangeElements
	_baseCase:
	POP		EBP
	RET 16
sortList ENDP

;**********************************************************************************
; Sub-procedure to exchange elements of the randomArray into the sortedArray and then copy back to the randomArray
;		so that the merge sort works. Can think of the sorted array as a temporary storage space to facilitate the
;		merge sort algorithm
;
; Receives: parameters{(sortedArray(reference, input/output); randomArray(reference, input/output); 
;		ARRAYSIZE(value, input); ArraySize/2(value, input); trackerArray(reference, input)}
;
; Returns:	The randArray input is sorted, and by consequence the sorted array is a copy of it. 
;
; Preconditions: randArray and sortedArray must be the same size and of TYPE DWORD
;
; Registers changed: ESI, EDI, EAX, ECX, EBX, EDX

; Notes: Here I make use of the tracker array to hold pointers to and lengths of the left and right halves of the array
;		it is formated as follows: [leftcount, rightcount, leftSize, rightSize]
;**********************************************************************************
exchangeElements PROC
	PUSH	EBP
	MOV		EBP, ESP
	
	;store parameters for use
	MOV		EAX, [EBP+8]			;length of array divided by 2 (leftArraySize)
	MOV		EDI, [EBP+12]			;pointer to beginning of sorted array
	MOV		ECX, [EBP+16]			;length of the whole array
	MOV		ESI, [EBP+20]			;pointer to beginning of unsorted array
	MOV		EBX, [EBP+ 24]			;pointer to beginning of trackerArr 
	
	;store count for left and right array (starts at 0) the first two elements using base+offset indexing
	MOV		EDX, 0
	MOV		[EBX], EDX
	MOV		[EBX+4], EDX
	
	;store the size of the left and right array in the last two elements of the tracker array using base+offset indexing
	MOV		[EBX +8], EAX
	MOV		EDX, ECX
	SUB		EDX, EAX
	MOV		[EBX+12], EDX
	
	;Make EAX point to the right half of the source array (sourceArrayPointer + leftArraySize x 4)
	MOV		EDX, 4
	MUL		EDX
	ADD		EAX, ESI	
	;save the arraySize, and source and destination pointer for use in _copyBack section
	PUSH	ECX			;length of the array
	PUSH	ESI			;pointer to source array
	PUSH	EDI			;pointer to destinatian array

;-------------------------------------------------------------------------
; The following section of code adjusts copies the elements from the random array
; into sorted order of the sorted array 
;-------------------------------------------------------------------------
_beginSortLoop:
	;if leftCount == leftArraySize, only add elements to the sortedArray from the right array
	MOV		ECX,[EBX]
	MOV		EDX, [EBX+8]
	CMP		ECX, EDX
	JE		_greaterThan
	
	;if rightCount == rightArraySize, only add elements to the sortedArray from the left array
	MOV		ECX, [EBX+4]
	MOV		EDX, [EBX+12]
	CMP		ECX, EDX
	JE		_lessThan
	
	;check if current element in the left half of the array is larger than the element in the right half of the array
	MOV		ECX, [ESI]
	MOV		EDX, [EAX]
	CMP		ECX, EDX
	JL		_lessThan

_greaterThan:
	;if rightCount == rightArraySize, end sorting loop and copy elements back to randArray
	MOV		ECX, [EBX+4]
	MOV		EDX, [EBX+12]
	CMP		ECX, EDX
	JE		_copyBack
	
	;move the smaller element, in the rightArray to the sortedArray
	MOV		ECX, [EAX]
	MOV		[EDI], ECX
	ADD		EDI, 4				;increment pointer to sorted Array
	ADD		EAX, 4				;increment pointer to right Array
	
	;increment right array count
	MOV		ECX, [EBX + 4]		
	INC		ECX
	MOV		[EBX + 4], ECX	
	JMP		_endLoop
_lessThan:
	;if the leftCount == leftArraySize, end sorting loop and copy elements back to randArray
	MOV		ECX,[EBX]
	MOV		EDX, [EBX+8]
	CMP		ECX, EDX
	JE		_copyBack

	;move the smaller element, in the first half of the array to the sorted array
	MOV		ECX, [ESI]
	MOV		[EDI], ECX
	ADD		EDI, 4			;increment pointer to the source array
	ADD		ESI, 4			;increment pointer to the left array

	;increment left array count
	MOV		ECX, [EBX]
	INC		ECX
	MOV		[EBX], ECX

_endLoop:
	JMP	_beginSortLoop	

_copyBack:
	;restore pointers to the beginnings of the sorted array, random array, and the ARRAYSIZE
	POP		EDI				;sortedArray
	POP		ESI				;randomArray
	POP		ECX				;ARRAYSIZE

;-------------------------------------------------------------------------
; Once the sorted array is filled in ascending order, it's results are copied
; back to the randArray in the followin section of code
;-------------------------------------------------------------------------
_copyBackLoop:
	MOV		EBX, [EDI]
	MOV		[ESI],EBX

	;increment pointers
	ADD		ESI, 4			
	ADD		EDI, 4
	LOOP	_copyBackLoop

	POP		EBP
	RET 20
exchangeElements ENDP

;**********************************************************************************
; Name: displayMedian
;
; Procedure to calculate and display the Median of the 
;
; Receives: parameters{(sortedArray(reference, input); ARRAYSIZE(reference, input); medianText(reference, input)}
;
; Returns: Displays the Median of the array after calculating, returns nothing to memory
;
; Preconditions: sorted array must be sorted in either ascending or descending order, and must be of type DWORD
;
; Registers changed: ESI, EAX, EDX, EBX
;
; future improvements: store the median as an array of length one and then feed that into the printArr (maybe?)
;**********************************************************************************
displayMedian PROC
	PUSH	EBP
	MOV		EBP, ESP

	;store parameters in registers for use
	MOV		ESI, [EBP + 8]		;pointer to the beginning of the sorted array
	MOV		EAX, [EBP + 12]		;offset of the ARRAYSIZE constant

	;print median label
	MOV		EDX, [EBP + 16]		;text for labeling the median
	CALL	WriteString

	;Determin if the array size is odd or even
	MOV		EBX, 2
	MOV		EDX, 0
	DIV		EBX
	CMP		EDX, 0
	JE		_twoMiddle			;if arraySize is even, find the two middle elements of the array

	;if arraySize is even, find the middle element of the array
	MOV		EBX, 4
	MUL		EBX
	ADD		ESI, EAX
	MOV		EAX, [ESI]
	JMP		_printMedian


_twoMiddle:
	;find and store the two middle numbers in EDX and EAX
	DEC		EAX
	MOV		EBX, 4
	MUL		EBX
	ADD		ESI, EAX
	MOV		EDX, [ESI]
	ADD		ESI, 4
	MOV		EAX, [ESI]

	;find the average of the two middle numbers
	ADD		EAX, EDX
	MOV		EBX, 2
	MOV		EDX, 0
	DIV		EBX
	cmp		EDX, 0				;round up if there is a fractional part from average, keep just the quotient if there is not
	JE		_printMedian
	INC		EAX

_printMedian:
	CALL	WriteDec
	CALL	CrLF
	CALL	CrLF

	POP		EBP
	RET 12
displayMedian	ENDP

;**********************************************************************************
; Name:countlist
;
; Procedure to genereate a count list that stores the number of times each value of the specified range appears in a separate list
;
; Receives: Parameters {sortedArray(reference, input); countArray(reference, input/output)}
;
; Returns: countArrray(reference, output) that shows the count that each value within the specified range appeared
;
; Preconditions: sortedArray must be sorted in either ascending or descending order and of type DWORD
;
; Registers changed:EDI, ESI, ECX, EBX, EDX
;**********************************************************************************
countList PROC
	PUSH	EBP
	MOV		EBP, ESP

	;store reference parameters for the sorted array and the counter array
	MOV		EDI, [EBP + 8]		
	MOV		ESI, [EBP + 12]
	;set ECX to HI-LO + 1 (since I can't use "Range" as a global variable) to account for each number in the required range
	MOV		ECX, HI
	INC		ECX					;set ECX to HI-LO + 1 (since I can't use "Range" as a global variable) to account for each number in the required range
	SUB		ECX, LO
	MOV		EBX, LO				;set comparison number equal to the element at the bottom of the range

_indexLoop:
_counterLoop:
	;compare the source array to the current value of the counter array
	MOV		EDX, [ESI]
	CMP		EBX, EDX
	JNE		 _endCount
	ADD		ESI, 4
	MOV		EDX, [EDI]
	INC		EDX
	MOV		[EDI], EDX
	JMP		_counterLoop
_endCount:
	INC		EBX
	ADD		EDI, 4
	LOOP	_indexLoop


	POP		EBP
	RET 8
countList	ENDP

;**********************************************************************************
; Name:sayGoodbye
;
; Procedure to say farwell to the user
;
; Receives: parameters{farewellText(reference, input)}
;
; Returns:None
;
; Preconditions: farewellText is a string
;
; Registers changed:EDX
;**********************************************************************************
sayGoodbye PROC
	PUSH	EBP
	MOV		EBP, ESP

	MOV		EDX, [EBP + 8]
	CALL	WriteString
	CALL	CrLf

	POP		EBP
	RET 4
sayGoodbye	ENDP
END main
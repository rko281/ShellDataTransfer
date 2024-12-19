"Filed out from Dolphin Smalltalk"!

OLEStructure subclass: #DROPFILES
	instanceVariableNames: ''
	classVariableNames: '_OffsetOf_fNC _OffsetOf_fWide _OffsetOf_pFiles _OffsetOf_pt'
	poolDictionaries: ''
	classInstanceVariableNames: ''!

DROPFILES guid: (GUID fromString: '{bc6c930b-bd51-4915-8174-8cb74ac7a741}')!

DROPFILES addClassConstant: '_OffsetOf_fNC' value: 16rC!
DROPFILES addClassConstant: '_OffsetOf_fWide' value: 16r10!
DROPFILES addClassConstant: '_OffsetOf_pFiles' value: 16r0!
DROPFILES addClassConstant: '_OffsetOf_pt' value: 16r4!

DROPFILES comment: 'DROPFILES is an <ExternalStructure> that wraps the Windows DROPFILES structure.  DROPFILES defines the CF_HDROP and CF_PRINTERS clipboard formats. In the CF_HDROP case, the data that follows is a double null-terminated list of file names. For CF_PRINTERS, the data that follows are the printer friendly names.

Aspects:
- pFiles, offset of the file list from the beginning of this structure, in bytes.
- pt , drop point. The coordinates depend on fNC.
- fNC, nonclient area flag. If true, pt specifies the screen coordinates of a point in a window''s nonclient area. If it is false, pt specifies the client coordinates of a point in the client area.
- fWide, a Boolean that indicates whether the file contains ANSI or Unicode characters. If the value is false, the file contains ANSI characters. Otherwise, it contains Unicode characters.'!

!DROPFILES categoriesForClass!Unclassified! !

!DROPFILES methodsFor!

fNC
	"Answer the receiver's fNC field as a Smalltalk object."

	^(bytes dwordAtOffset: 12) asBoolean!

fNC: anObject
	"Set the receiver's fNC field to the value of anObject."

	bytes dwordAtOffset: 12 put: anObject asParameter!

fWide
	"Answer the receiver's fWide field as a Smalltalk object."

	^(bytes dwordAtOffset: 16) asBoolean!

fWide: anObject
	"Set the receiver's fWide field to the value of anObject."

	bytes dwordAtOffset: 16 put: anObject asParameter!

pFiles
	"Answer the receiver's pFiles field as a Smalltalk object."

	^(bytes dwordAtOffset: 0)!

pFiles: anObject
	"Set the receiver's pFiles field to the value of anObject."

	bytes dwordAtOffset: 0 put: anObject!

pt
	"Answer the receiver's pt field as a Smalltalk object."

	^POINTL fromAddress: (bytes yourAddress + 4)!

pt: anObject
	"Set the receiver's pt field to the value of anObject."

	anObject replaceBytesOf: bytes from: 5 to: 12 startingAt: 1! !

!DROPFILES categoriesForMethods!
fNC!**compiled accessors**!public! !
fNC:!**compiled accessors**!public! !
fWide!**compiled accessors**!public! !
fWide:!**compiled accessors**!public! !
pFiles!**compiled accessors**!public! !
pFiles:!**compiled accessors**!public! !
pt!**compiled accessors**!public! !
pt:!**compiled accessors**!public! !
!

!DROPFILES class methodsFor!

defineFields
	"Define the fields of the DROPFILES .

		DROPFILES compileDefinition.

		typedef struct _DROPFILES {
    			DWORD  pFiles;
    			POINT  pt;
    			BOOL  fNC;
    			BOOL  fWide;
			} DROPFILES, *LPDROPFILES;
	"

	self
		defineField: #pFiles type: DWORDField new;
		defineField: #pt type: (StructureField type: POINT);
		defineField: #fNC type: BOOLField new;
		defineField: #fWide type: BOOLField new!

fromFilenames: aCollection

	| stream bytes |

	"A null terminated concatenation of null terminated strings"
	stream := WriteStream on: (String new: 64).
	aCollection do: [ :each | stream nextPutAll: each. stream nextPut: ##(Character null)].
	stream nextPut: ##(Character null).
	bytes := stream contents asByteArray.

	^(self withBytes: ((ByteArray new: self byteSize), bytes))
		fNC: false;
		fWide: false;
		pFiles: self byteSize;
		yourself

! !

!DROPFILES class categoriesForMethods!
defineFields!initializing!public! !
fromFilenames:!public! !
!


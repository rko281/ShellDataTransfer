"Filed out from Dolphin Smalltalk"!

Shell subclass: #ShellDragDropSample
	instanceVariableNames: 'fullTextPresenter filesListPresenter directory'
	classVariableNames: ''
	poolDictionaries: 'OLEShellDataTransferConstants'
	classInstanceVariableNames: ''!

ShellDragDropSample guid: (GUID fromString: '{ac1db0e4-af7f-4950-bd45-66bd0436dcc3}')!

ShellDragDropSample comment: 'ShellDragDropSample is a sample shell to demonstrates the use of Shell data transfer using COM drag and drop.

	ShellDragDropSample  show.'!

!ShellDragDropSample categoriesForClass!Unclassified! !

!ShellDragDropSample methodsFor!

contentsOf: aFilename

	^
	[| fs |
	fs := FileStream read: aFilename text: true.
	[fs contents] ensure: [fs close]] on: Error do: [ :exc | exc return: '']!

copyToClipboard

	Clipboard current setBytes: (DROPFILES fromFilenames: (filesListPresenter selections collect: [ :each | each name])) bytes formatId: CF_HDROP!

createComponents
	super createComponents.
	filesListPresenter := self add: ListPresenter new name: 'filesList'.
	fullTextPresenter := self add: TextPresenter new name: 'fullText'!

createSchematicWiring
	"Create the trigger wiring for the receiver"

	super createSchematicWiring.
	self when: #closeRequested: send: #onCloseRequested: to: self.

	filesListPresenter
		when: #drag: 
			send: #onDragFiles: 
			to: self;
		when: #dragCut: 
			send: #onDragFilesMoved:
			to: self;
		when: #dragOver:
			send: #onDragOverList:
			to: self;
		when: #drop:
			send: #onDropOverList:
			to: self.
	fullTextPresenter
		when: #dragOver:
			send: #onDragOverFullText:
			to: self;
		when: #drop:
			send: #onDropOverFullText:
			to: self!

createTestData

	(File exists: self directory) ifFalse: 
		[(File createDirectory: self directory) ifFalse: [self error: 'cannot create temp directory ', directory]].

	10 to: 20 do: 
		[ :index || filename |
		filename := File composePath: self directory subPath: 'test<1d>.txt' << index.
		(File exists: filename) ifFalse: 
			[(FileStream write: filename text: true)
				nextPutAll: 'dummy test file <1d>' << index;
				close]]!

directory

	^directory ifNil: [directory := File composePath: File tempPath subPath: self class name]!

onCloseRequested
	ShellDragDropSession revokeDropTarget: self view.
	^super onCloseRequested!

onCloseRequested: aValue
	ShellDragDropSession revokeDropTarget: self view.
	aValue value: true!

onDragFiles: aDragDropSession

	| filenames dropfiles medium fmt |

	aDragDropSession supportedOperations: #(#copy #move).

	filenames := aDragDropSession dragObjects collect: 
		[ :each || filename |
		filename := (each format: #Object) name.
		each format: #Filenames data: {filename}.
		filename].

	dropfiles := DROPFILES fromFilenames: filenames.
	medium := STGMEDIUM new.
	medium 
		tymed: TYMED_HGLOBAL;
		handle: (ExternalMemory copyBytesToGlobalHeap: dropfiles bytes);
		pUnkForRelease: nil.

	fmt := FORMATETC new.
	fmt 
		cfFormat: CF_HDROP;
		dwAspect: DVASPECT_CONTENT ;
		lindex: -1;
		tymed: TYMED_HGLOBAL.

	aDragDropSession dataObject SetData: fmt pmedium: medium fRelease: 1!

onDragFilesMoved: aDragDropSession

	"See 
		https://learn.microsoft.com/en-us/windows/win32/shell/clipboard#cfstr_performeddropeffect
	...for discussion of handling optimized versus unoptimized moves"

	aDragDropSession dragOperation = #unoptimizedMove ifTrue: 
		["Need to delete the files"
		aDragDropSession dragObjects do: 
			[ :each |
			(each isFormatAvailable: #Filenames) ifTrue: 
				[(each format: #Filenames) do: [ :filename | File delete: filename]]]].

	self refreshFilesList!

onDragOverFullText: aDragDropSession

	aDragDropSession 
		operation: ((aDragDropSession dragObjects 
				allSatisfy: [:each | (each isFormatAvailable: #Filenames) and: [(each format: #Filenames) size = 1]]) 
					ifTrue: [aDragDropSession intendedOperation]
					ifFalse: [])!

onDragOverList: aDragDropSession

	| operation |

	(aDragDropSession isFormatAvailable: #Filenames) ifFalse: [^aDragDropSession operation: nil].

	operation := aDragDropSession intendedOperation.
	Keyboard default isCtrlDown ifTrue: [operation := #copy].
	Keyboard default isShiftDown ifTrue: [operation := #move].
	
	aDragDropSession operation: operation!

onDropOverFullText: aSession
	| object |

	fullTextPresenter view text: ''.
	aSession dragObjects do: 
			[:each | 
			(each isFormatAvailable: #Filenames) 
				ifTrue: 
					[object := each format: #Filenames.
					each format: #String
						data: (object isEmpty ifTrue: [''] ifFalse: [self contentsOf: object first])]]!

onDropOverList: aSession

	aSession dragObjects do: 
		[ :each || newFiles |
		(each isFormatAvailable: #Filenames) ifTrue: 
			[newFiles := OrderedCollection new.
			(each format: #Filenames) do: 
				[ :source || destination |
				destination := File composePath: self directory subPath: (File splitFilenameFrom: source).
				(File exists: destination) 
				ifTrue: 
					[MessageBox warning: '<1s> already exists' << destination]
				ifFalse: 
					[File copy: source to: destination.
					aSession operation = #move ifTrue: [File delete: source].
					newFiles add: (File new spec: destination)]].
	
			aSession suggestedTarget isNil 
				ifTrue: [filesListPresenter model addAll: newFiles]
				ifFalse: [filesListPresenter model addAll: newFiles after: aSession suggestedTarget].
			filesListPresenter selections: newFiles]]!

onViewOpened

	super onViewOpened.

	self 
		createTestData;
		refreshFilesList.

	filesListPresenter view 
		isDragSource: true;
		dragDropSessionClass: ShellDragDropSession.

	fullTextPresenter value: 'Drop file here to view contents'.

	ShellDragDropSession registerDropTarget: self view.

	self view text: self directory!

openExplorer

	ShellLibrary default shellExecute: nil lpOperation: 'open' lpFile: 'explorer' lpParameters: self directory lpDirectory: nil nShowCmd: SW_SHOWNORMAL!

queryCommand: aCommandQuery

	aCommandQuery commandSymbol = #copyToClipboard ifTrue: 
		[aCommandQuery isEnabled: filesListPresenter hasSelection.
		^true].

	^super queryCommand: aCommandQuery!

refreshFilesList

	| files |

	files := OrderedCollection new.
	File for: '*' in: self directory do: [ :each | (each fileName first = $.) ifFalse: [files add: (File new spec: each path)]].
	filesListPresenter list: files! !

!ShellDragDropSample categoriesForMethods!
contentsOf:!helpers!private! !
copyToClipboard!commands!public! !
createComponents!initializing!public! !
createSchematicWiring!initializing!public! !
createTestData!helpers!private! !
directory!accessing!public! !
onCloseRequested!event handling!public! !
onCloseRequested:!event handling!public! !
onDragFiles:!event handling!public! !
onDragFilesMoved:!event handling!public! !
onDragOverFullText:!event handling!public! !
onDragOverList:!event handling!public! !
onDropOverFullText:!event handling!public! !
onDropOverList:!event handling!public! !
onViewOpened!event handling!public! !
openExplorer!commands!public! !
queryCommand:!commands!public! !
refreshFilesList!helpers!private! !
!

!ShellDragDropSample class methodsFor!

resource_Default_view
	"Answer the literal data from which the 'Default view' resource can be reconstituted.
	DO NOT EDIT OR RECATEGORIZE THIS METHOD.

	If you wish to modify this resource evaluate:
	ViewComposer openOn: (ResourceIdentifier class: self selector: #resource_Default_view)
	"

	^#(#'!!STL' 4 788558 11 ##(Smalltalk.STBViewProxy) ##(Smalltalk.ShellView) 34 27 nil nil 8 #(13565952 65536) 416 nil 327686 ##(Smalltalk.Color) #face3d 328198 ##(Smalltalk.Point) 1201 1601 517 nil nil nil 416 788230 ##(Smalltalk.BorderLayout) 1 1 410 ##(Smalltalk.ContainerView) 34 15 nil 416 34 2 8 1140850688 131073 560 nil nil nil 7 nil nil nil 560 530 1 1 nil nil 410 ##(Smalltalk.ToolButton) 34 14 nil 560 34 2 8 1140850688 131073 640 nil nil nil 7 nil nil nil 640 nil 410 ##(Smalltalk.Toolbar) 34 28 nil 640 34 2 8 1140857676 131137 704 nil nil nil 3 nil nil nil 704 nil 8 1908274960 nil nil nil nil 170 192 34 2 15633 1115718 2 ##(Smalltalk.ToolbarIconButton) 704 1 1180998 4 ##(Smalltalk.CommandDescription) #openExplorer 8 'Open in Explorer' 1 1 263494 3 ##(Smalltalk.Icon) nil true 1572870 ##(Smalltalk.ImageRelativeFileLocator) 9 786694 ##(Smalltalk.ShellLibrary) 15633 nil nil 34 1 832 nil nil 11 nil #mediumIcons 498 291 51 nil nil 983302 ##(Smalltalk.MessageSequence) 138 144 34 1 721670 ##(Smalltalk.MessageSend) #createWindow: 34 1 787462 ##(Smalltalk.CreateWindow) 262406 ##(Smalltalk.RECT) 8 #[0 0 0 0 0 0 0 0 150 0 0 0 30 0 0 0] 193 736 8 '' 704 3 8 #() 498 193 193 nil 31 1026 138 144 34 2 1090 #createWindow: 34 1 1138 1170 8 #[173 1 0 0 5 0 0 0 67 2 0 0 35 0 0 0] 193 672 8 'Open in Explorer' 640 1090 #isEnabled: 8 #(false) 640 3 34 1 704 498 193 193 nil 27 410 ##(Smalltalk.StaticText) 34 16 nil 560 34 2 8 1140850944 65 1472 nil nil nil 7 nil nil nil 1472 nil 8 1908362976 852486 ##(Smalltalk.NullConverter) nil nil nil 1026 138 144 34 2 1090 #createWindow: 34 1 1138 1170 8 #[5 0 0 0 5 0 0 0 114 1 0 0 35 0 0 0] 193 1504 nil 1472 1090 #text: 34 1 8 'Drag Files to/from the list:' 1472 3 8 #() 498 193 193 nil 27 nil 170 192 8 #() 590342 ##(Smalltalk.Rectangle) 498 11 11 498 11 11 1026 138 144 34 1 1090 #createWindow: 34 1 1138 1170 8 #[0 0 0 0 0 0 0 0 72 2 0 0 40 0 0 0] 193 592 8 '' 560 3 34 2 1472 640 498 193 193 nil 27 410 ##(Smalltalk.MultilineTextEdit) 34 16 nil 416 34 2 8 1143017796 1025 2064 nil 466 #default nil 23 nil nil nil 2064 nil 8 1908173184 1554 nil nil 11 1026 138 144 34 1 1090 #createWindow: 34 1 1138 1170 8 #[0 0 0 0 42 2 0 0 72 2 0 0 249 2 0 0] 193 2096 nil 2064 3 8 #() 498 193 193 nil 27 nil nil 410 ##(Smalltalk.ListView) 34 45 nil 416 34 2 8 1409355849 1025 2336 590662 2 ##(Smalltalk.ListModel) 138 144 1808 nil 1310726 ##(Smalltalk.IdentitySearchPolicy) 2128 nil 23 265030 4 ##(Smalltalk.Menu) nil true 34 1 984134 2 ##(Smalltalk.CommandMenuItem) 1 850 #copyToClipboard 8 'Copy to Clipboard' 1 1 nil nil nil 8 '' nil 134217729 nil nil nil nil nil nil nil 2336 nil 8 1908231776 459270 ##(Smalltalk.Message) #displayString 8 #() ##(Smalltalk.IconicListAbstract) 1049926 1 ##(Smalltalk.IconImageManager) nil nil nil nil nil nil 138 144 34 1 920646 5 ##(Smalltalk.ListViewColumn) 8 'Filename' 1161 #left 2626 #displayString 8 #() 2626 #<= 2800 787814 3 ##(Smalltalk.BlockClosure) 0 nil 1180966 ##(Smalltalk.CompiledExpression) 4 1 2832 8 'doIt' 8 '[ :file | File splitFilenameFrom: file name]' 8 #[32 105 45 226 1 178 106] 983558 ##(Smalltalk.VariableBinding) #File ##(Smalltalk.File) #name #splitFilenameFrom: 2848 7 257 nil nil 2336 nil 3 nil nil #report 8 #() nil 131169 nil 1 nil nil nil nil nil nil nil nil nil nil nil nil nil nil nil 1026 138 144 34 2 1090 #createWindow: 34 1 1138 1170 8 #[0 0 0 0 40 0 0 0 72 2 0 0 42 2 0 0] 193 2368 8 'Filename' 2336 1090 #contextMenu: 34 1 2496 2336 3 8 #() 498 193 193 nil 35 170 192 34 4 2064 8 'fullText' 2336 8 'filesList' nil nil nil nil nil 1 nil nil nil nil 1 nil 193 1026 138 144 34 1 1090 #createWindow: 34 1 1138 1826 498 5119 21 498 6319 1621 193 448 8 'Shell Drag Drop Sample' 416 1 34 3 560 2336 2064 498 193 193 nil 27 )! !

!ShellDragDropSample class categoriesForMethods!
resource_Default_view!public!resources-views! !
!


"Filed out from Dolphin Smalltalk"!

InternalDragDropSession subclass: #ShellDragDropSession
	instanceVariableNames: 'keyState dataObject registeredView dragOperation'
	classVariableNames: 'Register'
	poolDictionaries: 'OLEConstants OLEShellDataTransferConstants Win32Errors'
	classInstanceVariableNames: ''!

ShellDragDropSession guid: (GUID fromString: '{93e57526-c0be-48a8-9881-18746a7174d6}')!

ShellDragDropSession comment: 'This class attempts to integrate WindowsShell drag/drop into Dolphin''s drag/drop framework.

An instance is created and registered for each View that wishes to receive drap/drop from the WindowsShell. 

Instances implement the IDropTarget interface. The functions of this interface are implemented by converting the arguments into objects and then acting like a DragDropSession.

Note: Only a subset of formats/mediums are made available to presenters. See the method #createDragObjects

Instance Variables
	keyState			<Integer>
	dataObject		<IDataObject>
	operationDescriptions	<Dictionary>
	registeredView		<View>'!

!ShellDragDropSession categoriesForClass!Unclassified! !

!ShellDragDropSession methodsFor!

continueTrackingAt: aPoint from: lastPoint
	"Move the representation of the DragDropObject from lastPoint to aPoint."

	| newDropTarget |
	dragPoint := aPoint.
	(newDropTarget := View fromPoint: dragPoint) = dropTarget
		ifTrue: [self dropTargetOver]
		ifFalse: [
			self dropTargetLeave.
			dropTarget := newDropTarget.
			self dropTargetEnter].
	self giveFeedback.
	^dragPoint!

createDragObjects
	"Answer a Collection containing a DragDropObject.
	Note: IDataObject makes data available via a number of formats and a number of mediums.
		- A full wrapping of IDataObject was outside the scope of this project.
		- We make the filenames available and the IDataObject if the user needs fuller access"

	| fileNames dragObject |
	fileNames := dataObject getDropFilesIfNone: [#()].
	dragObjects := OrderedCollection with: (dragObject := self newDragObject: fileNames).
	dragObject format: #Filenames data: fileNames.
	dragObject format: #IDataObject data: dataObject.
	fileNames notEmpty ifTrue: [dragObject format: #String data: fileNames first]!

dataObject

	^dataObject ifNil:
		[dataObject := IDataObject newPointer.
		ShellLibrary default SHCreateDataObject: nil cidl: 0 apidl: nil pdtInner: nil riid: IDataObject clsid p: dataObject.
		dataObject]!

doDragDropAt: aPoint button: buttonSymbol 

	| effects dropSource pdwEffect dragResult performedDropEffect |

	dragOperation := nil.

	(self class isADragButton: buttonSymbol) ifFalse: [^nil].

	self dragSource isDragSource ifTrue: [self dragSource ddGetObjects: self].
	(dragObjects isNil or: [dragObjects isEmpty]) 
		ifTrue: 
			["Cancel the drag&drop operation"
			^nil].

	dragButton := buttonSymbol.
	oldCursor := Cursor reset.

	effects := 0.
	self supportedOperations do: [ :each | effects := effects bitOr: (self effectsMap at: each)].

	self 
		dragPoint: aPoint;
		buildDragImageList;
		beginDragImage.

	dropSource := self queryInterface: IDropSource.
	pdwEffect := DWORD new value: 1.
	dragResult := OLELibrary default doDragDrop: self dataObject dropSource: dropSource dwOKEffects: effects pdwEffect: pdwEffect.

	dragResult = DRAGDROP_S_DROP ifFalse: [^self].

	"Where a move/cut occurs but does not result in a file delete (an 'optimized move'), pdwEffect will NOT hold DROPEFFECT_MOVE.
	pdwEffect only holds DROPEFFECT_MOVE when an 'unoptimized move' occurs.
	To correctly determine the type of move we must check the dataObject's 'Performed DropEffect' value
	See https://learn.microsoft.com/en-us/windows/win32/shell/clipboard#cfstr_performeddropeffect"
	pdwEffect value = DROPEFFECT_MOVE 
	ifTrue: 
		[dragOperation := #unoptimizedMove]
	ifFalse: 
		[performedDropEffect := dataObject addressForFormatEtc: #'Performed DropEffect' do: [ :address | (DWORD fromAddress: address) value].
		dragOperation := self effectsMap keyAtValue: performedDropEffect ifAbsent: [nil]].

	(dragOperation = #move or: [dragOperation = #unoptimizedMove]) ifTrue: [self dragSourceCut]!

dragButton
	(self keyState anyMask: MK_RBUTTON) ifTrue: [^#right].
	^#left!

DragEnter: anIDataObject grfKeyState: grfKeyState pt: pt pdwEffect: aDWORD
	"<virtual stdcall: hresult 4 IDataObject* dword POINTL DWORD*>
	^self invalidCall"

	"Notification signal: anIDataObject availableFormatEtcs."

	keyState := grfKeyState.
	dataObject := anIDataObject.
	dragPoint := pt asPoint.
	dropTarget := registeredView.
	self createDragObjects.
	self dropTargetEnter.
	aDWORD value: self dropEffect.
	^S_OK!

DragLeave
	"<virtual stdcall: hresult 6>
	^self invalidCall"

	keyState := dataObject := dragObjects := nil.
	^S_OK!

dragOperation
	^dragOperation!

DragOver: dragOver pt: pt pdwEffect: aDWORD
	"<virtual stdcall: hresult 5 dword POINTL DWORD*>
	^self invalidCall"

	self continueTrackingAt: (dragPoint := pt asPoint) from: nil.
	aDWORD value: self dropEffect.
	^S_OK!

Drop: anIDataObject grfKeyState: grfKeyState pt: pt pdwEffect: aDWORD
	"<virtual stdcall: hresult 7 IDataObject* dword POINTL DWORD*>
	^self invalidCall"

	dataObject := anIDataObject.
	self createDragObjects.
	self continueTrackingAt: (dragPoint := pt asPoint) from: nil.
	operation isNil 
		ifTrue: [self dropTargetLeave]
		ifFalse: 
			[(self dropTargetDrop and: [operation == #move]) 
				ifTrue: 
					["self dragSourceCut"

					]].
	keyState := dataObject := dragObjects := nil.
	aDWORD value: self dropEffect.
	^S_OK!

dropEffect
	^self effectsMap at: self operation ifAbsent: [0]!

effectsMap

	^##(Dictionary new 
		at: #copy put: DROPEFFECT_COPY; 
		at: #move put: DROPEFFECT_MOVE; 
		at: #link put: DROPEFFECT_LINK; 
		yourself).!

endDragSourceAnswering: anInteger

	"A drag operation with this session as the source has ended. 
	Tidy up and answer anInteger (usually DRAGDROP_S_DROP or DRAGDROP_S_CANCEL)"

	imageList endDrag.

"	dataObject := nil."

	^anInteger!

finalRelease
	!

forcedOperation
	"If the user is currently holding down one of the drag and drop modifier keys
	answer the operation intended. If no such keys are held down then answer nil."

	(self keyState anyMask: MK_CONTROL) ifTrue: [^#copy].
	(self keyState anyMask: MK_SHIFT) ifTrue: [^#move].
	"self keyState anyMask: MK_ALT ifTrue: [^#link]."
	^nil!

getExtendedOperation
	"Private - An extended drop has occurred - query the drop target for a list of supported operations
	so that we may present these as a context menu to allow the user to choose the operation."

	| opNames supported |
	self dropTarget isDropTarget ifTrue: [dropTarget ddOperations: self].
	(supported := self supportedOperations) isEmpty 
		ifTrue: [self operation: nil]
		ifFalse: 
			[| popup defaultOp i default |
			defaultOp := self operation.
			popup := Menu new.
			i := 1.
			default := 0.
			opNames := self operationDescriptions.
			supported do: 
					[:opSymbol | 
					opSymbol == defaultOp ifTrue: [default := i].
					popup addCommand: (MessageSend 
								receiver: self
								selector: #operation:
								argument: opSymbol)
						description: (opNames at: opSymbol).
					i := i + 1].
			popup
				addSeparator;
				addCommand: (MessageSend 
							receiver: self
							selector: #operation:
							argument: nil)
					description: 'Cancel'.
			popup setDefault: default.
			self operation: nil.
			popup showIn: self dropTarget position: Cursor position.
			"Allow the command selected from the menu to be dispatched before returning"
			SessionManager inputState pumpMessages].
	^operation!

giveFeedback
	"Private - Set the drag cursor to indicate the effect of a drop on the current target."

	!

GiveFeedback: dwEffect

	^DRAGDROP_S_USEDEFAULTCURSORS!

hideDragImage
	"Do Nothing"

!

intendedDropEffect
	^self effectsMap at: self intendedOperation ifAbsent: [0]!

isExtendedDrag
	"Answer whether this drag was initiated with the 'right' mouse button."

	^self dragButton == self class extendedDragButton!

keyState
	^keyState!

QueryContinueDrag: fEscapePressed grfKeyState: grfKeyState

	| newDragPoint |

	keyState := grfKeyState.
	(newDragPoint := Cursor position) = dragPoint ifFalse: 
		[self continueTrackingAt: newDragPoint from: dragPoint.
		imageList dragMoveTo: dragPoint].

	fEscapePressed ifTrue: [^self endDragSourceAnswering: DRAGDROP_S_CANCEL].

	^((dragButton = #left and: [keyState anyMask: MK_LBUTTON]) or: [dragButton = #right and: [keyState anyMask: MK_RBUTTON]]) 
		ifTrue: [S_OK "Continue"]
		ifFalse: [self endDragSourceAnswering: DRAGDROP_S_DROP]
!

queryInterface: anInterfaceClass
	"Answer a new interface which supports the specified interface protocol
	(usually a class), or nil if the receiver does not support the interface."

	^self queryInterface: anInterfaceClass ifNone: []
!

queryInterface: anInterfaceClass ifNone: exceptionHandler
	"Answer a new interface pointer which supports the specified interface protocol
	(usually a class). If the receiver does not support the interface, answer the
	result of evaluating the niladic valuable, exceptionHandler."

	(IDropSource supportsInterface: anInterfaceClass) ifTrue: [^IDropSource on: self implementor: self].

	(IDropTarget supportsInterface: anInterfaceClass) ifFalse: [^exceptionHandler value].
	^IDropTarget on: self implementor: self!

registeredView
	^registeredView!

registeredView: anObject
	registeredView := anObject!

revokeDragDrop
	OLELibrary default revokeDragDrop: registeredView handle!

server
	"Answer the server object on behalf of which the receiver is implementing an
	interface or interfaces. By default this is the receiver itself, but subclasses
	may implement interfaces on behalf of other objects in order that any particular
	server object can support any number of interfaces with different implementors."

	^self!

showDragImage
	"Do Nothing"

	!

startTrackingAt: aPoint
	Error shouldNotImplement! !

!ShellDragDropSession categoriesForMethods!
continueTrackingAt:from:!public!tracking! !
createDragObjects!operations!public! !
dataObject!accessing!public! !
doDragDropAt:button:!operations!public! !
dragButton!accessing!public! !
DragEnter:grfKeyState:pt:pdwEffect:!COM Interfaces-IDropTarget!public! !
DragLeave!COM Interfaces-IDropTarget!public! !
dragOperation!accessing!public! !
DragOver:pt:pdwEffect:!COM Interfaces-IDropTarget!public! !
Drop:grfKeyState:pt:pdwEffect:!COM Interfaces-IDropTarget!public! !
dropEffect!accessing!public! !
effectsMap!accessing!public! !
endDragSourceAnswering:!private! !
finalRelease!initializing!public! !
forcedOperation!accessing!public! !
getExtendedOperation!operations!private! !
giveFeedback!operations!private! !
GiveFeedback:!COM Interfaces-IDropTarget!public! !
hideDragImage!operations!public! !
intendedDropEffect!accessing!public! !
isExtendedDrag!public!testing! !
keyState!accessing!public! !
QueryContinueDrag:grfKeyState:!COM Interfaces-IDropTarget!public! !
queryInterface:!accessing!public! !
queryInterface:ifNone:!accessing!public! !
registeredView!accessing!private! !
registeredView:!accessing!private! !
revokeDragDrop!initializing!public! !
server!accessing!public! !
showDragImage!operations!public! !
startTrackingAt:!public!tracking! !
!

!ShellDragDropSession class methodsFor!

initialize
	"
		self initialize
	"

	SessionManager current 
		when: #sessionStarted
		send: #onStartup
		to: self.
	SessionManager current 
		when: #sessionStopped
		send: #onExit
		to: self.
	self initializeRegister!

initializeRegister
	Register := WeakIdentityDictionary new!

onExit
	Register := nil!

onStartup
	"Private - The image has just started. Queue a deferredAction to re-register all drop targets once the View and COM systems
	have all be started up"

	SessionManager inputState queueDeferredAction: [self reregisterAll]!

registerDropTarget: aView
	"Answer and register an instance which is registered to receive shell drag/drop method sends for aView"

	| instance interface |
	instance := self new registeredView: aView.
	interface := instance queryInterface: IDropTarget.
	OLELibrary default registerDragDrop: aView handle pDropTarget: interface.
	Register at: aView put: instance.
	^instance!

reregisterAll
	| oldViews |
	oldViews := Register keys.
	self initializeRegister.
	oldViews do: [:each | each isOpen ifTrue: [self registerDropTarget: each]]!

revokeDropTarget: aView
	"Answer an instance which is registered to receive shell drag/drop method sends for aView"

	Register ifNotNil: [ :reg | (reg removeKey: aView ifAbsent: [^nil]) revokeDragDrop]!

uninitialize
	SessionManager current removeEventsTriggeredFor: self.
	Register := nil! !

!ShellDragDropSession class categoriesForMethods!
initialize!instance creation!public! !
initializeRegister!initializing!public! !
onExit!event handling!private! !
onStartup!event handling!private! !
registerDropTarget:!operations!public! !
reregisterAll!operations!public! !
revokeDropTarget:!operations!public! !
uninitialize!initializing!public! !
!


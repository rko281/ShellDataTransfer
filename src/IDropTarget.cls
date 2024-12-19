"Filed out from Dolphin Smalltalk"!

IUnknown subclass: #IDropTarget
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!

IDropTarget guid: (IID fromString: '{00000122-0000-0000-c000-000000000046}')!

IDropTarget comment: 'IDropTarget is a wrapper class for the IDropTarget COM interface.'!

!IDropTarget categoriesForClass!Unclassified! !

!IDropTarget methodsFor!

DragEnter: dragEnter grfKeyState: grfKeyState pt: pt pdwEffect: pdwEffect
	"Callout for the IDropTarget::DragEnter() interface function.
	N.B. This method has been automatically generated from 
	the vtable defined in IDropTarget>>defineFunctions. DO NOT MODIFY!!"

	<virtual stdcall: hresult 4 IDataObject* dword POINTL DWORD*>
	^self invalidCall: _failureCode!

DragLeave
	"Callout for the IDropTarget::DragLeave() interface function.
	N.B. This method has been automatically generated from 
	the vtable defined in IDropTarget>>defineFunctions. DO NOT MODIFY!!"

	<virtual stdcall: hresult 6>
	^self invalidCall: _failureCode!

DragOver: dragOver pt: pt pdwEffect: pdwEffect
	"Callout for the IDropTarget::DragOver() interface function.
	N.B. This method has been automatically generated from 
	the vtable defined in IDropTarget>>defineFunctions. DO NOT MODIFY!!"

	<virtual stdcall: hresult 5 dword POINTL DWORD*>
	^self invalidCall: _failureCode!

Drop: drop grfKeyState: grfKeyState pt: pt pdwEffect: pdwEffect
	"Callout for the IDropTarget::Drop() interface function.
	N.B. This method has been automatically generated from 
	the vtable defined in IDropTarget>>defineFunctions. DO NOT MODIFY!!"

	<virtual stdcall: hresult 7 IDataObject* dword POINTL DWORD*>
	^self invalidCall: _failureCode! !

!IDropTarget categoriesForMethods!
DragEnter:grfKeyState:pt:pdwEffect:!COM Interfaces-IDropTarget!public! !
DragLeave!COM Interfaces-IDropTarget!public! !
DragOver:pt:pdwEffect:!COM Interfaces-IDropTarget!public! !
Drop:grfKeyState:pt:pdwEffect:!COM Interfaces-IDropTarget!public! !
!

!IDropTarget class methodsFor!

defineFunctions
	"Declare the virtual function table for the COM interface 'oleidl.IDropTarget'
		IDropTarget  compileFunctions
		IDropTarget  compileDefinition
		IDropTarget  defineTemplate

	"

	self
		defineFunction: #DragEnter:grfKeyState:pt:pdwEffect:
			argumentTypes: 'IDataObject* dword POINTL DWORD*';
		defineFunction: #DragOver:pt:pdwEffect: argumentTypes: 'DWORD POINTL DWORD*';
		defineFunction: #DragLeave argumentTypes: '';
		defineFunction: #Drop:grfKeyState:pt:pdwEffect:
			argumentTypes: 'IDataObject* dword POINTL DWORD*'! !

!IDropTarget class categoriesForMethods!
defineFunctions!initializing!public! !
!


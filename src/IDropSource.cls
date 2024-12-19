"Filed out from Dolphin Smalltalk"!

IUnknown subclass: #IDropSource
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!

IDropSource guid: (IID fromString: '{bdfe14a1-df10-449f-946c-ced11c5356b7}')!

IDropSource comment: ''!

!IDropSource categoriesForClass!COM-Interfaces! !

!IDropSource methodsFor!

GiveFeedback: giveFeedback
	"Callout for the IDropSource::GiveFeedback() interface function.
	N.B. This method has been automatically generated from 
	the vtable defined in IDropSource>>defineFunctions. DO NOT MODIFY!!"

	<virtual stdcall: hresult 5 dword>
	^self invalidCall: _failureCode!

QueryContinueDrag: queryContinueDrag grfKeyState: grfKeyState
	"Callout for the IDropSource::QueryContinueDrag() interface function.
	N.B. This method has been automatically generated from 
	the vtable defined in IDropSource>>defineFunctions. DO NOT MODIFY!!"

	<virtual stdcall: hresult 4 bool dword>
	^self invalidCall: _failureCode! !

!IDropSource categoriesForMethods!
GiveFeedback:!COM Interfaces-IDropSource!public! !
QueryContinueDrag:grfKeyState:!COM Interfaces-IDropSource!public! !
!

!IDropSource class methodsFor!

defineFunctions
	"Declare the virtual function table for the COM interface 'oleidl.IDropSource'
		IDropSource  compileFunctions
		IDropSource  compileDefinition
		IDropSource  defineTemplate

	"

	self
		defineFunction: #QueryContinueDrag:grfKeyState:
			argumentTypes: 'bool dword';
		defineFunction: #GiveFeedback:
			argumentTypes: 'dword'! !

!IDropSource class categoriesForMethods!
defineFunctions!initializing!public! !
!


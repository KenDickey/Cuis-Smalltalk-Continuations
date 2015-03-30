'From Cuis 4.2 of 25 July 2013 [latest update: #2207] on 30 March 2015 at 7:43:13.20423 am'!
'Description Trivial port of Continuations code from SeaSide.'!
!provides: 'Continuations' 1 3!
!classDefinition: #Continuation category: #'Control-Continuations'!
Object subclass: #Continuation
	instanceVariableNames: 'values'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Control-Continuations'!
!classDefinition: 'Continuation class' category: #'Control-Continuations'!
Continuation class
	instanceVariableNames: ''!

!classDefinition: #MarkerNotFound category: #'Control-Continuations'!
Error subclass: #MarkerNotFound
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Control-Continuations'!
!classDefinition: 'MarkerNotFound class' category: #'Control-Continuations'!
MarkerNotFound class
	instanceVariableNames: ''!

!classDefinition: #MarkerRequest category: #'Control-Continuations'!
Notification subclass: #MarkerRequest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Control-Continuations'!
!classDefinition: 'MarkerRequest class' category: #'Control-Continuations'!
MarkerRequest class
	instanceVariableNames: ''!

!classDefinition: #PartialContinuation category: #'Control-Continuations'!
Object subclass: #PartialContinuation
	instanceVariableNames: 'values'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Control-Continuations'!
!classDefinition: 'PartialContinuation class' category: #'Control-Continuations'!
PartialContinuation class
	instanceVariableNames: ''!

!classDefinition: #ContinuationTest category: #'Control-Continuations'!
TestCase subclass: #ContinuationTest
	instanceVariableNames: 'tmp tmp2'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Control-Continuations'!
!classDefinition: 'ContinuationTest class' category: #'Control-Continuations'!
ContinuationTest class
	instanceVariableNames: ''!

!classDefinition: #PartialContinuationTest category: #'Control-Continuations'!
TestCase subclass: #PartialContinuationTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Control-Continuations'!
!classDefinition: 'PartialContinuationTest class' category: #'Control-Continuations'!
PartialContinuationTest class
	instanceVariableNames: ''!


!Continuation commentStamp: '<historical>' prior: 0!
Continuation class -- trivial port from Seaside

A Continuation is the Squeak implementation of a continuation. It serializes the whole stack into an array

Instance Variables
	values:		<Array>

values
	- an Array of ContextParts and the values they store
!

!PartialContinuation commentStamp: '<historical>' prior: 0!
NB: NOT a subclass of Continuation!

!Continuation methodsFor: 'private' stamp: 'KenD 3/26/2015 17:10'!
initializeFromContext: aContext
	| context stream |
	self initialize.
	context := aContext.
	stream := WriteStream on: (Array new: 200).
	[ context notNil ] whileTrue: [
		stream nextPut: context.
		1 to: context class instSize do: [ :index |
			stream nextPut: (context instVarAt: index) ].
		1 to: context size do: [ :index |
			stream nextPut: (context at: index) ].
		context := context sender ].
	values := stream contents! !

!Continuation methodsFor: 'accessing' stamp: 'KenD 3/26/2015 17:08'!
numArgs
	^ 1! !

!Continuation methodsFor: 'private' stamp: 'KenD 3/26/2015 17:10'!
restoreValues
	| stream context |
	stream := values readStream.
	[ stream atEnd ] whileFalse: [
		context := stream next.
		1 to: context class instSize do: [ :index |
			context instVarAt: index put: stream next ].
		1 to: context size do: [ :index |
			context at: index put: stream next ] ]! !

!Continuation methodsFor: 'private' stamp: 'KenD 3/26/2015 17:10'!
terminate: aContext
	| context |
	context := aContext.
	[ context notNil ] 
		whileTrue: [ context := context swapSender: nil ]! !

!Continuation methodsFor: 'evaluating' stamp: 'KenD 3/26/2015 17:08'!
value
	self value: nil! !

!Continuation methodsFor: 'evaluating' stamp: 'KenD 3/26/2015 17:08'!
value: anObject
	"Invoke the continuation and answer anObject as return value."

	self terminate: thisContext.
	self restoreValues.
	thisContext swapSender: values first.
	^ anObject! !

!Continuation methodsFor: 'evaluating' stamp: 'KenD 3/26/2015 17:10'!
valueWithArguments: anArray 
	anArray size = 1 ifFalse: 
		[ ^ self error: 'Continuations can only be resumed with one argument.' ].
	self value: anArray first! !

!Continuation methodsFor: 'evaluating' stamp: 'KenD 3/26/2015 17:10'!
valueWithPossibleArguments: anArray
	^ self value: anArray first! !

!Continuation class methodsFor: 'instance creation' stamp: 'KenD 3/26/2015 16:35'!
current
	^ self fromContext: thisContext sender! !

!Continuation class methodsFor: 'instance creation' stamp: 'KenD 3/26/2015 16:36'!
currentDo: aBlock
	^ aBlock value: (self fromContext: thisContext sender)! !

!Continuation class methodsFor: 'instance creation' stamp: 'KenD 3/26/2015 16:36'!
fromContext: aStack
	^ self basicNew initializeFromContext: aStack! !

!PartialContinuation methodsFor: 'private' stamp: 'KenD 3/28/2015 21:05'!
captureFrom: aSourceContext to: aTargetContext
	"Utilitiy method to capture the contexts between aSourceContext and aTargetContext."

	| stream context |
	context := aSourceContext.
	stream := WriteStream on: (Array new: 100).
	[ context isNil or: [ context == aTargetContext ] ] whileFalse: [
		stream nextPut: context.
		1 to: context class instSize do: [ :index |
			stream nextPut: (context instVarAt: index) ].
		1 to: context size do: [ :index |
			stream nextPut: (context at: index) ].
		context := context sender ].
	context isNil
		ifTrue: [ MarkerNotFound signal: aTargetContext printString , ' not found while capturing continuation.' ].
	^ stream contents! !

!PartialContinuation methodsFor: 'initialization' stamp: 'KenD 3/28/2015 21:05'!
initializeFrom: aSourceContext to: aTargetContext

	self initialize.
	values := self captureFrom: aSourceContext to: aTargetContext! !

!PartialContinuation methodsFor: 'accessing' stamp: 'KenD 3/28/2015 21:04'!
numArgs

	^ 1! !

!PartialContinuation methodsFor: 'private' stamp: 'KenD 3/28/2015 21:06'!
restoreValues
	"Restore the captured context chain."

	| stream context |
	stream := values readStream.
	[ stream atEnd ] whileFalse: [ 
		context := stream next.
		1 to: context class instSize do: [ :index | 
			context instVarAt: index put: stream next ].
		1 to: context size do: [ :index | 
			context at: index put: stream next ] ].
	^ context! !

!PartialContinuation methodsFor: 'private' stamp: 'KenD 3/28/2015 21:06'!
unwindFrom: aSourceContext to: aTargetContext
	"Utilitiy method to unwind and terminate from aSourceContext to aTargetContext. This implementation uses Squeak specific code implemented as primitives and is pretty fast."

	aSourceContext unwindTo: aTargetContext.
	aSourceContext terminateTo: aTargetContext! !

!PartialContinuation methodsFor: 'evaluating' stamp: 'KenD 3/28/2015 21:07'!
value

	^ self value: nil
! !

!PartialContinuation methodsFor: 'evaluating' stamp: 'KenD 3/28/2015 21:07'!
value: anObject
	"Evaluate the receiving partial continuation. Note tha partial continuations can be evaluated without a marker, in this case they are just spliced at the end of the current stack and resume return back to the sender."

	| marker |
	marker := MarkerRequest signal.
	marker isNil
		ifTrue: [ marker := thisContext sender ]
		ifFalse: [ self unwindFrom: thisContext to: marker ].
	self restoreValues swapSender: marker.
	thisContext swapSender: values first.
	^ anObject! !

!PartialContinuation methodsFor: 'evaluating' stamp: 'KenD 3/28/2015 21:10'!
valueWithArguments: anArray 

	^ (anArray size = 1)
		ifTrue: [ self value: anArray first ]
		ifFalse: 
			[ Error "InvalidArgumentCount"
				 signal: 'Continuations can only be resumed with one argument.' ]! !

!PartialContinuation methodsFor: 'evaluating' stamp: 'KenD 3/28/2015 21:09'!
valueWithPossibleArguments: anArray

	^ self value: anArray first! !

!PartialContinuation class methodsFor: 'instance creation' stamp: 'KenD 3/28/2015 21:01'!
currentDo: aBlock
	| marker |
	marker := MarkerRequest signal
		ifNil: [ MarkerNotFound signal: 'Marker not found when capturing partial continuation.' ].
	^ aBlock value: (self from: thisContext sender to: marker)! !

!PartialContinuation class methodsFor: 'instance creation' stamp: 'KenD 3/28/2015 21:02'!
from: aSourceContext to: aTargetContext

	^ self basicNew initializeFrom: aSourceContext to: aTargetContext! !

!ContinuationTest methodsFor: 'utilities' stamp: 'KenD 3/26/2015 17:45'!
callcc: aBlock
	^ Continuation currentDo: aBlock! !

!ContinuationTest methodsFor: 'tests' stamp: 'KenD 3/26/2015 17:46'!
testBlockEscape
	| x |
	tmp := 0.
	x := [ tmp := tmp + 1. tmp2 value ].
	self callcc: [ :cc | tmp2 := cc. x value ].
	tmp2 := [ ].
	x value.
	self assert: tmp = 2! !

!ContinuationTest methodsFor: 'tests' stamp: 'KenD 3/26/2015 17:46'!
testBlockTemps
	| y |
	#(1 2 3) do: [ :i |
		| x |
		x := i.
		tmp ifNil: [ tmp2 := (self callcc: [ :cc | tmp := cc. [ :q | ] ]) ].
		tmp2 value: x.
		x := 17 ].
	y := (self callcc: [ :cc | tmp value: cc. 42 ]).
	self assert: y = 1! !

!ContinuationTest methodsFor: 'tests' stamp: 'KenD 3/26/2015 17:46'!
testBlockVars
	| continuation |
	tmp := 0.
	tmp := (self callcc: [ :cc | continuation := cc. 0 ]) + tmp.
	tmp2 isNil
		ifFalse: [ tmp2 value ]
		ifTrue: [
			#(1 2 3) do: [ :i |
				self callcc: [ :cc | tmp2 := cc. continuation value: i ] ] ].
	self assert: tmp = 6! !

!ContinuationTest methodsFor: 'tests' stamp: 'KenD 3/26/2015 17:46'!
testComprehension
	"What should this print out?

	| yin yang |
	yin := [ :x | Transcript cr. x ] value: Continuation current.
	yang := [ :x | Transcript nextPut: $*. x ] value: Continuation current.
	yin value: yang"! !

!ContinuationTest methodsFor: 'tests' stamp: 'KenD 3/26/2015 17:47'!
testMethodTemps
	| i continuation |
	i := 0.
	i := i + (self callcc: [:cc | continuation := cc. 1]).
	self assert: i ~= 3.
	i = 2 ifFalse: [ continuation value: 2 ]! !

!ContinuationTest methodsFor: 'tests' stamp: 'KenD 3/26/2015 17:47'!
testReentrant
	| assoc |
	assoc := self callcc: [ :cc | cc -> 0 ].
	assoc value: assoc value + 1.
	self assert: assoc value ~= 5.
	assoc value = 4
		ifFalse: [ assoc key value: assoc ]! !

!ContinuationTest methodsFor: 'tests' stamp: 'KenD 3/26/2015 17:47'!
testSimpleCallCC
	| x continuation |
	x := self callcc: [ :cc | continuation := cc. false ].
	x ifFalse: [ continuation value: true ].
	self assert: x! !

!ContinuationTest methodsFor: 'tests' stamp: 'KenD 3/26/2015 17:47'!
testSimpleCallCCWithPossibleArgument
	| x continuation |
	x := self callcc: [ :cc | continuation := cc. false ].
	x ifFalse: [ continuation valueWithPossibleArguments: (Array with:  true) ].
	self assert: x! !

!ContinuationTest methodsFor: 'tests' stamp: 'KenD 3/26/2015 17:47'!
testSimplestCallCC
	| x |
	x := self callcc: [ :cc | cc value: true ].
	self assert: x! !

!PartialContinuationTest methodsFor: 'private' stamp: 'KenD 3/28/2015 21:12'!
callcc: aBlock

	^ PartialContinuation currentDo: aBlock! !

!PartialContinuationTest methodsFor: 'private' stamp: 'KenD 3/28/2015 21:13'!
mark: aBlock

	^ aBlock on: MarkerRequest do: [ :request | request resume: thisContext home ]! !

!PartialContinuationTest methodsFor: 'private' stamp: 'KenD 3/28/2015 21:13'!
markDiscardingResultOf: aBlock

	aBlock on: MarkerRequest do: [ :request | request resume: thisContext home ]! !

!PartialContinuationTest methodsFor: 'testing' stamp: 'KenD 3/28/2015 21:14'!
testEnsure
	| kk count |
	
	" before evaluation, ensure blocks should be unwound "
	count := 0.
	self mark: [ 2 * (self callcc: [ :cc | kk := cc. 0 ]) ].
	self assert: (self mark: [
		[ kk value: 3 ]
			ensure: [ count := count + 1 ] ])
				= 6.
	self assert: count = 1.
	
	" ensure blocks within the continuation should be unwound as well "
	count := 0.
	self mark: [ [ 2 * (self callcc: [ :cc | kk := cc. 0 ]) ] ensure: [ count := count + 1 ] ].
	self assert: count = 1.
	self assert: (kk value: 2) = 4.
	self assert: count = 2.
	self assert: (kk value: 3) = 6.
	self assert: count = 3! !

!PartialContinuationTest methodsFor: 'testing' stamp: 'KenD 3/28/2015 21:14'!
testMarkerOnValue
	| kk captured seen |
	captured := false.
	seen := false.
	self	shouldnt: [
			self markDiscardingResultOf: [ | value |
				value := self callcc: [ :cc | kk := cc. captured := true ].
				seen := true.
				value ] ]
		raise: Error.
		
	self assert: captured.
	self assert: seen.
	captured := false.
	seen := false.
	"Make sure the marker method is not included in the continuation and the continuation returns directly
	into the marker method."
	self assert: (self mark: [ kk value: 123. 456 ]) = 123.
	self deny: captured.
	self assert: seen.! !

!PartialContinuationTest methodsFor: 'testing' stamp: 'KenD 3/28/2015 21:14'!
testNestedEvaluation
	| k1 k2 |
	self assert: (self mark: [ 
		2 * (self callcc: [ :c1 | 
			k1 := c1. 
			3 * (self callcc: [ :c2 |
				k2 := c2.
				4 ]) ]) ])
					= 24.
					
	self assert: (self mark: [
		k1 value: 5 ])
			= 10.
	self assert: (self mark: [
		k2 value: 5 ])
			= 30! !

!PartialContinuationTest methodsFor: 'testing' stamp: 'KenD 3/28/2015 21:15'!
testNoMarkerOnCall
	| captured seen |
	captured := false.
	seen := false.
	self	should: [ self callcc: [ :cc | captured := true ]. seen := true ]
		raise: Error.
		
	self deny: captured.
	self deny: seen.! !

!PartialContinuationTest methodsFor: 'testing' stamp: 'KenD 3/28/2015 21:15'!
testNoMarkerOnValue
	| kk captured seen |
	captured := false.
	seen := false.
	self	shouldnt: [
			self markDiscardingResultOf: [ | value |
				value := self callcc: [ :cc | kk := cc. captured := true ].
				seen := true.
				value ] ]
		raise: Error.
		
	self assert: captured.
	self assert: seen.
	captured := false.
	seen := false.
	"Make sure the marker method was not included in the continuation"
	self assert: (kk value: 123) = 123.
	self deny: captured.
	self assert: seen.! !

!PartialContinuationTest methodsFor: 'testing' stamp: 'KenD 3/28/2015 21:15'!
testReentrant
	| kk |
	self assert: (self mark: [ 
		2 * (self callcc: [ :cc | 
			kk := cc. 2 ]) ]) 
				= 4.
	
	self assert: (self mark: [
		kk value: 3 ]) 
			= 6.
	self assert: (self mark: [
		kk value: 4 ]) 
			= 8.
	self assert: (self mark: [
		kk value: 5 ]) 
			= 10! !

!PartialContinuationTest methodsFor: 'testing' stamp: 'KenD 3/28/2015 21:15'!
testSimple

	self assert: (self mark: [ self callcc: [ :cc | cc value: true ] ])! !

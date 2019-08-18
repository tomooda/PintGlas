Class {
	#name : #PintSampler,
	#superclass : #Object,
	#instVars : [
		'samplerDirectory',
		'tapSockets',
		'tapValves'
	],
	#classVars : [
		'Server'
	],
	#category : #'PintGlas-Sampler'
}

{ #category : #'server handling' }
PintSampler class >> flushServer [
	<script: 'PintSampler flushServer'>
	Server ifNotNil: [ self stop ].
	Server := nil
]

{ #category : #'server handling' }
PintSampler class >> server [
	^ Server
		ifNil: [ Server := (ZnManagingMultiThreadedServer on: 8801)
				delegate: (ZnWebSocketDelegate handler: self new);
				yourself ]
]

{ #category : #'server handling' }
PintSampler class >> start [
	<script: 'PintSampler start'>
	self server
		register;
		start
]

{ #category : #'server handling' }
PintSampler class >> stop [
	<script: 'PintSampler stop'>
	self server
		unregister;
		stop
]

{ #category : #'request handling' }
PintSampler >> acceptBeam: tapInfo on: aWebSocket [
	| ref |
	ref := self fileReferenceForTap: tapInfo.
	ref ensureDelete.
	Transcript
		cr;
		show: 'receiving a file to ';
		show: ref printString.
	aWebSocket readMessageToFile: ref.
	Transcript
		cr;
		show: 'done'
]

{ #category : #'request handling' }
PintSampler >> acceptWait: tapInfo on: aWebSocket [
	| tapName sem |
	tapName := tapInfo at: 'name'.
	sem := self
		registerTap:
			{(tapInfo at: 'host').
			(tapInfo at: 'path').
			(tapInfo at: 'name')}.
	[ sem wait.
	Transcript
		cr;
		show: 'sending ';
		show: tapName.
	aWebSocket sendMessage: tapName ]
		ensure: [ self unregisterTap: tapName ]
]

{ #category : #defaults }
PintSampler >> defaultSamplerDirectory [
	^ (FileLocator documents / 'PintGlas') ensureCreateDirectory
]

{ #category : #accessing }
PintSampler >> fileReferenceForTap: aDictionary [
	| host path name |
	aDictionary isArray
		ifTrue: [ host := aDictionary first.
			path := aDictionary second.
			name := aDictionary third ]
		ifFalse: [ host := aDictionary at: 'host'.
			path := aDictionary at: 'path'.
			name := aDictionary at: 'name' ].
	^ (self samplerDirectory / host / (self hashPath: path) / name)
		ensureCreateDirectory
		/
			(self
				hashPath: host , path , name , Time microsecondClockValue asString)
		withExtension: 'glas'
]

{ #category : #accessing }
PintSampler >> hashPath: aString [
	^ (SHA1 hashMessage: aString asString) hex copyFrom: 1 to: 10
]

{ #category : #initialization }
PintSampler >> initialize [
	super initialize.
	tapValves := Dictionary new
]

{ #category : #'accessing - taps' }
PintSampler >> registerTap: aString [
	tapValves at: aString ifPresent: [ :sem | sem terminateProcess ].
	^ tapValves at: aString put: Semaphore new
]

{ #category : #'accessing - taps' }
PintSampler >> retrieveTap: anArray ifAbsent: errorBlock [
	(tapValves at: anArray ifAbsent: [ ^ errorBlock value ]) signal.
	tapValves removeKey: anArray
]

{ #category : #accessing }
PintSampler >> samplerDirectory [
	^ samplerDirectory
		ifNil: [ samplerDirectory := self defaultSamplerDirectory ]
]

{ #category : #'accessing - taps' }
PintSampler >> unregisterTap: anArray [
	tapValves at: anArray ifPresent: [ :sem | sem terminateProcess ].
	tapValves removeKey: anArray ifAbsent: [  ]
]

{ #category : #'request handling' }
PintSampler >> value: aWebSocket [
	| tapInfo action |
	tapInfo := STONJSON fromString: aWebSocket readMessage.
	action := tapInfo
		at: 'action'
		ifAbsent: [ Transcript
				cr;
				show: 'action not specified'.
			^ self ].
	action = 'beam'
		ifTrue: [ ^ self acceptBeam: tapInfo on: aWebSocket ].
	action = 'wait'
		ifTrue: [ ^ self acceptWait: tapInfo on: aWebSocket ].
	Transcript
		cr;
		show: 'Unknown action: ';
		show: action
]

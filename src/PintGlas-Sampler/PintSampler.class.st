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

{ #category : #defaults }
PintSampler >> defaultSamplerDirectory [
	^ (FileLocator documents / 'PintGlas') ensureCreateDirectory
]

{ #category : #accessing }
PintSampler >> fileReferenceForTap: aString [
	^ self samplerDirectory / aString withExtension: 'glas'
]

{ #category : #initialization }
PintSampler >> initialize [
	super initialize.
	tapValves := Dictionary new
]

{ #category : #'accessing - taps' }
PintSampler >> registerTap: aString [
	^ tapValves at: aString put: Semaphore new
]

{ #category : #'accessing - taps' }
PintSampler >> retrieveTap: aString ifAbsent: errorBlock [
	(tapValves at: aString ifAbsent: [ ^ errorBlock value ])
		signal;
		wait.
	^ self fileReferenceForTap: aString
]

{ #category : #accessing }
PintSampler >> samplerDirectory [
	^ samplerDirectory
		ifNil: [ samplerDirectory := self defaultSamplerDirectory ]
]

{ #category : #'accessing - taps' }
PintSampler >> unregisterTap: aString [
	tapValves removeKey: aString ifAbsent: [  ]
]

{ #category : #'request handling' }
PintSampler >> value: aWebSocket [
	| tapName ref sem |
	tapName := aWebSocket readMessage.
	sem := self registerTap: tapName.
	[ sem wait.
	aWebSocket sendMessage: tapName.
	ref := self fileReferenceForTap: tapName.
	ref ensureDelete.
	aWebSocket readMessageToFile: ref.
	sem signal ]
		ensure: [ self unregisterTap: tapName ]
]

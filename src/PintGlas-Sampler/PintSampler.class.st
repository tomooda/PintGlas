Class {
	#name : #PintSampler,
	#superclass : #Object,
	#instVars : [
		'tapSockets'
	],
	#classVars : [
		'Server'
	],
	#category : #'PintGlas-Sampler'
}

{ #category : #'server handling' }
PintSampler class >> flushServer [
	<script: 'PintSampler flushServer'>
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

{ #category : #initialization }
PintSampler >> initialize [
	super initialize.
	tapSockets := Dictionary new.
]

{ #category : #'accessing - taps' }
PintSampler >> registerTap: aString socket: aWebSocket [
	aString inspect.
	tapSockets at: aString put: aWebSocket
]

{ #category : #'accessing - taps' }
PintSampler >> tapForSocket: aWebSocket ifAbsent: errorBlock [
	^ tapSockets keyAtValue: aWebSocket ifAbsent: errorBlock
]

{ #category : #'accessing - taps' }
PintSampler >> unregisterSocket: aWebSocket [
	self
		unregisterTap: (self tapForSocket: aWebSocket ifAbsent: [ ^ self ])
]

{ #category : #'accessing - taps' }
PintSampler >> unregisterTap: aString [
	tapSockets removeKey: aString ifAbsent: [  ]
]

{ #category : #'request handling' }
PintSampler >> value: aWebSocket [
	[ aWebSocket
		runWith: [ :tapName | 
			self unregisterSocket: aWebSocket.
			self registerTap: tapName socket: aWebSocket ] ]
		on: ConnectionClosed
		do: [ :ex | self unregisterSocket: aWebSocket ]
]

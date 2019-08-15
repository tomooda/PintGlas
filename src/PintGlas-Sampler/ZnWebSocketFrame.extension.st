Extension { #name : #ZnWebSocketFrame }

{ #category : #'*PintGlas-Sampler' }
ZnWebSocketFrame class >> fileRef: aFileReference [
	^ self new
		opcode: 2;
		final: true;
		body: aFileReference;
		yourself
]

{ #category : #'*PintGlas-Sampler' }
ZnWebSocketFrame >> readBodyOfSize: size from: stream to: aFileReference [
	| mask |
	aFileReference
		binaryWriteStreamDo: [ :writeStream | 
			writeStream setToEnd.
			masked
				ifTrue: [ mask := stream next: 4.
					1 to: size do: [ :index | 
						writeStream
							nextPut: (stream next bitXor: (mask at: (index - 1) \\ 4 + 1)) ] ]
				ifFalse: [ size timesRepeat: [ writeStream nextPut: stream next ] ] ]
]

{ #category : #'*PintGlas-Sampler' }
ZnWebSocketFrame class >> readFrom: stream toFile: aFileRef [
	^ self new
		readFrom: stream toFile: aFileRef;
		yourself
]

{ #category : #'*PintGlas-Sampler' }
ZnWebSocketFrame >> readFrom: stream toFile: aFileReference [
	| byte size |
	(byte := stream next) ifNil: [ ConnectionClosed signal ].
	final := (byte bitAt: 8) = 1.
	opcode := byte bitAnd: 127.
	(byte := stream next) ifNil: [ ConnectionClosed signal ].
	masked := (byte bitAt: 8) = 1.
	size := byte bitAnd: 127.
	size < 126
		ifFalse: [ size := size = 126
				ifTrue: [ (stream next: 2) asInteger ]
				ifFalse: [ (stream next: 8) asInteger ].
			size = 0
				ifTrue: [ ConnectionClosed signal ] ].
	self isControl
		ifTrue: [ self readBodyOfSize: size from: stream ]
		ifFalse: [ self readBodyOfSize: size from: stream to: aFileReference ]
]

{ #category : #'*PintGlas-Sampler' }
ZnWebSocketFrame >> writeFileBodyOfSize: size on: stream [
	| mask |
	masked
		ifTrue: [ mask := ZnWebSocketUtils newMask.
			stream nextPutAll: mask ].
	size = 0
		ifTrue: [ ^ self ].
	body
		binaryReadStreamDo: [ :readStream | 
			masked
				ifTrue: [ | index |
					index := 0.
					[ readStream atEnd ]
						whileFalse: [ stream
								nextPut:
									(readStream next
										bitXor: (mask at: ((index := index + 1) - 1) \\ 4 + 1)) ] ]
				ifFalse:
					[ [ readStream atEnd ] whileFalse: [ stream nextPut: readStream next ] ] ]
]

{ #category : #'*PintGlas-Sampler' }
ZnWebSocketFrame >> writeFileOn: stream [
	| byte size |
	byte := (final ifTrue: [ 128 ] ifFalse: [ 0 ]) + opcode.
	stream nextPut: byte.
	byte := (masked ifTrue: [ 128 ] ifFalse: [ 0 ]).
	(size := self size) < 126
		ifTrue: [ stream nextPut: (byte + size) ]
		ifFalse: [
			size < 65536
				ifTrue: [ stream nextPut: (byte + 126); nextPutAll: (size asByteArrayOfSize: 2) ]
				ifFalse: [
					self assert: size < (2 raisedTo: 31).
					stream nextPut: (byte + 127); nextPutAll: (size asByteArrayOfSize: 8) ] ].
	self writeFileBodyOfSize: size on: stream 
]

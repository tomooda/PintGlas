Extension { #name : #ZnWebSocket }

{ #category : #'*PintGlas-Common' }
ZnWebSocket >> readFrameToFile: aFileReference [
	"Read and return the next non-control frame. Wait.
	Control frames are handled. ConnectionClosed is signalled when the other end closes."

	| frame |
	[ frame := ZnWebSocketFrame readFrom: stream toFile: aFileReference.
	frame isControl ] whileTrue: [ self handleControlFrame: frame ].
	^ frame
]

{ #category : #'*PintGlas-Common' }
ZnWebSocket >> readMessageToFile: aFileReference [
	"Read and return a complete message String or ByteArray, joining frames. 
	ConnectionClosed is signalled when the other end closes."

	[ | frame |
	frame := self readFrameToFile: aFileReference.
	frame isFinal ] whileFalse.
	^ aFileReference
]

{ #category : #'*PintGlas-Common' }
ZnWebSocket >> sendFile: aFileReference [
	"Send the content of the aFileReference in one binary frame"

	| frame |
	frame := ZnWebSocketFrame fileRef: aFileReference.
	self sendFileFrame: frame
]

{ #category : #'*PintGlas-Common' }
ZnWebSocket >> sendFileFrame: frame [
	"Send a single frame, masked when I am in a client role, flush"
	
	frame masked: self isClient.
	frame writeFileOn: stream.
	stream flush.
]

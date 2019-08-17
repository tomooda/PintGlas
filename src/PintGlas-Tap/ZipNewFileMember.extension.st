Extension { #name : #ZipNewFileMember }

{ #category : #'*PintGlas-Tap' }
ZipNewFileMember >> close [
	stream
		ifNotNil: [ stream close.
			stream := nil ]
]

{ #category : #'*PintGlas-Tap' }
ZipNewFileMember >> endRead [
	stream
		ifNotNil: [ stream close.
			stream := nil ].
	^ super endRead
]

{ #category : #'*PintGlas-Tap' }
ZipNewFileMember >> from: aFileName [

	| entry |
	"Now get the size, attributes, and timestamps, and see if the file exists"
	self localFileName: (externalFileName := aFileName).
	entry := aFileName asFileReference entry.
	compressedSize := uncompressedSize := entry size.
	desiredCompressionMethod := compressedSize > 0 ifTrue: [ CompressionDeflated ] ifFalse: [ CompressionStored ].
	self flag: 'When we replace Files with FileSystem, the following line won''t have to jump throught hoops (FS returns aDateAndTime)'.
	self modifiedAt: entry modificationTime.

]

{ #category : #'*PintGlas-Tap' }
ZipNewFileMember >> readRawChunk: n [
	^ self stream next: n
]

{ #category : #'*PintGlas-Tap' }
ZipNewFileMember >> rewindData [
	super rewindData.
	readDataRemaining := self stream size.
	self stream position: 0.
]

{ #category : #'*PintGlas-Tap' }
ZipNewFileMember >> stream [
	^ stream
		ifNil: [ stream := File openForReadFileNamed: externalFileName ]
]

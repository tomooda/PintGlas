Class {
	#name : #PintTap,
	#superclass : #Object,
	#instVars : [
		'path'
	],
	#classVars : [
		'Server'
	],
	#category : #'PintGlas-Tap'
}

{ #category : #serving }
PintTap class >> badRequest: aZnRequest [
	^ ZnResponse badRequest: aZnRequest
]

{ #category : #accessing }
PintTap class >> baseDirectory [
	^ (FileLocator documents / 'PintGlas' / 'images')
		ensureCreateDirectory;
		yourself
]

{ #category : #'instance creation' }
PintTap class >> fromUser [
	<script: 'PintTap fromUser inspect'>
	^ (UIManager default
		chooseDirectory: 'Tap directory'
		from: self baseDirectory) ifNotNil: [ :fileRef | self on: fileRef ]
]

{ #category : #serving }
PintTap class >> handleRequest: aZnRequest [
	| url pathSegments |
	url := aZnRequest url.
	url isFilePath
		ifFalse: [ ^ self badRequest: aZnRequest ].
	pathSegments := url pathSegments.
	pathSegments size ~= 2
		ifTrue: [ ^ self badRequest: aZnRequest ].
	pathSegments first = 'tap'
		ifTrue: [ | basename tap |
			basename := pathSegments second.
			(basename endsWith: '.zip')
				ifTrue: [ basename := basename copyFrom: 1 to: basename size - 4 ].
			tap := self on: self baseDirectory / basename.
			tap
				createZipAndDo: [ :zipRef | 
					^ ZnResponse
						ok:
							(ZnStreamingEntity
								readFrom: zipRef binaryReadStream
								usingType: (ZnMimeType main: 'application' sub: 'zip')
								andLength: zipRef size) ].
			^ self ].
	^ self badRequest: aZnRequest
]

{ #category : #'instance creation' }
PintTap class >> on: aFileReference [
	^ self new
		path: aFileReference;
		yourself
]

{ #category : #serving }
PintTap class >> server [
	^ Server
		ifNil: [ Server := (ZnSingleThreadedServer on: 8801) delegate: self ]
]

{ #category : #serving }
PintTap class >> start [
	<script: 'PintTap start'>
	self server
		register;
		start
]

{ #category : #serving }
PintTap class >> stop [
	<script: 'PintTap stop'>
	self server
		unregister;
		stop
]

{ #category : #snapshotting }
PintTap >> createSnapshotAndDo: aBlock [
	<script: 'PintTap fromUser createSnapshot'>
	| homeImageName tmpImageName homeImageDir tmpImageDir semaphore isClone |
	DefaultExecutionEnvironment
		beActiveDuring: [ homeImageName := Smalltalk shortImageName.
			homeImageDir := Smalltalk imageDirectory.
			tmpImageName := self path basename , '.image'.
			tmpImageDir := self path
				ensureCreateDirectory;
				yourself.
			Smalltalk
				imagePath: (tmpImageDir / tmpImageName) absolutePath fullName.
			semaphore := Semaphore new.
			[ Smalltalk snapshotPrimitive
				ifNotNil: [ :isBooting | 
					(isClone := isBooting)
						ifTrue: [ SessionManager default currentSession stop: false.
							SessionManager default installNewSession.
							SessionManager default currentSession start: isBooting.
							SystemAnnouncer uniqueInstance snapshotDone: isBooting ]
						ifFalse: [ Smalltalk
								imagePath: (homeImageDir / homeImageName) absolutePath fullName ] ].
			semaphore signal ] forkAt: Processor timingPriority - 1.
			semaphore wait.
			isClone = true
				ifTrue: [ SessionManager default currentSession
						executeDeferredStartupActions: isClone ]
				ifFalse: [ aBlock value: tmpImageDir / tmpImageName ] ]
]

{ #category : #snapshotting }
PintTap >> createZipAndDo: aBlock [
	<script: 'PintTap fromUser createSnapshot'>
	self
		createSnapshotAndDo: [ :imageRef | 
			| zip zipRef |
			zip := ZipArchive new.
			zip
				addFile: imageRef fullName
				as: self path basename , '/' , imageRef basename.
			zip
				addFile: FileLocator changes fullName
				as:
					self path basename , '/' , imageRef basenameWithoutExtension
						, '.changes'.
			zip
				addFile: Smalltalk sourcesFile fullName
				as: self path basename , '/' , Smalltalk sourcesFile basename.
			FileLocator localDirectory allChildren
				do: [ :file | 
					file isFile
						ifTrue: [ | filename |
							filename := self path basename , '/'
								, (file relativeToPath: FileLocator imageDirectory) fullName.
							Transcript
								cr;
								show: 'archive: ' , filename.
							zip addFile: file fullName as: filename ] ].
			zipRef := self path parent / (self path basename , '.zip').
			zipRef exists
				ifTrue: [ zipRef delete ].
			zipRef binaryWriteStreamDo: [ :stream | zip writeTo: stream ].
			aBlock value: zipRef ]
]

{ #category : #'library path' }
PintTap >> ffiLibraryName [ 
	^ LibC
]

{ #category : #accessing }
PintTap >> path [
	^ path
]

{ #category : #accessing }
PintTap >> path: aFileReference [
	path := aFileReference
]

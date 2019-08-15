Class {
	#name : #PintTap,
	#superclass : #Object,
	#instVars : [
		'path'
	],
	#classVars : [
		'SamplerCommunicationProcess'
	],
	#category : #'PintGlas-Tap'
}

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

{ #category : #'instance creation' }
PintTap class >> on: aFileReference [
	^ self new
		path: aFileReference;
		yourself
]

{ #category : #utilities }
PintTap class >> start [
	<script: 'PintTap start'>
	self stop.
	SamplerCommunicationProcess := [ | webSocket |
	webSocket := ZnWebSocket to: 'ws://localhost:8801'.
	[ | tapName |
	webSocket sendMessage: 'xxx'.
	tapName := nil.
	[ [ tapName := webSocket readMessage ]
		on: ConnectionTimedOut
		do: [ nil ].
	tapName isNil ] whileTrue.
	webSocket sendFile: FileLocator image ]
		ensure: [ webSocket close ] ]
		forkAt: Processor userBackgroundPriority
]

{ #category : #utilities }
PintTap class >> stop [
	<script: 'PintTap stop'>
	SamplerCommunicationProcess
		ifNotNil: [ (SamplerCommunicationProcess isTerminated
				or: [ SamplerCommunicationProcess isTerminating ])
				ifFalse: [ SamplerCommunicationProcess terminate ] ].
	SamplerCommunicationProcess := nil
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

{ #category : #accessing }
PintTap >> path [
	^ path
]

{ #category : #accessing }
PintTap >> path: aFileReference [
	path := aFileReference
]

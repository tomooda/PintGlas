Class {
	#name : #PintTap,
	#superclass : #Object,
	#instVars : [
		'path'
	],
	#classVars : [
		'CustomTapName',
		'ImageId',
		'SamplerAddress',
		'SamplerCommunicationProcess'
	],
	#category : #'PintGlas-Tap'
}

{ #category : #utilities }
PintTap class >> askToBeamUp [
	<script: '[PintTap askToBeamUp] forkAt: Processor userBackgroundPriority'>
	(Smalltalk isHeadless not
		and: [ (UIManager default confirm: 'Do you want to beam up the image?')
				= true ])
		ifTrue: [ self beamUp ]
]

{ #category : #accessing }
PintTap class >> availableSchemes [
	^ #('ws' 'wss')
]

{ #category : #accessing }
PintTap class >> baseDirectory [
	^ (FileLocator documents / 'PintGlas' / 'images')
		ensureCreateDirectory;
		yourself
]

{ #category : #utilities }
PintTap class >> beamUp [
	<script: 'PintTap beamUp'>
	[ | tapName |
	tapName := Smalltalk imageFile withoutExtension basename.
	UIManager default inform: 'Creating ' , tapName , '.glas'.
	(self
		on:
			(FileLocator imageDirectory
				/
					((SHA1 hashMessage: Time microsecondClockValue printString) hex
						copyFrom: 1
						to: 10) / tapName) ensureCreateDirectory)
		createZipAndDo: [ :ref | 
			| webSocket |
			webSocket := ZnWebSocket to: self samplerAddress.
			[ webSocket
				sendMessage:
					(STONJSON
						toString:
							(Dictionary new
								at: 'version' put: self protocolVersion;
								at: 'host' put: NetNameResolver localHostName;
								at: 'path'
									put: FileLocator imageDirectory absolutePath pathString;
								at: 'name' put: tapName;
								at: 'action' put: 'beam';
								at: 'imageId' put: self imageId;
								yourself)).
			UIManager default inform: 'sending ' , tapName , '.glas'.
			webSocket sendFile: ref.
			UIManager default inform: 'Beam up completed.' ]
				ensure: [ webSocket close ] ] ]
		forkAt: Processor userSchedulingPriority
]

{ #category : #utilities }
PintTap class >> checkForSuccessors [
	<script: 'PintTap checkForSuccessors'>
	self successors
		ifNotEmpty: [ :successors | 
			UIManager default
				alert:
					(String
						streamContents: [ :stream | 
							successors
								do: [ :tap | 
									stream
										nextPutAll: (tap at: 'host');
										nextPutAll: ':';
										nextPutAll: (tap at: 'path');
										nextPut: $/;
										nextPutAll: (tap at: 'name');
										nextPutAll: '.image (';
										nextPutAll: (tap at: 'date');
										nextPutAll: ')';
										cr ] ]) trim
				title: 'Successors of the current image...' ]
]

{ #category : #accessing }
PintTap class >> customTapName [
	^ CustomTapName ifNil: [ String new ]
]

{ #category : #accessing }
PintTap class >> customTapName: aString [
	CustomTapName := aString trim
		ifEmpty: [ nil ]
		ifNotEmpty: [ :tapName | tapName ]
]

{ #category : #defaults }
PintTap class >> defaultSamplerAddress [
	^ 'ws://localhost:8801/taps/' asUrl
]

{ #category : #accessing }
PintTap class >> ensureImageId [
	self imageId
]

{ #category : #'instance creation' }
PintTap class >> fromUser [
	<script: 'PintTap fromUser inspect'>
	^ (UIManager default
		chooseDirectory: 'Tap directory'
		from: self baseDirectory) ifNotNil: [ :fileRef | self on: fileRef ]
]

{ #category : #accessing }
PintTap class >> imageId [
	<script: 'UIManager default inform: self imageId'>
	^ ImageId
		ifNil:
			[ ImageId := (SHA1 hashMessage: Time microsecondClockValue printString)
				hex ]
]

{ #category : #initialization }
PintTap class >> initialize [
	self ensureImageId.
	SessionManager default
		registerSystemClassNamed: self name
		atPriority: 90
]

{ #category : #accessing }
PintTap class >> isLive [
	^ SamplerCommunicationProcess notNil
		and: [ SamplerCommunicationProcess isTerminated not ]
]

{ #category : #'instance creation' }
PintTap class >> on: aFileReference [
	^ self new
		path: aFileReference;
		yourself
]

{ #category : #menus }
PintTap class >> pintGlasMenuOn: aBuilder [
	<worldMenu>
	(aBuilder item: #PintGlas)
		label: 'PintGlas';
		order: 0.1;
		with: [ (aBuilder item: #PintGlasSettings)
				action: [ self showSettingBrowser ];
				label: 'settings';
				parent: #PintGlas;
				order: 0;
				help: 'Opens settings on PintGlas';
				iconName: #smallConfigurationIcon;
				withSeparatorAfter.
			(aBuilder item: #PintGlasStart)
				action: [ self beamUp ];
				label: 'beam up';
				parent: #PintGlas;
				order: 1;
				help: 'Send a snapshot to the PintGlas server';
				withSeparatorAfter.
			(aBuilder item: #PintGlasStart)
				action: [ self start ];
				enabledBlock: [ self isLive not ];
				label: 'live';
				parent: #PintGlas;
				order: 2;
				help: 'Make this session accessible from PintGlas server'.
			(aBuilder item: #PintGlasStop)
				action: [ self stop ];
				label: 'off';
				enabledBlock: [ self isLive ];
				parent: #PintGlas;
				order: 3;
				help: 'Disconnect PintGlas server';
				withSeparatorAfter;
				withSeparatorAfter.
			(aBuilder item: #PintGlasCheckForSuccessors)
				action: [ self checkForSuccessors ];
				label: 'check for successors';
				parent: #PintGlas;
				order: 3;
				help: 'Search PintGlas server for derived images' ]
]

{ #category : #menus }
PintTap class >> pintGlasSettingsOn: aBuilder [
	<systemsettings>
	(aBuilder group: #PintGlas)
		label: 'PintGlas';
		description: 'PintGlas related settings';
		noOrdering;
		with: [ (aBuilder pickOne: #samplerScheme)
				domainValues: self availableSchemes;
				label: 'Local server protocol';
				noOrdering;
				description: 'Select a websocket protocol for the local server'.
			(aBuilder setting: #samplerHost)
				label: 'Local server address';
				noOrdering;
				description: 'The local (Sampler) PintGlas server.'.
			(aBuilder setting: #samplerPort)
				label: 'Local server port number';
				noOrdering;
				description: 'The port number of local (Sampler) PintGlas server.'.
			(aBuilder setting: #usesCustomTapName)
				label: 'Use custom image name';
				noOrdering;
				description:
					'If checked then the you will be able to set an image name for PintTap. If unchecked, then the actual image name will be used.';
				with: [ (aBuilder setting: #customTapName)
						label: 'Name';
						description: 'The image name to be labeled on your image' ] ]
]

{ #category : #accessing }
PintTap class >> protocolVersion [
	^ #(0 0 1) copy
]

{ #category : #accessing }
PintTap class >> samplerAddress [
	^ SamplerAddress ifNil: [ SamplerAddress := self defaultSamplerAddress ]
]

{ #category : #accessing }
PintTap class >> samplerAddress: aZnUrl [
	SamplerAddress := aZnUrl
]

{ #category : #accessing }
PintTap class >> samplerHost [
	^ self samplerAddress host
]

{ #category : #accessing }
PintTap class >> samplerHost: aString [
	self samplerAddress host: aString
]

{ #category : #accessing }
PintTap class >> samplerPort [
	^ self samplerAddress port
]

{ #category : #accessing }
PintTap class >> samplerPort: aString [
	(aString allSatisfy: [ :char | char isDigit ])
		ifTrue: [ self samplerAddress port: aString asInteger ]
]

{ #category : #accessing }
PintTap class >> samplerScheme [
	^ self samplerAddress scheme
]

{ #category : #accessing }
PintTap class >> samplerScheme: aString [
	(self availableSchemes includes: aString)
		ifFalse: [ ^ self ].
	self samplerAddress scheme: aString
]

{ #category : #menus }
PintTap class >> showSettingBrowser [
	<script: 'PintTap showSettingBrowser'>
	SettingBrowser new
		changePackageSet: {(RPackageOrganizer default packageNamed: #'PintGlas-Tap')};
		open
]

{ #category : #'startup - shutdown' }
PintTap class >> shutDown: aBoolean [
	| context |
	context := thisContext.
	[ context := context sender.
	context notNil ]
		whileTrue: [ (context receiver class == self
				and: [ context selector = #createSnapshotAndDo: ])
				ifTrue: [ ^ self ] ].
	self updateImageId
]

{ #category : #utilities }
PintTap class >> start [
	<script: 'PintTap start'>
	self stop.
	SamplerCommunicationProcess := [ | webSocket |
	[ [ webSocket := ZnWebSocket to: self samplerAddress.
	webSocket
		sendMessage:
			(STONJSON
				toString:
					(Dictionary new
						at: 'version' put: self protocolVersion;
						at: 'host' put: NetNameResolver localHostName;
						at: 'path'
							put: FileLocator imageDirectory absolutePath pathString;
						at: 'name' put: self tapName;
						at: 'action' put: 'wait';
						at: 'imageId' put: self imageId;
						yourself)).
	UIManager default inform: 'Connected to the PintGlas server.'.
	webSocket
		runWith: [ :tapName | 
			UIManager default inform: 'Got a request for beam up.'.
			self beamUp ] ]
		on: NetworkError
		do: [ :ex | UIManager default inform: 'PintGlas disconnected.' ] ]
		ensure: [ [ webSocket close ]
				on: Error
				do: [ :ex |  ] ] ] forkAt: Processor userBackgroundPriority
]

{ #category : #'startup - shutdown' }
PintTap class >> startUp: aBoolean [
	(aBoolean and: [ self isLive ])
		ifTrue: [ self start ]
]

{ #category : #utilities }
PintTap class >> stop [
	<script: 'PintTap stop'>
	SamplerCommunicationProcess
		ifNotNil: [ (SamplerCommunicationProcess isTerminated
				or: [ SamplerCommunicationProcess isTerminating ])
				ifFalse: [ SamplerCommunicationProcess terminate.
					UIManager default inform: 'Disconnected.' ] ].
	SamplerCommunicationProcess := nil
]

{ #category : #utilities }
PintTap class >> successors [
	| url response |
	url := (ZnUrl new
		scheme:
			(self samplerScheme = 'wss'
				ifTrue: 'https'
				ifFalse: [ 'http' ]);
		host: self samplerHost;
		port: self samplerPort;
		yourself) / 'launcher-supercedes' / self imageId.
	response := ZnEasy get: url.
	response isSuccess
		ifFalse: [ ^ Array new ].
	^ STONJSON fromStream: response entity readStream
]

{ #category : #accessing }
PintTap class >> tapName [
	<script: 'PintTap tapName inspect'>
	^ CustomTapName
		ifNil: [ Smalltalk imageFile withoutExtension basename ]
]

{ #category : #accessing }
PintTap class >> tapName: aString [
	CustomTapName := aString
]

{ #category : #utilities }
PintTap class >> updateImageId [
	ImageId := self imageId , '-'
		,
			((SHA1 hashMessage: Time microsecondClockValue printString) hex
				copyFrom: 1
				to: 4)
]

{ #category : #accessing }
PintTap class >> usesCustomTapName [
	^ CustomTapName notNil
]

{ #category : #accessing }
PintTap class >> usesCustomTapName: aBoolean [
	CustomTapName := aBoolean
		ifTrue: [ self tapName ]
		ifFalse: [ nil ]
]

{ #category : #snapshotting }
PintTap >> createSnapshotAndDo: aBlock [
	<script: 'PintTap fromUser createSnapshot'>
	| homeImageName tmpImageName homeImageDir tmpImageDir semaphore isClone |
	self class updateImageId.
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
			FileLocator workingDirectory / 'meta-inf.ston'
				in: [ :ref | 
					ref exists
						ifTrue: [ zip
								addFile: ref fullName
								as: self path basename , '/' , ref basename ] ].
			FileLocator workingDirectory / 'pharo.version'
				in: [ :ref | 
					ref exists
						ifTrue: [ zip
								addFile: ref fullName
								as: self path basename , '/' , ref basename ] ].
			FileLocator localDirectory allChildren
				do: [ :file | 
					file isFile
						ifTrue: [ | filename |
							filename := self path basename , '/'
								, (file relativeToPath: FileLocator imageDirectory) fullName.
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

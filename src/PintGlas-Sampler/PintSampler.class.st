Class {
	#name : #PintSampler,
	#superclass : #Object,
	#instVars : [
		'samplerDirectory',
		'tapValves',
		'glasses'
	],
	#classVars : [
		'Server'
	],
	#category : #'PintGlas-Sampler'
}

{ #category : #'server handling' }
PintSampler class >> current [
	<script: 'PintSampler current inspect'>
	^ Server
		ifNotNil: [ (Server delegate prefixDictionary at: 'taps') handler ]
]

{ #category : #'server handling' }
PintSampler class >> flushServer [
	<script: 'PintSampler flushServer'>
	Server ifNotNil: [ self stop ].
	Server := nil
]

{ #category : #'class initialization' }
PintSampler class >> initialize [
	Smalltalk addToStartUpList: self
]

{ #category : #'server handling' }
PintSampler class >> server [
	^ Server
		ifNil: [ | handler |
			handler := self new.
			Server := ZnManagingMultiThreadedServer on: 8801.
			Server
				delegate:
					(ZnPrefixMappingDelegate new
						map: nil to: [ :request | handler indexHtml: request ];
						map: 'download' to: [ :request | handler download: request ];
						map: 'remove' to: [ :request | handler remove: request ];
						map: 'upload' to: [ :request | handler upload: request ];
						map: 'taps' to: (ZnWebSocketDelegate handler: handler);
						map: 'launcher-bottles'
							to: [ :request | handler bottlesJson: request ];
						map: 'launcher-taps'
							to: [ :request | handler liveTapsJson: request ];
						yourself);
				yourself ]
]

{ #category : #'server handling' }
PintSampler class >> start [
	<script: 'PintSampler start'>
	self server
		register;
		start
]

{ #category : #'system startup' }
PintSampler class >> startUp [
	self current ifNotNil: [ :sampler | sampler loadGlasses ]
]

{ #category : #'server handling' }
PintSampler class >> stop [
	<script: 'PintSampler stop'>
	self server
		unregister;
		stop
]

{ #category : #'request handling - tap' }
PintSampler >> acceptBeam: tap on: aWebSocket [
	| zipFileRef |
	tap
		at: 'date' put: DateAndTime now printString;
		at: 'glas-id' put: (self hash: 32).
	zipFileRef := (self zipFileFor: tap)
		ensureDelete;
		yourself.
	aWebSocket readMessageToFile: zipFileRef.
	tap at: 'size' put: zipFileRef size.
	(self glasFileFor: tap)
		ensureDelete;
		writeStreamDo: [ :stream | STONJSON put: tap onStream: stream ].
	glasses add: tap
]

{ #category : #'request handling - tap' }
PintSampler >> acceptWait: tapInfo on: aWebSocket [
	| tapName tapKey sem |
	tapName := tapInfo at: 'name'.
	tapKey := {(tapInfo at: 'host').
	(tapInfo at: 'path').
	(tapInfo at: 'name')}.
	sem := self registerTap: tapKey.
	[ [ [ 1 seconds wait.
	aWebSocket ping ] repeat ]
		on: Error
		do: [ :ex | self unregisterTap: tapKey ] ]
		forkAt: Processor userBackgroundPriority.
	[ [ sem wait.
	Transcript
		cr;
		show: 'sending ';
		show: tapName.
	aWebSocket sendMessage: tapName ] repeat ]
		ensure: [ self unregisterTap: tapName ]
]

{ #category : #'request handling - launcher' }
PintSampler >> bottlesJson: aZnRequest [
	^ ZnResponse
		ok: (ZnEntity json: (STONJSON toString: glasses asArray))
]

{ #category : #defaults }
PintSampler >> defaultSamplerDirectory [
	^ (FileLocator documents / 'PintGlas') ensureCreateDirectory
]

{ #category : #'request handling - browser' }
PintSampler >> download: aZnRequest [
	| url segments ref |
	url := aZnRequest url.
	segments := url pathSegments.
	segments size = 1
		ifFalse: [ ^ ZnResponse notFound: url ].
	ref := self
		zipFileFor:
			(Dictionary new
				at: self glasIdKey put: segments last;
				yourself).
	ref isFile
		ifFalse: [ ^ ZnResponse notFound: url ].
	^ ZnResponse
		ok:
			(ZnStreamingEntity
				readFrom: ref binaryReadStream
				usingType: (ZnMimeType main: 'application' sub: 'zip')
				andLength: ref size)
]

{ #category : #'accessing-glasses' }
PintSampler >> glasDateKey [
	^ 'date'
]

{ #category : #accessing }
PintSampler >> glasFileExtension [
	^ 'glas'
]

{ #category : #'accessing-glasses' }
PintSampler >> glasFileFor: tap [
	^ self samplerDirectory
		/
			(tap isString
				ifTrue: [ tap ]
				ifFalse: [ tap at: self glasIdKey ])
		withExtension: self glasFileExtension
]

{ #category : #'accessing-glasses' }
PintSampler >> glasHostKey [
	^ 'host'
]

{ #category : #'accessing-glasses' }
PintSampler >> glasIdKey [
	^ 'glas-id'
]

{ #category : #'accessing-glasses' }
PintSampler >> glasNameKey [
	^ 'name'
]

{ #category : #'accessing-glasses' }
PintSampler >> glasPathKey [
	^ 'path'
]

{ #category : #enumerating }
PintSampler >> glassesDo: aBlock [
	glasses do: aBlock
]

{ #category : #accessing }
PintSampler >> hash: anInteger [
	^ (SHA1 hashMessage: Time microsecondClockValue asString) hex
		copyFrom: 1
		to: anInteger
]

{ #category : #'request handling - browser' }
PintSampler >> indexHtml: aZnRequest [
	| query html now |
	query := aZnRequest url query ifNil: [ Dictionary new ].
	now := DateAndTime now.
	html := String
		streamContents: [ :stream | 
			stream
				nextPutAll: '<!DOCTYPE html>';
				cr;
				nextPutAll: '<html><title>PintGlas Sampler</title><body>';
				cr.
			stream
				nextPutAll: self uploaderScript;
				cr.
			stream
				nextPutAll: '<h1>PintGlas Sampler</h1>';
				cr.
			stream
				nextPutAll: '<h2>Live PintGlasses</h2>';
				cr;
				nextPutAll: '<table border="0">';
				cr;
				nextPutAll: '<tr><th>host</th><th>path</th><th>name</th>';
				cr.
			self liveKeys
				do: [ :array | 
					stream
						nextPutAll: '<tr><td>';
						nextPutAll: array first;
						nextPutAll: '</td><td>';
						nextPutAll: array second;
						nextPutAll: '</td><td>';
						nextPutAll: array third;
						nextPutAll: '</td><td><div style="mouse: pointer;" onclick=''PintGlas.upload("';
						nextPutAll: array first;
						nextPutAll: '","';
						nextPutAll: array second;
						nextPutAll: '","';
						nextPutAll: array third;
						nextPutAll: '")''>🚰</div></td></tr>';
						cr ].
			stream
				nextPutAll: '</table>';
				cr.
			stream
				nextPutAll: '<h2>Stock PintGlasses</h2>';
				cr;
				nextPutAll: '<form action="/" method="get">';
				nextPutAll: '<div><label>host</label><input type="text" name="host" value="';
				nextPutAll: (query at: 'host' ifAbsent: [ '' ]);
				nextPutAll: '"></div>';
				nextPutAll: '<div><label>path</label><input type="text" name="path" value="';
				nextPutAll: (query at: 'path' ifAbsent: [ '' ]);
				nextPutAll: '"></div>';
				nextPutAll: '<div><label>name</label><input type="text" name="name" value="';
				nextPutAll: (query at: 'name' ifAbsent: [ '' ]);
				nextPutAll: '"></div>';
				nextPutAll: '<div><input type="submit" value="update"></div>';
				nextPutAll: '</form>';
				cr.
			stream
				nextPutAll: '<table border="0">';
				nextPutAll: '<tr><th>host</th><th>path</th><th>name</th><th>age</th></tr>';
				cr.
			self
				query: query
				glassesDo: [ :glas | 
					stream
						nextPutAll: '<tr><td>';
						nextPutAll: (glas at: self glasHostKey);
						nextPutAll: '</td><td>';
						nextPutAll: (glas at: self glasPathKey);
						nextPutAll: '</td><td>';
						nextPutAll: (glas at: self glasNameKey);
						nextPutAll: '</td><td>';
						nextPutAll: (self printAge: (glas at: self glasDateKey) asDateAndTime);
						nextPutAll: '</td><td><a style="text-decoration-line: none;" href="download/';
						nextPutAll: (glas at: self glasIdKey);
						nextPutAll: '">🍺</a><a style="text-decoration-line: none;" href="remove/';
						nextPutAll: (glas at: self glasIdKey);
						nextPutAll: '">❌</a></td></tr>';
						cr ].
			stream
				nextPutAll: '</table>';
				cr.
			stream nextPutAll: '</body></html>' ].
	^ ZnResponse ok: (ZnEntity html: html)
]

{ #category : #initialization }
PintSampler >> initialize [
	super initialize.
	tapValves := Dictionary new.
	self loadGlasses
]

{ #category : #'request handling - tap' }
PintSampler >> liveKeys [
	^ tapValves keys
		asSortedCollection: [ :less :more | 
			less first < more first
				or: [ less first = more first
						and: [ less second < more second
								or: [ less second = more second and: [ less third <= more third ] ] ] ] ]
]

{ #category : #'request handling - launcher' }
PintSampler >> liveTapsJson: aZnRequest [
	^ ZnResponse
		ok:
			(ZnEntity
				json:
					(STONJSON
						toString:
							(self liveKeys asArray
								collect: [ :triple | 
									Dictionary new
										at: 'host' put: triple first;
										at: 'path' put: triple second;
										at: 'name' put: triple third;
										yourself ])))
]

{ #category : #'accessing-glasses' }
PintSampler >> loadGlasses [
	| newGlasses |
	newGlasses := SortedCollection
		sortBlock: [ :more :less | (less at: 'date') <= (more at: 'date') ].
	(self samplerDirectory
		childrenMatching: '*.' , self glasFileExtension)
		do: [ :ref | 
			ref
				readStreamDo: [ :stream | newGlasses add: (STONJSON fromStream: stream) ] ].
	^ glasses := newGlasses
]

{ #category : #'accessing-glasses' }
PintSampler >> moveToTrash: glas [
	glasses
		remove:
			(glasses
				detect: [ :g | (g at: self glasIdKey) = (glas at: self glasIdKey) ]
				ifNone: [ ^ self ])
		ifAbsent: [ ^ self ].
	(self glasFileFor: glas) moveTo: self trashDirectory.
	(self zipFileFor: glas) moveTo: self trashDirectory
]

{ #category : #'request handling - browser' }
PintSampler >> printAge: aDateAndTime [
	| segments |
	segments := (DateAndTime now - aDateAndTime roundTo: 1 minute)
		humanReadablePrintString substrings.
	segments isEmpty
		ifTrue: [ ^ String new ].
	segments size = 1
		ifTrue: [ ^ segments first ].
	^ String space
		join: (segments copyFrom: 1 to: (segments size min: 4))
]

{ #category : #enumerating }
PintSampler >> query: aDictionary glassesDo: aBlock [
	glasses
		do: [ :glas | 
			(self query: aDictionary matches: glas)
				ifTrue: [ aBlock value: glas ] ]
]

{ #category : #testing }
PintSampler >> query: queryDictionary matches: glasDictionary [
	queryDictionary
		keysAndValuesDo: [ :key :value | 
			value
				ifNotEmpty: [ ((glasDictionary at: key ifAbsent: [ '' ]) findString: value) = 0
						ifTrue: [ ^ false ] ] ].
	^ true
]

{ #category : #'accessing-taps' }
PintSampler >> registerTap: aString [
	tapValves at: aString ifPresent: [ :sem | sem terminateProcess ].
	^ tapValves at: aString put: Semaphore new
]

{ #category : #'request handling - browser' }
PintSampler >> remove: aZnRequest [
	| url segments tap |
	url := aZnRequest url.
	segments := url pathSegments.
	segments size = 1
		ifFalse: [ ^ ZnResponse notFound: url ].
	tap := Dictionary new
		at: self glasIdKey put: segments last;
		yourself.
	(self moveToTrash: tap) ifNil: [ ZnResponse notFound: url ].
	^ ZnResponse redirect: aZnRequest url / '..' / '..'
]

{ #category : #'accessing-taps' }
PintSampler >> retrieveTap: anArray ifAbsent: errorBlock [
	(tapValves at: anArray ifAbsent: [ ^ errorBlock value ]) signal
]

{ #category : #accessing }
PintSampler >> samplerDirectory [
	^ (samplerDirectory
		ifNil: [ samplerDirectory := self defaultSamplerDirectory ])
		ensureCreateDirectory
]

{ #category : #accessing }
PintSampler >> trashDirectory [
	^ (self samplerDirectory / '.trash')
		ensureCreateDirectory;
		yourself
]

{ #category : #'accessing-taps' }
PintSampler >> unregisterTap: anArray [
	tapValves at: anArray ifPresent: [ :sem | sem terminateProcess ].
	tapValves removeKey: anArray ifAbsent: [  ]
]

{ #category : #'request handling - browser' }
PintSampler >> upload: aZnRequest [
	aZnRequest entity
		ifNotNil: [ :entity | 
			self
				retrieveTap:
					([ STONJSON fromString: entity contents ]
						on: Error
						do: [ :ex | ^ ZnResponse notFound: aZnRequest url ])
				ifAbsent: [ ^ ZnResponse notFound: aZnRequest url ].
			^ ZnResponse ok: (ZnEntity text: 'OK') ].
	^ ZnResponse notFound: aZnRequest url
]

{ #category : #'request handling - browser' }
PintSampler >> uploaderScript [
	^ '<script type="text/javascript">
PintGlas = {};
PintGlas.upload = function (host,path,name) { 
	var req = new XMLHttpRequest();
	req.onreadystatechange = function () {
		if (req.readyState == 4) { 
			/* location.reload(true); */
		 } 
	}
	req.open("POST", "/upload");
	req.send(JSON.stringify([host,path,name]));
};
</script>' withUnixLineEndings
]

{ #category : #'request handling - tap' }
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

{ #category : #accessing }
PintSampler >> zipFileExtension [
	^ 'zip'
]

{ #category : #'accessing-glasses' }
PintSampler >> zipFileFor: tap [
	^ self samplerDirectory
		/
			(tap isString
				ifTrue: [ tap ]
				ifFalse: [ tap at: self glasIdKey ])
		withExtension: self zipFileExtension
]

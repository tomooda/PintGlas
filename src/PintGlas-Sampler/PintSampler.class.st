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
						map: 'upload' to: [ :request | handler upload: request ];
						map: 'taps' to: (ZnWebSocketDelegate handler: handler);
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

{ #category : #'server handling' }
PintSampler class >> stop [
	<script: 'PintSampler stop'>
	self server
		unregister;
		stop
]

{ #category : #'request handling - tap' }
PintSampler >> acceptBeam: tapInfo on: aWebSocket [
	| glasId zipFileRef |
	glasId := self hash: 32.
	zipFileRef := self samplerDirectory / glasId withExtension: 'zip'.
	zipFileRef ensureDelete.
	Transcript
		cr;
		show: 'receiving a file to ';
		show: zipFileRef printString.
	aWebSocket readMessageToFile: zipFileRef.
	Transcript
		cr;
		show: 'done'.
	tapInfo
		at: 'date' put: DateAndTime now printString;
		at: 'size' put: zipFileRef size;
		at: 'glas-id' put: glasId.
	(self samplerDirectory / glasId withExtension: 'glas')
		ensureDelete;
		writeStreamDo: [ :stream | STONJSON put: tapInfo onStream: stream ].
	glasses add: tapInfo
]

{ #category : #'request handling - tap' }
PintSampler >> acceptWait: tapInfo on: aWebSocket [
	| tapName tapKey sem |
	tapName := tapInfo at: 'name'.
	tapKey := {(tapInfo at: 'host').
	(tapInfo at: 'path').
	(tapInfo at: 'name')}.
	sem := self registerTap: tapKey.
	[ [ [ 60 seconds wait.
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

{ #category : #'accessing - glasses' }
PintSampler >> addGlass: aTapInfo [
	^ glasses add: aTapInfo
]

{ #category : #defaults }
PintSampler >> defaultSamplerDirectory [
	^ (FileLocator documents / 'PintGlas') ensureCreateDirectory
]

{ #category : #'request handling - browser' }
PintSampler >> download: aZnRequest [
	| url segments glasId ref |
	url := aZnRequest url.
	segments := url pathSegments.
	segments size = 1
		ifFalse: [ ^ ZnResponse notFound: url ].
	glasId := segments last.
	ref := self samplerDirectory / glasId withExtension: 'zip'.
	ref isFile
		ifFalse: [ ^ ZnResponse notFound: url ].
	^ ZnResponse
		ok:
			(ZnStreamingEntity
				readFrom: ref binaryReadStream
				usingType: (ZnMimeType main: 'application' sub: 'zip')
				andLength: ref size)
]

{ #category : #'accessing - glasses' }
PintSampler >> glasses [
	^ glasses
]

{ #category : #accessing }
PintSampler >> hash: anInteger [
	^ (SHA1 hashMessage: Time microsecondClockValue asString) hex
		copyFrom: 1
		to: anInteger
]

{ #category : #'request handling - browser' }
PintSampler >> indexHtml: aZnRequest [
	| query html |
	query := aZnRequest url query ifNil: [ Dictionary new ].
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
				nextPutAll: '<h3>PintGlas Sampler</h3>';
				cr.
			stream
				nextPutAll: '<h4>Live PintGlasses</h4>';
				cr;
				nextPutAll: '<table border="1">';
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
						nextPutAll: '</td><td><div onclick=''PintGlas.upload("';
						nextPutAll: array first;
						nextPutAll: '","';
						nextPutAll: array second;
						nextPutAll: '","';
						nextPutAll: array third;
						nextPutAll: '")''>Beam up</div></td></tr>';
						
						cr ].
			stream
				nextPutAll: '</table>';
				cr.
			stream
				nextPutAll: '<h4>Stock PintGlasses</h4>';
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
				nextPutAll: '<table border="1">';
				nextPutAll: '<tr><th>host</th><th>path</th><th>name</th><th>date</th></tr>';
				cr.
			self
				query: query
				glassesDo: [ :glas | 
					stream
						nextPutAll: '<tr><td>';
						nextPutAll: (glas at: 'host');
						nextPutAll: '</td><td>';
						nextPutAll: (glas at: 'path');
						nextPutAll: '</td><td>';
						nextPutAll: (glas at: 'name');
						nextPutAll: '</td><td>';
						nextPutAll: (glas at: 'date');
						nextPutAll: '</td><td><a href="download/';
						nextPutAll: (glas at: 'glas-id');
						nextPutAll: '">Download</a></td></tr>';
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
	glasses := SortedCollection
		sortBlock: [ :more :less | (less at: 'date') <= (more at: 'date') ].
	(self samplerDirectory childrenMatching: '*.glas')
		do: [ :ref | 
			ref
				readStreamDo: [ :stream | glasses add: (STONJSON fromStream: stream) ] ]
]

{ #category : #'request handling - tap' }
PintSampler >> liveKeys [
	^ tapValves keys asSortedCollection
]

{ #category : #'accessing - glasses' }
PintSampler >> query: aDictionary glassesDo: aBlock [
	glasses
		do: [ :glas | 
			(self query: aDictionary matches: glas)
				ifTrue: [ aBlock value: glas ] ]
]

{ #category : #'accessing - glasses' }
PintSampler >> query: queryDictionary matches: glasDictionary [
	queryDictionary
		keysAndValuesDo: [ :key :value | 
			value
				ifNotEmpty: [ ((glasDictionary at: key ifAbsent: [ '' ]) findString: value) = 0
						ifTrue: [ ^ false ] ] ].
	^ true
]

{ #category : #'accessing - taps' }
PintSampler >> registerTap: aString [
	tapValves at: aString ifPresent: [ :sem | sem terminateProcess ].
	^ tapValves at: aString put: Semaphore new
]

{ #category : #'accessing - taps' }
PintSampler >> retrieveTap: anArray ifAbsent: errorBlock [
	(tapValves at: anArray ifAbsent: [ ^ errorBlock value ]) signal
]

{ #category : #accessing }
PintSampler >> samplerDirectory [
	^ (samplerDirectory
		ifNil: [ samplerDirectory := self defaultSamplerDirectory ])
		ensureCreateDirectory
]

{ #category : #'accessing - taps' }
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
			^ ZnResponse ok: 'OK' ].
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

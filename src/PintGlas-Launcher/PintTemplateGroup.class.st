Class {
	#name : #PintTemplateGroup,
	#superclass : #PhLAbstractTemplateGroup,
	#instVars : [
		'name',
		'url'
	],
	#category : #'PintGlas-Launcher'
}

{ #category : #'instance creation' }
PintTemplateGroup class >> local [
	<script: 'PintTemplateGroup local inspect'>
	^ self name: 'Sampler at localhost' url: 'http://localhost:8801/'
]

{ #category : #'instance creation' }
PintTemplateGroup class >> name: aString url: aStringOrUrl [
	^ self new
		name: aString asString;
		url: aStringOrUrl asString;
		yourself
]

{ #category : #private }
PintTemplateGroup >> ancestorsOf: aString [
	| segments |
	segments := aString substrings: self imageIdSeparator.
	^ (segments size - 1 to: 1 by: -1)
		collect:
			[ :length | self imageIdSeparator join: (segments copyFrom: 1 to: length) ]
]

{ #category : #private }
PintTemplateGroup >> createTemplateFromTap: tapDictionary [
	^ PhLRemoteTemplate
		name:
			(self printTapName: tapDictionary)
		url:
			url asUrl / 'download'
				/ (tapDictionary at: self glasIdKey ifAbsent: [ '' ])
]

{ #category : #private }
PintTemplateGroup >> glasIdKey [
	^ 'glas-id'
]

{ #category : #private }
PintTemplateGroup >> imageIdKey [
	^ 'imageId'
]

{ #category : #private }
PintTemplateGroup >> imageIdSeparator [
	^ '-'
]

{ #category : #accessing }
PintTemplateGroup >> name [
	^ name
]

{ #category : #accessing }
PintTemplateGroup >> name: aString [
	name := aString asString
]

{ #category : #private }
PintTemplateGroup >> nameKey [
	^ 'name'
]

{ #category : #private }
PintTemplateGroup >> prefixKey [
	^ 'launcher-prefix'
]

{ #category : #private }
PintTemplateGroup >> prefixStringAtLevel: anInteger [
	^ anInteger <= 1
		ifTrue: [ '' ]
		ifFalse: [ String new: (anInteger - 1) * 4 withAll: Character space ]
]

{ #category : #private }
PintTemplateGroup >> printAge: aTap [
	| segments |
	segments := (DateAndTime now - (aTap at: 'date') asDateAndTime roundTo: 1 minute)
		humanReadablePrintString substrings.
	segments isEmpty
		ifTrue: [ ^ String new ].
	segments size = 1
		ifTrue: [ ^ segments first ].
	^ String space
		join: (segments copyFrom: 1 to: (segments size min: 4))
]

{ #category : #private }
PintTemplateGroup >> printTapName: tapDictionary [
	^ String
		streamContents: [ :stream | 
			stream
				nextPutAll: (tapDictionary at: self prefixKey ifAbsent: [ '' ]);
				nextPutAll: (tapDictionary at: self nameKey ifAbsent: [ 'no name' ]);
				nextPutAll: ' (';
				nextPutAll: (self printAge: tapDictionary);
				nextPut: $) ]
]

{ #category : #accessing }
PintTemplateGroup >> templatesAndGroups [
	| taps levels |
	taps := [ ((STONJSON
		fromStream:
			(PhLDownloadManager default
				downloadToPositionableStream: url asUrl / 'launcher-bottles'
				mimeType: ZnMimeType applicationJson
				timeout: 10))
		asSortedCollection:
			[ :less :more | (less at: self imageIdKey) <= (more at: self imageIdKey) ])
		asArray ]
		on: PhLDownloadError
		do: [ :ex | ex return: Array new ].
	levels := Dictionary new.
	^ taps
		do: [ :tap | 
			| id parent level |
			id := tap at: self imageIdKey.
			parent := (self ancestorsOf: id)
				detect: [ :i | levels includesKey: i ]
				ifNone: [ nil ].
			level := (levels at: parent ifAbsent: [ 0 ]) + 1.
			levels at: id put: level ];
		do: [ :tap | 
			tap
				at: self prefixKey
				put: (self prefixStringAtLevel: (levels at: (tap at: self imageIdKey))) ];
		collect: [ :tap | self createTemplateFromTap: tap ]
]

{ #category : #accessing }
PintTemplateGroup >> url [
	^ url
]

{ #category : #accessing }
PintTemplateGroup >> url: aStringOrUrl [
	url := aStringOrUrl asString
]

Class {
	#name : #PintTemplateGroup,
	#superclass : #PhLAbstractTemplateGroup,
	#instVars : [
		'url'
	],
	#category : #'PintGlas-Launcher'
}

{ #category : #'instance creation' }
PintTemplateGroup class >> url: aStringOrUrl [
	^ self new
		url: aStringOrUrl asUrl;
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
			(tapDictionary at: self prefixKey ifAbsent: [ '' ])
				, (tapDictionary at: self nameKey ifAbsent: [ 'no name' ])
		url: url / 'download' / (tapDictionary at: self glasIdKey ifAbsent: [ '' ])
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
	^ 'PintGlas stock at ' , url asString
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
		ifFalse:
			[ (String new: (anInteger - 1) * 4 - 2 withAll: Character space) , '+ ' ]
]

{ #category : #accessing }
PintTemplateGroup >> templatesAndGroups [
	| taps levels |
	taps := ((STONJSON
		fromStream:
			(PhLDownloadManager default
				downloadToPositionableStream: url / 'launcher'
				mimeType: ZnMimeType applicationJson))
		asSortedCollection:
			[ :less :more | (less at: self imageIdKey) <= (more at: self imageIdKey) ])
		asArray.
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
	url := aStringOrUrl asUrl
]

Class {
	#name : #PintTap,
	#superclass : #Object,
	#instVars : [
		'path'
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

{ #category : #snapshotting }
PintTap >> createSnapshot [
	<script: 'PintTap fromUser createSnapshot'>
	| homeImageName tmpImageName homeImageDir tmpImageDir |
	homeImageName := Smalltalk shortImageName.
	homeImageDir := Smalltalk imageDirectory.
	tmpImageName := self path basename , '.image'.
	tmpImageDir := self path.
	homeImageDir copyAllTo: tmpImageDir.
	(tmpImageDir / homeImageName) delete.
	(tmpImageDir / Smalltalk changesFile basename) delete.
	Smalltalk
		imagePath: (tmpImageDir / tmpImageName) absolutePath fullName.
	SessionManager default currentSession stop: false.
	Smalltalk snapshotPrimitive
		ifNotNil: [ :isBooting | 
			isBooting
				ifTrue: [ SessionManager default installNewSession ]
				ifFalse: [ Smalltalk
						imagePath: (homeImageDir / homeImageName) absolutePath fullName ].
			SessionManager default currentSession start: isBooting.
			SystemAnnouncer uniqueInstance snapshotDone: isBooting ]
]

{ #category : #archiving }
PintTap >> createZip [
	^ ZipArchive new
		addDirectory: self path as: self path basename;
		yourself
]

{ #category : #'library path' }
PintTap >> ffiLibraryName [ 
	^ LibC
]

{ #category : #private }
PintTap >> fork [
	^ self ffiCall: #(int fork #())
]

{ #category : #private }
PintTap >> fork: aBlock [
	| pid |
	pid := self fork.
	pid < 0
		ifTrue: [ self error: 'failed to fork' ].
	pid = 0
		ifTrue: [ aBlock valueNoContextSwitch ].
	Transcript
		cr;
		show: 'forked ' , pid printString
]

{ #category : #accessing }
PintTap >> path [
	^ path
]

{ #category : #accessing }
PintTap >> path: aFileReference [
	path := aFileReference
]

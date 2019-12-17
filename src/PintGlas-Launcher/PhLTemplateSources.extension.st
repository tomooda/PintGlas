Extension { #name : #PhLTemplateSources }

{ #category : #'*PintGlas-Launcher' }
PhLTemplateSources class >> samplers [
	<script: 'PhLTemplateSources samplers inspect'>
	[ self samplersFile
		readStreamDo: [ :stream | ^ STON fromStream: stream ] ]
		on: FileException
		do: [ :ex | 
			PhLUIInformation new
				message: 'Cannot fetch PintGlas samplers file: {1}'.
			^ Array new ]
]

{ #category : #'*PintGlas-Launcher' }
PhLTemplateSources >> samplers [
	^ self class samplers
]

{ #category : #'*PintGlas-Launcher' }
PhLTemplateSources class >> samplersFile [
	"File with the list of PintGlas servers for Pharo Launcher"
	^ self launcherCoreDir / 'samplers.list'
]

{ #category : #'*PintGlas-Launcher' }
PhLTemplateSources >> withSamplersCollect: aBlock [
	^ Array
		streamContents: [ :stream | 
			self samplers
				do: [ :pintTemplateGroup | stream nextPut: pintTemplateGroup ].
			self sources
				do: [ :templateSource | stream nextPut: (aBlock value: templateSource) ] ]
]

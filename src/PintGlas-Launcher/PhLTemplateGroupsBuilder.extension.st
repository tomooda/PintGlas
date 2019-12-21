Extension { #name : #PhLTemplateGroupsBuilder }

{ #category : #'*PintGlas-Launcher' }
PhLTemplateGroupsBuilder >> buildWithSamplers [
	sources ensureSourcesFile.
	^ groups := sources
		withSamplersCollect: [ :source | 
			| group |
			group := source asTemplateGroup.
			source
				templatesDo: [ :templateSource | group addTemplate: templateSource asTemplate ].
			group ]
]

{ #category : #'*PintGlas-Launcher' }
PhLTemplateGroupsBuilder class >> buildWithSamplers [
	^ self buildWithSamplersFrom: PhLTemplateSources fromFile
]

{ #category : #'*PintGlas-Launcher' }
PhLTemplateGroupsBuilder class >> buildWithSamplersFrom: aPhLTemplateSources [
	^ self new
		initializeWithSources: aPhLTemplateSources;
		buildWithSamplers
]

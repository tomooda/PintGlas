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

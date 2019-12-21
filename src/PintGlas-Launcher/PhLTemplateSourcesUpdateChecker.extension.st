Extension { #name : #PhLTemplateSourcesUpdateChecker }

{ #category : #'*PintGlas-Launcher' }
PhLTemplateSourcesUpdateChecker >> basicUpdateTemplateSources [
	PhLTemplateSources fromFile updateSourcesFile.
	PintLauncher allInstances do: [ :launcher | launcher window close ].
	PintLauncher resetTemplateRepository.
	PintLauncher openFull
]

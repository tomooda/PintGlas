Extension { #name : #PharoLauncherModel }

{ #category : #'*PintGlas-Launcher' }
PharoLauncherModel >> getTap: aDictionary [
	| client |
	client := (PhLDownloadManager default
		newHTTPClientForUrl: (aDictionary at: 'sampler-url') asUrl / 'upload')
		beOneShot;
		enforceAcceptContentType: true;
		entity:
			(ZnEntity
				json:
					(STONJSON
						toString:
							{(aDictionary at: 'host').
							(aDictionary at: 'path').
							(aDictionary at: 'name')}));
		yourself.
	PhLDownloadManager default displayProgressDuring: [ client post ].
	^ self
]

{ #category : #'*PintGlas-Launcher' }
PharoLauncherModel >> openTapDialog [
	| tapList dialog |
	tapList := MultiColumnListPresenter new
		displayBlock: [ :tap | 
			{(tap at: 'sampler-name').
			(tap at: 'host').
			(tap at: 'name').
			(tap at: 'path')} ];
		sortingBlock:
			[ :tap | tap at: 'sampler-name' ] asSortFunction
				, [ :tap | tap at: 'host' ] , [ :tap | tap at: 'name' ]
				, [ :tap | tap at: 'path' ];
		items:
			(Array
				streamContents: [ :stream | 
					PhLTemplateSources samplers
						do: [ :sampler | 
							(STONJSON
								fromStream:
									(PhLDownloadManager default
										downloadToPositionableStream: sampler url asUrl / 'launcher-taps'
										mimeType: ZnMimeType applicationJson))
								do: [ :tap | 
									stream
										nextPut:
											(tap
												at: 'sampler-url' put: sampler url;
												at: 'sampler-name' put: sampler name;
												yourself) ] ] ]);
		whenSelectedItemChanged: [ :item | dialog okButtonEnabled: item notNil ];
		yourself.
	dialog := tapList openDialogWithSpec
		okButtonEnabled: false;
		okAction: [ tapList selectedItem ifNotNil: [ :item | self getTap: item ] ]
]

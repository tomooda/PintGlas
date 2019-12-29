Extension { #name : #PharoLauncherModel }

{ #category : #'*PintGlas-Launcher' }
PharoLauncherModel >> getTap: aDictionary [
	[ PhLDownloadManager default
		displayProgressDuring: [ | client |
			client := (PhLDownloadManager default
				newHTTPClientForUrl: (aDictionary at: 'sampler-url') asUrl / 'upload')
				beOneShot;
				timeout: 10;
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
			client post ] ]
		on: PhLDownloadError
		do: [ :ex | UIManager default alert: 'Network Error' ].
	^ self
]

{ #category : #'*PintGlas-Launcher' }
PharoLauncherModel >> openTapDialog [
	| tapList dialog |
	tapList := MultiColumnListPresenter new
		title: 'Live Pharo images';
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
							([ STONJSON
								fromStream:
									(PhLDownloadManager default
										downloadToPositionableStream: sampler url asUrl / 'launcher-taps'
										mimeType: ZnMimeType applicationJson
										timeout: 10) ]
								on: PhLDownloadError
								do: [ :ex | ex return: Array new ])
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

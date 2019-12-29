Extension { #name : #PhLDownloadManager }

{ #category : #'*PintGlas-Launcher' }
PhLDownloadManager >> downloadToPositionableStream: url mimeType: mimeType timeout: anInteger [
	"Unfortunately, Zinc (and HTTP in general) doesn't support positionable streams so well. So we have to get the whole content as a collection and stream over it."

	| client content |
	client := (self newHTTPClientForUrl: url)
		beOneShot;
		timeout: anInteger;
		accept: mimeType;
		enforceAcceptContentType: true.
	self displayProgressDuring: [ content := client get ].
	^ content readStream
]

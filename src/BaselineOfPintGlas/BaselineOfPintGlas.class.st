Class {
	#name : #BaselineOfPintGlas,
	#superclass : #BaselineOf,
	#category : #BaselineOfPintGlas
}

{ #category : #baseline }
BaselineOfPintGlas >> baseline: spec [
	<baseline>
	spec
		for: #common
		do: [ spec
				baseline: 'ZincHTTPComponents'
				with: [ spec
						repository: 'github://svenvc/zinc/repository';
						loads: 'WebSocket' ].
			spec
				package: 'PintGlas-Common'
					with: [ spec requires: 'ZincHTTPComponents' ];
				package: 'PintGlas-Tap'
					with: [ spec requires: #('PintGlas-Common' 'ZincHTTPComponents') ];
				package: 'PintGlas-Sampler'
					with: [ spec requires: #('PintGlas-Common' 'ZincHTTPComponents') ];
				yourself.
			spec
				group: 'default' with: #('Tap');
				group: 'Tap' with: #('PintGlas-Tap');
				group: 'Sampler' with: #('PintGlas-Sampler') ]
]

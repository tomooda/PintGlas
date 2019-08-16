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
						loads: 'WebSocket';
						repository: 'github://svenvc/zinc/repository' ].
			spec
				package: 'Zinc-Character-Encoding-Core';
				package: 'PintGlas-Tap'
					with: [ spec requires: 'ZincHTTPComponents' ];
				package: 'PintGlas-Sampler'
					with: [ spec requires: 'ZincHTTPComponents' ];
				yourself.
			spec
				group: 'default' with: #('Tap');
				group: 'Tap' with: #('PintGlas-Tap');
				group: 'Sampler' with: #('PintGlas-Sampler') ]
]

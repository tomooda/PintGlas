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
						loads: 'WebSocket' ];
				baseline: 'PharoLauncher'
					with: [ spec repository: 'github://pharo-project/pharo-launcher/src' ].
			spec
				package: 'PintGlas-Common'
					with: [ spec requires: 'ZincHTTPComponents' ];
				package: 'PintGlas-Tap'
					with: [ spec requires: #('PintGlas-Common' 'ZincHTTPComponents') ];
				package: 'PintGlas-Sampler'
					with: [ spec requires: #('PintGlas-Common' 'ZincHTTPComponents') ];
				package: 'PintGlas-Launcher'
					with: [ spec requires: 'PharoLauncher' ].
			spec
				group: 'default' with: #('tap');
				group: 'tap' with: #('PintGlas-Tap');
				group: 'sampler' with: #('PintGlas-Sampler');
				group: 'launcher' with: #('PintGlas-Launcher') ]
]

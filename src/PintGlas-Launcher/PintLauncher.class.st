Class {
	#name : #PintLauncher,
	#superclass : #PharoLauncher,
	#category : #'PintGlas-Launcher'
}

{ #category : #'instance creation' }
PintLauncher class >> createLauncher [
	<script: 'PintLauncher open'>
	^ self
		createLauncherWithGroups: PhLTemplateGroupsBuilder buildWithSamplers
]

{ #category : #private }
PintLauncher >> commandClassesForTemplatesToolbar [
	^ {PintLauncherOpenTapDialogCommand}
		, super commandClassesForTemplatesToolbar
]

{ #category : #initialization }
PintLauncher >> setImageRepository: anImageRepository templateRepository: aTemplateRepository [
	TemplateRepository := aTemplateRepository.
	imageRepository := anImageRepository
]

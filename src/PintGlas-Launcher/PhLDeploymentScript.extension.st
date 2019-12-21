Extension { #name : #PhLDeploymentScript }

{ #category : #'*PintGlas-Launcher' }
PhLDeploymentScript class >> closeWindowsAndOpenDevelopmentEnvironment [
	PanelMorph allInstancesDo: [  :pm | pm delete ].
	self closeAllWindows.
	TaskbarMorph reset.
	Workspace open contents: self launcherClass name, ' open.'.
	
	"PanelMorph comes from use of #openWorldWithSpec"
]

{ #category : #'*PintGlas-Launcher' }
PhLDeploymentScript class >> launcherClass [
	^ PintLauncher
]

{ #category : #'*PintGlas-Launcher' }
PhLDeploymentScript class >> openLauncher [
	self launcherClass openFull
]

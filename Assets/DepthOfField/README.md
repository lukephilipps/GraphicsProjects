# Depth of Field

A depth of field effect with exposed parameters for altering:
* Circle of confusion
* CoC near bound effects (max filter, box blur)
* CoC blurring
* HDR

made for the Unity built-in pipeline.

This effect uses [Acerola's Karis average weighted blur](https://youtu.be/v9x_50czf-4?si=wkr0O45unljt7Su8) when blurring the CoC.

## Usage
Import the .unitypackage file into your scene and simply attach the script to your camera to use the features. The DepthOfFieldEditor.cs file *must* stay in the Editor folder or Unity will not display the easily editable parameters.

## Screenshots
### Scene Pre-DOF Pass
![A forest scene pre-DOF pass.](/DemoScreenshots/DepthOfField_0.png)
### After Applying DOF
![The forest scene after applying DOF.](/DemoScreenshots/DepthOfField_1.png)
### Combined With My [Palette Swapper](/Assets/PaletteSwapping/)
![The scene combined with my palette swapper effect.](/DemoScreenshots/DepthOfField_2.png)

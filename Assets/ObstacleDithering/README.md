# Obstacle Dithering

An effect that dithers possibly obstructive objects that are close to the camera.

The effect works by rendering 'obstacle' objects to a seperate RenderTarget which is used to partially shade the objects on the main camera. Before rendering, the objects will be changed to a seperate layer so that the whole scene isn't rendered twice and only the obstacles- this means that a dummy layer must be created.

## Usage
Import the .unitypackage file into your scene and attach the DitherObstacles.cs script to your camera to use the features. Create a new layer, and set the script's Close Layer property to said layer. Objects in the scene should not use this layer.

The LayerAttributeEditor.cs file *must* stay in the Editor folder or Unity will not display the easily editable parameters.

## Screenshots
### Undithered Obstacle
![An undithered obstacle.](/DemoScreenshots/ObstacleUndithered.png)
### Dithered Obstacle
![The dithered obstacle.](/DemoScreenshots/ObstacleDithered.png)

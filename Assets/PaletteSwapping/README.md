# Palette Swapper

A palette swapping effect supporting:
* Image downscaling (pixelization)
* Color quantizing
* Palette swapping based on pixel luminance

made for the Unity built-in pipeline.

## Usage
Import the .unitypackage file into your scene and simply attach the script to your camera to use the features. The PaletteSwapperEditor.cs file *must* stay in the Editor folder or Unity will not display the easily editable parameters.

The Channel Color Count and Per Channel Color Count options will limit the count of available colors to the rendered scene's RGB channels. The Palette Swapping effect takes in a color palette (check the Palettes folder for references) and swaps pixels based on luminance. Left-most of the palette will be the least luminant pixels and right-most will be the most.

## Screenshots
![A forest that has been shifted to have cool blues under the shade of trees and warm reds under the sun.](/DemoScreenshots/PaletteSwap_1.png)
![A field thats had its red color channel limited to 2 colors.](/DemoScreenshots/PaletteSwap_0.png)

# Billboard Grass

A billboard grass implementation based on [Acerola's video on the topic](https://youtu.be/Y0Ko0kvwfgA?si=2Yyv651xJ9TwYl72). This effect utilizes compute shaders and indirect rendering to leverage the GPU's parallelization-focused abilities for maximized FPS.

### Disclaimer
This effect was made to be a demonstration of compute shaders, and as such isn't built for use in actual Unity projects at the moment. The terrain that the grass is rendered on lacks collider functionality meaning it couldn't be used in most scenarios.

![A field of grass swaying in the wind.](/DemoScreenshots/Grass.gif)

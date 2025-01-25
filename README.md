# LCD Effect Shader for ReShade
This is a simple shader I wrote to evoke the look of a lower resolution LCD monitor. Currently the only implementation is for [ReShade](https://reshade.me/).

## Concept
The idea for this effect is break the display into 3x2 pixel blocks. The pixels within those blocks can be treated as the red, green, and blue subpixels. 

The default behavior is to find the average color of these 6 pixels. Then the top 3 pixels of the block are treated as the red, greed, and blue channels of that color, while the bottom 3 pixels are simply turned the average color.

This effect works, but it darkens the image significantly, because the intensity of the base color is spread across the top 3 pixels. To mitigate this, the intensity of the subpixels can be modulated with Boost Parameter.

That is the effect as I originally thought of it, but I figured why not parameterize the rest of it.

So the top and bottom halves of the block can be configured indepentedly with 3 options:

### Big Pixel
This means that the 3 subpixels will all be made the average color of all 6 pixels in the block. 

### RGB
This means that the first subpixel will be reduced to its red channel, the second to its green channel, and the third to its blue channel. When you activitate this without the Big Pixel setting, it preserves slightly more detail, since percevied lightness of the original image is partially preserved.

### Lum Boost
This only has an effect when the RGB setting is also active on the same block. This is a lerp value between the pre boost color and the boosted amount. Additionally, there is a checkbox to clamp the result between 0.0 and 1.0. While it makes the most sense to clamp it, I found in testing it can look cool when it overflows and you get blown out pixels. 

### Mask UI
This effect is specifically for if you are using this shader for Final Fantasy XIV. It uses the alpha channel of the base image as a mask for the effect, which means it may work (or behave unpredicatably) when used with other applications. I borrowed this masking implementaiton directly from [Acerola](https://github.com/GarrettGunnell/AcerolaFX/tree/main).

## Future Improvements
While this effect is "mostly finished", there are still possibly improvements. 
- The Lum Boost feature could be reworked. I think the boost factor should be moved into the ShiftLumToChannel method so that it occurs BEFORE the clamp, rather than as a lerp between the base and boosted value. 
- A scale parameter would be nice, to make the pixels even bigger, simply to show off the effect. 
- It might be fun to experiment with diffent subpixel patterns. That should probably be its own dedicated shader, but might share some code. 
- I would like to implement this in other shader languages, especially for Godot, which is similar to GLSL. 

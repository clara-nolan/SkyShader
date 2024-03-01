# Dynamic Sky Shader Description

This shader dynamically simulates the sky's appearance over time, transitioning through different parts of the day—sunrise, morning, midday, sunset, and night—using OpenGL Shading Language (GLSL) version 150. The shader is designed to run on the GPU for real-time graphics applications, such as video games, rendering a visually compelling skybox that changes based on the time within the game world. Watch a full cycle by clicking the image below!
[![Watch the video](https://img.youtube.com/vi/mwNiWVoK5KM/maxresdefault.jpg)](https://www.youtube.com/watch?v=mwNiWVoK5KM)


## Shader Uniforms
- `u_ViewProj`: The inverse of the view projection matrix, used for transforming screen space coordinates back into world space coordinates.
- `u_Dimensions`: The dimensions of the screen, used for normalizing device coordinates (NDC).
- `u_Eye`: The camera's position in the world, used for calculating ray directions from the camera to render the sky.
- `u_Time`: The current time within the game world, used to determine the sky's appearance based on the time of day.

## Key Concepts

### Time-Based Color Interpolation
The shader utilizes linear interpolation between predefined color palettes for sunrise, morning, midday, sunset, and night to simulate the changing sky colors throughout the day. These colors are applied based on the `u_Time` uniform, allowing for a smooth transition between times of day.

### Polar Coordinates for Sky Mapping
The shader converts Cartesian coordinates to polar coordinates to map the 3D direction vectors onto a 2D sphere representing the sky. This technique is used to determine the UV coordinates for applying the sky colors based on the direction the camera is facing.

### Dynamic Clouds and Sun Position
Worley noise is implemented to simulate clouds dynamically across the sky. The noise function is animated based on `u_Time`, creating an ever-changing sky. The sun's position also changes over time, calculated using the time of day to simulate sunrise and sunset accurately.

### Sky Gradient and Sun Rendering
The shader creates a gradient for the sky's appearance, smoothly blending between different colors based on the UV coordinates. The sun is rendered as a bright disc in the sky, with its intensity and position varying based on the time of day. The shader calculates the angle between the view direction and the sun's position to render the sun and its corona effect.

## Technical Implementation
The shader defines several functions to convert between coordinate systems, interpolate between colors based on time, and calculate noise values for cloud simulation. It uses the `u_Time` uniform to determine the current time of day and selects the appropriate color palette for rendering the sky. The final color of each pixel is determined by the ray direction from the camera, the time of day, and the calculated noise values for clouds.

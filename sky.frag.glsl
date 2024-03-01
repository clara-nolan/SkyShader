#version 150

uniform mat4 u_ViewProj;    // We're actually passing the inverse of the viewproj
// from our CPU, but it's named u_ViewProj so we don't
// have to bother rewriting our ShaderProgram class

uniform ivec2 u_Dimensions; // Screen dimensions

uniform vec3 u_Eye; // Camera pos

uniform float u_Time;

out vec4 outColor;

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

// Using this to determine time periods for sunrise, morning, midday, sunset, and night
const int DAY_LENGTH = 10000;

// Clara Comment: The color of the sky is determined by linearly interpolating the colors stored in these arrays

// Sunrise palette
const vec3 sunrise[5] = vec3[](vec3(255, 197, 197) / 255.0,
vec3(249,243,255) / 255.0,
vec3(249,243,255) / 255.0,
vec3(242,173,115) / 255.0,
vec3(255,163,69) / 255.0);

// Midday palette
const vec3 midday[5] = vec3[](vec3(255, 197, 197) / 255.0,
vec3(195,221,245) / 255.0,
vec3(179,210,239) / 255.0,
vec3(159,197,232) / 255.0,
vec3(128,182,232) / 255.0);

// Morning palette
const vec3 morning[5] = vec3[](vec3(100, 208, 227) / 255.0,
vec3(225,241,255) / 255.0,
vec3(225,241,255) / 255.0,
vec3(243,250,255) / 255.0,
vec3(229,243,255) / 255.0);

// Sunset palette
const vec3 sunset[5] = vec3[](vec3(255, 229, 119) / 255.0,
vec3(254, 192, 81) / 255.0,
vec3(255, 137, 103) / 255.0,
vec3(253, 96, 81) / 255.0,
vec3(57, 32, 51) / 255.0);

// Night palette
const vec3 night[5] = vec3[](vec3(5, 92, 153) / 255.0,
vec3(6, 74, 122) / 255.0,
vec3(24, 17, 156) / 255.0,
vec3(22, 1, 66) / 255.0,
vec3(0, 0, 0) / 255.0);

/*
// Sun palette
const vec3 sun[4] = vec3[](vec3(255, 154, 41) / 255.0,
                           vec3(255, 240, 119) / 255.0,
                           vec3(241, 92, 0) / 255.0,
                           vec3(0, 0, 0) / 255.0);
*/
// Going to use this later on to change whether or not there is a sun in the sky based off of time
vec3 sunColor = vec3(255, 240, 119) / 255.0;
vec3 currSkyColor;

//const vec3 sunColor = vec3(255, 255, 190) / 255.0;
const vec3 cloudColor = sunset[3];


// Clara Comment: Takes a vec3 (in cartesian coordinates) and tranforms it to a UV coordinate using polar coordinates
vec2 sphereToUV(vec3 p) {
    float phi = atan(p.z, p.x); // Clara Comment: using polar coordinates here
    if(phi < 0) {
        phi += TWO_PI;
    }
    float theta = acos(p.y);
    return vec2(1 - phi / TWO_PI, 1 - theta / PI);
}

// Clara Comment: These following uvTo... functions take in UV coordinates and map them to the sky's color.
// LERP/mix is used to linearly interpolate between the color values in order to create a gradient/transition from each cloudColor
//
vec3 uvToNight(vec2 uv) {
    // Clara Comment: 0.5 is being used here to represent the horizon line
    if(uv.y < 0.5) {
        return night[0];
    }
    else if(uv.y < 0.55) {
        return mix(night[0], night[1], (uv.y - 0.5) / 0.05);
    }
    else if(uv.y < 0.6) {
        return mix(night[1], night[2], (uv.y - 0.55) / 0.05);
    }
    else if(uv.y < 0.65) {
        return mix(night[2], night[3], (uv.y - 0.6) / 0.05);
    }
    else if(uv.y < 0.75) {
        return mix(night[3], night[4], (uv.y - 0.65) / 0.1);
    }
    // Clara Comment: If we reach this case, we are straight up from the horizon line / at a 90 degree vertical angle
    return night[4];
}

vec3 uvToMorning(vec2 uv) {
    if(uv.y < 0.5) {
        return morning[0];
    }
    else if(uv.y < 0.55) {
        return mix(morning[0], morning[1], (uv.y - 0.5) / 0.05);
    }
    else if(uv.y < 0.6) {
        return mix(morning[1], morning[2], (uv.y - 0.55) / 0.05);
    }
    else if(uv.y < 0.65) {
        return mix(morning[2], morning[3], (uv.y - 0.6) / 0.05);
    }
    else if(uv.y < 0.75) {
        return mix(morning[3], morning[4], (uv.y - 0.65) / 0.1);
    }
    return morning[4];
}

vec3 uvToSunrise(vec2 uv) {
    if(uv.y < 0.5) {
        return sunrise[0];
    }
    else if(uv.y < 0.55) {
        return mix(sunrise[0], sunrise[1], (uv.y - 0.5) / 0.05);
    }
    else if(uv.y < 0.6) {
        return mix(sunrise[1], sunrise[2], (uv.y - 0.55) / 0.05);
    }
    else if(uv.y < 0.65) {
        return mix(sunrise[2], sunrise[3], (uv.y - 0.6) / 0.05);
    }
    else if(uv.y < 0.75) {
        return mix(sunrise[3], sunrise[4], (uv.y - 0.65) / 0.1);
    }
    return sunrise[4];
}

vec3 uvToSunset(vec2 uv) {
    if(uv.y < 0.5) {
        return sunset[0];
    }
    else if(uv.y < 0.55) {
        return mix(sunset[0], sunset[1], (uv.y - 0.5) / 0.05);
    }
    else if(uv.y < 0.6) {
        return mix(sunset[1], sunset[2], (uv.y - 0.55) / 0.05);
    }
    else if(uv.y < 0.65) {
        return mix(sunset[2], sunset[3], (uv.y - 0.6) / 0.05);
    }
    else if(uv.y < 0.75) {
        return mix(sunset[3], sunset[4], (uv.y - 0.65) / 0.1);
    }
    return sunset[4];
}

vec3 uvToMidday(vec2 uv) {
    if(uv.y < 0.5) {
        return midday[0];
    }
    else if(uv.y < 0.55) {
        return mix(midday[0], midday[1], (uv.y - 0.5) / 0.05);
    }
    else if(uv.y < 0.6) {
        return mix(midday[1], midday[2], (uv.y - 0.55) / 0.05);
    }
    else if(uv.y < 0.65) {
        return mix(midday[2], midday[3], (uv.y - 0.6) / 0.05);
    }
    else if(uv.y < 0.75) {
        return mix(midday[3], midday[4], (uv.y - 0.65) / 0.1);
    }
    return midday[4];
}

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
}

float WorleyNoise3D(vec3 p)
{
    // Tile the space
    vec3 pointInt = floor(p);
    vec3 pointFract = fract(p);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int z = -1; z <= 1; z++)
    {
        for(int y = -1; y <= 1; y++)
        {
            for(int x = -1; x <= 1; x++)
            {
                vec3 neighbor = vec3(float(x), float(y), float(z));

                // Random point inside current neighboring cell
                vec3 point = random3(pointInt + neighbor);

                // Animate the point
                point = 0.5 + 0.5 * sin(u_Time * 0.01 + 6.2831 * point); // 0 to 1 range

                // Compute the distance b/t the point and the fragment
                // Store the min dist thus far
                vec3 diff = neighbor + point - pointFract;
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}

float WorleyNoise(vec2 uv)
{
    // Tile the space
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int y = -1; y <= 1; y++)
    {
        for(int x = -1; x <= 1; x++)
        {
            vec2 neighbor = vec2(float(x), float(y));

            // Random point inside current neighboring cell
            vec2 point = random2(uvInt + neighbor);

            // Animate the point
            point = 0.5 + 0.5 * sin(u_Time * 0.01 + 6.2831 * point); // 0 to 1 range

            // Compute the distance b/t the point and the fragment
            // Store the min dist thus far
            vec2 diff = neighbor + point - uvFract;
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    return minDist;
}

float worleyFBM(vec3 uv) {
    float sum = 0;
    float freq = 4;
    float amp = 0.5;
    for(int i = 0; i < 8; i++) {
        sum += WorleyNoise3D(uv * freq) * amp;
        freq *= 2;
        amp *= 0.5;
    }
    return sum;
}

// Clara Comment: Ray as color is showing us the direction for each fragment of the ray cast trhough that fragment off in space
//#define RAY_AS_COLOR
// Clara Comment: This maps a XYZ direction to a UV coordinate on a sphere around the player's position
//#define SPHERE_UV_AS_COLOR


void main()
{
    // Clara Comment: NDC means normalized device coordinate, so this is how we're getting to world space
    vec2 ndc = (gl_FragCoord.xy / vec2(u_Dimensions)) * 2.0 - 1.0; // -1 to 1 NDC

    vec4 p = vec4(ndc.xy, 1, 1); // Pixel at the far clip plane

    p *= 1000.0; // Times far clip plane value

    p = /*Inverse of*/ u_ViewProj * p; // Convert from unhomogenized screen to world

    vec3 rayDir = normalize(p.xyz - u_Eye); // Clara Comment: represents the ray direction from the camera/player position

    vec2 uv = sphereToUV(rayDir); // Clara Comment: Getting our UV value by converting from cartesian representation to polar

    vec2 offset = vec2(0.0);

    // Get a noise value in the range [-1, 1]
    // by using Worley noise as the noise basis of FBM
    offset = vec2(worleyFBM(rayDir));
    offset *= 2.0;
    offset -= vec2(1.0);


    // Compute a gradient from the bottom of the sky-sphere to the top
    vec3 sunriseColor = uvToSunrise(uv + offset * 0.1);
    vec3 morningColor = uvToMorning(uv + offset * 0.1);
    vec3 middayColor = uvToMidday(uv + offset * 0.1);
    vec3 sunsetColor = uvToSunset(uv + offset * 0.1);
    vec3 nightColor = uvToNight(uv + offset * 0.1);

    float time = u_Time *1.f;
    // Clara Comment: Map the current time to the range [0, 1] based on the day length
    // Clara Comment: Want to think of time in terms of our 10,000 tick long day night cycle
    float interval = mod(float(int(time)), DAY_LENGTH); // Clara Comment: Needed to do some weird casting to get this to work
    float intervalEnd = 2000.0; // Clara Comment: Splitting into 5 2000 tick long intervals


    float smallerTime = mod(time, DAY_LENGTH) / float(DAY_LENGTH);
      // Clara Comment: Sun direction ony changes on YZ plane, so we leave X to be 0
    vec3 sunDir = vec3(0.0f, sin(smallerTime * TWO_PI), cos(smallerTime * TWO_PI));

        // Calculate sky color based on the time interval
        if (interval < 2000) {
            float lerp = (interval - 0.0) / intervalEnd;
            float t = WorleyNoise3D(rayDir * 50);
            vec3 nColor = t < 0.1 ? vec3(1, 1, 1) : vec3(0, 0, 0);
            currSkyColor = mix(nColor, morningColor + (sunriseColor - 0.05), lerp);
        } else if (interval < 4000) {
            float lerp = (interval - 2000.0) / intervalEnd;
            currSkyColor = mix(morningColor, middayColor, lerp);
        } else if (interval < 6000) {
            float lerp = (interval - 4000.0) / intervalEnd;
            currSkyColor = mix(middayColor, sunsetColor, lerp);
        } else if (interval < 8000) {
            float lerp = (interval - 6000.0) / intervalEnd;
            currSkyColor = mix(sunsetColor, nightColor, lerp);
        } else if (interval < 10000) {
            float lerp = (interval - 8000.0) / intervalEnd;
            float t = WorleyNoise3D(rayDir * 50);
            vec3 nColor = t < 0.1 ? vec3(1, 1, 1) : vec3(0, 0, 0);
            currSkyColor = mix(nightColor, nColor, lerp);
        }

    float sunSize = 30;
    float angle = acos(dot(rayDir, sunDir)) * 360.0 / PI;

    // If the angle between our ray dir and vector to center of sun
    // is less than the threshold, then we're looking at the sun
    if (angle < sunSize) {
        // Full center of sun
        if (angle < 7.5) {
            currSkyColor = sunColor;
        }
        // Corona of sun, mix with sky color
        else {

            currSkyColor = mix(sunColor, currSkyColor + 0.1, (angle - 7.5) / 22.5);
        }
    }
    // Otherwise our ray is looking into just the sky

    outColor = vec4(currSkyColor, 1.0);
}

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform bool upperBlock <
    ui_category = "Upper Half";
    ui_label = "Big Upper Pixel";
    ui_tooltip = "Use Big Pixel for upper half";
> = true;

uniform bool upperRGB <
    ui_category = "Upper Half";
    ui_label = "Upper RGB LCD Effect";
    ui_tooltip = "LCD Effect on Upper Half";
> = true;

uniform float upperLumBoost < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Upper Half";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_label = "Upper RGB Lum Boost";
	ui_tooltip = "Ammount to boost Luminance for Upper Half LCD Effect";
> = 0.5;

uniform bool clampUpperRGB <
    ui_category = "Upper Half";
    ui_label = "Clamp Upper RGB Boost";
    ui_tooltip = "it looks better when you don't clamp it. eyeroll";
> = true;

uniform bool lowerBlock <
    ui_category = "Lower Half";
    ui_label = "Big Lower Pixel";
    ui_tooltip = "Use Big Pixel for lower half";
> = true;

uniform bool lowerRGB <
    ui_category = "Lower Half";
    ui_label = "Lower RGB LCD Effect";
    ui_tooltip = "LCD Effect on Lower Half";
> = false;

uniform float lowerLumBoost < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Lower Half";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
	ui_label = "Lower RGB Lum Boost";
	ui_tooltip = "Ammount to boost Luminance for Lower Half LCD Effect";

> = 0.5;

uniform bool clampLowerRGB <
    ui_category = "Lower Half";
    ui_label = "Clamp Lower RGB Boost";
    ui_tooltip = "it looks better when you don't clamp it. eyeroll";
> = true;

// borrowed this from Acerola
uniform bool _MaskUI <
    ui_label = "Mask UI";
    ui_tooltip = "Mask UI (disable if dithering/crt effects are enabled).";
> = true;

float GetLum(float4 col){
    return saturate(0.2126*col.x + 0.7152*col.y + 0.0722*col.z);
}

float4 ShiftLumToChannel(float4 col, int i, bool isUpper)
{
    float d = 1 + (0.2126*col.r*(i != 0) + 0.7152 * col.g * (i != 1) + 0.0722 * col.b * (i != 2)) / (0.2126*col.r*(i == 0) + 0.7152 * col.g * (i == 1) + 0.0722 * col.b * (i == 2));
    float3 lumAdjusted = float3(saturate(col.rgb * d)*(clampUpperRGB && isUpper) + (col.rgb * d) * (!clampUpperRGB && isUpper));
    lumAdjusted += float3(saturate(col.rgb * d)*(clampLowerRGB && !isUpper) + (col.rgb * d) * (!clampLowerRGB && !isUpper));
    // float3 lumAdjusted = float3(saturate(col.rgb * d)*(clampUpperRGB && isUpper) + (col.rgb * d) * (!clampUpperRGB && isUpper) + saturate(col.rgb * d)*(clampLowerRGB && !isUpper) + (col.rgb * d) * (!clampLowerRGB && !isUpper));
    return float4(lumAdjusted, col.a);
}

float4 GetBigPixelColor(sampler2D texSampler, float2 texcoord)
{
    float2 uv = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 unit = float2(1.0,1.0) / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 upperLeft = float2(floor(uv.x / 3.0) * 3.0, floor(uv.y / 2.0) * 2.0) / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float4 col = float4(0f,0f,0f,1f);
    for (uint i = 0; i < 2; i++)
    {
        for (uint j = 0; j < 3; j++)
        {
            col += tex2D(texSampler, upperLeft + unit * float2(j,i));
        }
    }

    return col / 6.0;
}

float4 LCDPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float4 col = tex2D(ReShade::BackBuffer, texcoord);

    uint xCoord = floor(texcoord.x * BUFFER_WIDTH);
    uint yCoord = floor(texcoord.y * BUFFER_HEIGHT);
    bool isUpper = (yCoord % 2 == 0);
    float4 blockCol = GetBigPixelColor(ReShade::BackBuffer, texcoord);
    col = float4(lerp(col.rgb, blockCol, (isUpper && upperBlock) || (!isUpper && lowerBlock)), col.a);

    uint xIndex = xCoord % 3;

    float4 rgbCol = float4(col.r * (xIndex == 0), col.g * (xIndex == 1), col.b * (xIndex == 2), col.a);
    float4 lumRGBCol = ShiftLumToChannel(col, xIndex, isUpper);

    rgbCol = float4(lerp(rgbCol, lumRGBCol, isUpper * upperLumBoost + !isUpper * lowerLumBoost));

    col = float4(lerp(col, rgbCol, (isUpper && upperRGB) || (!isUpper && lowerRGB))); 

    //mask ui (borrowed from Acerola)
    float4 originalCol = tex2D(ReShade::BackBuffer, texcoord);

    return float4(lerp(col.rgb, originalCol.rgb, originalCol.a * _MaskUI), originalCol.a);
}

technique wolscottLCD
{
    pass LCDEffect
    {
        VertexShader = PostProcessVS;
		PixelShader = LCDPass;
    }
}


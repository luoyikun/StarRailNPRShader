/*
 * StarRailNPRShader - Fan-made shaders for Unity URP attempting to replicate
 * the shading of Honkai: Star Rail.
 * https://github.com/stalomeow/StarRailNPRShader
 *
 * Copyright (C) 2023 Stalo <stalowork@163.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

Shader "Hidden/Honkai Star Rail/Post Processing/Bloom"
{
    Properties
    {
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        ZTest Always
        ZWrite Off
        Cull Off

        HLSLINCLUDE
        #pragma multi_compile_local _ _USE_RGBM

        #define MAX_KERNEL_SIZE 32
        #define MAX_MIP_DOWN_BLUR_COUNT 4

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #include "../Includes/HSRGBuffer.hlsl"
        #include "../Character/Shared/CharRenderingHelpers.hlsl"

        float4 _BlitTexture_TexelSize;

        float _BloomThreshold;
        float4 _BloomUVMinMax[MAX_MIP_DOWN_BLUR_COUNT];

        int _BloomUVIndex;
        int _BloomKernelSize;
        float _BloomKernel[MAX_KERNEL_SIZE];

        half4 EncodeHDR(half3 color)
        {
        #if _USE_RGBM
            half4 outColor = EncodeRGBM(color);
        #else
            half4 outColor = half4(color, 1.0);
        #endif

        #if UNITY_COLORSPACE_GAMMA
            return half4(sqrt(outColor.xyz), outColor.w); // linear to γ
        #else
            return outColor;
        #endif
        }

        half3 DecodeHDR(half4 color)
        {
        #if UNITY_COLORSPACE_GAMMA
            color.xyz *= color.xyz; // γ to linear
        #endif

        #if _USE_RGBM
            return DecodeRGBM(color);
        #else
            return color.xyz;
        #endif
        }

        float4 FragPrefilter(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);
            float3 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv).rgb;
            float4 bloom = HSRSampleGBuffer0(uv);
            color = max(0, color - _BloomThreshold.rrr) * DecodeBloomColor(bloom);
            return EncodeHDR(color);
        }

        half4 FragBlurV(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float texelSize = _BlitTexture_TexelSize.y;
            float halfKernelSize = (_BloomKernelSize - 1) * 0.5;
            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);

            half3 color = 0;
            for (int i = 0; i < _BloomKernelSize; i++)
            {
                float2 offset = float2(0.0, texelSize * (i - halfKernelSize));
                half3 c = DecodeHDR(SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv + offset));
                color += c * _BloomKernel[i];
            }
            return EncodeHDR(color);
        }

        half4 FragBlurH(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float texelSize = _BlitTexture_TexelSize.x;
            float halfKernelSize = (_BloomKernelSize - 1) * 0.5;

            // 从第一个图集中采样的 uv
            float4 uvMinMax = _BloomUVMinMax[_BloomUVIndex];
            float2 uv = lerp(uvMinMax.xy, uvMinMax.zw, UnityStereoTransformScreenSpaceTex(input.texcoord));

            half3 color = 0;
            for (int i = 0; i < _BloomKernelSize; i++)
            {
                float2 offset = float2(texelSize * (i - halfKernelSize), 0.0);
                half3 c = DecodeHDR(SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, clamp(uv + offset, uvMinMax.xy, uvMinMax.zw)));
                color += c * _BloomKernel[i];
            }
            return EncodeHDR(color);
        }

        half4 FragCombine(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);

            half3 color = 0;
            UNITY_UNROLL for (int i = 0; i < MAX_MIP_DOWN_BLUR_COUNT; i++)
            {
                float2 atlasUV = lerp(_BloomUVMinMax[i].xy, _BloomUVMinMax[i].zw, uv);
                color += DecodeHDR(SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, atlasUV));
            }
            return EncodeHDR(color);
        }
        ENDHLSL

        Pass
        {
            Name "Bloom Prefilter"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragPrefilter
            ENDHLSL
        }

        Pass
        {
            Name "Bloom Blur Vertical"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragBlurV
            ENDHLSL
        }

        Pass
        {
            Name "Bloom Blur Horizontal"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragBlurH
            ENDHLSL
        }

        Pass
        {
            Name "Bloom Combine"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragCombine
            ENDHLSL
        }
    }

    Fallback Off
}

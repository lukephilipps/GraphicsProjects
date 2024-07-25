Shader "Hidden/Dither"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        ZWrite Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            Texture2D _MainTex;
            float4 _MainTex_TexelSize; // (1/width, 1/height, width, height)
            SamplerState point_clamp_sampler;
            float _Scatter;
            int _PixelSize;

            struct a2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            static const float dither4[4][4] =
            {
                {0, 8, 2, 10},
                {12, 4, 14, 6},
                {3, 11, 1, 9},
                {15, 7, 13, 5}
            };

            static const float dither8[8][8] =
            {
                {0, 32, 8, 40, 2, 34, 10, 42},
                {48, 16, 56, 24, 50, 18, 58, 26},
                {12, 44, 4, 36, 14, 46, 6, 38},
                {60, 28, 52, 20, 62, 30, 54, 22},
                {3, 35, 11, 43, 1, 33, 9, 41},
                {51, 19, 59, 27, 49, 17, 57, 25},
                {15, 47, 7, 39, 13, 45, 5, 37},
                {63, 31, 55, 23, 61, 29, 53, 21}
            };

            v2f vert(a2f i)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(i.pos);
                o.uv = i.uv;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float x = i.uv.x * _MainTex_TexelSize.z / _PixelSize;
                float y = i.uv.y * _MainTex_TexelSize.w / _PixelSize;

                float m = dither4[x % 4][y % 4] * (1.0f / 16.0f) - 0.5f;

                x -= _PixelSize;
                y -= _PixelSize;

                x /= _MainTex_TexelSize.z / _PixelSize;
                y /= _MainTex_TexelSize.w / _PixelSize;

                float4 output = _MainTex.Sample(point_clamp_sampler, float2(x, y)) + m * 0.03f;

                int colorCount = 4;
                float colorMultiplier = colorCount - 1.0f;
                output.r = floor(output.r * colorMultiplier + 0.5f) / colorMultiplier;
                output.g = floor(output.g * colorMultiplier + 0.5f) / colorMultiplier;
                output.b = floor(output.b * colorMultiplier + 0.5f) / colorMultiplier;

                return output;
            }
            ENDCG
        }
    }
}

Shader "Hidden/PaletteSwapper"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Palette ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"

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

            Texture2D _MainTex;
            float4 _MainTex_TexelSize; // (1/width, 1/height, width, height)
            SamplerState point_clamp_sampler;

            v2f vert(a2f i)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(i.pos);
                o.uv = i.uv;

                return o;
            }
        ENDCG
        
        // For use in downsampling
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag(v2f i) : SV_Target
            {
                return _MainTex.Sample(point_clamp_sampler, i.uv);
            }
            ENDCG
        }

        // Dither + Color quantization
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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

            float _Scatter;
            int _RedColorCount;
            int _GreenColorCount;
            int _BlueColorCount;

            fixed4 frag(v2f i) : SV_Target
            {
                // int x = (i.uv.x * _MainTex_TexelSize.z) % 4;
                // int y = (i.uv.y * _MainTex_TexelSize.w) % 4;
                int x = (i.uv.x * _MainTex_TexelSize.z) % 8;
                int y = (i.uv.y * _MainTex_TexelSize.w) % 8;

                // float m = dither4[x][y] * (1.0f / 16.0f) - 0.5f;
                float m = dither8[x][y] * (1.0f / 64.0f) - 0.5f;

                float4 output = _MainTex.Sample(point_clamp_sampler, i.uv) + m * _Scatter;

                output.r = floor(output.r * (_RedColorCount - 1.0f) + 0.5f) / (_RedColorCount - 1.0f);
                output.g = floor(output.g * (_GreenColorCount - 1.0f) + 0.5f) / (_GreenColorCount - 1.0f);
                output.b = floor(output.b * (_BlueColorCount - 1.0f) + 0.5f) / (_BlueColorCount - 1.0f);

                return output;
            }
            ENDCG
        }

        // Palette swapping
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _Palette;

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 color = _MainTex.Sample(point_clamp_sampler, i.uv);

                return tex2D(_Palette, float2(color.r, 0));
            }
            ENDCG
        }

        // Grayscale
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 color = _MainTex.Sample(point_clamp_sampler, i.uv);
                fixed3 luminanceConv = { 0.2125f, 0.7154f, 0.0721f };

                float4 gray = dot(color, luminanceConv);
                gray.a = 1.0f;

                return gray;
            }
            ENDCG
        }
    }
}

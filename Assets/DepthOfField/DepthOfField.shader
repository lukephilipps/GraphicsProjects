Shader "Hidden/DepthOfField"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"

            struct app_data
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex, _CameraDepthTexture, _CoC, _Blur;
            float4 _MainTex_TexelSize;
            static const float3 luminanceConv = float3(0.2125f, 0.7154f, 0.0721f);
            float _Exposure;

            v2f vert(app_data i)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(i.vertex);
                o.uv = i.uv;
                return o;
            }
        ENDCG

        // Lottes SDR->HDR tonemapper
        Pass // 0
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target
            {
                float4 col = saturate(tex2D(_MainTex, i.uv));
                return col / (_Exposure - dot(col.rgb, luminanceConv));
            }
            ENDCG
        }

        // Lottes HDR->SDR tonemapper
        Pass // 1
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                return col / (_Exposure + dot(col.rgb, luminanceConv));
            }
            ENDCG
        }

        // CoC 
        Pass // 2
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float _FocusDistance, _FocusRange, _FocusBlend;

            float2 frag(v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                depth = LinearEyeDepth(depth);
                
                float d = depth - _FocusDistance; // Distance of point from FocusDistance
                float c = _FocusRange * _FocusBlend; // Inner radius of CoC, added for blending

                float2 o;
                o.x = clamp((d - c) / (_FocusRange - c), 0, 1);
                o.y = clamp((d + c) / (_FocusRange - c), -1, 0);
                o.y *= -1.0f;
                return o;
            }
            ENDCG
        }

        // Max filter Close CoC
        Pass // 3
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            int _MaxFilterRadius;

            float2 frag(v2f i) : SV_Target
            {
                float2 col = tex2D(_MainTex, i.uv);
                for (int x = -_MaxFilterRadius; x <= _MaxFilterRadius; ++x)
                    for (int y = -_MaxFilterRadius; y <= _MaxFilterRadius; ++y)
                        col.y = max(col.y, tex2D(_MainTex, i.uv + float2(x, y) * _MainTex_TexelSize.xy).y);

                return col;
            }
            ENDCG
        }

        // Box Blur Close CoC
        Pass // 4
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            int _BoxBlurRadius;

            float2 frag(v2f i) : SV_Target
            {
                float2 col = float2(tex2D(_MainTex, i.uv).x, 0.0f);
                for (int x = -_BoxBlurRadius; x <= _BoxBlurRadius; ++x)
                    for (int y = -_BoxBlurRadius; y <= _BoxBlurRadius; ++y)
                        col.y += tex2D(_MainTex, i.uv + float2(x, y) * _MainTex_TexelSize.xy).y;

                col.y /= pow(1 + (2 * _BoxBlurRadius), 2);

                return col;
            }
            ENDCG
        }

        // Get far color (pre-blur)
        Pass // 5
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                float coc = tex2D(_CoC, i.uv).x;
                return col * coc;
            }
            ENDCG
        }

        // Bokeh Blur
        Pass // 6
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            static const float2 offsets[] =
            {
                2.0f * float2(1.000000f, 0.000000f),
                2.0f * float2(0.707107f, 0.707107f),
                2.0f * float2(-0.000000f, 1.000000f),
                2.0f * float2(-0.707107f, 0.707107f),
                2.0f * float2(-1.000000f, -0.000000f),
                2.0f * float2(-0.707106f, -0.707107f),
                2.0f * float2(0.000000f, -1.000000f),
                2.0f * float2(0.707107f, -0.707107f),
                
                4.0f * float2(1.000000f, 0.000000f),
                4.0f * float2(0.923880f, 0.382683f),
                4.0f * float2(0.707107f, 0.707107f),
                4.0f * float2(0.382683f, 0.923880f),
                4.0f * float2(-0.000000f, 1.000000f),
                4.0f * float2(-0.382684f, 0.923879f),
                4.0f * float2(-0.707107f, 0.707107f),
                4.0f * float2(-0.923880f, 0.382683f),
                4.0f * float2(-1.000000f, -0.000000f),
                4.0f * float2(-0.923879f, -0.382684f),
                4.0f * float2(-0.707106f, -0.707107f),
                4.0f * float2(-0.382683f, -0.923880f),
                4.0f * float2(0.000000f, -1.000000f),
                4.0f * float2(0.382684f, -0.923879f),
                4.0f * float2(0.707107f, -0.707107f),
                4.0f * float2(0.923880f, -0.382683f),

                6.0f * float2(1.000000f, 0.000000f),
                6.0f * float2(0.965926f, 0.258819f),
                6.0f * float2(0.866025f, 0.500000f),
                6.0f * float2(0.707107f, 0.707107f),
                6.0f * float2(0.500000f, 0.866026f),
                6.0f * float2(0.258819f, 0.965926f),
                6.0f * float2(-0.000000f, 1.000000f),
                6.0f * float2(-0.258819f, 0.965926f),
                6.0f * float2(-0.500000f, 0.866025f),
                6.0f * float2(-0.707107f, 0.707107f),
                6.0f * float2(-0.866026f, 0.500000f),
                6.0f * float2(-0.965926f, 0.258819f),
                6.0f * float2(-1.000000f, -0.000000f),
                6.0f * float2(-0.965926f, -0.258820f),
                6.0f * float2(-0.866025f, -0.500000f),
                6.0f * float2(-0.707106f, -0.707107f),
                6.0f * float2(-0.499999f, -0.866026f),
                6.0f * float2(-0.258819f, -0.965926f),
                6.0f * float2(0.000000f, -1.000000f),
                6.0f * float2(0.258819f, -0.965926f),
                6.0f * float2(0.500000f, -0.866025f),
                6.0f * float2(0.707107f, -0.707107f),
                6.0f * float2(0.866026f, -0.499999f),
                6.0f * float2(0.965926f, -0.258818f),
            };

            float _LuminanceBias;

            float KarisWeight(float4 col)
            {
                return dot(col.rgb, luminanceConv) + _LuminanceBias + 0.00000001f;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                float karisSum = KarisWeight(col);
                col *= karisSum;

                for (int x = 0; x < 48; ++x)
                {
                    float2 offset = offsets[x];
                    offset *= _MainTex_TexelSize.xy;

                    float4 sampleCol = tex2D(_MainTex, i.uv + offset);
                    float weight = KarisWeight(sampleCol);
                    
                    karisSum += weight;
                    col += sampleCol * weight;
                }
                col /= karisSum;

                return col;
            }
            ENDCG
        }
        
        // Combine far color with source (post-blur)
        Pass // 7
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                float4 blur = tex2D(_Blur, i.uv);
                float coc = tex2D(_CoC, i.uv).x;
                return lerp(col, blur, coc);
            }
            ENDCG
        }

        // Combine close blur with source/far blur
        Pass // 8
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                float4 blur = tex2D(_Blur, i.uv);
                float coc = tex2D(_CoC, i.uv).y;
                return lerp(col, blur, coc);
            }
            ENDCG
        }
    }
}

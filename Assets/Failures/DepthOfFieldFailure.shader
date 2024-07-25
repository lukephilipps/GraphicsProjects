Shader "Hidden/DepthOfFieldFailure"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader 
    {
        CGINCLUDE
            #include "UnityCG.cginc"

            struct a2f
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct a2f_depth
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f_depth
            {
                float4 pos : SV_POSITION;
                float2 depth : TEXCOORD0;
            };

            v2f vert (a2f v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            v2f_depth vert_depth (a2f_depth v)
            {
                v2f_depth o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.depth = o.pos.xy * 0.5 + 0.5;
                return o;
            }
        ENDCG

        // Get mask 0
        Pass 
        {
            CGPROGRAM
            #pragma vertex vert_depth
            #pragma fragment frag

            sampler2D _CameraDepthTexture;
            float _Bound1;
            float _Bound2;

            float4 frag(v2f_depth i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.depth);
                depth = LinearEyeDepth(depth);
                depth = (depth - _Bound2) / (_Bound1 - _Bound2);
                return saturate(lerp(float4(1, 1, 1, 1), float4(0, 0, 0, 0), depth));
            }
            ENDCG
        }

        // Get far field 1
        Pass 
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            Texture2D _MainTex;
            sampler2D _FarMask;
            SamplerState sampler_MainTex;

            float4 frag(v2f i) : SV_Target
            {
                float2 maskUV = i.uv;
                maskUV.y = 1 - maskUV.y;
                return _MainTex.Sample(sampler_MainTex, i.uv) * tex2D(_FarMask, maskUV);
            }
            ENDCG
        }

        // Gaussian blur 2
        Pass 
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define PI2 6.2831853f

            Texture2D _MainTex;
            SamplerState sampler_MainTex;
            float4 _MainTex_TexelSize;
            float _GaussianSigma;
            int _KernelRadius;

            // Possible more efficient gaussian - https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
            float gaussian(float pos)
            {
                return exp(-(pos * pos) / (2.0f * _GaussianSigma * _GaussianSigma)) / sqrt(PI2 * _GaussianSigma * _GaussianSigma);
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 color = 0.0f;
                float guassSum = 0.0f;

                // Horizontal Gaussian
                for (int x = -_KernelRadius; x <= _KernelRadius; ++x)
                {
                    float gaus = gaussian(x);
                    color += gaus * _MainTex.Sample(sampler_MainTex, i.uv + float2(_MainTex_TexelSize.x * x, 0));
                    guassSum += gaus;
                }

                // Vertical Gaussian
                for (int y = -_KernelRadius; y <= _KernelRadius; ++y)
                {
                    float gaus = gaussian(y);
                    color += gaus * _MainTex.Sample(sampler_MainTex, i.uv + float2(0, _MainTex_TexelSize.y * y));
                    guassSum += gaus;
                }

                return color / guassSum;
            }
            ENDCG
        }

        // Interpolate between blur/source with mask 3
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            Texture2D _MainTex;
            Texture2D _Mask;
            Texture2D _BlurTex;
            SamplerState sampler_MainTex;

            float4 frag(v2f i) : SV_Target
            {
                float2 maskUV = i.uv;
                maskUV.y = 1 - maskUV.y;

                float4 color = _MainTex.Sample(sampler_MainTex, i.uv);
                float4 farColor = _BlurTex.Sample(sampler_MainTex, i.uv);
                float mask = _Mask.Sample(sampler_MainTex, maskUV).r;
                // mask = saturate(mask);

                // if (color.r > 1) return 1.0f;
                // return color;
                // return lerp(color, mask, .999);

                // if (mask.r <= 0.5f) return 1.0f;
                // if (mask == 0 || mask == 1) return 1.0f;
                return lerp(color, farColor, mask);
            }
            ENDCG
        }

        // Max filter 4
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            Texture2D _MainTex;
            float4 _MainTex_TexelSize;
            SamplerState sampler_MainTex;
            int _MaxFilterRadius;

            float4 frag(v2f i) : SV_Target
            {
                float4 color = _MainTex.Sample(sampler_MainTex, i.uv);
                for (int x = -_MaxFilterRadius; x <= _MaxFilterRadius; ++x)
                    for (int y = -_MaxFilterRadius; y <= _MaxFilterRadius; ++y)
                        color = max(color, _MainTex.Sample(sampler_MainTex, i.uv + float2(x, y) * _MainTex_TexelSize.xy));

                return color;
            }
            ENDCG
        }

        // Box blur 5
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            Texture2D _MainTex;
            float4 _MainTex_TexelSize;
            SamplerState sampler_MainTex;
            int _BoxBlurRadius;

            float4 frag(v2f i) : SV_Target
            {
                float4 color = 0.0f;
                for (int x = -_BoxBlurRadius; x <= _BoxBlurRadius; ++x)
                    for (int y = -_BoxBlurRadius; y <= _BoxBlurRadius; ++y)
                        color += _MainTex.Sample(sampler_MainTex, i.uv + float2(x, y) * _MainTex_TexelSize.xy);

                color /= pow(1 + (2 * _BoxBlurRadius), 2);

                return saturate(color);
            }
            ENDCG
        }

        // Bokeh Blur 6
        Pass
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
            Texture2D _MainTex;
            SamplerState sampler_MainTex;
            float4 _MainTex_TexelSize;
            float _LuminanceBias;

            float KarisWeight(float4 col)
            {
                return max(col.r, max(col.g, col.b)) + _LuminanceBias;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 color = _MainTex.Sample(sampler_MainTex, i.uv);
                float karisSum = KarisWeight(color);
                color *= karisSum;

                for (int x = 0; x < 48; ++x)
                {
                    float2 offset = offsets[x];
                    offset *= _MainTex_TexelSize.xy;

                    float4 sampleColor = _MainTex.Sample(sampler_MainTex, i.uv + offset);
                    float weight = KarisWeight(sampleColor);
                    
                    karisSum += weight;
                    color += sampleColor * weight;
                }
                color /= karisSum;

                // if (_LuminanceBias == 10) return 1.0f;

                return color;
            }
            ENDCG
        }

        // HDR conversion 7
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            Texture2D _MainTex;
            SamplerState sampler_MainTex;
            // static const float3 luminanceConv = float3(0.2125f, 0.7154f, 0.0721f);
            float _Exposure;

            float luminance(float3 color)
            {
                return max(color.r, max(color.g, color.b));
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 color = saturate(_MainTex.Sample(sampler_MainTex, i.uv));

                float denominator = _Exposure - luminance(color);
                if (denominator <= 0) denominator = 0.0000000000001f;

                float4 o = float4(color / denominator, 1.0f);

                return o;
            }
            ENDCG
        }
    }
}
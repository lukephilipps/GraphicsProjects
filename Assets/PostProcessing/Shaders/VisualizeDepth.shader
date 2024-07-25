Shader "Hidden/VisualizeDepth"
{
    SubShader 
    {
        Tags { "RenderType"="Opaque" }
        Pass 
        {
            // Blend Off Cull Off ZTest Off ZWrite Off
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _CameraDepthTexture;
            float _NearField;
            float _FarField;

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 depth : TEXCOORD0;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float2 t = o.pos.xy * 0.5 + 0.5;
                #if !defined(UNITY_UV_STARTS_AT_TOP)
                    t.y = 1.0 - t.y;
                #endif

                o.depth = t;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 cDepthColor = float4(1, 0, 0, 1);
                float4 fDepthColor = float4(0, 1, 0, 1);
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.depth);
                depth = LinearEyeDepth(depth);
                depth = (depth - _NearField) / (_FarField - _NearField);
                // depth = Linear01Depth(depth);
                return lerp(cDepthColor, fDepthColor, depth);
                // if (depth < _NearField) return cDepthColor;
                // if (depth > _FarField) return fDepthColor;
                // return DECODE_EYEDEPTH(depth);
            }
            ENDCG
        }
    }
}
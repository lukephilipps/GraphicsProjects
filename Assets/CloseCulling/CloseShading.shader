Shader "Hidden/CloseDither"
{
    SubShader
    {
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        Tags
		{
			"Queue" = "Transparent"
		}
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"

            sampler2D _OverlayTex;
            float _OverlayAlpha;

            struct a2v
            {
                float4 pos : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert(a2v v, uint svInstanceID : SV_InstanceID)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.pos);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 screenPos = i.pos.xy / _ScreenParams.xy;
                
                float2 clipCheck = floor(i.pos.xy * 0.25f) * 0.5f;
                clip(-frac(clipCheck.x + clipCheck.y));

                float4 color = tex2D(_OverlayTex, screenPos);
                color.a = _OverlayAlpha;

                return color;
            }
            ENDCG
        }
    }
}
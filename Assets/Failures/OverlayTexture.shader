Shader "Hidden/OverlayTexture"
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

            sampler2D _MainTex;
            sampler2D _OverlayMask;
            float _OverlayAlpha;

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

            v2f vert(a2f i)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(i.pos);
                o.uv = i.uv;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 scene = tex2D(_MainTex, i.uv);
                float4 overlay = tex2D(_OverlayMask, i.uv);
                return scene;
                return lerp(scene, overlay, overlay.a * _OverlayAlpha);
            }
            ENDCG
        }
    }
}

Shader "Hidden/Sharpen"
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
            float4 _MainTex_TexelSize;
            float _Sharpness;

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
                float4 neighbors = tex2D(_MainTex, i.uv + float2(_MainTex_TexelSize.x, 0.0f)) * -_Sharpness
                                + tex2D(_MainTex, i.uv - float2(_MainTex_TexelSize.x, 0.0f)) * -_Sharpness
                                + tex2D(_MainTex, i.uv + float2(0.0f, _MainTex_TexelSize.y)) * -_Sharpness
                                + tex2D(_MainTex, i.uv - float2(0.0f, _MainTex_TexelSize.y)) * -_Sharpness;
                float4 center = tex2D(_MainTex, i.uv) * (_Sharpness * 4.0f + 1.0f);
                return saturate(center + neighbors);
            }
            ENDCG
        }
    }
}

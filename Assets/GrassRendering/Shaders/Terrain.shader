Shader "Projects/Grass/Terrain"
{
    Properties
    {
        _Texture ("Albedo (RGB)", 2D) = "white" {}
        [NoScaleOffset] _NormalMap ("Normal", 2D) = "white" {}
        [NoScaleOffset] _HeightMap ("Height", 2D) = "white" {}
        _DisplaceStrength ("Displace Strength", Range(0, 1)) = 1
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _Texture, _NormalMap, _HeightMap;
            float4 _Texture_ST;
            float _DisplaceStrength;
            
            v2f vert(a2v v)
            {
                v2f o;
                float displace = tex2Dlod(_HeightMap, float4(v.uv, 0, 0)).x;
                v.vertex.z += displace * _DisplaceStrength;
                o.position = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;
                
                return o;
            }
            
            fixed4 frag(v2f i) : SV_TARGET
            {
                return tex2D(_Texture, i.uv * _Texture_ST.xy + _Texture_ST.zw);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}

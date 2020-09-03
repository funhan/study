Shader "Unlit/phong"
{
    Properties
    {
        _MainTex ("Base texture", 2D) = "white" {}
		_AmbientLight("Ambient Light", Color) = (0.2, 0.2, 0.2, 1)
		_AmbientMaterial("Ambient Material", Color) = (0.2, 0.2, 0.2, 1)
    }
    SubShader
    {

        Pass
        {
		Tags {"LightMode" = "ForwardBase"}
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
		#pragma multi_compile DIRECTIONAL POINT SPOT

        #include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
			float3 normal : NORMAL;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 pos : SV_POSITION;
			float3 worldPos : WORLDPOS;
			float3 worldNormal : WORLDNORMAL;
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;

        v2f vert (appdata v)
        {
            v2f o;
			o.uv = v.uv;
            o.pos = UnityObjectToClipPos(v.vertex); // MVP mat CC로 보냄
			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.worldNormal = UnityObjectToWorldNormal(v.normal);

            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
			fixed4 col = tex2D(_MainTex, i.uv);
			
			float3 LightDir_WC;
#if defined(POINT)
			LightDir_WC = normalize(_WorldSpaceLightPos0.xyz);
			col = fixed4(1.0f, 0.0f, 0.0f, 1.0f);
#else
			LightDir_WC = _WorldSpaceLightPos0.xyz; // -i.worldPos;
			// TODO : attenuation
			LightDir_WC = normalize(LightDir_WC);
			col = fixed4(1.0f, 1.0f, 1.0f, 1.0f);
#endif

			// col = fixed4(LightDir_WC, 1.0f);
            return col;
        }
        ENDCG
        }
    }
}

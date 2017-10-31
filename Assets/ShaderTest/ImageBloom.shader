Shader "ImageBloom"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BloomTex ("Bloom", 2D) = "white" {}
		_Bloom("Slide", Float) = 0.0
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			float _Bloom;
			half4 _MainTex_TexelSize;

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 uv2[4] : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				
				o.uv2[0] = v.uv + _MainTex_TexelSize.xy * half2(1.5, 1.5);
				o.uv2[1] = v.uv + _MainTex_TexelSize.xy * half2(-1.5, 1.5);
				o.uv2[2] = v.uv + _MainTex_TexelSize.xy * half2(-1.5, 1.5);
				o.uv2[3] = v.uv + _MainTex_TexelSize.xy * half2(-1.5, 1.5);
				
				return o;
			}
			
			sampler2D _MainTex;

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				// just invert the colors
				col = max(col, tex2D(_MainTex, i.uv2[0]));
				col = max(col, tex2D(_MainTex, i.uv2[1]));
				col = max(col, tex2D(_MainTex, i.uv2[2]));
				col = max(col, tex2D(_MainTex, i.uv2[3]));

				
				return saturate(col - half4(0.1,0.1,0.1,0));
			}
			ENDCG
		}

		Pass{
			CGPROGRAM
			#pragma vertex vertbloom
			//#pragma vertex vertbloomHor
			#pragma fragment fragmentbloom

			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			#include "UnityCG.cginc"
			struct v2f_withBlurCoordsSGX {
				float4 pos : SV_POSITION;
				half2 offset[7] :TEXCOORD0;
			};

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f_withBlurCoordsSGX vertbloom(appdata v)
			{
				v2f_withBlurCoordsSGX o;
				o.pos = UnityObjectToClipPos(v.vertex);
				half2 netFilterWidth = _MainTex_TexelSize.xy * half2(0.0, 1.0) * 2;

				o.offset[0] = v.uv + netFilterWidth;
				o.offset[1] = v.uv + netFilterWidth*2.0;  
            	o.offset[2] = v.uv + netFilterWidth*3.0;  
            	o.offset[3] = v.uv - netFilterWidth;  
            	o.offset[4] = v.uv - netFilterWidth*2.0;  
            	o.offset[5] = v.uv - netFilterWidth*3.0;  
				o.offset[6] = v.uv;

				
				return o;
			}

			v2f_withBlurCoordsSGX vertbloomHor(v2f_withBlurCoordsSGX v)
			{
				v2f_withBlurCoordsSGX o;
				//o.pos = UnityObjectToClipPos(v.vertex);
				half2 netFilterWidth = _MainTex_TexelSize.xy * half2(1.0, 0.0) * 2;

				o.offset[0] = v.offset[0] + netFilterWidth;
				o.offset[1] = v.offset[1] + netFilterWidth*2.0;  
            	o.offset[2] = v.offset[2] + netFilterWidth*3.0;  
            	o.offset[3] = v.offset[3] - netFilterWidth;  
            	o.offset[4] = v.offset[4] - netFilterWidth*2.0;  
            	o.offset[5] = v.offset[5] - netFilterWidth*3.0;  
				o.offset[6] = v.offset[6];

				
				return o;
			}

			fixed4 fragmentbloom(v2f_withBlurCoordsSGX  i) : COLOR
			{
				fixed4 color = tex2D(_MainTex, i.offset[6]) * 0.2;
				
				
				color += tex2D(_MainTex, i.offset[0]) * 0.5;
				color += tex2D(_MainTex, i.offset[1]) * 0.1;
				color += tex2D(_MainTex, i.offset[2]) * 0.1;
				color += tex2D(_MainTex, i.offset[3]) * 0.5;
				color += tex2D(_MainTex, i.offset[4]) * 0.1;
				color += tex2D(_MainTex, i.offset[5]) * 0.1;
				
				return color;
			}
			ENDCG
		}

	}
}

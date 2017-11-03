Shader "ImageBloom"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BloomTex("BloomTexture", 2D) = "White" {}
		_Radius("SampleRadius", Float) = 0.0		//pixel bloom select radius
		_Threshold("BloomRange", Float) = 0.0		//泛光范围，阈值越小，泛光的边缘的范围就越小
		_BloomColor("BloomColor", Color) = (0,0,0,0)
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		//Pass 0
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragBloom
			
			float _Radius;
			float _Threshold;
			half4 _MainTex_TexelSize;
			float4 _BloomColor;


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
				
				//先实现简单的4点采样，回头考虑更加复杂的8点采样及更过
				o.uv2[0] = v.uv + _MainTex_TexelSize.xy * half2(_Radius, _Radius);
				o.uv2[1] = v.uv + _MainTex_TexelSize.xy * half2(-_Radius, _Radius);
				o.uv2[2] = v.uv + _MainTex_TexelSize.xy * half2(-_Radius, -_Radius);
				o.uv2[3] = v.uv + _MainTex_TexelSize.xy * half2(_Radius, -_Radius);
				
				return o;
			}
			
			sampler2D _MainTex;

			fixed4 fragBloom (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				
				col = max(col, tex2D(_MainTex, i.uv2[0]));
				col = max(col, tex2D(_MainTex, i.uv2[1]));
				col = max(col, tex2D(_MainTex, i.uv2[2]));
				col = max(col, tex2D(_MainTex, i.uv2[3]));

				//return lerp(0, col, (Luminance(col) - (1-_Threshold)));
				return saturate((Luminance(col) - (1-_Threshold)) * _BloomColor);
				//return saturate(col - (1 - _Threshold));
			}
			ENDCG
		}

		//Pass 1
		Pass{
			CGPROGRAM
			#pragma vertex vertblur
			#pragma fragment fragmentblur

			sampler2D _MainTex;
			sampler2D _BloomTex;
			half4 _MainTex_TexelSize;
			float _Radius;
			float4 _BloomColor;

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

			v2f_withBlurCoordsSGX vertblur(appdata v)
			{
				v2f_withBlurCoordsSGX o;
				o.pos = UnityObjectToClipPos(v.vertex);
				half2 netFilterWidth = _MainTex_TexelSize.xy * half2(0.0, 1.0) * _Radius;

				//高斯模糊3σ采样
				o.offset[0] = v.uv + netFilterWidth;
				o.offset[1] = v.uv + netFilterWidth*2.0;  
            	o.offset[2] = v.uv + netFilterWidth*3.0;  
            	o.offset[3] = v.uv - netFilterWidth;  
            	o.offset[4] = v.uv - netFilterWidth*2.0;  
            	o.offset[5] = v.uv - netFilterWidth*3.0;  
				o.offset[6] = v.uv;

				
				return o;
			}

			fixed4 fragmentblur(v2f_withBlurCoordsSGX  i) : SV_Target
			{
				//这里权重参数是曲线值，可以是正太分布（高斯）曲线，也可以是自定义曲线
				fixed4 color = tex2D(_MainTex, i.offset[6]) * 0.5;
				
				
				color += tex2D(_MainTex, i.offset[0]) * 0.3;
				color += tex2D(_MainTex, i.offset[1]) * 0.15;
				color += tex2D(_MainTex, i.offset[2]) * 0.05;
				color += tex2D(_MainTex, i.offset[3]) * 0.3;
				color += tex2D(_MainTex, i.offset[4]) * 0.15;
				color += tex2D(_MainTex, i.offset[5]) * 0.5;
				
				fixed4 color2 = tex2D(_BloomTex, i.offset[6]) * 0.5;
				return color + color2;
			}
			ENDCG
		}

	}
}

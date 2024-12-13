// Test shader to verify compilation pipeline
struct VS_INPUT {
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
};

struct PS_INPUT {
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

PS_INPUT VSMain(VS_INPUT input) {
    PS_INPUT output;
    output.Position = input.Position;
    output.TexCoord = input.TexCoord;
    return output;
}

float4 PSMain(PS_INPUT input) : SV_Target {
    return float4(input.TexCoord, 0.0f, 1.0f);
}

#include "globals.hlsli"
#include "ShaderInterop_DDGI.h"

struct VSOut
{
	float4 pos : SV_Position;
	float3 normal : NORMAL;
	uint probeIndex : PROBEINDEX;
};

float4 main(VSOut input) : SV_Target
{
	float3 color = 0;

	StructuredBuffer<DDGIProbe> probe_buffer = bindless_structured_ddi_probes[descriptor_index(GetScene().ddgi.probe_buffer)];
	DDGIProbe probe = probe_buffer[input.probeIndex];
	
	// Manually create Packed struct from uint array
	SH::L4_RGB::Packed packed;
	[unroll]
	for (uint i = 0; i < 38; ++i)
	{
		packed.C[i] = probe.radiance[i];
	}
	SH::L4_RGB sh_data = packed.Unpack();
	
	// Use dynamic SH level to evaluate the correct coefficients
	uint sh_level = GetScene().ddgi.sh_level;
	if (sh_level == 0)
	{
		SH::L0_RGB l0_sh;
		l0_sh.C[0] = sh_data.C[0];
		color = SH::Evaluate(l0_sh, input.normal);
	}
	else if (sh_level == 1)
	{
		SH::L1_RGB l1_sh;
		l1_sh.C[0] = sh_data.C[0];
		l1_sh.C[1] = sh_data.C[1];
		l1_sh.C[2] = sh_data.C[2];
		l1_sh.C[3] = sh_data.C[3];
		color = SH::Evaluate(l1_sh, input.normal);
	}
	else if (sh_level == 2)
	{
		SH::L2_RGB l2_sh;
		[unroll]
		for (uint i = 0; i < 9; ++i)
		{
			l2_sh.C[i] = sh_data.C[i];
		}
		color = SH::Evaluate(l2_sh, input.normal);
	}
	else
	{
		color = SH::Evaluate(sh_data, input.normal);
	}
	
	return float4(color, 1);
}

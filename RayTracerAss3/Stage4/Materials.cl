float3 applyCheckerboard(const Intersection* intersect)
{
	float3 p = (intersect->pos - intersect->material->offset) / intersect->material->size;

	int which = ((int)(floor(p.x)) + (int)(floor(p.y)) + (int)(floor(p.z))) & 1;

	return (which ? intersect->material->diffuse : intersect->material->diffuse2);
}

// apply computed circular texture
float3 applyCircles(const Intersection* intersect)
{
	float3 p = (intersect->pos - intersect->material->offset) / intersect->material->size;

	int which = (int)(floor(sqrt(p.x * p.x + p.y * p.y + p.z * p.z))) & 1;

	return (which ? intersect->material->diffuse : intersect->material->diffuse2);
}

// apply computed wood grain texture
float3 applyWood(const Intersection* intersect)
{
	float3 preP = (intersect->pos - intersect->material->offset) / intersect->material->size;

	// squiggle up where the point is
	float3 p = { preP.x * cos(preP.y * 0.996f) * sin(preP.z * 1.023f),
		cos(preP.x) * preP.y * sin(preP.z * 1.211f),
		cos(preP.x * 1.473f) * cos(preP.y * 0.795f) * preP.z };

	int which = (int)(floor(sqrt(p.x * p.x + p.y * p.y + p.z * p.z))) & 1;

	return (which ? intersect->material->diffuse : intersect->material->diffuse2);
}
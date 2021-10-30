bool isSphereIntersected(__global Sphere* s, const Ray* r, float* t)
{
	float EPSILON = 0.01f;
	// Intersection of a ray and a sphere, check the articles for the rationale
	float3 dist = s->pos - r->start;
	float B = dot(r->dir, dist);
	float D = B * B - dot(dist, dist) + s->size * s->size;

	// if D < 0, no intersection, so don't try and calculate the point of intersection
	if (D < 0.0f) return false;

	// calculate both intersection times(/distances)
	float t0 = B - sqrt(D);
	float t1 = B + sqrt(D);

	// check to see if either of the two sphere collision points are closer than time parameter
	if ((t0 > EPSILON) && (t0 < *t))
	{
		*t = t0;
		return true;
	}
	else if ((t1 > EPSILON) && (t1 < *t))
	{
		*t = t1;
		return true;
	}

	return false;
}
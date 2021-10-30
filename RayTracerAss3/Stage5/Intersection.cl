float3 normalise(float3 x)
{
	return x * rsqrt(dot(x, x));
}

bool isCylinderIntersected(__global Cylinder* cy, const Ray* r, float* t, float3* normal)
{
	// vector between start and end of the cylinder (cylinder axis, i.e. ca)
	float3 ca = cy->p2 - cy->p1;
	// vector between ray origin and start of the cylinder
	float3 oc = r->start - cy->p1;
	// cache some dot-products 
	float caca = dot(ca, ca);
	float card = dot(ca, r->dir);
	float caoc = dot(ca, oc);

	// calculate values for coefficients of line-cylinder equation
	float a = caca - card * card;
	float b = caca * dot(oc, r->dir) - caoc * card;
	float c = caca * dot(oc, oc) - caoc * caoc - cy->size * cy->size * caca;

	// first half of distance calculation (distance squared)
	float h = b * b - a * c;

	// if ray doesn't intersect with infinite cylinder, exit
	if (h < 0.0f) return false;

	// second half of distance calculation (distance)
	h = sqrt(h);

	// calculate point of intersection (on infinite cylinder)
	float tBody = (-b - h) / a;

	// calculate distance along cylinder
	float y = caoc + tBody * card;

	// check intersection point is on the length of the cylinder
	if (y > 0 && y < caca)
	{
		// check to see if the collision point on the cylinder body is closer than the time parameter
		if (tBody > EPSILON && tBody < *t)
		{
			*t = tBody;
			*normal = (oc + (r->dir * tBody - ca * y / caca)) / cy->size;
			return true;
		}
	}

	// calculate point of intersection on plane containing cap
	float tCaps = (((y < 0.0f) ? 0.0f : caca) - caoc) / card;

	float valToAbs = b + a * tCaps;
	// check intersection point is within the radius of the cap
	if (fabs(b + a * tCaps) < h)
	{
		// check to see if the collision point on the cylinder cap is closer than the time parameter
		if (tCaps > EPSILON && tCaps < *t)
		{
			*t = tCaps;
			*normal = ca * rsqrt(caca) * sign(y);
			return true;
		}
	}

	return false;
}
bool isPlaneIntersected(__global const Plane* p, const Ray* r, float* t)
{
	// angle between ray and surface normal
	float angle = dot(r->dir, p->normal);

	// no intersection if ray and plane are parallel
	if (angle == 0.0f) return false;

	// find point of intersection
	float t0 = dot((p->pos - r->start), p->normal) / angle;

	// check to see if plane collision point is closer than time parameter
	if (t0 > EPSILON && t0 < *t)
	{
		*t = t0;
		return true;
	}

	return false;
}


bool isSphereIntersected(__global Sphere* s, const Ray* r, float* t)
{
	float EPSILON = 0.01f;
	float3 dist = s->pos - r->start;
	float B = dot(r->dir, dist);
	float D = B * B - dot(dist, dist) + s->size * s->size;

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

bool objectIntersection(const Scene* scene, const Ray* viewRay, Intersection* intersect)
{
	// set default distance to be a long long way away
	float t = MAX_RAY_DISTANCE;

	// no intersection found by default
	intersect->objectType = NONE;

	// search for sphere collisions, storing closest one found
	for (unsigned int i = 0; i < scene->numSpheres; ++i)
	{
		if (isSphereIntersected(&scene->sphereContainer[i], viewRay, &t))
		{
			intersect->objectType = SPHERE;
			intersect->sphere = &scene->sphereContainer[i];
		}
	}

	// search for plane collisions, storing closest one found
	for (unsigned int i = 0; i < scene->numPlanes; ++i)
	{
		if (isPlaneIntersected(&scene->planeContainer[i], viewRay, &t))
		{
			intersect->objectType = PLANE;
			intersect->plane = &scene->planeContainer[i];
		}
	}

	// search for cylinder collisions, storing closest one found (and the normal at that point)
	float3 normal;
	for (unsigned int i = 0; i < scene->numCylinders; ++i)
	{
		if (isCylinderIntersected(&scene->cylinderContainer[i], viewRay, &t, &normal))
		{
			intersect->objectType = CYLINDER;
			intersect->normal = normal;
			intersect->cylinder = &scene->cylinderContainer[i];
		}
	}

	// nothing detected, return false
	if (intersect->objectType == NONE)
	{
		return false;
	}

	// calculate the point of the intersection
	intersect->pos = viewRay->start + viewRay->dir * t;

	return true;
}

// calculate collision normal, viewProjection, object's material, and test to see if inside collision object
void calculateIntersectionResponse(const Scene* scene, const Ray* viewRay, Intersection* intersect)
{
	switch (intersect->objectType)
	{
	case SPHERE:
		intersect->normal = normalise(intersect->pos - intersect->sphere->pos);
		intersect->material = &scene->materialContainer[intersect->sphere->materialId];
		break;
	case PLANE:
		intersect->normal = intersect->plane->normal;
		intersect->material = &scene->materialContainer[intersect->plane->materialId];
		break;
	case CYLINDER:
		// normal already returned from intersection function, so nothing to do here
		intersect->material = &scene->materialContainer[intersect->cylinder->materialId];
		break;
	case NONE:
		break;
	}


	// calculate view projection
	intersect->viewProjection = dot(viewRay->dir, intersect->normal);

	// detect if we are inside an object (needed for refraction)
	intersect->insideObject = (dot(intersect->normal, viewRay->dir) > 0.0f);

	// if inside an object, reverse the normal
	if (intersect->insideObject)
	{
		intersect->normal = intersect->normal * -1.0f;
	}
}
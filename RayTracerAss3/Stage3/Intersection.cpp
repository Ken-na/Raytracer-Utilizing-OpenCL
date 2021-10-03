/*  The following code is a VERY heavily modified from code originally sourced from:
	Ray tracing tutorial of http://www.codermind.com/articles/Raytracer-in-C++-Introduction-What-is-ray-tracing.html
	It is free to use for educational purpose and cannot be redistributed outside of the tutorial pages. */

#include "Intersection.h"

// test to see if collision between ray and a plane happens before time t (equivalent to distance)
// updates closest collision time (/distance) if collision occurs
// see: http://en.wikipedia.org/wiki/Line-sphere_intersection
// see: http://www.codermind.com/articles/Raytracer-in-C++-Part-I-First-rays.html
// see: Step 8 of http://meatfighter.com/juggler/ 
// this code make heavy use of constant term removal due to ray always being a unit vector (i.e. normalised)
bool isSphereIntersected(const Sphere* s, const Ray* r, float* t)
{
    // Intersection of a ray and a sphere, check the articles for the rationale
    Vector dist = s->pos - r->start;
    float B = r->dir * dist;
    float D = B * B - dist * dist + s->size * s->size;

	// if D < 0, no intersection, so don't try and calculate the point of intersection
	if (D < 0.0f) return false;

	// calculate both intersection times(/distances)
	float t0 = B - sqrtf(D);
    float t1 = B + sqrtf(D);

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


// test to see if collision between ray and a plane happens before time t (equivalent to distance)
// updates closest collision time (/distance) if collision occurs
// see: http://en.wikipedia.org/wiki/Line-plane_intersection
// see: http://www.cs.princeton.edu/courses/archive/fall00/cs426/lectures/raycast/sld017.htm
// see: http://softsurfer.com/Archive/algorithm_0104/algorithm_0104B.htm#Line-Plane Intersection
bool isPlaneIntersected(const Plane* p, const Ray* r, float* t)
{
	// angle between ray and surface normal
	float angle = r->dir * p->normal;

	// no intersection if ray and plane are parallel
	if (angle == 0.0f) return false;

	// find point of intersection
	float t0 = ((p->pos - r->start) * p->normal) / angle;

	// check to see if plane collision point is closer than time parameter
	if (t0 > EPSILON && t0 < *t)
	{
		*t = t0;
		return true;
	}

	return false;
}


// test to see if collision between ray and a cylinder happens before time t (equivalent to distance)
// updates closest collision time (/distance) and normal (at point of collions) if collision occurs
// based on code from: https://www.shadertoy.com/view/4lcSRn
// see: https://mrl.cs.nyu.edu/~dzorin/rend05/lecture2.pdf
// see: https://math.stackexchange.com/questions/3248356/calculating-ray-cylinder-intersection-points
// see: https://www.doc.ic.ac.uk/~dfg/graphics/graphics2010/GraphicsLecture11.pdf
bool isCylinderIntersected(const Cylinder* cy, const Ray* r, float* t, Vector* normal)
{
	// vector between start and end of the cylinder (cylinder axis, i.e. ca)
	Vector ca = cy->p2 - cy->p1;

	// vector between ray origin and start of the cylinder
	Vector oc = r->start - cy->p1;

	// cache some dot-products 
	float caca = ca * ca;
	float card = ca * r->dir;
	float caoc = ca * oc;

	// calculate values for coefficients of line-cylinder equation
	float a = caca - card * card;
	float b = caca * (oc * r->dir) - caoc * card;
	float c = caca * (oc * oc) - caoc * caoc - cy->size * cy->size * caca;

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

	// check intersection point is within the radius of the cap
	if (abs(b + a * tCaps) < h)
	{
		// check to see if the collision point on the cylinder cap is closer than the time parameter
		if (tCaps > EPSILON && tCaps < *t)
		{
			*t = tCaps;
			*normal = ca * invsqrtf(caca) * sign(y);
			return true;
		}
	}

	return false;
}


// calculate collision normal, viewProjection, object's material, and test to see if inside collision object
void calculateIntersectionResponse(const Scene* scene, const Ray* viewRay, Intersection* intersect)
{
	switch (intersect->objectType)
	{
	case Intersection::PrimitiveType::SPHERE:
		intersect->normal = normalise(intersect->pos - intersect->sphere->pos);
		intersect->material = &scene->materialContainer[intersect->sphere->materialId];
		break;
	case Intersection::PrimitiveType::PLANE:
		intersect->normal = intersect->plane->normal;
		intersect->material = &scene->materialContainer[intersect->plane->materialId];
		break;
	case Intersection::PrimitiveType::CYLINDER:
		// normal already returned from intersection function, so nothing to do here
		intersect->material = &scene->materialContainer[intersect->cylinder->materialId];
		break;
	}

	// calculate view projection
	intersect->viewProjection = viewRay->dir * intersect->normal; 

	// detect if we are inside an object (needed for refraction)
	intersect->insideObject = (intersect->normal * viewRay->dir > 0.0f);

	// if inside an object, reverse the normal
    if (intersect->insideObject)
    {
        intersect->normal = intersect->normal * -1.0f;
    }
}


// test to see if collision between ray and any object in the scene
// updates intersection structure if collision occurs
bool objectIntersection(const Scene* scene, const Ray* viewRay, Intersection* intersect)
{
	// set default distance to be a long long way away
    float t = MAX_RAY_DISTANCE;

	// no intersection found by default
	intersect->objectType = Intersection::PrimitiveType::NONE;

	// search for sphere collisions, storing closest one found
    for (unsigned int i = 0; i < scene->numSpheres; ++i)
    {
        if (isSphereIntersected(&scene->sphereContainer[i], viewRay, &t))
        {
			intersect->objectType = Intersection::PrimitiveType::SPHERE;
			intersect->sphere = &scene->sphereContainer[i];
        }
    }

	// search for plane collisions, storing closest one found
	for (unsigned int i = 0; i < scene->numPlanes; ++i)
	{
		if (isPlaneIntersected(&scene->planeContainer[i], viewRay, &t))
		{
			intersect->objectType = Intersection::PrimitiveType::PLANE;
			intersect->plane = &scene->planeContainer[i];
		}
	}

	// search for cylinder collisions, storing closest one found (and the normal at that point)
	Vector normal;
	for (unsigned int i = 0; i < scene->numCylinders; ++i)
	{
		if (isCylinderIntersected(&scene->cylinderContainer[i], viewRay, &t, &normal))
		{
			intersect->objectType = Intersection::PrimitiveType::CYLINDER;
			intersect->normal = normal;
			intersect->cylinder = &scene->cylinderContainer[i];
		}
	}

	// nothing detected, return false
	if (intersect->objectType == Intersection::PrimitiveType::NONE)
	{
		return false;
	}

	// calculate the point of the intersection
	intersect->pos = viewRay->start + viewRay->dir * t;

	return true;
}

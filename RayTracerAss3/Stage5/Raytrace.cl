__constant float EPSILON = 0.01f;
__constant int MAX_RAYS_CAST = 10;
__constant float DEFAULT_REFRACTIVE_INDEX = 1.0f;
__constant const float MAX_RAY_DISTANCE = FLT_MAX;

enum PrimitiveType { NONE, SPHERE, PLANE, CYLINDER };


float3 normalise(float3 x)
{
	return x * rsqrt(dot(x, x));
}
//colour has been changed to int3 (NOW THEY"RE FLOAT3)
//point and vector are float3.

typedef struct Ray
{
	float3 start;
	float3 dir;
} Ray;
// material
typedef struct Material
{
	// type of colouring/texturing
	enum { GOURAUD, CHECKERBOARD, CIRCLES, WOOD } type;

	float3 diffuse;				// diffuse colour
	float3 diffuse2;			// second diffuse colour, only for checkerboard types

	float3 offset;				// offset of generated texture
	float size;					// size of generated texture

	float3 specular;			// colour of specular lighting
	float power;				// power of specular reflection

	float reflection;			// reflection amount
	float refraction;			// refraction amount
	float density;				// density of material (affects amount of defraction)
} Material;


// light object
typedef struct Light
{
	float3 pos;					// location
	float3 intensity;			// brightness and colour
} Light;


// sphere object
typedef struct Sphere
{
	float3 pos;					// a point on the plane
	float size;					// radius of sphere
	unsigned int materialId;	// material id
} Sphere;

// plane object
typedef struct Plane
{
	float3 pos;					// a point on the plane
	float3 normal;				// normal of the plane
	unsigned int materialId;	// material id
} Plane;

// cyliner object
typedef struct Cylinder
{
	float3 p1, p2;				// two points to define the centres of the ends of the cylinder
	float size;					// radius of cylinder
	unsigned int materialId;	// material id
} Cylinder;

typedef struct Intersection
{
	enum PrimitiveType objectType;	// type of object intersected with

	float3 pos;											// point of intersection
	float3 normal;										// normal at point of intersection
	float viewProjection;								// view projection 
	bool insideObject;									// whether or not inside an object

	__global Material* material;									// material of object

	// object collided with
	union
	{
		__global Sphere* sphere;
		__global Cylinder* cylinder;
		__global Plane* plane;
	};
} Intersection;

typedef struct Scene
{
	float3 cameraPosition;					// camera location
	float cameraRotation;					// direction camera points
	float cameraFieldOfView;				// field of view for the camera

	float exposure;							// image exposure

	unsigned int skyboxMaterialId;

	// scene object counts
	unsigned int numMaterials;
	unsigned int numLights;
	unsigned int numSpheres;
	unsigned int numPlanes;
	unsigned int numCylinders;

	// scene objects
	__global Material* materialContainer;
	__global Light* lightContainer;
	__global Sphere* sphereContainer;
	__global Plane* planeContainer;
	__global Cylinder* cylinderContainer;
} Scene;

// output a bunch of info about the contents of the scene
void OutputInfo(const Scene* scene)
{
	__global Plane* planes = scene->planeContainer;
	__global Cylinder* cylinders = scene->cylinderContainer;
	__global Sphere* spheres = scene->sphereContainer;
	__global Light* lights = scene->lightContainer;
	__global Material* materials = scene->materialContainer;

	printf("\n---- GEEPEEYOU --------\n");
	printf("sizeof(Point):    %d\n", sizeof(float3));
	printf("sizeof(Vector):   %d\n", sizeof(float3));
	printf("sizeof(Colour):   %d\n", sizeof(float3));
	printf("sizeof(Ray):      %d\n", sizeof(Ray));
	printf("sizeof(Light):    %d\n", sizeof(Light));
	printf("sizeof(Sphere):   %d\n", sizeof(Sphere));
		//printf("sizeof(Sphere->pos):   %d\n", sizeof(float3));
		//printf("sizeof(Sphere->size):   %d\n", sizeof(float));
		//printf("sizeof(Sphere->material):   %d\n", sizeof(unsigned int));
	printf("sizeof(Plane):    %d\n", sizeof(Plane));
	printf("sizeof(Cylinder): %d\n", sizeof(Cylinder));
	printf("sizeof(Material): %d\n", sizeof(Material));
	printf("sizeof(Scene):    %d\n", sizeof(Scene));

	printf("\n--- Scene:\n");;
	printf("pos: %.1f %.1f %.1f\n", scene->cameraPosition.x, scene->cameraPosition.y, scene->cameraPosition.z);
	printf("rot: %.1f\n", scene->cameraRotation);
	printf("fov: %.1f\n", scene->cameraFieldOfView);
	printf("exp: %.1f\n", scene->exposure);
	printf("sky: %d\n", scene->skyboxMaterialId);

	printf("\n--- Spheres (%d):\n", scene->numSpheres);;
	for (unsigned int i = 0; i < scene->numSpheres; ++i)
	{
		if (scene->numSpheres > 10 && i >= 3 && i < scene->numSpheres - 3)
		{
			printf(" ... \n");
			i = scene->numSpheres - 3;
			continue;
		}

		printf("Sphere %d: %.1f %.1f %.1f, %.1f -- %d\n", i, spheres[i].pos.x, spheres[i].pos.y, spheres[i].pos.z, spheres[i].size, spheres[i].materialId);
	}

	printf("\n--- Planes (%d):\n", scene->numPlanes);
	for (unsigned int i = 0; i < scene->numPlanes; ++i)
	{
		if (scene->numPlanes > 10 && i >= 3 && i < scene->numPlanes - 3)
		{
			printf(" ... \n");
			i = scene->numPlanes - 3;
			continue;
		}

		printf("Plane %d: %.1f %.1f %.1f, %.1f %.1f %.1f -- %d\n", i,
			planes[i].pos.x, planes[i].pos.y, planes[i].pos.z,
			planes[i].normal.x, planes[i].normal.y, planes[i].normal.z,
			planes[i].materialId
		);
	}

	printf("\n--- Cylinders (%d):\n", scene->numCylinders);
	for (unsigned int i = 0; i < scene->numCylinders; ++i)
	{
		if (scene->numCylinders > 10 && i >= 3 && i < scene->numCylinders - 3)
		{
			printf(" ... \n");
			i = scene->numCylinders - 3;
			continue;
		}

		printf("Cylinder %d: %.1f %.1f %.1f, %.1f %.1f %.1f, %.1f -- %d\n", i,
			cylinders[i].p1.x, cylinders[i].p1.y, cylinders[i].p1.z,
			cylinders[i].p2.x, cylinders[i].p2.y, cylinders[i].p2.z,
			cylinders[i].size,
			cylinders[i].materialId
		);
	}

	printf("\n--- Lights (%d):\n", scene->numLights);
	for (unsigned int i = 0; i < scene->numLights; ++i)
	{
		if (scene->numLights > 10 && i >= 3 && i < scene->numLights - 3)
		{
			printf(" ... \n");
			i = scene->numLights - 3;
			continue;
		}

		printf("Light %d: %.1f %.1f %.1f -- %.1f %.1f %.1f\n", i,
			lights[i].pos.x, lights[i].pos.y, lights[i].pos.z,
			lights[i].intensity.x, lights[i].intensity.y, lights[i].intensity.z);
	}

	printf("\n--- Materials (%d):\n", scene->numMaterials);
	for (unsigned int i = 0; i < scene->numMaterials; ++i)
	{
		if (scene->numMaterials > 10 && i >= 3 && i < scene->numMaterials - 3)
		{
			printf(" ... \n");
			i = scene->numMaterials - 3;
			continue;
		}

		printf("Material %d: %d %.1f %.1f %.1f ... %.1f %.1f %.1f\n", i,
			materials[i].type,
			materials[i].diffuse.x, materials[i].diffuse.y, materials[i].diffuse.z,
			materials[i].reflection,
			materials[i].refraction,
			materials[i].density);
	}

}

/*	Material* materialContainer;
	Light* lightContainer;
	Sphere* sphereContainer;
	Plane* planeContainer;
	Cylinder* cylinderContainer;*/
	// updates intersection structure if collision occurs

bool isCylinderIntersected(__global Cylinder* cy, const Ray* r, float* t, float3* normal)
{
	// vector between start and end of the cylinder (cylinder axis, i.e. ca)
	float3 ca = cy->p2 - cy->p1;

	// vector between ray origin and start of the cylinder
	float3 oc = r->start - cy->p1;

	// cache some dot-products 
	float caca = dot(ca, ca);
	//float caca = ca * ca;
	float card = dot(ca, r->dir);
	//float card = ca * r->dir;
	float caoc = dot(ca, oc);
	//float caoc = ca * oc;

	// calculate values for coefficients of line-cylinder equation
	float a = caca - card * card;
	float b = caca * dot(oc, r->dir) - caoc * card;
	//float b = caca * (oc * r->dir) - caoc * card;
	float c = caca * dot(oc, oc) - caoc * caoc - cy->size * cy->size * caca;
	//float c = caca * (oc * oc) - caoc * caoc - cy->size * cy->size * caca;

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
		//if (abs(b + a * tCaps) < h)
	{
		// check to see if the collision point on the cylinder cap is closer than the time parameter
		if (tCaps > EPSILON && tCaps < *t)
		{
			*t = tCaps;
			*normal = ca * rsqrt(caca) * sign(y);
			//*normal = ca * invsqrtf(caca) * sign(y);
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
	// Intersection of a ray and a sphere, check the articles for the rationale
	float3 dist = s->pos - r->start;
	//float B = r->dir * dist;
	float B = dot(r->dir, dist);
	float D = B * B - dot(dist, dist) + s->size * s->size;
	//float D = B * B - dist * dist + s->size * s->size;

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

	//p.x = p.x * cos(p.y * 0.996f) * sin(p.z * 1.023f);
	//p.y = cos(p.x) * p.y * sin(p.z * 1.211f);
	//p.z = cos(p.x * 1.473f) * cos(p.y * 0.795f) * p.z;

	int which = (int)(floor(sqrt(p.x * p.x + p.y * p.y + p.z * p.z))) & 1;

	return (which ? intersect->material->diffuse : intersect->material->diffuse2);
}

float3 applyDiffuse(const Ray* lightRay, __global const Light* currentLight, const Intersection* intersect)
{
	//float3 output = intersect->material->diffuse;
	float3 output = { 0.0f, 0.0f, 0.0f };

	switch (intersect->material->type)
	{
	case GOURAUD:
		output = intersect->material->diffuse;
		break;
	case CHECKERBOARD:
		output = applyCheckerboard(intersect);
		break;
	case CIRCLES:
		output = applyCircles(intersect);
		break;
	case WOOD:
		output = applyWood(intersect);
		break;
	}

	float lambert = dot(lightRay->dir, intersect->normal);

	//printf("currlight intensity: %f, %f, %f\n", lambert * currentLight->intensity.x * output, lambert * currentLight->intensity.y * output, lambert * currentLight->intensity.z * output);

	return lambert * currentLight->intensity * output;
}

float3 applySpecular(const Ray* lightRay, __global const Light* currentLight, const float fLightProjection, const Ray* viewRay, const Intersection* intersect)
{
	float3 blinnDir = lightRay->dir - viewRay->dir;
	float blinn = rsqrt(dot(blinnDir, blinnDir)) * max(fLightProjection - intersect->viewProjection, 0.0f);
	blinn = pow(blinn, intersect->material->power);

	return blinn * intersect->material->specular * currentLight->intensity;
}

bool isInShadow(const Scene* scene, const Ray* lightRay, const float lightDist)
{
	float t = lightDist;

	// search for sphere collision
	for (unsigned int i = 0; i < scene->numSpheres; ++i)
	{
		if (isSphereIntersected(&scene->sphereContainer[i], lightRay, &t))
		{
			return true;
		}
	}

	// search for plane collision
	for (unsigned int i = 0; i < scene->numPlanes; ++i)
	{
		if (isPlaneIntersected(&scene->planeContainer[i], lightRay, &t))
		{
			return true;
		}
	}

	// search for cylinder collision
	float3 normal; // unused here, but it's necessary for the function to work
	for (unsigned int i = 0; i < scene->numCylinders; ++i)
	{
		if (isCylinderIntersected(&scene->cylinderContainer[i], lightRay, &t, &normal))
		{
			return true;
		}
	}

	// not in shadow
	return false;
}

// apply diffuse and specular lighting contributions for all lights in scene taking shadowing into account
float3 applyLighting(const Scene* scene, const Ray* viewRay, const Intersection* intersect)
{
	// colour to return (starts as black)
	float3 output = { 0.0f, 0.0f, 0.0f };

	// same starting point for each light ray
	Ray lightRay = { intersect->pos };

	// loop through all the lights
	for (unsigned int j = 0; j < scene->numLights; ++j)
	{
		// get reference to current light
		__global const Light* currentLight = &scene->lightContainer[j]; //no longer a pointer.

		// light ray direction need to equal the normalised vector in the direction of the current light
		// as we need to reuse all the intermediate components for other calculations, 
		// we calculate the normalised vector by hand instead of using the normalise function
		lightRay.dir = currentLight->pos - intersect->pos;
		float angleBetweenLightAndNormal = dot(lightRay.dir, intersect->normal);

		// skip this light if it's behind the object (ie. both light and normal pointing in the same direction)
		if (angleBetweenLightAndNormal <= 0.0f)
		{
			continue;
		}

		// distance to light from intersection point (and it's inverse)
		float lightDist = sqrt(dot(lightRay.dir, lightRay.dir));
		//float lightDist = sqrt(lightRay.dir.dot());
		float invLightDist = 1.0f / lightDist;

		// light ray projection
		float lightProjection = invLightDist * angleBetweenLightAndNormal;

		// normalise the light direction
		lightRay.dir = lightRay.dir * invLightDist;

		if (!isInShadow(scene, &lightRay, lightDist)) {
			// add diffuse lighting from colour / texture
			output += applyDiffuse(&lightRay, currentLight, intersect);

			// add specular lighting
			output += applySpecular(&lightRay, currentLight, lightProjection, viewRay, intersect);
		}
		
		
		/*if (preoutput.x != output.x || preoutput.y != output.y || preoutput.z != output.z) {
			printf("\n\nOutput Pre Spec: %f, %f, %f\nOutput Post Spec: %f, %f, %f\n", preoutput.x, preoutput.y, preoutput.z, output.x, output.y, output.z);

		}*/
		
		//printf("Output Post Spec: %f, %f, %f\n", output.x, output.y, output.z);


		/*
		//diffuse
		output = intersect->material->diffuse;
		float lambert = dot(lightRay.dir, intersect->normal);
		output += lambert * dot(currentLight->intensity, intersect->material->diffuse);

		//specular
		float3 blinnDir = lightRay.dir - viewRay->dir;
		float blinn = rsqrt(dot(blinnDir, blinnDir)) * max(lightProjection - intersect->viewProjection, 0.0f);
		blinn = pow(blinn, intersect->material->power);

		output += blinn * intersect->material->specular * currentLight->intensity;*/

		//output += applyDiffuse(&lightRay, currentLight, intersect);
		// only apply lighting from this light if not in shadow of some other object
		/*if (!isInShadow(scene, &lightRay, lightDist))
		{
			// add diffuse lighting from colour / texture
			output += applyDiffuse(&lightRay, currentLight, intersect);

			// add specular lighting
			output += applySpecular(&lightRay, currentLight, lightProjection, viewRay, intersect);
		}*/

		//printf("%f\n", currentLight.intensity);
	}


	return output;
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

Ray calculateReflection(const Ray* viewRay, const Intersection* intersect)
{
	// reflect the viewRay around the object's normal
	Ray newRay = { intersect->pos, viewRay->dir - (intersect->normal * intersect->viewProjection * 2.0f) };

	return newRay;
}

// refract the ray through an object
Ray calculateRefraction(const Ray* viewRay, const Intersection* intersect, float* currentRefractiveIndex)
{
	// change refractive index depending on whether we are in an object or not
	float oldRefractiveIndex = *currentRefractiveIndex;
	*currentRefractiveIndex = intersect->insideObject ? DEFAULT_REFRACTIVE_INDEX : intersect->material->density;

	// calculate refractive ratio from old index and current index
	float refractiveRatio = oldRefractiveIndex / *currentRefractiveIndex;

	// Here we take into account that the light movement is symmetrical from the observer to the source or from the source to the oberver.
	// We then do the computation of the coefficient by taking into account the ray coming from the viewing point.
	float fCosThetaT;
	float fCosThetaI = fabs(intersect->viewProjection);

	// glass-like material, we're computing the fresnel coefficient.
	if (fCosThetaI >= 1.0f)
	{
		// In this case the ray is coming parallel to the normal to the surface
		fCosThetaT = 1.0f;
	}
	else
	{
		float fSinThetaT = refractiveRatio * sqrt(1 - fCosThetaI * fCosThetaI);

		// Beyond the angle (1.0f) all surfaces are purely reflective
		fCosThetaT = (fSinThetaT * fSinThetaT >= 1.0f) ? 0.0f : sqrt(1 - fSinThetaT * fSinThetaT);
	}

	// Here we compute the transmitted ray with the formula of Snell-Descartes
	Ray newRay = { intersect->pos, (viewRay->dir + intersect->normal * fCosThetaI) * refractiveRatio - (intersect->normal * fCosThetaT) };

	return newRay;
}

// follow a single ray until it's final destination (or maximum number of steps reached)
float3 traceRay(const Scene* scene, Ray viewRay)
{
	float3 output = { 0.0f, 0.0f, 0.0f };
	float currentRefractiveIndex = DEFAULT_REFRACTIVE_INDEX;		// current refractive index
	float coef = 1.0f;												// amount of ray left to transmit
	Intersection intersect;
																	// loop until reached maximum ray cast limit (unless loop is broken out of)
	for (int level = 0; level < MAX_RAYS_CAST; ++level)
	{
		// check for intersections between the view ray and any of the objects in the scene
		// exit the loop if no intersection found
		if (!objectIntersection(scene, &viewRay, &intersect)) break;

		calculateIntersectionResponse(scene, &viewRay, &intersect);

		if (!intersect.insideObject) output += coef * applyLighting(scene, &viewRay, &intersect);
		
		if (intersect.material->reflection) //unsure if works or too subtle
		{
			viewRay = calculateReflection(&viewRay, &intersect);
			coef *= intersect.material->reflection;
		}
		else if (intersect.material->refraction)
		{
			viewRay = calculateRefraction(&viewRay, &intersect, &currentRefractiveIndex);
			coef *= intersect.material->refraction;
		}
		else
		{
			// if no reflection or refraction, then finish looping (cast no more rays)
			return output;
		}
	}

	// if the calculation coefficient is non-zero, read from the environment map
	if (coef > 0.0f)
	{
		//Material& currentMaterial = scene->materialContainer[scene->skyboxMaterialId];

		output += coef * scene->materialContainer[scene->skyboxMaterialId].diffuse;
	}

	return output;
}


//TODO: add an appropriate set of parameters to transfer the data
	//MAY BE ABLE TO REMOVE WWIDTH AND HHEIGHT (we have get_global_size fo dat)
__kernel void func(__global struct Scene* scenein, int width, int height, int aaLevel,
	__global Material* materialContainerIn,
	__global Light* lightContainerIn,
	__global Sphere* sphereContainerIn,
	__global Plane* planeContainerIn,
	__global Cylinder* cylinderContainerIn,
	__global int* out, int blockSize, int pos) {

	Scene scene = *scenein;

	scene.materialContainer = materialContainerIn;
	scene.lightContainer = lightContainerIn;
	scene.sphereContainer = sphereContainerIn;
	scene.planeContainer = planeContainerIn;
	scene.cylinderContainer = cylinderContainerIn;



	//unsigned int width = get_global_size(0);
	//unsigned int height = get_global_size(1);

	unsigned int ix = get_global_id(0);
	//unsigned int ix = get_global_id(0) + ((pos * blockSize) % width);
	unsigned int iy = get_global_id(1);
	//unsigned int iy = get_global_id(1) + ((pos * blockSize) % height);
	//unsigned int iy = get_global_id(1) + pos;

	float PIOVER180 = 0.017453292519943295769236907684886f;
	
	//out[iy * width + ix] = (((ix % 256) << 16) | ((0) << 8) | (iy % 256));

	// angle between each successive ray cast (per pixel, anti-aliasing uses a fraction of this)
	const float dirStepSize = 1.0f / (0.5f * width / tan(PIOVER180 * 0.5f * scene.cameraFieldOfView));

	// pointer to output buffer
	//unsigned int* out = buffer;

	// count of samples rendered
	unsigned int samplesRendered = 0;

	// loop through all the pixels
	//for (int y = -height / 2; y < height / 2; ++y)
	//{
	//	for (int x = -width / 2; x < width / 2; ++x)
	//	{

	int ix2 = ix - (width / 2) + ((pos % (width / blockSize)) * blockSize);
	int iy2 = iy - (height / 2) + ((pos / (height / blockSize)) * blockSize);

	//float xCap = (float)ix2 + (float)blockSize;
	//float yCap = (float)iy2 + (float)blockSize;


	//int ix2 = (-width / 2) + ix;
	//int iy2 = (-height / 2) + ix;
	float3 output = { 0.0f, 0.0f, 0.0f };

		// calculate multiple samples for each pixel
		const float sampleStep = 1.0f / aaLevel, sampleRatio = 1.0f / (aaLevel * aaLevel);

		// loop through all sub-locations within the pixel
		//for (float fragmentx = (float)ix2; fragmentx < ix2 + 1.0f && fragmentx < xCap; fragmentx += sampleStep)
		for (float fragmentx = (float)ix2; fragmentx < ix2 + 1.0f; fragmentx += sampleStep)
		{
			//for (float fragmenty = (float)iy2; fragmenty < iy2 + 1.0f && fragmenty < yCap; fragmenty += sampleStep)
			for (float fragmenty = (float)iy2; fragmenty < iy2 + 1.0f; fragmenty += sampleStep)
			{
				// direction of default forward facing ray
				float3 dir = { fragmentx * dirStepSize, fragmenty * dirStepSize, 1.0f };

				// rotated direction of ray
				float3 rotatedDir = {
					dir.x * cos(scene.cameraRotation) - dir.z * sin(scene.cameraRotation),
					dir.y,
					dir.x * sin(scene.cameraRotation) + dir.z * cos(scene.cameraRotation) };

				// view ray starting from camera position and heading in rotated (normalised) direction
				Ray viewRay = { scene.cameraPosition, normalise(rotatedDir) };

				// follow ray and add proportional of the result to the final pixel colour
				output += sampleRatio * traceRay(&scene, viewRay);

				// count this sample
				samplesRendered++;
			}
		}

		//output.x *= 255.0f;
		//output.y *= 255.0f;
		//output.z *= 255.0f;

		out[((iy2 + (height / 2)) * (width)+(ix2 + (width / 2)))] = (unsigned char)((min(1.0f - exp(output.z * scene.exposure), 1.0f) * 255.0f)) << 16 | (unsigned char)((min(1.0f - exp(output.y * scene.exposure), 1.0f) * 255.0f)) << 8 | (unsigned char)((min(1.0f - exp(output.x * scene.exposure), 1.0f) * 255.0f));
		//out[iy * width + ix] = (unsigned char)((min(1.0f - exp(output.z * scene.exposure), 1.0f) * 255.0f)) << 16 | (unsigned char)((min(1.0f - exp(output.y * scene.exposure), 1.0f) * 255.0f)) << 8 | (unsigned char)((min(1.0f - exp(output.x * scene.exposure), 1.0f) * 255.0f));
		
		
		//out[iy * width + ix] = (((int)(output.z * scene.exposure) << 16) | ((int)(output.y * scene.exposure) << 8) | (int)(output.x * scene.exposure));
		//*out++ = (((int)(output.x) << 16) | ((int)(output.y) << 8) | (int)(output.z));
		//*out++ = (((ix % 256) << 16) | ((0) << 8) | (iy % 256));
		//if (!testMode)
		//{
			// store saturated final colour value in image buffer
			//*out++ = (((output.x) << 16) | ((output.y) << 8) | (output.z % 256));
			//*out++ = output.convertToPixel(scene->exposure);
		//}
		//else
		//{
		//	// store colour (calculated from x,y coordinates) in image buffer 
		//	//*out++ = Colour((x + width / 2) % 256 / 255.0f, 0, (y + height / 2) % 256 / 255.0f).convertToPixel();
		//	//*out++ = (((ix % 256) << 16) | ((0) << 8) | (iy % 256));
		//}
		//}
	//}
	
	//return samplesRendered;

		//printf("GARN (pos = %d) FROM X = %d / Y = %d\n", pos, ix, iy);

	if (iy == 255 && ix == 255) {


		//printf("output after almost everything (%f, %f, %f)\n", output.x, output.y, output.z);
		//output.x = output.x * 255;
		//output.y = output.y * 255;
		//output.z = output.z * 255;
		//printf("output after everything (%f, %f, %f)\n", output.x, output.y, output.z);
		//printf("Exposure: %f\n", scene.exposure);


		//OutputInfo(&scene);

		//printf("\nSAMPLES: %d\n", aaLevel);

		printf("GARN (pos = %d) FROM X = %d / Y = %d\n", pos, ix, iy);
		//printf("GARN FROM X = %d / Y = %d\n", ix2, iy2);
		//printf("GARN FROM X = %d / Y = %d -> X = %d / Y = %d", ix2, ixy, ix2 + pos, ixy + pos);

	}
	//printf("\nSAMPLES: %d\n", aaLevel);

}
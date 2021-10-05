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
// follow a single ray until it's final destination (or maximum number of steps reached)
float3 traceRay(const Scene* scene, Ray viewRay)
{
	float3 output = { 0.0f, 0.0f, 0.0f };
	int maxRayCast = 10;

	float3 red = { 255.0f, 0.0f, 0.0f };
	float3 green = { 0.0f, 255.0f, 0.0f };
	float3 blue = { 0.0f, 0.0f, 255.0f };

	float3 black = { 0.0f, 0.0f, 0.0f }; 								// colour value to be output
	float3 white = { 255.0f, 255.0f, 255.0f }; 								// colour value to be output
	//float currentRefractiveIndex = DEFAULT_REFRACTIVE_INDEX;		// current refractive index
	float coef = 1.0f;												// amount of ray left to transmit
	Intersection intersect;											// properties of current intersection

																	// loop until reached maximum ray cast limit (unless loop is broken out of)
	for (int level = 0; level < maxRayCast; ++level)
	{
		// check for intersections between the view ray and any of the objects in the scene
		// exit the loop if no intersection found
		if (!objectIntersection(scene, &viewRay, &intersect)) break;

		switch (intersect.objectType)
		{
		case SPHERE:
			//output = red;
			intersect.normal = normalise(intersect.pos - intersect.sphere->pos);
			intersect.material = &scene->materialContainer[intersect.sphere->materialId];
			break;
		case PLANE:
			//output = green;
			intersect.normal = intersect.plane->normal;
			intersect.material = &scene->materialContainer[intersect.plane->materialId];
			break;
		case CYLINDER:			
			//normal already returned from intersection function, so nothing to do here
			//output = blue;
			intersect.material = &scene->materialContainer[intersect.cylinder->materialId];
			break;
		}

		// calculate view projection
		intersect.viewProjection = dot(viewRay->dir, intersect->normal);

		// detect if we are inside an object (needed for refraction)
		intersect.insideObject = (dot(intersect->normal, viewRay->dir) > 0.0f);

		// if inside an object, reverse the normal
		if (intersect->insideObject)
		{
			intersect.normal = intersect.normal * -1.0f;
		}

		if (!intersect.insideObject) output += coef * applyLighting(scene, &viewRay, &intersect);
		/*float t = FLT_MAX;

		for (unsigned int i = 0; i < scene->numSpheres; ++i)
		{
			if (isSphereIntersected(&scene->sphereContainer[i], &viewRay, &t))
			{
				intersect->objectType = SPHERE;
				intersect->sphere = &scene->sphereContainer[i];
				return white;
			}
		}*/

		// calculate response to collision: ie. get normal at point of collision and material of object
		//calculateIntersectionResponse(scene, &viewRay, &intersect);

		// apply the diffuse and specular lighting 
//if (!intersect.insideObject) output += coef * applyLighting(scene, &viewRay, &intersect);

		// if object has reflection or refraction component, adjust the view ray and coefficent of calculation and continue looping
		//if (intersect.material->reflection)
		//{
		//	viewRay = calculateReflection(&viewRay, &intersect);
		//	coef *= intersect.material->reflection;
		//}
		//else if (intersect.material->refraction)
		//{
		//	viewRay = calculateRefraction(&viewRay, &intersect, &currentRefractiveIndex);
		//	coef *= intersect.material->refraction;
		//}
		//else
		//{
			// if no reflection or refraction, then finish looping (cast no more rays)
		//return black;
		//}
		return output;
	}

	// if the calculation coefficient is non-zero, read from the environment map
	/*if (coef > 0.0f)
	{
		Material& currentMaterial = scene->materialContainer[scene->skyboxMaterialId];

		output += coef * currentMaterial.diffuse;
	}*/

	return output;
}

/*float dot(float3 x){
{
	return x.x * x.x + x.y * x.y + x.z * x.z;
}*/



//TODO: add an appropriate set of parameters to transfer the data
	//MAY BE ABLE TO REMOVE WWIDTH AND HHEIGHT (we have get_global_size fo dat)
__kernel void func(__global struct Scene* scenein, int wwidth, int hheight, int aaLevel,
	__global Material* materialContainerIn,
	__global Light* lightContainerIn,
	__global Sphere* sphereContainerIn,
	__global Plane* planeContainerIn,
	__global Cylinder* cylinderContainerIn,
	__global int* out) {

	Scene scene = *scenein;

	scene.materialContainer = materialContainerIn;
	scene.lightContainer = lightContainerIn;
	scene.sphereContainer = sphereContainerIn;
	scene.planeContainer = planeContainerIn;
	scene.cylinderContainer = cylinderContainerIn;


	unsigned int width = get_global_size(0);
	unsigned int height = get_global_size(1);

	unsigned int ix = get_global_id(0);
	unsigned int iy = get_global_id(1);

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

	int ix2 = ix - (width / 2);
	int iy2 = iy - (height / 2);

	//int ix2 = (-width / 2) + ix;
	//int iy2 = (-height / 2) + ix;

	float3 output = { 0.0f, 0.0f, 0.0f };

		// calculate multiple samples for each pixel
		const float sampleStep = 1.0f / aaLevel, sampleRatio = 1.0f / (aaLevel * aaLevel);

		// loop through all sub-locations within the pixel
		for (float fragmentx = (float)ix2; fragmentx < ix2 + 1.0f; fragmentx += sampleStep)
		{
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

		out[iy * width + ix] = (((int)(output.x) << 16) | ((int)(output.y) << 8) | (int)(output.z));
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

	if (iy == 0 && ix == 0) {
		//OutputInfo(&scene);

		printf("stanky leg\n");

	}


}
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
	Plane* planes = scene->planeContainer;
	Cylinder* cylinders = scene->cylinderContainer;
	Sphere* spheres = scene->sphereContainer;
	Light* lights = scene->lightContainer;
	Material* materials = scene->materialContainer;

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

//TODO: add an appropriate set of parameters to transfer the data
__kernel void func(__global struct Scene* scenein, int width, int height, int aaLevel,
	__global Material* materialContainerIn,
	__global Light* lightContainerIn,
	__global Sphere* sphereContainerIn,
	__global Plane* planeContainerIn,
	__global Cylinder* cylinderContainerIn) {

	Scene scene = *scenein;

	scene.materialContainer = materialContainerIn;
	scene.lightContainer = lightContainerIn;
	scene.sphereContainer = sphereContainerIn;
	scene.planeContainer = planeContainerIn;
	scene.cylinderContainer = cylinderContainerIn;

	printf("hello world\n");
	printf("width: %d, height: %d\n", width, height);
	//printf("cameraFieldOfView: %d\n", scene.cameraFieldOfView);

	OutputInfo(&scene);
}
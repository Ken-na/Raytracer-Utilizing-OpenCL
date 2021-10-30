enum PrimitiveType { NONE, SPHERE, PLANE, CYLINDER };

float3 normalise(float3 x)
{
	return x * rsqrt(dot(x, x));
}

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

#include <stdlib.h>
#include <stdio.h>

#if defined(_WIN32) && _MSC_VER > 1200
#define STBIR_ASSERT(x) \
	if (!(x)) {         \
		__debugbreak();  \
	} else
#else
#include <assert.h>
#define STBIR_ASSERT(x) assert(x)
#endif

#define STBIR_MALLOC stbir_malloc
#define STBIR_FREE stbir_free

class stbir_context {
public:
	stbir_context()
	{
		size = 1000000;
		memory = malloc(size);
	}

	~stbir_context()
	{
		free(memory);
	}

	size_t size;
	void* memory;
} g_context;

void* stbir_malloc(size_t size, void* context)
{
	if (!context)
		return malloc(size);

	stbir_context* real_context = (stbir_context*)context;
	if (size > real_context->size)
		return 0;

	return real_context->memory;
}

void stbir_free(void* memory, void* context)
{
	if (!context)
		free(memory);
}

//#include <stdio.h>
void stbir_progress(float p)
{
	//printf("%f\n", p);
	STBIR_ASSERT(p >= 0 && p <= 1);
}

#define STBIR_PROGRESS_REPORT stbir_progress

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#define STB_IMAGE_RESIZE_STATIC
#include "stb_image_resize.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#ifdef _WIN32
#include <sys/timeb.h>
#endif

#include <direct.h>

#define MT_SIZE 624
static size_t g_aiMT[MT_SIZE];
static size_t g_iMTI = 0;

// Mersenne Twister implementation from Wikipedia.
// Avoiding use of the system rand() to be sure that our tests generate the same test data on any system.
void mtsrand(size_t iSeed)
{
	g_aiMT[0] = iSeed;
	for (size_t i = 1; i < MT_SIZE; i++)
	{
		size_t inner1 = g_aiMT[i - 1];
		size_t inner2 = (g_aiMT[i - 1] >> 30);
		size_t inner = inner1 ^ inner2;
		g_aiMT[i] = (0x6c078965 * inner) + i;
	}

	g_iMTI = 0;
}

size_t mtrand()
{
	if (g_iMTI == 0)
	{
		for (size_t i = 0; i < MT_SIZE; i++)
		{
			size_t y = (0x80000000 & (g_aiMT[i])) + (0x7fffffff & (g_aiMT[(i + 1) % MT_SIZE]));
			g_aiMT[i] = g_aiMT[(i + 397) % MT_SIZE] ^ (y >> 1);
			if ((y % 2) == 1)
				g_aiMT[i] = g_aiMT[i] ^ 0x9908b0df;
		}
	}

	size_t y = g_aiMT[g_iMTI];
	y = y ^ (y >> 11);
	y = y ^ ((y << 7) & (0x9d2c5680));
	y = y ^ ((y << 15) & (0xefc60000));
	y = y ^ (y >> 18);

	g_iMTI = (g_iMTI + 1) % MT_SIZE;

	return y;
}


inline float mtfrand()
{
	const int ninenine = 999999;
	return (float)(mtrand() % ninenine)/ninenine;
}

static void resizer(int argc, char **argv)
{
	unsigned char* input_pixels;
	unsigned char* output_pixels;
	int w, h;
	int n;
	int out_w, out_h;
	input_pixels = stbi_load(argv[1], &w, &h, &n, 0);
	out_w = w*3;
	out_h = h*3;
	output_pixels = (unsigned char*) malloc(out_w*out_h*n);
	//stbir_resize_uint8_srgb(input_pixels, w, h, 0, output_pixels, out_w, out_h, 0, n, -1,0);
	stbir_resize_uint8(input_pixels, w, h, 0, output_pixels, out_w, out_h, 0, n);
	stbi_write_png("output.png", out_w, out_h, n, output_pixels, 0);
	exit(0);
}

static void performance(int argc, char **argv)
{
	unsigned char* input_pixels;
	unsigned char* output_pixels;
	int w, h, count;
	int n, i;
	int out_w, out_h, srgb=1;
	input_pixels = stbi_load(argv[1], &w, &h, &n, 0);
    #if 0
    out_w = w/4; out_h = h/4; count=100; // 1
    #elif 0
	out_w = w*2; out_h = h/4; count=20; // 2   // note this is structured pessimily, would be much faster to downsample vertically first
    #elif 0
    out_w = w/4; out_h = h*2; count=50; // 3
    #elif 0
    out_w = w*3; out_h = h*3; count=2; srgb=0; // 4
    #else
    out_w = w*3; out_h = h*3; count=2; // 5   // this is dominated by linear->sRGB conversion
    #endif

	output_pixels = (unsigned char*) malloc(out_w*out_h*n);
    for (i=0; i < count; ++i)
        if (srgb)
	        stbir_resize_uint8_srgb(input_pixels, w, h, 0, output_pixels, out_w, out_h, 0, n,-1,0);
        else
	        stbir_resize(input_pixels, w, h, 0, output_pixels, out_w, out_h, 0, STBIR_TYPE_UINT8, n,-1, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_DEFAULT, STBIR_FILTER_DEFAULT, STBIR_COLORSPACE_LINEAR, NULL);
	exit(0);
}

void test_suite(int argc, char **argv);

int main(int argc, char** argv)
{
	//resizer(argc, argv);
    //performance(argc, argv);

	test_suite(argc, argv);
	return 0;
}

void resize_image(const char* filename, float width_percent, float height_percent, stbir_filter filter, stbir_edge edge, stbir_colorspace colorspace, const char* output_filename)
{
	int w, h, n;

	unsigned char* input_data = stbi_load(filename, &w, &h, &n, 0);
	if (!input_data)
	{
		printf("Input image could not be loaded\n");
		return;
	}

	int out_w = (int)(w * width_percent);
	int out_h = (int)(h * height_percent);

	unsigned char* output_data = (unsigned char*)malloc(out_w * out_h * n);

	stbir_resize(input_data, w, h, 0, output_data, out_w, out_h, 0, STBIR_TYPE_UINT8, n, STBIR_ALPHA_CHANNEL_NONE, 0, edge, edge, filter, filter, colorspace, &g_context);

	stbi_image_free(input_data);

	stbi_write_png(output_filename, out_w, out_h, n, output_data, 0);

	free(output_data);
}

template <typename F, typename T>
void convert_image(const F* input, T* output, int length)
{
	double f = (pow(2.0, 8.0 * sizeof(T)) - 1) / (pow(2.0, 8.0 * sizeof(F)) - 1);
	for (int i = 0; i < length; i++)
		output[i] = (T)(((double)input[i]) * f);
}

template <typename T>
void test_format(const char* file, float width_percent, float height_percent, stbir_datatype type, stbir_colorspace colorspace)
{
	int w, h, n;
	unsigned char* input_data = stbi_load(file, &w, &h, &n, 0);

	if (input_data == NULL)
		return;


	int new_w = (int)(w * width_percent);
	int new_h = (int)(h * height_percent);

	T* T_data = (T*)malloc(w * h * n * sizeof(T));
    memset(T_data, 0, w*h*n*sizeof(T));
	convert_image<unsigned char, T>(input_data, T_data, w * h * n);

	T* output_data = (T*)malloc(new_w * new_h * n * sizeof(T));

	stbir_resize(T_data, w, h, 0, output_data, new_w, new_h, 0, type, n, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, colorspace, &g_context);

	free(T_data);
	stbi_image_free(input_data);

	unsigned char* char_data = (unsigned char*)malloc(new_w * new_h * n * sizeof(char));
	convert_image<T, unsigned char>(output_data, char_data, new_w * new_h * n);

	char output[200];
	sprintf(output, "test-output/type-%d-%d-%d-%d-%s", type, colorspace, new_w, new_h, file);
	stbi_write_png(output, new_w, new_h, n, char_data, 0);

	free(char_data);
	free(output_data);
}

void convert_image_float(const unsigned char* input, float* output, int length)
{
	for (int i = 0; i < length; i++)
		output[i] = ((float)input[i])/255;
}

void convert_image_float(const float* input, unsigned char* output, int length)
{
	for (int i = 0; i < length; i++)
		output[i] = (unsigned char)(stbir__saturate(input[i]) * 255);
}

void test_float(const char* file, float width_percent, float height_percent, stbir_datatype type, stbir_colorspace colorspace)
{
	int w, h, n;
	unsigned char* input_data = stbi_load(file, &w, &h, &n, 0);

	if (input_data == NULL)
		return;

	int new_w = (int)(w * width_percent);
	int new_h = (int)(h * height_percent);

	float* T_data = (float*)malloc(w * h * n * sizeof(float));
	convert_image_float(input_data, T_data, w * h * n);

	float* output_data = (float*)malloc(new_w * new_h * n * sizeof(float));

	stbir_resize_float_generic(T_data, w, h, 0, output_data, new_w, new_h, 0, n, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, colorspace, &g_context);

	free(T_data);
	stbi_image_free(input_data);

	unsigned char* char_data = (unsigned char*)malloc(new_w * new_h * n * sizeof(char));
	convert_image_float(output_data, char_data, new_w * new_h * n);

	char output[200];
	sprintf(output, "test-output/type-%d-%d-%d-%d-%s", type, colorspace, new_w, new_h, file);
	stbi_write_png(output, new_w, new_h, n, char_data, 0);

	free(char_data);
	free(output_data);
}

void test_channels(const char* file, float width_percent, float height_percent, int channels)
{
	int w, h, n;
	unsigned char* input_data = stbi_load(file, &w, &h, &n, 0);

	if (input_data == NULL)
		return;

	int new_w = (int)(w * width_percent);
	int new_h = (int)(h * height_percent);

	unsigned char* channels_data = (unsigned char*)malloc(w * h * channels * sizeof(unsigned char));

	for (int i = 0; i < w * h; i++)
	{
		int input_position = i * n;
		int output_position = i * channels;

		for (int c = 0; c < channels; c++)
			channels_data[output_position + c] = input_data[input_position + stbir__min(c, n)];
	}

	unsigned char* output_data = (unsigned char*)malloc(new_w * new_h * channels * sizeof(unsigned char));

	stbir_resize_uint8_srgb(channels_data, w, h, 0, output_data, new_w, new_h, 0, channels, STBIR_ALPHA_CHANNEL_NONE, 0);

	free(channels_data);
	stbi_image_free(input_data);

	char output[200];
	sprintf(output, "test-output/channels-%d-%d-%d-%s", channels, new_w, new_h, file);
	stbi_write_png(output, new_w, new_h, channels, output_data, 0);

	free(output_data);
}

void test_subpixel(const char* file, float width_percent, float height_percent, float s1, float t1)
{
	int w, h, n;
	unsigned char* input_data = stbi_load(file, &w, &h, &n, 0);

	if (input_data == NULL)
		return;

	s1 = ((float)w - 1 + s1)/w;
	t1 = ((float)h - 1 + t1)/h;

	int new_w = (int)(w * width_percent);
	int new_h = (int)(h * height_percent);

	unsigned char* output_data = (unsigned char*)malloc(new_w * new_h * n * sizeof(unsigned char));

	stbir_resize_region(input_data, w, h, 0, output_data, new_w, new_h, 0, STBIR_TYPE_UINT8, n, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, 0, 0, s1, t1);

	stbi_image_free(input_data);

	char output[200];
	sprintf(output, "test-output/subpixel-%d-%d-%f-%f-%s", new_w, new_h, s1, t1, file);
	stbi_write_png(output, new_w, new_h, n, output_data, 0);

	free(output_data);
}

void test_subpixel_region(const char* file, float width_percent, float height_percent, float s0, float t0, float s1, float t1)
{
	int w, h, n;
	unsigned char* input_data = stbi_load(file, &w, &h, &n, 0);

	if (input_data == NULL)
		return;

	int new_w = (int)(w * width_percent);
	int new_h = (int)(h * height_percent);

	unsigned char* output_data = (unsigned char*)malloc(new_w * new_h * n * sizeof(unsigned char));

	stbir_resize_region(input_data, w, h, 0, output_data, new_w, new_h, 0, STBIR_TYPE_UINT8, n, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, s0, t0, s1, t1);

	stbi_image_free(input_data);

	char output[200];
	sprintf(output, "test-output/subpixel-region-%d-%d-%f-%f-%f-%f-%s", new_w, new_h, s0, t0, s1, t1, file);
	stbi_write_png(output, new_w, new_h, n, output_data, 0);

	free(output_data);
}

void test_subpixel_command(const char* file, float width_percent, float height_percent, float x_scale, float y_scale, float x_offset, float y_offset)
{
	int w, h, n;
	unsigned char* input_data = stbi_load(file, &w, &h, &n, 0);

	if (input_data == NULL)
		return;

	int new_w = (int)(w * width_percent);
	int new_h = (int)(h * height_percent);

	unsigned char* output_data = (unsigned char*)malloc(new_w * new_h * n * sizeof(unsigned char));

	stbir_resize_subpixel(input_data, w, h, 0, output_data, new_w, new_h, 0, STBIR_TYPE_UINT8, n, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, x_scale, y_scale, x_offset, y_offset);

	stbi_image_free(input_data);

	char output[200];
	sprintf(output, "test-output/subpixel-command-%d-%d-%f-%f-%f-%f-%s", new_w, new_h, x_scale, y_scale, x_offset, y_offset, file);
	stbi_write_png(output, new_w, new_h, n, output_data, 0);

	free(output_data);
}

unsigned int* pixel(unsigned int* buffer, int x, int y, int c, int w, int n)
{
	return &buffer[y*w*n + x*n + c];
}

void test_premul()
{
	unsigned int input[2 * 2 * 4];
	unsigned int output[1 * 1 * 4];
	unsigned int output2[2 * 2 * 4];

	memset(input, 0, sizeof(input));

	// First a test to make sure premul is working properly.

	// Top left - solid red
	*pixel(input, 0, 0, 0, 2, 4) = 255;
	*pixel(input, 0, 0, 3, 2, 4) = 255;

	// Bottom left - solid red
	*pixel(input, 0, 1, 0, 2, 4) = 255;
	*pixel(input, 0, 1, 3, 2, 4) = 255;

	// Top right - transparent green
	*pixel(input, 1, 0, 1, 2, 4) = 255;
	*pixel(input, 1, 0, 3, 2, 4) = 25;

	// Bottom right - transparent green
	*pixel(input, 1, 1, 1, 2, 4) = 255;
	*pixel(input, 1, 1, 3, 2, 4) = 25;

	stbir_resize(input, 2, 2, 0, output, 1, 1, 0, STBIR_TYPE_UINT32, 4, 3, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_BOX, STBIR_COLORSPACE_LINEAR, &g_context);

	float r = (float)255 / 4294967296;
	float g = (float)255 / 4294967296;
	float ra = (float)255 / 4294967296;
	float ga = (float)25 / 4294967296;
	float a = (ra + ga) / 2;

	STBIR_ASSERT(output[0] == (unsigned int)(r * ra / 2 / a * 4294967296 + 0.5f)); // 232
	STBIR_ASSERT(output[1] == (unsigned int)(g * ga / 2 / a * 4294967296 + 0.5f)); // 23
	STBIR_ASSERT(output[2] == 0);
	STBIR_ASSERT(output[3] == (unsigned int)(a * 4294967296 + 0.5f)); // 140

	// Now a test to make sure it doesn't clobber existing values.

	// Top right - completely transparent green
	*pixel(input, 1, 0, 1, 2, 4) = 255;
	*pixel(input, 1, 0, 3, 2, 4) = 0;

	// Bottom right - completely transparent green
	*pixel(input, 1, 1, 1, 2, 4) = 255;
	*pixel(input, 1, 1, 3, 2, 4) = 0;

	stbir_resize(input, 2, 2, 0, output2, 2, 2, 0, STBIR_TYPE_UINT32, 4, 3, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_BOX, STBIR_COLORSPACE_LINEAR, &g_context);

	STBIR_ASSERT(*pixel(output2, 0, 0, 0, 2, 4) == 255);
	STBIR_ASSERT(*pixel(output2, 0, 0, 1, 2, 4) == 0);
	STBIR_ASSERT(*pixel(output2, 0, 0, 2, 2, 4) == 0);
	STBIR_ASSERT(*pixel(output2, 0, 0, 3, 2, 4) == 255);

	STBIR_ASSERT(*pixel(output2, 0, 1, 0, 2, 4) == 255);
	STBIR_ASSERT(*pixel(output2, 0, 1, 1, 2, 4) == 0);
	STBIR_ASSERT(*pixel(output2, 0, 1, 2, 2, 4) == 0);
	STBIR_ASSERT(*pixel(output2, 0, 1, 3, 2, 4) == 255);

	STBIR_ASSERT(*pixel(output2, 1, 0, 0, 2, 4) == 0);
	STBIR_ASSERT(*pixel(output2, 1, 0, 1, 2, 4) == 255);
	STBIR_ASSERT(*pixel(output2, 1, 0, 2, 2, 4) == 0);
	STBIR_ASSERT(*pixel(output2, 1, 0, 3, 2, 4) == 0);

	STBIR_ASSERT(*pixel(output2, 1, 1, 0, 2, 4) == 0);
	STBIR_ASSERT(*pixel(output2, 1, 1, 1, 2, 4) == 255);
	STBIR_ASSERT(*pixel(output2, 1, 1, 2, 2, 4) == 0);
	STBIR_ASSERT(*pixel(output2, 1, 1, 3, 2, 4) == 0);
}

// test that splitting a pow-2 image into tiles produces identical results
void test_subpixel_1()
{
	unsigned char image[8 * 8];

	mtsrand(0);

	for (int i = 0; i < sizeof(image); i++)
		image[i] = mtrand() & 255;

	unsigned char output_data[16 * 16];

	stbir_resize_region(image, 8, 8, 0, output_data, 16, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, 0, 0, 1, 1);

	unsigned char output_left[8 * 16];
	unsigned char output_right[8 * 16];

	stbir_resize_region(image, 8, 8, 0, output_left, 8, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, 0, 0, 0.5f, 1);
	stbir_resize_region(image, 8, 8, 0, output_right, 8, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, 0.5f, 0, 1, 1);

	for (int x = 0; x < 8; x++)
	{
		for (int y = 0; y < 16; y++)
		{
			STBIR_ASSERT(output_data[y * 16 + x] == output_left[y * 8 + x]);
			STBIR_ASSERT(output_data[y * 16 + x + 8] == output_right[y * 8 + x]);
		}
	}

	stbir_resize_subpixel(image, 8, 8, 0, output_left, 8, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, 2, 2, 0, 0);
	stbir_resize_subpixel(image, 8, 8, 0, output_right, 8, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, 2, 2, 8, 0);

	{for (int x = 0; x < 8; x++)
	{
		for (int y = 0; y < 16; y++)
		{
			STBIR_ASSERT(output_data[y * 16 + x] == output_left[y * 8 + x]);
			STBIR_ASSERT(output_data[y * 16 + x + 8] == output_right[y * 8 + x]);
		}
	}}
}

// test that replicating an image and using a subtile of it produces same results as wraparound
void test_subpixel_2()
{
	unsigned char image[8 * 8];

	mtsrand(0);

	for (int i = 0; i < sizeof(image); i++)
		image[i] = mtrand() & 255;

	unsigned char large_image[32 * 32];

	for (int x = 0; x < 8; x++)
	{
		for (int y = 0; y < 8; y++)
		{
			for (int i = 0; i < 4; i++)
			{
				for (int j = 0; j < 4; j++)
					large_image[j*4*8*8 + i*8 + y*4*8 + x] = image[y*8 + x];
			}
		}
	}

	unsigned char output_data_1[16 * 16];
	unsigned char output_data_2[16 * 16];

	stbir_resize(image, 8, 8, 0, output_data_1, 16, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_WRAP, STBIR_EDGE_WRAP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context);
	stbir_resize_region(large_image, 32, 32, 0, output_data_2, 16, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_WRAP, STBIR_EDGE_WRAP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, 0.25f, 0.25f, 0.5f, 0.5f);

	{for (int x = 0; x < 16; x++)
	{
		for (int y = 0; y < 16; y++)
			STBIR_ASSERT(output_data_1[y * 16 + x] == output_data_2[y * 16 + x]);
	}}

	stbir_resize_subpixel(large_image, 32, 32, 0, output_data_2, 16, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_WRAP, STBIR_EDGE_WRAP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context, 2, 2, 16, 16);

	{for (int x = 0; x < 16; x++)
	{
		for (int y = 0; y < 16; y++)
			STBIR_ASSERT(output_data_1[y * 16 + x] == output_data_2[y * 16 + x]);
	}}
}

// test that 0,0,1,1 subpixel produces same result as no-rect
void test_subpixel_3()
{
	unsigned char image[8 * 8];

	mtsrand(0);

	for (int i = 0; i < sizeof(image); i++)
		image[i] = mtrand() & 255;

	unsigned char output_data_1[32 * 32];
	unsigned char output_data_2[32 * 32];

	stbir_resize_region(image, 8, 8, 0, output_data_1, 32, 32, 0, STBIR_TYPE_UINT8, 1, 0, STBIR_ALPHA_CHANNEL_NONE, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_LINEAR, NULL, 0, 0, 1, 1);
	stbir_resize_uint8(image, 8, 8, 0, output_data_2, 32, 32, 0, 1);

	for (int x = 0; x < 32; x++)
	{
		for (int y = 0; y < 32; y++)
			STBIR_ASSERT(output_data_1[y * 32 + x] == output_data_2[y * 32 + x]);
	}

	stbir_resize_subpixel(image, 8, 8, 0, output_data_1, 32, 32, 0, STBIR_TYPE_UINT8, 1, 0, STBIR_ALPHA_CHANNEL_NONE, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_LINEAR, NULL, 4, 4, 0, 0);

	{for (int x = 0; x < 32; x++)
	{
		for (int y = 0; y < 32; y++)
			STBIR_ASSERT(output_data_1[y * 32 + x] == output_data_2[y * 32 + x]);
	}}
}

// test that 1:1 resample using s,t=0,0,1,1 with bilinear produces original image
void test_subpixel_4()
{
	unsigned char image[8 * 8];

	mtsrand(0);

	for (int i = 0; i < sizeof(image); i++)
		image[i] = mtrand() & 255;

	unsigned char output[8 * 8];

	stbir_resize_region(image, 8, 8, 0, output, 8, 8, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_TRIANGLE, STBIR_FILTER_TRIANGLE, STBIR_COLORSPACE_LINEAR, &g_context, 0, 0, 1, 1);
	STBIR_ASSERT(memcmp(image, output, 8 * 8) == 0);

	stbir_resize_subpixel(image, 8, 8, 0, output, 8, 8, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_TRIANGLE, STBIR_FILTER_TRIANGLE, STBIR_COLORSPACE_LINEAR, &g_context, 1, 1, 0, 0);
	STBIR_ASSERT(memcmp(image, output, 8 * 8) == 0);
}

static unsigned int  image88_int[8][8];
static unsigned char image88 [8][8];
static unsigned char output88[8][8];
static unsigned char output44[4][4];
static unsigned char output22[2][2];
static unsigned char output11[1][1];

void resample_88(stbir_filter filter)
{
	stbir_resize_uint8_generic(image88[0],8,8,0, output88[0],8,8,0, 1,-1,0, STBIR_EDGE_CLAMP, filter, STBIR_COLORSPACE_LINEAR, NULL);
	stbir_resize_uint8_generic(image88[0],8,8,0, output44[0],4,4,0, 1,-1,0, STBIR_EDGE_CLAMP, filter, STBIR_COLORSPACE_LINEAR, NULL);
	stbir_resize_uint8_generic(image88[0],8,8,0, output22[0],2,2,0, 1,-1,0, STBIR_EDGE_CLAMP, filter, STBIR_COLORSPACE_LINEAR, NULL);
	stbir_resize_uint8_generic(image88[0],8,8,0, output11[0],1,1,0, 1,-1,0, STBIR_EDGE_CLAMP, filter, STBIR_COLORSPACE_LINEAR, NULL);
}

void verify_box(void)
{
	int i,j,t;

	resample_88(STBIR_FILTER_BOX);

	for (i=0; i < sizeof(image88); ++i)
		STBIR_ASSERT(image88[0][i] == output88[0][i]);

	t = 0;
	for (j=0; j < 4; ++j)
		for (i=0; i < 4; ++i) {
			int n = image88[j*2+0][i*2+0]
			      + image88[j*2+0][i*2+1]
				  + image88[j*2+1][i*2+0]
				  + image88[j*2+1][i*2+1];
			STBIR_ASSERT(output44[j][i] == ((n+2)>>2) || output44[j][i] == ((n+1)>>2)); // can't guarantee exact rounding due to numerical precision
			t += n;
		}
	STBIR_ASSERT(output11[0][0] == ((t+32)>>6) || output11[0][0] == ((t+31)>>6)); // can't guarantee exact rounding due to numerical precision
}

void verify_filter_normalized(stbir_filter filter, int output_size, unsigned int value)
{
	int i, j;
	unsigned int output[64];

	stbir_resize(image88_int[0], 8, 8, 0, output, output_size, output_size, 0, STBIR_TYPE_UINT32, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, filter, filter, STBIR_COLORSPACE_LINEAR, NULL);

	for (j = 0; j < output_size; ++j)
		for (i = 0; i < output_size; ++i)
			STBIR_ASSERT(value == output[j*output_size + i]);
}

float round2(float f)
{
	return (float) floor(f+0.5f); // round() isn't C standard pre-C99
}

void test_filters(void)
{
	int i,j;

	mtsrand(0);

	for (i=0; i < sizeof(image88); ++i)
		image88[0][i] = mtrand() & 255;
	verify_box();

	for (i=0; i < sizeof(image88); ++i)
		image88[0][i] = 0;
	image88[4][4] = 255;
	verify_box();

	for (j=0; j < 8; ++j)
		for (i=0; i < 8; ++i)
			image88[j][i] = (j^i)&1 ? 255 : 0;
	verify_box();

	for (j=0; j < 8; ++j)
		for (i=0; i < 8; ++i)
			image88[j][i] = i&2 ? 255 : 0;
	verify_box();

	int value = 64;

	for (j = 0; j < 8; ++j)
		for (i = 0; i < 8; ++i)
			image88_int[j][i] = value;

	verify_filter_normalized(STBIR_FILTER_BOX, 8, value);
	verify_filter_normalized(STBIR_FILTER_TRIANGLE, 8, value);
	verify_filter_normalized(STBIR_FILTER_CUBICBSPLINE, 8, value);
	verify_filter_normalized(STBIR_FILTER_CATMULLROM, 8, value);
	verify_filter_normalized(STBIR_FILTER_MITCHELL, 8, value);

	verify_filter_normalized(STBIR_FILTER_BOX, 4, value);
	verify_filter_normalized(STBIR_FILTER_TRIANGLE, 4, value);
	verify_filter_normalized(STBIR_FILTER_CUBICBSPLINE, 4, value);
	verify_filter_normalized(STBIR_FILTER_CATMULLROM, 4, value);
	verify_filter_normalized(STBIR_FILTER_MITCHELL, 4, value);

	verify_filter_normalized(STBIR_FILTER_BOX, 2, value);
	verify_filter_normalized(STBIR_FILTER_TRIANGLE, 2, value);
	verify_filter_normalized(STBIR_FILTER_CUBICBSPLINE, 2, value);
	verify_filter_normalized(STBIR_FILTER_CATMULLROM, 2, value);
	verify_filter_normalized(STBIR_FILTER_MITCHELL, 2, value);

	verify_filter_normalized(STBIR_FILTER_BOX, 1, value);
	verify_filter_normalized(STBIR_FILTER_TRIANGLE, 1, value);
	verify_filter_normalized(STBIR_FILTER_CUBICBSPLINE, 1, value);
	verify_filter_normalized(STBIR_FILTER_CATMULLROM, 1, value);
	verify_filter_normalized(STBIR_FILTER_MITCHELL, 1, value);

	{
		// This test is designed to produce coefficients that are very badly denormalized.
		unsigned int v = 556;

		unsigned int input[100 * 100];
		unsigned int output[11 * 11];

		for (j = 0; j < 100 * 100; ++j)
			input[j] = v;

		stbir_resize(input, 100, 100, 0, output, 11, 11, 0, STBIR_TYPE_UINT32, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_TRIANGLE, STBIR_FILTER_TRIANGLE, STBIR_COLORSPACE_LINEAR, NULL);

		for (j = 0; j < 11 * 11; ++j)
			STBIR_ASSERT(v == output[j]);
	}

	{
		// Now test the trapezoid filter for downsampling.
		unsigned int input[3 * 1];
		unsigned int output[2 * 1];

		input[0] = 0;
		input[1] = 255;
		input[2] = 127;

		stbir_resize(input, 3, 1, 0, output, 2, 1, 0, STBIR_TYPE_UINT32, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_BOX, STBIR_COLORSPACE_LINEAR, NULL);

		STBIR_ASSERT(output[0] == (unsigned int)round2((float)(input[0] * 2 + input[1]) / 3));
		STBIR_ASSERT(output[1] == (unsigned int)round2((float)(input[2] * 2 + input[1]) / 3));

		stbir_resize(input, 1, 3, 0, output, 1, 2, 0, STBIR_TYPE_UINT32, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_BOX, STBIR_COLORSPACE_LINEAR, NULL);

		STBIR_ASSERT(output[0] == (unsigned int)round2((float)(input[0] * 2 + input[1]) / 3));
		STBIR_ASSERT(output[1] == (unsigned int)round2((float)(input[2] * 2 + input[1]) / 3));
	}

	{
		// Now test the trapezoid filter for upsampling.
		unsigned int input[2 * 1];
		unsigned int output[3 * 1];

		input[0] = 0;
		input[1] = 255;

		stbir_resize(input, 2, 1, 0, output, 3, 1, 0, STBIR_TYPE_UINT32, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_BOX, STBIR_COLORSPACE_LINEAR, NULL);

		STBIR_ASSERT(output[0] == input[0]);
		STBIR_ASSERT(output[1] == (input[0] + input[1]) / 2);
		STBIR_ASSERT(output[2] == input[1]);

		stbir_resize(input, 1, 2, 0, output, 1, 3, 0, STBIR_TYPE_UINT32, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_BOX, STBIR_COLORSPACE_LINEAR, NULL);

		STBIR_ASSERT(output[0] == input[0]);
		STBIR_ASSERT(output[1] == (input[0] + input[1]) / 2);
		STBIR_ASSERT(output[2] == input[1]);
	}

	// checkerboard
	{
		unsigned char input[64][64];
		unsigned char output[16][16];
		int i,j;
		for (j=0; j < 64; ++j)
			for (i=0; i < 64; ++i)
				input[j][i] = (i^j)&1 ? 255 : 0;
		stbir_resize_uint8_generic(input[0], 64, 64, 0, output[0],16,16,0, 1,-1,0,STBIR_EDGE_WRAP,STBIR_FILTER_DEFAULT,STBIR_COLORSPACE_LINEAR,0);
		for (j=0; j < 16; ++j)
			for (i=0; i < 16; ++i)
				STBIR_ASSERT(output[j][i] == 128);
		stbir_resize_uint8_srgb_edgemode(input[0], 64, 64, 0, output[0],16,16,0, 1,-1,0,STBIR_EDGE_WRAP);
		for (j=0; j < 16; ++j)
			for (i=0; i < 16; ++i)
				STBIR_ASSERT(output[j][i] == 188);


	}

	{
		// Test trapezoid box filter
		unsigned char input[2 * 1];
		unsigned char output[127 * 1];

		input[0] = 0;
		input[1] = 255;

		stbir_resize(input, 2, 1, 0, output, 127, 1, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_BOX, STBIR_COLORSPACE_LINEAR, NULL);
		STBIR_ASSERT(output[0] == 0);
		STBIR_ASSERT(output[127 / 2 - 1] == 0);
		STBIR_ASSERT(output[127 / 2] == 128);
		STBIR_ASSERT(output[127 / 2 + 1] == 255);
		STBIR_ASSERT(output[126] == 255);
		stbi_write_png("test-output/trapezoid-upsample-horizontal.png", 127, 1, 1, output, 0);

		stbir_resize(input, 1, 2, 0, output, 1, 127, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_BOX, STBIR_COLORSPACE_LINEAR, NULL);
		STBIR_ASSERT(output[0] == 0);
		STBIR_ASSERT(output[127 / 2 - 1] == 0);
		STBIR_ASSERT(output[127 / 2] == 128);
		STBIR_ASSERT(output[127 / 2 + 1] == 255);
		STBIR_ASSERT(output[126] == 255);
		stbi_write_png("test-output/trapezoid-upsample-vertical.png", 1, 127, 1, output, 0);
	}
}

#define UMAX32   4294967295U

static void write32(char *filename, stbir_uint32 *output, int w, int h)
{
    stbir_uint8 *data = (stbir_uint8*) malloc(w*h*3);
    for (int i=0; i < w*h*3; ++i)
        data[i] = output[i]>>24;
    stbi_write_png(filename, w, h, 3, data, 0);
    free(data);
}

static void test_32(void)
{
    int w=100,h=120,x,y, out_w,out_h;
    stbir_uint32 *input  = (stbir_uint32*) malloc(4 * 3 * w * h);
    stbir_uint32 *output = (stbir_uint32*) malloc(4 * 3 * 3*w * 3*h);
    for (y=0; y < h; ++y) {
        for (x=0; x < w; ++x) {
            input[y*3*w + x*3 + 0] = x * ( UMAX32/w );
            input[y*3*w + x*3 + 1] = y * ( UMAX32/h );
            input[y*3*w + x*3 + 2] = UMAX32/2;
        }
    }
    out_w = w*33/16;
    out_h = h*33/16;
    stbir_resize(input,w,h,0,output,out_w,out_h,0,STBIR_TYPE_UINT32,3,-1,0,STBIR_EDGE_CLAMP,STBIR_EDGE_CLAMP,STBIR_FILTER_DEFAULT,STBIR_FILTER_DEFAULT,STBIR_COLORSPACE_LINEAR,NULL);
    write32("test-output/seantest_1.png", output,out_w,out_h);

    out_w = w*16/33;
    out_h = h*16/33;
    stbir_resize(input,w,h,0,output,out_w,out_h,0,STBIR_TYPE_UINT32,3,-1,0,STBIR_EDGE_CLAMP,STBIR_EDGE_CLAMP,STBIR_FILTER_DEFAULT,STBIR_FILTER_DEFAULT,STBIR_COLORSPACE_LINEAR,NULL);
    write32("test-output/seantest_2.png", output,out_w,out_h);
}


void test_suite(int argc, char **argv)
{
	int i;
	char *barbara;

	_mkdir("test-output");

	if (argc > 1)
		barbara = argv[1];
	else
		barbara = "barbara.png";

	// check what cases we need normalization for
#if 1
	{
		float x, y;
		for (x = -1; x < 1; x += 0.05f) {
			float sums[5] = { 0 };
			float o;
			for (o = -5; o <= 5; ++o) {
				sums[0] += stbir__filter_mitchell(x + o, 1);
				sums[1] += stbir__filter_catmullrom(x + o, 1);
				sums[2] += stbir__filter_cubic(x + o, 1);
				sums[3] += stbir__filter_triangle(x + o, 1);
				sums[4] += stbir__filter_trapezoid(x + o, 0.5f);
			}
			for (i = 0; i < 5; ++i)
				STBIR_ASSERT(sums[i] >= 1.0 - 0.001 && sums[i] <= 1.0 + 0.001);
		}

#if 1	
		for (y = 0.11f; y < 1; y += 0.01f) {  // Step
			for (x = -1; x < 1; x += 0.05f) { // Phase
				float sums[5] = { 0 };
				float o;
				for (o = -5; o <= 5; o += y) {
					sums[0] += y * stbir__filter_mitchell(x + o, 1);
					sums[1] += y * stbir__filter_catmullrom(x + o, 1);
					sums[2] += y * stbir__filter_cubic(x + o, 1);
					sums[4] += y * stbir__filter_trapezoid(x + o, 0.5f);
					sums[3] += y * stbir__filter_triangle(x + o, 1);
				}
				for (i = 0; i < 3; ++i)
					STBIR_ASSERT(sums[i] >= 1.0 - 0.0170 && sums[i] <= 1.0 + 0.0170);
			}
		}
#endif
	}
#endif

#if 0 // linear_to_srgb_uchar table
	for (i=0; i < 256; ++i) {
		float f = stbir__srgb_to_linear((i-0.5f)/255.0f);
		printf("%9d, ", (int) ((f) * (1<<28)));
		if ((i & 7) == 7)
			printf("\n");
	}
#endif

	// old tests that hacky fix worked on - test that
	// every uint8 maps to itself
	for (i = 0; i < 256; i++) {
		float f = stbir__srgb_to_linear(float(i) / 255);
		int n = stbir__linear_to_srgb_uchar(f);
		STBIR_ASSERT(n == i);
	}

	// new tests that hacky fix failed for - test that
	// values adjacent to uint8 round to nearest uint8
	for (i = 0; i < 256; i++) {
		for (float y = -0.42f; y <= 0.42f; y += 0.01f) {
			float f = stbir__srgb_to_linear((i+y) / 255.0f);
			int n = stbir__linear_to_srgb_uchar(f);
			STBIR_ASSERT(n == i);
		}
	}

	test_filters();

	test_subpixel_1();
	test_subpixel_2();
	test_subpixel_3();
	test_subpixel_4();

	test_premul();

	test_32();

	// Some tests to make sure errors don't pop up with strange filter/dimension combinations.
	stbir_resize(image88, 8, 8, 0, output88, 4, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context);
	stbir_resize(image88, 8, 8, 0, output88, 4, 16, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_BOX, STBIR_COLORSPACE_SRGB, &g_context);
	stbir_resize(image88, 8, 8, 0, output88, 16, 4, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_BOX, STBIR_FILTER_CATMULLROM, STBIR_COLORSPACE_SRGB, &g_context);
	stbir_resize(image88, 8, 8, 0, output88, 16, 4, 0, STBIR_TYPE_UINT8, 1, STBIR_ALPHA_CHANNEL_NONE, 0, STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_FILTER_CATMULLROM, STBIR_FILTER_BOX, STBIR_COLORSPACE_SRGB, &g_context);

	int barbara_width, barbara_height, barbara_channels;
	stbi_image_free(stbi_load(barbara, &barbara_width, &barbara_height, &barbara_channels, 0));

	int res = 10;
	// Downscaling
	{for (int i = 0; i <= res; i++)
	{
		float t = (float)i/res;
		float scale = 0.5;
		float out_scale = 2.0f/3;
		float x_shift = (barbara_width*out_scale - barbara_width*scale) * t;
		float y_shift = (barbara_height*out_scale - barbara_height*scale) * t;

		test_subpixel_command(barbara, scale, scale, out_scale, out_scale, x_shift, y_shift);
	}}

	// Upscaling
	{for (int i = 0; i <= res; i++)
	{
		float t = (float)i/res;
		float scale = 2;
		float out_scale = 3;
		float x_shift = (barbara_width*out_scale - barbara_width*scale) * t;
		float y_shift = (barbara_height*out_scale - barbara_height*scale) * t;

		test_subpixel_command(barbara, scale, scale, out_scale, out_scale, x_shift, y_shift);
	}}

	// Downscaling
	{for (int i = 0; i <= res; i++)
	{
		float t = (float)i/res / 2;
		test_subpixel_region(barbara, 0.25f, 0.25f, t, t, t+0.5f, t+0.5f);
	}}

	// No scaling
	{for (int i = 0; i <= res; i++)
	{
		float t = (float)i/res / 2;
		test_subpixel_region(barbara, 0.5f, 0.5f, t, t, t+0.5f, t+0.5f);
	}}

	// Upscaling
	{for (int i = 0; i <= res; i++)
	{
		float t = (float)i/res / 2;
		test_subpixel_region(barbara, 1, 1, t, t, t+0.5f, t+0.5f);
	}}

	{for (i = 0; i < 10; i++)
		test_subpixel(barbara, 0.5f, 0.5f, (float)i / 10, 1);
   }

	{for (i = 0; i < 10; i++)
		test_subpixel(barbara, 0.5f, 0.5f, 1, (float)i / 10);
   }

	{for (i = 0; i < 10; i++)
		test_subpixel(barbara, 2, 2, (float)i / 10, 1);
   }

	{for (i = 0; i < 10; i++)
		test_subpixel(barbara, 2, 2, 1, (float)i / 10);
   }

	// Channels test
	test_channels(barbara, 0.5f, 0.5f, 1);
	test_channels(barbara, 0.5f, 0.5f, 2);
	test_channels(barbara, 0.5f, 0.5f, 3);
	test_channels(barbara, 0.5f, 0.5f, 4);

	test_channels(barbara, 2, 2, 1);
	test_channels(barbara, 2, 2, 2);
	test_channels(barbara, 2, 2, 3);
	test_channels(barbara, 2, 2, 4);

	// filter tests
	resize_image(barbara, 2, 2, STBIR_FILTER_BOX         , STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-upsample-nearest.png");
	resize_image(barbara, 2, 2, STBIR_FILTER_TRIANGLE    , STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-upsample-bilinear.png");
	resize_image(barbara, 2, 2, STBIR_FILTER_CUBICBSPLINE, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-upsample-bicubic.png");
	resize_image(barbara, 2, 2, STBIR_FILTER_CATMULLROM  , STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-upsample-catmullrom.png");
	resize_image(barbara, 2, 2, STBIR_FILTER_MITCHELL    , STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-upsample-mitchell.png");

	resize_image(barbara, 0.5f, 0.5f, STBIR_FILTER_BOX         , STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-downsample-nearest.png");
	resize_image(barbara, 0.5f, 0.5f, STBIR_FILTER_TRIANGLE    , STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-downsample-bilinear.png");
	resize_image(barbara, 0.5f, 0.5f, STBIR_FILTER_CUBICBSPLINE, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-downsample-bicubic.png");
	resize_image(barbara, 0.5f, 0.5f, STBIR_FILTER_CATMULLROM  , STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-downsample-catmullrom.png");
	resize_image(barbara, 0.5f, 0.5f, STBIR_FILTER_MITCHELL    , STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, "test-output/barbara-downsample-mitchell.png");

	{for (i = 10; i < 100; i++)
	{
		char outname[200];
		sprintf(outname, "test-output/barbara-width-%d.jpg", i);
		resize_image(barbara, (float)i / 100, 1, STBIR_FILTER_CATMULLROM, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, outname);
	}}

	{for (i = 110; i < 500; i += 10)
	{
		char outname[200];
		sprintf(outname, "test-output/barbara-width-%d.jpg", i);
		resize_image(barbara, (float)i / 100, 1, STBIR_FILTER_CATMULLROM, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, outname);
	}}

	{for (i = 10; i < 100; i++)
	{
		char outname[200];
		sprintf(outname, "test-output/barbara-height-%d.jpg", i);
		resize_image(barbara, 1, (float)i / 100, STBIR_FILTER_CATMULLROM, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, outname);
	}}

	{for (i = 110; i < 500; i += 10)
	{
		char outname[200];
		sprintf(outname, "test-output/barbara-height-%d.jpg", i);
		resize_image(barbara, 1, (float)i / 100, STBIR_FILTER_CATMULLROM, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, outname);
	}}

	{for (i = 50; i < 200; i += 10)
	{
		char outname[200];
		sprintf(outname, "test-output/barbara-width-height-%d.jpg", i);
		resize_image(barbara, 100 / (float)i, (float)i / 100, STBIR_FILTER_CATMULLROM, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB, outname);
	}}

	test_format<unsigned short>(barbara, 0.5, 2.0, STBIR_TYPE_UINT16, STBIR_COLORSPACE_SRGB);
	test_format<unsigned short>(barbara, 0.5, 2.0, STBIR_TYPE_UINT16, STBIR_COLORSPACE_LINEAR);
	test_format<unsigned short>(barbara, 2.0, 0.5, STBIR_TYPE_UINT16, STBIR_COLORSPACE_SRGB);
	test_format<unsigned short>(barbara, 2.0, 0.5, STBIR_TYPE_UINT16, STBIR_COLORSPACE_LINEAR);

	test_format<unsigned int>(barbara, 0.5, 2.0, STBIR_TYPE_UINT32, STBIR_COLORSPACE_SRGB);
	test_format<unsigned int>(barbara, 0.5, 2.0, STBIR_TYPE_UINT32, STBIR_COLORSPACE_LINEAR);
	test_format<unsigned int>(barbara, 2.0, 0.5, STBIR_TYPE_UINT32, STBIR_COLORSPACE_SRGB);
	test_format<unsigned int>(barbara, 2.0, 0.5, STBIR_TYPE_UINT32, STBIR_COLORSPACE_LINEAR);

	test_float(barbara, 0.5, 2.0, STBIR_TYPE_FLOAT, STBIR_COLORSPACE_SRGB);
	test_float(barbara, 0.5, 2.0, STBIR_TYPE_FLOAT, STBIR_COLORSPACE_LINEAR);
	test_float(barbara, 2.0, 0.5, STBIR_TYPE_FLOAT, STBIR_COLORSPACE_SRGB);
	test_float(barbara, 2.0, 0.5, STBIR_TYPE_FLOAT, STBIR_COLORSPACE_LINEAR);

	// Edge behavior tests
	resize_image("hgradient.png", 2, 2, STBIR_FILTER_CATMULLROM, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_LINEAR, "test-output/hgradient-clamp.png");
	resize_image("hgradient.png", 2, 2, STBIR_FILTER_CATMULLROM, STBIR_EDGE_WRAP, STBIR_COLORSPACE_LINEAR, "test-output/hgradient-wrap.png");

	resize_image("vgradient.png", 2, 2, STBIR_FILTER_CATMULLROM, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_LINEAR, "test-output/vgradient-clamp.png");
	resize_image("vgradient.png", 2, 2, STBIR_FILTER_CATMULLROM, STBIR_EDGE_WRAP, STBIR_COLORSPACE_LINEAR, "test-output/vgradient-wrap.png");

	resize_image("1px-border.png", 2, 2, STBIR_FILTER_CATMULLROM, STBIR_EDGE_REFLECT, STBIR_COLORSPACE_LINEAR, "test-output/1px-border-reflect.png");
	resize_image("1px-border.png", 2, 2, STBIR_FILTER_CATMULLROM, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_LINEAR, "test-output/1px-border-clamp.png");

	// sRGB tests
	resize_image("gamma_colors.jpg", .5f, .5f, STBIR_FILTER_CATMULLROM, STBIR_EDGE_REFLECT, STBIR_COLORSPACE_SRGB, "test-output/gamma_colors.jpg");
	resize_image("gamma_2.2.jpg", .5f, .5f, STBIR_FILTER_CATMULLROM, STBIR_EDGE_REFLECT, STBIR_COLORSPACE_SRGB, "test-output/gamma_2.2.jpg");
	resize_image("gamma_dalai_lama_gray.jpg", .5f, .5f, STBIR_FILTER_CATMULLROM, STBIR_EDGE_REFLECT, STBIR_COLORSPACE_SRGB, "test-output/gamma_dalai_lama_gray.jpg");
}

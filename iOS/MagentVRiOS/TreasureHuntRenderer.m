#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support. Compile with -fobjc-arc"
#endif

#define NUM_CUBE_VERTICES 108
#define NUM_CUBE_COLORS 144
#define NUM_GRID_VERTICES 72
#define NUM_GRID_COLORS 96

#import "TreasureHuntRenderer.h"

#import <AudioToolbox/AudioToolbox.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

#import "GVRAudioEngine.h"

// Vertex shader implementation.
static const char *kVertexShaderString =
    "#version 100\n"
    "\n"
    "uniform mat4 uMVP; \n"
    "uniform vec3 uPosition; \n"
    "attribute vec3 aVertex; \n"
    "attribute vec4 aColor;\n"
    "varying vec4 vColor;\n"
    "varying vec3 vGrid;  \n"
    "void main(void) { \n"
    "  vGrid = aVertex + uPosition; \n"
    "  vec4 pos = vec4(vGrid, 1.0); \n"
    "  vColor = aColor;"
    "  gl_Position = uMVP * pos; \n"
    "    \n"
    "}\n";

// Simple pass-through fragment shader.
static const char *kPassThroughFragmentShaderString =
    "#version 100\n"
    "\n"
    "#ifdef GL_ES\n"
    "precision mediump float;\n"
    "#endif\n"
    "varying vec4 vColor;\n"
    "\n"
    "void main(void) { \n"
    "  gl_FragColor = vColor; \n"
    "}\n";

// Fragment shader for the floorplan grid.
// Line patters are generated based on the fragment's position in 3d.
static const char* kGridFragmentShaderString =
    "#version 100\n"
    "\n"
    "#ifdef GL_ES\n"
    "precision mediump float;\n"
    "#endif\n"
    "varying vec4 vColor;\n"
    "varying vec3 vGrid;\n"
    "\n"
    "void main() {\n"
    "    float depth = gl_FragCoord.z / gl_FragCoord.w;\n"
    "    if ((mod(abs(vGrid.x), 10.0) < 0.1) ||\n"
    "        (mod(abs(vGrid.z), 10.0) < 0.1)) {\n"
    "      gl_FragColor = max(0.0, (90.0-depth) / 90.0) *\n"
    "                     vec4(1.0, 1.0, 1.0, 1.0) + \n"
    "                     min(1.0, depth / 90.0) * vColor;\n"
    "    } else {\n"
    "      gl_FragColor = vColor;\n"
    "    }\n"
    "}\n";

// Vertices for uniform cube mesh centered at the origin.
static const float kCubeVertices[NUM_CUBE_VERTICES] = {
  // Front face
  -0.5f, 0.5f, 0.5f,
  -0.5f, -0.5f, 0.5f,
  0.5f, 0.5f, 0.5f,
  -0.5f, -0.5f, 0.5f,
  0.5f, -0.5f, 0.5f,
  0.5f, 0.5f, 0.5f,
  // Right face
  0.5f, 0.5f, 0.5f,
  0.5f, -0.5f, 0.5f,
  0.5f, 0.5f, -0.5f,
  0.5f, -0.5f, 0.5f,
  0.5f, -0.5f, -0.5f,
  0.5f, 0.5f, -0.5f,
  // Back face
  0.5f, 0.5f, -0.5f,
  0.5f, -0.5f, -0.5f,
  -0.5f, 0.5f, -0.5f,
  0.5f, -0.5f, -0.5f,
  -0.5f, -0.5f, -0.5f,
  -0.5f, 0.5f, -0.5f,
  // Left face
  -0.5f, 0.5f, -0.5f,
  -0.5f, -0.5f, -0.5f,
  -0.5f, 0.5f, 0.5f,
  -0.5f, -0.5f, -0.5f,
  -0.5f, -0.5f, 0.5f,
  -0.5f, 0.5f, 0.5f,
  // Top face
  -0.5f, 0.5f, -0.5f,
  -0.5f, 0.5f, 0.5f,
  0.5f, 0.5f, -0.5f,
  -0.5f, 0.5f, 0.5f,
  0.5f, 0.5f, 0.5f,
  0.5f, 0.5f, -0.5f,
  // Bottom face
  0.5f, -0.5f, -0.5f,
  0.5f, -0.5f, 0.5f,
  -0.5f, -0.5f, -0.5f,
  0.5f, -0.5f, 0.5f,
  -0.5f, -0.5f, 0.5f,
  -0.5f, -0.5f, -0.5f,
};

// Color of the cube's six faces.
static const float kCubeColors[NUM_CUBE_COLORS] = {
  // front, green
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,

  // right, blue
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,

    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,

    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,

    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,

    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
};

static const float kWall[NUM_CUBE_COLORS] = {
    // front, green
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,

    // front, green
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,

    // front, green
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,

    // front, green
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,

    // front, green
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,

    // front, green
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
    0.0f, 0.2356f, 0.2656f, 1.0f,
};

static const float kObserverColor[NUM_CUBE_COLORS] = {
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,

    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,

    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,

    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,

    // top, red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,

    // bottom, also red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
};

// Cube observer Yellow.
static const float kAttackerColors[NUM_CUBE_COLORS] = {
  // front, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // right, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // back, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // left, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // top, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // bottom, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
};

// The grid lines on the floor are rendered procedurally and large polygons cause floating point
// precision problems on some architectures. So we split the floor into 4 quadrants.
static const float kGridVertices[NUM_GRID_VERTICES] = {
  // +X, +Z quadrant
  200.0f, 0.0f, 0.0f,
  0.0f, 0.0f, 0.0f,
  0.0f, 0.0f, 200.0f,
  200.0f, 0.0f, 0.0f,
  0.0f, 0.0f, 200.0f,
  200.0f, 0.0f, 200.0f,

  // -X, +Z quadrant
  0.0f, 0.0f, 0.0f,
  -200.0f, 0.0f, 0.0f,
  -200.0f, 0.0f, 200.0f,
  0.0f, 0.0f, 0.0f,
  -200.0f, 0.0f, 200.0f,
  0.0f, 0.0f, 200.0f,

  // +X, -Z quadrant
  200.0f, 0.0f, -200.0f,
  0.0f, 0.0f, -200.0f,
  0.0f, 0.0f, 0.0f,
  200.0f, 0.0f, -200.0f,
  0.0f, 0.0f, 0.0f,
  200.0f, 0.0f, 0.0f,

  // -X, -Z quadrant
  0.0f, 0.0f, -200.0f,
  -200.0f, 0.0f, -200.0f,
  -200.0f, 0.0f, 0.0f,
  0.0f, 0.0f, -200.0f,
  -200.0f, 0.0f, 0.0f,
  0.0f, 0.0f, 0.0f,
};

static const float kGridColors[NUM_GRID_COLORS] = {
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
};

// Cube size (scale).
static const float kCubeSize = 0.5f;

// Grid size (scale).
static const float kGridSize = 1.0f;

// Cube focus angle threshold in radians.

static GLuint LoadShader(GLenum type, const char *shader_src) {
  GLint compiled = 0;

  // Create the shader object
  const GLuint shader = glCreateShader(type);
  if (shader == 0) {
    return 0;
  }
  // Load the shader source
  glShaderSource(shader, 1, &shader_src, NULL);

  // Compile the shader
  glCompileShader(shader);
  // Check the compile status
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

  if (!compiled) {
    GLint info_len = 0;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &info_len);

    if (info_len > 1) {
      char *info_log = ((char *)malloc(sizeof(char) * info_len));
      glGetShaderInfoLog(shader, info_len, NULL, info_log);
      NSLog(@"Error compiling shader:%s", info_log);
      free(info_log);
    }
    glDeleteShader(shader);
    return 0;
  }
  return shader;
}

// Checks the link status of the given program.
static bool checkProgramLinkStatus(GLuint shader_program) {
  GLint linked = 0;
  glGetProgramiv(shader_program, GL_LINK_STATUS, &linked);

  if (!linked) {
    GLint info_len = 0;
    glGetProgramiv(shader_program, GL_INFO_LOG_LENGTH, &info_len);

    if (info_len > 1) {
      char *info_log = ((char *)malloc(sizeof(char) * info_len));
      glGetProgramInfoLog(shader_program, info_len, NULL, info_log);
      NSLog(@"Error linking program: %s", info_log);
      free(info_log);
    }
    glDeleteProgram(shader_program);
    return false;
  }
  return true;
}

static void CheckGLError(const char *label) {
  int gl_error = glGetError();
  if (gl_error != GL_NO_ERROR) {
    NSLog(@"GL error %s: %d", label, gl_error);
  }
  assert(glGetError() == GL_NO_ERROR);
}

@implementation TreasureHuntRenderer {
  // GL variables for the cube.
  GLfloat _cube_vertices[NUM_CUBE_VERTICES];
  GLfloat _cube_position[3];
  GLfloat _cube_colors[NUM_CUBE_COLORS];
  GLfloat _cube_observer_colors[NUM_CUBE_COLORS];
  GLfloat _cube_attacker_colors[NUM_CUBE_COLORS];
  GLfloat _cube_wall_colors[NUM_CUBE_COLORS];

  GLuint _cube_program;
  GLint _cube_vertex_attrib;
  GLint _cube_position_uniform;
  GLint _cube_mvp_matrix;
  GLuint _cube_vertex_buffer;
  GLint _cube_color_attrib;
  GLuint _cube_color_buffer;
  GLuint _cube_observer_color_buffer;
  GLuint _cube_attacker_color_buffer;
  GLuint _cube_wall_color_buffer;

  // GL variables for the grid.
  GLfloat _grid_vertices[NUM_GRID_VERTICES];
  GLfloat _grid_colors[NUM_GRID_COLORS];
  GLfloat _grid_position[3];

  GLuint _grid_program;
  GLint _grid_vertex_attrib;
  GLint _grid_color_attrib;
  GLint _grid_position_uniform;
  GLint _grid_mvp_matrix;
  GLuint _grid_vertex_buffer;
  GLuint _grid_color_buffer;

  GVRAudioEngine *_gvr_audio_engine;
  int _sound_object_id;
  int _success_source_id;
  bool _is_cube_focused;
}

- (void)dealloc {
}
#define attacker_max 433813
#define cube_number 1196
#define veiw_height -5
#define frame_num 551
#define agent_view_num 512
#define refresh_rate 0.05
int attacker_number = 0;


int cube_program_list[cube_number];
bool is_attacker[cube_number];
bool is_alive[cube_number];
bool is_wall[cube_number];
float cube_postion_list_x[cube_number];
float cube_postion_list_y[cube_number];
float cube_postion_list_z[cube_number];
int action_attacker_list[attacker_max];
bool is_attack_action[attacker_max];
int action_vic_list_x[attacker_max];
int action_vic_list_y[attacker_max];
int action_vic_list_z[attacker_max];
int frame_index[frame_num];
NSString *path;
NSString *content;
NSArray *lines;

// data input here
- (void)input {
    path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"txt"];
    content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    lines = [content componentsSeparatedByString:@"\n"];
    int index = 0;
    int cube_count = 0;
    for (int i = 0; i < attacker_max; i++)
        is_attack_action[i] = false;
    for (int i = 0; i < cube_number; i++)
        is_alive[i] = true;
    for (int i = 0 ; i < [lines count]; i++) {
        NSString *line = lines[i];
        NSArray *element = [line componentsSeparatedByString:@" "];
        if (index == 1 && [element count] == 6) {
            int id = [element[0] intValue];
            is_attacker[id] = (id < 400);
            cube_postion_list_z[id] = [element[4] floatValue];
            cube_postion_list_x[id] = [element[3] floatValue];
            is_wall[id] = false;
            cube_count++;
        }

        if (index > 1 && [element count] == 6) {
            int id = [element[0] intValue];
            action_attacker_list[attacker_number] = id;
            action_vic_list_x[attacker_number] = [element[3] intValue];
            action_vic_list_z[attacker_number] = [element[4] intValue];
            attacker_number++;
        }

        if ([element[0] isEqualToString:@"F"] && [element count] == 4) {
            index++;
            frame_index[index] = attacker_number;
        }
    
        
        if ([element[0] isEqualToString:@"0"] && [element count] == 4) {
            int id = [element[1] intValue];
            for (int i = frame_index[index]; i < attacker_number; i++) {
                if (action_attacker_list[i] == id) {
                    action_vic_list_x[i] = [element[2] intValue];
                    action_vic_list_z[i] = [element[3] intValue];
                    is_attack_action[i] = true;
                    break;
                }
            }
        }
        if ([element count] == 2) {
            cube_postion_list_x[cube_count] = [element[0] floatValue];
            cube_postion_list_z[cube_count] = [element[1] floatValue];
            is_attacker[cube_count] = false;
            is_wall[cube_count] = true;
            cube_count++;
        }
    }
    NSLog(@"a n: %i", attacker_number);
    NSLog(@"cube: %i", cube_count);
    NSLog(@"f n: %i frame", index);

}


- (void)initializeGl {
  [super initializeGl];
    attacker_number = 0;
    frame_interval_index = 0;
    current_frame = 0;

  // Renderer must be created on GL thread before any call to drawFrame.
  // Load the vertex/fragment shaders.
  const GLuint vertex_shader = LoadShader(GL_VERTEX_SHADER, kVertexShaderString);
  NSAssert(vertex_shader != 0, @"Failed to load vertex shader");
  const GLuint fragment_shader = LoadShader(GL_FRAGMENT_SHADER, kPassThroughFragmentShaderString);
  NSAssert(fragment_shader != 0, @"Failed to load fragment shader");
  const GLuint grid_fragment_shader = LoadShader(GL_FRAGMENT_SHADER, kGridFragmentShaderString);
  NSAssert(grid_fragment_shader != 0, @"Failed to load grid fragment shader");

    //  Read input file
    [self input];
  /////// Create the program object for the cube.
    for (int i = 0; i < cube_number; i++) {
        cube_program_list[i] = glCreateProgram();
        NSAssert(cube_program_list[i] != 0, @"Failed to create program");
        glAttachShader(cube_program_list[i], vertex_shader);
        glAttachShader(cube_program_list[i], fragment_shader);

        // Link the shader program.
        glLinkProgram(cube_program_list[i]);
        NSAssert(checkProgramLinkStatus(cube_program_list[i]), @"Failed to link _cube_program");

        // Get the location of our attributes so we can bind data to them later.
        _cube_vertex_attrib = glGetAttribLocation(cube_program_list[i], "aVertex");
        NSAssert(_cube_vertex_attrib != -1, @"glGetAttribLocation failed for aVertex");
        _cube_color_attrib = glGetAttribLocation(cube_program_list[i], "aColor");
        NSAssert(_cube_color_attrib != -1, @"glGetAttribLocation failed for aColor");

        // After linking, fetch references to the uniforms in our shader.
        _cube_mvp_matrix = glGetUniformLocation(cube_program_list[i], "uMVP");
        _cube_position_uniform = glGetUniformLocation(cube_program_list[i], "uPosition");
        NSAssert(_cube_mvp_matrix != -1 && _cube_position_uniform != -1,
               @"Error fetching uniform values for shader.");
        // Initialize the vertex data for the cube mesh.
        for (int i = 0; i < NUM_CUBE_VERTICES; ++i) {
            _cube_vertices[i] = (GLfloat)(kCubeVertices[i] * kCubeSize);
        }
        glGenBuffers(1, &_cube_vertex_buffer);
        NSAssert(_cube_vertex_buffer != 0, @"glGenBuffers failed for vertex buffer");
        glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_vertices), _cube_vertices, GL_STATIC_DRAW);
    }

    // Initialize the color data for the cube mesh.
    for (int i = 0; i < NUM_CUBE_COLORS; ++i) {
        _cube_colors[i] = (GLfloat)(kCubeColors[i] * kCubeSize);
    }
    glGenBuffers(1, &_cube_color_buffer);
    NSAssert(_cube_color_buffer != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_colors), _cube_colors, GL_STATIC_DRAW);

    // Initialize the color data for the cube mesh.
    for (int i = 0; i < NUM_CUBE_COLORS; ++i) {
        _cube_attacker_colors[i] = (GLfloat)(kAttackerColors[i] * kCubeSize);
    }
    glGenBuffers(1, &_cube_attacker_color_buffer);
    NSAssert(_cube_attacker_color_buffer != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_attacker_color_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_attacker_colors), _cube_attacker_colors, GL_STATIC_DRAW);

    // Initialize the found color data for the cube mesh.
    for (int i = 0; i < NUM_CUBE_COLORS; ++i) {
        _cube_observer_colors[i] = (GLfloat)(kObserverColor[i] * kCubeSize);
    }
    glGenBuffers(1, &_cube_observer_color_buffer);
    NSAssert(_cube_observer_color_buffer != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_observer_color_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_observer_colors), _cube_observer_colors, GL_STATIC_DRAW);

    // Initialize the found color data for the cube mesh.
    for (int i = 0; i < NUM_CUBE_COLORS; ++i) {
        _cube_wall_colors[i] = (GLfloat)(kWall[i] * kCubeSize);
    }
    glGenBuffers(1, &_cube_wall_color_buffer);
    NSAssert(_cube_wall_color_buffer != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_wall_color_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_wall_colors), _cube_wall_colors, GL_STATIC_DRAW);

  /////// Create the program object for the grid.

  _grid_program = glCreateProgram();
  NSAssert(_grid_program != 0, @"Failed to create program");
  glAttachShader(_grid_program, vertex_shader);
  glAttachShader(_grid_program, grid_fragment_shader);
  glLinkProgram(_grid_program);
  NSAssert(checkProgramLinkStatus(_grid_program), @"Failed to link _grid_program");

  // Get the location of our attributes so we can bind data to them later.
  _grid_vertex_attrib = glGetAttribLocation(_grid_program, "aVertex");
  NSAssert(_grid_vertex_attrib != -1, @"glGetAttribLocation failed for aVertex");
  _grid_color_attrib = glGetAttribLocation(_grid_program, "aColor");
  NSAssert(_grid_color_attrib != -1, @"glGetAttribLocation failed for aColor");

  // After linking, fetch references to the uniforms in our shader.
  _grid_mvp_matrix = glGetUniformLocation(_grid_program, "uMVP");
  _grid_position_uniform = glGetUniformLocation(_grid_program, "uPosition");
  NSAssert(_grid_mvp_matrix != -1 && _grid_position_uniform != -1,
           @"Error fetching uniform values for shader.");

  // Position grid below the camera.
  _grid_position[0] = 0;
  _grid_position[1] = -20.0f;
  _grid_position[2] = 0;

  for (int i = 0; i < NUM_GRID_VERTICES; ++i) {
    _grid_vertices[i] = (GLfloat)(kGridVertices[i] * kCubeSize);
  }
  glGenBuffers(1, &_grid_vertex_buffer);
  NSAssert(_grid_vertex_buffer != 0, @"glGenBuffers failed for vertex buffer");
  glBindBuffer(GL_ARRAY_BUFFER, _grid_vertex_buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(_grid_vertices), _grid_vertices, GL_STATIC_DRAW);

  // Initialize the color data for the grid mesh.
  for (int i = 0; i < NUM_GRID_COLORS; ++i) {
    _grid_colors[i] = (GLfloat)(kGridColors[i] * kGridSize);
  }
  glGenBuffers(1, &_grid_color_buffer);
  NSAssert(_grid_color_buffer != 0, @"glGenBuffers failed for color buffer");
  glBindBuffer(GL_ARRAY_BUFFER, _grid_color_buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(_grid_colors), _grid_colors, GL_STATIC_DRAW);

  // Initialize GVRCardboardAudio engine.

  // Generate seed for random number generation.
  srand48(time(0));
    for (int i = 0; i < cube_number; i++) {
        cube_postion_list_y[i] = veiw_height;
    }
  CheckGLError("init");
    [NSTimer scheduledTimerWithTimeInterval:refresh_rate target:self selector:@selector(run_case:) userInfo:nil repeats:YES];
}

- (void)clearGl {
  [super clearGl];
}

// head posture? anyway it is update of the location of the cube
- (void)update:(GVRHeadPose *)headPose {

  // Check if the cube is focused.
//  GLKVector3 source_cube_position =
//      GLKVector3Make(_cube_position[0], _cube_position[1], _cube_position[2]);
//  _is_cube_focused = [self isLookingAtObject:&head_rotation sourcePosition:&source_cube_position];

  // Clear GL viewport.
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_SCISSOR_TEST);
  CheckGLError("update");
}


- (void)draw:(GVRHeadPose *)headPose {
  CGRect viewport = [headPose viewport];
  glViewport(viewport.origin.x, viewport.origin.y, viewport.size.width, viewport.size.height);
  glScissor(viewport.origin.x, viewport.origin.y, viewport.size.width, viewport.size.height);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  CheckGLError("glClear");

  // Get the head matrix.
  const GLKMatrix4 head_from_start_matrix = [headPose headTransform];

  // Get this eye's matrices.
  GLKMatrix4 projection_matrix = [headPose projectionMatrixWithNear:0.1f far:100.0f];
  GLKMatrix4 eye_from_head_matrix = [headPose eyeTransform];

  // Compute the model view projection matrix.
  GLKMatrix4 model_view_projection_matrix = GLKMatrix4Multiply(
      projection_matrix, GLKMatrix4Multiply(eye_from_head_matrix, head_from_start_matrix));

  // Render from this eye.
  [self renderWithModelViewProjectionMatrix:model_view_projection_matrix.m];
  CheckGLError("render");
}

float current_position[3] = {0.0f, 0.0f, 0.0f};

// Color ?
- (void)renderWithModelViewProjectionMatrix:(const float *)model_view_matrix {
  // Select our shader.
    for (int i = 0; i < cube_number; i++) {
        glUseProgram(cube_program_list[i]);
        CheckGLError("glUseProgram");

        // Set the uniform values that will be used by our shader.
        float position_vec[3] = {cube_postion_list_x[i] - cube_postion_list_x[agent_view_num], cube_postion_list_y[i], cube_postion_list_z[i] - cube_postion_list_z[agent_view_num]};
        if (agent_view_num == -1) {
            position_vec[0] = cube_postion_list_x[i] - current_position[0];
            position_vec[1] = cube_postion_list_y[i] - current_position[1];
            position_vec[2] = cube_postion_list_z[i] - current_position[2];
        }
        glUniform3fv(_cube_position_uniform, 1, position_vec);
        // Set the uniform matrix values that will be used by our shader.
        glUniformMatrix4fv(_cube_mvp_matrix, 1, false, model_view_matrix);

        if (i == agent_view_num)
            glBindBuffer(GL_ARRAY_BUFFER, _cube_observer_color_buffer);
        else if (is_attacker[i])
            glBindBuffer(GL_ARRAY_BUFFER, _cube_attacker_color_buffer);
        else if (is_wall[i])
            glBindBuffer(GL_ARRAY_BUFFER, _cube_wall_color_buffer);
        else
            glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer);

        CheckGLError("glBindBuffer");
        glVertexAttribPointer(_cube_color_attrib, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
        glEnableVertexAttribArray(_cube_color_attrib);

        // Draw our polygons.
        glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer);
        glVertexAttribPointer(_cube_vertex_attrib, 3, GL_FLOAT, GL_FALSE,
                              sizeof(float) * 3, 0);
        glEnableVertexAttribArray(_cube_vertex_attrib);
        glDrawArrays(GL_TRIANGLES, 0, NUM_CUBE_VERTICES / 3);
        glDisableVertexAttribArray(_cube_vertex_attrib);
        glDisableVertexAttribArray(_cube_color_attrib);
        CheckGLError("glDrawArrays");
    }


  // Select our shader.
  glUseProgram(_grid_program);

  // Set the uniform values that will be used by our shader.
  glUniform3fv(_grid_position_uniform, 1, _grid_position);

  // Set the uniform matrix values that will be used by our shader.
  glUniformMatrix4fv(_grid_mvp_matrix, 1, false, model_view_matrix);

  // Set the grid colors.
  glBindBuffer(GL_ARRAY_BUFFER, _grid_color_buffer);
  glVertexAttribPointer(_grid_color_attrib, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
  glEnableVertexAttribArray(_grid_color_attrib);

  // Draw our polygons.
  glBindBuffer(GL_ARRAY_BUFFER, _grid_vertex_buffer);
  glVertexAttribPointer(_grid_vertex_attrib, 3, GL_FLOAT, GL_FALSE,
                        sizeof(float) * 3, 0);
  glEnableVertexAttribArray(_grid_vertex_attrib);
  glDrawArrays(GL_TRIANGLES, 0, NUM_GRID_VERTICES / 3);
  glDisableVertexAttribArray(_grid_vertex_attrib);
  glDisableVertexAttribArray(_grid_color_attrib);
}

- (void)pause:(BOOL)pause {
  [super pause:pause];
}
bool moved = true;
int count = 0;
int max_movement = 20;
- (void)handleTrigger {
    moved = false;
    count = 0;
    NSLog(@"Touched");
}

#define interval 5
int frame_interval_index = 0;
int current_frame = 0;
- (void) run_case: (NSTimer *)timer{
    NSLog(@"This is the %i frame", current_frame);
    if (current_frame < frame_num) {
        if (frame_interval_index < interval) {
            for(int current_action = frame_index[current_frame]; current_action < frame_index[current_frame + 1]; current_action++) {
                int id = action_attacker_list[current_action];
                if (id > cube_number || !is_alive[id]) continue;
                int x = action_vic_list_x[current_action];
                int z = action_vic_list_z[current_action];
                float dx = x - cube_postion_list_x[id];
                float dz = z - cube_postion_list_z[id];
                cube_postion_list_x[id] += dx / interval;
                cube_postion_list_z[id] += dz / interval;
            }
            frame_interval_index++;
            if (!moved && count < max_movement) {
                current_position[0] += 0.5;
                current_position[2] += 0.5;
                count++;
            }
        } else {
//            [timer invalidate];
            frame_interval_index = 0;
            for (int current_action = frame_index[current_frame]; current_action < frame_index[current_frame + 1]; current_action++) {
                int x = action_vic_list_x[current_action];
                int z = action_vic_list_z[current_action];
                int id = action_attacker_list[current_action];
                if (id > cube_number || !is_alive[id]) continue;
                cube_postion_list_x[id] = action_vic_list_x[current_action];
                cube_postion_list_z[id] = action_vic_list_z[current_action];
                if (id == agent_view_num) {
                    NSLog(@"current viewer location: %f %f", cube_postion_list_x[id], cube_postion_list_z[id]);
                }
                if (is_attack_action[current_action]) {
                    for (int j = 0; j < cube_number; j++) {
                        if ((int)cube_postion_list_x[j] == x && (int) cube_postion_list_z[j] == z
                            && ((is_attacker[j] && !is_attacker[id]) || (!is_attacker[j] && is_attacker[id]))) {
                            if (j == agent_view_num) {
                                NSLog(@"You died");
                                [timer invalidate];
                                break;
                            }
                            is_alive[j] = false;
                            if (is_attacker[j]) {
                                NSLog(@"friend died");
                            } else {
                                NSLog(@"enemy died");
                            }

                            cube_postion_list_x[j] = 1000;
                            cube_postion_list_z[j] = 1000;
                            break;
                        }
                    }
                }
            }
            current_frame++;
        }
    } else {
        NSLog(@"Finished");
        [timer invalidate];
        [super clearGl];
        // end of the demo
    }
}


@end



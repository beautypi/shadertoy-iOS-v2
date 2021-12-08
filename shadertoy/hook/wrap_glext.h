#ifndef __wrap_gl_es30ext_h_
#define __wrap_gl_es30ext_h_

#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/OpenGLESAvailability.h>

#ifdef __cplusplus
extern "C" {
#endif

void hookES30GLExt(void);

/*------------------------------------------------------------------------*
 * APPLE extension functions
 *------------------------------------------------------------------------*/
#if GL_APPLE_copy_texture_levels
GLvoid wrap_glCopyTextureLevelsAPPLE(GLuint destinationTexture, GLuint sourceTexture, GLint sourceBaseLevel, GLsizei sourceLevelCount);

#endif

/*------------------------------------------------------------------------*
 * EXT extension functions
 *------------------------------------------------------------------------*/
#if GL_EXT_debug_label
GLvoid wrap_glLabelObjectEXT(GLenum type, GLuint object, GLsizei length, const GLchar *label);

GLvoid wrap_glGetObjectLabelEXT(GLenum type, GLuint object, GLsizei bufSize, GLsizei *length, GLchar *label);

#endif

#if GL_EXT_debug_marker
GLvoid wrap_glInsertEventMarkerEXT(GLsizei length, const GLchar *marker);

GLvoid wrap_glPushGroupMarkerEXT(GLsizei length, const GLchar *marker);

GLvoid wrap_glPopGroupMarkerEXT(void);

#endif

#if GL_EXT_separate_shader_objects
GLvoid wrap_glUseProgramStagesEXT(GLuint pipeline, GLbitfield stages, GLuint program);

GLvoid wrap_glActiveShaderProgramEXT(GLuint pipeline, GLuint program);

GLuint wrap_glCreateShaderProgramvEXT(GLenum type, GLsizei count, const GLchar* const *strings);

GLvoid wrap_glBindProgramPipelineEXT(GLuint pipeline);

GLvoid wrap_glDeleteProgramPipelinesEXT(GLsizei n, const GLuint *pipelines);

GLvoid wrap_glGenProgramPipelinesEXT(GLsizei n, GLuint *pipelines);

GLboolean wrap_glIsProgramPipelineEXT(GLuint pipeline);

GLvoid wrap_glProgramParameteriEXT(GLuint program, GLenum pname, GLint value);

GLvoid wrap_glGetProgramPipelineivEXT(GLuint pipeline, GLenum pname, GLint *params);

GLvoid wrap_glValidateProgramPipelineEXT(GLuint pipeline);

GLvoid wrap_glGetProgramPipelineInfoLogEXT(GLuint pipeline, GLsizei bufSize, GLsizei *length, GLchar *infoLog);


GLvoid wrap_glProgramUniform1iEXT(GLuint program, GLint location, GLint x);

GLvoid wrap_glProgramUniform2iEXT(GLuint program, GLint location, GLint x, GLint y);

GLvoid wrap_glProgramUniform3iEXT(GLuint program, GLint location, GLint x, GLint y, GLint z);

GLvoid wrap_glProgramUniform4iEXT(GLuint program, GLint location, GLint x, GLint y, GLint z, GLint w);


GLvoid wrap_glProgramUniform1fEXT(GLuint program, GLint location, GLfloat x);

GLvoid wrap_glProgramUniform2fEXT(GLuint program, GLint location, GLfloat x, GLfloat y);

GLvoid wrap_glProgramUniform3fEXT(GLuint program, GLint location, GLfloat x, GLfloat y, GLfloat z);

GLvoid wrap_glProgramUniform4fEXT(GLuint program, GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w);


GLvoid wrap_glProgramUniform1uiEXT(GLuint program, GLint location, GLuint x);

GLvoid wrap_glProgramUniform2uiEXT(GLuint program, GLint location, GLuint x, GLuint y);

GLvoid wrap_glProgramUniform3uiEXT(GLuint program, GLint location, GLuint x, GLuint y, GLuint z);

GLvoid wrap_glProgramUniform4uiEXT(GLuint program, GLint location, GLuint x, GLuint y, GLuint z, GLuint w);


GLvoid wrap_glProgramUniform1ivEXT(GLuint program, GLint location, GLsizei count, const GLint *value);

GLvoid wrap_glProgramUniform2ivEXT(GLuint program, GLint location, GLsizei count, const GLint *value);

GLvoid wrap_glProgramUniform3ivEXT(GLuint program, GLint location, GLsizei count, const GLint *value);

GLvoid wrap_glProgramUniform4ivEXT(GLuint program, GLint location, GLsizei count, const GLint *value);


GLvoid wrap_glProgramUniform1fvEXT(GLuint program, GLint location, GLsizei count, const GLfloat *value);

GLvoid wrap_glProgramUniform2fvEXT(GLuint program, GLint location, GLsizei count, const GLfloat *value);

GLvoid wrap_glProgramUniform3fvEXT(GLuint program, GLint location, GLsizei count, const GLfloat *value);

GLvoid wrap_glProgramUniform4fvEXT(GLuint program, GLint location, GLsizei count, const GLfloat *value);


GLvoid wrap_glProgramUniform1uivEXT(GLuint program, GLint location, GLsizei count, const GLuint *value);

GLvoid wrap_glProgramUniform2uivEXT(GLuint program, GLint location, GLsizei count, const GLuint *value);

GLvoid wrap_glProgramUniform3uivEXT(GLuint program, GLint location, GLsizei count, const GLuint *value);

GLvoid wrap_glProgramUniform4uivEXT(GLuint program, GLint location, GLsizei count, const GLuint *value);


GLvoid wrap_glProgramUniformMatrix2fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

GLvoid wrap_glProgramUniformMatrix3fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

GLvoid wrap_glProgramUniformMatrix4fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

GLvoid wrap_glProgramUniformMatrix2x3fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

GLvoid wrap_glProgramUniformMatrix3x2fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

GLvoid wrap_glProgramUniformMatrix2x4fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

GLvoid wrap_glProgramUniformMatrix4x2fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

GLvoid wrap_glProgramUniformMatrix3x4fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

GLvoid wrap_glProgramUniformMatrix4x3fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

#endif

#ifdef __cplusplus
}
#endif

#endif /* __wrap_gl_es30ext_h_ */

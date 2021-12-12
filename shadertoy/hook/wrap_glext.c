#include "wrap_glext.h"
#include <OpenGLES/ES3/glext.h>
#include <fishhook/fishhook.h>
#include <stdio.h>

static GLvoid (*orig_glCopyTextureLevelsAPPLE)(GLuint destinationTexture, GLuint sourceTexture, GLint sourceBaseLevel, GLsizei sourceLevelCount);
GLvoid wrap_glCopyTextureLevelsAPPLE(GLuint destinationTexture, GLuint sourceTexture, GLint sourceBaseLevel, GLsizei sourceLevelCount) {
    printf("/*#fishhook#**/ glCopyTextureLevelsAPPLE(%d, %d, %d, %d));\n", destinationTexture, sourceTexture, sourceBaseLevel, sourceLevelCount);
    orig_glCopyTextureLevelsAPPLE(destinationTexture, sourceTexture, sourceBaseLevel, sourceLevelCount);
}

static GLvoid (*orig_glLabelObjectEXT)(GLenum type, GLuint object, GLsizei length, const GLchar *label);
GLvoid wrap_glLabelObjectEXT(GLenum type, GLuint object, GLsizei length, const GLchar *label) {
    printf("/*#fishhook#**/ glLabelObjectEXT(0x%x, %d, %d, '%s'));\n", type, object, length, label);
    orig_glLabelObjectEXT(type, object, length, label);
}

static GLvoid (*orig_glGetObjectLabelEXT)(GLenum type, GLuint object, GLsizei bufSize, GLsizei *length, GLchar *label);
GLvoid wrap_glGetObjectLabelEXT(GLenum type, GLuint object, GLsizei bufSize, GLsizei *length, GLchar *label) {
    orig_glGetObjectLabelEXT(type, object, bufSize, length, label);
    printf("/*#fishhook#**/ {GLsizei length; glGetObjectLabelEXT(0x%x, %d, %d, &length, '%s');}", type, object, bufSize, label);
    
}

static GLvoid (*orig_glInsertEventMarkerEXT)(GLsizei length, const GLchar *marker);
GLvoid wrap_glInsertEventMarkerEXT(GLsizei length, const GLchar *marker) {
    printf("/*#fishhook#**/ glInsertEventMarkerEXT(%d, \"%s\"));\n", length, marker);
    orig_glInsertEventMarkerEXT(length, marker);
}

static GLvoid (*orig_glPushGroupMarkerEXT)(GLsizei length, const GLchar *marker);
GLvoid wrap_glPushGroupMarkerEXT(GLsizei length, const GLchar *marker) {
    printf("/*#fishhook#**/ glPushGroupMarkerEXT(%d, \"%s\"));\n", length, marker);
    orig_glPushGroupMarkerEXT(length, marker);
}

static GLvoid (*orig_glPopGroupMarkerEXT)(void);
GLvoid wrap_glPopGroupMarkerEXT(void) {
    printf("/*#fishhook#**/ glPopGroupMarkerEXT(");
    orig_glPopGroupMarkerEXT();
}

static GLvoid (*orig_glUseProgramStagesEXT)(GLuint pipeline, GLbitfield stages, GLuint program);
GLvoid wrap_glUseProgramStagesEXT(GLuint pipeline, GLbitfield stages, GLuint program) {
    printf("/*#fishhook#**/ glUseProgramStagesEXT(%d, %d, %d));\n", pipeline, stages, program);
    orig_glUseProgramStagesEXT(pipeline, stages, program);
}

static GLvoid (*orig_glActiveShaderProgramEXT)(GLuint pipeline, GLuint program);
GLvoid wrap_glActiveShaderProgramEXT(GLuint pipeline, GLuint program) {
    printf("/*#fishhook#**/ glActiveShaderProgramEXT(%d, %d));\n", pipeline, program);
    orig_glActiveShaderProgramEXT(pipeline, program);
}

static GLuint (*orig_glCreateShaderProgramvEXT)(GLenum type, GLsizei count, const GLchar* const *strings);
GLuint wrap_glCreateShaderProgramvEXT(GLenum type, GLsizei count, const GLchar* const *strings) {
    printf("/*#fishhook#**/ glCreateShaderProgramvEXT(0x%x, %d, [%d]));\n", type, count, ((int*)strings)[0]);
    return orig_glCreateShaderProgramvEXT(type, count, strings);
}

static GLvoid (*orig_glBindProgramPipelineEXT)(GLuint pipeline);
GLvoid wrap_glBindProgramPipelineEXT(GLuint pipeline) {
    printf("/*#fishhook#**/ glBindProgramPipelineEXT(%d));\n", pipeline);
    orig_glBindProgramPipelineEXT(pipeline);
}

static GLvoid (*orig_glDeleteProgramPipelinesEXT)(GLsizei n, const GLuint *pipelines);
GLvoid wrap_glDeleteProgramPipelinesEXT(GLsizei n, const GLuint *pipelines) {
    printf("/*#fishhook#**/ glDeleteProgramPipelinesEXT(%d, %d));\n", n, pipelines);
    orig_glDeleteProgramPipelinesEXT(n, pipelines);
}

static GLvoid (*orig_glGenProgramPipelinesEXT)(GLsizei n, GLuint *pipelines);
GLvoid wrap_glGenProgramPipelinesEXT(GLsizei n, GLuint *pipelines) {
    printf("/*#fishhook#**/ glGenProgramPipelinesEXT(%d, %d));\n", n, pipelines);
    orig_glGenProgramPipelinesEXT(n, pipelines);
}

static GLboolean (*orig_glIsProgramPipelineEXT)(GLuint pipeline);
GLboolean wrap_glIsProgramPipelineEXT(GLuint pipeline) {
    printf("/*#fishhook#**/ glIsProgramPipelineEXT(%d));\n", pipeline);
    return orig_glIsProgramPipelineEXT(pipeline);
}

static GLvoid (*orig_glProgramParameteriEXT)(GLuint program, GLenum pname, GLint value);
GLvoid wrap_glProgramParameteriEXT(GLuint program, GLenum pname, GLint value) {
    printf("/*#fishhook#**/ glProgramParameteriEXT(%d, 0x%x, %d));\n", program, pname, value);
    orig_glProgramParameteriEXT(program, pname, value);
}

static GLvoid (*orig_glGetProgramPipelineivEXT)(GLuint pipeline, GLenum pname, GLint *params);
GLvoid wrap_glGetProgramPipelineivEXT(GLuint pipeline, GLenum pname, GLint *params) {
    printf("/*#fishhook#**/ glGetProgramPipelineivEXT(%d, 0x%x, %d));\n", pipeline, pname, params);
    orig_glGetProgramPipelineivEXT(pipeline, pname, params);
}

static GLvoid (*orig_glValidateProgramPipelineEXT)(GLuint pipeline);
GLvoid wrap_glValidateProgramPipelineEXT(GLuint pipeline) {
    printf("/*#fishhook#**/ glValidateProgramPipelineEXT(%d));\n", pipeline);
    orig_glValidateProgramPipelineEXT(pipeline);
}

static GLvoid (*orig_glGetProgramPipelineInfoLogEXT)(GLuint pipeline, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
GLvoid wrap_glGetProgramPipelineInfoLogEXT(GLuint pipeline, GLsizei bufSize, GLsizei *length, GLchar *infoLog) {
    printf("/*#fishhook#**/ glGetProgramPipelineInfoLogEXT(%d, %d, %d, %d));\n", pipeline, bufSize, length, infoLog);
    orig_glGetProgramPipelineInfoLogEXT(pipeline, bufSize, length, infoLog);
}

static GLvoid (*orig_glProgramUniform1iEXT)(GLuint program, GLint location, GLint x);
GLvoid wrap_glProgramUniform1iEXT(GLuint program, GLint location, GLint x) {
    printf("/*#fishhook#**/ glProgramUniform1iEXT(%d, %d, %d));\n", program, location, x);
    orig_glProgramUniform1iEXT(program, location, x);
}

static GLvoid (*orig_glProgramUniform2iEXT)(GLuint program, GLint location, GLint x, GLint y);
GLvoid wrap_glProgramUniform2iEXT(GLuint program, GLint location, GLint x, GLint y) {
    printf("/*#fishhook#**/ glProgramUniform2iEXT(%d, %d, %d, %d));\n", program, location, x, y);
    orig_glProgramUniform2iEXT(program, location, x, y);
}

static GLvoid (*orig_glProgramUniform3iEXT)(GLuint program, GLint location, GLint x, GLint y, GLint z);
GLvoid wrap_glProgramUniform3iEXT(GLuint program, GLint location, GLint x, GLint y, GLint z) {
    printf("/*#fishhook#**/ glProgramUniform3iEXT(%d, %d, %d, %d, %d));\n", program, location, x, y, z);
    orig_glProgramUniform3iEXT(program, location, x, y, z);
}

static GLvoid (*orig_glProgramUniform4iEXT)(GLuint program, GLint location, GLint x, GLint y, GLint z, GLint w);
GLvoid wrap_glProgramUniform4iEXT(GLuint program, GLint location, GLint x, GLint y, GLint z, GLint w) {
    printf("/*#fishhook#**/ glProgramUniform4iEXT(%d, %d, %d, %d, %d, %d));\n", program, location, x, y, z, w);
    orig_glProgramUniform4iEXT(program, location, x, y, z, w);
}

static GLvoid (*orig_glProgramUniform1fEXT)(GLuint program, GLint location, GLfloat x);
GLvoid wrap_glProgramUniform1fEXT(GLuint program, GLint location, GLfloat x) {
    printf("/*#fishhook#**/ glProgramUniform1fEXT(%d, %d, %f));\n", program, location, x);
    orig_glProgramUniform1fEXT(program, location, x);
}

static GLvoid (*orig_glProgramUniform2fEXT)(GLuint program, GLint location, GLfloat x, GLfloat y);
GLvoid wrap_glProgramUniform2fEXT(GLuint program, GLint location, GLfloat x, GLfloat y) {
    printf("/*#fishhook#**/ glProgramUniform2fEXT(%d, %d, %f, %f));\n", program, location, x, y);
    orig_glProgramUniform2fEXT(program, location, x, y);
}

static GLvoid (*orig_glProgramUniform3fEXT)(GLuint program, GLint location, GLfloat x, GLfloat y, GLfloat z);
GLvoid wrap_glProgramUniform3fEXT(GLuint program, GLint location, GLfloat x, GLfloat y, GLfloat z) {
    printf("/*#fishhook#**/ glProgramUniform3fEXT(%d, %d, %f, %f, %f));\n", program, location, x, y, z);
    orig_glProgramUniform3fEXT(program, location, x, y, z);
}

static GLvoid (*orig_glProgramUniform4fEXT)(GLuint program, GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
GLvoid wrap_glProgramUniform4fEXT(GLuint program, GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w) {
    printf("/*#fishhook#**/ glProgramUniform4fEXT(%d, %d, %f, %f, %f, %f));\n", program, location, x, y, z, w);
    orig_glProgramUniform4fEXT(program, location, x, y, z, w);
}

static GLvoid (*orig_glProgramUniform1uiEXT)(GLuint program, GLint location, GLuint x);
GLvoid wrap_glProgramUniform1uiEXT(GLuint program, GLint location, GLuint x) {
    printf("/*#fishhook#**/ glProgramUniform1uiEXT(%d, %d, %d));\n", program, location, x);
    orig_glProgramUniform1uiEXT(program, location, x);
}

static GLvoid (*orig_glProgramUniform2uiEXT)(GLuint program, GLint location, GLuint x, GLuint y);
GLvoid wrap_glProgramUniform2uiEXT(GLuint program, GLint location, GLuint x, GLuint y) {
    printf("/*#fishhook#**/ glProgramUniform2uiEXT(%d, %d, %d, %d));\n", program, location, x, y);
    orig_glProgramUniform2uiEXT(program, location, x, y);
}

static GLvoid (*orig_glProgramUniform3uiEXT)(GLuint program, GLint location, GLuint x, GLuint y, GLuint z);
GLvoid wrap_glProgramUniform3uiEXT(GLuint program, GLint location, GLuint x, GLuint y, GLuint z) {
    printf("/*#fishhook#**/ glProgramUniform3uiEXT(%d, %d, %d, %d, %d));\n", program, location, x, y, z);
    orig_glProgramUniform3uiEXT(program, location, x, y, z);
}

static GLvoid (*orig_glProgramUniform4uiEXT)(GLuint program, GLint location, GLuint x, GLuint y, GLuint z, GLuint w);
GLvoid wrap_glProgramUniform4uiEXT(GLuint program, GLint location, GLuint x, GLuint y, GLuint z, GLuint w) {
    printf("/*#fishhook#**/ glProgramUniform4uiEXT(%d, %d, %d, %d, %d, %d));\n", program, location, x, y, z, w);
    orig_glProgramUniform4uiEXT(program, location, x, y, z, w);
}

static GLvoid (*orig_glProgramUniform1ivEXT)(GLuint program, GLint location, GLsizei count, const GLint *value);
GLvoid wrap_glProgramUniform1ivEXT(GLuint program, GLint location, GLsizei count, const GLint *value) {
    printf("/*#fishhook#**/ glProgramUniform1ivEXT(%d, %d, %d, %d));\n", program, location, count, value);
    orig_glProgramUniform1ivEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform2ivEXT)(GLuint program, GLint location, GLsizei count, const GLint *value);
GLvoid wrap_glProgramUniform2ivEXT(GLuint program, GLint location, GLsizei count, const GLint *value) {
    printf("/*#fishhook#**/ glProgramUniform2ivEXT(%d, %d, %d, %d));\n", program, location, count, value);
    orig_glProgramUniform2ivEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform3ivEXT)(GLuint program, GLint location, GLsizei count, const GLint *value);
GLvoid wrap_glProgramUniform3ivEXT(GLuint program, GLint location, GLsizei count, const GLint *value) {
    printf("/*#fishhook#**/ glProgramUniform3ivEXT(%d, %d, %d, %d));\n", program, location, count, value);
    orig_glProgramUniform3ivEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform4ivEXT)(GLuint program, GLint location, GLsizei count, const GLint *value);
GLvoid wrap_glProgramUniform4ivEXT(GLuint program, GLint location, GLsizei count, const GLint *value) {
    printf("/*#fishhook#**/ glProgramUniform4ivEXT(%d, %d, %d, %d));\n", program, location, count, value);
    orig_glProgramUniform4ivEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform1fvEXT)(GLuint program, GLint location, GLsizei count, const GLfloat *value);
GLvoid wrap_glProgramUniform1fvEXT(GLuint program, GLint location, GLsizei count, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniform1fvEXT(%d, %d, %d, %f));\n", program, location, count, value);
    orig_glProgramUniform1fvEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform2fvEXT)(GLuint program, GLint location, GLsizei count, const GLfloat *value);
GLvoid wrap_glProgramUniform2fvEXT(GLuint program, GLint location, GLsizei count, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniform2fvEXT(%d, %d, %d, %f));\n", program, location, count, value);
    orig_glProgramUniform2fvEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform3fvEXT)(GLuint program, GLint location, GLsizei count, const GLfloat *value);
GLvoid wrap_glProgramUniform3fvEXT(GLuint program, GLint location, GLsizei count, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniform3fvEXT(%d, %d, %d, %f));\n", program, location, count, value);
    orig_glProgramUniform3fvEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform4fvEXT)(GLuint program, GLint location, GLsizei count, const GLfloat *value);
GLvoid wrap_glProgramUniform4fvEXT(GLuint program, GLint location, GLsizei count, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniform4fvEXT(%d, %d, %d, %f));\n", program, location, count, value);
    orig_glProgramUniform4fvEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform1uivEXT)(GLuint program, GLint location, GLsizei count, const GLuint *value);
GLvoid wrap_glProgramUniform1uivEXT(GLuint program, GLint location, GLsizei count, const GLuint *value) {
    printf("/*#fishhook#**/ glProgramUniform1uivEXT(%d, %d, %d, %d));\n", program, location, count, value);
    orig_glProgramUniform1uivEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform2uivEXT)(GLuint program, GLint location, GLsizei count, const GLuint *value);
GLvoid wrap_glProgramUniform2uivEXT(GLuint program, GLint location, GLsizei count, const GLuint *value) {
    printf("/*#fishhook#**/ glProgramUniform2uivEXT(%d, %d, %d, %d));\n", program, location, count, value);
    orig_glProgramUniform2uivEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform3uivEXT)(GLuint program, GLint location, GLsizei count, const GLuint *value);
GLvoid wrap_glProgramUniform3uivEXT(GLuint program, GLint location, GLsizei count, const GLuint *value) {
    printf("/*#fishhook#**/ glProgramUniform3uivEXT(%d, %d, %d, %d));\n", program, location, count, value);
    orig_glProgramUniform3uivEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniform4uivEXT)(GLuint program, GLint location, GLsizei count, const GLuint *value);
GLvoid wrap_glProgramUniform4uivEXT(GLuint program, GLint location, GLsizei count, const GLuint *value) {
    printf("/*#fishhook#**/ glProgramUniform4uivEXT(%d, %d, %d, %d));\n", program, location, count, value);
    orig_glProgramUniform4uivEXT(program, location, count, value);
}

static GLvoid (*orig_glProgramUniformMatrix2fvEXT)(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLvoid wrap_glProgramUniformMatrix2fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniformMatrix2fvEXT(%d, %d, %d, %d, %f));\n", program, location, count, transpose, value);
    orig_glProgramUniformMatrix2fvEXT(program, location, count, transpose, value);
}

static GLvoid (*orig_glProgramUniformMatrix3fvEXT)(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLvoid wrap_glProgramUniformMatrix3fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniformMatrix3fvEXT(%d, %d, %d, %d, %f));\n", program, location, count, transpose, value);
    orig_glProgramUniformMatrix3fvEXT(program, location, count, transpose, value);
}

static GLvoid (*orig_glProgramUniformMatrix4fvEXT)(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLvoid wrap_glProgramUniformMatrix4fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniformMatrix4fvEXT(%d, %d, %d, %d, %f));\n", program, location, count, transpose, value);
    orig_glProgramUniformMatrix4fvEXT(program, location, count, transpose, value);
}

static GLvoid (*orig_glProgramUniformMatrix2x3fvEXT)(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLvoid wrap_glProgramUniformMatrix2x3fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniformMatrix2x3fvEXT(%d, %d, %d, %d, %f));\n", program, location, count, transpose, value);
    orig_glProgramUniformMatrix2x3fvEXT(program, location, count, transpose, value);
}

static GLvoid (*orig_glProgramUniformMatrix3x2fvEXT)(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLvoid wrap_glProgramUniformMatrix3x2fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniformMatrix3x2fvEXT(%d, %d, %d, %d, %f));\n", program, location, count, transpose, value);
    orig_glProgramUniformMatrix3x2fvEXT(program, location, count, transpose, value);
}

static GLvoid (*orig_glProgramUniformMatrix2x4fvEXT)(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLvoid wrap_glProgramUniformMatrix2x4fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniformMatrix2x4fvEXT(%d, %d, %d, %d, %f));\n", program, location, count, transpose, value);
    orig_glProgramUniformMatrix2x4fvEXT(program, location, count, transpose, value);
}

static GLvoid (*orig_glProgramUniformMatrix4x2fvEXT)(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLvoid wrap_glProgramUniformMatrix4x2fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniformMatrix4x2fvEXT(%d, %d, %d, %d, %f));\n", program, location, count, transpose, value);
    orig_glProgramUniformMatrix4x2fvEXT(program, location, count, transpose, value);
}

static GLvoid (*orig_glProgramUniformMatrix3x4fvEXT)(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLvoid wrap_glProgramUniformMatrix3x4fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniformMatrix3x4fvEXT(%d, %d, %d, %d, %f));\n", program, location, count, transpose, value);
    orig_glProgramUniformMatrix3x4fvEXT(program, location, count, transpose, value);
}

static GLvoid (*orig_glProgramUniformMatrix4x3fvEXT)(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLvoid wrap_glProgramUniformMatrix4x3fvEXT(GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {
    printf("/*#fishhook#**/ glProgramUniformMatrix4x3fvEXT(%d, %d, %d, %d, %f));\n", program, location, count, transpose, value);
    orig_glProgramUniformMatrix4x3fvEXT(program, location, count, transpose, value);
}

static struct rebinding rebindings[] = {
{"glCopyTextureLevelsAPPLE", wrap_glCopyTextureLevelsAPPLE, (void*)&orig_glCopyTextureLevelsAPPLE},
{"glLabelObjectEXT", wrap_glLabelObjectEXT, (void*)&orig_glLabelObjectEXT},
{"glGetObjectLabelEXT", wrap_glGetObjectLabelEXT, (void*)&orig_glGetObjectLabelEXT},
{"glInsertEventMarkerEXT", wrap_glInsertEventMarkerEXT, (void*)&orig_glInsertEventMarkerEXT},
{"glPushGroupMarkerEXT", wrap_glPushGroupMarkerEXT, (void*)&orig_glPushGroupMarkerEXT},
{"glPopGroupMarkerEXT", wrap_glPopGroupMarkerEXT, (void*)&orig_glPopGroupMarkerEXT},
{"glUseProgramStagesEXT", wrap_glUseProgramStagesEXT, (void*)&orig_glUseProgramStagesEXT},
{"glActiveShaderProgramEXT", wrap_glActiveShaderProgramEXT, (void*)&orig_glActiveShaderProgramEXT},
{"glCreateShaderProgramvEXT", wrap_glCreateShaderProgramvEXT, (void*)&orig_glCreateShaderProgramvEXT},
{"glBindProgramPipelineEXT", wrap_glBindProgramPipelineEXT, (void*)&orig_glBindProgramPipelineEXT},
{"glDeleteProgramPipelinesEXT", wrap_glDeleteProgramPipelinesEXT, (void*)&orig_glDeleteProgramPipelinesEXT},
{"glGenProgramPipelinesEXT", wrap_glGenProgramPipelinesEXT, (void*)&orig_glGenProgramPipelinesEXT},
{"glIsProgramPipelineEXT", wrap_glIsProgramPipelineEXT, (void*)&orig_glIsProgramPipelineEXT},
{"glProgramParameteriEXT", wrap_glProgramParameteriEXT, (void*)&orig_glProgramParameteriEXT},
{"glGetProgramPipelineivEXT", wrap_glGetProgramPipelineivEXT, (void*)&orig_glGetProgramPipelineivEXT},
{"glValidateProgramPipelineEXT", wrap_glValidateProgramPipelineEXT, (void*)&orig_glValidateProgramPipelineEXT},
{"glGetProgramPipelineInfoLogEXT", wrap_glGetProgramPipelineInfoLogEXT, (void*)&orig_glGetProgramPipelineInfoLogEXT},
{"glProgramUniform1iEXT", wrap_glProgramUniform1iEXT, (void*)&orig_glProgramUniform1iEXT},
{"glProgramUniform2iEXT", wrap_glProgramUniform2iEXT, (void*)&orig_glProgramUniform2iEXT},
{"glProgramUniform3iEXT", wrap_glProgramUniform3iEXT, (void*)&orig_glProgramUniform3iEXT},
{"glProgramUniform4iEXT", wrap_glProgramUniform4iEXT, (void*)&orig_glProgramUniform4iEXT},
{"glProgramUniform1fEXT", wrap_glProgramUniform1fEXT, (void*)&orig_glProgramUniform1fEXT},
{"glProgramUniform2fEXT", wrap_glProgramUniform2fEXT, (void*)&orig_glProgramUniform2fEXT},
{"glProgramUniform3fEXT", wrap_glProgramUniform3fEXT, (void*)&orig_glProgramUniform3fEXT},
{"glProgramUniform4fEXT", wrap_glProgramUniform4fEXT, (void*)&orig_glProgramUniform4fEXT},
{"glProgramUniform1uiEXT", wrap_glProgramUniform1uiEXT, (void*)&orig_glProgramUniform1uiEXT},
{"glProgramUniform2uiEXT", wrap_glProgramUniform2uiEXT, (void*)&orig_glProgramUniform2uiEXT},
{"glProgramUniform3uiEXT", wrap_glProgramUniform3uiEXT, (void*)&orig_glProgramUniform3uiEXT},
{"glProgramUniform4uiEXT", wrap_glProgramUniform4uiEXT, (void*)&orig_glProgramUniform4uiEXT},
{"glProgramUniform1ivEXT", wrap_glProgramUniform1ivEXT, (void*)&orig_glProgramUniform1ivEXT},
{"glProgramUniform2ivEXT", wrap_glProgramUniform2ivEXT, (void*)&orig_glProgramUniform2ivEXT},
{"glProgramUniform3ivEXT", wrap_glProgramUniform3ivEXT, (void*)&orig_glProgramUniform3ivEXT},
{"glProgramUniform4ivEXT", wrap_glProgramUniform4ivEXT, (void*)&orig_glProgramUniform4ivEXT},
{"glProgramUniform1fvEXT", wrap_glProgramUniform1fvEXT, (void*)&orig_glProgramUniform1fvEXT},
{"glProgramUniform2fvEXT", wrap_glProgramUniform2fvEXT, (void*)&orig_glProgramUniform2fvEXT},
{"glProgramUniform3fvEXT", wrap_glProgramUniform3fvEXT, (void*)&orig_glProgramUniform3fvEXT},
{"glProgramUniform4fvEXT", wrap_glProgramUniform4fvEXT, (void*)&orig_glProgramUniform4fvEXT},
{"glProgramUniform1uivEXT", wrap_glProgramUniform1uivEXT, (void*)&orig_glProgramUniform1uivEXT},
{"glProgramUniform2uivEXT", wrap_glProgramUniform2uivEXT, (void*)&orig_glProgramUniform2uivEXT},
{"glProgramUniform3uivEXT", wrap_glProgramUniform3uivEXT, (void*)&orig_glProgramUniform3uivEXT},
{"glProgramUniform4uivEXT", wrap_glProgramUniform4uivEXT, (void*)&orig_glProgramUniform4uivEXT},
{"glProgramUniformMatrix2fvEXT", wrap_glProgramUniformMatrix2fvEXT, (void*)&orig_glProgramUniformMatrix2fvEXT},
{"glProgramUniformMatrix3fvEXT", wrap_glProgramUniformMatrix3fvEXT, (void*)&orig_glProgramUniformMatrix3fvEXT},
{"glProgramUniformMatrix4fvEXT", wrap_glProgramUniformMatrix4fvEXT, (void*)&orig_glProgramUniformMatrix4fvEXT},
{"glProgramUniformMatrix2x3fvEXT", wrap_glProgramUniformMatrix2x3fvEXT, (void*)&orig_glProgramUniformMatrix2x3fvEXT},
{"glProgramUniformMatrix3x2fvEXT", wrap_glProgramUniformMatrix3x2fvEXT, (void*)&orig_glProgramUniformMatrix3x2fvEXT},
{"glProgramUniformMatrix2x4fvEXT", wrap_glProgramUniformMatrix2x4fvEXT, (void*)&orig_glProgramUniformMatrix2x4fvEXT},
{"glProgramUniformMatrix4x2fvEXT", wrap_glProgramUniformMatrix4x2fvEXT, (void*)&orig_glProgramUniformMatrix4x2fvEXT},
{"glProgramUniformMatrix3x4fvEXT", wrap_glProgramUniformMatrix3x4fvEXT, (void*)&orig_glProgramUniformMatrix3x4fvEXT},
{"glProgramUniformMatrix4x3fvEXT", wrap_glProgramUniformMatrix4x3fvEXT, (void*)&orig_glProgramUniformMatrix4x3fvEXT},
};

void hookES30GLExt()
{
    rebind_symbols(rebindings, 50);
}

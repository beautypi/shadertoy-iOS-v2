#ifndef __wrap_gl_es30_h__
#define __wrap_gl_es30_h__

#include <Availability.h>
#include <OpenGLES/OpenGLESAvailability.h>
#ifdef __cplusplus
extern "C" {
#endif

#include <OpenGLES/gltypes.h>

void hookES30GL(void);

/* OpenGL ES 2.0 */

void wrap_glActiveTexture(GLenum texture);

void wrap_glAttachShader(GLuint program, GLuint shader);

void wrap_glBindAttribLocation(GLuint program, GLuint index, const GLchar* name);

void wrap_glBindBuffer(GLenum target, GLuint buffer);

void wrap_glBindFramebuffer(GLenum target, GLuint framebuffer);

void wrap_glBindRenderbuffer(GLenum target, GLuint renderbuffer);

void wrap_glBindTexture(GLenum target, GLuint texture);

void wrap_glBlendColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);

void wrap_glBlendEquation(GLenum mode);

void wrap_glBlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha);

void wrap_glBlendFunc(GLenum sfactor, GLenum dfactor);

void wrap_glBlendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);

void wrap_glBufferData(GLenum target, GLsizeiptr size, const GLvoid* data, GLenum usage);

void wrap_glBufferSubData(GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid* data);

GLenum wrap_glCheckFramebufferStatus(GLenum target);

void wrap_glClear(GLbitfield mask);

void wrap_glClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);

void wrap_glClearDepthf(GLclampf depth);

void wrap_glClearStencil(GLint s);

void wrap_glColorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);

void wrap_glCompileShader(GLuint shader);

void wrap_glCompressedTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid* data);

void wrap_glCompressedTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid* data);

void wrap_glCopyTexImage2D(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);

void wrap_glCopyTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);

GLuint wrap_glCreateProgram(void);

GLuint wrap_glCreateShader(GLenum type);

void wrap_glCullFace(GLenum mode);

void wrap_glDeleteBuffers(GLsizei n, const GLuint* buffers);

void wrap_glDeleteFramebuffers(GLsizei n, const GLuint* framebuffers);

void wrap_glDeleteProgram(GLuint program);

void wrap_glDeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers);

void wrap_glDeleteShader(GLuint shader);

void wrap_glDeleteTextures(GLsizei n, const GLuint* textures);

void wrap_glDepthFunc(GLenum func);

void wrap_glDepthMask(GLboolean flag);

void wrap_glDepthRangef(GLclampf zNear, GLclampf zFar);

void wrap_glDetachShader(GLuint program, GLuint shader);

void wrap_glDisable(GLenum cap);

void wrap_glDisableVertexAttribArray(GLuint index);

void wrap_glDrawArrays(GLenum mode, GLint first, GLsizei count);

void wrap_glDrawElements(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);

void wrap_glEnable(GLenum cap);

void wrap_glEnableVertexAttribArray(GLuint index);

void wrap_glFinish(void);

void wrap_glFlush(void);

void wrap_glFramebufferRenderbuffer(GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);

void wrap_glFramebufferTexture2D(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);

void wrap_glFrontFace(GLenum mode);

void wrap_glGenBuffers(GLsizei n, GLuint* buffers);

void wrap_glGenerateMipmap(GLenum target);

void wrap_glGenFramebuffers(GLsizei n, GLuint* framebuffers);

void wrap_glGenRenderbuffers(GLsizei n, GLuint* renderbuffers);

void wrap_glGenTextures(GLsizei n, GLuint* textures);

void wrap_glGetActiveAttrib(GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size, GLenum* type, GLchar* name);

void wrap_glGetActiveUniform(GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size, GLenum* type, GLchar* name);

void wrap_glGetAttachedShaders(GLuint program, GLsizei maxcount, GLsizei* count, GLuint* shaders);

int wrap_glGetAttribLocation(GLuint program, const GLchar* name);

void wrap_glGetBooleanv(GLenum pname, GLboolean* params);

void wrap_glGetBufferParameteriv(GLenum target, GLenum pname, GLint* params);

GLenum wrap_glGetError(void);

void wrap_glGetFloatv(GLenum pname, GLfloat* params);

void wrap_glGetFramebufferAttachmentParameteriv(GLenum target, GLenum attachment, GLenum pname, GLint* params);

void wrap_glGetIntegerv(GLenum pname, GLint* params);

void wrap_glGetProgramiv(GLuint program, GLenum pname, GLint* params);

void wrap_glGetProgramInfoLog(GLuint program, GLsizei bufsize, GLsizei* length, GLchar* infolog);

void wrap_glGetRenderbufferParameteriv(GLenum target, GLenum pname, GLint* params);

void wrap_glGetShaderiv(GLuint shader, GLenum pname, GLint* params);

void wrap_glGetShaderInfoLog(GLuint shader, GLsizei bufsize, GLsizei* length, GLchar* infolog);

void wrap_glGetShaderPrecisionFormat(GLenum shadertype, GLenum precisiontype, GLint* range, GLint* precision);

void wrap_glGetShaderSource(GLuint shader, GLsizei bufsize, GLsizei* length, GLchar* source);

const GLubyte* wrap_glGetString(GLenum name);

void wrap_glGetTexParameterfv(GLenum target, GLenum pname, GLfloat* params);

void wrap_glGetTexParameteriv(GLenum target, GLenum pname, GLint* params);

void wrap_glGetUniformfv(GLuint program, GLint location, GLfloat* params);

void wrap_glGetUniformiv(GLuint program, GLint location, GLint* params);

int wrap_glGetUniformLocation(GLuint program, const GLchar* name);

void wrap_glGetVertexAttribfv(GLuint index, GLenum pname, GLfloat* params);

void wrap_glGetVertexAttribiv(GLuint index, GLenum pname, GLint* params);

void wrap_glGetVertexAttribPointerv(GLuint index, GLenum pname, GLvoid** pointer);

void wrap_glHint(GLenum target, GLenum mode);

GLboolean wrap_glIsBuffer(GLuint buffer);

GLboolean wrap_glIsEnabled(GLenum cap);

GLboolean wrap_glIsFramebuffer(GLuint framebuffer);

GLboolean wrap_glIsProgram(GLuint program);

GLboolean wrap_glIsRenderbuffer(GLuint renderbuffer);

GLboolean wrap_glIsShader(GLuint shader);

GLboolean wrap_glIsTexture(GLuint texture);

void wrap_glLineWidth(GLfloat width);

void wrap_glLinkProgram(GLuint program);

void wrap_glPixelStorei(GLenum pname, GLint param);

void wrap_glPolygonOffset(GLfloat factor, GLfloat units);

void wrap_glReadPixels(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid* pixels);

void wrap_glReleaseShaderCompiler(void);

void wrap_glRenderbufferStorage(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);

void wrap_glSampleCoverage(GLclampf value, GLboolean invert);

void wrap_glScissor(GLint x, GLint y, GLsizei width, GLsizei height);

void wrap_glShaderBinary(GLsizei n, const GLuint* shaders, GLenum binaryformat, const GLvoid* binary, GLsizei length);

void wrap_glShaderSource(GLuint shader, GLsizei count, const GLchar* const *string, const GLint* length);

void wrap_glStencilFunc(GLenum func, GLint ref, GLuint mask);

void wrap_glStencilFuncSeparate(GLenum face, GLenum func, GLint ref, GLuint mask);

void wrap_glStencilMask(GLuint mask);

void wrap_glStencilMaskSeparate(GLenum face, GLuint mask);

void wrap_glStencilOp(GLenum fail, GLenum zfail, GLenum zpass);

void wrap_glStencilOpSeparate(GLenum face, GLenum fail, GLenum zfail, GLenum zpass);

void wrap_glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid* pixels);

void wrap_glTexParameterf(GLenum target, GLenum pname, GLfloat param);

void wrap_glTexParameterfv(GLenum target, GLenum pname, const GLfloat* params);

void wrap_glTexParameteri(GLenum target, GLenum pname, GLint param);

void wrap_glTexParameteriv(GLenum target, GLenum pname, const GLint* params);

void wrap_glTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid* pixels);

void wrap_glUniform1f(GLint location, GLfloat x);

void wrap_glUniform1fv(GLint location, GLsizei count, const GLfloat* v);

void wrap_glUniform1i(GLint location, GLint x);

void wrap_glUniform1iv(GLint location, GLsizei count, const GLint* v);

void wrap_glUniform2f(GLint location, GLfloat x, GLfloat y);

void wrap_glUniform2fv(GLint location, GLsizei count, const GLfloat* v);

void wrap_glUniform2i(GLint location, GLint x, GLint y);

void wrap_glUniform2iv(GLint location, GLsizei count, const GLint* v);

void wrap_glUniform3f(GLint location, GLfloat x, GLfloat y, GLfloat z);

void wrap_glUniform3fv(GLint location, GLsizei count, const GLfloat* v);

void wrap_glUniform3i(GLint location, GLint x, GLint y, GLint z);

void wrap_glUniform3iv(GLint location, GLsizei count, const GLint* v);

void wrap_glUniform4f(GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w);

void wrap_glUniform4fv(GLint location, GLsizei count, const GLfloat* v);

void wrap_glUniform4i(GLint location, GLint x, GLint y, GLint z, GLint w);

void wrap_glUniform4iv(GLint location, GLsizei count, const GLint* v);

void wrap_glUniformMatrix2fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

void wrap_glUniformMatrix3fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

void wrap_glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

void wrap_glUseProgram(GLuint program);

void wrap_glValidateProgram(GLuint program);

void wrap_glVertexAttrib1f(GLuint indx, GLfloat x);

void wrap_glVertexAttrib1fv(GLuint indx, const GLfloat* values);

void wrap_glVertexAttrib2f(GLuint indx, GLfloat x, GLfloat y);

void wrap_glVertexAttrib2fv(GLuint indx, const GLfloat* values);

void wrap_glVertexAttrib3f(GLuint indx, GLfloat x, GLfloat y, GLfloat z);

void wrap_glVertexAttrib3fv(GLuint indx, const GLfloat* values);

void wrap_glVertexAttrib4f(GLuint indx, GLfloat x, GLfloat y, GLfloat z, GLfloat w);

void wrap_glVertexAttrib4fv(GLuint indx, const GLfloat* values);

void wrap_glVertexAttribPointer(GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr);

void wrap_glViewport(GLint x, GLint y, GLsizei width, GLsizei height);


/* OpenGL ES 3.0 */

void wrap_glReadBuffer(GLenum mode);

void wrap_glDrawRangeElements(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid* indices);

void wrap_glTexImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid* pixels);

void wrap_glTexSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid* pixels);

void wrap_glCopyTexSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);

void wrap_glCompressedTexImage3D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid* data);

void wrap_glCompressedTexSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid* data);

void wrap_glGenQueries(GLsizei n, GLuint* ids);

void wrap_glDeleteQueries(GLsizei n, const GLuint* ids);

GLboolean wrap_glIsQuery(GLuint id);

void wrap_glBeginQuery(GLenum target, GLuint id);

void wrap_glEndQuery(GLenum target);

void wrap_glGetQueryiv(GLenum target, GLenum pname, GLint* params);

void wrap_glGetQueryObjectuiv(GLuint id, GLenum pname, GLuint* params);

GLboolean wrap_glUnmapBuffer(GLenum target);

void wrap_glGetBufferPointerv(GLenum target, GLenum pname, GLvoid** params);

void wrap_glDrawBuffers(GLsizei n, const GLenum* bufs);

void wrap_glUniformMatrix2x3fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

void wrap_glUniformMatrix3x2fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

void wrap_glUniformMatrix2x4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

void wrap_glUniformMatrix4x2fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

void wrap_glUniformMatrix3x4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

void wrap_glUniformMatrix4x3fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

void wrap_glBlitFramebuffer(GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);

void wrap_glRenderbufferStorageMultisample(GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);

void wrap_glFramebufferTextureLayer(GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);

GLvoid* wrap_glMapBufferRange(GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access);

void wrap_glFlushMappedBufferRange(GLenum target, GLintptr offset, GLsizeiptr length);

void wrap_glBindVertexArray(GLuint array);

void wrap_glDeleteVertexArrays(GLsizei n, const GLuint* arrays);

void wrap_glGenVertexArrays(GLsizei n, GLuint* arrays);

GLboolean wrap_glIsVertexArray(GLuint array);

void wrap_glGetIntegeri_v(GLenum target, GLuint index, GLint* data);

void wrap_glBeginTransformFeedback(GLenum primitiveMode);

void wrap_glEndTransformFeedback(void);

void wrap_glBindBufferRange(GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);

void wrap_glBindBufferBase(GLenum target, GLuint index, GLuint buffer);

void wrap_glTransformFeedbackVaryings(GLuint program, GLsizei count, const GLchar* const *varyings, GLenum bufferMode);

void wrap_glGetTransformFeedbackVarying(GLuint program, GLuint index, GLsizei bufSize, GLsizei* length, GLsizei* size, GLenum* type, GLchar* name);

void wrap_glVertexAttribIPointer(GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid* pointer);

void wrap_glGetVertexAttribIiv(GLuint index, GLenum pname, GLint* params);

void wrap_glGetVertexAttribIuiv(GLuint index, GLenum pname, GLuint* params);

void wrap_glVertexAttribI4i(GLuint index, GLint x, GLint y, GLint z, GLint w);

void wrap_glVertexAttribI4ui(GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);

void wrap_glVertexAttribI4iv(GLuint index, const GLint* v);

void wrap_glVertexAttribI4uiv(GLuint index, const GLuint* v);

void wrap_glGetUniformuiv(GLuint program, GLint location, GLuint* params);

GLint wrap_glGetFragDataLocation(GLuint program, const GLchar *name);

void wrap_glUniform1ui(GLint location, GLuint v0);

void wrap_glUniform2ui(GLint location, GLuint v0, GLuint v1);

void wrap_glUniform3ui(GLint location, GLuint v0, GLuint v1, GLuint v2);

void wrap_glUniform4ui(GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);

void wrap_glUniform1uiv(GLint location, GLsizei count, const GLuint* value);

void wrap_glUniform2uiv(GLint location, GLsizei count, const GLuint* value);

void wrap_glUniform3uiv(GLint location, GLsizei count, const GLuint* value);

void wrap_glUniform4uiv(GLint location, GLsizei count, const GLuint* value);

void wrap_glClearBufferiv(GLenum buffer, GLint drawbuffer, const GLint* value);

void wrap_glClearBufferuiv(GLenum buffer, GLint drawbuffer, const GLuint* value);

void wrap_glClearBufferfv(GLenum buffer, GLint drawbuffer, const GLfloat* value);

void wrap_glClearBufferfi(GLenum buffer, GLint drawbuffer, GLfloat depth, GLint stencil);

const GLubyte* wrap_glGetStringi(GLenum name, GLuint index);

void wrap_glCopyBufferSubData(GLenum readTarget, GLenum writeTarget, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size);

void wrap_glGetUniformIndices(GLuint program, GLsizei uniformCount, const GLchar* const *uniformNames, GLuint* uniformIndices);

void wrap_glGetActiveUniformsiv(GLuint program, GLsizei uniformCount, const GLuint* uniformIndices, GLenum pname, GLint* params);

GLuint wrap_glGetUniformBlockIndex(GLuint program, const GLchar* uniformBlockName);

void wrap_glGetActiveUniformBlockiv(GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint* params);

void wrap_glGetActiveUniformBlockName(GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei* length, GLchar* uniformBlockName);

void wrap_glUniformBlockBinding(GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding);

void wrap_glDrawArraysInstanced(GLenum mode, GLint first, GLsizei count, GLsizei instancecount);

void wrap_glDrawElementsInstanced(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices, GLsizei instancecount);

GLsync wrap_glFenceSync(GLenum condition, GLbitfield flags);

GLboolean wrap_glIsSync(GLsync sync);

void wrap_glDeleteSync(GLsync sync);

GLenum wrap_glClientWaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout);

void wrap_glWaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout);

void wrap_glGetInteger64v(GLenum pname, GLint64* params);

void wrap_glGetSynciv(GLsync sync, GLenum pname, GLsizei bufSize, GLsizei* length, GLint* values);

void wrap_glGetInteger64i_v(GLenum target, GLuint index, GLint64* data);

void wrap_glGetBufferParameteri64v(GLenum target, GLenum pname, GLint64* params);

void wrap_glGenSamplers(GLsizei count, GLuint* samplers);

void wrap_glDeleteSamplers(GLsizei count, const GLuint* samplers);

GLboolean wrap_glIsSampler(GLuint sampler);

void wrap_glBindSampler(GLuint unit, GLuint sampler);

void wrap_glSamplerParameteri(GLuint sampler, GLenum pname, GLint param);

void wrap_glSamplerParameteriv(GLuint sampler, GLenum pname, const GLint* param);

void wrap_glSamplerParameterf(GLuint sampler, GLenum pname, GLfloat param);

void wrap_glSamplerParameterfv(GLuint sampler, GLenum pname, const GLfloat* param);

void wrap_glGetSamplerParameteriv(GLuint sampler, GLenum pname, GLint* params);

void wrap_glGetSamplerParameterfv(GLuint sampler, GLenum pname, GLfloat* params);

void wrap_glVertexAttribDivisor(GLuint index, GLuint divisor);

void wrap_glBindTransformFeedback(GLenum target, GLuint id);

void wrap_glDeleteTransformFeedbacks(GLsizei n, const GLuint* ids);

void wrap_glGenTransformFeedbacks(GLsizei n, GLuint* ids);

GLboolean wrap_glIsTransformFeedback(GLuint id);

void wrap_glPauseTransformFeedback(void);

void wrap_glResumeTransformFeedback(void);

void wrap_glGetProgramBinary(GLuint program, GLsizei bufSize, GLsizei* length, GLenum* binaryFormat, GLvoid* binary);

void wrap_glProgramBinary(GLuint program, GLenum binaryFormat, const GLvoid* binary, GLsizei length);

void wrap_glProgramParameteri(GLuint program, GLenum pname, GLint value);

void wrap_glInvalidateFramebuffer(GLenum target, GLsizei numAttachments, const GLenum* attachments);

void wrap_glInvalidateSubFramebuffer(GLenum target, GLsizei numAttachments, const GLenum* attachments, GLint x, GLint y, GLsizei width, GLsizei height);

void wrap_glTexStorage2D(GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);

void wrap_glTexStorage3D(GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);

void wrap_glGetInternalformativ(GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint* params);


#ifdef __cplusplus
}
#endif

#endif /* __wrap_gl_es30_h__ */

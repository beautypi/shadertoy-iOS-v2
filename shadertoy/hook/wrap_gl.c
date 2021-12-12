#include "wrap_gl.h"
#include <OpenGLES/ES3/gl.h>
#include <fishhook/fishhook.h>
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

static void (*orig_glActiveTexture)(GLenum texture);
void wrap_glActiveTexture(GLenum texture) {
    printf("/*#fishhook#**/ glActiveTexture(0x%04x));\n", texture);
    orig_glActiveTexture(texture);
}

static void (*orig_glAttachShader)(GLuint program, GLuint shader);
void wrap_glAttachShader(GLuint program, GLuint shader) {
    printf("/*#fishhook#**/ glAttachShader(%d, %d));\n", program, shader);
    orig_glAttachShader(program, shader);
}

static void (*orig_glBindAttribLocation)(GLuint program, GLuint index, const GLchar* name);
void wrap_glBindAttribLocation(GLuint program, GLuint index, const GLchar* name) {
    printf("/*#fishhook#**/ glBindAttribLocation(%d, %d, \"%s\"));\n", program, index, name);
    orig_glBindAttribLocation(program, index, name);
}

static void (*orig_glBindBuffer)(GLenum target, GLuint buffer);
void wrap_glBindBuffer(GLenum target, GLuint buffer) {
    printf("/*#fishhook#**/ glBindBuffer(0x%04x, %d));\n", target, buffer);
    orig_glBindBuffer(target, buffer);
}

static void (*orig_glBindFramebuffer)(GLenum target, GLuint framebuffer);
void wrap_glBindFramebuffer(GLenum target, GLuint framebuffer) {
    printf("/*#fishhook#**/ glBindFramebuffer(0x%04x, %d));\n", target, framebuffer);
    orig_glBindFramebuffer(target, framebuffer);
}

static void (*orig_glBindRenderbuffer)(GLenum target, GLuint renderbuffer);
void wrap_glBindRenderbuffer(GLenum target, GLuint renderbuffer) {
    printf("/*#fishhook#**/ glBindRenderbuffer(0x%04x, %d));\n", target, renderbuffer);
    orig_glBindRenderbuffer(target, renderbuffer);
}

static void (*orig_glBindTexture)(GLenum target, GLuint texture);
void wrap_glBindTexture(GLenum target, GLuint texture) {
    printf("/*#fishhook#**/ glBindTexture(0x%04x, %d));\n", target, texture);
    orig_glBindTexture(target, texture);
}

static void (*orig_glBlendColor)(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void wrap_glBlendColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {
    printf("/*#fishhook#**/ glBlendColor(%f, %f, %f, %f));\n", red, green, blue, alpha);
    orig_glBlendColor(red, green, blue, alpha);
}

static void (*orig_glBlendEquation)(GLenum mode);
void wrap_glBlendEquation(GLenum mode) {
    printf("/*#fishhook#**/ glBlendEquation(0x%04x));\n", mode);
    orig_glBlendEquation(mode);
}

static void (*orig_glBlendEquationSeparate)(GLenum modeRGB, GLenum modeAlpha);
void wrap_glBlendEquationSeparate(GLenum modeRGB, GLenum modeAlpha) {
    printf("/*#fishhook#**/ glBlendEquationSeparate(0x%04x, 0x%04x));\n", modeRGB, modeAlpha);
    orig_glBlendEquationSeparate(modeRGB, modeAlpha);
}

static void (*orig_glBlendFunc)(GLenum sfactor, GLenum dfactor);
void wrap_glBlendFunc(GLenum sfactor, GLenum dfactor) {
    printf("/*#fishhook#**/ glBlendFunc(0x%04x, 0x%04x));\n", sfactor, dfactor);
    orig_glBlendFunc(sfactor, dfactor);
}

static void (*orig_glBlendFuncSeparate)(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);
void wrap_glBlendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha) {
    printf("/*#fishhook#**/ glBlendFuncSeparate(0x%04x, 0x%04x, 0x%04x, 0x%04x));\n", srcRGB, dstRGB, srcAlpha, dstAlpha);
    orig_glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
}

static void (*orig_glBufferData)(GLenum target, GLsizeiptr size, const GLvoid* data, GLenum usage);
void wrap_glBufferData(GLenum target, GLsizeiptr size, const GLvoid* data, GLenum usage) {
    printf("/*#fishhook#**/ glBufferData(0x%04x, %d, [0x%04x], 0x%04x));\n", target, (int)size, ((int*)data)[0], usage);
    orig_glBufferData(target, size, data, usage);
}

static void (*orig_glBufferSubData)(GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid* data);
void wrap_glBufferSubData(GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid* data) {
    printf("/*#fishhook#**/ glBufferSubData(0x%04x, %d, %d, [0x%04x]));\n", target, (int)offset, (int)size, ((int*)data)[0]);
    orig_glBufferSubData(target, offset, size, data);
}

static GLenum (*orig_glCheckFramebufferStatus)(GLenum target);
GLenum wrap_glCheckFramebufferStatus(GLenum target) {
    printf("/*#fishhook#**/ glCheckFramebufferStatus(0x%04x));\n", target);
    return orig_glCheckFramebufferStatus(target);
}

static void (*orig_glClear)(GLbitfield mask);
void wrap_glClear(GLbitfield mask) {
    printf("/*#fishhook#**/ glClear(0x%04x));\n", mask);
    orig_glClear(mask);
}

static void (*orig_glClearColor)(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void wrap_glClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {
    printf("/*#fishhook#**/ glClearColor(%f, %f, %f, %f));\n", red, green, blue, alpha);
    orig_glClearColor(red, green, blue, alpha);
}

static void (*orig_glClearDepthf)(GLclampf depth);
void wrap_glClearDepthf(GLclampf depth) {
    printf("/*#fishhook#**/ glClearDepthf(%f));\n", depth);
    orig_glClearDepthf(depth);
}

static void (*orig_glClearStencil)(GLint s);
void wrap_glClearStencil(GLint s) {
    printf("/*#fishhook#**/ glClearStencil(%d));\n", s);
    orig_glClearStencil(s);
}

static void (*orig_glColorMask)(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
void wrap_glColorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha) {
    printf("/*#fishhook#**/ glColorMask(%d, %d, %d, %d));\n", red, green, blue, alpha);
    orig_glColorMask(red, green, blue, alpha);
}

static void (*orig_glCompileShader)(GLuint shader);
void wrap_glCompileShader(GLuint shader) {
    printf("/*#fishhook#**/ glCompileShader(%d));\n", shader);
    orig_glCompileShader(shader);
}

static void (*orig_glCompressedTexImage2D)(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid* data);
void wrap_glCompressedTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid* data) {
    printf("/*#fishhook#**/ glCompressedTexImage2D(0x%04x, %d, 0x%04x, %d, %d, %d, %d, [0x%04x]));\n", target, level, internalformat, width, height, border, imageSize, ((int*)data)[0]);
    orig_glCompressedTexImage2D(target, level, internalformat, width, height, border, imageSize, data);
}

static void (*orig_glCompressedTexSubImage2D)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid* data);
void wrap_glCompressedTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid* data) {
    printf("/*#fishhook#**/ glCompressedTexSubImage2D(0x%04x, %d, %d, %d, %d, %d, 0x%04x, %d, [0x%04x]));\n", target, level, xoffset, yoffset, width, height, format, imageSize, ((int*)data)[0]);
    orig_glCompressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, imageSize, data);
}

static void (*orig_glCopyTexImage2D)(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
void wrap_glCopyTexImage2D(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border) {
    printf("/*#fishhook#**/ glCopyTexImage2D(0x%04x, %d, 0x%04x, %d, %d, %d, %d, %d));\n", target, level, internalformat, x, y, width, height, border);
    orig_glCopyTexImage2D(target, level, internalformat, x, y, width, height, border);
}

static void (*orig_glCopyTexSubImage2D)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
void wrap_glCopyTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height) {
    printf("/*#fishhook#**/ glCopyTexSubImage2D(0x%04x, %d, %d, %d, %d, %d, %d, %d));\n", target, level, xoffset, yoffset, x, y, width, height);
    orig_glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
}

static GLuint (*orig_glCreateProgram)(void);
GLuint wrap_glCreateProgram(void) {
    printf("/*#fishhook#**/ glCreateProgram(");
    return orig_glCreateProgram();
}

static GLuint (*orig_glCreateShader)(GLenum type);
GLuint wrap_glCreateShader(GLenum type) {
    printf("/*#fishhook#**/ glCreateShader(0x%04x));\n", type);
    return orig_glCreateShader(type);
}

static void (*orig_glCullFace)(GLenum mode);
void wrap_glCullFace(GLenum mode) {
    printf("/*#fishhook#**/ glCullFace(0x%04x));\n", mode);
    orig_glCullFace(mode);
}

static void (*orig_glDeleteBuffers)(GLsizei n, const GLuint* buffers);
void wrap_glDeleteBuffers(GLsizei n, const GLuint* buffers) {
    printf("/*#fishhook#**/ glDeleteBuffers(%d, [%d]));\n", n, ((int*)buffers)[0]);
    orig_glDeleteBuffers(n, buffers);
}

static void (*orig_glDeleteFramebuffers)(GLsizei n, const GLuint* framebuffers);
void wrap_glDeleteFramebuffers(GLsizei n, const GLuint* framebuffers) {
    printf("/*#fishhook#**/ glDeleteFramebuffers(%d, [%d]));\n", n, ((int*)framebuffers)[0]);
    orig_glDeleteFramebuffers(n, framebuffers);
}

static void (*orig_glDeleteProgram)(GLuint program);
void wrap_glDeleteProgram(GLuint program) {
    printf("/*#fishhook#**/ glDeleteProgram(%d));\n", program);
    orig_glDeleteProgram(program);
}

static void (*orig_glDeleteRenderbuffers)(GLsizei n, const GLuint* renderbuffers);
void wrap_glDeleteRenderbuffers(GLsizei n, const GLuint* renderbuffers) {
    printf("/*#fishhook#**/ glDeleteRenderbuffers(%d, [%d]));\n", n, ((int*)renderbuffers)[0]);
    orig_glDeleteRenderbuffers(n, renderbuffers);
}

static void (*orig_glDeleteShader)(GLuint shader);
void wrap_glDeleteShader(GLuint shader) {
    printf("/*#fishhook#**/ glDeleteShader(%d));\n", shader);
    orig_glDeleteShader(shader);
}

static void (*orig_glDeleteTextures)(GLsizei n, const GLuint* textures);
void wrap_glDeleteTextures(GLsizei n, const GLuint* textures) {
    printf("/*#fishhook#**/ glDeleteTextures(%d, [%d]));\n", n, ((int*)textures)[0]);
    orig_glDeleteTextures(n, textures);
}

static void (*orig_glDepthFunc)(GLenum func);
void wrap_glDepthFunc(GLenum func) {
    printf("/*#fishhook#**/ glDepthFunc(0x%04x));\n", func);
    orig_glDepthFunc(func);
}

static void (*orig_glDepthMask)(GLboolean flag);
void wrap_glDepthMask(GLboolean flag) {
    printf("/*#fishhook#**/ glDepthMask(0x%04x));\n", flag);
    orig_glDepthMask(flag);
}

static void (*orig_glDepthRangef)(GLclampf zNear, GLclampf zFar);
void wrap_glDepthRangef(GLclampf zNear, GLclampf zFar) {
    printf("/*#fishhook#**/ glDepthRangef(%f, %f));\n", zNear, zFar);
    orig_glDepthRangef(zNear, zFar);
}

static void (*orig_glDetachShader)(GLuint program, GLuint shader);
void wrap_glDetachShader(GLuint program, GLuint shader) {
    printf("/*#fishhook#**/ glDetachShader(%d, %d));\n", program, shader);
    orig_glDetachShader(program, shader);
}

static void (*orig_glDisable)(GLenum cap);
void wrap_glDisable(GLenum cap) {
    printf("/*#fishhook#**/ glDisable(0x%04x));\n", cap);
    orig_glDisable(cap);
}

static void (*orig_glDisableVertexAttribArray)(GLuint index);
void wrap_glDisableVertexAttribArray(GLuint index) {
    printf("/*#fishhook#**/ glDisableVertexAttribArray(%d));\n", index);
    orig_glDisableVertexAttribArray(index);
}

static void (*orig_glDrawArrays)(GLenum mode, GLint first, GLsizei count);
void wrap_glDrawArrays(GLenum mode, GLint first, GLsizei count) {
    printf("/*#fishhook#**/ glDrawArrays(0x%04x, %d, %d));\n", mode, first, count);
    orig_glDrawArrays(mode, first, count);
}

static void (*orig_glDrawElements)(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
void wrap_glDrawElements(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices) {
    printf("/*#fishhook#**/ glDrawElements(0x%04x, %d, 0x%04x, 0x%lx));\n", mode, count, type, (long)indices);
    orig_glDrawElements(mode, count, type, indices);
}

static void (*orig_glEnable)(GLenum cap);
void wrap_glEnable(GLenum cap) {
    printf("/*#fishhook#**/ glEnable(0x%04x));\n", cap);
    orig_glEnable(cap);
}

static void (*orig_glEnableVertexAttribArray)(GLuint index);
void wrap_glEnableVertexAttribArray(GLuint index) {
    printf("/*#fishhook#**/ glEnableVertexAttribArray(%d));\n", index);
    orig_glEnableVertexAttribArray(index);
}

static void (*orig_glFinish)(void);
void wrap_glFinish(void) {
    printf("/*#fishhook#**/ glFinish(");
    orig_glFinish();
}

static void (*orig_glFlush)(void);
void wrap_glFlush(void) {
    printf("/*#fishhook#**/ glFlush(");
    orig_glFlush();
}

static void (*orig_glFramebufferRenderbuffer)(GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
void wrap_glFramebufferRenderbuffer(GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer) {
    printf("/*#fishhook#**/ glFramebufferRenderbuffer(0x%04x, 0x%04x, 0x%04x, %d));\n", target, attachment, renderbuffertarget, renderbuffer);
    orig_glFramebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer);
}

static void (*orig_glFramebufferTexture2D)(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
void wrap_glFramebufferTexture2D(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level) {
    printf("/*#fishhook#**/ glFramebufferTexture2D(0x%04x, 0x%04x, 0x%04x, %d, %d));\n", target, attachment, textarget, texture, level);
    orig_glFramebufferTexture2D(target, attachment, textarget, texture, level);
}

static void (*orig_glFrontFace)(GLenum mode);
void wrap_glFrontFace(GLenum mode) {
    printf("/*#fishhook#**/ glFrontFace(0x%04x));\n", mode);
    orig_glFrontFace(mode);
}

static void (*orig_glGenBuffers)(GLsizei n, GLuint* buffers);
void wrap_glGenBuffers(GLsizei n, GLuint* buffers) {
    orig_glGenBuffers(n, buffers);
    printf("/*#fishhook#**/ {GLuint buffers[] = {");
    for (int i = 0; i < n; ++i)
    {
        printf("%d, ", buffers[i]);
    }
    printf("}; glGenBuffers(%d, buffers));}\n", n);
}

static void (*orig_glGenerateMipmap)(GLenum target);
void wrap_glGenerateMipmap(GLenum target) {
    printf("/*#fishhook#**/ glGenerateMipmap(0x%04x));\n", target);
    orig_glGenerateMipmap(target);
}

static void (*orig_glGenFramebuffers)(GLsizei n, GLuint* framebuffers);
void wrap_glGenFramebuffers(GLsizei n, GLuint* framebuffers) {
    orig_glGenFramebuffers(n, framebuffers);
    printf("/*#fishhook#**/ {GLuint framebuffers[] = {");
    for (int i = 0; i < n; ++i)
    {
        printf("%d, ", framebuffers[i]);
    }
    printf("}; glGenFramebuffers(%d, framebuffers));}\n", n);
}

static void (*orig_glGenRenderbuffers)(GLsizei n, GLuint* renderbuffers);
void wrap_glGenRenderbuffers(GLsizei n, GLuint* renderbuffers) {
    orig_glGenRenderbuffers(n, renderbuffers);
    printf("/*#fishhook#**/ {GLuint renderbuffers[] = {");
    for (int i = 0; i < n; ++i)
    {
        printf("%d, ", renderbuffers[i]);
    }
    printf("}; glGenRenderbuffers(%d, renderbuffers));}\n", n);
}

static void (*orig_glGenTextures)(GLsizei n, GLuint* textures);
void wrap_glGenTextures(GLsizei n, GLuint* textures) {
    orig_glGenTextures(n, textures);
    printf("/*#fishhook#**/ {GLuint textures[] = {");
    for (int i = 0; i < n; ++i)
    {
        printf("%d, ", textures[i]);
    }
    printf("}; glGenTextures(%d, textures));}\n", n);
}

static void (*orig_glGetActiveAttrib)(GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size, GLenum* type, GLchar* name);
void wrap_glGetActiveAttrib(GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size, GLenum* type, GLchar* name) {
    printf("/*#fishhook#**/ glGetActiveAttrib(%d, %d, %d, [%d], [%d], [0x%04x], [[0x%04x]]));\n", program, index, bufsize, ((int*)length)[0], ((int*)size)[0], ((int*)type)[0], ((int*)name)[0]);
    orig_glGetActiveAttrib(program, index, bufsize, length, size, type, name);
}

static void (*orig_glGetActiveUniform)(GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size, GLenum* type, GLchar* name);
void wrap_glGetActiveUniform(GLuint program, GLuint index, GLsizei bufsize, GLsizei* length, GLint* size, GLenum* type, GLchar* name) {
    printf("/*#fishhook#**/ glGetActiveUniform(%d, %d, %d, [%d], [%d], [0x%04x], [[0x%04x]]));\n", program, index, bufsize, ((int*)length)[0], ((int*)size)[0], ((int*)type)[0], ((int*)name)[0]);
    orig_glGetActiveUniform(program, index, bufsize, length, size, type, name);
}

static void (*orig_glGetAttachedShaders)(GLuint program, GLsizei maxcount, GLsizei* count, GLuint* shaders);
void wrap_glGetAttachedShaders(GLuint program, GLsizei maxcount, GLsizei* count, GLuint* shaders) {
    printf("/*#fishhook#**/ glGetAttachedShaders(%d, %d, [%d], [%d]));\n", program, maxcount, ((int*)count)[0], ((int*)shaders)[0]);
    orig_glGetAttachedShaders(program, maxcount, count, shaders);
}

static int (*orig_glGetAttribLocation)(GLuint program, const GLchar* name);
int wrap_glGetAttribLocation(GLuint program, const GLchar* name) {
    int ret = orig_glGetAttribLocation(program, name);
    printf("/*#fishhook#**/ glGetAttribLocation(%d, \"%s\")); // = %d\n", program, name, ret);
    return ret;
}

static void (*orig_glGetBooleanv)(GLenum pname, GLboolean* params);
void wrap_glGetBooleanv(GLenum pname, GLboolean* params) {
    printf("/*#fishhook#**/ glGetBooleanv(0x%04x, [0x%04x]));\n", pname, ((int*)params)[0]);
    orig_glGetBooleanv(pname, params);
}

static void (*orig_glGetBufferParameteriv)(GLenum target, GLenum pname, GLint* params);
void wrap_glGetBufferParameteriv(GLenum target, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetBufferParameteriv(0x%04x, 0x%04x, [%d]));\n", target, pname, ((int*)params)[0]);
    orig_glGetBufferParameteriv(target, pname, params);
}

static GLenum (*orig_glGetError)(void);
GLenum wrap_glGetError(void) {
    GLenum ret = orig_glGetError();
    printf("/*#fishhook#**/ glGetError(); //=%d\n", ret);
    return ret;
}

static void (*orig_glGetFloatv)(GLenum pname, GLfloat* params);
void wrap_glGetFloatv(GLenum pname, GLfloat* params) {
    orig_glGetFloatv(pname, params);
    printf("/*#fishhook#**/ { GLfloat params[] = {...}; glGetFloatv(0x%04x, params));}\n", pname);
    //TODO:
}

static void (*orig_glGetFramebufferAttachmentParameteriv)(GLenum target, GLenum attachment, GLenum pname, GLint* params);
void wrap_glGetFramebufferAttachmentParameteriv(GLenum target, GLenum attachment, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetFramebufferAttachmentParameteriv(0x%04x, 0x%04x, 0x%04x, [%d]));\n", target, attachment, pname, ((int*)params)[0]);
    orig_glGetFramebufferAttachmentParameteriv(target, attachment, pname, params);
}

static void (*orig_glGetIntegerv)(GLenum pname, GLint* params);
void wrap_glGetIntegerv(GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetIntegerv(0x%04x, [%d]));\n", pname, ((int*)params)[0]);
    orig_glGetIntegerv(pname, params);
}

static void (*orig_glGetProgramiv)(GLuint program, GLenum pname, GLint* params);
void wrap_glGetProgramiv(GLuint program, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetProgramiv(%d, 0x%04x, [%d]));\n", program, pname, ((int*)params)[0]);
    orig_glGetProgramiv(program, pname, params);
}

static void (*orig_glGetProgramInfoLog)(GLuint program, GLsizei bufsize, GLsizei* length, GLchar* infolog);
void wrap_glGetProgramInfoLog(GLuint program, GLsizei bufsize, GLsizei* length, GLchar* infolog) {
    printf("/*#fishhook#**/ glGetProgramInfoLog(%d, %d, [%d], [[%d]]));\n", program, bufsize, ((int*)length)[0], ((int*)infolog)[0]);
    orig_glGetProgramInfoLog(program, bufsize, length, infolog);
}

static void (*orig_glGetRenderbufferParameteriv)(GLenum target, GLenum pname, GLint* params);
void wrap_glGetRenderbufferParameteriv(GLenum target, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetRenderbufferParameteriv(0x%04x, 0x%04x, [%d]));\n", target, pname, ((int*)params)[0]);
    orig_glGetRenderbufferParameteriv(target, pname, params);
}

static void (*orig_glGetShaderiv)(GLuint shader, GLenum pname, GLint* params);
void wrap_glGetShaderiv(GLuint shader, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetShaderiv(%d, 0x%04x, [%d]));\n", shader, pname, ((int*)params)[0]);
    orig_glGetShaderiv(shader, pname, params);
}

static void (*orig_glGetShaderInfoLog)(GLuint shader, GLsizei bufsize, GLsizei* length, GLchar* infolog);
void wrap_glGetShaderInfoLog(GLuint shader, GLsizei bufsize, GLsizei* length, GLchar* infolog) {
    printf("/*#fishhook#**/ glGetShaderInfoLog(%d, %d, [%d], [[%d]]));\n", shader, bufsize, ((int*)length)[0], ((int*)infolog)[0]);
    orig_glGetShaderInfoLog(shader, bufsize, length, infolog);
}

static void (*orig_glGetShaderPrecisionFormat)(GLenum shadertype, GLenum precisiontype, GLint* range, GLint* precision);
void wrap_glGetShaderPrecisionFormat(GLenum shadertype, GLenum precisiontype, GLint* range, GLint* precision) {
    printf("/*#fishhook#**/ glGetShaderPrecisionFormat(0x%04x, 0x%04x, [%d], [%d]));\n", shadertype, precisiontype, ((int*)range)[0], ((int*)precision)[0]);
    orig_glGetShaderPrecisionFormat(shadertype, precisiontype, range, precision);
}

static void (*orig_glGetShaderSource)(GLuint shader, GLsizei bufsize, GLsizei* length, GLchar* source);
void wrap_glGetShaderSource(GLuint shader, GLsizei bufsize, GLsizei* length, GLchar* source) {
    printf("/*#fishhook#**/ glGetShaderSource(%d, %d, [%d], [[%d]]));\n", shader, bufsize, ((int*)length)[0], ((int*)source)[0]);
    orig_glGetShaderSource(shader, bufsize, length, source);
}

static const GLubyte* (*orig_glGetString)(GLenum name);
const GLubyte* wrap_glGetString(GLenum name) {
    printf("/*#fishhook#**/ glGetString(0x%04x));\n", name);
    return orig_glGetString(name);
}

static void (*orig_glGetTexParameterfv)(GLenum target, GLenum pname, GLfloat* params);
void wrap_glGetTexParameterfv(GLenum target, GLenum pname, GLfloat* params) {
    orig_glGetTexParameterfv(target, pname, params);
    printf("/*#fishhook#**/ {GLfloat params[] = {...}; glGetTexParameterfv(0x%04x, 0x%04x, params));}\n", target, pname);
}

static void (*orig_glGetTexParameteriv)(GLenum target, GLenum pname, GLint* params);
void wrap_glGetTexParameteriv(GLenum target, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetTexParameteriv(0x%04x, 0x%04x, [%d]));\n", target, pname, ((int*)params)[0]);
    orig_glGetTexParameteriv(target, pname, params);
}

static void (*orig_glGetUniformfv)(GLuint program, GLint location, GLfloat* params);
void wrap_glGetUniformfv(GLuint program, GLint location, GLfloat* params) {
    printf("/*#fishhook#**/ {GLfloat params[] = {...}; glGetUniformfv(%d, %d, params));}\n", program, location);
    orig_glGetUniformfv(program, location, params);
}

static void (*orig_glGetUniformiv)(GLuint program, GLint location, GLint* params);
void wrap_glGetUniformiv(GLuint program, GLint location, GLint* params) {
    printf("/*#fishhook#**/ glGetUniformiv(%d, %d, [%d]));\n", program, location, ((int*)params)[0]);
    orig_glGetUniformiv(program, location, params);
}

static int (*orig_glGetUniformLocation)(GLuint program, const GLchar* name);
int wrap_glGetUniformLocation(GLuint program, const GLchar* name) {
    int ret = orig_glGetUniformLocation(program, name);
    printf("/*#fishhook#**/ glGetUniformLocation(%d, \"%s\"));// = %d\n", program, name, ret);
    return ret;
}

static void (*orig_glGetVertexAttribfv)(GLuint index, GLenum pname, GLfloat* params);
void wrap_glGetVertexAttribfv(GLuint index, GLenum pname, GLfloat* params) {
    printf("/*#fishhook#**/ {GLfloat params[] = {...}; glGetVertexAttribfv(%d, 0x%04x, params));\n", index, pname);
    orig_glGetVertexAttribfv(index, pname, params);
}

static void (*orig_glGetVertexAttribiv)(GLuint index, GLenum pname, GLint* params);
void wrap_glGetVertexAttribiv(GLuint index, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetVertexAttribiv(%d, 0x%04x, [%d]));\n", index, pname, ((int*)params)[0]);
    orig_glGetVertexAttribiv(index, pname, params);
}

static void (*orig_glGetVertexAttribPointerv)(GLuint index, GLenum pname, GLvoid** pointer);
void wrap_glGetVertexAttribPointerv(GLuint index, GLenum pname, GLvoid** pointer) {
    printf("/*#fishhook#**/ glGetVertexAttribPointerv(%d, 0x%04x, [0x%04x]));\n", index, pname, ((int*)pointer)[0]);
    orig_glGetVertexAttribPointerv(index, pname, pointer);
}

static void (*orig_glHint)(GLenum target, GLenum mode);
void wrap_glHint(GLenum target, GLenum mode) {
    printf("/*#fishhook#**/ glHint(0x%04x, 0x%04x));\n", target, mode);
    orig_glHint(target, mode);
}

static GLboolean (*orig_glIsBuffer)(GLuint buffer);
GLboolean wrap_glIsBuffer(GLuint buffer) {
    printf("/*#fishhook#**/ glIsBuffer(%d));\n", buffer);
    return orig_glIsBuffer(buffer);
}

static GLboolean (*orig_glIsEnabled)(GLenum cap);
GLboolean wrap_glIsEnabled(GLenum cap) {
    printf("/*#fishhook#**/ glIsEnabled(0x%04x));\n", cap);
    return orig_glIsEnabled(cap);
}

static GLboolean (*orig_glIsFramebuffer)(GLuint framebuffer);
GLboolean wrap_glIsFramebuffer(GLuint framebuffer) {
    printf("/*#fishhook#**/ glIsFramebuffer(%d));\n", framebuffer);
    return orig_glIsFramebuffer(framebuffer);
}

static GLboolean (*orig_glIsProgram)(GLuint program);
GLboolean wrap_glIsProgram(GLuint program) {
    printf("/*#fishhook#**/ glIsProgram(%d));\n", program);
    return orig_glIsProgram(program);
}

static GLboolean (*orig_glIsRenderbuffer)(GLuint renderbuffer);
GLboolean wrap_glIsRenderbuffer(GLuint renderbuffer) {
    printf("/*#fishhook#**/ glIsRenderbuffer(%d));\n", renderbuffer);
    return orig_glIsRenderbuffer(renderbuffer);
}

static GLboolean (*orig_glIsShader)(GLuint shader);
GLboolean wrap_glIsShader(GLuint shader) {
    printf("/*#fishhook#**/ glIsShader(%d));\n", shader);
    return orig_glIsShader(shader);
}

static GLboolean (*orig_glIsTexture)(GLuint texture);
GLboolean wrap_glIsTexture(GLuint texture) {
    printf("/*#fishhook#**/ glIsTexture(%d));\n", texture);
    return orig_glIsTexture(texture);
}

static void (*orig_glLineWidth)(GLfloat width);
void wrap_glLineWidth(GLfloat width) {
    printf("/*#fishhook#**/ glLineWidth(%f));\n", width);
    orig_glLineWidth(width);
}

static void (*orig_glLinkProgram)(GLuint program);
void wrap_glLinkProgram(GLuint program) {
    printf("/*#fishhook#**/ glLinkProgram(%d));\n", program);
    orig_glLinkProgram(program);
}

static void (*orig_glPixelStorei)(GLenum pname, GLint param);
void wrap_glPixelStorei(GLenum pname, GLint param) {
    printf("/*#fishhook#**/ glPixelStorei(0x%04x, %d));\n", pname, param);
    orig_glPixelStorei(pname, param);
}

static void (*orig_glPolygonOffset)(GLfloat factor, GLfloat units);
void wrap_glPolygonOffset(GLfloat factor, GLfloat units) {
    printf("/*#fishhook#**/ glPolygonOffset(%f, %f));\n", factor, units);
    orig_glPolygonOffset(factor, units);
}

static void (*orig_glReadPixels)(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid* pixels);
void wrap_glReadPixels(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid* pixels) {
    printf("/*#fishhook#**/ glReadPixels(%d, %d, %d, %d, 0x%04x, 0x%04x, [0x%04x]));\n", x, y, width, height, format, type, ((int*)pixels)[0]);
    orig_glReadPixels(x, y, width, height, format, type, pixels);
}

static void (*orig_glReleaseShaderCompiler)(void);
void wrap_glReleaseShaderCompiler(void) {
    printf("/*#fishhook#**/ glReleaseShaderCompiler(");
    orig_glReleaseShaderCompiler();
}

static void (*orig_glRenderbufferStorage)(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
void wrap_glRenderbufferStorage(GLenum target, GLenum internalformat, GLsizei width, GLsizei height) {
    printf("/*#fishhook#**/ glRenderbufferStorage(0x%04x, 0x%04x, %d, %d));\n", target, internalformat, width, height);
    orig_glRenderbufferStorage(target, internalformat, width, height);
}

static void (*orig_glSampleCoverage)(GLclampf value, GLboolean invert);
void wrap_glSampleCoverage(GLclampf value, GLboolean invert) {
    printf("/*#fishhook#**/ glSampleCoverage(%f, %d));\n", value, invert);
    orig_glSampleCoverage(value, invert);
}

static void (*orig_glScissor)(GLint x, GLint y, GLsizei width, GLsizei height);
void wrap_glScissor(GLint x, GLint y, GLsizei width, GLsizei height) {
    printf("/*#fishhook#**/ glScissor(%d, %d, %d, %d));\n", x, y, width, height);
    orig_glScissor(x, y, width, height);
}

static void (*orig_glShaderBinary)(GLsizei n, const GLuint* shaders, GLenum binaryformat, const GLvoid* binary, GLsizei length);
void wrap_glShaderBinary(GLsizei n, const GLuint* shaders, GLenum binaryformat, const GLvoid* binary, GLsizei length) {
    printf("/*#fishhook#**/ glShaderBinary(%d, [%d], 0x%04x, [0x%04x], %d));\n", n, ((int*)shaders)[0], binaryformat, ((int*)binary)[0], length);
    orig_glShaderBinary(n, shaders, binaryformat, binary, length);
}

static void (*orig_glShaderSource)(GLuint shader, GLsizei count, const GLchar* const *string, const GLint* length);
void wrap_glShaderSource(GLuint shader, GLsizei count, const GLchar* const *string, const GLint* length) {
    printf("/*#fishhook#**/ {const GLchar* string[] = {\n");
    for (int i = 0; i < count; ++i)
    {
        printf("\"%s\",\n", string[i]);
    }
    printf("};\nconst GLint length[] = {");
    for (int i = 0; i < count; ++i)
    {
        printf("%d, ", NULL == length ? (int)strlen(string[i]) : length[i]);
    }
    printf("}\nglShaderSource(%d, %d, string, length);}\n", shader, count);
    orig_glShaderSource(shader, count, string, length);
}

static void (*orig_glStencilFunc)(GLenum func, GLint ref, GLuint mask);
void wrap_glStencilFunc(GLenum func, GLint ref, GLuint mask) {
    printf("/*#fishhook#**/ glStencilFunc(0x%04x, %d, %d));\n", func, ref, mask);
    orig_glStencilFunc(func, ref, mask);
}

static void (*orig_glStencilFuncSeparate)(GLenum face, GLenum func, GLint ref, GLuint mask);
void wrap_glStencilFuncSeparate(GLenum face, GLenum func, GLint ref, GLuint mask) {
    printf("/*#fishhook#**/ glStencilFuncSeparate(0x%04x, 0x%04x, %d, %d));\n", face, func, ref, mask);
    orig_glStencilFuncSeparate(face, func, ref, mask);
}

static void (*orig_glStencilMask)(GLuint mask);
void wrap_glStencilMask(GLuint mask) {
    printf("/*#fishhook#**/ glStencilMask(%d));\n", mask);
    orig_glStencilMask(mask);
}

static void (*orig_glStencilMaskSeparate)(GLenum face, GLuint mask);
void wrap_glStencilMaskSeparate(GLenum face, GLuint mask) {
    printf("/*#fishhook#**/ glStencilMaskSeparate(0x%04x, %d));\n", face, mask);
    orig_glStencilMaskSeparate(face, mask);
}

static void (*orig_glStencilOp)(GLenum fail, GLenum zfail, GLenum zpass);
void wrap_glStencilOp(GLenum fail, GLenum zfail, GLenum zpass) {
    printf("/*#fishhook#**/ glStencilOp(0x%04x, 0x%04x, 0x%04x));\n", fail, zfail, zpass);
    orig_glStencilOp(fail, zfail, zpass);
}

static void (*orig_glStencilOpSeparate)(GLenum face, GLenum fail, GLenum zfail, GLenum zpass);
void wrap_glStencilOpSeparate(GLenum face, GLenum fail, GLenum zfail, GLenum zpass) {
    printf("/*#fishhook#**/ glStencilOpSeparate(0x%04x, 0x%04x, 0x%04x, 0x%04x));\n", face, fail, zfail, zpass);
    orig_glStencilOpSeparate(face, fail, zfail, zpass);
}

static void (*orig_glTexImage2D)(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid* pixels);
void wrap_glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid* pixels) {
//    if (width == 375)
//    {///!!!For Debug: -
//        width = 281;
//        height = 158;
//    }
    printf("/*#fishhook#**/ glTexImage2D(0x%04x, %d, 0x%04x, %d, %d, %d, 0x%04x, 0x%04x, 0x%lx));\n", target, level, internalformat, width, height, border, format, type, (long)pixels);
    orig_glTexImage2D(target, level, internalformat, width, height, border, format, type, pixels);
}

static void (*orig_glTexParameterf)(GLenum target, GLenum pname, GLfloat param);
void wrap_glTexParameterf(GLenum target, GLenum pname, GLfloat param) {
    printf("/*#fishhook#**/ glTexParameterf(0x%04x, 0x%04x, %f));\n", target, pname, param);
    orig_glTexParameterf(target, pname, param);
}

static void (*orig_glTexParameterfv)(GLenum target, GLenum pname, const GLfloat* params);
void wrap_glTexParameterfv(GLenum target, GLenum pname, const GLfloat* params) {
    printf("/*#fishhook#**/ {GLfloat params[] = {...}; glTexParameterfv(0x%04x, 0x%04x, params));}\n", target, pname);
    orig_glTexParameterfv(target, pname, params);
}

static void (*orig_glTexParameteri)(GLenum target, GLenum pname, GLint param);
void wrap_glTexParameteri(GLenum target, GLenum pname, GLint param) {
    printf("/*#fishhook#**/ glTexParameteri(0x%04x, 0x%04x, 0x%04x));\n", target, pname, param);
    orig_glTexParameteri(target, pname, param);
}

static void (*orig_glTexParameteriv)(GLenum target, GLenum pname, const GLint* params);
void wrap_glTexParameteriv(GLenum target, GLenum pname, const GLint* params) {
    printf("/*#fishhook#**/ glTexParameteriv(0x%04x, 0x%04x, [0x%04x]));\n", target, pname, ((int*)params)[0]);
    orig_glTexParameteriv(target, pname, params);
}

static void (*orig_glTexSubImage2D)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid* pixels);
void wrap_glTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid* pixels) {
    printf("/*#fishhook#**/ glTexSubImage2D(0x%04x, %d, %d, %d, %d, %d, 0x%04x, 0x%04x, [0x%04x]));\n", target, level, xoffset, yoffset, width, height, format, type, ((int*)pixels)[0]);
    orig_glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
}

static void (*orig_glUniform1f)(GLint location, GLfloat x);
void wrap_glUniform1f(GLint location, GLfloat x) {
    printf("/*#fishhook#**/ glUniform1f(%d, %f));\n", location, x);
    orig_glUniform1f(location, x);
}

static void (*orig_glUniform1fv)(GLint location, GLsizei count, const GLfloat* v);
void wrap_glUniform1fv(GLint location, GLsizei count, const GLfloat* v) {
    orig_glUniform1fv(location, count, v);
    printf("/*#fishhook#**/ {GLfloat v[] = {%f}; glUniform1fv(%d, %d, v));}\n", v[0], location, count);
}

static void (*orig_glUniform1i)(GLint location, GLint x);
void wrap_glUniform1i(GLint location, GLint x) {
    printf("/*#fishhook#**/ glUniform1i(%d, %d));\n", location, x);
    orig_glUniform1i(location, x);
}

static void (*orig_glUniform1iv)(GLint location, GLsizei count, const GLint* v);
void wrap_glUniform1iv(GLint location, GLsizei count, const GLint* v) {
    orig_glUniform1iv(location, count, v);
    printf("/*#fishhook#**/ {GLint v[] = {%d}; glUniform1iv(%d, %d, v));}\n", (int)v[0], location, count);
}

static void (*orig_glUniform2f)(GLint location, GLfloat x, GLfloat y);
void wrap_glUniform2f(GLint location, GLfloat x, GLfloat y) {
    printf("/*#fishhook#**/ glUniform2f(%d, %f, %f));\n", location, x, y);
    orig_glUniform2f(location, x, y);
}

static void (*orig_glUniform2fv)(GLint location, GLsizei count, const GLfloat* v);
void wrap_glUniform2fv(GLint location, GLsizei count, const GLfloat* v) {
    orig_glUniform2fv(location, count, v);
    printf("/*#fishhook#**/ {GLfloat v[] = {%f, %f}; glUniform2fv(%d, %d, v));}\n", v[0], v[1], location, count);
}

static void (*orig_glUniform2i)(GLint location, GLint x, GLint y);
void wrap_glUniform2i(GLint location, GLint x, GLint y) {
    printf("/*#fishhook#**/ glUniform2i(%d, %d, %d));\n", location, x, y);
    orig_glUniform2i(location, x, y);
}

static void (*orig_glUniform2iv)(GLint location, GLsizei count, const GLint* v);
void wrap_glUniform2iv(GLint location, GLsizei count, const GLint* v) {
    orig_glUniform2iv(location, count, v);
    printf("/*#fishhook#**/ {GLint v[] = {%d, %d}; glUniform2iv(%d, %d, v));}\n", v[0], v[1], location, count);
}

static void (*orig_glUniform3f)(GLint location, GLfloat x, GLfloat y, GLfloat z);
void wrap_glUniform3f(GLint location, GLfloat x, GLfloat y, GLfloat z) {
//    x = 281.0; y = 158.0; z = 1.0;///!!!For Debug: -
    printf("/*#fishhook#**/ glUniform3f(%d, %f, %f, %f));\n", location, x, y, z);
    orig_glUniform3f(location, x, y, z);
}

static void (*orig_glUniform3fv)(GLint location, GLsizei count, const GLfloat* v);
void wrap_glUniform3fv(GLint location, GLsizei count, const GLfloat* v) {
//    GLfloat dbgV[] = {281.000000, 158.000000, 1.000000};///!!!For Debug: -
    orig_glUniform3fv(location, count, v);
    printf("/*#fishhook#**/ {GLfloat v[] = {%f, %f, %f}; glUniform3fv(%d, %d, v));}\n", v[0], v[1], v[2], location, count);
}

static void (*orig_glUniform3i)(GLint location, GLint x, GLint y, GLint z);
void wrap_glUniform3i(GLint location, GLint x, GLint y, GLint z) {
    printf("/*#fishhook#**/ glUniform3i(%d, %d, %d, %d));\n", location, x, y, z);
    orig_glUniform3i(location, x, y, z);
}

static void (*orig_glUniform3iv)(GLint location, GLsizei count, const GLint* v);
void wrap_glUniform3iv(GLint location, GLsizei count, const GLint* v) {
    orig_glUniform3iv(location, count, v);
    printf("/*#fishhook#**/ {GLint v[] = {%d, %d, %d}; glUniform3iv(%d, %d, v));}\n", v[0], v[1], v[2], location, count);
}

static void (*orig_glUniform4f)(GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
void wrap_glUniform4f(GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w) {
    printf("/*#fishhook#**/ glUniform4f(%d, %f, %f, %f, %f));\n", location, x, y, z, w);
    orig_glUniform4f(location, x, y, z, w);
}

static void (*orig_glUniform4fv)(GLint location, GLsizei count, const GLfloat* v);
void wrap_glUniform4fv(GLint location, GLsizei count, const GLfloat* v) {
    orig_glUniform4fv(location, count, v);
    printf("/*#fishhook#**/ {GLfloat v[] = {%f, %f, %f, %f}; glUniform4fv(%d, %d, v));}\n", v[0], v[1], v[2], v[3], location, count);
}

static void (*orig_glUniform4i)(GLint location, GLint x, GLint y, GLint z, GLint w);
void wrap_glUniform4i(GLint location, GLint x, GLint y, GLint z, GLint w) {
    printf("/*#fishhook#**/ glUniform4i(%d, %d, %d, %d, %d));\n", location, x, y, z, w);
    orig_glUniform4i(location, x, y, z, w);
}

static void (*orig_glUniform4iv)(GLint location, GLsizei count, const GLint* v);
void wrap_glUniform4iv(GLint location, GLsizei count, const GLint* v) {
    orig_glUniform4iv(location, count, v);
    printf("/*#fishhook#**/ {GLint v[] = {%d, %d, %d, %d}; glUniform4iv(%d, %d, v));}\n", v[0], v[1], v[2], v[3], location, count);
}

static void (*orig_glUniformMatrix2fv)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
void wrap_glUniformMatrix2fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {
    orig_glUniformMatrix2fv(location, count, transpose, value);
    printf("/*#fishhook#**/ {GLint v[] = {%f", value[0]);
    for (int i = 1; i < 4; ++i)
    {
        printf(", %f", value[i]);
    }
    printf("}; glUniformMatrix2fv(%d, %d, %d, value));}\n", location, count, transpose);
}

static void (*orig_glUniformMatrix3fv)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
void wrap_glUniformMatrix3fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {
    orig_glUniformMatrix3fv(location, count, transpose, value);
    printf("/*#fishhook#**/ {GLint v[] = {%f", value[0]);
    for (int i = 1; i < 9; ++i)
    {
        printf(", %f", value[i]);
    }
    printf("}; glUniformMatrix3fv(%d, %d, %d, value));}\n", location, count, transpose);
}

static void (*orig_glUniformMatrix4fv)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
void wrap_glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {
    orig_glUniformMatrix4fv(location, count, transpose, value);
    printf("/*#fishhook#**/ {GLint v[] = {%f", value[0]);
    for (int i = 1; i < 16; ++i)
    {
        printf(", %f", value[i]);
    }
    printf("}; glUniformMatrix4fv(%d, %d, %d, value));}\n", location, count, transpose);
}

static void (*orig_glUseProgram)(GLuint program);
void wrap_glUseProgram(GLuint program) {
    printf("/*#fishhook#**/ glUseProgram(%d));\n", program);
    orig_glUseProgram(program);
}

static void (*orig_glValidateProgram)(GLuint program);
void wrap_glValidateProgram(GLuint program) {
    printf("/*#fishhook#**/ glValidateProgram(%d));\n", program);
    orig_glValidateProgram(program);
}

static void (*orig_glVertexAttrib1f)(GLuint indx, GLfloat x);
void wrap_glVertexAttrib1f(GLuint indx, GLfloat x) {
    printf("/*#fishhook#**/ glVertexAttrib1f(%d, %f));\n", indx, x);
    orig_glVertexAttrib1f(indx, x);
}

static void (*orig_glVertexAttrib1fv)(GLuint indx, const GLfloat* values);
void wrap_glVertexAttrib1fv(GLuint indx, const GLfloat* values) {
    printf("/*#fishhook#**/ {GLfloat values[] = {%f}; glVertexAttrib1fv(%d, values));}\n", values[0], indx);
    orig_glVertexAttrib1fv(indx, values);
}

static void (*orig_glVertexAttrib2f)(GLuint indx, GLfloat x, GLfloat y);
void wrap_glVertexAttrib2f(GLuint indx, GLfloat x, GLfloat y) {
    printf("/*#fishhook#**/ glVertexAttrib2f(%d, %f, %f));\n", indx, x, y);
    orig_glVertexAttrib2f(indx, x, y);
}

static void (*orig_glVertexAttrib2fv)(GLuint indx, const GLfloat* values);
void wrap_glVertexAttrib2fv(GLuint indx, const GLfloat* values) {
    printf("/*#fishhook#**/ {GLfloat values[] = {%f, %f}; glVertexAttrib2fv(%d, values));}\n", values[0], values[1], indx);
    orig_glVertexAttrib2fv(indx, values);
}

static void (*orig_glVertexAttrib3f)(GLuint indx, GLfloat x, GLfloat y, GLfloat z);
void wrap_glVertexAttrib3f(GLuint indx, GLfloat x, GLfloat y, GLfloat z) {
    printf("/*#fishhook#**/ glVertexAttrib3f(%d, %f, %f, %f));\n", indx, x, y, z);
    orig_glVertexAttrib3f(indx, x, y, z);
}

static void (*orig_glVertexAttrib3fv)(GLuint indx, const GLfloat* values);
void wrap_glVertexAttrib3fv(GLuint indx, const GLfloat* values) {
    printf("/*#fishhook#**/ {GLfloat values[] = {%f, %f, %f}; glVertexAttrib3fv(%d, values));}\n", values[0], values[1], values[2], indx);
    orig_glVertexAttrib3fv(indx, values);
}

static void (*orig_glVertexAttrib4f)(GLuint indx, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
void wrap_glVertexAttrib4f(GLuint indx, GLfloat x, GLfloat y, GLfloat z, GLfloat w) {
    printf("/*#fishhook#**/ glVertexAttrib4f(%d, %f, %f, %f, %f));\n", indx, x, y, z, w);
    orig_glVertexAttrib4f(indx, x, y, z, w);
}

static void (*orig_glVertexAttrib4fv)(GLuint indx, const GLfloat* values);
void wrap_glVertexAttrib4fv(GLuint indx, const GLfloat* values) {
    printf("/*#fishhook#**/ {GLfloat values[] = {%f, %f, %f, %f}; glVertexAttrib4fv(%d, values));}\n", values[0], values[1], values[2], values[3], indx);
    orig_glVertexAttrib4fv(indx, values);
}

static void (*orig_glVertexAttribPointer)(GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr);
void wrap_glVertexAttribPointer(GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr) {
    printf("/*#fishhook#**/ glVertexAttribPointer(%d, %d, 0x%04x, 0x%04x, %d, 0x%lx));\n", indx, size, type, normalized, stride, (long)ptr);
    orig_glVertexAttribPointer(indx, size, type, normalized, stride, ptr);
}

static void (*orig_glViewport)(GLint x, GLint y, GLsizei width, GLsizei height);
void wrap_glViewport(GLint x, GLint y, GLsizei width, GLsizei height) {
//    if (width == 375)
//    {///!!!For Debug: -
//        width = 281;
//        height = 158;
//    }
    printf("/*#fishhook#**/ glViewport(%d, %d, %d, %d));\n", x, y, width, height);
    orig_glViewport(x, y, width, height);
}

static void (*orig_glReadBuffer)(GLenum mode);
void wrap_glReadBuffer(GLenum mode) {
    printf("/*#fishhook#**/ glReadBuffer(0x%04x));\n", mode);
    orig_glReadBuffer(mode);
}

static void (*orig_glDrawRangeElements)(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid* indices);
void wrap_glDrawRangeElements(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid* indices) {
    printf("/*#fishhook#**/ glDrawRangeElements(0x%04x, %d, %d, %d, 0x%04x, [0x%04x]));\n", mode, start, end, count, type, ((int*)indices)[0]);
    orig_glDrawRangeElements(mode, start, end, count, type, indices);
}

static void (*orig_glTexImage3D)(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid* pixels);
void wrap_glTexImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid* pixels) {
    printf("/*#fishhook#**/ glTexImage3D(0x%04x, %d, %d, %d, %d, %d, %d, 0x%04x, 0x%04x, [0x%04x]));\n", target, level, internalformat, width, height, depth, border, format, type, ((int*)pixels)[0]);
    orig_glTexImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels);
}

static void (*orig_glTexSubImage3D)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid* pixels);
void wrap_glTexSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid* pixels) {
    printf("/*#fishhook#**/ glTexSubImage3D(0x%04x, %d, %d, %d, %d, %d, %d, %d, 0x%04x, 0x%04x, [0x%04x]));\n", target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, ((int*)pixels)[0]);
    orig_glTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
}

static void (*orig_glCopyTexSubImage3D)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);
void wrap_glCopyTexSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height) {
    printf("/*#fishhook#**/ glCopyTexSubImage3D(0x%04x, %d, %d, %d, %d, %d, %d, %d, %d));\n", target, level, xoffset, yoffset, zoffset, x, y, width, height);
    orig_glCopyTexSubImage3D(target, level, xoffset, yoffset, zoffset, x, y, width, height);
}

static void (*orig_glCompressedTexImage3D)(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid* data);
void wrap_glCompressedTexImage3D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid* data) {
    printf("/*#fishhook#**/ glCompressedTexImage3D(0x%04x, %d, 0x%04x, %d, %d, %d, %d, %d, [0x%04x]));\n", target, level, internalformat, width, height, depth, border, imageSize, ((int*)data)[0]);
    orig_glCompressedTexImage3D(target, level, internalformat, width, height, depth, border, imageSize, data);
}

static void (*orig_glCompressedTexSubImage3D)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid* data);
void wrap_glCompressedTexSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid* data) {
    printf("/*#fishhook#**/ glCompressedTexSubImage3D(0x%04x, %d, %d, %d, %d, %d, %d, %d, 0x%04x, %d, [0x%04x]));\n", target, level, xoffset, yoffset, zoffset, width, height, depth, format, imageSize, ((int*)data)[0]);
    orig_glCompressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, imageSize, data);
}

static void (*orig_glGenQueries)(GLsizei n, GLuint* ids);
void wrap_glGenQueries(GLsizei n, GLuint* ids) {
    printf("/*#fishhook#**/ glGenQueries(%d, [%d]));\n", n, ((int*)ids)[0]);
    orig_glGenQueries(n, ids);
}

static void (*orig_glDeleteQueries)(GLsizei n, const GLuint* ids);
void wrap_glDeleteQueries(GLsizei n, const GLuint* ids) {
    printf("/*#fishhook#**/ glDeleteQueries(%d, [%d]));\n", n, ((int*)ids)[0]);
    orig_glDeleteQueries(n, ids);
}

static GLboolean (*orig_glIsQuery)(GLuint id);
GLboolean wrap_glIsQuery(GLuint id) {
    printf("/*#fishhook#**/ glIsQuery(%d));\n", id);
    return orig_glIsQuery(id);
}

static void (*orig_glBeginQuery)(GLenum target, GLuint id);
void wrap_glBeginQuery(GLenum target, GLuint id) {
    printf("/*#fishhook#**/ glBeginQuery(0x%04x, %d));\n", target, id);
    orig_glBeginQuery(target, id);
}

static void (*orig_glEndQuery)(GLenum target);
void wrap_glEndQuery(GLenum target) {
    printf("/*#fishhook#**/ glEndQuery(0x%04x));\n", target);
    orig_glEndQuery(target);
}

static void (*orig_glGetQueryiv)(GLenum target, GLenum pname, GLint* params);
void wrap_glGetQueryiv(GLenum target, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetQueryiv(0x%04x, 0x%04x, [%d]));\n", target, pname, ((int*)params)[0]);
    orig_glGetQueryiv(target, pname, params);
}

static void (*orig_glGetQueryObjectuiv)(GLuint id, GLenum pname, GLuint* params);
void wrap_glGetQueryObjectuiv(GLuint id, GLenum pname, GLuint* params) {
    printf("/*#fishhook#**/ glGetQueryObjectuiv(%d, 0x%04x, [%d]));\n", id, pname, ((int*)params)[0]);
    orig_glGetQueryObjectuiv(id, pname, params);
}

static GLboolean (*orig_glUnmapBuffer)(GLenum target);
GLboolean wrap_glUnmapBuffer(GLenum target) {
    printf("/*#fishhook#**/ glUnmapBuffer(0x%04x));\n", target);
    return orig_glUnmapBuffer(target);
}

static void (*orig_glGetBufferPointerv)(GLenum target, GLenum pname, GLvoid** params);
void wrap_glGetBufferPointerv(GLenum target, GLenum pname, GLvoid** params) {
    printf("/*#fishhook#**/ glGetBufferPointerv(0x%04x, 0x%04x, [0x%04x]));\n", target, pname, ((int*)params)[0]);
    orig_glGetBufferPointerv(target, pname, params);
}

static void (*orig_glDrawBuffers)(GLsizei n, const GLenum* bufs);
void wrap_glDrawBuffers(GLsizei n, const GLenum* bufs) {
    printf("/*#fishhook#**/ glDrawBuffers(%d, [0x%04x]));\n", n, ((int*)bufs)[0]);
    orig_glDrawBuffers(n, bufs);
}

static void (*orig_glUniformMatrix2x3fv)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
void wrap_glUniformMatrix2x3fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {
    printf("/*#fishhook#**/ {GLfloat value[] = {%f", value[0]);
    for (int i = 1; i < 6; ++i)
    {
        printf(", %f", value[i]);
    }
    printf("}; glUniformMatrix2x3fv(%d, %d, %d, value));}\n", location, count, transpose);
    orig_glUniformMatrix2x3fv(location, count, transpose, value);
}

static void (*orig_glUniformMatrix3x2fv)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
void wrap_glUniformMatrix3x2fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {
    printf("/*#fishhook#**/ {GLfloat value[] = {%f", value[0]);
    for (int i = 1; i < 6; ++i)
    {
        printf(", %f", value[i]);
    }
    printf("}; glUniformMatrix3x2fv(%d, %d, %d, value));}\n", location, count, transpose);
    orig_glUniformMatrix3x2fv(location, count, transpose, value);
}

static void (*orig_glUniformMatrix2x4fv)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
void wrap_glUniformMatrix2x4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {
    printf("/*#fishhook#**/ {GLfloat value[] = {%f", value[0]);
    for (int i = 1; i < 8; ++i)
    {
        printf(", %f", value[i]);
    }
    printf("}; glUniformMatrix2x4fv(%d, %d, %d, value));}\n", location, count, transpose);
    orig_glUniformMatrix2x4fv(location, count, transpose, value);
}

static void (*orig_glUniformMatrix4x2fv)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
void wrap_glUniformMatrix4x2fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {
    printf("/*#fishhook#**/ {GLfloat value[] = {%f", value[0]);
    for (int i = 1; i < 8; ++i)
    {
        printf(", %f", value[i]);
    }
    printf("}; glUniformMatrix4x2fv(%d, %d, %d, value));}\n", location, count, transpose);
    orig_glUniformMatrix4x2fv(location, count, transpose, value);
}

static void (*orig_glUniformMatrix3x4fv)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
void wrap_glUniformMatrix3x4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {
    printf("/*#fishhook#**/ {GLfloat value[] = {%f", value[0]);
    for (int i = 1; i < 12; ++i)
    {
        printf(", %f", value[i]);
    }
    printf("}; glUniformMatrix3x4fv(%d, %d, %d, value));}\n", location, count, transpose);
    orig_glUniformMatrix3x4fv(location, count, transpose, value);
}

static void (*orig_glUniformMatrix4x3fv)(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
void wrap_glUniformMatrix4x3fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {
    printf("/*#fishhook#**/ {GLfloat value[] = {%f", value[0]);
    for (int i = 1; i < 12; ++i)
    {
        printf(", %f", value[i]);
    }
    printf("}; glUniformMatrix4x3fv(%d, %d, %d, value));}\n", location, count, transpose);
    orig_glUniformMatrix4x3fv(location, count, transpose, value);
}

static void (*orig_glBlitFramebuffer)(GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
void wrap_glBlitFramebuffer(GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter) {
    printf("/*#fishhook#**/ glBlitFramebuffer(%d, %d, %d, %d, %d, %d, %d, %d, %d, 0x%04x));\n", srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
    orig_glBlitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
}

static void (*orig_glRenderbufferStorageMultisample)(GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
void wrap_glRenderbufferStorageMultisample(GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height) {
    printf("/*#fishhook#**/ glRenderbufferStorageMultisample(0x%04x, %d, 0x%04x, %d, %d));\n", target, samples, internalformat, width, height);
    orig_glRenderbufferStorageMultisample(target, samples, internalformat, width, height);
}

static void (*orig_glFramebufferTextureLayer)(GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);
void wrap_glFramebufferTextureLayer(GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer) {
    printf("/*#fishhook#**/ glFramebufferTextureLayer(0x%04x, 0x%04x, %d, %d, %d));\n", target, attachment, texture, level, layer);
    orig_glFramebufferTextureLayer(target, attachment, texture, level, layer);
}

static GLvoid* (*orig_glMapBufferRange)(GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access);
GLvoid* wrap_glMapBufferRange(GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access) {
    printf("/*#fishhook#**/ glMapBufferRange(0x%04x, %d, %d, %d));\n", target, (int)offset, (int)length, access);
    return orig_glMapBufferRange(target, offset, length, access);
}

static void (*orig_glFlushMappedBufferRange)(GLenum target, GLintptr offset, GLsizeiptr length);
void wrap_glFlushMappedBufferRange(GLenum target, GLintptr offset, GLsizeiptr length) {
    printf("/*#fishhook#**/ glFlushMappedBufferRange(0x%04x, %d, %d));\n", target, (int)offset, (int)length);
    orig_glFlushMappedBufferRange(target, offset, length);
}

static void (*orig_glBindVertexArray)(GLuint array);
void wrap_glBindVertexArray(GLuint array) {
    printf("/*#fishhook#**/ glBindVertexArray(%d));\n", array);
    orig_glBindVertexArray(array);
}

static void (*orig_glDeleteVertexArrays)(GLsizei n, const GLuint* arrays);
void wrap_glDeleteVertexArrays(GLsizei n, const GLuint* arrays) {
    printf("/*#fishhook#**/ glDeleteVertexArrays(%d, [%d]));\n", n, ((int*)arrays)[0]);
    orig_glDeleteVertexArrays(n, arrays);
}

static void (*orig_glGenVertexArrays)(GLsizei n, GLuint* arrays);
void wrap_glGenVertexArrays(GLsizei n, GLuint* arrays) {
    orig_glGenVertexArrays(n, arrays);
    printf("/*#fishhook#**/ {GLuint arrays[] = {");
    for (int i = 0; i < n; ++i)
    {
        printf("%d, ", arrays[i]);
    }
    printf("}; glGenVertexArrays(%d, arrays));}\n", n);
}

static GLboolean (*orig_glIsVertexArray)(GLuint array);
GLboolean wrap_glIsVertexArray(GLuint array) {
    printf("/*#fishhook#**/ glIsVertexArray(%d));\n", array);
    return orig_glIsVertexArray(array);
}

static void (*orig_glGetIntegeri_v)(GLenum target, GLuint index, GLint* data);
void wrap_glGetIntegeri_v(GLenum target, GLuint index, GLint* data) {
    printf("/*#fishhook#**/ glGetIntegeri_v(0x%04x, %d, [%d]));\n", target, index, ((int*)data)[0]);
    orig_glGetIntegeri_v(target, index, data);
}

static void (*orig_glBeginTransformFeedback)(GLenum primitiveMode);
void wrap_glBeginTransformFeedback(GLenum primitiveMode) {
    printf("/*#fishhook#**/ glBeginTransformFeedback(0x%04x));\n", primitiveMode);
    orig_glBeginTransformFeedback(primitiveMode);
}

static void (*orig_glEndTransformFeedback)(void);
void wrap_glEndTransformFeedback(void) {
    printf("/*#fishhook#**/ glEndTransformFeedback(");
    orig_glEndTransformFeedback();
}

static void (*orig_glBindBufferRange)(GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
void wrap_glBindBufferRange(GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size) {
    printf("/*#fishhook#**/ glBindBufferRange(0x%04x, %d, %d, %d, %d));\n", target, index, buffer, (int)offset, (int)size);
    orig_glBindBufferRange(target, index, buffer, offset, size);
}

static void (*orig_glBindBufferBase)(GLenum target, GLuint index, GLuint buffer);
void wrap_glBindBufferBase(GLenum target, GLuint index, GLuint buffer) {
    printf("/*#fishhook#**/ glBindBufferBase(0x%04x, %d, %d));\n", target, index, buffer);
    orig_glBindBufferBase(target, index, buffer);
}

static void (*orig_glTransformFeedbackVaryings)(GLuint program, GLsizei count, const GLchar* const *varyings, GLenum bufferMode);
void wrap_glTransformFeedbackVaryings(GLuint program, GLsizei count, const GLchar* const *varyings, GLenum bufferMode) {
    printf("/*#fishhook#**/ glTransformFeedbackVaryings(%d, %d, [%d], 0x%04x));\n", program, count, ((int*)varyings)[0], bufferMode);
    orig_glTransformFeedbackVaryings(program, count, varyings, bufferMode);
}

static void (*orig_glGetTransformFeedbackVarying)(GLuint program, GLuint index, GLsizei bufSize, GLsizei* length, GLsizei* size, GLenum* type, GLchar* name);
void wrap_glGetTransformFeedbackVarying(GLuint program, GLuint index, GLsizei bufSize, GLsizei* length, GLsizei* size, GLenum* type, GLchar* name) {
    printf("/*#fishhook#**/ glGetTransformFeedbackVarying(%d, %d, %d, [%d], [%d], [0x%04x], [[0x%04x]]));\n", program, index, bufSize, ((int*)length)[0], ((int*)size)[0], ((int*)type)[0], ((int*)name)[0]);
    orig_glGetTransformFeedbackVarying(program, index, bufSize, length, size, type, name);
}

static void (*orig_glVertexAttribIPointer)(GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid* pointer);
void wrap_glVertexAttribIPointer(GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid* pointer) {
    printf("/*#fishhook#**/ glVertexAttribIPointer(%d, %d, 0x%04x, %d, [0x%04x]));\n", index, size, type, stride, ((int*)pointer)[0]);
    orig_glVertexAttribIPointer(index, size, type, stride, pointer);
}

static void (*orig_glGetVertexAttribIiv)(GLuint index, GLenum pname, GLint* params);
void wrap_glGetVertexAttribIiv(GLuint index, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetVertexAttribIiv(%d, 0x%04x, [%d]));\n", index, pname, ((int*)params)[0]);
    orig_glGetVertexAttribIiv(index, pname, params);
}

static void (*orig_glGetVertexAttribIuiv)(GLuint index, GLenum pname, GLuint* params);
void wrap_glGetVertexAttribIuiv(GLuint index, GLenum pname, GLuint* params) {
    printf("/*#fishhook#**/ glGetVertexAttribIuiv(%d, 0x%04x, [%d]));\n", index, pname, ((int*)params)[0]);
    orig_glGetVertexAttribIuiv(index, pname, params);
}

static void (*orig_glVertexAttribI4i)(GLuint index, GLint x, GLint y, GLint z, GLint w);
void wrap_glVertexAttribI4i(GLuint index, GLint x, GLint y, GLint z, GLint w) {
    printf("/*#fishhook#**/ glVertexAttribI4i(%d, %d, %d, %d, %d));\n", index, x, y, z, w);
    orig_glVertexAttribI4i(index, x, y, z, w);
}

static void (*orig_glVertexAttribI4ui)(GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
void wrap_glVertexAttribI4ui(GLuint index, GLuint x, GLuint y, GLuint z, GLuint w) {
    printf("/*#fishhook#**/ glVertexAttribI4ui(%d, %d, %d, %d, %d));\n", index, x, y, z, w);
    orig_glVertexAttribI4ui(index, x, y, z, w);
}

static void (*orig_glVertexAttribI4iv)(GLuint index, const GLint* v);
void wrap_glVertexAttribI4iv(GLuint index, const GLint* v) {
    printf("/*#fishhook#**/ glVertexAttribI4iv(%d, [%d]));\n", index, ((int*)v)[0]);
    orig_glVertexAttribI4iv(index, v);
}

static void (*orig_glVertexAttribI4uiv)(GLuint index, const GLuint* v);
void wrap_glVertexAttribI4uiv(GLuint index, const GLuint* v) {
    printf("/*#fishhook#**/ glVertexAttribI4uiv(%d, [%d]));\n", index, ((int*)v)[0]);
    orig_glVertexAttribI4uiv(index, v);
}

static void (*orig_glGetUniformuiv)(GLuint program, GLint location, GLuint* params);
void wrap_glGetUniformuiv(GLuint program, GLint location, GLuint* params) {
    printf("/*#fishhook#**/ glGetUniformuiv(%d, %d, [%d]));\n", program, location, ((int*)params)[0]);
    orig_glGetUniformuiv(program, location, params);
}

static GLint (*orig_glGetFragDataLocation)(GLuint program, const GLchar *name);
GLint wrap_glGetFragDataLocation(GLuint program, const GLchar *name) {
    printf("/*#fishhook#**/ glGetFragDataLocation(%d, \"%s\"));\n", program, name);
    return orig_glGetFragDataLocation(program, name);
}

static void (*orig_glUniform1ui)(GLint location, GLuint v0);
void wrap_glUniform1ui(GLint location, GLuint v0) {
    printf("/*#fishhook#**/ glUniform1ui(%d, %d));\n", location, v0);
    orig_glUniform1ui(location, v0);
}

static void (*orig_glUniform2ui)(GLint location, GLuint v0, GLuint v1);
void wrap_glUniform2ui(GLint location, GLuint v0, GLuint v1) {
    printf("/*#fishhook#**/ glUniform2ui(%d, %d, %d));\n", location, v0, v1);
    orig_glUniform2ui(location, v0, v1);
}

static void (*orig_glUniform3ui)(GLint location, GLuint v0, GLuint v1, GLuint v2);
void wrap_glUniform3ui(GLint location, GLuint v0, GLuint v1, GLuint v2) {
    printf("/*#fishhook#**/ glUniform3ui(%d, %d, %d, %d));\n", location, v0, v1, v2);
    orig_glUniform3ui(location, v0, v1, v2);
}

static void (*orig_glUniform4ui)(GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
void wrap_glUniform4ui(GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3) {
    printf("/*#fishhook#**/ glUniform4ui(%d, %d, %d, %d, %d));\n", location, v0, v1, v2, v3);
    orig_glUniform4ui(location, v0, v1, v2, v3);
}

static void (*orig_glUniform1uiv)(GLint location, GLsizei count, const GLuint* value);
void wrap_glUniform1uiv(GLint location, GLsizei count, const GLuint* value) {
    printf("/*#fishhook#**/ glUniform1uiv(%d, %d, [%d]));\n", location, count, ((int*)value)[0]);
    orig_glUniform1uiv(location, count, value);
}

static void (*orig_glUniform2uiv)(GLint location, GLsizei count, const GLuint* value);
void wrap_glUniform2uiv(GLint location, GLsizei count, const GLuint* value) {
    printf("/*#fishhook#**/ glUniform2uiv(%d, %d, [%d]));\n", location, count, ((int*)value)[0]);
    orig_glUniform2uiv(location, count, value);
}

static void (*orig_glUniform3uiv)(GLint location, GLsizei count, const GLuint* value);
void wrap_glUniform3uiv(GLint location, GLsizei count, const GLuint* value) {
    printf("/*#fishhook#**/ glUniform3uiv(%d, %d, [%d]));\n", location, count, ((int*)value)[0]);
    orig_glUniform3uiv(location, count, value);
}

static void (*orig_glUniform4uiv)(GLint location, GLsizei count, const GLuint* value);
void wrap_glUniform4uiv(GLint location, GLsizei count, const GLuint* value) {
    printf("/*#fishhook#**/ glUniform4uiv(%d, %d, [%d]));\n", location, count, ((int*)value)[0]);
    orig_glUniform4uiv(location, count, value);
}

static void (*orig_glClearBufferiv)(GLenum buffer, GLint drawbuffer, const GLint* value);
void wrap_glClearBufferiv(GLenum buffer, GLint drawbuffer, const GLint* value) {
    printf("/*#fishhook#**/ glClearBufferiv(0x%04x, %d, [%d]));\n", buffer, drawbuffer, ((int*)value)[0]);
    orig_glClearBufferiv(buffer, drawbuffer, value);
}

static void (*orig_glClearBufferuiv)(GLenum buffer, GLint drawbuffer, const GLuint* value);
void wrap_glClearBufferuiv(GLenum buffer, GLint drawbuffer, const GLuint* value) {
    printf("/*#fishhook#**/ glClearBufferuiv(0x%04x, %d, [%d]));\n", buffer, drawbuffer, ((int*)value)[0]);
    orig_glClearBufferuiv(buffer, drawbuffer, value);
}

static void (*orig_glClearBufferfv)(GLenum buffer, GLint drawbuffer, const GLfloat* value);
void wrap_glClearBufferfv(GLenum buffer, GLint drawbuffer, const GLfloat* value) {
    printf("/*#fishhook#**/ {GLfloat value[] = {%f, %f}; glClearBufferfv(0x%04x, %d, value));}\n", value[0], value[1], buffer, drawbuffer);
    orig_glClearBufferfv(buffer, drawbuffer, value);
}

static void (*orig_glClearBufferfi)(GLenum buffer, GLint drawbuffer, GLfloat depth, GLint stencil);
void wrap_glClearBufferfi(GLenum buffer, GLint drawbuffer, GLfloat depth, GLint stencil) {
    printf("/*#fishhook#**/ glClearBufferfi(0x%04x, %d, %f, %d));\n", buffer, drawbuffer, depth, stencil);
    orig_glClearBufferfi(buffer, drawbuffer, depth, stencil);
}

static const GLubyte* (*orig_glGetStringi)(GLenum name, GLuint index);
const GLubyte* wrap_glGetStringi(GLenum name, GLuint index) {
    printf("/*#fishhook#**/ glGetStringi(0x%04x, %d));\n", name, index);
    return orig_glGetStringi(name, index);
}

static void (*orig_glCopyBufferSubData)(GLenum readTarget, GLenum writeTarget, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size);
void wrap_glCopyBufferSubData(GLenum readTarget, GLenum writeTarget, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size) {
    printf("/*#fishhook#**/ glCopyBufferSubData(0x%04x, 0x%04x, %d, %d, %d));\n", readTarget, writeTarget, (int)readOffset, (int)writeOffset, (int)size);
    orig_glCopyBufferSubData(readTarget, writeTarget, readOffset, writeOffset, size);
}

static void (*orig_glGetUniformIndices)(GLuint program, GLsizei uniformCount, const GLchar* const *uniformNames, GLuint* uniformIndices);
void wrap_glGetUniformIndices(GLuint program, GLsizei uniformCount, const GLchar* const *uniformNames, GLuint* uniformIndices) {
    printf("/*#fishhook#**/ glGetUniformIndices(%d, %d, [%d], [%d]));\n", program, uniformCount, ((int*)uniformNames)[0], ((int*)uniformIndices)[0]);
    orig_glGetUniformIndices(program, uniformCount, uniformNames, uniformIndices);
}

static void (*orig_glGetActiveUniformsiv)(GLuint program, GLsizei uniformCount, const GLuint* uniformIndices, GLenum pname, GLint* params);
void wrap_glGetActiveUniformsiv(GLuint program, GLsizei uniformCount, const GLuint* uniformIndices, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetActiveUniformsiv(%d, %d, [%d], 0x%04x, [%d]));\n", program, uniformCount, ((int*)uniformIndices)[0], pname, ((int*)params)[0]);
    orig_glGetActiveUniformsiv(program, uniformCount, uniformIndices, pname, params);
}

static GLuint (*orig_glGetUniformBlockIndex)(GLuint program, const GLchar* uniformBlockName);
GLuint wrap_glGetUniformBlockIndex(GLuint program, const GLchar* uniformBlockName) {
    printf("/*#fishhook#**/ glGetUniformBlockIndex(%d, [%d]));\n", program, ((int*)uniformBlockName)[0]);
    return orig_glGetUniformBlockIndex(program, uniformBlockName);
}

static void (*orig_glGetActiveUniformBlockiv)(GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint* params);
void wrap_glGetActiveUniformBlockiv(GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetActiveUniformBlockiv(%d, %d, 0x%04x, [%d]));\n", program, uniformBlockIndex, pname, ((int*)params)[0]);
    orig_glGetActiveUniformBlockiv(program, uniformBlockIndex, pname, params);
}

static void (*orig_glGetActiveUniformBlockName)(GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei* length, GLchar* uniformBlockName);
void wrap_glGetActiveUniformBlockName(GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei* length, GLchar* uniformBlockName) {
    printf("/*#fishhook#**/ glGetActiveUniformBlockName(%d, %d, %d, [%d], [[%d]]));\n", program, uniformBlockIndex, bufSize, ((int*)length)[0], ((int*)uniformBlockName)[0]);
    orig_glGetActiveUniformBlockName(program, uniformBlockIndex, bufSize, length, uniformBlockName);
}

static void (*orig_glUniformBlockBinding)(GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding);
void wrap_glUniformBlockBinding(GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding) {
    printf("/*#fishhook#**/ glUniformBlockBinding(%d, %d, %d));\n", program, uniformBlockIndex, uniformBlockBinding);
    orig_glUniformBlockBinding(program, uniformBlockIndex, uniformBlockBinding);
}

static void (*orig_glDrawArraysInstanced)(GLenum mode, GLint first, GLsizei count, GLsizei instancecount);
void wrap_glDrawArraysInstanced(GLenum mode, GLint first, GLsizei count, GLsizei instancecount) {
    printf("/*#fishhook#**/ glDrawArraysInstanced(0x%04x, %d, %d, %d));\n", mode, first, count, instancecount);
    orig_glDrawArraysInstanced(mode, first, count, instancecount);
}

static void (*orig_glDrawElementsInstanced)(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices, GLsizei instancecount);
void wrap_glDrawElementsInstanced(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices, GLsizei instancecount) {
    printf("/*#fishhook#**/ glDrawElementsInstanced(0x%04x, %d, 0x%04x, [0x%04x], %d));\n", mode, count, type, ((int*)indices)[0], instancecount);
    orig_glDrawElementsInstanced(mode, count, type, indices, instancecount);
}

static GLsync (*orig_glFenceSync)(GLenum condition, GLbitfield flags);
GLsync wrap_glFenceSync(GLenum condition, GLbitfield flags) {
    printf("/*#fishhook#**/ glFenceSync(0x%04x, 0x%04x));\n", condition, flags);
    return orig_glFenceSync(condition, flags);
}

static GLboolean (*orig_glIsSync)(GLsync sync);
GLboolean wrap_glIsSync(GLsync sync) {
    printf("/*#fishhook#**/ glIsSync(0x%lx));\n", (long)sync);
    return orig_glIsSync(sync);
}

static void (*orig_glDeleteSync)(GLsync sync);
void wrap_glDeleteSync(GLsync sync) {
    printf("/*#fishhook#**/ glDeleteSync(0x%lx));\n", (long)sync);
    orig_glDeleteSync(sync);
}

static GLenum (*orig_glClientWaitSync)(GLsync sync, GLbitfield flags, GLuint64 timeout);
GLenum wrap_glClientWaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout) {
    printf("/*#fishhook#**/ glClientWaitSync(0x%lx, 0x%04x, %llu));\n", (long)sync, flags, timeout);
    return orig_glClientWaitSync(sync, flags, timeout);
}

static void (*orig_glWaitSync)(GLsync sync, GLbitfield flags, GLuint64 timeout);
void wrap_glWaitSync(GLsync sync, GLbitfield flags, GLuint64 timeout) {
    printf("/*#fishhook#**/ glWaitSync(0x%lx, %d, %llu));\n", (long)sync, flags, timeout);
    orig_glWaitSync(sync, flags, timeout);
}

static void (*orig_glGetInteger64v)(GLenum pname, GLint64* params);
void wrap_glGetInteger64v(GLenum pname, GLint64* params) {
    printf("/*#fishhook#**/ glGetInteger64v(0x%04x, [%d]));\n", pname, ((int*)params)[0]);
    orig_glGetInteger64v(pname, params);
}

static void (*orig_glGetSynciv)(GLsync sync, GLenum pname, GLsizei bufSize, GLsizei* length, GLint* values);
void wrap_glGetSynciv(GLsync sync, GLenum pname, GLsizei bufSize, GLsizei* length, GLint* values) {
    printf("/*#fishhook#**/ glGetSynciv([%d], 0x%04x, %d, [%d], [%d]));\n", ((int*)sync)[0], pname, bufSize, ((int*)length)[0], ((int*)values)[0]);
    orig_glGetSynciv(sync, pname, bufSize, length, values);
}

static void (*orig_glGetInteger64i_v)(GLenum target, GLuint index, GLint64* data);
void wrap_glGetInteger64i_v(GLenum target, GLuint index, GLint64* data) {
    printf("/*#fishhook#**/ glGetInteger64i_v(0x%04x, %d, [%d]));\n", target, index, ((int*)data)[0]);
    orig_glGetInteger64i_v(target, index, data);
}

static void (*orig_glGetBufferParameteri64v)(GLenum target, GLenum pname, GLint64* params);
void wrap_glGetBufferParameteri64v(GLenum target, GLenum pname, GLint64* params) {
    printf("/*#fishhook#**/ glGetBufferParameteri64v(0x%04x, 0x%04x, [%d]));\n", target, pname, ((int*)params)[0]);
    orig_glGetBufferParameteri64v(target, pname, params);
}

static void (*orig_glGenSamplers)(GLsizei count, GLuint* samplers);
void wrap_glGenSamplers(GLsizei count, GLuint* samplers) {
    printf("/*#fishhook#**/ glGenSamplers(%d, [%d]));\n", count, ((int*)samplers)[0]);
    orig_glGenSamplers(count, samplers);
}

static void (*orig_glDeleteSamplers)(GLsizei count, const GLuint* samplers);
void wrap_glDeleteSamplers(GLsizei count, const GLuint* samplers) {
    printf("/*#fishhook#**/ glDeleteSamplers(%d, [%d]));\n", count, ((int*)samplers)[0]);
    orig_glDeleteSamplers(count, samplers);
}

static GLboolean (*orig_glIsSampler)(GLuint sampler);
GLboolean wrap_glIsSampler(GLuint sampler) {
    printf("/*#fishhook#**/ glIsSampler(%d));\n", sampler);
    return orig_glIsSampler(sampler);
}

static void (*orig_glBindSampler)(GLuint unit, GLuint sampler);
void wrap_glBindSampler(GLuint unit, GLuint sampler) {
    printf("/*#fishhook#**/ glBindSampler(%d, %d));\n", unit, sampler);
    orig_glBindSampler(unit, sampler);
}

static void (*orig_glSamplerParameteri)(GLuint sampler, GLenum pname, GLint param);
void wrap_glSamplerParameteri(GLuint sampler, GLenum pname, GLint param) {
    printf("/*#fishhook#**/ glSamplerParameteri(%d, 0x%04x, %d));\n", sampler, pname, param);
    orig_glSamplerParameteri(sampler, pname, param);
}

static void (*orig_glSamplerParameteriv)(GLuint sampler, GLenum pname, const GLint* param);
void wrap_glSamplerParameteriv(GLuint sampler, GLenum pname, const GLint* param) {
    printf("/*#fishhook#**/ {GLint param[] = {%d, %d, %d, %d}; glSamplerParameteriv(%d, 0x%04x, param));}\n", param[0], param[1], param[2], param[3], sampler, pname);
    orig_glSamplerParameteriv(sampler, pname, param);
}

static void (*orig_glSamplerParameterf)(GLuint sampler, GLenum pname, GLfloat param);
void wrap_glSamplerParameterf(GLuint sampler, GLenum pname, GLfloat param) {
    printf("/*#fishhook#**/ glSamplerParameterf(%d, 0x%04x, %f));\n", sampler, pname, param);
    orig_glSamplerParameterf(sampler, pname, param);
}

static void (*orig_glSamplerParameterfv)(GLuint sampler, GLenum pname, const GLfloat* param);
void wrap_glSamplerParameterfv(GLuint sampler, GLenum pname, const GLfloat* param) {
    printf("/*#fishhook#**/ {GLfloat param[] = {%f, %f, %f, %f}; glSamplerParameterfv(%d, 0x%04x, param));}\n", param[0], param[1], param[2], param[3], sampler, pname);
    orig_glSamplerParameterfv(sampler, pname, param);
}

static void (*orig_glGetSamplerParameteriv)(GLuint sampler, GLenum pname, GLint* params);
void wrap_glGetSamplerParameteriv(GLuint sampler, GLenum pname, GLint* params) {
    printf("/*#fishhook#**/ glGetSamplerParameteriv(%d, 0x%04x, [%d]));\n", sampler, pname, ((int*)params)[0]);
    orig_glGetSamplerParameteriv(sampler, pname, params);
}

static void (*orig_glGetSamplerParameterfv)(GLuint sampler, GLenum pname, GLfloat* params);
void wrap_glGetSamplerParameterfv(GLuint sampler, GLenum pname, GLfloat* params) {
    orig_glGetSamplerParameterfv(sampler, pname, params);
    printf("/*#fishhook#**/ {GLfloat params[] = {%f, %f, %f, %f}; glGetSamplerParameterfv(%d, 0x%04x, params));\n", params[0], params[1], params[2], params[3], sampler, pname);
}

static void (*orig_glVertexAttribDivisor)(GLuint index, GLuint divisor);
void wrap_glVertexAttribDivisor(GLuint index, GLuint divisor) {
    printf("/*#fishhook#**/ glVertexAttribDivisor(%d, %d));\n", index, divisor);
    orig_glVertexAttribDivisor(index, divisor);
}

static void (*orig_glBindTransformFeedback)(GLenum target, GLuint id);
void wrap_glBindTransformFeedback(GLenum target, GLuint id) {
    printf("/*#fishhook#**/ glBindTransformFeedback(0x%04x, %d));\n", target, id);
    orig_glBindTransformFeedback(target, id);
}

static void (*orig_glDeleteTransformFeedbacks)(GLsizei n, const GLuint* ids);
void wrap_glDeleteTransformFeedbacks(GLsizei n, const GLuint* ids) {
    printf("/*#fishhook#**/ glDeleteTransformFeedbacks(%d, [%d]));\n", n, ((int*)ids)[0]);
    orig_glDeleteTransformFeedbacks(n, ids);
}

static void (*orig_glGenTransformFeedbacks)(GLsizei n, GLuint* ids);
void wrap_glGenTransformFeedbacks(GLsizei n, GLuint* ids) {
    printf("/*#fishhook#**/ glGenTransformFeedbacks(%d, [%d]));\n", n, ((int*)ids)[0]);
    orig_glGenTransformFeedbacks(n, ids);
}

static GLboolean (*orig_glIsTransformFeedback)(GLuint id);
GLboolean wrap_glIsTransformFeedback(GLuint id) {
    printf("/*#fishhook#**/ glIsTransformFeedback(%d));\n", id);
    return orig_glIsTransformFeedback(id);
}

static void (*orig_glPauseTransformFeedback)(void);
void wrap_glPauseTransformFeedback(void) {
    printf("/*#fishhook#**/ glPauseTransformFeedback(");
    orig_glPauseTransformFeedback();
}

static void (*orig_glResumeTransformFeedback)(void);
void wrap_glResumeTransformFeedback(void) {
    printf("/*#fishhook#**/ glResumeTransformFeedback(");
    orig_glResumeTransformFeedback();
}

static void (*orig_glGetProgramBinary)(GLuint program, GLsizei bufSize, GLsizei* length, GLenum* binaryFormat, GLvoid* binary);
void wrap_glGetProgramBinary(GLuint program, GLsizei bufSize, GLsizei* length, GLenum* binaryFormat, GLvoid* binary) {
    printf("/*#fishhook#**/ glGetProgramBinary(%d, %d, [%d], [0x%04x], [0x%04x]));\n", program, bufSize, ((int*)length)[0], ((int*)binaryFormat)[0], ((int*)binary)[0]);
    orig_glGetProgramBinary(program, bufSize, length, binaryFormat, binary);
}

static void (*orig_glProgramBinary)(GLuint program, GLenum binaryFormat, const GLvoid* binary, GLsizei length);
void wrap_glProgramBinary(GLuint program, GLenum binaryFormat, const GLvoid* binary, GLsizei length) {
    printf("/*#fishhook#**/ glProgramBinary(%d, 0x%04x, [0x%04x], %d));\n", program, binaryFormat, ((int*)binary)[0], length);
    orig_glProgramBinary(program, binaryFormat, binary, length);
}

static void (*orig_glProgramParameteri)(GLuint program, GLenum pname, GLint value);
void wrap_glProgramParameteri(GLuint program, GLenum pname, GLint value) {
    printf("/*#fishhook#**/ glProgramParameteri(%d, 0x%04x, %d));\n", program, pname, value);
    orig_glProgramParameteri(program, pname, value);
}

static void (*orig_glInvalidateFramebuffer)(GLenum target, GLsizei numAttachments, const GLenum* attachments);
void wrap_glInvalidateFramebuffer(GLenum target, GLsizei numAttachments, const GLenum* attachments) {
    printf("/*#fishhook#**/ glInvalidateFramebuffer(0x%04x, %d, [0x%04x]));\n", target, numAttachments, ((int*)attachments)[0]);
    orig_glInvalidateFramebuffer(target, numAttachments, attachments);
}

static void (*orig_glInvalidateSubFramebuffer)(GLenum target, GLsizei numAttachments, const GLenum* attachments, GLint x, GLint y, GLsizei width, GLsizei height);
void wrap_glInvalidateSubFramebuffer(GLenum target, GLsizei numAttachments, const GLenum* attachments, GLint x, GLint y, GLsizei width, GLsizei height) {
    printf("/*#fishhook#**/ glInvalidateSubFramebuffer(0x%04x, %d, [0x%04x], %d, %d, %d, %d));\n", target, numAttachments, ((int*)attachments)[0], x, y, width, height);
    orig_glInvalidateSubFramebuffer(target, numAttachments, attachments, x, y, width, height);
}

static void (*orig_glTexStorage2D)(GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);
void wrap_glTexStorage2D(GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height) {
    printf("/*#fishhook#**/ glTexStorage2D(0x%04x, %d, 0x%04x, %d, %d));\n", target, levels, internalformat, width, height);
    orig_glTexStorage2D(target, levels, internalformat, width, height);
}

static void (*orig_glTexStorage3D)(GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);
void wrap_glTexStorage3D(GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth) {
    printf("/*#fishhook#**/ glTexStorage3D(0x%04x, %d, 0x%04x, %d, %d, %d));\n", target, levels, internalformat, width, height, depth);
    orig_glTexStorage3D(target, levels, internalformat, width, height, depth);
}

static void (*orig_glGetInternalformativ)(GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint* params);
void wrap_glGetInternalformativ(GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint* params) {
    printf("/*#fishhook#**/ glGetInternalformativ(0x%04x, 0x%04x, 0x%04x, %d, [%d]));\n", target, internalformat, pname, bufSize, ((int*)params)[0]);
    orig_glGetInternalformativ(target, internalformat, pname, bufSize, params);
}

static struct rebinding rebindings[] = {
{"glUniform1ui", wrap_glUniform1ui, (void*)&orig_glUniform1ui},
{"glUniform2ui", wrap_glUniform2ui, (void*)&orig_glUniform2ui},
{"glUniform3ui", wrap_glUniform3ui, (void*)&orig_glUniform3ui},
{"glUniform4ui", wrap_glUniform4ui, (void*)&orig_glUniform4ui},
{"glUniform1uiv", wrap_glUniform1uiv, (void*)&orig_glUniform1uiv},
{"glUniform2uiv", wrap_glUniform2uiv, (void*)&orig_glUniform2uiv},
{"glUniform3uiv", wrap_glUniform3uiv, (void*)&orig_glUniform3uiv},
{"glUniform4uiv", wrap_glUniform4uiv, (void*)&orig_glUniform4uiv},
{"glActiveTexture", wrap_glActiveTexture, (void*)&orig_glActiveTexture},
{"glBindAttribLocation", wrap_glBindAttribLocation, (void*)&orig_glBindAttribLocation},
{"glBindFramebuffer", wrap_glBindFramebuffer, (void*)&orig_glBindFramebuffer},
{"glBindRenderbuffer", wrap_glBindRenderbuffer, (void*)&orig_glBindRenderbuffer},
{"glBindTexture", wrap_glBindTexture, (void*)&orig_glBindTexture},
{"glClear", wrap_glClear, (void*)&orig_glClear},
{"glCompressedTexImage2D", wrap_glCompressedTexImage2D, (void*)&orig_glCompressedTexImage2D},
{"glCompressedTexSubImage2D", wrap_glCompressedTexSubImage2D, (void*)&orig_glCompressedTexSubImage2D},
{"glCopyTexImage2D", wrap_glCopyTexImage2D, (void*)&orig_glCopyTexImage2D},
{"glCopyTexSubImage2D", wrap_glCopyTexSubImage2D, (void*)&orig_glCopyTexSubImage2D},
{"glViewport", wrap_glViewport, (void*)&orig_glViewport},
{"glDrawBuffers", wrap_glDrawBuffers, (void*)&orig_glDrawBuffers},
{"glUniformMatrix2x3fv", wrap_glUniformMatrix2x3fv, (void*)&orig_glUniformMatrix2x3fv},
{"glUniformMatrix3x2fv", wrap_glUniformMatrix3x2fv, (void*)&orig_glUniformMatrix3x2fv},
{"glUniformMatrix2x4fv", wrap_glUniformMatrix2x4fv, (void*)&orig_glUniformMatrix2x4fv},
{"glUniformMatrix4x2fv", wrap_glUniformMatrix4x2fv, (void*)&orig_glUniformMatrix4x2fv},
{"glUniformMatrix3x4fv", wrap_glUniformMatrix3x4fv, (void*)&orig_glUniformMatrix3x4fv},
{"glUniformMatrix4x3fv", wrap_glUniformMatrix4x3fv, (void*)&orig_glUniformMatrix4x3fv},
{"glDrawArraysInstanced", wrap_glDrawArraysInstanced, (void*)&orig_glDrawArraysInstanced},
{"glDrawElementsInstanced", wrap_glDrawElementsInstanced, (void*)&orig_glDrawElementsInstanced},
{"glDeleteTextures", wrap_glDeleteTextures, (void*)&orig_glDeleteTextures},
{"glDisable", wrap_glDisable, (void*)&orig_glDisable},
{"glDeleteFramebuffers", wrap_glDeleteFramebuffers, (void*)&orig_glDeleteFramebuffers},
{"glDrawArrays", wrap_glDrawArrays, (void*)&orig_glDrawArrays},
{"glDrawElements", wrap_glDrawElements, (void*)&orig_glDrawElements},
{"glEnable", wrap_glEnable, (void*)&orig_glEnable},
{"glFramebufferRenderbuffer", wrap_glFramebufferRenderbuffer, (void*)&orig_glFramebufferRenderbuffer},
{"glFramebufferTexture2D", wrap_glFramebufferTexture2D, (void*)&orig_glFramebufferTexture2D},
{"glGenerateMipmap", wrap_glGenerateMipmap, (void*)&orig_glGenerateMipmap},
{"glGenTextures", wrap_glGenTextures, (void*)&orig_glGenTextures},
{"glGetUniformLocation", wrap_glGetUniformLocation, (void*)&orig_glGetUniformLocation},
{"glLinkProgram", wrap_glLinkProgram, (void*)&orig_glLinkProgram},
{"glRenderbufferStorage", wrap_glRenderbufferStorage, (void*)&orig_glRenderbufferStorage},
{"glShaderSource", wrap_glShaderSource, (void*)&orig_glShaderSource},
{"glTexImage2D", wrap_glTexImage2D, (void*)&orig_glTexImage2D},
{"glTexParameterf", wrap_glTexParameterf, (void*)&orig_glTexParameterf},
{"glTexParameterfv", wrap_glTexParameterfv, (void*)&orig_glTexParameterfv},
{"glTexParameteri", wrap_glTexParameteri, (void*)&orig_glTexParameteri},
{"glTexParameteriv", wrap_glTexParameteriv, (void*)&orig_glTexParameteriv},
{"glTexSubImage2D", wrap_glTexSubImage2D, (void*)&orig_glTexSubImage2D},
{"glUniform1f", wrap_glUniform1f, (void*)&orig_glUniform1f},
{"glUniform1fv", wrap_glUniform1fv, (void*)&orig_glUniform1fv},
{"glUniform1i", wrap_glUniform1i, (void*)&orig_glUniform1i},
{"glUniform1iv", wrap_glUniform1iv, (void*)&orig_glUniform1iv},
{"glUniform2f", wrap_glUniform2f, (void*)&orig_glUniform2f},
{"glUniform2fv", wrap_glUniform2fv, (void*)&orig_glUniform2fv},
{"glUniform2i", wrap_glUniform2i, (void*)&orig_glUniform2i},
{"glUniform2iv", wrap_glUniform2iv, (void*)&orig_glUniform2iv},
{"glUniform3f", wrap_glUniform3f, (void*)&orig_glUniform3f},
{"glUniform3fv", wrap_glUniform3fv, (void*)&orig_glUniform3fv},
{"glUniform3i", wrap_glUniform3i, (void*)&orig_glUniform3i},
{"glUniform3iv", wrap_glUniform3iv, (void*)&orig_glUniform3iv},
{"glUniform4f", wrap_glUniform4f, (void*)&orig_glUniform4f},
{"glUniform4fv", wrap_glUniform4fv, (void*)&orig_glUniform4fv},
{"glUniform4i", wrap_glUniform4i, (void*)&orig_glUniform4i},
{"glUniform4iv", wrap_glUniform4iv, (void*)&orig_glUniform4iv},
{"glUniformMatrix2fv", wrap_glUniformMatrix2fv, (void*)&orig_glUniformMatrix2fv},
{"glUniformMatrix3fv", wrap_glUniformMatrix3fv, (void*)&orig_glUniformMatrix3fv},
{"glUniformMatrix4fv", wrap_glUniformMatrix4fv, (void*)&orig_glUniformMatrix4fv},
{"glUseProgram", wrap_glUseProgram, (void*)&orig_glUseProgram},
{"glDrawRangeElements", wrap_glDrawRangeElements, (void*)&orig_glDrawRangeElements},
{"glTexImage3D", wrap_glTexImage3D, (void*)&orig_glTexImage3D},
{"glTexSubImage3D", wrap_glTexSubImage3D, (void*)&orig_glTexSubImage3D},
{"glCopyTexSubImage3D", wrap_glCopyTexSubImage3D, (void*)&orig_glCopyTexSubImage3D},
{"glCompressedTexImage3D", wrap_glCompressedTexImage3D, (void*)&orig_glCompressedTexImage3D},
{"glCompressedTexSubImage3D", wrap_glCompressedTexSubImage3D, (void*)&orig_glCompressedTexSubImage3D},
//////////////
{"glAttachShader", wrap_glAttachShader, (void*)&orig_glAttachShader},
{"glBindBuffer", wrap_glBindBuffer, (void*)&orig_glBindBuffer},
{"glBlendColor", wrap_glBlendColor, (void*)&orig_glBlendColor},
{"glBlendEquation", wrap_glBlendEquation, (void*)&orig_glBlendEquation},
{"glBlendEquationSeparate", wrap_glBlendEquationSeparate, (void*)&orig_glBlendEquationSeparate},
{"glBlendFunc", wrap_glBlendFunc, (void*)&orig_glBlendFunc},
{"glBlendFuncSeparate", wrap_glBlendFuncSeparate, (void*)&orig_glBlendFuncSeparate},
{"glBufferData", wrap_glBufferData, (void*)&orig_glBufferData},
{"glBufferSubData", wrap_glBufferSubData, (void*)&orig_glBufferSubData},
{"glCheckFramebufferStatus", wrap_glCheckFramebufferStatus, (void*)&orig_glCheckFramebufferStatus},
{"glClearColor", wrap_glClearColor, (void*)&orig_glClearColor},
{"glClearDepthf", wrap_glClearDepthf, (void*)&orig_glClearDepthf},
{"glClearStencil", wrap_glClearStencil, (void*)&orig_glClearStencil},
{"glColorMask", wrap_glColorMask, (void*)&orig_glColorMask},
{"glCompileShader", wrap_glCompileShader, (void*)&orig_glCompileShader},
{"glCreateProgram", wrap_glCreateProgram, (void*)&orig_glCreateProgram},
{"glCreateShader", wrap_glCreateShader, (void*)&orig_glCreateShader},
{"glCullFace", wrap_glCullFace, (void*)&orig_glCullFace},
{"glDeleteBuffers", wrap_glDeleteBuffers, (void*)&orig_glDeleteBuffers},
{"glDeleteProgram", wrap_glDeleteProgram, (void*)&orig_glDeleteProgram},
{"glDeleteRenderbuffers", wrap_glDeleteRenderbuffers, (void*)&orig_glDeleteRenderbuffers},
{"glDeleteShader", wrap_glDeleteShader, (void*)&orig_glDeleteShader},
{"glDepthFunc", wrap_glDepthFunc, (void*)&orig_glDepthFunc},
{"glDepthMask", wrap_glDepthMask, (void*)&orig_glDepthMask},
{"glDepthRangef", wrap_glDepthRangef, (void*)&orig_glDepthRangef},
{"glDetachShader", wrap_glDetachShader, (void*)&orig_glDetachShader},
{"glDisableVertexAttribArray", wrap_glDisableVertexAttribArray, (void*)&orig_glDisableVertexAttribArray},
{"glEnableVertexAttribArray", wrap_glEnableVertexAttribArray, (void*)&orig_glEnableVertexAttribArray},
{"glFinish", wrap_glFinish, (void*)&orig_glFinish},
{"glFlush", wrap_glFlush, (void*)&orig_glFlush},
{"glFrontFace", wrap_glFrontFace, (void*)&orig_glFrontFace},
{"glGenBuffers", wrap_glGenBuffers, (void*)&orig_glGenBuffers},
{"glGenFramebuffers", wrap_glGenFramebuffers, (void*)&orig_glGenFramebuffers},
{"glGenRenderbuffers", wrap_glGenRenderbuffers, (void*)&orig_glGenRenderbuffers},
{"glGetActiveAttrib", wrap_glGetActiveAttrib, (void*)&orig_glGetActiveAttrib},
{"glGetActiveUniform", wrap_glGetActiveUniform, (void*)&orig_glGetActiveUniform},
{"glGetAttachedShaders", wrap_glGetAttachedShaders, (void*)&orig_glGetAttachedShaders},
{"glGetAttribLocation", wrap_glGetAttribLocation, (void*)&orig_glGetAttribLocation},
{"glGetBooleanv", wrap_glGetBooleanv, (void*)&orig_glGetBooleanv},
{"glGetBufferParameteriv", wrap_glGetBufferParameteriv, (void*)&orig_glGetBufferParameteriv},
//{"glGetError", wrap_glGetError, (void*)&orig_glGetError},
{"glGetFloatv", wrap_glGetFloatv, (void*)&orig_glGetFloatv},
{"glGetFramebufferAttachmentParameteriv", wrap_glGetFramebufferAttachmentParameteriv, (void*)&orig_glGetFramebufferAttachmentParameteriv},
{"glGetIntegerv", wrap_glGetIntegerv, (void*)&orig_glGetIntegerv},
{"glGetProgramiv", wrap_glGetProgramiv, (void*)&orig_glGetProgramiv},
{"glGetProgramInfoLog", wrap_glGetProgramInfoLog, (void*)&orig_glGetProgramInfoLog},
{"glGetRenderbufferParameteriv", wrap_glGetRenderbufferParameteriv, (void*)&orig_glGetRenderbufferParameteriv},
{"glGetShaderiv", wrap_glGetShaderiv, (void*)&orig_glGetShaderiv},
{"glGetShaderInfoLog", wrap_glGetShaderInfoLog, (void*)&orig_glGetShaderInfoLog},
{"glGetShaderPrecisionFormat", wrap_glGetShaderPrecisionFormat, (void*)&orig_glGetShaderPrecisionFormat},
{"glGetShaderSource", wrap_glGetShaderSource, (void*)&orig_glGetShaderSource},
{"glGetString", wrap_glGetString, (void*)&orig_glGetString},
{"glGetTexParameterfv", wrap_glGetTexParameterfv, (void*)&orig_glGetTexParameterfv},
{"glGetTexParameteriv", wrap_glGetTexParameteriv, (void*)&orig_glGetTexParameteriv},
{"glGetUniformfv", wrap_glGetUniformfv, (void*)&orig_glGetUniformfv},
{"glGetUniformiv", wrap_glGetUniformiv, (void*)&orig_glGetUniformiv},
{"glGetVertexAttribfv", wrap_glGetVertexAttribfv, (void*)&orig_glGetVertexAttribfv},
{"glGetVertexAttribiv", wrap_glGetVertexAttribiv, (void*)&orig_glGetVertexAttribiv},
{"glGetVertexAttribPointerv", wrap_glGetVertexAttribPointerv, (void*)&orig_glGetVertexAttribPointerv},
{"glHint", wrap_glHint, (void*)&orig_glHint},
{"glIsBuffer", wrap_glIsBuffer, (void*)&orig_glIsBuffer},
{"glIsEnabled", wrap_glIsEnabled, (void*)&orig_glIsEnabled},
{"glIsFramebuffer", wrap_glIsFramebuffer, (void*)&orig_glIsFramebuffer},
{"glIsProgram", wrap_glIsProgram, (void*)&orig_glIsProgram},
{"glIsRenderbuffer", wrap_glIsRenderbuffer, (void*)&orig_glIsRenderbuffer},
{"glIsShader", wrap_glIsShader, (void*)&orig_glIsShader},
{"glIsTexture", wrap_glIsTexture, (void*)&orig_glIsTexture},
{"glLineWidth", wrap_glLineWidth, (void*)&orig_glLineWidth},
{"glPixelStorei", wrap_glPixelStorei, (void*)&orig_glPixelStorei},
{"glPolygonOffset", wrap_glPolygonOffset, (void*)&orig_glPolygonOffset},
{"glReadPixels", wrap_glReadPixels, (void*)&orig_glReadPixels},
{"glReleaseShaderCompiler", wrap_glReleaseShaderCompiler, (void*)&orig_glReleaseShaderCompiler},
{"glSampleCoverage", wrap_glSampleCoverage, (void*)&orig_glSampleCoverage},
{"glScissor", wrap_glScissor, (void*)&orig_glScissor},
{"glShaderBinary", wrap_glShaderBinary, (void*)&orig_glShaderBinary},
{"glStencilFunc", wrap_glStencilFunc, (void*)&orig_glStencilFunc},
{"glStencilFuncSeparate", wrap_glStencilFuncSeparate, (void*)&orig_glStencilFuncSeparate},
{"glStencilMask", wrap_glStencilMask, (void*)&orig_glStencilMask},
{"glStencilMaskSeparate", wrap_glStencilMaskSeparate, (void*)&orig_glStencilMaskSeparate},
{"glStencilOp", wrap_glStencilOp, (void*)&orig_glStencilOp},
{"glStencilOpSeparate", wrap_glStencilOpSeparate, (void*)&orig_glStencilOpSeparate},
{"glValidateProgram", wrap_glValidateProgram, (void*)&orig_glValidateProgram},
{"glVertexAttrib1f", wrap_glVertexAttrib1f, (void*)&orig_glVertexAttrib1f},
{"glVertexAttrib1fv", wrap_glVertexAttrib1fv, (void*)&orig_glVertexAttrib1fv},
{"glVertexAttrib2f", wrap_glVertexAttrib2f, (void*)&orig_glVertexAttrib2f},
{"glVertexAttrib2fv", wrap_glVertexAttrib2fv, (void*)&orig_glVertexAttrib2fv},
{"glVertexAttrib3f", wrap_glVertexAttrib3f, (void*)&orig_glVertexAttrib3f},
{"glVertexAttrib3fv", wrap_glVertexAttrib3fv, (void*)&orig_glVertexAttrib3fv},
{"glVertexAttrib4f", wrap_glVertexAttrib4f, (void*)&orig_glVertexAttrib4f},
{"glVertexAttrib4fv", wrap_glVertexAttrib4fv, (void*)&orig_glVertexAttrib4fv},
{"glVertexAttribPointer", wrap_glVertexAttribPointer, (void*)&orig_glVertexAttribPointer},
{"glReadBuffer", wrap_glReadBuffer, (void*)&orig_glReadBuffer},
{"glGenQueries", wrap_glGenQueries, (void*)&orig_glGenQueries},
{"glDeleteQueries", wrap_glDeleteQueries, (void*)&orig_glDeleteQueries},
{"glIsQuery", wrap_glIsQuery, (void*)&orig_glIsQuery},
{"glBeginQuery", wrap_glBeginQuery, (void*)&orig_glBeginQuery},
{"glEndQuery", wrap_glEndQuery, (void*)&orig_glEndQuery},
{"glGetQueryiv", wrap_glGetQueryiv, (void*)&orig_glGetQueryiv},
{"glGetQueryObjectuiv", wrap_glGetQueryObjectuiv, (void*)&orig_glGetQueryObjectuiv},
{"glUnmapBuffer", wrap_glUnmapBuffer, (void*)&orig_glUnmapBuffer},
{"glGetBufferPointerv", wrap_glGetBufferPointerv, (void*)&orig_glGetBufferPointerv},
{"glBlitFramebuffer", wrap_glBlitFramebuffer, (void*)&orig_glBlitFramebuffer},
{"glRenderbufferStorageMultisample", wrap_glRenderbufferStorageMultisample, (void*)&orig_glRenderbufferStorageMultisample},
{"glFramebufferTextureLayer", wrap_glFramebufferTextureLayer, (void*)&orig_glFramebufferTextureLayer},
{"glMapBufferRange", wrap_glMapBufferRange, (void*)&orig_glMapBufferRange},
{"glFlushMappedBufferRange", wrap_glFlushMappedBufferRange, (void*)&orig_glFlushMappedBufferRange},
{"glBindVertexArray", wrap_glBindVertexArray, (void*)&orig_glBindVertexArray},
{"glDeleteVertexArrays", wrap_glDeleteVertexArrays, (void*)&orig_glDeleteVertexArrays},
{"glGenVertexArrays", wrap_glGenVertexArrays, (void*)&orig_glGenVertexArrays},
{"glIsVertexArray", wrap_glIsVertexArray, (void*)&orig_glIsVertexArray},
{"glGetIntegeri_v", wrap_glGetIntegeri_v, (void*)&orig_glGetIntegeri_v},
{"glBeginTransformFeedback", wrap_glBeginTransformFeedback, (void*)&orig_glBeginTransformFeedback},
{"glEndTransformFeedback", wrap_glEndTransformFeedback, (void*)&orig_glEndTransformFeedback},
{"glBindBufferRange", wrap_glBindBufferRange, (void*)&orig_glBindBufferRange},
{"glBindBufferBase", wrap_glBindBufferBase, (void*)&orig_glBindBufferBase},
{"glTransformFeedbackVaryings", wrap_glTransformFeedbackVaryings, (void*)&orig_glTransformFeedbackVaryings},
{"glGetTransformFeedbackVarying", wrap_glGetTransformFeedbackVarying, (void*)&orig_glGetTransformFeedbackVarying},
{"glVertexAttribIPointer", wrap_glVertexAttribIPointer, (void*)&orig_glVertexAttribIPointer},
{"glGetVertexAttribIiv", wrap_glGetVertexAttribIiv, (void*)&orig_glGetVertexAttribIiv},
{"glGetVertexAttribIuiv", wrap_glGetVertexAttribIuiv, (void*)&orig_glGetVertexAttribIuiv},
{"glVertexAttribI4i", wrap_glVertexAttribI4i, (void*)&orig_glVertexAttribI4i},
{"glVertexAttribI4ui", wrap_glVertexAttribI4ui, (void*)&orig_glVertexAttribI4ui},
{"glVertexAttribI4iv", wrap_glVertexAttribI4iv, (void*)&orig_glVertexAttribI4iv},
{"glVertexAttribI4uiv", wrap_glVertexAttribI4uiv, (void*)&orig_glVertexAttribI4uiv},
{"glGetUniformuiv", wrap_glGetUniformuiv, (void*)&orig_glGetUniformuiv},
{"glGetFragDataLocation", wrap_glGetFragDataLocation, (void*)&orig_glGetFragDataLocation},
{"glClearBufferiv", wrap_glClearBufferiv, (void*)&orig_glClearBufferiv},
{"glClearBufferuiv", wrap_glClearBufferuiv, (void*)&orig_glClearBufferuiv},
{"glClearBufferfv", wrap_glClearBufferfv, (void*)&orig_glClearBufferfv},
{"glClearBufferfi", wrap_glClearBufferfi, (void*)&orig_glClearBufferfi},
{"glGetStringi", wrap_glGetStringi, (void*)&orig_glGetStringi},
{"glCopyBufferSubData", wrap_glCopyBufferSubData, (void*)&orig_glCopyBufferSubData},
{"glGetUniformIndices", wrap_glGetUniformIndices, (void*)&orig_glGetUniformIndices},
{"glGetActiveUniformsiv", wrap_glGetActiveUniformsiv, (void*)&orig_glGetActiveUniformsiv},
{"glGetUniformBlockIndex", wrap_glGetUniformBlockIndex, (void*)&orig_glGetUniformBlockIndex},
{"glGetActiveUniformBlockiv", wrap_glGetActiveUniformBlockiv, (void*)&orig_glGetActiveUniformBlockiv},
{"glGetActiveUniformBlockName", wrap_glGetActiveUniformBlockName, (void*)&orig_glGetActiveUniformBlockName},
{"glUniformBlockBinding", wrap_glUniformBlockBinding, (void*)&orig_glUniformBlockBinding},
{"glFenceSync", wrap_glFenceSync, (void*)&orig_glFenceSync},
{"glIsSync", wrap_glIsSync, (void*)&orig_glIsSync},
{"glDeleteSync", wrap_glDeleteSync, (void*)&orig_glDeleteSync},
{"glClientWaitSync", wrap_glClientWaitSync, (void*)&orig_glClientWaitSync},
{"glWaitSync", wrap_glWaitSync, (void*)&orig_glWaitSync},
{"glGetInteger64v", wrap_glGetInteger64v, (void*)&orig_glGetInteger64v},
{"glGetSynciv", wrap_glGetSynciv, (void*)&orig_glGetSynciv},
{"glGetInteger64i_v", wrap_glGetInteger64i_v, (void*)&orig_glGetInteger64i_v},
{"glGetBufferParameteri64v", wrap_glGetBufferParameteri64v, (void*)&orig_glGetBufferParameteri64v},
{"glGenSamplers", wrap_glGenSamplers, (void*)&orig_glGenSamplers},
{"glDeleteSamplers", wrap_glDeleteSamplers, (void*)&orig_glDeleteSamplers},
{"glIsSampler", wrap_glIsSampler, (void*)&orig_glIsSampler},
{"glBindSampler", wrap_glBindSampler, (void*)&orig_glBindSampler},
{"glSamplerParameteri", wrap_glSamplerParameteri, (void*)&orig_glSamplerParameteri},
{"glSamplerParameteriv", wrap_glSamplerParameteriv, (void*)&orig_glSamplerParameteriv},
{"glSamplerParameterf", wrap_glSamplerParameterf, (void*)&orig_glSamplerParameterf},
{"glSamplerParameterfv", wrap_glSamplerParameterfv, (void*)&orig_glSamplerParameterfv},
{"glGetSamplerParameteriv", wrap_glGetSamplerParameteriv, (void*)&orig_glGetSamplerParameteriv},
{"glGetSamplerParameterfv", wrap_glGetSamplerParameterfv, (void*)&orig_glGetSamplerParameterfv},
{"glVertexAttribDivisor", wrap_glVertexAttribDivisor, (void*)&orig_glVertexAttribDivisor},
{"glBindTransformFeedback", wrap_glBindTransformFeedback, (void*)&orig_glBindTransformFeedback},
{"glDeleteTransformFeedbacks", wrap_glDeleteTransformFeedbacks, (void*)&orig_glDeleteTransformFeedbacks},
{"glGenTransformFeedbacks", wrap_glGenTransformFeedbacks, (void*)&orig_glGenTransformFeedbacks},
{"glIsTransformFeedback", wrap_glIsTransformFeedback, (void*)&orig_glIsTransformFeedback},
{"glPauseTransformFeedback", wrap_glPauseTransformFeedback, (void*)&orig_glPauseTransformFeedback},
{"glResumeTransformFeedback", wrap_glResumeTransformFeedback, (void*)&orig_glResumeTransformFeedback},
{"glGetProgramBinary", wrap_glGetProgramBinary, (void*)&orig_glGetProgramBinary},
{"glProgramBinary", wrap_glProgramBinary, (void*)&orig_glProgramBinary},
{"glProgramParameteri", wrap_glProgramParameteri, (void*)&orig_glProgramParameteri},
{"glInvalidateFramebuffer", wrap_glInvalidateFramebuffer, (void*)&orig_glInvalidateFramebuffer},
{"glInvalidateSubFramebuffer", wrap_glInvalidateSubFramebuffer, (void*)&orig_glInvalidateSubFramebuffer},
{"glTexStorage2D", wrap_glTexStorage2D, (void*)&orig_glTexStorage2D},
{"glTexStorage3D", wrap_glTexStorage3D, (void*)&orig_glTexStorage3D},
{"glGetInternalformativ", wrap_glGetInternalformativ, (void*)&orig_glGetInternalformativ},
};

void hookES30GL()
{
    rebind_symbols(rebindings, sizeof(rebindings) / sizeof(rebindings[0]));
    // Should call original functions first to avoid called-only-once issue: https://github.com/facebook/fishhook/issues/36
    void* handle = dlopen(NULL, RTLD_NOW);
    orig_glActiveTexture = dlsym(handle, "glActiveTexture");
    orig_glAttachShader = dlsym(handle, "glAttachShader");
    orig_glBindAttribLocation = dlsym(handle, "glBindAttribLocation");
    orig_glBindBuffer = dlsym(handle, "glBindBuffer");
    orig_glBindFramebuffer = dlsym(handle, "glBindFramebuffer");
    orig_glBindRenderbuffer = dlsym(handle, "glBindRenderbuffer");
    orig_glBindTexture = dlsym(handle, "glBindTexture");
    orig_glBlendColor = dlsym(handle, "glBlendColor");
    orig_glBlendEquation = dlsym(handle, "glBlendEquation");
    orig_glBlendEquationSeparate = dlsym(handle, "glBlendEquationSeparate");
    orig_glBlendFunc = dlsym(handle, "glBlendFunc");
    orig_glBlendFuncSeparate = dlsym(handle, "glBlendFuncSeparate");
    orig_glBufferData = dlsym(handle, "glBufferData");
    orig_glBufferSubData = dlsym(handle, "glBufferSubData");
    orig_glCheckFramebufferStatus = dlsym(handle, "glCheckFramebufferStatus");
    orig_glClear = dlsym(handle, "glClear");
    orig_glClearColor = dlsym(handle, "glClearColor");
    orig_glClearDepthf = dlsym(handle, "glClearDepthf");
    orig_glClearStencil = dlsym(handle, "glClearStencil");
    orig_glColorMask = dlsym(handle, "glColorMask");
    orig_glCompileShader = dlsym(handle, "glCompileShader");
    orig_glCompressedTexImage2D = dlsym(handle, "glCompressedTexImage2D");
    orig_glCompressedTexSubImage2D = dlsym(handle, "glCompressedTexSubImage2D");
    orig_glCopyTexImage2D = dlsym(handle, "glCopyTexImage2D");
    orig_glCopyTexSubImage2D = dlsym(handle, "glCopyTexSubImage2D");
    orig_glCreateProgram = dlsym(handle, "glCreateProgram");
    orig_glCreateShader = dlsym(handle, "glCreateShader");
    orig_glCullFace = dlsym(handle, "glCullFace");
    orig_glDeleteBuffers = dlsym(handle, "glDeleteBuffers");
    orig_glDeleteFramebuffers = dlsym(handle, "glDeleteFramebuffers");
    orig_glDeleteProgram = dlsym(handle, "glDeleteProgram");
    orig_glDeleteRenderbuffers = dlsym(handle, "glDeleteRenderbuffers");
    orig_glDeleteShader = dlsym(handle, "glDeleteShader");
    orig_glDeleteTextures = dlsym(handle, "glDeleteTextures");
    orig_glDepthFunc = dlsym(handle, "glDepthFunc");
    orig_glDepthMask = dlsym(handle, "glDepthMask");
    orig_glDepthRangef = dlsym(handle, "glDepthRangef");
    orig_glDetachShader = dlsym(handle, "glDetachShader");
    orig_glDisable = dlsym(handle, "glDisable");
    orig_glDisableVertexAttribArray = dlsym(handle, "glDisableVertexAttribArray");
    orig_glDrawArrays = dlsym(handle, "glDrawArrays");
    orig_glDrawElements = dlsym(handle, "glDrawElements");
    orig_glEnable = dlsym(handle, "glEnable");
    orig_glEnableVertexAttribArray = dlsym(handle, "glEnableVertexAttribArray");
    orig_glFinish = dlsym(handle, "glFinish");
    orig_glFlush = dlsym(handle, "glFlush");
    orig_glFramebufferRenderbuffer = dlsym(handle, "glFramebufferRenderbuffer");
    orig_glFramebufferTexture2D = dlsym(handle, "glFramebufferTexture2D");
    orig_glFrontFace = dlsym(handle, "glFrontFace");
    orig_glGenBuffers = dlsym(handle, "glGenBuffers");
    orig_glGenerateMipmap = dlsym(handle, "glGenerateMipmap");
    orig_glGenFramebuffers = dlsym(handle, "glGenFramebuffers");
    orig_glGenRenderbuffers = dlsym(handle, "glGenRenderbuffers");
    orig_glGenTextures = dlsym(handle, "glGenTextures");
    orig_glGetActiveAttrib = dlsym(handle, "glGetActiveAttrib");
    orig_glGetActiveUniform = dlsym(handle, "glGetActiveUniform");
    orig_glGetAttachedShaders = dlsym(handle, "glGetAttachedShaders");
    orig_glGetAttribLocation = dlsym(handle, "glGetAttribLocation");
    orig_glGetBooleanv = dlsym(handle, "glGetBooleanv");
    orig_glGetBufferParameteriv = dlsym(handle, "glGetBufferParameteriv");
    orig_glGetError = dlsym(handle, "glGetError");
    orig_glGetFloatv = dlsym(handle, "glGetFloatv");
    orig_glGetFramebufferAttachmentParameteriv = dlsym(handle, "glGetFramebufferAttachmentParameteriv");
    orig_glGetIntegerv = dlsym(handle, "glGetIntegerv");
    orig_glGetProgramiv = dlsym(handle, "glGetProgramiv");
    orig_glGetProgramInfoLog = dlsym(handle, "glGetProgramInfoLog");
    orig_glGetRenderbufferParameteriv = dlsym(handle, "glGetRenderbufferParameteriv");
    orig_glGetShaderiv = dlsym(handle, "glGetShaderiv");
    orig_glGetShaderInfoLog = dlsym(handle, "glGetShaderInfoLog");
    orig_glGetShaderPrecisionFormat = dlsym(handle, "glGetShaderPrecisionFormat");
    orig_glGetShaderSource = dlsym(handle, "glGetShaderSource");
    orig_glGetString = dlsym(handle, "glGetString");
    orig_glGetTexParameterfv = dlsym(handle, "glGetTexParameterfv");
    orig_glGetTexParameteriv = dlsym(handle, "glGetTexParameteriv");
    orig_glGetUniformfv = dlsym(handle, "glGetUniformfv");
    orig_glGetUniformiv = dlsym(handle, "glGetUniformiv");
    orig_glGetUniformLocation = dlsym(handle, "glGetUniformLocation");
    orig_glGetVertexAttribfv = dlsym(handle, "glGetVertexAttribfv");
    orig_glGetVertexAttribiv = dlsym(handle, "glGetVertexAttribiv");
    orig_glGetVertexAttribPointerv = dlsym(handle, "glGetVertexAttribPointerv");
    orig_glHint = dlsym(handle, "glHint");
    orig_glIsBuffer = dlsym(handle, "glIsBuffer");
    orig_glIsEnabled = dlsym(handle, "glIsEnabled");
    orig_glIsFramebuffer = dlsym(handle, "glIsFramebuffer");
    orig_glIsProgram = dlsym(handle, "glIsProgram");
    orig_glIsRenderbuffer = dlsym(handle, "glIsRenderbuffer");
    orig_glIsShader = dlsym(handle, "glIsShader");
    orig_glIsTexture = dlsym(handle, "glIsTexture");
    orig_glLineWidth = dlsym(handle, "glLineWidth");
    orig_glLinkProgram = dlsym(handle, "glLinkProgram");
    orig_glPixelStorei = dlsym(handle, "glPixelStorei");
    orig_glPolygonOffset = dlsym(handle, "glPolygonOffset");
    orig_glReadPixels = dlsym(handle, "glReadPixels");
    orig_glReleaseShaderCompiler = dlsym(handle, "glReleaseShaderCompiler");
    orig_glRenderbufferStorage = dlsym(handle, "glRenderbufferStorage");
    orig_glSampleCoverage = dlsym(handle, "glSampleCoverage");
    orig_glScissor = dlsym(handle, "glScissor");
    orig_glShaderBinary = dlsym(handle, "glShaderBinary");
    orig_glShaderSource = dlsym(handle, "glShaderSource");
    orig_glStencilFunc = dlsym(handle, "glStencilFunc");
    orig_glStencilFuncSeparate = dlsym(handle, "glStencilFuncSeparate");
    orig_glStencilMask = dlsym(handle, "glStencilMask");
    orig_glStencilMaskSeparate = dlsym(handle, "glStencilMaskSeparate");
    orig_glStencilOp = dlsym(handle, "glStencilOp");
    orig_glStencilOpSeparate = dlsym(handle, "glStencilOpSeparate");
    orig_glTexImage2D = dlsym(handle, "glTexImage2D");
    orig_glTexParameterf = dlsym(handle, "glTexParameterf");
    orig_glTexParameterfv = dlsym(handle, "glTexParameterfv");
    orig_glTexParameteri = dlsym(handle, "glTexParameteri");
    orig_glTexParameteriv = dlsym(handle, "glTexParameteriv");
    orig_glTexSubImage2D = dlsym(handle, "glTexSubImage2D");
    orig_glUniform1f = dlsym(handle, "glUniform1f");
    orig_glUniform1fv = dlsym(handle, "glUniform1fv");
    orig_glUniform1i = dlsym(handle, "glUniform1i");
    orig_glUniform1iv = dlsym(handle, "glUniform1iv");
    orig_glUniform2f = dlsym(handle, "glUniform2f");
    orig_glUniform2fv = dlsym(handle, "glUniform2fv");
    orig_glUniform2i = dlsym(handle, "glUniform2i");
    orig_glUniform2iv = dlsym(handle, "glUniform2iv");
    orig_glUniform3f = dlsym(handle, "glUniform3f");
    orig_glUniform3fv = dlsym(handle, "glUniform3fv");
    orig_glUniform3i = dlsym(handle, "glUniform3i");
    orig_glUniform3iv = dlsym(handle, "glUniform3iv");
    orig_glUniform4f = dlsym(handle, "glUniform4f");
    orig_glUniform4fv = dlsym(handle, "glUniform4fv");
    orig_glUniform4i = dlsym(handle, "glUniform4i");
    orig_glUniform4iv = dlsym(handle, "glUniform4iv");
    orig_glUniformMatrix2fv = dlsym(handle, "glUniformMatrix2fv");
    orig_glUniformMatrix3fv = dlsym(handle, "glUniformMatrix3fv");
    orig_glUniformMatrix4fv = dlsym(handle, "glUniformMatrix4fv");
    orig_glUseProgram = dlsym(handle, "glUseProgram");
    orig_glValidateProgram = dlsym(handle, "glValidateProgram");
    orig_glVertexAttrib1f = dlsym(handle, "glVertexAttrib1f");
    orig_glVertexAttrib1fv = dlsym(handle, "glVertexAttrib1fv");
    orig_glVertexAttrib2f = dlsym(handle, "glVertexAttrib2f");
    orig_glVertexAttrib2fv = dlsym(handle, "glVertexAttrib2fv");
    orig_glVertexAttrib3f = dlsym(handle, "glVertexAttrib3f");
    orig_glVertexAttrib3fv = dlsym(handle, "glVertexAttrib3fv");
    orig_glVertexAttrib4f = dlsym(handle, "glVertexAttrib4f");
    orig_glVertexAttrib4fv = dlsym(handle, "glVertexAttrib4fv");
    orig_glVertexAttribPointer = dlsym(handle, "glVertexAttribPointer");
    orig_glViewport = dlsym(handle, "glViewport");
    orig_glReadBuffer = dlsym(handle, "glReadBuffer");
    orig_glDrawRangeElements = dlsym(handle, "glDrawRangeElements");
    orig_glTexImage3D = dlsym(handle, "glTexImage3D");
    orig_glTexSubImage3D = dlsym(handle, "glTexSubImage3D");
    orig_glCopyTexSubImage3D = dlsym(handle, "glCopyTexSubImage3D");
    orig_glCompressedTexImage3D = dlsym(handle, "glCompressedTexImage3D");
    orig_glCompressedTexSubImage3D = dlsym(handle, "glCompressedTexSubImage3D");
    orig_glGenQueries = dlsym(handle, "glGenQueries");
    orig_glDeleteQueries = dlsym(handle, "glDeleteQueries");
    orig_glIsQuery = dlsym(handle, "glIsQuery");
    orig_glBeginQuery = dlsym(handle, "glBeginQuery");
    orig_glEndQuery = dlsym(handle, "glEndQuery");
    orig_glGetQueryiv = dlsym(handle, "glGetQueryiv");
    orig_glGetQueryObjectuiv = dlsym(handle, "glGetQueryObjectuiv");
    orig_glUnmapBuffer = dlsym(handle, "glUnmapBuffer");
    orig_glGetBufferPointerv = dlsym(handle, "glGetBufferPointerv");
    orig_glDrawBuffers = dlsym(handle, "glDrawBuffers");
    orig_glUniformMatrix2x3fv = dlsym(handle, "glUniformMatrix2x3fv");
    orig_glUniformMatrix3x2fv = dlsym(handle, "glUniformMatrix3x2fv");
    orig_glUniformMatrix2x4fv = dlsym(handle, "glUniformMatrix2x4fv");
    orig_glUniformMatrix4x2fv = dlsym(handle, "glUniformMatrix4x2fv");
    orig_glUniformMatrix3x4fv = dlsym(handle, "glUniformMatrix3x4fv");
    orig_glUniformMatrix4x3fv = dlsym(handle, "glUniformMatrix4x3fv");
    orig_glBlitFramebuffer = dlsym(handle, "glBlitFramebuffer");
    orig_glRenderbufferStorageMultisample = dlsym(handle, "glRenderbufferStorageMultisample");
    orig_glFramebufferTextureLayer = dlsym(handle, "glFramebufferTextureLayer");
    orig_glMapBufferRange = dlsym(handle, "glMapBufferRange");
    orig_glFlushMappedBufferRange = dlsym(handle, "glFlushMappedBufferRange");
    orig_glBindVertexArray = dlsym(handle, "glBindVertexArray");
    orig_glDeleteVertexArrays = dlsym(handle, "glDeleteVertexArrays");
    orig_glGenVertexArrays = dlsym(handle, "glGenVertexArrays");
    orig_glIsVertexArray = dlsym(handle, "glIsVertexArray");
    orig_glGetIntegeri_v = dlsym(handle, "glGetIntegeri_v");
    orig_glBeginTransformFeedback = dlsym(handle, "glBeginTransformFeedback");
    orig_glEndTransformFeedback = dlsym(handle, "glEndTransformFeedback");
    orig_glBindBufferRange = dlsym(handle, "glBindBufferRange");
    orig_glBindBufferBase = dlsym(handle, "glBindBufferBase");
    orig_glTransformFeedbackVaryings = dlsym(handle, "glTransformFeedbackVaryings");
    orig_glGetTransformFeedbackVarying = dlsym(handle, "glGetTransformFeedbackVarying");
    orig_glVertexAttribIPointer = dlsym(handle, "glVertexAttribIPointer");
    orig_glGetVertexAttribIiv = dlsym(handle, "glGetVertexAttribIiv");
    orig_glGetVertexAttribIuiv = dlsym(handle, "glGetVertexAttribIuiv");
    orig_glVertexAttribI4i = dlsym(handle, "glVertexAttribI4i");
    orig_glVertexAttribI4ui = dlsym(handle, "glVertexAttribI4ui");
    orig_glVertexAttribI4iv = dlsym(handle, "glVertexAttribI4iv");
    orig_glVertexAttribI4uiv = dlsym(handle, "glVertexAttribI4uiv");
    orig_glGetUniformuiv = dlsym(handle, "glGetUniformuiv");
    orig_glGetFragDataLocation = dlsym(handle, "glGetFragDataLocation");
    orig_glUniform1ui = dlsym(handle, "glUniform1ui");
    orig_glUniform2ui = dlsym(handle, "glUniform2ui");
    orig_glUniform3ui = dlsym(handle, "glUniform3ui");
    orig_glUniform4ui = dlsym(handle, "glUniform4ui");
    orig_glUniform1uiv = dlsym(handle, "glUniform1uiv");
    orig_glUniform2uiv = dlsym(handle, "glUniform2uiv");
    orig_glUniform3uiv = dlsym(handle, "glUniform3uiv");
    orig_glUniform4uiv = dlsym(handle, "glUniform4uiv");
    orig_glClearBufferiv = dlsym(handle, "glClearBufferiv");
    orig_glClearBufferuiv = dlsym(handle, "glClearBufferuiv");
    orig_glClearBufferfv = dlsym(handle, "glClearBufferfv");
    orig_glClearBufferfi = dlsym(handle, "glClearBufferfi");
    orig_glGetStringi = dlsym(handle, "glGetStringi");
    orig_glCopyBufferSubData = dlsym(handle, "glCopyBufferSubData");
    orig_glGetUniformIndices = dlsym(handle, "glGetUniformIndices");
    orig_glGetActiveUniformsiv = dlsym(handle, "glGetActiveUniformsiv");
    orig_glGetUniformBlockIndex = dlsym(handle, "glGetUniformBlockIndex");
    orig_glGetActiveUniformBlockiv = dlsym(handle, "glGetActiveUniformBlockiv");
    orig_glGetActiveUniformBlockName = dlsym(handle, "glGetActiveUniformBlockName");
    orig_glUniformBlockBinding = dlsym(handle, "glUniformBlockBinding");
    orig_glDrawArraysInstanced = dlsym(handle, "glDrawArraysInstanced");
    orig_glDrawElementsInstanced = dlsym(handle, "glDrawElementsInstanced");
    orig_glFenceSync = dlsym(handle, "glFenceSync");
    orig_glIsSync = dlsym(handle, "glIsSync");
    orig_glDeleteSync = dlsym(handle, "glDeleteSync");
    orig_glClientWaitSync = dlsym(handle, "glClientWaitSync");
    orig_glWaitSync = dlsym(handle, "glWaitSync");
    orig_glGetInteger64v = dlsym(handle, "glGetInteger64v");
    orig_glGetSynciv = dlsym(handle, "glGetSynciv");
    orig_glGetInteger64i_v = dlsym(handle, "glGetInteger64i_v");
    orig_glGetBufferParameteri64v = dlsym(handle, "glGetBufferParameteri64v");
    orig_glGenSamplers = dlsym(handle, "glGenSamplers");
    orig_glDeleteSamplers = dlsym(handle, "glDeleteSamplers");
    orig_glIsSampler = dlsym(handle, "glIsSampler");
    orig_glBindSampler = dlsym(handle, "glBindSampler");
    orig_glSamplerParameteri = dlsym(handle, "glSamplerParameteri");
    orig_glSamplerParameteriv = dlsym(handle, "glSamplerParameteriv");
    orig_glSamplerParameterf = dlsym(handle, "glSamplerParameterf");
    orig_glSamplerParameterfv = dlsym(handle, "glSamplerParameterfv");
    orig_glGetSamplerParameteriv = dlsym(handle, "glGetSamplerParameteriv");
    orig_glGetSamplerParameterfv = dlsym(handle, "glGetSamplerParameterfv");
    orig_glVertexAttribDivisor = dlsym(handle, "glVertexAttribDivisor");
    orig_glBindTransformFeedback = dlsym(handle, "glBindTransformFeedback");
    orig_glDeleteTransformFeedbacks = dlsym(handle, "glDeleteTransformFeedbacks");
    orig_glGenTransformFeedbacks = dlsym(handle, "glGenTransformFeedbacks");
    orig_glIsTransformFeedback = dlsym(handle, "glIsTransformFeedback");
    orig_glPauseTransformFeedback = dlsym(handle, "glPauseTransformFeedback");
    orig_glResumeTransformFeedback = dlsym(handle, "glResumeTransformFeedback");
    orig_glGetProgramBinary = dlsym(handle, "glGetProgramBinary");
    orig_glProgramBinary = dlsym(handle, "glProgramBinary");
    orig_glProgramParameteri = dlsym(handle, "glProgramParameteri");
    orig_glInvalidateFramebuffer = dlsym(handle, "glInvalidateFramebuffer");
    orig_glInvalidateSubFramebuffer = dlsym(handle, "glInvalidateSubFramebuffer");
    orig_glTexStorage2D = dlsym(handle, "glTexStorage2D");
    orig_glTexStorage3D = dlsym(handle, "glTexStorage3D");
    orig_glGetInternalformativ = dlsym(handle, "glGetInternalformativ");
    dlclose(handle);
}

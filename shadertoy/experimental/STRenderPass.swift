//
//  ShaderToyShaderPass.swift
//  ShaMderToy
//
//  Created by qiudong on 2021/8/18.
//

#if os(macOS)
import GLKit
#elseif os(iOS)
import OpenGLES
#endif //#if os(macOS)

let ShaderToyFixedUniforms: String = """
uniform vec3      iResolution;
uniform float     iTime;
uniform float     iTimeDelta;
uniform int       iFrame;
uniform float     iChannelTime[4];
uniform vec3      iChannelResolution[4];
struct Channel {
    vec3    resolution;
    float   time;
};
uniform Channel iChannel[4];
///!!!uniform vec4      iMouse;
const vec4 iMouse = vec4(0.0);
uniform vec4      iDate;
uniform float     iSampleRate;
uniform float     iFrameRate;
""";

let ShaderToyFragmentMain: String = """
in vec2 _uv;
in vec2 _fragCoord;
layout(location=0) out vec4 FragColor;
uniform sampler2D _MainTex;
void main()
{
    mainImage(FragColor, _fragCoord);
    ///??? gl_FragDepth = 1.0;
}
""";

let ShaderToyVertex: String = """

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texcoord;
out vec2 _uv;
out vec2 _fragCoord;
uniform mat4 u_MVP;
uniform vec2 _ShadowOffset;
void main() {
  gl_Position = vec4(position, 1.0);
  _uv = texcoord;
  _fragCoord = texcoord * iResolution.xy;
}
""";

let StandardQuadMeshData: [Float] = [
    -1,-1,0,
    0,0,
    
    1,-1,0,
    1,0,
    
    -1,1,0,
    0,1,
    
    1,1,0,
    1,1,
]

class STRenderPass: STProcessor {
    enum GLProgramSlotKey : Int {
        case position
        case texcoord
        case iResolution
        case iTime
        case iTimeDelta
        case iFrame
        case iMouse
        case iDate
        case iSampleRate
        case iFrameRate
        case iChannelResolution
        case iChannelTime
        case iChannel0
        case iChannel1
        case iChannel2
        case iChannel3
        case iChannel0Time
        case iChannel1Time
        case iChannel2Time
        case iChannel3Time
        case iChannel0Resolution
        case iChannel1Resolution
        case iChannel2Resolution
        case iChannel3Resolution
    }
    
    func createGLObjectsIfNecessary() {
//        print("#List#Cache#Leak# ShaderPass createGLObjectsIfNecessary : \((self as AnyObject).hash!)");
        glGenBuffers(1, &_vbo);
        CHECK_GL_ERROR();
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), _vbo);
        let dataSize = MemoryLayout<Float>.stride * StandardQuadMeshData.count;
//        let dataSize = MemoryLayout.size(ofValue: standardQuadMeshData);
        glBufferData(GLenum(GL_ARRAY_BUFFER), dataSize, StandardQuadMeshData, GLenum(GL_STATIC_DRAW));
        var vertexShaderSources: [String] = [];
        var fragmentShaderSources: [String] = [];
        
        var iChannelUniformsDeclaration: String = "";
        var channelsAssigned = Set<Int>();
        for elm in _stShaderPass.inputs
        {
            guard let input = elm as? APIShaderPassInput else { continue; }
            let channel = input.channel.intValue;
            channelsAssigned.insert(channel);
            switch input.type.intValue
            {
            case STInputType.cubemap.rawValue:
                iChannelUniformsDeclaration.append("uniform highp samplerCube iChannel\(channel);\n");
            case STInputType.volume.rawValue:
                iChannelUniformsDeclaration.append("uniform highp sampler3D iChannel\(channel);\n");
            default:
                iChannelUniformsDeclaration.append("uniform highp sampler2D iChannel\(channel);\n");
            }
        }
        for i in 0..<Self.MaxChannels
        {
            if (!channelsAssigned.contains(i))
            {
                iChannelUniformsDeclaration.append("uniform highp sampler2D iChannel\(i);\n");
            }
        }
        #if os(iOS)
        vertexShaderSources.append("#version 300 es");
        fragmentShaderSources.append("""
#version 300 es
precision highp float;
precision highp int;
precision highp sampler2D;
precision highp sampler3D;
""");
        #elseif os(macOS)
        vertexShaderSources.append("#version 410");
        fragmentShaderSources.append("#version 410");
        #endif
        vertexShaderSources.append(ShaderToyFixedUniforms);
        vertexShaderSources.append(iChannelUniformsDeclaration);
        fragmentShaderSources.append(ShaderToyFixedUniforms);
        fragmentShaderSources.append(iChannelUniformsDeclaration);
        if let commonPass = _stCommonPass
        {
            fragmentShaderSources.append(commonPass.code);
        }
        vertexShaderSources.append(ShaderToyVertex);
        
        fragmentShaderSources.append("#define HW_PERFORMANCE 1")
        
        fragmentShaderSources.append("PlaceHolder");
        
        fragmentShaderSources.append(ShaderToyFragmentMain);
        
        _vao = 0;
        if (_stShaderPass.type.intValue != STPassType.image.rawValue)
        {
            _renderTexture = GLRenderTexture(texture: 0, textureTarget: GLenum(GL_TEXTURE_2D), width: 256, height: 256, depth: 1, internalFormat: GL_RGBA16F, format: GLenum(GL_RGBA), dataType: GLenum(GL_HALF_FLOAT), enableDepthTest: false);
            if (nil != _outputID)
            {
                _renderTexture1 = GLRenderTexture(texture: 0, textureTarget: GLenum(GL_TEXTURE_2D), width: 256, height: 256, depth: 1, internalFormat: GL_RGBA16F, format: GLenum(GL_RGBA), dataType: GLenum(GL_HALF_FLOAT), enableDepthTest: false);
            }
        }
        
        fragmentShaderSources[fragmentShaderSources.count - 2] = _stShaderPass.code.replacingOccurrences(of: "precision ", with: "//precision ");
//        print("#DEBUG# vertexShaderSources:\n\(vertexShaderSources)\nfragmentShaderSources:\n\(fragmentShaderSources)");///!!!
        guard let program = try? GLProgram(vertexShaderSources, fragmentShaderSources)
        else
        {
            return;
        }
        _drawQuadProgram = program;
        
        program.bindUniformSlot("iResolution", GLProgramSlotKey.iResolution.rawValue);
        program.bindUniformSlot("iTime", GLProgramSlotKey.iTime.rawValue);
        program.bindUniformSlot("iTimeDelta", GLProgramSlotKey.iTimeDelta.rawValue);
        program.bindUniformSlot("iFrame", GLProgramSlotKey.iFrame.rawValue);
        program.bindUniformSlot("iMouse", GLProgramSlotKey.iMouse.rawValue);
        program.bindUniformSlot("iDate", GLProgramSlotKey.iDate.rawValue);
        program.bindUniformSlot("iSampleRate", GLProgramSlotKey.iSampleRate.rawValue);
        program.bindUniformSlot("iFrameRate", GLProgramSlotKey.iFrameRate.rawValue);
        program.bindUniformSlot("iChannelResolution", GLProgramSlotKey.iChannelResolution.rawValue);
        program.bindUniformSlot("iChannelTime", GLProgramSlotKey.iChannelTime.rawValue);
        program.bindUniformSlot("iChannel0", GLProgramSlotKey.iChannel0.rawValue);
        program.bindUniformSlot("iChannel1", GLProgramSlotKey.iChannel1.rawValue);
        program.bindUniformSlot("iChannel2", GLProgramSlotKey.iChannel2.rawValue);
        program.bindUniformSlot("iChannel3", GLProgramSlotKey.iChannel3.rawValue);
        program.bindUniformSlot("iChannel[0].time", GLProgramSlotKey.iChannel0Time.rawValue);
        program.bindUniformSlot("iChannel[1].time", GLProgramSlotKey.iChannel1Time.rawValue);
        program.bindUniformSlot("iChannel[2].time", GLProgramSlotKey.iChannel2Time.rawValue);
        program.bindUniformSlot("iChannel[3].time", GLProgramSlotKey.iChannel3Time.rawValue);
        program.bindUniformSlot("iChannel[0].resolution", GLProgramSlotKey.iChannel0Resolution.rawValue);
        program.bindUniformSlot("iChannel[1].resolution", GLProgramSlotKey.iChannel1Resolution.rawValue);
        program.bindUniformSlot("iChannel[2].resolution", GLProgramSlotKey.iChannel2Resolution.rawValue);
        program.bindUniformSlot("iChannel[3].resolution", GLProgramSlotKey.iChannel3Resolution.rawValue);
        
        let positionSlot = GLuint(program.bindVertexAttributeSlot("position", GLProgramSlotKey.position.rawValue));
        let texcoordSlot = GLuint(program.bindVertexAttributeSlot("texcoord", GLProgramSlotKey.texcoord.rawValue));
        
        glGenVertexArrays(1, &_vao);
        glBindVertexArray(_vao);
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), _vbo);
//        print("#ShaderToy# _vao=\(_vao), _vbo=\(_vbo), dataSize=\(dataSize)");
        CHECK_GL_ERROR();
//        print("#ShaderToy# Setting vertex attrib pointers");
        glEnableVertexAttribArray(positionSlot);
        glEnableVertexAttribArray(texcoordSlot);
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), 0, GLsizei(MemoryLayout<Float>.stride * 5), UnsafeRawPointer(bitPattern: 0));
        glVertexAttribPointer(texcoordSlot, 2, GLenum(GL_FLOAT), 0, GLsizei(MemoryLayout<Float>.stride * 5), UnsafeRawPointer(bitPattern: MemoryLayout<Float>.stride * 3));
        CHECK_GL_ERROR();
    }
    
    func releaseGLObjectsIfNecessary() {
//        print("#List#Cache#Leak# ShaderPass releaseGLObjectsIfNecessary : \((self as AnyObject).hash!)");
        glDeleteBuffers(1, &_vbo);
        _vbo = 0;
        glDeleteVertexArrays(1, &_vao);
        _vao = 0;
        _renderTexture = nil;
        _renderTexture1 = nil;
        if let _ = _drawQuadProgram
        {
            //glDeleteProgram(program.program);
            _drawQuadProgram = nil;
        }
    }
    
    override func process(timestamp: Float, frameCount: Int, width: GLint, height: GLint) -> Bool {
        super.process(timestamp: timestamp, frameCount: frameCount, width: width, height: height);
//        print("#List#Halt# ShaderPass.process Begin : \(_stShaderPass.name)");
//        defer {
//            print("#List#Halt# ShaderPass.process End : \(_stShaderPass.name)");
//        }
//#if os(iOS)
//        let glContext = CVEAGLContext.current();
//        print("#ST#Reuse# render by \((self as AnyObject).hash!) in context{\(glContext!.hash)}");
//#endif //#if os(iOS)
        _width = Int(width);
        _height = Int(height);
        if let rt = (0 == _currentRTIndex) ? _renderTexture : _renderTexture1
        {
            rt.resizeIfNecessary(width, height, 1);
            rt.blit();
        }
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        CHECK_GL_ERROR();
        if let glProgram = _drawQuadProgram
        {
            glUseProgram(glProgram.program);
            //TODO: Bind input textures:
            for elm in _stShaderPass.inputs
            {
                guard let input = elm as? APIShaderPassInput else { continue; }
                let channel = input.channel.intValue;
                if (channel < 0 || channel > 3) { continue; }
                
                let iChannelSlot = glProgram.slot(of: "iChannel\(channel)");
                if (iChannelSlot >= 0)
                {
                    let texture = _inputTextureOfChannel[channel];
                    glUniform1i(iChannelSlot, GLint(channel));
                    // glActiveTexture calling should precede to that of glBindTexture:
                    glActiveTexture(GLenum(Int(GL_TEXTURE0) + channel));
                    glBindTexture(GLenum(GL_TEXTURE_2D), texture);
                    STInputSource.setTextureParams(textureID: texture, shadertoyInput: input);
                    if (input.type.intValue == STInputType.buffer.rawValue)
                    {
                        let textureTarget = STInputSource.textureTarget(of: input);
                        if (input.sampler.filter.intValue == STSamplerFilter.mipmap.rawValue && !_mipmapGenerated.contains(texture))
                        {
                            glGenerateMipmap(textureTarget);
                            _mipmapGenerated.insert(texture);
                        }
                    }
                }
                
                let iChannelResSlot = glProgram.slot(of: "iChannel[\(channel)].resolution");
                if (iChannelResSlot >= 0)
                {
                    glUniform3f(iChannelResSlot, _channelResolutions[3 * channel], _channelResolutions[3 * channel + 1], _channelResolutions[3 * channel + 2]);
                }
                
                let iChannelTimeSlot = glProgram.slot(of: "iChannel[\(channel)].time");
                if (iChannelTimeSlot >= 0)
                {
                    glUniform1f(iChannelTimeSlot, _channelTime[channel]);
                }
            }
            let iChannelResolutionsSlot = glProgram.slot(of: GLProgramSlotKey.iChannelResolution.rawValue);
            if (iChannelResolutionsSlot >= 0)
            {
                glUniform3fv(iChannelResolutionsSlot, 4, &_channelResolutions);
            }
            let iChannelTimesSlot = glProgram.slot(of: GLProgramSlotKey.iChannelTime.rawValue);
            if (iChannelTimesSlot >= 0)
            {
                glUniform1fv(iChannelTimesSlot, 4, &_channelTime);
            }
            CHECK_GL_ERROR();
            let iResolutionSlot = glProgram.slot(of: GLProgramSlotKey.iResolution.rawValue);
            glUniform3f(iResolutionSlot, GLfloat(width), GLfloat(height), GLfloat(0.0));
            CHECK_GL_ERROR();
            glUniform1f(glProgram.slot(of: GLProgramSlotKey.iTime.rawValue), timestamp);
            let iFrameSlot = glProgram.slot(of: GLProgramSlotKey.iFrame.rawValue);
//            if (nil != _outputID && frameCount < 2)
//            {
//                glUniform1i(iFrameSlot, 0);
//            }
//            else
//            {
                glUniform1i(iFrameSlot, GLint(frameCount));
//            }
            let now = Date();
            let dateComponents = Calendar.current.dateComponents(Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second]), from: now);
            var totalSeconds = GLfloat(now.timeIntervalSince1970);
            let year = GLfloat(dateComponents.year!);
            let month = GLfloat(dateComponents.month!);
            let day = GLfloat(dateComponents.day!);
            let hour = GLfloat(dateComponents.hour!);
            let minute = GLfloat(dateComponents.minute!);
            let second = GLfloat(dateComponents.second!);
            totalSeconds = GLfloat((hour * 60 * 60) + (minute * 60) + second + (totalSeconds - floor(second)));
            glUniform4f(glProgram.slot(of: GLProgramSlotKey.iDate.rawValue), year, month, day, totalSeconds);
//            print("#Invalid# iFrameSlot=\(iFrameSlot), frameCount=\(frameCount)");
            CHECK_GL_ERROR();
    //        uniform float     iTimeDelta;
    //        uniform vec4      iDate;
    //        uniform float     iSampleRate;
    //        uniform float     iFrameRate;
            glBindVertexArray(_vao);
            CHECK_GL_ERROR();
            glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4);
            CHECK_GL_ERROR();
        }
        else
        {
            return false;
        }
//        var attachment = GLenum(GL_DEPTH_ATTACHMENT);
//        glInvalidateFramebuffer(GLenum(GL_FRAMEBUFFER), 1, &attachment);
        if let rt = (0 == _currentRTIndex) ? _renderTexture : _renderTexture1
        {
            if (nil != _outputID)
            {
                _currentRTIndex = 1 - _currentRTIndex;
            }
            rt.unblit();
        }
        CHECK_GL_ERROR();
        return true;
    }
    
    override var targetTexture: GLuint {
        get {
            if (nil != _outputID)
            {
                guard let rt = (0 == _currentRTIndex) ? _renderTexture1 : _renderTexture
                else
                {
                    return 0;
                }
                return rt.texture;
            }
            else
            {
                guard let rt = _renderTexture
                else
                {
                    return 0;
                }
                return rt.texture;
            }
        }
    }
    
    override var resolution: MTLSize {
        get {
            return MTLSize(width: _width, height: _height, depth: _depth);
        }
    }
    
    func setInputTexture(for channel: Int, with textureID: GLuint) {
        if (channel < 0 || channel >= Self.MaxChannels)
        {
            return;
        }
        _inputTextureOfChannel[channel] = textureID;
    }
    
    func setInputResolution(for channel: Int, with size: MTLSize) {
        if (channel < 0 || channel >= Self.MaxChannels)
        {
            return;
        }
        _channelResolutions[3 * channel] = GLfloat(size.width);
        _channelResolutions[3 * channel + 1] = GLfloat(size.height);
        _channelResolutions[3 * channel + 2] = GLfloat(size.depth);
    }
    
    func setInputTime(for channel: Int, with time: TimeInterval) {
        if (channel < 0 || channel >= Self.MaxChannels)
        {
            return;
        }
        _channelTime[channel] = GLfloat(time);
    }
    
    deinit {
//        print("#List#Cache#Leak# ShaderPass.deinit : \((self as AnyObject).hash!)");
        releaseGLObjectsIfNecessary();
    }
    
    required init(_ shaderPassModel: APIShaderPass, _ commonPassModel: APIShaderPass?) {
        _stShaderPass = shaderPassModel;
        _stCommonPass = commonPassModel;
        super.init();
//        print("#List#Cache#Leak# ShaderPass.init : \((self as AnyObject).hash!)");
        if (_stShaderPass.outputs.count > 0)
        {
            if let output = _stShaderPass.outputs[0] as? APIShaderPassOutput
            {
                for elm in _stShaderPass.inputs
                {
                    guard let input = elm as? APIShaderPassInput else { continue; }
                    if (input.inputId != nil && input.inputId == output.outputId)
                    {
                        _outputID = output.outputId;
                        break;
                    }
                }
            }
        }
        createGLObjectsIfNecessary();
    }
    
//    override func hash(into hasher: inout Hasher) {
//        _stShaderPass.name.hash(into: &hasher);
//        _stShaderPass.type.hash(into: &hasher);
//        _stShaderPass.code.hash(into: &hasher);
//        _stShaderPass.inputs.hash(into: &hasher);
//        _stShaderPass.outputs.hash(into: &hasher);
//    }
    override var hash: Int {
        get {
            return self._hash;
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? STRenderPass
        {
            return other._stShaderPass.name == self._stShaderPass.name;
        }
        return false;
    }
    
    private lazy var _hash: Int = "\(_stShaderPass.name.hash)\(_stShaderPass.type.hash)\(_stShaderPass.code.hash)\(_stShaderPass.inputs.hash)\(_stShaderPass.outputs.hash)".hash
    
    private var _stShaderPass: APIShaderPass
    private var _stCommonPass: APIShaderPass?
    
    private var _vbo: GLuint = 0
    
    private var _vao: GLuint = 0
    private var _drawQuadProgram: GLProgram? = nil
    
    private var _renderTexture: GLRenderTexture? = nil
    private var _renderTexture1: GLRenderTexture? = nil
    private var _currentRTIndex: Int8 = 0
    private var _outputID: String? = nil
    
    private static let MaxChannels = 4
    private var _inputTextureOfChannel: [GLuint] = [GLuint](repeating: 0, count: MaxChannels)
    private var _mipmapGenerated: Set<GLuint> = [];
    private var _channelResolutions: [GLfloat] = [GLfloat](repeating: 0.0, count: 3 * MaxChannels)
    private var _channelTime: [GLfloat] = [GLfloat](repeating: 0.0, count: MaxChannels)
    
    private var _width: Int = 0
    private var _height: Int = 0
    private var _depth: Int = 1
}

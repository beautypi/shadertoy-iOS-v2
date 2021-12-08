//
//  ShaderToyInputSource.swift
//  ShaMderToy
//
//  Created by Dom Chiu on 2021/8/2.
//

#if os(iOS)
import OpenGLES
#elseif os(macOS)
import OpenGL
#endif

class TextureCache : NSObject, NSCacheDelegate {
    class CacheItem {
        let texture: GLuint
        let width: GLuint
        let height: GLuint
        let depth: GLuint
        
        required init(texture: GLuint, width: GLuint, height: GLuint, depth: GLuint) {
            self.texture = texture;
            self.width = width;
            self.height = height;
            self.depth = depth;
        }
    }

    private var _cache: NSCache<NSString, CacheItem>

    required init(capacity: Int) {
        _cache = NSCache();
        super.init();
        _cache.delegate = self;
    }

    func set(texture: GLuint, width: GLuint, height: GLuint, depth: GLuint, for key: String) {
        _cache.setObject(CacheItem(texture: texture, width: width, height: height, depth: depth), forKey: NSString(string: key), cost: 1);
    }

    func get(_ key: String) -> CacheItem? {
        if let item = _cache.object(forKey: NSString(string: key))
        {
            return item;
        }
        return nil;
    }

    func clear() {
        _cache.removeAllObjects();
    }

    private func cache(_ cache: NSCache<NSString, CacheItem>, willEvictObject obj: CacheItem) {
        var texture = obj.texture;
        glDeleteTextures(1, &texture);
    }
}

class STInputSource: STProcessor {
//    public static let CTypeTexture = "texture"
//    public static let CTypeCubemap = "cubemap"
//    public static let CTypeVolume = "volume"
//    public static let CTypeBuffer = "buffer"
//    public static let CTypeKeyboard = "keyboard"
//    public static let CTypeVideo = "video"
//    public static let CTypeMusic = "music"
//    public static let CTypeMusicStream = "musicstream"
//
//    public static let SamplerFilterNearest = "nearest"
//    public static let SamplerFilterLinear = "linear"
//    public static let SamplerFilterMipmap = "mipmap"
//
//    public static let SamplerWrapRepeat = "repeat"
//    public static let SamplerWrapClamp = "clamp"

    deinit {
//        print("#List#Cache#Leak# ShaderToyInputSource.deinit (\(self.hash))");
    }
    
    required init(_ stInputModel: APIShaderPassInput) {
        _stInputModel = stInputModel;
        super.init();
//        print("#List#Cache#Leak# ShaderToyInputSource.init (\(self.hash))");
        if (_stInputModel.type.intValue == STInputType.musicStream.rawValue || _stInputModel.type.intValue == STInputType.music.rawValue)
        {

        }
        else if (_stInputModel.type.intValue == STInputType.keyboard.rawValue)
        {

        }
        else if (_stInputModel.type.intValue == STInputType.video.rawValue)
        {
            loadTexture(stInputModel: stInputModel);///!!!For Debug: With placeholder image files instead
        }
        else
        {
            loadTexture(stInputModel: stInputModel);
        }
    }

    private func loadTexture(stInputModel: APIShaderPassInput) {
        switch (stInputModel.type.intValue)
        {
        case STInputType.texture.rawValue,
             STInputType.cubemap.rawValue,
             STInputType.volume.rawValue,
            STInputType.mic.rawValue,///!!!TODO
            STInputType.video.rawValue,///!!!TODO
            STInputType.invalid.rawValue///!!!TODO
             :
            guard let fileKey = stInputModel.filepath else { break; }
            if let presetName = Self.presetMapping[fileKey]
            {
                let filePath: String! = Bundle.main.path(forResource: "./presets/\(presetName)", ofType: nil);
                loadImageTexture(fromFile: filePath);
            }
            else
            {
                let url = "http://www.shadertoy.com/\(fileKey)";
                loadImageTexture(fromURL: url);
            }
        default:
            break;
        }
    }

//    func fetchFilePathFromURL(_ url: String!) -> String? {
//        if let filePath = APIShaderRepository.sharedRepo().loadFile(fromURL: url, completion: nil)
//        {
//            return filePath;
//        }
//        return nil;
//    }

    private func asyncLoadTexture(from imagePath: String, with key: String, _ completion: (GLuint) -> Void)
    {
        var needLoadByMe = false;
        synchronized(Self.textureCache)
        { () -> Void in
            if (!Self.fetchingTextureKeys.contains(key) && nil == Self.textureCache.get(key))
            {
                needLoadByMe = true;
                Self.fetchingTextureKeys.insert(key);
            }
        };
        if (!needLoadByMe)
        {
            return;
        }
        print("#Cache# Actually fetching texture for key:\(key)");

        if (STInputType.volume.rawValue == _stInputModel.type.intValue)
        {
            glGenTextures(1, &_texture);
            if (!loadBin3DTextureFile(&_texture, imagePath, &_width, &_height, &_depth))
            {
                _failureTime = Date();
                return;
            }
        }
        else
        {
            guard let image = UIImage(contentsOfFile: imagePath)
            else
            {
                Self.fetchingTextureKeys.remove(key);
                _failureTime = Date();
                return;
            }

            glGenTextures(1, &_texture);
            switch (_stInputModel.type.intValue)
            {
            case STInputType.cubemap.rawValue:
                _width = GLuint(image.size.width);
                _height = _width;
                loadCubemapTextureFromImage(&_texture, image, image.size);
                break;
            default:
                _width = GLuint(image.size.width);
                _height = GLuint(image.size.height);
                loadTextureFromImage(&_texture, image, image.size);
                break;
            }
        }

        completion(_texture);
        Self.textureCache.set(texture: _texture, width: _width, height: _height, depth: _depth, for: key);
        Self.fetchingTextureKeys.remove(key);
    }

    func loadImageTexture(fromFile path: String!) {
        let callback = { (texture: GLuint) in
            let textureTarget = STInputSource.setTextureParams(textureID: texture, shadertoyInput: self._stInputModel);
            if (self._stInputModel.sampler.filter.intValue == STSamplerFilter.mipmap.rawValue)
            {
                glGenerateMipmap(textureTarget);
            }
        };
        if let cached = Self.textureCache.get(path)
        {
            _texture = cached.texture;
            _width = cached.width;
            _height = cached.height;
            _depth = cached.depth;
            callback(_texture);
            return;
        }
        asyncLoadTexture(from: path, with: path, callback);
    }

    func loadImageTexture(fromURL url: String!) {
        let callback = { (texture: GLuint) in
            let textureTarget = STInputSource.setTextureParams(textureID: texture, shadertoyInput: self._stInputModel);
            if (self._stInputModel.sampler.filter.intValue == STSamplerFilter.mipmap.rawValue)
            {
                glGenerateMipmap(textureTarget);
            }
        };
        if let cached = Self.textureCache.get(url)
        {
            _texture = cached.texture;
            _width = cached.width;
            _height = cached.height;
            _depth = cached.depth;
            callback(_texture);
            return;
        }

        let currentRunLoop = RunLoop.current;
        APIShaderRepository.sharedRepo().loadFile(fromURL: url, completion: { (filePath: String?, error: Error?, isAsync: Bool) in
            if (nil != error || nil == filePath)
            {
                self._failureTime = Date();
                return;
            }
            if (isAsync)
            {
                currentRunLoop.runBlock {
                    self.asyncLoadTexture(from: filePath!, with: url, callback);
                }
            }
            else
            {
                self.asyncLoadTexture(from: filePath!, with: url, callback);
            }
        });
    }

    static func textureTarget(of shadertoyInput: APIShaderPassInput!) -> GLenum {
        var textureTarget: GLenum
        switch shadertoyInput.type.intValue
        {
        case STInputType.cubemap.rawValue:
            textureTarget = GLenum(GL_TEXTURE_CUBE_MAP);
        case STInputType.volume.rawValue:
            textureTarget = GLenum(GL_TEXTURE_3D);
        default:
            textureTarget = GLenum(GL_TEXTURE_2D);
        }
        return textureTarget;
    }
    
    @discardableResult
    static func setTextureParams(textureID: GLuint, shadertoyInput: APIShaderPassInput!) -> GLenum {
        let texTarget = textureTarget(of: shadertoyInput);
        glBindTexture(texTarget, textureID);
        let sampler: APIShaderPassInputSampler = shadertoyInput.sampler;
        let wrapRepeat = (sampler.wrap.intValue == STSamplerWrap.repeat.rawValue);
        var minFilter, magFilter: GLint
        if (sampler.filter.intValue == STSamplerFilter.nearest.rawValue)
        {
            minFilter = GL_NEAREST;
            magFilter = GL_NEAREST;
        }
        else if (sampler.filter.intValue == STSamplerFilter.mipmap.rawValue)
        {
            minFilter = GL_LINEAR_MIPMAP_LINEAR;
            magFilter = GL_LINEAR;
        }
        else
        {
            minFilter = GL_LINEAR;
            magFilter = GL_LINEAR;
        }
        GLUtils.setTextureParams(textureTarget: texTarget, repeatS: wrapRepeat, repeatT: wrapRepeat, repeatR: wrapRepeat, minFilter: minFilter, magFilter: magFilter);
        return texTarget;
    }

    func synchronized<T>(_ obj: Any, _ body: () throws -> T) rethrows -> T {
        objc_sync_enter(obj)
        defer { objc_sync_exit(obj) }
        return try body()
    }

//    override func hash(into hasher: inout Hasher) {
//        _stInputModel.hash(into: &hasher);
//    }

    override func process(timestamp: Float, frameCount: Int, width: GLint, height: GLint) -> Bool {
        super.process(timestamp: timestamp, frameCount: frameCount, width: width, height: height);
//        print("#List#Halt# InputSource.process Begin : \(_stInputModel.inputId)");
//        defer {
//            print("#List#Halt# InputSource.process End : \(_stInputModel.inputId)");
//        }
        if let failureTime = _failureTime
        {
            if (Date().timeIntervalSince(failureTime) >= Self.FailureRetryTimeInterval)
            {
                _failureTime = nil;
                loadTexture(stInputModel: _stInputModel);
            }
        }
        
        if (_stInputModel.type.intValue == STInputType.musicStream.rawValue || _stInputModel.type.intValue == STInputType.music.rawValue)
        {
            return true;
        }
        else if (_stInputModel.type.intValue == STInputType.keyboard.rawValue)
        {
            return true;
        }
        else if (_stInputModel.type.intValue == STInputType.video.rawValue)
        {
            return true;
        }
        else
        {
            ///!!!return _texture > 0;
            return true;
        }
    }

    override var targetTexture: GLuint {
        get { return _texture; }
    }

    override var resolution: MTLSize {
        get {
            return MTLSize(width: Int(_width), height: Int(_height), depth: Int(_depth));
        }
    }
    
    override var hash: Int {
        get {
            return _stInputModel.hash;
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? STInputSource
        {
            return other._stInputModel.inputId == self._stInputModel.inputId;
        }
        return false;
    }
    
    private var _texture: GLuint = 0
    
    private var _width: GLuint = 0
    private var _height: GLuint = 0
    private var _depth: GLuint = 1

    private var _stInputModel: APIShaderPassInput

    private static let FailureRetryTimeInterval: TimeInterval = 10.0
    private var _failureTime: Date? = nil

    static var textureCache: TextureCache = TextureCache(capacity: 30)
    static var fetchingTextureKeys: Set<String> = Set()

    private static let presetMapping: [String:String] = [
        "/media/a/10eb4fe0ac8a7dc348a2cc282ca5df1759ab8bf680117e4047728100969e7b43.jpg":"tex00.jpg",
        "/media/a/cd4c518bc6ef165c39d4405b347b51ba40f8d7a065ab0e8d2e4f422cbc1e8a43.jpg":"tex01.jpg",
        "/media/a/95b90082f799f48677b4f206d856ad572f1d178c676269eac6347631d4447258.jpg":"tex02.jpg",
        "/media/a/e6e5631ce1237ae4c05b3563eda686400a401df4548d0f9fad40ecac1659c46c.jpg":"tex03.jpg",
        "/media/a/8de3a3924cb95bd0e95a443fff0326c869f9d4979cd1d5b6e94e2a01f5be53e9.jpg":"tex04.jpg",
        "/media/a/1f7dca9c22f324751f2a5a59c9b181dfe3b5564a04b724c657732d0bf09c99db.jpg":"tex05.jpg",
        "/media/a/fb918796edc3d2221218db0811e240e72e340350008338b0c07a52bd353666a6.jpg":"tex06.jpg",
        "/media/a/52d2a8f514c4fd2d9866587f4d7b2a5bfa1a11a0e772077d7682deb8b3b517e5.jpg":"tex07.jpg",
        "/media/a/bd6464771e47eed832c5eb2cd85cdc0bfc697786b903bfd30f890f9d4fc36657.jpg":"tex08.jpg",
        "/media/a/92d7758c402f0927011ca8d0a7e40251439fba3a1dac26f5b8b62026323501aa.jpg":"tex09.jpg",
        "/media/a/0a40562379b63dfb89227e6d172f39fdce9022cba76623f1054a2c83d6c0ba5d.png":"tex10.png",
        "/media/a/3083c722c0c738cad0f468383167a0d246f91af2bfa373e9c5c094fb8c8413e0.png":"tex11.png",
        "/media/a/0c7bf5fe9462d5bffbd11126e82908e39be3ce56220d900f633d58fb432e56f5.png":"tex12.png",
        "/media/a/cbcbb5a6cfb55c36f8f021fbb0e3f69ac96339a39fa85cd96f2017a2192821b5.png":"tex14.png",
        "/media/a/85a6d68622b36995ccb98a89bbb119edf167c914660e4450d313de049320005c.png":"tex15.png",
        "/media/a/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png":"tex16.png",
        "/media/a/3871e838723dd6b166e490664eead8ec60aedd6b8d95bc8e2fe3f882f0fd90f0.jpg":"tex17.jpg",
        "/media/a/79520a3d3a0f4d3caa440802ef4362e99d54e12b1392973e4ea321840970a88a.jpg":"tex18.jpg",
        "/media/a/ad56fba948dfba9ae698198c109e71f118a54d209c0ea50d77ea546abad89c57.png":"tex19.png",
        "/media/a/8979352a182bde7c3c651ba2b2f4e0615de819585cc37b7175bcefbca15a6683.jpg":"tex20.jpg",
        "/media/a/08b42b43ae9d3c0605da11d0eac86618ea888e62cdd9518ee8b9097488b31560.png":"tex21.png",

        "/media/a/585f9546c092f53ded45332b343144396c0b2d70d9965f585ebc172080d8aa58.jpg":"cube00_0.jpg",
        "/media/a/793a105653fbdadabdc1325ca08675e1ce48ae5f12e37973829c87bea4be3232.png":"cube01_0.png",
        "/media/a/488bd40303a2e2b9a71987e48c66ef41f5e937174bf316d3ed0e86410784b919.jpg":"cube02_0.jpg",
        "/media/a/550a8cce1bf403869fde66dddf6028dd171f1852f4a704a465e1b80d23955663.png":"cube03_0.png",
        "/media/a/94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0.png":"cube04_0.png",
        "/media/a/0681c014f6c88c356cf9c0394ffe015acc94ec1474924855f45d22c3e70b5785.png":"cube05_0.png",

        "/media/a/c3a071ecf273428bc72fc72b2dd972671de8da420a2d4f917b75d20e1c24b34c.ogv":"vid00.png",
        "/media/a/e81e818ac76a8983d746784b423178ee9f6cdcdf7f8e8d719341a6fe2d2ab303.webm":"vid01.png",
        "/media/a/3405e48f74815c7baa49133bdc835142948381fbe003ad2f12f5087715731153.ogv":"vid02.png",
        "/media/a/35c87bcb8d7af24c54d41122dadb619dd920646a0bd0e477e7bdc6d12876df17.webm":"vid03.png",

        "keyboard":"keyboard.png",
        "webcam":"webcam.png",
        "music":"music.png",
    ]
}

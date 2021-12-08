//
//  TwoLevelCache.swift
//  ShaMderToy
//
//  Created by Qiu Dong on 2021/9/15.
//

import Foundation

class TwoLevelCache : NSObject, NSCacheDelegate {
    @objc(TwoLevelCacheItem)
    class CacheItem : NSObject, NSSecureCoding {
        var value: NSCoding?
        var key: NSString
        var cost: Int
        
        var archivedData: Data? = nil
        
        static var supportsSecureCoding: Bool {
            get { return true; }
        }
        
        required init(_ value: NSCoding, _ key: String, _ cost: Int) {
            self.value = value;
            self.key = NSString(string: key);
            self.cost = cost;
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(key, forKey: "k");
            coder.encode(cost, forKey: "c");
            if #available(iOS 11.0, *) {
                if let v = value,
                   let data = try? NSKeyedArchiver.archivedData(withRootObject: v, requiringSecureCoding: false)
                {
                    coder.encode(data);
                }
            } else {
                // Fallback on earlier versions
                if let v = value
                {
                    let data = NSKeyedArchiver.archivedData(withRootObject: v);
                    coder.encode(data);
                }
            }
        }
        
        func unarchiveObject<ObjectClass>(of clazz: ObjectClass.Type) where ObjectClass : NSObject, ObjectClass : NSCoding {
            guard let data = archivedData else { return; }
            if #available(iOS 11.0, *) {
                if let v = try? NSKeyedUnarchiver.unarchivedObject(ofClass: clazz, from: data)
                {
                    value = v;
                }
            } else {
                // Fallback on earlier versions
                value = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSCoding;
            }
        }
        
        func unarchiveObject() {
            guard let data = archivedData else { return; }
            if let v = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSCoding
            {
                value = v;
            }
        }
        
        required init?(coder: NSCoder) {
            key = coder.decodeObject(forKey: "k") as! NSString;
            cost = coder.decodeInteger(forKey: "c");
            if let data = coder.decodeData()
            {
                archivedData = data;
            }
            super.init();
        }
    }
    
    deinit
    {
        _cache.removeAllObjects();//TODO:
    }
    
    @objc
    required init(with capacity: Int)
    {
        _cache = NSCache();
        _cache.totalCostLimit = capacity;
        _capacity = capacity;
        _notPersistedKeys = Set();
    }
    
    func get<DecodableType>(from key: String, of clazz: DecodableType.Type, ifMiss callback: ((_ key: String) -> Void)? = nil) -> NSCoding? where DecodableType : NSObject, DecodableType : NSSecureCoding {
        let k = NSString(string: key);
        if let cached = _cache.object(forKey: k)
        {
            return cached.value;
        }
        else if let cached = UserDefaults.standard.object(forKey: key) as? Data
        {
            do
            {
                if #available(iOS 11.0, *) {
                    if let cachedItem: CacheItem = try NSKeyedUnarchiver.unarchivedObject(ofClass: CacheItem.self, from: cached)
                    {
                        cachedItem.unarchiveObject(of: clazz);
                        _cache.setObject(cachedItem, forKey: k, cost: cachedItem.cost);
                        return cachedItem.value;
                    }
                } else {
                    // Fallback on earlier versions
                    if let cachedItem: CacheItem = NSKeyedUnarchiver.unarchiveObject(with: cached) as? CacheItem
                    {
                        cachedItem.unarchiveObject(of: clazz);
                        _cache.setObject(cachedItem, forKey: k, cost: cachedItem.cost);
                        return cachedItem.value;
                    }
                }
            }
            catch let ex
            {
                print("Exception \(ex)");
            }
        }
        
        if let callback_ = callback
        {
            callback_(key);
        }
        return nil;
    }
    
    @objc
    func get(from key: String, ifMiss callback: ((_ key: String) -> Void)? = nil) -> NSCoding? {
        let k = NSString(string: key);
        if let cached = _cache.object(forKey: k)
        {
            return cached.value;
        }
        else if let cached = UserDefaults.standard.object(forKey: key) as? Data
        {
            do
            {
                if #available(iOS 11.0, *) {
                    if let cachedItem: CacheItem = try NSKeyedUnarchiver.unarchivedObject(ofClass: CacheItem.self, from: cached)
                    {
                        cachedItem.unarchiveObject();
                        _cache.setObject(cachedItem, forKey: k, cost: cachedItem.cost);
                        return cachedItem.value;
                    }
                } else {
                    // Fallback on earlier versions
                    if let cachedItem: CacheItem = NSKeyedUnarchiver.unarchiveObject(with: cached) as? CacheItem
                    {
                        cachedItem.unarchiveObject();
                        _cache.setObject(cachedItem, forKey: k, cost: cachedItem.cost);
                        return cachedItem.value;
                    }
                }
            }
            catch let ex
            {
                print("Exception \(ex)");
            }
        }
        
        if let callback_ = callback
        {
            callback_(key);
        }
        return nil;
    }
    
    @objc
    func set(_ value: NSCoding, to key: String, with cost: Int = 1) {
        let cacheItem = CacheItem(value, key, cost);
        _cache.setObject(cacheItem, forKey: NSString(string: key), cost: cost);
        _notPersistedKeys.insert(key);
    }
    
    @objc
    func setAndSave(_ value: NSCoding?, to key: String, with cost: Int = 1) {
        guard let value = value
        else
        {
            return;
        }
        let cacheItem = CacheItem(value, key, cost);
        _cache.setObject(cacheItem, forKey: NSString(string: key), cost: cost);
        
        if #available(iOS 11.0, *) {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: cacheItem, requiringSecureCoding: false)
            {
                UserDefaults.standard.set(data, forKey: key);
//                UserDefaults.standard.synchronize();
                _notPersistedKeys.remove(key);
            }
        } else {
            // Fallback on earlier versions
            let data = NSKeyedArchiver.archivedData(withRootObject: cacheItem);
            UserDefaults.standard.set(data, forKey: key);
//            UserDefaults.standard.synchronize();
            _notPersistedKeys.remove(key);
        }
    }
    
    @objc
    func storeItem(of key: String) {
        if let cacheItem = _cache.object(forKey: NSString(string: key))
        {
            if #available(iOS 11.0, *) {
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: cacheItem, requiringSecureCoding: false)
                {
                    UserDefaults.standard.set(data, forKey: key);
                    UserDefaults.standard.synchronize();
                    _notPersistedKeys.remove(key);
                }
            } else {
                // Fallback on earlier versions
                let data = NSKeyedArchiver.archivedData(withRootObject: cacheItem);
                UserDefaults.standard.set(data, forKey: key);
                UserDefaults.standard.synchronize();
                _notPersistedKeys.remove(key);
            }
        }
    }
    
    @objc
    func saveAll() {
        for k in _notPersistedKeys
        {
            if let cacheItem = _cache.object(forKey: NSString(string: k))
            {
                if #available(iOS 11.0, *) {
                    if let data = try? NSKeyedArchiver.archivedData(withRootObject: cacheItem, requiringSecureCoding: false)
                    {
                        UserDefaults.standard.set(data, forKey: k);
                    }
                } else {
                    // Fallback on earlier versions
                    let data = NSKeyedArchiver.archivedData(withRootObject: cacheItem);
                    UserDefaults.standard.set(data, forKey: k);
                }
            }
        }
        UserDefaults.standard.synchronize();
        _notPersistedKeys.removeAll();
    }
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        let cacheItem = obj as! CacheItem;
        let key = cacheItem.key as String;
        if #available(iOS 11.0, *) {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: cacheItem, requiringSecureCoding: false)
            {
                UserDefaults.standard.set(data, forKey: key);
//                UserDefaults.standard.synchronize();
                _notPersistedKeys.remove(key);
            }
        } else {
            // Fallback on earlier versions
            let data = NSKeyedArchiver.archivedData(withRootObject: cacheItem);
            UserDefaults.standard.set(data, forKey: key);
//            UserDefaults.standard.synchronize();
            _notPersistedKeys.remove(key);
        }
    }
    
    private var _cache: NSCache<NSString, CacheItem>
    private var _capacity: Int
    
    private var _notPersistedKeys: Set<String>
}

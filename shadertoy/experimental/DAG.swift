//
//  DAG.swift
//  ShaMderToy
//
//  Created by qiudong on 2021/8/8.
//

import Foundation

protocol DAGNodeProtocol: Hashable {
    associatedtype Item
    
    init(with item: Item);

    @discardableResult
    mutating func setDependency(_ dependencyNode: Self, _ tag: Int) -> Bool;
    
    @discardableResult
    mutating func removeDependency(_ tag: Int) -> Bool;
}

protocol DAGProtocol {
    associatedtype Node: DAGNodeProtocol
    
}

class WeakHashableRef<T> : NSObject where T:NSObject {
//    static func == (lhs: WeakHashableRef<T>, rhs: WeakHashableRef<T>) -> Bool {
//        guard let lhv = lhs._value else { return false; }
//        guard let rhv = rhs._value else { return false; }
//        let ret = lhv == rhv;
//        print("WeakHashableRef operator == (\(lhv.description), \(rhv.description)) = \(ret)");
//        return ret;
//    }
//
//    func hash(into hasher: inout Hasher) {
//        _value?.hash(into: &hasher);
//    }

    override func isEqual(_ object: Any?) -> Bool {
        if object is WeakHashableRef<T>
        {
            guard let other: WeakHashableRef<T> = object as? WeakHashableRef<T> else { return false; }
            guard let otherV: T = other._value else { return false; }
            guard let thisV: T = self._value else { return false; }
            return thisV.isEqual(otherV);
        }
        else
        {
            return false;
        }
    }
    
    override var hash: Int {
        get {
            if let v = _value
            {
                let ret  = v.hashValue;
//                print("WeakRef \(v) .hash = \(ret)");
                return ret;
            }
            else
            {
//                print("WeakRef nil .hash = 0");
                return 0;
            }
        }
    }
    
    override var description: String {
        get {
            if let v = _value
            {
                return "WeakHashableRef{\(v.description)}";
            }
            else
            {
                return "WeakHashableRef{nil}";
            }
        }
    }
    
    private(set) weak var _value: T?
    
    required init(_ value: T?) {
        _value = value;
    }
}

class BaseDAG<ItemType: NSObject>: DAGProtocol {
    typealias Node = BaseDAGNode<ItemType>;
    
    class Actor {
        deinit {
//            print("Actor::deinit")
            _pendingNodes.removeAll();
            _callback = nil
        }

        required init(from graph: BaseDAG<ItemType>) {
            _originalGraph = graph.clone();
            _originalGraph.breakCircles();
//            _callback = callback;
//            print("Graph.Actor's cloned graph nodes:\n\(_actionGraph._nodes)");
//            beginAction();
        }
        
        @discardableResult
        public func beginAction(_ callback: @escaping (_ node: Node, _ actor: Actor) -> Void) -> Bool {
            _activeGraph = _originalGraph.clone();
            _callback = callback;
            guard let activeGraph = _activeGraph,
                  let rootNodes = activeGraph.beginAction()
            else
            {
                _callback = nil;
                return false;
            }
            
            _pendingNodes.removeAll();
            rootNodes.forEach { node in
                _pendingNodes.insert(node);
            }
            rootNodes.forEach { node in
                _callback?(node, self);
            }

            let ret = _pendingNodes.count > 0;
            if (!ret)
            {
                _callback = nil;
            }
            return ret;
        }
        
        @discardableResult
        public func finishNode(_ item: ItemType) -> Bool {
            guard let activeGraph = _activeGraph,
                  let node = activeGraph.getOrAddNode(item),
                  let newReadyNodes: [Node] = activeGraph.finishNodeAction(node)
            else { return false; }
//            print("finishNode '\(item)', newReadyNodes=\(newReadyNodes)");
            newReadyNodes.forEach { node in
                _pendingNodes.insert(node);
            }
            newReadyNodes.forEach { node in
                _callback?(node, self);
            }
            _pendingNodes.remove(node);
//            print("_pendingNodes=\(_pendingNodes)");
            let ret = _pendingNodes.count > 0;
            if (!ret)
            {
                _callback = nil;
            }
            return ret;
        }
        
        public var pendingNodesCount: Int {
            get { return _pendingNodes.count; }
        }
        
        var _originalGraph: BaseDAG<ItemType>
        var _activeGraph: BaseDAG<ItemType>? = nil
        var _pendingNodes: Set<Node> = []
        var _callback: ((_ node: Node, _ actor: Actor) -> Void)? = nil
    }
    
    deinit {
        _nodes.removeAll();
    }
    
    required init(_ items: [ItemType]?) {
        guard let allItems = items else { return; }
        for item in allItems
        {
            let node = BaseDAGNode<ItemType>(with: item);
            _nodes[node._item] = node;
        }
    }
    
    @discardableResult
    public func getOrAddNode(_ item: ItemType?) -> Node? {
        guard let item = item else { return nil; }
        let existing = _nodes[item];
        if (nil != existing) { return existing; }
        let newNode = Node(with: item);
        _nodes[item] = newNode;
        return newNode;
    }
    
    @discardableResult
    public func linkNode(from start: ItemType?, to end: ItemType?, with tag: Int) -> Bool {
        let s = getOrAddNode(start);
        let e = getOrAddNode(end);
        guard let startNode = s,
              let endNode = e
        else { return false; }
        return endNode.setDependency(startNode, tag);
    }
    
    public func forwardBFS(from startItems: [ItemType]) -> [ItemType] {
        var startNodes: [Node] = [];
        for item in startItems
        {
            if let node = getOrAddNode(item)
            {
                startNodes.append(node);
            }
        }
        return Self.forwardBFS(from: startNodes).map { node in
            return node._item;
        }
    }
    
    public func backwardBFS(from endItems: [ItemType]) -> [ItemType] {
        var endNodes: [Node] = [];
        for item in endItems
        {
            if let node = getOrAddNode(item)
            {
                endNodes.append(node);
            }
        }
        return Self.backwardBFS(from: endNodes).map { node in
            return node._item;
        }
    }
    
    public func getGraphActor() -> Actor {
        return Actor(from: self);
    }
    
    public func clone() -> BaseDAG<ItemType> {
        let copy = BaseDAG<ItemType>(nil);
        for (value, _) in _nodes
        {
            copy.getOrAddNode(value);
        }
        for (value, node) in _nodes
        {
            guard let toNode = copy.getOrAddNode(value) else { continue; }
            node._determinedDependencies.forEach { (tag: Int, dependency: BaseDAGNode<ItemType>) in
                guard let fromNode = copy.getOrAddNode(dependency.item) else { return; }
                toNode._determinedDependencies[tag] = fromNode;
            }
        }
        for (toItem, toNode) in _nodes
        {
            for (tag, fromNode) in toNode._dependencies
            {
                copy.linkNode(from: fromNode._item, to: toItem, with: tag);
            }
        }
        return copy;
    }
    
    func beginAction() -> [Node]? {
        if (_nodes.count == 0)
        {
            return nil;
        }
        ///breakCircles();
        var rootNodes: [Node] = [];
//        while (true)
//        {
            for (_, node) in _nodes
            {
                // A node can be a root node only if it has no dependencies:
                if (0 == node._dependencies.count)
                {
                    rootNodes.append(node);
                }
            }
            
//            if (0 == rootNodes.count && 0 < _nodes.count)
//            {
//                breakCircles();
//            }
//            else
//            {
//                break;
//            }
//        }
        return rootNodes;
    }

    func finishNodeAction(_ node: Node) -> [Node]? {
        guard let myNode = _nodes[node._item]
        else { return nil; }
        if (myNode._dependencies.count > 0)
        {
            return nil;
        }
        var newReadyNodes: [Node] = [];
        for (wRef, var tags) in myNode._dependents
        {
            guard let dependent = wRef._value else { continue; }
            for tag in tags
            {
                if let node = dependent._dependencies.removeValue(forKey: tag)
                {
                    dependent._determinedDependencies[tag] = node;
                    
                    if (0 == dependent._dependencies.count)
                    {
                        newReadyNodes.append(dependent);
                    }
                }
            }
            tags.removeAll();
        }
        myNode._dependents.removeAll();
        _nodes.removeValue(forKey: myNode._item);
        return newReadyNodes;
    }
    
    internal func breakCircles() {
        let copyGraph = self.clone();
//        print("breakCircles's cloned graph nodes:\n\(copyGraph._nodes)");
        while (copyGraph._nodes.count > 0)
        {
            // Find end nodes:
            var forwardQueue: [Node] = [];
            var backwardQueue: [Node] = [];
            copyGraph._nodes.forEach { (_, node) in
                if (0 == node._dependencies.count)
                {
                    forwardQueue.append(node);
                }
                if (0 == node._dependents.count)
                {
                    backwardQueue.append(node);
                }
            }
            // Burn rope(s) to get next generation of end nodes, until only circle(s) left:
            while (forwardQueue.count > 0)
            {
                forwardQueue.forEach { node in
                    copyGraph._nodes.removeValue(forKey: node._item);
                }
                
                let node = forwardQueue.removeFirst();
                for (dependentRef, var tags) in node._dependents
                {
                    guard let dependent = dependentRef._value else { continue; }
                    for tag in tags
                    {
                        dependent._dependencies.removeValue(forKey: tag);
                        if (0 == dependent._dependencies.count)
                        {
                            forwardQueue.append(dependent);
                        }
                    }
                    tags.removeAll();
                }
                node._dependents.removeAll();
            }
            while (backwardQueue.count > 0)
            {
                backwardQueue.forEach { node in
                    copyGraph._nodes.removeValue(forKey: node._item);
                }
                
                let node = backwardQueue.removeFirst();
                for (tag, dependency) in node._dependencies
                {
                    let wRef = WeakHashableRef(node);
                    if nil != dependency._dependents[wRef]
                    {
                        dependency._dependents[wRef]!.remove(tag);
                        if (0 == dependency._dependents[wRef]!.count)
                        {
                            dependency._dependents.removeValue(forKey: wRef);
                            if (0 == dependency._dependents.count)
                            {
                                backwardQueue.append(dependency);
                            }
                        }
                    }
                }
                node._dependencies.removeAll();
            }
            // Break any circle with least number of links:
            var minLinks:Int = Int(INT32_MAX);
            var minLinksNode: Node? = nil;
            var minLinksIsOutgoing: Bool = false;
            for (_, node) in copyGraph._nodes
            {
                if (node._dependents.count > node._dependencies.count)
                {
                    if (minLinks > node._dependencies.count)
                    {
                        minLinks = node._dependencies.count;
                        minLinksIsOutgoing = false;
                        minLinksNode = node;
                    }
                }
                else
                {
                    if (minLinks > node._dependents.count)
                    {
                        minLinks = node._dependents.count;
                        minLinksIsOutgoing = true;
                        minLinksNode = node;
                    }
                }
            }
            if let node = minLinksNode
            {
                if (minLinksIsOutgoing)
                {
                    if let originNode = self.getOrAddNode(node._item)
                    {
                        node._dependents.forEach { (dependentRef: WeakHashableRef<Node>, tags: Set<Int>) in
                            if let dependent = dependentRef._value
                            {
//                                print("breakCircles originNode(\(originNode)) removeDependent(\(dependent))");
                                if let originDependent = self.getOrAddNode(dependent._item)
                                {
                                    tags.forEach { tag in
                                        originNode.removeDependent(originDependent, tag: tag);
                                    }
                                }
                            }
                        }
                        
                    }
                    node.removeAllDependents();
                }
                else
                {
                    if let originNode = self.getOrAddNode(node._item)
                    {
                        node._dependencies.forEach { (tag: Int, dependency: Node) in
//                            print("breakCircles originNode(\(originNode)) removeDependency(\(dependency))");
                            originNode.removeDependency(tag);
                        }
                    }
                    node.removeAllDependencies();
                }
            }
        }
    }
    
    static func forwardBFS(from startNodes: [Node]) -> [Node] {
        var allNodes: [Node] = [];
        var queue: [Node] = startNodes;
        var stamped: Set<Node> = [];
        for item in startNodes
        {
            stamped.insert(item);
        }
        while (queue.count > 0)
        {
            let node = queue.removeFirst();
            allNodes.append(node);
            for (wRef, _) in node._dependents
            {
                guard let dependent = wRef._value else { continue; }
                if (stamped.contains(dependent))
                {
                    continue;
                }
                stamped.insert(dependent);
                queue.append(dependent);
            }
        }
        return allNodes;
    }

    static func backwardBFS(from endNodes: [Node]) -> [Node] {
        var allNodes: [Node] = [];
        var queue: [Node] = endNodes;
        var stamped: Set<Node> = [];
        for item in endNodes
        {
            stamped.insert(item);
        }
        while (queue.count > 0)
        {
            let node = queue.removeFirst();
            allNodes.append(node);
            for (_, dependency) in node._dependencies
            {
                if (stamped.contains(dependency))
                {
                    continue;
                }
                stamped.insert(dependency);
                queue.append(dependency);
            }
        }
        return allNodes;
    }
    
    fileprivate var _nodes: [ItemType:Node] = [:];
}

class BaseDAGNode<ItemType: NSObject>: NSObject, DAGNodeProtocol {
    typealias Item = ItemType
    
    @discardableResult
    internal func setDependency(_ dependencyNode: BaseDAGNode<ItemType>, _ tag: Int) -> Bool {
        let wRef = WeakHashableRef(self);
        if (nil != dependencyNode._dependents[wRef])
        {
            dependencyNode._dependents[wRef]?.insert(tag);
        }
        else
        {
            dependencyNode._dependents[wRef] = Set<Int>();
            dependencyNode._dependents[wRef]?.insert(tag);
        }
        let newInserted = _dependencies[tag] == nil;
        _dependencies[tag] = dependencyNode;
        return newInserted;
    }
    
    @discardableResult
    internal func removeDependency(_ tag: Int) -> Bool {
        if let dependencyNode = _dependencies.removeValue(forKey: tag)
        {
            let wRef = WeakHashableRef(self);
            if (nil != dependencyNode._dependents[wRef])
            {
                dependencyNode._dependents[wRef]?.remove(tag);
                if (0 == dependencyNode._dependents[wRef]!.count)
                {
                    dependencyNode._dependents.removeValue(forKey: wRef);
                }
            }
            _determinedDependencies[tag] = dependencyNode;
            return true;
        }
        return false;
    }

    internal func removeAllDependencies() {
        let wRef = WeakHashableRef(self);
        _dependencies.forEach { (tag, dependencyNode) in
            if (nil != dependencyNode._dependents[wRef])
            {
                dependencyNode._dependents[wRef]?.remove(tag);
                if (0 == dependencyNode._dependents[wRef]!.count)
                {
                    dependencyNode._dependents.removeValue(forKey: wRef);
                }
            }
            _determinedDependencies[tag] = dependencyNode;
        }
        _dependencies.removeAll();
    }
    
    @discardableResult
    internal func removeDependent(_ dependentNode: BaseDAGNode<ItemType>, tag: Int) -> Bool {
        let wRef = WeakHashableRef(dependentNode);
        if (nil != _dependents[wRef])
        {
            _dependents[wRef]?.remove(tag)
            if (0 == _dependents[wRef]!.count)
            {
                _dependents.removeValue(forKey: wRef);
            }
            dependentNode._dependencies.removeValue(forKey: tag);
            dependentNode._determinedDependencies[tag] = self;
            return true;
        }
        return false;
    }
    
    internal func removeAllDependents() {
        _dependents.forEach { (dependentNodeRef, tags) in
            for tag in tags
            {
                dependentNodeRef._value?._dependencies.removeValue(forKey: tag);
            }
        }
        _dependents.removeAll();
    }
    
    @discardableResult
    internal func enumerateInDependencies<R>(_ callback: (_ dependency: ItemType, _ tag: Int) -> R) -> [R]? {
        return _dependencies.map { (tag, dependencyNode) in
            return callback(dependencyNode._item, tag);
        }
    }

//    func enumerateInDependencies(_ callback: (_ dependency: ItemType) -> Void) {
//        _dependencies.forEach { dependencyNode in
//            callback(dependencyNode._item);
//        }
//    }
    
    @discardableResult
    func enumerateInDeterminedDependencies<R>(_ callback: (_ dependency: ItemType, _ tag: Int) -> R) -> [R]? {
        return _determinedDependencies.map { (tag, dependencyNode) in
            return callback(dependencyNode._item, tag);
        }
    }
    
//    func enumerateInDeterminedDependencies(_ callback: (_ dependency: ItemType) -> Void) {
//        _determinedDependencies.forEach { dependencyNode in
//            callback(dependencyNode._item);
//        }
//    }
    
    var item: ItemType {
        get { return _item; }
    }
    
    deinit {
        _dependencies.removeAll();
        _dependents.removeAll();
        _determinedDependencies.removeAll();
    }

    required init(with item: ItemType) {
        _item = item;
    }
    
//    static func == (lhs: BaseDAGNode, rhs: BaseDAGNode) -> Bool {
//        let ret = lhs._item == rhs._item;
//        print("BaseDAGNode operator == (\(lhs._item), \(rhs._item)) = \(ret)");
//        return ret;
//    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if object is Self
        {
            guard let other: Self = object as? Self else { return false; }
            let otherV: ItemType = other._item;
            let thisV: ItemType = self._item;
            return thisV.isEqual(otherV);
        }
        else
        {
            return false;
        }
    }
    
    override var hash: Int {
        get {
            let ret  = _item.hashValue;
//            print("BaseDAGNode \(_item) .hash = \(ret)");
            return ret;
        }
    }
    
    override var description: String {
        get {
            var desc = "Node{\(_item.description)} depends on";
            for (tag, dependency) in _dependencies
            {
                desc = "\(desc) \(dependency._item.description)@\(tag)";
            }
            return desc;
        }
    }
    
    internal var _item: ItemType
    internal var _dependencies: [Int:BaseDAGNode<ItemType>] = [:]
    internal var _dependents: [WeakHashableRef<BaseDAGNode<ItemType>>:Set<Int>] = [:]
    
    internal var _determinedDependencies: [Int:BaseDAGNode<ItemType>] = [:]
}

class FooProcessor: NSObject {
    required init(_ name: String) {
        self.name = name;
        modifyTimes = 0;
        currentDestIndex = -1;
    }
    
    var dest: String {
        get {
            if (currentDestIndex >= 0)
            {
                return "\(name)[\(modifyTimes)](\(currentDestIndex == 0 ? "A":"B"))";
            }
            else
            {
                return "\(name)[\(modifyTimes)]";
            }
        }
    }
    
    func setInput(_ dependency: FooProcessor, for tag: Int) {
        if (dependency === self)
        {
            if (currentDestIndex < 0)
            {
                currentDestIndex = 0;
                print("#DAG# Found self circle in Node \(name), create pingpong buffer");
            }
        }
        inputs[tag] = dependency.dest;
    }
    
    func process() {
        modifyTimes += 1;
        var desc = "Process: \(name)[\(modifyTimes)]";
        if (currentDestIndex >= 0)
        {
            desc += "(\(1 - currentDestIndex == 0 ? "A":"B"))";
        }
        var iter = inputs.makeIterator();
        if let next = iter.next()
        {
            desc += " = \(next.key)@\(next.value)"
        }
        while let next = iter.next()
        {
            desc += " + \(next.key)@\(next.value)"
        }
        print(desc);

        inputs.removeAll();
        if (currentDestIndex >= 0)
        {
            currentDestIndex = 1 - currentDestIndex;
        }
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? FooProcessor
        {
            return other.name == name;
        }
        return false;
    }
    
    override var hash: Int {
        get {
            return name.hash;
        }
    }
    
    private var inputs: [Int:String] = [:]
    private var modifyTimes: Int
    var name: String
    
    private var currentDestIndex: Int
}

class TestDAG : BaseDAG<FooProcessor> {
    
    static func test() {
        let dag = TestDAG(nil);
//        dag.linkNode(from: FooProcessor("E"), to: FooProcessor("G"), with: 5);
//        dag.linkNode(from: FooProcessor("H"), to: FooProcessor("G"), with: 8);
//        dag.linkNode(from: FooProcessor("E"), to: FooProcessor("I"), with: 5);
//        dag.linkNode(from: FooProcessor("D"), to: FooProcessor("E"), with: 4);
//        dag.linkNode(from: FooProcessor("C"), to: FooProcessor("E"), with: 3);
//        dag.linkNode(from: FooProcessor("D"), to: FooProcessor("J"), with: 4);
//        dag.linkNode(from: FooProcessor("F"), to: FooProcessor("D"), with: 6);
//        dag.linkNode(from: FooProcessor("B"), to: FooProcessor("D"), with: 2);
//        dag.linkNode(from: FooProcessor("C"), to: FooProcessor("B"), with: 3);
//        dag.linkNode(from: FooProcessor("A"), to: FooProcessor("B"), with: 1);
        
//        dag.linkNode(from: FooProcessor("A"), to: FooProcessor("B"), with: 1);
//        dag.linkNode(from: FooProcessor("B"), to: FooProcessor("A"), with: 2);
//        dag.linkNode(from: FooProcessor("B"), to: FooProcessor("C"), with: 3);
        
        // A -> 0 -> A
        // A -> 0 -> B
//        dag.linkNode(from: FooProcessor("A"), to: FooProcessor("B"), with: 0);
//        dag.linkNode(from: FooProcessor("A"), to: FooProcessor("A"), with: 0);
        
        // A -> 0 -> B
        // A -> 1 -> B
        // C -> 0 -> A
        // A -> 1 -> A
//        dag.linkNode(from: FooProcessor("A"), to: FooProcessor("B"), with: 0);
//        dag.linkNode(from: FooProcessor("A"), to: FooProcessor("B"), with: 1);
//        dag.linkNode(from: FooProcessor("C"), to: FooProcessor("A"), with: 0);
//        dag.linkNode(from: FooProcessor("A"), to: FooProcessor("A"), with: 1);

//        dag.linkNode(from: FooProcessor("C:4sXGR8"), to: FooProcessor("O:4dfGRr"), with: 1);
//        dag.linkNode(from: FooProcessor("D:XdfGR8"), to: FooProcessor("O:4dfGRr"), with: 2);
//        dag.linkNode(from: FooProcessor("B:XsXGR8"), to: FooProcessor("O:4dfGRr"), with: 0);
//        dag.linkNode(from: FooProcessor("A:4dXGR8"), to: FooProcessor("B:XsXGR8"), with: 0);
//        dag.linkNode(from: FooProcessor("D:XdfGR8"), to: FooProcessor("A:4dXGR8"), with: 0);
//        dag.linkNode(from: FooProcessor("C:4sXGR8"), to: FooProcessor("D:XdfGR8"), with: 0);
    
//        dag.linkNode(from: FooProcessor("A:4dXGR8"), to: FooProcessor("O:4dfGRr"), with: 0);
//        dag.linkNode(from: FooProcessor("ltf3zf"), to: FooProcessor("O:4dfGRr"), with: 1);
//        dag.linkNode(from: FooProcessor("A:4dXGR8"), to: FooProcessor("A:4dXGR8"), with: 0);
        // 4dcGW2:
        dag.linkNode(from: FooProcessor("I:Xsf3zn"), to: FooProcessor("A:4dXGR8"), with: 3);
        dag.linkNode(from: FooProcessor("A:4dXGR8"), to: FooProcessor("A:4dXGR8"), with: 0);
        dag.linkNode(from: FooProcessor("C:4sXGR8"), to: FooProcessor("A:4dXGR8"), with: 1);
        dag.linkNode(from: FooProcessor("D:XdfGR8"), to: FooProcessor("A:4dXGR8"), with: 2);
        dag.linkNode(from: FooProcessor("A:4dXGR8"), to: FooProcessor("B:XsXGR8"), with: 0);
        dag.linkNode(from: FooProcessor("B:XsXGR8"), to: FooProcessor("C:4sXGR8"), with: 0);
        dag.linkNode(from: FooProcessor("A:4dXGR8"), to: FooProcessor("D:XdfGR8"), with: 0);
        dag.linkNode(from: FooProcessor("I:Xsf3zn"), to: FooProcessor("O:4dfGRr"), with: 3);
        dag.linkNode(from: FooProcessor("A:4dXGR8"), to: FooProcessor("O:4dfGRr"), with: 0);
        dag.linkNode(from: FooProcessor("C:4sXGR8"), to: FooProcessor("O:4dfGRr"), with: 1);
        
//        let backwardBFSResult = dag.backwardBFS(from: ["G", "I"]);
//        print("backwardBFS: \(backwardBFSResult)\n");
//        let forwardBFSResult = dag.forwardBFS(from: ["F", "A", "C", "H"]);
//        print("forwardBFS: \(forwardBFSResult)\n");
        
        let actor = dag.getGraphActor();
        for i in 0..<10
        {
//            print("Round#\(i):\nBegin action:");
            actor.beginAction({ (node, actor) in
                var desc = "Node '\(node.item.name)' depends on: ";
                node.enumerateInDeterminedDependencies { (dependency, tag) in
                    desc = "\(desc)'\(dependency.name)'@\(tag) ";
                    node.item.setInput(dependency, for: tag);
                }
//                print(desc);
//                print("Node '\(node.item.name)' is done");
                node.item.process();
                actor.finishNode(node.item);
                if (actor.pendingNodesCount == 0)
                {
                    print("Round#\(i):\nFinish action\n-----------------\n");
                }
            });
            print("GraphActor's nodes: \(actor._activeGraph!._nodes)");
        }
    }
}

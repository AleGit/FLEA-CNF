import CTptpParsing
import Utile

typealias TreeNodeRef = UnsafeMutablePointer<prlc_tree_node>
typealias CStringRef = UnsafePointer<Int8>
typealias PrefixNodeRef = UnsafeMutablePointer<prlc_prefix_node>
typealias StoreRef = UnsafeMutablePointer<prlc_store>

// MARK: - define C-structure protocols
protocol SymbolNodeProtocol {
    var symbol: CStringRef! { get }
}

protocol TreeNodeProtocol: SymbolNodeProtocol {
    var type: PRLC_TREE_NODE_TYPE { get }
    var sibling: TreeNodeRef! { get }
    var child: TreeNodeRef! { get }
}

// MARK: - let C types conform to protocols

extension prlc_prefix_node: SymbolNodeProtocol {}
extension prlc_tree_node: TreeNodeProtocol {}
extension PRLC_TREE_NODE_TYPE : Hashable {}

// MARK: -

extension UnsafeMutablePointer where Pointee: SymbolNodeProtocol {
    var symbol: String? {
        guard let cstring = self.pointee.symbol else { return nil }
        return String(validatingUTF8: cstring)
    }
}

extension UnsafeMutablePointer where Pointee: TreeNodeProtocol {
    var type: PRLC_TREE_NODE_TYPE {
        pointee.type
    }

    var sibling: TreeNodeRef? {
        pointee.sibling
    }

    var child: TreeNodeRef? {
        pointee.child
    }
}

extension UnsafeMutablePointer where Pointee: TreeNodeProtocol {

    // func first(
    //   start:(UnsafeMutablePointer?)->UnsafeMutablePointer? = { $0 },
    //   step:(UnsafeMutablePointer?)->UnsafeMutablePointer?,
    //   where predicate: (UnsafeMutablePointer) -> Bool = { _ in true }
    // ) -> UnsafeMutablePointer? {
    //   guard let start = start(self) else { return nil }
    //   if predicate(start) { return start }
    //   return start.next(step:step, where:predicate)
    // }

    // func next(
    //   step:(UnsafeMutablePointer?)->UnsafeMutablePointer?,
    //   where predicate:(UnsafeMutablePointer)->Bool = { _ in true }
    // ) -> UnsafeMutablePointer? {
    //   var input = self
    //   while let next = step(input) {
    //     if predicate(next) { return next}
    //     input = next
    //   }
    //   return nil
    // }

    func children<T>(where predicate: @escaping (TreeNodeRef) -> Bool = { _ in true }, data: @escaping (TreeNodeRef) -> T) -> Utile.Sequence<TreeNodeRef, T> {
        Utile.Sequence(first: child, step: { $0.sibling }, where: predicate, data: data)
    }

    var children: Utile.Sequence<TreeNodeRef, TreeNodeRef> {
        children { $0 }
    }

    var childCount: Int {
        var member = child
        var count = 0
        while member != nil {
            count += 1
            member = member?.sibling
        }
        return count
    }
}

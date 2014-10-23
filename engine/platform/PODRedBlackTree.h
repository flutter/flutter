/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// A red-black tree, which is a form of a balanced binary tree. It
// supports efficient insertion, deletion and queries of comparable
// elements. The same element may be inserted multiple times. The
// algorithmic complexity of common operations is:
//
//   Insertion: O(lg(n))
//   Deletion:  O(lg(n))
//   Querying:  O(lg(n))
//
// The data type T that is stored in this red-black tree must be only
// Plain Old Data (POD), or bottom out into POD. It must _not_ rely on
// having its destructor called. This implementation internally
// allocates storage in large chunks and does not call the destructor
// on each object.
//
// Type T must supply a default constructor, a copy constructor, and
// the "<" and "==" operators.
//
// In debug mode, printing of the data contained in the tree is
// enabled. This requires the template specialization to be available:
//
//   template<> struct ValueToString<T> {
//       static String string(const T& t);
//   };
//
// Note that when complex types are stored in this red/black tree, it
// is possible that single invocations of the "<" and "==" operators
// will be insufficient to describe the ordering of elements in the
// tree during queries. As a concrete example, consider the case where
// intervals are stored in the tree sorted by low endpoint. The "<"
// operator on the Interval class only compares the low endpoint, but
// the "==" operator takes into account the high endpoint as well.
// This makes the necessary logic for querying and deletion somewhat
// more complex. In order to properly handle such situations, the
// property "needsFullOrderingComparisons" must be set to true on
// the tree.
//
// This red-black tree is designed to be _augmented_; subclasses can
// add additional and summary information to each node to efficiently
// store and index more complex data structures. A concrete example is
// the IntervalTree, which extends each node with a summary statistic
// to efficiently store one-dimensional intervals.
//
// The design of this red-black tree comes from Cormen, Leiserson,
// and Rivest, _Introduction to Algorithms_, MIT Press, 1990.

#ifndef PODRedBlackTree_h
#define PODRedBlackTree_h

#include "platform/PODFreeListArena.h"
#include "wtf/Assertions.h"
#include "wtf/Noncopyable.h"
#include "wtf/RefPtr.h"
#ifndef NDEBUG
#include "wtf/text/CString.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/WTFString.h"
#endif

namespace blink {

#ifndef NDEBUG
template<class T>
struct ValueToString;
#endif

enum UninitializedTreeEnum {
    UninitializedTree
};

template<class T>
class PODRedBlackTree {
public:
    class Node;

    // Visitor interface for walking all of the tree's elements.
    class Visitor {
    public:
        virtual void visit(const T& data) = 0;
    protected:
        virtual ~Visitor() { }
    };

    // Constructs a new red-black tree without allocating an arena.
    // isInitialized will return false in this case. initIfNeeded can be used
    // to init the structure. This constructor is usefull for creating
    // lazy initialized tree.
    explicit PODRedBlackTree(UninitializedTreeEnum)
        : m_root(0)
        , m_needsFullOrderingComparisons(false)
#ifndef NDEBUG
        , m_verboseDebugging(false)
#endif
    {
    }

    // Constructs a new red-black tree, allocating temporary objects
    // from a newly constructed PODFreeListArena.
    PODRedBlackTree()
        : m_arena(PODFreeListArena<Node>::create())
        , m_root(0)
        , m_needsFullOrderingComparisons(false)
#ifndef NDEBUG
        , m_verboseDebugging(false)
#endif
    {
    }

    // Constructs a new red-black tree, allocating temporary objects
    // from the given PODArena.
    explicit PODRedBlackTree(PassRefPtr<PODFreeListArena<Node> > arena)
        : m_arena(arena)
        , m_root(0)
        , m_needsFullOrderingComparisons(false)
#ifndef NDEBUG
        , m_verboseDebugging(false)
#endif
    {
    }

    virtual ~PODRedBlackTree() { }

    // Clearing will delete the contents of the tree. After this call
    // isInitialized will return false.
    void clear()
    {
        markFree(m_root);
        m_arena = nullptr;
        m_root = 0;
    }

    bool isInitialized() const
    {
        return m_arena;
    }

    void initIfNeeded()
    {
        if (!m_arena)
            m_arena = PODFreeListArena<Node>::create();
    }

    void initIfNeeded(PODFreeListArena<Node>* arena)
    {
        if (!m_arena)
            m_arena = arena;
    }

    void add(const T& data)
    {
        ASSERT(isInitialized());
        Node* node = m_arena->template allocateObject<T>(data);
        insertNode(node);
    }

    // Returns true if the datum was found in the tree.
    bool remove(const T& data)
    {
        ASSERT(isInitialized());
        Node* node = treeSearch(data);
        if (node) {
            deleteNode(node);
            return true;
        }
        return false;
    }

    bool contains(const T& data) const
    {
        ASSERT(isInitialized());
        return treeSearch(data);
    }

    void visitInorder(Visitor* visitor) const
    {
        ASSERT(isInitialized());
        if (!m_root)
            return;
        visitInorderImpl(m_root, visitor);
    }

    int size() const
    {
        ASSERT(isInitialized());
        Counter counter;
        visitInorder(&counter);
        return counter.count();
    }

    // See the class documentation for an explanation of this property.
    void setNeedsFullOrderingComparisons(bool needsFullOrderingComparisons)
    {
        m_needsFullOrderingComparisons = needsFullOrderingComparisons;
    }

    virtual bool checkInvariants() const
    {
        ASSERT(isInitialized());
        int blackCount;
        return checkInvariantsFromNode(m_root, &blackCount);
    }

#ifndef NDEBUG
    // Dumps the tree's contents to the logging info stream for
    // debugging purposes.
    void dump() const
    {
        if (m_arena)
            dumpFromNode(m_root, 0);
    }

    // Turns on or off verbose debugging of the tree, causing many
    // messages to be logged during insertion and other operations in
    // debug mode.
    void setVerboseDebugging(bool verboseDebugging)
    {
        m_verboseDebugging = verboseDebugging;
    }
#endif

    enum Color {
        Red = 1,
        Black
    };

    // The base Node class which is stored in the tree. Nodes are only
    // an internal concept; users of the tree deal only with the data
    // they store in it.
    class Node {
        WTF_MAKE_NONCOPYABLE(Node);
    public:
        // Constructor. Newly-created nodes are colored red.
        explicit Node(const T& data)
            : m_left(0)
            , m_right(0)
            , m_parent(0)
            , m_color(Red)
            , m_data(data)
        {
        }

        virtual ~Node() { }

        Color color() const { return m_color; }
        void setColor(Color color) { m_color = color; }

        // Fetches the user data.
        T& data() { return m_data; }

        // Copies all user-level fields from the source node, but not
        // internal fields. For example, the base implementation of this
        // method copies the "m_data" field, but not the child or parent
        // fields. Any augmentation information also does not need to be
        // copied, as it will be recomputed. Subclasses must call the
        // superclass implementation.
        virtual void copyFrom(Node* src) { m_data = src->data(); }

        Node* left() const { return m_left; }
        void setLeft(Node* node) { m_left = node; }

        Node* right() const { return m_right; }
        void setRight(Node* node) { m_right = node; }

        Node* parent() const { return m_parent; }
        void setParent(Node* node) { m_parent = node; }

    private:
        Node* m_left;
        Node* m_right;
        Node* m_parent;
        Color m_color;
        T m_data;
    };

protected:
    // Returns the root of the tree, which is needed by some subclasses.
    Node* root() const { return m_root; }

private:
    // This virtual method is the hook that subclasses should use when
    // augmenting the red-black tree with additional per-node summary
    // information. For example, in the case of an interval tree, this
    // is used to compute the maximum endpoint of the subtree below the
    // given node based on the values in the left and right children. It
    // is guaranteed that this will be called in the correct order to
    // properly update such summary information based only on the values
    // in the left and right children. This method should return true if
    // the node's summary information changed.
    virtual bool updateNode(Node*) { return false; }

    //----------------------------------------------------------------------
    // Generic binary search tree operations
    //

    // Searches the tree for the given datum.
    Node* treeSearch(const T& data) const
    {
        if (m_needsFullOrderingComparisons)
            return treeSearchFullComparisons(m_root, data);

        return treeSearchNormal(m_root, data);
    }

    // Searches the tree using the normal comparison operations,
    // suitable for simple data types such as numbers.
    Node* treeSearchNormal(Node* current, const T& data) const
    {
        while (current) {
            if (current->data() == data)
                return current;
            if (data < current->data())
                current = current->left();
            else
                current = current->right();
        }
        return 0;
    }

    // Searches the tree using multiple comparison operations, required
    // for data types with more complex behavior such as intervals.
    Node* treeSearchFullComparisons(Node* current, const T& data) const
    {
        if (!current)
            return 0;
        if (data < current->data())
            return treeSearchFullComparisons(current->left(), data);
        if (current->data() < data)
            return treeSearchFullComparisons(current->right(), data);
        if (data == current->data())
            return current;

        // We may need to traverse both the left and right subtrees.
        Node* result = treeSearchFullComparisons(current->left(), data);
        if (!result)
            result = treeSearchFullComparisons(current->right(), data);
        return result;
    }

    void treeInsert(Node* z)
    {
        Node* y = 0;
        Node* x = m_root;
        while (x) {
            y = x;
            if (z->data() < x->data())
                x = x->left();
            else
                x = x->right();
        }
        z->setParent(y);
        if (!y) {
            m_root = z;
        } else {
            if (z->data() < y->data())
                y->setLeft(z);
            else
                y->setRight(z);
        }
    }

    // Finds the node following the given one in sequential ordering of
    // their data, or null if none exists.
    Node* treeSuccessor(Node* x)
    {
        if (x->right())
            return treeMinimum(x->right());
        Node* y = x->parent();
        while (y && x == y->right()) {
            x = y;
            y = y->parent();
        }
        return y;
    }

    // Finds the minimum element in the sub-tree rooted at the given
    // node.
    Node* treeMinimum(Node* x)
    {
        while (x->left())
            x = x->left();
        return x;
    }

    // Helper for maintaining the augmented red-black tree.
    void propagateUpdates(Node* start)
    {
        bool shouldContinue = true;
        while (start && shouldContinue) {
            shouldContinue = updateNode(start);
            start = start->parent();
        }
    }

    //----------------------------------------------------------------------
    // Red-Black tree operations
    //

    // Left-rotates the subtree rooted at x.
    // Returns the new root of the subtree (x's right child).
    Node* leftRotate(Node* x)
    {
        // Set y.
        Node* y = x->right();

        // Turn y's left subtree into x's right subtree.
        x->setRight(y->left());
        if (y->left())
            y->left()->setParent(x);

        // Link x's parent to y.
        y->setParent(x->parent());
        if (!x->parent()) {
            m_root = y;
        } else {
            if (x == x->parent()->left())
                x->parent()->setLeft(y);
            else
                x->parent()->setRight(y);
        }

        // Put x on y's left.
        y->setLeft(x);
        x->setParent(y);

        // Update nodes lowest to highest.
        updateNode(x);
        updateNode(y);
        return y;
    }

    // Right-rotates the subtree rooted at y.
    // Returns the new root of the subtree (y's left child).
    Node* rightRotate(Node* y)
    {
        // Set x.
        Node* x = y->left();

        // Turn x's right subtree into y's left subtree.
        y->setLeft(x->right());
        if (x->right())
            x->right()->setParent(y);

        // Link y's parent to x.
        x->setParent(y->parent());
        if (!y->parent()) {
            m_root = x;
        } else {
            if (y == y->parent()->left())
                y->parent()->setLeft(x);
            else
                y->parent()->setRight(x);
        }

        // Put y on x's right.
        x->setRight(y);
        y->setParent(x);

        // Update nodes lowest to highest.
        updateNode(y);
        updateNode(x);
        return x;
    }

    // Inserts the given node into the tree.
    void insertNode(Node* x)
    {
        treeInsert(x);
        x->setColor(Red);
        updateNode(x);

        logIfVerbose("  PODRedBlackTree::InsertNode");

        // The node from which to start propagating updates upwards.
        Node* updateStart = x->parent();

        while (x != m_root && x->parent()->color() == Red) {
            if (x->parent() == x->parent()->parent()->left()) {
                Node* y = x->parent()->parent()->right();
                if (y && y->color() == Red) {
                    // Case 1
                    logIfVerbose("  Case 1/1");
                    x->parent()->setColor(Black);
                    y->setColor(Black);
                    x->parent()->parent()->setColor(Red);
                    updateNode(x->parent());
                    x = x->parent()->parent();
                    updateNode(x);
                    updateStart = x->parent();
                } else {
                    if (x == x->parent()->right()) {
                        logIfVerbose("  Case 1/2");
                        // Case 2
                        x = x->parent();
                        leftRotate(x);
                    }
                    // Case 3
                    logIfVerbose("  Case 1/3");
                    x->parent()->setColor(Black);
                    x->parent()->parent()->setColor(Red);
                    Node* newSubTreeRoot = rightRotate(x->parent()->parent());
                    updateStart = newSubTreeRoot->parent();
                }
            } else {
                // Same as "then" clause with "right" and "left" exchanged.
                Node* y = x->parent()->parent()->left();
                if (y && y->color() == Red) {
                    // Case 1
                    logIfVerbose("  Case 2/1");
                    x->parent()->setColor(Black);
                    y->setColor(Black);
                    x->parent()->parent()->setColor(Red);
                    updateNode(x->parent());
                    x = x->parent()->parent();
                    updateNode(x);
                    updateStart = x->parent();
                } else {
                    if (x == x->parent()->left()) {
                        // Case 2
                        logIfVerbose("  Case 2/2");
                        x = x->parent();
                        rightRotate(x);
                    }
                    // Case 3
                    logIfVerbose("  Case 2/3");
                    x->parent()->setColor(Black);
                    x->parent()->parent()->setColor(Red);
                    Node* newSubTreeRoot = leftRotate(x->parent()->parent());
                    updateStart = newSubTreeRoot->parent();
                }
            }
        }

        propagateUpdates(updateStart);

        m_root->setColor(Black);
    }

    // Restores the red-black property to the tree after splicing out
    // a node. Note that x may be null, which is why xParent must be
    // supplied.
    void deleteFixup(Node* x, Node* xParent)
    {
        while (x != m_root && (!x || x->color() == Black)) {
            if (x == xParent->left()) {
                // Note: the text points out that w can not be null.
                // The reason is not obvious from simply looking at
                // the code; it comes about from the properties of the
                // red-black tree.
                Node* w = xParent->right();
                ASSERT(w); // x's sibling should not be null.
                if (w->color() == Red) {
                    // Case 1
                    w->setColor(Black);
                    xParent->setColor(Red);
                    leftRotate(xParent);
                    w = xParent->right();
                }
                if ((!w->left() || w->left()->color() == Black)
                    && (!w->right() || w->right()->color() == Black)) {
                    // Case 2
                    w->setColor(Red);
                    x = xParent;
                    xParent = x->parent();
                } else {
                    if (!w->right() || w->right()->color() == Black) {
                        // Case 3
                        w->left()->setColor(Black);
                        w->setColor(Red);
                        rightRotate(w);
                        w = xParent->right();
                    }
                    // Case 4
                    w->setColor(xParent->color());
                    xParent->setColor(Black);
                    if (w->right())
                        w->right()->setColor(Black);
                    leftRotate(xParent);
                    x = m_root;
                    xParent = x->parent();
                }
            } else {
                // Same as "then" clause with "right" and "left"
                // exchanged.

                // Note: the text points out that w can not be null.
                // The reason is not obvious from simply looking at
                // the code; it comes about from the properties of the
                // red-black tree.
                Node* w = xParent->left();
                ASSERT(w); // x's sibling should not be null.
                if (w->color() == Red) {
                    // Case 1
                    w->setColor(Black);
                    xParent->setColor(Red);
                    rightRotate(xParent);
                    w = xParent->left();
                }
                if ((!w->right() || w->right()->color() == Black)
                    && (!w->left() || w->left()->color() == Black)) {
                    // Case 2
                    w->setColor(Red);
                    x = xParent;
                    xParent = x->parent();
                } else {
                    if (!w->left() || w->left()->color() == Black) {
                        // Case 3
                        w->right()->setColor(Black);
                        w->setColor(Red);
                        leftRotate(w);
                        w = xParent->left();
                    }
                    // Case 4
                    w->setColor(xParent->color());
                    xParent->setColor(Black);
                    if (w->left())
                        w->left()->setColor(Black);
                    rightRotate(xParent);
                    x = m_root;
                    xParent = x->parent();
                }
            }
        }
        if (x)
            x->setColor(Black);
    }

    // Deletes the given node from the tree. Note that this
    // particular node may not actually be removed from the tree;
    // instead, another node might be removed and its contents
    // copied into z.
    void deleteNode(Node* z)
    {
        // Y is the node to be unlinked from the tree.
        Node* y;
        if (!z->left() || !z->right())
            y = z;
        else
            y = treeSuccessor(z);

        // Y is guaranteed to be non-null at this point.
        Node* x;
        if (y->left())
            x = y->left();
        else
            x = y->right();

        // X is the child of y which might potentially replace y in
        // the tree. X might be null at this point.
        Node* xParent;
        if (x) {
            x->setParent(y->parent());
            xParent = x->parent();
        } else {
            xParent = y->parent();
        }
        if (!y->parent()) {
            m_root = x;
        } else {
            if (y == y->parent()->left())
                y->parent()->setLeft(x);
            else
                y->parent()->setRight(x);
        }
        if (y != z) {
            z->copyFrom(y);
            // This node has changed location in the tree and must be updated.
            updateNode(z);
            // The parent and its parents may now be out of date.
            propagateUpdates(z->parent());
        }

        // If we haven't already updated starting from xParent, do so now.
        if (xParent && xParent != y && xParent != z)
            propagateUpdates(xParent);
        if (y->color() == Black)
            deleteFixup(x, xParent);

        m_arena->freeObject(y);
    }

    // Visits the subtree rooted at the given node in order.
    void visitInorderImpl(Node* node, Visitor* visitor) const
    {
        if (node->left())
            visitInorderImpl(node->left(), visitor);
        visitor->visit(node->data());
        if (node->right())
            visitInorderImpl(node->right(), visitor);
    }

    void markFree(Node *node)
    {
        if (!node)
            return;

        if (node->left())
            markFree(node->left());
        if (node->right())
            markFree(node->right());
        m_arena->freeObject(node);
    }

    //----------------------------------------------------------------------
    // Helper class for size()

    // A Visitor which simply counts the number of visited elements.
    class Counter : public Visitor {
        WTF_MAKE_NONCOPYABLE(Counter);
    public:
        Counter()
            : m_count(0) { }

        virtual void visit(const T&) { ++m_count; }
        int count() const { return m_count; }

    private:
        int m_count;
    };

    //----------------------------------------------------------------------
    // Verification and debugging routines
    //

    // Returns in the "blackCount" parameter the number of black
    // children along all paths to all leaves of the given node.
    bool checkInvariantsFromNode(Node* node, int* blackCount) const
    {
        // Base case is a leaf node.
        if (!node) {
            *blackCount = 1;
            return true;
        }

        // Each node is either red or black.
        if (!(node->color() == Red || node->color() == Black))
            return false;

        // Every leaf (or null) is black.

        if (node->color() == Red) {
            // Both of its children are black.
            if (!((!node->left() || node->left()->color() == Black)))
                return false;
            if (!((!node->right() || node->right()->color() == Black)))
                return false;
        }

        // Every simple path to a leaf node contains the same number of
        // black nodes.
        int leftCount = 0, rightCount = 0;
        bool leftValid = checkInvariantsFromNode(node->left(), &leftCount);
        bool rightValid = checkInvariantsFromNode(node->right(), &rightCount);
        if (!leftValid || !rightValid)
            return false;
        *blackCount = leftCount + (node->color() == Black ? 1 : 0);
        return leftCount == rightCount;
    }

#ifdef NDEBUG
    void logIfVerbose(const char*) const { }
#else
    void logIfVerbose(const char* output) const
    {
        if (m_verboseDebugging)
            WTF_LOG_ERROR("%s", output);
    }
#endif

#ifndef NDEBUG
    // Dumps the subtree rooted at the given node.
    void dumpFromNode(Node* node, int indentation) const
    {
        StringBuilder builder;
        for (int i = 0; i < indentation; i++)
            builder.append(' ');
        builder.append('-');
        if (node) {
            builder.append(' ');
            builder.append(ValueToString<T>::string(node->data()));
            builder.append((node->color() == Black) ? " (black)" : " (red)");
        }
        WTF_LOG_ERROR("%s", builder.toString().ascii().data());
        if (node) {
            dumpFromNode(node->left(), indentation + 2);
            dumpFromNode(node->right(), indentation + 2);
        }
    }
#endif

    //----------------------------------------------------------------------
    // Data members

    RefPtr<PODFreeListArena<Node> > m_arena;
    Node* m_root;
    bool m_needsFullOrderingComparisons;
#ifndef NDEBUG
    bool m_verboseDebugging;
#endif
};

} // namespace blink

#endif // PODRedBlackTree_h

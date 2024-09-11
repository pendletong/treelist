//// TreeLists are ordered sequence of elements stored in an efficient binary
//// tree structure
//// 
//// New elements can be added at any index of the structure and will
//// be stored efficiently with O(log n) complexity
//// 
//// Based on https://en.wikipedia.org/wiki/AVL_tree
//// 

import gleam/bool
import gleam/int
import gleam/iterator.{type Iterator, Done, Next}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{Eq, Gt, Lt}

pub opaque type TreeList(value) {
  TreeList(root: Node(value))
}

pub opaque type Node(value) {
  Node(
    value: value,
    height: Int,
    size: Int,
    left: Node(value),
    right: Node(value),
  )
  BlankNode
}

fn new_node(value: value) -> Node(value) {
  Node(value, 1, 1, BlankNode, BlankNode)
}

/// Creates an empty treelist
pub fn new() -> TreeList(value) {
  TreeList(BlankNode)
}

/// Returns the number of elements in the provided treelist
pub fn size(list: TreeList(value)) -> Int {
  get_size(list.root)
}

/// Returns the element at the specified position in the provided treelist
/// 
/// Returns an Error(Nil) if the index is outside the allowed range
/// 
/// Index is zero based
/// 
/// 
/// ## Examples
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = add(list, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// ```
/// 
/// ```gleam
/// new() |> get(0)
/// // -> Error(Nil)
/// ```
/// 
pub fn get(list: TreeList(value), index: Int) -> Result(value, Nil) {
  use <- bool.guard(index < 0 || index >= size(list), return: Error(Nil))
  case get_node_at(list.root, index) {
    Node(value, ..) -> Ok(value)
    BlankNode -> Error(Nil)
  }
}

/// Adds an element to the end of the provided treelist
/// i.e. insert at position size(list)
/// 
/// Returns a new TreeList containing the provided element
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = add(list, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// ```
/// 
pub fn add(list: TreeList(value), value: value) -> Result(TreeList(value), Nil) {
  insert(list, size(list), value)
}

/// Inserts an element at the specified index in the provided treelist
/// 
/// Returns an Error(Nil) if the index is outside the allowed range
/// 
/// Index is zero based
/// 
/// Returns a new TreeList containing the provided element
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = insert(list, 0, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// ```
/// 
/// ```gleam
/// let list = new()
/// insert(list, 1, "Test")
/// // -> Error(Nil)
/// ```
/// 
pub fn insert(
  list: TreeList(value),
  index: Int,
  value: value,
) -> Result(TreeList(value), Nil) {
  use <- bool.guard(when: index < 0 || index > size(list), return: Error(Nil))
  use <- bool.guard(when: index > get_max_int(), return: Error(Nil))
  Ok(TreeList(insert_node_at(list.root, index, value)))
}

/// Updates the element at index specified in the provided treelist
/// 
/// Returns an Error(Nil) if the index is outside the allowed range
/// 
/// Index is zero based
/// 
/// Returns a new TreeList containing the updated node
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = add(list, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// let assert Ok(new_list) = set(list, 0, "Updated")
/// get(new_list, 0)
/// // -> Ok("Updated")
/// ```
/// 
pub fn set(
  list: TreeList(value),
  index: Int,
  value: value,
) -> Result(TreeList(value), Nil) {
  use <- bool.guard(index < 0 || index >= size(list), return: Error(Nil))

  Ok(TreeList(set_node_at(list.root, index, value)))
}

/// Converts a TreeList into a standard Gleam list
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = insert(list, 0, "Test")
/// let assert Ok(new_list2) = insert(new_list, 1, "Second")
/// to_list(new_list2)
/// // -> ["Test", "Second"]
/// ```
/// 
pub fn to_list(l: TreeList(value)) -> List(value) {
  do_to_list(l.root)
}

/// Takes a list and returns a new TreeList containing all the
/// elements from the list in the same order as that list
/// 
/// Returns an Error(Nil) in the case that the list is too large
/// 
/// ```gleam
/// let assert Ok(list) = from_list([1,2,3])
/// get(list, 1)
/// // -> Ok(2)
/// ```
/// 
pub fn from_list(list: List(value)) -> Result(TreeList(value), Nil) {
  list.try_fold(list, new(), fn(acc, val) { add(acc, val) })
}

/// Removes an element at the specified index in the provided treelist
/// 
/// Returns an Error(Nil) if the index is outside the allowed range
/// 
/// Index is zero based
/// 
/// Returns a tuple containing the value at the specified index and the new TreeList
/// 
/// ```gleam
/// let list = new()
/// let assert Ok(new_list) = insert(list, 0, "Test")
/// get(new_list, 0)
/// // -> Ok("Test")
/// remove(new_list, 0)
/// // -> #("Test", TreeList(..))
/// ```
/// 
/// ```gleam
/// let list = new()
/// remove(list, 1)
/// // -> Error(Nil)
/// ```
/// 
pub fn remove(
  list: TreeList(value),
  index: Int,
) -> Result(#(value, TreeList(value)), Nil) {
  use <- bool.guard(when: index < 0 || index > size(list), return: Error(Nil))

  case remove_node_at(list.root, index) {
    #(new_root, Some(value)) -> Ok(#(value, TreeList(new_root)))
    _ -> Error(Nil)
  }
}

/// Builds a list of a given value a given number of times.
///
/// ## Examples
///
/// ```gleam
/// repeat("a", times: 0)
/// // -> new()
/// ```
///
/// ```gleam
/// repeat("a", times: 5)
/// |> to_list
/// // -> ["a", "a", "a", "a", "a"]
/// ```
///
pub fn repeat(item a: a, times times: Int) -> Result(TreeList(a), Nil) {
  use <- bool.guard(when: times > get_max_int(), return: Error(Nil))
  Ok(TreeList(do_repeat(a, times, BlankNode)))
}

/// Creates an iterator that yields each element from the given treelist.
///
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// to_iterator(list)
/// |> to_list
/// // -> [1, 2, 3, 4]
/// ```
///
pub fn to_iterator(tlist: TreeList(value)) -> Iterator(value) {
  node_iterator(tlist.root, fn(_node, value, _index) { value })
}

/// Creates an iterator that yields each element from the given treelist.
///
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// to_iterator_reverse(list)
/// |> to_list
/// // -> [4, 3, 2, 1]
/// ```
///
pub fn to_iterator_reverse(tlist: TreeList(value)) -> Iterator(value) {
  node_iterator_reverse(tlist.root, fn(_node, value, _index) { value })
}

/// Returns the index of the first occurrence of the specified element
/// in this list, or -1 if this list does not contain the element.
/// 
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// index_of(list, 3)
/// // -> 2
/// ```
/// 
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4, 2, 2])
/// index_of(list, 2)
/// // -> 1
/// ```
/// 
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// index_of(list, 999)
/// // -> -1
/// ```
///
pub fn index_of(tlist: TreeList(value), item: value) -> Int {
  let stack = get_left_stack(tlist.root, [])
  do_index_of(stack, 0, item)
}

/// Returns the index of the last occurrence of the specified element
/// in this list, or -1 if this list does not contain the element.
/// 
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// last_index_of(list, 3)
/// // -> 2
/// ```
/// 
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4, 2, 2])
/// last_index_of(list, 2)
/// // -> 5
/// ```
/// 
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// last_index_of(list, 999)
/// // -> -1
/// ```
///
pub fn last_index_of(tlist: TreeList(value), item: value) -> Int {
  let stack = get_right_stack(tlist.root, [])
  do_last_index_of(stack, size(tlist) - 1, item)
}

/// Returns true if this list contains the specified element.
/// 
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// contains(list, 3)
/// // -> True
/// ```
/// 
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// contains(list, 999)
/// // -> False
/// ```
/// 
pub fn contains(tlist: TreeList(value), item: value) -> Bool {
  index_of(tlist, item) >= 0
}

/// Returns a new treelist containing only the elements from the first treelist for
/// which the given functions returns `True`.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(list) = from_list([2, 4, 6, 1])
/// filter(list), fn(x) { x > 2 })
/// |> to_list
/// // -> [4, 6]
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([2, 4, 6, 1])
/// filter(list), fn(x) { x > 6 })
/// |> to_list
/// // -> []
/// ```
///
pub fn filter(
  tlist: TreeList(value),
  filter_fn: fn(value) -> Bool,
) -> TreeList(value) {
  let stack = get_left_stack(tlist.root, [])
  TreeList(do_filter(stack, BlankNode, filter_fn))
}

/// Creates a new treelist from a given treelist containing the same elements but in the
/// opposite order.
///
/// ## Examples
///
/// ```gleam
/// reverse(new())
/// |> to_list
/// // -> []
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([1])
/// reverse(list)
/// |> to_list
/// // -> [1]
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2])
/// reverse(list)
/// |> to_list
/// // -> [2, 1]
/// ```
///
pub fn reverse(tlist: TreeList(value)) -> TreeList(value) {
  TreeList(do_reverse(tlist.root))
}

/// Gets the first element from the start of the treelist, if there is one.
///
/// ## Examples
///
/// ```gleam
/// first(new())
/// // -> Error(Nil)
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([0])
/// first(list)
/// // -> Ok(0)
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2])
/// first(list)
/// // -> Ok(1)
/// ```
///
pub fn first(tlist: TreeList(value)) -> Result(value, Nil) {
  case size(tlist) {
    0 -> Error(Nil)
    _ -> get(tlist, 0)
  }
}

/// Returns a new treelist minus the first element. If the treelist is empty, 
/// `Error(Nil)` is returned.
///
///
/// ## Examples
///
/// ```gleam
/// rest(new())
/// // -> Error(Nil)
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([0])
/// rest(list)
/// // -> Ok([])
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2])
/// rest(list)
/// // -> Ok([2])
/// ```
///
pub fn rest(tlist: TreeList(value)) -> Result(TreeList(value), Nil) {
  case size(tlist) {
    0 -> Error(Nil)
    1 -> Ok(new())
    _ -> Ok(TreeList(remove_node_at(tlist.root, 0).0))
  }
}

/// Gets the last element from the start of the treelist, if there is one.
///
/// ## Examples
///
/// ```gleam
/// last(new())
/// // -> Error(Nil)
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([0])
/// last(list)
/// // -> Ok(0)
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2])
/// last(list)
/// // -> Ok(2)
/// ```
///
pub fn last(tlist: TreeList(value)) -> Result(value, Nil) {
  case size(tlist) {
    0 -> Error(Nil)
    size -> get(tlist, size - 1)
  }
}

/// Returns a new treelist containing only the elements from the first treelist for
/// which the given functions returns `Ok(_)`.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(list) = from_list([2, 4, 6, 1])
/// filter_map(list, Error)
/// // -> []
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([2, 4, 6, 1])
/// filter_map(list, fn(x) { Ok(x + 1) })
/// |> to_list
/// // -> [3, 5, 7, 2]
/// ```
///
pub fn filter_map(
  tlist: TreeList(value),
  filter_fn: fn(value) -> Result(value2, err),
) -> TreeList(value2) {
  let stack = get_left_stack(tlist.root, [])
  TreeList(do_filter_map(stack, BlankNode, filter_fn))
}

/// Returns a new treelist containing only the elements of the first list after 
/// the function has been applied to each one.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(list) = from_list([2, 4, 6])
/// map(list, fn(x) { x * 2 })
/// |> to_list
/// // -> [4, 8, 12]
/// ```
///
pub fn map(
  tlist: TreeList(value),
  filter_fn: fn(value) -> value2,
) -> TreeList(value2) {
  let stack = get_left_stack(tlist.root, [])
  TreeList(do_map(stack, BlankNode, filter_fn))
}

/// Takes a function that returns a `Result` and applies it to each element in a
/// given treelist in turn.
///
/// If the function returns `Ok(new_value)` for all elements in the treelist then a
/// treelist of the new values is returned.
///
/// If the function returns `Error(reason)` for any of the elements then it is
/// returned immediately. None of the elements in the treelist are processed after
/// one returns an `Error`.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3])
/// let assert Ok(tl) = try_map(list, fn(x) { Ok(x + 2) })
/// treelist.to_list(tl)
/// // -> [3, 4, 5]
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3])
/// try_map(list, fn(_) { Error(0) })
/// // -> Error(0)
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([[1], [2, 3]])
/// let assert Ok(tl) = try_map(list, first)
/// treelist.to_list(tl)
/// // -> Ok([1, 2])
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([[1], [], [2]])
/// try_map(list, first)
/// // -> Error(Nil)
/// ```
///
pub fn try_map(
  tlist: TreeList(value),
  filter_fn: fn(value) -> Result(value2, err),
) -> Result(TreeList(value2), err) {
  let stack = get_left_stack(tlist.root, [])
  case do_try_map(stack, BlankNode, filter_fn) {
    Error(err) -> Error(err)
    Ok(node) -> Ok(TreeList(node))
  }
}

/// Returns a treelist that is the given treelist with up to the given number of
/// elements removed from the front of the treelist.
///
/// If the treelist has less than the number of elements an empty treelist is
/// returned.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// drop(list, 2)
/// |> to_list
/// // -> [3, 4]
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// drop(list, 9)
/// |> to_list
/// // -> []
/// ```
///
pub fn drop(tlist: TreeList(value), up_to_n: Int) -> TreeList(value) {
  case int.compare(size(tlist), up_to_n) {
    Eq | Lt -> new()
    Gt -> {
      TreeList(
        iterator.repeat(0)
        |> iterator.take(up_to_n)
        |> iterator.fold(tlist.root, fn(acc, n) {
          let #(new_list, _) = remove_node_at(acc, n)
          new_list
        }),
      )
    }
  }
}

/// Returns a treelist containing the first given number of elements from the given
/// treelist.
///
/// If the treelist has less than the number of elements then the full treelist is
/// returned.
///
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// take(list, 2)
/// |> to_list
/// // -> [1, 2]
/// ```
///
/// ```gleam
/// let assert Ok(list) = from_list([1, 2, 3, 4])
/// take(list, 9)
/// |> to_list
/// // -> [1, 2, 3, 4]
/// ```
///
pub fn take(tlist: TreeList(value), up_to_n: Int) -> TreeList(value) {
  case int.compare(size(tlist), up_to_n) {
    Eq | Lt -> tlist
    Gt -> {
      TreeList(do_take(get_left_stack(tlist.root, []), BlankNode, up_to_n - 1))
    }
  }
}

/// Returns the given item wrapped in a list.
///
/// ## Examples
///
/// ```gleam
/// wrap(1)
/// |> to_list
/// // -> [1]
///
/// wrap(["a", "b", "c"])
/// |> to_list
/// // -> [["a", "b", "c"]]
///
/// wrap([[]])
/// |> to_list
/// // -> [[[]]]
/// ```
///
///
pub fn wrap(val: value) -> TreeList(value) {
  TreeList(insert_node_at(BlankNode, 0, val))
}

/// Joins one treelist onto the end of another.
///
/// ## Examples
///
/// ```gleam
/// let assert Ok(l1) = treelist.from_list([1, 2])
/// let assert Ok(l2) = treelist.from_list([3])
/// let assert Ok(list) = append(l1, l2)
/// to_list(list)
/// // -> [1, 2, 3]
/// ```
///
pub fn append(
  tlist: TreeList(value),
  tlist2: TreeList(value),
) -> Result(TreeList(value), Nil) {
  use <- bool.guard(
    when: size(tlist) + size(tlist2) > get_max_int(),
    return: Error(Nil),
  )

  Ok(TreeList(do_append(get_left_stack(tlist2.root, []), tlist.root)))
}

// Internal functions

fn get_size(node: Node(value)) -> Int {
  case node {
    BlankNode -> 0
    Node(size:, ..) -> size
  }
}

fn get_height(node: Node(value)) -> Int {
  case node {
    BlankNode -> 0
    Node(height:, ..) -> height
  }
}

fn get_node_at(node: Node(value), index: Int) -> Node(value) {
  case node {
    Node(left: left, right: right, ..) -> {
      case int.compare(index, get_size(left)) {
        Lt -> {
          get_node_at(left, index)
        }
        Gt -> {
          get_node_at(right, index - get_size(left) - 1)
        }
        Eq -> node
      }
    }
    _ -> BlankNode
  }
}

fn insert_node_at(
  node: Node(value),
  index: Int,
  new_value: value,
) -> Node(value) {
  case node {
    Node(left:, right:, size:, height:, value:) -> {
      let left_size = get_size(left)
      let res = case int.compare(index, left_size) {
        Lt | Eq -> {
          Node(
            height:,
            size:,
            right:,
            value:,
            left: insert_node_at(left, index, new_value),
          )
        }
        Gt -> {
          Node(
            height:,
            size:,
            left:,
            value:,
            right: insert_node_at(right, index - left_size - 1, new_value),
          )
        }
      }
      case recalculate(res) {
        BlankNode -> BlankNode
        node -> balance(node)
      }
    }
    _ -> new_node(new_value)
  }
}

fn recalculate(node: Node(value)) -> Node(value) {
  case node {
    Node(value:, left:, right:, ..) -> {
      let new_height = int.max(get_height(left), get_height(right)) + 1
      let new_size = get_size(left) + get_size(right) + 1
      Node(value:, left:, right:, height: new_height, size: new_size)
    }
    _ -> BlankNode
  }
}

fn balance(node: Node(value)) -> Node(value) {
  case node {
    Node(value:, height:, size:, left:, right:) -> {
      case get_balance(left, right) {
        -2 -> {
          rotate_right(case balance_of(left) {
            1 -> {
              Node(value:, height:, size:, left: rotate_left(left), right:)
            }
            _ -> node
          })
        }
        2 -> {
          rotate_left(case balance_of(right) {
            -1 -> {
              Node(value:, height:, size:, left:, right: rotate_right(right))
            }
            _ -> node
          })
        }
        _ -> node
      }
    }
    _ -> BlankNode
  }
}

fn rotate_left(node: Node(value)) -> Node(value) {
  case node {
    Node(
      value:,
      height:,
      size:,
      right: Node(
        value: right_value,
        height: right_height,
        size: right_size,
        left: right_left,
        right: right_right,
      ),
      left:,
    ) -> {
      recalculate(Node(
        value: right_value,
        height: right_height,
        size: right_size,
        right: right_right,
        left: recalculate(Node(
          value: value,
          height: height,
          size: size,
          right: right_left,
          left: left,
        )),
      ))
    }
    _ -> BlankNode
  }
}

fn rotate_right(node: Node(value)) -> Node(value) {
  case node {
    Node(
      value:,
      height:,
      size:,
      left: Node(
        value: left_value,
        height: left_height,
        size: left_size,
        left: left_left,
        right: left_right,
      ),
      right:,
    ) -> {
      recalculate(Node(
        value: left_value,
        height: left_height,
        size: left_size,
        left: left_left,
        right: recalculate(Node(
          value: value,
          height: height,
          size: size,
          left: left_right,
          right: right,
        )),
      ))
    }
    _ -> BlankNode
  }
}

fn balance_of(node: Node(_)) -> Int {
  case node {
    Node(left:, right:, ..) -> get_balance(left, right)
    _ -> 9999
  }
}

fn get_balance(left: Node(_), right: Node(_)) -> Int {
  get_height(right) - get_height(left)
}

fn get_max_int() -> Int {
  999_999_999_999
}

fn do_to_list(node: Node(value)) -> List(value) {
  case node {
    Node(value:, left:, right:, ..) -> {
      let left_list = case left {
        BlankNode -> []
        _ -> do_to_list(left)
      }
      let right_list = case right {
        BlankNode -> []
        _ -> do_to_list(right)
      }

      list.append(left_list, [value, ..right_list])
    }
    _ -> []
  }
}

fn remove_node_at(
  node: Node(value),
  index: Int,
) -> #(Node(value), Option(value)) {
  case node {
    Node(value:, height:, size:, left:, right:) -> {
      let #(res, removed_value, rebalance) = case
        int.compare(index, get_size(left))
      {
        Lt -> {
          case remove_node_at(left, index) {
            #(new_node, Some(rval)) -> #(
              Node(value:, height:, size:, left: new_node, right:),
              Some(rval),
              True,
            )
            _ -> #(BlankNode, None, False)
          }
        }
        Gt -> {
          case remove_node_at(right, index - get_size(left) - 1) {
            #(new_node, Some(rval)) -> #(
              Node(value:, height:, size:, left:, right: new_node),
              Some(rval),
              True,
            )
            _ -> #(BlankNode, None, False)
          }
        }
        Eq -> {
          case left, right {
            BlankNode, BlankNode -> {
              #(BlankNode, Some(value), False)
            }
            _, BlankNode -> {
              #(left, Some(value), False)
            }
            BlankNode, _ -> {
              #(right, Some(value), False)
            }
            _, _ -> {
              let temp = find_ultimate_left(right)
              case remove_node_at(right, 0), temp {
                #(new_node, _), Node(unode_value, _, _, _, _) -> #(
                  Node(
                    value: unode_value,
                    height:,
                    size:,
                    left:,
                    right: new_node,
                  ),
                  Some(value),
                  True,
                )
                _, _ -> #(BlankNode, None, False)
              }
            }
          }
        }
      }

      case rebalance {
        False -> #(res, removed_value)
        True -> {
          case recalculate(res) {
            BlankNode -> #(BlankNode, None)
            node -> #(balance(node), removed_value)
          }
        }
      }
    }
    _ -> #(BlankNode, None)
  }
}

fn find_ultimate_left(node: Node(value)) -> Node(value) {
  case node {
    Node(_, _, _, left, _) -> {
      case left {
        BlankNode -> node
        _ -> find_ultimate_left(left)
      }
    }
    BlankNode -> panic
  }
}

fn do_repeat(a: a, times: Int, acc: Node(a)) -> Node(a) {
  case times <= 0 {
    True -> acc
    False -> do_repeat(a, times - 1, insert_node_at(acc, 0, a))
  }
}

fn node_iterator(
  tlist: Node(value),
  ret_fn: fn(Node(value), value, Int) -> ret_type,
) -> Iterator(ret_type) {
  let stack = #(get_left_stack(tlist, []), 0)
  let yield = fn(acc: #(List(Node(value)), Int)) {
    case acc {
      #([Node(value:, right:, ..) as node, ..rest], index) -> {
        let rest = list.append(get_left_stack(right, []), rest)
        Next(ret_fn(node, value, index), #(rest, index + 1))
      }
      _ -> Done
    }
  }

  iterator.unfold(stack, yield)
}

fn node_iterator_reverse(
  tlist: Node(value),
  ret_fn: fn(Node(value), value, Int) -> ret_type,
) -> Iterator(ret_type) {
  let stack = #(get_right_stack(tlist, []), 0)
  let yield = fn(acc: #(List(Node(value)), Int)) {
    case acc {
      #([Node(value:, left:, ..) as node, ..rest], index) -> {
        let rest = list.append(get_right_stack(left, []), rest)
        Next(ret_fn(node, value, index), #(rest, index + 1))
      }
      _ -> Done
    }
  }

  iterator.unfold(stack, yield)
}

fn get_left_stack(
  node: Node(value),
  acc: List(Node(value)),
) -> List(Node(value)) {
  case node {
    BlankNode -> acc
    Node(left:, ..) -> get_left_stack(left, [node, ..acc])
  }
}

fn get_right_stack(
  node: Node(value),
  acc: List(Node(value)),
) -> List(Node(value)) {
  case node {
    BlankNode -> acc
    Node(right:, ..) -> get_right_stack(right, [node, ..acc])
  }
}

fn set_node_at(node: Node(value), index: Int, new_value: value) -> Node(value) {
  case node {
    Node(value:, height:, size:, left:, right:) -> {
      let left_size = get_size(left)
      case int.compare(index, left_size) {
        Lt -> {
          Node(
            value:,
            size:,
            height:,
            left: set_node_at(left, index, new_value),
            right:,
          )
        }
        Gt -> {
          Node(
            value:,
            size:,
            height:,
            left:,
            right: set_node_at(right, index - left_size - 1, new_value),
          )
        }
        Eq -> Node(value: new_value, size:, height:, left:, right:)
      }
    }
    _ -> BlankNode
  }
}

fn do_index_of(
  node_stack: List(Node(value)),
  index: Int,
  search_value: value,
) -> Int {
  case node_stack {
    [Node(value:, right:, ..), ..rest] -> {
      case value == search_value {
        True -> index
        False ->
          do_index_of(
            list.append(get_left_stack(right, []), rest),
            index + 1,
            search_value,
          )
      }
    }
    _ -> -1
  }
}

fn do_last_index_of(
  node_stack: List(Node(value)),
  index: Int,
  search_value: value,
) -> Int {
  case node_stack {
    [Node(value:, left:, ..), ..rest] -> {
      case value == search_value {
        True -> index
        False ->
          do_last_index_of(
            list.append(get_right_stack(left, []), rest),
            index - 1,
            search_value,
          )
      }
    }
    _ -> -1
  }
}

fn do_filter(
  node_stack: List(Node(value)),
  acc: Node(value),
  filter_fn: fn(value) -> Bool,
) -> Node(value) {
  case node_stack {
    [Node(value:, right:, ..), ..rest] -> {
      do_filter(
        list.append(get_left_stack(right, []), rest),
        case filter_fn(value) {
          True -> insert_node_at(acc, get_size(acc), value)
          //add(acc, value)
          False -> acc
        },
        filter_fn,
      )
    }
    _ -> acc
  }
}

fn do_filter_map(
  node_stack: List(Node(value)),
  acc: Node(value2),
  filter_fn: fn(value) -> Result(value2, err),
) -> Node(value2) {
  case node_stack {
    [Node(value:, right:, ..), ..rest] -> {
      do_filter_map(
        list.append(get_left_stack(right, []), rest),
        case filter_fn(value) {
          Ok(val) -> insert_node_at(acc, get_size(acc), val)
          //add(acc, value)
          _ -> acc
        },
        filter_fn,
      )
    }
    _ -> acc
  }
}

fn do_map(
  node_stack: List(Node(value)),
  acc: Node(value2),
  filter_fn: fn(value) -> value2,
) -> Node(value2) {
  case node_stack {
    [Node(value:, right:, ..), ..rest] -> {
      do_map(
        list.append(get_left_stack(right, []), rest),
        insert_node_at(acc, get_size(acc), filter_fn(value)),
        filter_fn,
      )
    }
    _ -> acc
  }
}

pub fn do_reverse(node: Node(value)) -> Node(value) {
  case node {
    Node(left:, right:, value:, height:, size:) ->
      Node(
        left: do_reverse(right),
        right: do_reverse(left),
        value:,
        height:,
        size:,
      )
    _ -> node
  }
}

fn do_try_map(
  node_stack: List(Node(value)),
  acc: Node(value2),
  filter_fn: fn(value) -> Result(value2, err),
) -> Result(Node(value2), err) {
  case node_stack {
    [Node(value:, right:, ..), ..rest] -> {
      case filter_fn(value) {
        Error(err) -> Error(err)
        Ok(value) ->
          do_try_map(
            list.append(get_left_stack(right, []), rest),
            insert_node_at(acc, get_size(acc), value),
            filter_fn,
          )
      }
    }
    _ -> Ok(acc)
  }
}

fn do_take(
  node_stack: List(Node(value)),
  acc: Node(value),
  index: Int,
) -> Node(value) {
  case index >= 0 {
    True -> {
      case node_stack {
        [Node(value:, right:, ..), ..rest] -> {
          do_take(
            list.append(get_left_stack(right, []), rest),
            insert_node_at(acc, get_size(acc), value),
            index - 1,
          )
        }
        _ -> acc
      }
    }
    False -> acc
  }
}

fn do_append(node_stack: List(Node(value)), acc: Node(value)) -> Node(value) {
  case node_stack {
    [Node(value:, right:, ..), ..rest] -> {
      do_append(
        list.append(get_left_stack(right, []), rest),
        insert_node_at(acc, get_size(acc), value),
      )
    }
    _ -> acc
  }
}
